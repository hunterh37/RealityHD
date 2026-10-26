import simd
import Foundation

/// Medieval Tudor studded oak door, 1.1 x 2.2 m: seven vertical oak planks with chamfered edges, cut to a
/// four-centred head and hung on three ledgers with a diagonal brace behind. Rose-head forged nails run along each ledger and
/// the edges, three long strap hinges swing on pintles driven into stone, an iron ring pull hangs from a boss, and
/// a lock plate carries a keyhole. The doorway is chamfered limestone: jamb courses, radial voussoirs, spandrel and a
/// worn threshold step. Oak is silvered and dark-stained near the hands; nails weep rust.
public struct StuddedOakPlankDoor: RealAsset {
    public static let id = "studded-oak-plank-door"
    public static let summary = "Tudor studded oak plank door: vertical oak planks on oak ledgers, rows of forged nail heads, strap hinges, a ring pull and a pointed oak frame."
    public static let tags = ["prop", "architecture", "facade", "door", "wood", "metal"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 22, elevation: 6, distance: 3.6)

    /// Clear width of the doorway (m).
    public var openWidth: Float = 0.86
    /// Height of the jamb to the springing of the head (m).
    public var springHeight: Float = 1.82
    /// Rise of the four-centred head (m).
    public var rise: Float = 0.285
    /// Plank count.
    public var planks = 7
    public var stone: MaterialKey = "stone.limestone"
    public var sooted: MaterialKey = "stone.limestone-sooted"
    public var iron: MaterialKey = "metal.wrought-iron"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let ow = openWidth, ys = springHeight, hw = ow / 2
        let D: Float = 0.117, sill: Float = 0.04, jam: Float = 0.12
        func head(_ x: Float) -> Float { ys + rise * (1 - pow(min(abs(x) / hw, 1), 1.8)) }
        let zf: Float = 0.075                                                 // door front plane
        let oaks: [MaterialKey] = ["wood.oak", "wood.oak", "wood.oak", "wood.pine-aged", "wood.oak", "wood.weathered", "wood.oak"]

        // Threshold step.
        FA.box(&m, V3(ow + 2 * jam, sill, D), V3(0, sill / 2, D / 2), sooted, r: 0.004)
        FA.box(&m, V3(ow * 0.6, 0.0014, 0.06), V3(rng.float(-0.05...0.05), sill - 0.0004, 0.06), "stone.limestone-sooted:7B7468", r: 0.0008)   // worn dip
        // Jamb courses, chamfered at the reveal edge.
        let courses = 6, ch = (ys - sill) / Float(courses)
        for c in 0..<courses {
            let y = sill + (Float(c) + 0.5) * ch
            for e: Float in [-1, 1] {
                let mat: MaterialKey = rng.chance(0.35) ? sooted : stone
                FA.box(&m, V3(jam, ch - 0.007, D - 0.004), V3(e * (hw + jam / 2), y, D / 2), mat, r: 0.004)
                FJ.slab(&m, V3(0.014, ch - 0.014, 0.014), V3(e * (hw - 0.0035), y, D - 0.0075), mat, rot: FA.q(45, FA.Y))
            }
        }
        // Voussoirs round the head: quads between the doorway curve and an outer curve 0.10 above it.
        let nv = 9
        func pt(_ k: Int, off: Float) -> V2 {
            let x = -hw + ow * Float(k) / Float(nv), eps: Float = 0.001
            let dy = (head(x + eps) - head(x - eps)) / (2 * eps)
            let nrm = simd_normalize(V2(-dy, 1))
            return V2(x, head(x)) + nrm * off
        }
        var outer: [V2] = []
        for k in 0...nv { outer.append(pt(k, off: 0.1)) }
        for k in 0..<nv {
            let q = [pt(k, off: 0.0), pt(k + 1, off: 0.0), outer[k + 1], outer[k]]
            let c = (q[0] + q[1] + q[2] + q[3]) / 4
            let sh = q.map { c + ($0 - c) * 0.965 }
            m.add(Prim.extrude(sh, depth: D - 0.006, bevel: 0.003, bevelSegments: 1, material: k % 3 == 1 ? sooted : stone), Xform(translation: V3(0, 0, D / 2)))
        }
        // Spandrel mass between the voussoirs and the straight top.
        let top = outer.map(\.y).max()! + 0.0
        var sp: [V2] = [V2(-hw - jam, ys), V2(-hw - jam, top), V2(hw + jam, top), V2(hw + jam, ys)]
        sp += outer.reversed().map { V2($0.x, $0.y + 0.0) }
        m.add(Prim.extrude(Shape2D.deduped(sp), depth: D - 0.01, bevel: 0.003, bevelSegments: 1, material: sooted), Xform(translation: V3(0, 0, D / 2)))

        // Door leaf: vertical planks cut to the head, a dark backing, three ledgers and a brace behind.
        let n = planks, pw = ow / Float(n), tp: Float = 0.045, zb = zf - tp
        FJ.slab(&m, V3(ow, ys, 0.01), V3(0, (sill + ys) / 2, zb + 0.005), "wood.charred")
        for i in 0..<n {
            let x0 = -hw + Float(i) * pw, x1 = x0 + pw
            let a = x0 + 0.002, b = x1 - 0.002
            let outline: [V2] = [V2(a, sill + 0.002), V2(b, sill + 0.002), V2(b, head(b) - 0.004), V2((a + b) / 2, head((a + b) / 2) - 0.004), V2(a, head(a) - 0.004)]
            m.add(Prim.extrude(Shape2D.deduped(outline), depth: tp, bevel: 0.004, bevelSegments: 1, material: oaks[(i * 7 + 3) % oaks.count]),
                  Xform(translation: V3(0, 0, zb + tp / 2)))
        }
        let ledgerY: [Float] = [0.30, 0.98, 1.66]
        for y in ledgerY { FA.box(&m, V3(ow - 0.03, 0.16, 0.034), V3(0, y, zb - 0.015), "wood.oak", r: 0.003) }
        let dy = ledgerY[2] - ledgerY[0], dx = ow - 0.2
        FA.box(&m, V3(sqrt(dx * dx + dy * dy) - 0.1, 0.12, 0.034), V3(0, (ledgerY[0] + ledgerY[2]) / 2, zb - 0.015), "wood.oak", r: 0.003, rot: FA.q(atan2(dy, dx) * 180 / .pi, FA.Z))

        // Rose-head nails along the ledgers and the edges, one per plank per row.
        let rows: [Float] = [0.30, 0.64, 0.98, 1.32, 1.66]
        for y in rows {
            for i in 0..<n {
                let x = -hw + (Float(i) + 0.5) * pw
                if y < head(x) - 0.06 {
                    rivet(&m, at: V3(x, y + rng.float(-0.002...0.002), zf), normal: FA.Z, radius: 0.0105, height: 0.0085, segments: 8, material: iron)
                    rivet(&m, at: V3(x, y, zf + 0.0085), normal: FA.Z, radius: 0.0045, height: 0.004, segments: 5, material: iron)
                }
            }
        }
        // Border nails up the edge planks.
        for e: Float in [-1, 1] {
            for y in stride(from: Float(0.12), through: 1.95, by: 0.14) where y < head(e * hw * 0.9) - 0.05 {
                rivet(&m, at: V3(e * (hw - 0.022), y, zf), normal: FA.Z, radius: 0.0085, height: 0.0075, segments: 6, material: iron)
            }
        }
        // Strap hinges: long tapering straps from the pintles on the left jamb.
        let hx = -hw + 0.004
        for y in ledgerY {
            FJ.strapHinge(&m, from: hx, to: hx + 0.6, y: y, z: zf, width: 0.075, thick: 0.007, iron, nails: 3, rng: &rng)
            FA.rod(&m, V3(hx - 0.012, y - 0.06, zf - 0.02), V3(hx - 0.012, y + 0.06, zf - 0.02), r: 0.0085, iron, sides: 10)
            FA.box(&m, V3(0.034, 0.05, 0.012), V3(hx - 0.022, y, zf - 0.03), iron, r: 0.002)
        }
        // Ring pull: boss, ring and lock plate with keyhole on the latch side.
        let rx: Float = hw - 0.20, ry: Float = 1.04
        FA.cylZ(&m, r: 0.034, h: 0.01, at: V3(rx, ry, zf), iron, bevel: 0.0025, segments: 18)
        FC.bead(&m, r: 0.016, at: V3(rx, ry, zf + 0.012), iron, sub: 4)
        m.add(Prim.torus(major: 0.05, minor: 0.0075, segments: 28, sides: 8, material: iron), Xform(translation: V3(rx, ry - 0.045, zf + 0.025), rotation: FA.q(90, FA.X)))
        FA.box(&m, V3(0.11, 0.15, 0.005), V3(rx - 0.0, ry - 0.2, zf + 0.0025), iron, r: 0.0015)
        FJ.slab(&m, V3(0.008, 0.026, 0.0012), V3(rx, ry - 0.2, zf + 0.0056), "metal.painted:0B0B0B")
        FC.bead(&m, r: 0.0055, at: V3(rx, ry - 0.178, zf + 0.0056), "metal.painted:0B0B0B", sub: 2)
        for (dx2, dy2) in [(-0.04, -0.06), (0.04, -0.06), (-0.04, 0.06), (0.04, 0.06)] as [(Float, Float)] {
            rivet(&m, at: V3(rx + dx2, ry - 0.2 + dy2, zf + 0.005), normal: FA.Z, radius: 0.0048, segments: 8, material: iron)
        }

        // Wear: hand-dark oak around the pull, rust weeping from the nails, silvered grey at the foot, sooted stone, chips.
        FJ.slab(&m, V3(0.2, 0.34, 0.0012), V3(rx, ry - 0.1, zf + 0.0006), "wood.charred")
        for _ in 0..<26 {
            let i = rng.int(0...(n - 1)), y = rows[rng.int(0...(rows.count - 1))]
            let x = -hw + (Float(i) + 0.5) * pw
            if y < head(x) - 0.12 { FJ.streak(&m, x: x + rng.float(-0.003...0.003), top: y - 0.01, length: rng.float(0.08...0.26), width: rng.float(0.01...0.02), z: zf, "metal.rust") }
        }
        for _ in 0..<9 { FJ.streak(&m, x: rng.float(-hw + 0.03...hw - 0.03), top: rng.float(1.0...2.0), length: rng.float(0.2...0.55), width: rng.float(0.012...0.03), z: zf, "wood.charred") }
        for _ in 0..<7 { FJ.peel(&m, at: V3(rng.float(-hw + 0.05...hw - 0.05), rng.float(sill + 0.05...0.35), zf), w: rng.float(0.05...0.12), h: rng.float(0.05...0.15), "wood.weathered", rng: &rng) }
        for e: Float in [-1, 1] { for y in [0.5, 1.4] as [Float] { FJ.streak(&m, x: e * (hw + jam / 2), top: y + 0.25, length: rng.float(0.2...0.45), width: 0.03, z: D, "stone.limestone-sooted:5C564B") } }
        FJ.chips(&m, spots: [V3(-hw - 0.06, 0.8, 0), V3(hw + 0.06, 0.3, 0), V3(hw + 0.06, 1.5, 0)], face: D + 0.0004, "stone.limestone:EAE0CC", rng: &rng, each: 4)
        groundAO(&m, height: 0.15, floor: 0.7)
        return LODModel(FC.place(m))
    }
}
