import simd
import Foundation

/// Binary form of a complete `LODModel` (every level, switch distances, anchors). Used by the prebake
/// pipeline: a decoded model replaces generation, AO baking and LOD simplification.
public enum LODModelCodec {
    /// Bump when the layout changes.
    public static let version: UInt32 = 1
    static let magic: UInt32 = 0x3141_4652   // "RFA1"

    public static func encode(_ m: LODModel) -> Data {
        var d = Data()
        func u32(_ v: Int) { var x = UInt32(v); d.append(Data(bytes: &x, count: 4)) }
        func arr<T>(_ a: [T]) { u32(a.count); a.withUnsafeBytes { d.append(contentsOf: $0) } }
        u32(Int(magic)); u32(Int(version))
        arr(m.switchDistances)
        let anchors = m.anchors.sorted { $0.key < $1.key }
        u32(anchors.count)
        for (name, x) in anchors {
            arr(Array(name.utf8))
            arr([x.translation.x, x.translation.y, x.translation.z, x.rotation.vector.x, x.rotation.vector.y, x.rotation.vector.z,
                 x.rotation.vector.w, x.scale.x, x.scale.y, x.scale.z])
        }
        u32(m.levels.count)
        for l in m.levels {
            arr(Array(l.name.utf8))
            u32(l.surfaces.count)
            for s in l.surfaces {
                arr(Array(s.material.utf8)); arr(s.positions); arr(s.normals); arr(s.uvs); arr(s.tangents)
                arr(s.extra); arr(s.occlusion); arr(s.splat); arr(s.indices)
            }
        }
        return d
    }

    public static func decode(_ d: Data) -> LODModel? {
        var o = 0
        func u32() -> Int? {
            guard o + 4 <= d.count else { return nil }
            let v = d.withUnsafeBytes { $0.loadUnaligned(fromByteOffset: o, as: UInt32.self) }
            o += 4; return Int(v)
        }
        func arr<T>(_: T.Type) -> [T]? {
            guard let n = u32() else { return nil }
            let bytes = n * MemoryLayout<T>.stride
            guard o + bytes <= d.count else { return nil }
            let a = [T](unsafeUninitializedCapacity: n) { buf, c in
                if bytes > 0 { d.withUnsafeBytes { memcpy(buf.baseAddress!, $0.baseAddress! + o, bytes) } }
                c = n
            }
            o += bytes; return a
        }
        func str() -> String? { arr(UInt8.self).map { String(decoding: $0, as: UTF8.self) } }
        guard u32() == Int(magic), u32() == Int(version), let dist = arr(Float.self), let ac = u32() else { return nil }
        var anchors: [String: Xform] = [:]
        for _ in 0..<ac {
            guard let name = str(), let f = arr(Float.self), f.count == 10 else { return nil }
            anchors[name] = Xform(translation: V3(f[0], f[1], f[2]), rotation: simd_quatf(ix: f[3], iy: f[4], iz: f[5], r: f[6]), scale: V3(f[7], f[8], f[9]))
        }
        guard let lc = u32(), lc >= 1, dist.count == lc - 1 else { return nil }
        var levels: [Model] = []
        for _ in 0..<lc {
            guard let name = str(), let sc = u32() else { return nil }
            var m = Model(name: name)
            var surfaces: [Surface] = []
            for _ in 0..<sc {
                guard let mat = str(), let p = arr(V3.self), let n = arr(V3.self), let uv = arr(V2.self), let t = arr(V4.self),
                      let e = arr(V2.self), let occ = arr(Float.self), let sp = arr(Float.self), let ix = arr(UInt32.self) else { return nil }
                var s = Surface(material: mat)
                s.positions = p; s.normals = n; s.uvs = uv; s.tangents = t; s.extra = e; s.occlusion = occ; s.splat = sp; s.indices = ix
                surfaces.append(s)
            }
            m.surfaces = surfaces
            levels.append(m)
        }
        var out = LODModel(levels: levels, switchDistances: dist)
        out.anchors = anchors
        return out
    }
}
