import Foundation
import RealCore

/// Named ground actions for game birds (turkey, pheasant). `BirdMotion.pose(_:_:phase:)` turns one into joint angles.
public enum BirdAction: String, CaseIterable, Sendable {
    case idle, walk, trot, run, graze, alert

    /// Stride cycles per second for a unit-size bird.
    public var cycleRate: Float {
        switch self { case .walk: 1.1; case .trot: 1.9; case .run: 3.0; default: 0 }
    }
    public var isLocomotion: Bool { cycleRate > 0 }
}

extension BirdMotion {
    /// Motion input for a ground action. `phase` is the stride position (walk, trot, run) or the peck position (graze), 0...1.
    public static func input(_ action: BirdAction, _ p: BirdProfile, phase: Float = 0) -> BirdMotionInput {
        var i = BirdMotionInput()
        i.fold = 1; i.flap = 0; i.legs = 0
        i.tailSpread = p.anatomy.tailFeathers > 14 && p.anatomy.tailLength < 0.4 ? 0.7 : 0.06
        i.tailPitch = p.anatomy.tailLength > 0.4 ? -14 : 0
        i.stridePhase = phase - floor(phase)
        switch action {
        case .idle:
            i.crouch = 0
        case .walk:
            i.walk = 1
        case .trot:
            i.walk = 1; i.run = 0.45
        case .run:
            i.walk = 1; i.run = 1; i.crouch = 0.22; i.wingOpen = 0.18; i.tailPitch -= 6; i.neck = -6
        case .alert:
            i.neck = 12; i.headPitch = 6; i.crest = 1
        case .graze:
            // Peck: neck and head drop to the ground then lift, once per cycle.
            let dip = 0.5 - 0.5 * cos(2 * .pi * i.stridePhase)
            i.neck = -62 * dip - 8; i.headPitch = -32 * dip; i.crouch = 0.12 * dip; i.beak = 0.3 * (1 - dip)
        }
        return i
    }

    public static func pose(_ p: BirdProfile, _ action: BirdAction, phase: Float = 0) -> BirdPose {
        pose(p, input(action, p, phase: phase))
    }

    /// Cycles per second for `action`; larger birds step slower.
    public static func cycleRate(_ action: BirdAction, _ p: BirdProfile) -> Float {
        action.cycleRate / max(0.6, p.anatomy.length / 0.5).squareRoot()
    }

    /// Degrees the whole body leans nose down for `action` (apply as a pitch about the center of mass).
    public static func bodyPitch(_ action: BirdAction) -> Float {
        switch action { case .graze: 20; case .run: 9; case .trot: 3; default: 0 }
    }

    /// Preview names for game birds: idle, walk, trot, run, graze, alert, with an optional frame digit 0...3.
    public static func groundPreview(_ name: String, _ p: BirdProfile) -> BirdPose? {
        var base = name
        var phase: Float = 0.1
        if let d = name.last, let n = Int(String(d)) { base = String(name.dropLast()); phase = Float(n) / 4 }
        guard let action = BirdAction(rawValue: base) else { return nil }
        return pose(p, action, phase: phase)
    }
}
