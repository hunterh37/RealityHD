import simd
import Foundation

/// Victorian sandstone ashlar panel: a chamfered plinth course and three broken-bond courses of
/// rock-faced blocks with 25 mm chisel-drafted margins, set in recessed lime mortar. One block carries
/// a rusted iron cramp plate that has bled a stain down the stone below it.
public struct SandstoneAshlarPanel: RealAsset {
    public static let id = "sandstone-ashlar-panel"
    public static let summary = "Sandstone ashlar wall panel, 1.2 m square: four courses of tooled, rock-faced and margin-drafted blocks in recessed lime mortar joints."
    public static let tags = ["prop", "architecture", "facade", "stone", "trim"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 10, distance: 2.4)

    /// Panel width in meters.
    public var width: Float = 1.2
    /// Course height in meters (four courses).
    public var course: Float = 0.3
    /// Mortar joint width in meters.
    public var joint: Float = 0.01
    /// Drafted margin width in meters.
    public var margin: Float = 0.025
    /// Main stone.
    public var stone: MaterialKey = "stone.sandstone:BFA47F"
    /// Darker weathered stone for some blocks.
    public var stoneAlt: MaterialKey = "stone.sandstone:A88D68"
    /// Lime mortar.
    public var mortar: MaterialKey = "concrete.smooth:C8C2B4"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = width, H = course * 4, back: Float = 0.12
        // Mortar bed, recessed 12 mm behind the drafted margins.
        FA.box(&m, V3(W, H, back), V3(0, H / 2, back / 2), "stone.sandstone:B49A74", r: 0.004)
        FA.box(&m, V3(W - 0.004, H - 0.002, 0.03), V3(0, H / 2, back + 0.015), mortar, r: 0.002)
        let layouts: [[Float]] = [[0.6, 0.6], [0.35, 0.5, 0.35], [0.55, 0.65], [0.4, 0.45, 0.35]]
        for (ci, row) in layouts.enumerated() {
            let y0 = Float(ci) * course, bh = course - joint, yc = y0 + course / 2 + joint / 2 - (ci == 0 ? joint / 2 : 0)
            var x = -W / 2
            for (bi, len) in row.enumerated() {
                let bw = len - joint, cx = x + len / 2
                let mat = rng.chance(0.3) ? stoneAlt : stone
                let blockD: Float = 0.165
                if ci == 0 {
                    // Plinth: tooled face with a 45 degree weathered chamfer on top.
                    let prof = [V2(0, 0), V2(blockD + 0.02, 0), V2(blockD + 0.02, bh - 0.05), V2(blockD - 0.02, bh), V2(0, bh)]
                    FA.run(&m, prof, length: bw, at: V3(cx, y0 + 0.0, 0), mat, bevel: 0.003)
                    FCL.face(&m, w: bw - 0.03, h: bh - 0.09, seg: 16, at: V3(cx, (bh - 0.05) / 2, blockD + 0.0205), mat) { px, py in
                        let e = FCL.edge(px, py, bw - 0.03, bh - 0.09, 0.01)
                        return e * (0.0015 * Noise.perlin(V3(px * 300, py * 8, Float(bi))) + 0.001)
                    }
                } else {
                    FA.box(&m, V3(bw, bh, blockD), V3(cx, yc, blockD / 2), mat, r: 0.004)
                    // Drafted margin (fine vertical tooling) around a rock-faced boss, one heightfield.
                    let fw = bw - 0.006, fh = bh - 0.006, sd = Float(ci * 7 + bi)
                    FCL.face(&m, w: fw, h: fh, seg: 25, at: V3(cx, yc, blockD - 0.0005), mat) { px, py in
                        let e = FCL.edge(px, py, fw, fh, 0.004)
                        let inner = FCL.edge(px, py, fw - 2 * margin, fh - 2 * margin, 0.022)
                        let n = Noise.fbm(V3(px * 9 + sd, py * 9, sd), octaves: 4)
                        let chips = max(0, Noise.perlin(V3(px * 22, py * 22, sd + 3))) * 0.012
                        let tool = 0.0006 * sin(px * 700)
                        return e * (0.0015 + tool * (1 - inner) + inner * (0.024 + 0.022 * n - chips))
                    }
                }
                x += len
            }
        }
        // Iron cramp plate with two bolts and rust run-off stain.
        let px: Float = 0.25, py = course * 2.5
        FA.box(&m, V3(0.08, 0.05, 0.006), V3(px, py, 0.19), "metal.rust", r: 0.0015)
        for dx in [-0.026, 0.026] as [Float] { hexBolt(&m, at: V3(px + dx, py, 0.193), normal: FA.Z, size: 0.012, material: "metal.cast-iron") }
        groundAO(&m, height: 0.15, floor: 0.75)
        return LODModel(FC.place(m))
    }
}
