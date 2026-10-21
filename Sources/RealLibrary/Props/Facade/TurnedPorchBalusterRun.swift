import simd
import Foundation

/// Victorian turned porch baluster run: 21 lathe-turned balusters with square pommels, tenoned between a moulded
/// handrail (ogee underside, rounded top) and a chamfered bottom rail, closed by a newel post at each end. Each newel
/// stands on a moulded plinth, carries applied raised panels, a chamfered cap, a hipped pyramid and a turned ball
/// finial. Rails are dowel-pegged into the newels. White lead paint, flaked and greyed on the rail top, one bare
/// replacement baluster and a damp stain at the newel feet.
public struct TurnedPorchBalusterRun: RealAsset {
    public static let id = "turned-porch-baluster-run"
    public static let summary = "Victorian porch railing run, 2.4 m: turned balusters between a moulded handrail and bottom rail, with a newel post at each end."
    public static let tags = ["prop", "architecture", "facade", "trim", "wood", "decor"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 22, elevation: 8, distance: 3.4)

    /// Run length in meters, newel centers at +-(length / 2 - 0.05).
    public var length: Float = 2.4
    /// Number of balusters.
    public var balusters = 21
    /// Painted wood.
    public var paint: MaterialKey = "wood.painted-exterior:E3DDCB"
    /// Bare and weathered wood.
    public var bare: MaterialKey = "wood.weathered"
    /// Dowel pegs.
    public var peg: MaterialKey = "wood.oak:8A6642"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [make(seed: seed, lite: false), make(seed: seed, lite: true)], switchDistances: [5])
    }

    func make(seed: UInt64, lite: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let L = length, nx = L / 2 - 0.05          // newel center x
        let span = 2 * nx - 0.09                    // clear run between newel faces
        let yr0: Float = 0.05, yr1: Float = 0.12     // bottom rail
        let yh0: Float = 0.77, yh1: Float = 0.841    // handrail
        let seg = lite ? 5 : 8
        // Moulded handrail: mirrored half profile, bottom flat, ogee neck, rounded top.
        let hh: [V2] = [V2(0.022, yh0), V2(0.022, yh0 + 0.006), V2(0.030, yh0 + 0.012), V2(0.040, yh0 + 0.022), V2(0.047, yh0 + 0.032),
                        V2(0.0505, yh0 + 0.042), V2(0.049, yh0 + 0.053), V2(0.043, yh0 + 0.063), V2(0.032, yh0 + 0.069), V2(0.012, yh0 + 0.0715)]
        let hr: [V2] = hh + hh.reversed().map { V2(-$0.x, $0.y) }
        FA.run(&m, hr, length: span + 0.03, at: .zero, paint, bevel: 0.001)
        // Bottom rail: chamfered top, flat underside, shallow plough groove on the face.
        FA.run(&m, [V2(-0.0375, yr0), V2(0.0375, yr0), V2(0.0375, yr1 - 0.016), V2(0.0315, yr1), V2(-0.0315, yr1), V2(-0.0375, yr1 - 0.016)], length: span + 0.03, at: .zero, paint, bevel: 0.0012)
        // Balusters: square pommels top and bottom, turned vase between, tenons into the rails.
        let mid: [(Float, Float)] = [(0, 0), (0.0145, 0), (0.0145, 0.006), (0.0225, 0.014), (0.0235, 0.030), (0.0165, 0.044), (0.0125, 0.056),
                                     (0.0150, 0.066), (0.0110, 0.080), (0.0190, 0.112), (0.0210, 0.150),
                                     (0.0100, 0.200), (0.0095, 0.250), (0.0145, 0.290), (0.0215, 0.335),
                                     (0.0125, 0.356), (0.0150, 0.368), (0.0095, 0.380), (0.0, 0.386)]
        let yPom0 = yr1, yBody0 = yPom0 + 0.075, yBody1 = yh0 - 0.075 // pommel height 75 mm each end
        let bodyScale = (yBody1 - yBody0) / 0.386
        let step = span / Float(balusters + 1)
        let replaced = 12
        for i in 0..<balusters {
            let x = -span / 2 + Float(i + 1) * step
            // Repainted at different times: three whites; the bottom pommel is splash-dirtied.
            let tints: [MaterialKey] = [paint, "wood.painted-exterior:D6CFB8", "wood.painted-exterior:EAE5D6"]
            let mat: MaterialKey = i == replaced ? "wood.lumber-pine" : tints[rng.int(0...2)]
            let dirty: MaterialKey = i == replaced ? "wood.lumber-pine" : "wood.painted-exterior:B3AB93"
            let prof = mid.map { ($0.0, $0.1 * bodyScale) }
            m.add(turned(prof, segments: lite ? 4 : 7, material: mat, seamTile: 0.2, grainVertical: true),
                  Xform(translation: V3(x, yBody0, 0), rotation: FA.q(rng.float(-0.35...0.35), FA.Z)))
            // Square pommels: a four-sided lathe turned 45 degrees, chamfered at the shoulder.
            m.add(turned([(0, 0), (0.0283, 0), (0.0283, 0.066), (0.0235, 0.076), (0, 0.076)], segments: 4, material: dirty, seamTile: 0.2),
                  Xform(translation: V3(x, yPom0 - 0.001, 0), rotation: FA.q(45, FA.Y)))
            _ = dirty
            m.add(turned([(0, 0), (0.0235, 0), (0.0283, 0.01), (0.0283, 0.076), (0, 0.076)], segments: 4, material: mat, seamTile: 0.2),
                  Xform(translation: V3(x, yBody1 + 0.001, 0), rotation: FA.q(45, FA.Y)))
            if !lite { FA.cylZ(&m, r: 0.0042, h: 0.0022, at: V3(x, yPom0 + 0.030, 0.0385), peg, bevel: 0.0008, segments: 8) }
        }
        // Newel posts.
        for e: Float in [-1, 1] {
            let x = e * nx
            FA.box(&m, V3(0.1, 0.07, 0.1), V3(x, 0.035, 0), paint, r: 0.004)                       // plinth
            FA.box(&m, V3(0.098, 0.014, 0.098), V3(x, 0.077, 0), paint, r: 0.006)                  // base moulding
            FA.box(&m, V3(0.086, 0.74, 0.086), V3(x, 0.45, 0), paint, r: 0.005)                    // shaft
            for sx: Float in [-1, 1] { for sz: Float in [-1, 1] { FA.box(&m, V3(0.012, 0.66, 0.012), V3(x + sx * 0.043, 0.45, sz * 0.043), paint, r: 0.0045) } } // chamfer stops
            // Raised panels on front and back, sunken field on the sides.
            for sz: Float in [-1, 1] {
                FA.box(&m, V3(0.052, 0.34, 0.006), V3(x, 0.30, sz * 0.0455), paint, r: 0.002)
                FA.box(&m, V3(0.038, 0.24, 0.004), V3(x, 0.30, sz * 0.0485), "wood.painted-exterior:D9D2BE", r: 0.0015)
            }
            for sx: Float in [-1, 1] { FA.box(&m, V3(0.006, 0.34, 0.052), V3(x + sx * 0.0455, 0.30, 0), paint, r: 0.002) }
            // Neck moulding under the cap, chamfered cap block, hipped pyramid, turned ball finial.
            FA.box(&m, V3(0.092, 0.012, 0.092), V3(x, 0.806, 0), paint, r: 0.003)
            FA.box(&m, V3(0.1, 0.03, 0.1), V3(x, 0.827, 0), paint, r: 0.007)
            FA.box(&m, V3(0.1, 0.03, 0.1), V3(x, 0.827, 0), paint, r: 0.007)
            m.add(turned([(0, 0.842), (0.0707, 0.842), (0.0707 * 0.86, 0.8465), (0.0707 * 0.55, 0.862), (0.0707 * 0.25, 0.877), (0.006, 0.887), (0, 0.887)],
                         segments: 4, material: paint, seamTile: 0.2), Xform(translation: V3(x, 0, 0), rotation: FA.q(45, FA.Y)))
            m.add(turned([(0, 0.884), (0.012, 0.884), (0.0105, 0.893), (0.0075, 0.898), (0.016, 0.907), (0.0215, 0.920), (0.0185, 0.935), (0.009, 0.944), (0.004, 0.948), (0, 0.95)],
                         segments: lite ? 8 : 14, material: paint, seamTile: 0.2, grainVertical: true), Xform(translation: V3(x, 0, 0)))
            // Pegs where handrail and bottom rail meet the newel.
            if !lite {
                for py in [Float(0.795), 0.82, 0.092, 0.108] {
                    FA.cylZ(&m, r: 0.0045, h: 0.0022, at: V3(x, py, 0.0425), peg, bevel: 0.0008, segments: 8)
                }
            }
        }
        // Weathering: grey flaked patches on the handrail top, rot spots on the bottom rail, damp stain at the newel feet.
        if !lite {
            func flat(_ cx: Float, _ cz: Float, _ rx: Float, _ rz: Float, y: Float, _ mat: MaterialKey) {
                var poly: [V2] = []
                for j in 0..<8 { let a = Float(j) / 8 * 2 * .pi; poly.append(V2(cx + cos(a) * rx * rng.float(0.6...1.1), cz + sin(a) * rz * rng.float(0.6...1.1))) }
                m.add(HTKit.plate(outer: poly, depth: 0.0012, bevel: 0.0003, segments: 1, material: mat),
                      Xform(translation: V3(0, y, 0), rotation: FA.q(90, FA.X)))
            }
            for _ in 0..<8 { flat(rng.float(-span / 2 + 0.05...span / 2 - 0.05), rng.float(-0.012...0.012), rng.float(0.03...0.12), rng.float(0.008...0.018), y: yh1 + 0.0004, rng.float(0...1) < 0.7 ? bare : "wood.deadwood") }
            for _ in 0..<4 { flat(rng.float(-span / 2 + 0.05...span / 2 - 0.05), rng.float(-0.01...0.01), rng.float(0.02...0.05), rng.float(0.01...0.02), y: yr1 - 0.0 + 0.0004 - 0.004, "wood.deadwood") }
            for e: Float in [-1, 1] {
                FA.box(&m, V3(0.1005, 0.05, 0.1005), V3(e * nx, 0.025, 0), "wood.deadwood", r: 0.004)
                FA.box(&m, V3(0.1005, 0.012, 0.1005), V3(e * nx, 0.006, 0), "stone.limestone-sooted", r: 0.002)
            }
            // Hairline check along the grain of the handrail near one newel.
            FA.box(&m, V3(0.18, 0.0012, 0.0015), V3(-0.78, yh1 - 0.0005, 0.008), "wood.deadwood", r: 0.0003)
        }
        groundAO(&m, height: 0.2, floor: 0.8)
        return FC.place(m)
    }
}
