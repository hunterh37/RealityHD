import simd
import Foundation

/// Allotment potato ridge rows: four earthed-up ridges at 50 cm centres along X with hoed furrows
/// between, a line of potato haulms on each crest (branched stems carrying pinnate leaves of oval
/// leaflets), clods slumped down the flanks and stones in the furrows.
public struct AllotmentPotatoRidgeRows: RealAsset {
    public static let id = "allotment-potato-ridge-rows"
    public static let summary = "Earthed-up potato ridges: four soil ridges with furrows between, leafy potato haulms along each ridge crest."
    public static let tags = ["prop", "architecture", "facade", "ground", "garden", "outdoor"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 32, distance: 2.8, studio: true)

    /// Tile footprint (m).
    public var width: Float = 2.0
    public var depth: Float = 2.0
    /// Number of ridges and their spacing (m).
    public var ridges: Int = 4
    public var spacing: Float = 0.5
    /// Ridge crest height above the furrow floor (m).
    public var ridgeHeight: Float = 0.11
    /// Haulms per ridge.
    public var plantsPerRow: Int = 4
    /// Leaflet material (tinted stem shader).
    public var foliage: MaterialKey = "plant.stem:2E4820"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let sd = UInt32(truncatingIfNeeded: rng.int(0...99_999))
        let w = width, d = depth, base: Float = 0.02
        let z0 = -Float(ridges - 1) * spacing / 2
        func h(_ p: V2) -> Float {
            let u = (p.y - z0) / spacing
            let k = (u - (u).rounded()) * 2 // -1...1 across one ridge pitch
            let wob = 0.04 * Noise.fbm(V3(p.x * 1.5, 0, 0), octaves: 2, seed: sd)
            let r = AK.ridge((k + wob) / 0.85) * ridgeHeight
            let lump = 0.01 * Noise.fbm(V3(p.x * 8, 0, p.y * 8), octaves: 4, seed: sd + 1) + 0.005 * Noise.ridged(V3(p.x * 25, 0, p.y * 25), octaves: 2, seed: sd + 2)
            let e = min(w / 2 - abs(p.x), d / 2 - abs(p.y))
            let f = max(0, min(1, (e - 0.05) / 0.15))
            return base + 0.008 + (r * f + lump)
        }
        var m = Model(name: Self.id)
        AK.field(&m, w: w, d: d, base: base, segments: 40, h)
        // Haulms on the crests.
        for row in 0..<ridges {
            let zc = z0 + Float(row) * spacing
            for i in 0..<plantsPerRow {
                var r = rng.fork(row * 100 + i)
                let x = -w / 2 + 0.25 + (Float(i) + r.float(-0.15...0.15)) * (w - 0.5) / Float(plantsPerRow - 1)
                guard abs(x) < w / 2 - 0.1 else { continue }
                let root = V3(x, h(V2(x, zc)) - 0.01, zc + r.float(-0.03...0.03))
                let stems = r.int(4...5)
                for s in 0..<stems {
                    let yaw = Float(s) / Float(stems) * 2 * .pi + r.float(-0.4...0.4)
                    let pts = PlantKit.arc(from: root, height: r.float(0.12...0.17), yaw: yaw, lean: r.float(0.45...0.8), bend: 0.5, count: 5)
                    m.add(PlantKit.stem(pts, radius: 0.005, tipRadius: 0.003, sides: 4, weight: V2(0, 1), phase: 0, material: "plant.stem:5C6B3A"))
                    // Pinnate leaf: terminal leaflet plus three pairs along the upper stem.
                    let tip = pts[pts.count - 1]
                    let dir = simd_normalize(tip - pts[pts.count - 2])
                    let ty = atan2(dir.z, dir.x)
                    m.add(AK.leaflet(tip, dir: dir + V3(0, -0.3, 0), length: 0.08, width: 0.05, material: foliage))
                    for j in 2..<pts.count - 1 {
                        let p = pts[j]
                        for side: Float in [-1, 1] {
                            let a = ty + side * r.float(1.1...1.5)
                            m.add(AK.leaflet(p, dir: V3(cos(a), r.float(-0.25...0.05), sin(a)), length: r.float(0.065...0.08), width: 0.047, material: foliage))
                        }
                    }
                }
            }
        }
        // Clods slumped down the flanks; stones lying in the furrows.
        for i in 0..<40 {
            var r = rng.fork(5000 + i)
            let row = Float(r.int(0...ridges - 1))
            let side: Float = r.chance(0.5) ? -1 : 1
            let p = V2(r.float(-w / 2 + 0.12...w / 2 - 0.12), z0 + row * spacing + side * r.float(0.06...0.2))
            AK.clod(&m, at: p, y: h(p) - 0.006, size: r.float(0.03...0.07), rng: &r, material: r.chance(0.35) ? AK.dryClod : AK.clod)
        }
        for i in 0..<20 {
            var r = rng.fork(8000 + i)
            let row = Float(r.int(0...ridges))
            let p = V2(r.float(-w / 2 + 0.08...w / 2 - 0.08), z0 + (row - 0.5) * spacing + r.float(-0.05...0.05))
            guard abs(p.y) < d / 2 - 0.06 else { continue }
            AK.stone(&m, at: p, y: h(p) - 0.005, size: r.float(0.018...0.045), rng: &r)
        }
        var lite = Model(name: Self.id + "-lite")
        AK.field(&lite, w: w, d: d, base: base, segments: 32, h)
        return AK.finish(&m, lite: lite, ao: 0.12)
    }
}
