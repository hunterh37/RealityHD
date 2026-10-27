import simd
import Foundation

/// Electric citrus juicer: white plastic base on rubber feet with a dial, steel strainer basket, ribbed reamer cone, pouring spout and a clear dust cover. Story: orange pulp and juice dried on the cone and spout.
public struct JuicerCitrus: RealAsset {
    public static let id = "juicer-citrus"
    public static let summary = "Electric citrus juicer, 19 cm: white plastic base, steel strainer basket, ribbed reamer cone, clear lid and spout."
    public static let tags = ["prop", "interior", "kitchen", "plastic", "metal"]
    public static let budget = 14500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 22, distance: 1.15, studio: true)

    /// Base shell and reamer cone.
    public var plastic: MaterialKey = "plastic.white"
    /// Strainer basket.
    public var steel: MaterialKey = "metal.stainless"
    /// Dust cover.
    public var cover: MaterialKey = "plastic.polycarbonate-tint"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Rubber feet.
        for i in 0..<4 {
            let a = Float(i) / 4 * 2 * .pi + .pi / 4
            m.add(Prim.cylinder(radius: 0.0125, height: 0.0075, bevel: 0.0015, segments: 16, material: "rubber.insulating-black"),
                  Xform(translation: V3(0.066 * cos(a), 0, 0.066 * sin(a))))
        }
        // Base shell.
        let base: [V2] = [V2(0, 0.0072), V2(0.0788, 0.0072), V2(0.0882, 0.0100), V2(0.0928, 0.0200), V2(0.0936, 0.0450), V2(0.0911, 0.0780), V2(0.0857, 0.1000),
                          V2(0.0788, 0.1120), V2(0.0729, 0.1180), V2(0.0670, 0.1185), V2(0.0630, 0.1120), V2(0.0552, 0.1070), V2(0, 0.1070)]
        m.add(Prim.lathe(base, segments: 48, seamTile: 0.2, material: plastic))
        // Seam between base halves and a dial on the front.
        m.add(Prim.lathe([V2(0.0942, 0.0560), V2(0.0958, 0.0560), V2(0.0958, 0.0575), V2(0.0942, 0.0575), V2(0.0942, 0.0560)], segments: 64, seamTile: 0.2, material: "plastic.black"))
        DD1EKitchen.frontCylinder(&m, at: V3(0, 0.0330, 0.0905), radius: 0.0135, length: 0.0120, material: "plastic.black")
        m.add(Prim.roundedBox(V3(0.0030, 0.0090, 0.0012), radius: 0.0005, bevelSegments: 1, material: "plastic.white"), Xform(translation: V3(0, 0.0395, 0.1027)))
        // Strainer basket: perforated wall with a steel rim and base ring.
        let wall: [V2] = [V2(0.0560, 0.1100), V2(0.0600, 0.1250), V2(0.0640, 0.1400), V2(0.0636, 0.1400), V2(0.0596, 0.1250), V2(0.0556, 0.1100)]
        m.add(Prim.lathe(wall, segments: 40, seamTile: 0.06, material: "metal.perforated"))
        m.add(Prim.lathe([V2(0.0612, 0.1385), V2(0.0668, 0.1400), V2(0.0668, 0.1425), V2(0.0640, 0.1440), V2(0.0600, 0.1425), V2(0.0600, 0.1395), V2(0.0612, 0.1385)], segments: 56, seamTile: 0.1, material: steel))
        m.add(Prim.cylinder(radius: 0.0575, height: 0.0045, bevel: 0.0012, segments: 40, material: steel), Xform(translation: V3(0, 0.1100, 0)))
        // Reamer cone: straight ribbed cone with a centre spindle.
        let cone: [V2] = [V2(0, 0.1140), V2(0.0430, 0.1140), V2(0.0440, 0.1170), V2(0.0425, 0.1215), V2(0.0060, 0.1840), V2(0.0035, 0.1880), V2(0.0010, 0.1900), V2(0, 0.1902)]
        m.add(Prim.lathe(cone, segments: 40, seamTile: 0.08, material: plastic))
        let lo = V2(0.0425, 0.1215), hi = V2(0.0060, 0.1840)
        let d = simd_normalize(hi - lo), phi = atan2(-d.x, d.y)
        let len = simd_length(hi - lo)
        let nrm = V2(d.y, -d.x)
        for i in 0..<16 {
            let a = Float(i) / 16 * 2 * .pi
            let c = (lo + hi) / 2 + nrm * 0.0006
            m.add(Prim.roundedBox(V3(0.0026, len, 0.0026), radius: 0.0009, bevelSegments: 1, material: plastic),
                  Xform(translation: V3(c.x * cos(a), c.y, -c.x * sin(a)), rotation: DD1EKitchen.rotY(a * 180 / .pi) * simd_quatf(angle: phi, axis: V3(0, 0, 1))))
        }
        // Pouring spout on the front lip, with dried pulp.
        let spout = Shape2D.rounded([V2(-0.0200, 0.0600), V2(0.0200, 0.0600), V2(0.0115, 0.0930), V2(-0.0115, 0.0930)], radius: 0.0040)
        m.add(Prim.extrude(spout, depth: 0.0085, bevel: 0.0018, bevelSegments: 2, material: plastic),
              Xform(translation: V3(0, 0.1165, 0), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        m.add(Prim.superellipsoid(V3(0.0240, 0.0009, 0.0130), exponent: 2.4, subdivisions: 8, material: "plastic.orange:E8A531"),
              Xform(translation: V3(0.002, 0.1213, 0.0780), rotation: simd_quatf(degrees: 0, axis: V3(1, 0, 0))))
        for i in 0..<6 {
            let a = rng.float(0...(2 * .pi)), rr = rng.float(0.014...0.032), hh = 0.1215 + (0.0425 - rr) * 1.72 + 0.0008
            m.add(Prim.superellipsoid(V3(0.0045, 0.0014, 0.0035), exponent: 2.4, subdivisions: 6, material: "plastic.orange:E39A2B"),
                  Xform(translation: V3(rr * cos(a), hh, -rr * sin(a)), rotation: DD1EKitchen.rotY(a * 180 / .pi)))
        }
        // Clear dust cover on the base rim with a knob.
        let dome: [V2] = [V2(0.0948, 0.1185), V2(0.0953, 0.1300), V2(0.0926, 0.1650), V2(0.0827, 0.1950), V2(0.0630, 0.2130), V2(0.0374, 0.2190), V2(0.0177, 0.2200),
                          V2(0.0177, 0.2175), V2(0.0372, 0.2165), V2(0.0624, 0.2105), V2(0.0818, 0.1925), V2(0.0911, 0.1640), V2(0.0929, 0.1300), V2(0.0923, 0.1190)]
        m.add(Prim.lathe(dome, segments: 48, seamTile: 0.3, material: cover))
        m.add(Prim.cylinder(radius: 0.0150, height: 0.0090, bevel: 0.0030, segments: 28, material: plastic), Xform(translation: V3(0, 0.2130, 0)))
        // Hinge lugs at the back of the cover.
        for s: Float in [-1, 1] {
            m.add(Prim.roundedBox(V3(0.0160, 0.0140, 0.0090), radius: 0.0030, bevelSegments: 2, material: plastic), Xform(translation: V3(s * 0.0300, 0.1235, -0.0900)))
        }
        // Juice drips run down the front of the base from the spout.
        for (i, dx) in [Float(0.004), -0.007, 0.012].enumerated() {
            let hh: Float = 0.030 - Float(i) * 0.007, yc: Float = 0.1085 - hh / 2 - Float(i) * 0.004
            let r = sqrt(max(0.0895 * 0.0895 - dx * dx, 0.0001))
            m.add(Prim.superellipsoid(V3(0.0042, hh, 0.0016), exponent: 2.6, subdivisions: 5, material: "plastic.orange:E8A531"),
                  Xform(translation: V3(dx, yc, r)))
        }
        _ = rng.float()
        let b = m.bounds
        m = m.transformed(Xform(translation: V3(0, -b.min.y, 0)))
        groundAO(&m, height: 0.03, floor: 0.7)
        return LODModel(m)
    }
}
