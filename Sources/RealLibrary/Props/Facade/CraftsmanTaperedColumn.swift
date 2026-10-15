import simd
import Foundation

/// Craftsman tapered porch column, 0.45 x 2.7 m. A battered rubble-stone pier (seven courses of rounded
/// river and fieldstone laid dry over a mortar core, alternating through-corners) carries a cast-stone cap
/// slab, a painted wood plinth with an ovolo base moulding, and a tapered box shaft built of four
/// butt-jointed boards with a raised flat panel on each face. The top has a cove necking, a flared capital,
/// a bolted architrave seat block, and iron anchor straps at the plinth. Paint is chipped and splash-grimed
/// at the foot; the lowest stone courses are damp and mossy.
public struct CraftsmanTaperedColumn: RealAsset {
    public static let id = "craftsman-tapered-column"
    public static let summary = "Craftsman tapered porch column, 0.45 x 2.7 m: rubble stone pier, plinth, butt-jointed tapered wood shaft with panels, capital."
    public static let tags = ["prop", "architecture", "facade", "ornament", "wood", "stone"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 8, distance: 2.1)

    /// Pier height and base width (m).
    public var pierHeight: Float = 0.86
    public var pierWidth: Float = 0.45
    /// Shaft paint (Craftsman olive) and its splash-grimed foot.
    public var paint: MaterialKey = "wood.painted-shaker-worn:6B7355"
    public var foot: MaterialKey = "wood.painted-shaker-worn:8A8A74"
    /// Capital and plinth trim paint.
    public var trim: MaterialKey = "wood.painted-exterior:DAD3BE"
    public var iron: MaterialKey = "metal.wrought-iron"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let PH = pierHeight, PW = pierWidth
        /// Rotates a face-local transform about the column axis by `face` quarter turns.
        func around(_ face: Int, _ x: Xform) -> Xform {
            let q = FA.q(Float(face) * 90, FA.Y)
            return Xform(translation: q.act(x.translation), rotation: q * x.rotation)
        }
        let topHW: Float = 0.19, baseHW = PW / 2
        func pierHW(_ y: Float) -> Float { baseHW - (baseHW - topHW) * (y / PH) }

        // Mortar core: tapered square loft, recessed so joints read as shadow.
        let core = [Prim.ring(Shape2D.roundedRect(2 * (baseHW - 0.05), 2 * (baseHW - 0.05), radius: 0.01, segments: 1), y: 0),
                    Prim.ring(Shape2D.roundedRect(2 * (topHW - 0.05), 2 * (topHW - 0.05), radius: 0.01, segments: 1), y: PH)]
        m.add(Prim.loft(core, capStart: false, capEnd: true, material: "stone.cast-grey"))
        // Rubble courses: stones keyed through the corners, alternating which faces run through.
        let nCourse = 7
        let ch = PH / Float(nCourse)
        let stones: [MaterialKey] = ["stone.wall-block", "stone.sandstone", "stone.wall-block", "stone.granite-paver", "stone.sandstone"]
        for c in 0..<nCourse {
            let y0 = Float(c) * ch + 0.004, h0 = ch - 0.008
            let hw = pierHW(y0 + h0 / 2)
            for face in 0..<4 {
                let through = (face % 2 == c % 2)
                let span = through ? 2 * hw : 2 * hw - 0.19
                let n = (c + face) % 3 == 0 ? 3 : 2
                var cuts: [Float] = [0]
                for i in 1..<n { cuts.append((Float(i) + rng.float(-0.18...0.18)) / Float(n)) }
                cuts.append(1)
                for i in 0..<n {
                    let a = cuts[i], b = cuts[i + 1]
                    let w = (b - a) * span - 0.006
                    let hh = h0 + rng.float(-0.02...0.004)
                    let d: Float = 0.1
                    let u = -span / 2 + (a + b) / 2 * span
                    let out = hw - d / 2 + rng.float(-0.012...0.004)
                    let mat: MaterialKey = c < 3 && (face + i + c) % 3 != 0 ? "stone.granite-moss" : stones[(c * 3 + face * 2 + i) % stones.count]
                    let sub = Prim.roundedBox(V3(w, hh, d), radius: 0.02, bevelSegments: 1, material: mat)
                    m.add(sub, around(face, Xform(translation: V3(u, y0 + hh / 2, out))))
                }
            }
        }
        // Cast-stone cap slab with a drip chamfer.
        FA.box(&m, V3(0.43, 0.055, 0.43), V3(0, PH + 0.0275, 0), "stone.cast-stone", r: 0.01)
        FA.box(&m, V3(0.44, 0.012, 0.44), V3(0, PH + 0.006, 0), "stone.cast-grey", r: 0.003)

        // Wood plinth, base moulding.
        let yP = PH + 0.055
        FA.box(&m, V3(0.33, 0.1, 0.33), V3(0, yP + 0.05, 0), foot, r: 0.004)
        var sub = Model(name: "mould")
        FJ.mouldedFrame(&sub, cx: 0, cy: 0, w: 0.335, h: 0.335, z: 0, profile: FJ.ovoloProfile(width: 0.026, height: 0.026), trim, r: 0.006)
        m.add(sub, Xform(translation: V3(0, yP + 0.1, 0), rotation: FA.q(-90, FA.X)))
        FA.box(&m, V3(0.31, 0.016, 0.31), V3(0, yP + 0.108, 0), trim, r: 0.003)
        // Tapered box shaft: four butt-jointed boards (front and back overlap the sides), outer face tilted by the taper.
        let ys = yP + 0.116, ye: Float = 2.46, L = ye - ys
        let hw0: Float = 0.15, hw1: Float = 0.115, bt: Float = 0.03
        let k = (hw0 - hw1) / L
        let deg = atan(k) * 180 / .pi
        func hw(_ y: Float) -> Float { hw0 - k * (y - ys) }
        func boards(_ ya: Float, _ yb: Float, _ mat: MaterialKey) {
            for face in 0..<4 {
                let through = face % 2 == 0
                func w(_ y: Float) -> Float { through ? 2 * hw(y) : 2 * hw(y) - 2 * bt }
                let outline = [V2(-w(ya) / 2, 0), V2(w(ya) / 2, 0), V2(w(yb) / 2, yb - ya), V2(-w(yb) / 2, yb - ya)]
                let board = Prim.extrude(outline, depth: bt, bevel: 0.0015, bevelSegments: 1, material: mat)
                let local = Xform(translation: V3(0, ya, hw(ya) - bt / 2), rotation: FA.q(-deg, FA.X))
                m.add(board, around(face, local))
            }
        }
        let yFoot = ys + 0.34
        boards(ys, yFoot, foot)
        boards(yFoot, ye, paint)
        // Raised flat panels on each face.
        let p0 = ys + 0.42, p1 = ye - 0.14
        for face in 0..<4 {
            let wb = 2 * hw(p0) - 0.1, wt = 2 * hw(p1) - 0.1
            let outline = [V2(-wb / 2, 0), V2(wb / 2, 0), V2(wt / 2, p1 - p0), V2(-wt / 2, p1 - p0)]
            let panel = Prim.extrude(outline, depth: 0.012, bevel: 0.0035, bevelSegments: 1, material: "wood.painted-shaker-worn:757E5D")
            let local = Xform(translation: V3(0, p0, hw(p0) - 0.002), rotation: FA.q(-deg, FA.X))
            m.add(panel, around(face, local))
        }
        // Rain streaks running down the faces from the capital.
        for face in 0..<4 {
            for _ in 0..<3 {
                let y = ye - rng.float(0.1...0.3), len = rng.float(0.25...0.6), x = rng.float(-0.09...0.09)
                var st = Model(name: "streak")
                FJ.slab(&st, V3(rng.float(0.006...0.018), len, 0.0012), V3(x, -len / 2, 0.0006), "wood.painted-shaker-worn:49513B")
                m.add(st, around(face, Xform(translation: V3(0, y, hw(y)), rotation: FA.q(-deg, FA.X))))
            }
        }
        // Capital: cove necking, flared cap, abacus slab and bolted architrave seat.
        var neck = Model(name: "neck")
        FJ.mouldedFrame(&neck, cx: 0, cy: 0, w: 0.25, h: 0.25, z: 0, profile: FJ.ovoloProfile(width: 0.02, height: 0.02), trim, r: 0.005, backFacing: true)
        m.add(neck, Xform(translation: V3(0, ye, 0), rotation: FA.q(-90, FA.X)))
        FA.box(&m, V3(0.27, 0.03, 0.27), V3(0, ye + 0.015, 0), trim, r: 0.004)
        let flare = [Prim.ring(Shape2D.roundedRect(0.27, 0.27, radius: 0.006, segments: 1), y: ye + 0.03),
                     Prim.ring(Shape2D.roundedRect(0.33, 0.33, radius: 0.006, segments: 1), y: ye + 0.06),
                     Prim.ring(Shape2D.roundedRect(0.385, 0.385, radius: 0.006, segments: 1), y: ye + 0.09)]
        m.add(Prim.loft(flare, capStart: false, capEnd: true, material: trim))
        FA.box(&m, V3(0.43, 0.07, 0.43), V3(0, ye + 0.125, 0), trim, r: 0.005)                // abacus slab
        FA.box(&m, V3(0.38, 0.08, 0.38), V3(0, ye + 0.2, 0), paint, r: 0.004)                 // seat block under the beam
        for face in 0..<4 {
            let q = FA.q(Float(face) * 90, FA.Y)
            for dx: Float in [-0.12, 0.12] {
                let p = q.act(V3(dx, ye + 0.125, 0.215))
                hexBolt(&m, at: p, normal: q.act(FA.Z), size: 0.016, material: iron)
            }
            let p2 = q.act(V3(0, ye + 0.2, 0.19))
            rivet(&m, at: p2, normal: q.act(FA.Z), radius: 0.006, segments: 8, material: iron)
        }
        // Iron anchor straps tying the plinth to the pier cap on the front and back, two bolts each.
        for e: Float in [-1, 1] {
            FA.box(&m, V3(0.035, 0.17, 0.005), V3(0, yP + 0.05, e * 0.1675), iron, r: 0.0015)
            for dy: Float in [-0.045, 0.1] { hexBolt(&m, at: V3(0, yP + dy + 0.02, e * 0.17), normal: V3(0, 0, e), size: 0.012, material: iron) }
        }
        // Wear: chips on the plinth and foot, damp stain band on the lowest stone.
        var chipRng = rng.fork(4)
        FJ.chips(&m, spots: [V3(-0.06, yP + 0.05, 0), V3(0.08, yP + 0.03, 0)], face: 0.165, "wood.weathered", rng: &chipRng, each: 4)
        FJ.chips(&m, spots: [V3(0.0, ys + 0.1, 0), V3(-0.05, ys + 0.22, 0)], face: hw(ys + 0.15) + 0.0005, "wood.weathered", rng: &chipRng, each: 4)
        groundAO(&m, height: 0.35, floor: 0.6)
        return LODModel(FC.place(m))
    }
}
