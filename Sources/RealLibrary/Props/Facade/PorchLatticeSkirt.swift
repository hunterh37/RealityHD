import simd
import Foundation

/// Victorian porch lattice skirt, 3.0 m: three diagonal lattice panels (two crossing layers of 8.5 mm slats stapled where
/// they cross) in a painted frame of 70 mm end stiles, 60 mm joint stiles, a profiled bottom rail, a flat top rail with
/// a moulded cap, and bead stops around each opening, face-nailed at every joint. Cream paint is chipped along the
/// rails, the lowest 15 cm is stained with damp and mildew, one slat is a raw replacement and one slat is missing.
public struct PorchLatticeSkirt: RealAsset {
    public static let id = "porch-lattice-skirt"
    public static let summary = "Victorian porch lattice skirt, 3.0 m: diagonal lattice in a moulded painted frame with a top cap and bottom rail."
    public static let tags = ["prop", "architecture", "facade", "wood"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 8, distance: 3.2)

    /// Paint for frame and lattice (worn).
    public var paintKey = "wood.painted-exterior"
    /// Cream-white base paint colour (sRGB hex).
    public var paint: UInt32 = 0xDCD6C1
    /// Slat centre spacing measured across the slat, meters.
    public var slatPitch: Float = 0.076
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [make(seed: seed, lite: false), make(seed: seed, lite: true)], switchDistances: [6])
    }

    func hex(_ r: Int, _ g: Int, _ b: Int) -> String {
        String(format: "%02X%02X%02X", max(0, min(255, r)), max(0, min(255, g)), max(0, min(255, b)))
    }

    func make(seed: UInt64, lite: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let pr = Int((paint >> 16) & 0xFF), pg = Int((paint >> 8) & 0xFF), pb = Int(paint & 0xFF)
        func tone(_ d: Int) -> MaterialKey { "\(paintKey):" + hex(pr + d, pg + d, pb + d - d / 3) }
        let W: Float = 3.0, H: Float = 0.8
        let railT: Float = 0.023            // frame thickness
        let botH: Float = 0.1, topH: Float = 0.072, capH: Float = 0.03
        let endW: Float = 0.07, midW: Float = 0.06
        let yLo = botH, yHi = H - capH - topH
        let jx: [Float] = [-0.5, 0.5]
        // Stiles: end and joint.
        var stiles: [(Float, Float)] = [(-W / 2 + endW / 2, endW), (W / 2 - endW / 2, endW)]
        for x in jx { stiles.append((x, midW)) }
        for (x, w) in stiles.sorted(by: { $0.0 < $1.0 }) {
            FA.box(&m, V3(w, yHi - yLo + 0.01, railT), V3(x, (yLo + yHi) / 2, 0), tone(rng.int(-8...3)), r: 0.0025)
        }
        // Bottom rail: chamfered-top skirt board with a drip kerf; mildew-stained lower tone.
        FA.run(&m, [V2(-0.0115, 0), V2(0.0115, 0), V2(0.0115, botH - 0.014), V2(0.0098, botH), V2(-0.0098, botH), V2(-0.0115, botH - 0.014)], length: W, at: V3(0, 0, 0), tone(-34), bevel: 0.0015)
        // Top rail and moulded cap.
        FA.box(&m, V3(W, topH, railT), V3(0, yHi + topH / 2 - 0.001, 0), tone(-4), r: 0.0025)
        let capProfile: [V2] = [V2(-0.0125, 0), V2(0.0125, 0), V2(0.0140, 0.003), V2(0.0150, 0.008), V2(0.0150, 0.014), V2(0.0135, 0.019), V2(0.0150, 0.0215), V2(0.0150, 0.026), V2(0.0125, 0.030), V2(-0.0125, 0.030), V2(-0.0150, 0.026), V2(-0.0150, 0.0215), V2(-0.0135, 0.019), V2(-0.0150, 0.014), V2(-0.0150, 0.008), V2(-0.0140, 0.003)]
        FA.run(&m, capProfile, length: W, at: V3(0, H - capH, 0), tone(2), bevel: 0.0008)
        // Lattice panels between the stiles.
        let edges: [Float] = [-W / 2 + endW, jx[0] - midW / 2, jx[0] + midW / 2, jx[1] - midW / 2, jx[1] + midW / 2, W / 2 - endW]
        let slatW: Float = 0.032, slatT: Float = 0.0085, margin: Float = 0.014
        let s2: Float = 0.70710678
        var panelIdx = 0
        var staples: [(V3, Float)] = []
        for p in 0..<3 {
            let x0 = edges[p * 2], x1 = edges[p * 2 + 1]
            let cx = (x0 + x1) / 2, cy = (yLo + yHi) / 2
            let hx = (x1 - x0) / 2 + margin, hy = (yHi - yLo) / 2 + margin
            for dir in 0..<2 {
                let sgn: Float = dir == 0 ? 1 : -1
                let t = V2(s2, sgn * s2), nrm = V2(-sgn * s2, s2)
                let zc: Float = dir == 0 ? -0.0033 : 0.0033
                let reach = Int((hx + hy) / slatPitch) + 1
                for k in -reach...reach {
                    let off = (Float(k) + (p == 1 ? 0.5 : 0)) * slatPitch
                    // Clip the centre line to the opening plus margin.
                    var lo: Float = -10, hi: Float = 10
                    let o = V2(nrm.x * off, nrm.y * off)
                    for (oo, tt, h) in [(o.x, t.x, hx), (o.y, t.y, hy)] {
                        if abs(tt) < 1e-5 { continue }
                        let a = (-h - oo) / tt, b = (h - oo) / tt
                        lo = max(lo, min(a, b)); hi = min(hi, max(a, b))
                    }
                    if hi - lo < 0.05 { continue }
                    if p == 1 && dir == 1 && k == -reach / 2 - 2 { continue } // missing slat
                    let mid = (lo + hi) / 2
                    let c = V3(cx + o.x + t.x * mid, cy + o.y + t.y * mid, zc)
                    let raw = p == 2 && dir == 0 && k == 3
                    let low = c.y < yLo + 0.2
                    let mat: MaterialKey = raw ? "wood.weathered:C2B6A0" : (low ? "\(paintKey):" + (rng.chance(0.5) ? "B7BBA0" : "C3C4AA") : tone(rng.int(-22...8)))
                    let size = V3(hi - lo, slatW, slatT)
                    let rot = FA.q(sgn * 45, FA.Z)
                    if lite { m.add(cuboid(size, material: mat), Xform(translation: c, rotation: rot)) }
                    else { FA.box(&m, size, c, mat, r: 0.0018, rot: rot) }
                }
            }
            // Staples where layers cross, around the perimeter of each opening.
            if !lite {
                let reach = Int((hx + hy) / slatPitch) + 1
                for a in -reach...reach { for b in -reach...reach {
                    let oa = (Float(a) + (p == 1 ? 0.5 : 0)) * slatPitch, ob = (Float(b) + (p == 1 ? 0.5 : 0)) * slatPitch
                    // dir0: nrm=(-s2, s2) off=oa ; dir1: nrm=(s2, s2) off=ob. Solve for the crossing point.
                    let px = (ob - oa) * s2, py = (oa + ob) * s2
                    if abs(px) < (x1 - x0) / 2 - 0.02 && abs(py) < (yHi - yLo) / 2 - 0.02 {
                        let edgeNear = (x1 - x0) / 2 - abs(px) < 0.12 || (yHi - yLo) / 2 - abs(py) < 0.12
                        if edgeNear && rng.chance(0.7) { staples.append((V3(cx + px, cy + py, slatT + 0.0033 - 0.0005), rng.chance(0.5) ? 45 : -45)) }
                    }
                }}
            }
            panelIdx += 1
            // Bead stops around the opening.
            let bz = railT / 2 + 0.0017
            let bw: Float = 0.013, bt: Float = 0.0045
            FA.box(&m, V3(x1 - x0, bw, bt), V3(cx, yLo + bw / 2 - 0.001, bz), tone(-2), r: 0.0014)
            FA.box(&m, V3(x1 - x0, bw, bt), V3(cx, yHi - bw / 2 + 0.001, bz), tone(-2), r: 0.0014)
            FA.box(&m, V3(bw, yHi - yLo - 2 * bw + 0.004, bt), V3(x0 + bw / 2 - 0.001, cy, bz), tone(-2), r: 0.0014)
            FA.box(&m, V3(bw, yHi - yLo - 2 * bw + 0.004, bt), V3(x1 - bw / 2 + 0.001, cy, bz), tone(-2), r: 0.0014)
        }
        for (p, a) in staples {
            m.add(cuboid(V3(0.014, 0.0018, 0.0014), material: "metal.galvanized-aged"), Xform(translation: p, rotation: FA.q(a, FA.Z)))
        }
        // Face nails: stile heads into the top and bottom rails, rail heads into the stile ends.
        if !lite {
            for (x, _) in stiles {
                for y in [yHi + 0.03, botH - 0.045, botH - 0.015] as [Float] {
                    m.add(Prim.cylinder(radius: 0.0024, height: 0.0014, bevel: 0.0004, segments: 6, bevelSegments: 1, material: "metal.galvanized-aged"),
                          Xform(translation: V3(x + rng.float(-0.006...0.006), y, railT / 2), rotation: facing(FA.Z)))
                    if rng.chance(0.4) {
                        m.add(cuboid(V3(0.0007, rng.float(0.02...0.06), 0.0004), material: "metal.rust"), Xform(translation: V3(x, y - 0.03, railT / 2 + 0.0004)))
                    }
                }
            }
            for i in 0..<9 {
                let x = -1.4 + Float(i) * 0.35 + rng.float(-0.03...0.03)
                m.add(Prim.cylinder(radius: 0.0024, height: 0.0014, bevel: 0.0004, segments: 6, bevelSegments: 1, material: "metal.galvanized-aged"),
                      Xform(translation: V3(x, yHi + topH - 0.012, railT / 2), rotation: facing(FA.Z)))
            }
            // Wear: chips along rails and stiles, damp stain and mildew streaks low down.
            for _ in 0..<50 {
                let x = rng.float(-1.45...1.45)
                let onBot = rng.chance(0.4)
                let y = onBot ? rng.float(0.01...0.095) : rng.float(yLo...(yHi + topH - 0.01))
                m.add(cuboid(V3(rng.float(0.015...0.07), rng.float(0.004...0.014), 0.0005), material: "wood.weathered"),
                      Xform(translation: V3(x, y, railT / 2 + 0.0002), rotation: FA.q(rng.float(-12...12), FA.Z)))
            }
            for _ in 0..<30 {
                let x = rng.float(-1.45...1.45)
                let sh = rng.float(0.04...0.16)
                m.add(cuboid(V3(rng.float(0.012...0.05), sh, 0.0004), material: rng.chance(0.5) ? "wood.weathered:5F6B52" : "wood.weathered:6F7560"),
                      Xform(translation: V3(x, sh / 2 + rng.float(0...0.02), railT / 2 + 0.0002)))
            }
        }
        _ = rng
        return FC.place(m)
    }
}
