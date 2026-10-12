import simd
import Foundation

/// Shoji sliding panel, Japanese Sukiya: cedar stiles and rails around a koshi kick board and a kumiko
/// lattice backed by overlapped washi sheets, brass hikite pull, walnut shikii sill and pine kamoi lintel
/// with two guide grooves. Centered on Z, base at y = 0.
public struct ShojiSlidingPanel: RealAsset {
    public static let id = "shoji-sliding-panel"
    public static let summary = "Shoji sliding panel, 1.8 x 1.9 m: cedar kumiko lattice with washi paper, rails, and a pull recess."
    public static let tags = ["prop", "architecture", "facade", "wood"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 6, distance: 2.7)

    /// Overall size in meters (x width, y height, z depth including the tracks).
    public var size = V3(1.8, 1.9, 0.06)
    /// Stile width, rail height, koshi board height and kumiko row pitch (m).
    public var stile: Float = 0.045
    public var rail: Float = 0.05
    public var koshiHeight: Float = 0.38
    public var rowPitch: Float = 0.16
    public var columns = 6
    public var frame: MaterialKey = "wood.cedar"
    public var track: MaterialKey = "wood.pine-aged"
    public var sill: MaterialKey = "wood.walnut"
    public var paper: MaterialKey = "paper.sheet:DCCDA8"
    public var hardware: MaterialKey = "metal.brass-aged"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = size.x, H = size.y, D = size.z
        let t: Float = 0.032          // leaf thickness
        let sillH: Float = 0.03, lintelH: Float = 0.06
        let y0 = sillH + 0.004, y1 = H - lintelH + 0.012   // leaf bottom and top
        let LH = y1 - y0, lw = W - 0.02

        // Shikii sill with two raised guide ridges; kamoi lintel with two hanging lips and a groove between.
        FA.box(&m, V3(W, sillH, D), V3(0, sillH / 2, 0), sill, r: 0.004)
        for s: Float in [-1, 1] {
            FA.box(&m, V3(W - 0.02, 0.008, 0.012), V3(0, sillH + 0.004 - 0.0, s * 0.0215), sill, r: 0.002)
            FA.box(&m, V3(W, 0.03, 0.013), V3(0, H - lintelH + 0.002, s * 0.0235), track, r: 0.002)
        }
        FA.box(&m, V3(W, lintelH - 0.026, D), V3(0, H - (lintelH - 0.026) / 2, 0), track, r: 0.004)
        // Brass end caps on the lintel and countersunk screws along the sill.
        for s: Float in [-1, 1] {
            FA.box(&m, V3(0.004, lintelH - 0.026, D), V3(s * (W / 2 - 0.002), H - (lintelH - 0.026) / 2, 0), hardware, r: 0.001)
        }
        for k in 0..<7 {
            let x = -0.75 + Float(k) * 0.25
            FA.cylZ(&m, r: 0.005, h: 0.002, at: V3(x, sillH * 0.5, D / 2 - 0.002), hardware, bevel: 0.0005, segments: 10)
        }

        // Stiles (full leaf height) and top/bottom rails.
        for s: Float in [-1, 1] {
            FA.box(&m, V3(stile, LH, t), V3(s * (lw / 2 - stile / 2), y0 + LH / 2, 0), frame, r: 0.003)
        }
        let inW = lw - 2 * stile
        FA.box(&m, V3(inW, rail, t), V3(0, y0 + rail / 2, 0), track, r: 0.003)
        FA.box(&m, V3(inW, rail * 0.9, t), V3(0, y1 - rail * 0.45, 0), frame, r: 0.003)

        // Koshi: kick board framed by a mid rail, one horizontal cedar board panel, a darker patched board.
        let kTop = y0 + koshiHeight
        FA.box(&m, V3(inW, 0.045, t), V3(0, kTop - 0.0225, 0), frame, r: 0.003)
        let kb0 = y0 + rail, kb1 = kTop - 0.045
        FA.box(&m, V3(inW, kb1 - kb0, 0.012), V3(0, (kb0 + kb1) / 2, 0), "wood.cedar", r: 0.002)
        for k in 1..<3 {   // vertical grooves between kick boards
            let y = kb0 + (kb1 - kb0) * Float(k) / 3
            FA.box(&m, V3(inW, 0.003, 0.004), V3(0, y, 0.006), "wood.pine-aged", r: 0.001)
        }
        FA.box(&m, V3(0.12, kb1 - kb0 - 0.01, 0.004), V3(-0.55, (kb0 + kb1) / 2, 0.0075), "wood.pine-aged", r: 0.001)

        // Kumiko lattice: slender vertical and horizontal bars, with a double bar at mid height.
        let gx0 = -inW / 2
        let gy0 = kTop, gy1 = y1 - rail * 0.9
        let rows = Int(((gy1 - gy0) / rowPitch).rounded())
        let rp = (gy1 - gy0) / Float(rows)
        let kd: Float = 0.026, kw: Float = 0.011
        for r in 0...rows where r != 0 && r != rows {
            let y = gy0 + Float(r) * rp
            FA.box(&m, V3(inW, kw, kd - 0.006), V3(0, y, 0.003), frame, r: 0.0015)
        }
        for c in 0...columns {
            let x = gx0 + inW * Float(c) / Float(columns)
            if c == 0 || c == columns { continue }
            FA.box(&m, V3(kw * 1.2, gy1 - gy0, kd), V3(x, (gy0 + gy1) / 2, 0), frame, r: 0.0015)
        }
        // Washi: three overlapped sheets behind the lattice, edges 10 mm lapped; one bright repair patch.
        let pz = -t / 2 + 0.0015
        let bandH = (gy1 - gy0) / 3
        for k in 0..<3 {
            let h = bandH + 0.012
            let yc = gy0 + bandH * (Float(k) + 0.5)
            FA.box(&m, V3(inW + 0.004, h, 0.0016), V3(0, yc, pz - Float(k) * 0.0007 + rng.float(-0.0002...0.0002)), k == 2 ? "paper.sheet:CFC09A" : paper, r: 0.0006)
        }
        FA.box(&m, V3(0.15, 0.12, 0.0012), V3(0.46, gy0 + 0.62, pz - 0.0018), "paper.sheet:EADFC2", r: 0.0004)

        // Water stain along the bottom of the paper and a sun-faded band near the top.
        for k in 0..<4 {
            let w = 0.5 - Float(k) * 0.1
            FA.box(&m, V3(w, 0.03, 0.0011), V3(-0.3 + Float(k) * 0.02, gy0 + 0.015 + Float(k) * 0.025, pz - 0.0022), "paper.sheet:B8A67C", r: 0.0003)
        }
        FA.box(&m, V3(inW - 0.02, 0.08, 0.0011), V3(0, gy1 - 0.05, pz - 0.0022), "paper.sheet:E8DDBE", r: 0.0003)
        // Worn hand patch on the stile beside the pull.
        FA.box(&m, V3(stile - 0.006, 0.14, 0.0008), V3(lw / 2 - stile / 2, y0 + 0.4, t / 2 + 0.0004), "wood.pine-aged", r: 0.0003)

        // Hikite: walnut escutcheon plate with a recessed brass-lined pocket on the kick board.
        let hx: Float = 0.62, hy = y0 + koshiHeight * 0.5
        FA.box(&m, V3(0.12, 0.12, 0.006), V3(hx, hy, t / 2 - 0.002 + 0.003), sill, r: 0.002)
        FA.cylZ(&m, r: 0.036, h: 0.002, at: V3(hx, hy, t / 2 + 0.0), "wood.walnut", bevel: 0.0005, segments: 24)
        FA.cylZ(&m, r: 0.032, h: 0.0015, at: V3(hx, hy, t / 2 + 0.0015), hardware, bevel: 0.0005, segments: 24)
        FA.cylZ(&m, r: 0.024, h: 0.001, at: V3(hx, hy, t / 2 + 0.003), "wood.pine-aged", bevel: 0.0003, segments: 24)
        for (dx, dy) in [(-0.035, -0.035), (0.035, -0.035), (-0.035, 0.035), (0.035, 0.035)] as [(Float, Float)] {
            FC.bead(&m, r: 0.003, at: V3(hx + dx, hy + dy, t / 2 + 0.006), hardware, sub: 1)
        }
        // Kugikakushi: brass nail covers at the stile and rail joints.
        for s: Float in [-1, 1] {
            for y in [y0 + rail / 2, kTop - 0.0225, y1 - rail * 0.45] {
                FC.bead(&m, r: 0.0045, at: V3(s * (lw / 2 - stile / 2), y, t / 2 + 0.001), hardware, sub: 1)
            }
        }

        groundAO(&m, height: 0.1, floor: 0.9)
        return LODModel(FC.place(m))
    }
}
