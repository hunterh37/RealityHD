import Foundation
import simd
import RealCore
import RealLibrary

/// Output fingerprint of every asset and scene (FNV-1a over all geometry channels and transforms) plus
/// generation time. Used to prove perf changes are bit-identical: `realityhd hash > a.txt`, change, diff.
func hashCommand(_ args: [String]) {
    let filter = args.first { !$0.hasPrefix("-") }
    let timing = args.contains("--time")
    struct H {
        var h: UInt64 = 0xcbf29ce484222325
        mutating func u(_ x: UInt32) { h = (h ^ UInt64(x)) &* 0x100000001b3 }
        mutating func f(_ x: Float) { u(x.bitPattern) }
        mutating func s(_ x: String) { for b in x.utf8 { u(UInt32(b)) } }
        mutating func model(_ m: Model) {
            s(m.name)
            for sf in m.surfaces {
                s(sf.material)
                for p in sf.positions { f(p.x); f(p.y); f(p.z) }
                for p in sf.normals { f(p.x); f(p.y); f(p.z) }
                for p in sf.uvs { f(p.x); f(p.y) }
                for p in sf.tangents { f(p.x); f(p.y); f(p.z); f(p.w) }
                for p in sf.extra { f(p.x); f(p.y) }
                for p in sf.occlusion { f(p) }
                for p in sf.splat { f(p) }
                for i in sf.indices { u(i) }
            }
        }
        mutating func lod(_ l: LODModel) { for m in l.levels { model(m) }; for d in l.switchDistances { f(d) } }
        mutating func mat(_ m: simd_float4x4) { for c in 0..<4 { f(m[c].x); f(m[c].y); f(m[c].z); f(m[c].w) } }
    }
    func ms(_ t: Date) -> String { timing ? String(format: " %8.1f ms", Date().timeIntervalSince(t) * 1000) : "" }
    var totalA = 0.0, totalS = 0.0
    for t in Catalog.assets where filter == nil || t.id == filter {
        let t0 = Date(); let m = t.init().build(seed: 1); totalA += Date().timeIntervalSince(t0)
        var h = H(); h.lod(m)
        print("asset", t.id, String(h.h, radix: 16) + ms(t0))
    }
    for id in SceneCatalog.ids where filter == nil || id == filter {
        let t0 = Date(); let sc = SceneCatalog.build(id, seed: 1)!; totalS += Date().timeIntervalSince(t0)
        var h = H()
        for fd in sc.fields { h.lod(fd.asset); for m in fd.transforms { h.mat(m) } }
        for sg in sc.singles {
            h.lod(sg.asset); let x = sg.at
            h.f(x.translation.x); h.f(x.translation.y); h.f(x.translation.z)
            h.f(x.rotation.vector.x); h.f(x.rotation.vector.y); h.f(x.rotation.vector.z); h.f(x.rotation.vector.w)
            h.f(x.scale.x); h.f(x.scale.y); h.f(x.scale.z)
        }
        for r in sc.rigs { h.s(r.state ?? "-"); h.f(r.at.translation.x); h.f(r.at.translation.z) }
        print("scene", id, String(h.h, radix: 16) + ms(t0))
    }
    if timing { print(String(format: "total assets %.0f ms, scenes %.0f ms", totalA * 1000, totalS * 1000)) }
}
