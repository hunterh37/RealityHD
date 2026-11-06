import simd
import Foundation

/// Matte dark vigilante armor kit, life size for a 1.75 m wearer. Segmented rubberised plates over a leather undersuit: a
/// pointed-ear cowl with narrow slanted lenses, an angular jaw guard, pectoral plates carrying an original hex-and-lozenge
/// chest emblem, banded abdomen lames, a utility belt with pouches, scalloped-fin bracers, a right-wrist grapple launcher,
/// and a long cloth cape hanging from a collar. No bat shapes or logos. Origin at the neck base, face toward +Z, up +Y,
/// wearer's left = +X.
///
/// Kit parts (pivots in asset space): `helmet` (0, 0, 0), `chest` (0, -0.18, 0.12), `back` (0, -0.20, -0.12),
/// `shoulderL` / `shoulderR` (+-0.20, -0.05, 0), `gauntletL` / `gauntletR` (+-0.215, -0.31, 0) with the forearm along -Y,
/// plus the extra part `capeMantle` (0, -0.04, -0.17) for the cape, hanging down to y -1.25.
///
/// Joints (set with `setJoints`): `cowl` (0...1) lights the lenses, `emblem` (0...1) lights the chest emblem, `grapple`
/// (0...1) fires the wrist launcher (hook and line out along the forearm axis, -Y), `cape` (-1...1) is a driver for the lens
/// cape sway and glide spread. 0...1 joints are empty drivers; followers `cowlGlow`, `emblemGlow`, `grappleShot` switch
/// between option 0 and option 1 when the joint passes 0.05. 2 LODs.
public struct VigilanteArmor: RealArticulated {
    public static let id = "vigilante-armor"
    public static let summary = "Dark vigilante armor kit: pointed-ear cowl with glowing lenses, segmented matte plates, hex chest emblem, utility belt, fin bracers, wrist grapple and long cape."
    public static let tags = ["prop", "metal", "leather", "articulated", "glowing"]
    public static let budget = 20_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 8, distance: 1.0)

    /// Main matte armour plates.
    public var plateMat: MaterialKey = "rubber.insulating-black"
    /// Cowl shell, belt pouches and undersuit.
    public var suit: MaterialKey = "leather.black"
    /// Trim, buckles and rivets.
    public var trimMat: MaterialKey = "metal.titanium"
    /// Grapple launcher, hook and line.
    public var gunmetal: MaterialKey = "metal.steel"
    /// Cape cloth.
    public var capeMat: MaterialKey = "fabric.nylon"
    /// Lens and emblem glow.
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

    /// Curved armour plate: an arch swept across `right`, bowed toward `out`, with a chamfered octagon section whose size
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

    /// Cowl shell rings: a snug oval head with a sharp brow and a tapering jaw.
    func cowlRings(hi: Bool) -> [[V3]] {
        let rows = hi ? 16 : 8, sides = hi ? 48 : 20
        var rings: [[V3]] = []
        for j in 0...rows {
            let t = Float(j) / Float(rows)
            let dome = sqrt(max(0, 1 - pow(max(0, (t - 0.55) / 0.45), 2.4)))
            let jaw = 0.62 + 0.38 * smoothstep(0, 0.35, t)
            let k = max(0.02, dome) * jaw
            let a = 0.096 * k
            let front = 0.116 * k * (1 + 0.08 * smoothstep(0.45, 0.6, t) * (1 - smoothstep(0.6, 0.8, t)))
            let back = 0.128 * k
            let outline: [V2] = (0..<sides).map { i in
                let ang = Float(i) / Float(sides) * 2 * .pi, s = sin(ang)
                return V2(cos(ang) * a, s * (s >= 0 ? back : front))
            }
            rings.append(Prim.ring(outline, y: 0.005 + 0.31 * t, offset: V3(0, 0, 0.01)))
        }
        return rings
    }

    /// Cape shell: a thin cloth sheet hanging from the shoulders, widening toward the hem with deterministic fold waves.
    func capeRings(hi: Bool) -> [[V3]] {
        let rows = hi ? 22 : 8, cols = hi ? 25 : 9
        var rings: [[V3]] = []
        for j in 0..<rows {
            let t = Float(j) / Float(rows - 1)
            let half = 0.2 + 0.17 * pow(t, 0.8)
            var front: [V3] = []
            for i in 0..<cols {
                let u = Float(i) / Float(cols - 1) * 2 - 1
                let x = u * half
                let fold = 0.02 * t * sin(u * 9 + t * 2.0) + 0.012 * t * sin(u * 17 + 1.3)
                let z = -0.215 - 0.05 * u * u * (1 - 0.5 * t) - 0.1 * t - fold
                front.append(V3(x, -0.04 - 1.21 * t, z))
            }
            let back = front.reversed().map { $0 + V3(0, 0, -0.005) }
            rings.append(front + back)
        }
        return rings
    }

    // MARK: Rig

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [3])
        let X = V3(1, 0, 0), Y = V3(0, 1, 0), Z = V3(0, 0, 1)
        let flipX = simd_quatf(angle: .pi, axis: X)
        let hip = V3(0, -0.53, 0)

        // Drivers first so option links resolve.
        for name in ["cowl", "emblem", "grapple"] {
            _ = rig.part(name, pivot: .zero, joint: .hinge(axis: Y, 0...1, duration: 0.5))
        }
        _ = rig.part("cape", pivot: .zero, joint: .hinge(axis: Y, -1...1, duration: 0.5))
        let pivots: [(String, V3)] = [
            ("helmet", V3(0, 0, 0)), ("chest", V3(0, -0.18, 0.12)), ("back", V3(0, -0.20, -0.12)),
            ("shoulderL", V3(Self.shoulderX, -0.05, 0)), ("shoulderR", V3(-Self.shoulderX, -0.05, 0)),
            ("gauntletL", V3(Self.elbowX, Self.elbowY, 0)), ("gauntletR", V3(-Self.elbowX, Self.elbowY, 0)),
            ("capeMantle", V3(0, -0.04, -0.17)),
        ]
        for (name, p) in pivots { _ = rig.part(name, pivot: p, joint: .fixed) }
        _ = rig.part("cowlGlow", parent: "helmet", pivot: V3(0, 0.17, 0.1), joint: .fixed, options: 2)
        _ = rig.part("emblemGlow", parent: "chest", pivot: V3(0, -0.12, 0.17), joint: .fixed, options: 2)
        _ = rig.part("grappleShot", parent: "gauntletR", pivot: V3(-Self.elbowX, Self.elbowY, 0), joint: .fixed, options: 2)
        rig.optionLinks = [
            RigOptionLink(part: "cowlGlow", joint: "cowl", thresholds: [0.05]),
            RigOptionLink(part: "emblemGlow", joint: "emblem", thresholds: [0.05]),
            RigOptionLink(part: "grappleShot", joint: "grapple", thresholds: [0.05]),
        ]

        for l in 0..<2 {
            let hi = l == 0
            let sides = hi ? 48 : 16
            func put(_ s: Surface, _ part: String, option: Int = 0, _ x: Xform = .identity) {
                rig.add(s, x, to: part, option: option, lods: l...l)
            }
            func rivet(_ part: String, _ at: V3, _ dir: V3) {
                put(Prim.lathe([V2(0.0065, 0), V2(0.0048, 0.003), V2(0.001, 0.0046)], segments: 10, seamTile: 0.02, material: trimMat), part,
                    Xform(translation: at, rotation: simd_quatf(from: Y, to: dir)))
            }
            func armor(_ part: String, _ c: V3, right: V3, up: V3, out: V3, w: Float, h: Float, t: Float, b: Float,
                       rivets: Bool = true, _ mat: MaterialKey? = nil) {
                put(plate(c, right: right, up: up, out: out, width: w, height: h, thick: t, bulge: b, hi: hi, mat ?? plateMat), part)
                guard hi && rivets else { return }
                for s in [Float(-0.75), 0.75] {
                    let at = c + right * (s * w / 2) + out * (b * (1 - s * s) + t * 0.5)
                    rivet(part, at, simd_normalize(out + right * (2 * b * s / (w / 2))))
                }
            }
            func seam(_ part: String, _ c: V3, right: V3, out: V3, w: Float, b: Float) {
                let n = hi ? 9 : 4
                let path = (0..<n).map { i -> V3 in
                    let s = Float(i) / Float(n - 1) * 2 - 1
                    return c + right * (s * w / 2) + out * (b * (1 - s * s))
                }
                put(Prim.tube(path, radii: path.map { _ in 0.0035 }, sides: hi ? 8 : 4, seamTile: 0.02, material: trimMat, capEnd: true), part)
            }

            // MARK: Cowl: shell, pointed ears, lenses, jaw guard
            do {
                put(Prim.loft(cowlRings(hi: hi), capStart: true, capEnd: true, material: suit), "helmet")
                for sx in [Float(-1), 1] {
                    // Pointed ear: tall narrow cone leaning back and out.
                    put(Prim.lathe([V2(0.03, 0), V2(0.027, 0.03), V2(0.017, 0.07), V2(0.007, 0.105), V2(0.001, 0.135)], segments: sides, seamTile: 0.05, material: plateMat), "helmet",
                        Xform(translation: V3(sx * 0.062, 0.305, -0.005), rotation: simd_quatf(angle: -sx * rad(12), axis: Z) * simd_quatf(angle: -rad(8), axis: X)))
                    // Angular brow plate over each lens and the slanted lens itself.
                    let a = rad(20)
                    let r = V3(cos(a), sx * sin(a), 0)
                    armor("helmet", V3(sx * 0.05, 0.188, 0.062), right: r, up: Y, out: Z, w: 0.105, h: 0.03, t: 0.02, b: 0.04, rivets: false, plateMat)
                    put(plate(V3(sx * 0.05, 0.168, 0.099), right: r, up: Y, out: Z, width: 0.092, height: 0.026, thick: 0.01, bulge: 0.012, hi: hi, glass), "cowlGlow", option: 0)
                    put(plate(V3(sx * 0.05, 0.168, 0.103), right: r, up: Y, out: Z, width: 0.088, height: 0.022, thick: 0.01, bulge: 0.012, hi: hi, glow), "cowlGlow", option: 1)
                    // Jaw guard plate along each cheek.
                    armor("helmet", V3(sx * 0.087, 0.07, 0.03), right: Z, up: Y, out: X * sx, w: 0.14, h: 0.1, t: 0.012, b: 0.012, plateMat)
                }
                // Nose bridge and chin plate.
                armor("helmet", V3(0, 0.12, 0.103), right: Y, up: X, out: Z, w: 0.07, h: 0.022, t: 0.012, b: 0.01, rivets: false, plateMat)
                armor("helmet", V3(0, 0.025, 0.1), right: X, up: Y, out: Z, w: 0.13, h: 0.045, t: 0.016, b: 0.035, trimMat)
                // Neck collar the cape hangs from.
                put(Prim.lathe([V2(0.07, 0), V2(0.098, 0.01), V2(0.11, 0.05), V2(0.092, 0.075)], segments: sides, seamTile: 0.1, material: plateMat), "helmet",
                    Xform(translation: V3(0, -0.05, -0.01)))
            }

            // MARK: Chest: pectoral plates, emblem, abdomen lames, utility belt
            do {
                put(Prim.superellipsoid(V3(0.36, 0.78, 0.24), exponent: 2.4, subdivisions: hi ? 6 : 3, material: suit), "chest", Xform(translation: V3(0, -0.38, 0)))
                let tilt = rad(14)
                for sx in [Float(-1), 1] {
                    let r = V3(cos(tilt), 0, -sx * sin(tilt)), o = V3(sx * sin(tilt), 0, cos(tilt))
                    armor("chest", V3(sx * 0.092, -0.13, 0.07), right: r, up: Y, out: o, w: 0.19, h: 0.15, t: 0.022, b: 0.07)
                }
                armor("chest", V3(0, -0.025, 0.07), right: X, up: Y, out: Z, w: 0.3, h: 0.055, t: 0.02, b: 0.06, trimMat)
                for i in 0..<4 {
                    let f = Float(i)
                    let c = V3(0, -0.245 - 0.056 * f, 0.045)
                    armor("chest", c, right: X, up: Y, out: Z, w: 0.26 - 0.015 * f, h: 0.06, t: 0.016, b: 0.07 - 0.008 * f, rivets: false)
                    seam("chest", c + V3(0, -0.031, 0), right: X, out: Z, w: 0.25 - 0.015 * f, b: 0.068 - 0.008 * f)
                }
                // Chest emblem: hexagon ring and a lozenge, dull trim (option 0) or lit white (option 1).
                let emAt = V3(0, -0.125, 0.172)
                let hex = (0...6).map { i -> V3 in
                    let a = Float(i % 6) / 6 * 2 * .pi + .pi / 6
                    return emAt + V3(0.062 * cos(a), 0.062 * sin(a), 0)
                }
                for opt in 0..<2 {
                    let m = opt == 0 ? trimMat : glow
                    put(Prim.tube(hex, radii: hex.map { _ in 0.0045 }, sides: hi ? 12 : 5, seamTile: 0.02, material: m, capEnd: true), "emblemGlow", option: opt)
                    put(Prim.superellipsoid(V3(0.048, 0.086, 0.01), exponent: 1.3, subdivisions: hi ? 6 : 3, material: m), "emblemGlow", option: opt,
                        Xform(translation: emAt + V3(0, 0, 0.0)))
                }
                // Utility belt with buckle and six pouches.
                put(Prim.torus(major: 0.172, minor: 0.016, segments: hi ? 64 : 24, sides: hi ? 12 : 6, material: suit), "chest",
                    Xform(translation: hip, scale: V3(1, 1, 0.72)))
                armor("chest", hip + V3(0, 0, 0.125), right: X, up: Y, out: Z, w: 0.075, h: 0.05, t: 0.016, b: 0.012, rivets: false, trimMat)
                for k in 0..<6 {
                    let a = (Float(k) - 2.5) * rad(26)
                    let p = V3(0.172 * sin(a), 0, 0.172 * 0.72 * cos(a))
                    if abs(a) < rad(10) { continue }
                    put(Prim.superellipsoid(V3(0.045, 0.06, 0.03), exponent: 3, subdivisions: hi ? 5 : 3, material: plateMat), "chest",
                        Xform(translation: hip + p + V3(0, -0.005, 0.015), rotation: simd_quatf(angle: a, axis: Y)))
                }
            }

            // MARK: Back plate and cape clasp
            do {
                armor("back", V3(0, -0.2, -0.07), right: X, up: Y, out: -Z, w: 0.34, h: 0.3, t: 0.025, b: 0.07)
                put(Prim.tube([V3(0, -0.06, -0.16), V3(0, -0.2, -0.19), V3(0, -0.34, -0.16)], radii: [0.011, 0.014, 0.011], sides: hi ? 24 : 8, seamTile: 0.03, material: trimMat, capEnd: true), "back")
                // Cape yoke: a titanium bar across the shoulders at the top edge of the cape.
                let yoke = [V3(-0.2, -0.035, -0.1), V3(-0.1, -0.035, -0.195), V3(0.1, -0.035, -0.195), V3(0.2, -0.035, -0.1)]
                put(Prim.tube(yoke, radii: yoke.map { _ in 0.011 }, sides: hi ? 24 : 8, seamTile: 0.03, material: trimMat, capEnd: true), "capeMantle")
            }

            // MARK: Cape
            put(Prim.loft(capeRings(hi: hi), capStart: true, capEnd: true, material: capeMat), "capeMantle")

            // MARK: Shoulders
            for (sx, name) in [(Float(1), "shoulderL"), (Float(-1), "shoulderR")] {
                let tiltZ = simd_quatf(angle: -sx * 0.3, axis: Z)
                let base = V3(sx * 0.235, -0.07, 0)
                put(Prim.tube([V3(sx * 0.2, -0.05, 0), V3(sx * 0.208, -0.18, 0), V3(sx * Self.elbowX, Self.elbowY, 0)], radii: [0.05, 0.047, 0.043], sides: hi ? 24 : 8, seamTile: 0.05, material: suit, capEnd: true), name)
                put(Prim.lathe([V2(0.11, 0), V2(0.118, 0.01), V2(0.108, 0.035), V2(0.085, 0.058), V2(0.05, 0.075), V2(0.001, 0.082)], segments: sides, seamTile: 0.1, material: plateMat),
                    name, Xform(translation: base, rotation: tiltZ, scale: V3(1, 1, 1.12)))
                put(Prim.torus(major: 0.113, minor: 0.006, segments: hi ? 48 : 16, sides: hi ? 10 : 5, material: trimMat), name,
                    Xform(translation: base + V3(0, 0.004, 0), rotation: tiltZ, scale: V3(1, 1, 1.12)))
                for i in 0..<2 {
                    let f = Float(i)
                    armor(name, V3(sx * (0.3 - 0.014 * f), -0.09 - 0.05 * f, 0), right: Z, up: Y, out: X * sx, w: 0.19 - 0.015 * f, h: 0.05, t: 0.012, b: 0.04)
                }
            }

            // MARK: Bracers with scalloped fins; grapple launcher on the right wrist (-X)
            for (sx, name) in [(Float(1), "gauntletL"), (Float(-1), "gauntletR")] {
                let e = V3(sx * Self.elbowX, Self.elbowY, 0)
                put(Prim.tube([e, e + V3(0, -0.12, 0), e + V3(0, -0.25, 0)], radii: [0.045, 0.043, 0.04], sides: hi ? 24 : 8, seamTile: 0.05, material: suit, capEnd: true), name)
                put(Prim.lathe([V2(0.062, 0), V2(0.066, 0.015), V2(0.058, 0.06), V2(0.05, 0.14), V2(0.052, 0.2), V2(0.048, 0.226), V2(0.044, 0.232)], segments: sides, seamTile: 0.08, material: plateMat),
                    name, Xform(translation: e, rotation: flipX))
                // Three scalloped fins swept outward along the forearm, each shorter than the last.
                for i in 0..<3 {
                    let f = Float(i)
                    let y0 = -0.06 - 0.055 * f
                    let n = hi ? 9 : 4
                    let fin = (0..<n).map { k -> V3 in
                        let u = Float(k) / Float(n - 1)
                        return e + V3(sx * (0.058 + 0.05 * sin(u * .pi) * (1 - 0.2 * f)), y0 - 0.05 * u + 0.012 * sin(u * .pi), 0.0)
                    }
                    put(Prim.tube(fin, radii: fin.indices.map { 0.004 + 0.003 * sin(Float($0) / Float(n - 1) * .pi) }, sides: hi ? 12 : 5, seamTile: 0.03, material: trimMat, capEnd: true), name)
                    put(Prim.sweep(octagon(0.045, 0.005, chamfer: 0.0015), along: fin, up: Z, scales: fin.indices.map { 0.2 + 0.8 * sin(Float($0) / Float(n - 1) * .pi) }, caps: true, material: plateMat), name)
                }
                seam(name, e + V3(0, -0.075, 0), right: Z, out: X * sx, w: 0.1, b: 0.0)
                put(Prim.tube([e + V3(0, -0.23, 0), e + V3(0, -0.26, 0.0)], radii: [0.04, 0.042], sides: hi ? 24 : 8, seamTile: 0.05, material: suit, capEnd: true), name)
                put(Prim.superellipsoid(V3(0.085, 0.1, 0.1), exponent: 2.6, subdivisions: hi ? 6 : 3, material: suit), name, Xform(translation: e + V3(0, -0.3, 0.005)))
                armor(name, e + V3(0, -0.285, 0.05), right: X, up: Y, out: Z, w: 0.08, h: 0.03, t: 0.01, b: 0.012, rivets: false)
            }
            // Launcher on the right wrist: box housing and barrel, both states; the shot adds a line and a hook.
            do {
                let e = V3(-Self.elbowX, Self.elbowY, 0)
                let top = e + V3(0, -0.2, 0.05)
                put(Prim.superellipsoid(V3(0.05, 0.09, 0.04), exponent: 3, subdivisions: hi ? 5 : 3, material: gunmetal), "gauntletR", Xform(translation: top + V3(0, -0.02, 0)))
                put(Prim.tube([top + V3(0, -0.05, 0), top + V3(0, -0.09, 0)], radii: [0.014, 0.012], sides: hi ? 32 : 8, seamTile: 0.03, material: gunmetal, capEnd: true), "gauntletR")
                // Fired: line along -Y and a three-prong hook at the end (0.55 m).
                let n = hi ? 7 : 3
                let line = (0..<n).map { i in top + V3(0, -0.09 - 0.46 * Float(i) / Float(n - 1), 0) }
                put(Prim.tube(line, radii: line.map { _ in 0.0035 }, sides: hi ? 8 : 4, seamTile: 0.02, material: gunmetal, capEnd: true), "grappleShot", option: 1)
                let hookAt = top + V3(0, -0.55, 0)
                put(Prim.lathe([V2(0.001, 0), V2(0.014, 0.004), V2(0.012, 0.03), V2(0.001, 0.034)], segments: hi ? 24 : 8, seamTile: 0.03, material: gunmetal), "grappleShot", option: 1,
                    Xform(translation: hookAt + V3(0, -0.03, 0)))
                for k in 0..<3 {
                    let a = Float(k) / 3 * 2 * .pi
                    let p0 = hookAt + V3(0, -0.03, 0)
                    let path = (0..<(hi ? 6 : 3)).map { i -> V3 in
                        let u = Float(i) / Float(hi ? 5 : 2)
                        return p0 + V3(0.04 * sin(u * 1.6) * cos(a), -0.02 - 0.05 * u + 0.0 * u, 0.04 * sin(u * 1.6) * sin(a))
                    }
                    put(Prim.tube(path, radii: path.indices.map { 0.006 * (1 - 0.7 * Float($0) / Float(path.count - 1)) + 0.001 }, sides: hi ? 16 : 6, seamTile: 0.02, material: gunmetal, capEnd: true),
                        "grappleShot", option: 1)
                }
            }
        }

        rig.states = [
            RigState("rest", [:]),
            RigState("cowl-lit", ["cowl": 1], options: ["cowlGlow": 1]),
            RigState("emblem", ["cowl": 1, "emblem": 1], options: ["cowlGlow": 1, "emblemGlow": 1]),
            RigState("glide", ["cowl": 1, "cape": 1], options: ["cowlGlow": 1]),
            RigState("grapple", ["cowl": 1, "emblem": 1, "grapple": 1], options: ["cowlGlow": 1, "emblemGlow": 1, "grappleShot": 1]),
        ]
        return rig
    }
}
