import simd
import Foundation

/// Industrial exterior steel stair, 4.0 m run, 2.0 m rise: two bolted C-channel stringers on concrete footings, ten pan
/// treads (turned-down lips, raised anti-slip ribs, yellow nosing strip) on clip angles, a 0.9 m landing on a perimeter
/// angle frame with channel joists, two square-tube columns on base plates with anchor bolts and turnbuckle X-bracing,
/// a wall ledger angle, and pipe handrails with mid rail, balusters and posts on both sides. Galvanized steel dulled
/// to white rust, rust runs under the bolts, one new bright replacement tread, worn blue-grey rail paint.
public struct ExteriorSteelStairFlight: RealAsset {
    public static let id = "exterior-steel-stair-flight"
    public static let summary = "Exterior steel stair, 4.0 m run, 2.0 m rise: channel stringers, pan treads, landing on columns, pipe handrails."
    public static let tags = ["prop", "architecture", "facade", "metal", "urban"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 12, distance: 7.0)

    /// Landing height in meters.
    public var rise: Float = 2.0
    /// Number of risers up to the landing.
    public var risers = 11
    /// Tread going (horizontal depth) in meters.
    public var going: Float = 0.31
    /// Weathered galvanized steel.
    public var zinc: MaterialKey = "metal.galvanized-aged"
    /// Handrail paint.
    public var rail: MaterialKey = "metal.painted:34495E"
    /// Rust.
    public var rust: MaterialKey = "metal.rust"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [make(seed: seed, lite: false), make(seed: seed, lite: true)], switchDistances: [8])
    }

    /// Rectangle (x by y) extruded `z` deep, centred at `c`, rotated about Z by `deg`.
    func bx(_ m: inout Model, _ x: Float, _ y: Float, _ z: Float, at c: V3, deg: Float = 0, _ mat: MaterialKey, bevel: Float = 0.0015) {
        m.add(Prim.extrude([V2(-x / 2, -y / 2), V2(x / 2, -y / 2), V2(x / 2, y / 2), V2(-x / 2, y / 2)], depth: z, bevel: min(bevel, min(x, min(y, z)) * 0.3), bevelSegments: 1, material: mat),
              Xform(translation: c, rotation: FA.q(deg, FA.Z)))
    }

    func make(seed: UInt64, lite: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let ri = rise / Float(risers), g = going
        let nT = risers - 1
        let x0: Float = -2.0, x1 = x0 + Float(nT) * g, x2: Float = 1.95       // stair start, landing front, wall face
        let sz: Float = 0.52, pz: Float = 0.545                              // stringer web z, rail post z
        let pitch = atan2(ri, g) * 180 / .pi
        let slope = ri / g
        let pad: Float = 0.025
        func yN(_ x: Float) -> Float { ri + slope * (x - x0) }               // nose line
        let railH: Float = 0.975
        let replaced = 4
        // Footings.
        for e: Float in [-1, 1] {
            bx(&m, 0.55, pad, 0.14, at: V3(x0 + 0.22, pad / 2, e * sz), "stone.cast-stone", bevel: 0.003)
        }
        // Stringers: C channel, web plate with the flanges turned inward.
        let tx: Float = 0.26                                                         // channel depth
        let yt0 = yN(x0) - 0.03, yt1 = yN(x1) - 0.03
        let xa = x0 + (tx - yt0 + pad) / slope
        for e: Float in [-1, 1] {
            let web = [V2(x0, pad), V2(xa, pad), V2(x1, yt1 - tx), V2(x1, yt1), V2(x0, yt0)]
            m.add(Prim.extrude(web, depth: 0.008, bevel: 0.0015, bevelSegments: 1, material: zinc), Xform(translation: V3(0, 0, e * sz)))
            // Top and bottom flanges.
            let dxT: Float = x1 - x0, dyT: Float = yt1 - yt0
            let len: Float = sqrt(dxT * dxT + dyT * dyT)
            bx(&m, len, 0.006, 0.065, at: V3((x0 + x1) / 2, (yt0 + yt1) / 2 - 0.003, e * (sz - 0.0365)), deg: pitch, zinc, bevel: 0.0012)
            let dxB: Float = x1 - xa, dyB: Float = yt1 - tx - pad
            let lenB: Float = sqrt(dxB * dxB + dyB * dyB)
            bx(&m, lenB, 0.006, 0.065, at: V3((xa + x1) / 2, (pad + yt1 - tx) / 2 + 0.003, e * (sz - 0.0365)), deg: pitch, zinc, bevel: 0.0012)
            // Toe plate across the foot.
            bx(&m, 0.006, yt0 - pad, 0.065, at: V3(x0 + 0.003, (yt0 + pad) / 2, e * (sz - 0.0365)), zinc, bevel: 0.001)
            // Base angle with anchor bolts.
            bx(&m, 0.08, 0.008, 0.14, at: V3(x0 + 0.04, pad + 0.004, e * sz), zinc, bevel: 0.0015)
            if !lite {
                for dz: Float in [-0.045, 0.045] { FA.cylZ(&m, r: 0.0075, h: 0.012, at: V3(x0 + 0.04, pad + 0.008, e * sz + dz), "metal.bolt-bright", bevel: 0.0012, segments: 6) }
            }
        }
        // Splice plates bolted across the stringer webs.
        if !lite {
            for e: Float in [-1, 1] {
                for sx in [x0 + 1.25, x0 + 2.35] {
                    let yc = yN(sx) - 0.16
                    bx(&m, 0.34, 0.2, 0.006, at: V3(sx, yc, e * (sz + 0.007)), deg: pitch, zinc, bevel: 0.0015)
                    for (dx, dy) in [(-0.11, -0.06), (0.0, -0.06), (0.11, -0.06), (-0.11, 0.06), (0.0, 0.06), (0.11, 0.06)] as [(Float, Float)] {
                        let c = V3(sx + dx * cos(pitch * .pi / 180) - dy * sin(pitch * .pi / 180), yc + dx * sin(pitch * .pi / 180) + dy * cos(pitch * .pi / 180), e * (sz + 0.0105) + (e < 0 ? -0.004 : 0))
                        FA.cylZ(&m, r: 0.0075, h: 0.004, at: c, "metal.bolt-bright", bevel: 0, segments: 6)
                    }
                }
            }
        }
        // Treads.
        for i in 0..<nT {
            let xc = x0 + (Float(i) + 0.5) * g, top = Float(i + 1) * ri
            let mat: MaterialKey = i == replaced ? "metal.galvanized" : zinc
            bx(&m, g + 0.03, 0.012, 2 * (sz - 0.004) - 0.01, at: V3(xc - 0.005, top - 0.006, 0), mat, bevel: 0.002)       // pan top
            bx(&m, 0.007, 0.034, 2 * (sz - 0.004) - 0.01, at: V3(xc - g / 2 - 0.016, top - 0.025, 0), mat, bevel: 0.0015)   // front lip
            bx(&m, 0.007, 0.03, 2 * (sz - 0.004) - 0.01, at: V3(xc + g / 2 + 0.009, top - 0.022, 0), mat, bevel: 0.0015)    // rear lip
            bx(&m, 0.038, 0.005, 2 * (sz - 0.004) - 0.02, at: V3(xc - g / 2 - 0.004, top + 0.0025, 0), i == replaced ? "metal.painted:D8B53A" : "metal.painted:B89A3C", bevel: 0.001) // nosing strip
            if !lite {
                for k in 0..<3 {
                    bx(&m, 0.012, 0.0045, 2 * (sz - 0.004) - 0.06, at: V3(xc - 0.07 + Float(k) * 0.085, top + 0.0022, 0), mat, bevel: 0.0008)
                }
                // Clip angles and bolts on the stringer web outer face.
                for e: Float in [-1, 1] {
                    bx(&m, 0.05, 0.05, 0.004, at: V3(xc - 0.07, top - 0.05, e * (sz + 0.006)), mat, bevel: 0.001)
                    for dx: Float in [-0.015, 0.015] { FA.cylZ(&m, r: 0.0058, h: 0.004, at: V3(xc - 0.07 + dx, top - 0.05, e * (sz + 0.008) - (e < 0 ? 0.004 : 0)), "metal.bolt-bright", bevel: 0, segments: 6) }
                }
            }
        }
        // Landing: perimeter angle frame, plate, joists, columns with X-bracing, wall ledger.
        let lc = (x1 + x2) / 2, lw = x2 - x1
        let ly = rise
        bx(&m, lw, 0.012, 2 * pz, at: V3(lc, ly - 0.006, 0), zinc, bevel: 0.002)                                         // landing plate
        for e: Float in [-1, 1] { bx(&m, lw, 0.1, 0.008, at: V3(lc, ly - 0.062, e * sz), zinc, bevel: 0.0015) }          // side rim channels
        bx(&m, 0.008, 0.1, 2 * sz, at: V3(x1 + 0.004, ly - 0.062, 0), zinc, bevel: 0.0015)                                // front rim
        bx(&m, 0.04, 0.005, 2 * pz - 0.02, at: V3(x1 + 0.016, ly + 0.0025, 0), "metal.painted:B89A3C", bevel: 0.001)      // landing nosing strip
        for jx: Float in [0.25, 0.5, 0.75] { bx(&m, 0.05, 0.08, 2 * sz - 0.02, at: V3(x1 + lw * jx, ly - 0.052, 0), zinc, bevel: 0.0015) }
        if !lite {
            for k in 0..<3 { bx(&m, lw - 0.1, 0.0045, 0.012, at: V3(lc, ly + 0.0022, -0.3 + Float(k) * 0.3), zinc, bevel: 0.0008) }
        }
        // Wall ledger angle with bolts.
        bx(&m, 0.01, 0.1, 2 * pz, at: V3(x2 - 0.005, ly - 0.062, 0), zinc, bevel: 0.0015)
        if !lite {
            for k in 0..<6 {
                let z = -0.45 + Float(k) * 0.18
                m.add(Prim.cylinder(radius: 0.012, height: 0.01, bevel: 0.0015, segments: 6, bevelSegments: 1, material: "metal.bolt-bright"), Xform(translation: V3(x2 - 0.012, ly - 0.06, z), rotation: FA.q(90, FA.Z)))
            }
        }
        // Columns on base plates.
        let cx = x1 + 0.1
        for e: Float in [-1, 1] {
            let z = e * 0.42
            m.add(Prim.extrude([V2(-0.045, -0.045), V2(0.045, -0.045), V2(0.045, 0.045), V2(-0.045, 0.045)], depth: ly - 0.06 - pad - 0.012, bevel: 0.003, bevelSegments: 1, material: zinc),
                  Xform(translation: V3(cx, pad + 0.012 + (ly - 0.06 - pad - 0.012) / 2, z), rotation: FA.q(90, FA.X)))
            bx(&m, 0.16, 0.012, 0.16, at: V3(cx, pad + 0.006, z), zinc, bevel: 0.0025)
            bx(&m, 0.22, 0.025, 0.22, at: V3(cx, pad / 2 - 0.0, z), "stone.cast-stone", bevel: 0.003)
            if !lite {
                for (dx, dz) in [(-0.058, -0.058), (0.058, -0.058), (-0.058, 0.058), (0.058, 0.058)] as [(Float, Float)] {
                    m.add(Prim.cylinder(radius: 0.0085, height: 0.014, bevel: 0.0015, segments: 6, bevelSegments: 1, material: "metal.bolt-bright"), Xform(translation: V3(cx + dx, pad + 0.012, z + dz)))
                }
                // Cap plate and bolted knee gusset at the beam.
                bx(&m, 0.14, 0.01, 0.14, at: V3(cx, ly - 0.065, z), zinc, bevel: 0.002)
            }
        }
        // Cross-bracing between the columns (rods with a turnbuckle).
        let b0 = V3(cx, pad + 0.2, -0.42), b1 = V3(cx, ly - 0.16, 0.42), b2 = V3(cx, pad + 0.2, 0.42), b3 = V3(cx, ly - 0.16, -0.42)
        FA.rod(&m, b0, b1, r: 0.0115, zinc, sides: lite ? 5 : 7)
        FA.rod(&m, b2, b3, r: 0.0115, zinc, sides: lite ? 5 : 7)
        if !lite {
            for (a, b) in [(b0, b1), (b2, b3)] {
                let mid = (a + b) / 2
                let q = simd_quatf(from: V3(0, 1, 0), to: simd_normalize(b - a))
                m.add(Prim.cylinder(radius: 0.0165, height: 0.09, bevel: 0.003, segments: 8, bevelSegments: 1, material: zinc),
                      Xform(translation: mid - q.act(V3(0, 0.045, 0)), rotation: q))
            }
        }
        // Handrails, mid rails, posts and balusters on both sides.
        func railY(_ x: Float, _ h: Float) -> Float { x < x1 ? yN(x) + h : rise + h }
        func baseY(_ x: Float) -> Float { x < x1 ? (yN(x) - 0.03) - 0.1 : ly - 0.1 }
        for e: Float in [-1, 1] {
            let z = e * pz
            func path(_ h: Float) -> [V3] {
                var pts: [V3] = [V3(x0 + 0.02, yN(x0 + 0.02) + h, z)]
                var x = x0 + 0.02
                while x < x1 - 0.3 { x += g * 2; pts.append(V3(min(x, x1 - 0.3), yN(min(x, x1 - 0.3)) + h, z)) }
                pts += [V3(x1 - 0.12, yN(x1 - 0.12) + h + 0.02, z), V3(x1 + 0.02, rise + h - 0.004, z), V3(x1 + 0.2, rise + h, z), V3(x2 - 0.06, rise + h, z)]
                return pts
            }
            let hp = catmull(path(railH), per: lite ? 2 : 3)
            m.add(Prim.tube(hp, radii: Array(repeating: 0.0215, count: hp.count), sides: lite ? 8 : 10, seamTile: 0.15, material: rail, capEnd: true))
            let mp = catmull(path(railH * 0.5), per: 2)
            m.add(Prim.tube(mp, radii: Array(repeating: 0.0125, count: mp.count), sides: lite ? 5 : 7, seamTile: 0.15, material: rail, capEnd: true))
            // Posts: heavy pipe with a bolted flange at the stringer, every third tread and at the landing corners.
            let postX: [Float] = [x0 + 0.08, x0 + 3.5 * g, x0 + 6.5 * g, x0 + 9.5 * g, x1 + 0.1, x2 - 0.08]
            for px in postX {
                let b = baseY(px), t = railY(px, railH) - 0.02
                m.add(Prim.tube([V3(px, b, z), V3(px, t, z)], radii: [0.0185, 0.0185], sides: lite ? 6 : 8, seamTile: 0.15, material: rail, capEnd: true))
                if !lite {
                    bx(&m, 0.07, 0.1, 0.006, at: V3(px, b + 0.05, z - e * 0.0), zinc, bevel: 0.001)
                    FA.cylZ(&m, r: 0.0055, h: 0.004, at: V3(px - 0.02, b + 0.035, z + e * 0.003), "metal.bolt-bright", bevel: 0, segments: 6)
                    FA.cylZ(&m, r: 0.0055, h: 0.004, at: V3(px + 0.02, b + 0.065, z + e * 0.003), "metal.bolt-bright", bevel: 0, segments: 6)
                }
            }
            // Balusters.
            var x = x0 + 0.17
            var bi = 0
            while x < x2 - 0.1 {
                if !postX.contains(where: { abs($0 - x) < 0.05 }) {
                    let mat: MaterialKey = (bi == 11 && e > 0) ? "metal.rust" : rail
                    m.add(Prim.tube([V3(x, baseY(x) + 0.02, z), V3(x, railY(x, railH) - 0.02, z)], radii: [0.0075, 0.0075], sides: lite ? 4 : 5, seamTile: 0.15, material: mat, capEnd: false))
                }
                x += 0.115; bi += 1
            }
            if !lite {
                for p in [hp.first!, hp.last!] { m.add(Prim.superellipsoid(V3(0.05, 0.05, 0.05), exponent: 2, subdivisions: 3, material: rail), Xform(translation: p)) }
            }
        }
        // Weathering.
        if !lite {
            func bloom(_ cx: Float, _ cz: Float, _ rx: Float, _ rz: Float, y: Float, _ mat: MaterialKey) {
                var poly: [V2] = []
                for j in 0..<8 { let t = Float(j) / 8 * 2 * .pi; poly.append(V2(cx + cos(t) * rx * rng.float(0.55...1.1), cz + sin(t) * rz * rng.float(0.55...1.1))) }
                m.add(HTKit.plate(outer: poly, depth: 0.0008, bevel: 0.0002, segments: 1, material: mat), Xform(translation: V3(0, y, 0), rotation: FA.q(90, FA.X)))
            }
            for i in 0..<nT {
                let xc = x0 + (Float(i) + 0.5) * g, top = Float(i + 1) * ri
                bloom(xc - g / 2 + rng.float(0.0...0.05), rng.float(-0.4...0.4), rng.float(0.03...0.09), rng.float(0.03...0.07), y: top + 0.006, rng.chance(0.7) ? rust : "metal.galvanized")
                if i % 2 == 0 { bloom(xc + rng.float(-0.05...0.05), rng.float(-0.38...0.38), rng.float(0.03...0.07), rng.float(0.04...0.08), y: top + 0.006, "wood.deadwood") }
            }
            for i in 0..<4 {
                let top = Float(i + 1) * ri
                bloom(x0 + (Float(i) + 0.5) * g, rng.float(-0.3...0.3), 0.14, rng.float(0.2...0.4), y: top + 0.0058, "wood.deadwood")
            }
            for e: Float in [-1, 1] {
                bx(&m, 0.0915, 0.11, 0.0915, at: V3(cx, pad + 0.07, e * 0.42), rust, bevel: 0.003)
                bx(&m, 0.0925, 0.05, 0.0925, at: V3(cx, pad + 0.15, e * 0.42), "wood.deadwood", bevel: 0.003)
            }
            for _ in 0..<5 { bloom(rng.float(x1 + 0.1...x2 - 0.1), rng.float(-0.45...0.45), rng.float(0.05...0.12), rng.float(0.05...0.1), y: rise + 0.0056, rng.chance(0.6) ? rust : "metal.galvanized") }
            // Rust runs down the stringer webs below the clip bolts, and on the base angles.
            for e: Float in [-1, 1] {
                for _ in 0..<12 {
                    let x = rng.float(x0 + 0.3...x1 - 0.1)
                    bx(&m, rng.float(0.012...0.03), rng.float(0.06...0.16), 0.0012, at: V3(x, yN(x) - 0.15 - rng.float(0.0...0.06), e * (sz + 0.0045)), rust, bevel: 0.0003)
                }
                bx(&m, 0.1, 0.012, 0.15, at: V3(x0 + 0.04, pad + 0.002, e * sz), rust, bevel: 0.002)
                bx(&m, 0.22, 0.003, 0.22, at: V3(cx, pad + 0.0002, e * 0.42), rust, bevel: 0.001)
            }
            // Chips down to bare steel on the handrail where hands land.
            for k in 0..<12 {
                let x = rng.float(x0 + 0.3...x2 - 0.2), e: Float = k % 2 == 0 ? -1 : 1
                m.add(Prim.superellipsoid(V3(0.04, 0.008, 0.03), exponent: 2, subdivisions: 2, material: rust), Xform(translation: V3(x, railY(x, railH) + 0.0185, e * pz), rotation: FA.q(x < x1 ? pitch : 0, FA.Z)))
            }
        }
        groundAO(&m, height: 0.25, floor: 0.75)
        return FC.place(m.transformed(Xform(rotation: FA.q(90, FA.Y))))
    }
}
