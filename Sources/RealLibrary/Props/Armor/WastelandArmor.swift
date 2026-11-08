import simd
import Foundation

/// Wasteland raider armor kit, life size for a 1.75 m wearer: a spiked scrap collar with a chrome mouth guard, a riveted corten
/// chest plate on black leather straps, a pelvis ring with hanging plates, spiked scrap shoulder plates, and two exhaust pipes
/// rising behind the shoulders with flame tongues inside. Original shapes only: no logos, no film marks.
/// Origin at the neck base, face toward +Z, up +Y, wearer's left = +X.
///
/// Kit parts (pivots in asset space): `collar` (0, 0.05, 0), `chest` (0, -0.18, 0.1), `pelvis` (0, -0.62, 0),
/// `shoulderL` / `shoulderR` (+-0.20, -0.05, 0), `pipeL` / `pipeR` (+-0.17, -0.1, -0.14) with the pipe rising along +Y to a tip
/// at (+-0.2, 0.5, -0.2).
///
/// Joints (set with `setJoints`): `belch` (0...1) lights the flame tongues, `spray` (0...1) wets the chrome mouth guard,
/// `rev` (0...1) is an empty driver for pipe rattle. Followers `flameL` / `flameR` switch with `belch` at 0.05, `sprayLit`
/// switches with `spray` at 0.05. 2 LODs.
public struct WastelandArmor: RealArticulated {
    public static let id = "wasteland-armor"
    public static let summary = "Wasteland raider armor: spiked collar with chrome mouth guard, scrap shoulder plates and two exhaust pipes that belch flame."
    public static let tags = ["prop", "metal", "articulated", "glowing"]
    public static let budget = 24_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 8, distance: 1.2)

    /// Scrap plates, rusted.
    public var scrap: MaterialKey = "metal.corten"
    /// Mouth guard, spikes, pipe collars.
    public var chrome: MaterialKey = "metal.chrome"
    /// Exhaust pipes and rivets.
    public var iron: MaterialKey = "metal.cast-iron-worn"
    /// Straps and hanging plates backing.
    public var leather: MaterialKey = "leather.black"
    /// Flame tongues inside the pipes.
    public var flame: MaterialKey = "emissive.flame"
    public init() {}

    static let shoulderX: Float = 0.20
    static let pipeX: Float = 0.17
    static let pipeTipX: Float = 0.2

    // MARK: Rig

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [3])
        let X = V3(1, 0, 0), Y = V3(0, 1, 0), Z = V3(0, 0, 1)

        for name in ["belch", "spray", "rev"] {
            _ = rig.part(name, pivot: .zero, joint: .hinge(axis: Y, 0...1, duration: 0.5))
        }
        let pivots: [(String, V3)] = [
            ("collar", V3(0, 0.05, 0)), ("chest", V3(0, -0.18, 0.1)), ("pelvis", V3(0, -0.62, 0)),
            ("shoulderL", V3(Self.shoulderX, -0.05, 0)), ("shoulderR", V3(-Self.shoulderX, -0.05, 0)),
            ("pipeL", V3(Self.pipeX, -0.1, -0.14)), ("pipeR", V3(-Self.pipeX, -0.1, -0.14)),
        ]
        for (name, p) in pivots { _ = rig.part(name, pivot: p, joint: .fixed) }
        _ = rig.part("sprayLit", parent: "collar", pivot: V3(0, 0.1, 0.11), joint: .fixed, options: 2)
        _ = rig.part("flameL", parent: "pipeL", pivot: V3(Self.pipeTipX, 0.5, -0.2), joint: .fixed, options: 2)
        _ = rig.part("flameR", parent: "pipeR", pivot: V3(-Self.pipeTipX, 0.5, -0.2), joint: .fixed, options: 2)
        rig.optionLinks = [
            RigOptionLink(part: "sprayLit", joint: "spray", thresholds: [0.05]),
            RigOptionLink(part: "flameL", joint: "belch", thresholds: [0.05]),
            RigOptionLink(part: "flameR", joint: "belch", thresholds: [0.05]),
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
            func rivet(_ part: String, _ at: V3, r: Float = 0.008, facing q: simd_quatf = simd_quatf(angle: .pi / 2, axis: X)) {
                put(Prim.lathe([V2(r, 0), V2(r * 0.96, 0.004), V2(r * 0.6, 0.008), V2(0.001, 0.009)], segments: hi ? 16 : 6, seamTile: 0.02, material: iron), part,
                    Xform(translation: at, rotation: q))
            }
            /// Cone spike pointing along +Y of its local frame, rotated by `q`.
            func spike(_ part: String, _ at: V3, length: Float, radius: Float, _ q: simd_quatf, _ mat: MaterialKey) {
                put(Prim.lathe([V2(radius, 0), V2(radius * 0.8, length * 0.3), V2(radius * 0.4, length * 0.7), V2(0.001, length)], segments: hi ? 24 : 8, seamTile: 0.04, material: mat), part,
                    Xform(translation: at, rotation: q))
            }

            // MARK: Collar: scrap ring with chrome spikes and a chrome mouth guard in front of the face
            do {
                ring("collar", V3(0, 0.02, 0), major: 0.15, minor: 0.03, scrap, scale: V3(1, 1, 0.9))
                ring("collar", V3(0, 0.0, 0), major: 0.152, minor: 0.012, leather, scale: V3(1, 1, 0.9))
                for k in 0..<(hi ? 10 : 5) {
                    let a = (Float(k) + 0.5) / Float(hi ? 10 : 5) * 2 * .pi
                    let n = V3(sin(a), 0, cos(a))
                    let q = simd_quatf(angle: .pi / 2.6, axis: V3(n.z, 0, -n.x))
                    spike("collar", V3(n.x * 0.15, 0.06, n.z * 0.135), length: 0.075, radius: 0.012, q, chrome)
                }
                // Mouth guard: chrome U band around the lower face with four vertical bars.
                let band = (0...8).map { i -> V3 in
                    let a = (Float(i) / 8 - 0.5) * 1.6
                    return V3(sin(a) * 0.1, 0.1, cos(a) * 0.11)
                }
                put(Prim.tube(band, radii: band.map { _ in 0.009 }, sides: sides, seamTile: 0.03, material: chrome, capEnd: true), "collar")
                for i in 1..<8 where i % 2 == 0 {
                    let a = (Float(i) / 8 - 0.5) * 1.6
                    let p = V3(sin(a) * 0.1, 0.1, cos(a) * 0.11)
                    put(Prim.tube([p + V3(0, -0.05, 0), p + V3(0, 0.05, 0)], radii: [0.006, 0.006], sides: hi ? 20 : 8, seamTile: 0.03, material: chrome, capEnd: true), "collar")
                }
                // Wet chrome beads on the guard when spraying (option 1), dry caps when not (option 0).
                for sx in [Float(-0.5), 0, 0.5] {
                    let bead = Prim.lathe([V2(0.012, 0), V2(0.014, 0.008), V2(0.008, 0.018), V2(0.001, 0.022)], segments: hi ? 24 : 8, seamTile: 0.03, material: chrome)
                    put(bead, "sprayLit", option: 1, Xform(translation: V3(sx * 0.07, -0.01, 0.0), rotation: simd_quatf(angle: .pi / 2, axis: X)))
                }
                put(Prim.lathe([V2(0.01, 0), V2(0.006, 0.008), V2(0.001, 0.01)], segments: hi ? 16 : 6, seamTile: 0.03, material: iron), "sprayLit", option: 0,
                    Xform(translation: V3(0, -0.01, 0), rotation: simd_quatf(angle: .pi / 2, axis: X)))
            }

            // MARK: Chest: corten plate over leather straps with a riveted border
            do {
                put(Prim.superellipsoid(V3(0.38, 0.46, 0.18), exponent: 3.4, subdivisions: hi ? 6 : 3, material: scrap), "chest", Xform(translation: V3(0, -0.12, -0.03)))
                put(Prim.superellipsoid(V3(0.22, 0.16, 0.06), exponent: 3, subdivisions: hi ? 5 : 3, material: iron), "chest", Xform(translation: V3(0, 0.0, 0.1)))
                for sx in [Float(-1), 1] {
                    put(Prim.tube([V3(sx * 0.12, 0.12, 0.08), V3(sx * 0.13, -0.1, 0.12), V3(sx * 0.11, -0.34, 0.08)], radii: [0.02, 0.02, 0.02], sides: sides, seamTile: 0.05, material: leather, capEnd: true), "chest")
                    for k in 0..<(hi ? 5 : 2) { rivet("chest", V3(sx * 0.17, 0.08 - 0.07 * Float(k), 0.115)) }
                }
                ring("chest", V3(0, -0.36, -0.03), major: 0.17, minor: 0.016, leather, scale: V3(1, 1, 0.72))
            }

            // MARK: Pelvis ring with hanging scrap plates
            do {
                ring("pelvis", V3(0, 0, 0), major: 0.2, minor: 0.024, scrap, scale: V3(1, 1, 0.72))
                ring("pelvis", V3(0, -0.05, 0), major: 0.19, minor: 0.012, leather, scale: V3(1, 1, 0.72))
                for sx in [Float(-1), 0, 1] {
                    put(Prim.superellipsoid(V3(0.1, 0.16, 0.025), exponent: 3.2, subdivisions: hi ? 5 : 3, material: scrap), "pelvis",
                        Xform(translation: V3(sx * 0.15, -0.14, sx == 0 ? 0.15 : 0.1), rotation: simd_quatf(angle: -sx * 0.2, axis: Y)))
                    rivet("pelvis", V3(sx * 0.15, -0.07, sx == 0 ? 0.178 : 0.128), r: 0.007)
                }
            }

            // MARK: Shoulders: layered scrap plates with spikes
            for (sx, name) in [(Float(1), "shoulderL"), (Float(-1), "shoulderR")] {
                let base = V3(sx * 0.235, -0.04, 0)
                let tilt = simd_quatf(angle: -sx * 0.35, axis: Z)
                put(Prim.lathe([V2(0.13, 0), V2(0.14, 0.012), V2(0.115, 0.05), V2(0.08, 0.075), V2(0.001, 0.09)], segments: sides, seamTile: 0.1, material: scrap), name,
                    Xform(translation: base, rotation: tilt, scale: V3(1, 1, 1.1)))
                ring(name, base + V3(0, -0.006, 0), major: 0.134, minor: 0.011, chrome, tilt: tilt, scale: V3(1, 1, 1.1))
                put(Prim.lathe([V2(0.1, 0), V2(0.108, 0.01), V2(0.09, 0.04), V2(0.001, 0.065)], segments: sides, seamTile: 0.1, material: iron), name,
                    Xform(translation: base + V3(sx * 0.03, 0.05, 0), rotation: tilt, scale: V3(1, 1, 1.1)))
                for k in 0..<3 {
                    let a = Float(k - 1) * 0.5
                    let q = simd_quatf(angle: -sx * (0.9 + a * 0.3), axis: Z) * simd_quatf(angle: a, axis: X)
                    spike(name, base + V3(sx * 0.05, 0.08, Float(k - 1) * 0.07), length: 0.12, radius: 0.016, q, chrome)
                }
                put(Prim.tube([V3(sx * 0.2, -0.05, 0), V3(sx * 0.208, -0.18, 0), V3(sx * 0.215, -0.31, 0)], radii: [0.05, 0.048, 0.046], sides: hi ? 32 : 10, seamTile: 0.05, material: leather, capEnd: true), name)
                for k in 0..<(hi ? 6 : 3) {
                    let a = Float(k) / 6 * 2 * .pi
                    rivet(name, base + V3(cos(a) * 0.115 * sx, 0.012, sin(a) * 0.12), r: 0.007, facing: simd_quatf(angle: 0, axis: Y))
                }
            }

            // MARK: Exhaust pipes: two bent iron tubes with chrome collars behind the shoulders, flame tongue at the tip
            for (sx, name, flameName) in [(Float(1), "pipeL", "flameL"), (Float(-1), "pipeR", "flameR")] {
                let path = [V3(sx * Self.pipeX, -0.1, -0.14), V3(sx * 0.17, 0.1, -0.16), V3(sx * 0.19, 0.34, -0.19), V3(sx * Self.pipeTipX, 0.5, -0.2)]
                put(Prim.tube(path, radii: [0.032, 0.03, 0.03, 0.036], sides: sides, seamTile: 0.05, material: iron, capEnd: true), name)
                for y in [Float(0.0), 0.2, 0.42] {
                    let t = (y + 0.1) / 0.6
                    ring(name, V3(sx * (0.17 + 0.03 * t), y, -0.15 - 0.05 * t), major: 0.034, minor: 0.008, chrome)
                }
                ring(name, V3(sx * Self.pipeTipX, 0.5, -0.2), major: 0.034, minor: 0.007, chrome)
                put(Prim.lathe([V2(0.03, 0), V2(0.036, 0.1), V2(0.02, 0.22), V2(0.008, 0.34), V2(0.001, 0.4)], segments: hi ? 24 : 8, seamTile: 0.1, material: flame), flameName, option: 1,
                    Xform(translation: V3(sx * Self.pipeTipX, 0.5, -0.2)))
                put(Prim.lathe([V2(0.028, 0), V2(0.02, 0.01), V2(0.001, 0.014)], segments: hi ? 24 : 8, seamTile: 0.1, material: leather), flameName, option: 0,
                    Xform(translation: V3(sx * Self.pipeTipX, 0.5, -0.2)))
            }
        }

        rig.states = [
            RigState("rest", [:]),
            RigState("spray", ["spray": 1], options: ["sprayLit": 1]),
            RigState("belch", ["belch": 1], options: ["flameL": 1, "flameR": 1]),
            RigState("rev", ["rev": 1, "belch": 1], options: ["flameL": 1, "flameR": 1]),
        ]
        return rig
    }
}
