import simd
import Foundation

/// 55 in LED television on two outrigger feet, 123 x 78 x 26 cm, powered off: 12 mm black panel body under a
/// glass front, thin metal chin strip with logo plate and a standby LED, a rear chassis bulge with vent
/// slots, input ports and four VESA 200 x 200 screws, brushed black-metal feet with necks, and a power cord
/// lying behind the right foot.
public struct FlatTv: RealAsset {
    public static let id = "flat-tv"
    public static let summary = "55 in LED flat-screen TV on two outrigger feet: thin bezel, powered-off glass, ribbed rear chassis, ports, VESA screws and power cord."
    public static let tags = ["prop", "floorplan", "living", "electronics", "plastic", "interior"]
    public static let budget = 8500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 10, distance: 2.0, studio: true)

    /// Panel width and height in meters (active display plus bezel).
    public var panel = V2(1.227, 0.71)
    /// Height of the panel bottom edge above the floor (foot height).
    public var footHeight: Float = 0.07
    /// Chassis color tint.
    public var bodyColor = "151517"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [model(seed: seed, detail: true), model(seed: seed, detail: false)], switchDistances: [5])
    }

    func model(seed: UInt64, detail: Bool) -> Model {
        var m = Model(name: Self.id)
        let PW = panel.x, PH = panel.y, y0 = footHeight
        let yc = y0 + PH / 2
        let body: MaterialKey = "plastic.matte:\(bodyColor)"
        let rear: MaterialKey = "plastic.matte:1C1C1F"
        let metal: MaterialKey = "metal.anodized-black"
        let seg = detail ? 2 : 1
        let footMetal: MaterialKey = "metal.anodized-worn:34343A"

        // Panel body: 13 mm black shell (z -0.007 ... 0.006), front glass 1.5 mm proud of it.
        m.add(Prim.roundedBox(V3(PW, PH, 0.013), radius: 0.0035, bevelSegments: seg, material: body), Xform(translation: V3(0, yc, -0.0005)))
        // Brushed black-metal front bezel, then the active glass inset 7 mm at the sides and top, 16 mm at the chin.
        m.add(Prim.roundedBox(V3(PW - 0.002, PH - 0.002, 0.0018), radius: 0.0007, bevelSegments: 1, material: "metal.satin-aluminum:55555B"),
              Xform(translation: V3(0, yc, 0.0069)))
        let gw = PW - 0.014, gh = PH - 0.023
        m.add(Prim.roundedBox(V3(gw, gh, 0.0012), radius: 0.0004, bevelSegments: 1, material: "screen.off:0D0F14"),
              Xform(translation: V3(0, y0 + 0.016 + gh / 2, 0.0083)))
        // Thin metal edge band around the panel, 2 mm.
        m.add(Prim.roundedBox(V3(PW + 0.0008, PH + 0.0008, 0.0022), radius: 0.0006, bevelSegments: 1, material: metal), Xform(translation: V3(0, yc, -0.004)))
        // Chin strip and logo plate, standby LED.
        m.add(Prim.roundedBox(V3(PW - 0.02, 0.0025, 0.0004), radius: 0.0008, bevelSegments: 1, material: "plastic.matte:0C0C0E"), Xform(translation: V3(0, y0 + 0.008, 0.0079)))
        m.add(Prim.roundedBox(V3(0.05, 0.0035, 0.0006), radius: 0.0003, bevelSegments: 1, material: "metal.aluminum-brushed"), Xform(translation: V3(0, y0 + 0.008, 0.0083)))
        m.add(Prim.cylinder(radius: 0.0016, height: 0.0008, bevel: 0.0004, segments: 8, bevelSegments: 1, material: "emissive.led-red"),
              Xform(translation: V3(PW / 2 - 0.06, y0 + 0.008, 0.0082), rotation: facing(V3(0, 0, 1))))

        // Joystick button and IR window under the chin, right of center.
        m.add(Prim.cylinder(radius: 0.0035, height: 0.0014, bevel: 0.0006, segments: 10, bevelSegments: 1, material: "plastic.black"),
              Xform(translation: V3(-PW / 2 + 0.15, y0 + 0.002, -0.004), rotation: facing(V3(0, -1, 0))))
        m.add(cuboid(V3(0.012, 0.0014, 0.0035), material: "plastic.black"), Xform(translation: V3(PW / 2 - 0.15, y0 + 0.0008, 0.0)))
        // Rear: shell bulge (70 x 38 cm) with a thinner back plate; the lower edge sits a little below center.
        let by = yc - 0.04
        m.add(Prim.roundedBox(V3(0.72, 0.4, 0.04), radius: 0.012, bevelSegments: seg + 1, material: rear), Xform(translation: V3(0, by, -0.027)))
        m.add(Prim.roundedBox(V3(0.56, 0.31, 0.014), radius: 0.006, bevelSegments: seg, material: body), Xform(translation: V3(0, by + 0.01, -0.054)))
        // Rear half-moon sides: ribs under the bulge shoulders.
        if detail {
            for s: Float in [-1, 1] {
                for k in 0..<3 {
                    m.add(Prim.roundedBox(V3(0.012, 0.3, 0.012), radius: 0.003, bevelSegments: 1, material: rear),
                          Xform(translation: V3(s * (0.3 + Float(k) * 0.03), by, -0.0105)))
                }
            }
            // Vent slots on the back plate.
            let slot = cuboid(V3(0.028, 0.0028, 0.0008), material: "plastic.black")
            var slots = Surface(material: "plastic.black")
            for row in 0..<3 {
                for k in 0..<14 {
                    let x = (Float(k) - 6.5) * 0.034
                    slots.append(slot, Xform(translation: V3(x, by + 0.13 + Float(row) * 0.012, -0.0614)))
                }
            }
            m.add(slots)
            // VESA 200 x 200 screws, cross-head zinc.
            for sx: Float in [-1, 1] { for sy: Float in [-1, 1] {
                let p = V3(sx * 0.1, yc + sy * 0.1 - 0.0, -0.0615)
                m.add(Prim.cylinder(radius: 0.0045, height: 0.0014, bevel: 0.0005, segments: 10, bevelSegments: 1, material: "metal.screw-zinc"),
                      Xform(translation: p, rotation: facing(V3(0, 0, -1))))
                m.add(cuboid(V3(0.005, 0.0008, 0.0006), material: "plastic.black"), Xform(translation: p + V3(0, 0, -0.0015)))
                m.add(cuboid(V3(0.0008, 0.005, 0.0006), material: "plastic.black"), Xform(translation: p + V3(0, 0, -0.0015)))
            } }
        }
        // Bottom speaker slots along the lower rear edge of the shell, 40 slots.
        if detail {
            var spk = Surface(material: "plastic.black")
            let slit = cuboid(V3(0.008, 0.0012, 0.0006), material: "plastic.black")
            for k in 0..<40 {
                spk.append(slit, Xform(translation: V3((Float(k) - 19.5) * 0.0205, y0 + 0.0004, -0.0072)))
            }
            m.add(spk)
        }
        // Input bay on the back plate, left: black recess with HDMI, USB, antenna and optical ports.
        let bayX: Float = -0.18, bayY = yc - 0.065, bayZ: Float = -0.0616
        m.add(Prim.roundedBox(V3(0.16, 0.06, 0.003), radius: 0.001, bevelSegments: 1, material: "plastic.black"), Xform(translation: V3(bayX, bayY, bayZ - 0.0005)))
        for k in 0..<4 {
            let x = bayX - 0.055 + Float(k) * 0.027
            m.add(cuboid(V3(0.0155, 0.0065, 0.004), material: "metal.aluminum-brushed"), Xform(translation: V3(x, bayY + 0.012, bayZ - 0.0012)))
            m.add(cuboid(V3(0.012, 0.0035, 0.0045), material: "plastic.black"), Xform(translation: V3(x, bayY + 0.012, bayZ - 0.0013)))
        }
        m.add(Prim.cylinder(radius: 0.0055, height: 0.006, bevel: 0.001, segments: 14, bevelSegments: 1, material: "metal.brass-aged"),
              Xform(translation: V3(bayX + 0.055, bayY - 0.012, bayZ - 0.001), rotation: facing(V3(0, 0, -1))))
        m.add(cuboid(V3(0.022, 0.012, 0.003), material: "plastic.matte:2A2A2E"), Xform(translation: V3(bayX - 0.04, bayY - 0.014, bayZ - 0.0015)))
        // Barcode label and a second QR label on the shell shoulder.
        m.add(Prim.roundedBox(V3(0.05, 0.03, 0.0004), radius: 0.0002, bevelSegments: 1, material: "label.binder"),
              Xform(translation: V3(-0.24, yc - 0.14, -0.0476)))
        // Rating label on the back plate.
        m.add(Prim.roundedBox(V3(0.07, 0.045, 0.0004), radius: 0.0002, bevelSegments: 1, material: "label.inspection"),
              Xform(translation: V3(0.12, yc - 0.075, -0.0614)))

        // Outrigger feet: brushed black-metal plates with a tapered neck up to the panel bottom.
        for s: Float in [-1, 1] {
            let fx = s * 0.5
            m.add(Prim.extrude(Shape2D.roundedRect(0.2, 0.26, radius: 0.025, segments: detail ? 5 : 3), depth: 0.008, bevel: 0.0025, bevelSegments: seg, material: footMetal),
                  Xform(translation: V3(fx, 0.004, 0), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
            m.add(Prim.roundedBox(V3(0.2 - 0.04, 0.0014, 0.26 - 0.04), radius: 0.0004, bevelSegments: 1, material: "rubber.plate"),
                  Xform(translation: V3(fx, 0.0007, 0)))
            // Neck: swept profile from foot top to panel underside.
            let path = [V3(fx, 0.008, -0.010), V3(fx, 0.045, -0.012), V3(fx, y0 + 0.004, -0.006)]
            m.add(Prim.sweep(Shape2D.roundedRect(0.07, 0.022, radius: 0.004, segments: seg), along: path, up: V3(0, 0, 1), scales: [1.35, 1.0, 0.8], caps: true, material: footMetal))
            m.add(Prim.roundedBox(V3(0.09, 0.006, 0.05), radius: 0.002, bevelSegments: 1, material: footMetal), Xform(translation: V3(fx, 0.011, -0.010)))
            if detail {
                for dx: Float in [-0.035, 0.035] {
                    hexBolt(&m, at: V3(fx + dx, 0.0084 + 0.0016, 0.06), normal: V3(0, 1, 0), size: 0.007, material: "metal.screw-zinc")
                }
            }
        }

        // Power cord: from the back plate low right, looping to the floor and back along z behind the right foot.
        let cord = catmull([V3(0.22, yc - 0.12, -0.0615), V3(0.22, yc - 0.15, -0.072), V3(0.26, 0.18, -0.086), V3(0.30, 0.06, -0.10), V3(0.31, 0.006, -0.11), V3(0.34, 0.0035, -0.125)], per: detail ? 5 : 2)
        m.add(Prim.tube(cord, radii: Array(repeating: 0.0035, count: cord.count), sides: detail ? 8 : 5, seamTile: 0.05, material: "rubber.silicone", capEnd: true))
        if detail {
            // Zip tie bundling the cord to the shell, with its trimmed tail, and a velcro cord wrap near the floor.
            let tp = cord[min(4, cord.count - 1)]
            m.add(Prim.torus(major: 0.0042, minor: 0.0009, segments: 12, sides: 4, material: "plastic.white"),
                  Xform(translation: tp, rotation: simd_quatf(degrees: 70, axis: V3(1, 0, 0))))
            m.add(cuboid(V3(0.007, 0.0025, 0.003), material: "plastic.white"), Xform(translation: tp + V3(0.0042, 0.0, 0.0)))
            let wp = cord[min(cord.count - 3, cord.count - 1)]
            m.add(Prim.roundedBox(V3(0.02, 0.012, 0.012), radius: 0.002, bevelSegments: 1, material: "plastic.matte:2F5AA8"), Xform(translation: wp))
        }
        // Strain-relief boot at the chassis.
        m.add(Prim.cylinder(radius: 0.0065, height: 0.016, bevel: 0.002, segments: 10, bevelSegments: 1, material: "rubber.silicone"),
              Xform(translation: V3(0.22, yc - 0.12, -0.0615), rotation: facing(V3(0, 0, -1))))

        groundAO(&m, height: 0.1, floor: 0.6)
        return m
    }
}
