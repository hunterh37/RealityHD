import simd
import Foundation

/// Ghost-catcher proton pack kit, life size for a 1.75 m wearer. Tan canvas coverall with black leather webbing, a round
/// utility helmet with goggles and a headset boom, a grey alloy backpack with a four-lens cyclotron ring, power cell, vent
/// stack and hose to a hand wand on the right fist, and a belt trap on the wearer's left hip. All shapes are original.
/// Origin at the neck base, face toward +Z, up +Y, wearer's left = +X.
///
/// Kit parts (pivots in asset space): `helmet` (0, 0, 0), `chest` (0, -0.18, 0.12), `back` (0, -0.20, -0.12),
/// `shoulderL` / `shoulderR` (+-0.20, -0.05, 0), `gauntletL` / `gauntletR` (+-0.215, -0.31, 0) with the forearm along -Y,
/// plus the extra part `trapRig` (0.19, -0.56, 0) for the belt trap.
///
/// Joints 0...1 (set with `setJoints`): `stream` shows the wand stream cone ahead of the right fist, `cyclotron` lights the
/// four cyclotron lenses, `trap` opens the belt trap doors with a white light fan, `vent` shows steam plumes over the vent
/// stack. Each joint is an empty driver part; its follower part (`streamGlow`, `cyclotronGlow`, `ventSteam`, `trapRig`
/// option) switches between option 0 and option 1 when the joint passes 0.05. 2 LODs.
public struct ProtonPack: RealArticulated {
    public static let id = "proton-pack"
    public static let summary = "Ghost-catcher proton pack kit: tan coverall, goggle helmet, alloy backpack with cyclotron ring, vent stack, hand wand with stream and belt trap with light fan."
    public static let tags = ["prop", "metal", "fabric", "articulated", "glowing"]
    public static let budget = 20_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 150, elevation: 10, distance: 1.1)

    /// Tan coverall.
    public var coverall: MaterialKey = "fabric.canvas:A89460"
    /// Pack shell and wand body.
    public var plateMat: MaterialKey = "metal.painted:7A7E82"
    /// Frames, caps and wand trim.
    public var trimMat: MaterialKey = "metal.aluminum"
    /// Pack covers, boots, gloves and belt.
    public var suit: MaterialKey = "leather.black"
    /// Harness straps.
    public var webbing: MaterialKey = "fabric.webbing"
    /// Goggle glass.
    public var lens: MaterialKey = "plastic.polycarbonate-tint"
    /// Wand barrel and cyclotron housing.
    public var gunmetal: MaterialKey = "metal.blued-steel"
    /// Rivets and seams.
    public var iron: MaterialKey = "metal.iron"
    public init() {}

    static let elbowX: Float = 0.215
    static let elbowY: Float = -0.31
    static let shoulderX: Float = 0.20

    func rad(_ d: Float) -> Float { d * .pi / 180 }
    func octagon(_ w: Float, _ h: Float, chamfer c: Float) -> [V2] {
        let a = w / 2, b = h / 2
        return [V2(-a + c, -b), V2(a - c, -b), V2(a, -b + c), V2(a, b - c), V2(a - c, b), V2(-a + c, b), V2(-a, b - c), V2(-a, -b + c)]
    }

    /// Curved plate: an arch swept across `right`, bowed toward `out`, with a chamfered octagon section whose size
    /// falls off toward the ends so the outline reads as a rounded lens with bevelled edges.
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

    /// Rings of the round utility helmet: a low dome with a rolled rim, wider at the brow.
    func helmetRings(hi: Bool) -> [[V3]] {
        let rows = hi ? 16 : 8, sides = hi ? 48 : 20
        var rings: [[V3]] = []
        for j in 0...rows {
            let t = Float(j) / Float(rows)
            let dome = sqrt(max(0, 1 - pow(max(0, (t - 0.5) / 0.5), 2.2)))
            let rim = 1 + 0.06 * (1 - smoothstep(0.0, 0.25, abs(t - 0.38) * 2))
            let k = max(0.02, dome) * rim
            let a = 0.1 * k
            let front = 0.115 * k
            let back = 0.125 * k
            let outline: [V2] = (0..<sides).map { i in
                let ang = Float(i) / Float(sides) * 2 * .pi, s = sin(ang)
                return V2(cos(ang) * a, s * (s >= 0 ? back : front))
            }
            rings.append(Prim.ring(outline, y: 0.04 + 0.25 * t, offset: V3(0, 0, 0.01)))
        }
        return rings
    }

    // MARK: Rig

    public func rig(seed: UInt64) -> Rig {
        var rng = SeededRNG(seed: seed)
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [3])
        let X = V3(1, 0, 0), Y = V3(0, 1, 0), Z = V3(0, 0, 1)
        let flipX = simd_quatf(angle: .pi, axis: X)
        let toZ = simd_quatf(angle: .pi / 2, axis: X)
        let toNegZ = simd_quatf(angle: -.pi / 2, axis: X)
        let red = "emissive.led-red"
        let orange = "emissive.signal-orange"
        let white = "emissive.signal-white"
        let tp = V3(0.19, -0.56, 0)

        // Drivers first so option links resolve.
        for name in ["stream", "cyclotron", "trap", "vent"] {
            _ = rig.part(name, pivot: .zero, joint: .hinge(axis: Y, 0...1, duration: 0.5))
        }
        let pivots: [(String, V3)] = [
            ("helmet", V3(0, 0, 0)), ("chest", V3(0, -0.18, 0.12)), ("back", V3(0, -0.20, -0.12)),
            ("shoulderL", V3(Self.shoulderX, -0.05, 0)), ("shoulderR", V3(-Self.shoulderX, -0.05, 0)),
            ("gauntletL", V3(Self.elbowX, Self.elbowY, 0)), ("gauntletR", V3(-Self.elbowX, Self.elbowY, 0)),
            ("trapRig", tp),
        ]
        for (name, p) in pivots { _ = rig.part(name, pivot: p, joint: .fixed, options: name == "trapRig" ? 2 : 1) }
        _ = rig.part("streamGlow", parent: "gauntletR", pivot: V3(-Self.elbowX, Self.elbowY, 0), joint: .fixed, options: 2)
        _ = rig.part("cyclotronGlow", parent: "back", pivot: V3(0, -0.20, -0.12), joint: .fixed, options: 2)
        _ = rig.part("ventSteam", parent: "back", pivot: V3(0, -0.20, -0.12), joint: .fixed, options: 2)
        // trapRig itself carries options: 0 doors shut, 1 doors open with the light fan.
        rig.optionLinks = [
            RigOptionLink(part: "streamGlow", joint: "stream", thresholds: [0.05]),
            RigOptionLink(part: "cyclotronGlow", joint: "cyclotron", thresholds: [0.05]),
            RigOptionLink(part: "ventSteam", joint: "vent", thresholds: [0.05]),
            RigOptionLink(part: "trapRig", joint: "trap", thresholds: [0.05]),
        ]

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
                for s in [Float(-0.75), -0.3, 0.3, 0.75] {
                    let at = c + right * (s * w / 2) + out * (b * (1 - s * s) + t * 0.5)
                    let dir = simd_normalize(out + right * (2 * b * s / (w / 2)))
                    put(Prim.lathe([V2(0.0065, 0), V2(0.0048, 0.003), V2(0.001, 0.0046)], segments: 10, seamTile: 0.02, material: iron), part,
                        Xform(translation: at, rotation: simd_quatf(from: Y, to: dir)))
                }
            }
            func seam(_ part: String, _ c: V3, right: V3, out: V3, w: Float, b: Float) {
                let n = hi ? 9 : 4
                let path = (0..<n).map { i -> V3 in
                    let s = Float(i) / Float(n - 1) * 2 - 1
                    return c + right * (s * w / 2) + out * (b * (1 - s * s))
                }
                put(Prim.tube(path, radii: path.map { _ in 0.0035 }, sides: hi ? 8 : 4, seamTile: 0.02, material: iron, capEnd: true), part)
            }
            func cable(_ part: String, _ path: [V3], r: Float, _ mat: MaterialKey) {
                put(Prim.tube(path, radii: path.map { _ in r }, sides: hi ? 24 : 8, seamTile: 0.04, material: mat, capEnd: true), part)
            }

            // MARK: Helmet, goggles, headset
            do {
                put(Prim.loft(helmetRings(hi: hi), capStart: true, capEnd: true, material: plateMat), "helmet")
                // Neck and head under the shell.
                put(Prim.lathe([V2(0.052, -0.04), V2(0.058, 0), V2(0.075, 0.06), V2(0.092, 0.12), V2(0.098, 0.14)], segments: sides, seamTile: 0.1, material: coverall), "helmet")
                // Brim, rolled rim.
                put(Prim.torus(major: 0.106, minor: 0.008, segments: hi ? 64 : 24, sides: hi ? 12 : 6, material: trimMat), "helmet",
                    Xform(translation: V3(0, 0.17, 0.01), scale: V3(1, 1, 1.1)))
                armor("helmet", V3(0, 0.185, 0.115), right: X, up: Y, out: Z, w: 0.17, h: 0.03, t: 0.014, b: 0.03, rivets: false, plateMat)
                // Goggles: two lens barrels on a strap.
                for sx in [Float(-1), 1] {
                    let g = V3(sx * 0.042, 0.215, 0.125)
                    put(Prim.lathe([V2(0.03, 0), V2(0.033, 0.006), V2(0.033, 0.022), V2(0.028, 0.03), V2(0.001, 0.032)], segments: sides, seamTile: 0.1, material: trimMat),
                        "helmet", Xform(translation: g, rotation: toZ))
                    put(Prim.lathe([V2(0.026, 0.026), V2(0.014, 0.036), V2(0.001, 0.04)], segments: sides, seamTile: 0.1, material: lens),
                        "helmet", Xform(translation: g, rotation: toZ))
                }
                put(Prim.torus(major: 0.108, minor: 0.011, segments: hi ? 64 : 24, sides: hi ? 10 : 5, material: webbing), "helmet",
                    Xform(translation: V3(0, 0.215, 0.01), scale: V3(1, 1, 1.12)))
                // Headset: ear cups and a boom mic on the wearer's right (-X).
                for sx in [Float(-1), 1] {
                    put(Prim.lathe([V2(0.034, 0), V2(0.038, 0.006), V2(0.034, 0.022), V2(0.001, 0.026)], segments: sides, seamTile: 0.1, material: suit),
                        "helmet", Xform(translation: V3(sx * 0.105, 0.12, 0.0), rotation: simd_quatf(angle: -sx * .pi / 2, axis: Z)))
                }
                cable("helmet", [V3(-0.108, 0.12, 0.012), V3(-0.095, 0.08, 0.07), V3(-0.05, 0.045, 0.115)], r: 0.004, iron)
                put(Prim.superellipsoid(V3(0.02, 0.014, 0.014), exponent: 2.2, subdivisions: hi ? 5 : 3, material: suit), "helmet", Xform(translation: V3(-0.045, 0.043, 0.118)))
                // Headband arch over the dome.
                let n = hi ? 13 : 6
                let band = (0..<n).map { i -> V3 in
                    let phi = rad(-80) + Float(i) / Float(n - 1) * rad(160)
                    return V3(0, 0.17 + 0.13 * cos(phi) + 0.006, 0.01 + 0.125 * sin(phi))
                }
                cable("helmet", band, r: 0.006, trimMat)
            }

            // MARK: Chest, harness, belt
            do {
                put(Prim.superellipsoid(V3(0.36, 0.78, 0.24), exponent: 2.4, subdivisions: hi ? 6 : 3, material: coverall), "chest", Xform(translation: V3(0, -0.38, 0)))
                // Collar.
                put(Prim.lathe([V2(0.072, 0), V2(0.086, 0.008), V2(0.082, 0.036), V2(0.07, 0.044)], segments: sides, seamTile: 0.1, material: coverall),
                    "chest", Xform(translation: V3(0, -0.045, 0.0)))
                // Shoulder harness straps crossing the chest to the pack frame.
                for sx in [Float(-1), 1] {
                    armor("chest", V3(sx * 0.085, -0.15, 0.11), right: Y, up: Z, out: Z, w: 0.34, h: 0.04, t: 0.012, b: 0.012, rivets: false, webbing)
                    armor("chest", V3(sx * 0.07, -0.34, 0.1), right: X, up: Y, out: Z, w: 0.05, h: 0.04, t: 0.012, b: 0.012, rivets: false, trimMat)
                }
                // Chest patch: an original ring-and-bar emblem.
                put(Prim.torus(major: 0.034, minor: 0.004, segments: hi ? 48 : 16, sides: hi ? 8 : 4, material: iron), "chest",
                    Xform(translation: V3(-0.085, -0.1, 0.17), rotation: toZ))
                armor("chest", V3(-0.085, -0.1, 0.17), right: X, up: Y, out: Z, w: 0.06, h: 0.012, t: 0.008, b: 0.004, rivets: false, iron)
                // Belt with a buckle and two pouches.
                put(Prim.torus(major: 0.17, minor: 0.016, segments: hi ? 64 : 24, sides: hi ? 12 : 6, material: suit), "chest",
                    Xform(translation: V3(0, -0.5, 0), scale: V3(1, 1, 0.72)))
                armor("chest", V3(0, -0.5, 0.125), right: X, up: Y, out: Z, w: 0.07, h: 0.045, t: 0.014, b: 0.012, rivets: false, trimMat)
                for sx in [Float(-1), 1] {
                    put(Prim.superellipsoid(V3(0.06, 0.07, 0.04), exponent: 2.8, subdivisions: hi ? 5 : 3, material: suit), "chest",
                        Xform(translation: V3(sx * 0.07, -0.55, 0.095)))
                }
            }

            // MARK: Pack: frame, shell, cyclotron, power cell, vent stack, hose
            do {
                let c = V3(0, -0.2, -0.2)
                // Mounting frame against the back.
                armor("back", V3(0, -0.2, -0.085), right: X, up: Y, out: -Z, w: 0.3, h: 0.36, t: 0.02, b: 0.03, trimMat)
                // Main shell, a rounded grey slab.
                put(Prim.superellipsoid(V3(0.27, 0.4, 0.14), exponent: 2.6, subdivisions: hi ? 7 : 3, material: plateMat), "back", Xform(translation: c + V3(0, -0.02, 0)))
                armor("back", c + V3(0, -0.02, -0.07), right: X, up: Y, out: -Z, w: 0.22, h: 0.3, t: 0.014, b: 0.016, plateMat)
                seam("back", c + V3(0, 0.07, -0.088), right: X, out: -Z, w: 0.22, b: 0.0)
                seam("back", c + V3(0, -0.13, -0.088), right: X, out: -Z, w: 0.22, b: 0.0)
                // Cyclotron housing: a drum on the upper rear with four lens ports on a ring.
                let cy = V3(0, -0.07, -0.285)
                put(Prim.lathe([V2(0.085, 0), V2(0.092, 0.008), V2(0.09, 0.03), V2(0.082, 0.04), V2(0.001, 0.042)], segments: sides, seamTile: 0.1, material: gunmetal),
                    "back", Xform(translation: cy, rotation: toNegZ))
                put(Prim.torus(major: 0.09, minor: 0.006, segments: hi ? 64 : 24, sides: hi ? 10 : 5, material: trimMat), "back", Xform(translation: cy + V3(0, 0, -0.03), rotation: toZ))
                for k in 0..<4 {
                    let a = Float(k) / 4 * 2 * .pi + .pi / 4
                    let p = cy + V3(0.052 * cos(a), 0.052 * sin(a), -0.036)
                    put(Prim.lathe([V2(0.022, 0), V2(0.024, 0.005), V2(0.021, 0.01), V2(0.001, 0.012)], segments: hi ? 32 : 10, seamTile: 0.05, material: lens),
                        "back", Xform(translation: p, rotation: toNegZ))
                    put(Prim.torus(major: 0.0245, minor: 0.003, segments: hi ? 32 : 10, sides: hi ? 8 : 4, material: iron), "back",
                        Xform(translation: p + V3(0, 0, -0.002), rotation: toZ))
                    // Lit lens, shown while `cyclotron` is above 0.05.
                    put(Prim.lathe([V2(0.021, 0), V2(0.019, 0.008), V2(0.001, 0.014)], segments: hi ? 32 : 10, seamTile: 0.05, material: red),
                        "cyclotronGlow", option: 1, Xform(translation: p + V3(0, 0, -0.008), rotation: toNegZ))
                }
                put(Prim.torus(major: 0.052, minor: 0.004, segments: hi ? 48 : 16, sides: hi ? 8 : 4, material: red), "cyclotronGlow", option: 1,
                    Xform(translation: cy + V3(0, 0, -0.04), rotation: toZ))
                // Power cell: a tall tube on the lower pack with end caps.
                put(Prim.lathe([V2(0.04, 0), V2(0.044, 0.006), V2(0.044, 0.19), V2(0.04, 0.198), V2(0.001, 0.2)], segments: sides, seamTile: 0.1, material: trimMat),
                    "back", Xform(translation: c + V3(0.07, -0.26, -0.09)))
                put(Prim.lathe([V2(0.03, 0.02), V2(0.03, 0.18), V2(0.001, 0.182)], segments: sides, seamTile: 0.1, material: lens),
                    "back", Xform(translation: c + V3(0.07, -0.26, -0.09)))
                // Vent stack on the wearer's right: three short chimneys with caps.
                for i in 0..<3 {
                    let p = c + V3(-0.1 + 0.028 * Float(i), 0.19, -0.04)
                    put(Prim.lathe([V2(0.011, 0), V2(0.013, 0.004), V2(0.013, 0.05), V2(0.016, 0.056), V2(0.001, 0.058)], segments: hi ? 24 : 8, seamTile: 0.05, material: gunmetal),
                        "back", Xform(translation: p))
                    // Steam plume, shown while `vent` is above 0.05.
                    put(Prim.lathe([V2(0.008, 0), V2(0.026, 0.06), V2(0.04, 0.13), V2(0.026, 0.2), V2(0.001, 0.25)], segments: hi ? 24 : 8, seamTile: 0.3, material: "plastic.translucent"),
                        "ventSteam", option: 1, Xform(translation: p + V3(0, 0.058, 0)))
                }
                // Hose from the pack down the right side to the wand.
                cable("back", [c + V3(-0.1, -0.1, -0.04), V3(-0.19, -0.25, -0.12), V3(-0.25, -0.4, 0.0), V3(-0.25, -0.55, 0.12), V3(-0.215, -0.6, 0.12)], r: 0.012, suit)
                // Frame bolts.
                if hi {
                    for (x, y) in [(Float(-0.12), Float(-0.06)), (0.12, -0.06), (-0.12, -0.34), (0.12, -0.34)] {
                        put(Prim.lathe([V2(0.01, 0), V2(0.0075, 0.005), V2(0.001, 0.008)], segments: 12, seamTile: 0.02, material: iron), "back",
                            Xform(translation: V3(x, y, -0.105), rotation: toNegZ))
                    }
                }
            }

            // MARK: Shoulders and arms
            for (sx, name) in [(Float(1), "shoulderL"), (Float(-1), "shoulderR")] {
                put(Prim.tube([V3(sx * 0.2, -0.05, 0), V3(sx * 0.208, -0.18, 0), V3(sx * Self.elbowX, Self.elbowY, 0)], radii: [0.052, 0.049, 0.045], sides: hi ? 24 : 8, seamTile: 0.05, material: coverall, capEnd: true), name)
                put(Prim.superellipsoid(V3(0.12, 0.05, 0.13), exponent: 2.4, subdivisions: hi ? 6 : 3, material: coverall), name, Xform(translation: V3(sx * 0.215, -0.02, 0)))
                // Strap pad and a unit patch (ring) on the upper sleeve.
                armor(name, V3(sx * 0.225, -0.025, 0), right: Z, up: Y, out: X * sx, w: 0.12, h: 0.04, t: 0.012, b: 0.02, rivets: false, webbing)
                put(Prim.torus(major: 0.028, minor: 0.003, segments: hi ? 40 : 14, sides: hi ? 8 : 4, material: iron), name,
                    Xform(translation: V3(sx * 0.262, -0.12, 0), rotation: simd_quatf(angle: .pi / 2, axis: Z)))
            }
            for (sx, name) in [(Float(1), "gauntletL"), (Float(-1), "gauntletR")] {
                let e = V3(sx * Self.elbowX, Self.elbowY, 0)
                put(Prim.tube([e, e + V3(0, -0.12, 0), e + V3(0, -0.23, 0)], radii: [0.046, 0.044, 0.04], sides: hi ? 24 : 8, seamTile: 0.05, material: coverall, capEnd: true), name)
                // Elbow patch, cuff and glove.
                put(Prim.superellipsoid(V3(0.09, 0.08, 0.1), exponent: 2.5, subdivisions: hi ? 6 : 3, material: coverall), name, Xform(translation: e + V3(0, 0.005, -0.045)))
                put(Prim.lathe([V2(0.046, 0), V2(0.05, 0.008), V2(0.05, 0.03), V2(0.044, 0.036)], segments: sides, seamTile: 0.1, material: webbing),
                    name, Xform(translation: e + V3(0, -0.22, 0), rotation: flipX))
                put(Prim.tube([e + V3(0, -0.23, 0), e + V3(0, -0.26, 0.0)], radii: [0.04, 0.042], sides: hi ? 24 : 8, seamTile: 0.05, material: suit, capEnd: true), name)
                put(Prim.superellipsoid(V3(0.085, 0.1, 0.1), exponent: 2.6, subdivisions: hi ? 6 : 3, material: suit), name, Xform(translation: e + V3(0, -0.3, 0.005)))
                armor(name, e + V3(0, -0.285, 0.05), right: X, up: Y, out: Z, w: 0.08, h: 0.03, t: 0.01, b: 0.012, rivets: false, suit)
            }

            // MARK: Wand in the right fist (-X), barrel toward +Z
            do {
                let f = V3(-Self.elbowX, Self.elbowY - 0.3, 0.005)
                put(Prim.tube([f + V3(0, 0.005, -0.075), f + V3(0, 0.012, 0.0), f + V3(0, 0.02, 0.1)], radii: [0.026, 0.03, 0.028], sides: hi ? 24 : 8, seamTile: 0.04, material: plateMat, capEnd: true), "gauntletR")
                put(Prim.superellipsoid(V3(0.05, 0.055, 0.2), exponent: 2.6, subdivisions: hi ? 6 : 3, material: plateMat), "gauntletR", Xform(translation: f + V3(0, 0.05, 0.14)))
                put(Prim.lathe([V2(0.022, 0), V2(0.026, 0.006), V2(0.026, 0.12), V2(0.03, 0.128), V2(0.03, 0.14), V2(0.001, 0.142)], segments: sides, seamTile: 0.08, material: gunmetal),
                    "gauntletR", Xform(translation: f + V3(0, 0.055, 0.26), rotation: toZ))
                // Fins on the barrel and a top sight.
                for k in 0..<3 {
                    put(Prim.torus(major: 0.032, minor: 0.004, segments: hi ? 40 : 14, sides: hi ? 8 : 4, material: trimMat), "gauntletR",
                        Xform(translation: f + V3(0, 0.055, 0.3 + 0.025 * Float(k)), rotation: toZ))
                }
                armor("gauntletR", f + V3(0, 0.1, 0.16), right: Z, up: Y, out: Y, w: 0.14, h: 0.02, t: 0.012, b: 0.012, rivets: false, trimMat)
                put(Prim.lathe([V2(0.012, 0), V2(0.01, 0.006), V2(0.001, 0.01)], segments: hi ? 16 : 6, seamTile: 0.03, material: red), "gauntletR",
                    Xform(translation: f + V3(0.03, 0.098, 0.1)))
                // Stream: a core cone and an outer envelope ahead of the barrel, shown while `stream` is above 0.05.
                let tip = f + V3(0, 0.055, 0.405)
                put(Prim.lathe([V2(0.002, 0), V2(0.02, 0.03), V2(0.034, 0.12), V2(0.02, 0.3), V2(0.001, 0.5)], segments: hi ? 32 : 10, seamTile: 0.2, material: orange),
                    "streamGlow", option: 1, Xform(translation: tip, rotation: toZ))
                put(Prim.lathe([V2(0.002, 0), V2(0.009, 0.03), V2(0.014, 0.15), V2(0.001, 0.46)], segments: hi ? 24 : 8, seamTile: 0.2, material: white),
                    "streamGlow", option: 1, Xform(translation: tip, rotation: toZ))
            }

            // MARK: Belt trap on the left hip, doors shut (option 0) or open with a white light fan (option 1)
            do {
                // Body and pedal cable (always).
                for opt in 0..<2 {
                    put(Prim.superellipsoid(V3(0.1, 0.18, 0.06), exponent: 2.8, subdivisions: hi ? 6 : 3, material: gunmetal), "trapRig", option: opt,
                        Xform(translation: tp + V3(0, 0, 0.0)))
                    armor("trapRig", tp + V3(0, 0, 0.032), right: X, up: Y, out: Z, w: 0.08, h: 0.03, t: 0.01, b: 0.01, rivets: false, trimMat)
                    put(Prim.tube([tp + V3(0.03, -0.08, 0.02), tp + V3(0.07, -0.2, 0.04), tp + V3(0.05, -0.36, 0.2)], radii: [0.005, 0.005, 0.005], sides: hi ? 12 : 5,
                                  seamTile: 0.03, material: suit, capEnd: true), "trapRig", option: opt)
                    put(Prim.torus(major: 0.036, minor: 0.004, segments: hi ? 32 : 12, sides: hi ? 8 : 4, material: iron), "trapRig", option: opt,
                        Xform(translation: tp + V3(0, 0.1, 0.0)))
                }
                // Shut: two curved door plates meeting on the top edge.
                for sx in [Float(-1), 1] {
                    armor("trapRig", tp + V3(sx * 0.02, 0.095, 0.0), right: Z, up: X * sx, out: Y, w: 0.1, h: 0.04, t: 0.008, b: 0.012, rivets: false, plateMat)
                }
                // Open: doors swung out to the sides and a light fan above the slot.
                for sx in [Float(-1), 1] {
                    let hinge = tp + V3(sx * 0.05, 0.095, 0)
                    put(plate(hinge + V3(sx * 0.05, 0.03, 0), right: Z, up: X * sx, out: Y, width: 0.1, height: 0.1, thick: 0.008, bulge: 0.012, hi: hi, plateMat), "trapRig", option: 1)
                }
                put(Prim.lathe([V2(0.04, 0), V2(0.07, 0.12), V2(0.11, 0.3), V2(0.001, 0.31)], segments: hi ? 32 : 10, seamTile: 0.2, material: white),
                    "trapRig", option: 1, Xform(translation: tp + V3(0, 0.1, 0)))
                put(Prim.lathe([V2(0.03, 0), V2(0.032, 0.002), V2(0.001, 0.004)], segments: hi ? 24 : 8, seamTile: 0.2, material: white),
                    "trapRig", option: 1, Xform(translation: tp + V3(0, 0.099, 0)))
            }
            _ = rng.float()
        }

        rig.states = [
            RigState("rest", [:]),
            RigState("spin", ["cyclotron": 1], options: ["cyclotronGlow": 1]),
            RigState("stream", ["cyclotron": 1, "stream": 1], options: ["cyclotronGlow": 1, "streamGlow": 1]),
            RigState("trap", ["cyclotron": 1, "trap": 1], options: ["cyclotronGlow": 1, "trapRig": 1]),
            RigState("vent", ["cyclotron": 1, "vent": 1], options: ["cyclotronGlow": 1, "ventSteam": 1]),
        ]
        return rig
    }
}
