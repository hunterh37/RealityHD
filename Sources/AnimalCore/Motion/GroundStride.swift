import Foundation
import RealCore

/// Named actions for four-legged game animals. `GroundMotion.pose(_:_:phase:)` turns one into joint angles.
public enum GroundAction: String, CaseIterable, Sendable {
    case idle, walk, trot, run, graze, alert

    /// Speed fed to `GroundMotionInput.speed` (fraction of full run).
    public var speed: Float {
        switch self { case .walk: 0.12; case .trot: 0.42; case .run: 1; default: 0 }
    }
    /// Gait cycles per second for a unit stride scale.
    public var cycleRate: Float {
        switch self { case .walk: 0.85; case .trot: 1.5; case .run: 2.3; default: 0 }
    }
    public var isLocomotion: Bool { speed > 0 }
}

extension GroundMotion {
    /// Motion input for an action. `phase` is the gait cycle position 0...1.
    public static func input(_ action: GroundAction, _ p: GroundProfile, phase: Float = 0) -> GroundMotionInput {
        var i = GroundMotionInput()
        i.gait = p.behavior.gait
        i.speed = action.speed
        i.phase = phase - floor(phase)
        switch action {
        case .idle: i.alert = 0.25
        case .alert: i.alert = 1; i.headPitch = 12; i.neck = 8
        case .graze: i.graze = 1; i.jaw = 0.25
        case .run: i.alert = 1; i.tailRaise = 0.6
        case .walk, .trot: i.alert = 0.4
        }
        return i
    }

    public static func pose(_ p: GroundProfile, _ action: GroundAction, phase: Float = 0) -> GroundPose {
        pose(p, input(action, p, phase: phase))
    }

    /// Degrees the whole body leans nose down for `action` (about the center of mass). Short-necked animals
    /// lower the shoulders to reach the ground; `GroundPuppet.play` applies it.
    public static func bodyPitch(_ action: GroundAction, _ p: GroundProfile) -> Float {
        switch action {
        case .graze: p.anatomy.neckLength > 0.2 ? 10 : 14
        case .run: 3
        default: 0
        }
    }

    /// Cycles per second to advance `phase` at for this animal (longer legs cycle slower).
    public static func cycleRate(_ action: GroundAction, _ p: GroundProfile) -> Float {
        action.cycleRate / max(0.5, p.anatomy.strideScale).squareRoot()
    }

    /// Lateral-sequence walk, diagonal trot and rotary gallop, blended by `speed`.
    static func strideLegs(_ q: inout GroundPose, _ p: GroundProfile, _ i: GroundMotionInput) {
        let sp = saturate(i.speed)
        let a = p.anatomy
        let ks = 1 / max(0.5, a.strideScale).squareRoot()
        let toe = a.digitigrade
        let ws = 1 - smoothstep(0.2, 0.3, sp), wr = smoothstep(0.55, 0.65, sp), wt = max(0, 1 - ws - wr)
        func blend(_ l: GroundJoint.Leg, _ s: GroundJoint.Segment, _ walk: Float, _ trot: Float, _ run: Float) {
            q[l, s] = walk * ws + trot * wt + run * wr
        }
        func arc(_ ph: Float, duty: Float, amp: Float) -> (hip: Float, lift: Float) {
            let swing = ph >= duty
            let u = swing ? (ph - duty) / (1 - duty) : ph / duty
            return (swing ? -amp + 2 * amp * u : amp * (1 - 2 * u), swing ? sin(.pi * u) : 0)
        }
        func wrap(_ x: Float) -> Float { x - floor(x) }
        let walkOff: [GroundJoint.Leg: Float] = [.foreL: 0, .hindR: 0.25, .foreR: 0.5, .hindL: 0.75]
        let trotOff: [GroundJoint.Leg: Float] = [.foreL: 0, .hindR: 0, .foreR: 0.5, .hindL: 0.5]
        let gallopOff: [GroundJoint.Leg: Float] = [.hindL: 0, .hindR: 0.07, .foreR: 0.4, .foreL: 0.47]
        for l in GroundJoint.Leg.allCases {
            let fore = l.isFore
            let w = arc(wrap(i.phase + walkOff[l]!), duty: 0.62, amp: 19 * ks)
            let t = arc(wrap(i.phase + trotOff[l]!), duty: 0.5, amp: 26 * ks)
            let ph = i.phase + gallopOff[l]!
            let gHip = fore ? smooth([52, 62, 22, -26], ph) : smooth([-38, 2, 52, 40], ph)
            let gKnee = fore ? -smooth([15, 25, 62, 92], ph) : -smooth([25, 78, 118, 52], ph)
            let gAnk = fore ? -smooth([0, 5, 32, 20], ph) : smooth([-20, 15, 50, 10], ph)
            let wKnee: Float = fore ? -(toe ? 58 : 36) * w.lift : -(toe ? 30 : 40) * w.lift - 4
            let wAnk: Float = fore ? (toe ? -22 : 14) * w.lift : (toe ? 26 : 20) * w.lift
            let tKnee: Float = fore ? -(toe ? 84 : 50) * t.lift : -(toe ? 34 : 50) * t.lift - 4
            let tAnk: Float = fore ? (toe ? -30 : 18) * t.lift : (toe ? 24 : 24) * t.lift
            blend(l, .hip, w.hip, t.hip, gHip * ks)
            blend(l, .knee, wKnee, tKnee, gKnee)
            blend(l, .ankle, wAnk, tAnk, gAnk)
        }
        let gs = smooth([-14, 8, 22, 4], i.phase) * 0.8
        q[.spine] = gs * wr + 2.5 * sin(2 * .pi * i.phase * 2) * wt
        q[.neckPitch] = smooth([-8, 6, 9, -4], i.phase) * wr + 3 * sin(2 * .pi * i.phase) * ws
    }

    /// Named poses for the preview tool on game animals: idle, walk, trot, run, graze, alert, with an
    /// optional frame digit 0...3 on the locomotion names (walk2).
    public static func gamePreview(_ name: String, _ p: GroundProfile) -> GroundPose? {
        var base = name
        var phase: Float = name == "run" ? 0.2 : 0.1
        if let d = name.last, let n = Int(String(d)) { base = String(name.dropLast()); phase = Float(n) / 4 }
        guard let action = GroundAction(rawValue: base) else { return nil }
        return pose(p, action, phase: phase)
    }
}
