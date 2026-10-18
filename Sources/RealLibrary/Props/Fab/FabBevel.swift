import simd
import Foundation

/// Bevelled box, wear and fingerprint helpers for fab tools. Every edge gets a 2-5 mm bevel.
extension ClusterKit {
    /// Box with all edges bevelled at `r` clamped to 2-5 mm (thin plates under 12 mm use sharp cuboids).
    public func bb(_ s: V3, _ c: V3, _ mat: MaterialKey, r: Float = 0.003, yaw: Float = 0, name: String? = nil) {
        let lim = min(s.x, min(s.y, s.z))
        let xf = Xform(translation: c, rotation: simd_quatf(degrees: yaw, axis: V3(0, 1, 0)))
        if lim < 0.012 { put(cuboid(s, material: mat), xf, name); return }
        let b = min(min(max(r, 0.002), 0.005), lim * 0.4)
        put(Prim.extrude(Shape2D.roundedRect(s.x, s.y, radius: b * 1.5, segments: 2), depth: s.z, bevel: b, bevelSegments: 1, material: mat), xf, name)
    }
    /// Scuffs: bare-metal streaks and grime patches on a +Z facing surface at `c`, spread over `w` x `h`.
    public func scuffs(_ c: V3, w: Float, h: Float, n: Int = 5, name: String? = nil) {
        for i in 0..<n {
            let f = Float(i) / Float(max(1, n - 1)) - 0.5
            let sx = 0.03 + 0.02 * Float((i * 7) % 3), sy = 0.004 + 0.002 * Float(i % 2)
            let mat: MaterialKey = i % 2 == 0 ? "metal.stainless" : "plastic.matte:A9ADAA"
            bb(V3(sx, sy, 0.0008), c + V3(f * w, (Float((i * 5) % 4) / 3 - 0.5) * h, 0.0004), mat, yaw: 0, name: name)
        }
        if hi { bb(V3(w * 0.9, h * 0.5, 0.0006), c + V3(0, -h * 0.2, 0.0003), "plastic.matte:B9BDB8", name: name) }
    }
    /// Fingerprint smudges on glass facing +Z.
    public func prints(_ c: V3, w: Float, h: Float, n: Int = 6, name: String? = nil) {
        for i in 0..<n {
            let fx = Float((i * 37) % 11) / 10 - 0.5, fy = Float((i * 53) % 9) / 8 - 0.5
            put(Prim.extrude(Shape2D.roundedRect(0.018, 0.026, radius: 0.0085, segments: 2), depth: 0.0006, bevel: 0, bevelSegments: 1, material: "plastic.matte:B0B8BC"),
                Xform(translation: c + V3(fx * w, fy * h, 0.0004), rotation: simd_quatf(degrees: Float(i) * 23, axis: V3(0, 0, 1))), name)
        }
    }
    /// Bar handle on +Z face: two posts and a rail, worn at the grip.
    public func handle(_ c: V3, len: Float, vertical: Bool = true, name: String? = nil) {
        let a = vertical ? V3(0, len / 2 - 0.03, 0) : V3(len / 2 - 0.03, 0, 0)
        for q: Float in [-1, 1] { bb(V3(0.016, 0.016, 0.03), c + a * q + V3(0, 0, 0.015), "metal.stainless", r: 0.002, name: name) }
        bb(vertical ? V3(0.018, len, 0.018) : V3(len, 0.018, 0.018), c + V3(0, 0, 0.038), "metal.stainless", r: 0.004, name: name)
        scuffs(c + V3(0, 0, 0.048), w: vertical ? 0.0 : len * 0.5, h: vertical ? len * 0.4 : 0, n: 3, name: name)
    }
}
