import simd
import Foundation

/// Rapid entry key box: architectural facade customizer, Commercial. Surface-mount 0.2 x 0.25 m cabinet: back plate
/// on four screws, welded body, chamfered thick door on a full-height piano hinge, stainless lock cylinder in a
/// hex bezel under a spring dust cover, reveal gap and a red label plate. Powder coat is scuffed at the corners
/// and rust bleeds from the screw heads.
public struct KnoxBox: RealAsset {
    public static let id = "knox-box"
    public static let summary = "Knox rapid entry key box, 0.2 m: surface mount housing with hinged door and lock."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 12, distance: 1.2)

    /// Powder coat on body and door.
    public var coat: MaterialKey = "metal.painted:2A2C2F"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W: Float = 0.2, H: Float = 0.25
        let steel: MaterialKey = "metal.stainless", scuff: MaterialKey = "metal.steel", rust: MaterialKey = "metal.rust", dark: MaterialKey = "metal.rust-grime"
        // Back plate with four countersunk screws, welded body, step lip.
        FA.box(&m, V3(W, H, 0.008), V3(0, H / 2, 0.004), coat, r: 0.0025)
        FA.box(&m, V3(W - 0.012, H - 0.012, 0.05), V3(0, H / 2, 0.033), coat, r: 0.003)
        for sx: Float in [-1, 1] { for sy: Float in [-1, 1] {
            FSV.screw(&m, at: V3(sx * (W / 2 - 0.0085), H / 2 + sy * (H / 2 - 0.0085), 0.008), normal: FA.Z, r: 0.0042, "metal.screw-zinc")
        } }
        // Door: thick slab with chamfered face (loft of rectangles), reveal gap behind it.
        let dz: Float = 0.057
        FA.box(&m, V3(W - 0.01, H - 0.01, 0.004), V3(0, H / 2, dz - 0.001), dark, r: 0.0008)
        let door = Prim.loft([Prim.ring(Shape2D.rounded(Shape2D.rect(W - 0.014, H - 0.014), radius: 0.004), y: 0),
                              Prim.ring(Shape2D.rounded(Shape2D.rect(W - 0.014, H - 0.014), radius: 0.004), y: 0.021),
                              Prim.ring(Shape2D.rounded(Shape2D.rect(W - 0.03, H - 0.03), radius: 0.006), y: 0.024)], capStart: false, capEnd: true, material: coat)
        m.add(door, Xform(translation: V3(0, H / 2, dz + 0.0), rotation: FA.q(90, FA.X)))
        // Piano hinge on the left: ribbed barrel and leaf, pin heads at both ends.
        var barrel: [V2] = [V2(0, 0)]
        for k in 0..<12 {
            let y0 = 0.012 + Float(k) * 0.0185
            barrel += [V2(0.0045, y0), V2(0.0045, y0 + 0.0165), V2(0.0038, y0 + 0.0172)]
        }
        barrel += [V2(0.0045, H - 0.012), V2(0, H - 0.012)]
        m.add(Prim.lathe(barrel, segments: 10, seamTile: 0.1, material: steel), Xform(translation: V3(-W / 2 + 0.0046, 0, dz + 0.004)))
        FA.box(&m, V3(0.014, H - 0.03, 0.002), V3(-W / 2 + 0.01, H / 2, dz + 0.0), steel, r: 0.0005)
        // Lock: hex bezel, cylinder face, keyway and spring dust cover on a pivot.
        let lc = V3(0.03, H * 0.46, dz + 0.021)
        m.add(Prim.extrude(Shape2D.polygon(sides: 6, radius: 0.029), depth: 0.006, bevel: 0.0012, bevelSegments: 1, material: steel),
              Xform(translation: lc + V3(0, 0, 0.003), rotation: FA.q(0, FA.X)))
        FSV.cyl(&m, lc + V3(0, 0, 0.006), lc + V3(0, 0, 0.014), r: 0.021, "metal.brass", bevel: 0.0015, segments: 20)
        FA.box(&m, V3(0.002, 0.014, 0.001), lc + V3(0, 0, 0.0143), dark, r: 0.0003)
        FSV.cyl(&m, lc + V3(0, 0, 0.0145), lc + V3(0, 0, 0.0185), r: 0.0155, steel, bevel: 0.0012, segments: 16)
        FA.box(&m, V3(0.008, 0.004, 0.004), lc + V3(0.0, 0.0165, 0.0155), steel, r: 0.0008)
        // Label plate: red field with block legend and two rivets, serial plate bottom left.
        let ly = H * 0.82
        FA.box(&m, V3(0.15, 0.036, 0.002), V3(0, ly, dz + 0.0255), "sign.red", r: 0.0006)
        FSV.letters(&m, "FIRE", c: V3(0, ly, dz + 0.0272), h: 0.022, stroke: 0.0045, gap: 0.005, "sign.white")
        for s: Float in [-1, 1] { FC.bead(&m, r: 0.0022, at: V3(s * 0.069, ly + 0.0, dz + 0.0272), steel, sub: 2) }
        FA.box(&m, V3(0.045, 0.015, 0.0012), V3(-0.055, H * 0.12, dz + 0.0255), "sign.white", r: 0.0004)
        // Scuffed corners, screw rust bleed, dust line along the top of the door.
        for sx: Float in [-1, 1] { for sy: Float in [-1, 1] {
            FA.box(&m, V3(rng.float(0.01...0.02), 0.0045, 0.0008), V3(sx * (W / 2 - 0.014), H / 2 + sy * (H / 2 - 0.0165), dz + 0.0146), scuff, r: 0.0002)
        } }
        FSV.streak(&m, at: V3(-(W / 2 - 0.0085), H - 0.0085 - 0.004, 0.0095), w: 0.004, h: 0.03, rust)
        FA.box(&m, V3(W - 0.04, 0.003, 0.0008), V3(0, H - 0.0225, dz + 0.0242), "metal.rust-grime", r: 0.0002)
        return LODModel(FC.seatY(m))
    }
}
