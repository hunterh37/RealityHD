import simd
import Foundation

/// White EVA spacesuit kit, life size for a 1.75 m wearer: a bubble helmet with a stowable gold mirrored visor, a hard upper
/// torso with a chest control box, fabric arms with accordion hose rings, orange command stripes, steel wrist rings, gloves, a
/// life support pack with tanks, antenna and a status panel, and a hose looping from chest to pack. Original shapes only: no
/// agency marks, no patches. Origin at the neck base, face toward +Z, up +Y, wearer's left = +X.
///
/// Kit parts (pivots in asset space): `helmet` (0, 0, 0), `chest` (0, -0.18, 0.12), `back` (0, -0.20, -0.12),
/// `shoulderL` / `shoulderR` (+-0.20, -0.05, 0), `gauntletL` / `gauntletR` (+-0.215, -0.31, 0) with the forearm along -Y.
///
/// Joints (set with `setJoints`): `visor` (0...1) lowers the gold visor over the face, `pack` (0...1) lights the pack panel and
/// chest box, `pistol` (0...1) puts the sidearm in the right glove (muzzle along -Y), `earth` (0...1) is an empty driver for
/// the lens backdrop reveal. 0...1 joints are empty drivers; followers `visorDown`, `packLights`, `chestLights`, `sidearm`
/// switch between option 0 and option 1 when the joint passes 0.05. 2 LODs.
public struct EvaSpacesuit: RealArticulated {
    public static let id = "eva-spacesuit"
    public static let summary = "White EVA spacesuit kit: bubble helmet with stowable gold visor, hard torso with control box, hose-ringed arms, life support pack and a sidearm."
    public static let tags = ["prop", "fabric", "metal", "articulated", "glowing"]
    public static let budget = 20_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 8, distance: 1.0)

    /// Hard shell: helmet, torso, pack, shoulder bearings.
    public var shell: MaterialKey = "plastic.white"
    /// Soft goods: arms, gloves, hose covers (off-white canvas weave, tint at the lens for pure white).
    public var fabric: MaterialKey = "fabric.canvas"
    /// Mirrored visor.
    public var visorMat: MaterialKey = "insulation.foil-gold"
    /// Rings, ports, antenna and the sidearm.
    public var steel: MaterialKey = "metal.steel"
    /// Command stripes.
    public var stripe: MaterialKey = "plastic.orange"
    /// Dark rubber, vents and dead indicator lenses.
    public var dark: MaterialKey = "plastic.black"
    /// Lit pack indicators.
    public var lampGreen: MaterialKey = "emissive.signal-green"
    public var lampRed: MaterialKey = "emissive.signal-red"
    public init() {}

    static let elbowX: Float = 0.215
    static let elbowY: Float = -0.31
    static let shoulderX: Float = 0.20

    /// Bubble helmet profile (radius, y) from the neck rim up over the crown.
    func domeProfile(rx: Float, y0: Float, ry: Float, hi: Bool) -> [V2] {
        let n = hi ? 16 : 7
        var p: [V2] = [V2(rx * 0.72, y0 - 0.04), V2(rx * 0.96, y0)]
        for k in 1...n {
            let a = Float(k) / Float(n) * .pi / 2
            p.append(V2(max(0.001, rx * cos(a)), y0 + ry * sin(a)))
        }
        return p
    }

    // MARK: Rig

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [3])
        let X = V3(1, 0, 0), Y = V3(0, 1, 0), Z = V3(0, 0, 1)
        let flipX = simd_quatf(angle: .pi, axis: X)

        for name in ["visor", "pack", "pistol", "earth"] {
            _ = rig.part(name, pivot: .zero, joint: .hinge(axis: Y, 0...1, duration: 0.5))
        }
        let pivots: [(String, V3)] = [
            ("helmet", V3(0, 0, 0)), ("chest", V3(0, -0.18, 0.12)), ("back", V3(0, -0.20, -0.12)),
            ("shoulderL", V3(Self.shoulderX, -0.05, 0)), ("shoulderR", V3(-Self.shoulderX, -0.05, 0)),
            ("gauntletL", V3(Self.elbowX, Self.elbowY, 0)), ("gauntletR", V3(-Self.elbowX, Self.elbowY, 0)),
        ]
        for (name, p) in pivots { _ = rig.part(name, pivot: p, joint: .fixed) }
        _ = rig.part("visorDown", parent: "helmet", pivot: V3(0, 0.15, 0), joint: .fixed, options: 2)
        _ = rig.part("packLights", parent: "back", pivot: V3(0, -0.05, -0.28), joint: .fixed, options: 2)
        _ = rig.part("chestLights", parent: "chest", pivot: V3(0, -0.1, 0.16), joint: .fixed, options: 2)
        _ = rig.part("sidearm", parent: "gauntletR", pivot: V3(-Self.elbowX, Self.elbowY - 0.3, 0), joint: .fixed, options: 2)
        rig.optionLinks = [
            RigOptionLink(part: "visorDown", joint: "visor", thresholds: [0.05]),
            RigOptionLink(part: "packLights", joint: "pack", thresholds: [0.05]),
            RigOptionLink(part: "chestLights", joint: "pack", thresholds: [0.05]),
            RigOptionLink(part: "sidearm", joint: "pistol", thresholds: [0.05]),
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
            func lamp(_ part: String, _ at: V3, option: Int, _ mat: MaterialKey, r: Float = 0.009) {
                put(Prim.lathe([V2(r, 0), V2(r * 0.9, 0.004), V2(r * 0.5, 0.008), V2(0.001, 0.009)], segments: hi ? 16 : 6, seamTile: 0.02, material: mat), part,
                    option: option, Xform(translation: at, rotation: simd_quatf(angle: .pi / 2, axis: X)))
            }

            // MARK: Helmet: neck ring, bubble shell, visor (stowed or lowered), lamps, antenna
            do {
                ring("helmet", V3(0, 0.0, 0), major: 0.11, minor: 0.016, steel)
                put(Prim.lathe(domeProfile(rx: 0.145, y0: 0.03, ry: 0.255, hi: hi), segments: sides, seamTile: 0.1, material: shell), "helmet",
                    Xform(translation: V3(0, 0, 0.012), scale: V3(1, 1, 1.06)))
                ring("helmet", V3(0, 0.035, 0.012), major: 0.148, minor: 0.008, steel, scale: V3(1, 1, 1.06))
                // Gold visor: bubble just outside the shell. Stowed (option 0) it rests tipped up on the crown, lowered (option 1) it covers the face.
                let vis = Prim.lathe(domeProfile(rx: 0.158, y0: 0.07, ry: 0.225, hi: hi), segments: sides, seamTile: 0.1, material: visorMat)
                put(vis, "visorDown", option: 1, Xform(translation: V3(0, -0.002, 0.026), scale: V3(1, 1, 1.07)))
                put(vis, "visorDown", option: 0, Xform(translation: V3(0, 0.07, -0.085), rotation: simd_quatf(angle: -rad(62), axis: X), scale: V3(0.98, 1, 1.07)))
                ring("helmet", V3(0, 0.1, 0.012), major: 0.153, minor: 0.006, steel, scale: V3(1, 1, 1.06))
                // Side lamps and a top camera.
                for sx in [Float(-1), 1] {
                    put(Prim.superellipsoid(V3(0.04, 0.034, 0.05), exponent: 2.8, subdivisions: hi ? 5 : 3, material: shell), "helmet", Xform(translation: V3(sx * 0.155, 0.17, 0.05)))
                    lamp("helmet", V3(sx * 0.158, 0.17, 0.092), option: 0, steel, r: 0.015)
                }
                put(Prim.superellipsoid(V3(0.05, 0.03, 0.06), exponent: 2.6, subdivisions: hi ? 5 : 3, material: dark), "helmet", Xform(translation: V3(0, 0.285, 0.03)))
                put(Prim.tube([V3(-0.09, 0.2, -0.12), V3(-0.12, 0.3, -0.13), V3(-0.13, 0.42, -0.12)], radii: [0.005, 0.004, 0.003], sides: hi ? 12 : 5, seamTile: 0.02, material: steel, capEnd: true), "helmet")
            }

            // MARK: Chest: hard torso, control box, hose ports, waist ring
            do {
                put(Prim.superellipsoid(V3(0.42, 0.62, 0.27), exponent: 2.4, subdivisions: hi ? 6 : 3, material: shell), "chest", Xform(translation: V3(0, -0.2, 0)))
                put(Prim.superellipsoid(V3(0.2, 0.12, 0.06), exponent: 3, subdivisions: hi ? 5 : 3, material: steel), "chest", Xform(translation: V3(0, -0.1, 0.15)))
                for k in 0..<3 {
                    lamp("chestLights", V3(-0.05 + 0.05 * Float(k), -0.1, 0.18), option: 0, dark)
                    lamp("chestLights", V3(-0.05 + 0.05 * Float(k), -0.1, 0.18), option: 1, k == 1 ? lampRed : lampGreen)
                }
                for sx in [Float(-1), 1] {
                    put(Prim.lathe([V2(0.032, 0), V2(0.034, 0.012), V2(0.028, 0.03), V2(0.02, 0.034)], segments: hi ? 32 : 10, seamTile: 0.03, material: steel), "chest",
                        Xform(translation: V3(sx * 0.12, -0.2, 0.14), rotation: simd_quatf(angle: .pi / 2, axis: X)))
                }
                ring("chest", V3(0, -0.5, 0), major: 0.19, minor: 0.018, steel, scale: V3(1, 1, 0.68))
                // Fabric yoke around the neck.
                put(Prim.lathe([V2(0.1, 0.04), V2(0.14, 0.02), V2(0.185, -0.04), V2(0.2, -0.1)], segments: sides, seamTile: 0.1, material: fabric), "chest", Xform(translation: V3(0, 0.14, -0.04)))
                // Umbilical hose from the chest port to the pack.
                let n = hi ? 12 : 5
                let hose = (0..<n).map { i -> V3 in
                    let u = Float(i) / Float(n - 1)
                    return V3(0.12 + 0.16 * sin(u * .pi), -0.2 + 0.06 * u - 0.1 * sin(u * .pi), 0.14 - 0.34 * u + 0.05 * sin(u * .pi))
                }
                put(Prim.tube(hose, radii: hose.map { _ in 0.014 }, sides: hi ? 16 : 6, seamTile: 0.03, material: dark, capEnd: true), "chest")
            }

            // MARK: Life support pack
            do {
                put(Prim.superellipsoid(V3(0.38, 0.52, 0.2), exponent: 3, subdivisions: hi ? 6 : 3, material: shell), "back", Xform(translation: V3(0, -0.2, -0.12)))
                put(Prim.superellipsoid(V3(0.3, 0.16, 0.05), exponent: 3, subdivisions: hi ? 5 : 3, material: steel), "back", Xform(translation: V3(0, -0.02, -0.235)))
                for sx in [Float(-1), 1] {
                    put(Prim.lathe([V2(0.001, 0), V2(0.05, 0.01), V2(0.058, 0.07), V2(0.058, 0.25), V2(0.04, 0.3), V2(0.001, 0.31)], segments: sides, seamTile: 0.1, material: steel), "back",
                        Xform(translation: V3(sx * 0.085, -0.46, -0.25), rotation: simd_quatf(angle: 0, axis: Y)))
                    put(Prim.torus(major: 0.058, minor: 0.006, segments: hi ? 48 : 16, sides: hi ? 10 : 5, material: dark), "back", Xform(translation: V3(sx * 0.085, -0.34, -0.25)))
                }
                put(Prim.tube([V3(0.14, -0.04, -0.2), V3(0.2, 0.08, -0.22), V3(0.2, 0.2, -0.2)], radii: [0.004, 0.004, 0.003], sides: hi ? 12 : 5, seamTile: 0.02, material: steel, capEnd: true), "back")
                for k in 0..<4 {
                    lamp("packLights", V3(-0.09 + 0.06 * Float(k), -0.04, -0.015), option: 0, dark, r: 0.008)
                    lamp("packLights", V3(-0.09 + 0.06 * Float(k), -0.04, -0.015), option: 1, k % 2 == 0 ? lampGreen : lampRed, r: 0.008)
                }
            }

            // MARK: Shoulders and arms: bearing dome, fabric upper arm with hose rings
            for (sx, name) in [(Float(1), "shoulderL"), (Float(-1), "shoulderR")] {
                let base = V3(sx * 0.235, -0.07, 0)
                put(Prim.lathe([V2(0.1, 0), V2(0.108, 0.012), V2(0.1, 0.04), V2(0.075, 0.062), V2(0.04, 0.075), V2(0.001, 0.08)], segments: sides, seamTile: 0.1, material: shell), name,
                    Xform(translation: base, rotation: simd_quatf(angle: -sx * 0.3, axis: Z), scale: V3(1, 1, 1.1)))
                ring(name, base + V3(0, 0.004, 0), major: 0.103, minor: 0.008, steel, tilt: simd_quatf(angle: -sx * 0.3, axis: Z), scale: V3(1, 1, 1.1))
                let upper = [V3(sx * 0.2, -0.05, 0), V3(sx * 0.208, -0.18, 0), V3(sx * Self.elbowX, Self.elbowY, 0)]
                put(Prim.tube(upper, radii: [0.058, 0.055, 0.05], sides: hi ? 32 : 10, seamTile: 0.05, material: fabric, capEnd: true), name)
                for k in 0..<(hi ? 5 : 3) {
                    let y = -0.1 - 0.04 * Float(k)
                    ring(name, V3(sx * (0.205 + 0.002 * Float(k)), y, 0), major: 0.056 - 0.001 * Float(k), minor: 0.006, fabric)
                }
            }

            // MARK: Forearms: fabric, accordion rings, command stripe, wrist ring, glove
            for (sx, name) in [(Float(1), "gauntletL"), (Float(-1), "gauntletR")] {
                let e = V3(sx * Self.elbowX, Self.elbowY, 0)
                put(Prim.tube([e, e + V3(0, -0.12, 0), e + V3(0, -0.23, 0)], radii: [0.05, 0.047, 0.04], sides: hi ? 32 : 10, seamTile: 0.05, material: fabric, capEnd: true), name)
                for k in 0..<(hi ? 5 : 2) {
                    ring(name, e + V3(0, -0.03 - 0.032 * Float(k), 0), major: 0.05 - 0.002 * Float(k), minor: 0.005, fabric)
                }
                ring(name, e + V3(0, -0.19, 0), major: 0.044, minor: 0.007, stripe)
                // Wrist disconnect ring and glove cuff.
                put(Prim.lathe([V2(0.052, 0), V2(0.058, 0.01), V2(0.058, 0.03), V2(0.05, 0.04), V2(0.046, 0.045)], segments: sides, seamTile: 0.08, material: steel), name,
                    Xform(translation: e + V3(0, -0.225, 0), rotation: flipX))
                put(Prim.superellipsoid(V3(0.09, 0.115, 0.07), exponent: 2.4, subdivisions: hi ? 6 : 3, material: fabric), name, Xform(translation: e + V3(0, -0.335, 0.004)))
                for f in 0..<4 {
                    let x = (Float(f) - 1.5) * 0.02
                    put(Prim.tube([e + V3(x, -0.38, 0.015), e + V3(x, -0.42, 0.028), e + V3(x, -0.447, 0.025)], radii: [0.0095, 0.009, 0.0075], sides: hi ? 12 : 5, seamTile: 0.02, material: fabric, capEnd: true), name)
                }
            }

            // MARK: Sidearm: pouch on the right forearm (option 0), pistol in the glove (option 1, muzzle along -Y)
            do {
                let e = V3(-Self.elbowX, Self.elbowY, 0)
                put(Prim.superellipsoid(V3(0.05, 0.075, 0.03), exponent: 3, subdivisions: hi ? 5 : 3, material: dark), "sidearm", option: 0, Xform(translation: e + V3(-0.01, -0.13, 0.055)))
                let g = e + V3(0, -0.4, 0.04)
                put(Prim.superellipsoid(V3(0.032, 0.14, 0.04), exponent: 3, subdivisions: hi ? 6 : 3, material: steel), "sidearm", option: 1, Xform(translation: g + V3(0, -0.04, 0.012)))
                put(Prim.tube([g + V3(0, -0.08, 0.012), g + V3(0, -0.16, 0.012)], radii: [0.011, 0.01], sides: hi ? 32 : 8, seamTile: 0.03, material: steel, capEnd: true), "sidearm", option: 1)
                put(Prim.superellipsoid(V3(0.028, 0.06, 0.1), exponent: 3, subdivisions: hi ? 5 : 3, material: dark), "sidearm", option: 1, Xform(translation: g + V3(0, 0.0, -0.045), rotation: simd_quatf(angle: rad(14), axis: X)))
                put(Prim.torus(major: 0.022, minor: 0.003, segments: hi ? 32 : 12, sides: hi ? 8 : 4, material: steel), "sidearm", option: 1,
                    Xform(translation: g + V3(0, 0.0, -0.01), rotation: simd_quatf(angle: .pi / 2, axis: Y)))
            }
        }

        rig.states = [
            RigState("rest", [:]),
            RigState("visor", ["visor": 1], options: ["visorDown": 1]),
            RigState("pack", ["visor": 1, "pack": 1], options: ["visorDown": 1, "packLights": 1, "chestLights": 1]),
            RigState("pistol", ["visor": 1, "pack": 1, "pistol": 1], options: ["visorDown": 1, "packLights": 1, "chestLights": 1, "sidearm": 1]),
            RigState("earth", ["visor": 1, "pack": 1, "earth": 1], options: ["visorDown": 1, "packLights": 1, "chestLights": 1]),
        ]
        return rig
    }

    func rad(_ d: Float) -> Float { d * .pi / 180 }
}
