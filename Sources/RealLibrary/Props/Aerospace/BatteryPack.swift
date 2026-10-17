import simd
import Foundation

/// Li-ion flight battery pack, 0.4 x 0.3 x 0.2 m (2.5 kWh class). A black anodized aluminium case with
/// vertical cooling ribs on the long sides sits on two bolted mounting flanges; a brushed aluminium lid
/// is screwed down around its edge and carries a folding-style carry handle and a pressure vent. The
/// front face holds two orange HV connectors, a grey signal connector and a hazard label.
public struct BatteryPack: RealAsset {
    public static let id = "battery-pack"
    public static let summary = "Li-ion flight battery pack, 0.4 x 0.3 x 0.2 m: ribbed black anodized aluminium case with bolted lid, mounting flanges, HV connectors and a warning label."
    public static let tags = ["prop", "aerospace", "electronics", "metal"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 24, distance: 1.1, studio: true)

    /// Case size (m): x length, y height to the lid top, z depth.
    public var size = V3(0.4, 0.2, 0.3)
    public var body: MaterialKey = "metal.anodized-black"
    public var lid: MaterialKey = "metal.aluminum-brushed"
    public var fastener: MaterialKey = "metal.steel"
    /// HV connector shell colour (sRGB hex).
    public var hvColor: UInt32 = 0xE8641B
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let W = size.x - 0.03, H = size.y, D = size.z - 0.03
        let flangeH: Float = 0.008, lidH: Float = 0.014
        let hv: MaterialKey = "plastic.matte:" + String(format: "%06X", hvColor)
        var levels: [Model] = []
        for l in 0..<2 {
            var m = Model(name: Self.id)
            let bs = l == 0 ? 3 : 1
            // Mounting flanges along X under the case ends.
            for s: Float in [-1, 1] {
                m.add(Prim.roundedBox(V3(0.05, flangeH, D + 0.03), radius: 0.003, bevelSegments: bs, material: body),
                      Xform(translation: V3(s * (W / 2 - 0.02), flangeH / 2, 0)))
                if l == 0 {
                    for z: Float in [-1, 1] { hexBolt(&m, at: V3(s * (W / 2 - 0.02), flangeH, z * (D / 2 + 0.006)), normal: .up, size: 0.006, material: fastener) }
                }
            }
            // Case body.
            let bodyH = H - lidH - flangeH
            m.add(Prim.roundedBox(V3(W, bodyH, D), radius: 0.008, bevelSegments: bs, material: body),
                  Xform(translation: V3(0, flangeH + bodyH / 2, 0)))
            // Cooling ribs on the long sides (+/-Z).
            if l == 0 {
                for s: Float in [-1, 1] {
                    for k in 0..<11 {
                        let x = -W / 2 + 0.04 + Float(k) * (W - 0.08) / 10
                        m.add(Prim.roundedBox(V3(0.006, bodyH - 0.03, 0.012), radius: 0.0025, bevelSegments: 1, material: body),
                              Xform(translation: V3(x, flangeH + bodyH / 2, s * (D / 2 + 0.005))))
                    }
                }
            }
            // Lid: brushed plate with an overhanging lip, screws around the edge.
            let lidY = flangeH + bodyH
            m.add(Prim.roundedBox(V3(W + 0.006, lidH, D + 0.006), radius: 0.005, bevelSegments: bs, material: lid),
                  Xform(translation: V3(0, lidY + lidH / 2, 0)))
            if l == 0 {
                var pts: [V3] = []
                for k in 0..<6 { let x = -W / 2 + 0.02 + Float(k) * (W - 0.04) / 5; pts += [V3(x, H, -D / 2 + 0.012), V3(x, H, D / 2 - 0.012)] }
                for k in 1..<4 { let z = -D / 2 + 0.012 + Float(k) * (D - 0.024) / 4; pts += [V3(-W / 2 + 0.012, H, z), V3(W / 2 - 0.012, H, z)] }
                for p in pts { rivet(&m, at: p, normal: .up, radius: 0.0035, segments: 6, material: fastener) }
                // Carry handle across the lid.
                m.add(barHandle(length: 0.16, standoff: 0.03, radius: 0.0055, material: "metal.anodized-black"),
                      Xform(translation: V3(0, H, 0), rotation: simd_quatf(angle: -.pi / 2, axis: V3(1, 0, 0))))
                // Pressure vent: round boss with a slotted cap.
                m.add(Prim.cylinder(radius: 0.016, height: 0.006, bevel: 0.0015, segments: 20, material: "plastic.matte:2A2C2E"),
                      Xform(translation: V3(W / 2 - 0.06, H, D / 2 - 0.06)))
                // Front face (+X): HV connectors, signal connector, label.
                for (k, z) in [Float(-0.07), 0.0].enumerated() {
                    let c = V3(W / 2, flangeH + bodyH * 0.55, z)
                    let rx = simd_quatf(angle: -.pi / 2, axis: V3(0, 0, 1))
                    m.add(Prim.roundedBox(V3(0.006, 0.07, 0.06), radius: 0.004, bevelSegments: 2, material: body),
                          Xform(translation: c + V3(0.003, 0, 0)))
                    m.add(Prim.cylinder(radius: 0.022, height: 0.032, bevel: 0.003, segments: 24, material: hv),
                          Xform(translation: c + V3(0.004, 0, 0), rotation: rx))
                    m.add(Prim.cylinder(radius: 0.015, height: 0.006, bevel: 0.0015, segments: 20, material: "plastic.black"),
                          Xform(translation: c + V3(0.034, 0, 0), rotation: rx))
                    for d: Float in [-1, 1] { rivet(&m, at: c + V3(0.006, d * 0.028, d * 0.024), normal: V3(1, 0, 0), radius: 0.003, segments: 6, material: fastener) }
                    _ = k
                }
                let sc = V3(W / 2, flangeH + bodyH * 0.55, 0.075)
                m.add(Prim.cylinder(radius: 0.013, height: 0.024, bevel: 0.002, segments: 18, material: "metal.anodized:8A8F94"),
                      Xform(translation: sc, rotation: simd_quatf(angle: -.pi / 2, axis: V3(0, 0, 1))))
                m.add(Prim.roundedBox(V3(0.0008, 0.045, 0.1), radius: 0.0003, bevelSegments: 1, material: "label.hazard"),
                      Xform(translation: V3(W / 2 + 0.0004, flangeH + bodyH * 0.2, 0.02)))
                // Serial label on the back face, slightly askew.
                m.add(Prim.roundedBox(V3(0.0008, 0.04, 0.08), radius: 0.0003, bevelSegments: 1, material: "label.inspection"),
                      Xform(translation: V3(-W / 2 - 0.0004, flangeH + bodyH * 0.6, 0.03), rotation: simd_quatf(angle: rng.float(-0.04...0.04), axis: V3(1, 0, 0))))
            }
            groundAO(&m, height: 0.06, floor: 0.6)
            levels.append(m)
        }
        return LODModel(levels: levels, switchDistances: [4])
    }
}
