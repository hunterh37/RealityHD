import simd
import Foundation

/// English shopfront fascia sign, 3.0 x 0.5 x 0.12 m: a painted pine board with a moulded skirt, a projecting
/// cornice with a cyma bed mould and drip, a raised-and-fielded panel moulding around gilt stroke lettering,
/// scrolled end consoles with rosette bosses and brass-slotted screw heads. Green paint is chalked and flaked on
/// the cornice top and board foot, with a rust streak under each iron eye plate and one gilt stroke lost.
public struct PaintedWoodShopFasciaSign: RealAsset {
    public static let id = "painted-wood-shop-fascia-sign"
    public static let summary = "English shopfront fascia sign, 3.0 x 0.5 m: painted pine board, moulded cornice, panel border, gilt lettering, scrolled end consoles and brass screws."
    public static let tags = ["prop", "architecture", "facade", "trim", "wood"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 10, distance: 1.0)

    /// Sign text in capitals.
    public var text = "BAKER AND SON"
    /// Painted fascia board.
    public var board: MaterialKey = "wood.painted-exterior:1F3D2E"
    /// Slightly sun-faded paint on the cornice.
    public var faded: MaterialKey = "wood.painted-exterior:2A4D3A"
    /// Bare weathered timber showing through flaked paint.
    public var bare: MaterialKey = "wood.trim-weathered"
    /// Gilt lettering and bosses.
    public var gilt: MaterialKey = "metal.gold-leaf"
    /// Screw heads.
    public var brass: MaterialKey = "metal.brass"
    /// Iron eye plates.
    public var iron: MaterialKey = "metal.wrought-iron"
    /// Rust streaks.
    public var rust: MaterialKey = "metal.rust"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [make(seed: seed, lite: false), make(seed: seed, lite: true)], switchDistances: [6])
    }

    func make(seed: UInt64, lite: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W: Float = 3.0, bz: Float = 0.036
        // Skirt moulding along the foot.
        FA.run(&m, [V2(0, 0), V2(0.046, 0), V2(0.05, 0.007), V2(0.05, 0.026), V2(0.041, 0.034), V2(0.03, 0.04), V2(0.026, 0.05), V2(0, 0.05)], length: 2.86, at: .zero, faded, bevel: 0.0015)
        // Board: flat front, 2.86 wide from y 0.05 to 0.40.
        FA.box(&m, V3(2.86, 0.352, bz), V3(0, 0.226, bz / 2 - 0.001), board, r: 0.002)
        // Cornice: cyma bed mould, corona and drip, full 3.0 m.
        FA.run(&m, [V2(0, 0.398), V2(0.05, 0.398), V2(0.052, 0.408), V2(0.066, 0.42), V2(0.092, 0.432), V2(0.118, 0.436), V2(0.12, 0.442),
                    V2(0.12, 0.468), V2(0.114, 0.474), V2(0.098, 0.478), V2(0.1, 0.486), V2(0.088, 0.5), V2(0, 0.5)], length: W, at: .zero, faded, bevel: 0.002)
        // Bead under the corona (separate round member).
        FA.rod(&m, V3(-W / 2 + 0.01, 0.4, 0.049), V3(W / 2 - 0.01, 0.4, 0.049), r: 0.005, faded, sides: lite ? 5 : 8)
        // Dentil course under the corona.
        var comb: [V2] = [V2(-W / 2 + 0.02, 0.4)]
        var dx: Float = -W / 2 + 0.03
        while dx < W / 2 - 0.05 {
            comb += [V2(dx, 0.396), V2(dx, 0.374), V2(dx + 0.018, 0.374), V2(dx + 0.018, 0.396)]
            dx += 0.034
        }
        comb.append(V2(dx - 0.034 + 0.03, 0.4))
        m.add(Prim.extrude(comb, depth: 0.022, bevel: 0.0008, bevelSegments: 1, material: faded), Xform(translation: V3(0, 0, 0.049)))
        // Raised panel moulding around the lettered field (stiles, rails, mitred corners as boxes).
        let px: Float = 1.3, py0: Float = 0.1, py1: Float = 0.355
        let fz: Float = bz + 0.011
        FA.box(&m, V3(2 * px + 0.04, 0.026, 0.022), V3(0, py0 - 0.007, bz + 0.002), faded, r: 0.004)
        FA.box(&m, V3(2 * px + 0.04, 0.026, 0.022), V3(0, py1 + 0.007, bz + 0.002), faded, r: 0.004)
        for s: Float in [-1, 1] { FA.box(&m, V3(0.026, py1 - py0 + 0.04, 0.022), V3(s * (px + 0.007), (py0 + py1) / 2, bz + 0.002), faded, r: 0.004) }
        // Gilt fillet inside the moulding.
        FA.box(&m, V3(2 * px - 0.02, 0.0035, 0.0016), V3(0, py0 + 0.022, bz + 0.0125), gilt, r: 0.0005)
        FA.box(&m, V3(2 * px - 0.02, 0.0035, 0.0016), V3(0, py1 - 0.022, bz + 0.0125), gilt, r: 0.0005)
        for s: Float in [-1, 1] { FA.box(&m, V3(0.0035, py1 - py0 - 0.044, 0.0016), V3(s * (px - 0.01), (py0 + py1) / 2, bz + 0.0125), gilt, r: 0.0005) }
        // Inner bead of the moulding.
        FA.box(&m, V3(2 * px - 0.01, 0.007, 0.006), V3(0, py0 + 0.012, bz + 0.011), faded, r: 0.002)
        FA.box(&m, V3(2 * px - 0.01, 0.007, 0.006), V3(0, py1 - 0.012, bz + 0.011), faded, r: 0.002)
        _ = fz
        // Lettering: centred gilt strokes on the board face, plus pointing stops.
        let h: Float = 0.15, w: Float = 0.1, gap: Float = 0.052, st: Float = 0.015
        let total = Float(text.count) * (w + gap) - gap - 0.05
        let x0 = -total / 2
        var rs = rng.fork(7)
        FO.letters(&m, text, x0: x0 + 0.005, y0: 0.5 * (py0 + py1) - h / 2 - 0.005, height: h, width: w, gap: gap, stroke: st, depth: 0.004, z: bz - 0.001, "wood.painted-exterior:0B1A12", rng: &rs, loss: 0, cheap: true)
        FO.letters(&m, text, x0: x0, y0: 0.5 * (py0 + py1) - h / 2, height: h, width: w, gap: gap, stroke: st, depth: 0.007, z: bz - 0.001, gilt, rng: &rng, loss: lite ? 0 : 0.03, cheap: true, bevel: 0.0007)
        // Gilt rosette bosses at each end of the field.
        for s: Float in [-1, 1] {
            let c = V3(s * (px - 0.07), 0.5 * (py0 + py1), bz)
            m.add(turned([(0, 0), (0.026, 0), (0.026, 0.004), (0.02, 0.007), (0.012, 0.011), (0.006, 0.016), (0, 0.018)], segments: lite ? 8 : 14, material: gilt, seamTile: 0.1),
                  Xform(translation: c, rotation: FA.q(90, FA.X)))
        }
        // End consoles: scrolled bracket profile (x out from the wall) carrying the cornice.
        for s: Float in [-1, 1] {
            let cx = s * (W / 2 - 0.058)
            var prof: [V2] = [V2(0, 0.05), V2(0.05, 0.05), V2(0.058, 0.07), V2(0.056, 0.15), V2(0.08, 0.2), V2(0.095, 0.26), V2(0.085, 0.31), V2(0.07, 0.34),
                              V2(0.052, 0.34), V2(0.05, 0.3), V2(0.04, 0.26), V2(0.02, 0.24), V2(0.0, 0.24)]
            // Volute scroll at the foot as a spiral tube in the console plane.
            FA.side(&m, prof, thick: 0.1, at: V3(cx, 0, 0), board, bevel: 0.003)
            prof.removeAll()
            var pts: [V3] = [], rad: [Float] = []
            for k in 0...(lite ? 10 : 20) {
                let t = Float(k) / Float(lite ? 10 : 20), a = t * 2.3 * .pi
                let r = 0.034 * (1 - 0.72 * t)
                pts.append(V3(cx + 0.052, 0.12 + sin(a + 2.8) * r + 0.0, 0.058 + cos(a + 2.8) * r)); rad.append(0.0055 * (1 - 0.4 * t))
            }
            // Spiral lies in the YZ plane at the console face (x = cx + 0.052).
            m.add(Prim.tube(pts, radii: rad, sides: lite ? 5 : 8, seamTile: 0.08, material: board, capEnd: true))
            FC.bead(&m, r: 0.009, at: pts.last!, gilt, sub: lite ? 1 : 2)
            // Acanthus drop on the console face.
            m.add(turned([(0, 0), (0.012, 0.01), (0.02, 0.05), (0.012, 0.1), (0, 0.13)], segments: lite ? 5 : 8, material: faded, seamTile: 0.1),
                  Xform(translation: V3(cx + 0.044, 0.27, 0.075), rotation: FA.q(180, FA.X), scale: V3(1, 1, 0.5)))
        }
        // Fixings: brass screw heads along the skirt and cornice bed, slotted.
        if !lite {
            for k in 0..<7 {
                let x = -1.2 + Float(k) * 0.4
                FO.head(&m, at: V3(x, 0.075, bz), r: 0.0065, h: 0.0035, brass)
                FA.box(&m, V3(0.009, 0.0016, 0.0012), V3(x, 0.075, bz + 0.0038), board, r: 0.0003, rot: FA.q(Float(rng.int(0...3)) * 40, FA.Z))
            }
            for k in 0..<5 {
                FO.head(&m, at: V3(-1.15 + Float(k) * 0.575, 0.385, bz), r: 0.0065, h: 0.0035, brass)
            }
        }
        // Iron eye plates on the skirt for hanging a flower basket, with ring.
        for s: Float in [-1, 1] {
            let c = V3(s * 0.9, 0.024, 0.0505)
            FA.box(&m, V3(0.05, 0.034, 0.004), V3(c.x, c.y, 0.049), iron, r: 0.0015)
            m.add(Prim.torus(major: 0.011, minor: 0.0028, segments: lite ? 8 : 14, sides: 5, material: iron), Xform(translation: V3(c.x, c.y, 0.0535), rotation: FA.q(90, FA.X)))
            FO.head(&m, at: V3(c.x - 0.017, c.y, 0.0505), r: 0.0042, h: 0.0024, iron)
            FO.head(&m, at: V3(c.x + 0.017, c.y, 0.0505), r: 0.0042, h: 0.0024, iron)
        }
        // Weathering.
        if !lite {
            // Flaked paint along the cornice top and the board foot, exposing bare timber.
            for _ in 0..<9 { FO.patchTop(&m, cx: rng.float(-1.4...1.4), cz: rng.float(0.01...0.045), rx: rng.float(0.02...0.09), rz: rng.float(0.006...0.014), y: 0.5001, bare, rng: &rng) }
            for _ in 0..<7 { FO.patchTop(&m, cx: rng.float(-1.4...1.4), cz: rng.float(0.01...0.03), rx: rng.float(0.02...0.08), rz: rng.float(0.006...0.012), y: 0.0001 + 0.05, bare, rng: &rng) }
            for _ in 0..<6 { FO.patch(&m, cx: rng.float(-1.38...1.38), cy: rng.float(0.052...0.075), rx: rng.float(0.01...0.04), ry: rng.float(0.003...0.008), z: bz + 0.0004, bare, rng: &rng) }
            // Rust streaks below the eye plate bolts.
            for s: Float in [-1, 1] { FA.box(&m, V3(0.005, 0.02, 0.0012), V3(s * 0.9 + s * 0.017, 0.006, 0.0512), rust, r: 0.0004) }
            // Dirt wash under the cornice and rain runs down the board from the screws.
            for _ in 0..<12 { FO.patch(&m, cx: rng.float(-1.4...1.4), cy: rng.float(0.34...0.385), rx: rng.float(0.05...0.2), ry: rng.float(0.006...0.02), z: bz + 0.0003, "wood.painted-exterior:10241A", rng: &rng, depth: 0.0004) }
            for k in 0..<5 { FO.patch(&m, cx: -1.15 + Float(k) * 0.575 + rng.float(-0.02...0.02), cy: 0.33, rx: 0.004, ry: rng.float(0.02...0.05), z: bz + 0.0003, "wood.painted-exterior:0E1D15", rng: &rng, depth: 0.0004, n: 6) }
            // Flaked paint on the panel moulding and console edges.
            for _ in 0..<10 { FO.patch(&m, cx: rng.float(-1.3...1.3), cy: rng.pick([0.087, 0.368]), rx: rng.float(0.01...0.04), ry: 0.004, z: bz + 0.0138, bare, rng: &rng, depth: 0.0004, n: 7) }
            // Lighter sun-faded wash patch on the board between letters and panel edge.
            FO.patch(&m, cx: -1.0, cy: 0.33, rx: 0.2, ry: 0.015, z: bz + 0.0003, faded, rng: &rng, depth: 0.0004)
        }
        groundAO(&m, height: 0.12, floor: 0.9)
        return FC.place(m)
    }
}
