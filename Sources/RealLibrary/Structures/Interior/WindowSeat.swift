import simd
import Foundation

/// Built-in window seat, 1.4 x 0.55 x 0.5 m: painted shaker carcass with side gables, toe-kick plinth, face frame
/// and three inset drawers with raised-panel fronts and brass knobs, a top slab with a nosing, and a 90 mm
/// buttoned upholstered cushion. Back at -Z (against the sill wall), front faces +Z, base at y = 0.
public struct WindowSeat: RealAsset {
    public static let id = "window-seat"
    public static let summary = "Built-in window seat, 1.4 m: painted shaker carcass with three inset drawers and brass knobs, buttoned upholstered cushion."
    public static let tags = ["structure", "floorplan", "interior", "furniture", "wood", "fabric", "living"]
    public static let budget = 12_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 14, distance: 1.1, studio: true)

    public var width: Float = 1.4
    public var height: Float = 0.55
    public var depth: Float = 0.5
    /// Cushion thickness (m).
    public var cushionThickness: Float = 0.09
    public var paint: MaterialKey = "wood.painted-shaker:6E7F6B"
    public var paintWorn: MaterialKey = "wood.painted-shaker-worn:6E7F6B"
    public var cushion: MaterialKey = "fabric.linen:CFC6B0"
    public var knob: MaterialKey = "metal.brass-aged"
    public init() {}

    func model(lod: Int, seed: UInt64) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let seg = lod == 0 ? 2 : 1
        func box(_ s: V3, _ c: V3, _ mat: MaterialKey, r: Float = 0.002) {
            m.add(Prim.roundedBox(s, radius: min(r, min(s.x, s.y, s.z) * 0.45), bevelSegments: seg, material: mat),
                  Xform(translation: c).jittered(&rng, deg: 0, offset: 0.0004))
        }
        let W = width, D = depth - 0.024          // carcass depth; knobs reach the 0.5 m envelope
        let gt: Float = 0.022                                    // gable thickness
        let carcassTop = height - cushionThickness              // 0.46
        let toe: Float = 0.08
        let zf = D / 2                                           // front plane
        let inner = W - 2 * gt

        // Gables, back panel, plinth, deck and top slab.
        for sx: Float in [-1, 1] { box(V3(gt, carcassTop, D), V3(sx * (W / 2 - gt / 2), carcassTop / 2, 0), paint, r: 0.003) }
        box(V3(inner, carcassTop - toe - 0.02, 0.01), V3(0, (toe + carcassTop - 0.02) / 2, -zf + 0.005), paintWorn, r: 0.001)
        box(V3(inner, toe, D - 0.05), V3(0, toe / 2, -0.025), paintWorn, r: 0.002)
        // Toe-kick face board with a shadow gap, and a base molding cap above it.
        box(V3(inner, toe - 0.01, 0.014), V3(0, (toe - 0.01) / 2 + 0.002, zf - 0.04), paint, r: 0.002)
        box(V3(inner + 0.012, 0.014, 0.018), V3(0, toe + 0.003, zf - 0.04), paint, r: 0.004)

        // Face frame: two rails and four stiles around three drawer openings.
        let railB: Float = 0.026, railT: Float = 0.04
        let y0 = toe + railB, y1 = carcassTop - 0.02 - railT, oh = y1 - y0
        let stile: Float = 0.04
        let ow = (inner - 4 * stile) / 3
        box(V3(inner, railB, 0.02), V3(0, toe + railB / 2, zf - 0.01), paint, r: 0.002)
        box(V3(inner, railT, 0.02), V3(0, carcassTop - 0.02 - railT / 2, zf - 0.01), paint, r: 0.002)
        var xs: [Float] = []
        for i in 0..<4 {
            let x = -inner / 2 + stile / 2 + Float(i) * (ow + stile)
            box(V3(stile, oh + 0.002, 0.02), V3(x, (y0 + y1) / 2, zf - 0.01), paint, r: 0.002)
            if i < 3 { xs.append(x + stile / 2 + ow / 2) }
        }

        // Drawers: shaker fronts (frame + recessed panel) set 3 mm behind the face, boxes behind, knobs.
        for (i, cx) in xs.enumerated() {
            let fw = ow - 0.005, fh = oh - 0.005, fz = zf - 0.0115
            let ds = rng.fork(i)
            var r = ds
            let dy = r.float(-0.0006...0.0006)
            let fy = (y0 + y1) / 2 + dy
            box(V3(fw, fh, 0.019), V3(cx, fy, fz), paint, r: 0.002)
            // raised field: rail and stile frame, panel recessed 5 mm
            let f: Float = 0.05
            if lod == 0 {
                m.add(Prim.roundedBox(V3(fw - 2 * f, fh - 2 * f, 0.004), radius: 0.001, bevelSegments: 1, material: paintWorn),
                      Xform(translation: V3(cx, fy, zf - 0.0005 + 0.0)))
                for sx: Float in [-1, 1] {
                    m.add(Prim.roundedBox(V3(0.006, fh - 2 * f + 0.008, 0.007), radius: 0.0015, bevelSegments: 1, material: paint),
                          Xform(translation: V3(cx + sx * (fw / 2 - f + 0.003), fy, zf - 0.0045)))
                }
                for sy: Float in [-1, 1] {
                    m.add(Prim.roundedBox(V3(fw - 2 * f + 0.012, 0.006, 0.007), radius: 0.0015, bevelSegments: 1, material: paint),
                          Xform(translation: V3(cx, fy + sy * (fh / 2 - f + 0.003), zf - 0.0045)))
                }
                // Drawer box, partly visible in the gap, and a slide shadow line.
                m.add(cuboid(V3(ow - 0.03, oh - 0.04, 0.25), material: "wood.plywood"), Xform(translation: V3(cx, fy - 0.005, zf - 0.025 - 0.125)))
                // Brass knob on a 4 mm stem.
                let kn = turned([(0, 0), (0.005, 0), (0.0045, 0.004), (0.006, 0.007), (0.014, 0.011), (0.016, 0.017), (0.013, 0.022), (0.006, 0.025), (0, 0.026)],
                                segments: 16, material: knob, seamTile: 0.05)
                m.add(kn, Xform(translation: V3(cx, fy, zf - 0.0025), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
            } else {
                let kn = turned([(0, 0), (0.014, 0.006), (0.014, 0.02), (0, 0.026)], segments: 10, material: knob, seamTile: 0.05)
                m.add(kn, Xform(translation: V3(cx, fy, zf - 0.0025), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
            }
        }

        // Top slab, full width with a rounded nosing.
        box(V3(W, 0.02, D), V3(0, carcassTop - 0.01, 0), paint, r: 0.006)

        // Cushion: soft rounded slab with a gentle crown, plus buttons.
        let cy = carcassTop + cushionThickness / 2
        let cs = Prim.superellipsoid(V3(W - 0.02, cushionThickness, D - 0.03), exponent: 5, subdivisions: lod == 0 ? 12 : 7, material: cushion)
        m.add(cs, Xform(translation: V3(0, cy + 0.0, -0.005)))
        // Welt piping along the top and bottom edges of the cushion (superellipse path, exponent 5).
        if lod == 0 {
            let hx = (W - 0.02) / 2, hz = (D - 0.03) / 2
            for f: Float in [0.78, -0.78] {
                let k = powf(1 - powf(abs(f), 5), 0.2) * 0.985
                var path: [V3] = []
                let n = 36
                for i in 0...n {
                    let t = Float(i) / Float(n) * 2 * .pi
                    let c = cosf(t), sn = sinf(t)
                    let x = (c < 0 ? -1 : 1) * powf(abs(c), 2 / 5), z = (sn < 0 ? -1 : 1) * powf(abs(sn), 2 / 5)
                    path.append(V3(x * hx * k, cy + f * cushionThickness / 2, z * hz * k - 0.005))
                }
                m.add(Prim.tube(path, radii: [Float](repeating: 0.0045, count: path.count), sides: 6, seamTile: 0.04, material: cushion), .identity)
            }
        }
        if lod == 0 {
            for ix in 0..<5 {
                for iz in 0..<2 {
                    let bx = (Float(ix) - 2) * 0.28, bz = (Float(iz) - 0.5) * 0.24 - 0.005
                    m.add(Prim.superellipsoid(V3(0.02, 0.01, 0.02), exponent: 2, subdivisions: 4, material: cushion),
                          Xform(translation: V3(bx, cy + cushionThickness / 2 - 0.006, bz)))
                }
            }
        }
        for i in m.surfaces.indices { m.surfaces[i].positions = m.surfaces[i].positions.map { $0 + V3(0, 0, -0.012) } }
        // Height gradient only: cavity bake bands across the wide toe-kick faces.
        for i in m.surfaces.indices { m.surfaces[i].occlusion = m.surfaces[i].positions.map { 0.6 + 0.4 * smoothstep(0, 0.09, $0.y) } }
        return m
    }

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [model(lod: 0, seed: seed), model(lod: 1, seed: seed)], switchDistances: [5])
    }
}
