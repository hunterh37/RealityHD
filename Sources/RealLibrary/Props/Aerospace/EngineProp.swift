import simd
import Foundation

/// Electric propeller engine on a 1.25 m mount, 0.9 m tall: steel stack ring and aluminum nacelle
/// tapering to a finned motor housing, painted spinner and a 1.8 m three-blade carbon propeller with
/// twisted airfoil blades and aluminum root ferrules. The disc faces down (-Y), mount on top. States
/// stopped and spinning (rotor turned, blur disc shown); `rotor` is a full-turn joint for live spin.
public struct EngineProp: RealArticulated {
    public static let id = "engine-prop"
    public static let summary = "Electric propeller engine, 1.8 m three-blade carbon prop on a spinner, aluminum nacelle and stack mount; spins."
    public static let tags = ["prop", "aerospace", "metal", "articulated"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 14, distance: 1.0, studio: true)

    /// Propeller diameter in meters.
    public var propDiameter: Float = 1.8
    /// Mount diameter in meters.
    public var mountDiameter: Float = 1.25
    /// Overall height in meters.
    public var height: Float = 0.9
    /// Blade material.
    public var blade: MaterialKey = "composite.carbon"
    /// Spinner paint.
    public var spinner: MaterialKey = "metal.powder-white"
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        var rng = SeededRNG(seed: seed)
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [9])
        let Rm = mountDiameter / 2 - 0.008, H = height
        let hubY: Float = 0.16, motorR: Float = 0.2
        // Tapered cowl from the motor up to a short flared adapter under the mount ring.
        let yc0 = hubY + 0.2, yc1 = H - 0.17, cowlTop: Float = 0.34
        let cowlR: (Float) -> Float = { y in
            if y <= yc1 {
                let t = min(max((y - yc0) / (yc1 - yc0), 0), 1)
                return motorR + 0.03 + (cowlTop - motorR - 0.03) * (1 - pow(1 - t, 1.6))
            }
            let t = min((y - yc1) / (H - 0.04 - yc1), 1)
            return cowlTop + (Rm - 0.01 - cowlTop) * t * t
        }
        for l in 0..<2 {
            var m = Model(name: Self.id)
            let sg = l == 0 ? 48 : 24
            m.add(stackRing(radius: Rm - 0.01, y: H - 0.04, height: 0.04, proud: 0.012, segments: sg, material: "metal.steel"))
            m.add(Prim.lathe([V2(Rm - 0.012, H - 0.004), V2(0, H - 0.004)], segments: sg, material: "metal.aluminum-brushed"))
            // Nacelle: smooth taper from the mount to the motor housing.
            var nac: [V2] = []
            let nn = l == 0 ? 20 : 8
            for k in 0...nn {
                let t = Float(k) / Float(nn)
                let y = yc0 + (H - 0.04 - yc0) * t
                nac.append(V2(cowlR(y), y))
            }
            m.add(Prim.lathe(nac, segments: sg, seamTile: 0.6, material: "metal.aluminum-brushed"))
            // Motor housing with cooling fins.
            m.add(Prim.lathe([V2(motorR - 0.03, hubY + 0.03), V2(motorR, hubY + 0.05), V2(motorR, hubY + 0.2)], segments: sg, seamTile: 0.3,
                             material: "metal.anodized-black"))
            let nf = l == 0 ? 24 : 12
            for k in 0..<nf {
                let a = Float(k) / Float(nf) * 2 * .pi
                m.add(revPatch(radius: { _ in motorR }, a0: a - 0.012, a1: a + 0.012, y0: hubY + 0.06, y1: hubY + 0.19, lift: 0.018,
                               thickness: 0.02, nu: 1, nv: 1, material: "metal.anodized-black"))
            }
            let nr = cowlR
            // Cowl panel line and adapter stringers.
            m.add(Prim.torus(major: cowlR(yc1) + 0.001, minor: 0.004, segments: sg, sides: 6, material: "metal.steel"), Xform(translation: V3(0, yc1, 0)))
            for k in 0..<(l == 0 ? 16 : 8) {
                let a = Float(k) / Float(l == 0 ? 16 : 8) * 2 * .pi
                m.add(revPatch(radius: cowlR, a0: a - 0.015, a1: a + 0.015, y0: yc1 + 0.005, y1: H - 0.045, lift: 0.008, thickness: 0.01,
                               nu: 1, nv: 3, material: "metal.aluminum-brushed"))
            }
            // Exhaust stubs (inverter cooling air) with oil/soot streaks trailing aft (down the cowl toward the prop wash).
            for k in 0..<4 {
                let a = Float(k) / 4 * 2 * .pi + .pi / 4, d = V3(sin(a), 0, cos(a))
                let y0 = yc0 + 0.2, base = d * (cowlR(y0) - 0.004) + V3(0, y0, 0)
                m.add(Prim.lathe([V2(0.024, -0.006), V2(0.024, 0.04), V2(0.02, 0.045), V2(0.018, 0.012)], segments: l == 0 ? 12 : 6,
                                 seamTile: 0.1, material: "metal.heat-tint-cold"),
                      Xform(translation: base, rotation: facing(simd_normalize(d - V3(0, 0.5, 0)))))
                m.add(revPatch(radius: cowlR, a0: a - 0.05, a1: a + 0.05, y0: yc0 + 0.02, y1: y0 - 0.02, lift: 0.0015, thickness: 0.001,
                               nu: 2, nv: 4, material: "metal.powdercoat:2A2622"))
                m.add(revPatch(radius: cowlR, a0: a + 0.07, a1: a + 0.09, y0: yc0 + 0.05, y1: y0 - 0.03, lift: 0.0015, thickness: 0.001,
                               nu: 1, nv: 3, material: "metal.powdercoat:2A2622"))
            }
            if l == 0 {
                for k in 0..<6 {
                    let a = Float(k) / 6 * 2 * .pi + 0.3
                    for p in resample(meridian(nr, a: a, y0: hubY + 0.22, y1: H - 0.06, lift: 0.0005, n: 10), spacing: 0.06) {
                        rivet(&m, at: p, normal: simd_normalize(p - V3(0, p.y, 0)), radius: 0.004, height: 0.002, segments: 5, material: "metal.steel")
                    }
                }
                boltCircle(&m, radius: Rm - 0.035, y: H, count: 20, phase: rng.float(0...0.1), up: true, size: 0.006, material: "metal.steel")
            }
            rig.base[l] = m
        }
        // Rotor: spinner, hub and three blades; option 1 adds a translucent blur disc.
        rig.part("rotor", pivot: V3(0, hubY, 0), joint: .hinge(axis: .up, 0...360, duration: 0.4), options: 2)
        let tipR = propDiameter / 2
        for opt in 0..<2 {
            for l in 0..<2 {
                let sg = l == 0 ? 32 : 16
                var sp: [V2] = []
                for k in 0...8 { let t = Float(k) / 8; sp.append(V2(0.19 * sin(t * .pi / 2), hubY + 0.02 - (hubY + 0.02 - 0.0) * (1 - t))) }
                sp[0] = V2(0, 0.0)
                rig.add(Prim.lathe(sp + [V2(0.19, hubY + 0.03), V2(0.16, hubY + 0.035), V2(0, hubY + 0.035)], segments: sg, seamTile: 0.3,
                                   material: spinner), to: "rotor", option: opt, lods: l...l)
                for b in 0..<3 {
                    let ba = Float(b) / 3 * 2 * .pi
                    var rings: [[V3]] = []
                    let ns = l == 0 ? 10 : 5
                    for k in 0...ns {
                        let t = Float(k) / Float(ns)
                        let span = 0.13 + (tipR - 0.13) * t
                        let chord = (0.2 - 0.1 * t) * (t > 0.92 ? sqrt(max(0.15, (1 - t) / 0.08)) : 1)
                        let thick = chord * (0.16 - 0.07 * t)
                        let twist = (38 - 26 * t) * .pi / 180
                        let outline = Shape2D.superellipse(chord, thick, exponent: 2.2, segments: l == 0 ? 14 : 8)
                        rings.append(outline.map { p in
                            // Chord along Z, thickness along Y, twisted about the span (X).
                            let z = p.x, y = p.y
                            let zz = z * cos(twist) - y * sin(twist), yy = z * sin(twist) + y * cos(twist)
                            return V3(span, hubY + yy, zz)
                        })
                    }
                    // Leading-edge erosion strip (nickel) on the outer 60 % of the span.
                    let le = rings.dropFirst(ns * 2 / 5).map { ring in ring.max { $0.z < $1.z }! }
                    let lea = Array(le)
                    // Chipped strip: gaps where the nickel has eroded, plus chips in the carbon showing light fibre.
                    for i in 0..<(lea.count - 1) where (i + b) % 3 != 1 {
                        rig.add(Prim.tube([lea[i], lea[i + 1]], radii: [0.004, 0.004], sides: 6, seamTile: 0.1, material: "metal.machined", capEnd: true),
                                Xform(rotation: simd_quatf(angle: ba, axis: .up)), to: "rotor", option: opt, lods: l...l)
                    }
                    if l == 0 {
                        for i in stride(from: 1, to: lea.count - 1, by: 3) {
                            rig.add(Prim.roundedBox(V3(0.03, 0.006, 0.008), radius: 0.002, bevelSegments: 1, material: "plastic.matte:8A8478"),
                                    Xform(translation: simd_quatf(angle: ba, axis: .up).act(lea[i] + V3(0.0, 0, -0.002)),
                                          rotation: simd_quatf(angle: ba, axis: .up)), to: "rotor", option: opt, lods: 0...0)
                        }
                    }
                    var bl = Prim.loft(rings, capStart: true, capEnd: true, material: blade)
                    bl = bl.transformed(Xform(rotation: simd_quatf(angle: ba, axis: .up)))
                    rig.add(bl, to: "rotor", option: opt, lods: l...l)
                    // Root ferrule.
                    rig.add(Prim.tube([V3(0.1, hubY, 0), V3(0.2, hubY, 0)], radii: [0.03, 0.026], sides: l == 0 ? 12 : 6, seamTile: 0.1,
                                      material: "metal.aluminum-brushed", capEnd: true),
                            Xform(rotation: simd_quatf(angle: ba, axis: .up)), to: "rotor", option: opt, lods: l...l)
                }
            }
        }
        rig.add(Prim.lathe([V2(tipR, hubY - 0.003), V2(0.16, hubY - 0.003)], segments: 48, material: "glass.frosted"), to: "rotor", option: 1)
        rig.states = [RigState("stopped"), RigState("spinning", ["rotor": 40], options: ["rotor": 1])]
        groundAO(&rig, height: 0.08)
        return rig
    }
}
