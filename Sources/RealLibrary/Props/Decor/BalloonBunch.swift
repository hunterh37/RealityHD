import simd
import Foundation

/// Balloon Bunch: five helium balloons on curled ribbons tied through a 3 cm brass washer weight. Four 28 cm teardrop latex
/// balloons (seam, rolled lip, tied knot) and one gold foil star with a crimped edge, floating about 0.9 m above the weight.
public struct BalloonBunch: RealAsset {
    public static let id = "balloon-bunch"
    public static let summary = "Bunch of five helium balloons on curled ribbons tied to a small brass washer weight."
    public static let tags = ["prop", "decor", "plastic", "handheld"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 8, distance: 1.9, studio: true)

    /// Latex balloon height from lip to apex (m).
    public var latexHeight: Float = 0.28
    /// Latex balloon radius at the widest point (m).
    public var latexRadius: Float = 0.1
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let brass: MaterialKey = "metal.brass", foil: MaterialKey = "metal.gold-leaf"
        let latex: [(hex: String, ky: Float)] = [("D2161E", 0.76), ("", 0.87), ("0E9C9A", 0.80), ("F25C9E", 0.91), ("F3EEE4", 0.83)]
        let H = latexHeight, R = latexRadius

        // Teardrop latex profile, y = 0 at the lip: neck, flare, widest at 62 % height, rounded apex.
        let neckR: Float = 0.0034, neckH: Float = 0.012
        var prof: [V2] = [V2(0, 0), V2(neckR, 0), V2(neckR, neckH)]
        for u in [0.03, 0.09, 0.2, 0.32, 0.45, 0.6, 0.72, 0.83, 0.92, 0.98] as [Float] {
            let w = pow(max(0, sin(Float.pi * pow(u, 1.45))), 0.62)
            prof.append(V2(neckR + (R - neckR) * w, neckH + (H - neckH) * u))
        }
        prof.append(V2(0, H))
        let seamPath = prof.dropFirst(3).dropLast().map { V3($0.x - 0.0002, $0.y, 0) }

        func latexBalloon(_ tint: String) -> Model {
            var b = Model(name: "latex")
            let mat: MaterialKey = MaterialKey("plastic.gloss:" + tint)
            b.add(Prim.lathe(prof, segments: 64, seamTile: 0.3, material: mat))
            // Moulding seam down one side, rolled lip and the tied knot under it.
            b.add(Prim.tube(seamPath, radii: seamPath.map { _ in 0.0004 }, sides: 5, seamTile: 0.05, material: mat, capEnd: false))
            b.add(Prim.torus(major: 0.0046, minor: 0.0017, segments: 24, sides: 6, material: mat), Xform(translation: V3(0, 0.0008, 0)))
            b.add(Prim.superellipsoid(V3(0.0105, 0.0085, 0.0095), exponent: 3, subdivisions: 4, material: mat), Xform(translation: V3(0, -0.0035, 0)))
            b.add(Prim.torus(major: 0.0036, minor: 0.0012, segments: 16, sides: 5, material: mat), Xform(translation: V3(0, 0.0055, 0)))
            // Apex nipple where the latex was dipped, and a faint stretched-neck collar.
            b.add(Prim.superellipsoid(V3(0.007, 0.004, 0.007), exponent: 2.5, subdivisions: 4, material: mat), Xform(translation: V3(0, H - 0.001, 0)))
            return b.transformed(Xform(scale: V3(1, 1, 0.94)))
        }

        // Gold foil star: filleted outline extruded into a pillow, crimped ridge around the edge, sealed neck.
        let sr: Float = 0.14, si: Float = 0.064
        let star = (0..<10).map { k -> V2 in
            let a = Float.pi / 2 + Float(k) * Float.pi / 5, r = k % 2 == 0 ? sr : si
            return V2(cos(a) * r, sin(a) * r)
        }
        let outline = Shape2D.rounded(star, radius: 0.011, segments: 3)
        let starKnotDrop: Float = 0.112
        func starBalloon() -> Model {
            var b = Model(name: "star")
            b.add(Prim.extrude(outline, depth: 0.05, bevel: 0.021, bevelSegments: 4, material: foil))
            var ridge = outline.map { V3($0.x * 0.985, $0.y * 0.985, 0) }
            ridge.append(ridge[0])
            b.add(Prim.tube(ridge, radii: ridge.map { _ in 0.0042 }, sides: 6, seamTile: 0.05, material: foil, capEnd: false,
                            rippling: { _, v in 1 + 0.32 * sin(v / 0.0052 * 2 * .pi) }))
            b.add(Prim.superellipsoid(V3(0.03, 0.05, 0.007), exponent: 4, subdivisions: 5, material: foil), Xform(translation: V3(0, -0.086, 0)))
            b.add(Prim.roundedBox(V3(0.034, 0.006, 0.008), radius: 0.0025, bevelSegments: 2, material: foil), Xform(translation: V3(0, -0.108, 0)))
            return b
        }

        // Balloons around the weight: staggered heights, outward tilt, random spin about their own axis.
        var knots: [V3] = []
        for (i, spec) in latex.enumerated() {
            let az = (Float(i) * 72 + 15 + rng.float(-6...6)) * .pi / 180
            let kr: Float = 0.115 + rng.float(-0.01...0.01)
            let knot = V3(kr * cos(az), spec.ky + rng.float(-0.015...0.015), kr * sin(az))
            knots.append(knot)
            if spec.hex.isEmpty {
                let yaw = simd_quatf(angle: .pi / 2 - az, axis: .up)
                let tilt = simd_quatf(angle: -rng.float(0.05...0.12), axis: simd_cross(V3(cos(az), 0, sin(az)), V3(0, 1, 0)))
                m.add(starBalloon(), Xform(translation: knot + V3(0, starKnotDrop, 0), rotation: tilt * yaw))
            } else {
                let th = rng.float(11...19) * .pi / 180
                let dir = V3(sin(th) * cos(az), cos(th), sin(th) * sin(az))
                let q = simd_quatf(from: .up, to: dir) * simd_quatf(angle: rng.float(0...(2 * .pi)), axis: .up)
                m.add(latexBalloon(spec.hex), Xform(translation: knot, rotation: q))
            }
        }

        // Ribbons: eased descent with sway and a spiral curl, converging through the washer; free tails curl on the ground.
        let ribbonTint = ["D2161E", "F2C230", "0E9C9A", "F25C9E", "F3EEE4"]
        for (i, knot) in knots.enumerated() {
            let mat: MaterialKey = MaterialKey("plastic.gloss:" + ribbonTint[i])
            let a1 = rng.float(0...(2 * .pi)), freq = rng.float(3.2...4.6), amp = rng.float(0.006...0.011), sway = rng.float(0.012...0.024)
            let end = V3(rng.float(-0.002...0.002), 0.0016, rng.float(-0.002...0.002))
            var ctl: [V3] = [knot + V3(0, -0.006, 0)]
            let n = 16
            for k in 1...n {
                let t = Float(k) / Float(n), e = t * t * (3 - 2 * t)
                let hz = pow(1 - e, 1.5)
                let env = sin(t * .pi) * 0.9 + 0.1 * t
                let ph = a1 + t * freq * 2 * .pi
                let p = V3(knot.x * hz + amp * env * cos(ph) + sway * sin(t * .pi * 2 + a1) * env,
                           knot.y + (end.y - knot.y) * t,
                           knot.z * hz + amp * env * sin(ph) + sway * cos(t * .pi * 2 + a1) * env)
                ctl.append(k == n ? end : p)
            }
            let path = catmull(ctl, per: 2)
            m.add(Prim.tube(path, radii: path.map { _ in 0.0012 }, sides: 4, seamTile: 0.02, material: mat, capEnd: false))
            if i == 0 || i == 3 {
                var tail: [V3] = []
                let a0 = rng.float(0...(2 * .pi)), dir: Float = i % 2 == 0 ? 1 : -1
                for k in 0..<15 {
                    let a = a0 + dir * Float(k) * 0.3, r = 0.003 + 0.0021 * Float(k)
                    let lift = k > 9 ? 0.006 * max(0, sin(Float(k) * 0.75)) : 0
                    let y = (r < 0.0155 ? 0.0046 : 0.0013) + lift
                    tail.append(V3(r * cos(a), y, r * sin(a)))
                }
                let tp = catmull(tail, per: 1)
                m.add(Prim.tube(tp, radii: tp.map { _ in 0.0012 }, sides: 4, seamTile: 0.02, material: mat, capEnd: true))
            }
        }

        // 3 cm brass washer weight on the ground.
        let wp: [V2] = [V2(0.0075, 0), V2(0.0145, 0), V2(0.015, 0.0006), V2(0.015, 0.0024), V2(0.0145, 0.003), V2(0.0075, 0.003),
                        V2(0.0071, 0.0024), V2(0.0071, 0.0006), V2(0.0075, 0)]
        m.add(Prim.lathe(wp, segments: 48, seamTile: 0.05, material: brass))

        // Overhand knot of the bundled ribbons sitting on the washer.
        m.add(Prim.superellipsoid(V3(0.011, 0.009, 0.011), exponent: 2.6, subdivisions: 4, material: "plastic.gloss:" + ribbonTint[0]), Xform(translation: V3(0.0, 0.0075, 0.0)))
        m.add(Prim.torus(major: 0.0065, minor: 0.0011, segments: 20, sides: 5, material: "plastic.gloss:" + ribbonTint[2]), Xform(translation: V3(0, 0.0105, 0), rotation: simd_quatf(degrees: 70, axis: V3(1, 0, 0))))
        groundAO(&m, height: 0.02, floor: 0.5)
        return LODModel(m)
    }
}
