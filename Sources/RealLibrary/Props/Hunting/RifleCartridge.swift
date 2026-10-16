import simd
import Foundation

/// .308 Winchester cartridge, 71.1 mm overall: rimless bottleneck brass case (12.0 mm head, extractor
/// groove, 11.5 mm shoulder, 8.8 mm neck), nickel primer in its pocket, copper-jacketed 7.82 mm
/// soft-point bullet with a lead tip and cannelure. Lies on its side.
public struct RifleCartridge: RealAsset {
    public static let id = "rifle-cartridge"
    public static let summary = ".308 Winchester cartridge, 71 mm: brass case with rim and primer, copper soft-point bullet."
    public static let tags = ["prop", "hunting", "handheld", "metal"]
    public static let budget = 3500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 25, distance: 1.0, studio: true)

    /// Overall length in meters.
    public var overall: Float = 0.0711
    public var brass: MaterialKey = "metal.cartridge-brass"
    public var jacket: MaterialKey = "metal.bullet-copper"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        let rr: Float = 0.0060, y = rr
        let off = V3(-overall / 2, y, 0)
        func add(_ s: Surface) { m.add(s, Xform(translation: off)) }
        // Case: head face with primer pocket, rim, groove, body taper, shoulder, neck, mouth.
        let caseProf: [(Float, Float)] = [(0, 0), (0.0006, 0), (0.0006, 0.0034), (0, 0.0036), (0, 0.0056), (0.0004, 0.0060), (0.0013, 0.0060), (0.0015, 0.0052),
                                          (0.0033, 0.0052), (0.0035, 0.00596), (0.0200, 0.00590), (0.0356, 0.00560), (0.0388, 0.00540), (0.0414, 0.00500),
                                          (0.0440, 0.00444), (0.0505, 0.00440), (0.0511, 0.00415), (0.0511, 0.0), ]
        add(HuntKit.axial(caseProf, seg: 40, tile: 0.02, brass))
        add(HuntKit.axial([(0, 0), (0, 0.0031), (0.0003, 0.0032), (0.0007, 0.0032), (0.0007, 0)], at: V3(0.0002, 0, 0), seg: 20, tile: 0.01, "metal.bolt-bright"))
        // Bullet: seated 11 mm, ogive ending in a lead meplat.
        let x0: Float = 0.0400, ogive: Float = overall - 0.0511 - 0.0010
        var bp: [(Float, Float)] = [(0, 0), (0, 0.0037), (0.0004, 0.00391), (0.0111, 0.00391)]
        for i in 1...14 {
            let t = Float(i) / 14
            bp.append((0.0111 + ogive * t, 0.00096 + (0.00391 - 0.00096) * sqrt(max(0, 1 - pow(t, 1.7)))))
        }
        bp.append((0.0111 + ogive, 0.0))
        add(HuntKit.axial(bp, at: V3(x0, 0, 0), seg: 36, tile: 0.02, jacket))
        add(HuntKit.axial([(0, 0), (0, 0.00096), (0.0010, 0.00090), (0.0010, 0)], at: V3(overall - 0.0010, 0, 0), seg: 12, tile: 0.01, "metal.bolt-bright:7A7E80"))
        // Cannelure ring just ahead of the case mouth.
        add(HuntKit.axial([(0, 0.00391), (0.0004, 0.00372), (0.0016, 0.00372), (0.0020, 0.00391)], at: V3(0.0525, 0, 0), seg: 24, tile: 0.01, jacket))
        groundAO(&m, height: 0.004, floor: 0.75)
        return LODModel(m)
    }
}
