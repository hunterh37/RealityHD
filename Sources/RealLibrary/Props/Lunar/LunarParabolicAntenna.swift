import simd
import Foundation

/// Lunar surface Ka-band antenna: 0.5 m white composite dish with a feed horn on three struts, held in an elevation
/// yoke on an azimuth gimbal wrapped in gold MLI, on a 0.9 m mast and a bolted base plate with orange bands. Faces +Z.
/// Rig: `az` turns about Y, `el` tilts the dish about X. States: stowed (dish up), track, horizon.
public struct LunarParabolicAntenna: RealArticulated {
    public static let id = "lunar-parabolic-antenna"
    public static let summary = "0.5 m Ka-band dish on a gimbal mast: white composite dish, feed horn and struts, gold MLI gimbal wrap, orange bands; azimuth and elevation joints."
    public static let tags = ["prop", "aerospace", "metal", "electronics", "articulated"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 14, distance: 2.4, studio: true)

    /// Dish diameter (m) and focal ratio f/D.
    public var diameter: Float = 0.5
    public var focalRatio: Float = 0.4
    /// Mast height to the azimuth gimbal (m).
    public var mastHeight: Float = 0.9
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        var rng = SeededRNG(seed: seed)
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [6])
        typealias K = LunarKit
        let R = diameter / 2, f = diameter * focalRatio
        let gy = mastHeight, gH: Float = 0.16
        let ey = gy + gH + 0.2                       // elevation axis height
        for l in 0..<2 {
            var m = Model(name: Self.id)
            let sg = l == 0 ? 40 : 16
            m.add(Prim.roundedBox(V3(0.44, 0.02, 0.44), radius: 0.005, bevelSegments: 2, material: K.silver), Xform(translation: V3(0, 0.01, 0)))
            for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
                hexBolt(&m, at: V3(sx * 0.19, 0.02, sz * 0.19), normal: .up, size: 0.016, material: "metal.steel")
                m.add(Prim.extrude([V2(0, 0), V2(0.1, 0), V2(0, 0.14)], depth: 0.012, bevel: 0.002, bevelSegments: 1, material: K.white),
                      Xform(translation: V3(sx * 0.03, 0.02, sz * 0.03 + 0), rotation: simd_quatf(angle: atan2(sx, sz) * 0 + (sz > 0 ? 0 : .pi) + (sx > 0 ? -0.0 : 0), axis: .up)))
            } }
            m.add(Prim.lathe([V2(0.085, 0.02), V2(0.07, 0.07), V2(0.06, 0.12), V2(0.06, gy - 0.02), V2(0.075, gy)], segments: sg, seamTile: 0.3, material: K.white))
            m.add(Prim.lathe([V2(0.0605, 0.3), V2(0.065, 0.3), V2(0.065, 0.34), V2(0.0605, 0.34)], segments: sg, seamTile: 0.3, material: K.orange))
            m.add(Prim.lathe([V2(0.0605, 0.6), V2(0.065, 0.6), V2(0.065, 0.64), V2(0.0605, 0.64)], segments: sg, seamTile: 0.3, material: K.orange))
            // Cable clip run on the mast.
            m.add(Prim.tube([V3(0.07, 0.04, 0), V3(0.066, 0.4, 0), V3(0.066, gy - 0.02, 0)], radii: [0.006, 0.006, 0.006], sides: 6, seamTile: 0.05, material: K.dark))
            rig.base[l] = m
        }
        // Azimuth gimbal: gold MLI drum, white cap, orange ring.
        rig.part("az", pivot: V3(0, gy, 0), joint: .hinge(axis: .up, -170...170, duration: 1.4))
        rig.add(Prim.lathe([V2(0.08, gy), V2(0.1, gy + 0.01), V2(0.1, gy + gH - 0.02), V2(0.085, gy + gH)], segments: 32, seamTile: 0.2, material: K.gold), to: "az")
        rig.add(Prim.lathe([V2(0.0, gy + gH), V2(0.085, gy + gH), V2(0.09, gy + gH + 0.008), V2(0.0, gy + gH + 0.01)], segments: 32, seamTile: 0.2, material: K.white), to: "az")
        rig.add(Prim.lathe([V2(0.1, gy + 0.045), V2(0.104, gy + 0.045), V2(0.104, gy + 0.065), V2(0.1, gy + 0.065)], segments: 32, seamTile: 0.2, material: K.orange), to: "az")
        for s: Float in [-1, 1] {
            rig.add(Prim.roundedBox(V3(0.022, 0.24, 0.06), radius: 0.005, bevelSegments: 2, material: K.white), Xform(translation: V3(s * 0.13, gy + gH + 0.1, 0)), to: "az")
            rig.add(Prim.roundedBox(V3(0.03, 0.04, 0.05), radius: 0.005, bevelSegments: 2, material: K.silver), Xform(translation: V3(s * 0.13, ey, 0)), to: "az")
        }
        rig.add(Prim.roundedBox(V3(0.27, 0.03, 0.07), radius: 0.006, bevelSegments: 2, material: K.white), Xform(translation: V3(0, gy + gH + 0.015, 0)), to: "az")
        // Elevation assembly.
        rig.part("el", parent: "az", pivot: V3(0, ey, 0), joint: .hinge(axis: V3(1, 0, 0), -90...25, duration: 1.2))
        rig.add(Prim.cylinder(radius: 0.02, height: 0.23, bevel: 0.003, segments: 16, material: K.silver),
                Xform(translation: V3(-0.115, ey, 0), rotation: simd_quatf(angle: -.pi / 2, axis: .up)), to: "el")
        let vz: Float = -0.03
        for s in K.dish(R: R, f: f, thick: 0.012, segments: 64, rings: 14, front: "metal.powder-white:E6E8EA", back: K.white) {
            rig.add(s, Xform(translation: V3(0, ey, vz), rotation: K.toZ), to: "el", lods: 0...0)
        }
        for s in K.dish(R: R, f: f, thick: 0.012, segments: 28, rings: 6, front: "metal.powder-white:E6E8EA", back: K.white) {
            rig.add(s, Xform(translation: V3(0, ey, vz), rotation: K.toZ), to: "el", lods: 1...1)
        }
        // Hub box and gold-wrapped transceiver on the back.
        rig.add(Prim.roundedBox(V3(0.12, 0.1, 0.09), radius: 0.008, bevelSegments: 2, material: K.gold), Xform(translation: V3(0, ey, vz - 0.07)), to: "el")
        rig.add(Prim.cylinder(radius: 0.035, height: 0.03, bevel: 0.004, segments: 20, material: K.silver),
                Xform(translation: V3(0, ey, vz - 0.14), rotation: simd_quatf(angle: -.pi / 2, axis: V3(1, 0, 0))), to: "el")
        // Rim ring accent and feed on three struts.
        let rimZ = vz + R * R / (4 * f)
        rig.add(Prim.torus(major: R, minor: 0.005, segments: 48, sides: 8, material: K.orange), Xform(translation: V3(0, ey, rimZ - 0.004), rotation: K.toZ), to: "el", lods: 0...0)
        let fz = vz + f
        for k in 0..<3 {
            let a = Float(k) / 3 * 2 * .pi + .pi / 2 + rng.float(-0.01...0.01)
            rig.add(Prim.tube([V3(cos(a) * (R - 0.01), ey + sin(a) * (R - 0.01), rimZ - 0.01), V3(cos(a) * 0.02, ey + sin(a) * 0.02, fz - 0.03)],
                              radii: [0.006, 0.004], sides: 8, seamTile: 0.05, material: K.silver), to: "el")
        }
        rig.add(Prim.lathe([V2(0.012, 0), V2(0.02, 0.01), V2(0.03, 0.05), V2(0.032, 0.058), V2(0.02, 0.058)], segments: 24, seamTile: 0.1, material: K.gold),
                Xform(translation: V3(0, ey, fz - 0.04), rotation: K.toZ), to: "el")
        groundAO(&rig, height: 0.3, floor: 0.6)
        rig.states = [RigState("track", ["az": 35, "el": -38]), RigState("stowed", ["el": -90]), RigState("horizon", ["az": -60, "el": 0])]
        return rig
    }
}
