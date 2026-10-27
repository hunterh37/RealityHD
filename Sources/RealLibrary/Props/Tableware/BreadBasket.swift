import simd
import Foundation

/// Bread basket: everyday tableware, woven wicker. Oval willow basket, 28 x 20 cm and 8 cm tall: flat woven
/// base, upright rattan stakes, 13 over-under weaver courses (some darker from use), a bound rim of two
/// canes, one loose weaver end poking out, and a linen liner with a folded edge hanging over the front rim.
public struct BreadBasket: RealAsset {
    public static let id = "bread-basket"
    public static let summary = "Oval willow bread basket with woven courses, bound rim and a folded linen liner."
    public static let tags = ["prop", "interior", "tableware", "fabric"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 32, distance: 0.62, studio: true)

    /// Rim half-extents (x, z) at the top (m).
    public var rim = V2(0.136, 0.092)
    /// Wall height (m).
    public var height: Float = 0.088
    /// Weaver courses.
    public var courses = 12
    /// Stake count.
    public var stakes = 28
    /// Weaver material.
    public var weaver: MaterialKey = "wicker.willow"
    /// Darker worn weaver.
    public var weaverWorn: MaterialKey = "wicker.willow:8A6A40"
    /// Stake and rim cane.
    public var cane: MaterialKey = "wood.rattan"
    /// Liner.
    public var liner: MaterialKey = "fabric.linen:E6DCC4"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let n = 44
        let base = V2(rim.x - 0.022, rim.y - 0.022)
        func half(_ t: Float) -> V2 { base + (rim - base) * t }   // t 0 base ... 1 rim
        let y0: Float = 0.006
        // Base: woven oval disc, two crossing layers of flat slats.
        var disc = Prim.extrude(Shape2D.circle(base.x, ry: base.y, segments: 48), depth: 0.008, bevel: 0.0022, material: weaver)
        disc.recomputeNormals()
        m.add(disc, Xform(translation: V3(0, 0.004, 0), rotation: DD1ITableware.lay))
        for k in 0..<14 {
            let z = (Float(k) - 6.5) * (base.y * 2 / 14)
            let hl = base.x * sqrt(max(0.05, 1 - pow(z / base.y, 2))) - 0.004
            m.add(Prim.roundedBox(V3(hl * 2, 0.0022, 0.0105), radius: 0.0008, bevelSegments: 1, material: k % 3 == 0 ? weaverWorn : weaver),
                  Xform(translation: V3(0, 0.0087 + (k % 2 == 0 ? 0.0006 : 0), z)).jittered(&rng, deg: 0.4, offset: 0.0003))
        }
        // Stakes: rattan cores climbing the flared wall.
        for s in 0..<stakes {
            let a = Float(s) / Float(stakes) * 2 * .pi
            let path = (0...6).map { i -> V3 in
                let t = Float(i) / 6
                let h = half(t)
                return V3(h.x * cos(a), y0 + (height - y0) * t, h.y * sin(a))
            }
            m.add(Prim.tube(path, radii: Array(repeating: 0.0023, count: 7), sides: 4, seamTile: 0.02, material: cane))
        }
        // Weaver courses, offset in/out alternately per stake pair so they read as over-under.
        for c in 0..<courses {
            let t = (Float(c) + 0.5) / Float(courses)
            let y = y0 + (height - y0 - 0.006) * t + 0.003
            let h = half(Float(y - y0) / (height - y0))
            let wavy = (0..<n).map { k -> V3 in
                let a = Float(k) / Float(n) * 2 * .pi
                let ph = Float(c % 2) * .pi
                let off = 0.0028 * sin(Float(stakes) / 2 * a * 2 + ph) * 0.5 + 0.0033
                return V3((h.x + off) * cos(a), y, (h.y + off) * sin(a))
            }
            let worn = c % 3 == 1
            m.add(Prim.sweep(Shape2D.circle(0.0030, ry: 0.0022, segments: 5), along: wavy, up: .up, closedPath: true, caps: false,
                             material: worn ? weaverWorn : weaver))
        }
        // Rim: two bound canes with spiral wrap.
        let rimTop = DD1ITableware.oval(rim.x + 0.003, rim.y + 0.003, y: height + 0.002, n: n)
        m.add(Prim.sweep(Shape2D.circle(0.0048, segments: 6), along: rimTop, up: .up, closedPath: true, caps: false, material: cane))
        let rimLow = DD1ITableware.oval(rim.x + 0.001, rim.y + 0.001, y: height - 0.0075, n: n)
        m.add(Prim.sweep(Shape2D.circle(0.0036, segments: 6), along: rimLow, up: .up, closedPath: true, caps: false, material: cane))
        for k in 0..<64 {
            let a = Float(k) / 64 * 2 * .pi
            let p = V3((rim.x + 0.003) * cos(a), height + 0.002, (rim.y + 0.003) * sin(a))
            let tang = simd_normalize(V3(-(rim.x) * sin(a), 0, rim.y * cos(a)))
            m.add(Prim.tube([p - tang * 0.0035 + V3(0, -0.0052, 0), p + tang * 0.0035 + V3(0, 0.0052, 0)], radii: [0.0021, 0.0021], sides: 5, seamTile: 0.02, material: weaverWorn))
        }
        // Story: a loose weaver end sticks out of the side.
        let la = rng.float(0.5...1.0)
        let lp = half(0.45)
        let lo = V3(lp.x * cos(la), y0 + (height - y0) * 0.45, lp.y * sin(la))
        let dir = simd_normalize(V3(cos(la) / lp.x, 0.2, sin(la) / lp.y))
        m.add(Prim.tube([lo, lo + dir * 0.012, lo + dir * 0.022 + V3(0, 0.006, 0)], radii: [0.0024, 0.0022, 0.0013], sides: 5, seamTile: 0.02, material: weaver))
        // Liner: linen draped over the floor, up the wall and folded over the rim, rolled hem hanging outside.
        let steps: [(Float, Float)] = [(0.02, y0 + 0.0125), (0.5, y0 + 0.0125), (0.8, y0 + 0.0135), (0.86, height * 0.5), (0.925, height - 0.018),
                                       (0.975, height - 0.008), (1.04, height + 0.0085), (1.07, height - 0.003), (1.078, height - 0.018)]
        let lrings = steps.map { f, y in Prim.ring(Shape2D.circle(rim.x * f, ry: rim.y * f, segments: 44), y: y) }
        var top = Prim.loft(lrings, capStart: true, material: liner)
        top.displace { p, _ in 0.0016 * sin(p.x * 120 + p.z * 45) * cos(p.z * 85 + p.x * 20) }
        m.add(top)
        var under = Prim.loft(lrings, capStart: true, material: liner).flipped()
        under.deform { p in V3(p.x, p.y - 0.0016, p.z) }
        m.add(under)
        let hem = steps[steps.count - 1]
        m.add(Prim.sweep(Shape2D.circle(0.0017, segments: 6), along: DD1ITableware.oval(rim.x * hem.0, rim.y * hem.0, y: hem.1, n: 48), up: .up,
                         closedPath: true, caps: false, material: liner))
        // Butter stain and crumbs on the liner floor.
        let stain: [V2] = [V2(0, y0 + 0.0133), V2(0.022, y0 + 0.0133), V2(0.03, y0 + 0.0136), V2(0.0305, y0 + 0.0138), V2(0, y0 + 0.0138)]
        var st = Prim.lathe(stain, segments: 20, seamTile: 0.3, material: "fabric.linen:B7A07A")
        st.recomputeNormals()
        m.add(st, Xform(translation: V3(-0.03, 0, 0.012), rotation: simd_quatf(degrees: 0, axis: .up), scale: V3(1.5, 1, 0.8)))
        for _ in 0..<5 {
            let a = rng.float(0...6.28), d = rng.float(0.01...0.07)
            m.add(Prim.superellipsoid(V3(rng.float(0.002...0.0045), 0.0022, rng.float(0.002...0.004)), exponent: 3, subdivisions: 3, material: "food.bread-crust"),
                  Xform(translation: V3(d * cos(a) * 1.4, y0 + 0.0145, d * sin(a)), rotation: simd_quatf(degrees: rng.float(0...360), axis: .up)))
        }
        // Frayed ends and grimy darkening at the rim where hands lift it.
        for k in 0..<4 {
            let a2 = rng.float(0...6.28), tt = rng.float(0.3...0.8)
            let hp = half(tt)
            let o = V3(hp.x * cos(a2), y0 + (height - y0) * tt, hp.y * sin(a2))
            let d2 = simd_normalize(V3(cos(a2) / hp.x, 0.3, sin(a2) / hp.y))
            m.add(Prim.tube([o, o + d2 * 0.008, o + d2 * 0.014 + V3(rng.float(-0.004...0.004), 0.004, 0)], radii: [0.0016, 0.0013, 0.0007], sides: 4, seamTile: 0.02, material: weaverWorn))
        }
        for k in 0..<10 {
            let a2 = Float(k) / 10 * 2 * .pi + rng.float(0...0.3)
            let pts = (0...6).map { i -> V3 in
                let a = a2 + 0.28 * Float(i) / 6
                return V3((rim.x + 0.0052) * cos(a), height + 0.0062, (rim.y + 0.0052) * sin(a))
            }
            m.add(Prim.tube(pts, radii: Array(repeating: 0.0024, count: 7), sides: 4, seamTile: 0.02, material: "wicker.willow:5E4526"))
        }
        let b = m.bounds
        m = m.transformed(Xform(translation: V3(0, -b.min.y, 0)))
        groundAO(&m, height: 0.03, floor: 0.7)
        return LODModel(levels: [m, lite(seed: seed)], switchDistances: [4])
    }

    func lite(seed: UInt64) -> Model {
        var m = Model(name: Self.id + "-lite")
        var body = Prim.loft([Prim.ring(Shape2D.circle(rim.x - 0.022, ry: rim.y - 0.022, segments: 28), y: 0.0),
                              Prim.ring(Shape2D.circle(rim.x, ry: rim.y, segments: 28), y: height)], capStart: true, material: weaver)
        body.recomputeNormals()
        m.add(body)
        let b = m.bounds
        return m.transformed(Xform(translation: V3(0, -b.min.y, 0)))
    }
}
