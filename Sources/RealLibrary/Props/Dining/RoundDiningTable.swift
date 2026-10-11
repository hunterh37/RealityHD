import simd
import Foundation

/// Round pedestal dining table, 120 cm across, 76 cm high: 32 mm walnut-veneered top with an eased edge, a
/// 20 mm apron ring, a turned column (base ring, vase, collar), four swept feet with brass toe caps and
/// rubber glides, a mounting plate with four screws and a two-board cross bracket under the top.
public struct RoundDiningTable: RealAsset {
    public static let id = "round-dining-table"
    public static let summary = "Round walnut pedestal dining table, 1.2 m: veneered top, turned column, four swept feet with brass toe caps and a cross bracket."
    public static let tags = ["prop", "floorplan", "dining", "furniture", "wood", "interior"]
    public static let budget = 9000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 22, distance: 2.4, studio: true)

    /// Top diameter in meters.
    public var diameter: Float = 1.2
    /// Overall height in meters.
    public var height: Float = 0.76
    /// Top thickness in meters.
    public var topThickness: Float = 0.032
    /// Top veneer.
    public var topMaterial: MaterialKey = "wood.veneer-walnut:6A4630"
    /// Column, feet and apron wood.
    public var baseMaterial: MaterialKey = "wood.walnut:5A3C28"
    /// Toe cap and screw metal.
    public var metalMaterial: MaterialKey = "metal.brass-aged"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [model(seed: seed, detail: true), model(seed: seed, detail: false)], switchDistances: [5])
    }

    func model(seed: UInt64, detail: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let R = diameter / 2, H = height, t = topThickness
        let underTop = H - t
        let seg = detail ? 2 : 1
        let around = detail ? 56 : 28

        // Top.
        m.add(Prim.extrude(Shape2D.circle(R, segments: around), depth: t, bevel: 0.004, bevelSegments: detail ? 3 : 1, material: topMaterial),
              Xform(translation: V3(0, underTop + t / 2, 0), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        // Banded inlay: two light maple stringing rings flush with the top, 4 mm wide, 60 mm in from the edge.
        for r in [R - 0.06, R - 0.075] {
            m.add(Prim.lathe([V2(r + 0.002, H + 0.0006), V2(r - 0.002, H + 0.0006)], segments: around * 2, seamTile: 1.0, material: "wood.veneer-oak:D9BE8F"))
        }
        // Apron ring: 20 mm thick, 70 mm high, radius 0.5, tight under the top.
        let apron: [V2] = [V2(0.48, underTop - 0.07), V2(0.50, underTop - 0.07), V2(0.50, underTop - 0.0005), V2(0.48, underTop - 0.0005), V2(0.48, underTop - 0.07)]
        m.add(Prim.lathe(apron.map { V2($0.x, $0.y) }, segments: around, seamTile: 0.5, material: baseMaterial))
        // Mounting plate and cross bracket under the top.
        let plateY = underTop - 0.016
        m.add(Prim.roundedBox(V3(0.34, 0.016, 0.34), radius: 0.003, bevelSegments: seg, material: baseMaterial), Xform(translation: V3(0, plateY + 0.0, 0)))
        for a: Float in [0, 90] {
            m.add(plank(0.96, 0.075, 0.03, bevel: 0.0025, material: baseMaterial),
                  Xform(translation: V3(0, underTop - 0.015 - 0.0005, 0), rotation: simd_quatf(degrees: a, axis: .up)))
        }
        if detail {
            for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
                m.add(Prim.cylinder(radius: 0.0055, height: 0.0014, bevel: 0.0005, segments: 10, bevelSegments: 1, material: metalMaterial),
                      Xform(translation: V3(sx * 0.13, plateY - 0.008, sz * 0.13), rotation: simd_quatf(degrees: 180, axis: V3(1, 0, 0))))
            } }
        }

        // Column: turned in one piece from the base ring to the collar under the plate (vertical grain).
        let colTop = plateY - 0.008, colBot: Float = 0.085
        let prof: [(Float, Float)] = [
            (0.0001, colBot), (0.085, colBot), (0.092, colBot + 0.006), (0.092, colBot + 0.022), (0.078, colBot + 0.030), (0.062, colBot + 0.040),
            (0.052, colBot + 0.075), (0.050, colBot + 0.12), (0.072, colBot + 0.17), (0.092, colBot + 0.22), (0.092, colBot + 0.26),
            (0.070, colBot + 0.30), (0.052, colBot + 0.34), (0.050, colBot + 0.40), (0.060, colBot + 0.44), (0.078, colBot + 0.455),
            (0.078, colBot + 0.47), (0.095, colBot + 0.48), (0.095, colTop - colBot - 0.014 + colBot + 0.0), (0.105, colTop), (0.0001, colTop)
        ]
        m.add(turned(prof, segments: detail ? 36 : 18, material: baseMaterial, seamTile: 0.35, grainVertical: true))

        // Feet: four swept legs spiraling out and down from the column base, 55 x 75 mm at the root.
        let toe: Float = 0.485
        let path = catmull([V3(0.04, 0.17, 0), V3(0.14, 0.145, 0), V3(0.26, 0.095, 0), V3(0.38, 0.045, 0), V3(toe, 0.024, 0)], per: detail ? 6 : 3)
        let scales: [Float] = path.indices.map { i in 1.0 - 0.45 * Float(i) / Float(path.count - 1) }
        for k in 0..<4 {
            let rot = simd_quatf(degrees: Float(k) * 90, axis: .up)
            let foot = Prim.sweep(Shape2D.roundedRect(0.055, 0.075, radius: 0.008, segments: seg), along: path, up: V3(0, 0, 1), scales: scales, caps: true, grainAlongPath: true, material: baseMaterial)
            m.add(foot, Xform(rotation: rot).jittered(&rng, deg: 0.15, offset: 0.0003))
            // Brass toe cap and rubber glide.
            let tip = rot.act(V3(toe + 0.004, 0.024, 0))
            m.add(Prim.cylinder(radius: 0.024, height: 0.012, bevel: 0.0035, segments: 16, bevelSegments: 2, material: metalMaterial),
                  Xform(translation: V3(tip.x, 0.0, tip.z)))
            m.add(Prim.cylinder(radius: 0.02, height: 0.004, bevel: 0.0012, segments: 12, bevelSegments: 1, material: "rubber.plate"),
                  Xform(translation: V3(tip.x, 0.0, tip.z)))
        }

        groundAO(&m, height: 0.16, floor: 0.55)
        return m
    }
}
