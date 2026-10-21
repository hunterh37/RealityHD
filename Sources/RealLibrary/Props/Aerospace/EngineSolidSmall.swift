import simd
import Foundation

/// Small solid rocket motor (radial booster), 0.6 m by 1.8 m: white-painted steel case with a factory
/// joint band and raceway, ogive nose cap with a carbon tip, forward and aft attach lugs, flared aft
/// skirt and a charred, heat-tinted nozzle. States idle and burning (exhaust flame and its light).
public struct EngineSolidSmall: RealArticulated {
    public static let id = "engine-solid-small"
    public static let summary = "Small solid rocket motor, 0.6 m by 1.8 m: white steel case with an ogive cap, attach lugs, aft skirt and a charred nozzle; burning state shows the flame."
    public static let tags = ["prop", "aerospace", "metal", "articulated"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 12, distance: 1.0, studio: true)

    /// Case diameter in meters.
    public var diameter: Float = 0.6
    /// Overall height (nozzle exit to nose tip) in meters.
    public var height: Float = 1.8
    /// Case paint.
    public var paint: MaterialKey = "metal.powder-white"
    /// Nozzle metal.
    public var nozzle: MaterialKey = "metal.heat-tint-cold"
    /// Exhaust flame length in the burning state (meters).
    public var flameLength: Float = 1.6
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        var rng = SeededRNG(seed: seed)
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [8])
        let R = diameter / 2 - 0.004, H = height
        let yNoz: Float = 0.26, ySkirt: Float = 0.4, yCap = H - 0.36
        let caseR: (Float) -> Float = { _ in R }
        for l in 0..<2 {
            var m = Model(name: Self.id)
            let sg = l == 0 ? 48 : 24
            // Nozzle: bell from the throat housing to the exit, charred ablative liner inside.
            var bell: [V2] = []
            let nb = l == 0 ? 10 : 5
            for k in 0...nb {
                let t = Float(k) / Float(nb)
                bell.append(V2(0.19 - 0.1 * pow(t, 0.7), 0.004 + (yNoz - 0.004) * t))
            }
            bell.insert(V2(0.196, 0), at: 0)
            m.add(Prim.lathe(bell, segments: sg, seamTile: 0.4, material: nozzle))
            m.add(Prim.lathe([V2(0.09, yNoz - 0.004), V2(0.08, yNoz - 0.05)] + bell.reversed().dropLast().map { V2($0.x - 0.012, $0.y) } + [V2(0.184, 0.004)],
                             segments: sg, seamTile: 0.3, material: "ablative.char-heavy"))
            m.add(Prim.torus(major: 0.193, minor: 0.006, segments: sg, sides: 6, material: nozzle), Xform(translation: V3(0, 0.004, 0)))
            // Aft closure and skirt: flared painted skirt over the nozzle housing.
            m.add(Prim.lathe([V2(0.09, yNoz), V2(0.16, yNoz + 0.01), V2(R - 0.02, ySkirt - 0.12), V2(R + 0.012, ySkirt - 0.11),
                              V2(R + 0.012, ySkirt - 0.004), V2(R, ySkirt)], segments: sg, seamTile: 0.5, material: "metal.heat-tint-cold"))
            m.add(Prim.lathe([V2(0.09, yNoz), V2(0.09, yNoz + 0.04), V2(0, yNoz + 0.04)], segments: sg, material: "metal.steel"))
            // Case with a factory joint band at mid length.
            let yJ = (ySkirt + yCap) / 2
            m.add(Prim.lathe([V2(R, ySkirt), V2(R, yJ - 0.025)], segments: sg, seamTile: 1, material: paint))
            m.add(Prim.lathe([V2(R, yJ - 0.025), V2(R + 0.008, yJ - 0.02), V2(R + 0.008, yJ + 0.02), V2(R, yJ + 0.025)],
                             segments: sg, seamTile: 0.5, material: "metal.steel"))
            m.add(Prim.lathe([V2(R, yJ + 0.025), V2(R, yCap)], segments: sg, seamTile: 1, material: paint))
            // Ogive nose cap, carbon tip.
            var cap: [V2] = []
            let nc = l == 0 ? 12 : 6, Lc = H - yCap
            let rho = (R * R + Lc * Lc) / (2 * R)
            for k in 0...nc {
                let x = Lc * Float(k) / Float(nc)
                cap.append(V2(max(0, sqrt(rho * rho - x * x) + R - rho), yCap + x))
            }
            let split = nc * 3 / 4
            m.add(Prim.lathe(Array(cap[0...split]), segments: sg, seamTile: 1, material: paint))
            m.add(Prim.lathe(Array(cap[split...]), segments: sg, seamTile: 0.2, material: "composite.carbon"))
            m.add(Prim.torus(major: R + 0.001, minor: 0.005, segments: sg, sides: 6, material: "metal.steel"), Xform(translation: V3(0, yCap, 0)))
            // Black roll band under the cap.
            m.add(Prim.lathe([V2(R + 0.001, yCap - 0.12), V2(R + 0.001, yCap - 0.02)], segments: sg, seamTile: 1, material: "metal.powdercoat:1C1C1E"))
            // Attach lugs (forward and aft) on the -X side, a raceway between them.
            let la: Float = -.pi / 2, ld = V3(sin(la), 0, cos(la))
            for ly in [ySkirt + 0.12, yCap - 0.2] {
                m.add(Prim.roundedBox(V3(0.12, 0.09, 0.03), radius: 0.006, bevelSegments: l == 0 ? 2 : 1, material: "metal.steel"),
                      Xform(translation: ld * (R + 0.01) + V3(0, ly, 0), rotation: simd_quatf(angle: la, axis: .up)))
                m.add(Prim.cylinder(radius: 0.012, height: 0.14, bevel: 0.002, segments: l == 0 ? 12 : 6, material: "metal.machined"),
                      Xform(translation: ld * (R + 0.018) + V3(0, ly, -0.07), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
            }
            let rw: Float = 0.03 / R
            m.add(revPatch(radius: caseR, a0: la + 0.35 - rw, a1: la + 0.35 + rw, y0: ySkirt + 0.02, y1: yCap - 0.03, lift: 0.025,
                           thickness: 0.025, nu: l == 0 ? 3 : 1, nv: 1, material: paint))
            if l == 0 {
                // Igniter port and safe/arm plug on the case, rivet row along the joint band.
                let ia: Float = .pi / 2, id = V3(sin(ia), 0, cos(ia))
                m.add(Prim.lathe([V2(0.03, -0.004), V2(0.03, 0.008), V2(0.022, 0.012), V2(0.022, 0.018), V2(0, 0.018)], segments: 12,
                                 seamTile: 0.1, material: "metal.steel"), Xform(translation: id * R + V3(0, yCap - 0.3, 0), rotation: facing(id)))
                m.add(Prim.roundedBox(V3(0.05, 0.03, 0.01), radius: 0.003, bevelSegments: 1, material: "plastic.orange"),
                      Xform(translation: id * (R + 0.022) + V3(0, yCap - 0.3, 0), rotation: simd_quatf(angle: ia, axis: .up)))
                boltCircle(&m, radius: R + 0.008, y: yJ, count: 16, phase: rng.float(0...0.2), size: 0.005, material: "metal.steel")
            }
            rig.base[l] = m
        }
        // Flame: option 1 of a fixed part below the nozzle exit; a warm point light rides with it.
        rig.part("flame", pivot: .zero, joint: .fixed, options: 2)
        let fl = max(flameLength, 0.2)
        var outer: [V2] = [], core: [V2] = []
        for k in 0...10 {
            let t = Float(k) / 10
            outer.append(V2(0.2 * (1 + 0.35 * sin(t * .pi * 0.8)) * (1 - pow(t, 1.6)) + 0.002, -fl * t))
            core.append(V2(0.13 * (1 - pow(t, 0.9)) + 0.002, -fl * 0.55 * t))
        }
        rig.add(Prim.lathe(outer, segments: 24, seamTile: 0.5, material: "emissive.flame").flipped(), to: "flame", option: 1)
        rig.add(Prim.lathe(outer, segments: 24, seamTile: 0.5, material: "emissive.flame"), to: "flame", option: 1)
        rig.add(Prim.lathe(core, segments: 16, seamTile: 0.5, material: "emissive.warm"), to: "flame", option: 1)
        rig.lights = [RigLight(name: "exhaust", part: "flame", option: 1, position: V3(0, -0.4, 0), color: V3(1, 0.62, 0.3),
                               intensity: 40_000, attenuationRadius: 8)]
        rig.states = [RigState("idle"), RigState("burning", options: ["flame": 1])]
        groundAO(&rig, height: 0.15)
        return rig
    }
}
