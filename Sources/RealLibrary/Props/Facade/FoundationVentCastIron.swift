import simd
import Foundation

/// Foundation vent, cast iron: architectural facade customizer, Victorian. Cast flange with a raised bead
/// moulding, turned balusters and a scrolled central rosette over insect mesh, countersunk fixing screws
/// and rust bloom at the sill.
public struct FoundationVentCastIron: RealAsset {
    public static let id = "foundation-vent-cast-iron"
    public static let summary = "Victorian cast iron foundation vent, 0.4 m: scrolled fretwork grille in a beaded frame."
    public static let tags = ["prop", "architecture", "facade", "metal", "decor"]
    public static let budget = 10000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 10, distance: 0.7)

    /// Overall width in meters.
    public var width: Float = 0.4
    /// Overall height in meters.
    public var height: Float = 0.2
    /// Cast metal.
    public var iron: MaterialKey = "metal.cast-iron"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = width, H = height, rust: MaterialKey = "metal.rust", grime: MaterialKey = "metal.rust-grime"
        let fl: Float = 0.018, rail: Float = 0.032
        // Cast flange: four rails with a dark void behind and insect mesh.
        FA.box(&m, V3(W, rail, fl), V3(0, rail / 2, fl / 2), iron, r: 0.003)
        FA.box(&m, V3(W, rail, fl), V3(0, H - rail / 2, fl / 2), iron, r: 0.003)
        for e: Float in [-1, 1] { FA.box(&m, V3(rail, H - 2 * rail + 0.002, fl), V3(e * (W / 2 - rail / 2), H / 2, fl / 2), iron, r: 0.003) }
        let ow = W - 2 * rail, oh = H - 2 * rail
        FA.box(&m, V3(ow, oh, 0.002), V3(0, H / 2, 0.001), grime, r: 0.0005)
        FA.box(&m, V3(ow, oh, 0.0016), V3(0, H / 2, 0.006), "glass.wire-mesh", r: 0.0004)
        // Raised bead moulding (half-round) around the opening and a flat outer fillet.
        let bz: Float = fl + 0.003
        FA.box(&m, V3(ow + 0.016, 0.006, 0.006), V3(0, rail + 0.003 - 0.002, fl + 0.001), iron, r: 0.0018)
        FA.box(&m, V3(ow + 0.016, 0.006, 0.006), V3(0, H - rail - 0.003 + 0.002, fl + 0.001), iron, r: 0.0018)
        for e: Float in [-1, 1] { FA.box(&m, V3(0.006, oh, 0.006), V3(e * (ow / 2 + 0.003), H / 2, fl + 0.001), iron, r: 0.0018) }
        FA.path(&m, [V3(-ow / 2 - 0.012, 0.007, bz), V3(ow / 2 + 0.012, 0.007, bz)], r: 0.0025, iron, sides: 8)
        FA.path(&m, [V3(-ow / 2 - 0.012, H - 0.007, bz), V3(ow / 2 + 0.012, H - 0.007, bz)], r: 0.0025, iron, sides: 8)
        for e: Float in [-1, 1] {
            FA.path(&m, [V3(e * (W / 2 - 0.007), 0.007, bz), V3(e * (W / 2 - 0.007), H - 0.007, bz)], r: 0.0025, iron, sides: 8)
        }
        // Turned balusters with a vase swell, in the outer panels.
        let y0 = rail - 0.002, y1 = H - rail + 0.002, hh = y1 - y0
        let prof: [V2] = [V2(0, 0), V2(0.0055, 0), V2(0.0055, hh * 0.08), V2(0.0035, hh * 0.14), V2(0.0045, hh * 0.3), V2(0.0075, hh * 0.5),
                          V2(0.0045, hh * 0.7), V2(0.0035, hh * 0.86), V2(0.0055, hh * 0.92), V2(0.0055, hh), V2(0, hh)]
        for s: Float in [-1, 1] { for k in 0..<5 {
            m.add(Prim.lathe(prof, segments: 10, seamTile: 0.1, material: iron), Xform(translation: V3(s * (0.104 + 0.0162 * Float(k)), y0, 0.02)))
        } }
        // Central rosette: outer ring, inner ring, eight petals, boss.
        let cz: Float = 0.03, cy = H / 2
        m.add(Prim.torus(major: 0.043, minor: 0.0042, segments: 28, sides: 8, material: iron), Xform(translation: V3(0, cy, cz), rotation: FA.q(90, FA.X)))
        m.add(Prim.torus(major: 0.021, minor: 0.0035, segments: 20, sides: 8, material: iron), Xform(translation: V3(0, cy, cz), rotation: FA.q(90, FA.X)))
        for i in 0..<8 {
            let a = Float(i) * .pi / 4 + .pi / 8
            m.add(Prim.superellipsoid(V3(0.018, 0.0055, 0.008), exponent: 2, subdivisions: 4, material: iron),
                  Xform(translation: V3(0.032 * cos(a), cy + 0.032 * sin(a), cz), rotation: FA.q(a * 180 / .pi, FA.Z)))
        }
        m.add(Prim.superellipsoid(V3(0.026, 0.026, 0.016), exponent: 2, subdivisions: 6, material: iron), Xform(translation: V3(0, cy, cz + 0.002)))
        // C-scrolls flanking the rosette, mirrored.
        for s: Float in [-1, 1] {
            FA.path(&m, FSV.spiral(c: V2(s * 0.074, cy + 0.022), z: cz - 0.002, r0: 0.026, r1: 0.007, turns: 1.1, a0: s > 0 ? 200 : -20, dir: s), r: 0.0032, iron, sides: 6)
            FA.path(&m, FSV.spiral(c: V2(s * 0.074, cy - 0.022), z: cz - 0.002, r0: 0.026, r1: 0.007, turns: 1.1, a0: s > 0 ? 160 : 20, dir: -s), r: 0.0032, iron, sides: 6)
            FC.bead(&m, r: 0.0045, at: V3(s * 0.074, cy + 0.022, cz - 0.002), iron)
            FC.bead(&m, r: 0.0045, at: V3(s * 0.074, cy - 0.022, cz - 0.002), iron)
        }
        // Corner bosses with countersunk fixing screws, and a cast lug either side.
        for sx: Float in [-1, 1] { for sy: Float in [0, 1] {
            let p = V3(sx * (W / 2 - rail / 2), sy == 0 ? rail / 2 : H - rail / 2, fl)
            FA.cylZ(&m, r: 0.012, h: 0.006, at: p - V3(0, 0, 0.001), iron, bevel: 0.002, segments: 18)
            FSV.screw(&m, at: p + V3(0, 0, 0.0052), normal: FA.Z, r: 0.0062, "metal.screw-zinc")
        } }
        // Weathering: rust bloom along the sill, flaking edge and runoff streaks.
        FA.box(&m, V3(W - 0.04, 0.007, 0.0014), V3(0, 0.007, fl + 0.0007), rust, r: 0.0004)
        for _ in 0..<5 {
            let x = rng.float(-W / 2 + 0.03...W / 2 - 0.03)
            FSV.streak(&m, at: V3(x, rail - 0.004, fl + 0.0007), w: rng.float(0.004...0.012), h: rng.float(0.01...0.026), rust)
        }
        FA.box(&m, V3(0.03, 0.012, 0.0014), V3(-W / 2 + 0.06, H - 0.014, fl + 0.0007), grime, r: 0.0004)
        return LODModel(FC.place(m))
    }
}
