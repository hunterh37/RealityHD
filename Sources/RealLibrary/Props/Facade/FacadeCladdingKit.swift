import simd
import Foundation

/// Helpers for cladding and masonry panels. Wall plane at z = 0, faces toward +Z.
enum FCL {
    /// Heightfield sheet in the XY plane facing +Z, centered at `c`. `height(x, y)` in meters, local coords.
    static func face(_ m: inout Model, w: Float, h: Float, seg: Int, at c: V3, _ mat: MaterialKey,
                     height: (Float, Float) -> Float) {
        let n = max(2, seg)
        var s = Prim.terrain(size: V2(w, h), segments: n, material: mat) { p in height(p.x, -p.y) }
        if s.positions.isEmpty { return }
        s.bakeCavityAO(strength: 0.8, floor: 0.55)
        m.add(s, Xform(translation: c, rotation: FA.q(90, FA.X)))
    }
    /// 0 at the sheet edge rising to 1 inside `margin`.
    static func edge(_ x: Float, _ y: Float, _ w: Float, _ h: Float, _ margin: Float) -> Float {
        let dx = min(x + w / 2, w / 2 - x), dy = min(y + h / 2, h / 2 - y)
        let t = max(0, min(1, min(dx, dy) / margin))
        return t * t * (3 - 2 * t)
    }
    /// Countersunk / pan screw head facing +Z.
    static func screw(_ m: inout Model, at c: V3, r: Float, _ mat: MaterialKey) {
        m.add(Prim.lathe([V2(0, 0), V2(r, 0), V2(r, r * 0.25), V2(r * 0.7, r * 0.6), V2(0, r * 0.65)], segments: 12, material: mat),
              Xform(translation: c, rotation: FA.q(90, FA.X)))
        FA.box(&m, V3(r * 1.3, r * 0.22, r * 0.3), c + V3(0, 0, r * 0.6), "metal.anodized-black", r: 0.0003)
    }
    /// Hard 12-triangle box for tiny repeated hardware.
    static func cube(_ m: inout Model, _ size: V3, _ c: V3, _ mat: MaterialKey) {
        var s = Surface(material: mat)
        let h = size / 2
        let axes: [(V3, V3, V3)] = [(V3(1,0,0), V3(0,1,0), V3(0,0,1)), (V3(-1,0,0), V3(0,0,1), V3(0,1,0)),
                                    (V3(0,1,0), V3(0,0,1), V3(1,0,0)), (V3(0,-1,0), V3(1,0,0), V3(0,0,1)),
                                    (V3(0,0,1), V3(1,0,0), V3(0,1,0)), (V3(0,0,-1), V3(0,1,0), V3(1,0,0))]
        for (n, u, v) in axes {
            let o = n * h, du = u * h, dv = v * h
            let a = s.add(o - du - dv, n, V2(0, 0)), b = s.add(o + du - dv, n, V2(size.x, 0))
            let c2 = s.add(o + du + dv, n, V2(size.x, size.y)), d = s.add(o - du + dv, n, V2(0, size.y))
            s.quad(a, b, c2, d)
        }
        s.computeTangents()
        m.add(s, Xform(translation: c))
    }
    /// Heightfield sheet with separate X/Y resolution, facing +Z, centered at `c`.
    static func grid(_ m: inout Model, w: Float, h: Float, nx: Int, ny: Int, at c: V3, _ mat: MaterialKey, ao: Bool = true,
                     height: (Float, Float) -> Float) {
        var s = Surface(material: mat)
        for j in 0...ny { for i in 0...nx {
            let x = (Float(i) / Float(nx) - 0.5) * w, y = (Float(j) / Float(ny) - 0.5) * h
            _ = s.add(V3(x, y, height(x, y)), V3(0, 0, 1), V2(x, y))
        }}
        let row = UInt32(nx + 1)
        for j in 0..<UInt32(ny) { for i in 0..<UInt32(nx) {
            let a = j * row + i
            s.quad(a, a + 1, a + row + 1, a + row)
        }}
        s.recomputeNormals(weldSeams: false)
        s.computeTangents()
        if ao { s.bakeCavityAO(strength: 0.8, floor: 0.55) }
        m.add(s, Xform(translation: c))
    }
}
