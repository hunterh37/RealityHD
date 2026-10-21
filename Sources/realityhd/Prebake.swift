import Foundation
import RealCore
import RealMaterials
import RealKit
import RealLibrary

/// `realityhd prebake [--manifest prebake.json] [--asset id[:seed],...] [--scene id[:seed],...] [--all] [--no-textures] [--out dir] [--verify]`
/// Writes the folder an app ships as `RealityHDPrebaked`: `assets/*.rfasset` (geometry + LODs), `ao/*.rfao`
/// (scene occlusion), `textures/*.rftex` (synthesized PBR maps at the chosen `--tier`) and `manifest.json`.
/// Manifest file: {"assets": ["oak-tree", "mug:3"], "scenes": ["forest-glade"]}.
/// `--verify` rebuilds every baked asset and lists files that no longer match the code.
@MainActor
func prebakeCommand(_ args: Args) async throws {
    struct Spec: Codable { var assets: [String] = []; var scenes: [String] = [] }
    var spec = Spec()
    if let path = args.opt("--manifest") { spec = try JSONDecoder().decode(Spec.self, from: Data(contentsOf: URL(fileURLWithPath: path))) }
    spec.assets += (args.opt("--asset") ?? "").split(separator: ",").map(String.init)
    spec.scenes += (args.opt("--scene") ?? "").split(separator: ",").map(String.init)
    if args.flag("--all") { spec.assets = Catalog.assets.map { $0.id }; spec.scenes = SceneCatalog.ids }
    let verify = args.flag("--verify"), textures = !args.flag("--no-textures")
    let out = URL(fileURLWithPath: args.opt("--out") ?? "out/RealityHDPrebaked", isDirectory: true)
    guard !spec.assets.isEmpty || !spec.scenes.isEmpty else { throw CLIError("usage: realityhd prebake --manifest prebake.json | --asset a,b --scene s | --all") }
    func split(_ s: String) -> (String, UInt64) {
        let p = s.split(separator: ":"); return (String(p[0]), p.count > 1 ? UInt64(p[1]) ?? 1 : 1)
    }
    let t0 = Date()
    RealKitSetup.register()
    RealPrebake.directories = []; RealPrebake.cacheDirectory = out; RealPrebake.writeThrough = true
    RealTextureDiskCache.directory = out.appendingPathComponent("textures", isDirectory: true)
    RealTextureDiskCache.bundledDirectories = []
    var keys = Set<MaterialKey>(), stale: [String] = []
    for item in spec.assets {
        let (id, seed) = split(item)
        guard let t = Catalog.type(id) else { throw CLIError("unknown asset \(id)") }
        let lod = t.init().build(seed: seed)
        keys.formUnion(lod.levels.flatMap(\.materials))
        if verify {
            let file = out.appendingPathComponent("assets/" + RealPrebake.assetFile(id: id, seed: seed))
            if (try? Data(contentsOf: file)) != LODModelCodec.encode(lod) { stale.append(item) }
        } else {
            RealPrebake.store(lod, id: id, seed: seed, in: out)
        }
    }
    if verify {
        print(stale.isEmpty ? "prebake current: \(spec.assets.count) assets" : "stale: " + stale.joined(separator: " "))
        if !stale.isEmpty { exit(1) }
        return
    }
    for item in spec.scenes {
        let (id, seed) = split(item)
        guard let s = SceneCatalog.build(id, seed: seed) else { throw CLIError("unknown scene \(id)") }
        keys.formUnion(s.materialKeys)
        _ = try await s.entity()   // runs the AO bake; the result lands in ao/
    }
    let cache = RealMaterialCache.shared
    for base in Set(keys.map { String($0.split(separator: ":")[0]) }).sorted() where textures {
        let s = cache.spec(base)
        if s.program != nil { _ = try cache.textures(s) }
    }
    cache.waitForGPU(); RealTextureDiskCache.flush(); RealPrebake.flush()
    let files = FileManager.default.enumerator(at: out, includingPropertiesForKeys: [.fileSizeKey])?.compactMap { $0 as? URL } ?? []
    let sizes = files.map { (try? $0.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0 }
    let m = RealPrebake.Manifest(tier: (RealPerformance.current.tier?.rawValue ?? "custom"), assets: spec.assets, scenes: spec.scenes,
                                 textureFiles: files.filter { $0.pathExtension == "rftex" }.count, bytes: sizes.reduce(0, +),
                                 seconds: Date().timeIntervalSince(t0))
    try JSONEncoder().encode(m).write(to: out.appendingPathComponent("manifest.json"))
    print(String(format: "%@ %d assets %d scenes %d textures %.1f MB %.1fs", out.path, spec.assets.count, spec.scenes.count,
                 m.textureFiles, Double(m.bytes) / 1_048_576, m.seconds))
}
