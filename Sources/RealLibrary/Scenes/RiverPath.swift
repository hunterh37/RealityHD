import simd
import Foundation

/// River reach geometry for `mulberry-river`, shared by the scene builder and apps: a centerline polyline in
/// the XZ plane (flow toward +X, water surface y = 0), channel width and maximum depth per sample, and
/// named fishing spots. Apps use it for current, fish habitat and boat bounds.
public struct RiverPath: Sendable {
    /// One cross-section sample along the centerline.
    public struct Sample: Sendable {
        /// Centerline point (x, z) in meters.
        public var center: V2
        /// Unit flow direction (x, z).
        public var tangent: V2
        /// Wetted width in meters.
        public var width: Float
        /// Maximum depth at this section in meters (thalweg).
        public var depth: Float
        /// Thalweg offset from the centerline toward +normal (left bank, north) in meters.
        public var thalweg: Float
        /// Surface current speed in m/s (faster over riffles).
        public var current: Float
    }

    public var samples: [Sample]
    /// Named spots at the water surface: `pool-bluff`, `riffle-upper`, `eddy-gravel`, `logjam`, `tailout`.
    public var spots: [String: V3]
    /// Reach length along X in meters.
    public var length: Float

    /// Mulberry River reach: 400 m, 20 m wide, pools to 5.2 m and riffles to 0.35 m.
    public static func mulberry(length: Float = 400, width: Float = 20) -> RiverPath {
        // Depth keyframes along x: riffle-upper, the bluff pool, the gravel-bar run, a riffle, the logjam pool, the tailout.
        // Ozark pools scour to 4-5 m under bluffs and logjams; runs hold 1.5-2.5 m; riffles drop to 0.35 m.
        let keys: [(Float, Float)] = [(-200, 1.4), (-165, 0.8), (-125, 0.35), (-105, 1.2), (-80, 3.2), (-48, 5.2), (-30, 4.6),
                                      (-10, 3.0), (20, 1.9), (45, 2.4), (72, 0.4), (90, 1.1), (108, 3.6), (118, 4.4), (140, 2.6),
                                      (162, 1.2), (175, 0.5), (200, 1.6)]
        func depth(_ x: Float) -> Float {
            guard let i = keys.lastIndex(where: { $0.0 <= x }), i + 1 < keys.count else { return keys.last!.1 }
            let (x0, d0) = keys[i], (x1, d1) = keys[i + 1]
            return d0 + (d1 - d0) * smoothstep(x0, x1, x)
        }
        func zc(_ x: Float) -> Float { 7 * sin(x / 70 + 0.6) + 3 * sin(x / 31 + 1.7) }
        var s: [Sample] = []
        let n = Int(length / 2)
        for i in 0...n {
            let x = -length / 2 + Float(i) * 2
            let c = V2(x, zc(x)), t = simd_normalize(V2(1, (zc(x + 0.5) - zc(x - 0.5))))
            let d = depth(x)
            // Riffles spread wide and shallow; pools pinch slightly. The pool thalweg hugs the north bluff.
            let w = width * (1 + 0.18 * (1 - smoothstep(0.3, 1.5, d)) - 0.08 * smoothstep(1.5, 2.5, d))
            let th = -w * 0.22 * smoothstep(1.2, 2.4, d) * (x < 20 ? 1 : -0.6)
            let q: Float = 6 / max(w * d * 0.6, 1.5)
            s.append(Sample(center: c, tangent: t, width: w, depth: d, thalweg: th, current: min(1.4, q * 0.35 + 0.08)))
        }
        func spot(_ x: Float, side: Float) -> V3 { V3(x, 0, zc(x) + side) }
        let spots: [String: V3] = [
            "riffle-upper": spot(-125, side: 0),
            "pool-bluff": spot(-40, side: -4),
            "eddy-gravel": spot(32, side: 6),
            "logjam": spot(115, side: -7),
            "tailout": spot(170, side: 0),
        ]
        return RiverPath(samples: s, spots: spots, length: length)
    }

    /// Sample nearest to x (samples are evenly spaced along X).
    public func sample(atX x: Float) -> Sample {
        let f = (x + length / 2) / length * Float(samples.count - 1)
        let i = max(0, min(samples.count - 1, Int(f.rounded())))
        return samples[i]
    }

    /// Signed lateral offset of p from the centerline (positive toward +Z, the south bank) and the section there.
    public func lateral(_ p: V2) -> (offset: Float, sample: Sample) {
        let s = sample(atX: p.x)
        return (p.y - s.center.y, s)
    }

    /// Bed depth below the water surface at p (0 or less outside the channel).
    public func bedDepth(_ p: V2) -> Float {
        let (d, s) = lateral(p)
        let half = s.width / 2
        let u = (d - s.thalweg * (1 - abs(d) / half)) / half
        let k = max(0, 1 - u * u)
        // Steep cut banks, a flatter floor, and scour holes / ledges so depth changes across short distances.
        let scour = 1 + 0.22 * sin(p.x * 0.21 + p.y * 0.37) * sin(p.x * 0.083 - p.y * 0.19)
            + 0.12 * sin(p.x * 0.53 + 1.3) * sin(p.y * 0.61)
        return s.depth * pow(k, 0.38) * max(0.6, scour)
    }

    /// True when p is on open water.
    public func inChannel(_ p: V2) -> Bool { abs(lateral(p).offset) < sample(atX: p.x).width / 2 }

    /// Surface current at p in m/s along the flow, slower toward the banks.
    public func current(_ p: V2) -> V2 {
        let (d, s) = lateral(p)
        let edge = max(0, 1 - pow(abs(d) / (s.width / 2), 2))
        return s.tangent * s.current * edge
    }
}
