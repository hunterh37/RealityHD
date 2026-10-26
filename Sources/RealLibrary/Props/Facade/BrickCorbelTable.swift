import simd
import Foundation

/// Romanesque Revival brick corbel table, 3.0 m: textured brick backing wall carrying stepped corbel piers and
/// a run of blind round arches in header-bond voussoirs, a header string course and a limestone drip cap.
/// Lime mortar joints are raked into the backing. Backing face at z = 0.05, relief projects toward +Z.
public struct BrickCorbelTable: RealAsset {
    public static let id = "brick-corbel-table"
    public static let summary = "Romanesque Revival corbel table, 3.0 m: stepped brick piers, blind round arches, header string course, limestone cap."
    public static let tags = ["prop", "architecture", "facade", "trim", "stone"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 14, distance: 1.7)

    /// Run length in meters.
    public var length: Float = 3.0
    /// Bay pitch between corbel piers in meters.
    public var pitch: Float = 0.25
    /// Brick backing wall.
    public var backing: MaterialKey = "brick.common"
    /// Common face brick.
    public var brick: MaterialKey = "brick.unit-red"
    /// Darker over-fired brick mixed into courses.
    public var brickDark: MaterialKey = "brick.unit-red-dark"
    /// Sooted brick in the arch recesses and under the cap.
    public var brickSooted: MaterialKey = "brick.unit-sooted"
    /// Pale replacement brick.
    public var brickBuff: MaterialKey = "brick.unit-buff"
    /// Raked lime mortar.
    public var mortar: MaterialKey = "brick.mortar-lime"
    /// Limestone drip cap.
    public var cap: MaterialKey = "stone.limestone-sooted"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let L = length
        let n = Int((L / pitch).rounded())
        let p = L / Float(n)
        let wall: Float = 0.05
        func pick(_ rng: inout SeededRNG) -> MaterialKey {
            let r = rng.float()
            if r < 0.12 { return brickDark }
            if r < 0.17 { return brickBuff }
            return brick
        }
        // Backing wall: textured brick with the raked lime courses (4 x 75 mm) drawn as recessed bands.
        FC.brickBox(&m, V3(L, 0.30, wall), V3(0, 0.15, wall / 2), backing, r: 0.002)
        for c in 1..<4 {
            FC.brickBox(&m, V3(L, 0.0035, 0.002), V3(0, Float(c) * 0.075, wall + 0.0008), mortar, r: 0.0006)
        }
        // Corbel piers: two stepped courses, the upper wider and deeper, carrying the arch springers.
        let spring: Float = 0.082
        for i in 0...n {
            let edge = i == 0 || i == n
            let x = -L / 2 + Float(i) * p
            for s in 0..<2 {
                let w: Float = (s == 0 ? 0.058 : 0.092) * (edge ? 0.6 : 1.0)
                let proj: Float = s == 0 ? 0.03 : 0.047
                let cx = i == 0 ? -L / 2 + w / 2 : (i == n ? L / 2 - w / 2 : x)
                let y0 = Float(s) * 0.041 + 0.0
                let z = wall + proj / 2
                FC.brickBox(&m, V3(w - 0.006, 0.037, proj), V3(cx + rng.float(-0.001...0.001), y0 + 0.0185, z), pick(&rng), r: 0.0025)
            }
        }
        // Blind arches: sooted tympanum recess plus a ring of header-bond voussoirs.
        for i in 0..<n {
            let cx = -L / 2 + (Float(i) + 0.5) * p
            let R = (p - 0.092) / 2
            // Recess: arched outline set into the backing face (reads darker).
            let outline = FC.archOutline(width: 2 * R, spring: spring, pointed: false, steps: 10)
            m.add(Prim.extrude(outline, depth: 0.004, bevel: 0.0008, bevelSegments: 1, material: brickSooted),
                  Xform(translation: V3(cx, 0.0, wall + 0.0015)))
            let k = 7
            for j in 0..<k {
                let a0 = Float.pi * Float(j) / Float(k), a1 = Float.pi * Float(j + 1) / Float(k)
                let am = (a0 + a1) / 2
                let band: Float = 0.05
                let rm = R + band / 2
                let chord = (R + band) * (a1 - a0) * 0.93 - 0.003
                let c = V3(cx + cos(am) * rm, spring + sin(am) * rm, wall + 0.0235)
                let mat = j == k / 2 ? pick(&rng) : (j % 2 == 0 ? brick : brickDark)
                FC.brickBox(&m, V3(chord, band - 0.004, 0.047), c, mat, r: 0.0025, rot: FA.q(am * 180 / .pi - 90, FA.Z))
            }
        }
        // String course: header bricks projecting 0.13 over the arch crowns.
        var x = -L / 2
        while x < L / 2 - 0.01 {
            let w = min(0.1, L / 2 - x)
            FC.brickBox(&m, V3(w - 0.007, 0.035, 0.08), V3(x + w / 2, 0.247, wall + 0.04), pick(&rng), r: 0.0025)
            x += 0.1
        }
        // Sooting band under the drip and a patched joint.
        FC.brickBox(&m, V3(L, 0.012, 0.005), V3(0, 0.2615, 0.133), brickSooted, r: 0.001)
        // Limestone cap with a drip kerf.
        FC.brickBox(&m, V3(L, 0.035, 0.2), V3(0, 0.2825, 0.1), cap, r: 0.004)
        FC.brickBox(&m, V3(L - 0.01, 0.006, 0.01), V3(0, 0.261, 0.185), mortar, r: 0.001)
        // Cap joints every 0.5 m and a weathered spall on one arris.
        for k in 1..<6 { FC.brickBox(&m, V3(0.004, 0.036, 0.202), V3(-L / 2 + Float(k) * 0.5, 0.2825, 0.1), mortar, r: 0.0008) }
        FC.brickBox(&m, V3(0.09, 0.012, 0.0025), V3(0.62, 0.289, 0.2005), "stone.limestone", r: 0.0008)
        groundAO(&m, height: 0.08, floor: 0.88)
        return LODModel(FC.seatY(FA.centerZ(m)))
    }
}
