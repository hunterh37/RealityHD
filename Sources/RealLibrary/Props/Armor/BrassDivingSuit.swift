import simd
import Foundation

/// Brass deep-sea diving suit kit, life size for a 1.75 m wearer: a riveted brass helmet with a front porthole, two side portholes
/// and a guard grille, a bolted breastplate collar, a canvas dress with lead weights on a belt, an air hose and pump manifold on
/// the back, brass cuff clamps and rubber mitts, and a forearm drill on the right arm. Original shapes only, no maker marks.
/// Origin at the neck base, face toward +Z, up +Y, wearer's left = +X.
///
/// Kit parts (pivots in asset space): `helmet` (0, 0, 0), `chest` (0, -0.18, 0.12), `back` (0, -0.20, -0.12),
/// `shoulderL` / `shoulderR` (+-0.20, -0.05, 0), `gauntletL` / `gauntletR` (+-0.215, -0.31, 0) with the forearm along -Y.
///
/// Joints (set with `setJoints`, 0...1 empty drivers): `lamp` lights the crown lamp lens, `bubbles` opens the exhaust valve,
/// `drill` extends the forearm drill bit (the lens spins it), `rust` swaps in verdigris patina bands. Followers `lampOn`, `valveOpen`,
/// `drillOut` and `patina` switch between option 0 and option 1 when their joint passes the threshold (0.05, 0.05, 0.05, 0.5). 2 LODs.
public struct BrassDivingSuit: RealArticulated {
    public static let id = "brass-diving-suit"
    public static let summary = "Brass diving suit kit: riveted helmet with portholes and crown lamp, bolted collar, canvas dress, weight belt, air hose and a forearm drill."
    public static let tags = ["prop", "metal", "fabric", "articulated", "glowing"]
    public static let budget = 20_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 8, distance: 1.0)

    /// Polished helmet and collar.
    public var brass: MaterialKey = "metal.brass"
    /// Worn brass: clamps, bolts, valve, bezels.
    public var brassWorn: MaterialKey = "metal.brass-aged"
    /// Patina bands.
    public var patinaMat: MaterialKey = "metal.copper-patina"
    /// Air hose manifold coils.
    public var copper: MaterialKey = "metal.copper"
    /// Canvas dress.
    public var canvas: MaterialKey = "fabric.canvas"
    /// Weights, drill and guard bars.
    public var iron: MaterialKey = "metal.iron"
    /// Porthole glass.
    public var glass: MaterialKey = "glass.clear"
    /// Dead lamp lens and lit lamp lens.
    public var lampOff: MaterialKey = "glass.lamp"
    public var lampOn: MaterialKey = "emissive.warm"
    /// Hose, mitts and belt.
    public var rubber: MaterialKey = "rubber.insulating-black"
    public init() {}

    static let elbowX: Float = 0.215
    static let elbowY: Float = -0.31
    static let shoulderX: Float = 0.20

    /// Round helmet profile (radius, y) from the neck rim up over the crown.
    func domeProfile(rx: Float, y0: Float, ry: Float, hi: Bool) -> [V2] {
        let n = hi ? 24 : 8
        var p: [V2] = [V2(rx * 0.8, y0 - 0.03), V2(rx * 0.98, y0)]
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
        let faceZ = simd_quatf(angle: .pi / 2, axis: X)

        for name in ["lamp", "bubbles", "drill", "rust"] {
            _ = rig.part(name, pivot: .zero, joint: .hinge(axis: Y, 0...1, duration: 0.5))
        }
        let pivots: [(String, V3)] = [
            ("helmet", V3(0, 0, 0)), ("chest", V3(0, -0.18, 0.12)), ("back", V3(0, -0.20, -0.12)),
            ("shoulderL", V3(Self.shoulderX, -0.05, 0)), ("shoulderR", V3(-Self.shoulderX, -0.05, 0)),
            ("gauntletL", V3(Self.elbowX, Self.elbowY, 0)), ("gauntletR", V3(-Self.elbowX, Self.elbowY, 0)),
        ]
        for (name, p) in pivots { _ = rig.part(name, pivot: p, joint: .fixed) }
        _ = rig.part("lampOn", parent: "helmet", pivot: V3(0, 0.44, 0.1), joint: .fixed, options: 2)
        _ = rig.part("valveOpen", parent: "helmet", pivot: V3(0.2, 0.2, -0.1), joint: .fixed, options: 2)
        _ = rig.part("drillOut", parent: "gauntletR", pivot: V3(-Self.elbowX, Self.elbowY - 0.3, 0), joint: .fixed, options: 2)
        _ = rig.part("patina", parent: "helmet", pivot: V3(0, 0.1, 0), joint: .fixed, options: 2)
        rig.optionLinks = [
            RigOptionLink(part: "lampOn", joint: "lamp", thresholds: [0.05]),
            RigOptionLink(part: "valveOpen", joint: "bubbles", thresholds: [0.05]),
            RigOptionLink(part: "drillOut", joint: "drill", thresholds: [0.05]),
            RigOptionLink(part: "patina", joint: "rust", thresholds: [0.5]),
        ]

        for l in 0..<2 {
            let hi = l == 0
            let sides = hi ? 48 : 16
            func put(_ s: Surface, _ part: String, option: Int = 0, _ x: Xform = .identity) {
                rig.add(s, x, to: part, option: option, lods: l...l)
            }
            func ring(_ part: String, _ at: V3, major: Float, minor: Float, _ mat: MaterialKey, tilt: simd_quatf = simd_quatf(angle: 0, axis: V3(0, 1, 0)), scale: V3 = V3(1, 1, 1), option: Int = 0) {
                put(Prim.torus(major: major, minor: minor, segments: hi ? 48 : 16, sides: hi ? 12 : 6, material: mat), part, option: option,
                    Xform(translation: at, rotation: tilt, scale: scale))
            }
            /// Domed bolt or rivet head, axis +Y before the rotation.
            func bolt(_ part: String, _ at: V3, r: Float, rot: simd_quatf, _ mat: MaterialKey) {
                put(Prim.lathe([V2(r, 0), V2(r * 0.95, r * 0.35), V2(r * 0.6, r * 0.7), V2(0.001, r * 0.85)], segments: hi ? 12 : 5, seamTile: 0.01, material: mat), part,
                    Xform(translation: at, rotation: rot))
            }
            /// Porthole: bezel torus, inset glass dome and four guard bars, facing +Y before the rotation.
            func porthole(_ part: String, _ at: V3, r: Float, rot: simd_quatf) {
                put(Prim.torus(major: r, minor: r * 0.2, segments: hi ? 48 : 16, sides: hi ? 12 : 6, material: brassWorn), part, Xform(translation: at, rotation: rot))
                put(Prim.lathe([V2(r, 0), V2(r * 0.94, r * 0.12), V2(r * 0.6, r * 0.3), V2(0.001, r * 0.36)], segments: hi ? 48 : 16, seamTile: 0.05, material: glass), part,
                    Xform(translation: at + rot.act(V3(0, -r * 0.1, 0)), rotation: rot))
                if hi {
                    for k in 0..<4 {
                        let a = Float(k) * .pi / 4
                        let d = rot.act(V3(cos(a), 0, sin(a)))
                        put(Prim.tube([at + rot.act(V3(0, r * 0.4, 0)) + d * r * 0.95, at + rot.act(V3(0, r * 0.4, 0)) - d * r * 0.95], radii: [r * 0.05, r * 0.05], sides: 12, seamTile: 0.02, material: iron, capEnd: true), part)
                    }
                }
            }

            // MARK: Helmet: round shell, front and side portholes, rim, rivets, crown lamp, exhaust valve
            do {
                put(Prim.lathe(domeProfile(rx: 0.205, y0: 0.03, ry: 0.27, hi: hi), segments: sides, seamTile: 0.1, material: brass), "helmet",
                    Xform(translation: V3(0, 0, 0.005)))
                ring("helmet", V3(0, 0.032, 0.005), major: 0.208, minor: 0.012, brassWorn)
                ring("helmet", V3(0, 0.12, 0.005), major: 0.2, minor: 0.006, brassWorn)
                porthole("helmet", V3(0, 0.2, 0.2), r: 0.075, rot: faceZ)
                for sx in [Float(-1), 1] {
                    porthole("helmet", V3(sx * 0.2, 0.2, 0.02), r: 0.045, rot: simd_quatf(angle: -sx * .pi / 2, axis: Z))
                }
                porthole("helmet", V3(0, 0.34, 0.12), r: 0.04, rot: simd_quatf(angle: .pi / 4, axis: X))
                // Rim rivets around the front porthole and the neck ring.
                for k in 0..<(hi ? 16 : 6) {
                    let a = Float(k) / Float(hi ? 16 : 6) * 2 * .pi
                    let d = V3(cos(a), sin(a), 0)
                    bolt("helmet", V3(0, 0.2, 0.2) + d * 0.1 + V3(0, 0, 0.012), r: 0.007, rot: faceZ, brassWorn)
                    bolt("helmet", V3(0.208 * cos(a), 0.044, 0.208 * sin(a)), r: 0.008, rot: simd_quatf(angle: 0, axis: Y), brassWorn)
                }
                // Crown lamp: housing, dead lens (option 0) and lit lens (option 1).
                put(Prim.lathe([V2(0.04, 0), V2(0.045, 0.02), V2(0.04, 0.05), V2(0.03, 0.06)], segments: sides, seamTile: 0.05, material: brassWorn), "helmet",
                    Xform(translation: V3(0, 0.43, 0.06), rotation: simd_quatf(angle: .pi / 3, axis: X)))
                for o in 0..<2 {
                    put(Prim.lathe([V2(0.03, 0), V2(0.026, 0.01), V2(0.012, 0.016), V2(0.001, 0.018)], segments: hi ? 24 : 8, seamTile: 0.02, material: o == 0 ? lampOff : lampOn), "lampOn",
                        option: o, Xform(translation: V3(0, 0.46, 0.125), rotation: simd_quatf(angle: .pi / 3, axis: X)))
                }
                // Exhaust valve on the right of the helmet: closed cap (option 0), open stem with lifted lever (option 1).
                let vp = V3(0.2, 0.2, -0.1)
                let vrot = simd_quatf(angle: -.pi / 2, axis: Z)
                put(Prim.lathe([V2(0.024, 0), V2(0.026, 0.012), V2(0.02, 0.026), V2(0.001, 0.03)], segments: hi ? 32 : 10, seamTile: 0.03, material: brassWorn), "valveOpen",
                    option: 0, Xform(translation: vp, rotation: vrot))
                put(Prim.lathe([V2(0.024, 0), V2(0.026, 0.012), V2(0.012, 0.03), V2(0.01, 0.05)], segments: hi ? 32 : 10, seamTile: 0.03, material: brassWorn), "valveOpen",
                    option: 1, Xform(translation: vp, rotation: vrot))
                put(Prim.tube([vp + V3(0.05, 0, 0), vp + V3(0.07, 0.03, 0), vp + V3(0.07, 0.06, 0)], radii: [0.005, 0.005, 0.005], sides: hi ? 12 : 5, seamTile: 0.02, material: brassWorn, capEnd: true), "valveOpen", option: 1)
                // Patina bands (option 1): verdigris collars at the seams.
                ring("patina", V3(0, 0.032, 0.005), major: 0.21, minor: 0.014, patinaMat, option: 1)
                ring("patina", V3(0, 0.12, 0.005), major: 0.201, minor: 0.008, patinaMat, option: 1)
                put(Prim.lathe([V2(0.205, 0), V2(0.205, 0.05), V2(0.19, 0.11), V2(0.16, 0.16)], segments: sides, seamTile: 0.1, material: patinaMat), "patina",
                    option: 1, Xform(translation: V3(0, 0.2, 0.005), scale: V3(1.004, 1, 1.004)))
            }

            // MARK: Chest: bolted breastplate collar, canvas dress, weight belt, weights, hose ports
            do {
                put(Prim.lathe([V2(0.12, 0.05), V2(0.17, 0.04), V2(0.24, -0.02), V2(0.3, -0.1), V2(0.31, -0.15)], segments: sides, seamTile: 0.1, material: brass), "chest",
                    Xform(translation: V3(0, 0.1, 0), scale: V3(1, 1, 0.82)))
                ring("chest", V3(0, -0.05, 0), major: 0.31, minor: 0.012, brassWorn, scale: V3(1, 1, 0.82))
                for k in 0..<(hi ? 20 : 8) {
                    let a = Float(k) / Float(hi ? 20 : 8) * 2 * .pi
                    bolt("chest", V3(0.3 * cos(a), -0.05, 0.3 * sin(a) * 0.82 + 0.0), r: 0.009, rot: simd_quatf(angle: 0, axis: Y), brassWorn)
                }
                put(Prim.superellipsoid(V3(0.4, 0.58, 0.26), exponent: 2.4, subdivisions: hi ? 6 : 3, material: canvas), "chest", Xform(translation: V3(0, -0.28, 0)))
                // Weight belt with front and back lead weights.
                ring("chest", V3(0, -0.58, 0), major: 0.2, minor: 0.018, rubber, scale: V3(1, 1, 0.7))
                for z in [Float(1), -1] {
                    put(Prim.superellipsoid(V3(0.1, 0.17, 0.05), exponent: 3.2, subdivisions: hi ? 5 : 3, material: iron), "chest", Xform(translation: V3(0, -0.66, z * 0.15)))
                }
                // Air hose port: brass elbow on the left of the breastplate.
                put(Prim.lathe([V2(0.034, 0), V2(0.038, 0.014), V2(0.03, 0.04), V2(0.02, 0.046)], segments: hi ? 32 : 10, seamTile: 0.03, material: brassWorn), "chest",
                    Xform(translation: V3(0.18, -0.02, 0.1), rotation: simd_quatf(angle: .pi / 2, axis: X)))
                // Speaking-tube hose from the port up and over to the helmet.
                let n = hi ? 12 : 5
                let hose = (0..<n).map { i -> V3 in
                    let u = Float(i) / Float(n - 1)
                    return V3(0.18 + 0.05 * sin(u * .pi), -0.02 + 0.34 * u, 0.12 - 0.2 * u)
                }
                put(Prim.tube(hose, radii: hose.map { _ in 0.016 }, sides: hi ? 24 : 8, seamTile: 0.03, material: rubber, capEnd: true), "chest")
            }

            // MARK: Back: pump manifold, copper coil, hose to the helmet valve
            do {
                put(Prim.superellipsoid(V3(0.34, 0.4, 0.14), exponent: 3, subdivisions: hi ? 6 : 3, material: brassWorn), "back", Xform(translation: V3(0, -0.12, -0.12)))
                put(Prim.lathe([V2(0.001, 0), V2(0.05, 0.01), V2(0.058, 0.07), V2(0.058, 0.25), V2(0.04, 0.3), V2(0.001, 0.31)], segments: sides, seamTile: 0.1, material: copper), "back",
                    Xform(translation: V3(0, -0.46, -0.22)))
                for k in 0..<(hi ? 5 : 3) {
                    ring("back", V3(0, -0.4 + 0.05 * Float(k), -0.22), major: 0.06, minor: 0.008, copper)
                }
                let n = hi ? 14 : 6
                let hose = (0..<n).map { i -> V3 in
                    let u = Float(i) / Float(n - 1)
                    return V3(0.1 + 0.1 * sin(u * .pi), -0.1 + 0.42 * u, -0.2 - 0.12 * sin(u * .pi))
                }
                put(Prim.tube(hose, radii: hose.map { _ in 0.018 }, sides: hi ? 24 : 8, seamTile: 0.03, material: rubber, capEnd: true), "back")
                for k in 0..<4 {
                    bolt("back", V3(-0.15 + 0.1 * Float(k), 0.02, -0.2), r: 0.012, rot: simd_quatf(angle: -.pi / 2, axis: X), brassWorn)
                }
            }

            // MARK: Shoulders: brass clamp ring and canvas upper arm
            for (sx, name) in [(Float(1), "shoulderL"), (Float(-1), "shoulderR")] {
                let base = V3(sx * 0.235, -0.07, 0)
                put(Prim.superellipsoid(V3(0.2, 0.1, 0.2), exponent: 2.2, subdivisions: hi ? 5 : 3, material: brass), name, Xform(translation: base + V3(0, 0.02, 0)))
                ring(name, base + V3(0, -0.03, 0), major: 0.1, minor: 0.01, brassWorn, scale: V3(1, 1, 1.05))
                let upper = [V3(sx * 0.2, -0.05, 0), V3(sx * 0.208, -0.18, 0), V3(sx * Self.elbowX, Self.elbowY, 0)]
                put(Prim.tube(upper, radii: [0.064, 0.06, 0.056], sides: hi ? 32 : 10, seamTile: 0.05, material: canvas, capEnd: true), name)
            }

            // MARK: Forearms: canvas sleeve, brass cuff clamp, rubber mitt
            for (sx, name) in [(Float(1), "gauntletL"), (Float(-1), "gauntletR")] {
                let e = V3(sx * Self.elbowX, Self.elbowY, 0)
                put(Prim.tube([e, e + V3(0, -0.12, 0), e + V3(0, -0.23, 0)], radii: [0.056, 0.052, 0.046], sides: hi ? 32 : 10, seamTile: 0.05, material: canvas, capEnd: true), name)
                put(Prim.lathe([V2(0.054, 0), V2(0.062, 0.01), V2(0.062, 0.04), V2(0.054, 0.05)], segments: sides, seamTile: 0.08, material: brass), name,
                    Xform(translation: e + V3(0, -0.215, 0), rotation: flipX))
                ring(name, e + V3(0, -0.2, 0), major: 0.058, minor: 0.005, brassWorn)
                put(Prim.superellipsoid(V3(0.11, 0.13, 0.08), exponent: 2.4, subdivisions: hi ? 6 : 3, material: rubber), name, Xform(translation: e + V3(0, -0.34, 0.004)))
                put(Prim.superellipsoid(V3(0.05, 0.07, 0.05), exponent: 2.4, subdivisions: hi ? 5 : 3, material: rubber), name, Xform(translation: e + V3(sx * 0.055, -0.36, 0.045)))
            }

            // MARK: Forearm drill on the right arm: stowed stub (option 0), extended spiral bit (option 1)
            do {
                let e = V3(-Self.elbowX, Self.elbowY, 0)
                let hp = e + V3(-0.07, -0.1, 0.05)
                put(Prim.lathe([V2(0.03, 0), V2(0.034, 0.02), V2(0.034, 0.1), V2(0.026, 0.12)], segments: hi ? 32 : 10, seamTile: 0.04, material: iron), "drillOut",
                    option: 0, Xform(translation: hp, rotation: flipX))
                put(Prim.lathe([V2(0.03, 0), V2(0.034, 0.02), V2(0.034, 0.1), V2(0.026, 0.12)], segments: hi ? 32 : 10, seamTile: 0.04, material: iron), "drillOut",
                    option: 1, Xform(translation: hp, rotation: flipX))
                let bit: [V2] = [V2(0.024, 0), V2(0.024, 0.04), V2(0.018, 0.12), V2(0.01, 0.2), V2(0.001, 0.26)]
                put(Prim.lathe(bit, segments: hi ? 24 : 8, seamTile: 0.02, material: iron), "drillOut", option: 1,
                    Xform(translation: hp + V3(0, -0.12, 0), rotation: flipX))
                for k in 0..<(hi ? 6 : 3) {
                    ring("drillOut", hp + V3(0, -0.15 - 0.03 * Float(k), 0), major: 0.021 - 0.002 * Float(k), minor: 0.004, brassWorn, option: 1)
                }
            }
        }

        rig.states = [
            RigState("rest", [:]),
            RigState("lamp", ["lamp": 1], options: ["lampOn": 1]),
            RigState("bubbles", ["lamp": 1, "bubbles": 1], options: ["lampOn": 1, "valveOpen": 1]),
            RigState("drill", ["lamp": 1, "bubbles": 1, "drill": 1], options: ["lampOn": 1, "valveOpen": 1, "drillOut": 1]),
            RigState("rust", ["lamp": 1, "rust": 1], options: ["lampOn": 1, "patina": 1]),
        ]
        return rig
    }
}
