import simd
import Foundation

/// Industrial pipe guard rail, 3.0 m: 42 mm safety-yellow steel pipe top and mid rails run through cast cross fittings
/// with socket set screws on three posts, each post welded to a bolted square base flange. A threaded union couples
/// the top rail in the left span, a 100 mm toe plate in two bolted sheets overlaps at the middle post. Paint is chipped
/// to galvanized and rust on the top rail and fittings, rust bleeds from the flange bolts and weld beads, the right
/// post is an older galvanized replacement with a bright new bolt.
public struct PipeRailGuard: RealAsset {
    public static let id = "pipe-rail-guard"
    public static let summary = "Industrial pipe guard rail, 3.0 m: yellow steel pipe rails in cross fittings on three posts, toe plate and bolted flanges."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 12, distance: 2.6)

    /// Yellow painted rails and posts.
    public var paint: MaterialKey = "metal.signal-yellow"
    /// Galvanized fittings, flanges and toe plate.
    public var steel: MaterialKey = "metal.galvanized"
    /// Aged galvanized for the replacement post.
    public var aged: MaterialKey = "metal.galvanized-aged"
    /// Rust staining.
    public var rust: MaterialKey = "metal.rust"
    /// Replacement anchor bolt.
    public var bolt: MaterialKey = "metal.bolt-bright"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [make(seed: seed, lite: false), make(seed: seed, lite: true)], switchDistances: [6])
    }

    /// Hex head bolt, 6 sides, one bevel segment.
    func bolt6(_ m: inout Model, at p: V3, normal n: V3, size: Float, material: MaterialKey) {
        m.add(Prim.cylinder(radius: size * 0.55, height: size * 0.45, bevel: size * 0.07, segments: 6, bevelSegments: 1, material: material), Xform(translation: p, rotation: facing(n)))
    }

    func make(seed: UInt64, lite: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let seg = lite ? 8 : 12
        let rp: Float = 0.0192            // 33.4 mm (1 in) pipe
        let postX: [Float] = [-1.45, 0, 1.45]
        let topY: Float = 0.955, midY: Float = 0.50
        let fl: Float = 0.048, flT: Float = 0.011
        let railFront: MaterialKey = "metal.signal-yellow:C99B14"
        // Posts, flanges, fittings.
        for (i, x) in postX.enumerated() {
            let right = i == 2
            let postMat: MaterialKey = right ? aged : paint
            // Flange with chamfered edge and a rust skirt.
            FA.box(&m, V3(fl, flT, fl), V3(x, flT / 2, 0), steel, r: 0.004)
            if !lite { FA.box(&m, V3(fl + 0.0006, 0.0025, fl + 0.0006), V3(x, 0.00125, 0), rust, r: 0.001) }
            // Post: pipe with turned weld collar and domed cap.
            m.add(turned([(0, flT), (rp * 1.22, flT), (rp * 1.14, flT + 0.006), (rp * 1.08, flT + 0.014), (rp, flT + 0.02), (rp, topY + 0.04), (rp * 0.9, topY + 0.046), (rp * 0.55, topY + 0.052), (0, topY + 0.054)], segments: seg, material: postMat, seamTile: 0.1, grainVertical: true), Xform(translation: V3(x, 0, 0)))
            // Rust and oil stain on the ground around the flange.
            if !lite {
                FA.box(&m, V3(0.07, 0.0008, 0.046), V3(x + rng.float(-0.005...0.005), 0.0004, 0), "metal.rust-grime:4A3426", r: 0.0003)
                FA.box(&m, V3(0.05, 0.0012, 0.036), V3(x, 0.0006, 0), "metal.rust:7A3E1E", r: 0.0004)
            }
            // Weld bead ring at the flange.
            m.add(Prim.torus(major: rp * 1.12, minor: 0.0028, segments: lite ? 8 : 14, sides: lite ? 4 : 6, material: rust), Xform(translation: V3(x, flT + 0.006, 0)))
            // Anchor bolts with washers.
            for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
                let fresh = right && sx > 0 && sz > 0
                let p = V3(x + sx * 0.0195, flT, sz * 0.0195)
                m.add(Prim.cylinder(radius: 0.0058, height: 0.0007, bevel: 0, segments: lite ? 6 : 10, bevelSegments: 1, material: steel), Xform(translation: p))
                if !lite { bolt6(&m, at: p + V3(0, 0.0007, 0), normal: FA.Y, size: 0.0085, material: fresh ? bolt : "metal.steel") }
                else { FA.box(&m, V3(0.008, 0.005, 0.008), p + V3(0, 0.003, 0), steel, r: 0.001) }
                if !lite && !fresh && rng.chance(0.75) { FA.box(&m, V3(0.0056, 0.0015, 0.009), p + V3(0, 0.0009, -sz * 0.004), rust, r: 0.0005) }
            }}
            // Cross fittings: collar around the post, hub toward each rail, socket set screws on the front.
            for (ry, k) in [(topY, 0), (midY, 1)] {
                let fy = ry
                m.add(turned([(rp * 1.02, -0.035), (0.0222, -0.032), (0.0236, -0.028), (0.0236, 0.028), (0.0222, 0.032), (rp * 1.02, 0.035)], segments: seg, material: steel, seamTile: 0.1, grainVertical: true), Xform(translation: V3(x, fy, 0)))
                m.add(Prim.torus(major: 0.0236, minor: 0.002, segments: lite ? 8 : 14, sides: lite ? 4 : 6, material: steel), Xform(translation: V3(x, fy + 0.03, 0)))
                m.add(Prim.torus(major: 0.0236, minor: 0.002, segments: lite ? 8 : 14, sides: lite ? 4 : 6, material: steel), Xform(translation: V3(x, fy - 0.03, 0)))
            // Side hubs toward rails (end posts get a single hub inward).
                for sx: Float in [-1, 1] where !((i == 0 && sx < 0) || (i == 2 && sx > 0)) {
                    m.add(turned([(0.0213, 0), (0.0239, 0.003), (0.0244, 0.012), (0.0244, 0.044), (0.0222, 0.047), (rp * 1.01, 0.05)], segments: seg, material: steel, seamTile: 0.1, grainVertical: true),
                          Xform(translation: V3(x + sx * 0.0, fy, 0), rotation: FA.q(-sx * 90, FA.Z)))
                }
            // Cap plug where the rail stops at an end post.
                if i == 0 || i == 2 {
                    let sx: Float = i == 0 ? -1 : 1
                    m.add(turned([(0.0, 0.0), (0.0218, 0.0), (0.0218, 0.012), (0.0175, 0.018), (0, 0.02)], segments: seg, material: steel, seamTile: 0.1),
                          Xform(translation: V3(x + sx * 0.022, fy, 0), rotation: FA.q(-sx * 90, FA.Z)))
                }
            // Set screws (two per fitting on the front, one on the back).
                if !lite {
            for dy: Float in [-0.016, 0.016] { bolt6(&m, at: V3(x, fy + dy, 0.0236), normal: FA.Z, size: 0.0075, material: "metal.steel") }
                    
                    if k == 0 && rng.chance(0.8) { FA.box(&m, V3(0.01, 0.0014, 0.012), V3(x + 0.014, fy + 0.0236 + 0.0004, 0.004), rust, r: 0.0004) }
                }
            }
        }
        // Rails: pipe tubes between fittings, with a coupling on the left span of the top rail.
        func rail(_ y: Float, _ xa: Float, _ xb: Float, _ mat: MaterialKey) {
            m.add(Prim.tube([V3(xa, y, 0), V3(xb, y, 0)], radii: [rp, rp], sides: seg, seamTile: 0.1, material: mat, capEnd: true))
        }
        rail(topY, -1.45, -0.735, railFront)
        rail(topY, -0.705, 0, "metal.signal-yellow:EDC433")
        rail(topY, 0, 1.45, "metal.signal-yellow:D9A81A")
        rail(midY, -1.45, 0, "metal.signal-yellow:BF9312")
        rail(midY, 0, 1.45, "metal.signal-yellow:EDC02A")
        // Threaded union on the top rail: hex nut with two collars and a weld seam.
        do {
            let cx: Float = -0.72
            m.add(Prim.cylinder(radius: 0.0247, height: 0.024, bevel: 0.0015, segments: 6, bevelSegments: 1, material: steel), Xform(translation: V3(cx - 0.012, topY, 0), rotation: FA.q(-90, FA.Z)))
            for dx: Float in [-0.018, 0.018] {
                m.add(Prim.cylinder(radius: 0.0216, height: 0.008, bevel: 0.001, segments: seg, bevelSegments: 1, material: steel), Xform(translation: V3(cx + dx - 0.004, topY, 0), rotation: FA.q(-90, FA.Z)))
            }
            if !lite { m.add(Prim.torus(major: rp * 1.04, minor: 0.0022, segments: 20, sides: 6, material: rust), Xform(translation: V3(cx + 0.026, topY, 0), rotation: FA.q(90, FA.Z))) }
        }
        // Toe plate: two bolted sheets, second overlaps the first at the middle post.
        let tpT: Float = 0.0025, tpZ = rp + 0.0008 + tpT / 2
        func toe(_ xa: Float, _ xb: Float, z: Float, _ mat: MaterialKey) {
            FA.box(&m, V3(xb - xa, 0.1, tpT), V3((xa + xb) / 2, 0.016 + 0.05, z), mat, r: 0.0016)
        }
        toe(-1.462, -0.002, z: tpZ, "metal.galvanized-aged")
        toe(0.002, 1.462, z: tpZ, "metal.galvanized")
        // Folded top lip on the toe plate (bent return, 12 mm) so the plate edge reads as sheet metal.
        FA.box(&m, V3(1.46, 0.003, tpT + 0.002), V3(-0.732, 0.116 - 0.0015, tpZ), "metal.steel", r: 0.001)
        FA.box(&m, V3(1.46, 0.003, tpT + 0.002), V3(0.732, 0.116 - 0.0015, tpZ), "metal.steel", r: 0.001)
        // Hazard marking: black tape bands on each post below the top fitting, and grime on the rails beside each fitting.
        for x in postX {
            for k in 0..<3 {
                m.add(turned([(rp * 1.004, 0), (rp * 1.012, 0.001), (rp * 1.012, 0.027), (rp * 1.004, 0.028)], segments: seg, material: "plastic.black", seamTile: 0.1), Xform(translation: V3(x, 0.60 + Float(k) * 0.06, 0)))
            }
        }
        if !lite {
            for x in postX { for sx: Float in [-1, 1] where !((x < -1 && sx < 0) || (x > 1 && sx > 0)) {
                for (ry, tone) in [(topY, "metal.signal-yellow:A98616"), (midY, "metal.signal-yellow:B58F18")] {
                    m.add(turned([(rp * 1.003, 0), (rp * 1.01, 0.002), (rp * 1.01, 0.1), (rp * 1.003, 0.103)], segments: seg, material: tone, seamTile: 0.1), Xform(translation: V3(x + sx * 0.05, ry, 0), rotation: FA.q(-sx * 90, FA.Z)))
                }
            }}
            // Weld seams where the post meets each fitting hub are hidden; show the flange weld flare and extra rust.
        }
        // Back-side brackets for the toe plate, clamped to the posts.
        for x in postX {
            FA.box(&m, V3(0.034, 0.08, 0.004), V3(x, 0.056, -(rp + 0.002)), steel, r: 0.0012)
            if !lite {
                for dy: Float in [0.03, 0.082] {
                    let front = x < 0.01 && x > -0.01
                    let zf = tpZ + tpT / 2
                    _ = front
                    bolt6(&m, at: V3(x - 0.012, 0.016 + dy, zf), normal: FA.Z, size: 0.0075, material: rng.chance(0.3) ? bolt : "metal.steel")
                    bolt6(&m, at: V3(x + 0.012, 0.016 + dy, zf), normal: FA.Z, size: 0.0075, material: "metal.steel")
                }
            }
        }
        if !lite { for sx: Float in [-1, 1] { FA.box(&m, V3(1.46, 0.012, 0.0006), V3(sx * 0.732, 0.016 + 0.006, tpZ + tpT / 2 + 0.0003), rust, r: 0.0002) } }
        // Wear: paint chips and rust bleed.
        if !lite {
            let chipMats: [MaterialKey] = [steel, rust, aged]
            func chip(_ p: V3, _ w: Float, _ h: Float, _ mat: MaterialKey) {
                m.add(Prim.superellipsoid(V3(w, h, 0.0032), exponent: 3, subdivisions: 1, material: mat), Xform(translation: p))
            }
            // Top rail crown chips (hands and weather) on the front-top quadrant.
            for _ in 0..<28 {
                let x = rng.float(-1.4...1.4), a = rng.float(0.2...1.2)
                let r = rp * 1.002
                chip(V3(x, topY + sin(a) * r, cos(a) * r), rng.float(0.02...0.1), rng.float(0.008...0.02), rng.pick(chipMats))
            }
            for _ in 0..<16 {
                let x = rng.float(-1.4...1.4), a = rng.float(-0.2...0.8)
                let r = rp * 1.002
                chip(V3(x, midY + sin(a) * r, cos(a) * r), rng.float(0.015...0.07), rng.float(0.008...0.018), rng.pick(chipMats))
            }
            // Post chips and drips of rust down the post fronts below fittings.
            for x in postX where x < 1 {
                for _ in 0..<3 { chip(V3(x + rng.float(-0.01...0.01), rng.float(0.12...0.45), rp * 1.002), rng.float(0.012...0.03), rng.float(0.06...0.2), rust) }
                m.add(Prim.cylinder(radius: rp * 1.003, height: rng.float(0.05...0.11), bevel: 0, segments: 12, bevelSegments: 1, material: "metal.rust-grime"), Xform(translation: V3(x, flT + 0.02, 0)))
                m.add(Prim.cylinder(radius: rp * 1.003, height: rng.float(0.05...0.09), bevel: 0, segments: 12, bevelSegments: 1, material: rust), Xform(translation: V3(x, midY - 0.13, 0)))
            }
            // Rust bleed lines on toe plate below the bolts.
            for _ in 0..<5 {
                let x = rng.float(-1.3...1.3)
                FA.box(&m, V3(rng.float(0.003...0.006), rng.float(0.02...0.05), 0.0007), V3(x, 0.07, tpZ + tpT / 2 + 0.0004), rust, r: 0.0003)
            }
        }
        groundAO(&m, height: 0.1, floor: 0.85)
        return FC.place(m)
    }
}
