import simd
import Foundation

/// Salt canister: 8 cm wide, 14 cm tall cardboard cylinder with a spiral-wound body wrap and lap seam, galvanized crimped top and bottom
/// rims, a metal pour spout with a hinged flap, printed bands, a body dent and salt crystals spilled around the spout.
public struct SaltCanister: RealAsset {
    public static let id = "salt-canister"
    public static let summary = "Cardboard salt canister, 14 cm: crimped metal rims, pour spout with open flap, wrapped label, dent, spilled salt."
    public static let tags = ["prop", "interior", "pantry", "paper", "metal", "container", "food"]
    public static let budget = 9000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 20, distance: 0.9, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.08, 0.14, 0.08)
    /// Body wrap, rim metal and printed colour keys.
    public var wrap: MaterialKey = "plastic.white:2F5E9E"
    public var rim: MaterialKey = "metal.galvanized-aged"
    public var print: MaterialKey = "plastic.white:F1E7CC"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let r: Float = 0.0385, top: Float = 0.122
        // Body wrap with a dent on the left side, as cardboard canisters pick up.
        var body = Prim.lathe([V2(0, 0.004), V2(r - 0.0004, 0.004), V2(r, 0.0045), V2(r, top - 0.002), V2(r - 0.0006, top), V2(0, top)],
                              segments: 64, seamTile: 0.12, material: wrap)
        let dent = V3(-r, 0.06, 0)
        body.displace { p, _ in
            let d = simd_length(p - dent)
            return p.x < 0 ? -0.0014 * exp(-d * d / 0.0006) : 0
        }
        m.add(body)
        // Printed bands, cream label field with lap seam.
        m.add(Prim.lathe([V2(r + 0.0002, 0.028), V2(r + 0.0006, 0.0285), V2(r + 0.0006, 0.0955), V2(r + 0.0002, 0.096)], segments: 64, seamTile: 0.12, material: print))
        m.add(Prim.roundedBox(V3(0.007, 0.066, 0.0005), radius: 0.00015, bevelSegments: 1, material: print), Xform(translation: V3(0, 0.062, -(r + 0.0006))))
        for y in [Float(0.034), 0.088] {
            m.add(Prim.lathe([V2(r + 0.0006, y), V2(r + 0.0010, y + 0.0002), V2(r + 0.0010, y + 0.0052), V2(r + 0.0006, y + 0.0054)],
                             segments: 64, seamTile: 0.12, material: "plastic.white:C8281C"))
        }
        m.add(Prim.cylinder(radius: 0.0185, height: 0.0006, bevel: 0.0002, segments: 32, bevelSegments: 1, material: "plastic.white:2F5E9E"),
              Xform(translation: V3(0, 0.062, r + 0.0012), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        // Crimped bottom rim and top rim with a rolled bead.
        m.add(Prim.lathe([V2(r - 0.0004, 0), V2(r + 0.0011, 0.0012), V2(r + 0.0013, 0.0052), V2(r + 0.0004, 0.0088), V2(r - 0.0006, 0.0088), V2(r - 0.0006, 0.0)],
                         segments: 64, seamTile: 0.1, material: rim))
        m.add(Prim.lathe([V2(r - 0.0006, top - 0.0075), V2(r + 0.0010, top - 0.0072), V2(r + 0.0014, top - 0.004), V2(r + 0.0014, top + 0.0018),
                          V2(r + 0.0004, top + 0.0032), V2(r - 0.0020, top + 0.0032), V2(r - 0.0020, top - 0.0075)], segments: 64, seamTile: 0.1, material: rim))
        // Top disc and raised pour spout ring.
        m.add(Prim.cylinder(radius: r - 0.0016, height: 0.0030, bevel: 0.0008, segments: 56, bevelSegments: 2, material: rim), Xform(translation: V3(0, top + 0.0012, 0)))
        let sp = top + 0.0042
        m.add(Prim.lathe([V2(0.0125, sp), V2(0.0150, sp), V2(0.0158, sp + 0.0016), V2(0.0158, sp + 0.0042), V2(0.0148, sp + 0.0052),
                          V2(0.0132, sp + 0.0046), V2(0.0132, sp + 0.0010)], segments: 40, seamTile: 0.08, material: rim))
        m.add(Prim.cylinder(radius: 0.0105, height: 0.0008, bevel: 0.0002, segments: 24, bevelSegments: 1, material: "metal.steel"), Xform(translation: V3(0, sp - 0.0008, 0)))
        // Hinged flap raised about 70 degrees on its back edge.
        m.add(Prim.cylinder(radius: 0.0100, height: 0.0010, bevel: 0.0003, segments: 24, bevelSegments: 1, material: "metal.nickel-worn").transformed(Xform(translation: V3(0, 0, 0.0100))),
              Xform(translation: V3(0, sp + 0.0030, -0.0105), rotation: simd_quatf(degrees: -35, axis: V3(1, 0, 0))))
        m.add(Prim.cylinder(radius: 0.0016, height: 0.012, bevel: 0.0005, segments: 12, bevelSegments: 1, material: rim),
              Xform(translation: V3(-0.006, sp + 0.0030, -0.0112), rotation: simd_quatf(degrees: 90, axis: V3(0, 0, 1))))
        // Salt crystals spilled on the top disc and a small drift against the spout.
        for i in 0..<18 {
            let a = rng.float(0...(2 * .pi)), rr = rng.float(0.019...0.033)
            let s = rng.float(0.0009...0.0018)
            m.add(Prim.superellipsoid(V3(s, s, s), exponent: 5, subdivisions: 1, material: "food.sugar:F7F7F2"),
                  Xform(translation: V3(cos(a) * rr, top + 0.0042 + s * 0.4, sin(a) * rr), rotation: simd_quatf(degrees: Float(i) * 41, axis: V3(1, 1, 0))))
        }
        DD1KPantry.grounded(&m)
        groundAO(&m)
        return LODModel(m)
    }
}
