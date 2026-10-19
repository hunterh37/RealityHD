import simd
import Foundation

/// Cold plate: Factory new, mirror-polished copper, satin nickel.. Parts: copper base, nickel cover, inlet port, outlet port, mounting screws, gasket.
public struct ColdPlate: RealAsset {
    public static let id = "cold-plate"
    public static let summary = "Direct-to-chip microchannel cold plate: polished copper base with nickel-plated cover, two barbed coolant ports, four spring-loaded mounting screws and gasket."
    public static let tags = ["prop"]
    public static let budget = 3000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.12, 0.015, 0.18)
    /// Copper base material key.
    public var copper: MaterialKey = "copper.polished"
    /// Cover and screw plating material key.
    public var nickel: MaterialKey = "metal.nickel"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = size.x, D = size.z
        let baseT: Float = 0.003
        // Copper base plate with rounded corners and chamfered edge.
        m.add(Prim.extrude(Shape2D.rounded(Shape2D.rect(W, D), radius: 0.006, segments: 3), depth: baseT, bevel: 0.0008, bevelSegments: 1, material: copper),
              Xform(translation: V3(0, baseT / 2, 0), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        // Silicone gasket ring seated on the base around the cover.
        let cw: Float = W - 0.024
        let cd: Float = D - 0.034
        let gw = cw + 0.006, gd = cd + 0.006
        for (sx, sz, w, d) in [(Float, Float, Float, Float)]([(0.0, 1.0, gw, 0.003), (0.0, -1.0, gw, 0.003), (1.0, 0.0, 0.003, gd), (-1.0, 0.0, 0.003, gd)]) {
            m.add(Prim.roundedBox(V3(w, 0.0012, d), radius: 0.0005, bevelSegments: 1, material: "plastic.matte"),
                  Xform(translation: V3(sx * (gw / 2), baseT + 0.0006, sz * (gd / 2))))
        }
        // Nickel-plated cover with a stepped top and rolled edge.
        let coverY = baseT + 0.0012
        m.add(Prim.roundedBox(V3(cw, 0.0042, cd), radius: 0.0018, bevelSegments: 1, material: nickel),
              Xform(translation: V3(0, coverY + 0.0021, 0)))
        m.add(Prim.roundedBox(V3(cw - 0.012, 0.0017, cd - 0.012), radius: 0.001, bevelSegments: 1, material: nickel),
              Xform(translation: V3(0, coverY + 0.0042 + 0.00075, 0)))
        let topY = coverY + 0.0042 + 0.0015
        // Two barbed ports (inlet blue cap, outlet red cap) at the short ends.
        for (sz, cap) in [(Float(-1.0), "plastic.matte:2A5CB8"), (Float(1.0), "plastic.matte:B51D17")] {
            let pz = sz * (cd / 2 - 0.016)
            m.add(Prim.cylinder(radius: 0.0052, height: 0.0014, bevel: 0.0004, segments: 12, material: nickel), Xform(translation: V3(0, topY - 0.0006, pz)))
            m.add(Prim.cylinder(radius: 0.0036, height: 0.004, bevel: 0.0004, segments: 12, material: nickel), Xform(translation: V3(0, topY, pz)))
            for k in 0..<2 {
                m.add(Prim.lathe([V2(0.0034, 0), V2(0.0046, 0.0008), V2(0.0046, 0.0012), V2(0.0034, 0.0016)], segments: 12, material: nickel),
                      Xform(translation: V3(0, topY + 0.0012 + Float(k) * 0.0017, pz)))
            }
            m.add(Prim.cylinder(radius: 0.0041, height: 0.0016, bevel: 0.0005, segments: 12, material: cap), Xform(translation: V3(0, topY + 0.0036, pz)))
        }
        // Four spring-loaded captive screws on the base ears.
        for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
            let p = V3(sx * (W / 2 - 0.0058), baseT, sz * (D / 2 - 0.0058))
            for k in 0..<3 {
                m.add(Prim.torus(major: 0.0034, minor: 0.00035, segments: 12, sides: 5, material: nickel), Xform(translation: p + V3(0, 0.0004 + Float(k) * 0.0009, 0)))
            }
            m.add(Prim.cylinder(radius: 0.0026, height: 0.0016, bevel: 0.0004, segments: 12, material: nickel), Xform(translation: p + V3(0, 0.0028, 0)))
            m.add(Prim.cylinder(radius: 0.0012, height: 0.0034, bevel: 0.0002, segments: 12, material: nickel), Xform(translation: p + V3(0, -0.0012, 0)))
            hexBolt(&m, at: p + V3(0, 0.0044, 0), normal: V3(0, 1, 0), size: 0.0018, material: nickel)
        } }
        // Story detail: laser-etched serial plate on the cover.
        m.add(Prim.roundedBox(V3(0.026, 0.0004, 0.008), radius: 0.0001, bevelSegments: 1, material: "metal.stainless"),
              Xform(translation: V3(0.016, topY + 0.0002, 0.0)))
        groundAO(&m)
        return LODModel(m)
    }
}
