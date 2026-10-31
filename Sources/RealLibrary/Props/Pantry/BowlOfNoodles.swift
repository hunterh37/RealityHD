import simd
import Foundation

/// BowlOfNoodles: everyday pantry, pantry. Real-size 0.20 x 0.09 x 0.20 m.
public struct BowlOfNoodles: RealAsset {
    public static let id = "bowl-of-noodles"
    public static let summary = "BowlOfNoodles, 0.20 x 0.09 x 0.20 m, pantry prop with real proportions and surface detail."
    public static let tags = ["prop", "interior", "pantry", "food", "pantry"]
    public static let budget = 10000
    public static let author = "realityhd"

    /// Skin material key.
    public var skin: MaterialKey = "ceramic.stoneware:EDE8DC"
    /// Accent (stem, leaf, secondary) material key.
    public var accent: MaterialKey = "food.pasta-cooked:E8D08A"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
func bowl(_ pts: [V2], _ mat: MaterialKey) -> Surface {
            FoodMesh.revolve(edge: 0.014, seamTile: 0.08, material: mat, curve: FoodMesh.profile(pts, per: 4))
        }
        m.add(bowl([V2(0, 0), V2(0.05, 0), V2(0.058, 0.008), V2(0.085, 0.04), V2(0.1, 0.078), V2(0.1, 0.08), V2(0.096, 0.08), V2(0.082, 0.04), V2(0.052, 0.016), V2(0, 0.014)], skin))
        m.add(FoodMesh.revolve(edge: 0.014, seamTile: 0.08, material: "food.stock:C98B3E", curve: FoodMesh.profile([V2(0, 0.06), V2(0.076, 0.06), V2(0.078, 0.062), V2(0, 0.063)], per: 2)))
        for n in 0..<16 {
            let a0 = rng.float(0...6.28), off = rng.float(-0.04...0.04), ph = rng.float(0...6.28), y0 = 0.062 + rng.float(0...0.012)
            var path: [V3] = []
            for j in 0...14 {
                let t = Float(j) / 14
                let lx = -0.068 + 0.136 * t, lz = off + 0.02 * sin(t * 8 + ph)
                path.append(V3(lx * cos(a0) - lz * sin(a0), y0 + 0.004 * sin(t * 6 + ph * 2), lx * sin(a0) + lz * cos(a0)))
            }
            m.add(FoodMesh.tube(path, radii: Array(repeating: 0.0022, count: path.count), sides: 5, endBulge: 0.5, seamTile: 0.01, material: accent))
        }
        for s: Float in [-1, 1] {
            m.add(Prim.superellipsoid(V3(0.044, 0.026, 0.05), exponent: 2, subdivisions: 7, material: "food.egg-white-cooked"), Xform(translation: V3(s * 0.026, 0.075, 0.032), rotation: simd_quatf(degrees: s * 20, axis: V3(0, 1, 0))))
            m.add(Prim.superellipsoid(V3(0.02, 0.012, 0.02), exponent: 2, subdivisions: 6, material: "food.egg-yolk-cooked"), Xform(translation: V3(s * 0.026, 0.087, 0.032)))
        }
        for _ in 0..<14 {
            let c = rng.inDisc(radius: 0.06)
            m.add(Prim.cylinder(radius: 0.0045, height: 0.0025, bevel: 0.0005, segments: 8, material: "food.scallion-green"), Xform(translation: V3(c.x, 0.078, c.y - 0.01)))
        }
        m.add(Prim.roundedBox(V3(0.05, 0.03, 0.0018), radius: 0.0006, bevelSegments: 1, material: "plastic.matte:16241A"), Xform(translation: V3(0.0, 0.075, -0.058), rotation: simd_quatf(degrees: -14, axis: V3(1, 0, 0))))
        groundAO(&m, height: 0.01, floor: 0.6)
        return LODModel(m)
    }
}
