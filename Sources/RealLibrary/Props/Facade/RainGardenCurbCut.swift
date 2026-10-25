import simd
import Foundation

/// Rain garden curb cut: a 400 mm wide street-side opening in a 150 mm granite curb (200 mm reveal), 6 mm arris
/// radius, with 45 degree flared wing stones, a concrete gutter apron and sloped throat slab, a river-cobble
/// energy-dissipation pad bedded in silt loam, and tufted sedge (Carex) clumps flanking the inlet. Silt stains the
/// throat, tyre rubber smears the curb face, road salt crusts the top, and moss grows in the open joints.
public struct RainGardenCurbCut: RealAsset {
    public static let id = "rain-garden-curb-cut"
    public static let summary = "Granite curb with flared 400 mm inlet, concrete apron, cobble splash pad, sedge clumps, silt and tyre stains."
    public static let tags = ["prop", "architecture", "facade", "stone"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 24, distance: 1.7)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(1.0, 0.2, 0.5)
    public var granite: MaterialKey = "stone.granite-curb"
    public var concrete: MaterialKey = "concrete.sidewalk"
    public var sedge: MaterialKey = "leaf.river-cane"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let h: Float = 0.2
        func slab(_ x0: Float, _ x1: Float, _ z0: Float, _ z1: Float, _ y0: Float, _ y1: Float, _ mat: MaterialKey, r: Float = 0.004) {
            FA.box(&m, V3(x1 - x0, y1 - y0, z1 - z0), V3((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2), mat, r: r)
        }
        // Street gutter apron (z 0.30 ... 0.50): 15 mm pan with a trowelled lip, saw-cut joints.
        slab(-0.5, 0.5, 0.30, 0.44, 0, 0.016, concrete, r: 0.002)
        // Asphalt roadway edge (z 0.44 ... 0.50) with a poured sealant joint and a raveled patch.
        slab(-0.5, 0.5, 0.444, 0.50, 0, 0.0145, "asphalt.road", r: 0.002)
        FA.box(&m, V3(1.0, 0.0012, 0.008), V3(0, 0.0156, 0.442), "asphalt.sealant", r: 0.0004)
        m.add(Prim.superellipsoid(V3(0.16, 0.002, 0.04), exponent: 2.4, subdivisions: 3, material: "asphalt.patch"), Xform(translation: V3(0.2, 0.0155, 0.475)))
        for x in [-0.25, 0.25] as [Float] { FA.box(&m, V3(0.003, 0.0008, 0.14), V3(x, 0.0164, 0.37), "wood.charred", r: 0.0002) }
        // Throat slab between the wings, 20 mm at the street falling to the garden.
        let thr: [V2] = [V2(0, 0), V2(0.15, 0), V2(0.15, 0.004), V2(0, 0.02)]
        m.add(Prim.extrude(thr, depth: 0.46, bevel: 0.002, bevelSegments: 1, material: concrete), Xform(translation: V3(0, 0, 0.30), rotation: FA.q(90, FA.Y)))
        // Granite curb stones with flared wings: top-view outlines extruded up 200 mm.
        for s: Float in [-1, 1] {
            let o: [V2] = [V2(0.5 * s, 0.15), V2(0.2 * s, 0.15), V2(0.3 * s, 0.30), V2(0.5 * s, 0.30)].map { V2($0.x, -$0.y) }
            m.add(Prim.extrude(o.map { $0 }, depth: h, bevel: 0.006, bevelSegments: 2, material: granite), Xform(translation: V3(0, h / 2, 0), rotation: FA.q(-90, FA.X)))
        }
        // Face and top weathering: tyre rubber scuffs and salt crust.
        for _ in 0..<7 {
            let x = rng.float(0.26...0.48) * (rng.chance(0.5) ? 1 : -1)
            FC.slab(&m, V3(rng.float(0.05...0.14), rng.float(0.003...0.007), 0.0006), V3(x, rng.float(0.04...0.14), 0.3006), "metal.rust:2A2623")
        }
        for _ in 0..<4 {
            FA.box(&m, V3(rng.float(0.03...0.07), 0.0008, rng.float(0.015...0.04)), V3(rng.float(0.28...0.48) * (rng.chance(0.5) ? 1 : -1), h + 0.0004, 0.22 + rng.float(-0.03...0.03)), "concrete.smooth:D8D5CC", r: 0.0002)
        }
        // Silt tongue across the throat and onto the apron: overlapping thin lenses.
        for (x, z, w, d) in [(0.0, 0.25, 0.3, 0.12), (-0.04, 0.3, 0.22, 0.1), (0.05, 0.19, 0.18, 0.09), (0.0, 0.36, 0.1, 0.05)] as [(Float, Float, Float, Float)] {
            m.add(Prim.superellipsoid(V3(w, 0.005, d), exponent: 2.4, subdivisions: 4, material: "soil.potting"), Xform(translation: V3(x, 0.024, z)))
        }
        // Oil drip, wet stain and hairline crack on the apron.
        m.add(Prim.superellipsoid(V3(0.18, 0.001, 0.07), exponent: 2, subdivisions: 3, material: "concrete.smooth:7E7A70"), Xform(translation: V3(-0.32, 0.0165, 0.4)))
        m.add(Prim.superellipsoid(V3(0.1, 0.001, 0.05), exponent: 2, subdivisions: 3, material: "concrete.smooth:7E7A70"), Xform(translation: V3(0.36, 0.0165, 0.44)))
        FA.box(&m, V3(0.002, 0.0006, 0.14), V3(0.12, 0.0164, 0.42), "wood.charred", r: 0.0002)
        // Silt loam bed and cobble pad (z 0 ... 0.15), 20 cobbles of 60 - 110 mm, partially embedded.
        slab(-0.5, 0.5, 0.0, 0.15, 0, 0.028, "soil.potting", r: 0.003)
        let cm: [MaterialKey] = ["stone.granite-paver", "stone.slate", "stone.granite-moss", "stone.sandstone", "stone.granite-paver"]
        for i in 0..<26 {
            let cx = -0.46 + Float(i % 9) * 0.115 + rng.float(-0.02...0.02), cz = 0.025 + Float(i / 9) * 0.05 + rng.float(-0.01...0.01)
            let w = rng.float(0.07...0.105)
            m.add(Prim.superellipsoid(V3(w, rng.float(0.04...0.06), w * rng.float(0.7...0.95)), exponent: 2.6, subdivisions: 3, material: cm[rng.int(0...4)]),
                  Xform(translation: V3(cx, 0.03, cz), rotation: FA.q(rng.float(0...180), FA.Y)))
        }
        // Moss in the cobble gaps and the curb's open joint.
        for _ in 0..<7 {
            m.add(Prim.superellipsoid(V3(rng.float(0.03...0.07), 0.01, 0.025), exponent: 2.2, subdivisions: 2, material: "moss.cushion"),
                  Xform(translation: V3(rng.float(-0.45...0.45), 0.052, rng.float(0.02...0.14))))
        }
        // Sedge clumps: crossed leaf cards flanking the inlet and along the back edge.
        for (cx, cz) in [(-0.38, 0.1), (-0.3, 0.04), (0.33, 0.09), (0.41, 0.03), (-0.1, 0.02), (0.12, 0.04), (-0.46, 0.05), (0.47, 0.11), (-0.2, 0.06), (0.22, 0.07)] as [(Float, Float)] {
            for k in 0..<4 {
                let hh = rng.float(0.12...0.17)
                FC.leafCard(&m, sedge, at: V3(cx + rng.float(-0.02...0.02), 0.04, cz), width: hh * 0.95, height: hh, spin: rng.float(-10...10), tilt: rng.float(-12...12), yaw: Float(k) * 60 + rng.float(-10...10))
            }
        }
        groundAO(&m, height: 0.1, floor: 0.75)
        return LODModel(FC.fit(m, size))
    }
}
