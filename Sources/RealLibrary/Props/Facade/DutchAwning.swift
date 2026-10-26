import simd
import Foundation

/// Dutch awning, 2 m wide: a fixed sloped hood of burgundy and cream striped canvas stretched over welded
/// steel-pipe rafters, closed quadrilateral end panels bound with welt cord, a straight valance with a
/// weight-pocket hem, a galvanized cap flashing along the wall, rafter shoe plates lagged to an angle rail
/// and a pipe front bar. Sun-faded toward one end, sooty near the wall, one stitched repair on the valance.
public struct DutchAwning: RealAsset {
    public static let id = "dutch-awning"
    public static let summary = "Dutch (waterfall) awning, 2 m wide: sloped fixed canvas hood with closed triangular side ends on a welded steel pipe frame."
    public static let tags = ["prop", "architecture", "facade", "metal", "fabric"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 12, distance: 2.0, studio: true)

    /// Awning width along the wall (m).
    public var width: Float = 2.0
    /// Horizontal projection of the hood (m).
    public var projection: Float = 0.88
    /// Overall height at the wall (m).
    public var crown: Float = 0.80
    /// Valance drop (m).
    public var valance: Float = 0.2
    /// Canvas stripe colours (sRGB hex).
    public var stripeA: UInt32 = 0x55141F
    public var stripeB: UInt32 = 0xE6DFCB
    public var pipe: MaterialKey = "metal.galvanized"
    public var iron: MaterialKey = "metal.wrought-iron"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = width, vd = valance
        let front: Float = projection + 0.012
        let top = V2(0.012, crown - 0.045)
        let hoodEnd = V2(front, vd)
        func lerp(_ t: Float) -> V2 { top + (hoodEnd - top) * t }
        let n = 10
        // Hood in two cut panels with a cross seam; fade grows toward the +X end.
        let cuts: [Float] = [0, 0.52, 1]
        let sw = W / Float(n)
        for k in 0..<2 {
            let c = (0...4).map { lerp(cuts[k] + (cuts[k + 1] - cuts[k]) * Float($0) / 4) }
            for i in 0..<n {
                let x0 = -W / 2 + sw * Float(i)
                let fade = 0.0 + 0.2 * Float(i) / Float(n - 1) + (k == 0 ? 0.06 : 0)
                let dirt: Float = k == 0 ? 0.28 : 0.1
                let mat = FSH.jitter(FSH.canvas(i % 2 == 0 ? stripeA : stripeB, fade: i % 2 == 0 ? fade : fade * 0.3, dirt: i % 2 == 0 ? dirt * 0.8 : dirt * 1.3), i * 3 + k)
                FSH.strip(&m, c, thick: 0.004, x0: x0 + 0.0006, x1: x0 + sw - 0.0006, mat)
                if i > 0 { FSH.strip(&m, c, thick: 0.0064, x0: x0 - 0.004, x1: x0 + 0.004, FSH.canvas(stripeB, dirt: 0.2 + 0.1 * Float(k))) }
            }
        }
        // Cross seam welt.
        let seam = lerp(0.52)
        FA.rod(&m, V3(-W / 2, seam.y + 0.004, seam.x), V3(W / 2, seam.y + 0.004, seam.x), r: 0.0032, FSH.canvas(stripeB, dirt: 0.3), sides: 6)
        // Valance: straight drop with vertical stripes and a sooty weight-pocket hem.
        let vc = [V2(front, vd + 0.002), V2(front, 0.045)]
        for i in 0..<n {
            let x0 = -W / 2 + sw * Float(i)
            let mat = FSH.jitter(FSH.canvas(i % 2 == 0 ? stripeA : stripeB, fade: 0.05, dirt: 0.15), i * 5)
            FSH.strip(&m, vc, thick: 0.004, x0: x0 + 0.0006, x1: x0 + sw - 0.0006, mat)
        }
        FSH.strip(&m, [V2(front, 0.045), V2(front, 0.0)], thick: 0.005, x0: -W / 2, x1: W / 2, FSH.canvas(stripeA, dirt: 0.4))
        FA.rod(&m, V3(-W / 2, 0.012, front + 0.0055), V3(W / 2, 0.012, front + 0.0055), r: 0.005, FSH.canvas(stripeA, dirt: 0.45), sides: 8)
        // Binding tape where valance meets hood.
        FA.rod(&m, V3(-W / 2, vd + 0.0035, front + 0.0055), V3(W / 2, vd + 0.0035, front + 0.0055), r: 0.0055, FSH.canvas(stripeB, dirt: 0.25), sides: 8)
        FSH.patch(&m, cx: -0.43, cy: 0.12, w: 0.17, h: 0.09, z: front + 0.004, FSH.canvas(stripeB, dirt: 0.05), thread: "fabric.canvas:4F3A32")
        // Closed end panels (quadrilateral) with welt binding and a vertical pipe-seam.
        let end: [V2] = [V2(0.012, crown - 0.045), hoodEnd, V2(front, 0.0), V2(0.012, 0.0)]
        for e: Float in [-1, 1] {
            let x = e * (W / 2 - 0.0035)
            m.add(Prim.extrude(end, depth: 0.004, bevel: 0.0005, bevelSegments: 1, material: FSH.canvas(stripeA, fade: 0.05 + 0.2 * (e + 1) / 2, dirt: 0.25)),
                  Xform(translation: V3(x, 0, 0), rotation: FA.q(-90, FA.Y)))
            let s = e * (W / 2 + 0.0004)
            let w = FSH.canvas(stripeB, dirt: 0.28)
            FA.path(&m, [V3(s, end[0].y + 0.002, end[0].x + 0.004), V3(s, end[1].y + 0.002, end[1].x - 0.002), V3(s, 0.004, end[2].x - 0.002), V3(s, 0.004, end[3].x + 0.004)], r: 0.0035, w, sides: 6)
            // end seam: a tailored dart line
            FA.rod(&m, V3(s, 0.03, end[3].x + 0.012), V3(s, end[0].y - 0.03, end[3].x + 0.012), r: 0.0025, w, sides: 5)
        }
        // Frame under the canvas: rafters, purlins, front bar, bottom hoop.
        let r: Float = 0.0095
        let inT = FSH.offset([top, hoodEnd], -0.012)
        for i in 0..<6 {
            let x = -W / 2 + 0.03 + (W - 0.06) * Float(i) / 5
            FA.rod(&m, V3(x, inT[0].y, inT[0].x), V3(x, inT[1].y, inT[1].x), r: r, pipe)
            FA.rod(&m, V3(x, inT[1].y, inT[1].x), V3(x, 0.03, front - 0.016), r: r * 0.85, pipe)
            FA.box(&m, V3(0.03, 0.05, 0.006), V3(x, crown - 0.075, 0.012 + 0.004), iron, r: 0.002)   // shoe plate
        }
        for t: Float in [0.25, 0.5, 0.75] {
            let p = inT[0] + (inT[1] - inT[0]) * t
            FA.rod(&m, V3(-W / 2 + 0.02, p.y, p.x), V3(W / 2 - 0.02, p.y, p.x), r: 0.0065, iron, sides: 6)
        }
        FA.rod(&m, V3(-W / 2 + 0.015, 0.03, front - 0.016), V3(W / 2 - 0.015, 0.03, front - 0.016), r: 0.0125, pipe, sides: 10)
        FA.rod(&m, V3(-W / 2 + 0.015, 0.025, 0.04), V3(W / 2 - 0.015, 0.025, 0.04), r: 0.008, iron, sides: 8)
        for e: Float in [-1, 1] { FA.rod(&m, V3(e * (W / 2 - 0.015), 0.03, front - 0.016), V3(e * (W / 2 - 0.015), 0.025, 0.04), r: 0.008, iron, sides: 8) }
        // Wall angle rail, cap flashing and lag bolts.
        FA.box(&m, V3(W + 0.02, 0.06, 0.006), V3(0, crown - 0.04, 0.003), iron, r: 0.0015)
        FA.box(&m, V3(W + 0.02, 0.005, 0.05), V3(0, crown - 0.07, 0.025), iron, r: 0.0015)
        FA.box(&m, V3(W + 0.016, 0.006, 0.034), V3(0, crown + 0.0, 0.018), pipe, r: 0.0015, rot: FA.q(-4, FA.X))
        FSH.boltRow(&m, xs: (0..<7).map { -W / 2 + 0.06 + (W - 0.12) * Float($0) / 6 }, y: crown - 0.04, z: 0.007, r: 0.0065, "metal.rust")
        _ = rng.float()
        groundAO(&m, height: 0.1, floor: 0.8)
        return LODModel(FA.centerZ(m))
    }
}
