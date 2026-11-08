import simd
import Foundation

/// Black liquid-symbiote suit kit, life size for a 1.75 m wearer. A glossy black bio-mass sheath: bulbous helmet with two
/// slanted eye patches and a wide fanged grin, swollen pectoral and deltoid masses with sinew ridges, clawed gauntlets,
/// a ridged back with coiled tendril stubs, and hanging goo drips. Origin at the neck base, face toward +Z, up +Y,
/// wearer's left = +X. No logos or character emblems; every shape is a generic organic form.
///
/// Kit parts (pivots in asset space): `helmet` (0, 0, 0), `chest` (0, -0.18, 0.12), `back` (0, -0.20, -0.12),
/// `shoulderL` / `shoulderR` (+-0.20, -0.05, 0), `gauntletL` / `gauntletR` (+-0.215, -0.31, 0) with the forearm along -Y.
///
/// Joints (set with `setJoints`): `grin` (0...1) opens the fanged mouth, `tendril` (0...1) extends four back tendrils,
/// `eyes` (0...1) flares the white eye patches, `ooze` (-1...1) is a driver for the lens surface ripple. Each 0...1 joint
/// is an empty driver part; its follower (`grinOpen`, `tendrils`, `eyeGlow`) switches between option 0 and option 1
/// when the joint passes 0.05. 2 LODs.
public struct SymbioteSuit: RealArticulated {
    public static let id = "symbiote-suit"
    public static let summary = "Black symbiote suit kit: glossy bio-mass sheath, slanted eye patches, fanged grin that opens, back tendrils, clawed gauntlets and goo drips."
    public static let tags = ["prop", "metal", "leather", "articulated", "glowing"]
    public static let budget = 20_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 8, distance: 1.0)

    /// Main glossy black mass.
    public var body: MaterialKey = "plastic.black"
    /// Sinew ridges and claws, a duller black.
    public var sinew: MaterialKey = "rubber"
    /// Eye patch frames and fangs.
    public var tooth: MaterialKey = "plastic.white"
    /// Tongue and mouth interior.
    public var flesh: MaterialKey = "leather.oxblood"
    /// Eye flare.
    public var glow: MaterialKey = "emissive.surgical"
    public init() {}

    static let elbowX: Float = 0.215
    static let elbowY: Float = -0.31
    static let shoulderX: Float = 0.20

    func rad(_ d: Float) -> Float { d * .pi / 180 }
    func octagon(_ w: Float, _ h: Float, chamfer c: Float) -> [V2] {
        let a = w / 2, b = h / 2
        return [V2(-a + c, -b), V2(a - c, -b), V2(a, -b + c), V2(a, b - c), V2(a - c, b), V2(-a + c, b), V2(-a, b - c), V2(-a, -b + c)]
    }

    /// Rounded lens-shaped mass swept across `right`, bowed toward `out`; the section tapers to a point at both ends.
    func mass(_ c: V3, right: V3, up: V3, out: V3, width: Float, height: Float, thick: Float, bulge: Float,
              hi: Bool, _ mat: MaterialKey) -> Surface {
        let n = hi ? 11 : 5
        var path: [V3] = [], scales: [Float] = []
        for i in 0..<n {
            let s = Float(i) / Float(n - 1) * 2 - 1
            path.append(c + right * (s * width / 2) + out * (bulge * (1 - s * s)))
            scales.append(0.1 + 0.9 * pow(max(0, 1 - pow(abs(s), 2)), 0.5))
        }
        return Prim.sweep(octagon(height, thick, chamfer: min(height, thick) * 0.42), along: path, up: up, scales: scales, caps: true, material: mat)
    }

    /// Rings of the bulbous head, ascending from the neck to the crown.
    func headRings(hi: Bool) -> [[V3]] {
        let rows = hi ? 16 : 8, sides = hi ? 48 : 20
        var rings: [[V3]] = []
        for j in 0...rows {
            let t = Float(j) / Float(rows)
            let dome = sqrt(max(0, 1 - pow(max(0, (t - 0.5) / 0.5), 2.2)))
            let jaw = 0.66 + 0.34 * smoothstep(0, 0.3, t)
            let k = max(0.02, dome) * jaw
            let a = 0.1 * k
            let front = 0.122 * k * (1 + 0.12 * smoothstep(0.35, 0.6, t) * (1 - smoothstep(0.6, 0.9, t)))
            let back = 0.135 * k
            let outline: [V2] = (0..<sides).map { i in
                let ang = Float(i) / Float(sides) * 2 * .pi, s = sin(ang)
                return V2(cos(ang) * a, s * (s >= 0 ? back : front))
            }
            rings.append(Prim.ring(outline, y: 0.005 + 0.32 * t, offset: V3(0, 0, 0.01)))
        }
        return rings
    }

    // MARK: Rig

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [3])
        let X = V3(1, 0, 0), Y = V3(0, 1, 0), Z = V3(0, 0, 1)
        let flipX = simd_quatf(angle: .pi, axis: X)

        // Drivers first so option links resolve.
        for name in ["grin", "tendril", "eyes"] {
            _ = rig.part(name, pivot: .zero, joint: .hinge(axis: Y, 0...1, duration: 0.5))
        }
        _ = rig.part("ooze", pivot: .zero, joint: .hinge(axis: Y, -1...1, duration: 0.5))
        let pivots: [(String, V3)] = [
            ("helmet", V3(0, 0, 0)), ("chest", V3(0, -0.18, 0.12)), ("back", V3(0, -0.20, -0.12)),
            ("shoulderL", V3(Self.shoulderX, -0.05, 0)), ("shoulderR", V3(-Self.shoulderX, -0.05, 0)),
            ("gauntletL", V3(Self.elbowX, Self.elbowY, 0)), ("gauntletR", V3(-Self.elbowX, Self.elbowY, 0)),
        ]
        for (name, p) in pivots { _ = rig.part(name, pivot: p, joint: .fixed) }
        _ = rig.part("eyeGlow", parent: "helmet", pivot: V3(0, 0.165, 0.1), joint: .fixed, options: 2)
        _ = rig.part("grinOpen", parent: "helmet", pivot: V3(0, 0.06, 0.1), joint: .fixed, options: 2)
        _ = rig.part("tendrils", parent: "back", pivot: V3(0, -0.20, -0.12), joint: .fixed, options: 2)
        rig.optionLinks = [
            RigOptionLink(part: "eyeGlow", joint: "eyes", thresholds: [0.05]),
            RigOptionLink(part: "grinOpen", joint: "grin", thresholds: [0.05]),
            RigOptionLink(part: "tendrils", joint: "tendril", thresholds: [0.05]),
        ]

        for l in 0..<2 {
            let hi = l == 0
            var rng = SeededRNG(seed: seed)  // reseeded per LOD so both LODs match
            let sides = hi ? 48 : 16
            func put(_ s: Surface, _ part: String, option: Int = 0, _ x: Xform = .identity) {
                rig.add(s, x, to: part, option: option, lods: l...l)
            }
            func ridge(_ part: String, _ path: [V3], r0: Float, r1: Float, _ mat: MaterialKey? = nil) {
                let n = path.count
                let radii = (0..<n).map { i -> Float in
                    let f = Float(i) / Float(n - 1)
                    return (r0 + (r1 - r0) * f) * (0.8 + 0.2 * sin(f * .pi))
                }
                put(Prim.tube(path, radii: radii, sides: hi ? 24 : 8, seamTile: 0.05, material: mat ?? sinew, capEnd: true), part)
            }
            /// Hanging goo drip: narrow neck, round bulb at the bottom. `at` is the bulb's lowest point.
            func drip(_ part: String, _ at: V3, _ len: Float) {
                let k = len / 0.05
                put(Prim.lathe([V2(0.001, 0), V2(0.006 * k, 0.004 * k), V2(0.0085 * k, 0.012 * k), V2(0.007 * k, 0.022 * k), V2(0.0045 * k, 0.04 * k), V2(0.0035 * k, len)],
                               segments: hi ? 24 : 8, seamTile: 0.05, material: body), part, Xform(translation: at))
            }

            // MARK: Helmet, eye patches, grin
            do {
                put(Prim.loft(headRings(hi: hi), capStart: true, capEnd: true, material: body), "helmet")
                // Brow mass over each eye and a cranial ridge.
                for sx in [Float(-1), 1] {
                    let a = rad(24)
                    let r = V3(cos(a), sx * sin(a), 0)
                    put(mass(V3(sx * 0.052, 0.19, 0.062), right: r, up: Y, out: Z, width: 0.13, height: 0.03, thick: 0.03, bulge: 0.04, hi: hi, sinew), "helmet")
                    // Eye patch: dark recessed lens, white glow lens in front of it on `eyes`.
                    put(mass(V3(sx * 0.05, 0.165, 0.104), right: r, up: Y, out: Z, width: 0.115, height: 0.04, thick: 0.014, bulge: 0.012, hi: hi, body), "helmet")
                    put(mass(V3(sx * 0.05, 0.165, 0.111), right: r, up: Y, out: Z, width: 0.105, height: 0.03, thick: 0.01, bulge: 0.012, hi: hi, glow), "eyeGlow", option: 1)
                    put(mass(V3(sx * 0.05, 0.165, 0.11), right: r, up: Y, out: Z, width: 0.105, height: 0.03, thick: 0.01, bulge: 0.012, hi: hi, tooth), "eyeGlow", option: 0)
                }
                let n = hi ? 13 : 6
                let crest = (0..<n).map { i -> V3 in
                    let phi = rad(-70) + Float(i) / Float(n - 1) * rad(130)
                    let rz: Float = phi > 0 ? 0.124 : 0.136
                    return V3(0, 0.17 + 0.155 * cos(phi) + 0.004, 0.01 + rz * sin(phi))
                }
                put(Prim.tube(crest, radii: crest.enumerated().map { 0.006 + 0.004 * sin(Float($0.offset) / Float(n - 1) * .pi) }, sides: hi ? 24 : 8,
                              seamTile: 0.03, material: sinew, capEnd: true), "helmet")
                // Closed grin: lip tube curving up at the corners, with a short row of upper teeth (option 0 of grinOpen).
                let m = hi ? 15 : 7
                func grinPath(_ y0: Float, _ lift: Float, _ zOff: Float) -> [V3] {
                    (0..<m).map { i -> V3 in
                        let x = (Float(i) / Float(m - 1) * 2 - 1) * 0.075
                        return V3(x, y0 + lift * pow(x / 0.075, 2), 0.113 - 1.6 * x * x + zOff)
                    }
                }
                let lip = grinPath(0.066, 0.024, 0.004)
                put(Prim.tube(lip, radii: lip.map { _ in 0.0045 }, sides: hi ? 16 : 6, seamTile: 0.02, material: sinew, capEnd: true), "grinOpen", option: 0)
                let teeth = hi ? 9 : 5
                for i in 0..<teeth {
                    let f = Float(i) / Float(teeth - 1) * 2 - 1
                    let x = f * 0.07
                    let at = V3(x, 0.064 + 0.024 * f * f, 0.114 - 1.6 * x * x + 0.004)
                    put(Prim.lathe([V2(0.0045, 0), V2(0.0038, 0.006), V2(0.001, 0.014)], segments: hi ? 16 : 6, seamTile: 0.02, material: tooth), "grinOpen", option: 0,
                        Xform(translation: at, rotation: flipX))
                }
                // Open maw: dark interior, upper and lower fang rows, long tongue.
                put(Prim.superellipsoid(V3(0.15, 0.085, 0.05), exponent: 2.2, subdivisions: hi ? 6 : 3, material: flesh), "grinOpen", option: 1,
                    Xform(translation: V3(0, 0.045, 0.092)))
                let upper = grinPath(0.092, 0.03, 0.006), lower = grinPath(0.0, 0.02, 0.0)
                put(Prim.tube(upper, radii: upper.map { _ in 0.0055 }, sides: hi ? 16 : 6, seamTile: 0.02, material: sinew, capEnd: true), "grinOpen", option: 1)
                put(Prim.tube(lower, radii: lower.map { _ in 0.0055 }, sides: hi ? 16 : 6, seamTile: 0.02, material: sinew, capEnd: true), "grinOpen", option: 1)
                for i in 0..<teeth {
                    let f = Float(i) / Float(teeth - 1) * 2 - 1
                    let x = f * 0.07
                    let len: Float = (i % 2 == 0) ? 0.036 : 0.022
                    let zb = 0.113 - 1.6 * x * x
                    put(Prim.lathe([V2(0.0055, 0), V2(0.0045, len * 0.4), V2(0.001, len)], segments: hi ? 16 : 6, seamTile: 0.02, material: tooth), "grinOpen", option: 1,
                        Xform(translation: V3(x, 0.092 + 0.03 * f * f, zb + 0.006), rotation: flipX))
                    put(Prim.lathe([V2(0.005, 0), V2(0.004, len * 0.35), V2(0.001, len * 0.8)], segments: hi ? 16 : 6, seamTile: 0.02, material: tooth), "grinOpen", option: 1,
                        Xform(translation: V3(x, 0.0 + 0.02 * f * f, zb)))
                }
                let tongue = (0..<(hi ? 12 : 6)).map { i -> V3 in
                    let f = Float(i) / Float(hi ? 11 : 5)
                    return V3(0.012 * sin(f * 7), 0.03 - 0.12 * f * f - 0.02 * f, 0.1 + 0.2 * f)
                }
                put(Prim.tube(tongue, radii: tongue.indices.map { 0.02 * (1 - 0.6 * Float($0) / Float(tongue.count - 1)) }, sides: hi ? 32 : 8, seamTile: 0.04,
                              material: flesh, capEnd: true), "grinOpen", option: 1)
                // Brow-to-cheek sinews and neck cords.
                for sx in [Float(-1), 1] {
                    ridge("helmet", [V3(sx * 0.09, 0.2, 0.04), V3(sx * 0.108, 0.13, 0.03), V3(sx * 0.1, 0.05, 0.02), V3(sx * 0.085, -0.01, 0.0)], r0: 0.008, r1: 0.005)
                    ridge("helmet", [V3(sx * 0.03, 0.0, 0.07), V3(sx * 0.05, -0.04, 0.05), V3(sx * 0.07, -0.08, 0.02)], r0: 0.011, r1: 0.008)
                }
                put(Prim.lathe([V2(0.072, 0), V2(0.088, 0.012), V2(0.082, 0.04), V2(0.068, 0.056)], segments: sides, seamTile: 0.1, material: body), "helmet",
                    Xform(translation: V3(0, -0.055, 0)))
            }

            // MARK: Chest
            do {
                put(Prim.superellipsoid(V3(0.38, 0.78, 0.25), exponent: 2.3, subdivisions: hi ? 6 : 3, material: body), "chest", Xform(translation: V3(0, -0.38, 0)))
                let tilt = rad(14)
                for sx in [Float(-1), 1] {
                    let r = V3(cos(tilt), 0, -sx * sin(tilt)), o = V3(sx * sin(tilt), 0, cos(tilt))
                    put(mass(V3(sx * 0.095, -0.12, 0.075), right: r, up: Y, out: o, width: 0.2, height: 0.16, thick: 0.05, bulge: 0.04, hi: hi, body), "chest")
                    ridge("chest", [V3(sx * 0.02, -0.05, 0.14), V3(sx * 0.09, -0.07, 0.16), V3(sx * 0.16, -0.1, 0.12), V3(sx * 0.19, -0.14, 0.07)], r0: 0.007, r1: 0.005)
                }
                // Abdomen: three stacked muscle bands with a sternum cord.
                for i in 0..<3 {
                    let f = Float(i)
                    put(mass(V3(0, -0.245 - 0.085 * f, 0.06), right: X, up: Y, out: Z, width: 0.27 - 0.03 * f, height: 0.07, thick: 0.045, bulge: 0.05 - 0.008 * f, hi: hi, body), "chest")
                }
                ridge("chest", [V3(0, -0.04, 0.16), V3(0, -0.14, 0.18), V3(0, -0.24, 0.175), V3(0, -0.36, 0.16), V3(0, -0.48, 0.14)], r0: 0.009, r1: 0.007)
                for k in 0..<3 {
                    let x = (Float(k) - 1) * 0.12
                    drip("chest", V3(x, -0.57 - 0.01 * Float(k % 2), 0.1), 0.05 + 0.03 * rng.float())
                }
            }

            // MARK: Back
            do {
                put(mass(V3(0, -0.2, -0.07), right: X, up: Y, out: -Z, width: 0.34, height: 0.32, thick: 0.05, bulge: 0.07, hi: hi, body), "back")
                ridge("back", [V3(0, 0.0, -0.15), V3(0, -0.1, -0.18), V3(0, -0.2, -0.19), V3(0, -0.3, -0.18), V3(0, -0.4, -0.15)], r0: 0.016, r1: 0.012)
                for k in 0..<4 {
                    let y = -0.1 - 0.075 * Float(k)
                    for sx in [Float(-1), 1] {
                        ridge("back", [V3(sx * 0.02, y, -0.18), V3(sx * 0.1, y - 0.01, -0.16), V3(sx * 0.17, y - 0.04, -0.1)], r0: 0.008, r1: 0.005)
                    }
                }
                // Coiled stubs at rest (option 0): four short curls anchored between the shoulder blades.
                for (k, sx) in [Float(-1), -0.4, 0.4, 1].enumerated() {
                    let base = V3(sx * 0.09, -0.12 - 0.05 * Float(k % 2), -0.19)
                    let n = hi ? 9 : 5
                    let curl = (0..<n).map { i -> V3 in
                        let f = Float(i) / Float(n - 1)
                        return base + V3(sx * 0.03 * f, 0.07 * sin(f * 3.2), -0.05 * f - 0.03 * f * f)
                    }
                    put(Prim.tube(curl, radii: curl.indices.map { 0.022 * (1 - 0.7 * Float($0) / Float(n - 1)) }, sides: hi ? 32 : 8, seamTile: 0.04, material: body, capEnd: true),
                        "tendrils", option: 0)
                }
                // Extended tendrils (option 1): four long reaching arcs ending in blade tips.
                for (k, sx) in [Float(-1), -0.4, 0.4, 1].enumerated() {
                    let base = V3(sx * 0.09, -0.12 - 0.05 * Float(k % 2), -0.19)
                    let spread = sx * (0.5 + 0.1 * rng.float())
                    let n = hi ? 11 : 6
                    let path = (0..<n).map { i -> V3 in
                        let f = Float(i) / Float(n - 1)
                        return base + V3(spread * f * 0.9 + 0.04 * sin(f * 9 + Float(k)) * f, 0.55 * f - 0.25 * f * f + 0.03 * sin(f * 6 + Float(k)),
                                         -0.28 * f - 0.18 * f * f)
                    }
                    put(Prim.tube(path, radii: path.indices.map { 0.026 * pow(1 - Float($0) / Float(n - 1), 0.9) + 0.005 }, sides: hi ? 48 : 12, seamTile: 0.05,
                                  material: body, capEnd: true), "tendrils", option: 1)
                    if let last = path.last, let prev = path.dropLast().last {
                        let dir = simd_normalize(last - prev)
                        put(Prim.lathe([V2(0.001, 0), V2(0.016, 0.02), V2(0.014, 0.05), V2(0.001, 0.12)], segments: hi ? 24 : 8, seamTile: 0.05, material: sinew), "tendrils",
                            option: 1, Xform(translation: last, rotation: simd_quatf(from: Y, to: dir)))
                    }
                }
            }

            // MARK: Shoulders and arms
            for (sx, name) in [(Float(1), "shoulderL"), (Float(-1), "shoulderR")] {
                let tiltZ = simd_quatf(angle: -sx * 0.3, axis: Z)
                put(Prim.tube([V3(sx * 0.2, -0.05, 0), V3(sx * 0.208, -0.18, 0), V3(sx * Self.elbowX, Self.elbowY, 0)], radii: [0.062, 0.058, 0.05], sides: hi ? 32 : 8, seamTile: 0.05, material: body, capEnd: true), name)
                put(Prim.superellipsoid(V3(0.24, 0.2, 0.24), exponent: 2.2, subdivisions: hi ? 6 : 3, material: body), name,
                    Xform(translation: V3(sx * 0.235, -0.06, 0), rotation: tiltZ))
                for k in 0..<3 {
                    let z = (Float(k) - 1) * 0.06
                    ridge(name, [V3(sx * 0.13, 0.03, z), V3(sx * 0.22, 0.045, z * 1.1), V3(sx * 0.31, -0.01, z * 1.2), V3(sx * 0.335, -0.11, z * 1.2)], r0: 0.008, r1: 0.006)
                }
                drip(name, V3(sx * 0.3, -0.22, 0.05), 0.07 + 0.04 * rng.float())
                drip(name, V3(sx * 0.27, -0.2, -0.06), 0.05)
            }
            for (sx, name) in [(Float(1), "gauntletL"), (Float(-1), "gauntletR")] {
                let e = V3(sx * Self.elbowX, Self.elbowY, 0)
                // Forearm mass swelling toward the wrist.
                put(Prim.tube([e, e + V3(0, -0.06, 0), e + V3(0, -0.15, 0), e + V3(0, -0.25, 0)], radii: [0.05, 0.058, 0.052, 0.04], sides: hi ? 32 : 8, seamTile: 0.05, material: body, capEnd: true), name)
                put(Prim.superellipsoid(V3(0.1, 0.1, 0.11), exponent: 2.3, subdivisions: hi ? 6 : 3, material: body), name, Xform(translation: e + V3(0, 0.005, -0.04)))
                ridge(name, [e + V3(sx * 0.03, -0.02, 0.04), e + V3(sx * 0.055, -0.1, 0.03), e + V3(sx * 0.045, -0.2, 0.02)], r0: 0.008, r1: 0.005)
                ridge(name, [e + V3(-sx * 0.03, -0.03, 0.05), e + V3(-sx * 0.05, -0.12, 0.04), e + V3(-sx * 0.04, -0.22, 0.025)], r0: 0.007, r1: 0.005)
                // Fist and four claws, thumb claw.
                put(Prim.superellipsoid(V3(0.09, 0.1, 0.11), exponent: 2.5, subdivisions: hi ? 6 : 3, material: body), name, Xform(translation: e + V3(0, -0.3, 0.005)))
                for k in 0..<4 {
                    let x = (Float(k) - 1.5) * 0.02
                    put(Prim.lathe([V2(0.007, 0), V2(0.0055, 0.03), V2(0.001, 0.085)], segments: hi ? 20 : 6, seamTile: 0.03, material: sinew), name,
                        Xform(translation: e + V3(x, -0.35, 0.05), rotation: simd_quatf(angle: .pi + 0.35, axis: X)))
                }
                put(Prim.lathe([V2(0.008, 0), V2(0.006, 0.03), V2(0.001, 0.07)], segments: hi ? 20 : 6, seamTile: 0.03, material: sinew), name,
                    Xform(translation: e + V3(sx * 0.045, -0.29, 0.03), rotation: simd_quatf(angle: .pi + 0.9, axis: Z)))
                drip(name, e + V3(0, -0.52, 0.0), 0.06 + 0.03 * rng.float())
            }
        }

        rig.states = [
            RigState("rest", [:]),
            RigState("awake", ["eyes": 1], options: ["eyeGlow": 1]),
            RigState("grin", ["eyes": 1, "grin": 1], options: ["eyeGlow": 1, "grinOpen": 1]),
            RigState("lash", ["eyes": 1, "tendril": 1], options: ["eyeGlow": 1, "tendrils": 1]),
            RigState("scream", ["eyes": 1, "grin": 1, "tendril": 1, "ooze": 1], options: ["eyeGlow": 1, "grinOpen": 1, "tendrils": 1]),
        ]
        return rig
    }
}
