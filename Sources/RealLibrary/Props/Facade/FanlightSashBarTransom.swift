import simd
import Foundation

/// Regency fanlight, 1.1 m wide, 0.5 m tall, 100 mm deep: a painted pine semi-elliptical frame ring on a moulded transom
/// rail, nine radiating astragal bars from a central brass-capped hub, two concentric ring astragals, bar ends dowelled
/// into the frame, a single glass sheet held by a putty line and a keystone boss at the crown. Wear: crazed and
/// chipped paint on the rail, bare wood at the bar ends, dirt line above the rail, one glass lite with a lead patch.
public struct FanlightSashBarTransom: RealAsset {
    public static let id = "fanlight-sash-bar-transom"
    public static let summary = "Regency fanlight 1.1 m: radiating astragal bars, ring bar, transom rail, glazed."
    public static let tags = ["prop", "architecture", "facade", "trim", "wood"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 22, elevation: 6, distance: 2.0)

    /// Radiating bar count.
    public var bars: Int = 9
    /// Painted frame and bars.
    public var paint: MaterialKey = "wood.painted-exterior:CFCDBB"
    /// Worn paint on the exposed rail.
    public var worn: MaterialKey = "wood.trim-weathered"
    /// Glass.
    public var glass: MaterialKey = "glass.pane"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let A: Float = 0.55, B: Float = 0.415, cy: Float = 0.085, depth: Float = 0.088
        let fw: Float = 0.05                                                  // frame ring width
        let ai = A - fw, bi = B - fw
        let zg: Float = 0.044                                                 // glass plane

        // Transom rail with a mitred ovolo, bottom bead and a drip line.
        let rail: [V2] = [V2(0, 0), V2(depth, 0), V2(depth, 0.058), V2(depth - 0.012, 0.072), V2(depth - 0.034, cy - 0.001), V2(0, cy - 0.001)]
        FO.colX(&m, rail, x0: -A, x1: A, paint, bevel: 0.002)
        FO.colX(&m, [V2(depth - 0.004, 0.032), V2(depth + 0.006, 0.034), V2(depth + 0.006, 0.044), V2(depth - 0.004, 0.046)], x0: -A + 0.012, x1: A - 0.012, paint, bevel: 0.001)
        FJ.slab(&m, V3(2 * A - 0.02, 0.003, 0.004), V3(0, 0.0015, depth - 0.002), "wood.deadwood")

        // Frame ring (half ellipse), extruded the full depth.
        FM.prism(&m, FO.halfRing(outer: A, B, inner: ai, bi, cy: cy - 0.002), front: depth, depth: depth, paint, bevel: 0.0025)
        // Raised bead (ovolo) on the inside front edge of the ring.
        FM.prism(&m, FO.halfRing(outer: ai + 0.011, bi + 0.011, inner: ai, bi, cy: cy), front: depth + 0.005, depth: 0.012, paint, bevel: 0.0015)
        // Outer face stop bead around the ring, giving the frame a stepped section.
        FM.prism(&m, FO.halfRing(outer: A + 0.003, B + 0.003, inner: A - 0.012, B - 0.012, cy: cy - 0.002), front: depth - 0.02, depth: depth - 0.02, paint, bevel: 0.0015)

        // Glass sheet with a rebate and a putty line each side.
        FM.prism(&m, FO.halfDisc(ai + 0.004, bi + 0.004, cy: cy), front: zg + 0.002, depth: 0.004, glass, bevel: 0.0004)
        FM.prism(&m, FO.halfRing(outer: ai + 0.003, bi + 0.003, inner: ai - 0.007, bi - 0.007, cy: cy), front: zg + 0.0085, depth: 0.0065, "stone.limestone", bevel: 0.001)
        FM.prism(&m, FO.halfRing(outer: ai + 0.003, bi + 0.003, inner: ai - 0.007, bi - 0.007, cy: cy), front: zg - 0.0015, depth: 0.0065, "stone.limestone", bevel: 0.001)

        // Hub: stepped half-disc, brass boss, dowelled bar roots.
        FM.prism(&m, FO.halfDisc(0.075, 0.075, cy: cy), front: zg + 0.022, depth: 0.048, paint, bevel: 0.002)
        FM.prism(&m, FO.halfDisc(0.052, 0.052, cy: cy), front: zg + 0.030, depth: 0.012, "metal.brass-aged", bevel: 0.0015)
        FA.cylZ(&m, r: 0.016, h: 0.008, at: V3(0, cy + 0.0, zg + 0.030), "metal.brass-aged", bevel: 0.002, segments: 14)
        FC.bead(&m, r: 0.007, at: V3(0, cy + 0.0, zg + 0.04), "metal.brass", sub: 4)
        for k in 0..<7 {                                                      // petals around the boss
            let a = Float(k) / 6 * .pi
            FC.bead(&m, r: 0.005, at: V3(cos(a) * 0.039, cy + sin(a) * 0.039, zg + 0.0345), "metal.brass-aged", sub: 3)
        }

        // Radiating astragal bars: round-section rods from the hub to the inside of the ring, ends dowelled into the frame.
        for k in 1...bars {
            let t = Float(k) / Float(bars + 1) * .pi
            let p0 = V3(cos(t) * 0.07, cy + sin(t) * 0.07, zg)
            let p1 = V3(cos(t) * (ai + 0.004), cy + sin(t) * (bi + 0.004), zg)
            FA.rod(&m, p0, p1, r: 0.0072, paint, sides: 8)
            FC.bead(&m, r: 0.0058, at: p1, paint, sub: 3)
            // Pin head where the bar end meets the frame, on the front face.
            let pin = V3(cos(t) * (A - fw * 0.5), cy + sin(t) * (B - fw * 0.5), depth - 0.001)
            FO.peg(&m, at: pin, normal: FA.Z, r: 0.0042, h: 0.004, "wood.oak", sides: 6)
        }
        // Concentric ring astragals, rounded section.
        for s: Float in [0.46, 0.76] {
            var pts: [V3] = []
            for i in 0...36 { let t = Float(i) / 36 * .pi; pts.append(V3(cos(t) * (ai + 0.004) * s, cy + sin(t) * (bi + 0.004) * s, zg)) }
            FA.path(&m, pts, r: 0.0068, paint, sides: 8)
        }

        // Keystone boss at the crown.
        let top = cy + B
        FA.box(&m, V3(0.062, 0.07, 0.012), V3(0, top - 0.026, depth + 0.002), paint, r: 0.003)
        FA.box(&m, V3(0.04, 0.045, 0.006), V3(0, top - 0.026, depth + 0.0085), paint, r: 0.002)
        FA.cylZ(&m, r: 0.013, h: 0.006, at: V3(0, top - 0.026, depth + 0.011), "metal.brass-aged", bevel: 0.002, segments: 12)

        // Wear: paint chips to bare pine on the rail, hairline crazing, grime above the rail, water streaks from the crown.
        FJ.chips(&m, spots: [V3(-0.38, 0.03, 0), V3(0.12, 0.052, 0), V3(0.44, 0.02, 0), V3(-0.12, 0.01, 0)], face: depth, "wood.pine-aged", rng: &rng, each: 4)
        for _ in 0..<8 {
            FO.patch(&m, V2(0.0014, rng.float(0.01...0.03)), V2(rng.float(-0.5...0.5), rng.float(0.018...0.058)), z: depth, "wood.deadwood", rot: rng.float(-12...12))
        }
        FO.patch(&m, V2(2 * A - 0.06, 0.012), V2(0, 0.006), z: depth, "stone.limestone-sooted")
        for _ in 0..<6 {
            let t = rng.float(0.15...0.85) * .pi
            FO.patch(&m, V2(rng.float(0.006...0.012), rng.float(0.02...0.06)), V2(cos(t) * (A - fw / 2), cy + sin(t) * (B - fw / 2)), z: depth, worn, rot: Float(t * 180 / .pi) - 90)
        }
        // Flaking paint where rain sits: both frame feet, the rail top and the bar roots near the hub.
        for e: Float in [-1, 1] {
            for _ in 0..<5 {
                FO.patch(&m, V2(rng.float(0.01...0.03), rng.float(0.01...0.03)), V2(e * (A - fw * 0.5) + rng.float(-0.015...0.015), cy + rng.float(0.01...0.1)), z: depth, rng.chance(0.5) ? "wood.pine-aged" : worn, rot: rng.float(-30...30))
            }
            FO.patch(&m, V2(0.05, 0.1), V2(e * (A - fw * 0.5), cy + 0.06), z: depth, "stone.limestone-sooted")
        }
        for _ in 0..<7 {
            FO.patch(&m, V2(rng.float(0.02...0.06), rng.float(0.008...0.02)), V2(rng.float(-0.5...0.5), rng.float(0.01...0.05)), z: depth, rng.chance(0.5) ? worn : "wood.pine-aged", rot: rng.float(-8...8))
        }
        for _ in 0..<6 {
            FJ.slab(&m, V3(rng.float(0.03...0.09), 0.0012, 0.03), V3(rng.float(-0.45...0.45), cy - 0.0004, rng.float(0.03...0.07)), rng.chance(0.5) ? "wood.pine-aged" : "stone.limestone-sooted")
        }
        // Dirt run down the glass below the crown boss.
        FO.patch(&m, V2(0.014, 0.16), V2(-0.01, cy + 0.2), z: zg + 0.0042, "stone.limestone-sooted")
        // One lite patched with lead cames behind a crack line.
        FO.patch(&m, V2(0.05, 0.002), V2(0.22, cy + 0.16), z: zg + 0.0042, "metal.tinned-copper", rot: -25)
        FO.patch(&m, V2(0.03, 0.0016), V2(0.236, cy + 0.15), z: zg + 0.0042, "metal.tinned-copper", rot: 35)

        groundAO(&m, height: 0.1, floor: 0.7)
        return LODModel(FC.place(m))
    }
}
