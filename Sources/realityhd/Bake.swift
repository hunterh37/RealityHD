import Foundation
import simd
import RealCore
import RealMaterials
import RealKit
import RealLibrary
import AnimalCore
import AnimalKit
import CoreGraphics

/// `realityhd bake-scene <id> [--seed n] [--lod n] [--max-tris n] [--size px] [--out dir]`:
/// flattens a scene (singles plus every instanced field) into one static model and writes `<out>/<id>.glb`
/// and, with Blender on PATH, `<out>/<id>.usdz`. Fields are thinned evenly until the model fits `--max-tris`.
func bakeSceneCommand(_ args: Args) throws {
    guard let id = args.rest.first(where: { !$0.hasPrefix("--") }) else { throw CLIError("usage: realityhd bake-scene <id>") }
    let seed = UInt64(args.opt("--seed") ?? "1") ?? 1
    let lod = Int(args.opt("--lod") ?? "2") ?? 2
    let maxTris = Int(args.opt("--max-tris") ?? "600000") ?? 600_000
    let size = Int(args.opt("--size") ?? "512") ?? 512
    let outDir = args.opt("--out") ?? "out/bake"
    guard let scene = SceneCatalog.build(id, seed: seed) else { throw CLIError("unknown scene \(id)") }

    var model = Model(name: id)
    for s in scene.singles { model.add(s.asset.levels[min(lod, s.asset.levels.count - 1)], s.at) }
    let fixed = model.triangleCount
    var fieldTris = 0
    for f in scene.fields { fieldTris += f.asset.levels[min(lod, f.asset.levels.count - 1)].triangleCount * f.transforms.count }
    let budget = max(0, maxTris - fixed)
    let keep = fieldTris > budget ? Double(budget) / Double(max(1, fieldTris)) : 1
    for f in scene.fields {
        let m = f.asset.levels[min(lod, f.asset.levels.count - 1)]
        let stride = keep >= 1 ? 1 : max(1, Int((1 / max(keep, 0.0001)).rounded()))
        for (i, t) in f.transforms.enumerated() where i % stride == 0 {
            model.add(m, xform(t))
        }
    }
    try writeBaked(model.finalized(), id: id, outDir: outDir, size: size, resolve: { MaterialLibrary.spec(for: $0) })
}

/// `realityhd bake-asset <id>... [--state s] [--seed n] [--out dir] [--size px]`: static USDZ of catalog assets (lowest-detail level 0).
func bakeAssetCommand(_ args: Args) throws {
    let seed = UInt64(args.opt("--seed") ?? "1") ?? 1
    let size = Int(args.opt("--size") ?? "512") ?? 512
    let outDir = args.opt("--out") ?? "out/bake"
    let state = args.opt("--state")
    for id in args.rest {
        let lm: LODModel
        if let rig = Catalog.rig(id, seed: seed) { lm = rig.posed(state) }
        else if let b = Catalog.build(id, seed: seed) { lm = b }
        else { throw CLIError("unknown id \(id)") }
        try writeBaked(lm.levels[0], id: id, outDir: outDir, size: size, resolve: { MaterialLibrary.spec(for: $0) })
    }
}

/// `realityhd bake-buck [--out dir] [--size px]`: static antlered whitetail in its stand pose.
@MainActor
func bakeBuckCommand(_ args: Args) async throws {
    let outDir = args.opt("--out") ?? "out/bake"
    let size = Int(args.opt("--size") ?? "1024") ?? 1024
    let profile = GroundSpecies.whitetailDeer.profile(.antlered)
    AnimalMaterials.register(profile)
    let built = GroundRigBuilder.build(profile)
    let lm = built.rig.posed("stand")
    let overrides = RealMaterialCache.shared.overrides
    try writeBaked(lm.levels[0], id: "whitetail-buck", outDir: outDir, size: size, resolve: { overrides[$0] ?? MaterialLibrary.spec(for: $0) })
}

private func xform(_ m: simd_float4x4) -> Xform {
    let sx = simd_length(SIMD3(m.columns.0.x, m.columns.0.y, m.columns.0.z))
    let sy = simd_length(SIMD3(m.columns.1.x, m.columns.1.y, m.columns.1.z))
    let sz = simd_length(SIMD3(m.columns.2.x, m.columns.2.y, m.columns.2.z))
    let r = simd_float3x3(SIMD3(m.columns.0.x, m.columns.0.y, m.columns.0.z) / sx,
                          SIMD3(m.columns.1.x, m.columns.1.y, m.columns.1.z) / sy,
                          SIMD3(m.columns.2.x, m.columns.2.y, m.columns.2.z) / sz)
    return Xform(translation: SIMD3(m.columns.3.x, m.columns.3.y, m.columns.3.z), rotation: simd_quatf(r), scale: SIMD3(sx, sy, sz))
}

private func writeBaked(_ model: Model, id: String, outDir: String, size: Int, resolve: @escaping (MaterialKey) -> MaterialSpec) throws {
    let fm = FileManager.default
    let stage = "\(outDir)/\(id)-usd"
    try? fm.removeItem(atPath: stage)
    try fm.createDirectory(atPath: "\(stage)/tex", withIntermediateDirectories: true)
    var merged: [MaterialKey: Surface] = [:], order: [MaterialKey] = []
    for s in model.surfaces where !s.isEmpty {
        if merged[s.material] == nil { merged[s.material] = Surface(material: s.material); order.append(s.material) }
        merged[s.material]!.append(s, Xform())
    }
    func f3(_ v: V3) -> String { "(\(v.x), \(v.y), \(v.z))" }
    var meshes = "", mats = ""
    for (i, key) in order.enumerated() {
        let s = merged[key]!
        let spec = resolve(key)
        let tile: Float = spec.tileSize > 0 && spec.mode != .emissive ? spec.tileSize : 1
        let uvs = s.uvs.count == s.positions.count ? s.uvs : Array(repeating: V2(0, 0), count: s.positions.count)
        let idx = s.indices.map(String.init).joined(separator: ", ")
        meshes += """
            def Mesh "m\(i)" (prepend apiSchemas = ["MaterialBindingAPI"]) {
                int[] faceVertexCounts = [\(Array(repeating: "3", count: s.indices.count / 3).joined(separator: ", "))]
                int[] faceVertexIndices = [\(idx)]
                point3f[] points = [\(s.positions.map(f3).joined(separator: ", "))]
                normal3f[] normals = [\(s.normals.map(f3).joined(separator: ", "))] (interpolation = "vertex")
                texCoord2f[] primvars:st = [\(uvs.map { "(\($0.x / tile), \(1 - $0.y / tile))" }.joined(separator: ", "))] (interpolation = "vertex")
                uniform token subdivisionScheme = "none"
                rel material:binding = </Root/Materials/M\(i)>
            }

        """
        var inputs = ""
        var shaders = ""
        func tex(_ name: String, _ img: CGImage, channel: String, raw: Bool, extra: String = "") -> String {
            writePNG(img, "\(stage)/tex/m\(i)-\(name).png")
            shaders += """
                    def Shader "\(name)Tex" {
                        uniform token info:id = "UsdUVTexture"
                        asset inputs:file = @tex/m\(i)-\(name).png@
                        float2 inputs:st.connect = </Root/Materials/M\(i)/uv.outputs:result>
                        token inputs:wrapS = "repeat"
                        token inputs:wrapT = "repeat"
                        token inputs:sourceColorSpace = "\(raw ? "raw" : "sRGB")"
                        \(extra)
                        float\(channel == "rgb" ? "3" : "") outputs:\(channel)
                    }

            """
            return "</Root/Materials/M\(i)/\(name)Tex.outputs:\(channel)>"
        }
        var rough = "float inputs:roughness = \(spec.roughness)", metal = "float inputs:metallic = \(spec.metallic)"
        var diffuse = "color3f inputs:diffuseColor = \(f3(spec.baseColor))", normal = ""
        if spec.program != nil, let synth = TextureSynth.shared, let set = try? synth.generate(spec, size: size) {
            if let a = synth.cgImage(set.albedo) { diffuse = "color3f inputs:diffuseColor.connect = " + tex("albedo", a, channel: "rgb", raw: false) }
            if let r = synth.cgImage(set.roughness) { rough = "float inputs:roughness.connect = " + tex("rough", r, channel: "r", raw: true) }
            if let m = set.metallic.flatMap({ synth.cgImage($0) }) { metal = "float inputs:metallic.connect = " + tex("metal", m, channel: "r", raw: true) }
            if let n = synth.cgImage(set.normal) {
                normal = "normal3f inputs:normal.connect = " + tex("normal", n, channel: "rgb", raw: true, extra: "float4 inputs:scale = (2, 2, 2, 1)\n                        float4 inputs:bias = (-1, -1, -1, 0)")
            }
        }
        var emissive = ""
        if spec.mode == .emissive { emissive = "color3f inputs:emissiveColor = \(f3(spec.emissive == .zero ? spec.baseColor : spec.emissive))" }
        var opacity = ""
        if spec.mode == .transparent { opacity = "float inputs:opacity = \(spec.opacity)" }
        mats += """
            def Material "M\(i)" {
                token outputs:surface.connect = </Root/Materials/M\(i)/pbr.outputs:surface>
                def Shader "uv" {
                    uniform token info:id = "UsdPrimvarReader_float2"
                    token inputs:varname = "st"
                    float2 outputs:result
                }
        \(shaders)
                def Shader "pbr" {
                    uniform token info:id = "UsdPreviewSurface"
                    \(diffuse)
                    \(rough)
                    \(metal)
                    \(normal)
                    \(emissive)
                    \(opacity)
                    token outputs:surface
                }
            }

        """
        _ = inputs; inputs = ""
    }
    let usda = """
    #usda 1.0
    (
        defaultPrim = "Root"
        metersPerUnit = 1
        upAxis = "Y"
    )

    def Xform "Root" {
    \(meshes)
        def Scope "Materials" {
    \(mats)
        }
    }

    """
    try usda.write(toFile: "\(stage)/\(id).usda", atomically: true, encoding: .utf8)
    let usdz = "\(outDir)/\(id).usdz"
    try? fm.removeItem(atPath: usdz)
    // Binary crate: the text layer takes seconds to parse at load.
    let cat = Process(); cat.executableURL = URL(fileURLWithPath: "/usr/bin/usdcat")
    cat.arguments = ["\(stage)/\(id).usda", "-o", "\(stage)/\(id).usdc"]
    try cat.run(); cat.waitUntilExit()
    try? fm.removeItem(atPath: "\(stage)/\(id).usda")
    let p = Process(); p.executableURL = URL(fileURLWithPath: "/usr/bin/usdzip")
    p.currentDirectoryURL = URL(fileURLWithPath: stage)
    p.arguments = [URL(fileURLWithPath: usdz).standardizedFileURL.path, "\(id).usdc"] + ((try? fm.contentsOfDirectory(atPath: "\(stage)/tex"))?.sorted().map { "tex/\($0)" } ?? [])
    try p.run(); p.waitUntilExit()
    print(fm.fileExists(atPath: usdz) ? "\(usdz) tris \(model.triangleCount)" : "usdz: usdzip failed")
}
