import simd
import Foundation

/// Field horsetail (Equisetum arvense) patch, ~45 cm across: 22 to 30 hollow jointed stems 15 to 50 cm
/// tall, dark toothed sheaths at each node and whorls of thin upward-arching branchlets that shorten toward the tip.
public struct HorsetailPatch: RealAsset {
    public static let id = "horsetail-patch"
    public static let summary = "Field horsetail patch, ~45 cm across: 22-30 jointed green stems 15-50 cm with dark node sheaths and whorled branchlets; 2 LODs."
    public static let tags = ["nature", "plant", "ground"]
    public static let budget = 6_400
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 35, distance: 0.6)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let phase = rng.float(0...6.28)
        var levels = [Model(name: Self.id), Model(name: Self.id)]
        let n = rng.int(22...30)
        for c in 0..<n {
            var r = rng.fork(c + 1)
            let a = r.float(0...6.28), rad = 0.22 * sqrt(r.float())
            let h = r.float(0.15...0.5) * (1 - 0.35 * rad / 0.22)
            let base = V3(cos(a) * rad, -0.004, sin(a) * rad)
            let yaw = r.float(0...6.28)
            let lean = r.float(0.02...0.2) + 0.2 * rad / 0.22
            let nodes = max(4, Int(h / 0.06)), count = nodes + 1
            let pts = PlantKit.arc(from: base, height: h, yaw: yaw, lean: lean, bend: r.float(0...0.2), count: count)
            let ph = phase + r.float(0...0.5)
            let tint = r.chance(0.5) ? "plant.stem:6E8F48" : "plant.stem:5C7C3A"
            let stemR = r.float(0.0016...0.0028)
            levels[0].add(PlantKit.stem(pts, radius: stemR, tipRadius: stemR * 0.45, sides: 5, weight: V2(0, 0.75), phase: ph, material: tint))
            levels[1].add(PlantKit.stem(pts, radius: stemR, tipRadius: stemR * 0.45, sides: 3, weight: V2(0, 0.75), phase: ph, material: tint))
            for i in 1..<count {
                let t = Float(i) / Float(count - 1)
                let rr = stemR * (1 - 0.55 * t)
                let ax = simd_normalize(pts[min(i + 1, count - 1)] - pts[i - 1])
                // dark sheath
                var sh = Prim.tube([pts[i] - ax * 0.004, pts[i] + ax * 0.006], radii: [rr * 1.5, rr * 1.2], sides: 5, seamTile: 0.01,
                                   material: "plant.stem:4A3E2A", weights: [0.1 + 0.6 * t, 0.1 + 0.6 * t], phase: ph, capEnd: false)
                sh.occlusion = Array(repeating: 0.8, count: sh.positions.count)
                levels[0].add(sh)
                // whorl of branchlets, shorter and steeper toward the tip
                let bl = r.float(0.025...0.06) * (1 - 0.6 * t), k = r.int(3...4)
                let up = simd_normalize(simd_cross(ax, V3(0, 1, 0)).y == 0 ? V3(1, 0, 0) : simd_cross(ax, V3(0, 1, 0)))
                let side = simd_normalize(simd_cross(ax, up))
                for j in 0..<k {
                    let ang = (Float(j) + r.float(-0.25...0.25)) / Float(k) * 2 * .pi
                    let out = simd_normalize(up * cos(ang) + side * sin(ang))
                    let d0 = simd_normalize(out * 0.9 + ax * (0.5 + 0.6 * t) + V3(0, 0.1, 0))
                    let p0 = pts[i] + out * rr
                    let p2 = p0 + d0 * bl * 0.6 + simd_normalize(d0 + V3(0, 0.45, 0) + ax * 0.3) * bl * 0.45
                    var br = PlantKit.stem([p0, p2], radius: 0.0007, tipRadius: 0.0003, sides: 3, weight: V2(0.4, 0.95), phase: ph + Float(j) * 0.2, material: tint)
                    br.occlusion = Array(repeating: 0.9, count: br.positions.count)
                    levels[0].add(br)
                }
            }
            // fertile-looking cone on a few tall stems
            if h > 0.35 && r.chance(0.25) {
                let top = pts[count - 1], ax = simd_normalize(pts[count - 1] - pts[count - 2])
                var cone = Prim.tube([top - ax * 0.02, top, top + ax * 0.012], radii: [stemR * 0.5, stemR * 1.5, stemR * 0.3], sides: 5, seamTile: 0.01,
                                     material: "plant.stem:7A6A48", weights: [0.7, 0.8, 0.85], phase: ph, capEnd: true)
                cone.occlusion = Array(repeating: 0.95, count: cone.positions.count)
                levels[0].add(cone); levels[1].add(cone)
            }
        }
        for l in levels.indices { PlantKit.finish(&levels[l]) }
        return LODModel(levels: levels, switchDistances: [6])
    }
}
