import simd
import Foundation

/// Anti-ram steel bollard: architectural facade customizer, Contemporary. Stainless steel pipe with a welded
/// domed cap, reflective yellow bands, a ground flange with bolts, scuffs and tyre marks near the foot.
public struct AntiRamBollardSteel: RealAsset {
    public static let id = "anti-ram-bollard-steel"
    public static let summary = "Anti-ram bollard 1.0 m: stainless steel pipe with a welded domed cap, reflective bands, a ground flange with bolts and scuffs."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 12, distance: 2.4)

    /// Pipe outer radius in meters.
    public var pipeRadius: Float = 0.1015
    /// Brushed stainless.
    public var steel: MaterialKey = "metal.stainless"
    /// Scuffed lower pipe.
    public var scuffed: MaterialKey = "metal.stainless-smudged"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let R = pipeRadius
        // Cover flange: a shallow dished disc with a rolled edge.
        let flange: [V2] = [V2(0, 0), V2(0.148, 0), V2(0.15, 0.003), V2(0.15, 0.014), V2(0.146, 0.018), V2(0.13, 0.02), V2(0.112, 0.024), V2(R + 0.004, 0.03), V2(0, 0.03)]
        FE.turnDisp(&m, flange, steel, segments: 72) { _ in 0 }
        // Pipe in two zones: scuffed lower, clean upper, with the weld seam ring between.
        let lower: [V2] = [V2(0, 0.03), V2(R, 0.03), V2(R, 0.45), V2(0, 0.45)]
        FE.turnDisp(&m, lower, scuffed, segments: 72) { p in
            // Fine axial brushing and a few shallow dings near the base.
            let a = atan2(p.z, p.x)
            return 0.0004 * sin(90 * a) - (p.y < 0.25 ? 0.0012 * max(0, FE.noise(V3(a * 3, p.y * 20, 1), seed: 4)) : 0)
        }
        let upper: [V2] = [V2(0, 0.45), V2(R, 0.45), V2(R, 0.955), V2(R - 0.004, 0.968), V2(R - 0.02, 0.984), V2(R - 0.06, 0.996), V2(R - 0.085, 1.0), V2(0, 1.0)]
        FE.turnDisp(&m, upper, steel, segments: 72) { p in 0.0004 * sin(90 * atan2(p.z, p.x)) }
        // Weld beads: circumferential beads at the mid-pipe joint and at the cap seam.
        for y: Float in [0.45, 0.958] {
            m.add(Prim.torus(major: R + 0.0008, minor: 0.0042, segments: 72, sides: 8, material: "metal.steel"), Xform(translation: V3(0, y, 0)))
        }
        // Retroreflective yellow bands near the top.
        for (y0, h) in [(0.8, 0.07), (0.88, 0.035)] as [(Float, Float)] {
            let band: [V2] = [V2(R, y0), V2(R + 0.0022, y0 + 0.001), V2(R + 0.0022, y0 + h - 0.001), V2(R, y0 + h)]
            let s = Prim.lathe(band, segments: 72, seamTile: 0.3, material: "metal.signal-yellow")
            m.add(s, Xform())
        }
        // Six stainless socket-head bolts through the flange.
        for k in 0..<6 {
            let a = Float(k) / 6 * 2 * .pi + 0.26
            m.add(Prim.cylinder(radius: 0.0085, height: 0.007, bevel: 0.0015, segments: 10, bevelSegments: 1, material: "metal.steel"),
                  Xform(translation: V3(0.127 * cos(a), 0.014, 0.127 * sin(a))))
        }
        // Tyre rub marks and a paint scrape on the pipe.
        for k in 0..<3 {
            let a = Float(k) * 2.1 + rng.float(0...0.5)
            FA.box(&m, V3(rng.float(0.03...0.06), rng.float(0.1...0.18), 0.0012), V3((R + 0.0005) * cos(a), rng.float(0.1...0.3), (R + 0.0005) * sin(a)), "metal.steel", r: 0.0004, rot: FA.q(-a * 180 / .pi + 90, FA.Y))
        }
        m = FE.seat(m)
        groundAO(&m, height: 0.08, floor: 0.6)
        return LODModel(m)
    }
}
