import simd
import Foundation

/// Italianate campanile bell cage: a two-course limestone base with a chamfered cap, four square wrought
/// iron uprights leaded into the stone with C-scroll feet, a riveted ring band, four arched straps meeting at
/// a crown boss with a ball and cross finial, an oak headstock bolted between iron straps, a cast bronze bell
/// with sound bow, waist, shoulder and crown loops, an iron clapper and a rope wheel. Rust runs stain the
/// stone below each foot. Sits on y = 0, 1.4 m tall.
public struct CampanileBellCage: RealAsset {
    public static let id = "campanile-bell-cage"
    public static let summary = "Campanile bell cage, 1.4 m: stone base, arched wrought-iron uprights with scroll feet, oak headstock, bronze bell, ball-and-cross finial."
    public static let tags = ["prop", "architecture", "facade", "roof", "metal", "stone"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 12, distance: 3.0)

    /// Footprint width in meters.
    public var width: Float = 1.2
    /// Overall height in meters.
    public var height: Float = 1.4
    /// Base stone.
    public var stone: MaterialKey = "stone.limestone"
    /// Ironwork.
    public var iron: MaterialKey = "metal.wrought-iron"
    /// Bell metal.
    public var bronze: MaterialKey = "metal.bronze-cast:8A6A3A"
    /// Headstock timber.
    public var oak: MaterialKey = "wood.pine-aged"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let w = width, k = height / 1.4
        // Base: plinth course, chamfered cap.
        FA.box(&m, V3(w, 0.1, w), V3(0, 0.05, 0), "stone.limestone-sooted", r: 0.01)
        FA.box(&m, V3(w - 0.02, 0.03, w - 0.02), V3(0, 0.115, 0), "stone.limestone-sooted", r: 0.008)
        FA.box(&m, V3(w - 0.06, 0.02, w - 0.06), V3(0, 0.14, 0), "stone.limestone-sooted", r: 0.008)
        FA.box(&m, V3(w - 0.1, 0.012, w - 0.1), V3(0, 0.154, 0), stone, r: 0.005)
        let top: Float = 0.16
        let c = w / 2 - 0.1
        let postTop = 0.95 * k
        let corners = [V3(-c, 0, -c), V3(c, 0, -c), V3(c, 0, c), V3(-c, 0, c)]
        for (i, p) in corners.enumerated() {
            // Square upright, leaded into the cap.
            FA.box(&m, V3(0.034, postTop - top + 0.02, 0.034), V3(p.x, (top + postTop) / 2 - 0.01, p.z), iron, r: 0.004)
            m.add(Prim.cylinder(radius: 0.04, height: 0.008, bevel: 0.003, segments: 16, bevelSegments: 1, material: "metal.galvanized-aged"),
                  Xform(translation: V3(p.x, top - 0.004, p.z)))
            // C-scroll brackets on the two inward faces.
            let inward = [V3(-simd_sign(p.x), 0, 0), V3(0, 0, -simd_sign(p.z))]
            for d in inward {
                var pts: [V3] = [V3(p.x, top + 0.24, p.z) + d * 0.018]
                for j in 0...14 {
                    let t = Float(j) / 14
                    let a = Float.pi * 0.5 - t * 2.1 * .pi
                    let r = 0.055 * (1 - t * 0.6)
                    let local = V2(0.075 + cos(a) * r - 0.0, 0.065 + sin(a) * r)
                    pts.append(V3(p.x, top, p.z) + d * local.x + V3(0, local.y, 0))
                }
                FA.path(&m, pts, r: 0.007, iron, sides: 5)
                FC.bead(&m, r: 0.011, at: pts.last!, iron, sub: 2)
            }
            // Rust run on the stone below the foot.
            var rr = rng.fork(i)
            let dir = simd_normalize(V3(p.x, 0, p.z))
            let len = rr.float(0.12...0.2)
            m.add(Prim.superellipsoid(V3(0.045, 0.004, len), exponent: 2.6, subdivisions: 2, material: "metal.rust"),
                  Xform(translation: V3(p.x, 0.1605, p.z) - dir * (len / 2 - 0.05),
                        rotation: simd_quatf(angle: atan2(dir.x, dir.z), axis: FA.Y)))
            // Arched strap from the post head to the crown.
            var arc: [V3] = []
            for j in 0...14 {
                let t = Float(j) / 14
                arc.append(V3(p.x * (1 - t), postTop + (1.22 * k - postTop) * sin(t * .pi / 2), p.z * (1 - t)))
            }
            FA.path(&m, arc, r: 0.016, iron, sides: 7)
            FC.bead(&m, r: 0.024, at: V3(p.x, postTop, p.z), iron)
        }
        // Riveted ring band tying the uprights below the arches.
        let bandY = postTop - 0.06
        for i in 0..<4 {
            let a = corners[i], b = corners[(i + 1) % 4]
            let mid = (a + b) / 2, len = simd_length(b - a)
            let along = simd_normalize(b - a)
            let rot = simd_quatf(angle: atan2(-along.z, along.x), axis: FA.Y)
            FA.box(&m, V3(len + 0.03, 0.04, 0.008), V3(mid.x, bandY, mid.z), iron, r: 0.002, rot: rot)
            let out = simd_normalize(V3(mid.x, 0, mid.z))
            for j in 0..<5 {
                let pp = a + (b - a) * (Float(j) + 0.5) / 5
                rivet(&m, at: V3(pp.x, bandY, pp.z) + out * 0.0045, normal: out, radius: 0.006, material: iron)
            }
        }
        // Crown boss, ball and cross finial.
        m.add(Prim.lathe([V2(0, 1.2 * k), V2(0.05, 1.2 * k), V2(0.055, 1.22 * k), V2(0.035, 1.25 * k), V2(0.015, 1.26 * k), V2(0, 1.26 * k)], segments: 20, material: iron))
        FA.ball(&m, r: 0.035, at: V3(0, 1.29 * k, 0), "metal.brass-aged")
        FA.box(&m, V3(0.02, height - 1.32 * k, 0.02), V3(0, (1.32 * k + height) / 2, 0), iron, r: 0.003)
        FA.box(&m, V3(0.12, 0.02, 0.02), V3(0, height - 0.035, 0), iron, r: 0.004)
        FA.box(&m, V3(0.02, 0.02, 0.12), V3(0, height - 0.035, 0), iron, r: 0.004)
        // Oak headstock between two iron straps, bolted.
        let hY = 0.84 * k
        FA.box(&m, V3(2 * c + 0.03, 0.11, 0.12), V3(0, hY, 0), oak, r: 0.008)
        for s: Float in [-1, 1] {
            FA.box(&m, V3(0.5, 0.06, 0.006), V3(0, hY - 0.01, s * 0.064), iron, r: 0.002)
            for x: Float in [-0.2, 0, 0.2] {
                hexBolt(&m, at: V3(x, hY - 0.01, s * 0.067), normal: V3(0, 0, s), size: 0.018, material: iron)
            }
            // Gudgeon bearings where the headstock meets the posts.
            FA.box(&m, V3(0.05, 0.13, 0.15), V3(s * c, hY, 0), iron, r: 0.004)
        }
        // Bronze bell: lip, sound bow, waist, shoulder, crown.
        let bTop = hY - 0.055
        let H: Float = 0.48, R: Float = 0.25
        let outer: [V2] = [V2(R, 0), V2(R * 0.99, 0.03), V2(R * 0.92, 0.06), V2(R * 0.78, 0.13), V2(R * 0.7, 0.22), V2(R * 0.66, 0.32),
                           V2(R * 0.62, 0.38), V2(R * 0.5, 0.42), V2(R * 0.25, H), V2(0, H)]
        let inner: [V2] = [V2(0, H - 0.03), V2(R * 0.45, 0.385), V2(R * 0.56, 0.33), V2(R * 0.6, 0.22), V2(R * 0.68, 0.13), V2(R * 0.83, 0.05), V2(R * 0.9, 0.012)]
        let prof = (inner + outer).map { V2($0.x, bTop - H + $0.y) }
        m.add(Prim.lathe(prof, segments: 32, seamTile: 0.4, material: bronze))
        // Inscription bands on the waist and a verdigris run.
        for y: Float in [0.3, 0.34] {
            m.add(Prim.torus(major: R * 0.66 + 0.002, minor: 0.0035, segments: 28, sides: 4, material: bronze), Xform(translation: V3(0, bTop - H + y, 0)))
        }
        m.add(Prim.torus(major: R * 0.99, minor: 0.006, segments: 28, sides: 5, material: bronze), Xform(translation: V3(0, bTop - H + 0.025, 0)))
        m.add(Prim.superellipsoid(V3(0.05, 0.16, 0.012), exponent: 2.6, subdivisions: 3, material: "metal.copper-patina"),
              Xform(translation: V3(0.02, bTop - H + 0.26, R * 0.69), rotation: FA.q(-14, FA.X)))
        for j in 0..<3 {
            var pr = rng.fork(200 + j)
            let a = pr.float(0...(2 * .pi))
            m.add(Prim.superellipsoid(V3(0.04, pr.float(0.1...0.2), 0.01), exponent: 2.6, subdivisions: 2, material: "metal.copper-patina"),
                  Xform(translation: V3(sin(a) * R * 0.7, bTop - H + 0.25, cos(a) * R * 0.7), rotation: simd_quatf(angle: a, axis: FA.Y) * FA.q(-14, FA.X)))
        }
        // Crown loops (canons) into the headstock.
        for a: Float in [0, 90] {
            m.add(Prim.torus(major: 0.035, minor: 0.009, segments: 16, sides: 6, material: bronze),
                  Xform(translation: V3(0, bTop + 0.01, 0), rotation: FA.q(a, FA.Y) * FA.q(90, FA.X)))
        }
        // Clapper: iron shank and ball inside the mouth.
        FA.rod(&m, V3(0, bTop - 0.03, 0), V3(0.01, bTop - H + 0.06, 0), r: 0.009, iron)
        FA.ball(&m, r: 0.035, at: V3(0.012, bTop - H + 0.05, 0), "metal.cast-iron")
        // Rope wheel on the headstock end, spokes and rim.
        let wx = c - 0.06, wr: Float = 0.17
        m.add(Prim.torus(major: wr, minor: 0.012, segments: 24, sides: 6, material: oak),
              Xform(translation: V3(wx, hY, 0), rotation: FA.q(90, FA.Z)))
        for j in 0..<6 {
            let a = Float(j) / 6 * 2 * .pi
            FA.rod(&m, V3(wx, hY, 0), V3(wx, hY + sin(a) * wr, cos(a) * wr), r: 0.008, oak, sides: 4)
        }
        // Rope off the wheel groove, down to the base.
        FA.path(&m, [V3(wx, hY - 0.005, wr), V3(wx + 0.004, hY - 0.3, wr + 0.01), V3(wx + 0.01, top + 0.06, wr + 0.02)], r: 0.008, "fabric.burlap", sides: 6)
        // Weathering on the base: soot drips down the plinth faces, lichen crusts on the cap.
        for i in 0..<8 {
            var r3 = rng.fork(300 + i)
            let q = simd_quatf(degrees: Float(i % 4) * 90, axis: FA.Y)
            let len = r3.float(0.04...0.08)
            m.add(Prim.superellipsoid(V3(r3.float(0.02...0.05), len, 0.003), exponent: 2.6, subdivisions: 2, material: "stone.cast-grey"),
                  Xform(translation: q.act(V3(r3.float(-0.45...0.45), 0.1 - len / 2 + 0.002, w / 2 + 0.0004)), rotation: q))
        }
        for i in 0..<7 {
            var r4 = rng.fork(400 + i)
            let rad = r4.float(0.025...0.06)
            let pts = (0..<6).map { j -> V2 in let a = Float(j) / 6 * 2 * .pi; let rr = rad * r4.float(0.6...1.2); return V2(cos(a) * rr, sin(a) * rr) }
            let q = simd_quatf(degrees: Float(i % 4) * 90, axis: FA.Y)
            m.add(Prim.extrude(pts, depth: 0.003, bevel: 0.001, bevelSegments: 1, material: "stone.granite-moss"),
                  Xform(translation: q.act(V3(r4.float(-0.4...0.4), 0.1615, w / 2 - 0.07)), rotation: FA.q(90, FA.X)))
        }
        m = FC.place(m)
        groundAO(&m, height: 0.15, floor: 0.9)
        return LODModel(m)
    }
}
