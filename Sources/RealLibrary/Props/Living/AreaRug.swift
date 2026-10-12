import simd
import Foundation

/// Wool area rug: flat-woven neutral wool rug, navy and ivory border, faint wear. Parts: wool pile field, woven border band pattern in geometry, bound outer edge, knotted fringe on short ends, central medallion.
public struct AreaRug: RealAsset {
    public static let id = "area-rug"
    public static let summary = "Wool area rug, 2.4 x 1.7 m, flat: woven border bands, central medallion, bound edge and knotted fringe on the short ends."
    public static let tags = ["prop", "floorplan", "living", "decor", "fabric", "interior"]
    public static let budget = 7500
    public static let author = "realityhd"

    /// Overall size in meters (x width including fringe, y pile height, z depth).
    public var size = V3(2.4, 0.012, 1.7)
    /// Field (center) wool tint.
    public var fieldKey: MaterialKey = "carpet.rug:D9CDB8"
    /// Border and medallion wool tint.
    public var darkKey: MaterialKey = "carpet.rug:26364F"
    /// Accent wool tint (rust stripes and diamonds).
    public var accentKey: MaterialKey = "carpet.rug:A4553A"
    /// Ivory wool tint (bands and fringe).
    public var ivoryKey: MaterialKey = "carpet.rug:EFE8DA"
    public init() {}

    /// Four boxes forming a rectangular ring from the outer to the inner half-extents.
    private func ring(_ m: inout Model, ox: Float, oz: Float, ix: Float, iz: Float, y0: Float, y1: Float, key: MaterialKey) {
        let h = y1 - y0, cy = (y0 + y1) / 2, r: Float = min(0.0015, h / 2.5)
        let sz = oz - iz
        for s: Float in [-1, 1] {
            m.add(Prim.roundedBox(V3(ox * 2, h, sz), radius: r, bevelSegments: 1, material: key), Xform(translation: V3(0, cy, s * (oz + iz) / 2)))
            m.add(Prim.roundedBox(V3(ox - ix, h, iz * 2 - 0.0015), radius: r, bevelSegments: 1, material: key), Xform(translation: V3(s * (ox + ix) / 2, cy, 0)))
        }
    }

    /// Flat polygon (XZ outline) of height h on top of y0.
    private func flat(_ m: inout Model, _ pts: [V2], y0: Float, h: Float, key: MaterialKey, at c: V3 = .zero, rot: Float = 0) {
        let s = Prim.extrude(pts, depth: h, bevel: min(0.0008, h / 3), bevelSegments: 1, material: key)
        let q = simd_quatf(degrees: -90, axis: V3(1, 0, 0))
        m.add(s, Xform(translation: V3(c.x, y0 + h / 2, c.z), rotation: simd_quatf(degrees: rot, axis: .up) * q))
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let fringe: Float = 0.07
        let hx = (size.x - 2 * fringe) / 2, hz = size.z / 2
        let top = size.y
        // Pile body (field).
        m.add(Prim.roundedBox(V3(hx * 2, 0.008, hz * 2), radius: 0.003, bevelSegments: 2, material: fieldKey), Xform(translation: V3(0, 0.004, 0)))
        // Border rings, outside in: binding, ivory, dark main band, ivory, accent line, then field.
        let a = hx, b = hz
        ring(&m, ox: a, oz: b, ix: a - 0.022, iz: b - 0.022, y0: 0.004, y1: top - 0.0008, key: darkKey)
        ring(&m, ox: a - 0.022, oz: b - 0.022, ix: a - 0.04, iz: b - 0.04, y0: 0.006, y1: top - 0.0018, key: ivoryKey)
        let mo = (a - 0.04, b - 0.04), mi = (a - 0.2, b - 0.2)
        ring(&m, ox: mo.0, oz: mo.1, ix: mi.0, iz: mi.1, y0: 0.006, y1: top - 0.0004, key: darkKey)
        ring(&m, ox: mi.0, oz: mi.1, ix: mi.0 - 0.02, iz: mi.1 - 0.02, y0: 0.006, y1: top - 0.0018, key: ivoryKey)
        ring(&m, ox: mi.0 - 0.02, oz: mi.1 - 0.02, ix: mi.0 - 0.032, iz: mi.1 - 0.032, y0: 0.006, y1: top - 0.0012, key: accentKey)
        // Diamond motifs marching around the main band.
        let cx = a - 0.12, cz = b - 0.12, dsz: Float = 0.052
        let dia: [V2] = [V2(0, dsz), V2(dsz * 0.62, 0), V2(0, -dsz), V2(-dsz * 0.62, 0)]
        func motif(_ x: Float, _ z: Float) {
            flat(&m, dia, y0: top - 0.001, h: 0.0006, key: ivoryKey, at: V3(x, 0, z), rot: 90)
            flat(&m, dia.map { $0 * 0.5 }, y0: top - 0.0004, h: 0.0004, key: accentKey, at: V3(x, 0, z), rot: 90)
        }
        let nx = Int((cx * 2 / 0.14).rounded()), nz = Int((cz * 2 / 0.14).rounded())
        for i in 0...nx { let x = -cx + Float(i) * cx * 2 / Float(nx); motif(x, -cz); motif(x, cz) }
        for j in 1..<nz { let z = -cz + Float(j) * cz * 2 / Float(nz); motif(-cx, z); motif(cx, z) }
        // Central medallion: nested diamonds and a rosette ring.
        let fx = mi.0 - 0.032, fz = mi.1 - 0.032
        let d1: [V2] = [V2(-fx * 0.55, 0), V2(0, fz * 0.9), V2(fx * 0.55, 0), V2(0, -fz * 0.9)]
        let y0: Float = 0.0075
        flat(&m, d1, y0: y0, h: top - y0 - 0.0014, key: darkKey)
        flat(&m, d1.map { $0 * 0.82 }, y0: y0, h: top - y0 - 0.0008, key: ivoryKey)
        flat(&m, d1.map { $0 * 0.66 }, y0: y0, h: top - y0 - 0.0004, key: accentKey)
        flat(&m, d1.map { $0 * 0.48 }, y0: y0, h: top - y0 - 0.0001, key: darkKey)
        m.add(Prim.torus(major: fz * 0.22, minor: 0.0014, segments: 24, sides: 4, material: ivoryKey), Xform(translation: V3(0, top - 0.0016, 0)))
        // Knotted fringe: warp threads on both short ends.
        let nf = 36
        for s: Float in [-1, 1] {
            for i in 0..<nf {
                let z = -hz + 0.02 + (hz * 2 - 0.04) * Float(i) / Float(nf - 1)
                let len = fringe * rng.float(0.9...1.0), off = rng.float(-0.012...0.012)
                let path = [V3(s * (hx - 0.004), 0.0035, z), V3(s * (hx + len * 0.5), 0.0028, z + off * 0.5), V3(s * (hx + len), 0.0022, z + off)]
                m.add(Prim.tube(path, radii: [0.0022, 0.0019, 0.0016], sides: 4, seamTile: 0.03, material: ivoryKey, capEnd: true))
            }
            m.add(Prim.roundedBox(V3(0.012, 0.005, hz * 2 - 0.03), radius: 0.002, bevelSegments: 1, material: ivoryKey), Xform(translation: V3(s * (hx + 0.004), 0.0028, 0)))
        }
        let bb = m.bounds
        m = m.transformed(Xform(translation: V3(-(bb.min.x + bb.max.x) / 2, -bb.min.y, -(bb.min.z + bb.max.z) / 2)))
        groundAO(&m, height: 0.004, floor: 0.7)
        return LODModel(m)
    }
}
