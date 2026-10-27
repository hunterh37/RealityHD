import simd
import Foundation

/// Immersion stick blender standing on its bell guard: white plastic motor body with a rubber grip band, orange speed button, stainless shaft, vented bell guard over a blade, and a cord hung down the back. Story: paint worn off the speed button.
public struct StickBlender: RealAsset {
    public static let id = "stick-blender"
    public static let summary = "Immersion stick blender, 40 cm: white plastic motor body with grip band and speed button, brushed steel shaft ending in a vented bell guard over the blade."
    public static let tags = ["prop", "interior", "kitchen", "plastic", "metal"]
    public static let budget = 11000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 14, distance: 1.15, studio: true)

    /// Overall height (m).
    public var height: Float = 0.40
    /// Plastic housing.
    public var housing: MaterialKey = "plastic.white"
    /// Rubber grip band and cord.
    public var grip: MaterialKey = "rubber.insulating-black"
    /// Shaft and bell guard.
    public var steel: MaterialKey = "metal.satin-aluminum"
    /// Speed button.
    public var button: MaterialKey = "plastic.orange"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let k = height / 0.40
        func y(_ v: Float) -> Float { v * k }
        // Bell guard: stainless shell, open at the bottom, with a rolled lip.
        let bell: [V2] = [V2(0.0246, 0), V2(0.0258, 0), V2(0.0282, 0.0015), V2(0.0287, 0.012), V2(0.0282, 0.032), V2(0.0256, 0.044),
                          V2(0.0193, 0.0505), V2(0.0132, 0.0535), V2(0.0120, 0.0560),
                          V2(0.0120, 0.0520), V2(0.0174, 0.0480), V2(0.0230, 0.0415), V2(0.0259, 0.0300), V2(0.0263, 0.0120), V2(0.0250, 0.0012)]
        m.add(Prim.lathe(bell, segments: 40, seamTile: 0.08, material: steel))
        // Six vent slots punched in the bell wall.
        for i in 0..<6 {
            let a = Float(i) / 6 * 2 * .pi + 0.26
            m.add(Prim.roundedBox(V3(0.0042, 0.0170, 0.0016), radius: 0.0006, bevelSegments: 1, material: "plastic.black"),
                  Xform(translation: V3(0.0285 * cos(a), 0.0215, -0.0285 * sin(a)), rotation: DD1EKitchen.rotY(a * 180 / .pi + 90)))
        }
        // Blade inside the bell: hub and two bent wings.
        m.add(Prim.cylinder(radius: 0.0045, height: 0.004, bevel: 0.0008, segments: 12, material: "metal.knife-blade"), Xform(translation: V3(0, 0.0105, 0)))
        for s: Float in [-1, 1] {
            m.add(Prim.roundedBox(V3(0.0225, 0.0007, 0.0085), radius: 0.0003, bevelSegments: 1, material: "metal.knife-blade"),
                  Xform(translation: V3(s * 0.0115, 0.0125, 0), rotation: simd_quatf(degrees: s * 16, axis: V3(0, 0, 1))))
        }
        // Shaft and coupling collar.
        m.add(Prim.cylinder(radius: 0.0124, height: y(0.148), bevel: 0.0008, segments: 32, material: steel), Xform(translation: V3(0, 0.0535, 0)))
        m.add(Prim.cylinder(radius: 0.0150, height: y(0.010), bevel: 0.0014, segments: 32, material: "plastic.black"), Xform(translation: V3(0, y(0.186), 0)))
        // Motor housing: lower neck flaring into the body, shoulder, head.
        let body: [(Float, Float)] = [(0.0185, 0.194), (0.0210, 0.200), (0.0240, 0.214), (0.0262, 0.236), (0.0272, 0.262), (0.0274, 0.276),
                                      (0.0274, 0.344), (0.0276, 0.360), (0.0272, 0.384), (0.0250, 0.395), (0.0200, 0.3992), (0.0100, 0.4), (0, 0.4)]
        var hp = body.map { V2($0.0, y($0.1)) }
        hp.insert(V2(0, y(0.194)), at: 0)
        m.add(Prim.lathe(hp, segments: 48, seamTile: 0.15, material: housing))
        // Rubber grip band with raised ribs.
        m.add(Prim.lathe([V2(0.0272, y(0.2780)), V2(0.0284, y(0.2800)), V2(0.0287, y(0.2900)), V2(0.0287, y(0.3300)), V2(0.0284, y(0.3420)), V2(0.0272, y(0.3440)),
                          V2(0.0268, y(0.3440)), V2(0.0268, y(0.2780)), V2(0.0272, y(0.2780))], segments: 48, seamTile: 0.1, material: grip))
        for i in 0..<18 {
            let a = Float(i) / 18 * 2 * .pi
            m.add(Prim.roundedBox(V3(0.0022, y(0.050), 0.0012), radius: 0.0005, bevelSegments: 1, material: grip),
                  Xform(translation: V3(0.0289 * cos(a), y(0.311), -0.0289 * sin(a)), rotation: DD1EKitchen.rotY(a * 180 / .pi + 90)))
        }
        // Parting seam between the two housing halves.
        m.add(Prim.lathe([V2(0.0268, y(0.2672)), V2(0.0275, y(0.2672)), V2(0.0275, y(0.2692)), V2(0.0268, y(0.2692)), V2(0.0268, y(0.2672))], segments: 48, seamTile: 0.1, material: "plastic.black"))
        // Speed button on the front with paint worn off its centre.
        m.add(Prim.roundedBox(V3(0.0150, 0.0340, 0.0060), radius: 0.0026, bevelSegments: 3, material: button), Xform(translation: V3(0, y(0.366), 0.0278)))
        m.add(Prim.roundedBox(V3(0.0072, 0.0125, 0.0004), radius: 0.0002, bevelSegments: 1, material: "plastic.white:E8E2D2"), Xform(translation: V3(0.0006, y(0.361), 0.0309)))
        m.add(Prim.roundedBox(V3(0.0100, 0.0050, 0.0030), radius: 0.0012, bevelSegments: 2, material: "plastic.black"), Xform(translation: V3(0, y(0.335) + 0.037, 0.0266)))
        // Cord: leaves the back of the head, hangs down the back and lies out onto the table.
        let cp: [V3] = [V3(0, y(0.374), -0.020), V3(0, y(0.371), -0.0285), V3(0, y(0.340), -0.0300), V3(0, y(0.200), -0.0300), V3(0, y(0.130), -0.0305),
                        V3(0, 0.060, -0.0305), V3(0, 0.022, -0.0305), V3(0, 0.0085, -0.0305), V3(0.007, 0.0034, -0.0305), V3(0.019, 0.0028, -0.0305), V3(0.029, 0.0028, -0.0305)]
        let path = catmull(cp, per: 5)
        m.add(Prim.tube(path, radii: path.map { _ in 0.0027 }, sides: 10, seamTile: 0.02, material: "rubber.insulating-black"))
        m.add(Prim.tube([V3(0, y(0.374), -0.020), V3(0, y(0.371), -0.0285), V3(0, y(0.362), -0.0300)], radii: [0.0036, 0.0033, 0.0030], sides: 10, seamTile: 0.02, material: "rubber.insulating-black"))
        // Cooling slots on both sides of the head.
        for sx: Float in [-1, 1] {
            for j in 0..<5 {
                m.add(Prim.roundedBox(V3(0.0016, 0.0120, 0.0028), radius: 0.0006, bevelSegments: 1, material: "plastic.black"),
                      Xform(translation: V3(sx * 0.0268, y(0.372), (Float(j) - 2) * 0.0050 * 0.8)))
            }
        }
        _ = rng.float()
        groundAO(&m, height: 0.03, floor: 0.7)
        return LODModel(m)
    }
}
