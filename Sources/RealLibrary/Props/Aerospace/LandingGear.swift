import simd
import Foundation

/// Retractable main landing gear, 0.9 m tall, shown down. A machined trunnion fitting (the airframe
/// attachment) carries the leg on a pin along X. The leg is a grey painted oleo cylinder with a chrome
/// piston, scissor torque links, a yoke fork and a 5.00-5 class tire on a cast hub with a brake disc and
/// caliper; a hydraulic retract actuator rides on the back. The leg swings 90 degrees forward to stow.
public struct LandingGear: RealArticulated {
    public static let id = "landing-gear"
    public static let summary = "Retractable main landing gear, 0.9 m tall: oleo strut with chrome piston and torque links, fork and rubber tire, swinging up 90 degrees about its trunnion."
    public static let tags = ["prop", "aerospace", "metal", "rubber", "articulated"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 40, elevation: 12, distance: 1.25, studio: true)

    /// Overall height, tire contact to trunnion top (m).
    public var height: Float = 0.9
    /// Tire outer radius and section half-width (m).
    public var tireRadius: Float = 0.19
    public var tireHalfWidth: Float = 0.06
    /// Retraction angle (degrees).
    public var retract: Float = 90
    /// Leg paint (sRGB hex).
    public var paint: UInt32 = 0x8E9396
    public var chrome: MaterialKey = "metal.chrome"
    public var tire: MaterialKey = "rubber.tire"
    public var hub: MaterialKey = "metal.aluminum-cast"
    public var fastener: MaterialKey = "metal.steel"
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        var rng = SeededRNG(seed: seed)
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [6])
        let leg: MaterialKey = "metal.powdercoat:" + String(format: "%06X", paint)
        let fitting: MaterialKey = "metal.aluminum-brushed"
        let pinY = height - 0.045
        let axleY = tireRadius
        let rot90X = simd_quatf(angle: .pi / 2, axis: V3(0, 0, 1))   // +Y cylinder -> along -X/+X

        // Trunnion fitting: mounting plate with two lugs and the pin.
        for l in 0..<2 {
            var m = Model(name: Self.id)
            let bs = l == 0 ? 2 : 1
            m.add(Prim.roundedBox(V3(0.24, 0.016, 0.12), radius: 0.004, bevelSegments: bs, material: fitting),
                  Xform(translation: V3(0, height - 0.008, 0)))
            for s: Float in [-1, 1] {
                m.add(Prim.roundedBox(V3(0.016, 0.06, 0.07), radius: 0.006, bevelSegments: bs, material: fitting),
                      Xform(translation: V3(s * 0.06, pinY + 0.012, 0)))
            }
            m.add(Prim.cylinder(radius: 0.011, height: 0.16, bevel: 0.002, segments: l == 0 ? 14 : 8, material: fastener),
                  Xform(translation: V3(0.08, pinY, 0), rotation: rot90X))
            if l == 0 {
                for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
                    hexBolt(&m, at: V3(sx * 0.1, height, sz * 0.045), normal: .up, size: 0.008, material: fastener)
                } }
                hexBolt(&m, at: V3(0.08, pinY, 0), normal: V3(1, 0, 0), size: 0.012, material: fastener)
            }
            rig.base[l] = m
        }

        rig.part("leg", pivot: V3(0, pinY, 0), joint: .hinge(axis: V3(1, 0, 0), -retract...0, duration: 2.5))
        let cylTop = pinY + 0.025, cylBot: Float = 0.58, pistBot: Float = 0.42, yokeY: Float = 0.415
        for l in 0..<2 {
            var m = Model(name: Self.id)
            let sg = l == 0 ? 24 : 10, bs = l == 0 ? 2 : 1
            // Trunnion head: cross tube on the pin.
            m.add(Prim.cylinder(radius: 0.024, height: 0.096, bevel: 0.004, segments: sg, material: leg),
                  Xform(translation: V3(0.048, pinY, 0), rotation: rot90X))
            // Oleo cylinder with a gland nut collar at the bottom.
            m.add(Prim.lathe([V2(0, cylBot), V2(0.036, cylBot), V2(0.039, cylBot + 0.004), V2(0.039, cylBot + 0.03), V2(0.035, cylBot + 0.034),
                              V2(0.034, cylTop - 0.03), V2(0.028, cylTop), V2(0, cylTop)], segments: sg, material: leg))
            // Chrome piston, a dull band where the seal wipes.
            m.add(Prim.cylinder(radius: 0.026, height: cylBot - pistBot + 0.01, bevel: 0.002, segments: sg, material: chrome),
                  Xform(translation: V3(0, pistBot, 0)))
            // Yoke: crossbar above the tire and two fork legs down to the axle.
            let fx = tireHalfWidth + 0.022
            m.add(Prim.roundedBox(V3(2 * fx + 0.03, 0.04, 0.06), radius: 0.008, bevelSegments: bs, material: leg),
                  Xform(translation: V3(0, yokeY, 0)))
            for s: Float in [-1, 1] {
                let outline = Shape2D.rounded([V2(-0.03, axleY - 0.03), V2(0.03, axleY - 0.03), V2(0.028, yokeY), V2(-0.028, yokeY)], radius: 0.012, segments: 2)
                m.add(Prim.extrude(outline, depth: 0.018, bevel: 0.003, bevelSegments: bs, material: leg),
                      Xform(translation: V3(s * fx, 0, 0), rotation: simd_quatf(angle: .pi / 2, axis: V3(0, 1, 0))))
            }
            // Axle through the hub with nuts.
            m.add(Prim.cylinder(radius: 0.014, height: 2 * fx + 0.04, bevel: 0.002, segments: l == 0 ? 14 : 8, material: fastener),
                  Xform(translation: V3(fx + 0.02, axleY, 0), rotation: rot90X))
            // Tire: torus with a flattened contact patch; hub: cast lathe with spokes cut as a dish.
            var t = Prim.torus(major: tireRadius - tireHalfWidth, minor: tireHalfWidth, segments: l == 0 ? 56 : 20, sides: l == 0 ? 24 : 8, material: tire)
            if l == 0 {
                // Tread: three circumferential grooves across the crown, shoulders squared off a little.
                let crown = tireRadius - tireHalfWidth * 0.35
                t.displace { p, _ in
                    let r = simd_length(V2(p.x, p.z))
                    guard r > crown else { return 0 }
                    var d: Float = 0
                    for g: Float in [-0.022, 0, 0.022] where abs(p.y - g) < 0.0045 { d -= 0.0035 }
                    return d
                }
            }
            m.add(t, Xform(translation: V3(0, axleY, 0), rotation: simd_quatf(angle: .pi / 2, axis: V3(0, 0, 1))))
            let hr = tireRadius - tireHalfWidth * 1.55
            m.add(Prim.lathe([V2(0, -0.05), V2(0.03, -0.052), V2(hr * 0.7, -0.045), V2(hr, -0.05), V2(hr + 0.006, -0.042),
                              V2(hr + 0.006, 0.042), V2(hr, 0.05), V2(hr * 0.7, 0.045), V2(0.03, 0.052), V2(0, 0.05)], segments: sg, material: hub),
                  Xform(translation: V3(0, axleY, 0), rotation: rot90X))
            // Brake disc and caliper on the inboard side (-X).
            m.add(Prim.cylinder(radius: hr * 0.9, height: 0.006, bevel: 0.001, segments: sg, material: fastener),
                  Xform(translation: V3(-0.056, axleY, 0), rotation: rot90X))
            m.add(Prim.roundedBox(V3(0.03, 0.05, 0.04), radius: 0.008, bevelSegments: bs, material: leg),
                  Xform(translation: V3(-0.06, axleY + hr * 0.7, -0.02)))
            if l == 0 {
                // Hub bolt circle.
                for k in 0..<6 {
                    let a = Float(k) / 6 * 2 * .pi
                    hexBolt(&m, at: V3(0.053, axleY + cos(a) * 0.04, sin(a) * 0.04), normal: V3(1, 0, 0), size: 0.006, material: fastener)
                }
                // Torque links: scissor plates in front of the piston.
                let a = V3(0, cylBot + 0.01, 0.034), mid = V3(0, (cylBot + yokeY) / 2, 0.095), b = V3(0, yokeY + 0.01, 0.034)
                for (p0, p1) in [(a, mid), (mid, b)] {
                    let d = p1 - p0, len = simd_length(d)
                    let q = simd_quatf(from: V3(0, 1, 0), to: d / len)
                    m.add(Prim.roundedBox(V3(0.026, len + 0.02, 0.012), radius: 0.005, bevelSegments: 2, material: leg),
                          Xform(translation: (p0 + p1) / 2, rotation: q))
                }
                for p in [a, mid, b] {
                    m.add(Prim.cylinder(radius: 0.007, height: 0.034, bevel: 0.001, segments: 10, material: fastener),
                          Xform(translation: p + V3(0.017, 0, 0), rotation: rot90X))
                }
                // Retract actuator: body and chrome rod from the head to a lug on the cylinder back.
                let a0 = V3(0, pinY + 0.005, -0.075), a1 = V3(0, cylBot + 0.11, -0.04)
                let dir = simd_normalize(a1 - a0), mid2 = a0 + (a1 - a0) * 0.6
                m.add(Prim.tube([a0, mid2], radii: [0.016, 0.016], sides: 14, seamTile: 0.05, material: leg, capEnd: true))
                m.add(Prim.tube([mid2, a1], radii: [0.007, 0.007], sides: 10, seamTile: 0.05, material: chrome, capEnd: true))
                m.add(Prim.roundedBox(V3(0.02, 0.03, 0.03), radius: 0.006, bevelSegments: 2, material: leg),
                      Xform(translation: a1 + dir * 0.005 + V3(0, 0, 0.008)))
                m.add(Prim.roundedBox(V3(0.02, 0.03, 0.03), radius: 0.006, bevelSegments: 2, material: fitting),
                      Xform(translation: a0 + V3(0, 0.01, -0.005)))
                // Brake line along the leg.
                let line = [V3(-0.04, cylTop - 0.06, -0.02), V3(-0.042, cylBot, -0.025), V3(-0.045, yokeY, -0.03), V3(-0.06, axleY + hr * 0.7 + 0.02, -0.03)]
                m.add(Prim.tube(catmull(line, per: 6), radii: Array(repeating: 0.003, count: catmull(line, per: 6).count), sides: 6, seamTile: 0.03, material: "rubber", capEnd: true))
            }
            _ = rng.float()
            rig.add(m, to: "leg", lod: l)
        }

        rig.states = [RigState("down"), RigState("up", ["leg": -retract])]
        groundAO(&rig, height: 0.12, floor: 0.6)
        return rig
    }
}
