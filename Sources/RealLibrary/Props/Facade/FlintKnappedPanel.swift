import simd
import Foundation

/// Flint knapped panel: architectural facade customizer, East Anglian Vernacular. Knapped flint nodules
/// laid in courses with their split, glassy black faces outward and the white chalky cortex showing as a
/// rim, in a pale lime mortar galletted with flint chips. Red brick quoin dressings tooth into the flint at
/// both edges, over a three-course brick plinth and a two-course brick lacing band at mid height.
public struct FlintKnappedPanel: RealAsset {
    public static let id = "flint-knapped-panel"
    public static let summary = "East Anglian knapped flint panel, 1.2 m: coursed squared flint faces with white cortex rims in lime mortar, red brick quoin dressings and a brick lacing course."
    public static let tags = ["prop", "architecture", "facade", "stone"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 10, distance: 2.4)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(1.2, 1.2, 0.12)
    /// Brick course height including the 10 mm joint (m).
    public var course: Float = 0.075
    /// Brick plinth courses.
    public var plinthCourses: Int = 3
    /// First course of the lacing band.
    public var bandCourse: Int = 10
    /// Knapped flint face material (dark glassy).
    public var flint: MaterialKey = "stone.marble-dark:2B2A28"
    /// Cortex rind material.
    public var cortex: MaterialKey = "rock.limestone:D9D2C2"
    /// Brick tones (sRGB hex): soft red, orange red, dark burnt header.
    public var bricks: [UInt32] = [0x9A4A34, 0xA8553A, 0x8A3E2E, 0xB0624A, 0x6E3428]
    /// Lime mortar.
    public var mortar: MaterialKey = "concrete.rough:B3AA96"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = size.x, hw = W / 2, D = size.z, face: Float = D - 0.014, j: Float = 0.01
        let n = Int((size.y / course).rounded())
        SWK.mortar(&m, w: W, y0: 0, y1: size.y, face: face, key: mortar, rough: 0.003, seed: 21, segments: 14)
        func brick(_ x0: Float, _ x1: Float, _ y0: Float, _ r: inout SeededRNG) {
            var tone = r.pick(bricks)
            var proud = r.float(0.009...0.013)
            // Rising damp darkens the plinth; frost has spalled the odd face back 6-10 mm.
            if y0 < 0.2 { tone = r.chance(0.5) ? 0x6A3A2E : 0x7E4636 }
            if r.chance(0.06) { proud -= r.float(0.006...0.01); tone = 0xB87256 }
            m.add(Prim.roundedBox(V3(x1 - x0 - j, course - j, 0.06), radius: 0.004, bevelSegments: 1, material: SWK.tint("concrete.rough", tone)),
                  Xform(translation: V3((x0 + x1) / 2, y0 + course / 2, face + proud - 0.03), rotation: simd_quatf(degrees: r.float(-0.4...0.4), axis: V3(0, 0, 1))))
        }
        var id = 0
        for c in 0..<n {
            let y0 = Float(c) * course
            var r = rng.fork(c)
            let isBrick = c < plinthCourses || (c >= bandCourse && c < bandCourse + 2)
            if isBrick {
                // English bond: stretcher courses of 215 mm, header courses of 102.5 mm, closers at the ends.
                let unit: Float = c % 2 == 0 ? 0.225 : 0.1125
                var x = -hw + (c % 2 == 0 ? 0 : 0.0)
                if c % 2 == 0 { brick(x, x + 0.16, y0, &r); x += 0.16 }
                while x < hw - 0.001 { let x1 = min(hw, x + unit); brick(x, x1, y0, &r); x = x1 }
                continue
            }
            // Quoin dressings: alternate long and short bricks toothing into the flint.
            let long = c % 2 == 0
            let q: Float = long ? 0.225 : 0.1125
            brick(-hw, -hw + q, y0, &r); brick(hw - q, hw, y0, &r)
            // Flint course between the dressings.
            var x = -hw + q + 0.008
            while x < hw - q - 0.03 {
                id += 1
                var f = rng.fork(1000 + id)
                var w = f.float(0.08...0.115)
                if hw - q - (x + w) < 0.05 { w = hw - q - x - 0.008 }
                let h = course - f.float(0.007...0.012)
                let cx = x + w / 2, cy = y0 + course / 2 + f.float(-0.004...0.004)
                let proud = f.float(0.007...0.012)
                // Cortex rind: pale rim behind the face (fully squared flints lose it).
                let squared = f.chance(0.4)
                if !squared { SWK.stone(&m, V3(cx, cy, face - 0.013), V3(w, h, 0.03), exponent: 3.4, sub: 2, relief: 0.12,
                          key: f.chance(0.3) ? SWK.tint("rock.limestone", 0xBFB6A2) : cortex, roll: f.float(-6...6), seed: UInt32(id * 7)) }
                // Knapped face: flat conchoidal split, slightly smaller than the rind; a few faces are grey-blue or honey.
                let tone: UInt32 = f.chance(0.18) ? 0x4A4C50 : (f.chance(0.1) ? 0x5A4634 : 0x232220)
                SWK.stone(&m, V3(cx + f.float(-0.003...0.003), cy, face + proud - 0.01), V3(w * (squared ? 0.97 : f.float(0.86...0.93)), h * (squared ? 0.95 : f.float(0.84...0.9)), 0.02),
                          exponent: f.float(3.5...5), sub: 2, relief: 0.07, key: SWK.tint("stone.marble-dark", tone),
                          roll: f.float(-10...10), yaw: f.float(-5...5), pitch: f.float(-5...5), seed: UInt32(id * 7 + 3), face: 0.9, freq: 3)
                // Galletting: a flint chip pressed into the joint.
                if f.chance(0.18) {
                    SWK.stone(&m, V3(x + w + 0.004, y0 + f.float(0.01...0.06), face + 0.003), V3(0.014, 0.018, 0.008), exponent: 2.5, sub: 1,
                              relief: 0.2, key: SWK.tint("stone.marble-dark", 0x2E2D2B), roll: f.float(0...180), seed: UInt32(id))
                }
                x += w + 0.005
            }
        }
        return SWK.finish(&m, id: Self.id, cap: SWK.tint("stone.marble-dark", 0x3A3836))
    }
}
