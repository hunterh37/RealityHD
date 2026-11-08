import simd
import Foundation

/// Ancient ring gate, 8 m outside diameter: dark granite outer ring, a machined inner ring carrying nine
/// glyph panels, nine chevron locks on the outer ring, a translucent event-horizon disc with an emissive rim,
/// a three-legged iron tripod stand on a granite platform and a ramp that slides out from the platform.
/// Origin at the ground under the ring centre (ring centre 4.6 m up), the ring faces +Z, up +Y.
/// Rest pose (every joint 0) is the dormant gate: chevrons dark, no event horizon, ramp stowed.
/// Joints: `spin` 0...1 (inner ring turns one revolution about +Z), `lock` 0...1 (chevrons light in sequence,
/// top chevron first), `open` 0...1 (event horizon disc, shown above 0.05), `ramp` 0...1 (ramp extends 4 m toward +Z).
public struct ChevronGate: RealArticulated {
    public static let id = "chevron-gate"
    public static let summary = "8 m dark granite ring gate with a spinning glyph ring, nine amber chevron locks, a translucent event-horizon disc, tripod stand and extending ramp; spin, lock, open and ramp joints."
    public static let tags = ["prop", "structure", "stone", "rock", "metal", "glowing", "water", "outdoor", "articulated"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 6, distance: 1.6)

    /// Outer ring centre line radius and tube radius (m): 8 m outside diameter.
    public var ringMajor: Float = 3.6
    public var ringMinor: Float = 0.4
    /// Height of the ring centre above the ground (m).
    public var centerHeight: Float = 4.6
    /// Outer ring granite.
    public var ringMaterial: MaterialKey = "rock.granite"
    /// Glyph panels and platform slab.
    public var panelMaterial: MaterialKey = "rock.granite-bare"
    /// Machined inner ring and glyph insets.
    public var innerRingMaterial: MaterialKey = "metal.bronze-weathered"
    /// Dormant chevrons, tripod legs and feet.
    public var ironMaterial: MaterialKey = "metal.iron"
    /// Chevrons when locked.
    public var lockedMaterial: MaterialKey = "emissive.amber"
    /// Event horizon water.
    public var horizonMaterial: MaterialKey = "glass.water-clear"
    /// Event horizon rim.
    public var rimMaterial: MaterialKey = "emissive.thruster-cyan"
    /// Ramp.
    public var rampMaterial: MaterialKey = "concrete.ramp-cast"
    public init() {}

    private static let chevronCount = 9
    private static let rampTravel: Float = 4

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 1)
        var rng = SeededRNG(seed: seed)
        let rotX = simd_quatf(angle: -.pi / 2, axis: V3(1, 0, 0))
        let faceRing = simd_quatf(angle: .pi / 2, axis: V3(1, 0, 0))
        let cy = centerHeight
        let center = V3(0, cy, 0)
        let step = 2 * Float.pi / Float(Self.chevronCount)
        let n = Self.chevronCount

        // MARK: drivers (no geometry), value 0...1
        rig.part("spin", pivot: .zero, joint: Joint(.prismatic, axis: .up, range: 0...1, duration: 5.0))
        rig.part("lock", pivot: .zero, joint: Joint(.prismatic, axis: .up, range: 0...1, duration: 4.5))
        rig.part("open", pivot: .zero, joint: Joint(.prismatic, axis: .up, range: 0...1, duration: 1.5))
        rig.part("ramp", pivot: .zero, joint: Joint(.prismatic, axis: .up, range: 0...1, duration: 3.0))

        // MARK: granite platform, 9.2 m by 4 m, 0.4 m thick, ring side toward -Z
        let slab = Prim.extrude(Shape2D.rect(9.2, 4.0), depth: 0.4, bevel: 0.04, material: panelMaterial)
        rig.base[0].add(slab, Xform(translation: V3(0, 0.2, 1.0), rotation: rotX))

        // MARK: outer granite ring in the XY plane, facing +Z
        rig.base[0].add(Prim.torus(major: ringMajor, minor: ringMinor, segments: 64, sides: 48, material: ringMaterial),
                        Xform(translation: center, rotation: faceRing))

        // MARK: tripod stand, two front legs and one rear leg under the ring
        let legs: [(V3, V3)] = [
            (V3(-3.2, 0.4, 0.9), center + V3(-2.55, -2.55, 0)),
            (V3(3.2, 0.4, 0.9), center + V3(2.55, -2.55, 0)),
            (V3(0, 0.4, -1.6), center + V3(0, -ringMajor, -0.15)),
        ]
        let footProfile: [V2] = [V2(0, 0), V2(0.62, 0), V2(0.62, 0.1), V2(0.4, 0.22), V2(0.3, 0.3), V2(0, 0.3)]
        for (foot, top) in legs {
            rig.base[0].add(Prim.tube([foot, top], radii: [0.2, 0.15], sides: 48, seamTile: 0.2, material: ironMaterial), .identity)
            rig.base[0].add(Prim.lathe(footProfile, segments: 48, seamTile: 0.2, material: ironMaterial), Xform(translation: foot))
        }

        // MARK: inner ring, machined bronze band that turns about +Z with `spin`
        let spinPivot = center
        rig.part("innerRing", pivot: spinPivot,
                 joint: Joint(.revolute, axis: V3(0, 0, 1), range: 0...360, duration: 5.0, mimic: .init("spin", ratio: 360)))
        let band: [V2] = [V2(2.55, -0.14), V2(3.12, -0.14), V2(3.16, -0.10), V2(3.16, 0.10), V2(3.12, 0.14),
                          V2(2.55, 0.14), V2(2.51, 0.10), V2(2.51, -0.10), V2(2.55, -0.14)]
        rig.add(Prim.lathe(band, segments: 96, seamTile: 0.2, material: innerRingMaterial),
                Xform(translation: center, rotation: faceRing), to: "innerRing")
        // Nine glyph panels with bronze insets, offset half a step from the chevrons. Inset size and tilt vary by seed.
        for k in 0..<n {
            let a = Float.pi / 2 + (Float(k) + 0.5) * step
            let pos = center + V3(2.83 * cos(a), 2.83 * sin(a), 0.18)
            let spinZ = simd_quatf(angle: a - .pi / 2, axis: V3(0, 0, 1))
            let panel = Prim.extrude(Shape2D.rect(0.5, 0.46), depth: 0.08, bevel: 0.015, material: panelMaterial)
            rig.add(panel, Xform(translation: pos, rotation: spinZ), to: "innerRing")
            let w = rng.float(0.16...0.3), tilt = rng.float(-0.4...0.4)
            let inset = Prim.extrude(Shape2D.rect(w, 0.1), depth: 0.04, bevel: 0.01, material: innerRingMaterial)
            let insetRot = spinZ * simd_quatf(angle: tilt, axis: V3(0, 0, 1))
            rig.add(inset, Xform(translation: pos + V3(0, 0, 0.05), rotation: insetRot), to: "innerRing")
        }

        // MARK: nine chevron locks on the outer ring, option 0 dormant iron, option 1 locked amber
        let chevron: [V2] = [V2(0, 0.4), V2(0.5, -0.1), V2(0.5, -0.4), V2(0, 0.1), V2(-0.5, -0.4), V2(-0.5, -0.1)]
        for k in 0..<n {
            let a = Float.pi / 2 + Float(k) * step
            let name = "chev\(k)"
            rig.part(name, pivot: .zero, joint: .fixed, options: 2)
            let pos = center + V3(ringMajor * cos(a), ringMajor * sin(a), ringMinor + 0.03)
            let rot = simd_quatf(angle: a + .pi / 2, axis: V3(0, 0, 1))
            for o in 0..<2 {
                let s = Prim.extrude(chevron, depth: 0.14, bevel: 0.02, material: o == 0 ? ironMaterial : lockedMaterial)
                rig.add(s, Xform(translation: pos, rotation: rot), to: name, option: o)
            }
        }

        // MARK: event horizon, translucent water disc with an emissive rim, option 1 only
        rig.part("horizon", pivot: .zero, joint: .fixed, options: 2)
        let disc = Prim.extrude(Shape2D.circle(2.5, segments: 96), depth: 0.06, bevel: 0.015, material: horizonMaterial)
        rig.add(disc, Xform(translation: center + V3(0, 0, -0.02)), to: "horizon", option: 1)
        rig.add(Prim.torus(major: 2.47, minor: 0.07, segments: 96, sides: 16, material: rimMaterial),
                Xform(translation: center + V3(0, 0, 0.02), rotation: faceRing), to: "horizon", option: 1)

        // MARK: ramp, a 3 m wide wedge stowed inside the platform, slides out 4 m toward +Z
        rig.part("rampPlate", pivot: .zero,
                 joint: Joint(.prismatic, axis: V3(0, 0, 1), range: 0...Self.rampTravel, duration: 3.0, mimic: .init("ramp", ratio: Self.rampTravel)))
        let wedge: [V2] = [V2(0, 0), V2(4, 0), V2(4, 0.03), V2(0, 0.38)]
        let alongZ = simd_quatf(angle: -.pi / 2, axis: .up)
        rig.add(Prim.extrude(wedge, depth: 3.0, bevel: 0.01, material: rampMaterial),
                Xform(translation: V3(0, 0.001, -1.0), rotation: alongZ), to: "rampPlate")

        // MARK: option links and lights
        var links: [RigOptionLink] = (0..<n).map { RigOptionLink(part: "chev\($0)", joint: "lock", thresholds: [Float($0 + 1) / Float(n + 1)]) }
        links.append(RigOptionLink(part: "horizon", joint: "open", thresholds: [0.05]))
        rig.optionLinks = links
        rig.lights = [
            RigLight(name: "chevron-glow", part: "chev0", option: 1, position: center + V3(0, ringMajor, 1.2), direction: V3(0, 0, 1),
                     color: V3(1, 0.62, 0.2), intensity: 6000, attenuationRadius: 20),
            RigLight(name: "horizon-glow", part: "horizon", option: 1, position: center + V3(0, 0, 0.6), direction: V3(0, 0, 1),
                     color: V3(0.5, 0.82, 1), intensity: 24000, attenuationRadius: 40),
        ]

        func opts(lock: Float, open: Float) -> [String: Int] {
            var o = Dictionary(uniqueKeysWithValues: links.dropLast().map { ($0.part, $0.option(lock)) })
            o["horizon"] = links.last!.option(open)
            return o
        }
        rig.states = [
            RigState("dormant"),
            RigState("spinning", ["spin": 0.5]),
            RigState("locking", ["spin": 0.25, "lock": 0.5], options: opts(lock: 0.5, open: 0)),
            RigState("locked", ["lock": 1], options: opts(lock: 1, open: 0)),
            RigState("open", ["lock": 1, "open": 1], options: opts(lock: 1, open: 1)),
            RigState("open-ramp", ["lock": 1, "open": 1, "ramp": 1], options: opts(lock: 1, open: 1)),
        ]
        return rig
    }
}
