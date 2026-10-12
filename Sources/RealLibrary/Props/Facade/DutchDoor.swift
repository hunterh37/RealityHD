import simd
import Foundation

/// Dutch door: Colonial split door, 0.95 x 2.1 m with casing. Two independent four-panel leaves (raised and
/// fielded panels with ovolo sticking, 44 mm stiles and rails) meet at a 4 mm gap; the lower leaf carries a
/// rounded shelf cap. Cast-iron strap hinges on pintles, a Suffolk thumb latch per leaf, a barrel bolt
/// linking the leaves, a brass kick plate scuffed at the lower edge, and a worn oak threshold.
public struct DutchDoor: RealAsset {
    public static let id = "dutch-door"
    public static let summary = "Colonial Dutch door, 0.95 x 2.1 m: split four-panel leaves, shelf cap, strap hinges, thumb latches, barrel bolt."
    public static let tags = ["prop", "architecture", "facade", "door", "wood", "metal"]
    public static let budget = 14_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 6, distance: 1.6)

    /// Overall width and height including casing (m).
    public var width: Float = 0.95
    public var height: Float = 2.1
    /// Height of the split above the floor (m).
    public var splitHeight: Float = 1.07
    /// Painted leaf finish (Colonial green, weathered).
    public var leafPaint: MaterialKey = "wood.painted-shaker-worn:34493F"
    /// Casing and jamb finish.
    public var casingPaint: MaterialKey = "wood.painted-exterior:E6E0CF"
    /// Upper leaf, repainted earlier and sun-faded against the lower leaf.
    public var upperPaint: MaterialKey = "wood.painted-shaker-worn:46604F"
    /// Grimy casing foot where splash and boots reach.
    public var footPaint: MaterialKey = "wood.painted-shaker-worn:A39D8B"
    public var iron: MaterialKey = "metal.wrought-iron"
    public var brass: MaterialKey = "metal.brass-aged"
    public var threshold: MaterialKey = "wood.oak"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = width, H = height
        let cas: Float = 0.07, sill: Float = 0.025, zf: Float = 0.06      // casing width, threshold height, front plane
        let lw: Float = W - 2 * cas - 0.04 - 0.006                          // leaf width (jamb lining 20 mm each side)
        let zl: Float = 0.008, tl: Float = 0.044                            // leaf back plane, thickness
        let zfront = zl + tl
        let headUnder = H - 0.062
        let y0 = sill + 0.003, y1 = headUnder - 0.003, ys = splitHeight
        let gap: Float = 0.004

        // Casing: side boards, head board, drip cap and bead moulding on the inner edge.
        for e: Float in [-1, 1] {
            FA.box(&m, V3(cas, headUnder - sill, 0.016), V3(e * (W / 2 - cas / 2), (sill + headUnder) / 2, zf - 0.008), casingPaint, r: 0.002)
            FA.box(&m, V3(cas, 0.15, 0.03), V3(e * (W / 2 - cas / 2), sill + 0.075, zf - 0.015), footPaint, r: 0.003)          // plinth block
            FA.box(&m, V3(cas - 0.014, 0.012, 0.034), V3(e * (W / 2 - cas / 2), sill + 0.156, zf - 0.015), casingPaint, r: 0.003)  // plinth cap
            FA.box(&m, V3(0.02, headUnder - sill, zf), V3(e * (lw / 2 + 0.003 + 0.01), (sill + headUnder) / 2, zf / 2), casingPaint, r: 0.002)
            m.add(Prim.extrude([V2(-0.004, 0), V2(0.004, 0), V2(0.004, headUnder - sill), V2(-0.004, headUnder - sill)], depth: 0.012,
                               bevel: 0.0015, bevelSegments: 1, material: casingPaint),
                  Xform(translation: V3(e * (W / 2 - cas - 0.003), sill, zf - 0.016), rotation: .identity))
        }
        FA.box(&m, V3(W, 0.048, 0.022), V3(0, headUnder + 0.024, zf - 0.011), casingPaint, r: 0.002)
        FA.box(&m, V3(W, 0.014, 0.034), V3(0, H - 0.007, zf - 0.015), casingPaint, r: 0.003)
        FA.box(&m, V3(lw + 0.046, 0.02, zf), V3(0, headUnder - 0.01, zf / 2), casingPaint, r: 0.002)
        // Threshold with a worn saddle and a rain drip.
        FA.box(&m, V3(W - 0.02, sill, zf), V3(0, sill / 2, zf / 2), threshold, r: 0.004)
        FA.box(&m, V3(lw * 0.7, 0.0016, 0.03), V3(rng.float(-0.04...0.04), sill - 0.0004, zf / 2 + 0.01), "wood.weathered", r: 0.0008)

        // One leaf: stiles, rails, mid muntin, four raised panels with ovolo sticking.
        func leaf(_ leafPaint: MaterialKey, bottom b: Float, top t: Float, rails: [(y: Float, h: Float)], panels: [(Float, Float)], cap: Bool) {
            let stile: Float = 0.1
            let hh = t - b
            for e: Float in [-1, 1] {
                FA.box(&m, V3(stile, hh, tl), V3(e * (lw / 2 - stile / 2), (b + t) / 2, zl + tl / 2), leafPaint, r: 0.0025)
            }
            for r in rails {
                FA.box(&m, V3(lw - 2 * stile + 0.004, r.h, tl * 0.94), V3(0, r.y, zl + tl / 2), leafPaint, r: 0.0025)
            }
            let iw = (lw - 3 * stile) / 2
            for (p0, p1) in panels {
                for e: Float in [-1, 1] {
                    let cx = e * (stile / 2 + iw / 2), cy = (p0 + p1) / 2, ph = p1 - p0
                    FA.box(&m, V3(iw + 0.012, ph + 0.012, 0.012), V3(cx, cy, zl + 0.006), leafPaint, r: 0.001)   // solid panel back
                    FJ.raisedPanel(&m, cx: cx, cy: cy, w: iw + 0.012, h: ph + 0.012, z0: zl + 0.012, rise: 0.016, bevelRun: 0.028, leafPaint)
                    FJ.mouldedFrame(&m, cx: cx, cy: cy, w: iw, h: ph, z: zfront - 0.012, profile: FJ.ovoloProfile(width: 0.012, height: 0.012), leafPaint, r: 0.006)
                    FA.box(&m, V3(iw + 0.012, ph + 0.012, 0.004), V3(cx, cy, zl + 0.002 + 0.0), leafPaint, r: 0.001)
                    FJ.mouldedFrame(&m, cx: cx, cy: cy, w: iw - 0.004, h: ph - 0.004, z: zl + 0.003, profile: FJ.ovoloProfile(width: 0.010, height: 0.010),
                                    leafPaint, r: 0.006, backFacing: true)
                }
            }
            FA.box(&m, V3(stile, hh - 2 * 0.1, tl * 0.94), V3(0, (b + t) / 2, zl + tl / 2), leafPaint, r: 0.0025)   // centre muntin
            if cap {   // shelf cap: rounded-over board overhanging the front
                m.add(Prim.extrude(Shape2D.rounded([V2(-0.012, 0), V2(0.040, 0), V2(0.040, 0.022), V2(-0.012, 0.022)], radius: 0.008, segments: 3),
                                   depth: lw + 0.02, bevel: 0.002, bevelSegments: 1, material: leafPaint),
                      Xform(translation: V3(0, t - 0.022, zl + 0.012 + 0.0), rotation: FA.q(-90, FA.Y)))
            }
        }
        let lowTop = ys - gap / 2, upBot = ys + gap / 2
        leaf(leafPaint, bottom: y0, top: lowTop, rails: [(y0 + 0.095, 0.19), (lowTop - 0.011 - 0.05, 0.1)],
             panels: [(y0 + 0.19, lowTop - 0.022 - 0.1)], cap: true)
        leaf(upperPaint, bottom: upBot, top: y1, rails: [(upBot + 0.05, 0.1), (y1 - 0.05, 0.1)], panels: [(upBot + 0.1, y1 - 0.1)], cap: false)

        // Strap hinges on pintles (hinge side at -x), two per leaf.
        let hx = -lw / 2
        for y in [y0 + 0.2, lowTop - 0.2, upBot + 0.2, y1 - 0.2] {
            FJ.strapHinge(&m, from: hx + 0.004, to: hx + 0.32, y: y, z: zfront, width: 0.03, thick: 0.004, iron, rng: &rng)
            FA.cylZ(&m, r: 0.006, h: tl + 0.012, at: V3(hx - 0.004, y, zl - 0.004), iron, bevel: 0.001, segments: 10)
        }
        // Suffolk thumb latches on the latch stile (+x): backplate, pull bar, thumb piece, keeper.
        for y in [lowTop - 0.255, upBot + 0.255] {
            let x = lw / 2 - 0.05
            FA.box(&m, V3(0.034, 0.17, 0.004), V3(x, y, zfront + 0.002), iron, r: 0.0012)
            FA.box(&m, V3(0.014, 0.12, 0.006), V3(x, y - 0.01, zfront + 0.0055), iron, r: 0.002)
            FA.box(&m, V3(0.012, 0.03, 0.004), V3(x, y + 0.078, zfront + 0.0065), iron, r: 0.0015, rot: FA.q(14, FA.Z))
            for dy: Float in [-0.075, 0.075] { rivet(&m, at: V3(x, y + dy, zfront + 0.004), normal: FA.Z, radius: 0.0045, material: iron) }
        }
        // Barrel bolt on the upper leaf bottom rail, bolt rod bridging into the lower leaf cap.
        FA.box(&m, V3(0.1, 0.026, 0.004), V3(-0.05, upBot + 0.04, zfront + 0.002), iron, r: 0.0012)
        FA.cylX(&m, r: 0.004, h: 0.085, at: V3(-0.09, upBot + 0.04, zfront + 0.0065), iron, bevel: 0.001, segments: 10)
        FA.ball(&m, r: 0.006, at: V3(-0.09, upBot + 0.04, zfront + 0.0045), iron)
        for dx: Float in [-0.085, -0.015] { rivet(&m, at: V3(dx, upBot + 0.04, zfront + 0.004), normal: FA.Z, radius: 0.004, material: iron) }
        // Brass kick plate on the lower leaf, screws and a dent.
        FA.box(&m, V3(lw - 0.17, 0.17, 0.0015), V3(0, y0 + 0.095, zfront + 0.00075), brass, r: 0.0006)
        for i in 0..<6 {
            let sx = -(lw - 0.17) / 2 + 0.014 + Float(i) * ((lw - 0.17 - 0.028) / 5)
            for sy: Float in [y0 + 0.018, y0 + 0.172] {
                rivet(&m, at: V3(sx, sy, zfront + 0.0015), normal: FA.Z, radius: 0.0032, segments: 6, material: "metal.screw-zinc")
            }
        }
        // Paint chips where hands, boots and weather reach: latch stiles, lower stile feet, shelf cap edge.
        var chipRng = rng.fork(7)
        FJ.chips(&m, spots: [V3(lw / 2 - 0.05, lowTop - 0.45, 0), V3(lw / 2 - 0.05, upBot + 0.5, 0), V3(-lw / 2 + 0.05, y0 + 0.30, 0),
                             V3(lw / 2 - 0.05, y0 + 0.30, 0), V3(0.12, lowTop - 0.07, 0), V3(-0.25, upBot + 0.05, 0)],
                 face: zfront, "wood.weathered", rng: &chipRng, each: 4)
        groundAO(&m, height: 0.12, floor: 0.7)
        return LODModel(FA.centerZ(m))
    }
}
