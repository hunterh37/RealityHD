import simd
import Foundation

/// Arts and Crafts sgraffito panel, 0.8 m square: terracotta body under a cream slip scratched through
/// in a stylized tulip, vine border and corner rosettes, in a mitred oak frame with an inner bead and
/// brass screws. Edge chips and a hairline crack. Wall plane at z = 0.
public struct TerracottaSgraffitoPanel: RealAsset {
    public static let id = "terracotta-sgraffito-panel"
    public static let summary = "Arts and Crafts sgraffito panel, 0.8 m square: cream slip scratched to terracotta in a tulip and vine pattern, in an oak frame."
    public static let tags = ["prop", "architecture", "facade", "decor", "stone"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 8, distance: 1.1)

    /// Fired clay body.
    public var clay: MaterialKey = "ceramic.terracotta"
    /// Cream slip layer.
    public var slip: MaterialKey = "stone.limestone"
    /// Frame timber.
    public var timber: MaterialKey = "wood.oak"
    public init() {}

    static func strip(_ path: [V2], _ w: Float) -> [V2] {
        var left: [V2] = [], right: [V2] = []
        for i in path.indices {
            let a = path[max(i - 1, 0)], b = path[min(i + 1, path.count - 1)]
            let d = simd_normalize(b - a), n = V2(-d.y, d.x)
            left.append(path[i] + n * w / 2); right.append(path[i] - n * w / 2)
        }
        return Shape2D.deduped(left + right.reversed())
    }
    static func xf(_ pts: [V2], angle: Float, at o: V2) -> [V2] {
        let c = cos(angle), s = sin(angle)
        return pts.map { V2($0.x * c - $0.y * s, $0.x * s + $0.y * c) + o }
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let S: Float = 0.8, fw: Float = 0.055, fd: Float = 0.034, hi = S / 2, ho = hi - fw
        // Mitred oak frame (outer 0.8, opening 0.69) and inner bead lip.
        func bar(_ a: V2, _ b: V2, _ c: V2, _ d: V2, front: Float, depth: Float, _ mat: MaterialKey) {
            FM.prism(&m, [a, b, c, d], front: front, depth: depth, mat, bevel: 0.0015)
        }
        for k in 0..<4 {
            let r = Float(k) * .pi / 2
            func p(_ x: Float, _ y: Float) -> V2 { Self.xf([V2(x, y)], angle: r, at: .zero)[0] }
            bar(p(-hi, hi), p(hi, hi), p(ho, ho), p(-ho, ho), front: fd, depth: fd, timber)
            let hb = ho - 0.012
            bar(p(-ho, ho), p(ho, ho), p(hb, hb), p(-hb, hb), front: fd + 0.006, depth: 0.006 + 0.004, timber)
        }
        // Terracotta body and cream slip inside the frame.
        FA.box(&m, V3(2 * ho - 0.004, 2 * ho - 0.004, 0.02), V3(0, 0, 0.018), clay, r: 0.0015)
        FA.box(&m, V3(2 * ho - 0.012, 2 * ho - 0.012, 0.004), V3(0, 0, 0.0295), slip, r: 0.0012)
        let top: Float = 0.0315   // slip top surface; scratched design sits level with the clay
        func scratch(_ pts: [V2]) {
            guard pts.count >= 3 else { return }
            FM.prism(&m, pts, front: top + 0.0005, depth: 0.0012, clay, bevel: 0.0003)
        }
        // Central tulip: three petals, calyx, stem and two blades.
        let petal = Shape2D.superellipse(0.1, 0.2, exponent: 2.4, segments: 20)
        scratch(Self.xf(petal, angle: 0, at: V2(0, 0.14)))
        scratch(Self.xf(petal.map { V2($0.x * 0.9, $0.y * 0.92) }, angle: 0.5, at: V2(-0.06, 0.12)))
        scratch(Self.xf(petal.map { V2($0.x * 0.9, $0.y * 0.92) }, angle: -0.5, at: V2(0.06, 0.12)))
        scratch(Self.xf(Shape2D.superellipse(0.14, 0.05, exponent: 2.5, segments: 16), angle: 0, at: V2(0, 0.025)))
        let stem = (0...10).map { i -> V2 in let t = Float(i) / 10; return V2(0.012 * sin(t * 3), -0.28 + t * 0.3) }
        scratch(Self.strip(stem, 0.016))
        for s: Float in [-1, 1] {
            let blade = (0...10).map { i -> V2 in let t = Float(i) / 10; return V2(s * (0.015 + 0.2 * t * (1 - 0.35 * t)), -0.26 + 0.34 * t * t + 0.1 * t) }
            scratch(Self.strip(blade, 0.03 * (1.1 - 0.0)))
        }
        // Dotted hatching beside the tulip.
        for s: Float in [-1, 1] {
            for i in 0..<4 {
                for j in 0..<3 {
                    scratch(Shape2D.circle(0.007, segments: 8).map { $0 + V2(s * (0.19 + Float(j) * 0.04), 0.1 + Float(i) * 0.045) })
                }
            }
        }
        // Border vine: sine path with spiral buds along each side, inset 0.045 from the opening.
        let bo = ho - 0.045
        for k in 0..<4 {
            let r = Float(k) * .pi / 2
            let path = (0...48).map { i -> V2 in
                let t = Float(i) / 48
                return V2(-bo + 0.11 + t * (2 * bo - 0.22), 0.012 * sin(t * 2 * .pi * 6) + bo)
            }
            let line = Self.xf(Self.strip(path, 0.008), angle: r, at: .zero)
            scratch(line)
            for j in 0..<6 {
                let t = (Float(j) + 0.5) / 6
                scratch(Self.xf(Shape2D.superellipse(0.02, 0.034, exponent: 2, segments: 12).map { $0 + V2(-bo + 0.11 + t * (2 * bo - 0.22), bo - 0.027) }, angle: r, at: .zero))
            }
        }
        // Corner rosettes: ring and eight petals.
        for (cx, cy) in [(-1, -1), (1, -1), (1, 1), (-1, 1)] as [(Float, Float)] {
            let c = V2(cx * (ho - 0.055), cy * (ho - 0.055))
            scratch(Shape2D.circle(0.016, segments: 14).map { $0 + c })
            for k in 0..<8 {
                scratch(Self.xf(Shape2D.superellipse(0.016, 0.034, exponent: 2, segments: 10).map { $0 + V2(0, 0.034) }, angle: Float(k) * .pi / 4, at: c))
            }
        }
        // Wear: corner chip exposing clay, sooted run-off, hairline crack, brass screws through the frame.
        scratch([V2(0.2, -0.3), V2(0.235, -0.3), V2(0.24, -0.27), V2(0.215, -0.262)])
        FM.prism(&m, [V2(-0.31, -0.16), V2(-0.30, -0.16), V2(-0.295, 0.0), V2(-0.305, 0.0)], front: top + 0.0012, depth: 0.0006, "stone.limestone-sooted", bevel: 0.0002)
        FM.prism(&m, [V2(-0.12, 0.31), V2(-0.118, 0.31), V2(-0.05, 0.25), V2(-0.052, 0.25)], front: top + 0.0013, depth: 0.0006, "stone.limestone-sooted", bevel: 0.0001)
        // More chips along the slip edge and a hairline crack with efflorescence.
        scratch([V2(-0.33, 0.3), V2(-0.305, 0.3), V2(-0.3, 0.325), V2(-0.325, 0.33)])
        scratch([V2(0.3, 0.06), V2(0.328, 0.05), V2(0.33, 0.085)])
        let crack = (0...8).map { i -> V2 in let t = Float(i) / 8; return V2(0.12 + 0.17 * t + 0.01 * sin(t * 9), -0.33 + 0.3 * t) }
        FM.prism(&m, Self.strip(crack, 0.0016), front: top + 0.0014, depth: 0.0006, "stone.limestone-sooted", bevel: 0.0001)
        // Scratched hatching inside the tulip petals (slip showing through the clay).
        for k in 0..<7 {
            let x = -0.03 + Float(k) * 0.01
            let line = (0...4).map { i -> V2 in let t = Float(i) / 4; return V2(x * (1 + 1.5 * t), 0.1 + 0.15 * t) }
            FM.prism(&m, Self.strip(line, 0.0022), front: top + 0.0014, depth: 0.0006, slip, bevel: 0.0001)
        }
        // Frame dirt line on the bottom rail and a repaired split in the top rail.
        FM.prism(&m, [V2(-0.2, -0.392), V2(0.18, -0.392), V2(0.18, -0.372), V2(-0.2, -0.372)], front: fd + 0.0008, depth: 0.0008, "wood.weathered", bevel: 0.0002)
        FM.prism(&m, [V2(0.05, 0.372), V2(0.0515, 0.372), V2(0.056, 0.395), V2(0.0545, 0.395)], front: fd + 0.0012, depth: 0.0008, "wood.charred", bevel: 0.0001)
        for (sx, sy) in [(-1, -1), (1, -1), (1, 1), (-1, 1), (0, 1), (0, -1)] as [(Float, Float)] {
            let pos = V3(sx * (hi - fw / 2) * (sx == 0 ? 0 : 1), sy * (hi - fw / 2), fd)
            FA.cylZ(&m, r: 0.0065, h: 0.004, at: pos + V3(0, 0, 0.006 - 0.006 + 0.0), "metal.brass-aged", bevel: 0.0012, segments: 12)
            FA.box(&m, V3(0.009, 0.0016, 0.001), pos + V3(0, 0, 0.0045 + 0.0004), "metal.rust", r: 0.0003, rot: FA.q(Float(rng.int(0...5)) * 30, FA.Z))
        }
        groundAO(&m, height: 0.1, floor: 0.9)
        return LODModel(FC.place(m))
    }
}
