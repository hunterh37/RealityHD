import simd
import Foundation

/// One 12 m cell of US two-lane rural highway, 24 m wide, travel along +Z so tiles chain end to start
/// (same cell as `road-straight`). Two 3.66 m chip-seal asphalt lanes (7.32 m), double yellow centre line,
/// white edge lines, 2.4 m shoulders (0.8 m paved with milled rumble-strip grooves, the rest gravel) and
/// grass ditch slopes out to the tile edge at x = +-12. Optional reflector delineator posts. Road surface at
/// y = `roadTop`; seeds move cracks, patches, grass relief and post placement.
public struct RuralHighwayTile: RealAsset {
    public static let id = "rural-highway-tile"
    public static let summary = "12 m two-lane rural highway tile, 24 m wide: worn chip-seal asphalt, double yellow, edge lines, rumble-strip shoulders, gravel and grass ditches, optional delineator posts."
    public static let tags = ["structure", "city", "road", "tile", "outdoor", "street", "ground"]
    public static let budget = 7_800
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 30, distance: 1.0)

    /// Cell length along +Z in meters.
    public var cell: Float = CityGrid.roadCell
    /// Tile width in meters (x), grass runs to both edges.
    public var tileWidth: Float = 24
    /// Travel lane width in meters.
    public var laneWidth: Float = 3.66
    /// Total shoulder width per side in meters.
    public var shoulderWidth: Float = 2.4
    /// Paved part of the shoulder that carries the rumble strip, in meters.
    public var pavedShoulder: Float = 0.8
    /// Road surface height above the tile base in meters.
    public var roadTop: Float = 0.53
    /// Milled rumble-strip groove pitch (m) and depth (m).
    public var rumblePitch: Float = 0.3
    public var rumbleDepth: Float = 0.014
    /// Sealed cracks and utility patches.
    public var cracks = 7
    public var patches = 2
    /// Reflector delineator posts on both shoulders.
    public var delineators = true
    public var asphalt: MaterialKey = "asphalt.worn"
    public var gravel: MaterialKey = "ground.gravel"
    public var grass: MaterialKey = "ground.meadow"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let L = cell, T = roadTop, hw = laneWidth, ns = UInt32(truncatingIfNeeded: seed)
        let e1 = hw + pavedShoulder, e2 = hw + shoulderWidth, edge = tileWidth / 2
        let taper = { (s: Float) -> Float in smoothstep(0, 1.5, L / 2 - abs(s)) }

        /// Strip over sample positions `ss` (z) and `pts` (x, y) rows, facing up, UVs in meters.
        func strip(_ material: MaterialKey, _ pts: [(Float, Float)], along ss: [Float], wobble: Float = 0, dip: ((Float, Int) -> Float)? = nil) -> Surface {
            var sf = Surface(material: material)
            for s in ss { for (i, p) in pts.enumerated() {
                let fade = taper(s) * max(0, min(1, (edge - abs(p.0)) / 1.5))
                let w = wobble * Noise.fbm(V3(s * 0.6, p.0 * 0.6, 0), octaves: 3, seed: ns &+ 5) * fade
                _ = sf.add(V3(p.0, p.1 + w + (dip?(s, i) ?? 0), s), .up, V2(p.0, s))
            }}
            let row = UInt32(pts.count)
            for j in 0..<UInt32(ss.count - 1) { for i in 0..<(row - 1) {
                let a = j * row + i
                sf.quad(a, a + row, a + row + 1, a + 1)
            }}
            sf.recomputeNormals(weldSeams: false)
            var dot: Float = 0
            for n in sf.normals { dot += simd_dot(n, .up) }
            if dot < 0 {
                for k in stride(from: 0, to: sf.indices.count, by: 3) { sf.indices.swapAt(k + 1, k + 2) }
                sf.recomputeNormals(weldSeams: false)
            }
            sf.computeTangents()
            return sf
        }
        let coarse = (0...6).map { -L / 2 + L * Float($0) / 6 }
        let fine = (0...12).map { -L / 2 + L * Float($0) / 12 }

        // Carriageway: flat chip-seal, two lanes.
        m.add(strip(asphalt, [(-hw, T), (hw, T)], along: [-L / 2, L / 2]))

        // Paint, 4 mm proud: double yellow (10 cm bars, 10 cm gap), white edge lines inside the lane edge.
        let lift: Float = 0.004
        for u: Float in [-0.1, 0.1] {
            m.add(strip("paint.lane-yellow", [(u - 0.05, T + lift), (u + 0.05, T + lift)], along: [-L / 2, L / 2]))
        }
        for s: Float in [-1, 1] {
            m.add(strip("paint.lane-white", [(s * (hw - 0.27), T + lift), (s * (hw - 0.15), T + lift)], along: [-L / 2, L / 2]))
        }

        // Shoulders: paved strip with milled rumble grooves (0.17 m long, every `rumblePitch`), gravel, grass ditch.
        var rs: [Float] = [-L / 2]
        var g = -L / 2 + 0.09
        var grooves: [(Float, Float)] = []
        while g + 0.17 < L / 2 - 0.05 { grooves.append((g, g + 0.17)); g += rumblePitch }
        for (a, b) in grooves { rs += [a, a + 0.02, b - 0.02, b] }
        rs.append(L / 2)
        func groove(_ s: Float) -> Float {
            for (a, b) in grooves where s >= a - 1e-4 && s <= b + 1e-4 {
                return -rumbleDepth * min(1, min(s - a, b - s) / 0.02)
            }
            return 0
        }
        for side: Float in [-1, 1] {
            let pave: [(Float, Float)] = [(side * hw, T), (side * (hw + 0.1), T - 0.002), (side * (hw + 0.6), T - 0.006), (side * e1, T - 0.01)]
            let ordered = side < 0 ? pave.reversed() : pave
            m.add(strip(asphalt, Array(ordered), along: rs, dip: { s, i in
                let k = side < 0 ? 3 - i : i
                return (k == 1 || k == 2) ? groove(s) : 0
            }))
            let gr: [(Float, Float)] = [(side * e1, T - 0.01), (side * (e1 + 0.8), T - 0.03), (side * e2, T - 0.06)]
            m.add(strip(gravel, side < 0 ? gr.reversed() : gr, along: coarse, wobble: 0.015))
            let dt: [(Float, Float)] = [(e2, -0.06), (e2 + 0.7, -0.26), (e2 + 1.4, -0.5), (e2 + 1.9, -0.48), (edge, -0.32)]
                .map { ($0.0 * side, T + $0.1) }
            m.add(strip(grass, side < 0 ? dt.reversed() : dt, along: fine, wobble: 0.07))
        }

        // Patches and sealed cracks on the lanes (flat layers at road level).
        for _ in 0..<patches {
            cityPatch(&m, center: V2(rng.pick([-1, 1]) * rng.float(1.2...3.2), rng.float(-4...4)), size: V2(rng.float(0.9...1.4), rng.float(1.8...3.4)),
                      angle: rng.float(-0.04...0.04), y: T, rng: &rng)
        }
        for _ in 0..<cracks {
            let across = rng.chance(0.4)
            citySealedCrack(&m, start: V2(rng.float(-5.5...5.5), rng.float(-5...5)), angle: (across ? 0 : .pi / 2) + rng.float(-0.4...0.4),
                            length: rng.float(1.5...4.0), y: T, bounds: 5.9, rng: &rng)
        }

        // Delineators: flexible white post, 1.1 m, reflector on both faces. White right of travel (-x), yellow left.
        if delineators {
            for side: Float in [-1, 1] {
                let z = rng.float(-2.5...2.5)
                var p = Model(name: "post")
                p.add(Prim.roundedBox(V3(0.07, 1.1, 0.07), radius: 0.012, bevelSegments: 1, material: "plastic.pom"), Xform(translation: V3(0, 0.55, 0)))
                for f: Float in [-1, 1] {
                    p.add(Prim.roundedBox(V3(0.05, 0.16, 0.006), radius: 0.002, bevelSegments: 1, material: side < 0 ? "paint.lane-white" : "paint.lane-yellow"),
                          Xform(translation: V3(0, 0.95, f * 0.036)))
                }
                m.add(p, Xform(translation: V3(side * (e2 + 0.15), T - 0.07, z),
                               rotation: simd_quatf(angle: rng.float(-0.03...0.03), axis: V3(1, 0, 0))))
            }
        }
        return LODModel(m)
    }
}
