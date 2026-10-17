import simd
import Foundation

/// Flemish bond brick panel, Georgian: each course alternates stretchers and burnt headers, closers at
/// the reveals, tuck-pointed lime mortar, over a rubbed-brick plinth course and a stone base course.
public struct FlemishBondBrickPanel: RealAsset {
    public static let id = "flemish-bond-brick-panel"
    public static let summary = "Flemish bond brick panel: stretchers alternating with burnt headers each course, struck lime joints, rubbed plinth and stone base."
    public static let tags = ["prop", "architecture", "facade", "stone"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 10, distance: 2.2)

    /// Panel width (m).
    public var width: Float = 1.2
    /// Panel height (m).
    public var height: Float = 1.2
    /// Stretcher bricks (tints cycled).
    public var stretchers: [MaterialKey] = ["stone.sandstone:9C4A32", "stone.sandstone:8C4230", "stone.sandstone:A85A3E", "stone.sandstone:7E3E2C"]
    /// Burnt headers.
    public var header: MaterialKey = "stone.sandstone:4A2E28"
    /// Lime mortar.
    public var mortar: MaterialKey = "concrete.smooth:CFC5AE"
    /// Stone base course.
    public var stone: MaterialKey = "stone.limestone"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let L: Float = 0.215, H: Float = 0.065, D: Float = 0.1025, hd: Float = 0.1025, j: Float = 0.01
        let base: Float = 0.15, depth: Float = 0.11
        // stone base course with weathered top chamfer
        FA.box(&m, V3(width, base, depth + 0.01), V3(0, base / 2, (depth + 0.01) / 2), stone, r: 0.008)
        // mortar bed, recessed 5 mm behind the brick face (struck joint)
        FA.box(&m, V3(width - 0.004, height - base, depth - 0.006), V3(0, base + (height - base) / 2, (depth - 0.006) / 2), mortar, r: 0.002)
        let unit = L + j + hd + j
        var y = base + j
        var course = 0
        while y + H <= height + 0.001 {
            let off: Float = course % 2 == 0 ? 0 : (L + j) / 2 + hd / 4
            var x = -width / 2 - off - unit
            var k = 0
            while x < width / 2 {
                for (len, isHeader) in [(L, false), (hd, true)] {
                    let x0 = max(x, -width / 2 + 0.001), x1 = min(x + len, width / 2 - 0.001)
                    if x1 - x0 > 0.02 {
                        var r = rng.fork(course * 100 + k)
                        var mat: MaterialKey = isHeader ? header : stretchers[r.int(0...stretchers.count - 1)]
                        if course == 0 { mat = "stone.sandstone:B0654A" }  // rubbed plinth course
                        else if course < 3 && r.chance(0.18) { mat = "stone.sandstone:B8A08E" }  // efflorescence
                        else if course > 10 && r.chance(0.1) { mat = "stone.sandstone:4C3530" }  // soot
                        let w = x1 - x0 - 0.001
                        FA.box(&m, V3(w, H + r.float(-0.002...0.0), D), V3((x0 + x1) / 2, y + H / 2 + r.float(-0.0008...0.0008),
                               depth - D / 2 + r.float(-0.0015...0.0)), mat, r: isHeader ? 0.004 : 0.003)
                    }
                    x += len + j
                    k += 1
                }
            }
            y += H + j
            course += 1
        }
        groundAO(&m, height: 0.15, floor: 0.85)
        return LODModel(FC.place(m))
    }
}
