import simd
import Foundation

/// Victorian window awning, 1.8 m wide: a sloped navy and cream striped canvas roof on a pipe-and-strap
/// frame with scrolled iron side arms, bound side edges, and a scalloped drop valance (one scallop per
/// stripe) hung from a front bar with brass snaps and contrast binding round every scallop. Roof faded and
/// sooty, valance hem stained by splash, rust bleeding from the arm plates.
public struct ScallopedValanceAwning: RealAsset {
    public static let id = "scalloped-valance-awning"
    public static let summary = "Victorian window awning, 1.8 m wide: sloped striped canvas with a scalloped drop valance hung from a front bar and wall rail."
    public static let tags = ["prop", "architecture", "facade", "trim", "fabric", "metal"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 12, distance: 2.0, studio: true)

    /// Awning width along the wall (m).
    public var width: Float = 1.8
    /// Horizontal projection of the roof (m).
    public var projection: Float = 1.08
    /// Height of the roof at the wall (m).
    public var crown: Float = 0.9
    /// Straight part of the valance (m); scallops add `scallop` below it.
    public var valanceDrop: Float = 0.22
    public var scallop: Float = 0.12
    /// Canvas stripe colours (sRGB hex).
    public var stripeA: UInt32 = 0x1F3C68
    public var stripeB: UInt32 = 0xE6DFCB
    public var pipe: MaterialKey = "metal.galvanized"
    public var iron: MaterialKey = "metal.wrought-iron"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = width, front: Float = projection + 0.012
        let vTop = valanceDrop + scallop
        let top = V2(0.012, crown - 0.04), lip = V2(front, vTop)
        let n = 12, sw = W / Float(n)
        // Roof: two cut panels per stripe with a cross seam.
        for k in 0..<2 {
            let t0: Float = k == 0 ? 0 : 0.5, t1: Float = k == 0 ? 0.5 : 1
            let c = (0...3).map { top + (lip - top) * (t0 + (t1 - t0) * Float($0) / 3) }
            for i in 0..<n {
                let x0 = -W / 2 + sw * Float(i)
                let dirt: Float = k == 0 ? 0.3 : 0.1
                let fade: Float = k == 0 ? 0.18 : 0.06
                let mat = FSH.jitter(FSH.canvas(i % 2 == 0 ? stripeA : stripeB, fade: i % 2 == 0 ? fade : fade * 0.3, dirt: i % 2 == 0 ? dirt * 0.8 : dirt * 1.2), i * 3 + k)
                FSH.strip(&m, c, thick: 0.004, x0: x0 + 0.0006, x1: x0 + sw - 0.0006, mat)
                if i > 0 { FSH.strip(&m, c, thick: 0.0062, x0: x0 - 0.0035, x1: x0 + 0.0035, FSH.canvas(stripeB, dirt: 0.25)) }
            }
        }
        let mid = top + (lip - top) * 0.5
        FA.rod(&m, V3(-W / 2, mid.y + 0.004, mid.x), V3(W / 2, mid.y + 0.004, mid.x), r: 0.003, FSH.canvas(stripeB, dirt: 0.25), sides: 6)
        // Bound side edges and front piping over the bar.
        for e: Float in [-1, 1] {
            FA.rod(&m, V3(e * (W / 2 - 0.001), top.y + 0.004, top.x), V3(e * (W / 2 - 0.001), lip.y + 0.004, lip.x), r: 0.0048, FSH.canvas(stripeB, dirt: 0.2), sides: 6)
        }
        FA.rod(&m, V3(-W / 2, lip.y + 0.006, front + 0.002), V3(W / 2, lip.y + 0.006, front + 0.002), r: 0.0068, FSH.canvas(stripeB, dirt: 0.18), sides: 8)
        // Scalloped valance: one scallop per stripe, outline = straight top + semi-elliptical hem.
        let sd = scallop
        for i in 0..<n {
            let x0 = -W / 2 + sw * Float(i), x1 = x0 + sw
            var o: [V2] = [V2(x0 + 0.0006, vTop), V2(x1 - 0.0006, vTop), V2(x1 - 0.0006, sd)]
            let steps = 9
            var arcPts: [V3] = []
            for s in 1..<steps {
                let a = Float(s) / Float(steps) * .pi
                let p = V2((x0 + x1) / 2 + cos(a) * (sw / 2 - 0.0006), sd - sin(a) * sd)
                o.append(p)
                arcPts.append(V3(p.x, p.y, 0))
            }
            o.append(V2(x0 + 0.0006, sd))
            let hemDirt: Float = (i == 4 || i == 5) ? 0.5 : 0.22
            let key = FSH.jitter(FSH.canvas(i % 2 == 0 ? stripeA : stripeB, fade: 0.06, dirt: hemDirt * 0.7), i * 7)
            m.add(Prim.extrude(o, depth: 0.004, bevel: 0.0004, bevelSegments: 1, material: key),
                  Xform(translation: V3(0, 0, front + 0.006)))
            // Contrast binding round the scallop (cream on navy, navy on cream).
            let bind = FSH.canvas(i % 2 == 0 ? stripeB : stripeA, dirt: 0.3 + hemDirt * 0.4)
            FA.path(&m, [V3(x1 - 0.003, sd, front + 0.0085)] + arcPts.map { V3($0.x, $0.y - 0.001, front + 0.0085) } + [V3(x0 + 0.003, sd, front + 0.0085)], r: 0.0034, bind, sides: 4)
            // Brass snap at the top of each panel.
            FA.cylZ(&m, r: 0.0048, h: 0.0022, at: V3((x0 + x1) / 2, vTop - 0.022, front + 0.0095), "metal.brass-aged", bevel: 0.0006, segments: 8)
        }
        FSH.patch(&m, cx: 0.36, cy: vTop - 0.08, w: 0.09, h: 0.075, z: front + 0.0095, FSH.canvas(stripeB, dirt: 0.05), thread: "fabric.canvas:3D3C4A")
        // Frame: front bar, rafters, cross strap, scrolled side arms, wall rail.
        let inT = FSH.offset([top, lip], -0.012)
        FA.rod(&m, V3(-W / 2 + 0.015, lip.y - 0.012, front - 0.01), V3(W / 2 - 0.015, lip.y - 0.012, front - 0.01), r: 0.0125, pipe, sides: 10)
        for i in 0..<5 {
            let x = -W / 2 + 0.05 + (W - 0.1) * Float(i) / 4
            FA.rod(&m, V3(x, inT[0].y, inT[0].x), V3(x, inT[1].y, inT[1].x), r: 0.0085, pipe)
            FA.box(&m, V3(0.028, 0.05, 0.006), V3(x, crown - 0.07, 0.016), iron, r: 0.002)
        }
        for t: Float in [0.33, 0.66] {
            let p = inT[0] + (inT[1] - inT[0]) * t
            FA.rod(&m, V3(-W / 2 + 0.02, p.y, p.x), V3(W / 2 - 0.02, p.y, p.x), r: 0.0062, iron, sides: 6)
        }
        for e: Float in [-1, 1] {
            let x = e * (W / 2 - 0.004)
            // Arm: down from the wall plate in a concave curve to the bar, plus a scroll curl beneath the roof.
            var arm: [V3] = []
            for s in 0...10 {
                let t = Float(s) / 10
                let y = crown - 0.2 - (crown - 0.2 - (lip.y - 0.03)) * (t * t * 0.55 + t * 0.45)
                arm.append(V3(x, y, 0.016 + (front - 0.03) * t))
            }
            FA.path(&m, arm, r: 0.0075, iron, sides: 6)
            var curl: [V3] = []
            let cz: Float = 0.12, cy = crown - 0.2 - 0.14
            for s in 0...16 {
                let a = Float(s) / 16 * 2.4 * .pi, rad = 0.005 + 0.052 * (1 - Float(s) / 16)
                curl.append(V3(x, cy + sin(a) * rad, cz + cos(a) * rad * 1.1))
            }
            FA.path(&m, curl, r: 0.0055, iron, sides: 6)
            FA.box(&m, V3(0.007, 0.16, 0.05), V3(x, crown - 0.12, 0.025), iron, r: 0.0015)
            for dy: Float in [-0.05, 0.05] { FA.ball(&m, r: 0.006, at: V3(x + e * 0.006, crown - 0.12 + dy, 0.04), "metal.rust") }
            FA.ball(&m, r: 0.015, at: V3(x, lip.y - 0.03, front - 0.03), iron)
            // rust bleed down the wall plate
            FA.box(&m, V3(0.0016, 0.07, 0.014), V3(x - e * 0.004, crown - 0.22, 0.02), "metal.rust-grime", r: 0.0004)
        }
        FA.box(&m, V3(W + 0.02, 0.06, 0.006), V3(0, crown - 0.04, 0.003), iron, r: 0.0015)
        FA.box(&m, V3(W + 0.02, 0.005, 0.04), V3(0, crown - 0.068, 0.02), iron, r: 0.0015)
        FSH.boltRow(&m, xs: (0..<6).map { -W / 2 + 0.06 + (W - 0.12) * Float($0) / 5 }, y: crown - 0.04, z: 0.007, r: 0.0065, "metal.rust")
        _ = rng.float()
        groundAO(&m, height: 0.1, floor: 0.8)
        return LODModel(FA.centerZ(m))
    }
}
