import simd
import Foundation

/// 12 gauge 2.75 in shotshell, 70 mm: red polyethylene hull with a six-point folded crimp, brass-plated
/// steel head with rim, extractor groove and a primer in its pocket. Lies on its side.
public struct ShotgunShell: RealAsset {
    public static let id = "shotgun-shell"
    public static let summary = "12 gauge shotshell, 70 mm: red hull, brass-plated head with rim, folded crimp."
    public static let tags = ["prop", "hunting", "handheld", "plastic", "metal"]
    public static let budget = 3500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 25, distance: 0.32, studio: true)

    /// Overall length in meters.
    public var overall: Float = 0.0700
    /// Hull radius in meters (12 gauge: 10.0 mm).
    public var hullRadius: Float = 0.0100
    public var hull: MaterialKey = "plastic.shotshell"
    public var head: MaterialKey = "metal.cartridge-brass"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        let rim: Float = 0.0106, y = rim
        let off = V3(-overall / 2, y, 0)
        func add(_ s: Surface) { m.add(s, Xform(translation: off)) }
        let R = hullRadius
        // Head: pocket, rim, groove, then the straight wall that the hull slides over.
        let headProf: [(Float, Float)] = [(0, 0), (0.0009, 0), (0.0009, 0.0051), (0, 0.0053), (0, 0.0098), (0.0004, 0.0106), (0.0017, 0.0106), (0.0019, 0.0098),
                                          (0.0032, 0.0098), (0.0036, R + 0.0002), (0.0192, R + 0.0002), (0.0200, R + 0.0001), (0.0200, 0)]
        add(HuntKit.axial(headProf, seg: 48, tile: 0.02, head))
        add(HuntKit.axial([(0, 0), (0, 0.0047), (0.0004, 0.0048), (0.0010, 0.0048), (0.0010, 0)], at: V3(0.0002, 0, 0), seg: 24, tile: 0.01, "metal.bolt-bright"))
        // Hull: tube with a shoulder at the head, rolled crimp closing the end.
        var hp: [(Float, Float)] = [(0.0196, 0), (0.0196, R - 0.0004), (0.0210, R), (0.0640, R)]
        let cl = overall - 0.0640
        for i in 1...8 { let t = Float(i) / 8; hp.append((0.0640 + cl * t, R * (1 - 0.72 * pow(t, 1.8)))) }
        hp.append((overall, 0))
        var s = HuntKit.axial(hp, seg: 72, tile: 0.02, hull)
        // Six crimp folds: dips every 60 degrees that deepen toward the tip.
        s.deform { p in
            let t = smoothstep(0.0625 - 0.0, overall, p.x)
            let a = atan2(p.z, p.y - 0)
            let dip = 1 - 0.20 * pow(abs(cos(3 * a)), 1.4) * smoothstep(0.0625, 0.0670, p.x) * (1 - 0.4 * t)
            return V3(p.x, p.y * dip, p.z * dip)
        }
        add(s)
        groundAO(&m, height: 0.004, floor: 0.75)
        return LODModel(m)
    }
}
