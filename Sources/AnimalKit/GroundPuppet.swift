import Foundation
import RealityKit
import RealKit
import RealCore
import AnimalCore

@MainActor
public struct GroundTemplate {
    public let built: GroundRig
    let schema: Rig
    let entity: Entity
}

/// One live ground animal: holder at the center of mass, rig below.
@MainActor
public final class GroundPuppet {
    public let species: GroundSpecies
    public let variant: GroundVariant
    public let built: GroundRig
    public let holder = Entity()
    public let model: Entity
    private var joints: [Entity?]
    private var rest: [Xform]
    private var defs: [Joint]
    private var last: [Float]
    private let specs: [BirdJointSpec]

    init(template: GroundTemplate) {
        species = template.built.profile.species
        variant = template.built.profile.variant
        built = template.built
        model = template.entity.clone(recursive: true)
        specs = built.joints
        var js: [Entity?] = [], rs: [Xform] = [], ds: [Joint] = []
        for sp in specs {
            js.append(model.findEntity(named: "joint:\(sp.name)"))
            let i = template.schema.index(sp.name)!
            rs.append(template.schema.localJointTransform(i, value: 0))
            ds.append(template.schema.parts[i].joint)
        }
        joints = js; rest = rs; defs = ds
        last = [Float](repeating: .nan, count: specs.count)
        holder.name = "ground:\(species.rawValue)"
        model.position = [0, -built.comHeight, 0]
        holder.addChild(model)
    }

    private var cycle: Float = 0
    private var clock: Float = 0

    /// Poses the animal for `action`. `phase` is the gait cycle 0...1 and `time` drives idle motion
    /// (head turns, tail sway, chewing). Use `animate(_:dt:)` to advance both automatically.
    public func play(_ action: GroundAction, phase: Float = 0, time: Float = 0) {
        var i = GroundMotion.input(action, built.profile, phase: phase)
        let still = action == .idle || action == .graze || action == .alert
        if still { i.headYaw = (action == .alert ? 8 : 16) * sin(time * 0.55) }
        i.tailSway = (action.isLocomotion ? 3 : 7) * sin(time * 1.7)
        i.twitch = time * 20
        if action == .graze { i.jaw = 0.3 + 0.3 * sin(time * 9) }
        if action == .idle { i.alert = 0.2 + 0.2 * max(0, sin(time * 0.9)) }
        i.blink = max(0, sin(time * 1.3 + 2)) > 0.985 ? 1 : 0
        apply(GroundMotion.pose(built.profile, i))
        let q = simd_quatf(angle: -GroundMotion.bodyPitch(action, built.profile) * .pi / 180, axis: [1, 0, 0])
        model.orientation = q
        model.position = q.act([0, -built.comHeight, 0])
    }

    /// Advances the gait cycle and idle clock by `dt` seconds and poses the animal.
    public func animate(_ action: GroundAction, dt: Float) {
        clock += dt
        cycle = (cycle + GroundMotion.cycleRate(action, built.profile) * dt).truncatingRemainder(dividingBy: 1)
        play(action, phase: cycle, time: clock)
    }

    public func apply(_ pose: GroundPose) {
        for i in 0..<specs.count {
            let r = specs[i].range
            let v = min(max(pose.values[i], r.lowerBound), r.upperBound)
            if abs(v - last[i]) < 1e-3 { continue }
            last[i] = v
            guard let e = joints[i] else { continue }
            let x = defs[i].motion(v).then(rest[i])
            e.transform = Transform(scale: x.scale, rotation: x.rotation, translation: x.translation)
        }
    }
}

@MainActor
public enum GroundFactory {
    private struct Key: Hashable { var species: GroundSpecies; var variant: GroundVariant }
    private static var templates: [Key: GroundTemplate] = [:]
    private static var building: [Key: Task<GroundTemplate, Error>] = [:]

    public static func template(_ s: GroundSpecies, variant: GroundVariant = .standard) async throws -> GroundTemplate {
        let key = Key(species: s, variant: s.hasAntlers ? variant : .standard)
        if let t = templates[key] { return t }
        if let task = building[key] { return try await task.value }
        let task = Task { @MainActor () -> GroundTemplate in
            let profile = s.profile(key.variant)
            AnimalMaterials.register(profile)
            let built = await Task.detached(priority: .userInitiated) { GroundRigBuilder.build(profile) }.value
            let entity = try await built.rig.entityAsync(name: s.rawValue, state: "stand", interactive: false)
            entity.removeRestProxy()
            return GroundTemplate(built: built, schema: built.rig.schema, entity: entity)
        }
        building[key] = task
        defer { building[key] = nil }
        let t = try await task.value
        templates[key] = t
        return t
    }

    /// One live animal. `variant: .antlered` gives the buck or bull for deer and elk.
    public static func puppet(_ s: GroundSpecies, variant: GroundVariant = .standard) async throws -> GroundPuppet {
        GroundPuppet(template: try await template(s, variant: variant))
    }
}
