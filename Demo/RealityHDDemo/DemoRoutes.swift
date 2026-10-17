#if DEBUG
import Foundation
import DicyaninStageDirector

/// StageDirector routes: walking takes through demo scenes (`walk/<scene>`). Params: `dolly` m/s,
/// `pan` deg/s, `steps` seconds between walk steps (0 = continuous dolly).
@MainActor
enum DemoRoutes {
    static func register(_ b: RouteBook, model: DemoModel, enter: @escaping @MainActor (DemoScene) async -> Void) {
        b.group("walk") { b in
            for scene in [DemoScene.forestGlade, .hospital, .parkPath, .linemanDistrict, .siphonCafe] {
                b.route(scene.rawValue, "Walk through \(scene.rawValue)", duration: 12, tags: ["walk", "perf"]) { t in
                    let d = UserDefaults.standard
                    d.set(t.param("dolly", default: 0.6), forKey: "dolly")
                    d.set(t.param("pan", default: 0), forKey: "pan")
                    d.set(t.param("steps", default: 0), forKey: "steps")
                    if let sky = scene.defaultSky { model.sky = sky }
                    model.seed = t.seed
                    await enter(scene)
                    while model.open == nil || model.loading { await t.wait(0.1) }
                    await t.wait(1.5)
                    await t.ready()
                    t.cue("walk")
                    await t.wait(t.param("duration", default: 12))
                    t.done()
                }
            }
        }
    }
}
#endif
