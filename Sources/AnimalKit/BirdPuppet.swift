import Foundation
import RealityKit
import RealKit
import RealCore
import AnimalCore

/// Built geometry and entity for one species, cloned for every bird of that species.
@MainActor
public struct BirdTemplate {
    public let built: BirdRig
    let schema: Rig
    let entity: Entity
}

/// One live bird: a holder entity at the center of mass, the rig below it, and the joint entities
/// that `apply(_:)` poses. Position and orient `holder` to fly the bird.
@MainActor
public final class BirdPuppet {
    public let species: BirdSpecies
    public let built: BirdRig
    /// Origin at the body center. Move and rotate this.
    public let holder = Entity()
    public let model: Entity
    private var joints: [Entity?]
    private var rest: [Xform]
    private var defs: [Joint]
    private var last: [Float]
    private let specs: [BirdJointSpec]
    /// Joint-driven part options (folded wing, closed tail).
    private var links: [(joint: Int, link: RigOptionLink, entity: Entity, option: Int)] = []

    init(template: BirdTemplate) {
        species = template.built.profile.species
        built = template.built
        model = template.entity.clone(recursive: true)
        specs = built.joints
        var js: [Entity?] = []
        var rs: [Xform] = []
        var ds: [Joint] = []
        for sp in specs {
            js.append(model.findEntity(named: "joint:\(sp.name)"))
            let i = template.schema.index(sp.name)!
            rs.append(template.schema.localJointTransform(i, value: 0))
            ds.append(template.schema.parts[i].joint)
        }
        joints = js; rest = rs; defs = ds
        last = [Float](repeating: .nan, count: specs.count)
        holder.name = "bird:\(species.rawValue)"
        for l in built.rig.optionLinks {
            guard let j = specs.firstIndex(where: { $0.name == l.joint }), let e = model.findEntity(named: "joint:\(l.part)") else { continue }
            links.append((j, l, e, -1))
        }
        model.position = [0, -built.comHeight, 0]
        holder.addChild(model)
    }

    private var cycle: Float = 0
    private var clock: Float = 0

    /// Poses a ground action (idle, walk, trot, run, graze, alert) and leans the body to match.
    /// `phase` is the stride or peck cycle 0...1; `time` drives idle head turns and blinks.
    public func play(_ action: BirdAction, phase: Float = 0, time: Float = 0) {
        var i = BirdMotion.input(action, built.profile, phase: phase)
        if action == .idle || action == .alert { i.headYaw = 22 * sin(time * 0.7); i.headRoll = 6 * sin(time * 0.7 + 1) }
        i.blink = max(0, sin(time * 1.1 + 1)) > 0.985 ? 1 : 0
        apply(BirdMotion.pose(built.profile, i))
        let q = simd_quatf(angle: -BirdMotion.bodyPitch(action) * .pi / 180, axis: [1, 0, 0])
        model.orientation = q
        model.position = q.act([0, -built.comHeight, 0])
    }

    /// Advances the stride cycle and idle clock by `dt` seconds and poses the bird.
    public func animate(_ action: BirdAction, dt: Float) {
        clock += dt
        cycle = (cycle + BirdMotion.cycleRate(action, built.profile) * dt).truncatingRemainder(dividingBy: 1)
        play(action, phase: cycle, time: clock)
    }

    /// Poses every joint. Skips joints that moved less than a thousandth of a degree.
    public func apply(_ pose: BirdPose) {
        for k in links.indices {
            let o = links[k].link.option(pose.values[links[k].joint])
            guard o != links[k].option else { continue }
            links[k].option = o
            for c in links[k].entity.children where c.name.hasPrefix("opt") { c.isEnabled = c.name == "opt\(o)" }
        }
        for i in 0..<specs.count {
            var v = pose.values[i]
            if let m = specs[i].mimic { v = pose.values[m.master] * m.ratio }
            let r = specs[i].range
            v = min(max(v, r.lowerBound), r.upperBound)
            if abs(v - last[i]) < 1e-3 { continue }
            last[i] = v
            guard let e = joints[i] else { continue }
            let x = defs[i].motion(v).then(rest[i])
            e.transform = Transform(scale: x.scale, rotation: x.rotation, translation: x.translation)
        }
    }
}

@MainActor
public enum BirdFactory {
    private static var templates: [BirdSpecies: BirdTemplate] = [:]
    private static var building: [BirdSpecies: Task<BirdTemplate, Error>] = [:]

    public static func template(_ s: BirdSpecies) async throws -> BirdTemplate {
        if let t = templates[s] { return t }
        if let task = building[s] { return try await task.value }
        let task = Task { @MainActor () -> BirdTemplate in
            let profile = s.profile
            AnimalMaterials.register(profile)
            let built = await Task.detached(priority: .userInitiated) { BirdRigBuilder.build(profile) }.value
            let entity = try await built.rig.entityAsync(name: s.rawValue, state: "perched", interactive: false)
            entity.removeRestProxy()
            return BirdTemplate(built: built, schema: built.rig.schema, entity: entity)
        }
        building[s] = task
        defer { building[s] = nil }
        let t = try await task.value
        templates[s] = t
        return t
    }

    public static func puppet(_ s: BirdSpecies) async throws -> BirdPuppet {
        BirdPuppet(template: try await template(s))
    }

    /// Number of species with built templates (tests).
    public static var cached: Int { templates.count }
}
