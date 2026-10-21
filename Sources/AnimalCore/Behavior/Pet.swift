import Foundation
import RealCore

/// Life stage of a pet, from real-time age since adoption.
public enum PetStage: String, CaseIterable, Codable, Sendable {
    case baby, juvenile, adult, elder
}

/// Growth stages by age in days: baby 0-14, juvenile 14-60, adult 60 d to 2 years, elder after.
public struct PetGrowth: Sendable, Equatable {
    public var stage: PetStage
    /// Uniform body scale.
    public var scale: Float
    /// Extra head scale on top of `scale` (babies have big heads).
    public var headBoost: Float
    /// Extra eye scale on top of `scale`.
    public var eyeBoost: Float

    public static let juvenileDay = 14.0, adultDay = 60.0, elderDay = 730.0

    public init(stage: PetStage) {
        self.stage = stage
        switch stage {
        case .baby: scale = 0.62; headBoost = 1.25; eyeBoost = 1.35
        case .juvenile: scale = 0.82; headBoost = 1; eyeBoost = 1
        case .adult, .elder: scale = 1; headBoost = 1; eyeBoost = 1
        }
    }

    public init(ageDays: Double) {
        self.init(stage: PetGrowth.stage(ageDays: ageDays))
    }

    public static func stage(ageDays: Double) -> PetStage {
        ageDays < juvenileDay ? .baby : ageDays < adultDay ? .juvenile : ageDays < elderDay ? .adult : .elder
    }

    public func apply(to p: GroundProfile) -> GroundProfile {
        var p = p
        var a = p.anatomy
        let s = scale, h = scale * headBoost, e = scale * eyeBoost
        a.bodyLength *= s; a.bodyDepth *= s; a.bodyWidth *= s
        a.headLength *= h; a.headWidth *= h; a.headHeight *= h; a.snout *= h
        a.earLength *= h; a.earWidth *= h
        a.tailLength *= s; a.tailWidth *= s
        a.foreLeg *= s; a.hindLeg *= s; a.legRadius *= s
        a.foreAnkle *= s; a.hindAnkle *= s; a.neckLength *= s
        a.eyeRadius *= e
        a.rideHeight = a.rideHeight.map { $0 * s }
        p.anatomy = a
        return p
    }

    public func apply(to p: BirdProfile) -> BirdProfile {
        var p = p
        var a = p.anatomy
        let s = scale, h = scale * headBoost, e = scale * eyeBoost
        a.length *= s; a.wingspan *= s; a.bodyLength *= s; a.bodyDepth *= s; a.bodyWidth *= s
        a.neckLength *= s
        a.headLength *= h; a.headWidth *= h; a.headHeight *= h
        a.beakLength *= h; a.beakDepth *= h; a.beakWidth *= h
        a.tailLength *= s; a.tailWidth *= s; a.tarsus *= s; a.toeLength *= s; a.tibia *= s
        a.crestHeight *= s; a.crestLength *= s; a.wingChord *= s
        a.eyeRadius *= e
        p.anatomy = a
        return p
    }
}

public enum PetSurface: String, CaseIterable, Sendable {
    case floor, table, wall, ceiling

    /// Floor, wall or ceiling from the surface normal (up = +Y). A horizontal surface raised off the floor is `.table`; pass `raised`.
    public static func classify(normal: V3, raised: Bool = false) -> PetSurface {
        let n = simd_normalize(normal)
        if n.y > 0.7 { return raised ? .table : .floor }
        if n.y < -0.7 { return .ceiling }
        return .wall
    }

    /// Multiplier on walk and run speed.
    public var speedScale: Float {
        switch self { case .floor: 1; case .table: 0.8; case .wall: 0.55; case .ceiling: 0.4 }
    }
}

/// Pure math for a pet moving over any surface: body up follows the surface normal.
public enum SurfaceCrawl {
    /// Body orientation (animals face -Z, up +Y) with up along `normal` and facing `heading` projected onto the surface.
    public static func orientation(normal: V3, heading: V3) -> simd_quatf {
        let up = simd_normalize(normal)
        var fwd = heading - up * simd_dot(heading, up)
        if simd_length(fwd) < 1e-4 {
            // Heading parallel to the normal: fall back to world -Z, then X.
            for alt in [V3(0, 0, -1), V3(1, 0, 0)] {
                fwd = alt - up * simd_dot(alt, up)
                if simd_length(fwd) > 1e-3 { break }
            }
        }
        fwd = simd_normalize(fwd)
        let z = -fwd
        let x = simd_normalize(simd_cross(up, z))
        return simd_quatf(simd_float3x3(columns: (x, up, z)))
    }

    /// Pose on a surface at `position`; `speed` is the unscaled gait speed.
    public static func pose(position: V3, normal: V3, heading: V3, surface: PetSurface? = nil, speed: Float = 1) -> (position: V3, rotation: simd_quatf, speed: Float) {
        let s = surface ?? PetSurface.classify(normal: normal)
        return (position, orientation(normal: normal, heading: heading), speed * s.speedScale)
    }

    /// Advance along the surface: motion follows the heading projected onto the plane.
    public static func step(position: V3, normal: V3, heading: V3, speed: Float, surface: PetSurface? = nil, dt: Float) -> V3 {
        let r = pose(position: position, normal: normal, heading: heading, surface: surface, speed: speed)
        return position + r.rotation.act(V3(0, 0, -1)) * r.speed * dt
    }
}

/// Where a small pet sits on an open palm.
public enum HandPerch {
    public enum Kind: Sendable { case squirrel, bird }

    public struct Target: Sendable {
        public var position: V3
        public var rotation: simd_quatf
        /// 0 standing ... 1 fully crouched on the palm.
        public var crouch: Float
    }

    /// `palm` is the palm center, `normal` out of the palm, `fingers` the direction toward the fingertips (the pet faces it).
    public static func target(kind: Kind, palm: V3, normal: V3, fingers: V3 = V3(0, 0, -1)) -> Target {
        let n = simd_normalize(normal)
        // Feet rest slightly above the skin: squirrel paws sink into the palm less than bird toes grip it.
        let lift: Float = kind == .squirrel ? 0.006 : 0.01
        let crouch: Float = kind == .squirrel ? 0.5 : 0.25
        return Target(position: palm + n * lift, rotation: SurfaceCrawl.orientation(normal: n, heading: fingers), crouch: crouch)
    }
}
