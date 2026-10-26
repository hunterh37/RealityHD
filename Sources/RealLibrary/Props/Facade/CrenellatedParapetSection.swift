import simd
import Foundation

/// Castellated Gothic crenellated parapet section, 2.4 x 0.9 x 0.4 m: a limestone ashlar wall core with five merlons and
/// four crenels, a stepped corbel table under a moulded string course on both faces, chamfered sandstone copings,
/// lead flashing and drip lips in each crenel, a cross-shaped arrow loop in the centre merlon, iron tie plates with
/// bolts and soot, lichen and drip staining. Base on y = 0 (the roofline).
public struct CrenellatedParapetSection: RealAsset {
    public static let id = "crenellated-parapet-section"
    public static let summary = "Castellated Gothic crenellated parapet section, 2.4 x 0.9 m: limestone ashlar with merlons, crenels, corbel table, arrow loop, lead flashing, iron cramps."
    public static let tags = ["prop", "architecture", "facade", "roof", "stone"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 14, distance: 2.3)

    /// Run length in meters.
    public var length: Float = 2.4
    /// Wall thickness before the corbel table in meters.
    public var wall: Float = 0.3
    /// Ashlar limestone, three tones.
    public var stone: [MaterialKey] = ["stone.limestone", "stone.limestone:D9D2BE", "stone.limestone:C9C0A8", "stone.limestone-sooted", "stone.limestone:B7AE96", "stone.limestone:CFC4A6", "stone.limestone-sooted:A39C88"]
    /// Copings, string course and corbels.
    public var dressed: MaterialKey = "stone.sandstone"
    /// Lead flashing.
    public var lead: MaterialKey = "metal.galvanized-aged"
    public var iron: MaterialKey = "metal.wrought-iron"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let hw = length / 2, T = wall, zw = T / 2
        let mw: Float = 0.32, pitch: Float = 0.52
        let wallTop: Float = 0.64, merTop: Float = 0.86
        let centers: [Float] = (0..<5).map { -1.04 + Float($0) * pitch }
        func isMerlon(_ x: Float) -> Bool { centers.contains { abs(x - $0) <= mw / 2 + 0.002 } }

        // Core: mortar-dark ashlar backing, extruded through the wall thickness with the crenellated top.
        var outline: [V2] = [V2(-hw, 0), V2(hw, 0)]
        for k in stride(from: 4, through: 0, by: -1) {
            let c = centers[k]
            outline.append(V2(c + mw / 2, merTop)); outline.append(V2(c - mw / 2, merTop))
            if k > 0 { outline.append(V2(c - mw / 2, wallTop)); outline.append(V2(centers[k - 1] + mw / 2, wallTop)) }
        }
        m.add(Prim.extrude(Shape2D.deduped(outline), depth: T, bevel: 0.004, bevelSegments: 1, material: "stone.limestone-sooted"))

        // Ashlar courses on both faces: 140 mm courses up to the crenel floor, 120 mm in the merlons.
        let zc = zw + 0.002
        for s: Float in [-1, 1] {
            FO.courses(&m, &rng, xr: -hw...hw, yr: 0.2...wallTop, course: 0.11, block: 0.4, z: s * zc, depth: 0.008, mats: stone)
            FO.courses(&m, &rng, xr: -hw...hw, yr: wallTop...merTop, course: 0.11, block: 0.3, z: s * zc, depth: 0.008, mats: stone,
                       skip: { x0, x1, _, _ in !isMerlon((x0 + x1) / 2) })
        }

        // Stepped corbel table: twelve four-step corbels under a moulded string course.
        let corbel: [V2] = [V2(0, 0), V2(0.018, 0), V2(0.018, 0.04), V2(0.034, 0.04), V2(0.034, 0.08), V2(0.05, 0.08), V2(0.05, 0.12), V2(0, 0.12)]
        for k in 0..<12 {
            FO.runBoth(&m, corbel, length: 0.1, x: -1.1 + Float(k) * 0.2, y: 0, zWall: zw, dressed, bevel: 0.0015)
        }
        let band: [V2] = [V2(0, 0), V2(0.05, 0), V2(0.05, 0.01), V2(0.044, 0.018), V2(0.044, 0.062), V2(0.05, 0.07), V2(0.05, 0.08), V2(0, 0.08)]
        FO.runBoth(&m, band, length: length, y: 0.12, zWall: zw, dressed, bevel: 0.002)

        // Crenels: lead sheet over the full thickness with a drip lip folded down each face; soot streak under the lip.
        for k in 0..<4 {
            let cx = (centers[k] + centers[k + 1]) / 2
            FA.box(&m, V3(0.2 + 0.008, 0.008, T + 0.06), V3(cx, wallTop + 0.004, 0), lead, r: 0.0015)
            for s: Float in [-1, 1] {
                FA.box(&m, V3(0.2, 0.034, 0.004), V3(cx, wallTop - 0.012, s * (zw + 0.0105)), lead, r: 0.001)
                FA.box(&m, V3(0.06 + rng.float(0...0.04), 0.14 + rng.float(0...0.08), 0.0025), V3(cx, 0.54, s * (zc + 0.0065)),
                       "stone.limestone:8A8574", r: 0.001)
                for dx: Float in [-0.07, 0.07] { rivet(&m, at: V3(cx + dx, wallTop - 0.012, s * (zw + 0.0125)), normal: V3(0, 0, s), radius: 0.004, material: lead) }
            }
        }

        // Copings: chamfered sandstone cap on each merlon, overhanging 15 mm per side, each a separate stone.
        for c in centers {
            let w = mw + 0.03
            let cd = T + 0.03
            m.add(Prim.loft([Prim.ring(Shape2D.rounded(Shape2D.rect(w, cd), radius: 0.004, segments: 1), y: 0),
                             Prim.ring(Shape2D.rounded(Shape2D.rect(w, cd), radius: 0.004, segments: 1), y: 0.026),
                             Prim.ring(Shape2D.rounded(Shape2D.rect(w - 0.03, cd - 0.03), radius: 0.004, segments: 1), y: 0.04)],
                            capStart: true, capEnd: true, material: dressed),
                  Xform(translation: V3(c + rng.float(-0.001...0.001), merTop, 0)))
        }

        // Arrow loop in the centre merlon on both faces: dressed surround, cross slit, sill block.
        for s: Float in [-1, 1] {
            let z = s * (zw + 0.0065)
            FA.box(&m, V3(0.15, 0.2, 0.012), V3(0, 0.75, z), dressed, r: 0.002)
            FA.box(&m, V3(0.17, 0.02, 0.016), V3(0, 0.65, s * (zw + 0.008)), dressed, r: 0.002)
            FA.box(&m, V3(0.03, 0.16, 0.004), V3(0, 0.75, s * (zw + 0.0125)), "stone.limestone:151412", r: 0.0008)
            FA.box(&m, V3(0.09, 0.028, 0.004), V3(0, 0.79, s * (zw + 0.0125)), "stone.limestone:151412", r: 0.0008)
        }

        // Iron tie plates (square washer plate with a bolt head and a rust bleed below) on the wall face.
        for x: Float in [-0.8, 0.8] {
            for s: Float in [-1, 1] {
                let z = s * (zc + 0.0045)
                FA.box(&m, V3(0.07, 0.07, 0.008), V3(x, 0.42, z), iron, r: 0.002)
                hexBolt(&m, at: V3(x, 0.42, z + s * 0.004), normal: V3(0, 0, s), size: 0.016, material: "metal.rust")
                FA.box(&m, V3(0.018, 0.1, 0.0022), V3(x + 0.01, 0.34, s * (zc + 0.0066)), "metal.rust:7A4A2E", r: 0.0006)
            }
        }

        // Weathering: soot, lichen and efflorescence on the ashlar.
        FO.patches(&m, &rng, count: 10, xr: -1.1...1.1, yr: 0.24...0.6, w: 0.05...0.16, h: 0.03...0.1, zFace: zc + 0.005,
                   mats: ["stone.limestone:A9A28C", "stone.limestone:8E8F6C", "stone.limestone:BDB6A2"])
        FO.patches(&m, &rng, count: 6, xr: -1.1...1.1, yr: 0.64...0.84, w: 0.03...0.08, h: 0.02...0.06, zFace: zc + 0.005,
                   mats: ["stone.limestone:9A9580", "stone.limestone:8E8F6C"])

        // Rain streaks under every coping and below the crenel lips, rising damp and a green band at the string course.
        for c in centers {
            for s: Float in [-1, 1] {
                for _ in 0..<2 {
                    FO.slab(&m, rng.float(0.008...0.016), rng.float(0.08...0.17), 0.0022,
                            V3(c + rng.float(-0.12...0.12), merTop - 0.1, s * (zc + 0.0068 + 0.0003 * Float(rng.int(0...2)))),
                            "stone.limestone:6F6B5C", bevel: 0.0006)
                }
            }
        }
        for s: Float in [-1, 1] {
            FO.slab(&m, length - 0.04, 0.035, 0.0024, V3(0, 0.222, s * (zc + 0.0072)), "stone.limestone:7C8160", bevel: 0.0008)
            for k in 0..<7 {
                FO.slab(&m, rng.float(0.05...0.14), rng.float(0.01...0.03), 0.0024, V3(-1.05 + Float(k) * 0.35, 0.2, s * (zc + 0.0085)), "stone.limestone:6B7646", bevel: 0.0006)
            }
            // Repair: a bright replacement ashlar and a cracked block pinned with an iron cramp.
            FO.slab(&m, 0.3, 0.102, 0.009, V3(0.55, 0.42, s * (zc + 0.0008)), "stone.limestone:EDE6D2")
            FA.box(&m, V3(0.004, 0.1, 0.0026), V3(-0.3, 0.37, s * (zc + 0.0066)), "stone.limestone:2B2924", r: 0.0005, rot: FA.q(14, FA.Z))
            FA.box(&m, V3(0.14, 0.014, 0.006), V3(-0.3, 0.37, s * (zc + 0.0075)), iron, r: 0.002)
            for dx: Float in [-0.055, 0.055] { hexBolt(&m, at: V3(-0.3 + dx, 0.37, s * (zc + 0.0105)), normal: V3(0, 0, s), size: 0.012, material: "metal.rust") }
        }
        // Moss in the crenel corners.
        for k in 0..<4 {
            let cx = (centers[k] + centers[k + 1]) / 2
            FA.box(&m, V3(0.07, 0.012, 0.09), V3(cx + rng.float(-0.05...0.05), wallTop + 0.01, rng.float(-0.04...0.04)), "stone.granite-moss", r: 0.004)
        }

        groundAO(&m, height: 0.1, floor: 0.85)
        return LODModel(FC.place(m))
    }
}
