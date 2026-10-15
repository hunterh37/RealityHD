import simd
import Foundation

/// Cylindrical fuselage section, 1.25 m diameter x 2.0 m, lying along X: a carbon composite skin barrel
/// between two machined aluminium end frames, each with a bolt ring for stacking. Four longitudinal lap
/// seams and a mid-barrel splice band carry fastener rows; a painted access hatch with a screw ring and
/// a flush latch sits on the side, with an inspection label beside it.
public struct FuselageSection: RealAsset {
    public static let id = "fuselage-section"
    public static let summary = "Cylindrical fuselage section, 1.25 m diameter x 2.0 m: carbon composite skin barrel with machined aluminium end frames, bolt rings and a fastened access hatch."
    public static let tags = ["prop", "aerospace"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 14, distance: 1.15, studio: true)

    /// Outer diameter at the end frames (m).
    public var diameter: Float = 1.25
    /// Length frame face to frame face (m).
    public var length: Float = 2.0
    /// Access hatch size along X and around the barrel (m), and its angle from the top (degrees).
    public var hatch = V2(0.52, 0.4)
    public var hatchAngle: Float = 70
    public var skin: MaterialKey = "composite.carbon"
    public var frame: MaterialKey = "metal.aluminum-brushed"
    public var fastener: MaterialKey = "metal.steel"
    /// Hatch paint.
    public var hatchPaint: MaterialKey = "paint.field-white"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let R = diameter / 2, L = length, cy = R
        let skinR = R - 0.008, fw: Float = 0.05
        let toX = simd_quatf(angle: -.pi / 2, axis: V3(0, 0, 1))      // lathe +Y axis -> +X
        // Point on the barrel at angle a from the top (+Y), toward +Z for positive a.
        func onSkin(_ x: Float, _ a: Float, _ r: Float) -> V3 { V3(x, cy + cos(a) * r, sin(a) * r) }
        func normal(_ a: Float) -> V3 { V3(0, cos(a), sin(a)) }

        var levels: [Model] = []
        for l in 0..<2 {
            var m = Model(name: Self.id)
            let sg = l == 0 ? 48 : 24
            // Skin barrel: open tube with an inner wall so the ends read as a shell.
            m.add(Prim.lathe([V2(skinR - 0.012, -L / 2 + fw), V2(skinR, -L / 2 + fw), V2(skinR, L / 2 - fw), V2(skinR - 0.012, L / 2 - fw)],
                             segments: sg, seamTile: 1.2, material: skin), Xform(translation: V3(0, cy, 0), rotation: toX))
            // Inner wall (faces inward), so the open ends show a lined shell.
            m.add(Prim.lathe([V2(skinR - 0.012, L / 2 - fw), V2(skinR - 0.012, -L / 2 + fw)], segments: sg, seamTile: 1.2, material: skin),
                  Xform(translation: V3(0, cy, 0), rotation: toX))
            // End frames: machined rings with a lip, flange face and inner web.
            for s: Float in [-1, 1] {
                let x0 = s * L / 2
                var prof: [V2] = [V2(R - 0.06, 0), V2(R - 0.004, 0), V2(R, 0.004), V2(R, fw - 0.006), V2(R - 0.004, fw), V2(skinR - 0.004, fw + 0.004), V2(R - 0.06, fw + 0.004)]
                if s > 0 { prof = prof.map { V2($0.x, -$0.y) }.reversed() }
                m.add(Prim.lathe(prof, segments: sg, seamTile: 0.5, material: frame), Xform(translation: V3(x0 * 1, cy, 0), rotation: toX))
                if l == 0 {
                    for k in 0..<12 {
                        let a = (Float(k) + 0.5) / 12 * 2 * .pi
                        hexBolt(&m, at: V3(x0, cy + cos(a) * (R - 0.032), sin(a) * (R - 0.032)), normal: V3(s, 0, 0), size: 0.009, material: fastener)
                    }
                    // Frame-to-skin rivet row.
                    for k in 0..<16 {
                        let a = Float(k) / 16 * 2 * .pi
                        rivet(&m, at: onSkin(x0 - s * (fw + 0.018), a, skinR), normal: normal(a), radius: 0.004, segments: 5, material: fastener)
                    }
                }
            }
            // Mid-barrel splice band.
            m.add(Prim.lathe([V2(skinR - 0.002, -0.05), V2(skinR + 0.0025, -0.048), V2(skinR + 0.0025, 0.048), V2(skinR - 0.002, 0.05)],
                             segments: sg, seamTile: 0.6, material: skin), Xform(translation: V3(-0.25, cy, 0), rotation: toX))
            if l == 0 {
                // Longitudinal lap seams with fastener rows (skipping the hatch).
                for a0: Float in [20, 110, 200, 290] {
                    let a = a0 * .pi / 180
                    let path = [onSkin(-L / 2 + fw + 0.03, a, skinR + 0.0005), onSkin(L / 2 - fw - 0.03, a, skinR + 0.0005)]
                    let mid = (path[0] + path[1]) / 2
                    m.add(Prim.roundedBox(V3(path[1].x - path[0].x, 0.003, 0.03), radius: 0.001, bevelSegments: 1, material: skin),
                          Xform(translation: mid, rotation: simd_quatf(angle: a, axis: V3(1, 0, 0))))
                }
                // Access hatch: curved painted panel, doubler frame, screw ring and a flush latch.
                let ha = hatchAngle * .pi / 180, hx: Float = 0.42
                let span = hatch.y / skinR
                let cols = 10
                // Curved plate: annular sector extruded along X.
                func panel(_ r: Float, _ w: Float, _ hgt: Float, _ mat: MaterialKey) -> Surface {
                    let half = (hgt / skinR) / 2
                    var o: [V2] = []
                    for i in 0...cols { let a = ha - half + 2 * half * Float(i) / Float(cols); o.append(V2(-sin(a) * r, cos(a) * r)) }
                    for i in (0...cols).reversed() { let a = ha - half + 2 * half * Float(i) / Float(cols); o.append(V2(-sin(a) * (r - 0.004), cos(a) * (r - 0.004))) }
                    return Prim.extrude(o, depth: w, bevel: 0.0012, bevelSegments: 1, material: mat)
                }
                m.add(panel(skinR + 0.0022, hatch.x + 0.06, hatch.y + 0.06, frame), Xform(translation: V3(hx, cy, 0), rotation: simd_quatf(angle: .pi / 2, axis: V3(0, 1, 0))))
                m.add(panel(skinR + 0.0052, hatch.x, hatch.y, hatchPaint), Xform(translation: V3(hx, cy, 0), rotation: simd_quatf(angle: .pi / 2, axis: V3(0, 1, 0))))
                let ring: [(Float, Float)] = (0..<8).map { (Float($0) / 7 - 0.5, -0.5) } + (0..<8).map { (Float($0) / 7 - 0.5, 0.5) }
                    + (1..<6).map { (-0.5, Float($0) / 6 - 0.5) } + (1..<6).map { (0.5, Float($0) / 6 - 0.5) }
                for (u, v) in ring {
                    let a = ha + v * (span - 0.05 / skinR)
                    rivet(&m, at: onSkin(hx + u * (hatch.x - 0.04), a, skinR + 0.0062), normal: normal(a), radius: 0.0045, segments: 5, material: fastener)
                }
                let la = ha + 0.32 * span
                m.add(Prim.roundedBox(V3(0.09, 0.004, 0.03), radius: 0.0015, bevelSegments: 1, material: frame),
                      Xform(translation: onSkin(hx, la, skinR + 0.0078), rotation: simd_quatf(angle: la, axis: V3(1, 0, 0))))
                // Inspection label beside the hatch.
                m.add(Prim.roundedBox(V3(0.09, 0.0008, 0.05), radius: 0.0004, bevelSegments: 1, material: "label.inspection"),
                      Xform(translation: onSkin(hx - hatch.x / 2 - 0.1, ha + 0.05, skinR + 0.0006), rotation: simd_quatf(angle: ha + 0.05, axis: V3(1, 0, 0))))
            }
            _ = rng.float()
            levels.append(m)
        }
        groundAO(&levels[0], height: 0.25, floor: 0.6)
        groundAO(&levels[1], height: 0.25, floor: 0.6)
        return LODModel(levels: levels, switchDistances: [10])
    }
}
