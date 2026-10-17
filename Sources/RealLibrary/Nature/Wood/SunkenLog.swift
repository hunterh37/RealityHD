import simd
import Foundation

/// Waterlogged sunken log, 5 m: a fallen sycamore trunk stripped of bark, dark tea-stained wood under a slimy
/// algae film on top, half buried in the bed, with a root wad of 8 to 12 broken roots at the butt. Classic
/// river cover. 3 LODs.
public struct SunkenLog: RealAsset {
    public static let id = "sunken-log"
    public static let summary = "Sunken waterlogged log, 5 m: bark gone, dark slimy wood with algae on top, half buried, broken root wad at the butt, 3 LODs."
    public static let tags = ["nature", "wood", "water", "river"]
    public static let budget = 9_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 22, distance: 0.8)

    public var length: Float = 5
    public var buttDiameter: Float = 0.55
    public var topDiameter: Float = 0.3
    /// Depth the log has settled into the riverbed.
    public var sink: Float = 0.14
    public var roots: ClosedRange<Int> = 8...12
    public var wood: MaterialKey = "wood.waterlogged"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let log = FallenLog().with {
            $0.length = length; $0.buttDiameter = buttDiameter; $0.topDiameter = topDiameter; $0.sink = sink
            $0.peeled = 0.6; $0.branchStubs = 3; $0.bark = wood; $0.wood = wood; $0.end = "wood.driftwood-end"
        }.build(seed: seed)
        // Root wad at the butt (-X end), fanned in the YZ plane and bent back along the trunk.
        let L = length, r0 = buttDiameter / 2
        var wad = Surface(material: wood), wad1 = Surface(material: wood)
        let n = rng.int(roots)
        for i in 0..<n {
            let a = Float(i) / Float(n) * 2 * .pi + rng.float(-0.3...0.3)
            let dir = V3(-rng.float(0.5...1.0), cos(a) * 0.7, sin(a))
            let len = rng.float(0.35...0.8), rr = rng.float(0.05...0.09)
            let base = V3(-L / 2 + 0.1, r0 - sink, 0) + V3(0, cos(a), sin(a)) * r0 * 0.7
            var pts: [V3] = []
            for k in 0...4 {
                let t = Float(k) / 4
                let p = base + simd_normalize(dir) * len * t + V3(0.25 * t * t, -0.3 * t * t, 0) + V3(rng.float(-0.04...0.04), rng.float(-0.04...0.04), rng.float(-0.04...0.04)) * t
                pts.append(V3(p.x, max(p.y, -sink * 0.5), p.z))
            }
            let radii = (0...4).map { rr * (1 - 0.8 * Float($0) / 4) }
            wad.append(Prim.tube(pts, radii: radii, sides: 6, seamTile: 0.3, material: wood, capEnd: true))
            if i % 2 == 0 { wad1.append(Prim.tube([pts[0], pts[2], pts[4]], radii: [radii[0], radii[2], radii[4]], sides: 4, seamTile: 0.3, material: wood, capEnd: true)) }
        }
        var levels = log.levels
        if levels.count > 0 { levels[0].add(wad) }
        if levels.count > 1 { levels[1].add(wad1) }
        return LODModel(levels: levels, switchDistances: log.switchDistances)
    }
}
