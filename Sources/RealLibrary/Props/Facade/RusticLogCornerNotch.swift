import simd
import Foundation

/// Rustic log cabin corner with saddle notches, 0.5 x 1.2 x 0.5 m: seven courses of round pine logs (about 0.2 m
/// across) laid at 0.167 m centres, each course carrying one log past the corner on alternating walls so the
/// overlaps nest, cut end faces with growth rings, bark furrows, knots and checks along the grain, lime chinking
/// bedded in the grooves, and an iron drift pin driven through the top log. The lower courses are damp and dark,
/// the top courses grey, with rust streaks from the pin and soil splash at the base.
public struct RusticLogCornerNotch: RealAsset {
    public static let id = "rustic-log-corner-notch"
    public static let summary = "Rustic log cabin corner, 0.5 x 1.2 m: seven courses of round pine logs with nested saddle notches, ring-marked end cuts, lime chinking and a drift pin."
    public static let tags = ["prop", "architecture", "facade", "wood"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 40, elevation: 14, distance: 1.1)

    /// Log bark and wood.
    public var log: MaterialKey = "wood.pine-aged"
    /// Silvered, sun-dried logs on the upper courses.
    public var aged: MaterialKey = "wood.cedar-weathered"
    /// Cut end faces.
    public var cut: MaterialKey = "wood.endgrain-weathered"
    /// Lime chinking.
    public var chinking: MaterialKey = "brick.mortar-lime"
    /// Iron pin and nail heads.
    public var iron: MaterialKey = "metal.rust"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [make(seed: seed, lite: false), make(seed: seed, lite: true)], switchDistances: [3])
    }

    func make(seed: UInt64, lite: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let sides = lite ? 8 : 12
        let R: Float = 0.1, pitch: Float = 1.0 / 6.0 * 1.0 * 1.0
        let step: Float = 1.0 / 6.0 // 0.1667: seven courses between centres 0.1 and 1.1
        _ = pitch
        /// One round log from `a` to `b` (axis along X or Z), with butt-to-tip taper, wobble and knots.
        func addLog(_ a: V3, _ b: V3, course: Int, _ i: Int) {
            var r = rng.fork(100 + i)
            let mat: MaterialKey = course >= 5 ? aged : log
            let axis = simd_normalize(b - a)
            let side = abs(axis.x) > 0.5 ? V3(0, 0, 1) : V3(1, 0, 0)
            var pts: [V3] = [], rad: [Float] = []
            let n = lite ? 3 : 6
            let rScale: Float = r.float(0.95...1.0)
            let L = simd_length(b - a)
            for k in 0...n {
                let t = Float(k) / Float(n)
                pts.append(a + (b - a) * t)
                rad.append(R * rScale * (1.04 - 0.07 * t) * (1 + r.float(-0.012...0.012)))
            }
            // Round log: a lathe along +Y with the grain running along the log, laid on its axis.
            var prof: [(Float, Float)] = [(0, 0)]
            for k in 0...n { prof.append((rad[k], L * Float(k) / Float(n))) }
            prof.append((0, L))
            let laid: simd_quatf = abs(axis.x) > 0.5 ? FA.q(-90, FA.Z) : FA.q(90, FA.X)
            m.add(turned(prof, segments: sides, material: mat, seamTile: 0.35, grainVertical: true), Xform(translation: a, rotation: laid))
            for (p, rr, dir) in [(pts[0], rad[0], axis), (pts[n], rad[n], -axis)] {
                // End disc: cylinder proud by 2 mm, on the cut face.
                let rot: simd_quatf = abs(axis.x) > 0.5 ? FA.q(dir.x > 0 ? -90 : 90, FA.Z) : FA.q(dir.z > 0 ? 90 : -90, FA.X)
                m.add(Prim.cylinder(radius: rr * 0.985, height: 0.003, bevel: 0.0008, segments: sides, bevelSegments: 1, material: cut), Xform(translation: p - dir * 0.001, rotation: rot))
                if !lite {
                    // Growth rings as a shallow darker ring on the face.
                    let ringRot = rot
                    m.add(Prim.torus(major: rr * 0.55, minor: 0.0014, segments: 12, sides: 3, material: aged), Xform(translation: p + dir * 0.0016, rotation: ringRot))
                }
            }
            if lite { return }
            // Bark furrows: thin darker ridges along the log at random angles.
            for _ in 0..<3 {
                let phi = r.float(0...(2 * .pi))
                let radial = side * cos(phi) + V3(0, 1, 0) * sin(phi)
                let q0 = pts[0] + axis * r.float(0.01...0.05) + radial * (rad[0] * 1.0)
                let q1 = pts[n] - axis * r.float(0.01...0.05) + radial * (rad[n] * 1.0)
                FA.rod(&m, q0, q1, r: 0.0042, aged, sides: 4)
            }
            // Drying check: a long dark crack along the upper face, and a drawknife flat where bark was shaved.
            let cphi = r.float(1.2...1.9)
            let cdir = side * cos(cphi) + V3(0, 1, 0) * sin(cphi)
            FA.rod(&m, pts[0] + axis * r.float(0.04...0.1) + cdir * (rad[0] * 0.985), pts[n] - axis * r.float(0.04...0.12) + cdir * (rad[n] * 0.985), r: 0.0022, "wood.charred", sides: 3)
            // A knot and a check.
            let kt = r.float(0.3...0.7), kphi = r.float(0...(2 * .pi))
            let kc = pts[0] + (pts[n] - pts[0]) * kt + (side * cos(kphi) + V3(0, 1, 0) * sin(kphi)) * (R * 1.0)
            m.add(Prim.superellipsoid(V3(0.03, 0.03, 0.012), exponent: 2, subdivisions: 1, material: cut), Xform(translation: kc, rotation: simd_quatf(from: V3(0, 0, 1), to: simd_normalize(kc - (pts[0] + (pts[n] - pts[0]) * kt)))))
        }
        var idx = 0
        for k in 0..<7 {
            let y = R + Float(k) * step
            if k % 2 == 0 {
                addLog(V3(-0.1, y, 0), V3(0.4, y, 0), course: k, idx); idx += 1
                addLog(V3(0, y, 0.1), V3(0, y, 0.4), course: k, idx); idx += 1
            } else {
                addLog(V3(0, y, -0.1), V3(0, y, 0.4), course: k, idx); idx += 1
                addLog(V3(0.1, y, 0), V3(0.4, y, 0), course: k, idx); idx += 1
            }
        }
        // Lime chinking bedded in the grooves between courses on both faces of each wall.
        for k in 0..<6 {
            let y = R + (Float(k) + 0.5) * step
            for s: Float in [-1, 1] {
                FA.box(&m, V3(0.3, 0.07, 0.036), V3(0.25, y, s * 0.068), chinking, r: 0.008)
                FA.box(&m, V3(0.036, 0.07, 0.3), V3(s * 0.068, y, 0.25), chinking, r: 0.008)
            }
        }
        // Drift pin through the top log with a rusty head and a streak running down the bark.
        m.add(Prim.cylinder(radius: 0.012, height: 0.006, bevel: 0.0015, segments: lite ? 6 : 8, bevelSegments: 1, material: iron), Xform(translation: V3(0.0, R + 6 * step + R * 0.99, 0)))
        if !lite {
            FA.rod(&m, V3(0.0, R + 6 * step + R * 0.97, 0), V3(0.0, R + 6 * step + R * 0.97, -0.0), r: 0.001, iron, sides: 4)
            // Rust streak down the face of the top log below a nail, and nail heads on the face of the lower wall.
            for (x, y) in [(Float(0.22), Float(1.0)), (0.33, 0.67), (0.18, 0.34)] {
                m.add(Prim.cylinder(radius: 0.008, height: 0.005, bevel: 0.0012, segments: 6, bevelSegments: 1, material: iron), Xform(translation: V3(x, y, 0.098), rotation: FA.q(90, FA.X)))
                FA.box(&m, V3(0.006, rng.float(0.05...0.1), 0.0016), V3(x, y - 0.04, 0.0975), iron, r: 0.0005)
            }
            // Soil splash: dark band on the bottom course, damp patches climbing the first two courses.
            for _ in 0..<7 { FO9.patch(&m, cx: rng.float(0.1...0.38), cy: rng.float(0.01...0.07), rx: rng.float(0.02...0.06), ry: rng.float(0.01...0.03), z: 0.0995, "wood.deadwood", rng: &rng, depth: 0.0006) }
            for _ in 0..<6 { FO9.patch(&m, cx: rng.float(0.1...0.38), cy: rng.float(0.2...0.4), rx: rng.float(0.02...0.05), ry: rng.float(0.015...0.04), z: 0.0995, "wood.deadwood", rng: &rng, depth: 0.0005) }
            // Bark remnants on the lower courses and lime smears under each chinking line.
            for _ in 0..<9 { FO9.patch(&m, cx: rng.float(0.12...0.38), cy: rng.float(0.05...0.6), rx: rng.float(0.01...0.03), ry: rng.float(0.01...0.025), z: 0.1, "wood.deadwood", rng: &rng, depth: 0.0008, n: 8) }
            for k in 0..<6 { FO9.patch(&m, cx: rng.float(0.15...0.38), cy: R + (Float(k) + 0.5) * step - 0.045, rx: rng.float(0.03...0.08), ry: 0.008, z: 0.0985, chinking, rng: &rng, depth: 0.0006, n: 7) }
            // Sap staining and bird lime streaks on top surface of the top log.
            for _ in 0..<4 { FO9.patchTop(&m, cx: rng.float(0.05...0.35), cz: rng.float(-0.03...0.03), rx: rng.float(0.02...0.05), rz: rng.float(0.01...0.02), y: R + 6 * step + R * 1.0 - 0.0006, chinking, rng: &rng, depth: 0.0005) }
        }
        groundAO(&m, height: 0.25, floor: 0.7)
        return FC.place(m)
    }
}
