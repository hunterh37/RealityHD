import simd
import Foundation

/// Beech pepper mill, 20 cm: a turned body with a flared foot, waist and shoulder, turned grooves, a stainless collar,
/// a mushroom knob with a washer and a steel crown nut, and a steel grinder ring with a burr hole in the base.
/// The waist and knob are hand-darkened and peppercorns lie spilled at the foot.
public struct PepperMill: RealAsset {
    public static let id = "pepper-mill"
    public static let summary = "Turned beech pepper mill with stainless collar, steel crown nut, grinder base, hand-darkened knob and spilled peppercorns."
    public static let tags = ["prop", "interior", "tableware", "wood", "metal", "handheld"]
    public static let budget = 10000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 18, studio: true)

    /// Body wood.
    public var wood: MaterialKey = "wood.beech-spoon-stained"
    /// Hand-darkened wood on the knob and waist.
    public var darkWood: MaterialKey = "wood.beech-spoon-stained:946236"
    /// Peppercorns.
    public var pepper: MaterialKey = "plastic.black:26211E"
    public init() {}

    func level(segs: Int, detail: Bool) -> Model {
        var rng = SeededRNG(seed: 71)
        var m = Model(name: Self.id)
        var prof = Profile.smooth([
            V2(0.0258, 0.0072), V2(0.0290, 0.0150), V2(0.0300, 0.0300), V2(0.0290, 0.0500), V2(0.0262, 0.0800), V2(0.0236, 0.1100),
            V2(0.0226, 0.1350), V2(0.0243, 0.1520), V2(0.0252, 0.1600), V2(0.0240, 0.1656),
        ], per: detail ? 5 : 2)
        // Turned grooves: pairs of fine V cuts.
        for yg: Float in [0.1220, 0.1262, 0.0360, 0.0400] {
            prof = prof.map { p in
                let d = abs(p.y - yg)
                return d < 0.0013 ? V2(p.x - 0.0007 * (1 - d / 0.0013), p.y) : p
            }
        }
        var body = DD1GWare.lathe([V2(0, 0.0072)] + prof + [V2(0.0230, 0.1660), V2(0, 0.1662)], segs: segs, wood, tile: 0.5)
        body.recomputeNormals()
        m.add(body)
        // Hand-darkened band on the waist.
        let waist = prof.filter { $0.y > 0.074 && $0.y < 0.132 }.map { V2($0.x + 0.00025, $0.y) }
        m.add(DD1GWare.lathe(waist + [V2(waist.last!.x - 0.0005, waist.last!.y), V2(waist.first!.x - 0.0005, waist.first!.y), waist[0]], segs: segs, darkWood, tile: 0.5))
        // Stainless collar.
        m.add(DD1GWare.lathe([V2(0.0215, 0.1658), V2(0.0254, 0.1658), V2(0.0258, 0.1666), V2(0.0258, 0.1714), V2(0.0254, 0.1722), V2(0.0215, 0.1722), V2(0.0215, 0.1658)],
                             segs: segs, "metal.stainless-smudged"))
        // Mushroom knob.
        let knob: [V2] = [V2(0, 0.1720), V2(0.0230, 0.1720), V2(0.0242, 0.1732), V2(0.0262, 0.1790), V2(0.0262, 0.1850), V2(0.0244, 0.1900),
                          V2(0.0205, 0.1936), V2(0.0140, 0.1946), V2(0.0090, 0.1950), V2(0, 0.1950)]
        var ks = DD1GWare.lathe(Profile.smooth(knob, per: detail ? 3 : 1), segs: segs, darkWood, tile: 0.5)
        ks.recomputeNormals()
        m.add(ks)
        // Washer and hex crown nut.
        m.add(Prim.cylinder(radius: 0.0105, height: 0.0013, bevel: 0.0003, segments: 24, material: "metal.steel"), Xform(translation: V3(0, 0.1950, 0)))
        let nut = Prim.extrude(Shape2D.polygon(sides: 6, radius: 0.0085), depth: 0.0040, bevel: 0.0007, bevelSegments: 2, material: "metal.steel")
        m.add(nut, Xform(translation: V3(0, 0.1983, 0), rotation: simd_quatf(degrees: -90, axis: V3(1, 0, 0))))
        // Steel grinder ring at the foot with a burr hole.
        m.add(DD1GWare.lathe([V2(0, 0.0042), V2(0.0130, 0.0042), V2(0.0150, 0.0014), V2(0.0165, 0), V2(0.0200, 0), V2(0.0214, 0.0020), V2(0.0216, 0.0074), V2(0, 0.0074)],
                             segs: segs, "metal.stainless"))
        m.add(DD1GWare.lathe([V2(0, 0.0036), V2(0.0048, 0.0036), V2(0.0052, 0.0044), V2(0, 0.0044)], segs: 14, "metal.parkerized"))
        // Spilled peppercorns.
        DD1GWare.grains(&m, &rng, center: V3(0.0246, 0, 0.0246), radiusMin: 0.0, radiusMax: 0.0042, count: detail ? 7 : 3, size: 0.0042,
                        angle: 0...2 * .pi, material: pepper, round: true)
        DD1GWare.plant(&m)
        groundAO(&m, height: 0.012, floor: 0.75)
        return m
    }

    public func build(seed: UInt64) -> LODModel {
        _ = seed
        return LODModel(levels: [level(segs: 40, detail: true), level(segs: 18, detail: false)], switchDistances: [2.5])
    }
}
