import simd
import Foundation

/// Walk-in closet organizer, 180 x 200 x 60 cm, white melamine against a wall: two outer panels and two dividers drilled
/// with shelf-pin rows, a left section with double-hang chrome rods, a center tower of three drawers under shelves
/// holding folded stacks and canvas bins, and a right section with a long-hang rod over two shoe shelves. Filled with
/// garments on hangers, folded knits and shoes.
public struct ClosetOrganizer: RealAsset {
    public static let id = "closet-organizer"
    public static let summary = "Closet organizer, 1.8 x 2.0 x 0.6 m: white panels, chrome hanging rods, shelves, three drawers, hangers and folded clothes."
    public static let tags = ["prop", "floorplan", "bedroom", "furniture", "wood", "metal", "wall", "interior"]
    public static let budget = 14500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 18, elevation: 8, distance: 0.95, studio: true)

    /// Overall size in meters (x width, y height, z depth); the open side faces +Z and the back goes to the wall at -Z.
    public var size = V3(1.8, 2.0, 0.6)
    /// Melamine panels.
    public var panel: MaterialKey = "wood.painted-shaker:F3F0E8"
    /// Rods and brackets.
    public var rodMetal: MaterialKey = "metal.chrome"
    /// Garments on the rods (0 = empty).
    public var garmentDensity: Float = 1
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [model(seed: seed, detail: true), model(seed: seed, detail: false)], switchDistances: [5])
    }

    func model(seed: UInt64, detail: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = size.x, H = size.y, D = size.z
        let z0 = -D / 2
        let t: Float = 0.019
        let toe: Float = 0.08
        let pD = D - 0.035 - 0.008              // panel depth: front stepped back 2 cm, rear 8 mm off the wall for the back panel
        let pc = z0 + 0.008 + pD / 2            // panel center z
        let zF = pc + pD / 2                    // front plane of the uprights
        let paintWorn: MaterialKey = "wood.painted-shaker-worn:F3F0E8"
        let xs: [Float] = [-W / 2 + t / 2, -0.3, 0.3, W / 2 - t / 2]       // outer, divider, divider, outer

        func box(_ s: V3, _ p: V3, _ mat: MaterialKey? = nil, r: Float = 0.002) {
            m.add(Prim.roundedBox(s, radius: min(r, s.x / 2.2, s.y / 2.2, s.z / 2.2), bevelSegments: 1, material: mat ?? panel), Xform(translation: p))
        }
        func flat(_ s: V3, _ p: V3, _ mat: MaterialKey? = nil, rot: simd_quatf = .identity) { m.add(cuboid(s, material: mat ?? panel), Xform(translation: p, rotation: rot)) }

        // Uprights: outer panels, dividers (the tall center tower stops at the top shelf), back panel, toe kick, top.
        for (i, x) in xs.enumerated() {
            let top: Float = i == 1 || i == 2 ? H - 0.1 : H
            box(V3(t, top - toe, pD), V3(x, toe + (top - toe) / 2, pc), r: 0.002)
        }
        flat(V3(W - 2 * t, H - toe, 0.008), V3(0, toe + (H - toe) / 2, z0 + 0.004), paintWorn)
        flat(V3(W - 2 * t, toe, pD - 0.05), V3(0, toe / 2, pc - 0.0), "plastic.matte:D6D2C6")
        box(V3(W, t, pD), V3(0, H - t / 2, pc), r: 0.002)
        box(V3(W - 2 * t, t, pD - 0.01), V3(0, toe + t / 2, pc - 0.005), r: 0.002)

        // Shelf-pin holes: small dark squares in two columns on every inner upright face.
        func holes(x: Float, normal: Float, y0: Float, y1: Float) {
            var s = Surface(material: "plastic.black:1A1A1A")
            let n = V3(normal, 0, 0), u = V3(0, 0, -normal), v = V3(0, 1, 0)   // u x v = n
            let hs: Float = 0.0035
            for zc in [Float(-0.2), 0.2] {
                var y = y0
                while y <= y1 {
                    let c = V3(x + normal * 0.0003, y, zc)
                    let base = UInt32(s.positions.count)
                    for (a, b) in [(-1, -1), (1, -1), (1, 1), (-1, 1)] as [(Float, Float)] { let pt = c + u * (hs * a) + v * (hs * b); s.add(pt, n, V2(pt.z, pt.y)) }
                    s.quad(base, base + 1, base + 2, base + 3)
                    y += 0.032
                }
            }
            s.computeTangents()
            m.add(s)
        }
        if detail {
            holes(x: xs[0] + t / 2, normal: 1, y0: 0.2, y1: H - 0.25)
            holes(x: xs[3] - t / 2, normal: -1, y0: 0.2, y1: H - 0.25)
            holes(x: -0.3 - t / 2, normal: -1, y0: 0.2, y1: H - 0.25)
            holes(x: -0.3 + t / 2, normal: 1, y0: 0.2, y1: H - 0.25)
            holes(x: 0.3 - t / 2, normal: -1, y0: 0.2, y1: H - 0.25)
            holes(x: 0.3 + t / 2, normal: 1, y0: 0.2, y1: H - 0.25)
        }

        // Shelves: (x0, x1, y).
        func shelf(_ x0: Float, _ x1: Float, _ y: Float) {
            box(V3(x1 - x0, t, pD - 0.01), V3((x0 + x1) / 2, y - t / 2, pc - 0.005), r: 0.002)
            flat(V3(x1 - x0, 0.01, 0.008), V3((x0 + x1) / 2, y - t / 2, pc + (pD - 0.01) / 2), "plastic.matte:E9E6DB")
        }
        let L0 = xs[0] + t / 2, L1 = -0.3 - t / 2, C0 = -0.3 + t / 2, C1 = 0.3 - t / 2, R0 = 0.3 + t / 2, R1 = xs[3] - t / 2
        shelf(L0, L1, 1.88); shelf(L0, L1, 1.04)                           // left: rod shelves
        shelf(R0, R1, 1.88); shelf(R0, R1, 0.55); shelf(R0, R1, 0.3)       // right: long-hang shelf and two shoe shelves
        let cs: [Float] = [0.82, 1.12, 1.42, 1.72, 1.9 - 0.0]
        for y in cs { shelf(C0, C1, y) }

        // Rods with end sockets and a center clip.
        func rod(_ x0: Float, _ x1: Float, _ y: Float) {
            m.add(Prim.cylinder(radius: 0.0125, height: x1 - x0, bevel: 0.002, segments: detail ? 14 : 8, bevelSegments: 1, seamTile: 0.1, material: rodMetal),
                  Xform(translation: V3(x0, y, pc - 0.03), rotation: simd_quatf(degrees: -90, axis: V3(0, 0, 1))))
            for x in [x0, x1] { box(V3(0.012, 0.045, 0.06), V3(x + (x == x0 ? 0.006 : -0.006), y + 0.012, pc - 0.03), rodMetal, r: 0.003) }
            box(V3(0.03, 0.02, 0.05), V3((x0 + x1) / 2, y + 0.022, pc - 0.03), rodMetal, r: 0.004)
        }
        rod(L0, L1, 1.79); rod(L0, L1, 0.97)
        rod(R0, R1, 1.79)

        // Garments: lofted soft bodies hanging with the broad face toward +Z, hanger and hook on the rod.
        let cols: [MaterialKey] = ["fabric.linen:E9E4D8", "fabric.linen:6B7F95", "fabric.wool:3C4350", "fabric.linen:B9A68A", "fabric.canvas:7A8268", "fabric.linen:C9D3DA",
                                   "fabric.wool:8A4B45", "fabric.linen:F1EEE6", "fabric.wool:2E3B4E", "fabric.canvas:A38E6E", "fabric.linen:7E5F4E", "fabric.wool:55606A"]
        func hung(x0: Float, x1: Float, rodY: Float, lenRange: ClosedRange<Float>, widthRange: ClosedRange<Float>, gi0: Int) {
            var x = x0 + 0.035
            var gi = gi0
            while x < x1 - 0.045 {
                let len = rng.float(lenRange), gw = rng.float(widthRange), gt = rng.float(0.035...0.06)
                if rng.chance(0.07) { x += rng.float(0.03...0.06); continue }
                let top = rodY - 0.045
                let mat = cols[gi % cols.count]
                let lean = rng.float(-3...3)
                let q = simd_quatf(degrees: lean, axis: V3(0, 0, 1))
                // Body: narrow shoulders flaring to the hem, slight belly.
                var rings: [(Float, Float, Float)] = [(0, gw * 0.7, gt * 0.7), (1, gw * 1.04, gt)]
                if detail { rings = [(0, gw * 0.62, gt * 0.55), (0.12, gw * 0.86, gt * 0.9), (0.55, gw, gt), (1, gw * 1.06, gt * 0.9)] }
                let rr = rings.map { r -> [V3] in Prim.ring(Shape2D.roundedRect(r.2, r.1, radius: min(r.2, r.1) * 0.35, segments: 1), y: -r.0 * len) }
                let body = Prim.loft(rr.reversed(), capStart: true, capEnd: true, material: mat)
                m.add(body, Xform(translation: V3(x, top, pc - 0.03), rotation: q))
                // Hanger: shoulders tube in the YZ plane and a hook over the rod.
                let hz = pc - 0.03
                let hp: [V3] = [V3(x, top - 0.062, hz - gw * 0.5), V3(x, top - 0.014, hz - gw * 0.12), V3(x, top, hz), V3(x, top - 0.014, hz + gw * 0.12), V3(x, top - 0.062, hz + gw * 0.5)]
                if detail {
                    m.add(Prim.tube(hp, radii: hp.map { _ in 0.0016 }, sides: 3, seamTile: 0.02, material: rodMetal))
                    m.add(Prim.tube([V3(x, top, hz), V3(x, top + 0.03, hz), V3(x, top + 0.05, hz - 0.016), V3(x, top + 0.028, hz - 0.03)], radii: [0.0016, 0.0016, 0.0016, 0.0016], sides: 3, seamTile: 0.02, material: rodMetal))
                }
                x += gt + rng.float(0.012...0.045); gi += 1
            }
        }
        if garmentDensity > 0 {
            hung(x0: L0, x1: L1, rodY: 1.79, lenRange: 0.62...0.78, widthRange: 0.34...0.42, gi0: 0)
            hung(x0: L0, x1: L1, rodY: 0.97, lenRange: 0.42...0.58, widthRange: 0.26...0.34, gi0: 5)
            hung(x0: R0, x1: R1, rodY: 1.79, lenRange: 0.98...1.08, widthRange: 0.34...0.42, gi0: 2)
        }

        // Drawers in the center tower: three fronts with bar pulls over a shadowed carcass.
        let dBot = toe + t + 0.004, dTop = cs[0] - t - 0.004
        let dh = (dTop - dBot - 0.012) / 3
        flat(V3(C1 - C0, dTop - dBot, pD - 0.04), V3(0, (dTop + dBot) / 2, pc - 0.02), "plastic.matte:2A2926")
        for i in 0..<3 {
            let y = dBot + 0.003 + dh / 2 + Float(i) * (dh + 0.003)
            box(V3(C1 - C0 - 0.006, dh, 0.019), V3(0, y, zF - 0.0095 + 0.01), i == 0 ? paintWorn : panel, r: 0.003)
            m.add(barHandle(length: 0.16, standoff: 0.03, radius: 0.0055, overhang: 0.012, material: "metal.brushed-nickel"),
                  Xform(translation: V3(0, y + dh / 2 - 0.045, zF + 0.0085)))
        }

        // Folded knits, bins and shoe boxes on the center shelves.
        let fold: [MaterialKey] = ["fabric.wool:55606A", "fabric.wool:A8453D", "fabric.wool:E3DCCB", "fabric.wool:2F4A63", "fabric.linen:CFC8B6", "fabric.wool:6E7F5F"]
        func stack(x: Float, y: Float, n: Int, w: Float, d: Float) {
            var yy = y
            for k in 0..<n {
                let h = rng.float(0.038...0.06)
                m.add(Prim.superellipsoid(V3(w - rng.float(0...0.03), h * 1.1, d), exponent: 4, subdivisions: detail ? 2 : 1, material: fold[(k + Int(rng.int(0...5))) % fold.count]),
                      Xform(translation: V3(x + rng.float(-0.006...0.006), yy + h / 2, pc + 0.04 + rng.float(-0.008...0.008)), rotation: simd_quatf(degrees: rng.float(-2.5...2.5), axis: .up)))
                yy += h
            }
        }
        func bin(x: Float, y: Float, w: Float, d: Float, h: Float, mat: MaterialKey) {
            let outer = Prim.loft([Prim.ring(Shape2D.roundedRect(w * 0.9, d * 0.9, radius: 0.02, segments: 2), y: 0), Prim.ring(Shape2D.roundedRect(w, d, radius: 0.025, segments: 2), y: h)], capStart: true, capEnd: false, material: mat)
            let inner = Prim.loft([Prim.ring(Shape2D.roundedRect(w * 0.9 - 0.02, d * 0.9 - 0.02, radius: 0.012, segments: 2), y: 0.006), Prim.ring(Shape2D.roundedRect(w - 0.02, d - 0.02, radius: 0.018, segments: 2), y: h)], capStart: false, capEnd: false, material: mat).flipped()
            m.add(outer, Xform(translation: V3(x, y, pc + 0.03)))
            m.add(inner, Xform(translation: V3(x, y, pc + 0.03)))
            let rim = Shape2D.roundedRect(w - 0.004, d - 0.004, radius: 0.024, segments: 3).map { V3($0.x, h, $0.y) + V3(x, y, pc + 0.03) }
            m.add(Prim.sweep(Shape2D.circle(0.005, segments: 5), along: rim, closedPath: true, caps: false, material: mat))
        }
        stack(x: -0.15, y: cs[0], n: 4, w: 0.26, d: 0.32)
        stack(x: 0.15, y: cs[0], n: 3, w: 0.26, d: 0.32)
        bin(x: -0.15, y: cs[1], w: 0.26, d: 0.36, h: 0.22, mat: "fabric.canvas:B7A98A")
        stack(x: 0.15, y: cs[1], n: 5, w: 0.26, d: 0.32)
        stack(x: -0.15, y: cs[2], n: 5, w: 0.26, d: 0.32)
        bin(x: 0.15, y: cs[2], w: 0.26, d: 0.36, h: 0.22, mat: "fabric.canvas:6E7F8C")
        bin(x: -0.15, y: cs[3], w: 0.26, d: 0.36, h: 0.14, mat: "fabric.canvas:B7A98A")
        stack(x: 0.15, y: cs[3], n: 2, w: 0.26, d: 0.32)
        flat(V3(0.24, 0.1, 0.34), V3(0.0 - 0.0, cs[4] + 0.05 - 0.0 + 0.0, pc + 0.02), "paper.sheet:B8946A")     // hat box on the top shelf

        // Shoes on the two right shoe shelves: pairs of soft uppers on dark soles.
        func shoe(_ p: V3, yaw: Float, mat: MaterialKey) {
            // Upper lofted toe to heel (loft Y becomes -Z), then a rubber sole slab.
            let L: Float = 0.27
            let prof: [(Float, Float, Float)] = [(0, 0.05, 0.022), (0.08, 0.082, 0.04), (0.3, 0.092, 0.052), (0.55, 0.078, 0.074), (0.82, 0.07, 0.084), (1, 0.066, 0.07)]
            let rr = prof.map { Prim.ring(Shape2D.roundedRect($0.1, $0.2, radius: 0.016, segments: 1), y: $0.0 * L, offset: V3(0, 0, $0.2 / 2 + 0.014)) }
            let up = Prim.loft(rr, capStart: true, capEnd: true, material: mat)
            let q = simd_quatf(degrees: yaw, axis: .up)
            let toFront = simd_quatf(degrees: -90, axis: V3(1, 0, 0))
            m.add(up, Xform(translation: p + q.act(V3(0, 0, L / 2)), rotation: q * toFront))
            m.add(Prim.roundedBox(V3(0.09, 0.016, L + 0.008), radius: 0.007, bevelSegments: 1, material: "rubber"), Xform(translation: p + V3(0, 0.008, 0) + q.act(V3(0, 0, 0.0)), rotation: q))
        }
        let shoeMats: [MaterialKey] = ["leather.black", "leather.tan", "leather.oxblood-worn", "fabric.canvas:D8D2C2", "leather.black", "leather.tan"]
        for (row, y) in [Float(0.55), 0.3].enumerated() {
            for k in 0..<3 {
                let x = R0 + 0.1 + Float(k) * 0.17 + rng.float(-0.01...0.01)
                let mat = shoeMats[(row * 3 + k) % shoeMats.count]
                shoe(V3(x - 0.05, y, pc + 0.05), yaw: rng.float(-6...6), mat: mat)
                shoe(V3(x + 0.05, y, pc + 0.05), yaw: rng.float(-6...6), mat: mat)
            }
        }
        // Floor-level shoe boxes on the left bottom.
        for (i, c) in ["paper.sheet:C8B79A", "paper.sheet:3E3A36", "paper.sheet:B7573F"].enumerated() {
            flat(V3(0.3, 0.11, 0.2), V3(L0 + 0.2 + rng.float(-0.01...0.01), toe + t + 0.055 + Float(i) * 0.112, pc + 0.04), c, rot: simd_quatf(degrees: rng.float(-3...3), axis: .up))
        }

        // Authoring frame: centered on X/Z, base at y = 0.
        let bb = m.bounds
        m = m.transformed(Xform(translation: V3(-(bb.min.x + bb.max.x) / 2, -bb.min.y, -(bb.min.z + bb.max.z) / 2)))
        groundAO(&m, height: 0.25, floor: 0.5)
        return m
    }
}
