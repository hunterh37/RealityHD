import simd
import Foundation

/// Art Nouveau whiplash railing: architectural facade customizer, Art Nouveau, painted wrought iron with verdigris wear. Parts: bottom rail, top rail, bronze handrail cap, end posts with whiplash curl finials, tapered whiplash flat-bar curves, paired tendril scrolls, rivet collars, floor plates.
public struct ArtNouveauWhiplashRailing: RealAsset {
    public static let id = "art-nouveau-whiplash-railing"
    public static let summary = "Art Nouveau balcony railing, 1.8 m: flat-bar frame, tapered whiplash curves, bronze handrail, rivets."
    public static let tags = ["prop", "architecture", "facade", "trim", "decor", "metal"]
    public static let budget = 15000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(1.8, 1.0, 0.06)
    /// Painted wrought-iron material (green paint over iron).
    public var iron: MaterialKey = "metal.painted:2F4A3C"
    /// Bare wrought iron for rails and collars.
    public var bare: MaterialKey = "metal.wrought-iron"
    /// Handrail cap material.
    public var bronze: MaterialKey = "metal.bronze-cast"
    public init() {}

    /// Inward spiral in the XY plane: radius r0 to r1 over `turns`, starting at angle a0 (radians), dir +1 CCW.
    static func spiral(center c: V2, r0: Float, r1: Float, a0: Float, turns: Float, dir: Float, z: Float, steps: Int = 15) -> [V3] {
        (0...steps).map { i in
            let t = Float(i) / Float(steps)
            let a = a0 + dir * t * turns * 2 * .pi
            let r = r0 + (r1 - r0) * t * t * (3 - 2 * t) * 0.5 + (r1 - r0) * t * 0.5
            return V3(c.x + r * cos(a), c.y + r * sin(a), z)
        }
    }

    /// Domed rivet head.
    func stud(_ m: inout Model, _ r: Float, _ c: V3) {
        m.add(Prim.superellipsoid(V3(repeating: r * 2), exponent: 2, subdivisions: 2, material: bare), Xform(translation: c))
    }

    /// Tapered flat-bar sweep: 12 mm thick in Z, `w` wide in plane at the root, tapering to 40 percent.
    static func bar(_ m: inout Model, _ path: [V3], w: Float, _ mat: MaterialKey) {
        let t: Float = 0.006, b: Float = 0.003
        let prof = [V2(-t + b, -w / 2), V2(t - b, -w / 2), V2(t, 0), V2(t - b, w / 2), V2(-t + b, w / 2), V2(-t, 0)]
        let n = path.count
        let scales = (0..<n).map { i -> Float in 1 - 0.6 * pow(Float(i) / Float(n - 1), 1.3) }
        m.add(Prim.sweep(prof, along: path, up: FA.Z, scales: scales, caps: true, material: mat))
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = size.x, H = size.y, hw = W / 2
        let postX = hw - 0.016
        let railLo: Float = 0.08, railHi: Float = 0.915

        // Bottom and top flat-bar rails, bronze D-section handrail cap on top.
        FA.box(&m, V3(W - 0.06, 0.03, 0.016), V3(0, railLo, 0), bare, r: 0.003)
        FA.box(&m, V3(W - 0.06, 0.026, 0.016), V3(0, railHi, 0), bare, r: 0.003)
        let cap = Shape2D.rounded([V2(-0.028, 0.945), V2(0.028, 0.945), V2(0.028, 1.0), V2(-0.028, 1.0)], radius: 0.02)
        FA.run(&m, cap, length: W, bronze, bevel: 0.002)
        FA.box(&m, V3(W - 0.06, 0.006, 0.035), V3(0, 0.941, 0), bronze, r: 0.002)

        // End posts: square bar with a floor plate, four rivets, a collar and a curl finial.
        for e: Float in [-1, 1] {
            let x = e * postX
            FA.box(&m, V3(0.032, 0.95, 0.032), V3(x, 0.485, 0), iron, r: 0.004)
            FA.box(&m, V3(0.07, 0.012, 0.06), V3(x - e * 0.018, 0.006, 0), bare, r: 0.003)
            for (dx, dz) in [(-0.036, -0.02), (0.036, -0.02), (-0.036, 0.02), (0.036, 0.02)] as [(Float, Float)] {
                stud(&m, 0.006, V3(x - e * 0.018 + dx * 0.55, 0.014, dz))
            }
            for y: Float in [0.20, 0.72] {
                FA.box(&m, V3(0.044, 0.026, 0.044), V3(x, y, 0), bare, r: 0.004)
            }
            // Whiplash curl finial on the inner face of the post.
            let sp = Self.spiral(center: V2(x - e * 0.06, 0.52), r0: 0.06, r1: 0.012, a0: e > 0 ? 0 : .pi, turns: 1.35, dir: e > 0 ? 1 : -1, z: 0)
            let root = [V3(x, 0.30, 0), V3(x - e * 0.01, 0.40, 0), V3(x - e * 0.025, 0.47, 0)]
            Self.bar(&m, root + sp.dropFirst(), w: 0.02, iron)
        }

        // Four whiplash units: paired mirrored stems with spiral ends and secondary tendrils.
        let units: [Float] = [-0.675, -0.225, 0.225, 0.675]
        for (ui, c) in units.enumerated() {
            var urng = rng.fork(ui)
            for s: Float in [-1, 1] {
                let sx = { (x: Float) -> Float in c + s * (x - c) }
                let jit = urng.float(-0.006...0.006)
                let stem: [V3] = [V3(sx(c), railLo + 0.015, 0), V3(sx(c - 0.018 + jit), 0.24, 0), V3(sx(c + 0.004), 0.42, 0),
                                  V3(sx(c + 0.032), 0.58, 0), V3(sx(c + 0.04), 0.67, 0)]
                let sc = V2(sx(c + 0.04 + 0.085), 0.70)
                let sp = Self.spiral(center: sc, r0: 0.085, r1: 0.014, a0: s > 0 ? .pi : 0, turns: 1.3, dir: s > 0 ? -1 : 1, z: 0)
                let line = catmull(stem, per: 3) + sp.dropFirst()
                let dedup = line.enumerated().filter { $0.offset == 0 || simd_length($0.element - line[$0.offset - 1]) > 0.013 }.map { $0.element }
                Self.bar(&m, dedup, w: 0.024, iron)
                // Secondary tendril: a small C curl leaving the stem at y 0.33, curling outward and down.
                let tc = V2(sx(c + 0.004 + 0.045), 0.33)
                let tend = Self.spiral(center: tc, r0: 0.045, r1: 0.012, a0: s > 0 ? .pi : 0, turns: 0.95, dir: s > 0 ? 1 : -1, z: 0.0035, steps: 12)
                Self.bar(&m, tend, w: 0.014, iron)
                // Rivet collars where the tendril and the stem meet, and at the rail joint.
                for y: Float in [0.33, 0.52] {
                    let x = sx(c + (y < 0.4 ? 0.0 : 0.02))
                    FA.box(&m, V3(0.036, 0.018, 0.024), V3(x, y, 0), bare, r: 0.003)
                    stud(&m, 0.0048, V3(x, y, 0.013))
                }
                FA.box(&m, V3(0.034, 0.02, 0.022), V3(sx(c), railLo + 0.012, 0), bare, r: 0.003)
                FA.box(&m, V3(0.034, 0.02, 0.022), V3(sx(c + 0.03), railHi - 0.012, 0), bare, r: 0.003)
            }
            // Upper tie: round rod from the top of each spiral pair up into the top rail.
            for s: Float in [-1, 1] {
                let x = c + s * 0.125
                FA.rod(&m, V3(x, 0.735, 0), V3(x, railHi, 0), r: 0.006, iron, sides: 8)
            }
            // Short upper stem pair tying the units to the top rail.
            FA.rod(&m, V3(c, railLo + 0.02, 0), V3(c, 0.2, 0), r: 0.007, iron, sides: 8)
        }

        // Wear: rust blooms at the floor plates and rail joints, verdigris runs under the bronze cap, chips in the paint.
        for e: Float in [-1, 1] {
            FA.box(&m, V3(0.06, 0.05, 0.002), V3(e * postX, 0.04, 0.0175), "metal.rust", r: 0.0005)
        }
        // Verdigris crusting on the stems at the collars, flush with the bar.
        for i in 0..<10 {
            let c = units[i % 4], s: Float = i % 2 == 0 ? -1 : 1
            FA.cylZ(&m, r: rng.float(0.008...0.014), h: 0.0016, at: V3(c + s * rng.float(0.0...0.03), rng.float(0.25...0.6), 0.0072), "metal.painted:5E9C86", bevel: 0.0005, segments: 6)
        }
        for i in 0..<10 {
            let x = rng.float(-hw + 0.1...hw - 0.1)
            FA.box(&m, V3(rng.float(0.008...0.02), 0.01, 0.0015), V3(x, railLo + rng.float(-0.006...0.006), 0.009), "metal.rust", r: 0.0004)
        }
        // Chipped paint on the stems: bare rust showing through at hand height and where the bars cross.
        for i in 0..<16 {
            let c = units[i % 4], s: Float = i % 8 < 4 ? -1 : 1
            let y = rng.float(0.16...0.55)
            FA.box(&m, V3(rng.float(0.006...0.014), rng.float(0.008...0.02), 0.0015), V3(c + s * rng.float(0.0...0.03), y, 0.0065), "metal.rust", r: 0.0004)
        }
        // Rust bleed on the bottom rail and flaking at the post collars.
        for i in 0..<14 {
            let x = rng.float(-hw + 0.1...hw - 0.1)
            FA.cylZ(&m, r: rng.float(0.005...0.011), h: 0.0014, at: V3(x, railLo + rng.float(-0.008...0.008), 0.0088), "metal.rust", bevel: 0.0004, segments: 6)
        }
        for e: Float in [-1, 1] {
            for y: Float in [0.20, 0.72] {
                FA.cylZ(&m, r: 0.007, h: 0.0014, at: V3(e * postX + 0.008, y, 0.0225), "metal.rust", bevel: 0.0004, segments: 6)
            }
        }
        groundAO(&m, height: 0.12, floor: 0.7)
        return LODModel(FA.centerZ(m))
    }
}
