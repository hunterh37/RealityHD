import simd
import Foundation

/// Nautical rope handrail run, 3.0 m: five galvanized round stanchions on bolted square flanges, each capped with a
/// brass ball and fitted with two brass thimble rings through which a three-strand laid manila rope runs in four
/// sagging spans. The rope ends in stopper knots with whipped tails at the end stanchions. Sun-bleached and
/// grimy rope tones differ per span, the middle span is a newer rope, salt crust and rust bleed mark the flanges,
/// bolts are galvanized with one bright replacement.
public struct RopeHandrailRun: RealAsset {
    public static let id = "rope-handrail-run"
    public static let summary = "Nautical rope handrail run, 3.0 m: manila rope through four stanchions with brass eyes, whipped ends and flanged bases."
    public static let tags = ["prop", "architecture", "facade", "trim", "metal"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 10, distance: 2.4)

    /// Manila rope, weathered.
    public var rope: MaterialKey = "sack.jute"
    /// Galvanized stanchions and flanges.
    public var steel: MaterialKey = "metal.galvanized"
    /// Brass caps and thimbles.
    public var brass: MaterialKey = "metal.brass-aged"
    /// Rust staining.
    public var rust: MaterialKey = "metal.rust"
    /// Replacement bolt.
    public var bolt: MaterialKey = "metal.bolt-bright"
    /// Whipping twine.
    public var twine: MaterialKey = "fabric.canvas"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [make(seed: seed, lite: false), make(seed: seed, lite: true)], switchDistances: [6])
    }

    func make(seed: UInt64, lite: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let n = 5
        let x0: Float = -1.41, gap: Float = 0.705
        let eyeY: Float = 0.80, sag: Float = 0.07
        let ro: Float = 0.0098, rs: Float = 0.012
        // Stanchions.
        for i in 0..<n {
            let x = x0 + Float(i) * gap
            FA.box(&m, V3(0.05, 0.008, 0.05), V3(x, 0.004, 0), steel, r: 0.0025)
            let postMat: MaterialKey = i == 3 ? "metal.stainless" : (i % 2 == 0 ? "metal.galvanized-aged" : steel)   // post 3 is a newer stainless replacement
            m.add(turned([(0, 0.008), (0.024, 0.008), (0.0235, 0.016), (0.0225, 0.03), (0.0195, 0.05), (0.0195, 0.80), (0.0215, 0.815), (0.0215, 0.838), (0.0195, 0.848), (0.0195, 0.86), (0, 0.86)], segments: lite ? 8 : 12, material: postMat, seamTile: 0.1, grainVertical: true), Xform(translation: V3(x, 0, 0)))
            m.add(Prim.superellipsoid(V3(0.046, 0.046, 0.046), exponent: 2, subdivisions: lite ? 2 : 2, material: brass), Xform(translation: V3(x, 0.882, 0)))
            m.add(turned([(0, 0.855), (0.0215, 0.855), (0.0235, 0.859), (0.0235, 0.863), (0.017, 0.868), (0, 0.868)], segments: lite ? 8 : 12, material: brass, seamTile: 0.1), Xform(translation: V3(x, 0, 0)))
            // Brass eye collar through the post: a barrel with flared mouths either side, rope runs through it.
            for sx: Float in [-1, 1] {
                m.add(turned([(0.0185, 0), (0.0235, 0.002), (0.0252, 0.007), (0.0252, 0.012), (0.0235, 0.02), (0.0235, 0.032)], segments: lite ? 8 : 14, material: brass, seamTile: 0.1),
                      Xform(translation: V3(x + sx * 0.014, eyeY, 0), rotation: FA.q(-sx * 90, FA.Z)))
            }
            if !lite {
                for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
                    let fresh = i == 3 && sx > 0 && sz > 0
                    m.add(Prim.cylinder(radius: 0.0048, height: 0.005, bevel: 0.0008, segments: 6, bevelSegments: 1, material: fresh ? bolt : steel), Xform(translation: V3(x + sx * 0.0195, 0.008, sz * 0.0195)))
                }}
            }
        }
        // Rope: three laid strands twisted round a core, one object per span so tones can differ.
        let tones: [MaterialKey] = ["sack.jute:B49B72", "sack.jute:8A7458", "sack.jute:D3BE92", "sack.jute:A08A66"]
        let steps = lite ? 24 : 32
        func ropeY(_ t: Float) -> Float { eyeY - sag * 4 * t * (1 - t) }
        for sp in 0..<(n - 1) {
            let xa = x0 + Float(sp) * gap, xb = xa + gap
            var centre: [V3] = []
            for k in 0...steps { let t = Float(k) / Float(steps); centre.append(V3(xa + (xb - xa) * t, ropeY(t), 0)) }
            m.add(Prim.tube(centre, radii: Array(repeating: ro * 1.05, count: centre.count), sides: lite ? 4 : 5, seamTile: 0.1, material: tones[sp], capEnd: true))
            if lite { continue }
            // Turk's head knot and a few stray fibres near the span quarter points.
            m.add(Prim.torus(major: 0.0225, minor: 0.0034, segments: 10, sides: 4, material: tones[(sp + 2) % 4]), Xform(translation: centre[steps / 4] + V3(0, 0, 0), rotation: FA.q(90, FA.Z)))
            for _ in 0..<5 {
                let k = rng.int(2...(steps - 2)), a = rng.float(0...(2 * .pi))
                let p = centre[k] + V3(0, cos(a) * ro * 1.6, sin(a) * ro * 1.6)
                m.add(Prim.tube([p, p + V3(rng.float(-0.012...0.012), cos(a) * 0.0075, sin(a) * 0.0075)], radii: [0.0012, 0.0006], sides: 3, seamTile: 0.1, material: tones[(sp + 3) % 4], capEnd: true))
            }
            for st in 0..<3 {
                var pts: [V3] = []
                for k in 0...steps {
                    let t = Float(k) / Float(steps)
                    let s = (Float(sp) * gap + t * gap)
                    let phi = s * 2 * .pi / 0.085 + Float(st) * 2 * .pi / 3
                    let c = centre[k]
                    pts.append(c + V3(0, cos(phi) * ro, sin(phi) * ro))
                }
                m.add(Prim.tube(pts, radii: Array(repeating: rs, count: pts.count), sides: 5, seamTile: 0.1, material: tones[sp], capEnd: true))
            }
        }
        // End treatment: stopper knot beyond each end stanchion, whipped tail below.
        for e: Float in [-1, 1] {
            let xe = e * 1.41
            let kx = xe + e * 0.055
            m.add(Prim.superellipsoid(V3(0.05, 0.05, 0.05), exponent: 2, subdivisions: lite ? 2 : 3, material: tones[e < 0 ? 0 : 3]), Xform(translation: V3(kx, eyeY, 0)))
            m.add(Prim.tube([V3(xe + e * 0.03, eyeY, 0), V3(xe + e * 0.055, eyeY - 0.004, 0), V3(kx, eyeY - 0.02, 0)], radii: [ro * 1.05, ro * 1.05, ro * 1.05], sides: 6, seamTile: 0.1, material: tones[e < 0 ? 0 : 3], capEnd: true))
            if !lite {
                // Frayed tail ends and whipping bands.
                for k in 0..<3 {
                    let a = Float(k) * 2.1
                    m.add(Prim.tube([V3(kx, eyeY - 0.02, 0), V3(kx + e * 0.02, eyeY - 0.05, sin(a) * 0.006), V3(kx + e * 0.026, eyeY - 0.09 - Float(k) * 0.01, sin(a) * 0.012)], radii: [0.0045, 0.0042, 0.0025], sides: 4, seamTile: 0.1, material: tones[e < 0 ? 0 : 3], capEnd: true))
                }
                for k in 0..<2 {
                    m.add(Prim.torus(major: 0.0215, minor: 0.0028, segments: 10, sides: 4, material: twine), Xform(translation: V3(xe + e * (0.04 + Float(k) * 0.0065), eyeY, 0), rotation: FA.q(90, FA.Z)))
                }
            }
        }
        // Weathering: salt crust and rust at the flanges, rust bleed down the posts, brine streak on the rope span low points.
        if !lite {
            func flat(_ cx: Float, _ cz: Float, _ rx: Float, _ rz: Float, y: Float, _ mat: MaterialKey) {
                var poly: [V2] = []
                for j in 0..<9 { let a = Float(j) / 9 * 2 * .pi; poly.append(V2(cx + cos(a) * rx * rng.float(0.55...1.1), cz + sin(a) * rz * rng.float(0.55...1.1))) }
                m.add(HTKit.plate(outer: poly, depth: 0.0008, bevel: 0.0002, segments: 1, material: mat), Xform(translation: V3(0, y, 0), rotation: FA.q(90, FA.X)))
            }
            for i in 0..<n {
                let x = x0 + Float(i) * gap
                for _ in 0..<2 { flat(x + rng.float(-0.015...0.015), rng.float(-0.015...0.015), rng.float(0.005...0.01), rng.float(0.004...0.008), y: 0.0088, rust) }
                FA.box(&m, V3(0.0505, 0.003, 0.0505), V3(x, 0.0015, 0), rust, r: 0.001)
                if i != 3 {
                    // Verdigris run below the brass collar and a dark tar chafe band on the rope at the collar.
                    m.add(Prim.cylinder(radius: 0.0199, height: rng.float(0.05...0.1), bevel: 0, segments: 10, bevelSegments: 1, material: "metal.copper-patina"), Xform(translation: V3(x, eyeY - 0.12, 0)))
                }
                for sx: Float in [-1, 1] where (sx > 0 && i < n - 1) || (sx < 0 && i > 0) {
                    FA.cylX(&m, r: 0.0225, h: 0.045, at: V3(x + (sx > 0 ? 0.034 : -0.079), eyeY - 0.0008, 0), "sack.jute:3F3426", bevel: 0.002, segments: 8)
                }
                for _ in 0..<2 { flat(x + rng.float(-0.015...0.015), rng.float(-0.015...0.015), rng.float(0.004...0.009), rng.float(0.004...0.008), y: 0.0089, "stone.limestone") }
                m.add(Prim.cylinder(radius: 0.0199, height: rng.float(0.03...0.08), bevel: 0, segments: 10, bevelSegments: 1, material: rust), Xform(translation: V3(x, 0.045, 0)))
                m.add(Prim.cylinder(radius: 0.0198, height: 0.04, bevel: 0, segments: 10, bevelSegments: 1, material: "metal.galvanized"), Xform(translation: V3(x, 0.44 + rng.float(-0.1...0.1), 0)))
            }
        }
        groundAO(&m, height: 0.1, floor: 0.85)
        return FC.place(m)
    }
}
