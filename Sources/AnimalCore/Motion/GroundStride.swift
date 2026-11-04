import Foundation
import RealCore

/// Named actions for four-legged game animals. `GroundMotion.pose(_:_:phase:)` turns one into joint angles.
public enum GroundAction: String, CaseIterable, Sendable {
    case idle, walk, trot, run, graze, alert, jump

    /// Speed fed to `GroundMotionInput.speed` (fraction of full run).
    public var speed: Float {
        switch self { case .walk: 0.12; case .trot: 0.42; case .run: 1; default: 0 }
    }
    /// Gait cycles per second for a unit stride scale.
    public var cycleRate: Float {
        switch self { case .walk: 0.85; case .trot: 1.5; case .run: 2.3; case .idle: 0.125; case .jump: 0.7; default: 0 }
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
        case .idle: i.alert = 0.25; i.idle = 1
        case .jump: i.jump = true; i.alert = 0.8
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
        if action == .walk, p.behavior.gait == .stride {
            // Stance foot travels 2 L sin(A) per `walkDuty` of a cycle; match the ground speed so feet do not slide.
            let a = p.anatomy
            let stance = 2 * a.standHeight * sin(radians(walkAmp(p)))
            return min(2, max(0.3, p.behavior.walk * walkDuty / max(0.05, stance)))
        }
        if action == .idle || action == .jump { return action.cycleRate }
        return action.cycleRate / max(0.5, p.anatomy.strideScale).squareRoot()
    }

    static let walkDuty: Float = 0.66
    /// Half swing of the walk hip in degrees: plantigrade bears roll wider than hoofed animals.
    static func walkAmp(_ p: GroundProfile) -> Float {
        (p.anatomy.digitigrade ? 20 : 24) / max(0.5, p.anatomy.strideScale).squareRoot()
    }

    /// Metres the body rides above (or below) the standing height: walk bob, jump crouch and flight.
    public static func bodyLift(_ action: GroundAction, _ p: GroundProfile, phase: Float) -> Float {
        let h = p.anatomy.standHeight
        switch action {
        case .walk: return -0.012 * h * (1 + cos(4 * .pi * phase))
        case .jump:
            let k: [Float] = [0, -0.03, -0.07, 0.04, 0.20, 0.32, 0.24, 0.02, -0.08, -0.02]
            return h * cyc(k, phase) * (p.anatomy.digitigrade ? 1 : 0.8)
        default: return 0
        }
    }

    /// Body lift for a preview pose name (walk2, jump, jump1).
    public static func previewLift(_ name: String, _ p: GroundProfile) -> Float {
        var base = name
        var phase: Float = name == "jump" ? 0.45 : 0.1
        if let d = name.last, let n = Int(String(d)) { base = String(name.dropLast()); phase = Float(n) / 4 }
        guard p.behavior.gait == .stride, let a = GroundAction(rawValue: base) else { return 0 }
        return bodyLift(a, p, phase: phase)
    }

    /// Cyclic Catmull-Rom through equally spaced keys; phase 0 and 1 give the same value and slope.
    static func cyc(_ k: [Float], _ ph: Float) -> Float {
        let n = k.count
        let x = (ph - floor(ph)) * Float(n)
        let i = Int(x) % n, t = x - floor(x)
        let p0 = k[(i + n - 1) % n], p1 = k[i], p2 = k[(i + 1) % n], p3 = k[(i + 2) % n]
        return 0.5 * (2 * p1 + (p2 - p0) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t * t + (3 * p1 - p0 - 3 * p2 + p3) * t * t * t)
    }

    /// Wrapped distance of `ph` from `c`, then a raised-cosine pulse of half width `w`.
    static func pulse(_ ph: Float, _ c: Float, _ w: Float) -> (d: Float, v: Float) {
        var d = ph - c
        d -= floor(d + 0.5)
        return (d, abs(d) < w ? 0.5 * (1 + cos(.pi * d / w)) : 0)
    }

    /// Crouch, launch, airborne tuck, landing reach and absorb over one phase 0...1; phase 0 and 1 stand.
    static func jumpLegs(_ q: inout GroundPose, _ p: GroundProfile, _ ph: Float) {
        let s: Float = p.anatomy.digitigrade ? 1 : 0.8
        let toe: Float = p.anatomy.digitigrade ? -1 : 1
        let fHip: [Float] = [0, -6, -12, 30, 42, 44, 38, 28, 8, 2]
        let fKnee: [Float] = [0, -14, -30, -12, -45, -80, -55, -12, -38, -12]
        let fAnk: [Float] = [0, 4, 10, 2, 12, 22, 14, 2, 8, 2]
        let hHip: [Float] = [0, 12, 26, -40, -5, 24, 34, 18, 22, 8]
        let hKnee: [Float] = [0, -18, -52, -8, -50, -88, -60, -22, -55, -20]
        let hAnk: [Float] = [0, 10, 28, -30, 10, 38, 28, 6, 22, 6]
        for l in GroundJoint.Leg.allCases {
            if l.isFore {
                q[l, .hip] = cyc(fHip, ph) * s; q[l, .knee] = cyc(fKnee, ph) * s; q[l, .ankle] = toe * cyc(fAnk, ph) * s
            } else {
                q[l, .hip] = cyc(hHip, ph) * s; q[l, .knee] = cyc(hKnee, ph) * s; q[l, .ankle] = cyc(hAnk, ph) * s
            }
        }
        q[.spine] = cyc([0, -3, -6, 10, 8, 0, -8, -6, 2, 0], ph)
        q[.neckPitch] = cyc([0, -6, -12, 6, 8, 4, -4, -6, -8, -2], ph)
        let t = cyc([0, 0, 0.1, 0.4, 0.6, 0.5, 0.3, 0.1, 0.1, 0], ph)
        q[.tail0] = -30 * t
    }

    /// Slow loop (phase 0...1 is one 8 s cycle): breathing, weight shift, head and ear micro motion, tail flick.
    static func idleLayer(_ q: inout GroundPose, _ p: GroundProfile, _ ph: Float, _ k: Float) {
        let tau = 2 * Float.pi
        let breath = sin(2 * tau * ph), shift = sin(tau * ph)
        q[.spine] += k * 1.1 * breath
        q[.neckPitch] += k * (0.9 * breath - 1.2 * shift)
        q[.headYaw] += k * (5 * sin(tau * ph) + 2.5 * sin(3 * tau * ph + 1))
        q[.headPitch] += k * (2 * sin(2 * tau * ph + 0.5) - 0.8 * breath)
        // Weight shift: the unloaded side relaxes a little, the loaded side stays planted.
        let u = max(0, shift), v = max(0, -shift)
        q[.foreL, .knee] -= k * 3 * u; q[.hindR, .knee] -= k * 3.5 * u
        q[.foreR, .knee] -= k * 3 * v; q[.hindL, .knee] -= k * 3.5 * v
        q[.hindR, .ankle] += k * 2 * u; q[.hindL, .ankle] += k * 2 * v
        q[.earL] += k * 18 * pulse(ph, 0.35, 0.04).v
        q[.earR] += k * 14 * pulse(ph, 0.72, 0.035).v
        let tf = pulse(ph, 0.56, 0.05)
        q[.tailYaw] += k * 16 * tf.v * sin(tau * 2 * tf.d / 0.1)
        q[.tail0] += k * (-6 * tf.v + 1.5 * breath)
        q[.lidL] -= k * 40 * pulse(ph, 0.9, 0.012).v
        q[.lidR] -= k * 40 * pulse(ph, 0.9, 0.012).v
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
        // Lateral sequence: hind L, fore L, hind R, fore R, a quarter cycle apart (offset = minus footfall time).
        let walkOff: [GroundJoint.Leg: Float] = [.hindL: 0, .foreL: 0.75, .hindR: 0.5, .foreR: 0.25]
        let wd = GroundMotion.walkDuty, wA = GroundMotion.walkAmp(p), sinA = sin(radians(wA))
        /// Walk hip: stance moves the foot back at constant ground speed (hip = asin), swing eases out of and into rest.
        func walkArc(_ ph: Float, amp: Float) -> (hip: Float, lift: Float) {
            if ph < wd {
                let u = ph / wd
                return (degrees(asin(min(1, sin(radians(amp)) * (1 - 2 * u)))), 0)
            }
            let u = (ph - wd) / (1 - wd)
            let e = u - sin(2 * .pi * u) / (2 * .pi)
            return (-amp + 2 * amp * e, pow(sin(.pi * u), 0.8))
        }
        _ = sinA
        let trotOff: [GroundJoint.Leg: Float] = [.foreL: 0, .hindR: 0, .foreR: 0.5, .hindL: 0.5]
        let gallopOff: [GroundJoint.Leg: Float] = [.hindL: 0, .hindR: 0.07, .foreR: 0.4, .foreL: 0.47]
        for l in GroundJoint.Leg.allCases {
            let fore = l.isFore
            let w = walkArc(wrap(i.phase + walkOff[l]!), amp: wA + (fore && !toe ? 4 : 0))
            let t = arc(wrap(i.phase + trotOff[l]!), duty: 0.5, amp: 26 * ks)
            let ph = i.phase + gallopOff[l]!
            let gHip = fore ? smooth([52, 62, 22, -26], ph) : smooth([-38, 2, 52, 40], ph)
            let gKnee = fore ? -smooth([15, 25, 62, 92], ph) : -smooth([25, 78, 118, 52], ph)
            let gAnk = fore ? -smooth([0, 5, 32, 20], ph) : smooth([-20, 15, 50, 10], ph)
            let wKnee: Float = fore ? -(toe ? 82 : 30) * w.lift : -(toe ? 30 : 38) * w.lift - 4
            let wAnk: Float = fore ? (toe ? -34 : 10) * w.lift : (toe ? 22 : 22) * w.lift
            let tKnee: Float = fore ? -(toe ? 84 : 50) * t.lift : -(toe ? 34 : 50) * t.lift - 4
            let tAnk: Float = fore ? (toe ? -30 : 18) * t.lift : (toe ? 24 : 24) * t.lift
            blend(l, .hip, w.hip, t.hip, gHip * ks)
            blend(l, .knee, wKnee, tKnee, gKnee)
            blend(l, .ankle, wAnk, tAnk, gAnk)
        }
        let gs = smooth([-14, 8, 22, 4], i.phase) * 0.8
        q[.spine] = gs * wr + 2.5 * sin(2 * .pi * i.phase * 2) * wt
        q[.neckPitch] = smooth([-8, 6, 9, -4], i.phase) * wr + (toe ? 4 : 3) * sin(2 * .pi * i.phase) * ws
        if !toe {
            // Rolling shoulders: the spine and head sway with the fore legs.
            q[.spine] += 2.2 * sin(2 * .pi * i.phase * 2) * ws
            q[.headYaw] = 5 * sin(2 * .pi * i.phase) * ws
        }
    }

    /// Named poses for the preview tool on game animals: idle, walk, trot, run, graze, alert, jump, with an
    /// optional frame digit 0...3 on the locomotion names (walk2).
    public static func gamePreview(_ name: String, _ p: GroundProfile) -> GroundPose? {
        var base = name
        var phase: Float = name == "run" ? 0.2 : name == "jump" ? 0.45 : 0.1
        if let d = name.last, let n = Int(String(d)) { base = String(name.dropLast()); phase = Float(n) / 4 }
        guard let action = GroundAction(rawValue: base) else { return nil }
        return pose(p, action, phase: phase)
    }
}
