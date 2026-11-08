import simd
import Foundation

/// Tray pack of chocolate chip cookies, 20 x 6 x 13 cm: a blue printed paperboard sleeve base, a row of
/// cookies standing on edge in a tray, clear crimped film over the top and a label strip with the invented
/// brand BAKEWELL HOUSE.
public struct CookiePack: RealAsset {
    public static let id = "cookie-pack"
    public static let summary = "Tray pack of chocolate chip cookies, 20 cm: printed sleeve base, cookies on edge in a tray, clear crimped film, label strip."
    public static let tags = ["prop", "grocery", "food", "baked", "paper", "plastic", "handheld"]
    public static let budget = 6000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 35, distance: 1.3, studio: true)

    public var size = V3(0.2, 0.06, 0.13)
    public var sleeve: MaterialKey = "paper.sheet:1F4E96"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let s = size
        GroceryKit.box(&m, V3(s.x, s.y * 0.45, s.z), V3(0, s.y * 0.225, 0), sleeve, r: 0.002)
        GroceryKit.decal(&m, s.x * 0.9, s.y * 0.3, V3(0, s.y * 0.23, s.z / 2 + 0.0006), "paper.sheet:F2C230")
        GroceryKit.print(&m, "CHOC CHIP", height: 0.009, at: V3(0, s.y * 0.17, s.z / 2 + 0.0008), "paper.sheet:1F4E96", maxWidth: s.x * 0.8)
        // Cookies on edge, leaning in a row along X.
        let n = 9
        for i in 0..<n {
            let x = -s.x / 2 + 0.016 + Float(i) * (s.x - 0.032) / Float(n - 1)
            let c = Prim.lathe([V2(0, 0), V2(0.026, 0), V2(0.029, 0.004), V2(0.028, 0.008), V2(0, 0.0095)], segments: 14, seamTile: 0.03,
                               material: "food.cookie-dough-cooked")
            m.add(c, Xform(translation: V3(x, s.y * 0.3 + 0.026, 0), rotation: simd_quatf(degrees: -78 + rng.float(-4...4), axis: V3(0, 0, 1))))
            if i % 2 == 0 {
                GroceryKit.box(&m, V3(0.006, 0.004, 0.005), V3(x + 0.004, s.y * 0.3 + 0.03 + rng.float(-0.01...0.01), rng.float(-0.012...0.012)),
                               "food.chocolate-chunk", r: 0.0015)
            }
        }
        // Film over the top, crimped ends, label strip.
        m.add(Prim.superellipsoid(V3(s.x - 0.01, s.y * 0.95, s.z), exponent: 5, subdivisions: 4, material: "plastic.clear"), Xform(translation: V3(0, s.y * 0.5, 0)))
        for sx: Float in [-1, 1] { GroceryKit.box(&m, V3(0.012, s.y * 0.7, s.z * 0.96), V3(sx * (s.x / 2 - 0.004), s.y * 0.4, 0), "plastic.clear", r: 0.003) }
        GroceryKit.decal(&m, s.x * 0.5, s.z * 0.4, V3(0, s.y * 0.976, 0), "paper.sheet:F6F1E4", rot: simd_quatf(degrees: -90, axis: V3(1, 0, 0)))
        GroceryKit.print(&m, "BAKEWELL", height: 0.012, at: V3(0, s.y * 0.978, 0.006), "paper.sheet:1F4E96", rot: simd_quatf(degrees: -90, axis: V3(1, 0, 0)), maxWidth: s.x * 0.44)
        GroceryKit.print(&m, "HOUSE", height: 0.007, at: V3(0, s.y * 0.978, -0.012), "paper.sheet:C8262B", rot: simd_quatf(degrees: -90, axis: V3(1, 0, 0)))
        groundAO(&m, height: 0.01, floor: 0.7)
        return LODModel(m)
    }
}
