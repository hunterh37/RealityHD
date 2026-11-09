import simd
import Foundation

/// 32 oz trigger spray cleaner, 27 cm: oval clear PET bottle with a grip waist, blue liquid fill and a dip
/// tube seen through the wall, printed front and back labels, a ribbed closure collar, and a trigger
/// sprayer with turret, shroud, pump piston, ribbed lever trigger and a square spray/off nozzle. Invented
/// brand SHINEWELL.
public struct CleaningSpray: RealAsset {
    public static let id = "cleaning-spray"
    public static let summary = "32 oz trigger spray cleaner, 27 cm: oval PET bottle with blue liquid, dip tube, labels, trigger sprayer."
    public static let tags = ["prop", "grocery", "plastic", "container", "home", "handheld"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 12, distance: 1.3, studio: true)

    public var liquid: MaterialKey = "plastic.translucent:2E8FE0"
    public var sprayer: MaterialKey = "plastic.matte:F2F2EE"
    public var nozzleKey: MaterialKey = "plastic.gloss:1E5BB8"
    /// Label brand field color.
    public var label: UInt32 = 0x0E4A9E
    public var brand = "SHINEWELL"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(hi: true), level(hi: false)], switchDistances: [2])
    }

    /// Bottle sections (y, width, depth) from the base to the neck.
    static let sections: [(Float, Float, Float)] = [
        (0, 0.096, 0.060), (0.004, 0.104, 0.066), (0.012, 0.106, 0.068), (0.105, 0.106, 0.068), (0.118, 0.094, 0.062),
        (0.128, 0.090, 0.060), (0.140, 0.096, 0.063), (0.160, 0.104, 0.066), (0.176, 0.098, 0.063), (0.188, 0.074, 0.052),
        (0.198, 0.048, 0.040), (0.204, 0.031, 0.031), (0.208, 0.029, 0.029),
    ]

    func half(_ y: Float) -> (Float, Float) {
        let s = Self.sections
        for i in 1..<s.count where y <= s[i].0 {
            let t = (y - s[i - 1].0) / (s[i].0 - s[i - 1].0)
            return ((s[i - 1].1 + (s[i].1 - s[i - 1].1) * t) / 2, (s[i - 1].2 + (s[i].2 - s[i - 1].2) * t) / 2)
        }
        return (s.last!.1 / 2, s.last!.2 / 2)
    }

    func frontZ(_ x: Float, _ y: Float, n: Float = 3) -> Float {
        let (hw, hd) = half(y)
        return hd * pow(max(0, 1 - pow(min(1, abs(x) / hw), n)), 1 / n)
    }

    func level(hi: Bool) -> Model {
        var m = Model(name: Self.id)
        let sides = hi ? 48 : 20
        func ex(_ y: Float) -> Float { y > 0.196 ? 2 : 3 }
        // Bottle wall.
        var rings: [[V3]] = []
        for (y, w, d) in Self.sections {
            let inset: Float = y < 0.001 ? 0.006 : 0
            rings.append(Prim.ring(Shape2D.superellipse(w - inset, d - inset, exponent: ex(y), segments: sides), y: y))
        }
        // Neck finish with a thread bead.
        for (y, r) in [(0.209, 0.0145), (0.212, 0.0152), (0.214, 0.0145), (0.222, 0.0145)] as [(Float, Float)] {
            rings.append(Prim.ring(Shape2D.circle(r, segments: sides), y: y))
        }
        m.add(Prim.loft(rings, capStart: true, capEnd: false, material: "pkg.pet-clear"))
        // Liquid fill to 0.168 m, a hair inside the wall.
        let fill: Float = 0.168
        var lr: [[V3]] = []
        for (y, w, d) in Self.sections where y < fill {
            lr.append(Prim.ring(Shape2D.superellipse(max(0.01, w - 0.003), max(0.01, d - 0.003), exponent: 3, segments: sides), y: max(0.0015, y)))
        }
        let (fw, fd) = half(fill)
        lr.append(Prim.ring(Shape2D.superellipse(fw * 2 - 0.003, fd * 2 - 0.003, exponent: 3, segments: sides), y: fill))
        m.add(Prim.loft(lr, capStart: true, capEnd: true, material: liquid))
        // Dip tube from the pump down to the back bottom corner.
        let tube: [V3] = [V3(0, 0.222, -0.002), V3(0, 0.17, -0.004), V3(0, 0.08, -0.012), V3(0.004, 0.006, -0.02)]
        m.add(Prim.tube(catmull(tube, per: hi ? 6 : 2), radii: Array(repeating: 0.0022, count: catmull(tube, per: hi ? 6 : 2).count),
                        sides: 6, seamTile: 0.05, material: "plastic.translucent:E8EEF2"))
        // Front and back labels conforming to the lower body.
        let key = GroceryKit.tint("pkg.carton-gloss", label)
        let lw: Float = 0.086, ly0: Float = 0.016, ly1: Float = 0.102
        for back in [false, true] {
            let crop: (Float, Float, Float, Float) = back ? (0, 1, 0, 0.72) : (0, 1, 0.26, 1)
            var s = GroceryKit.sheet(cols: hi ? 14 : 6, rows: 2, key, crop: crop) { u, v in
                let x = (u - 0.5) * lw, y = ly0 + v * (ly1 - ly0)
                return V3(x, y, self.frontZ(x, y) + 0.0004)
            }
            if back { s = s.transformed(Xform(rotation: simd_quatf(angle: .pi, axis: .up))) }
            m.add(s)
        }
        // Wordmark on the label: big brand, small claim in the pill.
        let by: Float = ly0 + (ly1 - ly0) * 0.13
        m.add(GroceryKit.conformedText(brand, height: 0.011, "plastic.gloss:0E4A9E", maxWidth: 0.07, weight: 1.3) { x, y in
            self.frontZ(x, by + y) + 0.0008 }, Xform(translation: V3(0, by, 0)))
        let py = ly0 + (ly1 - ly0) * ((0.85 - 0.26) / 0.74) - 0.0028, px = 0.2 * lw
        m.add(GroceryKit.conformedText("GLASS", height: 0.0056, "plastic.gloss:FFFFFF", maxWidth: 0.03, weight: 1.15) { x, y in
            self.frontZ(px + x, py + y) + 0.0008 }, Xform(translation: V3(px, py, 0)))
        // Closure collar.
        m.add(GroceryKit.knurledCap(r: 0.0175, h: 0.016, seg: hi ? 72 : 20, rib: 0.0006, sprayer), Xform(translation: V3(0, 0.207, 0)))
        // Turret, shroud and top ridge.
        m.add(GroceryKit.cyl(0.0105, 0.012, seg: hi ? 24 : 10, sprayer), Xform(translation: V3(0, 0.222, 0)))
        var shroud = Prim.superellipsoid(V3(0.034, 0.036, 0.078), exponent: 3.2, subdivisions: hi ? 8 : 4, material: sprayer)
        shroud.deform { p in
            let t = max(0, (p.z + 0.039) / 0.078)          // 0 back, 1 front
            return V3(p.x * (1 - 0.32 * t), p.y * (1 - 0.3 * t) + 0.004 * t, p.z)
        }
        m.add(shroud, Xform(translation: V3(0, 0.25, 0.012)))
        GroceryKit.box(&m, V3(0.004, 0.003, 0.05), V3(0, 0.2685, 0.006), sprayer, r: 0.0012)
        // Nozzle: square cap with spray/off faces and an orifice.
        GroceryKit.box(&m, V3(0.016, 0.016, 0.012), V3(0, 0.252, 0.056), nozzleKey, r: 0.0022)
        m.add(GroceryKit.cyl(0.0016, 0.0006, seg: 10, "plastic.matte:1A1A1C"), Xform(translation: V3(0, 0.252, 0.0621), rotation: simd_quatf(angle: .pi / 2, axis: V3(1, 0, 0))))
        if hi {
            let fr = simd_quatf(angle: .pi / 2, axis: .up)
            GroceryKit.printSmooth(&m, "OFF", height: 0.0035, at: V3(0.0081, 0.2505, 0.056), "plastic.gloss:FFFFFF", rot: fr, maxWidth: 0.01, weight: 1)
            GroceryKit.printSmooth(&m, "SPRAY", height: 0.0035, at: V3(0, 0.2603, 0.056), "plastic.gloss:FFFFFF",
                                   rot: simd_quatf(angle: -.pi / 2, axis: V3(1, 0, 0)), maxWidth: 0.012, weight: 1)
        }
        // Pump piston under the shroud.
        m.add(Prim.cylinder(radius: 0.0055, height: 0.022, bevel: 0.0008, segments: hi ? 20 : 8, material: "plastic.translucent:E8EEF2"),
              Xform(translation: V3(0, 0.236, 0.016), rotation: simd_quatf(angle: .pi / 2, axis: V3(1, 0, 0))))
        // Trigger lever: curved profile (z, y), extruded across x, with finger ribs.
        let prof: [V2] = [V2(0.022, 0.240), V2(0.034, 0.243), V2(0.040, 0.236), V2(0.042, 0.222), V2(0.045, 0.206),
                          V2(0.050, 0.194), V2(0.054, 0.188), V2(0.050, 0.184), V2(0.043, 0.188), V2(0.037, 0.198),
                          V2(0.033, 0.214), V2(0.030, 0.228), V2(0.024, 0.233)]
        let trig = Prim.extrude(Shape2D.rounded(prof, radius: 0.002, segments: hi ? 3 : 1), depth: 0.017, bevel: 0.0015,
                                bevelSegments: hi ? 2 : 1, material: sprayer)
        m.add(trig, Xform(rotation: simd_quatf(angle: -.pi / 2, axis: .up)))
        if hi {
            for i in 0..<4 {
                let t = Float(i) / 3, z = 0.0415 + 0.008 * t, y = 0.226 - 0.03 * t
                GroceryKit.box(&m, V3(0.015, 0.0016, 0.0018), V3(0, y, z + 0.0012), sprayer, r: 0.0006)
            }
        }
        // Pivot pin.
        m.add(Prim.cylinder(radius: 0.0018, height: 0.02, bevel: 0.0004, segments: 8, material: "plastic.matte:B8BCC0"),
              Xform(translation: V3(-0.01, 0.238, 0.028), rotation: simd_quatf(angle: -.pi / 2, axis: V3(0, 0, 1))))
        return m
    }
}
