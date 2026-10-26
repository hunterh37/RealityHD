import simd
import Foundation

/// Dutch Colonial split door, 0.95 x 2.1 m: two independently hung leaves of vertical beaded boards on back ledges with
/// a diagonal brace, a rounded shelf cap on the lower leaf, a 4 mm split, strap hinges on pintles, a Norfolk thumb
/// latch per leaf, a barrel bolt tying the leaves together, moulded casing with a drip cap and a worn oak sill.
/// The lower leaf is dark Colonial green, the upper leaf sun-faded; boots and hands have scuffed paint to bare wood.
public struct DutchDoorSplitLeaf: RealAsset {
    public static let id = "dutch-door-split-leaf"
    public static let summary = "Dutch Colonial split door: two hung painted board-and-batten leaves with shelf cap, strap hinges, thumb latches, barrel bolt and worn oak sill."
    public static let tags = ["prop", "architecture", "facade", "door", "wood", "metal"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 26, elevation: 6, distance: 3.4)

    /// Overall width and height including casing (m).
    public var width: Float = 0.95
    public var height: Float = 2.1
    /// Height of the split above the floor (m).
    public var splitHeight: Float = 1.07
    /// Lower leaf paint, Colonial green, scuffed.
    public var lowerPaint: MaterialKey = "wood.painted-shaker-worn:2E4A3B"
    /// Upper leaf paint, sun-faded.
    public var upperPaint: MaterialKey = "wood.painted-shaker-worn:46604F"
    /// Casing paint.
    public var casingPaint: MaterialKey = "wood.painted-exterior:E3DDCB"
    public var iron: MaterialKey = "metal.wrought-iron"
    public var brass: MaterialKey = "metal.brass-aged"
    public var oak: MaterialKey = "wood.oak"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = width, H = height, cas: Float = 0.07, sill: Float = 0.03
        let lw = W - 2 * cas - 0.024, zb: Float = 0.02, tb: Float = 0.03, zf = zb + tb       // leaf width, board back, board thickness, front
        let zc: Float = 0.068                                                                   // casing front plane
        let headUnder = H - 0.07
        let gap: Float = 0.004
        let y0 = sill + 0.003, y1 = headUnder - 0.003, ys = splitHeight

        // Casing: side boards with a bead edge, head board with drip cap, plinth blocks.
        for e: Float in [-1, 1] {
            FA.box(&m, V3(cas, headUnder - sill, 0.034), V3(e * (W / 2 - cas / 2), (sill + headUnder) / 2, zc - 0.017), casingPaint, r: 0.002)
            FA.box(&m, V3(0.012, headUnder - sill, 0.012), V3(e * (W / 2 - cas - 0.006), (sill + headUnder) / 2, zc - 0.006 + 0.004), casingPaint, r: 0.0025)
            FA.box(&m, V3(0.02, headUnder - sill, 0.05), V3(e * (lw / 2 + 0.014), (sill + headUnder) / 2, 0.025), casingPaint, r: 0.002)   // jamb lining
            FA.box(&m, V3(cas + 0.012, 0.16, 0.044), V3(e * (W / 2 - cas / 2), sill + 0.08, zc - 0.022), "wood.painted-shaker-worn:B9B3A0", r: 0.003)   // grimy plinth
            FA.box(&m, V3(cas + 0.018, 0.014, 0.05), V3(e * (W / 2 - cas / 2), sill + 0.167, zc - 0.025), casingPaint, r: 0.003)
        }
        FA.box(&m, V3(W, 0.07, 0.034), V3(0, headUnder + 0.035, zc - 0.017), casingPaint, r: 0.002)
        FA.box(&m, V3(W + 0.0, 0.022, 0.056), V3(0, H - 0.011, zc - 0.022), casingPaint, r: 0.004)
        FA.box(&m, V3(W, 0.006, 0.07), V3(0, H - 0.002, zc - 0.03), "metal.galvanized-aged", r: 0.0015)    // lead-coated drip flashing
        FA.box(&m, V3(lw + 0.04, 0.02, 0.05), V3(0, headUnder - 0.01, 0.025), casingPaint, r: 0.002)
        // Oak sill: worn saddle, rain drip groove.
        FA.box(&m, V3(W - 0.02, sill, 0.1), V3(0, sill / 2, 0.05), oak, r: 0.004)
        FA.box(&m, V3(lw * 0.75, 0.0014, 0.035), V3(rng.float(-0.04...0.04), sill - 0.0003, 0.06), "wood.weathered", r: 0.0008)
        FJ.slab(&m, V3(W - 0.14, 0.002, 0.004), V3(0, sill + 0.0005, 0.098), "wood.weathered")

        // One leaf: vertical beaded boards over ledges, brace on the back.
        func leaf(_ paint: MaterialKey, bottom b: Float, top t: Float, cap: Bool, brace: Bool) {
            let n = 8, bw = lw / Float(n), hh = t - b
            FJ.slab(&m, V3(lw, hh, 0.004), V3(0, (b + t) / 2, zb + 0.002), "wood.weathered")
            for i in 0..<n {
                let x = -lw / 2 + bw / 2 + Float(i) * bw
                let k = rng.float(0.88...1.12)
                let bpaint: MaterialKey = paint.hasPrefix("wood.painted-shaker-worn:") ? {
                    let hex = UInt32(paint.dropFirst("wood.painted-shaker-worn:".count), radix: 16) ?? 0x405040
                    let r = min(255, Int(Float((hex >> 16) & 255) * k)), g = min(255, Int(Float((hex >> 8) & 255) * k)), bl = min(255, Int(Float(hex & 255) * k))
                    return "wood.painted-shaker-worn:" + String(format: "%02X%02X%02X", r, g, bl)
                }() : paint
                FA.box(&m, V3(bw - 0.003, hh, tb), V3(x, (b + t) / 2, zb + tb / 2 + 0.002), bpaint, r: 0.0022)
                if i > 0 {   // bead along the tongue joint
                    FA.rod(&m, V3(x - bw / 2, b + 0.004, zf + 0.0012), V3(x - bw / 2, t - 0.004, zf + 0.0012), r: 0.0026, paint, sides: 6)
                }
            }
            // Ledges and brace on the back (z behind the boards).
            let ledgeH: Float = 0.12
            let ys = [b + 0.07, (b + t) / 2, t - 0.07]
            for y in ys { FA.box(&m, V3(lw - 0.03, ledgeH, 0.02), V3(0, y, zb - 0.008), paint, r: 0.002) }
            if brace {
                let dx = lw - 0.2, dy = ys[2] - ys[0]
                let ang = atan2(dy, dx) * 180 / .pi
                FA.box(&m, V3(sqrt(dx * dx + dy * dy) - 0.05, 0.095, 0.02), V3(0, (ys[0] + ys[2]) / 2, zb - 0.008 - 0.0), paint, r: 0.002, rot: FA.q(ang, FA.Z))
            }
            if cap {   // shelf cap: rounded-over board overhanging the front
                m.add(Prim.extrude(Shape2D.rounded([V2(-0.012, 0), V2(0.056 - 0.012, 0), V2(0.056 - 0.012, 0.024), V2(-0.012, 0.024)], radius: 0.009, segments: 3),
                                   depth: lw + 0.024, bevel: 0.002, bevelSegments: 1, material: paint),
                      Xform(translation: V3(0, t - 0.024, zb + 0.004), rotation: FA.q(-90, FA.Y)))
            }
        }
        let lowTop = ys - gap / 2, upBot = ys + gap / 2
        leaf(lowerPaint, bottom: y0, top: lowTop, cap: true, brace: true)
        leaf(upperPaint, bottom: upBot, top: y1, cap: false, brace: true)

        // Strap hinges on pintles (hinge side at -x): two per leaf, eye wrapped round the pintle.
        let hx = -lw / 2
        for y in [y0 + 0.22, lowTop - 0.22, upBot + 0.22, y1 - 0.22] {
            FJ.strapHinge(&m, from: hx + 0.006, to: hx + 0.34, y: y, z: zf + 0.002, width: 0.034, thick: 0.0045, iron, nails: 5, rng: &rng)
            FA.rod(&m, V3(hx - 0.004, y - 0.05, zb + 0.026), V3(hx - 0.004, y + 0.05, zb + 0.026), r: 0.0062, iron, sides: 10)
            FA.box(&m, V3(0.014, 0.034, 0.012), V3(hx - 0.012, y, zb + 0.02), iron, r: 0.0015)   // pintle plate into the jamb
        }
        // Norfolk thumb latches: backplate, grip bar, thumb piece, keeper on the jamb.
        for y in [lowTop - 0.3, upBot + 0.3] {
            let x = lw / 2 - 0.058
            FA.box(&m, V3(0.04, 0.2, 0.004), V3(x, y, zf + 0.004), iron, r: 0.0013)
            FA.box(&m, V3(0.016, 0.15, 0.007), V3(x, y - 0.012, zf + 0.0095), iron, r: 0.0025)
            FA.box(&m, V3(0.014, 0.034, 0.005), V3(x, y + 0.092, zf + 0.0125), iron, r: 0.002, rot: FA.q(15, FA.Z))
            for dy: Float in [-0.085, 0.085] { rivet(&m, at: V3(x, y + dy, zf + 0.006), normal: FA.Z, radius: 0.0048, segments: 8, material: iron) }
            FA.box(&m, V3(0.03, 0.05, 0.008), V3(lw / 2 + 0.002, y - 0.012, zf - 0.006), iron, r: 0.0015)        // keeper
        }
        // Barrel bolt: base plate on the upper leaf's bottom, bolt rod and knob dropping into the shelf cap.
        let bx: Float = 0.12, by = upBot + 0.05
        FA.box(&m, V3(0.11, 0.028, 0.004), V3(bx, by, zf + 0.004), iron, r: 0.0012)
        FA.cylX(&m, r: 0.0045, h: 0.09, at: V3(bx - 0.045, by, zf + 0.0095), iron, bevel: 0.001, segments: 10)
        FA.box(&m, V3(0.012, 0.014, 0.012), V3(bx - 0.05, by, zf + 0.0095), iron, r: 0.002)
        FA.ball(&m, r: 0.006, at: V3(bx + 0.044, by, zf + 0.0125), iron)
        for dx: Float in [-0.045, 0.045] { rivet(&m, at: V3(bx + dx, by + 0.0, zf + 0.0075), normal: FA.Z, radius: 0.0036, segments: 6, material: iron) }
        // Brass kick plate on the lower leaf with screws.
        let kw = lw - 0.2
        FA.box(&m, V3(kw, 0.17, 0.0015), V3(0, y0 + 0.095, zf + 0.00075), brass, r: 0.0006)
        for i in 0..<6 {
            let sx = -kw / 2 + 0.014 + Float(i) * ((kw - 0.028) / 5)
            for sy: Float in [y0 + 0.018, y0 + 0.172] { rivet(&m, at: V3(sx, sy, zf + 0.0015), normal: FA.Z, radius: 0.0032, segments: 6, material: "metal.screw-zinc") }
        }

        // Wear: bare boards where hands and boots land, flaked paint, rust bleed under hinges, grime on the lower boards.
        for _ in 0..<12 { FJ.peel(&m, at: V3(rng.float(-lw / 2 + 0.05...lw / 2 - 0.05), rng.float(y0 + 0.22...lowTop - 0.5), zf + 0.002), w: rng.float(0.04...0.09), h: rng.float(0.06...0.22), "wood.weathered", rng: &rng) }
        for _ in 0..<8 { FJ.peel(&m, at: V3(rng.float(-lw / 2 + 0.05...lw / 2 - 0.05), rng.float(upBot + 0.4...y1 - 0.2), zf + 0.002), w: rng.float(0.04...0.08), h: rng.float(0.05...0.16), "wood.weathered", rng: &rng) }
        FJ.peel(&m, at: V3(lw / 2 - 0.058, lowTop - 0.3, zf + 0.002), w: 0.07, h: 0.16, "wood.weathered", rng: &rng)
        FJ.peel(&m, at: V3(lw / 2 - 0.058, upBot + 0.3, zf + 0.002), w: 0.07, h: 0.16, "wood.painted-shaker-worn:7C8076", rng: &rng)
        for y in [y0 + 0.22, lowTop - 0.22, upBot + 0.22, y1 - 0.22] { FJ.streak(&m, x: hx + 0.03, top: y - 0.02, length: 0.1, width: 0.01, z: zf + 0.002, "metal.rust") }
        FJ.slab(&m, V3(lw - 0.03, 0.09, 0.0012), V3(0, y0 + 0.28, zf + 0.0026), "wood.painted-shaker-worn:1F332A")      // splash grime
        FJ.chips(&m, spots: [V3(0.2, lowTop - 0.07, 0), V3(-0.25, upBot + 0.05, 0), V3(0.3, y0 + 0.3, 0)], face: zf + 0.002, "wood.weathered", rng: &rng, each: 4)
        groundAO(&m, height: 0.12, floor: 0.7)
        return LODModel(FA.centerZ(m))
    }
}
