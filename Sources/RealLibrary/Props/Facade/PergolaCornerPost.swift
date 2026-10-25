import simd
import Foundation

/// Craftsman pergola corner post, 2.4 m: a battered four-course fieldstone pier with a chamfered cast-stone cap slab,
/// an iron strap base standing 18 mm off the slab on four pins, a tapered cedar post with chamfered arrises and raised
/// face battens, a stacked capital (neck cove, bolster, ogee, abacus) carrying two notched beam stubs bolted through
/// with carriage bolts. Weathered cedar has checks, water streaks under the cap and grey end grain, the stone is
/// sooted with moss at the base, iron bolts bleed rust.
public struct PergolaCornerPost: RealAsset {
    public static let id = "pergola-corner-post"
    public static let summary = "Craftsman pergola corner post, 2.4 m: tapered cedar post with batten faces on a coursed stone pier, iron strap base, moulded capital and beam stubs."
    public static let tags = ["prop", "architecture", "facade", "wood", "stone"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 38, elevation: 6, distance: 2.3)

    /// Post timber.
    public var timber: MaterialKey = "wood.lumber-oak"
    /// Battens and mouldings.
    public var trim: MaterialKey = "wood.painted-shaker-worn:4A5640"
    /// Pier stone.
    public var stone: MaterialKey = "stone.wall-block"
    /// Cap slab stone.
    public var capStone: MaterialKey = "stone.cast-stone:B1AB9E"
    /// Strap base iron.
    public var iron: MaterialKey = "metal.wrought-iron"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [make(seed: seed, lite: false), make(seed: seed, lite: true)], switchDistances: [7])
    }

    /// Square outline with chamfered arrises, CCW.
    func chamfered(_ w: Float, _ c: Float) -> [V2] {
        let h = w / 2
        return [V2(-h + c, -h), V2(h - c, -h), V2(h, -h + c), V2(h, h - c), V2(h - c, h), V2(-h + c, h), V2(-h, h - c), V2(-h, -h + c)]
    }

    /// Lofts chamfered squares given (y, width, chamfer) stations, grain running along the height.
    func column(_ stations: [(Float, Float, Float)], _ mat: MaterialKey, cap: Bool = true) -> Surface {
        var s = Prim.loft(stations.map { Prim.ring(chamfered($0.1, $0.2), y: $0.0) }, capStart: cap, capEnd: cap, material: mat)
        s.uvs = s.uvs.map { V2($0.y, $0.x) }
        s.computeTangents()
        return s
    }

    func make(seed: UInt64, lite: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let courses: [Float] = [0.125, 0.11, 0.12, 0.105]
        let hw0: Float = 0.097, taper: Float = 0.003
        let stoneMats: [MaterialKey] = ["stone.wall-block:9A9488", "stone.wall-block:7F796E", "stone.wall-block:A8A092", "stone.wall-block:8A8478"]
        // Mortar core.
        var y: Float = 0
        for (i, h) in courses.enumerated() {
            let hw = hw0 - Float(i) * taper
            FA.box(&m, V3(hw * 2 - 0.016, h, hw * 2 - 0.016), V3(0, y + h / 2, 0), "stone.limestone-sooted:7D776B", r: 0.002)
            // Stones: two per face, quoins alternate which faces run through the corner.
            let tk: Float = 0.026
            for face in 0..<4 {
                let along = face % 2 == 0 ? (i % 2 == 0) : (i % 2 == 1)
                let len = along ? hw * 2 : hw * 2 - tk * 2 + 0.004
                let gap: Float = 0.009
                let a = rng.float(0.38...0.62)
                let lens = [len * a - gap / 2, len * (1 - a) - gap / 2]
                var cursor = -len / 2
                for (k, l) in lens.enumerated() {
                    let hh = h - 0.012 + rng.float(-0.012...0.004)
                    let depth = tk + rng.float(-0.006...0.005)
                    let c = cursor + l / 2
                    cursor += l + gap
                    let out = hw - depth / 2 + 0.0015 + rng.float(-0.002...0.002)
                    var size = V3(l, hh, depth)
                    var pos = V3(c, y + h / 2 + rng.float(-0.002...0.002), out)
                    let rot = simd_quatf(angle: Float(face) * .pi / 2, axis: FA.Y)
                    pos = rot.act(pos)
                    if face % 2 == 1 { size = V3(l, hh, depth) }
                    let mat: MaterialKey = i == 0 && rng.chance(0.6) ? (rng.chance(0.5) ? "stone.wall-block:56653F" : "stone.wall-block:5A554C") : (i == 1 && rng.chance(0.2) ? "stone.wall-block:6A7550" : stoneMats[(i + k + face) % 4])
                    m.add(Prim.roundedBox(size, radius: rng.float(0.005...0.009), bevelSegments: 1, material: mat), Xform(translation: pos, rotation: rot))
                }
            }
            y += h
        }
        // Cap slab with drip chamfer, grout bed under it.
        let slabY: Float = 0.462
        FA.box(&m, V3(0.19, 0.004, 0.19), V3(0, slabY - 0.002, 0), "stone.limestone-sooted", r: 0.001)
        m.add(Prim.extrude(Shape2D.rect(0.2, 0.2), depth: 0.038, bevel: 0.011, bevelSegments: 2, material: capStone), Xform(translation: V3(0, slabY + 0.019, 0), rotation: FA.q(90, FA.X)))
        let slabTop = slabY + 0.038
        // Iron strap base: plate on four pins, two side straps bolted through the post.
        let plateY = slabTop + 0.003
        FA.box(&m, V3(0.13, 0.006, 0.13), V3(0, plateY + 0.003, 0), iron, r: 0.0015)
        for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
            m.add(Prim.cylinder(radius: 0.0055, height: 0.018, bevel: 0.0008, segments: lite ? 6 : 8, bevelSegments: 1, material: "metal.galvanized-aged"), Xform(translation: V3(sx * 0.047, plateY + 0.006, sz * 0.047)))
            hexBolt(&m, at: V3(sx * 0.056, plateY + 0.006, sz * 0.056), normal: FA.Y, size: 0.011, material: "metal.bolt-bright")
        }}
        let postBot = plateY + 0.006 + 0.018
        let postTop: Float = 2.1
        let wB: Float = 0.14, wT: Float = 0.118
        func pw(_ yy: Float) -> Float { wB + (wT - wB) * (yy - postBot) / (postTop - postBot) }
        // Three timber lengths so wear differs: dark splash zone, stained mid span, sun-greyed top.
        m.add(column([(postBot, wB * 0.96, 0.012), (postBot + 0.006, wB, 0.012), (0.95, pw(0.95), 0.0125)], "wood.lumber-oak:3E2C1C"))
        m.add(column([(0.95, pw(0.95), 0.0125), (1.85, pw(1.85), 0.013)], "wood.lumber-oak:8A6A48", cap: false))
        m.add(column([(1.85, pw(1.85), 0.013), (postTop, wT, 0.013)], "wood.lumber-oak:9C855F"))
        // End grain cap on the post foot (stained dark) and top seat.
        FA.box(&m, V3(wB * 0.9, 0.003, wB * 0.9), V3(0, postBot - 0.0005, 0), "wood.weathered", r: 0.001)
        // Side straps up the post with bolts and washers.
        for sx: Float in [-1, 1] {
            FA.box(&m, V3(0.005, 0.2, 0.06), V3(sx * (pw(postBot + 0.1) / 2 + 0.0035), postBot + 0.1, 0), iron, r: 0.0012)
            FA.box(&m, V3(0.005, 0.016, 0.13 - 0.06 + 0.06), V3(sx * 0.0655, plateY + 0.01, 0), iron, r: 0.0012)
            for dy: Float in [0.05, 0.15] {
                let p = V3(sx * (pw(postBot + dy) / 2 + 0.006), postBot + dy, 0)
                m.add(Prim.cylinder(radius: 0.0085, height: 0.0015, bevel: 0.0003, segments: lite ? 8 : 12, bevelSegments: 1, material: iron), Xform(translation: p, rotation: FA.q(-sx * 90, FA.Z)))
                bolt(&m, p + V3(sx * 0.0015, 0, 0), V3(sx, 0, 0), 0.014, lite: lite)
            }
        }
        // Post base moulding: chamfered plinth block with a cove stop.
        m.add(column([(postBot + 0.2, 0.156, 0.008), (postBot + 0.21, 0.15, 0.008), (postBot + 0.255, 0.15, 0.008), (postBot + 0.268, 0.146, 0.006)], trim))
        m.add(column([(postBot + 0.268, 0.146, 0.006), (postBot + 0.275, pw(postBot + 0.275) + 0.004, 0.012)], trim, cap: false))
        // Face battens (raised, chamfered) on four faces, following the taper, with a shadow groove either side.
        let bY0: Float = 0.95, bY1: Float = 1.82
        let bw: Float = 0.06, bt: Float = 0.009
        let lean = atan((wB - wT) / 2 / (postTop - postBot))
        for face in 0..<4 {
            let rot = simd_quatf(angle: Float(face) * .pi / 2, axis: FA.Y)
            let yc = (bY0 + bY1) / 2
            let zc = pw(yc) / 2 + bt / 2 - 0.001
            let outline = Shape2D.rounded(Shape2D.rect(bw, bY1 - bY0), radius: 0.004, segments: 1)
            // Batten tilts with the post face (top leans in, toward -Z of the local face).
            m.add(Prim.extrude(outline, depth: bt, bevel: 0.0028, bevelSegments: 1, material: face % 2 == 0 ? "wood.walnut-oiled" : "wood.walnut-oiled:5A4430"),
                  Xform(translation: rot.act(V3(0, yc, zc)), rotation: rot * simd_quatf(angle: -lean, axis: FA.X)))
        }
        // Capital: neck cove, bolster, ogee overhang, abacus.
        let c0 = postTop
        m.add(column([(c0 - 0.004, wT, 0.013), (c0 + 0.004, wT + 0.004, 0.011), (c0 + 0.012, 0.13, 0.009), (c0 + 0.02, 0.15, 0.008)], trim, cap: false))
        m.add(column([(c0 + 0.02, 0.15, 0.008), (c0 + 0.021, 0.156, 0.008), (c0 + 0.058, 0.156, 0.008), (c0 + 0.06, 0.15, 0.007)], trim))
        let ogee: [(Float, Float)] = [(0.0, 0.15), (0.004, 0.158), (0.01, 0.17), (0.018, 0.186), (0.028, 0.196), (0.032, 0.2)]
        m.add(column(ogee.map { (c0 + 0.06 + $0.0, $0.1, 0.009) }, trim))
        let absY = c0 + 0.06 + 0.032
        FA.box(&m, V3(0.2, 0.034, 0.2), V3(0, absY + 0.017, 0), "wood.lumber-oak:6B5238", r: 0.007)
        // Beam stubs: lower along X, upper along Z, notched tails with bevelled top corners.
        let bmY = absY + 0.034
        func tail(_ len: Float, _ h: Float) -> [V2] {
            // Craftsman rafter tail: deep 45 degree top cuts, small bottom chamfers, stepped shoulder.
            let l = len / 2, t = h / 2, c: Float = 0.036, d: Float = 0.012
            return Shape2D.rounded([V2(-l + d, -t), V2(l - d, -t), V2(l, -t + d), V2(l, t - c), V2(l - c, t), V2(-l + c, t), V2(-l, t - c), V2(-l, -t + d)], radius: 0.003, segments: 1)
        }
        m.add(Prim.extrude(tail(0.2, 0.09), depth: 0.09, bevel: 0.004, bevelSegments: 1, material: "wood.lumber-oak:6B4F36"), Xform(translation: V3(0, bmY + 0.045, 0)))
        m.add(Prim.extrude(tail(0.2, 0.09), depth: 0.09, bevel: 0.004, bevelSegments: 1, material: "wood.lumber-oak:50392A"), Xform(translation: V3(0, bmY + 0.09 + 0.045 + 0.001, 0), rotation: FA.q(90, FA.Y)))
        // Carriage bolts through the beam stubs with square washers.
        for (k, yy) in [bmY + 0.045, bmY + 0.136].enumerated() {
            let face: Float = 0.046
            for sgn: Float in [0] {
                let p = k == 0 ? V3(0.03 * sgn, yy, face) : V3(face, yy, 0.03 * sgn)
                let n = k == 0 ? V3(0, 0, 1) : V3(1, 0, 0)
                FA.box(&m, k == 0 ? V3(0.026, 0.026, 0.003) : V3(0.003, 0.026, 0.026), p, iron, r: 0.0006)
                m.add(Prim.superellipsoid(V3(0.016, 0.016, 0.006), exponent: 2, subdivisions: lite ? 1 : 2, material: "metal.bolt-bright"), Xform(translation: p + n * 0.0015, rotation: facing(n) * simd_quatf(angle: -.pi / 2, axis: V3(1, 0, 0))))
            }
        }
        // Paint chips at moulding arrises and on the bolster face, bare grey wood showing.
        if !lite {
            for _ in 0..<10 {
                let rot = simd_quatf(angle: Float(rng.int(0...3)) * .pi / 2, axis: FA.Y)
                let yy = rng.chance(0.5) ? postBot + 0.2 + rng.float(0.0...0.06) : postTop + 0.021 + rng.float(0.0...0.036)
                let hw: Float = yy < 1 ? 0.075 : 0.078
                FA.box(&m, V3(rng.float(0.012...0.03), rng.float(0.006...0.014), 0.0012), rot.act(V3(rng.float(-0.06...0.06), yy, hw + 0.0008)), "wood.weathered", r: 0.0003, rot: rot)
            }
        }
        // Wear: checks along the grain, grey streaks under the cap, rust runs below bolts, moss and soot on the pier.
        if !lite {
            for _ in 0..<14 {
                let face = rng.int(0...3)
                let rot = simd_quatf(angle: Float(face) * .pi / 2, axis: FA.Y)
                let yy = rng.float(0.7...2.0), xx = rng.float(-0.045...0.045)
                let hh = rng.float(0.08...0.38)
                m.add(Prim.extrude(Shape2D.rect(rng.float(0.0016...0.003), hh), depth: 0.0012, bevel: 0.0003, bevelSegments: 1, material: "wood.charred"),
                      Xform(translation: rot.act(V3(xx, yy, pw(yy) / 2 + 0.0004)), rotation: rot * simd_quatf(angle: -lean, axis: FA.X)))
            }
            for sx: Float in [-1, 1] {
                m.add(Prim.cylinder(radius: 0.0007, height: 0.002, bevel: 0, segments: 3, bevelSegments: 1, material: "metal.rust"), Xform(translation: V3(sx * 0.07, postBot + 0.12, 0)))
                FA.box(&m, V3(0.0008, 0.09, 0.008), V3(sx * (pw(postBot + 0.1) / 2 + 0.0009), postBot + 0.09, 0), "metal.rust", r: 0.0002)
            }
            // Rust runs from the strap bolts down the iron and the oak.
            for sx: Float in [-1, 1] { for dy: Float in [0.05, 0.15] {
                FA.box(&m, V3(0.0008, rng.float(0.04...0.08), 0.005), V3(sx * (pw(postBot + dy) / 2 + 0.0063), postBot + dy - 0.04, rng.float(-0.004...0.004)), "metal.rust", r: 0.0002)
            }}
        }
        groundAO(&m, height: 0.12, floor: 0.85)
        return FC.place(m)
    }

    func bolt(_ m: inout Model, _ p: V3, _ n: V3, _ size: Float, lite: Bool) {
        m.add(Prim.cylinder(radius: size * 0.55, height: size * 0.45, bevel: size * 0.07, segments: 6, bevelSegments: 1, material: "metal.bolt-bright"), Xform(translation: p, rotation: facing(n)))
    }
}
