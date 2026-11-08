import simd
import Foundation

/// 16 oz peanut butter jar, 11.5 cm: clear PET jar showing the spread, a ribbed red screw lid, and a cream
/// wrap label with a blue band and the invented brand NUTTALE printed around the wall.
public struct PeanutButterJar: RealAsset {
    public static let id = "peanut-butter-jar"
    public static let summary = "Peanut butter jar, 11.5 cm: clear PET jar with spread inside, ribbed red screw lid, cream wrap label with blue band."
    public static let tags = ["prop", "grocery", "food", "plastic", "container", "pantry", "handheld"]
    public static let budget = 5000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 18, distance: 1.3, studio: true)

    public var brand = "NUTTALE"
    public var lid: MaterialKey = "plastic.gloss:C4322A"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(hi: true), level(hi: false)], switchDistances: [2])
    }

    func level(hi: Bool) -> Model {
        var m = Model(name: Self.id)
        let seg = hi ? 32 : 12, r: Float = 0.041
        m.add(Prim.lathe([V2(0, 0.003), V2(0.034, 0), V2(r, 0.006), V2(r, 0.088), V2(0.037, 0.095), V2(0.035, 0.098), V2(0.035, 0.1), V2(0, 0.1)],
                         segments: seg, seamTile: 0.05, material: "plastic.clear"))
        m.add(Prim.lathe([V2(0, 0.004), V2(0.039, 0.005), V2(0.0395, 0.086), V2(0.03, 0.094), V2(0, 0.093)], segments: seg, seamTile: 0.05,
                         material: "food.cookie-dough-cooked:B07438"))
        m.add(Prim.lathe([V2(r + 0.0006, 0.02), V2(r + 0.0006, 0.08)], segments: seg, seamTile: 0.05, material: "paper.sheet:F3E3B5"))
        m.add(Prim.lathe([V2(r + 0.0009, 0.024), V2(r + 0.0009, 0.036)], segments: seg, seamTile: 0.05, material: "paper.sheet:2E5D9C"))
        // Ribbed lid.
        var lp: [V2] = [V2(0, 0.115), V2(0.0425, 0.115), V2(0.0435, 0.113)]
        lp += [V2(0.0435, 0.099), V2(0.0425, 0.097), V2(0, 0.097)]
        m.add(Prim.lathe(lp.reversed(), segments: seg, seamTile: 0.05, material: lid))
        if hi {
            for i in 0..<36 {
                let a = Float(i) / 36 * 2 * .pi
                GroceryKit.flat(&m, V3(0.0016, 0.012, 0.0012), V3(0.0438 * cos(a), 0.106, 0.0438 * sin(a)), lid,
                                rot: simd_quatf(angle: -a + .pi / 2, axis: .up))
            }
        }
        GroceryKit.wrapPrint(&m, brand, height: 0.016, radius: r + 0.0006, y: 0.05, "paper.sheet:7A3A16", maxWidth: 0.09)
        GroceryKit.wrapPrint(&m, "CREAMY", height: 0.006, radius: r + 0.0009, y: 0.027, "paper.sheet:F6F2E8")
        return m
    }
}
