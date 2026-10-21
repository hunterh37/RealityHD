import simd
import Foundation

/// Ceiling smoke alarm, Ø130 mm, authored in place: the base touches the ceiling plane at y = 2.6 and the domed
/// cover hangs 40 mm below it. Mounting ring with a seam line, domed cover with a ring of radial sensing vent
/// slots, recessed center test button and a status LED.
public struct SmokeDetector: RealAsset {
    public static let id = "smoke-detector"
    public static let summary = "Ceiling smoke alarm: white domed cover with radial sensing vents, test button, status LED and mounting ring."
    public static let tags = ["prop", "floorplan", "interior", "ceiling", "electronics", "plastic"]
    public static let budget = 2800
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: -35, distance: 0.7, ground: false, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.13, 0.04, 0.13)
    /// Ceiling plane height (m).
    public var ceilingY: Float = 2.6
    /// Cover plastic.
    public var plastic: MaterialKey = "plastic.matte:F2F0EA"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        let top = ceilingY, R = size.x / 2, D = size.y - 0.0015
        func make(_ lod: Int) -> Model {
            var m = Model(name: Self.id)
            let seg = lod == 0 ? 40 : 20
            // Mounting ring (flush with the ceiling) and the cover dome. Profile runs bottom to top for outward normals,
            // so it is listed from the center of the cover up to the ceiling.
            let dome: [V2] = [V2(0, top - D), V2(0.022, top - D + 0.0005), V2(0.04, top - D + 0.004), V2(0.054, top - D + 0.012),
                              V2(0.0605, top - D + 0.02), V2(0.0635, top - D + 0.028), V2(0.0645, top - 0.011)]
            m.add(Prim.lathe(Profile.smooth(dome, per: lod == 0 ? 2 : 1), segments: seg, seamTile: 0.2, material: plastic))
            m.add(Prim.lathe([V2(R - 0.003, top - 0.011), V2(R, top - 0.0095), V2(R, top - 0.002), V2(R - 0.0015, top), V2(0, top)], segments: seg, seamTile: 0.2, material: plastic))
            // Radial sensing slots on the shoulder of the dome.
            if lod == 0 {
                for k in 0..<28 {
                    let a = Float(k) * 2 * .pi / 28
                    let dir = V3(cos(a), 0, -sin(a))
                    let c = dir * 0.0552 + V3(0, top - D + 0.0128, 0)
                    let q = simd_quatf(angle: a, axis: .up) * simd_quatf(degrees: 48, axis: V3(0, 0, 1))
                    m.add(cuboid(V3(0.0075, 0.0007, 0.0045), material: "plastic.black"), Xform(translation: c, rotation: q))
                }
            }
            // Center test button: recessed ring and a raised matte disc with a ridge.
            m.add(Prim.lathe([V2(0.0205, top - D + 0.0006), V2(0.0215, top - D - 0.0004), V2(0.0215, top - D - 0.0008)], segments: seg, seamTile: 0.1, material: "plastic.black"))
            m.add(Prim.cylinder(radius: 0.0185, height: 0.0014, bevel: 0.0005, segments: lod == 0 ? 28 : 14, bevelSegments: 1, material: plastic), Xform(translation: V3(0, top - D - 0.0012, 0)))
            // Inspection sticker on the dome shoulder opposite the LED.
            if lod == 0 {
                m.add(cuboid(V3(0.02, 0.0004, 0.014), material: "label.inspection"), Xform(translation: V3(-0.033, top - D + 0.0014, 0.0), rotation: simd_quatf(degrees: -12, axis: V3(0, 0, 1))))
            }
            // Status LED and a seam line where cover meets ring.
            if lod == 0 {
                m.add(Prim.cylinder(radius: 0.0026, height: 0.0014, bevel: 0.0004, segments: 10, bevelSegments: 1, material: "emissive.led-green"),
                      Xform(translation: V3(0.034, top - D + 0.0024, 0.0)))
                m.add(Prim.torus(major: 0.0643, minor: 0.00055, segments: 48, sides: 4, material: "plastic.black"), Xform(translation: V3(0, top - 0.0112, 0)))
            }
            return m
        }
        return LODModel(levels: [make(0), make(1)], switchDistances: [4])
    }
}
