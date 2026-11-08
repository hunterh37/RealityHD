import RealCore
import RealMaterials
import simd

/// Smooth wordmarks: the 5x7 glyph grid drawn as round dots joined by capsule strokes (orthogonal and
/// diagonal neighbours), so letters read as bold rounded type instead of square pixels.
extension GroceryKit {
    /// `weight` is stroke width in grid cells (0.9 regular, 1.2 bold). Same layout as `text`.
    static func smoothText(_ s: String, height h: Float, material: MaterialKey, weight: Float = 1.1) -> Surface {
        var out = Surface(material: material)
        let px = h / 7, adv = 6 * px, rad = px * weight / 2
        let chars = Array(s.uppercased())
        var gx = -(Float(chars.count) * adv - px) / 2
        let n = V3(0, 0, 1)
        func v(_ p: V2) -> UInt32 { out.add(V3(p.x, p.y, 0), n, p) }
        func dot(_ c: V2) {
            let k = 10
            let ci = v(c)
            var prev = v(c + V2(rad, 0))
            for i in 1...k {
                let a = Float(i) / Float(k) * 2 * .pi
                let cur = v(c + V2(cos(a), sin(a)) * rad)
                out.tri(ci, prev, cur); prev = cur
            }
        }
        func stroke(_ a: V2, _ b: V2) {
            let d = simd_normalize(b - a), p = V2(-d.y, d.x) * rad
            out.quad(v(a - p), v(b - p), v(b + p), v(a + p))
        }
        for ch in chars {
            if let g = glyphs[ch] {
                let bits = Array(g)
                func on(_ r: Int, _ c: Int) -> Bool { r >= 0 && r < 7 && c >= 0 && c < 5 && bits[r * 5 + c] == "1" }
                func ctr(_ r: Int, _ c: Int) -> V2 { V2(gx + (Float(c) + 0.5) * px, (Float(6 - r) + 0.5) * px) }
                for r in 0..<7 { for c in 0..<5 where on(r, c) {
                    dot(ctr(r, c))
                    if on(r, c + 1) { stroke(ctr(r, c), ctr(r, c + 1)) }
                    if on(r + 1, c) { stroke(ctr(r, c), ctr(r + 1, c)) }
                    if on(r + 1, c + 1) && !on(r, c + 1) && !on(r + 1, c) { stroke(ctr(r, c), ctr(r + 1, c + 1)) }
                    if on(r + 1, c - 1) && !on(r, c - 1) && !on(r + 1, c) { stroke(ctr(r, c), ctr(r + 1, c - 1)) }
                } }
            }
            gx += adv
        }
        out.computeTangents()
        return out
    }

    /// `print` with smooth glyphs.
    static func printSmooth(_ m: inout Model, _ s: String, height: Float, at: V3, _ key: MaterialKey, rot: simd_quatf = .identity,
                            maxWidth: Float? = nil, weight: Float = 1.1) {
        var h = height
        if let w = maxWidth { let full = Float(s.count) * 6 * h / 7; if full > w { h *= w / full } }
        m.add(smoothText(s, height: h, material: key, weight: weight), Xform(translation: at, rotation: rot))
    }

    /// `wrapPrint` with smooth glyphs.
    static func wrapPrintSmooth(_ m: inout Model, _ s: String, height: Float, radius r: Float, y: Float, _ key: MaterialKey,
                                maxWidth: Float? = nil, weight: Float = 1.1) {
        var h = height
        if let w = maxWidth { let full = Float(s.count) * 6 * h / 7; if full > w { h *= w / full } }
        m.add(wrap(smoothText(s, height: h, material: key, weight: weight), radius: r + 0.0006), Xform(translation: V3(0, y, 0)))
    }
}
