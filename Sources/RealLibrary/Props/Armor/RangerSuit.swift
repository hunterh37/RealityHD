import simd
import Foundation

/// Color-ranger bodysuit kit, life size for a 1.75 m wearer: glossy red armored suit with a visor helmet (crest fin, chin guard),
/// torso with white V stripes and a diamond emblem, belt with a chrome buckle, upper arms with shoulder caps, white-gloved
/// forearms, and legs with knee guards and white boots. Original shapes only: no logos, no film marks.
/// Origin at the neck base, face toward +Z, up +Y, wearer's left = +X.
///
/// Kit parts (pivots in asset space): `helmet` (0, 0.12, 0), `chest` (0, -0.18, 0), `belt` (0, -0.62, 0),
/// `upperL` / `upperR` (+-0.20, -0.05, 0), `foreL` / `foreR` (+-0.215, -0.31, 0), `legL` / `legR` (+-0.10, -0.62, 0). Limbs hang along -Y.
///
/// Joints (set with `setJoints`): `visor` (0...1) and `buckle` (0...1) are drivers. Followers `visorLit` and `buckleLit` switch
/// with the matching joint at 0.05. 2 LODs.
public struct RangerSuit: RealArticulated {
    public static let id = "ranger-suit"
    public static let summary = "Glossy color-ranger bodysuit: visor helmet, striped torso, chrome buckle belt, white gloves and boots."
    public static let tags = ["prop", "armor", "articulated", "glowing"]
    public static let budget = 24_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 6, distance: 2.6)

    /// Glossy suit paint.
    public var suit: MaterialKey = "paint.measure-red"
    /// Gloves, boots, stripes, emblem.
    public var trim: MaterialKey = "plastic.white"
    /// Belt strap, soles, undersuit joints.
    public var dark: MaterialKey = "plastic.black"
    /// Buckle housing.
    public var chrome: MaterialKey = "metal.chrome"
    /// Visor glass.
    public var glass: MaterialKey = "glass.tinted"
    /// Lit visor and buckle.
    public var lit: MaterialKey = "emissive.warm"
    public init() {}

    static let elbowX: Float = 0.215
    static let elbowY: Float = -0.31
    static let shoulderX: Float = 0.20
    static let hipX: Float = 0.10
    static let hipY: Float = -0.62

    // MARK: Rig

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [4])
        let X = V3(1, 0, 0), Y = V3(0, 1, 0), Z = V3(0, 0, 1)

        for name in ["visor", "buckle"] {
            _ = rig.part(name, pivot: .zero, joint: .hinge(axis: Y, 0...1, duration: 0.4))
        }
        let pivots: [(String, V3)] = [
            ("helmet", V3(0, 0.12, 0)), ("chest", V3(0, -0.18, 0)), ("belt", V3(0, Self.hipY, 0)),
            ("upperL", V3(Self.shoulderX, -0.05, 0)), ("upperR", V3(-Self.shoulderX, -0.05, 0)),
            ("foreL", V3(Self.elbowX, Self.elbowY, 0)), ("foreR", V3(-Self.elbowX, Self.elbowY, 0)),
            ("legL", V3(Self.hipX, Self.hipY, 0)), ("legR", V3(-Self.hipX, Self.hipY, 0)),
        ]
        for (name, p) in pivots { _ = rig.part(name, pivot: p, joint: .fixed) }
        _ = rig.part("visorLit", parent: "helmet", pivot: V3(0, 0.12, 0.1), joint: .fixed, options: 2)
        _ = rig.part("buckleLit", parent: "belt", pivot: V3(0, Self.hipY, 0.15), joint: .fixed, options: 2)
        rig.optionLinks = [
            RigOptionLink(part: "visorLit", joint: "visor", thresholds: [0.05]),
            RigOptionLink(part: "buckleLit", joint: "buckle", thresholds: [0.05]),
        ]

        for l in 0..<2 {
            let hi = l == 0
            let sides = hi ? 48 : 16
            func put(_ s: Surface, _ part: String, option: Int = 0, _ x: Xform = .identity) {
                rig.add(s, x, to: part, option: option, lods: l...l)
            }
            func ring(_ part: String, _ at: V3, major: Float, minor: Float, _ mat: MaterialKey, tilt: simd_quatf = simd_quatf(angle: 0, axis: V3(0, 1, 0)), scale: V3 = V3(1, 1, 1)) {
                put(Prim.torus(major: major, minor: minor, segments: hi ? 48 : 16, sides: hi ? 12 : 6, material: mat), part,
                    Xform(translation: at, rotation: tilt, scale: scale))
            }
            func limb(_ part: String, _ pts: [V3], _ radii: [Float], _ mat: MaterialKey) {
                put(Prim.tube(pts, radii: radii, sides: hi ? 40 : 12, seamTile: 0.05, material: mat, capEnd: true), part)
            }
            func ellipsoid(_ part: String, _ at: V3, _ r: V3, exponent: Float = 2.2, _ mat: MaterialKey, subdiv: Int = 6) {
                put(Prim.superellipsoid(r, exponent: exponent, subdivisions: hi ? subdiv : 3, material: mat), part, Xform(translation: at))
            }

            // MARK: Helmet: shell, visor, chin guard, crest fin
            do {
                ellipsoid("helmet", V3(0, 0.12, -0.005), V3(0.125, 0.145, 0.14), exponent: 2.1, suit, subdiv: 7)
                ellipsoid("helmet", V3(0, 0.115, 0.095), V3(0.098, 0.052, 0.05), exponent: 2.6, glass, subdiv: 6)
                put(Prim.superellipsoid(V3(0.092, 0.04, 0.05), exponent: 2.6, subdivisions: hi ? 5 : 3, material: lit), "visorLit", option: 1,
                    Xform(translation: V3(0, 0.0, 0.0)))
                put(Prim.superellipsoid(V3(0.092, 0.04, 0.05), exponent: 2.6, subdivisions: hi ? 5 : 3, material: dark), "visorLit", option: 0,
                    Xform(translation: V3(0, 0.0, 0.0)))
                ellipsoid("helmet", V3(0, 0.035, 0.085), V3(0.07, 0.04, 0.045), exponent: 2.4, trim, subdiv: 5)
                limb("helmet", [V3(0, 0.2, -0.1), V3(0, 0.29, -0.03), V3(0, 0.29, 0.07), V3(0, 0.22, 0.12)], [0.008, 0.012, 0.012, 0.008], trim)
                ring("helmet", V3(0, -0.015, 0), major: 0.082, minor: 0.016, dark)
            }

            // MARK: Torso: shell, V stripes, diamond emblem, collar
            do {
                ellipsoid("chest", V3(0, -0.14, 0), V3(0.2, 0.26, 0.12), exponent: 2.6, suit, subdiv: 7)
                for sx in [Float(-1), 1] {
                    limb("chest", [V3(sx * 0.13, 0.07, 0.085), V3(sx * 0.07, -0.08, 0.115), V3(sx * 0.02, -0.26, 0.108)], [0.012, 0.011, 0.01], trim)
                    ellipsoid("chest", V3(sx * 0.205, -0.02, 0), V3(0.05, 0.1, 0.1), exponent: 2.3, suit, subdiv: 5)
                }
                put(Prim.lathe([V2(0.0, 0), V2(0.036, 0.002), V2(0.04, 0.008), V2(0.001, 0.014)], segments: 4, seamTile: 0.04, material: trim), "chest",
                    Xform(translation: V3(0, -0.1, 0.124), rotation: simd_quatf(angle: .pi / 2, axis: X) * simd_quatf(angle: .pi / 4, axis: Y), scale: V3(1, 1, 1.5)))
                ring("chest", V3(0, 0.06, 0), major: 0.095, minor: 0.016, dark, scale: V3(1, 1, 0.8))
            }

            // MARK: Belt: strap, chrome buckle (lit option), hip plates
            do {
                ring("belt", V3(0, 0, 0), major: 0.185, minor: 0.03, dark, scale: V3(1, 1, 0.68))
                ellipsoid("belt", V3(0, 0, 0.14), V3(0.07, 0.055, 0.03), exponent: 3, chrome, subdiv: 5)
                put(Prim.superellipsoid(V3(0.046, 0.034, 0.012), exponent: 2.6, subdivisions: hi ? 5 : 3, material: lit), "buckleLit", option: 1, Xform(translation: V3(0, 0, 0.03)))
                put(Prim.superellipsoid(V3(0.046, 0.034, 0.012), exponent: 2.6, subdivisions: hi ? 5 : 3, material: trim), "buckleLit", option: 0, Xform(translation: V3(0, 0, 0.03)))
                for sx in [Float(-1), 1] { ellipsoid("belt", V3(sx * 0.16, -0.02, 0.07), V3(0.04, 0.06, 0.02), exponent: 3, suit, subdiv: 4) }
            }

            // MARK: Arms: upper arm with shoulder cap, forearm with white glove
            for (sx, up, fore) in [(Float(1), "upperL", "foreL"), (Float(-1), "upperR", "foreR")] {
                let sh = V3(sx * Self.shoulderX, -0.05, 0), el = V3(sx * Self.elbowX, Self.elbowY, 0)
                ellipsoid(up, sh + V3(sx * 0.03, 0.0, 0), V3(0.075, 0.06, 0.075), exponent: 2.2, suit, subdiv: 5)
                limb(up, [sh, (sh + el) * 0.5, el], [0.048, 0.046, 0.042], suit)
                ring(up, el + V3(0, 0.02, 0), major: 0.044, minor: 0.008, dark)
                limb(fore, [el, el + V3(0, -0.13, 0), el + V3(0, -0.24, 0)], [0.042, 0.04, 0.036], suit)
                put(Prim.lathe([V2(0.04, 0), V2(0.056, -0.014), V2(0.058, -0.06), V2(0.04, -0.075)], segments: sides, seamTile: 0.05, material: trim), fore,
                    Xform(translation: el + V3(0, -0.2, 0)))
                ellipsoid(fore, el + V3(0, -0.34, 0), V3(0.045, 0.06, 0.03), exponent: 2.3, trim, subdiv: 5)
                for f in 0..<4 {
                    let z = (Float(f) - 1.5) * 0.015
                    limb(fore, [el + V3(sx * 0.0, -0.38, z), el + V3(0, -0.43, z)], [0.008, 0.007], trim)
                }
            }

            // MARK: Legs: thigh, knee guard, shin, white boot
            for (sx, name) in [(Float(1), "legL"), (Float(-1), "legR")] {
                let hp = V3(sx * Self.hipX, Self.hipY, 0), kn = V3(sx * Self.hipX, -1.04, 0.01), an = V3(sx * Self.hipX, -1.38, 0)
                limb(name, [hp, (hp + kn) * 0.5, kn, (kn + an) * 0.5, an], [0.08, 0.072, 0.058, 0.05, 0.042], suit)
                ellipsoid(name, kn + V3(0, 0, 0.045), V3(0.055, 0.06, 0.035), exponent: 2.4, trim, subdiv: 5)
                put(Prim.lathe([V2(0.052, 0), V2(0.062, -0.03), V2(0.066, -0.07), V2(0.07, -0.1)], segments: sides, seamTile: 0.05, material: trim), name,
                    Xform(translation: an + V3(0, 0.05, 0)))
                ellipsoid(name, V3(sx * Self.hipX, -1.41, 0.04), V3(0.055, 0.04, 0.1), exponent: 2.3, trim, subdiv: 5)
                ellipsoid(name, V3(sx * Self.hipX, -1.445, 0.035), V3(0.058, 0.012, 0.108), exponent: 3, dark, subdiv: 4)
                ring(name, hp + V3(0, -0.02, 0), major: 0.075, minor: 0.01, dark)
            }
        }

        rig.states = [
            RigState("rest", [:]),
            RigState("visor", ["visor": 1], options: ["visorLit": 1]),
            RigState("morphed", ["visor": 1, "buckle": 1], options: ["visorLit": 1, "buckleLit": 1]),
        ]
        return rig
    }
}
