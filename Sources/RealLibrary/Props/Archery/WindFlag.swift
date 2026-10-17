import simd
import Foundation

/// Range wind flag: orange-and-white nylon streamer pennant 1.0 m long blowing slightly toward +X, tapered white pole, black rubber base. Parts: pole, base, pennant, grommets, pole cap.
public struct WindFlag: RealAsset {
    public static let id = "wind-flag"
    public static let summary = "Range wind flag: tapered fiberglass pole on a weighted base with a draped nylon pennant."
    public static let tags = ["prop", "archery", "outdoor", "fabric"]
    public static let budget = 10000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(1.08, 2.58, 0.39)
    /// Pennant length in meters, pole to tip.
    public var pennantLength: Float = 0.86
    /// Pennant height at the pole in meters.
    public var pennantHeight: Float = 0.28
    /// Band colours (hex tints), alternating from the top.
    public var bandTints: [String] = ["E8650E", "F4F2EC", "E8650E", "F4F2EC"]
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Centered on X: the pole stands at x = -(pennant + base overhang) / 2 so bounds center on the origin.
        let dx = -(pennantLength + 0.027 - 0.195) / 2
        func put(_ s: Surface, _ x: Xform) { var y = x; y.translation += V3(dx, 0, 0); m.add(s, y) }
        let rubber: MaterialKey = "rubber.insulating-black", white: MaterialKey = "plastic.white", zinc: MaterialKey = "metal.galvanized"
        let poleTop: Float = 2.55, baseH: Float = 0.10
        // Weighted rubber base: low dome with a rim and a socket collar.
        put(Prim.lathe([V2(0, 0), V2(0.18, 0), V2(0.195, 0.010), V2(0.19, 0.03), V2(0.15, 0.052), V2(0.07, 0.072), V2(0.03, 0.10), V2(0, 0.10)],
                         segments: 40, seamTile: 0.3, material: rubber), .identity)
        put(Prim.torus(major: 0.17, minor: 0.006, segments: 40, sides: 6, material: rubber), Xform(translation: V3(0, 0.017, 0)))
        put(HuntKit.cyl(V3(0, 0.07, 0), V3(0, 0.15, 0), r: 0.0205, bevel: 0.003, seg: 20, zinc), .identity)
        // Tapered fiberglass pole in two sections with a ferrule joint.
        let pole = Prim.lathe([V2(0, baseH), V2(0.0165, baseH), V2(0.0150, 1.3), V2(0.0112, 1.31), V2(0.0108, poleTop - 0.012),
                               V2(0.0085, poleTop - 0.004), V2(0, poleTop)], segments: 20, seamTile: 0.1, material: white)
        put(pole, .identity)
        put(HuntKit.cyl(V3(0, 1.27, 0), V3(0, 1.34, 0), r: 0.0172, bevel: 0.002, seg: 20, zinc), .identity)
        // Cap ball.
        put(Prim.lathe([V2(0, poleTop - 0.006), V2(0.0085, poleTop - 0.006), V2(0.0115, poleTop + 0.004), V2(0.0105, poleTop + 0.014), V2(0.006, poleTop + 0.02), V2(0, poleTop + 0.022)],
                         segments: 16, seamTile: 0.05, material: white), .identity)
        // Pennant: four colour bands swept along one wavy path, tapering to a narrow tip.
        let H = pennantHeight, L = pennantLength, yc = poleTop - H / 2 - 0.03, t: Float = 0.002
        let n = 24
        var path: [V3] = []
        for i in 0...n {
            let s = Float(i) / Float(n)
            path.append(V3(0.022 + L * s, yc - 0.07 * s * s, 0.04 * sin(2 * Float.pi * 1.15 * s) * s))
        }
        let scales: [Float] = (0...n).map { 1 - 0.78 * (Float($0) / Float(n)) }
        let bh = H / Float(bandTints.count)
        for (k, tint) in bandTints.enumerated() {
            let c = H / 2 - bh * (Float(k) + 0.5) - 0.0003 * Float(k)
            let prof = [V2(c - bh / 2 + 0.0002, -t / 2), V2(c + bh / 2 - 0.0002, -t / 2), V2(c + bh / 2 - 0.0002, t / 2), V2(c - bh / 2 + 0.0002, t / 2)]
            put(Prim.sweep(prof, along: path, up: V3(0, 1, 0), scales: scales, closedPath: false, caps: true, grainAlongPath: true,
                             material: MaterialKey("fabric.nylon:" + tint)), .identity)
        }
        // Hem stitching along the top and bottom edges.
        for sgn: Float in [1, -1] {
            let edge = path.enumerated().map { (i, p) -> V3 in V3(p.x, p.y + sgn * (H / 2 - 0.008) * scales[i], p.z + t) }
            put(stitches(along: Array(edge[0..<20]), normal: { _ in V3(0, 0, 1) }, pitch: 0.008, material: "fabric.nylon:F4F2EC"), .identity)
        }
        // Grommets at the pole edge plus ties around the pole.
        for dy: Float in [0.085, -0.085] {
            put(Prim.torus(major: 0.0075, minor: 0.0022, segments: 16, sides: 6, material: zinc),
                  Xform(translation: V3(0.026, yc + dy, 0.0), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
            put(Prim.torus(major: 0.0135, minor: 0.0016, segments: 16, sides: 6, material: zinc), Xform(translation: V3(0, yc + dy, 0)))
        }
        _ = rng.float()
        groundAO(&m)
        return LODModel(m)
    }
}
