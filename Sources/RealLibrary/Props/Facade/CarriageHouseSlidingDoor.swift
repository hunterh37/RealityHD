import simd
import Foundation

/// Carriage house sliding door, 2.4 x 2.4 m: 23 tongue-and-groove boards in barn red (each board its own repaint
/// tone) under Z-bracing battens, hung from an overhead steel box rail on two strap-and-wheel hangers with through
/// bolts. Five L-brackets carry the rail off the wall, a floor guide and a wooden stop control the travel, a cast
/// iron D-pull and backplate sit at hand height over a stone sill strip. The red is sun-bleached high up, flaked
/// to grey wood on the bracing and scuffed with mud near the floor; rust bleeds from the hangers.
public struct CarriageHouseSlidingDoor: RealAsset {
    public static let id = "carriage-house-sliding-door"
    public static let summary = "Carriage house sliding barn door: painted X-braced plank leaf on an overhead steel track with wheel hangers, a flat guide at the floor and a pull handle."
    public static let tags = ["prop", "architecture", "facade", "door", "wood", "metal"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 6, distance: 5.0)

    /// Leaf width (m).
    public var leafWidth: Float = 2.3
    /// Board count.
    public var boards = 23
    /// Leaf paint, barn red.
    public var red: UInt32 = 0x5C211B
    public var steel: MaterialKey = "metal.steel"
    public var rail: MaterialKey = "metal.galvanized-aged"
    public var iron: MaterialKey = "metal.cast-iron"
    public init() {}

    func tinted(_ hex: UInt32, _ k: Float) -> MaterialKey {
        let r = min(255, Int(Float((hex >> 16) & 255) * k)), g = min(255, Int(Float((hex >> 8) & 255) * k)), b = min(255, Int(Float(hex & 255) * k))
        return "wood.painted-shaker-worn:" + String(format: "%02X%02X%02X", r, g, b)
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let lw = leafWidth, n = boards, bw = lw / Float(n)
        let y0: Float = 0.05, y1: Float = 2.28, hh = y1 - y0
        let zb: Float = 0.058, tb: Float = 0.026, zf = zb + tb           // board back, thickness, board front
        let tbat: Float = 0.024, zbat = zf + tbat                         // batten thickness, batten front
        let railY: Float = 2.365

        // Stone sill strip and floor guide.
        FA.box(&m, V3(2.4, 0.04, 0.14), V3(0, 0.02, 0.07), "stone.granite-paver", r: 0.004)
        FA.box(&m, V3(0.07, 0.06, 0.016), V3(0.0, 0.07, zb + 0.013), steel, r: 0.0015)
        FA.box(&m, V3(0.016, 0.07, 0.06), V3(0.0, 0.075, zb + 0.04), steel, r: 0.0015)
        rivet(&m, at: V3(0.0, 0.092, zb + 0.0215), normal: FA.Z, radius: 0.004, segments: 6, material: steel)
        // Wooden stop block on the sill at the right end.
        FA.box(&m, V3(0.1, 0.09, 0.07), V3(1.12, 0.085, 0.085), "wood.weathered", r: 0.006)

        // Boards: tongue-and-groove, each repainted a slightly different red, jittered a touch for warp.
        FJ.slab(&m, V3(lw, hh, 0.008), V3(0, (y0 + y1) / 2, zb + 0.013), "wood.charred")
        for i in 0..<n {
            let x = -lw / 2 + bw / 2 + Float(i) * bw
            let k = rng.float(0.85...1.18)
            let top = y1 - rng.float(0...0.006), bottom = y0 + rng.float(0...0.01)
            FA.box(&m, V3(bw - 0.004, top - bottom, tb), V3(x, (top + bottom) / 2, zb + tb / 2 + rng.float(-0.0012...0.0012)), tinted(red, k), r: 0.0022)
            if i > 0 { FA.rod(&m, V3(x - bw / 2, bottom + 0.004, zf + 0.0012), V3(x - bw / 2, top - 0.004, zf + 0.0012), r: 0.0022, tinted(red, k), sides: 5) }
        }
        // Z-bracing battens: top, bottom and diagonal rails on the front.
        let bat: MaterialKey = "wood.painted-shaker-worn:4E1D18"
        let rh: Float = 0.15, ytop = y1 - 0.12, ybot = y0 + 0.17
        FA.box(&m, V3(lw - 0.02, rh, tbat), V3(0, ytop, zf + tbat / 2), bat, r: 0.003)
        FA.box(&m, V3(lw - 0.02, rh, tbat), V3(0, ybot, zf + tbat / 2), bat, r: 0.003)
        let dx = lw - 0.3, dy = ytop - ybot
        FA.box(&m, V3(sqrt(dx * dx + dy * dy) - 0.04, 0.15, tbat + 0.0025), V3(0, (ytop + ybot) / 2, zf + (tbat + 0.0025) / 2), "wood.painted-shaker-worn:60241E", r: 0.003, rot: FA.q(atan2(dy, dx) * 180 / .pi, FA.Z))
        // Carriage bolts through the battens at the board lines (every third board).
        for i in stride(from: 1, to: n, by: 3) {
            let x = -lw / 2 + bw / 2 + Float(i) * bw
            for y in [ytop - 0.04, ytop + 0.04, ybot - 0.04, ybot + 0.04] {
                rivet(&m, at: V3(x, y, zbat), normal: FA.Z, radius: 0.0065, height: 0.0045, segments: 7, material: "metal.galvanized")
            }
        }

        // Overhead rail: box tube with end caps and L-brackets to the wall; flat wheel hangers from the leaf.
        FA.box(&m, V3(2.4, 0.042, 0.042), V3(0, railY, zb + 0.026), rail, r: 0.004)
        for e: Float in [-1, 1] { FA.box(&m, V3(0.012, 0.05, 0.05), V3(e * 1.19, railY, zb + 0.026), steel, r: 0.002) }
        for t in stride(from: Float(-1.0), through: 1.0, by: 0.5) {
            FA.box(&m, V3(0.05, 0.1, 0.008), V3(t, railY - 0.02, 0.004), steel, r: 0.001)                       // wall plate
            FA.box(&m, V3(0.05, 0.016, zb + 0.026 + 0.02), V3(t, railY - 0.03, (zb + 0.046) / 2), steel, r: 0.0015)   // arm
            rivet(&m, at: V3(t, railY + 0.014, 0.008), normal: FA.Z, radius: 0.0055, segments: 6, material: "metal.galvanized")
            rivet(&m, at: V3(t, railY - 0.054, 0.008), normal: FA.Z, radius: 0.0055, segments: 6, material: "metal.galvanized")
        }
        for e: Float in [-1, 1] {
            let hx = e * 0.78, wy = railY - 0.0
            // Hanger: two plates either side of the rail wheel, bolted through the leaf header.
            FA.box(&m, V3(0.05, 0.27, 0.006), V3(hx, y1 - 0.12, zbat + 0.003), steel, r: 0.0012)
            FA.box(&m, V3(0.05, 0.1, 0.006), V3(hx, y1 + 0.015, zb - 0.0), steel, r: 0.0012)
            FA.box(&m, V3(0.034, 0.03, 0.05), V3(hx, y1 + 0.0, zb + 0.0125), steel, r: 0.0012)
            FA.cylZ(&m, r: 0.034, h: 0.016, at: V3(hx, wy, zb + 0.005), steel, bevel: 0.0025, segments: 18)
            FC.bead(&m, r: 0.0085, at: V3(hx, wy, zb + 0.026), steel, sub: 3)
            for yy in [y1 - 0.05, y1 - 0.12, y1 - 0.19] { rivet(&m, at: V3(hx + 0.0, yy, zbat + 0.006), normal: FA.Z, radius: 0.0075, height: 0.005, segments: 7, material: steel) }
            FJ.streak(&m, x: hx, top: y1 - 0.2, length: rng.float(0.2...0.4), width: 0.03, z: zbat, "metal.rust")
        }
        // Cast iron D-pull on a backplate and a slide latch below it.
        let px: Float = 0.62, py: Float = 1.15
        FA.box(&m, V3(0.12, 0.34, 0.008), V3(px, py, zbat + 0.004), iron, r: 0.002)
        m.add(barHandle(length: 0.2, standoff: 0.021, radius: 0.0105, overhang: 0.012, material: iron), Xform(translation: V3(px, py, zbat + 0.008), rotation: FA.q(90, FA.Z)))
        for dy: Float in [-0.14, 0.14] { for dxp: Float in [-0.04, 0.04] { rivet(&m, at: V3(px + dxp, py + dy, zbat + 0.008), normal: FA.Z, radius: 0.0055, segments: 7, material: iron) } }
        FA.box(&m, V3(0.16, 0.026, 0.006), V3(px, py - 0.28, zbat + 0.003), iron, r: 0.0012)
        FA.cylX(&m, r: 0.0055, h: 0.12, at: V3(px - 0.06, py - 0.28, zbat + 0.0085), iron, bevel: 0.001, segments: 8)
        FA.ball(&m, r: 0.0085, at: V3(px + 0.05, py - 0.28, zbat + 0.012), iron)

        // Wear: bleached upper boards, grey flaking on battens, muddy splash band and rust on the diagonal ends.
        for _ in 0..<22 { FJ.peel(&m, at: V3(rng.float(-lw / 2 + 0.08...lw / 2 - 0.08), rng.float(y0 + 0.2...y1 - 0.2), zf + 0.0006), w: rng.float(0.03...0.09), h: rng.float(0.06...0.24), "wood.weathered", rng: &rng) }
        for _ in 0..<7 { FJ.peel(&m, at: V3(rng.float(-lw / 2 + 0.1...lw / 2 - 0.1), ytop + rng.float(-0.04...0.04), zbat + 0.0006), w: rng.float(0.05...0.16), h: rng.float(0.03...0.07), "wood.weathered", rng: &rng) }
        for _ in 0..<5 { FJ.peel(&m, at: V3(rng.float(-lw / 2 + 0.1...lw / 2 - 0.1), ybot + rng.float(-0.04...0.04), zbat + 0.0006), w: rng.float(0.05...0.16), h: rng.float(0.03...0.07), "wood.weathered", rng: &rng) }
        FJ.slab(&m, V3(lw - 0.02, 0.2, 0.0012), V3(0, y0 + 0.1, zf + 0.0008), "wood.painted-shaker-worn:3F342B")
        for i in 0..<9 { FJ.streak(&m, x: -lw / 2 + 0.15 + Float(i) * 0.27 + rng.float(-0.05...0.05), top: y0 + 0.5, length: rng.float(0.15...0.4), width: rng.float(0.015...0.04), z: zf + 0.0008, "wood.painted-shaker-worn:3F342B") }
        FJ.chips(&m, spots: [V3(px, py + 0.25, 0), V3(px - 0.2, py - 0.3, 0)], face: zf + 0.0005, "wood.weathered", rng: &rng, each: 5)
        groundAO(&m, height: 0.15, floor: 0.7)
        return LODModel(FC.place(m))
    }
}
