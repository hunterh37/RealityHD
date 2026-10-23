import simd
import Foundation

/// Victorian wrought-iron stair rail, 2.0 m: flat-bar top and bottom rails with a rounded cap bar, forged round pickets
/// turned with a central knop and collars at each rail, a centre panel of paired C-scrolls and a ring held by riveted
/// flat bars, and a square end post at each end with a ball-and-spear finial on a bolted base flange. Black paint
/// chipped to rust at the joints, rust bleed on the flanges and the bottom rail, bright new bolts on one flange.
public struct WroughtIronStairRail: RealAsset {
    public static let id = "wrought-iron-stair-rail"
    public static let summary = "Victorian wrought iron stair rail, 2.0 m: flat top and bottom rails, forged pickets with collars, scroll panel, end posts on base flanges."
    public static let tags = ["prop", "architecture", "facade", "trim", "metal"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 10, distance: 3.2)

    /// Black painted iron.
    public var iron: MaterialKey = "metal.wrought-iron"
    /// Cast-iron flanges and finials.
    public var cast: MaterialKey = "metal.cast-iron"
    /// Rust showing through chipped paint.
    public var rust: MaterialKey = "metal.rust"
    /// Bolts.
    public var bolt: MaterialKey = "metal.bolt-bright"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [make(seed: seed, lite: false), make(seed: seed, lite: true)], switchDistances: [6])
    }

    func make(seed: UInt64, lite: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let px: Float = 0.975                          // post centre x
        let span: Float = 2 * px - 0.032               // clear run between post faces
        let yb0: Float = 0.085, yb1: Float = 0.112     // bottom rail
        let yt0: Float = 0.90, yt1: Float = 0.925      // top rail flat bar
        let sides = lite ? 6 : 8
        // Rails: bottom flat bar, top flat bar with a rounded cap bar and a thin spacer bar beneath it.
        FA.box(&m, V3(span + 0.02, yb1 - yb0, 0.024), V3(0, (yb0 + yb1) / 2, 0), iron, r: 0.0025)
        FA.box(&m, V3(span + 0.02, yt1 - yt0, 0.03), V3(0, (yt0 + yt1) / 2, 0), iron, r: 0.003)
        FA.run(&m, [V2(-0.018, yt1), V2(0.018, yt1), V2(0.018, yt1 + 0.007), V2(0.0145, yt1 + 0.0115), V2(0.007, yt1 + 0.0135), V2(-0.007, yt1 + 0.0135), V2(-0.0145, yt1 + 0.0115), V2(-0.018, yt1 + 0.007)],
               length: span + 0.02, at: .zero, iron, bevel: 0.001)
        FA.box(&m, V3(span + 0.02, 0.01, 0.008), V3(0, yt0 - 0.005, 0), iron, r: 0.002)
        // Pickets every 0.1043, skipping the scroll panel.
        let n = 15, step = span / Float(n + 1), panelHalf: Float = 0.33
        let pk: [(Float, Float)] = [(0, 0), (0.0062, 0), (0.0062, 0.06), (0.0105, 0.066), (0.0105, 0.071), (0.0062, 0.077), (0.0062, 0.28),
                                    (0.0068, 0.292), (0.0125, 0.305), (0.0145, 0.320), (0.0125, 0.335), (0.0068, 0.348), (0.0062, 0.36),
                                    (0.0062, 0.54), (0.0105, 0.547), (0.0105, 0.552), (0.0062, 0.558), (0.0062, 0.7), (0, 0.7)]
        let ph = yt0 - yb1 + 0.012
        for i in 0..<n {
            let x = -span / 2 + Float(i + 1) * step
            if abs(x) < panelHalf { continue }
            // Repainted at different times: three blacks; one bare rusted picket, one fresh-painted replacement, one bent.
            let blacks: [MaterialKey] = [iron, "metal.wrought-iron:2B2723", "metal.wrought-iron:1B1A19"]
            let mat: MaterialKey = i == 2 ? rust : (i == 9 ? "metal.painted:0C0C0E" : blacks[rng.int(0...2)])
            let lean: Float = i == 11 ? 4.5 : rng.float(-0.4...0.4)
            m.add(turned(pk.map { ($0.0, $0.1 * ph / 0.7) }, segments: lite ? 6 : 8, material: mat, seamTile: 0.1, grainVertical: true),
                  Xform(translation: V3(x, yb1 - 0.006, 0), rotation: FA.q(lean, FA.Z)))
            // Rust sleeve at the picket foot where water sits, and a rust-edged collar at the top.
            if !lite {
                m.add(Prim.cylinder(radius: 0.0066, height: 0.035, bevel: 0, segments: 6, bevelSegments: 1, material: rust), Xform(translation: V3(x, yb1, 0)))
            }
            // Forged collars where the picket passes the rails.
            if !lite {
                for cy in [yb1 + 0.0035, yt0 - 0.0035] {
                    m.add(Prim.cylinder(radius: 0.0105, height: 0.006, bevel: 0.0012, segments: 6, bevelSegments: 1, material: iron), Xform(translation: V3(x, cy - 0.003, 0)))
                }
            }
        }
        // Centre panel: bounding flat bars, back-to-back C scrolls and a ring.
        for sx: Float in [-1, 1] {
            FA.box(&m, V3(0.014, yt0 - yb1, 0.008), V3(sx * panelHalf, (yb1 + yt0) / 2, 0), iron, r: 0.0025)
            for ry: Float in [yb1 + 0.01, yt0 - 0.01] { FA.cylZ(&m, r: 0.0075, h: 0.012, at: V3(sx * panelHalf, ry, -0.006), iron, bevel: 0.0015, segments: 10) }  // rivet heads
        }
        func spiral(_ c: V3, radius R: Float, dir: Float, start: Float, turns: Float, _ mat: MaterialKey) {
            var pts: [V3] = [], rad: [Float] = []
            let steps = lite ? 16 : 26
            for k in 0...steps {
                let t = Float(k) / Float(steps)
                let a = start + dir * t * turns * 2 * .pi
                let r = R * (1 - 0.82 * t)
                pts.append(c + V3(cos(a) * r, sin(a) * r, 0)); rad.append(0.0058 - 0.0022 * t)
            }
            m.add(Prim.tube(pts, radii: rad, sides: sides, seamTile: 0.1, material: mat, capEnd: true))
            m.add(Prim.superellipsoid(V3(repeating: 0.0125), exponent: 2, subdivisions: 6, material: mat), Xform(translation: pts.last!))
        }
        let cy = (yb1 + yt0) / 2
        for sx: Float in [-1, 1] {
            spiral(V3(sx * 0.195, cy + 0.2, 0), radius: 0.13, dir: -sx, start: sx > 0 ? .pi : 0, turns: 1.15, iron)
            spiral(V3(sx * 0.195, cy - 0.2, 0), radius: 0.13, dir: sx, start: sx > 0 ? .pi : 0, turns: 1.15, iron)
        }
        m.add(Prim.torus(major: 0.085, minor: 0.0055, segments: lite ? 18 : 30, sides: 8, material: iron), Xform(translation: V3(0, cy, 0), rotation: FA.q(90, FA.X)))
        FA.box(&m, V3(0.012, yt0 - yb1, 0.008), V3(0, cy, 0), iron, r: 0.0025)
        // Riveted bands where scrolls cross the centre bar.
        if !lite {
            for by in [cy - 0.2, cy, cy + 0.2] {
                FA.box(&m, V3(0.026, 0.014, 0.014), V3(0, by, 0), iron, r: 0.003)
                for rx: Float in [-0.009, 0.009] { FA.cylZ(&m, r: 0.0028, h: 0.0035, at: V3(rx, by, 0.007), cast, bevel: 0.001, segments: 8) }
            }
        }
        // End posts: square bar, collar rings, ball and spear finial, cast flange with bolts.
        for e: Float in [-1, 1] {
            let x = e * px
            FA.box(&m, V3(0.032, 0.84, 0.032), V3(x, 0.455, 0), iron, r: 0.0035)
            FA.box(&m, V3(0.04, 0.012, 0.04), V3(x, yb0 - 0.01, 0), iron, r: 0.003)
            FA.box(&m, V3(0.04, 0.012, 0.04), V3(x, yt1 + 0.022, 0), iron, r: 0.003)
            FA.box(&m, V3(0.05, 0.01, 0.05), V3(x, 0.005, 0), cast, r: 0.003)                              // flange plate
            m.add(turned([(0, 0.01), (0.0235, 0.01), (0.021, 0.017), (0.0165, 0.03), (0.0165, 0.036), (0, 0.036)], segments: 8, material: cast, seamTile: 0.1), Xform(translation: V3(x, 0, 0)))
            m.add(turned([(0, 0.875), (0.012, 0.875), (0.015, 0.882), (0.0105, 0.892), (0.017, 0.903), (0.0195, 0.918), (0.015, 0.934), (0.0065, 0.941), (0.0045, 0.955),
                          (0.0095, 0.967), (0.0105, 0.980), (0.004, 0.998), (0, 1.0)], segments: lite ? 8 : 10, material: cast, seamTile: 0.1, grainVertical: true), Xform(translation: V3(x, 0, 0)))
            if !lite {
                for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
                    m.add(Prim.cylinder(radius: 0.0048, height: 0.004, bevel: 0.0007, segments: 6, bevelSegments: 1, material: bolt), Xform(translation: V3(x + sx * 0.019, 0.01, sz * 0.019)))
                }}
            }
        }
        // Weathering: rust where paint chipped at the rail joints, flanges, bottom rail top, and a few pickets.
        if !lite {
            func flat(_ cx: Float, _ cz: Float, _ rx: Float, _ rz: Float, y: Float, _ mat: MaterialKey) {
                var poly: [V2] = []
                for j in 0..<9 { let a = Float(j) / 9 * 2 * .pi; poly.append(V2(cx + cos(a) * rx * rng.float(0.55...1.1), cz + sin(a) * rz * rng.float(0.55...1.1))) }
                m.add(HTKit.plate(outer: poly, depth: 0.0008, bevel: 0.0002, segments: 1, material: mat), Xform(translation: V3(0, y, 0), rotation: FA.q(90, FA.X)))
            }
            for _ in 0..<12 { flat(rng.float(-0.9...0.9), rng.float(-0.008...0.008), rng.float(0.015...0.06), rng.float(0.004...0.009), y: yb1 + 0.0004, rust) }
            for _ in 0..<6 { flat(rng.float(-0.9...0.9), rng.float(-0.01...0.01), rng.float(0.012...0.05), rng.float(0.004...0.009), y: yt1 + 0.0141, rust) }
            for e: Float in [-1, 1] {
                for _ in 0..<3 { flat(e * px + rng.float(-0.02...0.02), rng.float(-0.012...0.012), rng.float(0.005...0.01), rng.float(0.004...0.008), y: 0.0106, rust) }
                FA.box(&m, V3(0.0505, 0.003, 0.0505), V3(e * px, 0.0015, 0), rust, r: 0.001)                    // rust bleed under the flange
                FA.box(&m, V3(0.033, 0.03, 0.033), V3(e * px, 0.052, 0), rust, r: 0.003)                        // chipped post foot
                FA.box(&m, V3(0.0335, 0.012, 0.0335), V3(e * px, 0.07, 0), iron, r: 0.002)
            }
            // Hairline crack in the paint down one post.
            FA.box(&m, V3(0.0012, 0.25, 0.0334), V3(-px + 0.01, 0.5, 0), rust, r: 0.0003)
        }
        groundAO(&m, height: 0.15, floor: 0.8)
        return FC.place(m)
    }
}
