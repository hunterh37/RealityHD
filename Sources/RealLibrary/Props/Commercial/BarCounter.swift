import simd
import Foundation

/// Hospitality bar counter, 240 x 110 x 60 cm: fluted walnut front between pilasters, dark marble top with a rounded
/// overhang, brass foot rail on brackets, deep-green plinth. The service side (-Z, wall side) has three stainless
/// drawers, a bottle shelf with a brass bottle rail and a stainless drip rail along the back of the top.
public struct BarCounter: RealAsset {
    public static let id = "bar-counter"
    public static let summary = "Bar counter, 2.4 x 1.1 x 0.6 m: fluted walnut front, dark marble top, brass foot rail, stainless service rail."
    public static let tags = ["prop", "floorplan", "commercial", "furniture", "wood", "wall", "interior"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 16, distance: 0.85, studio: true)

    /// Overall size in meters (x width, y height, z depth); the customer side faces +Z, the service side the wall.
    public var size = V3(2.4, 1.1, 0.6)
    /// Fluted front and carcass wood.
    public var wood: MaterialKey = "wood.walnut"
    /// Counter top stone.
    public var topStone: MaterialKey = "stone.marble-dark"
    /// Plinth and drawer carcass paint.
    public var paint: MaterialKey = "wood.painted-shaker-worn:2B3A36"
    /// Foot rail and bar hardware metal.
    public var brass: MaterialKey = "metal.brass-aged"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [model(seed: seed, detail: true), model(seed: seed, detail: false)], switchDistances: [6])
    }

    func model(seed: UInt64, detail: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = size.x, D = size.z
        let topT: Float = 0.04
        let topY: Float = size.y - 0.09              // top surface; leaves room for glassware inside the size envelope
        let zFront = D / 2, zBack = -D / 2
        let bodyFront = zFront - 0.06                // carcass front plane under the overhang
        let bodyBack = zBack + 0.12                  // service side is recessed under the overhang
        let plinthH: Float = 0.09
        let endT: Float = 0.028
        let sides = detail ? 14 : 8

        func box(_ s: V3, _ p: V3, _ mat: MaterialKey, r: Float = 0.002, seg: Int = 1) {
            m.add(Prim.roundedBox(s, radius: min(r, s.x / 2.2, s.y / 2.2, s.z / 2.2), bevelSegments: detail ? seg : 1, material: mat),
                  Xform(translation: p).jittered(&rng, deg: 0.03, offset: 0.0002))
        }
        func flat(_ s: V3, _ p: V3, _ mat: MaterialKey) {
            m.add(cuboid(s, material: mat), Xform(translation: p))
        }
        func rodX(_ y: Float, _ z: Float, _ x0: Float, _ x1: Float, r: Float, mat: MaterialKey) {
            m.add(Prim.cylinder(radius: r, height: x1 - x0, bevel: r * 0.4, segments: sides, bevelSegments: 1, seamTile: 0.1, material: mat),
                  Xform(translation: V3(x0, y, z), rotation: simd_quatf(degrees: -90, axis: V3(0, 0, 1))))
        }

        // Marble slab with a rounded top edge, slightly dished at the corners by the bevel, plus a thin apron under it.
        box(V3(W, topT, D), V3(0, topY - topT / 2, 0), topStone, r: 0.014, seg: 4)
        flat(V3(W - 0.05, 0.03, D - 0.1), V3(0, topY - topT - 0.015 + 0.002, 0.0), wood)

        // Plinth and carcass. Ends are solid walnut panels; the fluted front hangs on a plywood backing.
        let carcassH = topY - topT - plinthH
        flat(V3(W - 0.08, plinthH, bodyFront - bodyBack - 0.02), V3(0, plinthH / 2, (bodyFront + bodyBack) / 2 - 0.01), paint)
        for s: Float in [-1, 1] {
            box(V3(endT, carcassH, bodyFront - bodyBack), V3(s * (W / 2 - 0.04 - endT / 2), plinthH + carcassH / 2, (bodyFront + bodyBack) / 2), "wood.walnut-oiled", r: 0.003, seg: 1)
        }
        let backingT: Float = 0.018
        flat(V3(W - 0.08 - 2 * endT + 0.004, carcassH, backingT), V3(0, plinthH + carcassH / 2, bodyFront - backingT / 2), "wood.plywood")

        // Fluted front: three bays between pilasters, vertical half-round flutes on a 30 mm pitch.
        let panelTop = topY - topT - 0.012
        let panelBot = plinthH + 0.01
        let panelH = panelTop - panelBot
        let pil: Float = 0.075
        let xs: [Float] = [-W / 2 + 0.04 + pil / 2 + 0.0, -(W / 2 - 0.04 - pil / 2) / 3, (W / 2 - 0.04 - pil / 2) / 3, W / 2 - 0.04 - pil / 2]
        for x in xs {
            box(V3(pil, panelH + 0.01, 0.034), V3(x, (panelTop + panelBot) / 2, bodyFront + 0.003), wood, r: 0.006, seg: 1)
        }
        for b in 0..<3 {
            let x0 = xs[b] + pil / 2, x1 = xs[b + 1] - pil / 2
            let n = Int(((x1 - x0) / 0.034).rounded(.down))
            let pitch = (x1 - x0) / Float(n)
            // Rail caps top and bottom of each bay.
            box(V3(x1 - x0 + 0.002, 0.02, 0.016), V3((x0 + x1) / 2, panelTop - 0.01, bodyFront + 0.008), wood, r: 0.002)
            flat(V3(x1 - x0 + 0.002, 0.02, 0.016), V3((x0 + x1) / 2, panelBot + 0.01, bodyFront + 0.008), wood)
            for i in 0..<n {
                let x = x0 + pitch * (Float(i) + 0.5)
                m.add(Prim.cylinder(radius: 0.0125, height: panelH - 0.04, bevel: 0.0005, segments: detail ? 6 : 4, bevelSegments: 1, seamTile: 0.08, material: wood),
                      Xform(translation: V3(x + rng.float(-0.0003...0.0003), panelBot + 0.02, bodyFront + 0.003)))
            }
        }

        // Brass foot rail on three brackets, inside the top overhang.
        let railY: Float = 0.19, railZ = zFront - 0.022
        // Foot rail: polished bright where boots rub, aged toward the ends.
        rodX(railY, railZ, -W / 2 + 0.1, -0.7, r: 0.0235, mat: brass)
        rodX(railY, railZ, 0.7, W / 2 - 0.1, r: 0.0235, mat: brass)
        rodX(railY, railZ, -0.7, 0.7, r: 0.0235, mat: "metal.brass")
        for s: Float in [-1, 0, 1] {
            let x = s * (W / 2 - 0.16)
            m.add(Prim.tube([V3(x, railY - 0.01, bodyFront + 0.012), V3(x, railY - 0.01, railZ - 0.012), V3(x, railY - 0.0, railZ - 0.022)],
                            radii: [0.008, 0.008, 0.008], sides: detail ? 8 : 5, seamTile: 0.05, material: brass))
            m.add(Prim.cylinder(radius: 0.022, height: 0.006, bevel: 0.002, segments: sides, bevelSegments: 1, material: brass),
                  Xform(translation: V3(x, railY - 0.01, bodyFront + 0.0), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        }
        for s: Float in [-1, 1] {
            m.add(Prim.cylinder(radius: 0.0265, height: 0.012, bevel: 0.004, segments: sides, bevelSegments: 1, material: brass),
                  Xform(translation: V3(s * (W / 2 - 0.1) + (s > 0 ? 0 : -0.012), railY, railZ), rotation: simd_quatf(degrees: -90, axis: V3(0, 0, 1))))
        }

        // Service side: drawer block under the top, shelf with bottle rail below it.
        let drawTop = topY - topT - 0.006, drawH: Float = 0.27
        let drawBot = drawTop - drawH
        let blockD = bodyFront - bodyBack - 0.02
        flat(V3(W - 0.08 - 2 * endT, drawH, blockD), V3(0, drawBot + drawH / 2, bodyBack + blockD / 2), paint)
        let dw = (W - 0.08 - 2 * endT - 0.032) / 3
        for i in 0..<3 {
            let x = -(W - 0.08 - 2 * endT) / 2 + 0.008 + dw / 2 + Float(i) * (dw + 0.008) + 0.004
            box(V3(dw, drawH - 0.016, 0.022), V3(x, drawBot + drawH / 2, bodyBack - 0.011), "metal.stainless-smudged", r: 0.003, seg: 1)
            let py = drawBot + drawH / 2 + 0.01, pz = bodyBack - 0.022
            rodX(py, pz - 0.03, x - 0.12, x + 0.12, r: 0.0055, mat: brass)
            for k: Float in [-1, 1] { flat(V3(0.01, 0.01, 0.03), V3(x + k * 0.1, py, pz - 0.015), brass) }
        }
        // Shelf stub (leather-topped bar mat feel via stainless lip) and bottle rail.
        let shelfY: Float = 0.43, shelfD: Float = 0.2
        box(V3(W - 0.08 - 2 * endT, 0.032, shelfD), V3(0, shelfY, bodyBack + shelfD / 2), wood, r: 0.004, seg: 2)
        flat(V3(W - 0.08 - 2 * endT, 0.07, 0.012), V3(0, shelfY - 0.05, bodyBack + 0.006), wood)
        let rail0 = -(W - 0.08 - 2 * endT) / 2 + 0.06, rail1 = (W - 0.08 - 2 * endT) / 2 - 0.06
        let railH: Float = 0.085
        rodX(shelfY + railH, bodyBack + 0.032, rail0, rail1, r: 0.007, mat: brass)
        for x in stride(from: rail0 + 0.02, through: rail1 - 0.02, by: (rail1 - rail0 - 0.04) / 4) {
            m.add(Prim.cylinder(radius: 0.0045, height: railH, bevel: 0.0015, segments: 6, bevelSegments: 1, material: brass),
                  Xform(translation: V3(x, shelfY + 0.016, bodyBack + 0.032)))
        }

        // Bottles on the shelf, behind the rail.
        func lathe(_ prof: [V2], _ mat: MaterialKey, at p: V3, seg: Int? = nil) {
            m.add(Prim.lathe(prof, segments: seg ?? (detail ? 10 : 6), seamTile: 0.1, material: mat), Xform(translation: p))
        }
        func bottle(_ p: V3, h: Float, r: Float, glass: MaterialKey, label: MaterialKey, cap: MaterialKey? = nil) {
            let neckR = r * 0.3, shoulder = h * 0.58
            lathe([V2(0.0001, 0), V2(r * 0.92, 0), V2(r, 0.004), V2(r, shoulder), V2(neckR * 1.4, shoulder + 0.05), V2(neckR, shoulder + 0.085),
                   V2(neckR, h - 0.012), V2(neckR * 1.12, h), V2(0.0001, h)], glass, at: p)
            lathe([V2(r + 0.0006, h * 0.16), V2(r + 0.0006, h * 0.5), V2(r - 0.001, h * 0.5), V2(r - 0.001, h * 0.16)], label, at: p)
            if let c = cap {
                lathe([V2(neckR * 1.14, h - 0.03), V2(neckR * 1.14, h + 0.004), V2(0.0001, h + 0.004)], c, at: p, seg: 8)
            }
        }
        let glasses: [MaterialKey] = ["glass.emerald", "glass.tinted", "glass.clear", "glass.emerald", "glass.tinted", "glass.clear", "glass.tinted", "glass.emerald"]
        let labels: [MaterialKey] = ["paper.sheet", "paper.sheet:D9C79C", "paper.sheet", "paper.sheet:B9473B", "paper.sheet", "paper.sheet:D9C79C", "paper.sheet", "paper.sheet:2F4A63"]
        var bx = rail0 + 0.06
        var bi = 0
        while bx < rail1 - 0.05 {
            let h = rng.float(0.25...0.3), r = rng.float(0.03...0.036)
            // Rail sits at the front; bottles are set 6 cm behind its plane toward the carcass.
            bottle(V3(bx, shelfY + 0.016, bodyBack + 0.1), h: h, r: r, glass: glasses[bi % glasses.count], label: labels[bi % labels.count], cap: bi % 3 == 0 ? "metal.brass-aged" : nil)
            bx += r * 2 + rng.float(0.06...0.1); bi += 1
        }

        // Lower service niche: two wooden crates of stock and a tied linen sack on the plinth floor.
        for (i, x) in [Float(-0.62), 0.05].enumerated() {
            let cz = bodyBack + 0.16, cw: Float = 0.5, cd: Float = 0.3, ch: Float = 0.26
            let yb = plinthH + 0.002
            for sy: Float in [0.06, 0.2] {
                flat(V3(cw, 0.05, cd), V3(x, yb + sy, cz), "wood.pine-aged")
            }
            for sx: Float in [-1, 1] { for sz: Float in [-1, 1] { flat(V3(0.03, ch, 0.03), V3(x + sx * (cw / 2 - 0.015), yb + ch / 2, cz + sz * (cd / 2 - 0.015)), "wood.pine-aged") } }
            for k in 0..<3 {
                bottle(V3(x - 0.14 + Float(k) * 0.14, yb + 0.07, cz - 0.02 + (k % 2 == 0 ? 0 : 0.05)), h: 0.17 + 0.01 * Float(i), r: 0.032, glass: k % 2 == 0 ? "glass.emerald" : "glass.tinted", label: "paper.sheet", cap: nil)
            }
        }
        // Top: stainless drip rail with slots along the back edge, a bar mat, inverted tumblers, coasters, one cocktail glass.
        let railTopZ = zBack + 0.065
        box(V3(1.1, 0.012, 0.11), V3(-0.5, topY + 0.004, railTopZ), "metal.stainless-smudged", r: 0.003, seg: 1)
        for i in 0..<18 {
            flat(V3(0.045, 0.002, 0.012), V3(-1.0 + 0.03 + Float(i) * 0.057, topY + 0.0105, railTopZ), "plastic.black:1A1A1A")
        }
        box(V3(0.46, 0.012, 0.22), V3(0.35, topY + 0.006, -0.04), "plastic.black:1C1C1E", r: 0.004)
        for (i, x) in [Float(0.22), 0.33, 0.44].enumerated() {
            lathe([V2(0.0001, 0.08), V2(0.033, 0.08), V2(0.036, 0.0), V2(0.0001, 0.0)], "glass.clear", at: V3(x, topY + 0.012, -0.0 - 0.06 + Float(i % 2) * 0.01))
        }
        for x: Float in [-0.45, -0.05] {
            m.add(Prim.cylinder(radius: 0.05, height: 0.005, bevel: 0.0015, segments: detail ? 20 : 10, bevelSegments: 1, material: "leather.black"),
                  Xform(translation: V3(x, topY, 0.14)))
        }
        lathe([V2(0.0001, 0), V2(0.03, 0), V2(0.03, 0.003), V2(0.004, 0.008), V2(0.003, 0.07), V2(0.02, 0.078), V2(0.05, 0.1), V2(0.05, 0.103), V2(0.0001, 0.103)], "glass.clear", at: V3(-0.45, topY + 0.005, 0.14), seg: detail ? 16 : 8)
        // Bar towel hung over the front edge of the top.
        m.add(Prim.superellipsoid(V3(0.28, 0.014, 0.18), exponent: 3, subdivisions: 2, material: "fabric.linen:E8E4D8"),
              Xform(translation: V3(-0.85, topY + 0.007, 0.08), rotation: simd_quatf(degrees: 8, axis: .up)))
        m.add(Prim.superellipsoid(V3(0.28, 0.01, 0.09), exponent: 3, subdivisions: 2, material: "fabric.linen:CFCABD"),
              Xform(translation: V3(-0.85, topY + 0.017, 0.12), rotation: simd_quatf(degrees: 8, axis: .up)))

        // Authoring frame: centered on X and Z, base at y = 0.
        let bb = m.bounds
        m = m.transformed(Xform(translation: V3(-(bb.min.x + bb.max.x) / 2, -bb.min.y, -(bb.min.z + bb.max.z) / 2)))
        groundAO(&m, height: 0.12, floor: 0.55)
        return m
    }
}
