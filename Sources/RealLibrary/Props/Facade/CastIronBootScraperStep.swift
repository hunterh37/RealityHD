import simd
import Foundation

/// Victorian cast-iron boot scraper, 0.4 x 0.25 x 0.2 m: a slotted mud plate with four countersunk anchor holes,
/// two pierced lyre-profile end plates, an upper scraper blade with a sharpened top edge and a lower round bar,
/// both through-bolted with hex nuts. Black paint is worn off the blade edge to bright steel and off the plate
/// edges to rust, with dried mud in the slots and a rust run below each bolt.
public struct CastIronBootScraperStep: RealAsset {
    public static let id = "cast-iron-boot-scraper-step"
    public static let summary = "Victorian cast-iron boot scraper, 0.4 x 0.25 m: slotted base plate, pierced lyre end plates, sharpened scraper blade, lower bar and hex bolts."
    public static let tags = ["prop", "architecture", "facade", "decor", "metal"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 22, distance: 1.1)

    /// Black painted cast iron.
    public var iron: MaterialKey = "metal.wrought-iron"
    /// Bare cast iron under the paint.
    public var cast: MaterialKey = "metal.cast-iron"
    /// Rust.
    public var rust: MaterialKey = "metal.rust"
    /// Polished steel of the scraping edge.
    public var steel: MaterialKey = "metal.bolt-bright"
    /// Dried mud.
    public var mud: MaterialKey = "paint.stucco:5E4C38"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [make(seed: seed, lite: false), make(seed: seed, lite: true)], switchDistances: [2])
    }

    func make(seed: UInt64, lite: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let n = lite ? 12 : 24
        // Mud plate: 0.4 x 0.2, 14 mm thick, with drain slots and four anchor holes.
        var holes: [[V2]] = []
        for k in 0..<5 {
            let x = -0.13 + Float(k) * 0.065
            holes.append(HTKit.slot(V2(x, -0.045), V2(x, 0.045), r: 0.009, n: lite ? 4 : 6))
        }
        for (hx, hy) in [(Float(-0.175), Float(0.075)), (0.175, 0.075), (-0.175, -0.075), (0.175, -0.075)] { holes.append(HTKit.ellipse(V2(hx, hy), a: 0.0075, b: 0.0075, n: lite ? 8 : 12)) }
        let outer: [V2] = Shape2D.rounded([V2(-0.2, -0.1), V2(0.2, -0.1), V2(0.2, 0.1), V2(-0.2, 0.1)], radius: 0.012)
        m.add(HTKit.plate(outer: outer, holes: holes, depth: 0.014, bevel: 0.003, segments: 2, material: iron), Xform(translation: V3(0, 0.007, 0), rotation: FA.q(90, FA.X)))
        // Raised rim along the front and back edges.
        for s: Float in [-1, 1] { FA.box(&m, V3(0.39, 0.01, 0.01), V3(0, 0.017, s * 0.0925), iron, r: 0.003) }
        // Pierced lyre end plates (profile in z, y; thickness along x).
        let lyre: [V2] = [V2(-0.09, 0), V2(0.09, 0), V2(0.09, 0.028), V2(0.062, 0.05), V2(0.048, 0.12), V2(0.062, 0.165), V2(0.074, 0.2), V2(0.056, 0.222), V2(0.0, 0.232),
                          V2(-0.056, 0.222), V2(-0.074, 0.2), V2(-0.062, 0.165), V2(-0.048, 0.12), V2(-0.062, 0.05), V2(-0.09, 0.028)]
        for s: Float in [-1, 1] {
            let cutouts: [[V2]] = [HTKit.ellipse(V2(0, 0.145), a: 0.028, b: 0.034, n: n), HTKit.ellipse(V2(0, 0.065), a: 0.016, b: 0.016, n: lite ? 8 : 14)]
            // Local XY plate rotated so local x runs along world z and the thickness along world x.
            m.add(HTKit.plate(outer: lyre, holes: cutouts, depth: 0.014, bevel: 0.003, segments: 2, material: iron),
                  Xform(translation: V3(s * 0.183, 0.0, 0), rotation: FA.q(90, FA.Y)))
            // Cast ring mouldings around the large opening (torus on the outer face).
            m.add(Prim.torus(major: 0.034, minor: 0.0042, segments: lite ? 10 : 20, sides: 5, material: iron),
                  Xform(translation: V3(s * (0.183 + 0.0105), 0.145, 0), rotation: FA.q(90, FA.Z)))
            // Ball finial on top of each end plate.
            FC.bead(&m, r: 0.0115, at: V3(s * 0.183, 0.2385, 0), cast, sub: lite ? 2 : 3)
        }
        // Scraper blade: flat bar with a sharpened top edge, spanning the end plates.
        FA.run(&m, [V2(-0.0065, 0.19), V2(0.0065, 0.19), V2(0.0065, 0.226), V2(0.0015, 0.2415), V2(-0.0015, 0.2415), V2(-0.0065, 0.226)], length: 0.36, at: .zero, iron, bevel: 0.0008)
        // Steel edge polished by boots.
        FA.run(&m, [V2(-0.0017, 0.2335), V2(0.0017, 0.2335), V2(0.0017, 0.2418), V2(-0.0017, 0.2418)], length: 0.3, at: .zero, steel, bevel: 0.0003)
        // Lower round bar and a flat stay between the plates.
        FA.rod(&m, V3(-0.19, 0.095, 0), V3(0.19, 0.095, 0), r: 0.0085, iron, sides: lite ? 6 : 10)
        FA.run(&m, [V2(-0.005, 0.045), V2(0.005, 0.045), V2(0.005, 0.07), V2(-0.005, 0.07)], length: 0.36, at: .zero, iron, bevel: 0.0008)
        // Through-bolts: hex heads outside, nuts on the other side of the blade and bar.
        for s: Float in [-1, 1] {
            for (y, z) in [(Float(0.21), Float(0.0)), (0.095, 0.0), (0.057, 0.0)] {
                FA.cylX(&m, r: 0.0085, h: 0.0065, at: V3(s * (0.19 + (s > 0 ? 0.0 : 0.0)), y, z) + V3(s > 0 ? 0 : -0.0065, 0, 0), cast, bevel: 0.0012, segments: 6)
            }
        }
        // Weathering.
        if !lite {
            // Paint worn to rust along the plate rim and the end plate edges.
            for _ in 0..<8 { FO.patchTop(&m, cx: rng.float(-0.18...0.18), cz: rng.pick([Float(-0.0925), 0.0925]) + rng.float(-0.004...0.004), rx: rng.float(0.01...0.04), rz: 0.004, y: 0.0221, rust, rng: &rng, depth: 0.0006, n: 7) }
            for _ in 0..<7 { FO.patchTop(&m, cx: rng.float(-0.19...0.19), cz: rng.float(-0.09...0.09), rx: rng.float(0.01...0.03), rz: rng.float(0.01...0.03), y: 0.0141, rust, rng: &rng, depth: 0.0006, n: 8) }
            // Dried mud in the slots and a smear on the plate between them.
            for k in 0..<5 { FO.patchTop(&m, cx: -0.13 + Float(k) * 0.065, cz: rng.float(-0.02...0.02), rx: 0.011, rz: rng.float(0.02...0.04), y: 0.0143, mud, rng: &rng, depth: 0.0008, n: 8) }
            for _ in 0..<3 { FO.patchTop(&m, cx: rng.float(-0.17...0.17), cz: rng.float(-0.085...0.085), rx: rng.float(0.02...0.05), rz: rng.float(0.01...0.03), y: 0.0144, mud, rng: &rng, depth: 0.0008, n: 9) }
            // Rust runs below the bolts on the outer faces, and chips on the lyre rim.
            for s: Float in [-1, 1] {
                for y in [Float(0.21), 0.095, 0.057] { FA.box(&m, V3(0.0016, rng.float(0.02...0.05), 0.006), V3(s * 0.2012, y - 0.03, 0.0), rust, r: 0.0005) }
            }
            // Blade grime: a streak of rust along the foot of the blade.
            FA.run(&m, [V2(-0.0067, 0.19), V2(0.0067, 0.19), V2(0.0067, 0.2), V2(-0.0067, 0.2)], length: 0.2, at: V3(0.05, 0, 0), rust, bevel: 0.0003)
        }
        groundAO(&m, height: 0.06, floor: 0.8)
        return FC.place(m)
    }
}
