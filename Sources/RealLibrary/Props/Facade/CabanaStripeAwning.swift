import simd
import Foundation

/// Resort cabana awning, 2.4 m wide: a pitched roof of wide aqua and white acrylic stripes over brushed
/// aluminium rafters and a powder-white front bar, a valance with a gently wavy hem and rope piping, and
/// natural-rope tie-backs with tassel balls at both ends. Salt-faded and chalky at the crown, stained at
/// the hem, aluminium pitted at the wall channel, one white stripe sun-yellowed.
public struct CabanaStripeAwning: RealAsset {
    public static let id = "cabana-stripe-awning"
    public static let summary = "Resort cabana awning, 2.4 m wide: bold-striped canvas on a pitched pipe frame with wavy-edge valance and rope tie-backs."
    public static let tags = ["prop", "architecture", "facade", "fabric", "metal"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 12, distance: 2.4, studio: true)

    /// Awning width along the wall (m).
    public var width: Float = 2.4
    /// Horizontal projection of the roof (m).
    public var projection: Float = 1.18
    /// Roof height at the wall (m).
    public var crown: Float = 0.9
    /// Straight valance height (m) and hem wave amplitude (m).
    public var valanceDrop: Float = 0.2
    public var wave: Float = 0.03
    /// Canvas stripe colours (sRGB hex).
    public var stripeA: UInt32 = 0x1F6F8B
    public var stripeB: UInt32 = 0xF0EBDD
    public var alu: MaterialKey = "metal.aluminum-brushed"
    public var frame: MaterialKey = "metal.powder-white"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = width, front: Float = projection + 0.012
        let vTop = valanceDrop + 2 * wave
        let top = V2(0.012, crown - 0.04), lip = V2(front, vTop)
        let n = 8, sw = W / Float(n)
        for k in 0..<2 {
            let t0: Float = k == 0 ? 0 : 0.55, t1: Float = k == 0 ? 0.55 : 1
            let c = (0...3).map { top + (lip - top) * (t0 + (t1 - t0) * Float($0) / 3) }
            for i in 0..<n {
                let x0 = -W / 2 + sw * Float(i)
                let dirt: Float = k == 0 ? 0.22 : 0.08
                let fade: Float = k == 0 ? 0.22 : 0.08
                let yellow: Float = (i == 5 && k == 1) ? 0.3 : 0
                let mat = FSH.jitter(FSH.canvas(i % 2 == 0 ? stripeA : stripeB, fade: i % 2 == 0 ? fade : fade * 0.3, dirt: i % 2 == 0 ? dirt * 0.8 : dirt * 1.1 + yellow), i * 3 + k)
                FSH.strip(&m, c, thick: 0.004, x0: x0 + 0.0006, x1: x0 + sw - 0.0006, mat)
                if i > 0 { FSH.strip(&m, c, thick: 0.0062, x0: x0 - 0.0035, x1: x0 + 0.0035, FSH.canvas(stripeB, dirt: 0.25)) }
            }
        }
        let mid = top + (lip - top) * 0.55
        FA.rod(&m, V3(-W / 2, mid.y + 0.004, mid.x), V3(W / 2, mid.y + 0.004, mid.x), r: 0.003, FSH.canvas(stripeB, dirt: 0.25), sides: 6)
        for e: Float in [-1, 1] {
            FA.rod(&m, V3(e * (W / 2 - 0.001), top.y + 0.004, top.x), V3(e * (W / 2 - 0.001), lip.y + 0.004, lip.x), r: 0.005, FSH.canvas(stripeB, dirt: 0.2), sides: 6)
        }
        // Rope piping over the front bar.
        FA.rod(&m, V3(-W / 2, lip.y + 0.006, front + 0.002), V3(W / 2, lip.y + 0.006, front + 0.002), r: 0.0075, "fabric.burlap:B59A6A", sides: 8)
        // Valance with wavy hem, one panel per stripe, rope welt along the hem.
        let lam = sw
        func hem(_ x: Float) -> Float { wave * (1 + sin(2 * .pi * x / lam)) }
        var hemPath: [V3] = []
        for i in 0..<n {
            let x0 = -W / 2 + sw * Float(i), x1 = x0 + sw
            var o: [V2] = [V2(x0 + 0.0006, vTop), V2(x1 - 0.0006, vTop)]
            let steps = 8
            for s in 0...steps {
                let x = x1 - 0.0006 - (sw - 0.0012) * Float(s) / Float(steps)
                let p = V2(x, hem(x))
                o.append(p)
                hemPath.append(V3(x, hem(x) + 0.003, front + 0.0085))
            }
            let dirt: Float = (i == 2 || i == 3) ? 0.45 : 0.18
            let key = FSH.jitter(FSH.canvas(i % 2 == 0 ? stripeA : stripeB, fade: 0.08, dirt: dirt * (i % 2 == 0 ? 0.7 : 1.1)), i * 7)
            m.add(Prim.extrude(o, depth: 0.004, bevel: 0, bevelSegments: 1, material: key), Xform(translation: V3(0, 0, front + 0.006)))
        }
        FA.path(&m, hemPath.reversed(), r: 0.0036, "fabric.burlap:A88F62", sides: 4)
        // Brass grommets with rope loops at the top of each panel.
        for i in 0..<n {
            let x = -W / 2 + sw * (Float(i) + 0.5)
            FA.cylZ(&m, r: 0.0065, h: 0.0022, at: V3(x, vTop - 0.026, front + 0.0095), "metal.brass-aged", bevel: 0.0006, segments: 8)
        }
        // Frame: aluminium channel, rafters, front bar with end caps.
        let inT = FSH.offset([top, lip], -0.012)
        FA.rod(&m, V3(-W / 2 + 0.015, lip.y - 0.012, front - 0.01), V3(W / 2 - 0.015, lip.y - 0.012, front - 0.01), r: 0.0135, frame, sides: 10)
        for e: Float in [-1, 1] { FC.bead(&m, r: 0.0165, at: V3(e * (W / 2 - 0.012), lip.y - 0.012, front - 0.01), frame, sub: 4) }
        for i in 0..<7 {
            let x = -W / 2 + 0.05 + (W - 0.1) * Float(i) / 6
            FA.rod(&m, V3(x, inT[0].y, inT[0].x), V3(x, inT[1].y, inT[1].x), r: 0.009, alu, sides: 7)
            FA.box(&m, V3(0.03, 0.05, 0.006), V3(x, crown - 0.075, 0.016), alu, r: 0.002)
            hexBolt(&m, at: V3(x, crown - 0.075, 0.021), normal: FA.Z, size: 0.012, material: "metal.screw-zinc")
        }
        for t: Float in [0.3, 0.62] {
            let p = inT[0] + (inT[1] - inT[0]) * t
            FA.rod(&m, V3(-W / 2 + 0.02, p.y, p.x), V3(W / 2 - 0.02, p.y, p.x), r: 0.0065, alu, sides: 6)
        }
        FA.box(&m, V3(W + 0.02, 0.07, 0.007), V3(0, crown - 0.045, 0.0035), alu, r: 0.0015)
        FA.box(&m, V3(W + 0.02, 0.006, 0.04), V3(0, crown - 0.078, 0.02), alu, r: 0.0015)
        FSH.boltRow(&m, xs: (0..<6).map { -W / 2 + 0.06 + (W - 0.12) * Float($0) / 5 }, y: crown - 0.045, z: 0.0075, r: 0.0065, "metal.screw-zinc")
        // Rope tie-backs: loop from the wall plate over the roof side to a knot with tassel at the front corner.
        for e: Float in [-1, 1] {
            let x = e * (W / 2 + 0.002)
            var rope: [V3] = []
            for s in 0...10 {
                let t = Float(s) / 10
                let sag = -0.07 * sin(t * .pi)
                rope.append(V3(x, (crown - 0.18) + (lip.y - 0.03 - (crown - 0.18)) * t + sag, 0.03 + (front - 0.04) * t))
            }
            FA.path(&m, rope, r: 0.0055, "fabric.burlap:B59A6A", sides: 6)
            FC.bead(&m, r: 0.012, at: V3(x, crown - 0.18, 0.03), "metal.brass-aged", sub: 4)
            FC.bead(&m, r: 0.013, at: V3(x, lip.y - 0.03, front - 0.04), "fabric.burlap:A88F62", sub: 4)
            FA.rod(&m, V3(x, lip.y - 0.035, front - 0.04), V3(x, lip.y - 0.1, front - 0.04), r: 0.0045, "fabric.burlap:A88F62", sides: 5)
            FC.bead(&m, r: 0.011, at: V3(x, lip.y - 0.115, front - 0.04), "fabric.burlap:9C8359", sub: 4)
        }
        _ = rng.float()
        groundAO(&m, height: 0.1, floor: 0.8)
        return LODModel(FA.centerZ(m))
    }
}
