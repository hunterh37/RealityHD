import Foundation
#if canImport(CryptoKit)
import CryptoKit
#endif

/// On-disk cache of `LODModel.withAutoLevels` results, keyed by asset id, seed, the LOD0 shape and the
/// simplifier version. A hit replaces edge-collapse simplification with a file read. Location:
/// ~/Library/Caches/RealityHD/lods. Opt out with `isEnabled = false`, REALITYHD_NO_DISK_CACHE=1 or REALITYHD_NO_LOD_CACHE=1.
public enum SimplifyDiskCache {
    nonisolated(unsafe) public static var isEnabled = ProcessInfo.processInfo.environment["REALITYHD_NO_DISK_CACHE"] == nil
        && ProcessInfo.processInfo.environment["REALITYHD_NO_LOD_CACHE"] == nil
    nonisolated(unsafe) public static var directory: URL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("RealityHD/lods", isDirectory: true)
    /// Bump when `withAutoLevels` or the file layout changes.
    public static let version = 1

    static func url(id: String, seed: UInt64, base: Model, minTriangles: Int) -> URL {
        let b = base.bounds
        let text = "v\(version)|\(id)|\(seed)|\(minTriangles)|\(base.triangleCount)|\(base.vertexCount)|\(b.min)|\(b.max)"
        #if canImport(CryptoKit)
        let h = SHA256.hash(data: Data(text.utf8)).prefix(16).map { String(format: "%02x", $0) }.joined()
        #else
        let h = String(text.hashValue, radix: 16)
        #endif
        return directory.appendingPathComponent("\(id)-\(seed)-\(h).rflod")
    }

    public static func clear() { try? FileManager.default.removeItem(at: directory) }

    static func encode(_ m: LODModel) -> Data {
        var d = Data()
        func u32(_ v: Int) { var x = UInt32(v); d.append(Data(bytes: &x, count: 4)) }
        func arr<T>(_ a: [T]) { u32(a.count); a.withUnsafeBytes { d.append(contentsOf: $0) } }
        u32(m.levels.count - 1)
        arr(m.switchDistances)
        for (i, l) in m.levels.enumerated() {
            // LOD0 is the caller's model and is not stored.
            if i == 0 { u32(0); continue }
            u32(l.surfaces.count)
            for s in l.surfaces {
                let name = Array(s.material.utf8)
                arr(name); arr(s.positions); arr(s.normals); arr(s.uvs); arr(s.tangents)
                arr(s.extra); arr(s.occlusion); arr(s.splat); arr(s.indices)
            }
        }
        return d
    }

    static func decode(_ d: Data) -> LODModel? {
        var o = 0
        func u32() -> Int? {
            guard o + 4 <= d.count else { return nil }
            let v = d.subdata(in: o..<o + 4).withUnsafeBytes { $0.loadUnaligned(as: UInt32.self) }
            o += 4; return Int(v)
        }
        func arr<T>(_: T.Type) -> [T]? {
            guard let n = u32() else { return nil }
            let bytes = n * MemoryLayout<T>.stride
            guard n >= 0, o + bytes <= d.count else { return nil }
            let a = [T](unsafeUninitializedCapacity: n) { buf, c in
                d.withUnsafeBytes { raw in
                    if bytes > 0 { memcpy(buf.baseAddress!, raw.baseAddress! + o, bytes) }
                }
                c = n
            }
            o += bytes; return a
        }
        guard let extra = u32(), let dist = arr(Float.self), dist.count == extra else { return nil }
        var levels: [Model] = []
        for i in 0...extra {
            guard let sc = u32() else { return nil }
            var m = Model(name: "lod\(i)")
            for _ in 0..<sc {
                guard let name = arr(UInt8.self) else { return nil }
                var s = Surface(material: String(decoding: name, as: UTF8.self))
                guard let p = arr(V3.self), let n = arr(V3.self), let uv = arr(V2.self), let t = arr(V4.self),
                      let e = arr(V2.self), let occ = arr(Float.self), let sp = arr(Float.self), let ix = arr(UInt32.self) else { return nil }
                s.positions = p; s.normals = n; s.uvs = uv; s.tangents = t; s.extra = e; s.occlusion = occ; s.splat = sp; s.indices = ix
                m.surfaces.append(s)
            }
            levels.append(m)
        }
        return LODModel(levels: levels, switchDistances: dist)
    }
}

public extension LODModel {
    /// `withAutoLevels`, read from or stored in `SimplifyDiskCache`. LOD0 is always the caller's own model.
    func withAutoLevels(cacheID id: String, seed: UInt64, minTriangles: Int = 1500) -> LODModel {
        guard SimplifyDiskCache.isEnabled, levels.count == 1, let base = levels.first, base.triangleCount >= minTriangles else {
            return withAutoLevels(minTriangles: minTriangles)
        }
        let url = SimplifyDiskCache.url(id: id, seed: seed, base: base, minTriangles: minTriangles)
        if let data = try? Data(contentsOf: url, options: .mappedIfSafe), let c = SimplifyDiskCache.decode(data),
           c.levels.count > 1 {
            var out = c
            out.levels[0] = base
            return out
        }
        let r = withAutoLevels(minTriangles: minTriangles)
        // Single-level results (nothing saved) are not stored; the next build recomputes them.
        if r.levels.count > 1 {
            let data = SimplifyDiskCache.encode(r)
            DispatchQueue.global(qos: .utility).async {
                try? FileManager.default.createDirectory(at: SimplifyDiskCache.directory, withIntermediateDirectories: true)
                try? data.write(to: url, options: .atomic)
            }
        }
        return r
    }
}
