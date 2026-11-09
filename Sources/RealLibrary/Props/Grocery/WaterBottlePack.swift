import simd
import Foundation

/// Twelve-pack of 500 ml water bottles (4 x 3) in clear shrink film, 27 x 21 x 20 cm: PET bottles with a
/// petaloid foot, grip ribs, water fill, neck support ring and knurled caps, printed wrap labels, and a
/// shrink film sleeve with gathered bullseye openings at both ends. Invented brand VALE.
public struct WaterBottlePack: RealAsset {
    public static let id = "water-bottle-pack"
    public static let summary = "Twelve-pack of 500 ml water bottles in shrink film, 27 cm: ribbed PET bottles, caps, labels, bullseye ends."
    public static let tags = ["prop", "grocery", "food", "plastic", "container", "handheld"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 22, distance: 1.3, studio: true)

    public var columns = 4
    public var rows = 3
    public var capColor: MaterialKey = "plastic.gloss:2E73C8"
    /// Label brand field color.
    public var label: UInt32 = 0x1D6FD0
    public var brand = "VALE"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(hi: true), level(hi: false)], switchDistances: [3])
    }

    func level(hi: Bool) -> Model {
        var m = Model(name: Self.id)
        let r: Float = 0.0325, pitch: Float = 0.0655, seg = hi ? 12 : 8
        var prof: [V2] = [V2(0.0001, 0.004), V2(0.012, 0.0045), V2(0.019, 0.0005), V2(0.024, 0), V2(0.029, 0.002), V2(0.0318, 0.007), V2(r, 0.014)]
        for (y, rr) in [(0.12, r), (0.124, 0.0302), (0.128, r), (0.132, 0.0302), (0.136, r), (0.14, 0.0302), (0.144, r)] as [(Float, Float)] {
            prof.append(V2(rr, y))
        }
        prof += [V2(0.0318, 0.156), V2(0.0285, 0.167), V2(0.022, 0.177), V2(0.0165, 0.184), V2(0.0138, 0.188), V2(0.0138, 0.1905),
                 V2(0.0168, 0.191), V2(0.0168, 0.1925), V2(0.0138, 0.193)]
        let bottle = Prim.lathe(prof, segments: seg, seamTile: 0.05, material: "pkg.pet-clear")
        let water = Prim.lathe([V2(0.0001, 0.006), V2(0.026, 0.004), V2(0.0308, 0.014), V2(0.0308, 0.15), V2(0.0285, 0.16), V2(0.0001, 0.16)],
                               segments: seg, seamTile: 0.05, material: "food.water")
        let cap = GroceryKit.knurledCap(r: 0.0152, h: 0.016, seg: hi ? 16 : 10, rib: 0.0005, capColor)
        let ring = Prim.lathe([V2(0.0146, 0.1905), V2(0.0155, 0.1905), V2(0.0155, 0.193)], segments: hi ? 14 : 8, seamTile: 0.05, material: capColor)
        let key = GroceryKit.tint("pkg.paper-label", label)
        let lab = GroceryKit.printLathe([V2(r + 0.0004, 0.05), V2(r + 0.0004, 0.115)], seg: seg, key, y0: 0.05, y1: 0.115)
        let x0 = -Float(columns - 1) * pitch / 2, z0 = -Float(rows - 1) * pitch / 2
        var rng = SeededRNG(seed: 5150)
        for i in 0..<columns { for j in 0..<rows {
            let c = V3(x0 + Float(i) * pitch, 0, z0 + Float(j) * pitch)
            let spin = simd_quatf(angle: (j == rows - 1 ? 0 : rng.float(0...6.28)) + rng.float(-0.12...0.12), axis: .up)
            let inner = j > 0 && j < rows - 1 && i > 0 && i < columns - 1
            m.add(bottle, Xform(translation: c, rotation: spin))
            m.add(cap, Xform(translation: c + V3(0, 0.193, 0), rotation: spin))
            m.add(ring, Xform(translation: c, rotation: spin))
            if !inner { m.add(water, Xform(translation: c)); m.add(lab, Xform(translation: c, rotation: spin)) }
            if j == rows - 1 && hi && (i == 1 || i == 2) {
                var w = Model(name: "w")
                GroceryKit.wrapPrintSmooth(&w, brand, height: 0.0085, radius: r + 0.0006, y: 0.05 + 0.065 * 0.15 + 0.004, "plastic.gloss:FFFFFF",
                                           maxWidth: 0.04, weight: 1.2)
                m.add(w, Xform(translation: c, rotation: spin))
            }
        } }
        // Shrink sleeve: loft along x, rounded sections, gathered bullseye lips at both ends.
        let hw = Float(columns) * pitch / 2 + 0.002, hz = Float(rows) * pitch / 2 + 0.0015, hy: Float = 0.1035, cy: Float = 0.1035
        let n = hi ? 36 : 20
        func section(_ x: Float, _ k: Float, _ wob: Float) -> [V3] {
            (0..<n).map { q in
                let a = Float(q) / Float(n) * 2 * .pi
                func f(_ v: Float) -> Float { (v < 0 ? -1 : 1) * pow(abs(v), 2 / 7) }
                let wr = 1 + wob * sin(a * 7 + x * 40)
                return V3(x, cy + f(sin(a)) * hy * k * wr, f(cos(a)) * hz * k * wr)
            }
        }
        var rings: [[V3]] = []
        let xs: [(Float, Float, Float)] = [(-hw - 0.004, 0.62, 0.02), (-hw - 0.001, 0.86, 0.012), (-hw + 0.012, 1.0, 0.003),
                                           (-hw * 0.5, 1.0, 0.002), (0, 1.0, 0.002), (hw * 0.5, 1.0, 0.002), (hw - 0.012, 1.0, 0.003),
                                           (hw + 0.001, 0.86, 0.012), (hw + 0.004, 0.62, 0.02)]
        for (x, k, w) in xs { rings.append(section(x, k, w)) }
        m.add(Prim.loft(rings, material: "pkg.shrink-film"))
        // Gathered film rims at the openings.
        for s: Float in [1, -1] {
            var rim = section(s * (hw + 0.004), 0.62, 0.02)
            rim.append(rim[0])
            m.add(Prim.tube(rim, radii: rim.map { _ in 0.0016 }, sides: 5, seamTile: 0.05, material: "plastic.translucent:EEF2F4"))
        }
        // Printed film panel on the front: brand strip.
        let fz = hz + 0.0008
        GroceryKit.panel(&m, 0.15, 0.034, V3(0, 0.17, fz), GroceryKit.tint("pkg.carton-gloss", label), crop: (0.45, 0.98, 0.78, 0.92))
        GroceryKit.printSmooth(&m, brand, height: 0.018, at: V3(-0.03, 0.161, fz + 0.0006), "plastic.gloss:FFFFFF", maxWidth: 0.07, weight: 1.3)
        GroceryKit.printSmooth(&m, "12 PACK", height: 0.008, at: V3(0.042, 0.165, fz + 0.0006), "plastic.gloss:FFFFFF", maxWidth: 0.05, weight: 0.9)
        return m
    }
}
