import Foundation
import RealityKit
import RealKit
import RealCore
import RealMaterials
import AnimalCore

@MainActor
public struct DinoTemplate {
    public let built: DinoRig
    let schema: Rig
    let entity: Entity
}

/// One live dinosaur. `entity` sits on the ground at its origin (feet at y = 0); add it to the scene.
@MainActor
public final class DinoPuppet {
    public let species: DinoSpecies
    public let seed: UInt64
    public let built: DinoRig
    /// Root entity: position, rotate and scale this one.
    public let entity = Entity()
    public let model: Entity
    /// Uniform body scale (1 = real size). Applied to `entity.scale`.
    public var scale: Float { didSet { entity.scale = SIMD3(repeating: scale) } }
    /// Current clip and its clock in seconds.
    public private(set) var animation: DinoAnimation = .idle
    public private(set) var time: Float = 0
    /// Clip playback rate multiplier.
    public var speed: Float = 1

    public static var animationNames: [String] { DinoAnimation.allCases.map(\.rawValue) }

    private var joints: [String: Entity] = [:]
    private var rest: [String: Xform] = [:]
    private var defs: [String: Joint] = [:]

    init(template: DinoTemplate, seed: UInt64, scale: Float) {
        species = template.built.profile.species
        self.seed = seed
        built = template.built
        model = template.entity.clone(recursive: true)
        for sp in built.joints {
            let i = template.schema.index(sp.name)!
            joints[sp.name] = model.findEntity(named: "joint:\(sp.name)")
            rest[sp.name] = template.schema.localJointTransform(i, value: 0)
            defs[sp.name] = template.schema.parts[i].joint
        }
        self.scale = scale
        entity.name = "dino:\(species.rawValue)"
        entity.scale = SIMD3(repeating: scale)
        entity.addChild(model)
        play(.idle, time: 0)
    }

    /// Poses `animation` at `time` seconds (deterministic for a given seed).
    public func play(_ animation: DinoAnimation, time: Float) {
        self.animation = animation
        self.time = time
        apply(DinoMotion.pose(built.profile, animation, time: time, seed: seed))
    }

    /// Plays a clip by name (`idle`, `walk`, `stomp`, `roar`, `pulled`). Returns false for unknown names.
    @discardableResult
    public func play(_ name: String, time: Float = 0) -> Bool {
        guard let a = DinoAnimation(rawValue: name) else { return false }
        play(a, time: time)
        return true
    }

    /// Advances the clock by `dt` and poses `animation`; switching clips restarts the clock.
    public func animate(_ animation: DinoAnimation, dt: Float) {
        let t = animation == self.animation ? time + dt * speed : 0
        play(animation, time: t)
    }

    public func apply(_ pose: DinoPose) {
        for (name, e) in joints {
            guard let d = defs[name], let r = rest[name] else { continue }
            let v = min(max(pose.values[name] ?? 0, d.range.lowerBound), d.range.upperBound)
            let x = d.motion(v).then(r)
            e.transform = Transform(scale: x.scale, rotation: x.rotation, translation: x.translation)
        }
        model.position = [0, pose.bob, 0]
        model.orientation = simd_quatf(angle: pose.roll * .pi / 180, axis: [0, 0, 1])
    }
}

/// Loads dinosaurs. Templates are cached per species and seed; each puppet is a clone.
@MainActor
public enum DinoFactory {
    public enum LoadError: Error { case unknownSpecies(String) }
    private struct Key: Hashable { var species: DinoSpecies; var seed: UInt64 }
    private static var templates: [Key: DinoTemplate] = [:]
    private static var registered: Set<DinoSpecies> = []

    public static func registerMaterials(_ s: DinoSpecies) {
        guard registered.insert(s).inserted else { return }
        for m in DinoMaterials.specs(for: s.profile) { RealMaterialCache.shared.overrides[m.key] = m }
    }

    public static func template(_ s: DinoSpecies, seed: UInt64 = 1) async throws -> DinoTemplate {
        let key = Key(species: s, seed: seed)
        if let t = templates[key] { return t }
        registerMaterials(s)
        let profile = s.profile
        let built = await Task.detached(priority: .userInitiated) { DinoRigBuilder.build(profile, seed: seed) }.value
        let entity = try await built.rig.entityAsync(name: s.rawValue, state: "stand", interactive: false)
        entity.removeRestProxy()
        let t = DinoTemplate(built: built, schema: built.rig.schema, entity: entity)
        templates[key] = t
        return t
    }

    /// One live dinosaur at `scale` (1 = real size).
    public static func puppet(_ s: DinoSpecies, seed: UInt64 = 1, scale: Float = 1) async throws -> DinoPuppet {
        DinoPuppet(template: try await template(s, seed: seed), seed: seed, scale: scale)
    }

    /// Same as `puppet(_:)` keyed by species id (`trex`, `triceratops`, `velociraptor`).
    public static func puppet(id: String, seed: UInt64 = 1, scale: Float = 1) async throws -> DinoPuppet {
        guard let s = DinoSpecies(rawValue: id) else { throw LoadError.unknownSpecies(id) }
        return try await puppet(s, seed: seed, scale: scale)
    }
}
