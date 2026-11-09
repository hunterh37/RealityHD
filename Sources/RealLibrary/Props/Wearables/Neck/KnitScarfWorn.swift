import simd
import Foundation

/// Chunky rib-knit scarf worn at the base of the neck: two bulky wraps around a 38 cm neck, a long front tail and a
/// shorter tail with cream end stripes and hand-knotted fringe. Raised 8 mm rib geometry runs the full length of
/// the scarf, the wraps sag toward the front, and one fringe strand is twisted back on itself.
public struct KnitScarfWorn: RealAsset {
    public static let id = "knit-scarf-worn"
    public static let summary = "Worn chunky rib-knit scarf: two neck wraps, two striped tails with knotted fringe."
    public static let tags = ["prop", "wearable", "worn", "fabric", "knit", "wool"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 10, distance: 0.8, ground: false, studio: true)

    /// Main yarn.
    public var yarn: MaterialKey = "fabric.knit:5C1D28"
    /// Stripe yarn.
    public var stripe: MaterialKey = "fabric.knit:D8CDB5"
    /// Scarf width (m).
    public var width: Float = 0.16
    public init() {}

    /// Width-across rib profile: rounded selvedge ends, raised ribs on both faces.
    static func ribProfile(width w: Float, thick t: Float, pitch: Float, amp: Float) -> [V2] {
        var pts: [V2] = []
        let inner = w - t
        let n = max(2, Int((inner / (pitch / 2)).rounded()))
        for k in 0...n {
            let x = -inner / 2 + inner * Float(k) / Float(n)
            pts.append(V2(x, t / 2 + amp * cos(2 * .pi * x / pitch)))
        }
        for k in 1..<5 { let a = .pi / 2 - Float(k) / 5 * .pi; pts.append(V2(inner / 2 + cos(a) * t / 2, sin(a) * t / 2)) }
        for k in stride(from: n, through: 0, by: -1) {
            let x = -inner / 2 + inner * Float(k) / Float(n)
            pts.append(V2(x, -t / 2 - amp * cos(2 * .pi * x / pitch)))
        }
        for k in 1..<5 { let a = -.pi / 2 - Float(k) / 5 * .pi; pts.append(V2(-inner / 2 + cos(a) * t / 2, sin(a) * t / 2)) }
        return Shape2D.deduped(pts)
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Wraps: two bulky folded loops, the outer one riding higher and sagging to the front.
        func loopPath(y: Float, rx: Float, rz: Float, sag: Float, count: Int) -> [V3] {
            (0..<count).map { k in
                let th = 2 * Float.pi * Float(k) / Float(count)
                let f = (1 + cos(th)) / 2
                return V3(sin(th) * rx, y - sag * f * f + 0.003 * sin(th * 3 + 1), cos(th) * rz)
            }
        }
        let wrap1 = Prim.sweep(Self.ribProfile(width: 0.088, thick: 0.030, pitch: 0.012, amp: 0.0016),
                               along: loopPath(y: 0.030, rx: 0.088, rz: 0.083, sag: 0.012, count: 44), up: .up,
                               closedPath: true, caps: false, material: yarn)
        let wrap2 = Prim.sweep(Self.ribProfile(width: 0.080, thick: 0.026, pitch: 0.012, amp: 0.0016),
                               along: loopPath(y: 0.062, rx: 0.098, rz: 0.094, sag: 0.022, count: 44), up: .up,
                               closedPath: true, caps: false, material: yarn)
        m.add(wrap1); m.add(wrap2)
        // Tails hang from the front of the wraps.
        // Straight tails with a gentle forward curve; drape wobble is applied per section after sweeping.
        func tailPath(x0: Float, z0: Float, drop: Float, drift: Float, count: Int) -> [V3] {
            (0..<count).map { k in
                let t = Float(k) / Float(count - 1)
                return V3(x0, 0.02 - drop * t, z0 + 0.016 * t * t)
            }
        }
        func tail(_ path: [V3], width w: Float, drift: Float, drop: Float, ranges: [(Float, Float, MaterialKey)]) {
            let prof = Self.ribProfile(width: w, thick: 0.012, pitch: 0.012, amp: 0.0014)
            for (a, b, mat) in ranges {
                let ia = Int(a * Float(path.count - 1)), ib = max(ia + 1, Int((b * Float(path.count - 1)).rounded()))
                let seg = Array(path[ia...min(ib, path.count - 1)])
                var surf = Prim.sweep(prof, along: seg, up: V3(1, 0, 0.0), caps: true, material: mat)
                surf.deform { p in
                    let t = saturate((0.02 - p.y) / drop)
                    return V3(p.x + drift * sin(t * 2.4) + 0.004 * sin(t * 9) + 0.01 * p.z * 0, p.y, p.z + 0.004 * sin(t * 5 + p.x * 20) * t)
                }
                m.add(surf)
            }
        }
        let p1 = tailPath(x0: 0.012, z0: 0.108, drop: 0.37, drift: 0.018, count: 24)
        // Stripe pair near the end: sections are cut at path indices.
        tail(p1, width: width, drift: 0.018, drop: 0.37, ranges: [(0, 17.0 / 23, yarn), (17.0 / 23, 18.0 / 23, stripe), (18.0 / 23, 20.0 / 23, yarn), (20.0 / 23, 21.0 / 23, stripe), (21.0 / 23, 1, yarn)])
        let p2 = tailPath(x0: -0.046, z0: 0.098, drop: 0.26, drift: -0.014, count: 22)
        tail(p2, width: width * 0.94, drift: -0.014, drop: 0.26, ranges: [(0, 16.0 / 21, yarn), (16.0 / 21, 18.0 / 21, stripe), (18.0 / 21, 1, yarn)])
        // Fringe: knotted tufts hanging from the bottom edge of each tail.
        func fringe(_ end: V3, half w: Float, tufts: Int, len: Float) {
            for i in 0..<tufts {
                let x = -w + 2 * w * (Float(i) + 0.5) / Float(tufts)
                let base = end + V3(x, -0.004, 0.0)
                for _ in 0..<2 {
                    let l = len * rng.float(0.88...1.08), j = rng.float(-0.004...0.004)
                    let path = [base, base + V3(j * 0.3, -l * 0.35, 0.002), base + V3(j, -l * 0.7, 0.003 + j * 0.2), base + V3(j * 1.6, -l, 0.001)]
                    m.add(Prim.tube(path, radii: [0.0017, 0.0016, 0.0015, 0.0011], sides: 5, seamTile: 0.01, material: yarn, capEnd: true))
                }
            }
        }
        fringe(p1.last! + V3(0.018 * sin(2.4), 0, 0), half: width / 2 - 0.004, tufts: 14, len: 0.05)
        fringe(p2.last! + V3(-0.014 * sin(2.4), 0, 0), half: width * 0.47 - 0.004, tufts: 13, len: 0.05)
        // Story detail: one strand twisted back on itself.
        let e = p1.last! + V3(0.018 * sin(2.4) + 0.02, -0.004, 0.003)
        let curl = catmull([e, e + V3(0.002, -0.02, 0.004), e + V3(0.012, -0.034, 0.008), e + V3(0.018, -0.02, 0.01), e + V3(0.01, -0.014, 0.006)], per: 4)
        m.add(Prim.tube(curl, radii: curl.map { _ in 0.0017 }, sides: 5, seamTile: 0.01, material: stripe, capEnd: true))
        return LODModel(m)
    }
}
