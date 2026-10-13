import simd
import Foundation

/// Bossage pier: architectural facade customizer, French Neoclassical. Parts: plinth, rusticated courses, chamfered V-joints, impost cornice, cap.
public struct BossagePier: RealAsset {
    public static let id = "bossage-pier"
    public static let summary = "Bossage pier, 3.0 m: banded rusticated limestone courses with V-joints between a plinth and impost cap."
    public static let tags = ["prop", "architecture", "facade", "trim", "stone"]
    public static let budget = 12000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.6, 3.0, 0.3)
    public init() {}

    /// Block face material (limestone, alternating courses use the cast-stone variant).
    public var stone: MaterialKey = "stone.limestone"
    /// Cast-stone courses interleaved with the limestone.
    public var cast: MaterialKey = "stone.cast-stone"
    /// Sooted limestone for the plinth, joints and the weathered top.
    public var sooted: MaterialKey = "stone.limestone-sooted"
    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = size.x, H = size.y, D = size.z
        let plinthH: Float = 0.34, imposH: Float = 0.26, capH: Float = 0.06
        let shaftTop = H - imposH - capH, face: Float = D - 0.04
        // Plinth: base block, torus-and-scotia base moulding, die.
        FA.box(&m, V3(W, 0.12, D), V3(0, 0.06, D / 2), sooted, r: 0.004)
        FA.run(&m, [V2(0, 0.12), V2(D - 0.01, 0.12), V2(D - 0.01, 0.15), V2(D - 0.035, 0.17), V2(D - 0.035, 0.19),
                    V2(D - 0.012, 0.215), V2(D - 0.012, 0.235), V2(face + 0.008, 0.245), V2(face + 0.008, plinthH), V2(0, plinthH)],
               length: W, at: .zero, sooted, bevel: 0.002)
        // Recessed core behind the V-joints so each joint reads as a dark chamfer.
        FA.box(&m, V3(W - 0.12, shaftTop - plinthH, face - 0.03), V3(0, (shaftTop + plinthH) / 2, (face - 0.03) / 2), sooted, r: 0.002)
        // Rusticated courses: chamfered blocks (bevel = the V-joint), alternate courses split with staggered joints.
        let courses = 8
        let ch = (shaftTop - plinthH) / Float(courses)
        let bw = W - 0.016
        for c in 0..<courses {
            let y0 = plinthH + Float(c) * ch
            let mat: MaterialKey = c % 2 == 0 ? stone : cast
            let split = c % 2 == 1
            let pieces: [(Float, Float)] = split ? [(-bw / 2, bw * 0.38), (-bw / 2 + bw * 0.38, bw * 0.62)] : [(-bw / 2, bw)]
            for (px, pw) in pieces {
                let proj = face - 0.03 + rng.float(-0.002...0.002)
                let outline = Shape2D.rect(pw - 0.004, ch - 0.004)
                m.add(Prim.extrude(outline, depth: proj, bevel: 0.013, bevelSegments: 1, material: c == 0 ? sooted : mat),
                      Xform(translation: V3(px + pw / 2, y0 + ch / 2, proj / 2 + 0.002)))
                // Pecked surface: a shallow raised pad inside the chamfers.
                m.add(Prim.roundedBox(V3(pw - 0.05, ch - 0.05, 0.008), radius: 0.003, bevelSegments: 1, material: mat),
                      Xform(translation: V3(px + pw / 2, y0 + ch / 2, proj + 0.004 + rng.float(0...0.001))))
                // Vermiculation: shallow worm-track pits read as soot-filled lozenges on the pecked face.
                for _ in 0..<(c < 3 ? 7 : 3) {
                    let vx = px + pw / 2 + rng.float(-(pw - 0.1) / 2...(pw - 0.1) / 2)
                    let vy = y0 + ch / 2 + rng.float(-(ch - 0.1) / 2...(ch - 0.1) / 2)
                    FA.box(&m, V3(rng.float(0.018...0.045), rng.float(0.005...0.01), 0.003), V3(vx, vy, proj + 0.011), sooted, r: 0.0012,
                           rot: FA.q(rng.float(-60...60), FA.Z))
                }
                // Rain streak running down from the joint above.
                if rng.chance(0.4) {
                    let sw = rng.float(0.03...0.07)
                    FA.box(&m, V3(sw, ch * 0.8, 0.002), V3(px + pw / 2 + rng.float(-pw / 4...pw / 4), y0 + ch * 0.45, proj + 0.0125), sooted, r: 0.0008)
                }
            }
        }
        // Iron tie plate (wall anchor) on the third course joint.
        let ty = plinthH + 3 * ch
        FA.box(&m, V3(0.07, 0.018, 0.006), V3(0.12, ty, face - 0.012), "metal.cast-iron", r: 0.002)
        FA.box(&m, V3(0.018, 0.07, 0.006), V3(0.12, ty, face - 0.011), "metal.cast-iron", r: 0.002)
        // Impost cornice: neck, fillet, cyma recta, corona, bed.
        FA.box(&m, V3(W - 0.06, 0.05, face), V3(0, shaftTop + 0.025, face / 2), sooted, r: 0.003)
        FA.run(&m, [V2(0, shaftTop + 0.05), V2(face - 0.02, shaftTop + 0.05), V2(face - 0.02, shaftTop + 0.07), V2(D - 0.03, shaftTop + 0.08),
                    V2(D - 0.03, shaftTop + 0.10), V2(face + 0.002, shaftTop + 0.125), V2(face + 0.002, shaftTop + 0.135),
                    V2(D, shaftTop + 0.15), V2(D, shaftTop + 0.20), V2(D - 0.025, shaftTop + 0.215), V2(D - 0.025, H - capH), V2(0, H - capH)],
               length: W, at: .zero, stone, bevel: 0.002)
        // Cap slab with a weathering slope and drip.
        FA.box(&m, V3(W + 0.02, capH, D + 0.015), V3(0, H - capH / 2, (D + 0.015) / 2), sooted, r: 0.004)
        // Chip on the cap corner.
        FA.box(&m, V3(0.05, 0.02, 0.04), V3(W / 2 - 0.02, H - 0.005, D - 0.012), sooted, r: 0.004, rot: FA.q(18, FA.Y))
        groundAO(&m, height: 0.2, floor: 0.55)
        return LODModel(FC.place(m))
    }
}
