import simd
import Foundation

/// 52 in hugger ceiling fan with light kit, authored in place: the canopy top touches the ceiling plane at
/// y = 2.6 and the body hangs 0.42 m below it. Parts: canopy with trim ring, short downrod and coupler, motor
/// housing with vent ring, five walnut blades on blade irons with screws, frosted light bowl, two pull chains.
public struct CeilingFan: RealAsset {
    public static let id = "ceiling-fan"
    public static let summary = "52 in ceiling fan: nickel downrod and motor, five walnut blades, frosted light bowl, pull chains."
    public static let tags = ["prop", "floorplan", "home", "interior", "ceiling", "light", "metal"]
    public static let budget = 8000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: -18, distance: 1.35, ground: false, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(1.32, 0.42, 1.32)
    /// Ceiling plane height (m); the canopy top touches it.
    public var ceilingY: Float = 2.6
    /// Number of blades.
    public var blades = 5
    /// Blade pitch in degrees.
    public var pitch: Float = 12
    /// Motor and downrod finish.
    public var metal: MaterialKey = "metal.brushed-nickel"
    /// Blade material.
    public var wood: MaterialKey = "wood.veneer-walnut"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        let top = ceilingY
        func Y(_ d: Float) -> Float { top - d }
        let radius = size.x / 2
        func make(_ lod: Int) -> Model {
            var m = Model(name: Self.id)
            let seg = lod == 0 ? 28 : 14
            // Canopy: shallow dome with a rolled lip, then a chrome trim ring.
            m.add(Prim.lathe([V2(0, Y(0)), V2(0.058, Y(0)), V2(0.066, Y(0.012)), V2(0.071, Y(0.028)), V2(0.0735, Y(0.04)),
                              V2(0.0715, Y(0.0525)), V2(0.04, Y(0.0525)), V2(0, Y(0.0525))], segments: seg, seamTile: 0.1, material: metal))
            if lod == 0 {
                m.add(Prim.torus(major: 0.0725, minor: 0.0016, segments: 28, sides: 5, material: "metal.chrome"), Xform(translation: V3(0, Y(0.048), 0)))
                // Canopy set screws.
                for k in 0..<3 {
                    let a = Float(k) * 2 * .pi / 3 + 0.4
                    rivet(&m, at: V3(cos(a) * 0.0735, Y(0.034), -sin(a) * 0.0735), normal: V3(cos(a), 0, -sin(a)), radius: 0.0025, segments: 6, material: "metal.chrome")
                }
            }
            // Downrod with coupler ball and collar.
            m.add(Prim.lathe([V2(0, Y(0.05)), V2(0.019, Y(0.05)), V2(0.019, Y(0.11)), V2(0, Y(0.11))], segments: 20, seamTile: 0.05, material: metal))
            m.add(Prim.lathe([V2(0, Y(0.05)), V2(0.0245, Y(0.05)), V2(0.0245, Y(0.058)), V2(0.0215, Y(0.062)), V2(0, Y(0.062))],
                             segments: 24, seamTile: 0.05, material: metal))
            // Motor housing: tapered cap, vent ring band, rolled bottom edge, blade flange.
            m.add(Prim.lathe([V2(0, Y(0.108)), V2(0.044, Y(0.108)), V2(0.07, Y(0.116)), V2(0.095, Y(0.133)), V2(0.108, Y(0.152)),
                              V2(0.1135, Y(0.172)), V2(0.1135, Y(0.2)), V2(0.1105, Y(0.216)), V2(0.1, Y(0.222)), V2(0.092, Y(0.222)), V2(0, Y(0.222))],
                             segments: seg, seamTile: 0.1, material: metal))
            m.add(Prim.torus(major: 0.1137, minor: 0.0018, segments: 28, sides: 5, material: "metal.chrome"), Xform(translation: V3(0, Y(0.176), 0)))
            m.add(Prim.torus(major: 0.1137, minor: 0.0018, segments: 28, sides: 5, material: "metal.chrome"), Xform(translation: V3(0, Y(0.196), 0)))
            if lod == 0 {
                // Vent slots between the two rings.
                for k in 0..<18 {
                    let a = Float(k) * 2 * .pi / 18
                    let o = cuboid(V3(0.004, 0.012, 0.002), material: "metal.iron")
                    m.add(o, Xform(translation: V3(cos(a) * 0.1138, Y(0.186), -sin(a) * 0.1138), rotation: simd_quatf(degrees: a * 180 / .pi + 90, axis: .up)))
                }
            }
            // Blade flange plate under the motor.
            m.add(Prim.cylinder(radius: 0.098, height: 0.011, bevel: 0.002, segments: seg, material: metal), Xform(translation: V3(0, Y(0.2325), 0)))
            // Blades: walnut, slightly tapered, rounded tip, pitched about their long axis.
            let bladeY = Y(0.2105)
            let r0: Float = 0.16, len = radius * 1.045 - r0
            let outline = Shape2D.rounded([V2(0, -0.066), V2(len - 0.06, -0.074), V2(len, -0.056), V2(len, 0.056), V2(len - 0.06, 0.074), V2(0, 0.066)],
                                          radius: 0.03, segments: 2)
            let flat = simd_quatf(degrees: -90, axis: V3(1, 0, 0))
            for b in 0..<blades {
                let a = Float(b) * 2 * .pi / Float(blades)
                let yaw = simd_quatf(angle: a + 0.157, axis: .up)
                let tilt = simd_quatf(degrees: pitch, axis: V3(1, 0, 0))
                let blade = Prim.extrude(outline, depth: 0.012, bevel: 0.0025, bevelSegments: 1, material: wood)
                let c = yaw.act(V3(r0, 0, 0))
                m.add(blade, Xform(translation: V3(c.x, bladeY, c.z), rotation: yaw * tilt * flat))
                // Blade iron: flat arm from the flange to the blade root, screws through the blade.
                let iron = Prim.roundedBox(V3(0.11, 0.0035, 0.045), radius: 0.001, bevelSegments: 1, material: metal)
                let ic = yaw.act(V3(0.158, 0, 0))
                m.add(iron, Xform(translation: V3(ic.x, bladeY - 0.0085, ic.z), rotation: yaw * tilt))
                if lod == 0 {
                    for s in [0.18, 0.225] as [Float] {
                        for z in [-0.016, 0.016] as [Float] {
                            let p = yaw.act(V3(s, 0, 0)) + V3(0, 0, 0)
                            let off = (yaw * tilt).act(V3(0, 0.0075, z))
                            rivet(&m, at: V3(p.x, bladeY, p.z) + off, normal: (yaw * tilt).act(.up), radius: 0.0032, segments: 6, material: "metal.chrome")
                        }
                    }
                }
            }
            // Light kit: switch cup with fitter ring, frosted bowl, bottom finial.
            m.add(Prim.lathe([V2(0, Y(0.2435)), V2(0.062, Y(0.2435)), V2(0.066, Y(0.249)), V2(0.066, Y(0.262)), V2(0.056, Y(0.268)), V2(0, Y(0.268))],
                             segments: seg, seamTile: 0.1, material: metal))
            m.add(Prim.lathe([V2(0.0, Y(0.2435)), V2(0.099, Y(0.2435)), V2(0.1005, Y(0.248)), V2(0.1005, Y(0.256)), V2(0.098, Y(0.2595)), V2(0, Y(0.2595))],
                             segments: seg, seamTile: 0.1, material: metal))
            let bowl: [V2] = [V2(0.062, Y(0.262)), V2(0.075, Y(0.28)), V2(0.0855, Y(0.31)), V2(0.0855, Y(0.34)), V2(0.075, Y(0.375)),
                              V2(0.052, Y(0.405)), V2(0.022, Y(0.416)), V2(0.0, Y(0.417))]
            m.add(Prim.lathe(Profile.smooth(bowl, per: lod == 0 ? 2 : 1), segments: seg, seamTile: 0.1, material: "glass.frosted"))
            m.add(Prim.lathe([V2(0, Y(0.4105)), V2(0.02, Y(0.4105)), V2(0.0255, Y(0.414)), V2(0.0255, Y(0.418)), V2(0.02, Y(0.42)), V2(0, Y(0.42))],
                             segments: 20, seamTile: 0.05, material: metal))
            // Bulb and socket inside the bowl, visible through the frosted glass.
            m.add(Prim.lathe([V2(0, Y(0.262)), V2(0.014, Y(0.262)), V2(0.014, Y(0.285)), V2(0, Y(0.285))], segments: 12, seamTile: 0.03, material: "metal.brass"))
            m.add(Prim.superellipsoid(V3(0.04, 0.062, 0.04), exponent: 2, subdivisions: 4, material: "emissive.bulb"), Xform(translation: V3(0, Y(0.315), 0)))
            // Reverse switch slider and nameplate on the motor housing.
            if lod == 0 {
                m.add(Prim.roundedBox(V3(0.014, 0.006, 0.004), radius: 0.001, bevelSegments: 1, material: "plastic.black"), Xform(translation: V3(0, Y(0.165), 0.1135)))
                m.add(Prim.roundedBox(V3(0.03, 0.01, 0.0015), radius: 0.0005, bevelSegments: 1, material: "metal.aluminum-brushed"), Xform(translation: V3(0.05, Y(0.186), 0.1005 + 0.0), rotation: simd_quatf(degrees: 25, axis: .up)))
            }
            // Pull chains with bead ends, hanging outside the bowl from the fitter ring.
            for (k, (ang, drop)) in [(Float(0.9), Float(0.105)), (Float(2.35), Float(0.145))].enumerated() {
                let p = V3(cos(ang) * 0.0935, Y(0.26), -sin(ang) * 0.0935)
                let path = [p, p + V3(0, -drop * 0.5, 0), p + V3(0, -drop, 0)]
                m.add(Prim.tube(path, radii: [0.0009, 0.0009, 0.0009], sides: 5, seamTile: 0.01, material: "metal.chrome"))
                let bead = Prim.lathe([V2(0, 0.0), V2(0.0045, 0.0005), V2(0.0055, 0.006), V2(0.0045, 0.0125), V2(0, 0.013)], segments: 10, seamTile: 0.02, material: k == 0 ? "metal.brass" : "metal.chrome")
                m.add(bead, Xform(translation: p + V3(0, -drop - 0.012, 0)))
            }
            return m
        }
        return LODModel(levels: [make(0), make(1)], switchDistances: [6])
    }
}
