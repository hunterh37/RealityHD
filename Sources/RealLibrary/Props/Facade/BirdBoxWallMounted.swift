import simd
import Foundation

/// Bird box, wall mounted: RSPB-style cedar nest box. 16 mm boards, butt-jointed two-board front with a 32 mm
/// entrance hole and brass predator plate, floor recessed 3 mm, side panels raked to a hinged lid sloping 9 degrees
/// forward with a 25 mm drip overhang, hanging plate with zinc screws, galvanised pins through the sides.
public struct BirdBoxWallMounted: RealAsset {
    public static let id = "bird-box-wall-mounted"
    public static let summary = "Cedar nest box: raked sides, sloping hinged lid, 32 mm hole with brass plate, hanging plate and zinc screws."
    public static let tags = ["prop", "architecture", "facade", "wood", "decor"]
    public static let budget = 10000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 14, distance: 0.7)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.18, 0.30, 0.20)
    /// Board material (box, lid, plate).
    public var wood: MaterialKey = "wood.pencil-cedar"
    /// Lid material, more weathered than the body.
    public var lidWood: MaterialKey = "wood.saw-tote-worn"
    /// Entrance plate and hinges.
    public var brass: MaterialKey = "metal.brass-aged"
    /// Screws and pins.
    public var zinc: MaterialKey = "metal.screw-zinc"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let t: Float = 0.016, bodyW: Float = 0.15, yb: Float = 0.04
        let slope: Float = 9.4
        // Hanging plate, top end chamfered and bevelled 3 mm.
        FA.box(&m, V3(0.18, 0.30, t), V3(0, 0.15, t / 2), wood, r: 0.003)
        for y: Float in [0.275, 0.045] {
            rivet(&m, at: V3(0, y, t), normal: FA.Z, radius: 0.0055, height: 0.003, material: zinc)
        }
        // Side panels raked from 262 mm at the back to 235 mm at the front.
        let side: [V2] = [V2(t, yb), V2(0.18, yb), V2(0.18, 0.235), V2(t, 0.262)]
        for s: Float in [-1, 1] {
            FA.side(&m, side, thick: t, at: V3(s * (bodyW / 2 - t / 2), 0, 0), wood, bevel: 0.0015)
            for (z, y): (Float, Float) in [(0.172, 0.06), (0.172, 0.215), (0.10, 0.05)] {
                rivet(&m, at: V3(s * bodyW / 2, y, z + rng.float(-0.001...0.001)), normal: V3(s, 0, 0), radius: 0.0018, height: 0.0012, material: zinc)
            }
        }
        // Floor recessed 3 mm, front board with 32 mm hole at 2/3 height.
        FA.box(&m, V3(bodyW - 2 * t + 0.002, t, 0.164 - 0.002), V3(0, yb + 0.003 + t / 2, 0.016 + 0.082), wood, r: 0.002)
        FC.boardWithHole(&m, width: bodyW - 2 * t - 0.001, height: 0.235 - yb, thick: t, holeR: 0.016, holeY: 0.133, z: 0.18 - t / 2, y0: yb, wood)
        // Brass entrance plate (washer) over the hole, four pins.
        let ring: [V2] = [V2(0.0165, 0), V2(0.0245, 0), V2(0.0245, 0.0018), V2(0.0165, 0.0018), V2(0.0165, 0)]
        m.add(Prim.lathe(ring, segments: 20, seamTile: 0.05, material: brass), Xform(translation: V3(0, yb + 0.133, 0.18), rotation: FA.q(90, FA.X)))
        for a in stride(from: Float(45), to: 360, by: 90) {
            let r: Float = 0.0205
            rivet(&m, at: V3(r * cos(a * .pi / 180), yb + 0.133 + r * sin(a * .pi / 180), 0.1818), normal: FA.Z, radius: 0.0013, height: 0.001, material: zinc)
        }
        // Lid: board raked 9.4 degrees as an extruded profile (z out, y up), 25 mm front overhang.
        func lidY(_ z: Float) -> Float { 0.264 - 0.1646 * (z - 0.016) }
        let lidP: [V2] = [V2(0, lidY(0)), V2(0.2, lidY(0.2)), V2(0.2, lidY(0.2) + 0.0162), V2(0, lidY(0) + 0.0162)]
        FA.run(&m, lidP, length: 0.18, lidWood, bevel: 0.0025)
        // Drip batten under the front edge and a hook screw through the lid into the front board.
        FA.run(&m, [V2(0.178, lidY(0.178) - 0.008), V2(0.19, lidY(0.19) - 0.008), V2(0.19, lidY(0.19)), V2(0.178, lidY(0.178))],
               length: 0.15, lidWood, bevel: 0.001)
        rivet(&m, at: V3(0, lidY(0.19) + 0.0162, 0.19), normal: FA.Y, radius: 0.0035, height: 0.002, material: zinc)
        // Two brass butt hinges across the lid back edge on the plate.
        for x: Float in [-0.05, 0.05] {
            FA.box(&m, V3(0.024, 0.032, 0.0018), V3(x, 0.268, t + 0.0009), brass, r: 0.0008)
            FA.cylX(&m, r: 0.0022, h: 0.024, at: V3(x - 0.012, 0.276, t + 0.003), brass, bevel: 0.0005, segments: 10)
            rivet(&m, at: V3(x, 0.262, t + 0.0018), normal: FA.Z, radius: 0.0018, height: 0.001, material: zinc)
            rivet(&m, at: V3(x, 0.276, t + 0.0018), normal: FA.Z, radius: 0.0018, height: 0.001, material: zinc)
        }
        // Rain streaks on the front boards (dark grime under the lid, green copper-salt run under the brass plate).
        for i in 0..<4 {
            let x = -0.05 + Float(i) * 0.033 + rng.float(-0.004...0.004), len = rng.float(0.02...0.05)
            FA.box(&m, V3(rng.float(0.002...0.004), len, 0.0004), V3(x, 0.235 - len / 2 - 0.001, 0.1802), "wood.saw-tote-worn", r: 0.0002)
        }
        FA.box(&m, V3(0.004, 0.05, 0.0004), V3(0.004, yb + 0.133 - 0.0245 - 0.025, 0.1802), "metal.copper-patina", r: 0.0002)
        // Weathering story: moss cushions in the lid's back corners and along the rain-fed rear edge.
        for (x, z, w): (Float, Float, Float) in [(-0.07, 0.03, 0.035), (0.062, 0.045, 0.03), (-0.03, 0.02, 0.025), (0.085, 0.02, 0.02)] {
            let zz = z + rng.float(-0.004...0.004)
            m.add(Prim.superellipsoid(V3(w, 0.008, w * 0.9), exponent: 2.4, subdivisions: 4, material: "moss.cushion"),
                  Xform(translation: V3(x, lidY(zz) + 0.0162 + 0.002, zz)))
        }
        groundAO(&m, height: 0.12, floor: 0.7)
        return LODModel(FC.fit(m, size))
    }
}
