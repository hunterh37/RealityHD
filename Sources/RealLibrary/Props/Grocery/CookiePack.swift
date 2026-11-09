import simd
import Foundation

/// Flow-wrapped chocolate chip cookie pack, 21.5 x 6.2 x 13 cm, lying flat: printed film tube with crimped,
/// serrated end seals, a clear window on the top over two rows of cookies standing on edge in a brown tray,
/// a printed top panel and the invented brand BAKEWELL.
public struct CookiePack: RealAsset {
    public static let id = "cookie-pack"
    public static let summary = "Flow-wrapped chocolate chip cookie pack, 21 cm: printed film, crimped end seals, clear window over cookies in a tray."
    public static let tags = ["prop", "grocery", "food", "baked", "plastic", "handheld"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 35, distance: 1.3, studio: true)

    /// Body length (x, without seals), height, width.
    public var size = V3(0.18, 0.06, 0.128)
    /// Printed film brand field color.
    public var color: UInt32 = 0x1F4E96
    public var brand = "BAKEWELL"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(hi: true, seed: seed), level(hi: false, seed: seed)], switchDistances: [2])
    }

    func level(hi: Bool, seed: UInt64) -> Model {
        var m = Model(name: Self.id)
        let L = size.x / 2, hh = size.y / 2, hw = size.z / 2, cy = hh, seal: Float = 0.018
        func f(_ v: Float) -> Float { (v < 0 ? -1 : 1) * pow(abs(v), 2 / 6) }
        func pt(_ x: Float, _ a: Float, _ k: Float = 1, _ g: Float = 0) -> V3 {
            V3(x, cy + f(sin(a)) * (hh * k + g), f(cos(a)) * (hw + g))
        }
        let film = GroceryKit.tint("pkg.film-bag", color)
        let n = hi ? 40 : 16
        // Clear body tube.
        let body = [-L, L].map { x in (0..<n).map { q in pt(x, Float(q) / Float(n) * 2 * .pi) } }
        m.add(Prim.loft(body, material: "pkg.pet-clear"))
        // Printed seal zones: the tube pinches to a flat serrated fin.
        for s: Float in [1, -1] {
            var rings: [[V3]] = []
            let steps = hi ? 8 : 3
            for i in 0...steps {
                let t = Float(i) / Float(steps), x = s * (L + seal * t)
                let k = max(0.05, 1 - pow(min(1, t * 1.7), 0.7))
                rings.append((0..<n).map { q in
                    var p = pt(x, Float(q) / Float(n) * 2 * .pi, k)
                    if t > 0.6 { p.y += 0.0005 * sin(p.z * 2 * .pi / 0.004) }
                    return p
                })
            }
            var lz = Prim.loft(s > 0 ? rings : rings.reversed(), material: film)
            lz.uvs = lz.positions.map { V2(($0.z + 0.07) * 0.6, $0.y * 0.6 + 0.29) }
            lz.computeTangents()
            m.add(lz)
            // Serrated edge.
            GroceryKit.box(&m, V3(0.002, 0.0028, size.z + 0.002), V3(s * (L + seal), cy, 0), film, r: 0.0006)
        }
        // Printed wrap over sides and bottom (brand field), top panel with the design; window on the right.
        let g: Float = 0.0004
        let wrap = GroceryKit.sheet(cols: hi ? 8 : 2, rows: hi ? 30 : 10, film, crop: (0.02, 0.12, 0.965, 0.995)) { u, v in
            pt(-L + 2 * L * u, (0.83 + 1.34 * v) * .pi, 1, g) }
        m.add(wrap)
        let wx: Float = 0.035
        let top = GroceryKit.sheet(cols: hi ? 10 : 3, rows: hi ? 12 : 4, film, crop: (0, 1, 0.12, 0.92)) { u, v in
            pt(-L + (L + wx) * u, (0.17 + 0.66 * v) * .pi, 1, g) }
        m.add(top)
        // Window border keyline.
        GroceryKit.box(&m, V3(0.003, 0.0006, size.z * 0.86), V3(wx + 0.0015, size.y + 0.0004, 0), "plastic.gloss:F2C230", r: 0.0002)
        // Wordmark on the top panel (faces +y, reads from the front edge).
        let up = simd_quatf(angle: -.pi / 2, axis: V3(1, 0, 0))
        let cx = (-L + wx) / 2
        GroceryKit.printSmooth(&m, brand, height: 0.016, at: V3(cx, size.y + g + 0.0007, 0.012), "plastic.gloss:FFFFFF", rot: up,
                               maxWidth: 0.1, weight: 1.35)
        GroceryKit.printSmooth(&m, "CHOC CHIP", height: 0.008, at: V3(cx, size.y + g + 0.0007, 0.03), "plastic.gloss:F2C230", rot: up,
                               maxWidth: 0.06, weight: 1.2)
        // Tray and cookies standing on edge in two rows.
        GroceryKit.box(&m, V3(size.x - 0.006, 0.012, size.z - 0.01), V3(0, 0.007, 0), "plastic.gloss:3A2214", r: 0.003)
        var rng = SeededRNG(seed: seed &+ 31)
        let d: Float = 0.054
        let cookie = Prim.superellipsoid(V3(0.0105, d, d), exponent: 2.6, subdivisions: hi ? 5 : 2, material: "food.cookie-dough-cooked") { dir in
            1 + 0.05 * Noise.fbm(dir * 6, octaves: 2, seed: 3) }
        let chip = Prim.superellipsoid(V3(0.006, 0.006, 0.006), exponent: 2, subdivisions: 1, material: "food.chocolate-chunk")
        var x = -L + 0.012
        while x < L - 0.006 {
            for zc: Float in [-0.031, 0.031] {
                let tilt = simd_quatf(angle: rng.float(-0.28 ... -0.18), axis: V3(0, 0, 1)) * simd_quatf(angle: rng.float(0...6.28), axis: V3(1, 0, 0))
                let c = V3(x, 0.006 + d / 2 - 0.001, zc + rng.float(-0.002...0.002))
                m.add(cookie, Xform(translation: c, rotation: tilt))
                if hi && x > wx - 0.01 {
                    for _ in 0..<5 {
                        let a = rng.float(0...6.28), rr = rng.float(0...0.02)
                        m.add(chip, Xform(translation: c + tilt.act(V3(0.005, rr * sin(a), rr * cos(a))), scale: V3(repeating: rng.float(0.7...1.2))))
                    }
                }
            }
            x += 0.0118
        }
        return m
    }
}
