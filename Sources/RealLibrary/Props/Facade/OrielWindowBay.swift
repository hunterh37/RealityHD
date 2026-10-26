import simd
import Foundation

/// Oriel window bay, Tudor Revival: a 1.6 m wide oak box window projecting 0.8 m from the wall on three
/// sandstone corbel tiers and a moulded oak bressummer with turned pendants. Each face has a linenfold
/// apron, leaded casements between oak mullions, a carved rosette frieze and a lead-rolled lean-to roof.
public struct OrielWindowBay: RealAsset {
    public static let id = "oriel-window-bay"
    public static let summary = "Oriel window bay, 1.6 m: sandstone corbels, oak bressummer, linenfold aprons, leaded casements, lead roof."
    public static let tags = ["prop", "architecture", "facade", "wood", "stone"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 38, elevation: 10, distance: 4.6)

    /// Oak frame.
    public var oak: MaterialKey = "wood.walnut"
    /// Weathered oak on the sill and roof edge.
    public var weathered: MaterialKey = "wood.weathered"
    /// Corbel stone.
    public var stone: MaterialKey = "stone.brownstone"
    /// Glazing.
    public var glass: MaterialKey = "glass.pane"
    /// Hinges, saddle bars and stays.
    public var iron: MaterialKey = "metal.wrought-iron"
    /// Lead roof sheet.
    public var lead: MaterialKey = "metal.galvanized-aged"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)

        // One glazed face in local space: back on z = 0, front at z = 0.07, y absolute 0.35...1.50.
        func diamonds(_ f: inout Model, cx: Float, cy: Float, w: Float, h: Float) {
            let dw: Float = 0.07, dh: Float = 0.1, a = dh / dw, hw = w / 2, hh = h / 2
            let steps = Int((hh + a * hw) / dh) + 1
            for k in -steps...steps {
                for sgn: Float in [1, -1] {
                    let kk = sgn * a, c = Float(k) * dh
                    let xa = (-hh - c) / kk, xb = (hh - c) / kk
                    let x0 = max(-hw, min(xa, xb)), x1 = min(hw, max(xa, xb))
                    if x1 - x0 < 0.02 { continue }
                    let p0 = V2(x0, kk * x0 + c), p1 = V2(x1, kk * x1 + c), mid = (p0 + p1) / 2
                    FJ.slab(&f, V3(simd_length(p1 - p0), 0.005, 0.004), V3(cx + mid.x, cy + mid.y, 0.0375), "metal.galvanized-aged",
                            rot: FA.q(atan2(p1.y - p0.y, p1.x - p0.x) * 180 / .pi, FA.Z))
                }
            }
        }
        func windowFace(_ W: Float, _ r: inout SeededRNG) -> Model {
            var f = Model(name: "face")
            let bevelled = W > 1.0
            let D: Float = 0.07
            if bevelled { FA.box(&f, V3(W, 0.27, D), V3(0, 0.485, D / 2), oak, r: 0.004) } else { FJ.slab(&f, V3(W, 0.27, D), V3(0, 0.485, D / 2), oak) }
            let np = max(1, Int(W / 0.38))
            let pw = W / Float(np)
            for i in 0..<np {
                FJ.raisedPanel(&f, cx: -W / 2 + pw * (Float(i) + 0.5), cy: 0.485, w: pw - 0.09, h: 0.18, z0: D, rise: 0.012, bevelRun: 0.03, oak)
            }
            if bevelled { FA.box(&f, V3(W, 0.16, D), V3(0, 1.42, D / 2), oak, r: 0.004) } else { FJ.slab(&f, V3(W, 0.16, D), V3(0, 1.42, D / 2), oak) }
            FJ.slab(&f, V3(W, 0.02, D + 0.012), V3(0, 1.335, (D + 0.012) / 2), oak)
            FJ.slab(&f, V3(W, 0.025, D + 0.016), V3(0, 0.625, (D + 0.016) / 2), weathered)
            let n = max(2, Int(W / 0.4))
            let post: Float = 0.06
            let lw = (W - post * Float(n + 1)) / Float(n)
            for k in 0...n {
                let x = -W / 2 + post / 2 + Float(k) * (lw + post)
                if bevelled { FA.box(&f, V3(post, 0.72, D), V3(x, 0.98, D / 2), oak, r: 0.004) } else { FJ.slab(&f, V3(post, 0.72, D), V3(x, 0.98, D / 2), oak) }
            }
            for k in 0..<n {
                let cx = -W / 2 + post + lw / 2 + Float(k) * (lw + post)
                FJ.sash(&f, cx: cx, cy: 0.98, w: lw + 0.012, h: 0.72, z0: 0.016, thick: 0.036, stile: 0.028, cols: 1, rows: 1, bar: 0.009, oak, glass: glass)
                diamonds(&f, cx: cx, cy: 0.98, w: lw - 0.04, h: 0.64)
                FJ.slab(&f, V3(lw, 0.007, 0.004), V3(cx, 0.98, 0.012), iron)
                FA.cylZ(&f, r: 0.004, h: 0.004, at: V3(cx - lw / 2 + 0.03, 0.98, 0.0525), iron, bevel: 0.0008, segments: 8)
            }
            for k in 0..<max(1, n - 1) {
                let x = -W / 2 + post + Float(k + 1) * (lw + post) - post / 2
                FP.rosette(&f, at: V3(x, 1.42, D), r: 0.045, petals: 5, oak, boss: weathered)
            }
            // Silvered grain on the sill face, rain streaks off the transom and a rust run under the saddle bar.
            for q in 0..<4 {
                FJ.slab(&f, V3(r.float(0.012...0.03), r.float(0.12...0.22), 0.002), V3(-W / 2 + W * (Float(q) + r.float(0.2...0.8)) / 4, 1.22, D + 0.0005), weathered)
            }
            FJ.slab(&f, V3(W * 0.7, 0.03, 0.003), V3(0, 0.64, D + 0.0165), weathered)
            // Rain stain under the sill.
            FJ.slab(&f, V3(W * 0.5, 0.1, 0.002), V3(r.float(-0.1...0.1), 0.56, D + 0.0005), weathered)
            return f
        }
        let front = windowFace(1.42, &rng), side = windowFace(0.62, &rng)
        m.add(front, Xform(translation: V3(0, 0, 0.72)))
        m.add(side, Xform(translation: V3(0.72, 0, 0.4), rotation: FA.q(90, FA.Y)))
        m.add(side, Xform(translation: V3(-0.72, 0, 0.4), rotation: FA.q(-90, FA.Y)))

        // Back board closing the box against the wall.
        FJ.slab(&m, V3(1.6, 1.15, 0.03), V3(0, 0.925, 0.015), weathered)
        FJ.slab(&m, V3(1.5, 0.03, 0.8), V3(0, 0.365, 0.4), weathered)
        // Corner posts.
        for sx: Float in [-1, 1] {
            FA.box(&m, V3(0.1, 1.15, 0.1), V3(sx * 0.75, 0.925, 0.75), oak, r: 0.004)
            FA.box(&m, V3(0.1, 1.15, 0.1), V3(sx * 0.75, 0.925, 0.05), oak, r: 0.004)
            FA.cylX(&m, r: 0.006, h: 0.006, at: V3(sx * 0.75 - 0.003, 1.0, 0.8), weathered, bevel: 0.001, segments: 8)
            FA.cylX(&m, r: 0.006, h: 0.006, at: V3(sx * 0.75 - 0.003, 0.75, 0.8), weathered, bevel: 0.001, segments: 8)
        }
        // Stone corbel tiers (narrow at the bottom, stepping out), each with a rain drip stain.
        let tiers: [(Float, Float, Float)] = [(0.5, 0.3, 0), (1.0, 0.54, 0.07), (1.5, 0.76, 0.14)]
        for (w, d, y) in tiers {
            FA.box(&m, V3(w, 0.07, d), V3(0, y + 0.035, d / 2), stone, r: 0.005)
            FA.box(&m, V3(w * 0.4, 0.05, 0.002), V3(rng.float(-0.1...0.1), y + 0.035, d + 0.0008), "stone.limestone-sooted", r: 0.0005)
        }
        // Moulded oak bressummer with a bead along its lower edge and turned pendants at the front corners.
        FA.box(&m, V3(1.6, 0.14, 0.8), V3(0, 0.28, 0.4), oak, r: 0.006)
        FA.rod(&m, V3(-0.8, 0.225, 0.8), V3(0.8, 0.225, 0.8), r: 0.009, weathered, sides: 8)
        FA.rod(&m, V3(0.8, 0.225, 0.8), V3(0.8, 0.225, 0.0), r: 0.009, weathered, sides: 8)
        FA.rod(&m, V3(-0.8, 0.225, 0.8), V3(-0.8, 0.225, 0.0), r: 0.009, weathered, sides: 8)
        for sx: Float in [-1, 1] {
            m.add(Prim.lathe([V2(0, 0), V2(0.012, 0), V2(0.018, 0.02), V2(0.026, 0.05), V2(0.02, 0.075), V2(0.032, 0.1), V2(0.046, 0.14), V2(0.046, 0.185), V2(0.042, 0.215), V2(0, 0.215)], segments: 14, material: oak),
                  Xform(translation: V3(sx * 0.75, 0, 0.75)))
        }
        // Silvered, rain-washed lower face of the bressummer and rust-brown run-off from the bolts.
        FJ.slab(&m, V3(1.58, 0.06, 0.003), V3(0, 0.235, 0.8015), weathered)
        FJ.slab(&m, V3(0.003, 0.06, 0.78), V3(0.8015, 0.235, 0.4), weathered)
        FJ.slab(&m, V3(0.003, 0.06, 0.78), V3(-0.8015, 0.235, 0.4), weathered)
        // Lean-to roof: sloped lead sheet over oak boards, wood rolls, fascia and gable cheeks.
        let slope: [V2] = [V2(0, 1.70), V2(0.8, 1.50), V2(0.8, 1.54), V2(0, 1.76)]
        FA.run(&m, slope, length: 1.6, at: V3(0, 0, 0), lead, bevel: 0.002)
        for k in -3...3 {
            let x = Float(k) * 0.25
            FA.rod(&m, V3(x, 1.77, 0.0), V3(x, 1.555, 0.8), r: 0.012, weathered, sides: 8)
        }
        for k in -3...3 {
            FJ.slab(&m, V3(0.05, 0.001, rng.float(0.3...0.7)), V3(Float(k) * 0.25 + 0.06, 1.7 - 0.2 * 0.5 + 0.045, 0.45), "metal.verdigris-roof", rot: FA.q(-14, FA.X))
        }
        FA.box(&m, V3(1.6, 0.06, 0.04), V3(0, 1.49, 0.78), oak, r: 0.004)
        for sx: Float in [-1, 1] {
            FA.side(&m, [V2(0, 1.48), V2(0.8, 1.48), V2(0.8, 1.52), V2(0, 1.72)], thick: 0.04, at: V3(sx * 0.78, 0, 0), oak, bevel: 0.002)
        }
        FA.box(&m, V3(1.6, 0.04, 0.05), V3(0, 1.76, 0.02), weathered, r: 0.004)
        groundAO(&m, height: 0.35, floor: 0.6)
        return LODModel(FC.place(m))
    }
}
