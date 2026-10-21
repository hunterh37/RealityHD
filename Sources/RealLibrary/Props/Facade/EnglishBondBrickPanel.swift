import simd
import Foundation

/// English bond brick panel: Victorian pressed red brick, alternating courses of stretchers and headers
/// (215 x 102.5 x 65 mm units, 10 mm joints, 75 mm gauge) with a queen closer after the quoin header in
/// every header course. Lime mortar sits 4 mm back from the face. Headers are kiln-burnt darker, the base
/// courses carry salt bloom and one stretcher has a chipped arris.
public struct EnglishBondBrickPanel: RealAsset {
    public static let id = "english-bond-brick-panel"
    public static let summary = "English bond brick panel, 1.2 m square: alternating stretcher and header courses of pressed red brick with queen closers in recessed lime mortar."
    public static let tags = ["prop", "architecture", "facade", "stone"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 8, distance: 2.6)

    /// Panel width in meters.
    public var width: Float = 1.2
    /// Number of 75 mm courses.
    public var courses: Int = 16
    /// Brick length, header face width and course height (meters, joints excluded).
    public var brickLength: Float = 0.215
    /// Header face width (half brick less half a joint).
    public var headerWidth: Float = 0.1025
    /// Brick height.
    public var brickHeight: Float = 0.065
    /// Mortar joint thickness.
    public var joint: Float = 0.01
    /// Mortar recess behind the brick face.
    public var recess: Float = 0.004
    /// Brick materials.
    public var stretcher: MaterialKey = "brick.unit-red"
    /// Burnt header material.
    public var header: MaterialKey = "brick.unit-header"
    /// Mortar material.
    public var mortar: MaterialKey = "brick.mortar-lime"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let j = joint, gauge = brickHeight + j, half = width / 2, depth: Float = 0.1025
        let reds: [MaterialKey] = [stretcher, stretcher, "brick.unit-red-dark", "brick.unit-red-light"]
        let chipAt = (3, 2)
        for c in 0..<courses {
            let y0 = Float(c) * gauge + j / 2, y1 = y0 + brickHeight
            var units: [(Float, Float, Bool)] = []   // x0, x1, isHeader
            var x = -half
            if c % 2 == 0 {
                // Stretcher course: starts with a full stretcher at the reveal.
                while x < half - 0.02 { units.append((x, min(x + brickLength + j, half), false)); x += brickLength + j }
            } else {
                // Header course: quoin header, queen closer, then headers.
                units.append((x, x + headerWidth + j, true)); x += headerWidth + j
                units.append((x, x + 0.046 + j, false)); x += 0.046 + j
                while x < half - 0.02 { units.append((x, min(x + headerWidth + j, half), true)); x += headerWidth + j }
            }
            for (i, u) in units.enumerated() {
                var r = rng.fork(c * 64 + i)
                let base = c < 2 && r.chance(0.55) ? "brick.unit-efflorescent" : nil
                let mat: MaterialKey = base.map { MaterialKey(stringLiteral: $0) }
                    ?? (u.2 ? (r.chance(0.7) ? header : r.pick(reds)) : r.pick(reds))
                brick(&m, x0: u.0 + j / 2, x1: u.1 - j / 2, y0: y0, y1: y1, depth: depth, mat, &r, chip: (c, i) == chipAt)
            }
        }
        let h = Float(courses) * gauge
        FM.mortar(&m, w: width, h: h, recess: recess, back: 0.12, mortar)
        groundAO(&m, height: 0.12, floor: 0.8)
        return LODModel(FC.place(m))
    }

    private func brick(_ m: inout Model, x0: Float, x1: Float, y0: Float, y1: Float, depth: Float, _ mat: MaterialKey,
                       _ r: inout SeededRNG, chip: Bool) {
        FM.brick(&m, x0: x0, x1: x1, y0: y0, y1: y1, depth: depth, mat, rng: &r, chip: chip)
    }
}
