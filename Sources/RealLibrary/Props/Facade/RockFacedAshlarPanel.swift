import simd
import Foundation

/// Rock-faced ashlar panel: Richardsonian Romanesque coursed rusticated brownstone. Four courses of
/// alternating height (0.4 m, 0.2 m) with broken vertical joints. Each block has a flat tooled drafted
/// margin 25 mm wide around a quarry-split face that bulges up to ~45 mm, set in dark mortar raked
/// 15 mm back. Faces are pitched sharply off the draft line; some blocks are soot-darkened. A wrought-iron tie-rod anchor plate with a square nut is fixed through one block.
public struct RockFacedAshlarPanel: RealAsset {
    public static let id = "rock-faced-ashlar-panel"
    public static let summary = "Rock-faced ashlar panel, 1.2 m square: coursed rusticated brownstone blocks with quarry-split faces, drafted margins and deep raked joints."
    public static let tags = ["prop", "architecture", "facade", "stone"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 10, distance: 2.8)

    /// Panel width (m).
    public var width: Float = 1.2
    /// Course heights bottom to top, joints included (m).
    public var courses: [Float] = [0.4, 0.2, 0.4, 0.2]
    /// Joint thickness.
    public var joint: Float = 0.012
    /// Drafted margin width.
    public var margin: Float = 0.025
    /// Maximum bulge of the rock face beyond the margin.
    public var bulge: Float = 0.032
    /// Block bed depth.
    public var bed: Float = 0.168
    /// Stone material.
    public var stone: MaterialKey = "stone.brownstone"
    /// Mortar.
    public var mortar: MaterialKey = "brick.mortar-dark"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let j = joint, half = width / 2
        var y: Float = 0, n = 0
        var anchorAt: V3 = .zero
        for (c, ch) in courses.enumerated() {
            var x = -half - (c % 2 == 0 ? 0 : rng.float(0.2...0.3))
            while x < half - 0.05 {
                var len = ch > 0.3 ? rng.float(0.5...0.75) : rng.float(0.4...0.6)
                if x < -half { len = max(len, -half - x + 0.3) }   // no slivers at the left end
                if half - (x + len) < 0.18 { len = half - x }      // no slivers at the right end
                let x0 = max(x, -half) + j / 2, x1 = min(x + len, half) - j / 2
                let y0 = y + j / 2, y1 = y + ch - j / 2
                n += 1
                var r = rng.fork(n)
                block(&m, x0: x0, x1: x1, y0: y0, y1: y1, rng: &r, seed: UInt32(n))
                if c == 2 && anchorAt == .zero && x1 > -0.1 { anchorAt = V3((x0 + x1) / 2, (y0 + y1) / 2, 0) }
                x += len
            }
            y += ch
        }
        FM.mortar(&m, w: width, h: y, recess: 0.015, back: bed - 0.004, mortar)
        // Tie-rod anchor: square plate with chamfered edges, square nut, rod end.
        let az = bulge * 1.7
        FA.box(&m, V3(0.11, 0.11, 0.012), anchorAt + V3(0, 0, az), "metal.rust", r: 0.004, rot: FA.q(45, FA.Z))
        FA.box(&m, V3(0.034, 0.034, 0.016), anchorAt + V3(0, 0, az + 0.012), "metal.cast-iron", r: 0.003)
        FA.cylZ(&m, r: 0.011, h: 0.008, at: anchorAt + V3(0, 0, az + 0.02), "metal.rust", segments: 10)
        FA.box(&m, V3(0.05, 0.05, az), anchorAt + V3(0, 0, az / 2), "metal.rust", r: 0.003)   // seating pad bedded in the face
        groundAO(&m, height: 0.12, floor: 0.8)
        return LODModel(FC.place(m))
    }

    private func block(_ m: inout Model, x0: Float, x1: Float, y0: Float, y1: Float, rng: inout SeededRNG, seed: UInt32) {
        let w = x1 - x0, h = y1 - y0, mg = margin
        let mat: MaterialKey = stone
        let rock: MaterialKey = rng.chance(0.25) ? "stone.brownstone-sooted" : "stone.brownstone-rockface"
        FA.box(&m, V3(w, h, bed), V3((x0 + x1) / 2, (y0 + y1) / 2, -bed / 2), mat, r: 0.005)
        let fw = w - 2 * mg, fh = h - 2 * mg
        let seg = max(10, min(32, Int(max(fw, fh) / 0.018)))
        let peak = bulge * rng.float(0.75...1.1)
        let off = V3(rng.float(0...50), rng.float(0...50), 0)
        var face = Prim.terrain(size: V2(fw, fh), segments: seg, material: stone) { p in
            let ex = min(fw / 2 - abs(p.x), fh / 2 - abs(p.y))       // distance to the margin line
            let e = simd_smoothstep(Float(0), Float(0.009), ex)   // pitched arris: the face breaks sharply at the draft line
            let dome = 0.6 - 0.2 * (p.x * p.x / (fw * fw / 4) + p.y * p.y / (fh * fh / 4))
            let q = V3(p.x, p.y, 0) + off
            // Quarry split: ridged low-frequency facets plus fine pitting.
            let rough = (0.5 - abs(Noise.fbm(q * 5, octaves: 4, seed: seed))) * 2.0 + Noise.fbm(q * 24, octaves: 3, seed: seed + 7) * 0.35
            return 0.001 + e * peak * max(0.1, dome + rough)
        }
        face.material = rock
        m.add(face, Xform(translation: V3((x0 + x1) / 2, (y0 + y1) / 2, 0), rotation: FA.q(90, FA.X)))
    }
}
