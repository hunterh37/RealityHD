import simd
import Foundation

/// Steel Water Bottle: everyday school, steel. Parts: powder-coated steel body, steel base ring, screw cap with ribs, carry loop, seal ring, grip bands.
public struct WaterBottleSteel: RealAsset {
    public static let id = "water-bottle-steel"
    public static let summary = "Insulated steel bottle with a powder-coated body, ribbed screw cap and carry loop."
    public static let tags = ["prop", "interior", "school", "metal"]
    public static let budget = 9000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.07, 0.25, 0.07)
    public init() {}

        public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        let paint = "metal.powdercoat:2F6F8F", sc: Float = 0.935
        // Brushed steel base ring, then the painted body lathed with shoulder and neck.
        m.add(Prim.cylinder(radius: 0.0345, height: 0.014, bevel: 0.003, segments: 40, material: "metal.stainless"), Xform())
        let prof: [V2] = [V2(0.0345, 0.013), V2(0.0352, 0.020), V2(0.0352, 0.180), V2(0.0338, 0.196), V2(0.0285, 0.206), V2(0.0215, 0.2135), V2(0.0192, 0.2185), V2(0.0192, 0.224)]
        m.add(Prim.lathe(prof.map { V2($0.x, $0.y * sc) }, segments: 40, seamTile: 0.2, material: paint), Xform())
        // Grip bands and a lighter wear scuff low on the body.
        for y: Float in [0.060, 0.066, 0.072] {
            m.add(Prim.torus(major: 0.0353, minor: 0.0007, segments: 40, sides: 6, material: "metal.powdercoat:276080"), Xform(translation: V3(0, y, 0)))
        }
        m.add(Prim.roundedBox(V3(0.012, 0.0006, 0.0004), radius: 0.0001, bevelSegments: 1, material: "metal.stainless"),
              Xform(translation: V3(0.0, 0.032, 0.0354), rotation: simd_quatf(degrees: 12, axis: V3(0, 0, 1))))
        // Seal ring between neck and cap, then the ribbed screw cap with a top disc.
        m.add(Prim.torus(major: 0.0205, minor: 0.0012, segments: 32, sides: 6, material: "plastic.matte:1A1A1A"), Xform(translation: V3(0, 0.2255 * sc, 0)))
        m.add(Prim.cylinder(radius: 0.0225, height: 0.028, bevel: 0.003, segments: 32, material: "plastic.matte:25282B"), Xform(translation: V3(0, 0.2265 * sc, 0)))
        for k in 0..<28 {
            let a = Float.pi * 2 * Float(k) / 28
            m.add(Prim.roundedBox(V3(0.0016, 0.020, 0.0012), radius: 0.0004, bevelSegments: 1, material: "plastic.matte:25282B"),
                  Xform(translation: V3(0.0226 * cos(a), 0.2405 * sc, 0.0226 * sin(a)), rotation: simd_quatf(degrees: -a * 180 / .pi, axis: V3(0, 1, 0))))
        }
        // Carry loop: arched strap on top of the cap.
        var arc: [V3] = []
        for k in 0...14 { let a = Float.pi * Float(k) / 14; arc.append(V3(-0.0145 * cos(a), 0.2565 * sc + 0.011 * sin(a), 0)) }
        m.add(Prim.tube(arc, radii: Array(repeating: 0.0022, count: arc.count), sides: 8, seamTile: 0.04, material: "plastic.matte:25282B"), Xform())
        groundAO(&m)
        return LODModel(m)
    }
}
