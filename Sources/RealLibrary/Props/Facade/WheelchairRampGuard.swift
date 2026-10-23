import simd
import Foundation

/// Accessible ramp edge guard, 3.0 m long, 1.0 m high, 50 mm deep: four galvanized 42 mm pipe posts on bolted base
/// flanges with domed caps, a powder-coated 38 mm handrail at 865 mm with 90 degree drop returns at both ends, a 33 mm
/// brushed-aluminum guard rail at 965 mm in saddle clamps, two 25 mm intermediate rails through the posts with weld
/// beads, a 100 mm aluminum curb rail with a safety-yellow edge strip bolted to the posts, and a splice sleeve in the
/// handrail. Wear: white rust on the zinc, wheel-strike scuffs and a dent on the curb, polished hand wear and
/// chipped powder coat on the handrail, rust under the flanges, one replaced bright bolt.
public struct WheelchairRampGuard: RealAsset {
    public static let id = "wheelchair-ramp-guard"
    public static let summary = "Accessible ramp guard 3.0 m: ADA handrail at 865 mm, mid rail, 100 mm curb rail, tubular posts, extension returns."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 9, distance: 2.1)

    /// Overall length in meters.
    public var length: Float = 3.0
    /// Handrail powder coat.
    public var coat: MaterialKey = "metal.painted:34495C"
    /// Posts and intermediate rails.
    public var zinc: MaterialKey = "metal.galvanized-aged"
    /// Guard rail and curb.
    public var alu: MaterialKey = "metal.aluminum-brushed"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [make(seed: seed, lite: false), make(seed: seed, lite: true)], switchDistances: [5])
    }

    func bx(_ m: inout Model, _ size: V3, _ c: V3, _ mat: MaterialKey, r: Float = 0.002, rot: simd_quatf = .identity) {
        let x = size.x / 2, y = size.y / 2
        m.add(Prim.extrude([V2(-x, -y), V2(x, -y), V2(x, y), V2(-x, y)], depth: size.z, bevel: min(r, min(size.x, min(size.y, size.z)) * 0.3), bevelSegments: 1, material: mat),
              Xform(translation: c, rotation: rot))
    }

    /// Hex bolt head, axis along `n`.
    func hb(_ m: inout Model, at p: V3, normal n: V3, size: Float, material: MaterialKey = "metal.bolt-bright") {
        let hex = Shape2D.polygon(sides: 6, radius: size / sqrt(3))
        m.add(Prim.extrude(hex, depth: size * 0.5, bevel: size * 0.07, bevelSegments: 1, material: material),
              Xform(translation: p + simd_normalize(n) * size * 0.25, rotation: facing(n) * simd_quatf(degrees: -90, axis: V3(1, 0, 0))))
    }

    func make(seed: UInt64, lite: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let L = length
        let postX: [Float] = [-1.35, -0.45, 0.45, 1.35]
        let rP: Float = 0.0213                                    // post radius (42.6 mm pipe)
        let yH: Float = 0.865, yG: Float = 0.965                  // handrail, guard rail
        let yM: [Float] = [0.60, 0.33]                            // intermediate rails
        let postTop: Float = 0.983
        let sides = lite ? 8 : 14
        // Posts: pipe, base flange with bolts, gusset ring, domed cap.
        for (pi, x) in postX.enumerated() {
            let pm: MaterialKey = pi == 2 ? "metal.galvanized" : zinc          // one replacement post, brighter zinc
            m.add(Prim.tube([V3(x, 0.006, 0), V3(x, postTop, 0)], radii: [rP, rP], sides: sides, seamTile: 0.15, material: pm, capEnd: false))
            bx(&m, V3(0.1, 0.008, 0.05), V3(x, 0.004, 0), zinc, r: 0.0022)                       // base flange
            m.add(Prim.cylinder(radius: 0.0245, height: 0.012, bevel: 0.004, segments: lite ? 8 : 14, bevelSegments: 1, material: zinc), Xform(translation: V3(x, 0.008, 0)))   // weld collar
            if !lite {
                for dx: Float in [-0.035, 0.035] {
                    hb(&m, at: V3(x + dx, 0.008, 0.0), normal: FA.Y, size: 0.012)
                }
                // Top: domed cap.
            }
            let cap: [(Float, Float)] = [(0, postTop - 0.002), (rP + 0.0015, postTop - 0.002), (rP + 0.0025, postTop + 0.002), (rP + 0.0015, postTop + 0.006), (0.0165, postTop + 0.012), (0.009, postTop + 0.0155), (0, postTop + 0.017)]
            m.add(turned(cap, segments: lite ? 8 : 16, material: zinc, seamTile: 0.1, grainVertical: true), Xform(translation: V3(x, 0, 0)))
        }
        // Handrail with drop returns at both ends.
        let xe: Float = L / 2 - 0.02
        let hp: [V3] = [V3(-xe, yH - 0.1, 0), V3(-xe, yH - 0.06, 0), V3(-xe + 0.008, yH - 0.03, 0), V3(-xe + 0.03, yH - 0.008, 0), V3(-xe + 0.06, yH, 0), V3(-xe + 0.1, yH, 0),
                        V3(xe - 0.1, yH, 0), V3(xe - 0.06, yH, 0), V3(xe - 0.03, yH - 0.008, 0), V3(xe - 0.008, yH - 0.03, 0), V3(xe, yH - 0.06, 0), V3(xe, yH - 0.1, 0)]
        let left = catmull(Array(hp[0...5]), per: lite ? 3 : 5), right = catmull(Array(hp[6...11]), per: lite ? 3 : 5)
        let run = left + right
        FA.path(&m, run, r: 0.019, coat, sides: lite ? 10 : 16)
        // Guard rail, intermediate rails.
        FA.rod(&m, V3(-1.38, yG, 0), V3(1.38, yG, 0), r: 0.0165, alu, sides: lite ? 8 : 14)
        FA.rod(&m, V3(-1.38, yM[0], 0), V3(1.38, yM[0], 0), r: 0.0127, zinc, sides: lite ? 6 : 10)
        // Lower rail struck by a wheelchair footplate: bowed down 14 mm between two posts, kink marks at the clamps.
        var lowPts: [V3] = [V3(-1.38, yM[1], 0), V3(-1.2, yM[1], 0)]
        for k in 0...6 {
            let t = Float(k) / 6, x = -1.2 + t * 0.75
            let d = sin(t * .pi)
            lowPts.append(V3(x, yM[1] - 0.016 * d * d, 0.004 * d))
        }
        lowPts += [V3(-0.3, yM[1], 0), V3(1.38, yM[1], 0)]
        FA.path(&m, lowPts, r: 0.0127, zinc, sides: lite ? 6 : 10)
        // Bright end plugs on the guard rail and mid rails.
        for e: Float in [-1, 1] {
            m.add(Prim.cylinder(radius: 0.0172, height: 0.012, bevel: 0.003, segments: lite ? 8 : 14, bevelSegments: 1, material: "metal.satin-aluminum"), Xform(translation: V3(e * 1.38 + (e > 0 ? 0.0 : -0.012) - 0.0, yG, 0), rotation: FA.q(-90, FA.Z)))
        }
        // Saddle clamps on the handrail and guard rail, weld beads on the mid rails.
        for x in postX {
            for y in [yH, yG] as [Float] {
                bx(&m, V3(0.052, 0.036, 0.04), V3(x, y, 0), "metal.satin-aluminum", r: 0.004)
                if !lite {
                    for dx: Float in [-0.016, 0.016] {
                        hb(&m, at: V3(x + dx, y, 0.02), normal: FA.Z, size: 0.0095)
                    }
                }
            }
            if !lite {
                for y in yM {
                    for sgn: Float in [-1, 1] {
                        m.add(Prim.torus(major: 0.0135, minor: 0.0036, segments: 10, sides: 4, material: zinc), Xform(translation: V3(x + sgn * (rP + 0.002), y, 0), rotation: FA.q(90, FA.Z)))
                    }
                }
            }
        }
        // Handrail splice sleeve at mid span, with set screws.
        m.add(Prim.cylinder(radius: 0.0238, height: 0.09, bevel: 0.004, segments: lite ? 8 : 16, bevelSegments: 1, material: "metal.satin-aluminum"), Xform(translation: V3(-0.045, yH, 0), rotation: FA.q(-90, FA.Z)))
        if !lite {
            for dx: Float in [-0.02, 0.02] {
                hb(&m, at: V3(0.0 + dx, yH + 0.0236, 0), normal: FA.Y, size: 0.008)
            }
        }
        // Curb rail: 100 mm aluminum bar on the front face of the posts, top lip, yellow strip, bolts.
        let cz: Float = 0.0125
        bx(&m, V3(2.76, 0.1, 0.012), V3(0, 0.055, cz), alu, r: 0.0025)
        bx(&m, V3(2.76, 0.008, 0.012), V3(0, 0.1, cz - 0.0016), "metal.satin-aluminum", r: 0.002)
        bx(&m, V3(2.76, 0.016, 0.0014), V3(0, 0.082, cz + 0.0066), "metal.painted:D6B22A", r: 0.0004)
        if !lite {
            for x in postX {
                for y in [0.035, 0.075] as [Float] { hb(&m, at: V3(x, y + 0.005, cz + 0.006), normal: FA.Z, size: 0.0105) }
            }
        }
        // Curb butt joint with a bolted splice plate, rubber plugs on the handrail returns, maker plate on a post.
        bx(&m, V3(0.0016, 0.1, 0.0014), V3(0, 0.055, cz + 0.0066), "metal.painted:1F1F22", r: 0.0003)
        bx(&m, V3(0.16, 0.09, 0.0025), V3(0, 0.055, cz + 0.006 + 0.00125), "metal.satin-aluminum", r: 0.0012)
        for e: Float in [-1, 1] {
            m.add(Prim.cylinder(radius: 0.0198, height: 0.012, bevel: 0.0035, segments: lite ? 8 : 14, bevelSegments: 1, material: "metal.painted:141416"), Xform(translation: V3(e * xe, yH - 0.1 - 0.0115, 0)))
        }
        if !lite {
            for (dx, dy) in [(-0.06, -0.03), (0.06, -0.03), (-0.06, 0.03), (0.06, 0.03)] as [(Float, Float)] {
                hb(&m, at: V3(dx, 0.055 + dy, cz + 0.0085), normal: FA.Z, size: 0.008)
            }
            bx(&m, V3(0.05, 0.03, 0.002), V3(postX[1], 0.74, rP + 0.0008), "metal.brass-aged", r: 0.0006)
            for (dx, dy) in [(-0.02, -0.011), (0.02, -0.011), (-0.02, 0.011), (0.02, 0.011)] as [(Float, Float)] {
                m.add(Prim.cylinder(radius: 0.0022, height: 0.0012, bevel: 0.0004, segments: 6, bevelSegments: 1, material: "metal.bolt-bright"), Xform(translation: V3(postX[1] + dx, 0.74 + dy, rP + 0.0018), rotation: FA.q(90, FA.X)))
            }
        }
        // Weathering.
        if !lite {
            for x in postX {
                // Rust bloom under the flange, running onto the deck, rust weep at the weld collar.
                bx(&m, V3(0.2, 0.0010, 0.05), V3(x, 0.0, 0), "wood.deadwood", r: 0.0003)
                bx(&m, V3(0.12, 0.0012, 0.05), V3(x, 0.0, 0), "metal.rust", r: 0.0003)
                bx(&m, V3(0.1, 0.0012, 0.05), V3(x, 0.0086, 0.0), "metal.rust", r: 0.0003)
                bx(&m, V3(rng.float(0.014...0.024), rng.float(0.05...0.09), 0.0012), V3(x + rng.float(-0.012...0.012), 0.05, rP + 0.0004 + 0.0004), "metal.rust", r: 0.0003)
                // White rust streaks down the zinc.
                for _ in 0..<3 {
                    bx(&m, V3(rng.float(0.012...0.026), rng.float(0.12...0.4), 0.0012), V3(x + rng.float(-0.014...0.014), rng.float(0.25...0.8), rP + 0.0003), rng.chance(0.5) ? "stone.limestone" : "wood.deadwood", r: 0.0003)
                }
            }
            // Rust and white-rust bloom on the intermediate rails and guard rail ends.
            for y in yM {
                for _ in 0..<4 {
                    bx(&m, V3(rng.float(0.03...0.16), 0.0014, rng.float(0.012...0.022)), V3(rng.float(-1.3...1.3), y + 0.0126, 0), rng.chance(0.5) ? "metal.rust" : "stone.limestone", r: 0.0003)
                }
            }
            // Wheel scuffs, tire rubber streaks and a dent on the curb, chipped yellow strip.
            for _ in 0..<10 {
                bx(&m, V3(rng.float(0.08...0.3), rng.float(0.01...0.026), 0.0012), V3(rng.float(-1.25...1.25), rng.float(0.018...0.06), cz + 0.0067), rng.chance(0.55) ? "metal.painted:1F1F22" : "metal.steel", r: 0.0003)
            }
            for _ in 0..<8 {
                bx(&m, V3(rng.float(0.02...0.1), rng.float(0.008...0.016), 0.0012), V3(rng.float(-1.3...1.3), 0.082, cz + 0.0073), "metal.steel", r: 0.0003)   // chipped yellow
            }
            m.add(Prim.superellipsoid(V3(0.09, 0.05, 0.008), exponent: 2, subdivisions: 3, material: "metal.steel"), Xform(translation: V3(0.62, 0.05, cz + 0.0058)))
            for _ in 0..<5 {
                bx(&m, V3(rng.float(0.012...0.03), rng.float(0.02...0.05), 0.0012), V3(rng.float(-1.3...1.3), rng.float(0.02...0.07), cz + 0.0068), "metal.rust", r: 0.0003)
            }
            // Powder coat worn through where hands land, orange rust at chips, bare patches on top.
            for _ in 0..<12 {
                let x = rng.float(-1.3...1.3)
                bx(&m, V3(rng.float(0.05...0.2), 0.0014, rng.float(0.01...0.022)), V3(x, yH + 0.0188, rng.float(-0.004...0.004)), rng.chance(0.6) ? "metal.steel" : "metal.satin-aluminum", r: 0.0003)
            }
            for _ in 0..<8 {
                bx(&m, V3(rng.float(0.012...0.03), rng.float(0.012...0.03), 0.0012), V3(rng.float(-1.3...1.3), yH + rng.float(-0.012...0.012), 0.0192), "metal.rust", r: 0.0003)
            }
            // Water stain and grime on the guard rail, dirt line along the curb foot.
            for _ in 0..<6 {
                bx(&m, V3(rng.float(0.04...0.14), 0.0014, 0.012), V3(rng.float(-1.3...1.3), yG + 0.0166, 0), "stone.limestone-sooted", r: 0.0003)
            }
            bx(&m, V3(2.7, 0.008, 0.0012), V3(0, 0.006, cz + 0.0067), "wood.deadwood", r: 0.0003)
            // One replacement bright bolt on the curb.
            hb(&m, at: V3(0.45, 0.045, cz + 0.0066), normal: FA.Z, size: 0.0105, material: "metal.steel")
        }
        groundAO(&m, height: 0.3, floor: 0.5)
        return FC.place(m)
    }
}
