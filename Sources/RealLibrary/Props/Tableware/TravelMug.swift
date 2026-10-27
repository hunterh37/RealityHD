import simd
import Foundation

/// Travel mug: everyday tableware, insulated steel. Parts: double-wall stainless body with rolled bottom seam, screw-on lid with sip opening, slide switch, rubber base, silicone grip band, loop handle, fingerprint-worn patch and scuffed seam.
public struct TravelMug: RealAsset {
    public static let id = "travel-mug"
    public static let summary = "Insulated stainless travel mug: screw lid with slide switch, silicone grip band, rubber foot, side handle, scuffed from daily use."
    public static let tags = ["prop", "interior", "metal", "plastic", "handheld", "container"]
    public static let budget = 13000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 15, studio: true)

    /// Overall size in meters (x width, y height, z depth including the handle).
    public var size = V3(0.08, 0.19, 0.10)
    /// Steel body.
    public var steel: MaterialKey = "metal.stainless"
    /// Fingerprint-smudged steel patch.
    public var smudged: MaterialKey = "metal.stainless-smudged"
    /// Scuffed steel at the bottom seam.
    public var scuffed: MaterialKey = "metal.nickel-worn"
    /// Lid plastic.
    public var lid: MaterialKey = "plastic.matte:2A2D31"
    /// Silicone grip band.
    public var grip: MaterialKey = "rubber.silicone:3A3D42"
    /// Rubber foot.
    public var rubber: MaterialKey = "rubber.plate"
    public init() {}

    static let body: [V2] = [V2(0, 0.0058), V2(0.0330, 0.0058), V2(0.0354, 0.0075), V2(0.0363, 0.0092), V2(0.0358, 0.0112), V2(0.0361, 0.020),
                             V2(0.0372, 0.060), V2(0.0385, 0.100), V2(0.0392, 0.130), V2(0.0395, 0.1525)]

    func make(_ seg: Int, _ detail: Bool) -> Model {
        var m = Model(name: Self.id)
        let off = V3(0, 0, -0.0095)
        func R(_ y: Float) -> Float { DD1FTableware.radius(Self.body, at: y) }
        m.add(Prim.lathe([V2(0, 0), V2(0.0318, 0), V2(0.0336, 0.0012), V2(0.0344, 0.0050), V2(0.0338, 0.0062), V2(0, 0.0062)], segments: seg, seamTile: 0.1, material: rubber), Xform(translation: off))
        m.add(Prim.lathe(Self.body + [V2(0.0385, 0.1535), V2(0, 0.1540)], segments: seg, seamTile: 0.12, material: steel), Xform(translation: off))
        // Scuffed seam: worn bare metal around the rolled bottom edge, thicker on one side.
        m.add(Prim.lathe([V2(R(0.0075) + 0.0002, 0.0075), V2(R(0.0092) + 0.0002, 0.0092), V2(R(0.0125) + 0.0001, 0.0125), V2(R(0.0160) + 0.0001, 0.0160)], segments: seg, seamTile: 0.1, material: scuffed), Xform(translation: off))
        // Fingerprint patch: smudged steel zone where the other hand grips above the band.
        m.add(Prim.lathe([V2(R(0.121) + 0.0002, 0.121), V2(R(0.131) + 0.0002, 0.131), V2(R(0.141) + 0.0002, 0.141)], segments: seg, seamTile: 0.12, material: smudged), Xform(translation: off))
        // Silicone grip band with raised ribs.
        var bp: [V2] = [V2(R(0.0450) - 0.0003, 0.0450), V2(R(0.0460) + 0.0009, 0.0460)]
        for y in stride(from: Float(0.0500), through: 0.1100, by: 0.0100) { bp.append(V2(R(y) + 0.0011, y)) }
        bp.append(V2(R(0.1140) + 0.0009, 0.1140)); bp.append(V2(R(0.1150) - 0.0003, 0.1150))
        m.add(Prim.lathe(bp, segments: seg, seamTile: 0.12, material: grip), Xform(translation: off))
        if detail {
            for y in stride(from: Float(0.055), through: 0.105, by: 0.010) {
                m.add(Prim.torus(major: R(y) + 0.0011, minor: 0.0008, segments: seg, sides: 6, material: grip), Xform(translation: V3(0, y, 0) + off))
            }
        }
        // Lid: skirt over the rim, tapering shoulder, flat top with sip opening and slide switch.
        let lp: [V2] = [V2(0.0398, 0.1528), V2(0.0410, 0.1545), V2(0.0413, 0.1640), V2(0.0404, 0.1668), V2(0.0392, 0.1725), V2(0.0370, 0.1815), V2(0.0338, 0.1880), V2(0.0300, 0.1898), V2(0.0296, 0.1902), V2(0, 0.1902)]
        m.add(Prim.lathe(lp, segments: seg, seamTile: 0.12, material: lid), Xform(translation: off))
        m.add(Prim.torus(major: 0.0400, minor: 0.0006, segments: seg, sides: 6, material: "plastic.black"), Xform(translation: V3(0, 0.1537, 0) + off))
        // Sip opening on the -Z side: oval raised rim around a dark hole.
        let ovalPath = (0..<24).map { k -> V3 in
            let a = Float(k) / 24 * 2 * .pi
            return V3(cos(a) * 0.0100, 0.1904, sin(a) * 0.0058 - 0.0150)
        }
        m.add(Prim.sweep(Shape2D.circle(0.0012, segments: 8), along: ovalPath, up: V3(0, 1, 0), closedPath: true, caps: false, material: lid), Xform(translation: off))
        m.add(Prim.cylinder(radius: 0.0050, height: 0.0006, bevel: 0.0001, segments: 20, bevelSegments: 1, material: "plastic.black:08090A"),
              Xform(translation: V3(0, 0.1899, -0.0150) + off, scale: V3(1.8, 1, 1.0)))
        // Slide switch on the +Z side: groove track and a lighter slider.
        m.add(Prim.roundedBox(V3(0.0220, 0.0012, 0.0062), radius: 0.0005, bevelSegments: 1, material: "plastic.black:0E0F11"), Xform(translation: V3(0, 0.1904, 0.0160) + off))
        m.add(Prim.roundedBox(V3(0.0100, 0.0034, 0.0054), radius: 0.0012, bevelSegments: 2, material: "plastic.matte:8E949B"), Xform(translation: V3(0.0042, 0.1918, 0.0160) + off))
        // Loop handle (steel strap) at +Z, root pads on the body.
        let ctrl = [V2(0.0360, 0.1350), V2(0.0500, 0.1360), V2(0.0580, 0.1150), V2(0.0585, 0.0850), V2(0.0510, 0.0620), V2(0.0368, 0.0600)]
        m.add(DD1FTableware.loop(ctrl, dir: V3(0, 0, 1), section: V2(0.0125, 0.0060), detail: detail, flare: 0.4, material: steel), Xform(translation: off))
        // Scratches on the lower steel body and a thumb-worn patch on the lid shoulder.
        var rng = SeededRNG(seed: 21)
        for _ in 0..<(detail ? 10 : 4) {
            let a = rng.float(0...(2 * .pi)), y = rng.float(0.012...0.042), len = rng.float(0.010...0.022)
            let rr = R(y) + 0.0002
            let q = simd_quatf(angle: -a - .pi / 2, axis: V3(0, 1, 0)) * simd_quatf(angle: rng.float(-0.5...0.5), axis: V3(0, 0, 1))
            m.add(Prim.superellipsoid(V3(len, 0.0006, 0.0008), exponent: 2, subdivisions: 2, material: scuffed),
                  Xform(translation: V3(cos(a) * rr, y, sin(a) * rr) + off, rotation: q))
        }
        m.add(Prim.superellipsoid(V3(0.016, 0.0008, 0.010), exponent: 2.2, subdivisions: 3, material: "plastic.matte:5B5F66"), Xform(translation: V3(0.016, 0.1897, 0.0) + off))
        // Thumb-worn patch on the silicone grip: the black has rubbed to grey where the mug is held.
        let pa: Float = 0.45, py: Float = 0.082
        let pr = R(py) + 0.0012
        m.add(Prim.superellipsoid(V3(0.018, 0.026, 0.0010), exponent: 2.6, subdivisions: 4, material: "rubber.silicone:6E7278"),
              Xform(translation: V3(cos(pa) * pr, py, sin(pa) * pr) + off, rotation: simd_quatf(angle: .pi / 2 - pa, axis: V3(0, 1, 0))))
        // Trim to the brief size: authored profile radii run 3.5% wide and the lid 1.5% tall.
        for i in m.surfaces.indices {
            m.surfaces[i].positions = m.surfaces[i].positions.map { V3($0.x * 0.965, $0.y * 0.985, ($0.z + 0.0095) * 0.965 - 0.0095 * 0.965) }
        }
        groundAO(&m, height: 0.02, floor: 0.6)
        return m
    }

    public func build(seed: UInt64) -> LODModel {
        _ = seed
        return LODModel(levels: [make(56, true), make(28, false)], switchDistances: [3])
    }
}
