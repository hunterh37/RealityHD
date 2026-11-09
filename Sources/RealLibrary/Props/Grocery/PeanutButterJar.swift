import simd
import Foundation

/// 16 oz peanut butter jar, 11.5 cm: clear PET jar with a rounded heel, shoulder and threaded neck finish,
/// peanut butter filling it with a swirled top and an air pocket against the wall, a knurled red screw lid,
/// and a printed paper wrap label (invented brand NUTTALE) with a glued seam. A smear of spread sits on the
/// neck threads.
public struct PeanutButterJar: RealAsset {
    public static let id = "peanut-butter-jar"
    public static let summary = "Peanut butter jar, 11.5 cm: clear PET jar with spread inside, knurled red lid, printed wrap label, threaded neck."
    public static let tags = ["prop", "grocery", "food", "plastic", "container", "pantry", "handheld"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 18, distance: 1.3, studio: true)

    public var brand = "NUTTALE"
    public var line = "CREAMY"
    public var lid: MaterialKey = "plastic.gloss:C4322A"
    public var jar: MaterialKey = "pkg.pet-clear"
    public var spread: MaterialKey = "plastic.matte:9A6226"
    /// Printed label (brand field tint).
    public var label: MaterialKey = "pkg.paper-label:EFE4C8"
    public var ink: MaterialKey = "paper.sheet:FFFFFF"
    /// Jar radius and height without the lid.
    public var r: Float = 0.043
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [make(hi: true), make(hi: false)], switchDistances: [3])
    }

    func make(hi: Bool) -> Model {
        typealias K = GroceryKit
        var m = Model(name: Self.id)
        let segs = hi ? 64 : 20
        // Jar: push-up base, heel, wall, shoulder, neck finish with two thread turns.
        let jarP: [V2] = [V2(0, 0.0025), V2(0.03, 0.0015), V2(r - 0.004, 0), V2(r - 0.001, 0.0012), V2(r, 0.004), V2(r, 0.08), V2(r - 0.001, 0.086),
                          V2(r - 0.0045, 0.0905), V2(0.0378, 0.0925), V2(0.0378, 0.094)]
        m.add(Prim.lathe(jarP, segments: segs, seamTile: 0.05, material: jar))
        // Spread inside, swirled top with an air pocket at the front wall.
        var fillP: [V2] = [V2(0, 0.0035), V2(r - 0.004, 0.0018), V2(r - 0.0011, 0.004), V2(r - 0.0011, 0.08), V2(r - 0.002, 0.085), V2(0.034, 0.088)]
        fillP += [V2(0.025, 0.0895), V2(0.012, 0.0905), V2(0, 0.0915)]
        var fill = Prim.lathe(fillP, segments: hi ? 48 : 16, seamTile: 0.05, material: spread)
        if hi { fill.displace { p, nn in
            let a = atan2(p.z, p.x), rr = simd_length(V2(p.x, p.z))
            let swirl: Float = nn.y > 0.5 ? 0.0012 * sin(a * 3 + rr * 260) : 0
            let pocket = -0.0015 * exp(-(pow(a - 1.2, 2) / 0.05 + pow((p.y - 0.045) / 0.008, 2))) * (nn.y < 0.3 ? 1 : 0)
            return swirl + pocket
        } }
        m.add(fill)
        // Thread turns on the neck.
        if hi {
            let th = (0...96).map { k -> V3 in
                let t = Float(k) / 96 * 4 * .pi
                return V3(0.0381 * cos(t), 0.0928 + 0.0028 * t / (2 * .pi), 0.0381 * sin(t))
            }
            m.add(Prim.tube(th, radii: th.map { _ in 0.0006 }, sides: 4, seamTile: 0.01, material: jar))
            // Spread smeared on the threads.
            m.add(K.revSheet(cols: 6, rows: 2, y0: 0.0926, y1: 0.0942, a0: 0.4, a1: 0.95, uSpan: 0.02, vSpan: 0.002, spread) { _, _ in 0.0384 })
        }
        // Lid: knurled skirt over the neck.
        m.add(K.knurledCap(r: 0.0432, h: 0.0215, y0: 0.0935, ribs: hi ? 64 : 16, depth: 0.0006, lid))
        // Label: one design around (tile 0.25 x 0.09, lower 20 % trimmed), seam at the back.
        let ly0: Float = 0.012, ly1: Float = 0.078, over: Float = 0.14
        let span = 0.25 * (1 + over / (2 * .pi))
        m.add(K.revSheet(cols: hi ? 64 : 20, rows: 2, y0: ly0, y1: ly1, a0: -.pi, a1: .pi + over, uSpan: span, vSpan: -0.072, u0: 0.03, v0: 0.072, label) { _, a in
            r + 0.0005 + (a > .pi ? 0.00028 : 0) })
        if hi {
            let aPill = (0.7 * 0.25 - 0.03) / span * (2 * .pi + over) - .pi
            let yOf: (Float) -> Float = { q in ly0 + (q * 0.09 - 0.018) / 0.072 * (ly1 - ly0) }
            K.wrapText(&m, brand, height: 0.0072, y: yOf(0.815), at: aPill, ink, maxWidth: 0.085, weight: 1.25, lift: 0.0013) { _ in r }
            // Spread run down the outside from under the lid.
            let dp = (0...5).map { k -> V3 in let y = 0.093 - Float(k) * 0.0028, a: Float = -0.9; return V3((r + 0.0012) * sin(a), y, (r + 0.0012) * cos(a)) }
            m.add(Prim.tube(dp, radii: [0.0022, 0.0018, 0.0015, 0.0014, 0.0016, 0.002], sides: 8, seamTile: 0.01, material: spread))
            K.wrapText(&m, line, height: 0.0065, y: yOf(0.69), at: aPill, "paper.sheet:7A2E1A", maxWidth: 0.06, weight: 1.2, lift: 0.0013) { _ in r }
        }
        groundAO(&m, height: 0.02, floor: 0.7)
        return m
    }
}
