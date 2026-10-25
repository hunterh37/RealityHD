import simd
import Foundation

/// Bay window flower box, iron: Victorian wrought iron cradle for a window ledge. Flat-laid 28 x 6 mm top rail,
/// 20 mm bottom rail, 16 mm square corner posts with ball finials, 9.5 mm round pickets tipped with spear points,
/// a centre pair of C-scrolls, wall plates with coach screws and arms back to the sill, coir liner, soil,
/// pelargoniums and trailing ivy. Paint is chipped at joints with rust runs.
public struct BayWindowFlowerBoxIron: RealAsset {
    public static let id = "bay-window-flower-box-iron"
    public static let summary = "Victorian wrought iron window box cradle: pickets, C-scrolls, ball finials, coir liner, pelargoniums and ivy."
    public static let tags = ["prop", "architecture", "facade", "metal", "decor"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 16, distance: 1.5)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(1.2, 0.35, 0.30)
    /// Painted wrought iron.
    public var iron: MaterialKey = "metal.wrought-iron"
    public var coir: MaterialKey = "fabric.burlap"
    /// Bloom color.
    public var bloom: MaterialKey = "flower.petal:C4202A"
    public init() {}

    /// Spiral polyline in the XY plane at depth z.
    func spiral(_ cx: Float, _ cy: Float, _ z: Float, _ r0: Float, _ r1: Float, a0: Float, turns: Float, dir: Float, n: Int = 16) -> [V3] {
        (0...n).map { i in
            let u = Float(i) / Float(n), a = (a0 + dir * u * turns * 360) * .pi / 180, r = r0 + (r1 - r0) * u
            return V3(cx + r * cos(a), cy + r * sin(a), z)
        }
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W: Float = 1.2, D: Float = 0.30, top: Float = 0.21, bot: Float = 0.022, hw = W / 2 - 0.008
        // Rails: flat-laid top (28 x 6), bottom 20 x 5, on front, back and both returns.
        FA.box(&m, V3(W, 0.006, 0.028), V3(0, top, D - 0.014), iron, r: 0.0012)
        FA.box(&m, V3(W, 0.006, 0.028), V3(0, top, 0.014), iron, r: 0.0012)
        for s: Float in [-1, 1] {
            FA.box(&m, V3(0.028, 0.006, D - 0.056), V3(s * (W / 2 - 0.014), top, D / 2), iron, r: 0.0012)
            FA.box(&m, V3(0.02, 0.005, D - 0.04), V3(s * (W / 2 - 0.01), bot, D / 2), iron, r: 0.001)
        }
        FA.box(&m, V3(W, 0.005, 0.02), V3(0, bot, D - 0.01), iron, r: 0.001)
        FA.box(&m, V3(W, 0.005, 0.02), V3(0, bot, 0.01), iron, r: 0.001)
        // Corner posts with ball finials.
        for sx: Float in [-1, 1] {
            for z: Float in [0.012, D - 0.012] {
                FA.box(&m, V3(0.016, top + 0.006, 0.016), V3(sx * (W / 2 - 0.012), (top + 0.006) / 2 - 0.003, z), iron, r: 0.0015)
                FA.ball(&m, r: 0.0125, at: V3(sx * (W / 2 - 0.012), top + 0.016, z), iron)
                FA.box(&m, V3(0.022, 0.004, 0.022), V3(sx * (W / 2 - 0.012), top + 0.0035, z), iron, r: 0.001)
            }
        }
        // Pickets on the front (centre panel replaced by scrolls) and returns, spear-tipped every second one.
        let tip: [V2] = [V2(0.0072, 0), V2(0.0072, 0.002), V2(0.0045, 0.012), V2(0.0005, 0.024), V2(0, 0.025)]
        var x = -hw + 0.05
        var idx = 0
        while x < hw - 0.03 {
            if abs(x) > 0.2 {
                FA.rod(&m, V3(x, bot, D - 0.01), V3(x, top, D - 0.01), r: 0.0047, iron, sides: 6)
                if idx % 2 == 0 { FA.rod(&m, V3(x, bot, 0.01), V3(x, top, 0.01), r: 0.0047, iron, sides: 6) }
                if idx % 2 == 0 { m.add(Prim.lathe(tip, segments: 7, seamTile: 0.05, material: iron), Xform(translation: V3(x, top + 0.002, D - 0.01))) }
            }
            x += 0.062
            idx += 1
        }
        for s: Float in [-1, 1] {
            for z in stride(from: Float(0.075), through: D - 0.075, by: 0.075) {
                FA.rod(&m, V3(s * (W / 2 - 0.012), bot, z), V3(s * (W / 2 - 0.012), top, z), r: 0.0047, iron, sides: 7)
            }
        }
        // Centre scroll panel: facing C-scrolls with a lozenge boss between.
        let mid = (top + bot) / 2
        for s: Float in [-1, 1] {
            let p = spiral(s * 0.105, mid, D - 0.01, 0.08, 0.012, a0: s > 0 ? 160 : 20, turns: 1.15, dir: s > 0 ? 1 : -1, n: 20)
            m.add(Prim.tube(p, radii: Array(repeating: 0.0046, count: p.count), sides: 7, seamTile: 0.1, material: iron, capEnd: true))
            let q = spiral(s * 0.2, mid, D - 0.01, 0.045, 0.01, a0: s > 0 ? 180 : 0, turns: 1.1, dir: s > 0 ? -1 : 1, n: 18)
            m.add(Prim.tube(q, radii: Array(repeating: 0.0042, count: q.count), sides: 7, seamTile: 0.1, material: iron, capEnd: true))
        }
        FA.rod(&m, V3(-0.24, mid, D - 0.01), V3(0.24, mid, D - 0.01), r: 0.0038, iron, sides: 6)
        FA.ball(&m, r: 0.011, at: V3(0, mid, D - 0.01), iron)
        // Wall plates, arms to the frame, coach screws with rust at the heads.
        for sx: Float in [-0.44, 0.44] {
            FA.box(&m, V3(0.06, 0.19, 0.007), V3(sx, 0.115, 0.0035), iron, r: 0.0018)
            hexBolt(&m, at: V3(sx, 0.17, 0.007), normal: FA.Z, size: 0.016, material: "metal.rust")
            hexBolt(&m, at: V3(sx, 0.06, 0.007), normal: FA.Z, size: 0.016, material: iron)
            FA.box(&m, V3(0.018, 0.006, 0.04), V3(sx, bot, 0.02 + 0.0), iron, r: 0.001)
        }
        // Coir liner (4 mm walls) and soil.
        let ly = (top + 0.002 + 0.004) / 2
        FA.box(&m, V3(W - 0.044, top - 0.01, 0.004), V3(0, ly - 0.001, D - 0.024), coir, r: 0.001)
        FA.box(&m, V3(W - 0.044, top - 0.01, 0.004), V3(0, ly - 0.001, 0.028), coir, r: 0.001)
        for s: Float in [-1, 1] { FA.box(&m, V3(0.004, top - 0.01, D - 0.056), V3(s * (W / 2 - 0.024), ly - 0.001, D / 2), coir, r: 0.001) }
        m.add(Prim.superellipsoid(V3(W - 0.056, 0.14, D - 0.06), exponent: 8, subdivisions: 8, material: "soil.potting"), Xform(translation: V3(0, 0.09 + 0.07 - 0.005, D / 2)))
        // Planting.
        for k in 0..<16 {
            let px = -hw + 0.07 + Float(k) * (2 * hw - 0.14) / 15 + rng.float(-0.01...0.01), pz = D / 2 + rng.float(-0.06...0.06)
            FC.leafCard(&m, "leaf.rose", at: V3(px, 0.185, pz), width: 0.13, height: rng.float(0.1...0.16), spin: rng.float(-25...25), tilt: rng.float(-30...20), yaw: rng.float(-40...40))
        }
        let tones: [MaterialKey] = [bloom, "flower.petal:D9435B", "flower.petal:E27A8C", "flower.petal:B3162A"]
        for k in 0..<10 {
            let c = V3(-hw + 0.09 + Float(k) * (2 * hw - 0.18) / 9 + rng.float(-0.015...0.015), 0.27 + rng.float(0...0.04), D / 2 + rng.float(-0.04...0.04))
            for j in 0..<5 {
                m.add(ShrubKit.floretBall(center: c + V3(rng.float(-0.022...0.022), rng.float(-0.012...0.012), rng.float(-0.022...0.022)), radius: rng.float(0.011...0.016),
                                          up: FA.Y, subdivisions: 2, seed: rng.float(0...40), material: tones[(k + j) % tones.count]))
            }
        }
        for k in 0..<9 {
            let px = -hw + 0.05 + Float(k) * (2 * hw - 0.1) / 8 + rng.float(-0.012...0.012)
            FC.leafCard(&m, "leaf.boxwood", at: V3(px, 0.195, D - 0.006), width: 0.09, height: rng.float(0.06...0.13), spin: 180, tilt: rng.float(-12...(-3)))
        }
        // Wear: rust at the post bases and along the bottom rail.
        for sx: Float in [-1, 1] {
            for z: Float in [0.012, D - 0.012] {
                FA.box(&m, V3(0.018, 0.012, 0.018), V3(sx * (W / 2 - 0.012), 0.004, z), "metal.rust", r: 0.0012)
            }
        }
        for _ in 0..<6 {
            FA.box(&m, V3(rng.float(0.03...0.07), 0.0012, 0.0212), V3(rng.float(-0.5...0.5), bot + 0.0027, D - 0.01), "metal.rust", r: 0.0003)
        }
        groundAO(&m, height: 0.15, floor: 0.75)
        return LODModel(FC.fit(m, size))
    }
}
