import simd
import RealityKit
import RealCore
import RealKit

public extension RealScene {
    /// Splits the scene by `graph` cells: statics, field instances and rigs whose center lies in a cell go
    /// under that cell's entity; the rest (doors in doorways, lights, far ground, anything spanning rooms)
    /// stays always on. AO bake and the sun-blocked caster pass run once over the whole scene first.
    @MainActor
    internal func cellEntity(_ graph: RealCellGraph, materials: RealMaterialCache?) async throws -> Entity {
        let split = await cellSplit(graph)
        let root = try await split.core.entity(materials: materials)
        var roots: [Entity] = []
        for (i, part) in split.cells.enumerated() {
            let e = try await part.entity(materials: materials)
            e.name = "cell:" + graph.cells[i].name
            root.addChild(e)
            roots.append(e)
        }
        root.components.set(RealCellVisibilityComponent(graph: graph, cellRoots: roots))
        return root
    }

    /// The core scene and one scene per cell (index order of `graph.cells`), all with `cells` cleared.
    func cellSplit(_ graph: RealCellGraph) async -> (core: RealScene, cells: [RealScene]) {
        var statics = shadowResolved(singles)
        if let bake { statics = await Self.baked(statics, rigs: rigs, fields: fields, settings: bake) }
        var core = self
        core.cells = nil; core.bake = nil; core.cullSunBlockedCasters = false
        core.singles = []; core.fields = []; core.rigs = []
        var parts = graph.cells.map { c -> RealScene in
            var s = RealScene(name: "\(name):\(c.name)")
            s.farGround = nil; s.batchStatics = batchStatics; s.batchCell = batchCell; s.cullSunBlockedCasters = false
            return s
        }
        for var s in statics {
            s.bake = false
            let b = s.asset.levels[0].bounds
            if let i = graph.cell(at: s.at.point((b.min + b.max) / 2)) { parts[i].singles.append(s) } else { core.singles.append(s) }
        }
        for f in fields {
            var by: [Int: [simd_float4x4]] = [:], rest: [simd_float4x4] = []
            for m in f.transforms {
                if let i = graph.cell(at: SIMD3(m.columns.3.x, m.columns.3.y, m.columns.3.z)) { by[i, default: []].append(m) } else { rest.append(m) }
            }
            for (i, list) in by { parts[i].fields.append(.init(asset: f.asset, transforms: list, options: f.options)) }
            if !rest.isEmpty { core.fields.append(.init(asset: f.asset, transforms: rest, options: f.options)) }
        }
        for r in rigs {
            // Grabbables stay on: one carried out of its room must not vanish with the room.
            if !r.grabbable, let i = graph.cell(at: r.at.translation + V3(0, 0.1, 0)) { parts[i].rigs.append(r) } else { core.rigs.append(r) }
        }
        return (core, parts)
    }
}
