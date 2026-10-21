import simd
import Foundation

/// One 40 m tile of tight two-lane mountain road, 6.5 m of fresh asphalt with white edge lines and a dashed
/// yellow centerline, 1 m gravel shoulders, a W-beam guardrail on the drop side (+Z of travel) and a quarried
/// granite cut with a gravel ditch on the uphill side (-Z). Travel is along +X. The tile is centred on its own
/// midpoint with the road heading +X there, so `Pose.advance` chains tiles end to start. Road surface at
/// y = `roadTop`, embankment foot at y = 0.
public struct MountainRoadTile: RealAsset {
    public static let id = "mountain-road-tile"
    public static let summary = "40 m two-lane mountain road tile: fresh asphalt, painted lines, gravel shoulders, drop-side guardrail, uphill rock cut; signed bend radius for chaining."
    public static let tags = ["structure", "road", "tile", "outdoor", "barrier", "rock", "metal"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 205, elevation: 24, distance: 1.1)

    /// Tile length along the road centerline in meters.
    public var length: Float = 40
    /// Asphalt width between edge lines' outer sides in meters.
    public var width: Float = 6.5
    /// Signed bend radius of the centerline in meters. 0 = straight; positive bends toward the drop side (right of travel), negative toward the rock cut.
    public var curvature: Float = 0
    /// Height of the road surface above the embankment foot in meters.
    public var roadTop: Float = 2.0
    /// Height of the rock cut above the road in meters.
    public var cutHeight: Float = 6.5
    /// Guardrail on the drop side.
    public var guardrail = true
    /// Fresh asphalt tint.
    public var asphalt: MaterialKey = "asphalt.road:2A2A2D"
    public var rock: MaterialKey = "rock.granite"
    public var verge: MaterialKey = "ground.alpine"
    public init() {}

    /// Position (x, z), heading (radians from +X toward +Z) after `s` meters along the centerline of a tile
    /// whose centerline curvature is 1/`radius`, starting at `start`. Chain tiles: advance by `length`.
    public struct Pose: Sendable {
        public var p: V2
        public var heading: Float
        public init(p: V2 = .zero, heading: Float = 0) { self.p = p; self.heading = heading }
        public func advanced(_ s: Float, radius: Float) -> Pose {
            guard abs(radius) > 0.01 else { return Pose(p: p + V2(cos(heading), sin(heading)) * s, heading: heading) }
            let phi = s / radius
            let d = V2(sin(heading + phi) - sin(heading), -(cos(heading + phi) - cos(heading))) * radius
            return Pose(p: p + d, heading: heading + phi)
        }
        /// Scene placement of a tile whose start is this pose, at height y.
        public func tilePlacement(length: Float, radius: Float, y: Float) -> Xform {
            let mid = advanced(length / 2, radius: radius)
            return Xform(translation: V3(mid.p.x, y, mid.p.y), rotation: simd_quatf(angle: -mid.heading, axis: .up))
        }
    }

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        let L = length, T = roadTop, hw = width / 2
        let ns = UInt32(truncatingIfNeeded: seed)
        let R = curvature
        let nAlong = max(8, Int(L))
        /// Centerline frame at arc length s (tile-centred).
        func frame(_ s: Float) -> (p: V2, right: V2, dir: V2) {
            if abs(R) < 0.01 { return (V2(s, 0), V2(0, 1), V2(1, 0)) }
            let phi = s / R
            return (V2(R * sin(phi), R * (1 - cos(phi))), V2(-sin(phi), cos(phi)), V2(cos(phi), sin(phi)))
        }
        func world(_ s: Float, _ u: Float, _ y: Float) -> V3 {
            let f = frame(s); let q = f.p + f.right * u
            return V3(q.x, y, q.y)
        }
        let taper = { (s: Float) -> Float in smoothstep(0, 1.5, L / 2 - abs(s)) }
        func crown(_ u: Float) -> Float { 0.05 * (1 - (u / hw) * (u / hw)) }

        /// Mesh over (s, row) with row positions from a (u, y) polyline; UVs in meters. Faces `want`.
        func grid(_ material: MaterialKey, rows: Int, along: Int, want: V3 = .up,
                  point: (Float, Int) -> V3, uv: (Float, Int) -> V2) -> Surface {
            var sf = Surface(material: material)
            for j in 0...along {
                let s = -L / 2 + L * Float(j) / Float(along)
                for i in 0...rows { _ = sf.add(point(s, i), .up, uv(s, i)) }
            }
            let row = UInt32(rows + 1)
            for j in 0..<UInt32(along) { for i in 0..<UInt32(rows) {
                let a = j * row + i
                sf.quad(a, a + row, a + row + 1, a + 1)
            }}
            sf.recomputeNormals(weldSeams: false)
            var dot: Float = 0
            for n in sf.normals { dot += simd_dot(n, want) }
            if dot < 0 {
                for k in stride(from: 0, to: sf.indices.count, by: 3) { sf.indices.swapAt(k + 1, k + 2) }
                sf.recomputeNormals(weldSeams: false)
            }
            sf.computeTangents()
            return sf
        }
        /// Ground strip following a (u, y) polyline along the road.
        func strip(_ material: MaterialKey, _ pts: [(Float, Float)], along: Int? = nil, wobble: Float = 0) -> Surface {
            grid(material, rows: pts.count - 1, along: along ?? nAlong, point: { s, i in
                let (u, y) = pts[i]
                let w = wobble * Noise.fbm(V3(s * 0.7, u * 0.7, 0), octaves: 3, seed: ns &+ 3) * taper(s)
                return world(s, u, y + w * min(1, max(0, y / T)))
            }, uv: { s, i in V2(s, pts[i].0) })
        }

        // Asphalt: parabolic crown, 3% cross fall.
        let asphaltU = (0...12).map { -hw + width * Float($0) / 12 }
        m.add(strip(asphalt, asphaltU.map { ($0, T + crown($0)) }))

        // Paint, lifted 4 mm over the crown: white edge lines 0.3 m inside the edge, dashed yellow centre.
        let edgeU = hw - 0.3
        for side: Float in [-1, 1] {
            let u0 = side * edgeU - 0.06, u1 = side * edgeU + 0.06
            m.add(strip("paint.lane-white", [(u0, T + crown(u0) + 0.004), (u1, T + crown(u1) + 0.004)], along: nAlong))
        }
        let pitch: Float = 10, dash: Float = 3
        var dStart = -L / 2 + 1.5
        while dStart + dash <= L / 2 {
            let a = dStart, b = dStart + dash
            var sf = grid("paint.lane-yellow", rows: 1, along: 3, point: { s, i in
                let ss = a + (b - a) * (s + L / 2) / L
                let u: Float = i == 0 ? -0.06 : 0.06
                return world(ss, u, T + crown(u) + 0.004)
            }, uv: { s, i in V2(a + (b - a) * (s + L / 2) / L, i == 0 ? -0.06 : 0.06) })
            sf.computeTangents()
            m.add(sf)
            dStart += pitch
        }

        // Gravel shoulders, uphill ditch and drop-side embankment.
        let sh1 = hw + 1.0
        m.add(strip("ground.gravel", [(hw, T), (hw + 0.5, T - 0.015), (sh1, T - 0.04)], wobble: 0.012))
        let ditchU: [(Float, Float)] = [(-hw - 1.75, T - 0.12), (-hw - 1.4, T - 0.24), (-hw - 0.9, T - 0.1), (-hw - 0.45, T - 0.035), (-hw, T)]
        m.add(strip("ground.gravel", ditchU, wobble: 0.02))
        let footU = sh1 + (T - 0.04) * 2.0
        m.add(strip(verge, [(sh1, T - 0.04), (sh1 + 0.8, T - 0.2), (sh1 + (footU - sh1) * 0.6, T * 0.45), (footU, 0)], wobble: 0.1))

        // Rock cut: leaning granite face with strata ledges, topped by an alpine shelf.
        let u0 = -hw - 1.75, H = cutHeight, lean: Float = 2.2
        let baseY = T - 0.12
        let rows = 30
        m.add(grid(rock, rows: rows, along: nAlong * 2, want: V3(0, 0, 1), point: { s, i in
            let v = Float(i) / Float(rows)
            let y = baseY + H * v
            let ledge = 0.28 * sin(y * 2.6 + 3 * Noise.perlin(V3(s * 0.05, y * 0.2, 0), seed: ns))
            let nz = Noise.fbm(V3(s * 0.32, y * 0.4, 1.7), octaves: 4, seed: ns &+ 11)
            let blocks = 0.22 * Noise.ridged(V3(s * 0.7, y * 0.9, 4.1), octaves: 2, seed: ns &+ 7)
            let u = u0 - lean * v - (0.18 + 0.82 * v) * (1.6 * ledge + 2.6 * nz - 2 * blocks) * taper(s) * smoothstep(0, 0.08, v)
            return world(s, u, y)
        }, uv: { s, i in V2(s, baseY + H * Float(i) / Float(rows)) }))
        let topU = u0 - lean
        m.add(strip(verge, [(topU - 0.9, baseY + H - 0.05), (topU - 3.0, baseY + H + 0.1), (topU - 6.0, baseY + H + 0.35)], along: nAlong, wobble: 0.1))

        // Guardrail along the drop side, 4 m panels (2 m post pitch) following the curve.
        if guardrail {
            // Light W-beam panel: rail (face 0.35 m toward the road), two posts with blockouts, 2 m pitch.
            var g = Model(name: "rail")
            let hc: Float = 0.76 - 0.156, th: Float = 0.0035
            let wz: [(Float, Float)] = [(0, 0.156), (0, 0.13), (0.0825, 0.098), (0.0825, 0.072), (0, 0.04), (0, -0.04),
                                        (0.0825, -0.072), (0.0825, -0.098), (0, -0.13), (0, -0.156)]
            var outline: [V2] = wz.map { V2(-$0.0, $0.1) }
            outline += wz.reversed().map { V2(-($0.0 + th), $0.1) }
            g.add(Prim.extrude(outline, depth: 4, bevel: 0.0008, bevelSegments: 1, material: "metal.galvanized-aged"),
                  Xform(translation: V3(0, hc, 0.26), rotation: simd_quatf(degrees: 90, axis: .up)))
            for px: Float in [-1, 1] {
                g.add(Prim.roundedBox(V3(0.1, 0.92, 0.15), radius: 0.003, bevelSegments: 1, material: "metal.galvanized"), Xform(translation: V3(px, 0.46, 0)))
                g.add(Prim.roundedBox(V3(0.2, 0.3, 0.12), radius: 0.004, bevelSegments: 1, material: "wood.pine-aged"), Xform(translation: V3(px, hc, 0.135)))
            }
            let n = Int(L / 4)
            for k in 0..<n {
                let s = -L / 2 + 2 + 4 * Float(k)
                let f = frame(s)
                let ang = Float.pi - atan2(f.dir.y, f.dir.x)
                let p = world(s, hw + 1.1, T - 0.1)
                m.add(g, Xform(translation: p, rotation: simd_quatf(angle: ang, axis: .up)))
            }
        }
        return LODModel(m)
    }
}
