import simd
import Foundation

/// Fallen black walnut husks, 5-6 cm: green to rotten black rind, one split with the ridged shell showing.
public struct WalnutHusk: RealAsset {
    public static let id = "walnut-husk"
    public static let summary = "Four fallen walnut husks, 5-6 cm, from green to rotten black, one split open on the ridged shell."
    public static let tags = ["nature", "plant", "ground"]
    public static let budget = 5_700
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 50, distance: 0.65)
    public init() {}
    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let rinds: [MaterialKey] = ["bark.dead:5B6B2A", "bark.dead:4A4A22", "bark.dead:2E2416", "bark.dead:1C1712"]
        for i in 0..<4 {
            let p = i == 0 ? V2(0, 0) : rng.inDisc(radius: 0.13)
            let c = V3(p.x + (i == 0 ? 0 : 0.03 * Float(i % 2 == 0 ? 1 : -1)), 0, p.y)
            let r = rng.float(0.024...0.031)
            let sq = V3(rng.float(0.95...1.1), rng.float(0.88...1.0), rng.float(0.95...1.1))
            if i == 2 {
                // split husk: two curled rind halves around the shell
                let shell = DetailKit15.blob(at: c + V3(0, 0.017, 0), radii: V3(0.019, 0.021, 0.018), lump: 0.15, fine: 0.05, sub: 8, material: "wood.walnut:8A6A44", rng: &rng, ridges: 14, ridgeDepth: 0.14)
                m.add(shell)
                for s in [Float(-1), 1] {
                    let h = DetailKit15.blob(at: c + V3(s * 0.016, 0.014, rng.float(-0.004...0.004)), radii: V3(0.015, 0.016, 0.027), lump: 0.25, fine: 0.04, sub: 6, material: rinds[2], rng: &rng)
                    m.add(h)
                }
                continue
            }
            m.add(DetailKit15.blob(at: c + V3(0, r * sq.y * 0.96, 0), radii: V3(r, r, r) * sq, lump: 0.22, fine: i >= 2 ? 0.07 : 0.035, sub: 9, material: rinds[i], rng: &rng))
            // stem scar and dried calyx tip
            m.add(Prim.lathe([V2(0, 0), V2(0.005, 0.0012), V2(0.0045, 0.0035), V2(0, 0.004)], segments: 7, seamTile: 0.02, material: "bark.dead:221A12"), Xform(translation: c + V3(rng.float(-0.003...0.003), r * 1.85 * sq.y, 0), rotation: simd_quatf(angle: rng.float(0...0.3), axis: V3(1, 0, 0))))
        }
        // dry leaf-litter pieces
        for _ in 0..<5 {
            let p = rng.inDisc(radius: 0.14)
            var b = PlantKit.Blade()
            b.root = V3(p.x, 0.001, p.y); b.yaw = rng.float(0...6.28); b.length = rng.float(0.05...0.09); b.width = rng.float(0.014...0.02)
            b.lean = 1.45; b.curl = rng.float(-0.15...0.1); b.segments = 3; b.tipWidth = 0.1; b.belly = 0.5; b.weight = V2(0, 0)
            m.add(PlantKit.blade(b, material: "leaf.maple:8C6A2A"))
        }
        groundAO(&m, height: 0.03, floor: 0.55)
        PlantKit.finish(&m)
        return LODModel(levels: [m], switchDistances: [])
    }
}
