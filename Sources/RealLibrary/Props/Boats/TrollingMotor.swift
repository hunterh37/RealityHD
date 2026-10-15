import simd
import Foundation

/// 30 lb thrust clamp-on electric trolling motor for a small jon boat, 1.25 m tall deployed: composite
/// 36 in shaft, glossy black control head with a twist tiller, clamp bracket with screw clamps, bullet
/// motor pod (9 cm) with skeg and a two-blade weedless prop (25 cm). Bracket clamp (`mountPoint`) sits on
/// the boat transom top; bow is +X. Parts: `shaft` (tilt about the bracket), `head` (steer, carries the
/// pod), `prop` (spin), `tiller` (lift). States: `deployed`, `stowed`.
public struct TrollingMotor: RealArticulated {
    public static let id = "trolling-motor"
    public static let summary = "Clamp-on electric trolling motor, 1.25 m: composite shaft, control head with twist tiller, clamp bracket, motor pod, two-blade prop."
    public static let tags = ["prop", "vehicle", "boat", "river", "plastic", "articulated"]
    public static let budget = 9_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 120, elevation: 15, distance: 1.0)

    /// Shaft length in meters (36 in).
    public var shaftLength: Float = 0.91
    /// Prop diameter in meters.
    public var propDiameter: Float = 0.25
    public var body: MaterialKey = "plastic.gloss:1A1A1C"
    public var shaftMaterial: MaterialKey = "plastic.matte:202022"
    public var grip: MaterialKey = "rubber.plate"
    public init() {}

    /// Height of the bracket clamp above the pod bottom (the boat gunwale sits here).
    public var mountHeight: Float { shaftLength * 0.62 + 0.175 }
    /// Bracket clamp point in asset space, rest (deployed) pose.
    public var mountPoint: V3 { V3(-0.07 - centerOffset, mountHeight, 0) }
    /// X offset applied so the rest-pose bounds are centered.
    let centerOffset: Float = 0.114

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 1)
        let podY: Float = 0.125, shaftTop = podY + shaftLength
        let mh = mountHeight
        // Clamp bracket (static): C-shaped body, two screw clamps with pads, tilt lever.
        let bracket: [V2] = [V2(-0.02, -0.16), V2(0.03, -0.16), V2(0.03, 0.06), V2(-0.13, 0.06), V2(-0.13, -0.06), V2(-0.1, -0.06), V2(-0.1, 0.02), V2(-0.02, 0.02)]
        rig.base[0].add(Prim.extrude(Shape2D.rounded(bracket, radius: 0.008), depth: 0.07, bevel: 0.004, material: body), Xform(translation: V3(0, mh, 0)))
        for z: Float in [-0.022, 0.022] {
            rig.base[0].add(Prim.cylinder(radius: 0.005, height: 0.09, bevel: 0.001, segments: 8, material: "metal.stainless"),
                            Xform(translation: V3(-0.11, mh - 0.06, z), rotation: .identity))
            rig.base[0].add(Prim.cylinder(radius: 0.014, height: 0.008, bevel: 0.002, segments: 12, material: grip), Xform(translation: V3(-0.11, mh + 0.03, z)))
            rig.base[0].add(Prim.roundedBox(V3(0.012, 0.05, 0.014), radius: 0.004, bevelSegments: 1, material: body), Xform(translation: V3(-0.11, mh - 0.07, z)))
        }
        // Shaft: tilts about the bracket pivot (axis Z). Stowing swings the pod up and aft over the boat.
        rig.part("shaft", pivot: V3(0, mh, 0), joint: .hinge(axis: V3(0, 0, 1), -85...0, duration: 1.2))
        rig.add(Prim.tube([V3(0, podY + 0.02, 0), V3(0, shaftTop, 0)], radii: [0.0125, 0.0125], sides: 12, seamTile: 0.05, material: shaftMaterial, capEnd: true), to: "shaft")
        rig.add(Prim.cylinder(radius: 0.024, height: 0.09, bevel: 0.004, segments: 14, material: body), Xform(translation: V3(0, mh - 0.05, 0)), to: "shaft")
        rig.add(Prim.cylinder(radius: 0.02, height: 0.03, bevel: 0.004, segments: 14, material: body), Xform(translation: V3(0, mh + 0.12, 0)), to: "shaft")
        // Head: steers about the shaft axis and carries the control head and the lower unit.
        rig.part("head", parent: "shaft", pivot: V3(0, shaftTop, 0), joint: .hinge(axis: .up, -90...90, duration: 0.6))
        let headPts: [V3] = (0...8).map { i in let t = Float(i) / 8; return V3(-0.13 + 0.25 * t, shaftTop + 0.045 + 0.01 * sin(t * .pi), 0) }
        let headR: [Float] = (0...8).map { i in let t = Float(i) / 8; return 0.022 + 0.05 * sqrt(sin(min(1, t * 1.15) * .pi * 0.98 + 0.02)) }
        var head = Prim.tube(headPts, radii: headR, sides: 16, seamTile: 0.1, material: body, capEnd: true)
        head.deform { p in V3(p.x, shaftTop + 0.045 + (p.y - shaftTop - 0.045) * 0.75, p.z * 1.05) }
        rig.add(head, to: "head")
        rig.add(Prim.cylinder(radius: 0.03, height: 0.03, bevel: 0.006, segments: 16, material: body), Xform(translation: V3(0, shaftTop - 0.01, 0)), to: "head")
        // Lower unit: bullet pod along X, nose cone forward, skeg below.
        let pod: [V2] = [V2(0, -0.11), V2(0.02, -0.1), V2(0.038, -0.07), V2(0.045, -0.02), V2(0.045, 0.09), V2(0.04, 0.1), V2(0.02, 0.105), V2(0, 0.105)]
        rig.add(Prim.lathe(pod, segments: 18, material: body), Xform(translation: V3(0, podY, 0), rotation: simd_quatf(degrees: -90, axis: V3(0, 0, 1))), to: "head")
        let skeg: [V2] = [V2(0.04, 0), V2(-0.04, 0), V2(0.02, -0.07)]
        rig.add(Prim.extrude(Shape2D.rounded(skeg, radius: 0.006), depth: 0.006, bevel: 0.002, material: body), Xform(translation: V3(0, podY - 0.035, 0)), to: "head")
        rig.add(Prim.cylinder(radius: 0.02, height: 0.03, bevel: 0.004, segments: 14, material: body), Xform(translation: V3(0, podY + 0.03, 0)), to: "head")
        // Prop: two weedless swept blades on a hub behind the pod (-X), spins about X.
        let hubX: Float = -0.115
        rig.part("prop", parent: "head", pivot: V3(hubX, podY, 0), joint: .hinge(axis: V3(1, 0, 0), 0...360, duration: 0.3))
        rig.add(Prim.lathe([V2(0, 0), V2(0.022, 0.002), V2(0.024, 0.03), V2(0.01, 0.045), V2(0, 0.046)], segments: 14, material: body),
                Xform(translation: V3(hubX, podY, 0), rotation: simd_quatf(degrees: 90, axis: V3(0, 0, 1))), to: "prop")
        let R = propDiameter / 2
        let blade: [V2] = [V2(-0.022, 0), V2(0.022, 0), V2(0.05, R * 0.5), V2(0.03, R), V2(-0.015, R * 0.96), V2(-0.042, R * 0.5)]
        for k in 0..<2 {
            let roll = simd_quatf(angle: Float(k) * .pi, axis: V3(1, 0, 0))
            rig.add(Prim.extrude(Shape2D.rounded(blade, radius: 0.008), depth: 0.004, bevel: 0.0015, material: body),
                    Xform(translation: V3(hubX - 0.02, podY, 0), rotation: roll * simd_quatf(degrees: 25, axis: .up) * simd_quatf(degrees: 90, axis: .up)), to: "prop")
        }
        // Tiller: hinged at the front of the head, twist grip with rubber rings.
        rig.part("tiller", parent: "head", pivot: V3(0.12, shaftTop + 0.045, 0), joint: .hinge(axis: V3(0, 0, 1), 0...60, duration: 0.5))
        rig.add(Prim.tube([V3(0.11, shaftTop + 0.045, 0), V3(0.24, shaftTop + 0.045, 0)], radii: [0.016, 0.014], sides: 12, seamTile: 0.05, material: body), to: "tiller")
        rig.add(Prim.tube([V3(0.24, shaftTop + 0.045, 0), V3(0.38, shaftTop + 0.045, 0)], radii: [0.019, 0.017], sides: 14, seamTile: 0.03, material: grip, capEnd: true), to: "tiller")
        for i in 0..<5 {
            rig.add(Prim.torus(major: 0.019, minor: 0.0025, segments: 16, sides: 5, material: grip),
                    Xform(translation: V3(0.26 + Float(i) * 0.025, shaftTop + 0.045, 0), rotation: simd_quatf(degrees: 90, axis: V3(0, 0, 1))), to: "tiller")
        }
        // Battery leads: a twin cable leaving the back of the head and looping down past the bracket.
        let cable = catmull([V3(-0.12, shaftTop + 0.03, 0.01), V3(-0.17, shaftTop - 0.05, 0.03), V3(-0.16, mh + 0.15, 0.05), V3(-0.2, mh, 0.06), V3(-0.26, mh - 0.12, 0.04)], per: 5)
        rig.add(Prim.tube(cable, radii: cable.map { _ in 0.004 }, sides: 6, seamTile: 0.05, material: "rubber.plate:1C1C1C"), to: "head")
        // Depth collar with a knob on the shaft above the bracket.
        rig.add(Prim.cylinder(radius: 0.019, height: 0.035, bevel: 0.004, segments: 14, material: body), Xform(translation: V3(0, mh + 0.2, 0)), to: "shaft")
        rig.add(Prim.cylinder(radius: 0.011, height: 0.03, bevel: 0.003, segments: 10, material: grip), Xform(translation: V3(0.018, mh + 0.217, 0), rotation: simd_quatf(degrees: -90, axis: V3(0, 0, 1))), to: "shaft")
        // Center the rest-pose footprint on X (the tiller and bracket reach forward and aft of the shaft).
        let shift = Xform(translation: V3(-centerOffset, 0, 0))
        for l in rig.base.indices { rig.base[l] = rig.base[l].transformed(shift) }
        for i in rig.parts.indices {
            rig.parts[i].pivot.translation.x -= centerOffset
            for l in rig.parts[i].levels.indices { rig.parts[i].levels[l] = rig.parts[i].levels[l].transformed(shift) }
        }
        rig.states = [
            RigState("deployed"),
            RigState("stowed", ["shaft": -85, "tiller": 0]),
        ]
        return rig
    }
}
