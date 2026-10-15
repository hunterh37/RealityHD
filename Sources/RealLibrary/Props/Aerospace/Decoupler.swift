import simd
import Foundation

/// Stack decoupler on the 1.25 m bus, 0.2 m: lower and upper aluminum rings meeting at a machined
/// separation plane, eight pyro bolts in split bosses across the joint, four separation spring cans
/// pushing on plungers in the upper ring, and a yellow/black hazard band. States attached, separated
/// (upper ring slides up 0.25 m, bolt heads leave with it).
public struct Decoupler: RealArticulated {
    public static let id = "decoupler"
    public static let summary = "Stack decoupler, 1.25 m: two aluminum rings held by pyro bolts with separation springs and a yellow and black hazard band."
    public static let tags = ["prop", "aerospace", "metal", "articulated"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 16, distance: 1.0, studio: true)

    /// Diameter in meters.
    public var diameter: Float = 1.25
    /// Overall height in meters.
    public var height: Float = 0.2
    /// Ring material.
    public var ring: MaterialKey = "metal.aluminum-brushed"
    /// Hazard stripe colors.
    public var hazardA: MaterialKey = "metal.painted:E8C21C"
    public var hazardB: MaterialKey = "metal.powdercoat:1C1C1E"
    /// Separation travel at the separated state (meters).
    public var travel: Float = 0.25
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        var rng = SeededRNG(seed: seed)
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [8])
        let R = diameter / 2 - 0.006, H = height, J = H * 0.5
        let shell: (Float) -> Float = { _ in R }
        rig.part("upper", pivot: V3(0, J, 0), joint: .slide(axis: .up, 0...max(travel, 0.01), duration: 0.6))
        for l in 0..<2 {
            var lo = Model(name: Self.id), up = Model(name: "upper")
            let sg = l == 0 ? 48 : 24
            // Lower ring: base lip, wall, machined separation face with a seal groove, inner web plate.
            lo.add(Prim.lathe([V2(R - 0.06, 0.0), V2(R - 0.004, 0.0), V2(R, 0.004), V2(R, J - 0.004), V2(R - 0.003, J - 0.001),
                               V2(R - 0.02, J - 0.001), V2(R - 0.02, J - 0.005), V2(R - 0.03, J - 0.005), V2(R - 0.03, J - 0.001),
                               V2(R - 0.07, J - 0.001), V2(R - 0.07, 0.02), V2(R - 0.06, 0.012)], segments: sg, seamTile: 0.5, material: ring))
            lo.add(Prim.lathe([V2(R - 0.07, 0.03), V2(0, 0.03)], segments: sg, material: ring))
            lo.add(Prim.lathe([V2(0, 0.024), V2(R - 0.07, 0.024)], segments: sg, material: ring))
            // Upper ring (mirror) with the stack lip on top.
            up.add(Prim.lathe([V2(R - 0.07, J + 0.001), V2(R - 0.03, J + 0.001), V2(R - 0.03, J + 0.004), V2(R - 0.02, J + 0.004),
                               V2(R - 0.02, J + 0.001), V2(R - 0.003, J + 0.001), V2(R, J + 0.004), V2(R, H - 0.004), V2(R - 0.004, H),
                               V2(R - 0.06, H), V2(R - 0.07, H - 0.012), V2(R - 0.07, J + 0.001)], segments: sg, seamTile: 0.5, material: ring))
            up.add(Prim.lathe([V2(0, H - 0.03), V2(R - 0.07, H - 0.03)], segments: sg, material: ring))
            up.add(Prim.lathe([V2(R - 0.07, H - 0.024), V2(0, H - 0.024)], segments: sg, material: ring))
            // Hazard band on the lower ring: diagonal-reading alternating blocks.
            let nb = 24
            for k in 0..<nb {
                let a0 = Float(k) / Float(nb) * 2 * .pi
                lo.add(revPatch(radius: shell, a0: a0, a1: a0 + 2 * .pi / Float(nb), y0: 0.022, y1: J - 0.02, lift: 0.0015, thickness: 0.002,
                                nu: l == 0 ? 3 : 1, nv: 1, material: k % 2 == 0 ? hazardA : hazardB))
            }
            // Pyro bolt bosses: split blocks across the joint, bolt head on top of the upper half.
            for k in 0..<8 {
                let a = Float(k) / 8 * 2 * .pi + .pi / 8, d = V3(sin(a), 0, cos(a))
                let q = simd_quatf(angle: a, axis: .up)
                lo.add(Prim.roundedBox(V3(0.07, 0.045, 0.035), radius: 0.004, bevelSegments: 1, material: "metal.steel"),
                       Xform(translation: d * (R + 0.004) + V3(0, J - 0.0235, 0), rotation: q))
                up.add(Prim.roundedBox(V3(0.07, 0.045, 0.035), radius: 0.004, bevelSegments: 1, material: "metal.steel"),
                       Xform(translation: d * (R + 0.004) + V3(0, J + 0.0235, 0), rotation: q))
                if l == 0 {
                    hexBolt(&up, at: d * (R + 0.004) + V3(0, J + 0.046, 0), normal: .up, size: 0.017, material: "metal.steel")
                    // Pyro initiator lead: short orange-sleeved cable into the lower boss.
                    up.add(Prim.tube([d * (R + 0.022) + V3(0, J + 0.03, 0), d * (R + 0.03) + V3(0, J + 0.055, 0), d * (R + 0.008) + V3(0, H - 0.015, 0)],
                                     radii: [0.004, 0.004, 0.004], sides: 6, seamTile: 0.05, material: "plastic.orange", capEnd: true))
                }
            }
            // Separation spring cans (outside, between bosses) with plungers in the upper ring.
            for k in 0..<4 {
                let a = Float(k) / 4 * 2 * .pi, d = V3(sin(a), 0, cos(a))
                let c = d * (R - 0.1)
                lo.add(Prim.roundedBox(V3(0.06, 0.012, 0.05), radius: 0.003, bevelSegments: 1, material: ring),
                       Xform(translation: c + V3(0, 0.03, 0) + d * 0.012, rotation: simd_quatf(angle: a, axis: .up)))
                lo.add(Prim.helix(radius: 0.014, pitch: 0.0075, turns: Float(Int((J - 0.04) / 0.0075)), wire: 0.0022,
                                  perTurn: l == 0 ? 10 : 6, sides: l == 0 ? 4 : 3, material: "metal.steel"),
                       Xform(translation: c + V3(0, 0.036, 0)))
                up.add(Prim.cylinder(radius: 0.017, height: 0.05, bevel: 0.002, segments: l == 0 ? 12 : 6, material: ring),
                       Xform(translation: c + V3(0, J + 0.002, 0)))
                up.add(Prim.roundedBox(V3(0.06, 0.012, 0.05), radius: 0.003, bevelSegments: 1, material: ring),
                       Xform(translation: c + V3(0, J + 0.05, 0) + d * 0.012, rotation: simd_quatf(angle: a, axis: .up)))
            }
            if l == 0 {
                boltCircle(&up, radius: R - 0.035, y: H, count: 20, phase: rng.float(0...0.1), up: true, size: 0.006, material: "metal.steel")
            }
            rig.base[l] = lo
            for s in up.surfaces { rig.add(s, to: "upper", lods: l...l) }
        }
        rig.states = [RigState("attached"), RigState("separated", ["upper": travel])]
        groundAO(&rig, height: 0.06)
        return rig
    }
}
