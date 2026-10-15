import simd
import Foundation

/// Stack bond brick panel: Modernist buff facing brick laid with every perpend aligned (215 x 65 mm faces,
/// 10 mm joints). Bed joints are raked 8 mm deep for a strong horizontal shadow line, perpends are struck
/// nearly flush. Galvanized ladder bed-joint reinforcement shows at the panel ends, the base course has an
/// open weep perpend with a black plastic weep vent, and one replaced brick comes from a darker batch. Rising damp darkens
/// the base courses and run-off soils the top course.
public struct StackBondBrickPanel: RealAsset {
    public static let id = "stack-bond-brick-panel"
    public static let summary = "Stack bond brick panel, 1.2 m square: buff bricks in vertically aligned columns with raked bed joints and a base weep vent."
    public static let tags = ["prop", "architecture", "facade", "stone"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 8, distance: 2.6)

    /// Panel width in meters.
    public var width: Float = 1.2
    /// Number of courses (75 mm gauge).
    public var courses: Int = 16
    /// Brick face length.
    public var brickLength: Float = 0.215
    /// Brick face height.
    public var brickHeight: Float = 0.065
    /// Joint thickness.
    public var joint: Float = 0.01
    /// Bed joint rake depth.
    public var bedRake: Float = 0.008
    /// Perpend recess.
    public var perpRecess: Float = 0.002
    /// Brick material.
    public var brick: MaterialKey = "brick.unit-buff"
    /// Mortar material.
    public var mortar: MaterialKey = "brick.mortar-grey"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let j = joint, gauge = brickHeight + j, half = width / 2, depth: Float = 0.097, pitch = brickLength + j
        let cols = Int((width / pitch).rounded(.up))
        let start = -Float(cols) * pitch / 2           // centred columns, cut bricks equal at both ends
        let weepCol = cols / 2, replaced = (9, 1)
        let h = Float(courses) * gauge
        for c in 0..<courses {
            let y0 = Float(c) * gauge + j / 2, y1 = y0 + brickHeight
            for i in 0..<cols {
                var r = rng.fork(c * 32 + i)
                let x0 = max(start + Float(i) * pitch + j / 2, -half), x1 = min(start + Float(i + 1) * pitch - j / 2, half)
                guard x1 - x0 > 0.02 else { continue }
                let mat: MaterialKey = (c, i) == replaced ? "brick.unit-buff-dark"
                    : MaterialKey(stringLiteral: r.pick(["\(brick)", "\(brick)", "brick.unit-buff:988062", "brick.unit-buff:B09A7A", "brick.unit-buff:8E7A60"]))
                // Rising damp darkens the base courses; run-off soils the top course; two arrises chipped.
                let damp: MaterialKey? = c < 2 ? (c == 0 ? "brick.unit-buff:6E5E4A" : "brick.unit-buff:84725A")
                    : (c == courses - 1 && r.chance(0.6) ? "brick.unit-buff:7A6A55" : nil)
                FM.brick(&m, x0: x0, x1: x1, y0: y0, y1: y1, depth: depth, damp ?? mat, rng: &r,
                         chip: (c, i) == (5, 3) || (c, i) == (12, 1))
                // Struck perpend to the right of this brick (none at the panel edge, none at the weep).
                let px = start + Float(i + 1) * pitch
                if px < half - 0.005 && !(c == 0 && i == weepCol) {
                    FM.prism(&m, [V2(px - j / 2 - 0.001, y0), V2(px + j / 2 + 0.001, y0), V2(px + j / 2 + 0.001, y1), V2(px - j / 2 - 0.001, y1)], front: -perpRecess, depth: 0.02, mortar, bevel: 0.001)
                }
            }
            // Ladder reinforcement every third bed joint: side wires visible at both ends.
            if c % 3 == 2 {
                let y = y1 + j / 2
                for zx in [Float(-0.02), -0.07] {
                    FA.rod(&m, V3(-half - 0.003, y, zx), V3(-half + 0.03, y, zx), r: 0.0019, "metal.galvanized-aged", sides: 6)
                    FA.rod(&m, V3(half - 0.03, y, zx), V3(half + 0.003, y, zx), r: 0.0019, "metal.galvanized-aged", sides: 6)
                }
            }
        }
        // Weep vent in the open base perpend: black louvred insert set 6 mm back.
        let wx = start + Float(weepCol + 1) * pitch, wy = j / 2 + brickHeight / 2
        FA.box(&m, V3(j - 0.001, brickHeight - 0.002, 0.08), V3(wx, wy, -0.006 - 0.04), "plastic.black", r: 0.0008)
        for k in 0..<5 { FA.box(&m, V3(j - 0.002, 0.003, 0.004), V3(wx, wy - 0.024 + Float(k) * 0.012, -0.004), "plastic.black", r: 0.0006) }
        FM.mortar(&m, w: width, h: h, recess: bedRake, back: depth - 0.005, mortar)   // single wythe: joints read from both faces
        groundAO(&m, height: 0.12, floor: 0.8)
        return LODModel(FC.place(m))
    }
}
