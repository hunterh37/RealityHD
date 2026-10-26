import simd
import Foundation

/// Pressed tin cornice run, Victorian: three 1.0 m stamped sheets with a bed mould of pearls, a
/// rosette frieze, scrolled modillion brackets under a drip-edged corona and an ogee crown. Overlap
/// seams carry cover strips and nail heads; paint is crazed and rust blooms at the lower edge.
public struct PressedTinCorniceRun: RealAsset {
    public static let id = "pressed-tin-cornice-run"
    public static let summary = "Pressed tin cornice run, 3.0 m: stamped sheets, pearl bed mould, rosette frieze, modillions, ogee crown."
    public static let tags = ["prop", "architecture", "facade", "trim", "metal", "decor"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 14, distance: 3.6)

    /// Run length in meters.
    public var length: Float = 3.0
    /// Painted tin.
    public var paint: MaterialKey = "metal.painted:A69C80"
    /// Bare galvanized tin showing through chips.
    public var bare: MaterialKey = "metal.galvanized-aged"
    /// Rust bloom.
    public var rust: MaterialKey = "metal.rust"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let L = length
        var prof: [V2] = [V2(0, 0), V2(0.07, 0), V2(0.07, 0.012), V2(0.085, 0.02), V2(0.085, 0.035), V2(0.07, 0.04),
                          V2(0.05, 0.045), V2(0.05, 0.20), V2(0.20, 0.20), V2(0.20, 0.215), V2(0.235, 0.225), V2(0.25, 0.235), V2(0.25, 0.27)]
        prof += FL.ogee(from: V2(0.25, 0.27), to: V2(0.16, 0.36), steps: 8)
        prof += [V2(0.10, 0.375), V2(0.10, 0.40), V2(0, 0.40)]
        let sheets = 3, gap: Float = 0.002
        let sl = (L - Float(sheets - 1) * gap) / Float(sheets)
        for s in 0..<sheets {
            let cx = -L / 2 + sl / 2 + Float(s) * (sl + gap)
            FA.run(&m, prof, length: sl, at: V3(cx, 0, 0), paint, bevel: 0.0012)
        }
        // Modillion brackets (scrolled) every 0.2 m with a rosette on the frieze between them.
        let bracket: [V2] = [V2(0.05, 0.20), V2(0.20, 0.20), V2(0.20, 0.186), V2(0.19, 0.166), V2(0.165, 0.146), V2(0.125, 0.136),
                             V2(0.095, 0.122), V2(0.075, 0.104), V2(0.05, 0.098)]
        let n = Int(L / 0.2)
        for i in 0..<n {
            let x = -L / 2 + (Float(i) + 0.5) * (L / Float(n))
            FA.side(&m, bracket, thick: 0.045, at: V3(x, 0, 0), paint, bevel: 0.0012)
            let rx = x + L / Float(n) / 2
            if i < n - 1 {
                FA.cylZ(&m, r: 0.03, h: 0.007, at: V3(rx, 0.115, 0.05), paint, bevel: 0.0012, segments: 16)
                for p in 0..<4 {
                    let a = Float(p) / 4 * 2 * .pi
                    m.add(Prim.superellipsoid(V3(0.016, 0.009, 0.008), exponent: 2, subdivisions: 2, material: paint),
                          Xform(translation: V3(rx + cos(a) * 0.018, 0.115 + sin(a) * 0.018, 0.0575), rotation: FA.q(a * 180 / .pi, FA.Z)))
                }
                FC.bead(&m, r: 0.006, at: V3(rx, 0.115, 0.064), paint, sub: 2)
            }
        }
        // Pearl row on the bed mould.
        let pn = Int(L / 0.09)
        for i in 0..<pn {
            let x = -L / 2 + (Float(i) + 0.5) * (L / Float(pn))
            FC.bead(&m, r: 0.0085, at: V3(x, 0.028, 0.087), paint, sub: 2)
        }
        // Egg-and-dart band along the lower frieze.
        let en = Int(L / 0.1)
        for i in 0..<en {
            let x = -L / 2 + (Float(i) + 0.5) * (L / Float(en))
            let egg = Prim.superellipsoid(V3(0.02, 0.026, 0.007), exponent: 2, subdivisions: 2, material: paint)
            m.add(egg, Xform(translation: V3(x, 0.07, 0.052)))
            FJ.slab(&m, V3(0.004, 0.02, 0.004), V3(x + 0.025, 0.072, 0.052), paint)
        }
        // Lap seam cover strips and nail heads.
        for s in 1..<sheets {
            let x = -L / 2 + Float(s) * (sl + gap) - gap / 2
            FJ.slab(&m, V3(0.02, 0.155, 0.003), V3(x, 0.122, 0.0515), paint)
            FJ.slab(&m, V3(0.02, 0.025, 0.07), V3(x, 0.385, 0.14), paint)
        }
        var x = -L / 2 + 0.08
        while x < L / 2 {
            FA.cylZ(&m, r: 0.003, h: 0.002, at: V3(x, 0.052, 0.05), bare, bevel: 0.0005, segments: 6)
            FA.cylZ(&m, r: 0.003, h: 0.002, at: V3(x + 0.03, 0.19, 0.05), bare, bevel: 0.0005, segments: 6)
            x += 0.1
        }
        // Wear: paint chips to bare tin on the high points, rust blooms at the lower edge and under the drip.
        for _ in 0..<14 {
            let cx = rng.float(-L / 2 + 0.05...L / 2 - 0.05)
            FJ.slab(&m, V3(rng.float(0.01...0.04), rng.float(0.004...0.012), 0.0008), V3(cx, 0.03, 0.0875), bare, rot: FA.q(rng.float(-20...20), FA.Z))
        }
        for _ in 0..<6 {
            let cx = rng.float(-L / 2 + 0.1...L / 2 - 0.1)
            FJ.slab(&m, V3(rng.float(0.03...0.07), rng.float(0.01...0.03), 0.001), V3(cx, 0.055, 0.0506), rust)
            FJ.slab(&m, V3(rng.float(0.02...0.05), rng.float(0.006...0.012), 0.001), V3(cx + 0.1, 0.21, 0.0506), rust)
        }
        groundAO(&m, height: 0.12, floor: 0.8)
        return LODModel(FC.place(m))
    }
}
