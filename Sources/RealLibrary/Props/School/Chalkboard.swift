import simd
import Foundation

/// Chalkboard: everyday school, slate. Parts: oak frame, slate writing surface, chalk tray with lip, chalk pieces, felt eraser, chalk writing and wipe marks.
public struct Chalkboard: RealAsset {
    public static let id = "chalkboard"
    public static let summary = "Wall chalkboard in an oak frame with a chalk tray, chalk, eraser and chalk writing."
    public static let tags = ["prop", "interior", "school", "stone", "wood"]
    public static let budget = 14000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(1.8, 1.2, 0.03)
    public init() {}

        public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = size.x, H = size.y, f: Float = 0.05
        let oak = "wood.oak"
        // Frame: rails along X (grain along U), stiles along Y rotated so grain follows the member.
        for s: Float in [0, 1] {
            m.add(Prim.roundedBox(V3(W, f, 0.02), radius: 0.003, bevelSegments: 2, material: oak), Xform(translation: V3(0, s == 0 ? f / 2 : H - f / 2, -0.005)))
            m.add(Prim.roundedBox(V3(H - 2 * f + 0.002, f, 0.02), radius: 0.003, bevelSegments: 2, material: oak),
                  Xform(translation: V3(s == 0 ? -W / 2 + f / 2 : W / 2 - f / 2, H / 2, -0.005), rotation: simd_quatf(degrees: 90, axis: V3(0, 0, 1))))
        }
        // Slate writing surface, recessed 7 mm behind the frame face.
        m.add(Prim.roundedBox(V3(W - 2 * f + 0.004, H - 2 * f + 0.004, 0.012), radius: 0.001, bevelSegments: 1, material: "stone.slate"), Xform(translation: V3(0, H / 2, -0.008)))
        // Chalk tray along the bottom of the board with a front lip and a back wall.
        let trayY = f + 0.006
        m.add(Prim.roundedBox(V3(W - 2 * f, 0.012, 0.03), radius: 0.002, bevelSegments: 2, material: oak), Xform(translation: V3(0, trayY, 0)))
        m.add(Prim.roundedBox(V3(W - 2 * f, 0.010, 0.004), radius: 0.001, bevelSegments: 1, material: oak), Xform(translation: V3(0, trayY + 0.009, 0.0125)))
        // Chalk: three sticks lying in the tray, one broken, with white dust smears.
        for k in 0..<3 {
            let len: Float = k == 1 ? 0.04 : rng.float(0.065...0.08)
            m.add(Prim.cylinder(radius: 0.0045, height: len, bevel: 0.0004, segments: 12, material: "plastic.matte:EDEBE4"),
                  Xform(translation: V3(-0.55 + Float(k) * 0.03, trayY + 0.006 + 0.0045, -0.004 + Float(k) * 0.004), rotation: simd_quatf(degrees: rng.float(-12...12), axis: .up) * simd_quatf(degrees: 90, axis: V3(0, 0, 1))))
        }
        m.add(Prim.roundedBox(V3(0.25, 0.0004, 0.014), radius: 0.0001, bevelSegments: 1, material: "plastic.matte:D9D7CF"), Xform(translation: V3(-0.45, trayY + 0.0062, 0.0)))
        // Felt eraser: felt strip under a beech block.
        m.add(Prim.roundedBox(V3(0.12, 0.008, 0.026), radius: 0.001, bevelSegments: 1, material: "fabric.wool:3A3A3A"), Xform(translation: V3(0.4, trayY + 0.010, 0)))
        m.add(Prim.roundedBox(V3(0.12, 0.022, 0.026), radius: 0.003, bevelSegments: 2, material: "wood.beech-stained"), Xform(translation: V3(0.4, trayY + 0.025, 0)))
        // Chalk writing and a wiped smudge on the slate, as flat quads facing +Z.
        let z: Float = -0.0014, nrm = V3(0, 0, 1)
        var ink = Surface(material: "plastic.matte:E9E7E0")
        func bar(_ x: Float, _ y: Float, _ w: Float, _ h: Float) {
            for order in 0..<2 {
                let p = [V2(x, y), V2(x + w, y), V2(x + w, y + h), V2(x, y + h)]
                let q = order == 0 ? p : p.reversed()
                let i = q.map { ink.add(V3($0.x, $0.y, z), nrm, V2($0.x, $0.y)) }
                ink.quad(i[0], i[1], i[2], i[3])
            }
        }
        for row in 0..<5 {
            var x: Float = -0.62
            let y: Float = 1.0 - Float(row) * 0.12
            while x < 0.1 + Float(row % 2) * 0.35 {
                let w = rng.float(0.012...0.05)
                bar(x, y + rng.float(-0.004...0.004), w, 0.0035)
                if rng.chance(0.12) { bar(x + w * 0.4, y - 0.02, 0.0035, rng.float(0.02...0.05)) }
                x += w + rng.float(0.012...0.03)
            }
        }
        // Underline and a ruled chalk box.
        bar(-0.62, 0.34, 0.9, 0.003); bar(0.25, 0.30, 0.5, 0.003); bar(0.25, 0.66, 0.5, 0.003); bar(0.25, 0.30, 0.003, 0.36); bar(0.747, 0.30, 0.003, 0.36)
        ink.computeTangents()
        m.add(ink, Xform())
        for k in 0..<3 {
            m.add(Prim.superellipsoid(V3(rng.float(0.35...0.6), 0.0006, rng.float(0.12...0.2)), exponent: 2, subdivisions: 8, material: "stone.slate:58645E"),
                  Xform(translation: V3(rng.float(-0.4...0.5), rng.float(0.35...0.6), -0.0020), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        }
        groundAO(&m)
        return LODModel(m)
    }
}
