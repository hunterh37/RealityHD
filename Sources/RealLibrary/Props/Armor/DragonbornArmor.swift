import simd
import Foundation

/// Dragonborn Nordic armour kit, life size for a 1.75 m wearer. Horned steel helm with glowing eye slits, a steel cuirass
/// over a leather undersuit, fur-trimmed pauldrons, rune-etched gauntlets and a leather and fur cloak. Plates are curved
/// lofts with chamfered edges and rivets. Origin at the neck base, face toward +Z, up +Y, wearer's left = +X.
///
/// Kit parts (pivots in asset space): `helmet` (0, 0, 0), `chest` (0, -0.18, 0.12), `back` (0, -0.20, -0.12),
/// `shoulderL` / `shoulderR` (+-0.20, -0.05, 0), `gauntletL` / `gauntletR` (+-0.215, -0.31, 0) with the forearm along -Y.
///
/// Joints: `eyes`, `rune`, `shout` (0...1) are empty drivers; followers `eyesGlow` (helmet), `runeGlowL` / `runeGlowR`
/// (gauntlets) and `shoutGlow` (helmet mouth) switch between hidden and lit when the driver passes 0.05. `fur` (-1...1)
/// is a hinge about Z on the `fur` part (cloak, collar and back fur), pivot between the shoulder blades. 2 LODs.
public struct DragonbornArmor: RealArticulated {
    public static let id = "dragonborn-armor"
    public static let summary = "Dragonborn Nordic armour kit: horned steel helm with glowing eye slits, fur-trimmed pauldrons, rune-etched gauntlets and a leather and fur cloak."
    public static let tags = ["prop", "metal", "leather", "articulated", "glowing"]
    public static let budget = 20_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 8, distance: 1.0)

    /// Plates, helm and horns.
    public var steel: MaterialKey = "metal.steel"
    /// Trim bands, rivets and dark recesses.
    public var iron: MaterialKey = "metal.iron"
    /// Undersuit, straps, cloak body.
    public var leather: MaterialKey = "leather.tan"
    /// Pauldron trim, collar and cloak edge.
    public var fur: MaterialKey = "fauna.fur"
    /// Eye slits, runes and shout glow.
    public var glow: MaterialKey = "emissive.thruster-cyan"
    public init() {}

    static let elbowX: Float = 0.215
    static let elbowY: Float = -0.31
    static let shoulderX: Float = 0.20

    func rad(_ d: Float) -> Float { d * .pi / 180 }
    func octagon(_ w: Float, _ h: Float, chamfer c: Float) -> [V2] {
        let a = w / 2, b = h / 2
        return [V2(-a + c, -b), V2(a - c, -b), V2(a, -b + c), V2(a, b - c), V2(a - c, b), V2(-a + c, b), V2(-a, b - c), V2(-a, -b + c)]
    }

    /// Curved plate: chamfered octagon swept along an arch bowed toward `out`, tapering at the ends.
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

    /// Rings of the helm shell, ascending from the neck to the crown; the brow and nose guard bulge forward.
    func helmetRings(hi: Bool) -> [[V3]] {
        let rows = hi ? 16 : 8, sides = hi ? 48 : 20
        var rings: [[V3]] = []
        for j in 0...rows {
            let t = Float(j) / Float(rows)
            let dome = sqrt(max(0, 1 - pow(max(0, (t - 0.5) / 0.5), 2.2)))
            let jaw = 0.66 + 0.34 * smoothstep(0, 0.3, t)
            let k = max(0.02, dome) * jaw
            let a = 0.1 * k, front = 0.118 * k, back = 0.13 * k
            let outline: [V2] = (0..<sides).map { i in
                let ang = Float(i) / Float(sides) * 2 * .pi, s = sin(ang)
                return V2(cos(ang) * a, s * (s >= 0 ? back : front))
            }
            rings.append(Prim.ring(outline, y: 0.005 + 0.31 * t, offset: V3(0, 0, 0.01)))
        }
        return rings
    }

    // MARK: Rig

    public func rig(seed: UInt64) -> Rig {
        var rng = SeededRNG(seed: seed)
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [3])
        let X = V3(1, 0, 0), Y = V3(0, 1, 0), Z = V3(0, 0, 1)
        let flipX = simd_quatf(angle: .pi, axis: X)

        for name in ["eyes", "rune", "shout"] {
            _ = rig.part(name, pivot: .zero, joint: .hinge(axis: Y, 0...1, duration: 0.4))
        }
        let pivots: [(String, V3)] = [
            ("helmet", V3(0, 0, 0)), ("chest", V3(0, -0.18, 0.12)), ("back", V3(0, -0.20, -0.12)),
            ("shoulderL", V3(Self.shoulderX, -0.05, 0)), ("shoulderR", V3(-Self.shoulderX, -0.05, 0)),
            ("gauntletL", V3(Self.elbowX, Self.elbowY, 0)), ("gauntletR", V3(-Self.elbowX, Self.elbowY, 0)),
        ]
        for (name, p) in pivots { _ = rig.part(name, pivot: p, joint: .fixed) }
        _ = rig.part("fur", parent: "back", pivot: V3(0, -0.03, -0.14), joint: .hinge(axis: Z, -1...1, duration: 0.5))
        _ = rig.part("eyesGlow", parent: "helmet", pivot: V3(0, 0.17, 0.1), joint: .fixed, options: 2)
        _ = rig.part("shoutGlow", parent: "helmet", pivot: V3(0, 0.07, 0.1), joint: .fixed, options: 2)
        _ = rig.part("runeGlowL", parent: "gauntletL", pivot: V3(Self.elbowX, Self.elbowY, 0), joint: .fixed, options: 2)
        _ = rig.part("runeGlowR", parent: "gauntletR", pivot: V3(-Self.elbowX, Self.elbowY, 0), joint: .fixed, options: 2)
        rig.optionLinks = [("eyes", "eyesGlow"), ("shout", "shoutGlow"), ("rune", "runeGlowL"), ("rune", "runeGlowR")].map {
            RigOptionLink(part: $0.1, joint: $0.0, thresholds: [0.05])
        }

        for l in 0..<2 {
            let hi = l == 0
            let sides = hi ? 48 : 16
            func put(_ s: Surface, _ part: String, option: Int = 0, _ x: Xform = .identity) {
                rig.add(s, x, to: part, option: option, lods: l...l)
            }
            func armor(_ part: String, _ c: V3, right: V3, up: V3, out: V3, w: Float, h: Float, t: Float, b: Float,
                       rivets: Bool = true, _ mat: MaterialKey) {
                put(plate(c, right: right, up: up, out: out, width: w, height: h, thick: t, bulge: b, hi: hi, mat), part)
                guard hi && rivets else { return }
                for s in [Float(-0.75), -0.25, 0.25, 0.75] {
                    let at = c + right * (s * w / 2) + out * (b * (1 - s * s) + t * 0.5)
                    let dir = simd_normalize(out + right * (2 * b * s / (w / 2)))
                    put(Prim.lathe([V2(0.0065, 0), V2(0.0048, 0.003), V2(0.001, 0.0046)], segments: 8, seamTile: 0.02, material: iron), part,
                        Xform(translation: at, rotation: simd_quatf(from: Y, to: dir)))
                }
            }
            /// Fur tuft: a thin cone lathe leaning along `dir`.
            func tuft(_ part: String, _ at: V3, dir: V3, len: Float, r: Float) {
                put(Prim.lathe([V2(r, 0), V2(r * 0.8, len * 0.4), V2(r * 0.35, len * 0.8), V2(0.001, len)], segments: hi ? 8 : 5, seamTile: 0.05, material: fur),
                    part, Xform(translation: at, rotation: simd_quatf(from: Y, to: simd_normalize(dir))))
            }

            // MARK: Helmet
            do {
                put(Prim.loft(helmetRings(hi: hi), capStart: true, capEnd: true, material: steel), "helmet")
                // Brow band with eye slits cut as dark recesses, nose guard, cheek guards.
                armor("helmet", V3(0, 0.185, 0.04), right: X, up: Y, out: Z, w: 0.21, h: 0.05, t: 0.018, b: 0.097, iron)
                armor("helmet", V3(0, 0.1, 0.105), right: Y, up: X, out: Z, w: 0.14, h: 0.025, t: 0.016, b: 0.02, rivets: false, steel)
                for sx in [Float(-1), 1] {
                    armor("helmet", V3(sx * 0.1, 0.1, 0.0), right: Z, up: Y, out: X * sx, w: 0.13, h: 0.1, t: 0.012, b: 0.012, steel)
                    armor("helmet", V3(sx * 0.04, 0.148, 0.105), right: X, up: Y, out: Z, w: 0.05, h: 0.012, t: 0.012, b: 0.01, rivets: false, iron)
                    // Curved horn: tapering tube sweeping out, up and forward.
                    let n = hi ? 12 : 6
                    let horn = (0..<n).map { i -> V3 in
                        let t = Float(i) / Float(n - 1)
                        return V3(sx * (0.095 + 0.1 * sin(t * 1.5)), 0.24 + 0.2 * t * t + 0.05 * t, -0.01 + 0.07 * t * t)
                    }
                    put(Prim.tube(horn, radii: horn.indices.map { 0.026 * (1 - Float($0) / Float(n)) + 0.003 }, sides: hi ? 24 : 8, seamTile: 0.04, material: steel, capEnd: true), "helmet")
                    put(Prim.torus(major: 0.027, minor: 0.006, segments: hi ? 32 : 12, sides: hi ? 8 : 4, material: iron), "helmet",
                        Xform(translation: horn[0] + V3(sx * 0.003, 0, 0), rotation: simd_quatf(angle: .pi / 2, axis: Z)))
                }
                // Crown ridge.
                let n = hi ? 13 : 6
                let ridge = (0..<n).map { i -> V3 in
                    let phi = rad(-75) + Float(i) / Float(n - 1) * rad(135)
                    let rz: Float = phi > 0 ? 0.118 : 0.13
                    return V3(0, 0.155 + 0.155 * cos(phi) + 0.006, 0.01 + rz * sin(phi))
                }
                put(Prim.tube(ridge, radii: ridge.map { _ in 0.007 }, sides: hi ? 24 : 8, seamTile: 0.03, material: iron, capEnd: true), "helmet")
                // Eye slits, lit while `eyes` is above 0.05.
                for sx in [Float(-1), 1] {
                    put(plate(V3(sx * 0.04, 0.17, 0.108), right: X, up: Y, out: Z, width: 0.05, height: 0.01, thick: 0.014, bulge: 0.012, hi: hi, glow), "eyesGlow", option: 1)
                }
                // Mouth slit for the shout.
                put(plate(V3(0, 0.06, 0.1), right: X, up: Y, out: Z, width: 0.07, height: 0.012, thick: 0.012, bulge: 0.02, hi: hi, glow), "shoutGlow", option: 1)
            }

            // MARK: Chest
            do {
                put(Prim.superellipsoid(V3(0.36, 0.78, 0.24), exponent: 2.4, subdivisions: hi ? 6 : 3, material: leather), "chest", Xform(translation: V3(0, -0.38, 0)))
                let tilt = rad(14)
                for sx in [Float(-1), 1] {
                    let r = V3(cos(tilt), 0, -sx * sin(tilt)), o = V3(sx * sin(tilt), 0, cos(tilt))
                    armor("chest", V3(sx * 0.092, -0.13, 0.07), right: r, up: Y, out: o, w: 0.19, h: 0.16, t: 0.022, b: 0.07, steel)
                }
                armor("chest", V3(0, -0.025, 0.07), right: X, up: Y, out: Z, w: 0.3, h: 0.055, t: 0.02, b: 0.06, iron)
                for i in 0..<3 {
                    let f = Float(i)
                    armor("chest", V3(0, -0.255 - 0.075 * f, 0.045), right: X, up: Y, out: Z, w: 0.26 - 0.025 * f, h: 0.08, t: 0.016, b: 0.07 - 0.01 * f, i == 1 ? iron : steel)
                }
                // Leather belt and buckle.
                put(Prim.tube([V3(-0.17, -0.58, 0.02), V3(-0.09, -0.58, 0.1), V3(0.09, -0.58, 0.1), V3(0.17, -0.58, 0.02)], radii: [0.022, 0.022, 0.022, 0.022], sides: hi ? 16 : 6, seamTile: 0.05, material: leather, capEnd: true), "chest")
                put(Prim.torus(major: 0.026, minor: 0.006, segments: hi ? 32 : 12, sides: hi ? 8 : 4, material: iron), "chest", Xform(translation: V3(0, -0.58, 0.122), rotation: simd_quatf(angle: .pi / 2, axis: X)))
                // Fur collar around the neck.
                put(Prim.torus(major: 0.09, minor: 0.03, segments: hi ? 48 : 16, sides: hi ? 16 : 6, material: fur), "chest", Xform(translation: V3(0, -0.03, 0)))
            }

            // MARK: Back and cloak (`fur` joint swings the cloak)
            do {
                armor("back", V3(0, -0.2, -0.07), right: X, up: Y, out: -Z, w: 0.34, h: 0.3, t: 0.022, b: 0.06, steel)
                let n = hi ? 11 : 5
                var path: [V3] = [], sc: [Float] = []
                for i in 0..<n {
                    let t = Float(i) / Float(n - 1)
                    path.append(V3(0, -0.04 - 0.95 * t, -0.15 - 0.1 * sin(t * 2.4) - 0.04 * t))
                    sc.append(1 + 0.18 * t)
                }
                put(Prim.sweep(octagon(0.42, 0.012, chamfer: 0.004), along: path, up: X, scales: sc, caps: true, material: leather), "fur")
                // Fur lining along the cloak hem and shoulder line.
                let hem = path[n - 1]
                put(Prim.tube([hem + V3(-0.24, 0, 0), hem + V3(-0.08, 0, 0.01), hem + V3(0.08, 0, 0.01), hem + V3(0.24, 0, 0)],
                              radii: [0.02, 0.025, 0.025, 0.02], sides: hi ? 16 : 6, seamTile: 0.05, material: fur, capEnd: true), "fur")
                put(Prim.tube([V3(-0.2, -0.05, -0.15), V3(0, -0.04, -0.17), V3(0.2, -0.05, -0.15)], radii: [0.03, 0.036, 0.03], sides: hi ? 24 : 8, seamTile: 0.05, material: fur, capEnd: true), "fur")
                if hi {
                    for i in 0..<14 {
                        let u = Float(i) / 13 * 2 - 1
                        tuft("fur", V3(u * 0.2, -0.045, -0.165), dir: V3(u * 0.3, -0.3, -1), len: 0.05, r: 0.012)
                    }
                    for i in 0..<10 {
                        let u = Float(i) / 9 * 2 - 1
                        tuft("fur", path[n - 1] + V3(u * 0.22, 0, 0), dir: V3(u * 0.2, -1, 0.1), len: 0.06, r: 0.012)
                    }
                }
            }

            // MARK: Shoulders and arms
            for (sx, name) in [(Float(1), "shoulderL"), (Float(-1), "shoulderR")] {
                let tiltZ = simd_quatf(angle: -sx * 0.3, axis: Z)
                let base = V3(sx * 0.235, -0.07, 0)
                put(Prim.tube([V3(sx * 0.2, -0.05, 0), V3(sx * 0.208, -0.18, 0), V3(sx * Self.elbowX, Self.elbowY, 0)], radii: [0.05, 0.047, 0.043], sides: hi ? 24 : 8, seamTile: 0.05, material: leather, capEnd: true), name)
                put(Prim.lathe([V2(0.114, 0), V2(0.122, 0.012), V2(0.116, 0.04), V2(0.096, 0.068), V2(0.06, 0.09), V2(0.001, 0.1)], segments: sides, seamTile: 0.1, material: steel),
                    name, Xform(translation: base, rotation: tiltZ, scale: V3(1, 1, 1.1)))
                // Fur trim: roll around the pauldron rim plus tufts at LOD0.
                put(Prim.torus(major: 0.12, minor: 0.022, segments: hi ? 48 : 16, sides: hi ? 14 : 6, material: fur), name,
                    Xform(translation: base + V3(sx * 0.004, -0.004, 0), rotation: tiltZ, scale: V3(1, 1, 1.1)))
                if hi {
                    for k in 0..<20 {
                        let a = Float(k) / 20 * 2 * .pi
                        let p = tiltZ.act(V3(cos(a) * 0.12, -0.01, sin(a) * 0.12 * 1.1))
                        tuft(name, base + p, dir: V3(cos(a) * 0.5, -0.8, sin(a) * 0.5), len: 0.045, r: 0.011)
                    }
                }
                for i in 0..<2 {
                    let f = Float(i)
                    armor(name, V3(sx * (0.305 - 0.012 * f), -0.1 - 0.045 * f, 0), right: Z, up: Y, out: X * sx, w: 0.19 - 0.015 * f, h: 0.045, t: 0.012, b: 0.04, i == 1 ? iron : steel)
                }
            }
            for (sx, name, glowName) in [(Float(1), "gauntletL", "runeGlowL"), (Float(-1), "gauntletR", "runeGlowR")] {
                let e = V3(sx * Self.elbowX, Self.elbowY, 0)
                put(Prim.tube([e, e + V3(0, -0.12, 0), e + V3(0, -0.25, 0)], radii: [0.045, 0.043, 0.04], sides: hi ? 24 : 8, seamTile: 0.05, material: leather, capEnd: true), name)
                put(Prim.lathe([V2(0.066, 0), V2(0.07, 0.015), V2(0.062, 0.06), V2(0.054, 0.14), V2(0.056, 0.2), V2(0.05, 0.226), V2(0.046, 0.232)], segments: sides, seamTile: 0.08, material: steel),
                    name, Xform(translation: e, rotation: flipX))
                put(Prim.superellipsoid(V3(0.1, 0.09, 0.11), exponent: 2.5, subdivisions: hi ? 6 : 3, material: iron), name, Xform(translation: e + V3(0, 0.005, -0.045)))
                armor(name, e + V3(sx * 0.052, -0.15, 0), right: Z, up: Y, out: X * sx, w: 0.1, h: 0.16, t: 0.012, b: 0.012, iron)
                put(Prim.torus(major: 0.056, minor: 0.004, segments: hi ? 48 : 16, sides: hi ? 8 : 4, material: iron), name, Xform(translation: e + V3(0, -0.215, 0)))
                put(Prim.tube([e + V3(0, -0.23, 0), e + V3(0, -0.26, 0)], radii: [0.04, 0.042], sides: hi ? 24 : 8, seamTile: 0.05, material: leather, capEnd: true), name)
                put(Prim.superellipsoid(V3(0.085, 0.1, 0.1), exponent: 2.6, subdivisions: hi ? 6 : 3, material: leather), name, Xform(translation: e + V3(0, -0.3, 0.005)))
                armor(name, e + V3(0, -0.285, 0.05), right: X, up: Y, out: Z, w: 0.08, h: 0.03, t: 0.01, b: 0.012, rivets: false, steel)
                // Etched runes on the forearm front, lit while `rune` is above 0.05.
                let zf: Float = 0.063
                let glyphs: [[V2]] = [
                    [V2(0, 0), V2(0.012, -0.03), V2(-0.012, -0.03), V2(0, -0.06)],
                    [V2(-0.014, 0), V2(0.014, 0), V2(0, -0.03), V2(0.014, -0.06)],
                    [V2(0, 0), V2(0, -0.06), V2(0.014, -0.03), V2(-0.014, -0.03)],
                ]
                for (gi, g) in glyphs.enumerated() {
                    let y0 = -0.04 - 0.05 * Float(gi)
                    let pts = g.map { e + V3($0.x, y0 + $0.y * 0.8, zf) }
                    put(Prim.tube(pts, radii: pts.map { _ in 0.0028 }, sides: hi ? 8 : 4, seamTile: 0.02, material: glow, capEnd: true), glowName, option: 1)
                }
                put(Prim.torus(major: 0.0585, minor: 0.0035, segments: hi ? 48 : 16, sides: hi ? 8 : 4, material: glow), glowName, option: 1, Xform(translation: e + V3(0, -0.205, 0)))
            }
            _ = rng.float()
        }

        rig.states = [
            RigState("rest", [:]),
            RigState("eyes-lit", ["eyes": 1], options: ["eyesGlow": 1]),
            RigState("shout", ["eyes": 1, "shout": 1], options: ["eyesGlow": 1, "shoutGlow": 1]),
            RigState("runes", ["eyes": 1, "rune": 1], options: ["eyesGlow": 1, "runeGlowL": 1, "runeGlowR": 1]),
            RigState("fur-left", ["eyes": 1, "fur": -1], options: ["eyesGlow": 1]),
            RigState("fur-right", ["eyes": 1, "fur": 1], options: ["eyesGlow": 1]),
        ]
        return rig
    }
}
