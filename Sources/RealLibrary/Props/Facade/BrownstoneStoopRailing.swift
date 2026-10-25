import simd
import Foundation

/// New York brownstone stoop railing, 2.6 m long, 1.0 m high, 50 mm deep: a bullnose brownstone sill, three cast-iron
/// newel posts (plinth, panelled shaft, cap block, turned acorn finials) lead-set in iron shoes, a moulded top rail over
/// an apron bar, a flat bottom rail, diamond-section wrought pickets with forged collars (every second one carrying a
/// spear head above the rail), and a centre scroll panel in each bay: a ring, a bar and four volutes. Glossy black
/// paint chipped to rust at the rail tops and shoes, rust bleed on the brownstone, one rusty replacement picket.
public struct BrownstoneStoopRailing: RealAsset {
    public static let id = "brownstone-stoop-railing"
    public static let summary = "Brownstone stoop railing 2.6 m: wrought pickets, scroll panels, flat rails, cast newels with finials, lead-set base shoes."
    public static let tags = ["prop", "architecture", "facade", "metal", "trim"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 22, elevation: 9, distance: 2.3)

    /// Run length in meters.
    public var length: Float = 2.6
    /// Black paint on the iron.
    public var iron: MaterialKey = "metal.painted:1B1C1F"
    /// Brownstone sill.
    public var stone: MaterialKey = "stone.brownstone"
    /// Picket spacing in meters.
    public var pitch: Float = 0.115
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [make(seed: seed, lite: false), make(seed: seed, lite: true)], switchDistances: [5])
    }

    /// Beveled box as an extruded rectangle.
    func bx(_ m: inout Model, _ size: V3, _ c: V3, _ mat: MaterialKey, r: Float = 0.002, rot: simd_quatf = .identity) {
        let x = size.x / 2, y = size.y / 2
        m.add(Prim.extrude([V2(-x, -y), V2(x, -y), V2(x, y), V2(-x, y)], depth: size.z, bevel: min(r, min(size.x, min(size.y, size.z)) * 0.3), bevelSegments: 1, material: mat),
              Xform(translation: c, rotation: rot))
    }

    func make(seed: UInt64, lite: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let L = length
        let sillH: Float = 0.08
        let postW: Float = 0.07
        let px: [Float] = [-L / 2 + 0.035, 0, L / 2 - 0.035]
        let yB0: Float = sillH + 0.04, yB1 = yB0 + 0.026          // bottom rail
        let yA0: Float = 0.800, yA1: Float = 0.826                 // apron bar
        let yT0: Float = 0.838                                     // top rail base
        let ironLight: MaterialKey = "metal.painted:2B2C30"
        // Brownstone sill: bullnose, drip groove, bed joints, soot.
        FA.run(&m, [V2(-0.025, 0), V2(0.025, 0), V2(0.025, 0.068), V2(0.0225, 0.0775), V2(0.017, 0.08), V2(-0.017, 0.08), V2(-0.0225, 0.0775), V2(-0.025, 0.068)], length: L, stone, bevel: 0.001)
        if !lite {
            for k in 1..<4 { bx(&m, V3(0.0025, 0.078, 0.0504), V3(-L / 2 + Float(k) * L / 4, 0.04, 0), "stone.brownstone-sooted", r: 0.0004) }
            bx(&m, V3(L - 0.04, 0.0025, 0.0016), V3(0, 0.012, 0.0246), "stone.brownstone-sooted", r: 0.0004)     // drip groove
        }
        // Posts.
        for x in px {
            let pw: Float = 0.046
            bx(&m, V3(0.074, 0.012, 0.049), V3(x, sillH + 0.006, 0), "metal.galvanized-aged", r: 0.002)               // lead-set shoe
            bx(&m, V3(postW + 0.002, 0.075, pw + 0.002), V3(x, sillH + 0.0495, 0), iron, r: 0.005)                       // plinth
            bx(&m, V3(postW - 0.003, 0.018, pw - 0.003), V3(x, sillH + 0.096, 0), iron, r: 0.004)                        // plinth step
            bx(&m, V3(postW - 0.01, 0.675, pw - 0.01), V3(x, 0.50, 0), iron, r: 0.004)                                   // shaft
            if !lite {
                for sgn: Float in [-1, 1] {
                    bx(&m, V3(postW - 0.022, 0.36, 0.0016), V3(x, 0.47, sgn * (pw - 0.01) / 2 - sgn * 0.0004), ironLight, r: 0.0005)   // raised panel
                }
                for sgn: Float in [-1, 1] {
                    bx(&m, V3(0.0016, 0.36, pw - 0.022), V3(x + sgn * ((postW - 0.01) / 2 - 0.0004), 0.47, 0), ironLight, r: 0.0005)
                }
            }
            bx(&m, V3(postW + 0.003, 0.012, pw + 0.003), V3(x, 0.857, 0), iron, r: 0.003)                                // collar ring
            bx(&m, V3(postW + 0.003, 0.04, pw + 0.003), V3(x, 0.8975, 0), iron, r: 0.004)                                // cap block
            bx(&m, V3(postW - 0.004, 0.006, pw - 0.004), V3(x, 0.9235, 0), iron, r: 0.002)
            // Turned acorn finial.
            let prof: [(Float, Float)] = [(0, 0.9265), (0.0195, 0.9265), (0.0215, 0.929), (0.0155, 0.936), (0.012, 0.943), (0.0145, 0.950), (0.0215, 0.961), (0.0245, 0.973), (0.0215, 0.985), (0.0085, 0.987), (0, 0.987)]
            m.add(turned(prof, segments: lite ? 8 : 16, material: iron, seamTile: 0.1, grainVertical: true), Xform(translation: V3(x, 0, 0)))
            m.add(Prim.superellipsoid(V3(repeating: 0.0135), exponent: 2, subdivisions: lite ? 2 : 3, material: "metal.gold-leaf"), Xform(translation: V3(x, 0.9935, 0)))
            if !lite {
                // Shoe bolts / lead pour ring.
                for (dx, dz) in [(-0.03, -0.019), (0.03, -0.019), (-0.03, 0.019), (0.03, 0.019)] as [(Float, Float)] {
                    m.add(Prim.cylinder(radius: 0.0035, height: 0.0025, bevel: 0.0006, segments: 6, bevelSegments: 1, material: "metal.bolt-bright"), Xform(translation: V3(x + dx, sillH + 0.012, dz)))
                }
            }
        }
        // Bays.
        for bay in 0..<2 {
            let xl = px[bay] + postW / 2 - 0.002, xr = px[bay + 1] - postW / 2 + 0.002
            let w = xr - xl, cx = (xl + xr) / 2
            // Top rail: bullnose profile on a flat base, bead underneath.
            let cap: [V2] = [V2(-0.0215, yT0), V2(0.0215, yT0), V2(0.0215, yT0 + 0.016), V2(0.0185, yT0 + 0.0225), V2(0.011, yT0 + 0.026), V2(-0.011, yT0 + 0.026), V2(-0.0185, yT0 + 0.0225), V2(-0.0215, yT0 + 0.016)]
            FA.run(&m, cap, length: w, at: V3(cx, 0, 0), iron, bevel: 0.0008)
            bx(&m, V3(w, 0.008, 0.036), V3(cx, yT0 - 0.004, 0), iron, r: 0.0012)
            // Apron bar and bottom rail with drip lip.
            bx(&m, V3(w, yA1 - yA0, 0.02), V3(cx, (yA0 + yA1) / 2, 0), iron, r: 0.0015)
            bx(&m, V3(w, yB1 - yB0, 0.02), V3(cx, (yB0 + yB1) / 2, 0), iron, r: 0.0015)
            bx(&m, V3(w, 0.006, 0.03), V3(cx, yB0 - 0.003, 0), iron, r: 0.0012)
            // Pickets.
            let n = Int(w / pitch)
            let step = w / Float(n)
            for i in 1..<n {
                let x = xl + Float(i) * step
                if abs(x - cx) < 0.19 { continue }
                let long = i % 2 == 0
                let top: Float = long ? 0.915 : yT0 - 0.004
                let bottomY = yB0 + 0.004
                let ph = top - bottomY
                let rusty = bay == 1 && i == 3
                let mat: MaterialKey = rusty ? "metal.rust" : (i % 5 == 0 ? ironLight : iron)
                // Diamond-section bar.
                let d: Float = 0.0088
                m.add(Prim.extrude([V2(-d, 0), V2(0, d), V2(d, 0), V2(0, -d)], depth: ph, bevel: 0.0007, bevelSegments: 1, material: mat),
                      Xform(translation: V3(x, bottomY + ph / 2, 0), rotation: FA.q(-90, FA.X)))
                // Forged collars where the bar passes through the bottom rail and apron, and a swelling.
                for cy in [yB1 + 0.014, yA0 - 0.014] as [Float] {
                    m.add(Prim.cylinder(radius: 0.0105, height: 0.012, bevel: 0.0025, segments: lite ? 6 : 10, bevelSegments: 1, material: mat), Xform(translation: V3(x, cy - 0.006, 0)))
                }
                if long {
                    // Spear head with neck ring above the cap rail.
                    m.add(Prim.cylinder(radius: 0.0095, height: 0.01, bevel: 0.002, segments: lite ? 6 : 10, bevelSegments: 1, material: mat), Xform(translation: V3(x, 0.9, 0)))
                    let leaf: [V2] = [V2(-0.005, 0), V2(0.005, 0), V2(0.0115, 0.017), V2(0.0115, 0.026), V2(0, 0.056), V2(-0.0115, 0.026), V2(-0.0115, 0.017)]
                    m.add(Prim.extrude(leaf, depth: 0.011, bevel: 0.0014, bevelSegments: 1, material: mat), Xform(translation: V3(x, 0.907, 0)))
                }
                if !lite && i % 3 == 0 {
                    // Forged swelling with fillets on every third bar.
                    m.add(turned([(0, 0.40), (0.0085, 0.40), (0.0125, 0.408), (0.0155, 0.425), (0.0155, 0.445), (0.0125, 0.462), (0.0085, 0.47), (0, 0.47)], segments: 10, material: mat, seamTile: 0.1, grainVertical: true), Xform(translation: V3(x, 0, 0)))
                }
            }
            // Scroll panel: centre bar, ring, four volutes, collars.
            let sY0 = yB1, sY1 = yA0
            bx(&m, V3(0.0125, sY1 - sY0 + 0.01, 0.0125), V3(cx, (sY0 + sY1) / 2, 0), iron, r: 0.0015)
            let ringY = (sY0 + sY1) / 2
            m.add(Prim.torus(major: 0.056, minor: 0.0078, segments: lite ? 20 : 32, sides: lite ? 5 : 7, material: iron), Xform(translation: V3(cx, ringY, 0), rotation: FA.q(90, FA.X)))
            let vR: Float = 0.088
            for (vy, vdir) in [(ringY - 0.16, Float(1)), (ringY + 0.16, Float(-1))] as [(Float, Float)] {
                for sgn: Float in [-1, 1] {
                    var pts: [V3] = []
                    let steps = lite ? 10 : 16
                    let turns: Float = 1.3
                    for k in 0...steps {
                        let t = Float(k) / Float(steps)
                        let a = (sgn > 0 ? Float.pi : 0) + vdir * sgn * t * turns * 2 * .pi
                        let r = vR * (1 - 0.86 * t)
                        let ux = cx + sgn * vR + r * cos(a)
                        pts.append(V3(ux, vy + r * sin(a), 0))
                    }
                    let c = catmull(pts, per: 2)
                    m.add(Prim.tube(c, radii: Array(repeating: 0.0078, count: c.count), sides: lite ? 4 : 6, seamTile: 0.1, material: iron, capEnd: true))
                    // Curl end bead.
                    m.add(Prim.superellipsoid(V3(repeating: 0.016), exponent: 2, subdivisions: 2, material: iron), Xform(translation: pts.last!))
                    // Forged collar where the volute leaves the bar.
                    m.add(Prim.cylinder(radius: 0.0115, height: 0.012, bevel: 0.002, segments: lite ? 6 : 8, bevelSegments: 1, material: iron), Xform(translation: V3(cx, vy - 0.006, 0)))
                }
            }
            m.add(Prim.cylinder(radius: 0.013, height: 0.009, bevel: 0.003, segments: lite ? 8 : 14, bevelSegments: 1, material: "metal.gold-leaf"), Xform(translation: V3(cx, ringY, 0.0045), rotation: FA.q(90, FA.X)))
            // Wrought C-scrolls beside the ring tie to the rails with short bars.
            for ty in [yB1 + 0.004, yA0 - 0.004] as [Float] {
                bx(&m, V3(0.02, 0.012, 0.014), V3(cx, ty, 0), iron, r: 0.002)
            }
        }
        // Weathering.
        if !lite {
            func patch(_ c: V3, _ w: Float, _ h: Float, _ mat: MaterialKey) {
                var poly: [V2] = []
                for j in 0..<8 { let a = Float(j) / 8 * 2 * .pi; poly.append(V2(cos(a) * w * rng.float(0.55...1.1), sin(a) * h * rng.float(0.55...1.1))) }
                m.add(HTKit.plate(outer: poly, depth: 0.0008, bevel: 0.0002, segments: 1, material: mat), Xform(translation: c))
            }
            // Paint worn through on the top rail crown and posts' caps.
            for _ in 0..<12 {
                let x = rng.float(-L / 2 + 0.1...L / 2 - 0.1)
                bx(&m, V3(rng.float(0.03...0.12), 0.0012, rng.float(0.006...0.014)), V3(x, yT0 + 0.0261, rng.float(-0.004...0.004)), rng.chance(0.6) ? "metal.steel" : "metal.rust", r: 0.0003)
            }
            for x in px {
                bx(&m, V3(0.03, 0.0012, 0.03), V3(x + rng.float(-0.003...0.003), 0.9176, rng.float(-0.003...0.003)), "metal.rust", r: 0.0003)
                // Rust bleed down the plinth and onto the brownstone.
                bx(&m, V3(0.026, 0.0012, 0.03), V3(x, sillH + 0.0002, 0.0), "metal.rust", r: 0.0003)
                bx(&m, V3(rng.float(0.01...0.02), rng.float(0.04...0.08), 0.0012), V3(x + rng.float(-0.012...0.012), sillH - 0.03, 0.0255), "metal.rust", r: 0.0003)
                bx(&m, V3(rng.float(0.012...0.03), rng.float(0.03...0.07), 0.0012), V3(x + rng.float(-0.015...0.015), sillH + 0.08, 0.0245), "metal.rust", r: 0.0003)
            }
            // Flaked paint on the shafts and rails, soot streaks on the sill.
            for _ in 0..<10 {
                let x = rng.float(-L / 2 + 0.08...L / 2 - 0.08)
                bx(&m, V3(rng.float(0.01...0.03), rng.float(0.01...0.03), 0.0012), V3(x, rng.float(yB0...yA1), 0.0106), rng.chance(0.5) ? "metal.rust" : "metal.steel", r: 0.0003)
            }
            for _ in 0..<5 {
                let x = rng.float(-L / 2 + 0.1...L / 2 - 0.1)
                bx(&m, V3(rng.float(0.04...0.14), rng.float(0.01...0.03), 0.0012), V3(x, 0.04, 0.0252), "stone.brownstone-sooted", r: 0.0003)
            }
            // Shoe corrosion.
            for x in px { bx(&m, V3(0.05, 0.0012, 0.05), V3(x, sillH + 0.0126, 0), "metal.rust", r: 0.0003) }
            patch(V3(0, sillH + 0.0001, 0.0), 0.002, 0.002, "metal.rust")
        }
        groundAO(&m, height: 0.12, floor: 0.7)
        return FC.place(m)
    }
}
