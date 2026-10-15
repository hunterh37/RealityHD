import simd
import Foundation

/// Wall-mounted three-light vanity bar. Authored with its lowest point at y = 0 and its back face at z = -0.06;
/// the planner lifts it to 1.8 m. Brushed nickel back plate with a cross bar and arms, three frosted glass
/// cylinder shades with cap collars and bulbs, two visible mounting screws.
public struct VanityLightBar: RealAsset {
    public static let id = "vanity-light-bar"
    public static let summary = "Wall vanity light bar: brushed nickel back plate and arms, three clear glass cylinder shades with bulbs."
    public static let tags = ["prop", "floorplan", "interior", "light", "metal", "glass", "wall"]
    public static let budget = 3800
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 12, distance: 1.1, ground: false, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.6, 0.12, 0.12)
    /// Hardware finish.
    public var metal: MaterialKey = "metal.brushed-nickel"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        let back = -size.z / 2
        let H = size.y
        let R: Float = 0.042
        let T = H - 0.0105                          // shade top; the acorn nut reaches H
        let sz: Float = back + size.z - R - 0.0025            // shade axis z so the front reaches +depth/2
        func make(_ lod: Int) -> Model {
            var m = Model(name: Self.id)
            let seg = lod == 0 ? 24 : 12
            // Back plate with rolled edges and a raised center boss.
            m.add(lod == 0 ? Prim.roundedBox(V3(size.x, 0.034, 0.012), radius: 0.004, bevelSegments: 2, material: metal) : cuboid(V3(size.x, 0.034, 0.012), material: metal),
                  Xform(translation: V3(0, H / 2, back + 0.006)))
            m.add(cuboid(V3(size.x - 0.06, 0.012, 0.0045), material: metal), Xform(translation: V3(0, H / 2, back + 0.014)))
            for s in [-1, 1] as [Float] {
                rivet(&m, at: V3(s * 0.27, H / 2, back + 0.012), normal: V3(0, 0, 1), radius: 0.0045, segments: 8, material: "metal.chrome")
            }
            let barY = H / 2, barZ = back + 0.03
            for x in [-0.215, 0, 0.215] as [Float] {
                m.add(Prim.tube([V3(x, barY, back + 0.012), V3(x, barY, sz - R * 0.5)], radii: [0.0085, 0.0085], sides: lod == 0 ? 8 : 5, seamTile: 0.04, material: metal))
                // Socket cup holding the shade: bottom collar and top cap.
                m.add(Prim.lathe([V2(R - 0.0045, 0), V2(R + 0.0025, 0.0), V2(R + 0.0025, 0.016), V2(R - 0.0005, 0.018), V2(R - 0.0045, 0.018), V2(R - 0.0045, 0.016)], segments: seg, seamTile: 0.1, material: metal), Xform(translation: V3(x, 0, sz)))
                m.add(Prim.lathe([V2(0, T - 0.016), V2(R - 0.0045, T - 0.016), V2(R + 0.0025, T - 0.016), V2(R + 0.0025, T - 0.004), V2(R - 0.0025, T), V2(0, T)], segments: seg, seamTile: 0.1, material: metal), Xform(translation: V3(x, 0, sz)))
                // Frosted glass cylinder: outer and inner skins plus rolled lip.
                let g: [V2] = [V2(R - 0.0012, 0.016), V2(R - 0.0012, T - 0.016)]
                m.add(Prim.lathe(g, segments: seg, seamTile: 0.12, material: "glass.clear"), Xform(translation: V3(x, 0, sz)))
                m.add(Prim.lathe(g.reversed().map { V2($0.x - 0.0016, $0.y) }, segments: seg, seamTile: 0.12, material: "glass.clear"), Xform(translation: V3(x, 0, sz)))
                // Bulb on a candelabra socket, visible through the frosted glass.
                m.add(Prim.lathe([V2(0, 0.058), V2(0.0085, 0.058), V2(0.0085, T - 0.016), V2(0, T - 0.016)], segments: 10, seamTile: 0.03, material: metal), Xform(translation: V3(x, 0, sz)))
                if lod == 0 {
                    // Acorn nut on the cap and a set screw on the lower collar.
                    m.add(Prim.lathe(Profile.smooth([V2(0, T), V2(0.011, T), V2(0.0105, T), V2(0.0095, T + 0.006), V2(0.005, T + 0.0095), V2(0, T + 0.0105)], per: 1), segments: 12, seamTile: 0.03, material: "metal.chrome"), Xform(translation: V3(x, 0, sz)))
                }
                m.add(Prim.superellipsoid(V3(0.036, 0.05, 0.036), exponent: 2, subdivisions: lod == 0 ? 4 : 2, material: "glass.frosted"), Xform(translation: V3(x, 0.034, sz)))
                m.add(Prim.superellipsoid(V3(0.012, 0.026, 0.012), exponent: 2, subdivisions: lod == 0 ? 3 : 2, material: "emissive.bulb"), Xform(translation: V3(x, 0.036, sz)))
            }
            return m
        }
        return LODModel(levels: [make(0), make(1)], switchDistances: [5])
    }
}
