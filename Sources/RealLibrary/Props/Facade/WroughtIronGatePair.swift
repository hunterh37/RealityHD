import simd
import Foundation

/// Wrought iron gate pair: architectural facade customizer, Victorian. Parts: two gate leaves, top and bottom rails, vertical pickets, scroll panels, spear finials, strap hinges, drop bolt, centre latch.
public struct WroughtIronGatePair: RealAsset {
    public static let id = "wrought-iron-gate-pair"
    public static let summary = "Victorian cast and wrought iron double gate, 2.4 m wide, black paint with scrolls and spear-point finials."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 15000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(2.4, 1.8, 0.06)
    public init() {}

    /// Painted wrought iron for bars, rails and scrolls.
    public var iron: MaterialKey = "metal.wrought-iron"
    /// Cast iron for finials, collars and hinge straps.
    public var cast: MaterialKey = "metal.painted:1C1C1F"
    /// Worn iron where rust shows through at the foot of the leaves.
    public var worn: MaterialKey = "metal.rust-grime"
    /// Brass for the latch handle.
    public var brass: MaterialKey = "metal.brass-aged"
    /// Picket spacing in meters.
    public var picketPitch: Float = 0.1

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = size.x, H = size.y
        let gap: Float = 0.02, leafW = (W - gap) / 2 - 0.04
        let bot: Float = 0.14, midY: Float = 0.78, topY: Float = H - 0.24, stile: Float = 0.032
        for side in [-1, 1] as [Float] {
            // Leaf x range: hinge stile at the outer end, meeting stile at the centre.
            let xo = side * (W / 2 - 0.02), xi = side * (gap / 2 + 0.012)
            let x0 = min(xo, xi), x1 = max(xo, xi)
            let cx = (x0 + x1) / 2, lw = x1 - x0
            var lr = rng.fork(side > 0 ? 1 : 0)
            // Stiles run the full leaf height and carry the larger finials.
            for sx in [xo - side * stile / 2 + side * 0.0, xi - side * stile / 2 * -1 * 0 + (-side) * stile / 2] {
                FA.box(&m, V3(stile, topY - bot + 0.1, 0.03), V3(sx, (bot - 0.02 + topY + 0.08) / 2, 0), iron, r: 0.003)
                FGate.spear(&m, x: sx, y: topY + 0.08, z: 0, h: 0.15, w: 0.05, cast)
                FA.box(&m, V3(0.046, 0.016, 0.046), V3(sx, topY + 0.07, 0), cast, r: 0.003)
            }
            // Rails: flat bars with a stepped double rail at top and mid.
            for (y, hh) in [(bot, 0.04), (bot + 0.05, 0.016), (midY, 0.026), (midY + 0.05, 0.026), (topY, 0.03), (topY - 0.055, 0.016)] as [(Float, Float)] {
                FA.box(&m, V3(lw, hh, 0.024), V3(cx, y, 0), iron, r: 0.0025)
            }
            // Bottom rail wear where water pools.
            FA.box(&m, V3(lw * 0.7, 0.034, 0.0255), V3(cx + lr.float(-0.05...0.05), bot, 0), worn, r: 0.002)
            // Pickets with collars where they pass through the rails.
            let inner = lw - 2 * stile
            let n = Int(inner / picketPitch)
            let p0 = x0 + stile + (inner - Float(n - 1) * picketPitch) / 2 - 0.0
            for i in 0..<max(n, 1) {
                let px = p0 + Float(i) * picketPitch
                FGate.picket(&m, x: px, y0: bot, y1: topY + 0.03, z: 0, r: 0.0075, iron, sides: 6)
                FGate.spear(&m, x: px, y: topY + 0.03, z: 0, h: 0.1, w: 0.032, cast)
            }
            // Scroll panel between the bottom and mid rails: facing C-scrolls on each picket bay.
            let bays = max(n / 2, 1)
            for b in 0..<bays {
                let bx = p0 + Float(b * 2) * picketPitch + picketPitch / 2
                let cy = (bot + 0.05 + midY) / 2
                FGate.scroll(&m, c: V3(bx - 0.0, cy + 0.115, 0.012), r0: 0.085, turns: 1.2, start: 90, dir: 1, wire: 0.007, iron)
                FGate.scroll(&m, c: V3(bx + picketPitch * 0.0, cy - 0.115, 0.012), r0: 0.085, turns: 1.2, start: -90, dir: -1, wire: 0.007, iron)
                if b % 2 == 0 { FGate.scroll(&m, c: V3(bx + picketPitch, cy, -0.012), r0: 0.075, turns: 1.3, start: 180, dir: -1, wire: 0.007, iron) }
            }
            // Strap hinges on the outer stile, riveted through to the pintle.
            for y in [bot + 0.15, topY - 0.15] {
                FGate.strapHinge(&m, at: V3(xo + side * 0.012, y, 0.0), length: 0.34, dirX: -side, w: 0.034, cast)
            }
            // Paint loss on the hinge stile and rust drips under each strap.
            for y in [bot + 0.15, topY - 0.15] {
                FA.box(&m, V3(0.006, 0.09 + lr.float(0...0.06), 0.0302), V3(xo + side * 0.012 - side * 0.004, y - 0.07, 0), worn, r: 0.001)
            }
            for k in 0..<4 {
                let yy = lr.float(bot + 0.1...topY - 0.2)
                FA.box(&m, V3(0.014, lr.float(0.03...0.07), 0.0305), V3(xo - side * stile / 2, yy, 0), worn, r: 0.001)
            }
            // Drop-bolt guides on the meeting stile.
            let bx = xi - side * 0.0 - side * stile / 2 + side * 0.0
            _ = bx
        }
        // Centre latch: backplate, brass lever and keeper.
        FA.box(&m, V3(0.1, 0.07, 0.008), V3(0, 0.95, 0.016), cast, r: 0.003)
        FA.cylZ(&m, r: 0.012, h: 0.012, at: V3(0, 0.95, 0.02), brass, segments: 14)
        FA.box(&m, V3(0.1, 0.016, 0.01), V3(0.03, 0.95, 0.03), brass, r: 0.004)
        for ix in [-0.04, 0.04] as [Float] { FC.bead(&m, r: 0.005, at: V3(ix, 0.975, 0.02), cast, sub: 2) }
        // Drop bolt on the left meeting stile: rod, two guides and a pull knob.
        FA.rod(&m, V3(-0.026, 0.02, 0.02), V3(-0.026, 0.52, 0.02), r: 0.007, iron)
        for y in [0.12, 0.34] as [Float] { FA.box(&m, V3(0.026, 0.04, 0.016), V3(-0.026, y, 0.02), cast, r: 0.003) }
        FC.bead(&m, r: 0.011, at: V3(-0.026, 0.52, 0.02), brass, sub: 4)
        // Ground socket plate under the bolt (story detail: one chipped corner).
        FA.box(&m, V3(0.07, 0.012, 0.045), V3(-0.026, 0.006, 0.0), cast, r: 0.003)
        groundAO(&m, height: 0.2, floor: 0.5)
        return LODModel(FC.place(m))
    }
}
