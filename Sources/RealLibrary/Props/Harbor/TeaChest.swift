import simd
import Foundation

/// 18th century Chinese export tea chest of the kind thrown overboard in Boston harbor, 0.5 x 0.6 x 0.5 m. Thick cedar
/// plank box with sides tapering 2 cm toward the base, a rebated two-plank lid with nail heads, two rope-lashed lid cleats,
/// iron corner straps, black stencilled export marks and a merchant patch, lead-foil lining showing at a chipped top corner,
/// salt-stained boards and two rope handles. One lid corner is split open and spilling dark tea leaves.
/// Origin at the centre of the base, front +Z.
public struct TeaChest: RealAsset {
    public static let id = "tea-chest"
    public static let summary = "Chinese export tea chest, 0.5 x 0.6 x 0.5 m: tapered cedar plank box, split lid with spilled tea, rope cleats and handles, iron corner straps, stencilled marks, lead lining."
    public static let tags = ["prop", "wood", "container", "harbor", "antique", "handheld"]
    public static let budget = 8_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 20, distance: 0.95, studio: true)

    /// Half width at the top of the walls (m); the base is 2 cm narrower each side.
    public var topHalf: Float = 0.25
    /// Wall plank thickness (m).
    public var wallThickness: Float = 0.02
    /// Height of the box body below the lid (m).
    public var bodyHeight: Float = 0.56
    /// Boards near the waterline, heavily salt stained.
    public var stained: MaterialKey = "wood.waterlogged"
    /// Mid boards.
    public var weathered: MaterialKey = "wood.lumber-cedar"
    /// Upper boards and lid battens.
    public var cedar: MaterialKey = "wood.cedar"
    /// Rope handles and lashing.
    public var rope: MaterialKey = "sack.jute"
    /// Corner straps, nail heads.
    public var iron: MaterialKey = "metal.cast-iron"
    /// Rusted lower straps.
    public var rust: MaterialKey = "metal.rust"
    /// Stencil ink.
    public var ink: MaterialKey = "metal.painted:121212"
    /// Lead foil lining.
    public var lead: MaterialKey = "metal.galvanized-aged"
    /// Dark tea leaves.
    public var tea: MaterialKey = "wood.walnut-oiled"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let H = bodyHeight, t = wallThickness
        let bottomHalf = topHalf - 0.02
        let theta = atan2(topHalf - bottomHalf, H)
        let st = sin(theta)
        func half(_ y: Float) -> Float { bottomHalf + (topHalf - bottomHalf) * y / H }
        func q(_ a: Float, _ axis: V3) -> simd_quatf { simd_quatf(angle: a, axis: axis) }
        let Y = V3(0, 1, 0), X = V3(1, 0, 0), Z = V3(0, 0, 1)
        let yaws: [Float] = [0, .pi, .pi / 2, -.pi / 2]
        /// Frame on a wall: local x along the wall, y up the wall, z outward, `off` meters off the face.
        func wall(_ side: Int, _ u: Float, _ y: Float, _ off: Float = 0) -> Xform {
            let r = half(y)
            let (base, tilt): (V3, simd_quatf) = {
                switch side {
                case 0: return (V3(u, y, r), q(theta, X))
                case 1: return (V3(-u, y, -r), q(-theta, X))
                case 2: return (V3(r, y, -u), q(-theta, Z))
                default: return (V3(-r, y, u), q(theta, Z))
                }
            }()
            let rot = tilt * q(yaws[side], Y)
            return Xform(translation: base + rot.act(Z) * off, rotation: rot)
        }
        func put(_ s: Surface, _ side: Int, _ u: Float, _ y: Float, _ off: Float = 0) { m.add(s, wall(side, u, y, off)) }
        func box(_ w: Float, _ h: Float, _ d: Float, _ bev: Float, _ mat: MaterialKey, seg: Int = 1) -> Surface {
            Prim.roundedBox(V3(w, h, d), radius: bev, bevelSegments: seg, material: mat)
        }

        func slab(_ w: Float, _ h: Float, _ d: Float, _ mat: MaterialKey) -> Surface {
            Prim.extrude(Shape2D.rect(w, h), depth: d, bevel: min(0.0004, d / 3), bevelSegments: 1, material: mat)
        }

        // Dark interior and floor, visible through gaps and breaks.
        m.add(box(2 * bottomHalf - 2 * t - 0.004, H - 0.02, 2 * bottomHalf - 2 * t - 0.004, 0.003, "wood.charred", seg: 1), Xform(translation: V3(0, H / 2 + 0.005, 0)))

        // Wall boards: three per side, grain along the board, tide-line wear from the base up.
        let gap: Float = 0.002
        let bh = (H - 2 * gap) / 3
        let tiers: [MaterialKey] = [stained, weathered, cedar]
        for side in 0..<4 {
            for i in 0..<3 {
                let y = Float(i) * (bh + gap) + bh / 2
                let r = half(y)
                var len = side < 2 ? 2 * r : 2 * r - 2 * t - gap
                var centerU: Float = 0
                // Chipped top corner (+X, -Z): top boards stop short and show the lead lining.
                if i == 2 && side == 1 { len -= 0.075; centerU += 0.0375 }       // wall frame u flips on side 1
                if i == 2 && side == 2 { len -= 0.06; centerU -= 0.03 }
                let mat = rng.chance(0.25) && i > 0 ? tiers[i - 1] : tiers[i]
                put(box(len, bh, t, 0.003, mat), side, centerU, y, -t / 2)
            }
        }
        // Splintered chip edge and a loose sliver at the notch.
        m.add(box(0.03, 0.012, 0.007, 0.0015, weathered, seg: 1),
              Xform(translation: V3(0.168, 0.55, -0.248), rotation: q(0.5, Y) * q(0.35, Z)))
        // Lead foil lining behind the chipped corner, with a curled lip.
        let leadSheetY: Float = 0.382
        m.add(slab(0.062, 0.176, 0.0016, lead), Xform(translation: V3(0.205, leadSheetY + 0.088, -0.2285)))
        m.add(slab(0.04, 0.176, 0.0016, lead), Xform(translation: V3(0.2285, leadSheetY + 0.088, -0.209), rotation: q(.pi / 2, Y)))
        m.add(slab(0.058, 0.014, 0.0016, lead),
              Xform(translation: V3(0.2, 0.564, -0.223), rotation: q(-0.5, X)))

        // Iron corner straps: vertical bands on both faces at every corner, top and bottom, lower ones rusted.
        for (cs, cside) in [(1, 0), (-1, 0), (1, 1), (-1, 1)] {
            _ = cs; _ = cside
        }
        for side in 0..<4 {
            for sgn in [Float(-1), 1] {
                for (yc, hgt, mat) in [(0.095 as Float, 0.15 as Float, rust), (0.475, 0.16, iron)] {
                    // Skip the chipped corner's top strap on the chipped faces.
                    if yc > 0.4 && ((side == 1 && sgn == -1) || (side == 2 && sgn == 1)) { continue }
                    let u = sgn * (half(yc) - 0.021)
                    put(slab(0.026, hgt, 0.0035, mat), side, u, yc, 0.0012)
                    for dy in [Float(0)] {
                        let w = wall(side, u, yc + dy, 0.0028)
                        rivet(&m, at: w.translation, normal: w.rotation.act(Z), radius: 0.0034, segments: 6, material: mat)
                    }
                }
            }
        }
        // Lid: rebated two-plank top, 3 mm inside the walls, front plank broken at the -X corner.
        let lidY = H + 0.011
        let lh = topHalf - 0.003
        let plankD = lh - 0.002
        func lid(_ w: Float, _ d: Float, _ cx: Float, _ cz: Float, _ mat: MaterialKey) {
            m.add(box(w, 0.022, d, 0.0025, mat), Xform(translation: V3(cx, lidY, cz)))
        }
        lid(2 * lh, plankD, 0, -(0.002 + plankD / 2), weathered)           // back plank, whole
        let lx = -lh + 0.087
        lid(lh - (-0.158) + 0.0, plankD, (lh + (-0.158)) / 2, 0.002 + plankD / 2, cedar)                         // front plank, main run
        lid(0.087, 0.168, -lh + 0.0435, 0.002 + 0.084, cedar)              // front plank, behind the break
        _ = lx
        // Broken chunk lifted at its inner edge.
        m.add(box(0.087, 0.022, 0.0755, 0.0025, cedar),
              Xform(translation: V3(-0.2035 + 0.01, lidY + 0.017, 0.2098), rotation: q(0.14, Y) * q(0.30, Z)))
        // Lid cleats, lashed with rope arches.
        for sx in [Float(-1), 1] {
            let cx = sx * 0.2
            m.add(box(0.044, 0.02, 0.34, 0.0035, cedar), Xform(translation: V3(cx, H + 0.022 + 0.01, 0)))
            for z in [Float(-0.1), 0.1] {
                let top = H + 0.022 + 0.02
                let pts = catmull([V3(cx - 0.0275, H + 0.022, z), V3(cx - 0.0285, top - 0.01, z), V3(cx - 0.015, top + 0.004, z),
                                   V3(cx, top + 0.0055, z), V3(cx + 0.015, top + 0.004, z), V3(cx + 0.0285, top - 0.01, z),
                                   V3(cx + 0.0275, H + 0.022, z)], per: 2)
                m.add(Prim.tube(pts, radii: pts.map { _ in 0.0042 }, sides: 12, seamTile: 0.012, material: rope, capEnd: true))
            }
        }

        // Stencilled export marks: raised ink bars on the front and back faces.
        func bar(_ side: Int, _ u: Float, _ y: Float, _ w: Float, _ h: Float, rot: Float = 0) {
            var x = wall(side, u, y, 0.0006)
            x.rotation = x.rotation * q(rot, Z)
            m.add(slab(w, h, 0.0016, ink), x)
        }
        func markPanel(_ side: Int, _ u: Float, _ y: Float, _ w: Float, _ h: Float, _ rr: inout SeededRNG) {
            bar(side, u, y + h / 2, w, 0.004); bar(side, u, y - h / 2, w, 0.004)
            bar(side, u - w / 2, y, 0.004, h); bar(side, u + w / 2, y, 0.004, h)
            for c in 0..<3 {
                let cu = u - w / 2 + w * (Float(c) + 0.5) / 3
                var yy = y + h / 2 - 0.016
                for _ in 0..<3 {
                    let bhh = rr.float(0.014...0.026)
                    bar(side, cu, yy - bhh / 2, rr.float(0.006...0.012), bhh)
                    yy -= bhh + 0.01
                }
            }
        }
        var mr = rng.fork(7)
        markPanel(0, -0.04, 0.34, 0.2, 0.15, &mr)
                // Merchant patch: octagonal ring with an initial cross on the +X face.
        for k in 0..<6 {
            let a = Float(k) / 6 * 2 * .pi + .pi / 6
            bar(2, 0.075 * cos(a), 0.3 + 0.075 * sin(a), 0.08, 0.0045, rot: a + .pi / 2)
        }
        bar(2, 0, 0.3, 0.09, 0.008, rot: .pi / 4); bar(2, 0, 0.3, 0.09, 0.008, rot: -.pi / 4)
        bar(2, 0, 0.3 + 0.05, 0.018, 0.005); bar(2, 0, 0.3 - 0.05, 0.018, 0.005)
        _ = st

        // Rope handles through the end boards.
        for s in [Float(-1), 1] {
            let y0: Float = 0.45
            let r = half(y0)
            let xo = s * r
            func p(_ d: Float, _ dy: Float, _ z: Float) -> V3 { V3(xo + s * d, y0 + dy, z) }
            let loop = catmull([p(-0.004, 0.004, -0.065), p(0.008, 0.012, -0.072), p(0.009, -0.02, -0.07), p(0.01, -0.05, -0.04),
                                p(0.008, -0.07, 0), p(0.01, -0.05, 0.04), p(0.009, -0.02, 0.07), p(0.008, 0.012, 0.072),
                                p(-0.004, 0.004, 0.065)], per: 2)
            m.add(Prim.tube(loop, radii: loop.map { _ in 0.0095 }, sides: 14, seamTile: 0.02, material: rope, capEnd: true))
            for z in [Float(-0.065), 0.065] {
                m.add(Prim.superellipsoid(V3(0.026, 0.026, 0.026), exponent: 2.5, subdivisions: 4, material: rope),
                      Xform(translation: p(0.002, 0.004, z)))
            }
            // Wooden hand cleat plate behind the rope.
            m.add(box(0.006, 0.06, 0.17, 0.003, weathered), Xform(translation: V3(xo + s * 0.001, y0 + 0.0, 0), rotation: q(-s * theta, Z)))
        }

        // Spilled tea: a heap in the split corner and loose leaves on the lid, sill and ground.
        var tr = rng.fork(11)
        func leaf(_ l: Float, _ w: Float) -> Surface {
            Prim.extrude(Shape2D.polygon(sides: 5, radius: 0.5).map { V2($0.x * l, $0.y * w) }, depth: 0.0012, bevel: 0.0003, bevelSegments: 1, material: tea)
        }
        m.add(Prim.superellipsoid(V3(0.075, 0.016, 0.066), exponent: 2.2, subdivisions: 5, material: tea), Xform(translation: V3(-0.205, 0.558, 0.208)))
        for _ in 0..<8 {
            let a = tr.float(0...(2 * .pi)), rd = tr.float(0.004...0.075)
            let px = -0.2 + cos(a) * rd * 1.1, pz = 0.205 + sin(a) * rd
            let inHole = px < -0.158 && pz > 0.17
            let y = (inHole ? 0.567 : H + 0.0232) + (inHole ? tr.float(0...0.004) : 0)
            m.add(leaf(tr.float(0.007...0.012), tr.float(0.003...0.005)),
                  Xform(translation: V3(px, y, pz), rotation: q(tr.float(0...6.28), Y) * q(-.pi / 2, X)))
        }
        for _ in 0..<4 {
            let a = tr.float(0...(2 * .pi)), rd = tr.float(0.02...0.09)
            m.add(leaf(tr.float(0.007...0.012), tr.float(0.003...0.005)),
                  Xform(translation: V3(-0.2 + cos(a) * rd * 0.5, 0.0008, 0.245), rotation: q(tr.float(0...6.28), Y) * q(-.pi / 2, X)))
        }

        groundAO(&m)
        return LODModel(m)
    }
}
