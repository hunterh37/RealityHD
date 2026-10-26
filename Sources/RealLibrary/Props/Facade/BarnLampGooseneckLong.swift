import simd
import Foundation

/// Gooseneck barn lamp, long arm: architectural facade customizer, Modern Farmhouse. Black powder-coated round wall
/// plate on four bolts with a cast collar, a swan-neck arm sweeping out and over 0.5 m, a 0.6 m galvanized
/// warehouse shade with rolled rim and white enamel interior, gooseneck socket nut and a warm bulb. Zinc is dulled
/// with rust bloom at the rim and the powder coat is chipped at the plate edge.
public struct BarnLampGooseneckLong: RealAsset {
    public static let id = "barn-lamp-gooseneck-long"
    public static let summary = "Gooseneck barn light, 0.8 m reach: galvanized dome shade on a curved arm."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 55, elevation: 16, distance: 2.2)

    /// Arm and plate powder coat.
    public var coat: MaterialKey = "metal.painted:1E1F21"
    /// Shade metal.
    public var shade: MaterialKey = "metal.galvanized-aged"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let rust: MaterialKey = "metal.rust", steel: MaterialKey = "metal.screw-zinc"
        let zs: Float = 0.5, R: Float = 0.3, yPlate: Float = 0.2
        // Wall plate: round cast rosette with collar and four bolts, chip near the edge.
        m.add(Prim.lathe([V2(0, 0), V2(0.062, 0), V2(0.066, 0.004), V2(0.066, 0.012), V2(0.058, 0.017), V2(0.04, 0.02), V2(0.034, 0.03), V2(0, 0.03)], segments: 32, seamTile: 0.3, material: coat),
              Xform(translation: V3(0, yPlate, 0), rotation: FA.q(90, FA.X)))
        for sx: Float in [-1, 1] { for sy: Float in [-1, 1] {
            FSV.bolt(&m, at: V3(sx * 0.044, yPlate + sy * 0.044, 0.0165), normal: FA.Z, size: 0.012, material: steel)
        } }
        FA.box(&m, V3(0.01, 0.008, 0.0012), V3(0.056, yPlate - 0.01, 0.0125), "metal.steel", r: 0.0003)
        // Gooseneck arm: out from the collar, rising in a long swan curve, over the top and down to the shade.
        let ctrl: [V3] = [V3(0, yPlate, 0.02), V3(0, yPlate, 0.1), V3(0, yPlate + 0.03, 0.22), V3(0, yPlate + 0.1, 0.33), V3(0, yPlate + 0.17, 0.42),
                          V3(0, yPlate + 0.2, 0.48), V3(0, yPlate + 0.19, zs), V3(0, yPlate + 0.14, zs), V3(0, 0.215, zs)]
        let path = catmull(ctrl, per: 8)
        let n = path.count
        let radii: [Float] = (0..<n).map { 0.0185 - 0.003 * Float($0) / Float(n) }
        m.add(Prim.tube(path, radii: radii, sides: 14, seamTile: 0.2, material: coat, capEnd: true))
        // Collar where the arm meets the plate, a split clamp ring mid arm, and a sleeve at the shade.
        FSV.cyl(&m, V3(0, yPlate, 0.02), V3(0, yPlate, 0.052), r: 0.027, coat, bevel: 0.003, segments: 18)
        let mid = path[n / 3]
        m.add(Prim.torus(major: 0.0195, minor: 0.0045, segments: 16, sides: 6, material: coat), Xform(translation: mid, rotation: facing(simd_normalize(path[n / 3 + 1] - path[n / 3 - 1])) * FA.q(0, FA.X)))
        // Shade: spun dome with rolled rim, thickness shown, white enamel interior, rust bloom at the lip.
        let outer: [V2] = [V2(0.0, 0.234), V2(0.045, 0.231), V2(0.1, 0.22), V2(0.165, 0.193), V2(0.23, 0.145), V2(0.275, 0.098), V2(0.295, 0.066), V2(0.3, 0.052), V2(0.3, 0.008), V2(0.295, 0.0), V2(0.286, 0.0)]
        m.add(Prim.lathe(outer, segments: 48, seamTile: 0.6, material: shade), Xform(translation: V3(0, 0, zs), rotation: .identity))
        let inner: [V2] = [V2(0.0, 0.228), V2(0.044, 0.225), V2(0.097, 0.214), V2(0.16, 0.188), V2(0.222, 0.141), V2(0.266, 0.097), V2(0.286, 0.066), V2(0.2905, 0.052), V2(0.2905, 0.004), V2(0.286, 0.0)]
        m.add(Prim.lathe(inner, segments: 48, seamTile: 0.6, material: "metal.painted:ECEBE5").flipped(), Xform(translation: V3(0, 0, zs)))
        m.add(Prim.torus(major: 0.2955, minor: 0.0045, segments: 48, sides: 8, material: shade), Xform(translation: V3(0, 0.004, zs)))
        m.add(Prim.torus(major: 0.2975, minor: 0.0035, segments: 48, sides: 8, material: shade), Xform(translation: V3(0, 0.052, zs)))
        FSV.streak(&m, at: V3(0.0, 0.056, zs + 0.301), w: 0.02, h: 0.048, rust)
        for k in 0..<6 {
            let a = rng.float(0...6.28)
            FA.box(&m, V3(rng.float(0.012...0.03), rng.float(0.008...0.02), 0.0014), V3(0.299 * cos(a), rng.float(0.01...0.045), zs + 0.299 * sin(a)), rust, r: 0.0004, rot: FA.q(-a * 57.3 + 90, FA.Y))
            _ = k
        }
        // Socket nut and gasket where the arm enters, lock-nut hex and bulb socket under the dome.
        m.add(Prim.lathe([V2(0, 0.205), V2(0.034, 0.205), V2(0.034, 0.215), V2(0.028, 0.222), V2(0.0, 0.224)], segments: 24, seamTile: 0.2, material: coat), Xform(translation: V3(0, 0, zs)))
        m.add(Prim.extrude(Shape2D.polygon(sides: 6, radius: 0.04), depth: 0.014, bevel: 0.0016, bevelSegments: 1, material: coat),
              Xform(translation: V3(0, 0.2315, zs), rotation: FA.q(-90, FA.X)))
        m.add(Prim.lathe([V2(0, 0.22), V2(0.026, 0.22), V2(0.026, 0.17), V2(0.032, 0.17), V2(0.032, 0.14), V2(0.0, 0.14)], segments: 18, seamTile: 0.2, material: "ceramic.vitreous"), Xform(translation: V3(0, 0, zs)))
        FSV.cyl(&m, V3(0, 0.145, zs), V3(0, 0.125, zs), r: 0.0155, "metal.brass", bevel: 0.001, segments: 14)
        m.add(Prim.lathe([V2(0, 0.125), V2(0.03, 0.12), V2(0.045, 0.1), V2(0.046, 0.075), V2(0.036, 0.05), V2(0.012, 0.04), V2(0, 0.04)], segments: 22, seamTile: 0.2, material: "emissive.warm"),
              Xform(translation: V3(0, 0, zs)))
        return LODModel(FC.seatY(m))
    }
}
