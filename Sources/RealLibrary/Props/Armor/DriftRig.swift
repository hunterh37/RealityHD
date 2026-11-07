import simd
import Foundation

/// Giant-robot pilot drift rig, life size for a 1.75 m wearer: a pale plated exo frame worn over the body with a back spine
/// rig (twin rails, seven vertebra rings, glowing core stack), a chest plate with a reactor ring and core, a pelvis ring with
/// hip skirt plates, layered shoulder pauldrons and two forearm sleeves with a rocket nozzle at each elbow. Original shapes
/// only: no logos, no film marks. Origin at the neck base, face toward +Z, up +Y, wearer's left = +X. The spine sits on -Z.
///
/// Kit parts (pivots in asset space): `spine` (0, 0.05, 0), `chest` (0, -0.18, 0.12), `pelvis` (0, -0.62, 0),
/// `shoulderL` / `shoulderR` (+-0.20, -0.05, 0), `rocketL` / `rocketR` (+-0.215, -0.31, 0) with the forearm along -Y and the
/// nozzle on the +Y side of the elbow.
///
/// Joints (set with `setJoints`): `reactor` (0...1) lights the core stack and chest core, `thrustL` / `thrustR` (0...1) fire
/// the rocket nozzles, `punch` (0...1) is an empty driver. Followers `reactorLit` switches with `reactor` at 0.05 and
/// `flameL` / `flameR` switch with the thrust joints at 0.05. 2 LODs.
public struct DriftRig: RealArticulated {
    public static let id = "drift-rig"
    public static let summary = "Pilot drift exo rig: plated frame, back spine rig, chest reactor and rocket-elbow forearm sleeves."
    public static let tags = ["prop", "metal", "articulated", "glowing"]
    public static let budget = 24_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 205, elevation: 8, distance: 1.1)

    /// Painted armor plates.
    public var paint: MaterialKey = "metal.satin-aluminum"
    /// Rails, vents, bearings.
    public var steel: MaterialKey = "metal.steel"
    /// Rocket nozzle bells.
    public var nozzle: MaterialKey = "metal.anodized-worn"
    /// Seals, harness, flaps.
    public var dark: MaterialKey = "plastic.black"
    /// Lit reactor core.
    public var coreLit: MaterialKey = "emissive.thruster-cyan"
    /// Rocket flame cone.
    public var flameLit: MaterialKey = "emissive.flame"
    public init() {}

    static let elbowX: Float = 0.215
    static let elbowY: Float = -0.31
    static let shoulderX: Float = 0.20

    // MARK: Rig

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [3])
        let X = V3(1, 0, 0), Y = V3(0, 1, 0), Z = V3(0, 0, 1)

        for name in ["reactor", "thrustL", "thrustR", "punch"] {
            _ = rig.part(name, pivot: .zero, joint: .hinge(axis: Y, 0...1, duration: 0.5))
        }
        let pivots: [(String, V3)] = [
            ("spine", V3(0, 0.05, 0)), ("chest", V3(0, -0.18, 0.12)), ("pelvis", V3(0, -0.62, 0)),
            ("shoulderL", V3(Self.shoulderX, -0.05, 0)), ("shoulderR", V3(-Self.shoulderX, -0.05, 0)),
            ("rocketL", V3(Self.elbowX, Self.elbowY, 0)), ("rocketR", V3(-Self.elbowX, Self.elbowY, 0)),
        ]
        for (name, p) in pivots { _ = rig.part(name, pivot: p, joint: .fixed) }
        _ = rig.part("reactorLit", parent: "spine", pivot: V3(0, -0.2, -0.13), joint: .fixed, options: 2)
        _ = rig.part("reactorLitChest", parent: "chest", pivot: V3(0, -0.06, 0.03), joint: .fixed, options: 2)
        _ = rig.part("flameL", parent: "rocketL", pivot: V3(Self.elbowX, Self.elbowY + 0.13, 0), joint: .fixed, options: 2)
        _ = rig.part("flameR", parent: "rocketR", pivot: V3(-Self.elbowX, Self.elbowY + 0.13, 0), joint: .fixed, options: 2)
        rig.optionLinks = [
            RigOptionLink(part: "reactorLit", joint: "reactor", thresholds: [0.05]),
            RigOptionLink(part: "reactorLitChest", joint: "reactor", thresholds: [0.05]),
            RigOptionLink(part: "flameL", joint: "thrustL", thresholds: [0.05]),
            RigOptionLink(part: "flameR", joint: "thrustR", thresholds: [0.05]),
        ]

        for l in 0..<2 {
            let hi = l == 0
            let sides = hi ? 48 : 16
            func put(_ s: Surface, _ part: String, option: Int = 0, _ x: Xform = .identity) {
                rig.add(s, x, to: part, option: option, lods: l...l)
            }
            func ring(_ part: String, _ at: V3, major: Float, minor: Float, _ mat: MaterialKey, tilt: simd_quatf = simd_quatf(angle: 0, axis: V3(0, 1, 0)),
                      scale: V3 = V3(1, 1, 1), option: Int = 0) {
                put(Prim.torus(major: major, minor: minor, segments: hi ? 48 : 16, sides: hi ? 12 : 6, material: mat), part, option: option,
                    Xform(translation: at, rotation: tilt, scale: scale))
            }
            func bolt(_ part: String, _ at: V3, r: Float = 0.007) {
                put(Prim.lathe([V2(r, 0), V2(r * 0.95, 0.004), V2(r * 0.55, 0.008), V2(0.001, 0.009)], segments: hi ? 16 : 6, seamTile: 0.02, material: steel), part,
                    Xform(translation: at, rotation: simd_quatf(angle: .pi / 2, axis: X)))
            }

            // MARK: Spine rig: twin rails, vertebra rings, core stack, shoulder bar
            do {
                for sx in [Float(-1), 1] {
                    put(Prim.tube([V3(sx * 0.07, -0.57, -0.13), V3(sx * 0.07, 0.05, -0.13)], radii: [0.014, 0.014], sides: sides, seamTile: 0.04, material: steel, capEnd: true), "spine")
                }
                for k in 0..<7 {
                    ring("spine", V3(0, 0.04 - 0.09 * Float(k), -0.13), major: 0.085, minor: 0.012, k % 2 == 0 ? paint : dark,
                         tilt: simd_quatf(angle: .pi / 2, axis: X), scale: V3(1, 1, 0.5))
                }
                for k in 0..<4 {
                    let y = -0.04 - 0.14 * Float(k)
                    let core = Prim.lathe([V2(0.02, -0.03), V2(0.02, 0.03)], segments: sides, seamTile: 0.02, material: coreLit)
                    let off = Prim.lathe([V2(0.02, -0.03), V2(0.02, 0.03)], segments: sides, seamTile: 0.02, material: dark)
                    put(core, "reactorLit", option: 1, Xform(translation: V3(0, y + 0.2, -0.005)))
                    put(off, "reactorLit", option: 0, Xform(translation: V3(0, y + 0.2, -0.005)))
                }
                put(Prim.superellipsoid(V3(0.3, 0.06, 0.05), exponent: 3.4, subdivisions: hi ? 6 : 3, material: paint), "spine", Xform(translation: V3(0, 0.07, -0.12)))
                for sx in [Float(-1), 1] { bolt("spine", V3(sx * 0.13, 0.04, -0.15)) }
            }

            // MARK: Chest plate with reactor ring and core
            do {
                put(Prim.superellipsoid(V3(0.38, 0.46, 0.18), exponent: 3.2, subdivisions: hi ? 6 : 3, material: paint), "chest", Xform(translation: V3(0, -0.12, -0.04)))
                ring("chest", V3(0, -0.06, 0.03), major: 0.07, minor: 0.014, dark, tilt: simd_quatf(angle: .pi / 2, axis: X))
                put(Prim.superellipsoid(V3(0.08, 0.08, 0.05), exponent: 2, subdivisions: hi ? 6 : 3, material: coreLit), "reactorLitChest", option: 1)
                put(Prim.superellipsoid(V3(0.08, 0.08, 0.05), exponent: 2, subdivisions: hi ? 6 : 3, material: dark), "reactorLitChest", option: 0)
                for sx in [Float(-1), 1] {
                    put(Prim.tube([V3(sx * 0.11, 0.1, 0.1), V3(sx * 0.12, -0.1, 0.12), V3(sx * 0.11, -0.34, 0.1)], radii: [0.014, 0.014, 0.014], sides: sides, seamTile: 0.05, material: dark, capEnd: true), "chest")
                    bolt("chest", V3(sx * 0.15, 0.02, 0.145))
                }
                ring("chest", V3(0, -0.42, -0.04), major: 0.18, minor: 0.016, paint, scale: V3(1, 1, 0.7))
            }

            // MARK: Pelvis ring and hip skirt plates
            do {
                ring("pelvis", .zero, major: 0.2, minor: 0.026, paint, scale: V3(1, 1, 0.72))
                ring("pelvis", V3(0, -0.06, 0), major: 0.19, minor: 0.012, dark, scale: V3(1, 1, 0.72))
                for sx in [Float(-1), 1] {
                    put(Prim.superellipsoid(V3(0.08, 0.2, 0.14), exponent: 3, subdivisions: hi ? 6 : 3, material: paint), "pelvis", Xform(translation: V3(sx * 0.22, -0.1, 0)))
                    bolt("pelvis", V3(sx * 0.2, 0.0, 0.07))
                }
            }

            // MARK: Shoulder pauldrons
            for (sx, name) in [(Float(1), "shoulderL"), (Float(-1), "shoulderR")] {
                let base = V3(sx * 0.24, -0.07, 0)
                put(Prim.lathe([V2(0.12, 0), V2(0.128, 0.012), V2(0.11, 0.05), V2(0.075, 0.075), V2(0.001, 0.088)], segments: sides, seamTile: 0.1, material: paint), name,
                    Xform(translation: base, rotation: simd_quatf(angle: -sx * 0.3, axis: Z), scale: V3(1, 1, 1.12)))
                ring(name, base, major: 0.122, minor: 0.01, dark, tilt: simd_quatf(angle: -sx * 0.3, axis: Z), scale: V3(1, 1, 1.12))
                let upper = [V3(sx * 0.2, -0.05, 0), V3(sx * 0.208, -0.18, 0), V3(sx * Self.elbowX, Self.elbowY, 0)]
                put(Prim.tube(upper, radii: [0.05, 0.048, 0.046], sides: hi ? 32 : 10, seamTile: 0.05, material: paint, capEnd: true), name)
                bolt(name, V3(sx * 0.29, -0.02, 0.03))
            }

            // MARK: Rocket forearm: sleeve, intake rings, elbow cap, nozzle bell, flame cone when thrusting
            for (sx, name, flame) in [(Float(1), "rocketL", "flameL"), (Float(-1), "rocketR", "flameR")] {
                let e = V3(sx * Self.elbowX, Self.elbowY, 0)
                put(Prim.tube([e, e + V3(0, -0.13, 0), e + V3(0, -0.26, 0)], radii: [0.06, 0.058, 0.052], sides: hi ? 32 : 10, seamTile: 0.05, material: paint, capEnd: true), name)
                for k in 0..<(hi ? 3 : 2) { ring(name, e + V3(0, -0.05 - 0.06 * Float(k), 0), major: 0.058, minor: 0.005, dark) }
                put(Prim.superellipsoid(V3(0.12, 0.1, 0.12), exponent: 2.4, subdivisions: hi ? 6 : 3, material: paint), name, Xform(translation: e))
                put(Prim.lathe([V2(0.04, 0), V2(0.05, 0.03), V2(0.06, 0.07), V2(0.056, 0.09)], segments: sides, seamTile: 0.05, material: nozzle), name, Xform(translation: e + V3(0, 0.04, 0)))
                ring(name, e + V3(0, 0.13, 0), major: 0.056, minor: 0.008, dark)
                put(Prim.superellipsoid(V3(0.1, 0.1, 0.1), exponent: 2, subdivisions: hi ? 6 : 3, material: steel), name, Xform(translation: e + V3(0, -0.28, 0)))
                put(Prim.lathe([V2(0.05, 0), V2(0.035, 0.1), V2(0.015, 0.22), V2(0.001, 0.3)], segments: hi ? 32 : 10, seamTile: 0.1, material: flameLit), flame, option: 1, Xform(translation: V3(0, 0.0, 0)))
            }
        }

        rig.states = [
            RigState("rest", [:]),
            RigState("reactor", ["reactor": 1], options: ["reactorLit": 1, "reactorLitChest": 1]),
            RigState("thrust", ["reactor": 1, "thrustL": 1, "thrustR": 1], options: ["reactorLit": 1, "reactorLitChest": 1, "flameL": 1, "flameR": 1]),
            RigState("punchL", ["reactor": 1, "thrustL": 1], options: ["reactorLit": 1, "reactorLitChest": 1, "flameL": 1]),
        ]
        return rig
    }
}
