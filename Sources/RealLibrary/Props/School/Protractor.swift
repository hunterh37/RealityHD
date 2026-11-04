import simd
import Foundation

/// Protractor: everyday school, plastic. Parts: clear semicircle plate, degree ticks 0-180, numerals every 10 degrees, center crosshair, base line.
public struct Protractor: RealAsset {
    public static let id = "protractor"
    public static let summary = "Clear 180 degree protractor with one-degree ticks, numerals and a base line."
    public static let tags = ["prop", "interior", "school", "plastic"]
    public static let budget = 8000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.12, 0.002, 0.063)
    public init() {}

        public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        let R: Float = 0.06, margin: Float = 0.0035, T: Float = 0.002, dz: Float = -0.0285
        var pts: [V2] = []
        for k in 0...60 { let a = Float.pi * Float(k) / 60; pts.append(V2(R * cos(a), R * sin(a))) }
        pts.append(V2(-R, -margin)); pts.append(V2(R, -margin))
        m.add(Prim.extrude(pts, depth: T, bevel: 0.0004, bevelSegments: 1, material: "plastic.gloss:DDE8F0"),
              Xform(translation: V3(0, T / 2, dz), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        // Printed ink: flat quads (both windings so either side renders).
        let y = T + 0.00003
        var ink = Surface(material: "plastic.matte:1B1B1B")
        func quad(_ a: V2, _ b: V2, _ c: V2, _ d: V2) {
            let n = V3(0, 1, 0)
            for order in 0..<2 {
                let p = order == 0 ? [a, b, c, d] : [d, c, b, a]
                let i = p.map { ink.add(V3($0.x, y, $0.y + dz), n, V2($0.x, $0.y)) }
                ink.quad(i[0], i[3], i[2], i[1])
            }
        }
        func mark(_ x0: Float, _ z0: Float, _ w: Float, _ d: Float) { quad(V2(x0, z0), V2(x0 + w, z0), V2(x0 + w, z0 + d), V2(x0, z0 + d)) }
        func ray(_ deg: Float, _ r1: Float, _ r2: Float, _ w: Float) {
            let a = deg * .pi / 180, d = V2(cos(a), sin(a)), n = V2(-sin(a), cos(a)) * (w / 2)
            quad(d * r1 - n, d * r2 - n, d * r2 + n, d * r1 + n)
        }
        for t in 0...180 {
            let len: Float = t % 10 == 0 ? 0.0055 : (t % 5 == 0 ? 0.004 : 0.0025)
            ray(Float(t), R - 0.0015 - len, R - 0.0015, 0.00016)
            // Inner scale (right-to-left) ticks.
            if t % 5 == 0 { ray(Float(t), R - 0.0185, R - 0.0185 + (t % 10 == 0 ? 0.003 : 0.002), 0.00014) }
        }
        let masks = ["abcdef", "bc", "abged", "abgcd", "fgbc", "afgcd", "afgedc", "abc", "abcdefg", "abcdfg"]
        func digit(_ x0: Float, _ z0: Float, _ n: Int, _ H: Float, _ Wd: Float) {
            let t: Float = 0.00035
            for ch in masks[n] {
                switch ch {
                case "a": mark(x0, z0 + H - t, Wd, t)
                case "d": mark(x0, z0, Wd, t)
                case "g": mark(x0, z0 + H / 2 - t / 2, Wd, t)
                case "b": mark(x0 + Wd - t, z0 + H / 2, t, H / 2)
                case "c": mark(x0 + Wd - t, z0, t, H / 2)
                case "f": mark(x0, z0 + H / 2, t, H / 2)
                default: mark(x0, z0, t, H / 2)
                }
            }
        }
        for t in stride(from: 10, through: 170, by: 10) {
            let a = Float(t) * .pi / 180, r = R - 0.0115
            let s = String(t), Wd: Float = 0.0018, gap: Float = 0.0007, H: Float = 0.0030
            let total = Float(s.count) * Wd + Float(s.count - 1) * gap
            for (k, ch) in s.enumerated() {
                digit(r * cos(a) - total / 2 + Float(k) * (Wd + gap), r * sin(a) - H / 2, Int(String(ch))!, H, Wd)
            }
        }
        // Base line, center crosshair and a small center ring.
        mark(-R + 0.0015, -0.00008, 2 * R - 0.003, 0.00016)
        mark(-0.0035, -0.00008, 0.007, 0.00016)
        mark(-0.00008, -0.0035, 0.00016, 0.007)
        ink.computeTangents()
        m.add(ink, Xform())
        groundAO(&m)
        return LODModel(m)
    }
}
