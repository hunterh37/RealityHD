import simd
import Foundation

/// Wardenclyffe-style Tesla tower, 40 m tall when extended: octagonal brick base with copper roof deck,
/// five nested lattice shaft stages, six ceramic insulators carrying a 12 m copper toroid, a ground ring coil
/// with brass bands and eight ground spike electrodes.
/// Origin at the ground centre of the base, up +Y. Rest pose (every joint 0) is the collapsed tower at 12 m
/// (0.3 of full height); the default state `standing` sets `rise` to 1 (toroid top at 40 m).
/// Joints: `rise` 0...1 (four shaft stages telescope up 7 m each, 28 m total), `charge` 0...1 (coil bands and
/// toroid ring light from the base upward), `spin` 0...1 (toroid turns one revolution about +Y),
/// `spikes` 0...1 (ground electrodes extend 2.5 m).
public struct TeslaTower: RealArticulated {
    public static let id = "tesla-tower"
    public static let summary = "Wardenclyffe-style 40 m Tesla tower, brick octagon base, telescoping lattice shaft, 12 m copper toroid on ceramic insulators, ground ring coil and eight spike electrodes; rise, charge, spin and spikes joints."
    public static let tags = ["prop", "structure", "metal", "brick", "ceramic", "electrical", "glowing", "outdoor", "articulated"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 8, distance: 1.5)

    /// Base octagon apothem (m).
    public var baseApothem: Float = 6.0
    /// Brick base height (m), plinth to cornice.
    public var baseHeight: Float = 5.0
    /// Toroid centre line radius and tube radius (m): 12 m outside diameter.
    public var toroidMajor: Float = 4.8
    public var toroidMinor: Float = 1.2
    /// Brick walls.
    public var brickMaterial: MaterialKey = "brick.unit-red-dark"
    /// Plinth and cornice stone.
    public var trimMaterial: MaterialKey = "concrete.smooth"
    /// Roof deck.
    public var roofMaterial: MaterialKey = "metal.copper-patina"
    /// Window frames.
    public var windowMaterial: MaterialKey = "metal.cast-iron-worn"
    /// Lattice shaft steel.
    public var shaftMaterial: MaterialKey = "metal.galvanized-aged"
    /// Toroid skin, polished copper.
    public var copperMaterial: MaterialKey = "metal.copper"
    /// Coil bands uncharged, studs, hub and spikes.
    public var brassMaterial: MaterialKey = "metal.brass"
    public var brassAgedMaterial: MaterialKey = "metal.brass-aged"
    /// Ceramic insulators and spike collars.
    public var insulatorMaterial: MaterialKey = "ceramic.porcelain-gray"
    /// Coil bands and toroid ring when charged.
    public var chargedMaterial: MaterialKey = "emissive.thruster-cyan"
    public init() {}

    private static let stageTravel: Float = 7
    private static let stageLo: Float = 0.6
    private static let stageHi: Float = 9.6

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 1)
        var rng = SeededRNG(seed: seed)
        let rotX = simd_quatf(angle: -.pi / 2, axis: V3(1, 0, 0))
        let A = baseApothem, topY = Self.stageHi
        let hubY = topY + 1.2
        let toroidRest = V3(0, hubY, 0)

        // MARK: drivers (no geometry), value 0...1
        rig.part("rise", pivot: .zero, joint: Joint(.prismatic, axis: .up, range: 0...1, duration: 6.0))
        rig.part("charge", pivot: .zero, joint: Joint(.prismatic, axis: .up, range: 0...1, duration: 3.0))
        rig.part("spin", pivot: .zero, joint: Joint(.prismatic, axis: .up, range: 0...1, duration: 4.0))
        rig.part("spikes", pivot: .zero, joint: Joint(.prismatic, axis: .up, range: 0...1, duration: 2.0))

        // MARK: octagonal brick base: plinth, body, cornice, roof deck
        func octagon(_ apothem: Float) -> [V2] {
            let r = apothem / cos(.pi / 8)
            return (0..<8).map { k in let a = (Float(k) + 0.5) * .pi / 4; return V2(r * cos(a), r * sin(a)) }
        }
        func prism(_ apothem: Float, _ y0: Float, _ y1: Float, _ mat: MaterialKey) {
            let s = Prim.extrude(octagon(apothem), depth: y1 - y0, bevel: 0.04, material: mat)
            rig.base[0].add(s, Xform(translation: V3(0, (y0 + y1) / 2, 0), rotation: rotX))
        }
        let corniceY = baseHeight
        prism(A + 0.5, 0, 0.7, trimMaterial)
        prism(A, 0.7, corniceY - 0.5, brickMaterial)
        prism(A + 0.5, corniceY - 0.5, corniceY, trimMaterial)
        prism(A + 0.2, corniceY, corniceY + 0.2, roofMaterial)
        // Four cast-iron windows on the cardinal faces.
        for k in 0..<4 {
            let a = Float(k) * .pi / 2
            let dir = V3(cos(a), 0, -sin(a))
            let w = Prim.extrude(Shape2D.rect(1.2, 2.4), depth: 0.3, bevel: 0.03, material: windowMaterial)
            rig.base[0].add(w, Xform(translation: dir * (A + 0.02) + V3(0, 2.7, 0), rotation: simd_quatf(angle: .pi / 2 + a, axis: .up)))
        }

        // MARK: ground ring coil with eight brass bands (option 1 charged)
        let ringMajor: Float = 9.2, ringMinor: Float = 0.45
        rig.base[0].add(Prim.torus(major: ringMajor, minor: ringMinor, segments: 48, sides: 10, minorY: nil, material: copperMaterial),
                        Xform(translation: V3(0, ringMinor, 0)))
        rig.part("coilBands", pivot: .zero, joint: .fixed, options: 2)
        for k in 0..<8 {
            let a = Float(k) * .pi / 4
            for o in 0..<2 {
                let band = Prim.torus(major: ringMajor, minor: ringMinor + 0.07, segments: 3, sides: 8, arc: 0.42,
                                      material: o == 0 ? brassAgedMaterial : chargedMaterial)
                rig.add(band, Xform(translation: V3(0, ringMinor, 0), rotation: simd_quatf(angle: a, axis: .up)), to: "coilBands", option: o)
            }
        }

        // MARK: ground spike electrodes, eight at 11.6 m, extend 2.5 m with `spikes`
        let spikeProfile: [V2] = [V2(0, -3), V2(0.22, -3), V2(0.22, -0.3), V2(0.12, 0.4), V2(0.1, 0.8), V2(0.3, 1.0), V2(0.28, 1.3), V2(0, 1.5)]
        let collarProfile: [V2] = [V2(0.7, 0), V2(0.7, 0.18), V2(0.4, 0.5), V2(0.28, 0.5)]
        for k in 0..<8 {
            let a = (Float(k) + 0.5) * .pi / 4
            let p = V3(11.6 * cos(a), 0, -11.6 * sin(a))
            let name = "spike\(k)"
            rig.part(name, pivot: p, joint: Joint(.prismatic, axis: .up, range: 0...2.5, duration: 2.0, mimic: .init("spikes", ratio: 2.5)))
            rig.add(Prim.lathe(spikeProfile, segments: 16, seamTile: 0.2, material: brassMaterial), Xform(translation: p), to: name)
            rig.base[0].add(Prim.lathe(collarProfile, segments: 16, seamTile: 0.2, material: insulatorMaterial), Xform(translation: p))
        }

        // MARK: telescoping lattice shaft, stage 0 fixed, stages 1...4 each rise 7 m
        func beam(_ a: V3, _ b: V3, _ r: Float, _ mat: MaterialKey) -> Surface {
            Prim.tube([a, b], radii: [r, r], sides: 4, seamTile: 0.2, material: mat)
        }
        func ringPath(_ y: Float, _ w: Float) -> [V3] {
            [V3(w, y, w), V3(-w, y, w), V3(-w, y, -w), V3(w, y, -w), V3(w, y, w)]
        }
        for stage in 0..<5 {
            let part = stage == 0 ? nil : "stage\(stage)"
            if let part {
                rig.part(part, parent: stage > 1 ? "stage\(stage - 1)" : nil, pivot: .zero,
                         joint: Joint(.prismatic, axis: .up, range: 0...Self.stageTravel, duration: 1.8, mimic: .init("rise", ratio: Self.stageTravel)))
            }
            let w0 = 1.9 - 0.25 * Float(stage), w1 = w0 * 0.9
            let y0 = stage == 0 ? baseHeight : Self.stageLo, y1 = topY
            func width(_ y: Float) -> Float { w0 + (w1 - w0) * (y - y0) / (y1 - y0) }
            var parts: [Surface] = []
            for sx in [Float(1), -1] { for sz in [Float(1), -1] {
                parts.append(beam(V3(sx * w0, y0, sz * w0), V3(sx * w1, y1, sz * w1), 0.09, shaftMaterial))
            }}
            let levels: [Float] = [y0, (y0 + y1) / 2, y1]
            for y in levels {
                let w = width(y), c = ringPath(y, w)
                for i in 0..<4 { parts.append(beam(c[i], c[i + 1], 0.05, shaftMaterial)) }
            }
            for bay in 0..<2 {
                let ya = levels[bay], yb = levels[bay + 1], wa = width(ya), wb = width(yb)
                let ca = ringPath(ya, wa), cb = ringPath(yb, wb)
                for i in 0..<4 {
                    let flip = (i + bay) % 2 == 0
                    parts.append(beam(flip ? ca[i] : ca[i + 1], flip ? cb[i + 1] : cb[i], 0.04, shaftMaterial))
                }
            }
            for s in parts {
                if let part { rig.add(s, to: part) } else { rig.base[0].add(s, .identity) }
            }

            // Coil band: square brass loop near the stage top, option 1 charged.
            let bandName = "bands\(stage)"
            rig.part(bandName, parent: part, pivot: .zero, joint: .fixed, options: 2)
            let by = y1 - 0.45, bw = width(by) + 0.12
            for o in 0..<2 {
                let loop = Prim.tube(ringPath(by, bw), radii: Array(repeating: 0.11, count: 5), sides: 6, seamTile: 0.2,
                                     material: o == 0 ? brassAgedMaterial : chargedMaterial)
                rig.add(loop, to: bandName, option: o)
            }
        }

        // MARK: hub and post on stage 4, toroid on six struts with ceramic insulators
        rig.add(Prim.lathe([V2(0, topY), V2(0.9, topY), V2(0.9, topY + 0.15), V2(0.45, topY + 0.3), V2(0.45, topY + 0.6)],
                           segments: 16, seamTile: 0.2, material: insulatorMaterial), to: "stage4")
        let hub: [V2] = [V2(0, -0.9), V2(0.5, -0.78), V2(0.8, -0.4), V2(0.9, 0), V2(0.8, 0.4), V2(0.5, 0.78), V2(0, 0.9)]
        rig.add(Prim.lathe(hub, segments: 24, seamTile: 0.2, material: brassMaterial), Xform(translation: toroidRest), to: "stage4")

        rig.part("toroid", parent: "stage4", pivot: toroidRest,
                 joint: Joint(.revolute, axis: .up, range: 0...360, duration: 4.0, mimic: .init("spin", ratio: 360)))
        rig.add(Prim.torus(major: toroidMajor, minor: toroidMinor, segments: 64, sides: 20, material: copperMaterial),
                Xform(translation: toroidRest), to: "toroid")
        let discs: [V2] = [V2(0, 0), V2(0.34, 0), V2(0.34, 0.08), V2(0.2, 0.14), V2(0.2, 0.3), V2(0.34, 0.36), V2(0.34, 0.44), V2(0, 0.44)]
        for k in 0..<6 {
            let a = Float(k) * .pi / 3
            let dir = V3(cos(a), 0, -sin(a))
            rig.add(Prim.tube([toroidRest + dir * 0.8, toroidRest + dir * (toroidMajor - toroidMinor + 0.1)], radii: [0.14, 0.14],
                              sides: 8, seamTile: 0.2, material: brassMaterial), to: "toroid")
            let tilt = simd_quatf(from: .up, to: dir)
            rig.add(Prim.lathe(discs, segments: 16, seamTile: 0.2, material: insulatorMaterial),
                    Xform(translation: toroidRest + dir * 1.5, rotation: tilt), to: "toroid")
        }
        // Six brass studs at uneven angles on the crown, so the spin reads.
        for k in 0..<6 {
            let a = (Float(k) + rng.float(-0.3...0.3)) * .pi / 3 + 0.4
            let r = toroidMajor + rng.float(-0.35...0.35)
            let dome: [V2] = [V2(0, 0), V2(0.24, 0), V2(0.2, 0.12), V2(0.1, 0.2), V2(0, 0.22)]
            rig.add(Prim.lathe(dome, segments: 12, seamTile: 0.2, material: brassMaterial),
                    Xform(translation: toroidRest + V3(r * cos(a), toroidMinor - 0.02, -r * sin(a))), to: "toroid")
        }
        // Charged ring on the inner equator.
        rig.part("toroidBands", parent: "toroid", pivot: .zero, joint: .fixed, options: 2)
        for o in 0..<2 {
            rig.add(Prim.torus(major: toroidMajor - toroidMinor - 0.02, minor: 0.13, segments: 48, sides: 6,
                               material: o == 0 ? brassAgedMaterial : chargedMaterial),
                    Xform(translation: toroidRest), to: "toroidBands", option: o)
        }

        // Charge climbs from the ground coil to the toroid.
        let links: [(String, Float)] = [("coilBands", 0.1), ("bands0", 0.25), ("bands1", 0.4), ("bands2", 0.55),
                                        ("bands3", 0.7), ("bands4", 0.82), ("toroidBands", 0.92)]
        rig.optionLinks = links.map { RigOptionLink(part: $0.0, joint: "charge", thresholds: [$0.1]) }
        rig.lights = [
            RigLight(name: "coil-glow", part: "coilBands", option: 1, position: V3(0, 1.5, 0), direction: V3(0, 1, 0),
                     color: V3(0.45, 0.8, 1), intensity: 9000, attenuationRadius: 35),
            RigLight(name: "toroid-glow", part: "toroidBands", option: 1, position: toroidRest, direction: V3(0, -1, 0),
                     color: V3(0.55, 0.85, 1), intensity: 30000, attenuationRadius: 80),
        ]

        let allOn = Dictionary(uniqueKeysWithValues: links.map { ($0.0, 1) })
        rig.states = [
            RigState("standing", ["rise": 1]),
            RigState("retracted"),
            RigState("rising", ["rise": 0.5]),
            RigState("spikes-out", ["rise": 1, "spikes": 1]),
            RigState("spinning", ["rise": 1, "spin": 0.5]),
            RigState("charged", ["rise": 1, "charge": 1, "spikes": 1], options: allOn),
            RigState("discharge", ["rise": 1, "charge": 1, "spin": 0.75, "spikes": 1], options: allOn),
        ]
        return rig
    }
}
