import simd
import Foundation

/// Glass salt shaker: a gently panelled 40 mm glass body with a thick base and a threaded neck, filled with salt
/// to the shoulder, under a stainless screw cap with a rolled worn-nickel skirt and five shaker holes.
/// A salt crust sits in the thread gap and loose grains lie around the base.
public struct SaltShaker: RealAsset {
    public static let id = "salt-shaker"
    public static let summary = "Glass salt shaker with a stainless domed screw cap with five holes, salt fill, salt crust at the thread and spilled grains."
    public static let tags = ["prop", "interior", "tableware", "glass", "metal", "handheld"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 20, studio: true)

    /// Glass body.
    public var glass: MaterialKey = "glass.clear"
    /// Cap metal.
    public var cap: MaterialKey = "metal.stainless-smudged"
    /// Salt.
    public var salt: MaterialKey = "food.sugar:F2F0EA"
    public init() {}

    func level(segs: Int, detail: Bool) -> Model {
        var rng = SeededRNG(seed: 61)
        var m = Model(name: Self.id)
        let outer: [V2] = Profile.smooth([
            V2(0, 0.0045), V2(0.0150, 0.0045), V2(0.0170, 0.0010), V2(0.0186, 0), V2(0.0196, 0.0030), V2(0.0198, 0.0120),
            V2(0.0197, 0.0400), V2(0.0190, 0.0540), V2(0.0172, 0.0615), V2(0.0160, 0.0650), V2(0.0158, 0.0690),
        ], per: detail ? 3 : 1)
        var body = DD1GWare.lathe(Profile.shell(outer, wall: 0.0030, floor: 0.0085), segs: segs, glass)
        // Eight shallow panels, fading out at the base and shoulder.
        body.deform { p in
            let th = atan2(p.z, p.x)
            let f = 1 + 0.022 * cos(th * 8) * DD1GWare.smooth(0.012, 0.03, p.y) * (1 - DD1GWare.smooth(0.045, 0.058, p.y))
            return V3(p.x * f, p.y, p.z * f)
        }
        m.add(body)
        // Thread ridges on the neck, mostly hidden under the cap.
        let th: [V2] = [V2(0.0156, 0.0664), V2(0.0167, 0.0672), V2(0.0156, 0.0680), V2(0.0167, 0.0688), V2(0.0156, 0.0696), V2(0.0167, 0.0704), V2(0.0156, 0.0712)]
        m.add(DD1GWare.lathe(th, segs: segs, glass))
        // Salt fill, a little mounded.
        m.add(DD1GWare.lathe([V2(0, 0.0602), V2(0.0080, 0.0592), V2(0.0150, 0.0575), V2(0.0166, 0.0562), V2(0.0166, 0.0090), V2(0, 0.0090)].reversed(), segs: segs, salt))
        // Cap: skirt band in worn nickel, then the stainless body with a domed top.
        let band: [V2] = [V2(0.0182, 0.0600), V2(0.0199, 0.0600), V2(0.0201, 0.0610), V2(0.0200, 0.0640), V2(0.0199, 0.0648), V2(0.0182, 0.0648), V2(0.0182, 0.0600)]
        m.add(DD1GWare.lathe(band, segs: segs, "metal.nickel-worn"))
        let capP: [V2] = [
            V2(0, 0.0870), V2(0.0150, 0.0856), V2(0.0182, 0.0830), V2(0.0182, 0.0646), V2(0.0196, 0.0647), V2(0.0198, 0.0652),
            V2(0.0198, 0.0720), V2(0.0196, 0.0790), V2(0.0190, 0.0840), V2(0.0170, 0.0877), V2(0.0130, 0.0896), V2(0.0070, 0.0902), V2(0, 0.0904),
        ]
        var capS = DD1GWare.lathe(Profile.smooth(capP, per: detail ? 2 : 1), segs: segs, cap)
        capS.recomputeNormals()
        m.add(capS)
        // Five shaker holes: dark discs ringed by a raised lip.
        let holes: [V2] = [V2(0, 0), V2(0.0058, 0), V2(-0.0058, 0), V2(0, 0.0058), V2(0, -0.0058)]
        for h in holes {
            m.add(Prim.cylinder(radius: 0.0013, height: 0.00045, bevel: 0.0001, segments: 10, material: "metal.parkerized"), Xform(translation: V3(h.x, 0.09005, h.y)))
        }
        // Salt crust in the thread gap and on the shoulder.
        m.add(DD1GWare.lathe([V2(0.0170, 0.0582), V2(0.0192, 0.0590), V2(0.0200, 0.0601), V2(0.0183, 0.0601), V2(0.0170, 0.0582)], segs: segs, salt))
        DD1GWare.grains(&m, &rng, center: V3(0, 0.0592, 0), radiusMin: 0.0172, radiusMax: 0.0190, count: detail ? 10 : 0, size: 0.0014, material: salt)
        // Loose grains on the table beside the base.
        DD1GWare.grains(&m, &rng, center: V3(0.0168, 0, 0.0168), radiusMin: 0.0, radiusMax: 0.0028, count: detail ? 16 : 5, size: 0.0013, material: salt)
        DD1GWare.plant(&m)
        groundAO(&m, height: 0.008, floor: 0.75)
        return m
    }

    public func build(seed: UInt64) -> LODModel {
        _ = seed
        return LODModel(levels: [level(segs: 48, detail: true), level(segs: 20, detail: false)], switchDistances: [2])
    }
}
