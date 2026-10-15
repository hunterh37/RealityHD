import simd
import Foundation

/// Round quartz wall clock, 31 cm across and 5 cm deep: oiled walnut bezel with a black inner ring, white dial with
/// twelve hour bars and sixty minute ticks, tapered hour and minute hands, a red sweep hand with counterweight, a
/// brass hub, a domed glass lens, and a black back plate with a battery cap and a keyhole hanging slot. Set to 10:08:35.
/// Authored with the back face at z = -depth / 2, 12 o'clock toward +Y.
public struct WallClock: RealAsset {
    public static let id = "wall-clock"
    public static let summary = "Round wall clock, 31 cm: walnut bezel, glass dome, white face with hour bars, three hands, hanging slot on the back."
    public static let tags = ["prop", "floorplan", "decor", "wall", "wood", "glass", "interior"]
    public static let budget = 10000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 10, distance: 0.8, studio: true)

    /// Overall size in meters (x and y diameter, z depth).
    public var size = V3(0.31, 0.31, 0.05)
    /// Bezel wood.
    public var wood: MaterialKey = "wood.walnut"
    /// Dial face.
    public var dial: MaterialKey = "paper.sheet:EFE8D6"
    /// Hour and minute hands.
    public var hands: MaterialKey = "plastic.black"
    /// Sweep second hand.
    public var sweep: MaterialKey = "plastic.gloss:B5241B"
    public init() {}

    /// Disc or cylinder with its axis along +Z starting at `z`.
    private func disc(_ m: inout Model, r: Float, h: Float, z: Float, _ key: MaterialKey, bevel: Float = 0.0006, seg: Int = 32) {
        m.add(Prim.cylinder(radius: r, height: h, bevel: min(bevel, h * 0.45, r * 0.45), segments: seg, bevelSegments: 1, material: key),
              Xform(translation: V3(0, 0, z), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let R = size.x / 2
        let zf: Float = 0.046                                // front of the bezel lip above the back plane
        // Bezel: stepped walnut ring, rounded lip, rabbet for dial and lens. Lathe profile (r, depth) turned about the depth axis.
        let bezel: [V2] = Profile.smooth([V2(0.1300, 0.0), V2(R - 0.004, 0.0), V2(R, 0.004), V2(R, 0.034), V2(R - 0.003, 0.043), V2(R - 0.011, zf),
                                          V2(R - 0.020, zf), V2(0.1395, 0.040), V2(0.1385, 0.036), V2(0.1385, 0.012), V2(0.1300, 0.012)], per: 2)
        m.add(Prim.lathe(bezel, segments: 56, seamTile: 0.25, material: wood), Xform(rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        // Inner black ring, back plate.
        let ring: [V2] = [V2(0.1385, 0.012), V2(0.1385, 0.033), V2(0.1362, 0.0345), V2(0.1362, 0.012)]
        m.add(Prim.lathe(ring, segments: 48, seamTile: 0.25, material: "plastic.matte:0C0C0D"), Xform(rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        disc(&m, r: R - 0.002, h: 0.004, z: -0.0005, "plastic.black", bevel: 0.0012, seg: 48)
        // Dial: white face, slightly recessed, with a printed outer minute track ring.
        disc(&m, r: 0.1366, h: 0.0028, z: 0.0165, dial, bevel: 0.0004, seg: 48)
        // Hour bars: four long (12, 3, 6, 9) and eight short.
        let zm: Float = 0.0192
        for k in 0..<12 {
            let big = k % 3 == 0
            let a = Float(k) * .pi / 6
            let len: Float = big ? 0.026 : 0.014, wid: Float = big ? 0.0062 : 0.0036
            let rc: Float = 0.126 - len / 2 + 0.0015
            m.add(Prim.roundedBox(V3(wid, len, 0.0016), radius: 0.0005, bevelSegments: 1, material: "plastic.black"),
                  Xform(translation: V3(sin(a) * rc, cos(a) * rc, zm + 0.0008), rotation: simd_quatf(angle: -a, axis: V3(0, 0, 1))))
        }
        // Minute ticks around the rim (every fifth is covered by an hour bar).
        for k in 0..<60 where k % 5 != 0 {
            let a = Float(k) * .pi / 30
            let rc: Float = 0.1295
            m.add(cuboid(V3(0.0011, 0.0062, 0.0006), material: "plastic.matte:222224"),
                  Xform(translation: V3(sin(a) * rc, cos(a) * rc, zm + 0.0003), rotation: simd_quatf(angle: -a, axis: V3(0, 0, 1))))
        }
        // Brand mark: a small bar pair above the hub, where a printed logo would be.
        m.add(cuboid(V3(0.020, 0.0020, 0.0005), material: "plastic.matte:3A3A3D"), Xform(translation: V3(0, 0.042, zm + 0.00025)))
        m.add(cuboid(V3(0.012, 0.0012, 0.0005), material: "plastic.matte:6A6A6E"), Xform(translation: V3(0, 0.0375, zm + 0.00025)))
        // Hands: shaped slabs on a common hub, each on its own layer so they never share a plane. 10:08:35.
        let hourA: Float = (10 + 8.0 / 60) * 30, minA: Float = (8 + 35.0 / 60) * 6, secA: Float = 35 * 6
        let hourOutline: [V2] = [V2(-0.0030, -0.022), V2(0.0030, -0.022), V2(0.0048, 0.018), V2(0.0085, 0.040), V2(0, 0.082), V2(-0.0085, 0.040), V2(-0.0048, 0.018)]
        let minOutline: [V2] = [V2(-0.0026, -0.026), V2(0.0026, -0.026), V2(0.0040, 0.040), V2(0.0022, 0.112), V2(0, 0.124), V2(-0.0022, 0.112), V2(-0.0040, 0.040)]
        func hand(_ outline: [V2], z: Float, thick: Float, angle: Float, _ key: MaterialKey) {
            var s = Prim.extrude(Shape2D.rounded(outline, radius: 0.0008, segments: 2), depth: thick, bevel: 0.0003, bevelSegments: 1, material: key)
            s.recomputeNormals()
            m.add(s, Xform(translation: V3(0, 0, z + thick / 2), rotation: simd_quatf(degrees: -angle, axis: V3(0, 0, 1))))
        }
        hand(hourOutline, z: 0.0225, thick: 0.0020, angle: hourA, hands)
        hand(minOutline, z: 0.0252, thick: 0.0018, angle: minA, hands)
        // Hub: brass cap over the arbor, sweep hand on top with a counterweight disc.
        disc(&m, r: 0.0052, h: 0.0042, z: 0.0272, "metal.brass", bevel: 0.0012, seg: 20)
        let sa = secA * .pi / 180
        m.add(cuboid(V3(0.0013, 0.152, 0.0012), material: sweep),
              Xform(translation: V3(sin(sa) * 0.046, cos(sa) * 0.046, 0.0318), rotation: simd_quatf(angle: -sa, axis: V3(0, 0, 1))))
        let cwp = V3(-sin(sa) * 0.026, -cos(sa) * 0.026, 0.0318)
        m.add(Prim.cylinder(radius: 0.0048, height: 0.0014, bevel: 0.0004, segments: 14, material: sweep),
              Xform(translation: V3(cwp.x, cwp.y, cwp.z - 0.0006), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        disc(&m, r: 0.0022, h: 0.0024, z: 0.0324, "metal.brass", bevel: 0.0007, seg: 12)
        // Glass lens: shallow dome with a flat rim, tinted a touch blue-grey by thickness.
        let dome: [V2] = Profile.smooth([V2(0.1384, 0.0345), V2(0.1370, 0.0395), V2(0.1000, 0.0428), V2(0.0500, 0.0447), V2(0, 0.0452)], per: 3)
        m.add(Prim.lathe(dome, segments: 48, seamTile: 0.5, material: "glass.clear"), Xform(rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        // Back: movement housing, battery cap with a notch, keyhole hanging slot with a screw-head stop.
        disc(&m, r: 0.034, h: 0.005, z: -0.0045, "plastic.black", bevel: 0.0014, seg: 28)
        disc(&m, r: 0.0125, h: 0.0016, z: -0.0059, "plastic.matte:19191B", bevel: 0.0005, seg: 18)
        m.add(cuboid(V3(0.012, 0.0014, 0.0008), material: "plastic.matte:050506"), Xform(translation: V3(0, 0, -0.0066)))
        m.add(Prim.roundedBox(V3(0.020, 0.012, 0.0032), radius: 0.0012, bevelSegments: 1, material: "plastic.black"),
              Xform(translation: V3(0, 0.080, -0.0014 + rng.float(-0.0001...0.0001))))
        m.add(Prim.roundedBox(V3(0.007, 0.0095, 0.0036), radius: 0.0015, bevelSegments: 1, material: "plastic.matte:020203"),
              Xform(translation: V3(0, 0.0805, -0.0012)))
        // Four rubber bumpers on the back plate rim.
        for k in 0..<4 {
            let a = (Float(k) * 90 + 45) * .pi / 180
            m.add(Prim.cylinder(radius: 0.0055, height: 0.0020, bevel: 0.0008, segments: 10, bevelSegments: 1, material: "rubber.silicone:1E1E20"),
                  Xform(translation: V3(sin(a) * 0.118, cos(a) * 0.118, -0.0030), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        }
        // Authoring frame: lowest point y = 0, centred on X, back face (bumpers and movement behind) at z = -depth / 2.
        let b = m.bounds
        m = m.transformed(Xform(translation: V3(-(b.min.x + b.max.x) / 2, -b.min.y, -size.z / 2 - b.min.z)))
        return LODModel(m)
    }
}
