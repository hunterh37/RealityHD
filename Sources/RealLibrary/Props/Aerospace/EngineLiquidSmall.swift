import simd
import Foundation

/// Small kerolox engine on a 1.25 m mount, 1.5 m tall: aluminum thrust plate with a stack ring, six-strut
/// thrust frame onto a gimbal block, and the gimballed engine (combustion chamber, injector dome,
/// foil-wrapped turbopump with a volute, propellant lines, regeneratively cooled bell with tube ribs,
/// manifolds and heat tint). Gimbal: pitch about X, yaw about Z, ±6 degrees.
public struct EngineLiquidSmall: RealArticulated {
    public static let id = "engine-liquid-small"
    public static let summary = "Small kerolox engine, 1.25 m mount: thrust frame, turbopump, plumbing, gimbal and a tubed bell with heat tint; gimbals in yaw and pitch."
    public static let tags = ["prop", "aerospace", "metal", "articulated"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 10, distance: 1.0, studio: true)

    /// Mount diameter in meters.
    public var diameter: Float = 1.25
    /// Overall height in meters.
    public var height: Float = 1.5
    /// Bell exit radius in meters.
    public var exitRadius: Float = 0.44
    /// Bell metal.
    public var bell: MaterialKey = "metal.heat-tint-cold"
    /// Gimbal range (degrees).
    public var gimbal: Float = 6
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        var rng = SeededRNG(seed: seed)
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [9])
        let R = diameter / 2 - 0.008, H = height
        let plateY = H - 0.07, gY = H - 0.36            // gimbal pivot height
        let chamberTop = gY - 0.06, throatY = gY - 0.42, exitY: Float = 0.004
        rig.part("pitch", pivot: V3(0, gY, 0), joint: .hinge(axis: V3(1, 0, 0), -gimbal...gimbal, duration: 0.5))
        rig.part("yaw", parent: "pitch", pivot: V3(0, gY, 0), joint: .hinge(axis: V3(0, 0, 1), -gimbal...gimbal, duration: 0.5))
        for l in 0..<2 {
            var m = Model(name: Self.id), e = Model(name: "engine")
            let sg = l == 0 ? 48 : 24
            // Thrust plate and stack ring.
            m.add(stackRing(radius: R - 0.01, y: H - 0.04, height: 0.04, proud: 0.012, segments: sg, material: "metal.steel"))
            m.add(Prim.lathe([V2(R - 0.012, plateY), V2(0.16, plateY), V2(0.16, plateY - 0.02), V2(0.12, plateY - 0.03), V2(0, plateY - 0.03)],
                             segments: sg, seamTile: 0.5, material: "metal.aluminum-brushed"))
            m.add(Prim.lathe([V2(0, H - 0.006), V2(R - 0.012, H - 0.006)], segments: sg, material: "metal.aluminum-brushed"))
            m.add(Prim.lathe([V2(R - 0.012, plateY), V2(R - 0.012, H - 0.04)], segments: sg, seamTile: 0.5, material: "insulation.foil-gold"))
            // Thrust frame: six struts from the plate to the gimbal block.
            for k in 0..<6 {
                let a = Float(k) / 6 * 2 * .pi + .pi / 6, d = V3(sin(a), 0, cos(a))
                let top = d * (R - 0.08) + V3(0, plateY - 0.005, 0), bot = d * 0.1 + V3(0, gY + 0.05, 0)
                m.add(Prim.tube([top, bot], radii: [0.022, 0.018], sides: l == 0 ? 10 : 6, seamTile: 0.2, material: "metal.titanium", capEnd: true))
                if l == 0 {
                    m.add(Prim.roundedBox(V3(0.07, 0.02, 0.07), radius: 0.004, bevelSegments: 1, material: "metal.steel"),
                          Xform(translation: top + V3(0, 0.002, 0), rotation: simd_quatf(angle: a, axis: .up)))
                }
            }
            m.add(Prim.roundedBox(V3(0.2, 0.08, 0.2), radius: 0.01, bevelSegments: l == 0 ? 2 : 1, material: "metal.steel"),
                  Xform(translation: V3(0, gY + 0.07, 0)))
            // Gimbal actuators (bodies on the frame; rods meet the chamber collar).
            for a in [Float(0), .pi / 2] {
                let d = V3(sin(a), 0, cos(a))
                let p0 = d * (R - 0.2) + V3(0, plateY - 0.03, 0), p1 = d * 0.17 + V3(0, chamberTop - 0.12, 0)
                let mid = p0 + (p1 - p0) * 0.55
                m.add(Prim.tube([p0, mid], radii: [0.03, 0.03], sides: l == 0 ? 12 : 6, seamTile: 0.2, material: "metal.anodized-black", capEnd: true))
                m.add(Prim.tube([mid, p1], radii: [0.013, 0.013], sides: l == 0 ? 10 : 6, seamTile: 0.1, material: "metal.chrome", capEnd: true))
            }
            // Engine (gimballed): gimbal ball, injector dome, chamber, throat, bell.
            e.add(Prim.lathe([V2(0.0, gY + 0.05), V2(0.05, gY + 0.04), V2(0.06, gY), V2(0.05, gY - 0.04), V2(0.0, gY - 0.05)],
                             segments: 16, material: "metal.machined"))
            e.add(Prim.lathe([V2(0.06, gY - 0.03), V2(0.12, chamberTop + 0.01), V2(0.15, chamberTop - 0.02), V2(0.155, chamberTop - 0.05)],
                             segments: sg, seamTile: 0.3, material: "metal.steel"))
            var ch: [V2] = [V2(0.155, chamberTop - 0.05), V2(0.155, throatY + 0.16)]
            for k in 1...6 { let t = Float(k) / 6; ch.append(V2(0.155 - 0.07 * (1 - cos(t * .pi)) / 2 * 1.0, throatY + 0.16 - 0.16 * t)) }
            e.add(Prim.lathe(ch, segments: sg, seamTile: 0.3, material: "metal.titanium"))
            // Bell with regenerative tube ribs.
            var bp: [V2] = []
            let nbp = l == 0 ? 14 : 7, rt: Float = 0.085
            for k in 0...nbp {
                let t = Float(k) / Float(nbp)
                bp.append(V2(rt + (exitRadius - rt) * pow(t, 0.62), throatY - (throatY - exitY) * t))
            }
            var bs = Prim.lathe(bp, segments: l == 0 ? 96 : 32, seamTile: 0.6, material: bell)
            if l == 0 {
                bs.displace { p, _ in
                    let a = atan2(p.x, p.z)
                    return 0.0035 * abs(sin(a * 48))
                }
            }
            e.add(bs)
            e.add(Prim.lathe(bp.reversed().map { V2($0.x - 0.006, $0.y) }, segments: l == 0 ? 48 : 24, seamTile: 0.6, material: "metal.heat-tint-cold"))
            // Manifolds: exit ring and mid-bell coolant manifold.
            e.add(Prim.torus(major: exitRadius + 0.004, minor: 0.012, segments: sg, sides: 8, material: "metal.steel"), Xform(translation: V3(0, exitY + 0.008, 0)))
            let mt: Float = 0.35, mr = rt + (exitRadius - rt) * pow(mt, 0.62), my = throatY - (throatY - exitY) * mt
            e.add(Prim.torus(major: mr + 0.012, minor: 0.018, segments: sg, sides: 8, material: "metal.steel"), Xform(translation: V3(0, my, 0)))
            // Turbopump on the +X side: foil-wrapped housing, volute, turbine exhaust duct.
            let pc = V3(0.3, throatY + 0.2, 0.05)
            e.add(Prim.cylinder(radius: 0.075, height: 0.22, bevel: 0.01, segments: l == 0 ? 20 : 10, material: "insulation.foil-gold"),
                  Xform(translation: pc + V3(0, -0.11, 0)))
            e.add(Prim.torus(major: 0.07, minor: 0.03, segments: l == 0 ? 20 : 10, sides: 8, material: "metal.steel"), Xform(translation: pc + V3(0, 0.12, 0)))
            e.add(Prim.lathe([V2(0.04, -0.13), V2(0.045, -0.15), V2(0.05, -0.3), V2(0.046, -0.3)], segments: l == 0 ? 14 : 8, seamTile: 0.2,
                             material: "metal.heat-tint-cold"), Xform(translation: pc))
            // Propellant lines: pump to injector (two), pump to manifold.
            let lines: [[V3]] = [
                [pc + V3(-0.03, 0.14, 0), pc + V3(-0.08, 0.3, 0.0), V3(0.13, chamberTop - 0.01, 0.06)],
                [pc + V3(0.0, 0.14, -0.06), pc + V3(-0.05, 0.34, -0.12), V3(0.06, chamberTop + 0.0, -0.12)],
                [pc + V3(-0.06, -0.05, -0.05), V3(0.22, my + 0.12, -0.12), V3(mr * 0.7, my + 0.02, -mr * 0.7)],
            ]
            for (i, path) in lines.enumerated() {
                let pts = catmull(path, per: l == 0 ? 5 : 2)
                e.add(Prim.tube(pts, radii: pts.map { _ in i == 2 ? 0.016 : 0.022 }, sides: l == 0 ? 10 : 6, seamTile: 0.2,
                                material: i == 0 ? "metal.steel" : "metal.titanium", capEnd: true))
            }
            if l == 0 {
                boltCircle(&m, radius: R - 0.035, y: H, count: 20, phase: rng.float(0...0.1), up: true, size: 0.006, material: "metal.steel")
                boltCircle(&e, radius: 0.14, y: chamberTop + 0.005, count: 12, up: true, size: 0.006, material: "metal.steel")
            }
            rig.base[l] = m
            for s in e.surfaces { rig.add(s, to: "yaw", lods: l...l) }
        }
        rig.states = [RigState("neutral"), RigState("pitch", ["pitch": gimbal]), RigState("yaw", ["yaw": gimbal]),
                      RigState("pitch-yaw", ["pitch": -gimbal, "yaw": -gimbal])]
        groundAO(&rig, height: 0.1)
        return rig
    }
}
