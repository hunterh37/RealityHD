import simd
import Foundation

/// Red and blue full-body webbed suit kit, life size for a 1.75 m wearer. A snug hood with two large slanted eye lenses,
/// a red torso with blue flank panels, blue limbs, red gloves and cuffs, and a raised web pattern (radial spokes joined by
/// sagging rings) swept over the hood, chest, back and shoulders. The right wrist carries a web shooter that fires a
/// strand with a splat. The chest mark is an original six-spoke web star; no character names, logos or film marks.
/// Origin at the neck base, face toward +Z, up +Y, wearer's left = +X.
///
/// Kit parts (pivots in asset space): `helmet` (0, 0, 0), `chest` (0, -0.18, 0.12), `back` (0, -0.20, -0.12),
/// `shoulderL` / `shoulderR` (+-0.20, -0.05, 0), `gauntletL` / `gauntletR` (+-0.215, -0.31, 0) with the forearm along -Y.
///
/// Joints (set with `setJoints`): `lenses` (0...1) squints the eye lenses (wide dark glass to narrow lit slits), `web`
/// (0...1) fires the wrist shooter (strand and splat out along the forearm axis, -Y), `cling` (0...1) shows three
/// spider-sense ripple rings around the head, `point` (0...1) is a driver for the lens point-pose blend. 0...1 joints are
/// empty drivers; followers `lensGlow`, `webShot`, `senseRipple` switch between option 0 and option 1 when the joint
/// passes 0.05. 2 LODs.
public struct WebSuit: RealArticulated {
    public static let id = "web-suit"
    public static let summary = "Red and blue webbed suit kit: slanted-lens hood, raised web pattern, web star chest mark, wrist web shooter with strand and splat, spider-sense ripple rings."
    public static let tags = ["prop", "rubber", "fabric", "articulated", "glowing"]
    public static let budget = 20_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 8, distance: 1.0)

    /// Red suit panels, hood, gloves and cuffs.
    public var redMat: MaterialKey = "rubber.insulating-red"
    /// Blue limb and flank panels.
    public var blueMat: MaterialKey = "fabric.nylon"
    /// Raised web strands.
    public var webMat: MaterialKey = "rubber.insulating-black"
    /// Web shooter housing, nozzle and the fired strand.
    public var gunmetal: MaterialKey = "metal.steel"
    /// Trim rings and rivets.
    public var trimMat: MaterialKey = "metal.titanium"
    /// Lit lens, ripple rings.
    public var glow: MaterialKey = "emissive.surgical"
    /// Unlit lens glass.
    public var glass: MaterialKey = "plastic.black"
    public init() {}

    static let elbowX: Float = 0.215
    static let elbowY: Float = -0.31
    static let shoulderX: Float = 0.20

    func rad(_ d: Float) -> Float { d * .pi / 180 }
    func octagon(_ w: Float, _ h: Float, chamfer c: Float) -> [V2] {
        let a = w / 2, b = h / 2
        return [V2(-a + c, -b), V2(a - c, -b), V2(a, -b + c), V2(a, b - c), V2(a - c, b), V2(-a + c, b), V2(-a, b - c), V2(-a, -b + c)]
    }

    /// Curved panel: an arch swept across `right`, bowed toward `out`, chamfered octagon section that falls off at the ends.
    func plate(_ c: V3, right: V3, up: V3, out: V3, width: Float, height: Float, thick: Float, bulge: Float,
               hi: Bool, _ mat: MaterialKey) -> Surface {
        let n = hi ? 11 : 5
        var path: [V3] = [], scales: [Float] = []
        for i in 0..<n {
            let s = Float(i) / Float(n - 1) * 2 - 1
            path.append(c + right * (s * width / 2) + out * (bulge * (1 - s * s)))
            scales.append(0.14 + 0.86 * pow(max(0, 1 - pow(abs(s), 3)), 0.45))
        }
        return Prim.sweep(octagon(height, thick, chamfer: min(height, thick) * 0.3), along: path, up: up, scales: scales, caps: true, material: mat)
    }

    /// Hood shell rings: a snug oval head, rounded brow, tapering jaw, open neck at the bottom.
    func hoodRings(hi: Bool) -> [[V3]] {
        let rows = hi ? 16 : 8, sides = hi ? 48 : 20
        var rings: [[V3]] = []
        for j in 0...rows {
            let t = Float(j) / Float(rows)
            let dome = sqrt(max(0, 1 - pow(max(0, (t - 0.5) / 0.5), 2.2)))
            let jaw = 0.66 + 0.34 * smoothstep(0, 0.3, t)
            let k = max(0.02, dome) * jaw
            let a = 0.098 * k
            let front = 0.118 * k
            let back = 0.13 * k
            let outline: [V2] = (0..<sides).map { i in
                let ang = Float(i) / Float(sides) * 2 * .pi, s = sin(ang)
                return V2(cos(ang) * a, s * (s >= 0 ? back : front))
            }
            rings.append(Prim.ring(outline, y: 0.005 + 0.31 * t, offset: V3(0, 0, 0.01)))
        }
        return rings
    }

    /// Raised web pattern on a dome-bowed patch: `spokes` radial strands from the centre joined by `rings` sagging arcs.
    func webPatch(hi: Bool, _ part: String, in rig: inout Rig, lod l: Int, center c: V3, right: V3, up: V3, out: V3,
                  radius R: Float, bulge b: Float, spokes: Int = 8, rings: Int = 3) {
        func pt(_ r: Float, _ a: Float) -> V3 {
            let x = r * cos(a), y = r * sin(a)
            return c + right * x + up * y + out * (b * (1 - (r * r) / (R * R)) + 0.0025)
        }
        let sides = hi ? 6 : 3
        for k in 0..<spokes {
            let a = Float(k) / Float(spokes) * 2 * .pi
            let path = (0..<4).map { pt(R * Float($0 + 0) / 3 * 0.96 + 0.01, a) }
            rig.add(Prim.tube(path, radii: path.indices.map { 0.0034 - 0.0006 * Float($0) / 3 }, sides: sides, seamTile: 0.02, material: webMat, capEnd: true),
                    .identity, to: part, option: 0, lods: l...l)
            guard hi || k % 2 == 0 else { continue }
            let a2 = Float(k + 1) / Float(spokes) * 2 * .pi
            for j in 1...rings {
                let r = R * Float(j) / (Float(rings) + 0.4)
                let mid = pt(r * 0.88, (a + a2) / 2)
                let path2 = [pt(r, a), mid, pt(r, a2)]
                rig.add(Prim.tube(path2, radii: [0.0024, 0.0022, 0.0024], sides: sides, seamTile: 0.02, material: webMat, capEnd: true),
                        .identity, to: part, option: 0, lods: l...l)
            }
        }
    }

    // MARK: Rig

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [3])
        let X = V3(1, 0, 0), Y = V3(0, 1, 0), Z = V3(0, 0, 1)
        let flipX = simd_quatf(angle: .pi, axis: X)
        let hip = V3(0, -0.53, 0)

        // Drivers first so option links resolve.
        for name in ["lenses", "web", "cling", "point"] {
            _ = rig.part(name, pivot: .zero, joint: .hinge(axis: Y, 0...1, duration: 0.5))
        }
        let pivots: [(String, V3)] = [
            ("helmet", V3(0, 0, 0)), ("chest", V3(0, -0.18, 0.12)), ("back", V3(0, -0.20, -0.12)),
            ("shoulderL", V3(Self.shoulderX, -0.05, 0)), ("shoulderR", V3(-Self.shoulderX, -0.05, 0)),
            ("gauntletL", V3(Self.elbowX, Self.elbowY, 0)), ("gauntletR", V3(-Self.elbowX, Self.elbowY, 0)),
        ]
        for (name, p) in pivots { _ = rig.part(name, pivot: p, joint: .fixed) }
        _ = rig.part("lensGlow", parent: "helmet", pivot: V3(0, 0.17, 0.1), joint: .fixed, options: 2)
        _ = rig.part("senseRipple", parent: "helmet", pivot: V3(0, 0.17, 0), joint: .fixed, options: 2)
        _ = rig.part("webShot", parent: "gauntletR", pivot: V3(-Self.elbowX, Self.elbowY, 0), joint: .fixed, options: 2)
        rig.optionLinks = [
            RigOptionLink(part: "lensGlow", joint: "lenses", thresholds: [0.05]),
            RigOptionLink(part: "senseRipple", joint: "cling", thresholds: [0.05]),
            RigOptionLink(part: "webShot", joint: "web", thresholds: [0.05]),
        ]

        for l in 0..<2 {
            let hi = l == 0
            let sides = hi ? 48 : 16
            func put(_ s: Surface, _ part: String, option: Int = 0, _ x: Xform = .identity) {
                rig.add(s, x, to: part, option: option, lods: l...l)
            }
            func rivet(_ part: String, _ at: V3, _ dir: V3) {
                put(Prim.lathe([V2(0.006, 0), V2(0.0045, 0.003), V2(0.001, 0.0044)], segments: 10, seamTile: 0.02, material: trimMat), part,
                    Xform(translation: at, rotation: simd_quatf(from: Y, to: dir)))
            }
            func panel(_ part: String, _ c: V3, right: V3, up: V3, out: V3, w: Float, h: Float, t: Float, b: Float,
                       _ mat: MaterialKey? = nil) {
                put(plate(c, right: right, up: up, out: out, width: w, height: h, thick: t, bulge: b, hi: hi, mat ?? blueMat), part)
            }

            // MARK: Hood: shell, web pattern, slanted lenses, brow seams, ripple rings
            do {
                put(Prim.loft(hoodRings(hi: hi), capStart: true, capEnd: true, material: redMat), "helmet")
                webPatch(hi: hi, "helmet", in: &rig, lod: l, center: V3(0, 0.3, -0.01), right: X, up: Z, out: Y, radius: 0.1, bulge: 0.0, spokes: 8, rings: 3)
                webPatch(hi: hi, "helmet", in: &rig, lod: l, center: V3(0, 0.2, -0.125), right: X, up: Y, out: -Z, radius: 0.095, bulge: 0.01, spokes: 8, rings: 3)
                for sx in [Float(-1), 1] {
                    let a = rad(26)
                    let r = V3(cos(a), sx * sin(a), 0)
                    // Rim around each lens, the dark glass lens (option 0, wide) and the lit squinted lens (option 1, narrow).
                    panel("helmet", V3(sx * 0.052, 0.17, 0.097), right: r, up: Y, out: Z, w: 0.112, h: 0.062, t: 0.008, b: 0.016, webMat)
                    put(plate(V3(sx * 0.052, 0.17, 0.103), right: r, up: Y, out: Z, width: 0.1, height: 0.05, thick: 0.01, bulge: 0.014, hi: hi, glass), "lensGlow", option: 0)
                    put(plate(V3(sx * 0.052, 0.17, 0.106), right: r, up: Y, out: Z, width: 0.1, height: 0.022, thick: 0.01, bulge: 0.014, hi: hi, glow), "lensGlow", option: 1)
                }
                // Jaw seam and neck collar.
                let jaw = (0..<(hi ? 9 : 4)).map { i -> V3 in
                    let s = Float(i) / Float(hi ? 8 : 3) * 2 - 1
                    return V3(0.1 * s, 0.045 + 0.02 * s * s, 0.1 * (1 - s * s) + 0.015)
                }
                put(Prim.tube(jaw, radii: jaw.map { _ in 0.0032 }, sides: hi ? 8 : 4, seamTile: 0.02, material: webMat, capEnd: true), "helmet")
                put(Prim.lathe([V2(0.07, 0), V2(0.088, 0.008), V2(0.092, 0.04), V2(0.082, 0.07)], segments: sides, seamTile: 0.1, material: blueMat), "helmet",
                    Xform(translation: V3(0, -0.05, -0.005)))
                // Spider-sense ripple: three emissive rings stepped up the head (option 1 only).
                for k in 0..<3 {
                    let f = Float(k)
                    put(Prim.torus(major: 0.16 + 0.05 * f, minor: 0.0035, segments: hi ? 64 : 24, sides: hi ? 12 : 6, material: glow), "senseRipple", option: 1,
                        Xform(translation: V3(0, 0.17 + 0.012 * f, 0), rotation: simd_quatf(angle: rad(90), axis: X), scale: V3(1, 0.9, 1)))
                }
            }

            // MARK: Chest: red torso, blue flanks, web star, belt
            do {
                put(Prim.superellipsoid(V3(0.36, 0.78, 0.24), exponent: 2.4, subdivisions: hi ? 6 : 3, material: redMat), "chest", Xform(translation: V3(0, -0.38, 0)))
                let tilt = rad(14)
                for sx in [Float(-1), 1] {
                    let r = V3(cos(tilt), 0, -sx * sin(tilt)), o = V3(sx * sin(tilt), 0, cos(tilt))
                    webPatch(hi: hi, "chest", in: &rig, lod: l, center: V3(sx * 0.092, -0.12, 0.095), right: r, up: Y, out: o, radius: 0.1, bulge: 0.03)
                    // Blue flank panel along each side.
                    panel("chest", V3(sx * 0.165, -0.3, 0.02), right: Z, up: Y, out: X * sx, w: 0.19, h: 0.3, t: 0.012, b: 0.014)
                }
                // Original web star mark: six spokes and a ring, raised in black.
                let at = V3(0, -0.14, 0.168)
                let ringPts = (0...6).map { i -> V3 in
                    let a = Float(i % 6) / 6 * 2 * .pi
                    return at + V3(0.034 * cos(a), 0.034 * sin(a), 0)
                }
                put(Prim.tube(ringPts, radii: ringPts.map { _ in 0.0035 }, sides: hi ? 12 : 5, seamTile: 0.02, material: webMat, capEnd: true), "chest")
                for k in 0..<6 {
                    let a = Float(k) / 6 * 2 * .pi
                    put(Prim.tube([at, at + V3(0.07 * cos(a), 0.07 * sin(a), -0.004)], radii: [0.004, 0.003], sides: hi ? 10 : 4, seamTile: 0.02, material: webMat, capEnd: true), "chest")
                }
                put(Prim.torus(major: 0.17, minor: 0.016, segments: hi ? 64 : 24, sides: hi ? 12 : 6, material: blueMat), "chest",
                    Xform(translation: hip, scale: V3(1, 1, 0.72)))
                panel("chest", hip + V3(0, 0, 0.125), right: X, up: Y, out: Z, w: 0.07, h: 0.045, t: 0.014, b: 0.01, trimMat)
                rivet("chest", hip + V3(0.03, 0, 0.14), Z)
                rivet("chest", hip + V3(-0.03, 0, 0.14), Z)
            }

            // MARK: Back: web pattern and spine seam
            do {
                webPatch(hi: hi, "back", in: &rig, lod: l, center: V3(0, -0.16, -0.095), right: X, up: Y, out: -Z, radius: 0.13, bulge: 0.02, spokes: 8, rings: 4)
                put(Prim.tube([V3(0, 0.02, -0.15), V3(0, -0.2, -0.17), V3(0, -0.42, -0.14)], radii: [0.005, 0.006, 0.005], sides: hi ? 16 : 6, seamTile: 0.03, material: webMat, capEnd: true), "back")
            }

            // MARK: Shoulders: blue arm, red cap with web pattern
            for (sx, name) in [(Float(1), "shoulderL"), (Float(-1), "shoulderR")] {
                let tiltZ = simd_quatf(angle: -sx * 0.3, axis: Z)
                let base = V3(sx * 0.235, -0.07, 0)
                put(Prim.tube([V3(sx * 0.2, -0.05, 0), V3(sx * 0.208, -0.18, 0), V3(sx * Self.elbowX, Self.elbowY, 0)], radii: [0.052, 0.048, 0.043], sides: hi ? 24 : 8, seamTile: 0.05, material: blueMat, capEnd: true), name)
                put(Prim.lathe([V2(0.1, 0), V2(0.108, 0.01), V2(0.098, 0.035), V2(0.078, 0.056), V2(0.046, 0.072), V2(0.001, 0.078)], segments: sides, seamTile: 0.1, material: redMat),
                    name, Xform(translation: base, rotation: tiltZ, scale: V3(1, 1, 1.1)))
                webPatch(hi: hi, name, in: &rig, lod: l, center: base + V3(0, 0.074, 0), right: X, up: Z, out: Y, radius: 0.07, bulge: 0.0, spokes: 6, rings: 3)
                put(Prim.torus(major: 0.103, minor: 0.005, segments: hi ? 48 : 16, sides: hi ? 10 : 5, material: webMat), name,
                    Xform(translation: base + V3(0, 0.003, 0), rotation: tiltZ, scale: V3(1, 1, 1.1)))
            }

            // MARK: Forearms: blue sleeve, red cuff and glove, wrist web shooter on the right (-X)
            for (sx, name) in [(Float(1), "gauntletL"), (Float(-1), "gauntletR")] {
                let e = V3(sx * Self.elbowX, Self.elbowY, 0)
                put(Prim.tube([e, e + V3(0, -0.12, 0), e + V3(0, -0.25, 0)], radii: [0.045, 0.043, 0.04], sides: hi ? 24 : 8, seamTile: 0.05, material: blueMat, capEnd: true), name)
                put(Prim.lathe([V2(0.056, 0), V2(0.06, 0.012), V2(0.054, 0.045), V2(0.048, 0.06), V2(0.044, 0.064)], segments: sides, seamTile: 0.08, material: redMat),
                    name, Xform(translation: e + V3(0, -0.2, 0), rotation: flipX))
                put(Prim.tube([e + V3(0, -0.23, 0), e + V3(0, -0.26, 0.0)], radii: [0.04, 0.042], sides: hi ? 24 : 8, seamTile: 0.05, material: redMat, capEnd: true), name)
                put(Prim.superellipsoid(V3(0.085, 0.1, 0.1), exponent: 2.6, subdivisions: hi ? 6 : 3, material: redMat), name, Xform(translation: e + V3(0, -0.3, 0.005)))
                // Web lines on the back of the glove.
                for k in 0..<3 {
                    let x = (Float(k) - 1) * 0.022
                    let path = [e + V3(x, -0.26, 0.052), e + V3(x * 1.2, -0.3, 0.058), e + V3(x * 1.5, -0.34, 0.05)]
                    put(Prim.tube(path, radii: [0.0028, 0.0028, 0.0022], sides: hi ? 6 : 3, seamTile: 0.02, material: webMat, capEnd: true), name)
                }
            }
            // Shooter on the right wrist: housing, nozzle, both states. The shot adds a strand (48 sides) and a splat.
            do {
                let e = V3(-Self.elbowX, Self.elbowY, 0)
                let top = e + V3(0, -0.2, 0.05)
                put(Prim.superellipsoid(V3(0.05, 0.085, 0.036), exponent: 3, subdivisions: hi ? 5 : 3, material: gunmetal), "gauntletR", Xform(translation: top + V3(0, -0.01, 0)))
                put(Prim.tube([top + V3(0, -0.05, 0), top + V3(0, -0.085, 0)], radii: [0.012, 0.0095], sides: sides, seamTile: 0.03, material: gunmetal, capEnd: true), "gauntletR")
                put(Prim.torus(major: 0.011, minor: 0.0028, segments: hi ? 48 : 16, sides: hi ? 10 : 5, material: trimMat), "gauntletR",
                    Xform(translation: top + V3(0, -0.058, 0), rotation: simd_quatf(angle: rad(90), axis: X)))
                // Fired: strand along -Y (0.55 m) ending in an irregular splat of radiating arms.
                let n = hi ? 7 : 3
                let line = (0..<n).map { i in top + V3(0.004 * sin(Float(i) * 1.3), -0.085 - 0.465 * Float(i) / Float(n - 1), 0) }
                put(Prim.tube(line, radii: line.map { _ in 0.0032 }, sides: sides, seamTile: 0.02, material: webMat, capEnd: true), "webShot", option: 1)
                let hookAt = top + V3(0, -0.56, 0)
                put(Prim.lathe([V2(0.001, 0), V2(0.03, 0.002), V2(0.026, 0.006), V2(0.008, 0.012), V2(0.001, 0.014)], segments: sides, seamTile: 0.03, material: webMat), "webShot", option: 1,
                    Xform(translation: hookAt + V3(0, -0.014, 0), rotation: flipX))
                for k in 0..<7 {
                    let a = Float(k) / 7 * 2 * .pi + 0.2 * Float(k % 2)
                    let len: Float = 0.05 + 0.025 * Float((k * 3) % 3)
                    let path = (0..<(hi ? 4 : 2)).map { i -> V3 in
                        let u = Float(i) / Float(hi ? 3 : 1)
                        return hookAt + V3(len * u * cos(a), -0.014 - 0.006 * u, len * u * sin(a))
                    }
                    put(Prim.tube(path, radii: path.indices.map { 0.0046 * (1 - 0.7 * Float($0) / Float(max(1, path.count - 1))) + 0.001 }, sides: hi ? 10 : 4, seamTile: 0.02, material: webMat, capEnd: true),
                        "webShot", option: 1)
                }
            }
        }

        rig.states = [
            RigState("rest", [:]),
            RigState("squint", ["lenses": 1], options: ["lensGlow": 1]),
            RigState("sense", ["lenses": 1, "cling": 1], options: ["lensGlow": 1, "senseRipple": 1]),
            RigState("point", ["lenses": 1, "point": 1], options: ["lensGlow": 1]),
            RigState("shoot", ["lenses": 1, "web": 1, "point": 1], options: ["lensGlow": 1, "webShot": 1]),
        ]
        return rig
    }
}
