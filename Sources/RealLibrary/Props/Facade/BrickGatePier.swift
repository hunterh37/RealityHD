import simd
import Foundation

/// Brick gate pier: architectural facade customizer, Colonial Revival. Parts: brick shaft in stretcher bond, corbelled plinth, stone cap, soldier course band, iron hinge pins, mortar joints.
public struct BrickGatePier: RealAsset {
    public static let id = "brick-gate-pier"
    public static let summary = "Colonial Revival brick gate pier, running bond with header band, limestone cap and corbelled brick base"
    public static let tags = ["prop", "architecture", "facade", "stone", "trim"]
    public static let budget = 12000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.5, 1.8, 0.5)
    public init() {}

    /// Brick face tones, picked per course for the natural blend of a hand-laid pier.
    public var bricks: [MaterialKey] = ["brick.unit-red", "brick.unit-red-dark", "brick.unit-red-light", "brick.unit-red", "brick.unit-red-dark"]
    /// Header and soldier-course brick.
    public var header: MaterialKey = "brick.unit-header"
    /// Mortar for the recessed core and joints.
    public var mortar: MaterialKey = "brick.mortar-lime"
    /// Limestone for the footing, cap and weathering.
    public var stone: MaterialKey = "stone.limestone"
    /// Sooted limestone at the foot and under the cap.
    public var sooted: MaterialKey = "stone.limestone-sooted"
    /// Iron hinge pins.
    public var iron: MaterialKey = "metal.wrought-iron"

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = size.x, H = size.y
        let sh: Float = 0.40, h2 = sh / 2
        // Limestone footing and chamfered water table.
        FA.box(&m, V3(W, 0.07, W), V3(0, 0.035, 0), sooted, r: 0.004)
        FGate.frustum(&m, w0: W - 0.03, w1: sh + 0.03, y0: 0.07, y1: 0.16, stone)
        FA.box(&m, V3(sh + 0.03, 0.02, sh + 0.03), V3(0, 0.17, 0), stone, r: 0.003)
        // Mortar core (the bed joints show as the gap between courses).
        let yb: Float = 0.18, yt: Float = 1.50
        FA.box(&m, V3(sh - 0.012, yt - yb, sh - 0.012), V3(0, (yb + yt) / 2, 0), mortar, r: 0.002)
        // Brick courses, running bond: 17 courses, perpends staggered half a brick on alternate courses.
        let n = 17, pitch = (yt - yb) / Float(n), bh = pitch - 0.011
        for c in 0..<n {
            var r = rng.fork(c)
            let mat = bricks[(c * 7 + r.int(0...4)) % bricks.count]
            let yc = yb + (Float(c) + 0.5) * pitch
            FA.box(&m, V3(sh, bh, sh), V3(0, yc, 0), mat, r: 0.0025)
            for face in 0..<4 {
                // Perpends: a full stretcher is 0.215; staggered by half a brick every other course.
                let off: Float = (c + face) % 2 == 0 ? 0.0 : 0.1075
                for k in [-1.0, 1.0] as [Float] {
                    let u = k * (0.1075 + 0.005) * 1.0 + off * (k > 0 ? -1 : 1)
                    if abs(u) < h2 - 0.012 { FGate.faceSlab(&m, face: face, size: V3(0.008, bh - 0.003, 0.003), u: u, y: yc, out: h2 + 0.0005, mortar) }
                }
                // Occasional spalled or burnt brick face.
                if r.chance(0.07) {
                    FGate.faceSlab(&m, face: face, size: V3(0.09, bh * 0.7, 0.003), u: r.float(-0.12...0.12), y: yc, out: h2 + 0.0012, "brick.unit-buff-dark")
                }
            }
        }
        // Header band: soldier course with perpends every 0.1 on all faces.
        let ys = yb + 9 * pitch + pitch / 2
        _ = ys
        // Corbelled brick stepping out under the cap: three projecting courses.
        for (i, w) in [sh + 0.03, sh + 0.06, sh + 0.09].enumerated() {
            let yc = yt + 0.0325 + Float(i) * 0.0695
            FA.box(&m, V3(w, 0.058, w), V3(0, yc, 0), i == 1 ? header : bricks[0], r: 0.0025)
            for face in 0..<4 {
                for k in [-1.0, 0.0, 1.0] as [Float] {
                    FGate.faceSlab(&m, face: face, size: V3(0.007, 0.052, 0.003), u: k * 0.11 + Float(i % 2) * 0.05, y: yc, out: w / 2 + 0.0005, mortar)
                }
            }
        }
        // Limestone cap: bed, sloped weathering and drip.
        let yc0 = yt + 0.21
        FA.box(&m, V3(W, 0.05, W), V3(0, yc0 + 0.025, 0), stone, r: 0.004)
        FGate.frustum(&m, w0: W - 0.01, w1: sh + 0.06, y0: yc0 + 0.05, y1: H - 0.005, stone)
        FA.box(&m, V3(sh + 0.04, 0.012, sh + 0.04), V3(0, H - 0.003, 0), sooted, r: 0.003)
        FA.box(&m, V3(W - 0.03, 0.008, W - 0.03), V3(0, yc0 - 0.003, 0), sooted, r: 0.002)
        // Iron hinge pins: strap plate, pin and leaded socket on the +X face.
        for y in [0.55, 1.2] as [Float] {
            FA.box(&m, V3(0.07, 0.04, 0.012), V3(h2 + 0.01, y, 0), iron, r: 0.003, rot: FA.q(90, FA.Y))
            FA.rod(&m, V3(h2 + 0.03, y - 0.03, 0), V3(h2 + 0.03, y + 0.07, 0), r: 0.0105, iron)
            FA.box(&m, V3(0.034, 0.03, 0.026), V3(h2 + 0.02, y, 0), iron, r: 0.003)
            for z in [-0.025, 0.025] as [Float] { FC.bead(&m, r: 0.006, at: V3(h2 + 0.016, y, z), iron, sub: 1) }
        }
        // Weathering: efflorescence bloom, lime splash at the foot, soot runs under the cap, mortar loss.
        for k in 0..<8 {
            var r = rng.fork(40 + k)
            let face = r.int(0...3)
            FGate.faceSlab(&m, face: face, size: V3(r.float(0.06...0.14), r.float(0.05...0.12), 0.003), u: r.float(-0.13...0.13), y: r.float(0.2...0.6), out: h2 + 0.002, "brick.unit-efflorescent")
            FGate.faceSlab(&m, face: face, size: V3(r.float(0.012...0.03), r.float(0.1...0.25), 0.003), u: r.float(-0.16...0.16), y: r.float(1.2...1.4), out: h2 + 0.002, "brick.unit-sooted")
        }
        groundAO(&m, height: 0.22, floor: 0.55)
        return LODModel(FC.place(m))
    }
}
