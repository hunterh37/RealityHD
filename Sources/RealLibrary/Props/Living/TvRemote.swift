import simd
import Foundation

/// Smart-TV remote, 4.5 x 2.0 x 19 cm, lying flat with the IR window toward +Z: a slim black body with softly
/// tapered ends, a red power key, a ringed direction pad with an OK button, back / home / menu keys, volume and
/// channel rockers, a mute key, three shortcut keys, a microphone pinhole row, a smoked IR lens with a status LED
/// and a battery-cover seam on the underside.
public struct TvRemote: RealAsset {
    public static let id = "tv-remote"
    public static let summary = "Slim TV remote: black body, rubber buttons, direction ring, IR window."
    public static let tags = ["prop", "floorplan", "living", "electronics", "plastic", "interior", "handheld"]
    public static let budget = 5600
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 42, distance: 0.9, studio: true)

    /// Overall size in meters (x width, y height, z length).
    public var size = V3(0.045, 0.02, 0.19)
    /// Housing plastic.
    public var body: MaterialKey = "plastic.black"
    /// Rubber keys.
    public var keys: MaterialKey = "rubber.silicone:2A2A2A"
    /// Power key.
    public var powerKey: MaterialKey = "rubber.silicone:A3241C"
    public init() {}

    private func disc(_ m: inout Model, r: Float, h: Float, at p: V3, _ key: MaterialKey, seg: Int = 18) {
        m.add(Prim.cylinder(radius: r, height: h, bevel: min(0.0004, h * 0.4), segments: seg, material: key), Xform(translation: p))
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let L = size.z, W = size.x
        let th: Float = 0.0175                       // housing thickness
        let top = th                                  // top face height
        let hl = L / 2
        // Housing: tapered outline in XY (y = length), extruded then laid flat (y -> +z).
        let hw = W / 2
        let outline = Shape2D.rounded([V2(-hw + 0.0035, -hl), V2(hw - 0.0035, -hl), V2(hw, -hl + 0.030), V2(hw, hl - 0.030),
                                       V2(hw - 0.0025, hl), V2(-hw + 0.0025, hl), V2(-hw, hl - 0.030), V2(-hw, -hl + 0.030)], radius: 0.0045)
        let shell = Prim.extrude(outline, depth: th, bevel: 0.0042, bevelSegments: 3, material: body)
        m.add(shell, Xform(translation: V3(0, th / 2, 0), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        // Soft keypad island: a slightly raised glossy plate over the key area, worn matte at the edges.
        m.add(Prim.roundedBox(V3(W - 0.0085, 0.0006, 0.150), radius: 0.0025, bevelSegments: 1, material: "plastic.gloss:141416"),
              Xform(translation: V3(0, top + 0.0001, -0.002)))
        let ky = top + 0.0003
        // Power key near the IR end.
        disc(&m, r: 0.0046, h: 0.0020, at: V3(-0.0125, ky, 0.072), powerKey)
        // Input / settings key opposite the power key.
        m.add(Prim.roundedBox(V3(0.0100, 0.0020, 0.0075), radius: 0.0016, bevelSegments: 1, material: keys), Xform(translation: V3(0.0125, ky + 0.0010, 0.072)))
        // Direction pad: ring plus centre OK key, four tick dots at the compass points.
        let pz: Float = 0.040
        let ring: [V2] = [V2(0.0072, 0), V2(0.0150, 0), V2(0.0150, 0.0016), V2(0.0143, 0.0023), V2(0.0080, 0.0023), V2(0.0072, 0.0016)]
        m.add(Prim.lathe(ring, segments: 32, seamTile: 0.05, material: keys), Xform(translation: V3(0, ky, pz)))
        disc(&m, r: 0.0066, h: 0.0024, at: V3(0, ky, pz), "rubber.silicone:34343A", seg: 24)
        for k in 0..<4 {
            let a = Float(k) * .pi / 2
            disc(&m, r: 0.0009, h: 0.0005, at: V3(sin(a) * 0.0112, ky + 0.0023, pz + cos(a) * 0.0112), "plastic.white", seg: 8)
        }
        // Back, home, menu row.
        for (i, dx) in ([-0.0138, 0, 0.0138] as [Float]).enumerated() {
            let key: MaterialKey = i == 1 ? "rubber.silicone:3A3A40" : keys
            m.add(Prim.roundedBox(V3(0.0108, 0.0019, 0.0078), radius: 0.0018, bevelSegments: 1, material: key), Xform(translation: V3(dx, ky + 0.0009, 0.0172)))
        }
        // Volume and channel rockers.
        for (i, dx) in ([-0.0108, 0.0108] as [Float]).enumerated() {
            m.add(Prim.roundedBox(V3(0.0162, 0.0022, 0.0300), radius: 0.0032, bevelSegments: 2, material: keys), Xform(translation: V3(dx, ky + 0.0010, -0.0150)))
            let plus: MaterialKey = "plastic.white"
            m.add(cuboid(V3(0.0060, 0.0003, 0.0009), material: plus), Xform(translation: V3(dx, ky + 0.0022, -0.0050)))
            if i == 0 { m.add(cuboid(V3(0.0009, 0.0003, 0.0060), material: plus), Xform(translation: V3(dx, ky + 0.0022, -0.0050))) }
            m.add(cuboid(V3(0.0060, 0.0003, 0.0009), material: plus), Xform(translation: V3(dx, ky + 0.0022, -0.0250)))
        }
        // Mute key between the rockers.
        disc(&m, r: 0.0036, h: 0.0019, at: V3(0, ky, -0.0150), "rubber.silicone:3A3A40", seg: 14)
        // Three shortcut keys near the tail, one tinted.
        let tints: [MaterialKey] = ["rubber.silicone:3A3A40", "rubber.silicone:2E4F86", keys]
        for (i, dx) in ([-0.0138, 0, 0.0138] as [Float]).enumerated() {
            m.add(Prim.roundedBox(V3(0.0112, 0.0019, 0.0078), radius: 0.0018, bevelSegments: 1, material: tints[i]), Xform(translation: V3(dx, ky + 0.0009, -0.0560)))
        }
        // Microphone pinholes between the pad and the rockers.
        for k in 0..<3 { disc(&m, r: 0.0007, h: 0.0003, at: V3(Float(k - 1) * 0.0045, top - 0.0001, 0.0125 + 0.0), "plastic.matte:050506", seg: 8) }
        // IR window on the tip: smoked lens set into a black bezel, status LED on top.
        m.add(Prim.roundedBox(V3(0.0210, 0.0070, 0.0036), radius: 0.0016, bevelSegments: 2, material: "glass.tinted"),
              Xform(translation: V3(0, th * 0.5, hl - 0.0010)))
        disc(&m, r: 0.0013, h: 0.0006, at: V3(0, top, hl - 0.0095), "emissive.led-red", seg: 10)
        // Underside: battery cover seam, thumb dent, screws.
        m.add(cuboid(V3(W - 0.012, 0.0004, 0.0007), material: "plastic.matte:0B0B0C"), Xform(translation: V3(0, 0.0003, -0.0560)))
        for sx: Float in [-1, 1] { m.add(cuboid(V3(0.0007, 0.0004, 0.0980), material: "plastic.matte:0B0B0C"), Xform(translation: V3(sx * (W / 2 - 0.0070), 0.0003, -0.0070))) }
        for sx: Float in [-1, 1] { disc(&m, r: 0.0018, h: 0.0004, at: V3(sx * 0.0125, 0.0001, 0.060 + rng.float(-0.0005...0.0005)), "metal.steel", seg: 8) }
        let b = m.bounds
        m = m.transformed(Xform(translation: V3(-(b.min.x + b.max.x) / 2, -b.min.y, -(b.min.z + b.max.z) / 2)))
        groundAO(&m, height: 0.004, floor: 0.8)
        return LODModel(m)
    }
}
