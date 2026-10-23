import simd
import Foundation

/// Oak twig, 28 cm, carrying two marble galls of 2 cm (one with a wasp exit hole) and one fallen gall.
public struct OakGall: RealAsset {
    public static let id = "oak-gall"
    public static let summary = "Fallen oak twig, 28 cm, with two 2 cm marble galls, one bored through, and a loose gall beside it."
    public static let tags = ["nature", "plant", "wood"]
    public static let budget = 3_200
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 40, distance: 0.7)
    public init() {}
    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let L: Float = 0.28, r0 = rng.float(0.0045...0.006)
        let raw = DetailKit02.limbPath(from: V3(-L / 2, r0 + 0.003, -0.06), dir: V3(1, 0.03, 0.15), len: L, segs: 12, wobble: 0.12, rng: &rng)
        let pts = raw.map { V3($0.x, max($0.y, r0 * 0.8), $0.z) }
        let radii = (0...12).map { r0 * (1 - 0.35 * Float($0) / 12) * rng.float(0.92...1.08) }
        m.add(Prim.tube(pts, radii: radii, sides: 7, seamTile: 0.03, material: "bark.oak:6B5A48", capEnd: true))
        // side twiglet with bud cluster
        let bi = 8
        let sd = V3(0.5, 0.35, -0.8).normalized
        let b0 = pts[bi]
        m.add(Prim.tube([b0, b0 + sd * 0.025, b0 + sd * 0.05 + V3(0, 0.01, 0)], radii: [r0 * 0.6, r0 * 0.45, r0 * 0.3], sides: 5, seamTile: 0.02, material: "bark.oak:6B5A48", capEnd: true))
        // galls
        for (k, idx) in [4, 7].enumerated() {
            let g = rng.float(0.0095...0.0115)
            let c = pts[idx] + V3(rng.float(-0.002...0.002), g * 0.55 + radii[idx] * 0.4, rng.float(-0.004...0.004))
            let hue: MaterialKey = k == 0 ? "bark.dead:B58B52" : "bark.dead:A8794A"
            m.add(DetailKit15.blob(at: c, radii: V3(g, g * 0.97, g), lump: 0.06, fine: 0.025, sub: 8, floorY: 0, material: hue, rng: &rng))
            if k == 1 {
                // wasp exit hole: dark disc recessed slightly outside the surface
                let d = V3(0.4, 0.6, 0.7).normalized
                let q = simd_quatf(from: .up, to: d)
                m.add(Prim.lathe([V2(0, 0.0004), V2(0.0014, 0.0004), V2(0.0019, 0.0009), V2(0.0019, 0.0)], segments: 8, seamTile: 0.01, material: "bark.dead:1A130E"), Xform(translation: c + d * g * 0.985, rotation: q))
            }
            // gall base collar where it grips the twig
            m.add(Prim.lathe([V2(0.0, 0), V2(g * 0.28, 0.0), V2(g * 0.2, 0.004), V2(0, 0.004)], segments: 6, seamTile: 0.02, material: "bark.oak:5A4A3A"), Xform(translation: pts[idx] - V3(0, radii[idx] * 0.6, 0)))
        }
        // fallen gall, one rotted flat, with pit marks
        let fg = rng.float(0.0105...0.0125)
        m.add(DetailKit15.blob(at: V3(0.065, fg * 0.9, 0.04), radii: V3(fg, fg * 0.95, fg), lump: 0.08, fine: 0.04, sub: 8, material: "bark.dead:9A6E40", rng: &rng))
        // dry oak leaf scraps
        for _ in 0..<3 {
            let p = rng.inDisc(radius: 0.12)
            var b = PlantKit.Blade()
            b.root = V3(p.x - 0.03, 0.001, p.y + 0.03); b.yaw = rng.float(0...6.28); b.length = rng.float(0.05...0.08); b.width = rng.float(0.02...0.03)
            b.lean = 1.45; b.curl = rng.float(-0.2...0.1); b.segments = 3; b.tipWidth = 0.2; b.belly = 0.6; b.weight = V2(0, 0)
            m.add(PlantKit.blade(b, material: "leaf.oak:7A5428"))
        }
        groundAO(&m, height: 0.03, floor: 0.6)
        PlantKit.finish(&m)
        return LODModel(levels: [m], switchDistances: [])
    }
}
