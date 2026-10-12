import simd
import Foundation

/// Mission Revival shaped parapet: a 2.2 m stucco wall head with a semicircular central gable, concave
/// shoulders, end piers with round heads, a curved clay coping, a quatrefoil of clay rings, a belt
/// course, a base cornice and a metal scupper with a rain stain below it.
public struct MissionShapedParapet: RealAsset {
    public static let id = "mission-shaped-parapet"
    public static let summary = "Mission Revival shaped parapet, 2.2 m: stucco ogee profile, clay coping, quatrefoil, belt course, scupper."
    public static let tags = ["prop", "architecture", "facade", "trim", "decor", "stone"]
    public static let budget = 14_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 10, distance: 3.2)

    public var width: Float = 2.2
    public var wallThickness: Float = 0.24
    public var stucco: MaterialKey = "paint.stucco:DCC8A0"
    public var clay: MaterialKey = "ceramic.terracotta"
    public init() {}

    /// Half outline (x >= 0) from the base up the pier, along the shoulder, up the concave cove and over the gable crown.
    static func halfProfile(_ hw: Float) -> [V2] {
        var p: [V2] = [V2(hw, 0), V2(hw, 0.6)]
        // End pier round head: semicircle r 0.1 centred (hw - 0.1, 0.6).
        let pr: Float = 0.1
        for i in 1...8 {
            let a = Float(i) * .pi / 8
            p.append(V2(hw - pr + pr * cos(a), 0.6 + pr * sin(a)))
        }
        p.append(V2(hw - 2 * pr, 0.52))
        p.append(V2(0.54, 0.52))
        // Concave cove: centre (0.38 + r, 0.72), 270 -> 180 degrees (rising toward the gable).
        let r: Float = 0.16
        for i in 0...8 {
            let a = (270 - Float(i) * 90 / 8) * .pi / 180
            p.append(V2(0.38 + r + r * cos(a), 0.68 + r * sin(a)))
        }
        // Gable crown: semicircle r 0.38 centred (0, 0.72), 0 -> 90 degrees.
        for i in 1...16 {
            let a = Float(i) * 90 / 16 * .pi / 180
            p.append(V2(0.38 * cos(a), 0.68 + 0.38 * sin(a)))
        }
        return p
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let hw = width / 2, T = wallThickness, zc: Float = 0.15
        let half = Self.halfProfile(hw)
        // Full outline counter-clockwise: right half going up, mirrored left half coming down.
        var outline = half
        for p in half.reversed() where p.x > 0.0001 { outline.append(V2(-p.x, p.y)) }
        outline.append(V2(-hw, 0))
        let clean = Shape2D.deduped(outline)
        m.add(Prim.extrude(clean, depth: T, bevel: 0.008, bevelSegments: 2, material: stucco), Xform(translation: V3(0, 0, zc)))

        // Clay coping swept over the crest (flat 0.28 x 0.05 section, outer edge rounded).
        let crest = half.filter { $0.y >= 0.5 }
        var path: [V3] = []
        for p in crest.reversed() { path.append(V3(-p.x, p.y + 0.018, zc)) }
        for p in crest.dropFirst(0) { path.append(V3(p.x, p.y + 0.018, zc)) }
        let dedup = path.enumerated().filter { $0.offset == 0 || simd_length($0.element - path[$0.offset - 1]) > 0.004 }.map { $0.element }
        let prof = Shape2D.rounded([V2(-0.14, -0.022), V2(0.14, -0.022), V2(0.14, 0.022), V2(-0.14, 0.022)], radius: 0.01)
        m.add(Prim.sweep(prof, along: dedup, up: V3(0, 0, 1), caps: true, material: clay))
        // Tile joints: raised mortar ribs across the coping every ~0.24 m of path, turned to the local tangent.
        var acc: Float = 0, nextAt: Float = 0.12
        for i in 1..<dedup.count {
            let seg = dedup[i] - dedup[i - 1], len = simd_length(seg)
            acc += len
            if acc >= nextAt {
                nextAt += 0.24
                let ang = atan2(seg.y, seg.x) * 180 / .pi
                FA.box(&m, V3(0.012, 0.012, 0.292), dedup[i] + V3(0, 0.017, 0), "paint.stucco:CDBA97", r: 0.002, rot: FA.q(ang, FA.Z))
            }
        }
        // Lime-wash lichen patches on the coping and chipped stucco showing the brick core.
        for i in 0..<5 {
            let x = rng.float(0.65...hw - 0.25) * (i % 2 == 0 ? 1 : -1)
            FA.box(&m, V3(rng.float(0.05...0.1), 0.004, 0.06), V3(x, 0.52 + 0.043, zc + rng.float(-0.05...0.05)), "paint.stucco:9AA27F", r: 0.001)
        }
        for (x, y, w, h): (Float, Float, Float, Float) in [(-0.9, 0.2, 0.14, 0.1), (0.35, 0.1, 0.1, 0.07), (-0.2, 0.45, 0.08, 0.06)] {
            FA.box(&m, V3(w + 0.02, h + 0.02, 0.003), V3(x, y, zc + T / 2 + 0.0008), "paint.stucco:BFAE8C", r: 0.001)
            FA.box(&m, V3(w, h, 0.004), V3(x, y, zc + T / 2 + 0.0018), "brick.common", r: 0.001)
        }
        // Base cornice and belt course.
        FA.box(&m, V3(width, 0.09, 0.3), V3(0, 0.045, zc), stucco, r: 0.006)
        FA.box(&m, V3(width + 0.02, 0.04, T + 0.04), V3(0, 0.12, zc), stucco, r: 0.004)
        FA.box(&m, V3(width - 0.02, 0.035, T + 0.03), V3(0, 0.36, zc), stucco, r: 0.004)
        // Quatrefoil of four clay rings with a recessed dark core, on the front face of the gable.
        let fz = zc + T / 2, qc = V2(0, 0.8)
        m.add(Prim.cylinder(radius: 0.115, height: 0.006, bevel: 0.001, segments: 24, bevelSegments: 1, material: "paint.stucco:6B5846"),
              Xform(translation: V3(qc.x, qc.y, fz), rotation: FA.q(90, FA.X)))
        for k in 0..<4 {
            let a = Float(k) * .pi / 2 + .pi / 4
            let c = V3(qc.x + 0.062 * cos(a), qc.y + 0.062 * sin(a), fz + 0.004)
            m.add(Prim.torus(major: 0.056, minor: 0.011, segments: 18, sides: 6, material: clay), Xform(translation: c, rotation: FA.q(90, FA.X)))
        }
        FA.ball(&m, r: 0.016, at: V3(qc.x, qc.y, fz + 0.012), clay)
        // Metal scupper on the right shoulder and the stain below it.
        let sx = hw - 0.5
        FA.box(&m, V3(0.12, 0.07, 0.05), V3(sx, 0.2, zc + T / 2 + 0.0), "metal.galvanized-aged", r: 0.003)
        FA.box(&m, V3(0.15, 0.1, 0.012), V3(sx, 0.2, zc + T / 2 + 0.002), "metal.galvanized-aged", r: 0.002)
        for i in 0..<4 {
            let w = rng.float(0.012...0.03)
            FA.box(&m, V3(w, rng.float(0.1...0.17), 0.002), V3(sx + rng.float(-0.05...0.05), 0.07, zc + T / 2 + 0.001), "paint.stucco:A39478", r: 0.0005)
        }
        // Hairline cracks running from the cove corner and the pier.
        for (x, y, len, ang): (Float, Float, Float, Float) in [(0.62, 0.45, 0.16, 62), (-0.7, 0.3, 0.2, -70), (hw - 0.05, 0.5, 0.12, 80)] {
            FA.box(&m, V3(0.003, len, 0.002), V3(x, y, zc + T / 2 + 0.001), "paint.stucco:5A4B3A", r: 0.0005, rot: FA.q(ang - 90 + 90, FA.Z))
        }
        // Rain-wash streaks under the coping and a dirt band at the splash zone.
        for i in 0..<14 {
            let x = rng.float(-hw + 0.1...hw - 0.1)
            let top: Float = abs(x) < 0.38 ? 0.68 + sqrt(max(0.0001, 0.38 * 0.38 - x * x)) - 0.04 : 0.5
            let h = rng.float(0.05...0.16)
            FA.box(&m, V3(rng.float(0.01...0.035), h, 0.002), V3(x, top - h / 2, fz + 0.0006), "paint.stucco:B8A582", r: 0.0005)
        }
        FA.box(&m, V3(width - 0.04, 0.05, 0.002), V3(0, 0.165, fz + 0.0008), "paint.stucco:A8957A", r: 0.0005)
        FA.box(&m, V3(0.5, 0.06, 0.002), V3(-0.55, 0.26, fz + 0.001), "paint.stucco:C9B48D", r: 0.0005)
        groundAO(&m, height: 0.1, floor: 0.85)
        return LODModel(FA.centerZ(m))
    }
}
