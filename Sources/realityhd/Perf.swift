import Foundation
import simd
import RealCore
import RealKit
import RealLibrary

/// `realityhd perf [scene...] [--tier t] [--seed n] [--all-in-view]`: per-scene cost at the camera hint for
/// every tier (or one), from the same LOD, culling, thinning, batching and shadow policy the runtime uses.
/// Counts are frustum-accurate (union of the two eye frustums at device field of view); `--all-in-view`
/// prints the pre-frustum counts instead.
///
/// `realityhd perf --budget [scene...]`: balanced-tier view counts against `docs/perf-budgets.json`; exits 1
/// when any scene is over. `--write` records the current counts plus 5 % as each scene's budget (new
/// scenes, or after a change that lowers cost).
@MainActor
func perfCommand(_ args: Args, tier: RealPerformance.Tier?) throws {
    let seed = UInt64(args.opt("--seed") ?? "1") ?? 1
    let budget = args.flag("--budget"), write = args.flag("--write"), preFrustum = args.flag("--all-in-view")
    let breakdown = args.flag("--breakdown")
    let ids = args.rest.isEmpty ? SceneCatalog.ids : args.rest
    if breakdown { perfBreakdown(ids, seed: seed); return }
    if budget { try perfBudget(ids, seed: seed, write: write); return }
    let tiers = tier.map { [$0] } ?? RealPerformance.Tier.allCases
    print(pad("scene", 18), pad("tier", 12), pad("tris", 9), pad("shadow", 9), pad("draws", 7), pad("live", 6), pad("inst", 8),
          pad("meshes", 8), "weight vs balanced")
    for id in ids {
        guard let scene = SceneCatalog.build(id, seed: seed) else { print("unknown scene \(id)"); continue }
        let view: ViewVolume? = preFrustum ? nil : scene.viewVolume()
        let base = scene.estimate(settings: RealPerformance(.balanced), view: view).weight
        for t in tiers {
            let c = scene.estimate(settings: RealPerformance(t), view: view)
            let rel = base > 0 ? String(format: "%.2fx", Double(c.weight) / Double(base)) : "-"
            print(pad(id, 18), pad(t.rawValue, 12), pad("\(c.triangles / 1000)k", 9), pad("\(c.shadowTriangles / 1000)k", 9),
                  pad("\(c.drawCalls)", 7), pad("\(c.liveDrawCalls)", 6), pad("\(c.instances)", 8), pad("\(c.meshes)", 8), rel)
        }
    }
}

/// Per-scene ceilings at the camera hint, balanced tier, frustum-accurate.
struct PerfBudget: Codable, Equatable {
    var triangles: Int
    var shadowTriangles: Int
    var drawCalls: Int
}

@MainActor
func perfBudget(_ ids: [String], seed: UInt64, write: Bool) throws {
    let url = try repoRoot().appendingPathComponent("docs/perf-budgets.json")
    var budgets: [String: PerfBudget] = (try? JSONDecoder().decode([String: PerfBudget].self, from: Data(contentsOf: url))) ?? [:]
    var failures: [String] = []
    print(pad("scene", 22), pad("tris", 16), pad("shadow", 16), pad("draws", 12), "result")
    for id in ids {
        guard let scene = SceneCatalog.build(id, seed: seed) else { failures.append("\(id): unknown scene"); continue }
        let c = scene.estimate(settings: RealPerformance(.balanced), view: scene.viewVolume())
        let now = PerfBudget(triangles: c.triangles, shadowTriangles: c.shadowTriangles, drawCalls: c.drawCalls)
        if write {
            func up(_ v: Int, _ step: Int) -> Int { ((v * 105 / 100) / step + 1) * step }
            budgets[id] = PerfBudget(triangles: up(now.triangles, 1000), shadowTriangles: up(now.shadowTriangles, 1000), drawCalls: up(now.drawCalls, 5))
        }
        guard let b = budgets[id] else {
            failures.append("\(id): no budget (run realityhd perf --budget --write \(id))")
            print(pad(id, 22), pad("\(now.triangles / 1000)k", 16), pad("\(now.shadowTriangles / 1000)k", 16), pad("\(now.drawCalls)", 12), "no budget")
            continue
        }
        var over: [String] = []
        if now.triangles > b.triangles { over.append("tris \(now.triangles) > \(b.triangles)") }
        if now.shadowTriangles > b.shadowTriangles { over.append("shadow \(now.shadowTriangles) > \(b.shadowTriangles)") }
        if now.drawCalls > b.drawCalls { over.append("draws \(now.drawCalls) > \(b.drawCalls)") }
        if !over.isEmpty { failures.append("\(id): " + over.joined(separator: ", ")) }
        print(pad(id, 22), pad("\(now.triangles / 1000)k/\(b.triangles / 1000)k", 16), pad("\(now.shadowTriangles / 1000)k/\(b.shadowTriangles / 1000)k", 16),
              pad("\(now.drawCalls)/\(b.drawCalls)", 12), over.isEmpty ? "ok" : "OVER")
    }
    if write {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        try enc.encode(budgets).write(to: url)
        print("wrote \(url.path)")
        return
    }
    if !failures.isEmpty {
        for f in failures { print("over budget: \(f)") }
        exit(1)
    }
}

/// `realityhd perf --breakdown [scene...]`: balanced in-view draws and tris split into fields, statics and
/// live rigs, plus the live rigs with the most draws.
@MainActor
func perfBreakdown(_ ids: [String], seed: UInt64) {
    let perf = RealPerformance(.balanced)
    for id in ids {
        guard let scene = SceneCatalog.build(id, seed: seed) else { print("unknown scene \(id)"); continue }
        let view = scene.viewVolume()
        var f = scene; f.singles = []; f.rigs = []
        var s = scene; s.fields = []; s.rigs = []
        var r = scene; r.fields = []; r.singles = []
        print(id, "total", scene.estimate(settings: perf, view: view).drawCalls)
        for (n, part) in [("fields", f), ("statics", s), ("rigs", r)] {
            let c = part.estimate(settings: perf, view: view)
            print("  ", pad(n, 9), pad("\(c.drawCalls) draws", 12), "\(c.triangles / 1000)k tris")
        }
        var bySingle: [String: (n: Int, t: Int, d: Int, lods: [Int])] = [:]
        for sg in scene.singles {
            var one = s; one.singles = [sg]
            let c = one.estimate(settings: perf, view: view)
            let k = sg.asset.levels[0].name
            bySingle[k, default: (0, 0, 0, sg.asset.levels.map { $0.triangleCount })].n += 1
            bySingle[k, default: (0, 0, 0, [])].t += c.triangles
            bySingle[k, default: (0, 0, 0, [])].d += c.drawCalls
        }
        for (k, v) in bySingle.sorted(by: { $0.value.t > $1.value.t }).prefix(12) {
            print("     static", pad(k, 28), "x\(v.n)", pad("\(v.t / 1000)k", 7), "\(v.d)d", "lods", v.lods.map { "\($0)" }.joined(separator: "/"))
        }
        var byField: [String: (n: Int, t: Int, d: Int, lods: [Int])] = [:]
        for fld in scene.fields {
            var one = f; one.fields = [fld]
            let c = one.estimate(settings: perf, view: view)
            let k = fld.asset.levels[0].materials.joined(separator: ",").prefix(28).description
            let lods = fld.asset.levels.map { $0.triangleCount }
            byField[k, default: (0, 0, 0, lods)].n += fld.transforms.count
            byField[k, default: (0, 0, 0, lods)].t += c.triangles
            byField[k, default: (0, 0, 0, lods)].d += c.drawCalls
        }
        for (k, v) in byField.sorted(by: { $0.value.t > $1.value.t }).prefix(12) {
            print("     field", pad(k, 28), "x\(v.n)", pad("\(v.t / 1000)k", 7), "\(v.d)d", "lods", v.lods.map { "\($0)" }.joined(separator: "/"))
        }
        var byRig: [String: (n: Int, d: Int)] = [:]
        for rig in scene.rigs {
            var one = r; one.rigs = [rig]
            let d = one.estimate(settings: perf, view: view).drawCalls
            let posed = rig.rig.posed(rig.state), b = posed.levels[0].bounds
            let dist = simd_distance(rig.at.point((b.min + b.max) / 2), view.center)
            let lod0 = posed.switchDistances.first.map { dist < $0 * perf.lodBias } ?? true
            let k = (rig.name ?? rig.rig.base[0].name) + (lod0 ? " lod0" : " lod1+") + (rig.interactive ? "" : " passive")
            byRig[k, default: (0, 0)].n += 1; byRig[k, default: (0, 0)].d += d
        }
        for (k, v) in byRig.sorted(by: { $0.value.d > $1.value.d }).prefix(12) { print("     ", pad(k, 32), "x\(v.n)", v.d) }
    }
}
