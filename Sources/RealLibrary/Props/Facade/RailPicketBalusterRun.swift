import simd
import Foundation

/// American Traditional porch picket run, 2.4 m: 21 pointed 38 mm pickets screwed between a bullnose cap rail
/// (cove under the nosing, drip groove) over a 2x2 apron rail with a bead, and a bottom 2x3 on edge with a
/// chamfered top, closed by a 4x4 post at each end with a chamfered cap and a bolted base. Painted white, with flaked
/// paint and grey bare wood on the cap, putty-filled nail holes, zinc screws, one unpainted replacement picket
/// and a damp stain at the picket feet.
public struct RailPicketBalusterRun: RealAsset {
    public static let id = "rail-picket-baluster-run"
    public static let summary = "Porch baluster run, 2.4 m: moulded top rail, bottom rail, turned pickets, newels with caps, painted and weathered."
    public static let tags = ["prop", "architecture", "facade", "trim", "wood"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 10, distance: 3.2)

    /// Run length in meters.
    public var length: Float = 2.4
    /// Number of pickets.
    public var pickets = 19
    /// Painted wood.
    public var paint: MaterialKey = "wood.painted-exterior:DDD7C4"
    /// Bare weathered wood showing through flaked paint.
    public var bare: MaterialKey = "wood.weathered"
    /// Zinc screws.
    public var screw: MaterialKey = "metal.screw-zinc"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [make(seed: seed, lite: false), make(seed: seed, lite: true)], switchDistances: [5])
    }

    func make(seed: UInt64, lite: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let L = length, px = L / 2 - 0.0255, span = 2 * px - 0.05
        let yb0: Float = 0.09, yb1: Float = 0.142          // bottom rail 2x3 on edge
        let ya0: Float = 0.838, ya1: Float = 0.876          // apron 2x2
        let yc0: Float = 0.876                               // cap rail
        let pw: Float = 0.042, pt: Float = 0.038
        // Bottom rail: chamfered top, flat under, 38 mm thick.
        FA.run(&m, [V2(-0.019, yb0), V2(0.019, yb0), V2(0.019, yb1 - 0.012), V2(0.012, yb1), V2(-0.012, yb1), V2(-0.019, yb1 - 0.012)], length: span + 0.02, paint, bevel: 0.0012)
        // Apron rail with a half-round bead along its lower edge.
        FA.run(&m, [V2(-0.019, ya0), V2(0.019, ya0), V2(0.019, ya1), V2(-0.019, ya1)], length: span + 0.02, paint, bevel: 0.0015)
        FA.run(&m, [V2(-0.0195, ya0 - 0.001), V2(0.0195, ya0 - 0.001), V2(0.0195, ya0 + 0.004), V2(0.0165, ya0 + 0.0075), V2(-0.0165, ya0 + 0.0075), V2(-0.0195, ya0 + 0.004)], length: span + 0.021, paint, bevel: 0.0005)
        // Cap rail: bullnose edges, cove under the nosing, slight crown for drainage, drip groove.
        let cap: [V2] = [V2(-0.0325, yc0 + 0.012), V2(-0.0325, yc0 + 0.026), V2(-0.0305, yc0 + 0.0405), V2(-0.0235, yc0 + 0.0465), V2(-0.010, yc0 + 0.0495), V2(0.010, yc0 + 0.0495),
                         V2(0.0235, yc0 + 0.0465), V2(0.0305, yc0 + 0.0405), V2(0.0325, yc0 + 0.026), V2(0.0325, yc0 + 0.012), V2(0.0285, yc0 + 0.0075), V2(0.0255, yc0 + 0.0035),
                         V2(0.0215, yc0 + 0.0), V2(0.015, yc0), V2(-0.015, yc0), V2(-0.0215, yc0), V2(-0.0255, yc0 + 0.0035), V2(-0.0285, yc0 + 0.0075)]
        FA.run(&m, cap.map { V2($0.x * 0.77, $0.y) }, length: span + 0.04, paint, bevel: 0.0008)
        // Pickets: pointed profile extruded 38 mm, chamfer reveal, seated on the bottom rail, tops into the apron.
        let ph = ya0 - yb1 + 0.02
        let pw2 = pw / 2
        let prof: [V2] = [V2(-pw2, 0), V2(pw2, 0), V2(pw2, ph - 0.05), V2(pw2 * 0.55, ph - 0.012), V2(0, ph), V2(-pw2 * 0.55, ph - 0.012), V2(-pw2, ph - 0.05)]
        let step = span / Float(pickets + 1)
        let replaced = 14
        for i in 0..<pickets {
            let x = -span / 2 + Float(i + 1) * step
            let tints: [MaterialKey] = [paint, "wood.painted-exterior:CFC8B3", "wood.painted-exterior:E8E2D0", "wood.painted-exterior:C2BAA3"]
            let mat: MaterialKey = i == replaced ? "wood.lumber-pine" : tints[rng.int(0...3)]
            m.add(Prim.extrude(prof, depth: pt - 0.006, bevel: 0.0025, bevelSegments: 1, material: mat),
                  Xform(translation: V3(x + rng.float(-0.0006...0.0006), yb1 - 0.01, 0), rotation: FA.q(0, FA.Y)))
            if !lite {
                // Vertical bead groove down the picket face, damp-darkened foot, and flaked paint on some pickets.
                FA.box(&m, V3(pw - 0.004, rng.float(0.05...0.16), 0.0013), V3(x, yb1 + 0.04 + rng.float(0.0...0.03), 0.0163), i % 4 == 0 ? "wood.painted-exterior:6F7862" : "wood.painted-exterior:9D957E", r: 0.0005)
                if i % 3 == 1 {
                    FA.box(&m, V3(rng.float(0.008...0.02), rng.float(0.03...0.09), 0.0012), V3(x + rng.float(-0.006...0.006), rng.float(0.28...0.62), 0.0163), rng.chance(0.5) ? bare : "wood.deadwood", r: 0.0004)
                }
                // Zinc screws through the picket into the bottom rail and the apron, filled nail holes in the apron.
                for sy in [yb1 + 0.018, ya0 - 0.02] {
                    FA.cylZ(&m, r: 0.0036, h: 0.0016, at: V3(x, sy, pt / 2 - 0.003), screw, bevel: 0.0006, segments: 8)
                }
                
            }
        }
        // End posts: 4x4 with chamfered edges, base moulding, cap block with a hipped top, bolted foot plate.
        for e: Float in [-1, 1] {
            let x = e * px
            FA.box(&m, V3(0.05, 0.012, 0.05), V3(x, 0.006, 0), "metal.galvanized-aged", r: 0.002)              // foot plate
            FA.box(&m, V3(0.05, 0.86, 0.05), V3(x, 0.44, 0), paint, r: 0.0045)                                   // shaft
            FA.box(&m, V3(0.05, 0.02, 0.05), V3(x, 0.04, 0), paint, r: 0.003)                                     // base block
            FA.box(&m, V3(0.05, 0.008, 0.05), V3(x, 0.052, 0), paint, r: 0.002)
            FA.box(&m, V3(0.05, 0.024, 0.05), V3(x, 0.875, 0), paint, r: 0.004)                                  // cap block
            m.add(turned([(0, 0.887), (0.021, 0.887), (0.0175, 0.894), (0.0105, 0.900), (0.0075, 0.905), (0.0195, 0.912), (0.0245, 0.926), (0.0225, 0.940), (0.0125, 0.945), (0.004, 0.949), (0, 0.950)],
                         segments: lite ? 8 : 14, material: paint, seamTile: 0.2, grainVertical: true), Xform(translation: V3(x, 0, 0)))
            if !lite {
                for (sx, sz) in [(-1, -1), (1, -1), (-1, 1), (1, 1)] as [(Float, Float)] {
                    m.add(Prim.cylinder(radius: 0.0046, height: 0.004, bevel: 0.0007, segments: 6, bevelSegments: 1, material: "metal.bolt-bright"),
                          Xform(translation: V3(x + sx * 0.019, 0.012, sz * 0.019)))
                }
                // Rail-to-post screws and filled nail holes.
                for sy in [yc0 - 0.02, yb0 + 0.025] {
                    FA.cylZ(&m, r: 0.0036, h: 0.0016, at: V3(x - e * 0.014, sy, 0.0233), screw, bevel: 0.0006, segments: 8)
                }
            }
        }
        // Weathering: flaked grey patches on the cap top and nosing, soiled bottom rail, damp at picket feet.
        if !lite {
            func flat(_ cx: Float, _ cz: Float, _ rx: Float, _ rz: Float, y: Float, _ mat: MaterialKey) {
                var poly: [V2] = []
                for j in 0..<8 { let a = Float(j) / 8 * 2 * .pi; poly.append(V2(cx + cos(a) * rx * rng.float(0.6...1.1), cz + sin(a) * rz * rng.float(0.6...1.1))) }
                m.add(HTKit.plate(outer: poly, depth: 0.0012, bevel: 0.0003, segments: 1, material: mat),
                      Xform(translation: V3(0, y, 0), rotation: FA.q(90, FA.X)))
            }
            for _ in 0..<10 { flat(rng.float(-span / 2 + 0.05...span / 2 - 0.05), rng.float(-0.012...0.012), rng.float(0.05...0.22), rng.float(0.008...0.016), y: yc0 + 0.0494, rng.chance(0.7) ? bare : "wood.deadwood") }
            for _ in 0..<5 { flat(rng.float(-span / 2 + 0.05...span / 2 - 0.05), rng.float(-0.006...0.006), rng.float(0.02...0.06), rng.float(0.006...0.01), y: yb1 - 0.0, "wood.deadwood") }
            for e: Float in [-1, 1] {
                FA.box(&m, V3(0.0501, 0.04, 0.0501), V3(e * px, 0.02, 0), "wood.trim-weathered", r: 0.003)
                FA.box(&m, V3(0.0501, 0.05, 0.0501), V3(e * px, 0.085, 0), "wood.painted-exterior:77806A", r: 0.003)
                FA.box(&m, V3(0.05, 0.003, 0.05), V3(e * px, 0.0135, 0), "metal.rust", r: 0.001)
                FA.box(&m, V3(0.05, 0.0012, 0.05), V3(e * px, 0.0006, 0), "metal.rust", r: 0.0003)   // rust bleed under the plate
            }
            // Splash staining on the bottom rail face under pickets.
            for _ in 0..<7 { FA.box(&m, V3(rng.float(0.02...0.06), rng.float(0.01...0.03), 0.0012), V3(rng.float(-span / 2 + 0.05...span / 2 - 0.05), yb0 + 0.02, 0.0196), "wood.painted-exterior:B3AB93", r: 0.0004) }
            // Flaked paint on posts, apron and bottom rail faces: bare grey wood through the cream.
            for e: Float in [-1, 1] {
                for _ in 0..<3 { FA.box(&m, V3(rng.float(0.008...0.025), rng.float(0.02...0.09), 0.0012), V3(e * px + rng.float(-0.014...0.014), rng.float(0.1...0.8), 0.0245), rng.chance(0.5) ? bare : "wood.deadwood", r: 0.0004) }
            }
            for _ in 0..<5 { FA.box(&m, V3(rng.float(0.02...0.09), rng.float(0.006...0.02), 0.0012), V3(rng.float(-span / 2 + 0.05...span / 2 - 0.05), ya0 + 0.02 + rng.float(-0.01...0.01), 0.0195), rng.chance(0.5) ? bare : "wood.deadwood", r: 0.0004) }
            for _ in 0..<4 { FA.box(&m, V3(rng.float(0.02...0.1), rng.float(0.006...0.016), 0.0012), V3(rng.float(-span / 2 + 0.05...span / 2 - 0.05), yb0 + 0.03 + rng.float(-0.012...0.012), 0.0195), rng.chance(0.5) ? bare : "wood.deadwood", r: 0.0004) }
            // Check along the grain on the cap.
            FA.box(&m, V3(0.22, 0.0012, 0.0015), V3(0.7, yc0 + 0.0488, 0.012), "wood.deadwood", r: 0.0003)
            // Paint run on the apron.
            FA.box(&m, V3(0.003, 0.03, 0.0012), V3(-0.4, ya0 + 0.02, 0.0196), "wood.painted-exterior:F6F3EA", r: 0.0005)
        }
        groundAO(&m, height: 0.22, floor: 0.7)
        return FC.place(m)
    }
}
