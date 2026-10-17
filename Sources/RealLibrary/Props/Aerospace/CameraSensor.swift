import simd
import Foundation

/// Machine vision camera module, about 0.1 m: a black anodized housing with heat-sink fins on top sits on
/// a mounting plate; a brushed aluminium lens barrel with a grip ring and a short sun hood faces +Z, and
/// a locking M12 connector exits the back. A small status LED sits beside the connector.
public struct CameraSensor: RealAsset {
    public static let id = "camera-sensor"
    public static let summary = "Machine vision camera, 0.1 m cube: finned black anodized housing with a lens barrel, sun hood and locking connector."
    public static let tags = ["prop", "aerospace", "electronics"]
    public static let budget = 8000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 34, elevation: 20, distance: 1.1, studio: true)

    /// Housing size (m).
    public var housing = V3(0.07, 0.06, 0.07)
    /// Lens barrel radius and length (m).
    public var lensRadius: Float = 0.021
    public var lensLength: Float = 0.04
    public var body: MaterialKey = "metal.anodized-black"
    public var barrel: MaterialKey = "metal.aluminum-brushed"
    public var glass: MaterialKey = "glass.led-lens:1E2A3C"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let H = housing, plateH: Float = 0.006
        let cy = plateH + H.y / 2
        let toZ = simd_quatf(angle: .pi / 2, axis: V3(1, 0, 0))       // lathe +Y -> +Z
        let zf = H.z / 2 - 0.02                                        // housing front face, lens axis centre
        var levels: [Model] = []
        for l in 0..<2 {
            var m = Model(name: Self.id)
            let bs = l == 0 ? 2 : 1, sg = l == 0 ? 40 : 16
            // Mounting plate.
            m.add(Prim.roundedBox(V3(H.x + 0.016, plateH, H.z - 0.01), radius: 0.002, bevelSegments: bs, material: body),
                  Xform(translation: V3(0, plateH / 2, -0.02)))
            // Housing.
            m.add(Prim.roundedBox(V3(H.x, H.y, H.z), radius: 0.005, bevelSegments: bs, material: body),
                  Xform(translation: V3(0, cy, zf - H.z / 2)))
            // Heat fins on top.
            for k in 0..<7 {
                let x = -H.x / 2 + 0.008 + Float(k) * (H.x - 0.016) / 6
                m.add(Prim.roundedBox(V3(0.003, 0.012, H.z - 0.012), radius: 0.001, bevelSegments: 1, material: body),
                      Xform(translation: V3(x, plateH + H.y + 0.005, zf - H.z / 2)))
            }
            // Lens: mount ring, barrel with grip ring, sun hood, glass.
            let ly = cy - 0.003
            m.add(Prim.lathe([V2(lensRadius + 0.006, 0), V2(lensRadius + 0.006, 0.006), V2(lensRadius + 0.002, 0.008), V2(lensRadius, 0.008),
                              V2(lensRadius, lensLength * 0.45), V2(lensRadius + 0.003, lensLength * 0.47), V2(lensRadius + 0.003, lensLength * 0.7),
                              V2(lensRadius, lensLength * 0.72), V2(lensRadius, lensLength), V2(lensRadius - 0.003, lensLength)],
                             segments: sg, seamTile: 0.05, material: barrel), Xform(translation: V3(0, ly, zf), rotation: toZ))
            if l == 0 {
                // Knurl ribs on the grip ring.
                for k in 0..<24 {
                    let a = Float(k) / 24 * 2 * .pi
                    m.add(Prim.roundedBox(V3(0.0015, 0.0012, lensLength * 0.2), radius: 0.0004, bevelSegments: 1, material: barrel),
                          Xform(translation: V3(cos(a) * (lensRadius + 0.0035), ly + sin(a) * (lensRadius + 0.0035), zf + lensLength * 0.585),
                                rotation: simd_quatf(angle: a, axis: V3(0, 0, 1))))
                }
            }
            m.add(Prim.lathe([V2(lensRadius - 0.001, 0), V2(lensRadius + 0.004, 0.003), V2(lensRadius + 0.007, 0.018), V2(lensRadius + 0.005, 0.019),
                              V2(lensRadius + 0.002, 0.004), V2(lensRadius - 0.004, 0.002)], segments: sg, seamTile: 0.05, material: body),
                  Xform(translation: V3(0, ly, zf + lensLength - 0.002), rotation: toZ))
            m.add(Prim.lathe([V2(lensRadius - 0.003, 0), V2(lensRadius * 0.6, 0.002), V2(0, 0.003)], segments: sg, seamTile: 0.05, material: glass),
                  Xform(translation: V3(0, ly, zf + lensLength - 0.006), rotation: toZ))
            if l == 0 {
                // M12 connector at the back with a cable stub, status LED, mounting screws.
                let back = zf - H.z
                m.add(Prim.cylinder(radius: 0.008, height: 0.016, bevel: 0.0015, segments: 18, material: "metal.anodized:9AA0A6"),
                      Xform(translation: V3(-0.012, cy - 0.01, back), rotation: simd_quatf(angle: -.pi / 2, axis: V3(1, 0, 0))))
                let cable = catmull([V3(-0.012, cy - 0.01, back - 0.014), V3(-0.012, cy - 0.016, back - 0.03), V3(-0.01, plateH + 0.004, back - 0.042)], per: 5)
                m.add(Prim.tube(cable, radii: cable.map { _ in 0.0042 }, sides: 8, seamTile: 0.03, material: "rubber", capEnd: true))
                m.add(Prim.cylinder(radius: 0.0025, height: 0.002, bevel: 0.0005, segments: 10, material: "emissive.led-green"),
                      Xform(translation: V3(0.018, cy + 0.015, back), rotation: simd_quatf(angle: -.pi / 2, axis: V3(1, 0, 0))))
                for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
                    hexBolt(&m, at: V3(sx * (H.x / 2 + 0.004), plateH, -0.02 + sz * (H.z / 2 - 0.016)), normal: .up, size: 0.0035, material: "metal.steel")
                } }
                m.add(Prim.roundedBox(V3(0.0008, 0.016, 0.036), radius: 0.0003, bevelSegments: 1, material: "label.inspection"),
                      Xform(translation: V3(H.x / 2 + 0.0004, cy, zf - H.z / 2), rotation: simd_quatf(angle: rng.float(-0.04...0.04), axis: V3(1, 0, 0))))
            }
            groundAO(&m, height: 0.03, floor: 0.6)
            levels.append(m)
        }
        return LODModel(levels: levels, switchDistances: [3])
    }
}
