import simd
import Foundation

/// Weathered dark iron knight kit, life size for a 1.75 m wearer: a closed great helm with a vision slit and a frayed plume
/// stub, a pitted breastplate under a tattered wool surcoat, layered pauldrons, riveted vambraces, leather gloves, a ragged cloak
/// on a swaying joint and a long sword held in the right hand (tip along -Y, along the raised forearm). Original shapes only:
/// no crests, no emblems. Origin at the neck base, face toward +Z, up +Y, wearer's left = +X.
///
/// Kit parts (pivots in asset space): `helmet` (0, 0, 0), `chest` (0, -0.18, 0.12), `back` (0, -0.20, -0.12),
/// `shoulderL` / `shoulderR` (+-0.20, -0.05, 0), `gauntletL` / `gauntletR` (+-0.215, -0.31, 0) with the forearm along -Y,
/// `cloak` (0, -0.03, -0.105) with child `cloakSway`.
///
/// Joints (set with `setJoints`): `grace` (0...1) lights the golden rune lines on the breastplate, `cloak` (-1...1)
/// swings the cloak 20 degrees about X (mimic child `cloakSway`), `blade` (0...1) lights the golden sword glint, `message`
/// (0...1) lights the amber message plaque on the belt. 0...1 joints are empty drivers; followers `graceRunes`, `bladeGlint`,
/// `messagePlaque` switch between option 0 and option 1 when the joint passes 0.05. 2 LODs.
public struct TarnishedArmor: RealArticulated {
    public static let id = "tarnished-armor"
    public static let summary = "Weathered dark iron knight kit: great helm, pitted breastplate, tattered surcoat and cloak, pauldrons, vambraces and a long sword with golden rune lines."
    public static let tags = ["prop", "metal", "fabric", "articulated", "glowing"]
    public static let budget = 20_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 8, distance: 1.0)

    /// Plate: helm, breastplate, pauldrons, vambraces (Metal.swift:15, painted iron with rust edge).
    public var plate: MaterialKey = "metal.iron"
    /// Pitted raw iron for rims, rivets and the cloak clasp (Craft.swift:66).
    public var rawIron: MaterialKey = "metal.cast-iron"
    /// Sword steel (Metal.swift:14).
    public var steel: MaterialKey = "metal.steel"
    /// Tattered surcoat (Fabric.swift:25, tint at the lens).
    public var surcoat: MaterialKey = "fabric.wool:3A3630"
    /// Cloak cloth (Fabric.swift:25).
    public var cloakCloth: MaterialKey = "fabric.wool:241F1B"
    /// Gloves and straps (Craft.swift:18).
    public var leather: MaterialKey = "leather.black"
    /// Gold leaf trim and rune inlay base (Metal.swift:19).
    public var gold: MaterialKey = "metal.gold-leaf"
    /// Lit rune lines and sword glint (TerawattFab.swift:110).
    public var rune: MaterialKey = "emissive.amber"
    /// Message plaque light (Emissive.swift:10).
    public var plaque: MaterialKey = "emissive.warm"
    public init() {}

    static let elbowX: Float = 0.215
    static let elbowY: Float = -0.31
    static let shoulderX: Float = 0.20

    /// Great helm profile (radius, y): flat-topped barrel with a slight crown.
    func helmProfile(hi: Bool) -> [V2] {
        let n = hi ? 12 : 5
        var p: [V2] = [V2(0.118, -0.02), V2(0.13, 0.0), V2(0.138, 0.06), V2(0.14, 0.2)]
        for k in 1...n {
            let a = Float(k) / Float(n) * .pi / 2
            p.append(V2(max(0.001, 0.14 * cos(a) * 0.96 + 0.0), 0.2 + 0.07 * sin(a)))
        }
        return p
    }

    // MARK: Rig

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [3])
        let X = V3(1, 0, 0), Y = V3(0, 1, 0), Z = V3(0, 0, 1)
        let flipX = simd_quatf(angle: .pi, axis: X)

        for name in ["grace", "blade", "message"] {
            _ = rig.part(name, pivot: .zero, joint: .hinge(axis: Y, 0...1, duration: 0.5))
        }
        let pivots: [(String, V3)] = [
            ("helmet", V3(0, 0, 0)), ("chest", V3(0, -0.18, 0.12)), ("back", V3(0, -0.20, -0.12)),
            ("shoulderL", V3(Self.shoulderX, -0.05, 0)), ("shoulderR", V3(-Self.shoulderX, -0.05, 0)),
            ("gauntletL", V3(Self.elbowX, Self.elbowY, 0)), ("gauntletR", V3(-Self.elbowX, Self.elbowY, 0)),
        ]
        for (name, p) in pivots { _ = rig.part(name, pivot: p, joint: .fixed) }
        let cloakPivot = V3(0, -0.03, -0.105)
        _ = rig.part("cloak", pivot: cloakPivot, joint: .hinge(axis: X, -1...1, duration: 1.2))
        _ = rig.part("cloakSway", parent: "cloak", pivot: cloakPivot,
                     joint: Joint(.revolute, axis: X, range: -20...20, mimic: .init("cloak", ratio: 20)))
        _ = rig.part("graceRunes", parent: "chest", pivot: V3(0, -0.2, 0.2), joint: .fixed, options: 2)
        _ = rig.part("bladeGlint", parent: "gauntletR", pivot: V3(-Self.elbowX, Self.elbowY - 0.4, 0), joint: .fixed, options: 2)
        _ = rig.part("messagePlaque", parent: "chest", pivot: V3(0, -0.5, 0.15), joint: .fixed, options: 2)
        rig.optionLinks = [
            RigOptionLink(part: "graceRunes", joint: "grace", thresholds: [0.05]),
            RigOptionLink(part: "bladeGlint", joint: "blade", thresholds: [0.05]),
            RigOptionLink(part: "messagePlaque", joint: "message", thresholds: [0.05]),
        ]

        for l in 0..<2 {
            let hi = l == 0
            let sides = hi ? 48 : 16
            func put(_ s: Surface, _ part: String, option: Int = 0, _ x: Xform = .identity) {
                rig.add(s, x, to: part, option: option, lods: l...l)
            }
            func ring(_ part: String, _ at: V3, major: Float, minor: Float, _ mat: MaterialKey, scale: V3 = V3(1, 1, 1)) {
                put(Prim.torus(major: major, minor: minor, segments: hi ? 48 : 16, sides: hi ? 12 : 6, material: mat), part,
                    Xform(translation: at, scale: scale))
            }
            func rivet(_ part: String, _ at: V3, r: Float = 0.007) {
                put(Prim.superellipsoid(V3(r, r, r * 0.7), exponent: 2, subdivisions: hi ? 4 : 2, material: rawIron), part, Xform(translation: at))
            }

            // MARK: Helmet: great helm barrel, vision slit, breath holes, gold brow band, plume stub
            do {
                put(Prim.lathe(helmProfile(hi: hi), segments: sides, seamTile: 0.1, material: plate), "helmet", Xform(translation: V3(0, 0, 0.01), scale: V3(1, 1, 1.08)))
                ring("helmet", V3(0, 0.0, 0.01), major: 0.122, minor: 0.012, rawIron, scale: V3(1, 1, 1.08))
                ring("helmet", V3(0, 0.2, 0.01), major: 0.141, minor: 0.007, gold, scale: V3(1, 1, 1.08))
                // Vision slit: dark bar recessed on the face.
                put(Prim.superellipsoid(V3(0.12, 0.012, 0.01), exponent: 4, subdivisions: hi ? 5 : 3, material: leather), "helmet", Xform(translation: V3(0, 0.15, 0.158)))
                // Vertical face ridge and breath holes.
                put(Prim.superellipsoid(V3(0.012, 0.15, 0.014), exponent: 3, subdivisions: hi ? 5 : 3, material: rawIron), "helmet", Xform(translation: V3(0, 0.09, 0.157)))
                for k in 0..<(hi ? 5 : 2) {
                    for sx in [Float(-1), 1] {
                        put(Prim.superellipsoid(V3(0.005, 0.005, 0.004), exponent: 2, subdivisions: 3, material: leather), "helmet",
                            Xform(translation: V3(sx * 0.04, 0.05 + 0.018 * Float(k), 0.155)))
                    }
                }
                // Frayed plume stub on the crown.
                put(Prim.tube([V3(0, 0.26, 0), V3(0, 0.32, -0.04), V3(0, 0.3, -0.12), V3(0, 0.22, -0.18)], radii: [0.016, 0.02, 0.016, 0.006], sides: hi ? 16 : 6,
                              seamTile: 0.03, material: cloakCloth, capEnd: true), "helmet")
            }

            // MARK: Chest: pitted breastplate, surcoat, belt, gorget
            do {
                put(Prim.superellipsoid(V3(0.4, 0.58, 0.26), exponent: 2.6, subdivisions: hi ? 6 : 3, material: plate), "chest", Xform(translation: V3(0, -0.2, 0)))
                // Ridge down the plate.
                put(Prim.superellipsoid(V3(0.02, 0.5, 0.05), exponent: 2.4, subdivisions: hi ? 5 : 3, material: rawIron), "chest", Xform(translation: V3(0, -0.2, 0.125)))
                // Surcoat: tattered skirt over the belt, hanging front panel.
                put(Prim.lathe([V2(0.19, 0), V2(0.21, -0.1), V2(0.235, -0.22), V2(0.25, -0.3)], segments: sides, seamTile: 0.1, material: surcoat), "chest",
                    Xform(translation: V3(0, -0.43, 0), scale: V3(1, 1, 0.7)))
                let drop = (0..<(hi ? 8 : 4)).map { i -> V3 in
                    let u = Float(i) / Float(hi ? 7 : 3)
                    return V3(0.01 * sin(u * 5), -0.2 - 0.52 * u, 0.15 + 0.012 * sin(u * 7))
                }
                put(Prim.tube(drop, radii: drop.map { _ in 0.075 }, sides: hi ? 24 : 8, seamTile: 0.05, material: surcoat, capEnd: true), "chest", Xform(scale: V3(1, 1, 0.12)))
                // Belt, buckle plate.
                ring("chest", V3(0, -0.5, 0), major: 0.19, minor: 0.014, leather, scale: V3(1, 1, 0.7))
                put(Prim.superellipsoid(V3(0.05, 0.04, 0.012), exponent: 3, subdivisions: hi ? 5 : 3, material: gold), "chest", Xform(translation: V3(0, -0.5, 0.135)))
                // Gorget collar.
                put(Prim.lathe([V2(0.1, 0.05), V2(0.14, 0.02), V2(0.19, -0.04), V2(0.205, -0.1)], segments: sides, seamTile: 0.1, material: plate), "chest", Xform(translation: V3(0, 0.14, -0.04)))
                for k in 0..<(hi ? 6 : 0) { rivet("chest", V3(-0.12 + 0.048 * Float(k), 0.04, 0.138)) }
                // Rune lines across the plate: dormant gold inlay (option 0) and lit amber (option 1).
                for (opt, mat) in [(0, gold), (1, rune)] {
                    put(Prim.tube([V3(-0.11, 0.03, 0), V3(0, -0.04, 0.012), V3(0.11, 0.03, 0)], radii: [0.003, 0.003, 0.003], sides: hi ? 8 : 4, seamTile: 0.02, material: mat, capEnd: true),
                        "graceRunes", option: opt, Xform(translation: V3(0, -0.1, 0.135)))
                    put(Prim.tube([V3(0, -0.04, 0.012), V3(0, -0.2, 0.014), V3(0, -0.32, 0.01)], radii: [0.003, 0.003, 0.003], sides: hi ? 8 : 4, seamTile: 0.02, material: mat, capEnd: true),
                        "graceRunes", option: opt, Xform(translation: V3(0, -0.1, 0.135)))
                }
                // Message plaque: dull brass (option 0) or amber light (option 1).
                put(Prim.superellipsoid(V3(0.05, 0.03, 0.01), exponent: 3, subdivisions: hi ? 5 : 3, material: rawIron), "messagePlaque", option: 0)
                put(Prim.superellipsoid(V3(0.05, 0.03, 0.01), exponent: 3, subdivisions: hi ? 5 : 3, material: plaque), "messagePlaque", option: 1)
            }

            // MARK: Back plate
            do {
                put(Prim.superellipsoid(V3(0.38, 0.5, 0.18), exponent: 2.8, subdivisions: hi ? 6 : 3, material: plate), "back", Xform(translation: V3(0, -0.2, -0.12)))
                ring("back", V3(0, -0.35, -0.12), major: 0.17, minor: 0.012, leather, scale: V3(1, 1, 0.7))
                for sx in [Float(-1), 1] { rivet("back", V3(sx * 0.07, -0.02, -0.28), r: 0.01) }
            }

            // MARK: Cloak: torn cloth lofted from the shoulders, double sided, ragged hem; clasp ring
            do {
                let nu = hi ? 14 : 6, nv = hi ? 12 : 5
                func cloth(_ v: Float, _ u: Float) -> V3 {
                    let x = (u - 0.5) * (0.34 + 0.24 * v)
                    let rag = 0.04 * v * v * sin(u * 23 + 1.3) + 0.03 * v * sin(u * 9)
                    let y = -0.02 - 0.86 * v * (1 - 0.15 * abs(u - 0.5)) - rag
                    let z = -0.02 - 0.12 * v - 0.03 * sin(u * 6 + v * 3) * v
                    return V3(x, y, z)
                }
                let rows = (0...nv).map { i in (0...nu).map { j in cloth(Float(i) / Float(nv), Float(j) / Float(nu)) } }
                put(Prim.loft(rows, material: cloakCloth), "cloakSway")
                put(Prim.loft(rows.map { $0.map { $0 + V3(0, 0, -0.004) }.reversed() }, material: cloakCloth), "cloakSway")
                put(Prim.tube((0...nu).map { cloth(0, Float($0) / Float(nu)) + V3(0, 0.0, 0) }, radii: [Float](repeating: 0.012, count: nu + 1), sides: hi ? 12 : 5,
                              seamTile: 0.03, material: cloakCloth, capEnd: true), "cloakSway")
                ring("cloak", V3(0, 0.0, 0.0), major: 0.012, minor: 0.004, gold)
            }

            // MARK: Shoulders: layered pauldrons with gold trim and iron rims
            for (sx, name) in [(Float(1), "shoulderL"), (Float(-1), "shoulderR")] {
                let base = V3(sx * 0.235, -0.07, 0)
                put(Prim.lathe([V2(0.115, 0), V2(0.12, 0.015), V2(0.105, 0.045), V2(0.075, 0.07), V2(0.04, 0.082), V2(0.001, 0.088)], segments: sides, seamTile: 0.1, material: plate), name,
                    Xform(translation: base, rotation: simd_quatf(angle: -sx * 0.3, axis: Z), scale: V3(1, 1, 1.1)))
                put(Prim.lathe([V2(0.12, 0), V2(0.126, -0.02), V2(0.112, -0.055), V2(0.09, -0.07)], segments: sides, seamTile: 0.1, material: plate), name,
                    Xform(translation: base + V3(sx * 0.006, -0.01, 0), rotation: simd_quatf(angle: -sx * 0.3, axis: Z), scale: V3(1, 1, 1.1)))
                ring(name, base + V3(0, 0.004, 0), major: 0.12, minor: 0.008, rawIron, scale: V3(1, 1, 1.1))
                ring(name, base + V3(sx * 0.003, 0.03, 0), major: 0.09, minor: 0.004, gold, scale: V3(1, 1, 1.1))
                let upper = [V3(sx * 0.2, -0.05, 0), V3(sx * 0.208, -0.18, 0), V3(sx * Self.elbowX, Self.elbowY, 0)]
                put(Prim.tube(upper, radii: [0.058, 0.055, 0.05], sides: hi ? 32 : 10, seamTile: 0.05, material: leather, capEnd: true), name)
            }

            // MARK: Vambraces, elbow cops, gloves
            for (sx, name) in [(Float(1), "gauntletL"), (Float(-1), "gauntletR")] {
                let e = V3(sx * Self.elbowX, Self.elbowY, 0)
                put(Prim.superellipsoid(V3(0.12, 0.09, 0.12), exponent: 2.4, subdivisions: hi ? 5 : 3, material: plate), name, Xform(translation: e + V3(0, 0.0, -0.01)))
                put(Prim.tube([e + V3(0, -0.05, 0), e + V3(0, -0.14, 0), e + V3(0, -0.23, 0)], radii: [0.055, 0.052, 0.045], sides: hi ? 32 : 10, seamTile: 0.05, material: plate, capEnd: true), name)
                for k in 0..<(hi ? 3 : 1) { ring(name, e + V3(0, -0.08 - 0.05 * Float(k), 0), major: 0.054 - 0.003 * Float(k), minor: 0.005, rawIron) }
                ring(name, e + V3(0, -0.235, 0), major: 0.046, minor: 0.008, gold)
                put(Prim.lathe([V2(0.05, 0), V2(0.058, 0.012), V2(0.054, 0.04), V2(0.046, 0.05)], segments: sides, seamTile: 0.08, material: leather), name,
                    Xform(translation: e + V3(0, -0.225, 0), rotation: flipX))
                put(Prim.superellipsoid(V3(0.09, 0.115, 0.07), exponent: 2.4, subdivisions: hi ? 6 : 3, material: leather), name, Xform(translation: e + V3(0, -0.335, 0.004)))
                for f in 0..<4 {
                    let x = (Float(f) - 1.5) * 0.02
                    put(Prim.tube([e + V3(x, -0.38, 0.015), e + V3(x, -0.42, 0.028), e + V3(x, -0.447, 0.025)], radii: [0.0095, 0.009, 0.0075], sides: hi ? 12 : 5,
                                  seamTile: 0.02, material: leather, capEnd: true), name)
                }
            }

            // MARK: Sword in the right hand: grip, pommel, crossguard, lens-section blade along -Y; glint overlay (option 1)
            do {
                let e = V3(-Self.elbowX, Self.elbowY, 0)
                let g = e + V3(0, -0.4, 0.02)
                put(Prim.tube([g + V3(0, 0.06, 0), g + V3(0, -0.06, 0)], radii: [0.014, 0.014], sides: hi ? 24 : 8, seamTile: 0.03, material: leather, capEnd: true), "gauntletR")
                put(Prim.superellipsoid(V3(0.03, 0.03, 0.03), exponent: 2, subdivisions: hi ? 5 : 3, material: rawIron), "gauntletR", Xform(translation: g + V3(0, 0.085, 0)))
                put(Prim.tube([g + V3(-0.1, -0.075, 0), g + V3(0, -0.075, 0), g + V3(0.1, -0.075, 0)], radii: [0.008, 0.011, 0.008], sides: hi ? 24 : 8,
                              seamTile: 0.03, material: rawIron, capEnd: true), "gauntletR")
                let diamond = [V2(-0.02, 0), V2(0, 0.0045), V2(0.02, 0), V2(0, -0.0045)]
                let path = [g + V3(0, -0.08, 0), g + V3(0, -0.45, 0), g + V3(0, -0.82, 0)]
                put(Prim.sweep(diamond, along: path, scales: [1, 0.9, 0.35], material: steel), "gauntletR")
                let glintPath = [g + V3(0, -0.12, 0.003), g + V3(0, -0.45, 0.003), g + V3(0, -0.78, 0.003)]
                put(Prim.sweep([V2(-0.006, 0), V2(0, 0.0015), V2(0.006, 0), V2(0, -0.0015)], along: glintPath, scales: [1, 1, 0.4], material: rune), "bladeGlint", option: 1)
                put(Prim.sweep([V2(-0.006, 0), V2(0, 0.0015), V2(0.006, 0), V2(0, -0.0015)], along: glintPath, scales: [1, 1, 0.4], material: gold), "bladeGlint", option: 0)
            }
        }

        rig.states = [
            RigState("rest", [:]),
            RigState("grace", ["grace": 1], options: ["graceRunes": 1]),
            RigState("blade", ["grace": 1, "blade": 1], options: ["graceRunes": 1, "bladeGlint": 1]),
            RigState("message", ["grace": 1, "blade": 1, "message": 1], options: ["graceRunes": 1, "bladeGlint": 1, "messagePlaque": 1]),
            RigState("sway-left", ["cloak": -1]),
            RigState("sway-right", ["cloak": 1]),
        ]
        return rig
    }
}
