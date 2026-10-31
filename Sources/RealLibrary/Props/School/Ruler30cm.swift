import simd
import Foundation

/// Ruler 30cm: everyday school, plastic. Parts: clear acrylic bar, beveled edge, graduation marks cm and mm, numerals, hang hole.
public struct Ruler30cm: RealAsset {
    public static let id = "ruler-30cm"
    public static let summary = "30 cm clear plastic ruler with printed graduations and a hang hole."
    public static let tags = ["prop", "interior", "school", "plastic"]
    public static let budget = 6000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.03, 0.003, 0.3)
    public init() {}

        public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = size.x, T = size.y, L = size.z
        // Clear acrylic bar, 3 mm thick, with 45 degree bevel on the measuring edge.
        m.add(Prim.roundedBox(V3(W, T, L), radius: 0.0006, bevelSegments: 2, material: "plastic.gloss:E6EEF2"),
              Xform(translation: V3(0, T / 2, 0)))
        // Graduation marks and numerals along the +X edge as one flat printed surface on the top face.
        let top = T + 0.00003
        var ink = Surface(material: "plastic.matte")
        func mark(_ x0: Float, _ z0: Float, _ w: Float, _ d: Float) {
            let n = V3(0, 1, 0)
            let i0 = ink.add(V3(x0, top, z0), n, V2(0, 0)), i1 = ink.add(V3(x0 + w, top, z0), n, V2(w, 0))
            let i2 = ink.add(V3(x0 + w, top, z0 + d), n, V2(w, d)), i3 = ink.add(V3(x0, top, z0 + d), n, V2(0, d))
            ink.quad(i0, i3, i2, i1)
        }
        for i in 0...299 {
            let z = -L / 2 + 0.0015 + Float(i) * 0.001
            let len: Float = i % 10 == 0 ? 0.011 : (i % 5 == 0 ? 0.008 : 0.005)
            mark(W / 2 - 0.0015 - len, z, len, 0.00018)
        }
        // Seven-segment numerals: height along X, advance along Z.
        let masks: [String] = ["abcdef", "bc", "abged", "abgcd", "fgbc", "afgcd", "afgedc", "abc", "abcdefg", "abcdfg"]
        func digit(_ x0: Float, _ z0: Float, _ n: Int, _ H: Float, _ Wd: Float) {
            let t: Float = 0.00035
            for ch in masks[n] {
                switch ch {
                case "a": mark(x0 + H - t, z0, t, Wd)
                case "d": mark(x0, z0, t, Wd)
                case "g": mark(x0 + H / 2 - t / 2, z0, t, Wd)
                case "b": mark(x0 + H / 2, z0 + Wd - t, H / 2, t)
                case "c": mark(x0, z0 + Wd - t, H / 2, t)
                case "f": mark(x0 + H / 2, z0, H / 2, t)
                default: mark(x0, z0, H / 2, t)
                }
            }
        }
        func number(_ x0: Float, _ z0: Float, _ n: Int, _ H: Float, _ Wd: Float) {
            let s = String(n)
            for (k, ch) in s.enumerated() { digit(x0, z0 + Float(k) * (Wd + 0.0008), Int(String(ch))!, H, Wd) }
        }
        for c in 1...29 { number(W / 2 - 0.0185, -L / 2 + 0.0015 + Float(c) * 0.01 + 0.0008, c, 0.0035, 0.0021) }
        // Inch scale on the -X edge: 1/16 in ticks, longer at 1/2 and 1 in.
        for i in 0...187 {
            let z = -L / 2 + 0.0015 + Float(i) * 0.0254 / 16
            let len: Float = i % 16 == 0 ? 0.010 : (i % 8 == 0 ? 0.008 : (i % 4 == 0 ? 0.006 : (i % 2 == 0 ? 0.0045 : 0.003)))
            mark(-W / 2 + 0.0015, z, len, 0.00016)
        }
        for c in 1...11 { number(-W / 2 + 0.0125, -L / 2 + 0.0015 + Float(c) * 0.0254 + 0.0008, c, 0.0035, 0.0021) }
        // Units label near the hang end.
        number(-0.0015, L / 2 - 0.027, 30, 0.0035, 0.0021)
        ink.computeTangents()
        m.add(ink, Xform())
        // Hang hole: dark disc through the far end.
        m.add(Prim.cylinder(radius: 0.0033, height: 0.00008, bevel: 0, segments: 16, material: "plastic.matte"),
              Xform(translation: V3(0, T, -L / 2 + 0.008)))
        groundAO(&m)
        return LODModel(m)
    }
}
