import simd
import Foundation

/// Romanesque Revival stone corbel table, 2.0 x 0.35 x 0.3 m: an ashlar base course, eight four-step corbels with a carved
/// roll nose (face masks on the end pair, one nose chipped), blind round arches of seven voussoirs springing between them over a
/// sooted tympanum, and a three-piece cornice slab with drip groove and mortar joints. Brownstone corbels, sandstone arches.
/// Wall plane at z = 0, piece projecting toward +Z.
public struct StoneCorbelTableCourse: RealAsset {
    public static let id = "stone-corbel-table-course"
    public static let summary = "Romanesque Revival stone corbel table, 2.0 m: stepped corbels with roll noses and masks, blind arches, cornice slab with drip, ashlar base."
    public static let tags = ["prop", "architecture", "facade", "trim", "stone"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 3, distance: 2.3)

    /// Corbel pitch in meters.
    public var pitch: Float = 0.25
    /// Corbel and cornice stone.
    public var brown: MaterialKey = "stone.brownstone"
    /// Arch voussoirs and wall facing.
    public var sand: MaterialKey = "stone.sandstone"
    /// Base course.
    public var lime: MaterialKey = "stone.limestone"
    /// Sooted recesses and joints.
    public var soot: MaterialKey = "stone.limestone-sooted"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let L: Float = 2.0
        let browns: [MaterialKey] = [brown, "stone.brownstone:7A5A44", "stone.brownstone:8C6A50", "stone.brownstone:6C4F3C"]
        let sands: [MaterialKey] = [sand, "stone.sandstone:C4A98A", "stone.sandstone:D3BA9B", "stone.sandstone:BCA284"]

        // Ashlar base course in five blocks, the wall facing above it in five blocks, joints as gaps.
        for k in 0..<5 {
            let x = -0.8 + Float(k) * 0.4
            FA.box(&m, V3(0.394, 0.09, 0.06), V3(x, 0.045, 0.03), k % 2 == 0 ? lime : "stone.limestone:CFC5AA", r: 0.003)
            FA.box(&m, V3(0.394, 0.18, 0.04), V3(x, 0.18, 0.02), sands[k % 4], r: 0.003)
        }

        // Corbels: four steps up to a quarter-round roll nose, extruded 90 mm wide.
        func corbel(chipped: Bool) -> [V2] {
            var p: [V2] = [V2(0, 0.09), V2(0.1, 0.09), V2(0.1, 0.14), V2(0.17, 0.14), V2(0.17, 0.19), V2(0.23, 0.19)]
            if chipped {
                p += [V2(0.23, 0.2), V2(0.245, 0.225), V2(0.25, 0.27)]
            } else {
                for i in 0...6 {
                    let a = Float(i) / 6 * (.pi / 2)
                    p.append(V2(0.23 + 0.03 * sin(a), 0.21 + 0.03 * (1 - cos(a)) * 1.0))
                }
                p.append(V2(0.26, 0.27))
            }
            p.append(V2(0, 0.27))
            return Shape2D.deduped(p)
        }
        let n = 8
        for i in 0..<n {
            let x = (Float(i) - Float(n - 1) / 2) * pitch
            let chipped = i == 2
            FA.run(&m, corbel(chipped: chipped), length: 0.09, at: V3(x, 0, 0), browns[(i * 3 + 1) % 4], bevel: 0.003)
            // Carved roll: a half-round on the nose face and two fillets on the step faces.
            if !chipped {
                FA.rod(&m, V3(x, 0.215, 0.262), V3(x, 0.268, 0.262), r: 0.012, browns[(i + 2) % 4], sides: 8)
            }
            for (px, y0, y1) in [(Float(0.1), Float(0.09), Float(0.14)), (0.17, 0.14, 0.19), (0.23, 0.19, 0.21)] {
                FA.box(&m, V3(0.045, y1 - y0 - 0.008, 0.003), V3(x, (y0 + y1) / 2, px + 0.0015), browns[(i + 1) % 4], r: 0.0008)
            }
            // Face mask on the end corbels: brow, eyes, nose, mouth, ears.
            if i == 0 || i == n - 1 {
                let mc = V3(x, 0.195, 0.24)
                let mk = browns[(i + 2) % 4]
                m.add(Prim.superellipsoid(V3(0.062, 0.078, 0.04), exponent: 2.4, subdivisions: 5, material: mk), Xform(translation: mc))
                for s: Float in [-1, 1] {
                    FC.bead(&m, r: 0.008, at: mc + V3(s * 0.016, 0.014, 0.019), soot, sub: 2)
                    m.add(Prim.superellipsoid(V3(0.026, 0.008, 0.012), exponent: 2, subdivisions: 3, material: mk),
                          Xform(translation: mc + V3(s * 0.016, 0.028, 0.019), rotation: FA.q(-s * 15, FA.Z)))
                    FC.bead(&m, r: 0.011, at: mc + V3(s * 0.034, -0.005, 0.0), mk, sub: 2)
                }
                m.add(Prim.superellipsoid(V3(0.014, 0.034, 0.016), exponent: 2, subdivisions: 3, material: mk), Xform(translation: mc + V3(0, -0.002, 0.022)))
                FA.box(&m, V3(0.034, 0.008, 0.008), mc + V3(0, -0.03, 0.017), soot, r: 0.002)
            }
        }
        // Fresh break on the chipped nose.
        FA.box(&m, V3(0.05, 0.03, 0.003), V3((2 - 3.5) * pitch, 0.255, 0.25), "stone.sandstone:E3CFB0", r: 0.001, rot: FA.q(-12, FA.X))

        // Blind arches between the corbels: sooted tympanum and seven wedge voussoirs springing from the corbel sides.
        let spring: Float = 0.15
        for i in 0..<(n - 1) {
            let cx = (Float(i) - Float(n - 2) / 2) * pitch
            let outline = FC.archOutline(width: 0.14, spring: 0, pointed: false, steps: 10)
            m.add(Prim.extrude(outline, depth: 0.012, bevel: 0.0008, bevelSegments: 1, material: soot), Xform(translation: V3(cx, spring, 0.044)))
            FO.voussoirs(&m, c: V2(cx, spring), rIn: 0.07, rOut: 0.098, from: 0, to: 180, count: 7, z0: 0.04, depth: 0.03, gap: 0.003, bevel: 0.0015) { k in
                k == 3 ? sands[(i + 2) % 4] : sands[(i + k) % 4]
            }
        }

        // Cornice slab in three pieces with a drip groove, resting on the roll noses.
        var slab: [V2] = [V2(0, 0.27), V2(0.255, 0.27), V2(0.258, 0.277), V2(0.268, 0.277), V2(0.272, 0.27), V2(0.292, 0.27),
                          V2(0.3, 0.278), V2(0.3, 0.325), V2(0.285, 0.338)]
        slab += [V2(0.26, 0.35), V2(0, 0.35)]
        slab = Shape2D.deduped(slab)
        let pl: Float = (L - 0.008) / 3
        for k in 0..<3 {
            let cx = (Float(k) - 1) * (pl + 0.004)
            FA.run(&m, slab, length: pl, at: V3(cx, 0, 0), browns[(k * 2 + 1) % 4], bevel: 0.003)
        }
        for x in [Float(-0.668), 0.668] {
            FA.box(&m, V3(0.004, 0.07, 0.002), V3(x, 0.31, 0.3005), soot, r: 0.0005)
        }

        // Weathering: soot runs under the slab nose, algae-dark streaks down the base course, damp stain at the bottom.
        for _ in 0..<10 {
            FO.streak(&m, x: rng.float(-0.95...0.95), top: 0.09, w: rng.float(0.02...0.06), h: rng.float(0.04...0.09), z: 0.06, "stone.limestone:5F594A")
        }
        for _ in 0..<7 {
            FO.streak(&m, x: rng.float(-0.95...0.95), top: 0.268, w: rng.float(0.015...0.04), h: rng.float(0.05...0.16), z: 0.04, "stone.sandstone:7B6A55")
        }
        FA.box(&m, V3(L - 0.1, 0.015, 0.002), V3(0, 0.01, 0.0615), "stone.limestone:8E866F", r: 0.0005)

        groundAO(&m, height: 0.1, floor: 0.9)
        return LODModel(FA.centerZ(FC.seatY(m)))
    }
}
