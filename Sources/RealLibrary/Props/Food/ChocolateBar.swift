import simd
import Foundation

/// Dark chocolate bar lying flat, long side along +X, half unwrapped: a 6 x 3 tablet of pieces separated by
/// beveled V grooves, crinkled foil torn open over the left pieces, and a printed paper sleeve slid back over
/// the right half with smooth wordmarks of the invented brand NOIRE. Cut face `food.chocolate`.
public struct ChocolateBar: RealFood {
    public static let id = "chocolate-bar"
    public static let summary = "Dark chocolate bar, 16 cm: scored tablet in torn foil with a printed paper sleeve slid back."
    public static let tags = ["prop", "food", "kitchen", "handheld"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let kind = FoodKind.dairy
    public static let preview = PreviewHint(azimuth: 25, elevation: 40, distance: 1.3, studio: true)

    /// Bar size (m).
    public var size = V3(0.155, 0.009, 0.075)
    /// Pieces along X and Z.
    public var columns = 6
    public var rows = 3
    /// Groove depth and half width (m).
    public var grooveDepth: Float = 0.0035
    public var grooveHalf: Float = 0.0028
    /// Material key.
    public var chocolate: MaterialKey = "food.chocolate"
    /// Sleeve brand field color and brand.
    public var sleeve: UInt32 = 0x5C1A1E
    public var brand = "NOIRE"
    public init() {}

    public var coreCenter: V3 { V3(0, size.y / 2, 0) }

    public func capMaterial(for key: MaterialKey) -> MaterialKey? { key == chocolate ? chocolate : nil }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let h = size / 2
        func lines(_ n: Int, _ half: Float) -> [Float] { (1..<n).map { -half + 2 * half * Float($0) / Float(n) } }
        let gx = lines(columns, h.x), gz = lines(rows, h.z)
        func extra(_ g: [Float]) -> [Float] { g.flatMap { [$0 - grooveHalf, $0, $0 + grooveHalf] } }
        var s = FoodMesh.box(size, radius: 0.0018, edge: 0.006, bevelSegments: 2, extra: [extra(gx), [], extra(gz)], material: chocolate)
        func groove(_ v: Float, _ g: [Float]) -> Float {
            g.map { max(0, 1 - abs(v - $0) / grooveHalf) }.max() ?? 0
        }
        // A small chip off one corner piece and slight piece-to-piece height variation.
        let chip = V3(h.x * (rng.chance(0.5) ? 1 : -1), h.y, h.z * (rng.chance(0.5) ? 1 : -1))
        let jitter = (0..<(columns * rows)).map { _ in rng.float(-0.00015...0.00015) }
        s.deform { p in
            var q = p
            let up = (p.y + h.y) / size.y          // 0 at the back, 1 at the face
            let g = max(groove(p.x, gx), groove(p.z, gz))
            let ci = min(columns - 1, max(0, Int((p.x + h.x) / size.x * Float(columns))))
            let ri = min(rows - 1, max(0, Int((p.z + h.z) / size.z * Float(rows))))
            q.y -= up * (self.grooveDepth * g - jitter[ri * columns + ci] * (1 - g))
            let d = simd_distance(V3(p.x, p.y, p.z), chip)
            if d < 0.006 { q.y -= up * 0.0025 * (1 - d / 0.006) * (1 - d / 0.006) }
            return q
        }
        var m = Model(name: Self.id)
        m.add(s)
        m = m.transformed(Xform(translation: V3(0, h.y, 0)))
        wrapper(&m, seed: seed)
        groundAO(&m, height: 0.004, floor: 0.7)
        return LODModel(m)
    }

    /// Rounded-rect section around the tablet at angle `a` (y up, z front), grown by `g`.
    func section(_ a: Float, _ g: Float) -> (Float, Float) {
        func f(_ v: Float) -> Float { (v < 0 ? -1 : 1) * pow(abs(v), 2 / 10) }
        return (size.y / 2 + f(sin(a)) * (size.y / 2 + g), f(cos(a)) * (size.z / 2 + g))
    }

    func wrapper(_ m: inout Model, seed: UInt64) {
        let hx = size.x / 2
        // Foil: wraps the right of the tablet, torn edge on the left, crinkled.
        let foilX0: Float = -0.018, n = 48
        var foil = GroceryKit.sheet(cols: 22, rows: n, "pkg.foil-wrapper") { u, v in
            let a = v * 2 * .pi
            let tear = 0.006 * Noise.fbm(V3(v * 9, 1, 2), octaves: 3, seed: 5) + 0.004 * sin(v * 37)
            let x = foilX0 + tear * (1 - u) + (hx + 0.0012 - foilX0 - tear * (1 - u)) * u
            let crinkle = 0.0004 * Noise.ridged(V3(x * 300, v * 40, 0), octaves: 2, seed: 9) + (u < 0.06 ? 0.0006 : 0)
            let (y, z) = self.section(a, 0.0006 + crinkle)
            return V3(x, y, z)
        }
        foil.uvs = foil.positions.map { V2($0.x + $0.z, $0.y + $0.z) }
        foil.computeTangents()
        m.add(foil); m.add(foil.flipped())
        GroceryKit.box(&m, V3(0.001, size.y + 0.0014, size.z + 0.0014), V3(hx + 0.0012, size.y / 2, 0), "pkg.foil-wrapper", r: 0.0004)
        // Paper sleeve slid back: open tube, printed outside, plain inside.
        let key = GroceryKit.tint("pkg.carton-matte", sleeve)
        let sx0: Float = 0.004, sx1 = hx + 0.003
        func tube(_ a0: Float, _ a1: Float, _ crop: (Float, Float, Float, Float), _ k: MaterialKey, _ g: Float) -> Surface {
            GroceryKit.sheet(cols: 2, rows: 16, k, crop: crop) { u, v in
                let (y, z) = self.section(a0 + (a1 - a0) * v, g)
                return V3(sx0 + (sx1 - sx0) * u, y, z)
            }
        }
        m.add(tube(0.18 * .pi, 0.82 * .pi, (0, 1, 0.2, 0.88), key, 0.0022))
        m.add(tube(0.82 * .pi, 2.18 * .pi, (0.02, 0.12, 0.965, 0.995), key, 0.0022))
        m.add(tube(0, 2 * .pi, (0, 1, 0, 1), "paper.sheet:EFE6D6", 0.0016).flipped())
        // Rims at the open ends.
        for x in [sx0, sx1] {
            var rim: [V3] = (0...32).map { i in let (y, z) = self.section(Float(i) / 32 * 2 * .pi, 0.0019); return V3(x, y, z) }
            rim[32] = rim[0]
            m.add(Prim.tube(rim, radii: rim.map { _ in 0.0003 }, sides: 4, seamTile: 0.05, material: "paper.sheet:EFE6D6"))
        }
        // Wordmarks on the sleeve top, reading from the front.
        let up = simd_quatf(angle: -.pi / 2, axis: V3(1, 0, 0)), ty = size.y + 0.0029, cx = (sx0 + sx1) / 2
        GroceryKit.printSmooth(&m, brand, height: 0.014, at: V3(cx, ty, 0.004), "plastic.gloss:E8C77A", rot: up, maxWidth: 0.06, weight: 1.3)
        GroceryKit.printSmooth(&m, "70 CACAO", height: 0.0055, at: V3(cx, ty, 0.016), "plastic.gloss:F4EEE2", rot: up, maxWidth: 0.04, weight: 1)
        _ = seed
    }
}
