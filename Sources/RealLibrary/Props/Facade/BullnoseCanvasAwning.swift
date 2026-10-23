import simd
import Foundation

/// Victorian bullnose shop awning, 2 m wide: a quarter-round dome of striped canvas stretched over bent
/// steel-pipe hoops and purlins, a hemmed valance with a cream trim band and rolled welt, brass lacing
/// eyelets with a zig-zag cord, a pipe front bar with ball finials, and an angle-iron wall rail lagged to
/// the wall with diagonal flat-bar braces. Forest-green canvas, bleached at the crown, sooty near the wall.
public struct BullnoseCanvasAwning: RealAsset {
    public static let id = "bullnose-canvas-awning"
    public static let summary = "Victorian bullnose shop awning, 2 m wide: quarter-round canvas dome on a bent iron-pipe frame with boxed valance and wall rail."
    public static let tags = ["prop", "architecture", "facade", "trim", "metal", "fabric"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 12, distance: 2.0, studio: true)

    /// Awning width along the wall (m).
    public var width: Float = 2.0
    /// Horizontal projection of the dome (m).
    public var projection: Float = 0.94
    /// Height of the crown at the wall (m).
    public var crown: Float = 0.90
    /// Valance drop below the dome (m).
    public var valance: Float = 0.2
    /// Canvas stripe colours (sRGB hex).
    public var stripeA: UInt32 = 0x214A3C
    public var stripeB: UInt32 = 0xE2DAC4
    public var pipe: MaterialKey = "metal.galvanized"
    public var iron: MaterialKey = "metal.wrought-iron"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = width, P = projection, vd = valance
        let ry = crown - vd
        let dome = FSH.arc(cz: 0.012, cy: vd, rz: P, ry: ry, from: 0, to: 90, steps: 15)
        // Sections cut like real panels: crown, shoulder, front, then valance and trim band.
        let sec: [(Int, Int)] = [(0, 5), (5, 10), (10, 15)]
        let n = 12
        for (k, s) in sec.enumerated() {
            let part = Array(dome[s.0...s.1])
            let fade: Float = [0.32, 0.14, 0.02][k], dirt: Float = [0.25, 0.08, 0.14][k]
            let a = FSH.canvas(stripeA, fade: fade + rng.float(0...0.04), dirt: dirt), b = FSH.canvas(stripeB, fade: fade * 0.4, dirt: dirt * 1.2)
            FSH.stripes(&m, part, thick: 0.004, width: W, count: n, a, b, seam: FSH.canvas(stripeB, dirt: 0.2))
        }
        let front = dome.last!.x
        let band: Float = 0.04
        let val = [V2(front, vd + 0.002), V2(front, band)]
        let trim = [V2(front, band), V2(front, 0.0)]
        FSH.stripes(&m, val, thick: 0.004, width: W, count: n, FSH.canvas(stripeA, dirt: 0.22), FSH.canvas(stripeB, dirt: 0.2), seam: FSH.canvas(stripeB, dirt: 0.2))
        FSH.strip(&m, trim, thick: 0.0045, x0: -W / 2, x1: W / 2, FSH.canvas(stripeB, dirt: 0.5))
        // Rolled welt along the hem and both side edges.
        FA.rod(&m, V3(-W / 2, 0.004, front + 0.004), V3(W / 2, 0.004, front + 0.004), r: 0.006, FSH.canvas(stripeB, dirt: 0.25), sides: 8)
        for e: Float in [-1, 1] {
            FSH.hoop(&m, dome.map { $0 + V2(0.004, 0.0) }, x: e * (W / 2 - 0.002), r: 0.0045, FSH.canvas(stripeB, dirt: 0.15), sides: 6)
            FA.rod(&m, V3(e * (W / 2 - 0.002), 0.0, front + 0.004), V3(e * (W / 2 - 0.002), vd, front + 0.004), r: 0.0045, FSH.canvas(stripeB, dirt: 0.15), sides: 6)
        }
        // Brass lacing eyelets along the trim band with a zig-zag cord.
        var cord: [V3] = []
        let ne = 15
        for i in 0..<ne {
            let x = -W / 2 + 0.1 + (W - 0.2) * Float(i) / Float(ne - 1)
            FA.cylZ(&m, r: 0.0055, h: 0.0022, at: V3(x, 0.095, front + 0.0046), "metal.brass-aged", bevel: 0.0007, segments: 8)
            cord.append(V3(x, i % 2 == 0 ? 0.092 : 0.128, front + 0.011))
        }
        FA.path(&m, cord, r: 0.0022, "fabric.linen:E3D9BC", sides: 5)
        // Sewn repair patch on a cream valance stripe and verdigris drips under the eyelets.
        FSH.patch(&m, cx: 0.52, cy: 0.13, w: 0.15, h: 0.085, z: front + 0.004, FSH.canvas(stripeB, dirt: 0.02), thread: "fabric.canvas:5B5444")
        for i in 0..<ne where i % 2 == 0 {
            let x = -W / 2 + 0.1 + (W - 0.2) * Float(i) / Float(ne - 1)
            FA.box(&m, V3(0.006, 0.03 + rng.float(0...0.02), 0.0008), V3(x, 0.07, front + 0.0044), "fabric.canvas:6C7A5C", r: 0.0002)
        }
        // Frame under the canvas: pipe hoops, purlins, front bar.
        let inner = FSH.offset(dome, -0.014)
        let hoopX: [Float] = (0..<7).map { -W / 2 + 0.04 + (W - 0.08) * Float($0) / 6 }
        for x in hoopX { FSH.hoop(&m, inner, x: x, r: 0.0105, pipe, sides: 8) }
        for i in [2, 4, 6, 8, 10, 12, 14] {
            FA.rod(&m, V3(-W / 2 + 0.03, inner[i].y, inner[i].x), V3(W / 2 - 0.03, inner[i].y, inner[i].x), r: 0.0065, iron, sides: 6)
        }
        let barY = vd - 0.006
        FA.rod(&m, V3(-W / 2 - 0.008, barY, front - 0.014), V3(W / 2 + 0.008, barY, front - 0.014), r: 0.0135, pipe, sides: 10)
        for e: Float in [-1, 1] { FA.ball(&m, r: 0.0185, at: V3(e * (W / 2 + 0.014), barY, front - 0.014), iron) }
        // Wall rail: angle iron with lag bolts, plus flat-bar braces at both ends.
        FA.box(&m, V3(W + 0.02, 0.05, 0.006), V3(0, crown - 0.012, 0.003), iron, r: 0.0015)
        FA.box(&m, V3(W + 0.02, 0.006, 0.045), V3(0, crown - 0.037, 0.0225), iron, r: 0.0015)
        FSH.boltRow(&m, xs: (0..<7).map { -W / 2 + 0.05 + (W - 0.1) * Float($0) / 6 }, y: crown - 0.012, z: 0.007, r: 0.0065, "metal.rust")
        for e: Float in [-1, 1] {
            let x = e * (W / 2 + 0.006)
            FA.box(&m, V3(0.006, 0.07, 0.006), V3(x, crown * 0.52, 0.003), iron, r: 0.001)
            FA.rod(&m, V3(x, crown * 0.52, 0.01), V3(x, barY, front - 0.014), r: 0.0055, iron, sides: 6)
            FA.cylX(&m, r: 0.0065, h: 0.004, at: V3(x, crown * 0.52, 0.012), iron, bevel: 0.0007, segments: 8)
        }
        groundAO(&m, height: 0.1, floor: 0.8)
        return LODModel(FA.centerZ(m))
    }
}
