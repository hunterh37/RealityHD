import Foundation
import RealCore

/// Dinosaur animation clips. Raw values are the public names.
public enum DinoAnimation: String, CaseIterable, Codable, Sendable {
    /// Breathing, slow head look, tail sway.
    case idle
    /// Gait cycle (biped stride or quadruped diagonal walk).
    case walk
    /// Heavy footfall: one leg lifts high and slams down, the body drops on impact.
    case stomp
    /// Head and chest raise, jaw opens wide, tremor while held.
    case roar
    /// Struggle against a pull: leaning back, braced legs, head yanks, tail thrash, jaw snaps.
    case pulled
}

/// Joint values (degrees, by joint name) plus root motion for one frame.
public struct DinoPose: Sendable {
    public var values: [String: Float] = [:]
    /// Vertical root offset in meters at real scale.
    public var bob: Float = 0
    /// Root roll in degrees (side lean).
    public var roll: Float = 0
}

public enum DinoMotion {
    /// Seconds per loop at real scale.
    public static func period(_ a: DinoAnimation, _ p: DinoProfile) -> Float {
        let size = (p.targetHipHeight / 4).squareRoot()   // bigger animals move slower
        switch a {
        case .idle: return 4.0
        case .walk: return 2.2 * size + 0.3
        case .stomp: return 2.4 * size + 0.5
        case .roar: return 3.2
        case .pulled: return 1.6 * size + 0.5
        }
    }

    /// Pose at `time` seconds. `seed` offsets the idle and struggle rhythm so herds do not move in lockstep.
    public static func pose(_ p: DinoProfile, _ a: DinoAnimation, time: Float, seed: UInt64 = 1) -> DinoPose {
        var rng = SeededRNG(seed: seed &+ 0x51)
        let off = rng.float(0...6.28)
        let T = period(a, p)
        let ph = (time / T).truncatingRemainder(dividingBy: 1)
        let w = 2 * Float.pi
        var o = DinoPose()
        func set(_ k: String, _ v: Float) { o.values[k] = v }
        let limbs = DinoJoint.limbs(p.stance)
        // Breathing and tail sway are always on.
        let breath = sin(time * w / 3.6 + off)
        set(DinoJoint.chest, 1.2 * breath)
        set(DinoJoint.tailYaw, 6 * sin(time * 0.9 + off))
        for (k, t) in DinoJoint.tails.enumerated() { set(t, 2 * sin(time * 1.1 + off - Float(k) * 0.6)) }
        func step(_ limb: String, _ q: Float, lift: Float, swing: Float) {
            // q 0...1: 0-0.6 stance (foot travels back), 0.6-1 swing (foot lifts and travels forward).
            let stance = q < 0.6
            let s = stance ? 1 - 2 * q / 0.6 : -1 + 2 * (q - 0.6) / 0.4
            let up = stance ? 0 : sin((q - 0.6) / 0.4 * .pi)
            set(DinoJoint.name(limb, .hip), swing * s + lift * 0.3 * up)
            set(DinoJoint.name(limb, .knee), -lift * up)
            set(DinoJoint.name(limb, .ankle), lift * 0.8 * up - 6 * s)
            set(DinoJoint.name(limb, .toe), -lift * 0.5 * up + (stance && q > 0.45 ? 15 * (q - 0.45) / 0.15 : 0))
        }
        switch a {
        case .idle:
            set(DinoJoint.headYaw, 22 * sin(time * 0.35 + off))
            set(DinoJoint.head, 6 * sin(time * 0.5 + off * 0.5))
            set(DinoJoint.neck0, 3 * breath)
            set(DinoJoint.jaw, max(0, 8 * sin(time * 0.4 + off * 2) - 6))
            o.bob = 0.004 * p.targetHipHeight * breath
        case .walk:
            if p.isBiped {
                step(limbs[0], ph, lift: 40, swing: 22)
                step(limbs[1], (ph + 0.5).truncatingRemainder(dividingBy: 1), lift: 40, swing: 22)
                set(DinoJoint.shoulder("L"), 6 * sin(ph * w)); set(DinoJoint.shoulder("R"), -6 * sin(ph * w))
                o.roll = 3 * sin(ph * w)
            } else {
                step("hindL", ph, lift: 30, swing: 16)
                step("foreR", (ph + 0.1).truncatingRemainder(dividingBy: 1), lift: 30, swing: 16)
                step("hindR", (ph + 0.5).truncatingRemainder(dividingBy: 1), lift: 30, swing: 16)
                step("foreL", (ph + 0.6).truncatingRemainder(dividingBy: 1), lift: 30, swing: 16)
                o.roll = 1.5 * sin(ph * w)
            }
            set(DinoJoint.pelvis, 2 * sin(ph * 2 * w))
            set(DinoJoint.neck0, -4 * sin(ph * 2 * w))
            set(DinoJoint.head, 3 * sin(ph * 2 * w + 1))
            set(DinoJoint.headYaw, 4 * sin(ph * w))
            set(DinoJoint.tailYaw, 8 * sin(ph * w + .pi))
            o.bob = -0.02 * p.targetHipHeight * abs(sin(ph * w))
        case .stomp:
            // Alternate legs each half cycle: raise slowly (0-0.55), slam (0.55-0.65), settle.
            let half = (ph * 2).truncatingRemainder(dividingBy: 1)
            let leg = ph < 0.5 ? 0 : (p.isBiped ? 1 : 3)
            let other = p.isBiped ? 1 - leg : (leg == 0 ? 3 : 0)
            let raise: Float = half < 0.55 ? sin(half / 0.55 * .pi / 2) : (half < 0.65 ? 1 - (half - 0.55) / 0.1 : 0)
            let impact: Float = half >= 0.62 ? exp(-(half - 0.62) * 18) : 0
            let lf = limbs[leg]
            set(DinoJoint.name(lf, .hip), 45 * raise)
            set(DinoJoint.name(lf, .knee), -70 * raise)
            set(DinoJoint.name(lf, .ankle), 40 * raise)
            set(DinoJoint.name(lf, .toe), -25 * raise)
            set(DinoJoint.name(limbs[other], .knee), -12 * raise - 10 * impact)
            set(DinoJoint.name(limbs[other], .ankle), 8 * raise + 8 * impact)
            set(DinoJoint.pelvis, -5 * raise + 4 * impact)
            set(DinoJoint.neck0, -8 * impact + 4 * raise)
            set(DinoJoint.head, 10 * impact * sin(half * 60))
            set(DinoJoint.jaw, 12 * impact)
            for (k, t) in DinoJoint.tails.enumerated() { set(t, 8 * impact * sin(half * 40 - Float(k))) }
            o.roll = (leg == 0 ? -1 : 1) * 4 * raise
            o.bob = p.targetHipHeight * (0.015 * raise - 0.04 * impact)
        case .roar:
            let rise: Float = ph < 0.25 ? sin(ph / 0.25 * .pi / 2) : (ph < 0.75 ? 1 : cos((ph - 0.75) / 0.25 * .pi / 2))
            let hold: Float = (ph > 0.25 && ph < 0.75) ? 1 : 0
            let tremor = hold * (sin(time * 37 + off) + 0.5 * sin(time * 53)) / 1.5
            set(DinoJoint.pelvis, -6 * rise)
            set(DinoJoint.chest, 10 * rise + 1.2 * breath)
            set(DinoJoint.neck0, (p.isBiped ? 25 : 12) * rise + 1.5 * tremor)
            set(DinoJoint.neck1, (p.isBiped ? 18 : 6) * rise)
            set(DinoJoint.head, 20 * rise + 2 * tremor)
            set(DinoJoint.headYaw, 10 * hold * sin(ph * w * 1.5))
            set(DinoJoint.jaw, (p.isBiped ? 46 : 22) * rise + 3 * tremor)
            for (k, t) in DinoJoint.tails.enumerated() { set(t, -10 * rise + 3 * tremor * Float(k)) }
            if p.isBiped {
                for s in ["L", "R"] { set(DinoJoint.shoulder(s), 25 * rise); set(DinoJoint.elbow(s), -30 * rise) }
            } else {
                set("foreL_hip", 8 * rise); set("foreR_hip", 8 * rise)
            }
            o.bob = 0.03 * p.targetHipHeight * rise
        case .pulled:
            // Irregular yanks: two incommensurate sines per channel, seeded phase.
            let y1 = sin(time * 4.3 + off), y2 = sin(time * 7.1 + off * 1.7), y3 = sin(time * 2.2 + off * 0.3)
            let yank = 0.6 * y1 + 0.4 * y2
            set(DinoJoint.pelvis, 10 + 3 * y3)                       // lean back onto the haunches
            set(DinoJoint.chest, -6 + 3 * y2)
            set(DinoJoint.neck0, -18 + 10 * y1)
            set(DinoJoint.neck1, 10 * y2)
            set(DinoJoint.headYaw, 40 * yank)
            set(DinoJoint.head, -10 + 14 * y2)
            set(DinoJoint.jaw, max(0, 35 * sin(time * 6 + off)))
            set(DinoJoint.tailYaw, 35 * sin(time * 3.4 + off))
            for (k, t) in DinoJoint.tails.enumerated() { set(t, -8 + 14 * sin(time * 5 + off - Float(k) * 0.8)) }
            // Braced legs: front leg planted forward, rear leg pushing, small scrabbling steps.
            let signs: [Float] = [1, -1, 1, -1]
            let pairs: [(String, Float)] = limbs.enumerated().map { ($0.element, signs[$0.offset]) }
            for (limb, s) in pairs {
                let scrab = max(0, sin(time * 5.5 + off + s))
                set(DinoJoint.name(limb, .hip), -10 + 18 * s + 6 * scrab)
                set(DinoJoint.name(limb, .knee), -25 - 20 * scrab)
                set(DinoJoint.name(limb, .ankle), 15 + 12 * scrab)
                set(DinoJoint.name(limb, .toe), -10 * scrab)
            }
            if p.isBiped { for s in ["L", "R"] { set(DinoJoint.shoulder(s), 20 * y2); set(DinoJoint.elbow(s), -25 + 15 * y1) } }
            o.roll = 6 * y1
            o.bob = -0.05 * p.targetHipHeight + 0.01 * p.targetHipHeight * y3
        }
        // Keep legs planted: cancel the trunk pitch carried down to the hips.
        let pel = o.values[DinoJoint.pelvis] ?? 0, ch = o.values[DinoJoint.chest] ?? 0
        for limb in limbs {
            let k = DinoJoint.name(limb, .hip)
            o.values[k] = (o.values[k] ?? 0) - pel - (limb.hasPrefix("fore") ? ch : 0)
        }
        return o
    }
}
