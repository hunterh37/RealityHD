import Foundation
import RealCore
import RealMaterials

/// Dinosaurs at real scale (meters). Raw values are stable ids.
public enum DinoSpecies: String, CaseIterable, Codable, Sendable, Identifiable {
    case trex
    case triceratops
    case velociraptor

    public var id: String { rawValue }
    public var profile: DinoProfile { DinoProfile.make(self) }
}

public enum DinoStance: String, Sendable { case biped, quadruped }

/// One cross-section of the body midline. Tail at +z, head at -z, y up.
public struct DinoSection: Sendable {
    public var z, y, halfWidth, halfDorsal, halfVentral: Float
    init(_ z: Float, _ y: Float, _ w: Float, _ d: Float, _ v: Float) { self.z = z; self.y = y; halfWidth = w; halfDorsal = d; halfVentral = v }
}

/// Leg chain at rest on the left side (x > 0 mirrors to the right). Points in meters.
public struct DinoLeg: Sendable {
    public var hip, knee, ankle, ball: V3
    /// Toe length forward of the ball.
    public var toe: Float
    /// Radii: thigh, shin, metatarsus, toe.
    public var radii: V4
}

public struct DinoColors: Sendable {
    public var back: UInt32, belly: UInt32, stripe: UInt32, claw: UInt32, horn: UInt32, eye: UInt32, mouth: UInt32
}

public struct DinoProfile: Sendable {
    public var species: DinoSpecies
    public var stance: DinoStance
    /// Real-scale targets the rig is built to.
    public var targetLength: Float
    public var targetHipHeight: Float
    /// Midline sections from tail tip to snout.
    public var spine: [DinoSection]
    /// Part boundaries along z: tail root, chest start, neck start, head start.
    public var tailRoot, chestZ, neckZ, headZ: Float
    public var jawHinge: V3, chin: V3
    /// Jaw half sizes at the hinge and at the chin (width, depth).
    public var jawHinges: V2, jawTip: V2
    public var hind: DinoLeg
    /// Fore legs (quadrupeds) or arms (bipeds: hip = shoulder, knee = elbow, ankle = hand).
    public var fore: DinoLeg
    public var colors: DinoColors
    public var feathered: Bool
    public var teeth: Int
    /// Scale rows across the body length for the skin atlas.
    public var scaleRows: Float

    public var isBiped: Bool { stance == .biped }
    public var hasSickleClaw: Bool { species == .velociraptor }

    static func make(_ s: DinoSpecies) -> DinoProfile {
        switch s {
        case .trex:
            return DinoProfile(
                species: s, stance: .biped, targetLength: 12, targetHipHeight: 4,
                spine: [
                    .init(6.4, 3.0, 0.05, 0.05, 0.05), .init(5.0, 3.25, 0.18, 0.18, 0.22), .init(3.5, 3.55, 0.32, 0.3, 0.38),
                    .init(2.0, 3.8, 0.45, 0.4, 0.55), .init(0.8, 3.95, 0.62, 0.5, 0.75), .init(0, 3.95, 0.72, 0.55, 0.95),
                    .init(-1.0, 3.75, 0.85, 0.6, 1.2), .init(-2.0, 3.65, 0.8, 0.62, 1.15), .init(-2.8, 3.85, 0.6, 0.55, 0.8),
                    .init(-3.4, 4.15, 0.42, 0.4, 0.5), .init(-3.8, 4.3, 0.4, 0.38, 0.42), .init(-4.05, 4.28, 0.5, 0.46, 0.42),
                    .init(-4.5, 4.17, 0.42, 0.42, 0.3), .init(-5.0, 4.02, 0.3, 0.35, 0.2), .init(-5.4, 3.93, 0.22, 0.27, 0.14),
                    .init(-5.6, 3.88, 0.12, 0.16, 0.08),
                ],
                tailRoot: 1.2, chestZ: -1.2, neckZ: -2.7, headZ: -3.85,
                jawHinge: V3(0, 3.95, -3.95), chin: V3(0, 3.72, -5.45), jawHinges: V2(0.4, 0.26), jawTip: V2(0.16, 0.1),
                hind: DinoLeg(hip: V3(0.55, 3.9, 0.1), knee: V3(0.6, 2.4, -0.45), ankle: V3(0.5, 0.95, 0.25), ball: V3(0.48, 0.14, -0.3), toe: 0.75, radii: V4(0.5, 0.28, 0.16, 0.09)),
                fore: DinoLeg(hip: V3(0.55, 3.0, -2.3), knee: V3(0.62, 2.68, -2.5), ankle: V3(0.6, 2.55, -2.82), ball: V3(0.6, 2.5, -2.9), toe: 0.14, radii: V4(0.11, 0.08, 0.05, 0.03)),
                colors: DinoColors(back: 0x4A4231, belly: 0xB9A783, stripe: 0x2B261C, claw: 0x2A2420, horn: 0x5A5040, eye: 0xB07818, mouth: 0x8A3A3A),
                feathered: false, teeth: 12, scaleRows: 160)
        case .triceratops:
            return DinoProfile(
                species: s, stance: .quadruped, targetLength: 8, targetHipHeight: 2,
                spine: [
                    .init(3.2, 1.35, 0.05, 0.05, 0.05), .init(2.4, 1.65, 0.15, 0.14, 0.17), .init(1.4, 2.0, 0.3, 0.25, 0.35),
                    .init(0.5, 2.2, 0.7, 0.45, 0.75), .init(0, 2.25, 0.85, 0.5, 0.9), .init(-0.8, 2.2, 1.0, 0.55, 1.0),
                    .init(-1.6, 2.0, 0.95, 0.5, 0.95), .init(-2.3, 1.75, 0.7, 0.45, 0.75), .init(-2.7, 1.6, 0.5, 0.38, 0.5),
                    .init(-3.0, 1.6, 0.5, 0.4, 0.45), .init(-3.6, 1.45, 0.4, 0.38, 0.35), .init(-4.2, 1.3, 0.25, 0.3, 0.22),
                    .init(-4.6, 1.2, 0.12, 0.22, 0.12), .init(-4.8, 1.12, 0.05, 0.12, 0.08),
                ],
                tailRoot: 0.9, chestZ: -0.8, neckZ: -2.4, headZ: -2.85,
                jawHinge: V3(0, 1.35, -3.1), chin: V3(0, 0.98, -4.7), jawHinges: V2(0.38, 0.22), jawTip: V2(0.06, 0.08),
                hind: DinoLeg(hip: V3(0.6, 2.0, 0.3), knee: V3(0.65, 1.15, -0.1), ankle: V3(0.65, 0.4, 0.15), ball: V3(0.65, 0.12, -0.1), toe: 0.28, radii: V4(0.4, 0.23, 0.18, 0.08)),
                fore: DinoLeg(hip: V3(0.75, 1.6, -1.9), knee: V3(0.88, 0.95, -1.75), ankle: V3(0.86, 0.35, -1.85), ball: V3(0.86, 0.1, -1.95), toe: 0.2, radii: V4(0.3, 0.19, 0.15, 0.07)),
                colors: DinoColors(back: 0x5B5236, belly: 0xC2B28A, stripe: 0x6E3A22, claw: 0x2E2822, horn: 0xD8CDB0, eye: 0x6A4A14, mouth: 0x7A3A34),
                feathered: false, teeth: 0, scaleRows: 110)
        case .velociraptor:
            return DinoProfile(
                species: s, stance: .biped, targetLength: 2, targetHipHeight: 0.55,
                spine: [
                    .init(1.15, 0.62, 0.015, 0.015, 0.015), .init(0.8, 0.6, 0.03, 0.03, 0.035), .init(0.4, 0.6, 0.05, 0.045, 0.055),
                    .init(0.12, 0.6, 0.08, 0.07, 0.09), .init(0, 0.6, 0.1, 0.08, 0.12), .init(-0.2, 0.58, 0.11, 0.08, 0.14),
                    .init(-0.38, 0.6, 0.09, 0.07, 0.1), .init(-0.5, 0.68, 0.05, 0.05, 0.06), .init(-0.56, 0.78, 0.045, 0.045, 0.05),
                    .init(-0.6, 0.82, 0.05, 0.05, 0.045), .init(-0.68, 0.81, 0.04, 0.04, 0.025), .init(-0.78, 0.79, 0.025, 0.028, 0.015),
                    .init(-0.85, 0.78, 0.012, 0.014, 0.008),
                ],
                tailRoot: 0.15, chestZ: -0.2, neckZ: -0.42, headZ: -0.58,
                jawHinge: V3(0, 0.8, -0.6), chin: V3(0, 0.765, -0.83), jawHinges: V2(0.04, 0.025), jawTip: V2(0.012, 0.01),
                hind: DinoLeg(hip: V3(0.07, 0.56, 0.02), knee: V3(0.08, 0.38, -0.1), ankle: V3(0.075, 0.17, 0.05), ball: V3(0.075, 0.02, -0.02), toe: 0.1, radii: V4(0.055, 0.03, 0.02, 0.011)),
                fore: DinoLeg(hip: V3(0.07, 0.53, -0.38), knee: V3(0.09, 0.45, -0.3), ankle: V3(0.09, 0.44, -0.45), ball: V3(0.09, 0.43, -0.48), toe: 0.05, radii: V4(0.02, 0.015, 0.01, 0.005)),
                colors: DinoColors(back: 0x7A5634, belly: 0xD4C29E, stripe: 0x2E2216, claw: 0x1E1A16, horn: 0x3A3028, eye: 0xC89018, mouth: 0x9A4A44),
                feathered: true, teeth: 10, scaleRows: 60)
        }
    }

    /// Midline section at `z`, interpolated.
    public func section(at z: Float) -> DinoSection {
        let sp = spine
        if z >= sp[0].z { return sp[0] }
        if z <= sp[sp.count - 1].z { return sp[sp.count - 1] }
        for i in 0..<(sp.count - 1) where z <= sp[i].z && z >= sp[i + 1].z {
            let a = sp[i], b = sp[i + 1], t = (a.z - z) / (a.z - b.z)
            func l(_ x: Float, _ y: Float) -> Float { x + (y - x) * t }
            return DinoSection(z, l(a.y, b.y), l(a.halfWidth, b.halfWidth), l(a.halfDorsal, b.halfDorsal), l(a.halfVentral, b.halfVentral))
        }
        return sp[sp.count - 1]
    }
}

/// Material keys and specs for dinosaurs: `dino.<species>.<region>`. AnimalKit registers them as overrides.
public enum DinoMaterials {
    public enum Region: String, CaseIterable, Sendable {
        case skin, head, limb, claw, tooth, eye, horn, mouth, feather, featherCard, frill
    }
    public static func key(_ s: DinoSpecies, _ r: Region) -> MaterialKey { "dino.\(s.rawValue).\(r.rawValue)" }

    public static func specs(for p: DinoProfile) -> [MaterialSpec] {
        let c = p.colors, s = p.species
        var seed: UInt32 = 9400 + UInt32(DinoSpecies.allCases.firstIndex(of: s)!) * 16
        func make(_ r: Region, _ prog: TextureProgram, _ edit: (inout MaterialSpec) -> Void) -> MaterialSpec {
            seed += 1
            return MaterialSpec(key: key(s, r), program: prog).with { $0.seed = seed; edit(&$0) }
        }
        func scales(_ rows: Float, around: Float, scute: Float, stripe: Float) -> (inout MaterialSpec) -> Void {
            { $0.colorA = linear(c.back); $0.colorB = linear(c.belly); $0.colorC = linear(c.stripe, around)
              $0.knobs = V4(rows, 0.6, scute, stripe); $0.tileSize = 0; $0.resolution = 2048; $0.normalStrength = 2.4; $0.roughness = 0.72 }
        }
        let limbRows: Float = p.targetLength > 5 ? 14 : 70
        return [
            make(.skin, .dinoScale, scales(p.scaleRows, around: 0.5, scute: p.isBiped ? 0.9 : 0.6, stripe: p.species == .trex ? 0.35 : 0.5)),
            make(.head, .dinoScale, scales(p.targetLength > 5 ? 34 : 30, around: 1.4, scute: 0.3, stripe: 0.15)),
            make(.limb, .dinoScale, scales(limbRows, around: 0.15, scute: 0, stripe: 0)),
            make(.frill, .dinoScale) {
                $0.colorA = linear(c.stripe); $0.colorB = linear(c.belly); $0.colorC = linear(c.back, 1)
                $0.knobs = V4(22, 0.35, 0, 0.8); $0.tileSize = 0; $0.resolution = 1024; $0.normalStrength = 2; $0.roughness = 0.7
            },
            make(.claw, .plastic) {
                $0.colorA = linear(c.claw); $0.knobs = V4(0.4, 0.4, 0.5, 0)
                $0.tileSize = 0.05; $0.resolution = 128; $0.normalStrength = 0.6; $0.roughness = 0.42; $0.clearcoat = 0.2
            },
            make(.tooth, .plastic) {
                $0.colorA = linear(0xE2D6B4); $0.knobs = V4(0.3, 0.3, 0.4, 0)
                $0.tileSize = 0.03; $0.resolution = 128; $0.normalStrength = 0.3; $0.roughness = 0.35; $0.clearcoat = 0.4
            },
            make(.eye, .plastic) {
                $0.colorA = linear(c.eye); $0.knobs = V4(0.25, 0.2, 0.25, 0)
                $0.tileSize = 0.01; $0.resolution = 128; $0.normalStrength = 0; $0.roughness = 0.03; $0.clearcoat = 1; $0.specular = 1
            },
            make(.horn, .plastic) {
                $0.colorA = linear(c.horn); $0.knobs = V4(0.7, 0.55, 0.8, 0)
                $0.tileSize = 0.08; $0.resolution = 256; $0.normalStrength = 2; $0.roughness = 0.55
            },
            make(.mouth, .plastic) {
                $0.colorA = linear(c.mouth); $0.knobs = V4(0.4, 0.3, 0.3, 0)
                $0.tileSize = 0.05; $0.resolution = 128; $0.normalStrength = 0.4; $0.roughness = 0.35; $0.clearcoat = 0.5
            },
            make(.feather, .plumageBody) {
                $0.colorA = linear(c.back); $0.colorB = linear(c.belly); $0.colorC = linear(c.stripe)
                $0.knobs = V4(70, 0.55, 0, 0.35); $0.tileSize = 0; $0.resolution = 1024; $0.normalStrength = 0.9; $0.roughness = 0.85; $0.specular = 0.25
            },
            make(.featherCard, .plumageFeather) {
                $0.colorA = linear(c.back); $0.colorB = linear(c.back); $0.colorC = linear(c.stripe)
                $0.knobs = V4(30, 0.3, 0.6, 0.4); $0.tileSize = 0; $0.resolution = 512; $0.normalStrength = 1
                $0.mode = .cutout; $0.twoSided = true; $0.roughness = 0.7
            },
        ]
    }
}
