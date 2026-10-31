import simd
import Foundation

/// Shared builder for oval blow-moulded toiletry bottles (shampoo, conditioner, body wash, lotion).
public enum BottleKit {
    public enum Cap { case flip, pump }

    /// size = (x width, y height, z depth); base at y = 0, centred on X/Z.
    public static func model(id: String, size: V3, body: MaterialKey, cap: MaterialKey, label: MaterialKey, capStyle: Cap) -> Model {
        var m = Model(name: id)
        let r = size.x / 2, h = size.y
        let sz = size.z / size.x
        let sc = V3(1, 1, sz)
        let bodyTop = h * 0.78
        let neckR = r * 0.36
        func lathe(_ pts: [V2], _ mat: MaterialKey, seg: Int = 32) {
            m.add(Prim.lathe(pts, segments: seg, seamTile: 0.1, material: mat), Xform(scale: sc))
        }
        // Body: filleted base, straight sides, rounded shoulder to the neck.
        lathe([V2(0.001, 0.0), V2(r * 0.82, 0.0), V2(r * 0.95, 0.0025), V2(r, 0.009), V2(r, bodyTop - h * 0.1),
               V2(r * 0.97, bodyTop - h * 0.06), V2(r * 0.8, bodyTop - h * 0.025), V2(r * 0.5, bodyTop + 0.003),
               V2(neckR * 1.15, bodyTop + 0.008), V2(neckR, bodyTop + 0.012), V2(neckR, bodyTop + 0.016), V2(0.001, bodyTop + 0.016)], body)
        // Wrap label band, 0.4 mm proud of the body.
        let l0 = h * 0.2, l1 = h * 0.6
        lathe([V2(r + 0.0004, l0), V2(r + 0.0004, l1), V2(r - 0.001, l1 + 0.0004), V2(r - 0.001, l0 - 0.0004)], label)
        // Accent stripe on the label.
        lathe([V2(r + 0.0007, l1 - 0.018), V2(r + 0.0007, l1 - 0.008), V2(r - 0.001, l1 - 0.008), V2(r - 0.001, l1 - 0.018)], body)
        // Printed label art: product-name block and text rows as thin dark rings on the label.
        let ink: MaterialKey = "plastic.matte:3A3F46"
        func ring(_ y0: Float, _ y1: Float, _ mat: MaterialKey) {
            lathe([V2(r + 0.0007, y0), V2(r + 0.0007, y1), V2(r - 0.001, y1), V2(r - 0.001, y0)], mat)
        }
        ring(l1 - 0.045, l1 - 0.032, ink)
        ring(l1 - 0.055, l1 - 0.0505, "plastic.matte:8A9097")
        ring(l0 + 0.012, l0 + 0.016, "plastic.matte:8A9097")
        // Shoulder ridge where the label panel ends.
        lathe([V2(r * 0.985, bodyTop - h * 0.1), V2(r * 1.004, bodyTop - h * 0.095), V2(r * 1.004, bodyTop - h * 0.088), V2(r * 0.975, bodyTop - h * 0.082)], body)
        // Moulding parting line near the base.
        lathe([V2(r + 0.0003, 0.012), V2(r + 0.0003, 0.0135), V2(r - 0.001, 0.0135), V2(r - 0.001, 0.012)], "plastic.matte:D8D8D8")
        // Wear: soap scum ring at the base.
        lathe([V2(r + 0.0006, 0.0095), V2(r + 0.0006, 0.017), V2(r - 0.001, 0.017), V2(r - 0.001, 0.0095)], "plastic.matte:CFC8B8")
        let cy = bodyTop + 0.012
        switch capStyle {
        case .flip:
            // Ribbed collar, then flip cap with a hinge step and a thumb lip.
            lathe([V2(neckR * 1.25, 0.0), V2(neckR * 1.3, 0.0015), V2(neckR * 1.3, 0.011), V2(neckR * 1.2, 0.012), V2(0.001, 0.012)].map { V2($0.x, $0.y + cy) }, cap, seg: 24)
            lathe([V2(0.001, 0.0), V2(r * 0.52, 0.0), V2(r * 0.55, 0.002), V2(r * 0.55, h - cy - 0.012 - 0.003 - 0.003),
                   V2(r * 0.5, h - cy - 0.012 - 0.0015), V2(r * 0.42, h - cy - 0.012), V2(0.001, h - cy - 0.012)].map { V2($0.x, $0.y + cy + 0.012) }, cap, seg: 28)
            lathe([V2(neckR * 1.3, cy + 0.0115), V2(neckR * 1.45, cy + 0.011), V2(neckR * 1.4, cy + 0.0085), V2(neckR * 1.3, cy + 0.0075)], "plastic.matte:E9E4D8", seg: 16)
            // Hinge barrel at the back and thumb tab at the front of the cap.
            let capR = r * 0.55
            m.add(Prim.cylinder(radius: 0.0032, height: capR * 1.0, bevel: 0.0008, segments: 10, material: cap),
                  Xform(translation: V3(capR * 0.5, cy + 0.0125, -capR * sz * 0.88), rotation: simd_quatf(degrees: 90, axis: V3(0, 0, 1))))
            m.add(Prim.roundedBox(V3(capR * 0.8, 0.0035, 0.0045), radius: 0.0012, bevelSegments: 1, material: cap),
                  Xform(translation: V3(0, cy + 0.0135, capR * sz * 1.0)))
            // Orifice dimple on top of the cap.
            lathe([V2(0.001, h - 0.0008), V2(0.005, h - 0.0008), V2(0.005, h - 0.0001), V2(0.001, h - 0.0001)], "plastic.black", seg: 12)
        case .pump:
            lathe([V2(neckR * 1.3, 0.0), V2(neckR * 1.35, 0.002), V2(neckR * 1.35, 0.009), V2(neckR * 1.25, 0.011), V2(0.001, 0.011)].map { V2($0.x, $0.y + cy) }, cap, seg: 24)
            let stemTop = h - 0.0115
            lathe([V2(0.001, cy + 0.011), V2(0.0045, cy + 0.011), V2(0.0045, stemTop), V2(0.001, stemTop)], cap, seg: 14)
            // Dried product crust on the collar.
            lathe([V2(neckR * 1.36, cy + 0.0085), V2(neckR * 1.5, cy + 0.008), V2(neckR * 1.45, cy + 0.0055), V2(neckR * 1.36, cy + 0.005)], "plastic.matte:E9E4D8", seg: 16)
            // Pump head and horizontal nozzle.
            lathe([V2(0.001, stemTop), V2(r * 0.42, stemTop), V2(r * 0.46, stemTop + 0.003), V2(r * 0.45, h - 0.002), V2(r * 0.38, h), V2(0.001, h)], cap, seg: 24)
            m.add(Prim.roundedBox(V3(0.008, 0.007, 0.034), radius: 0.0025, bevelSegments: 2, material: cap),
                  Xform(translation: V3(0, h - 0.0085, size.z * 0.0), rotation: simd_quatf(degrees: 90, axis: V3(0, 1, 0))))
        }
        groundAO(&m)
        return m
    }
}
