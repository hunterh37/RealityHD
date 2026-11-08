import simd
import Foundation

/// Cargo power-loader exosuit kit, life size for a 1.75 m wearer: a yellow painted steel exoframe worn over the body, with a
/// roll cage carrying an amber beacon, a chest frame with harness bars, a pelvis ring, shoulder bearings with hydraulic
/// pistons (48 side tubes), and two forearm claws with three fingers each. Original shapes only: no logos, no film marks.
/// Origin at the neck base, face toward +Z, up +Y, wearer's left = +X.
///
/// Kit parts (pivots in asset space): `cage` (0, 0.05, 0), `chest` (0, -0.18, 0.12), `pelvis` (0, -0.62, 0),
/// `shoulderL` / `shoulderR` (+-0.20, -0.05, 0), `clawL` / `clawR` (+-0.215, -0.31, 0) with the forearm along -Y.
///
/// Joints (set with `setJoints`): `clamp` (0...1) closes the claw fingers, `hydraulic` (0...1) is an empty driver for the
/// piston stroke, `beacon` (0...1) lights the amber roll-bar beacon, `stomp` (0...1) is an empty driver for the foot slam.
/// Followers `clawsOpen` / `clawsClosed` switch with `clamp` at 0.5, `beaconLit` switches with `beacon` at 0.05. 2 LODs.
public struct LoaderExosuit: RealArticulated {
    public static let id = "loader-exosuit"
    public static let summary = "Yellow power-loader exoframe: roll cage with amber beacon, hydraulic pistons, harness chest frame and two three-finger claws."
    public static let tags = ["prop", "metal", "articulated", "glowing"]
    public static let budget = 20_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 8, distance: 1.1)

    /// Painted frame plates and cage tubes.
    public var paint: MaterialKey = "metal.signal-yellow"
    /// Pistons, pins, claw fingers.
    public var steel: MaterialKey = "metal.steel"
    /// Polished piston rods.
    public var rod: MaterialKey = "metal.chrome"
    /// Hose, boots, seals, harness.
    public var dark: MaterialKey = "plastic.black"
    /// Lit beacon lens.
    public var beaconLit: MaterialKey = "emissive.amber"
    public init() {}

    static let elbowX: Float = 0.215
    static let elbowY: Float = -0.31
    static let shoulderX: Float = 0.20

    // MARK: Rig

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [3])
        let X = V3(1, 0, 0), Y = V3(0, 1, 0), Z = V3(0, 0, 1)

        for name in ["clamp", "hydraulic", "beacon", "stomp"] {
            _ = rig.part(name, pivot: .zero, joint: .hinge(axis: Y, 0...1, duration: 0.5))
        }
        let pivots: [(String, V3)] = [
            ("cage", V3(0, 0.05, 0)), ("chest", V3(0, -0.18, 0.12)), ("pelvis", V3(0, -0.62, 0)),
            ("shoulderL", V3(Self.shoulderX, -0.05, 0)), ("shoulderR", V3(-Self.shoulderX, -0.05, 0)),
            ("clawL", V3(Self.elbowX, Self.elbowY, 0)), ("clawR", V3(-Self.elbowX, Self.elbowY, 0)),
        ]
        for (name, p) in pivots { _ = rig.part(name, pivot: p, joint: .fixed) }
        _ = rig.part("beaconLit", parent: "cage", pivot: V3(0, 0.34, 0), joint: .fixed, options: 2)
        _ = rig.part("clawsOpenL", parent: "clawL", pivot: V3(Self.elbowX, Self.elbowY - 0.3, 0), joint: .fixed, options: 2)
        _ = rig.part("clawsOpenR", parent: "clawR", pivot: V3(-Self.elbowX, Self.elbowY - 0.3, 0), joint: .fixed, options: 2)
        rig.optionLinks = [
            RigOptionLink(part: "beaconLit", joint: "beacon", thresholds: [0.05]),
            RigOptionLink(part: "clawsOpenL", joint: "clamp", thresholds: [0.5]),
            RigOptionLink(part: "clawsOpenR", joint: "clamp", thresholds: [0.5]),
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
            func bolt(_ part: String, _ at: V3, r: Float = 0.007) {
                put(Prim.lathe([V2(r, 0), V2(r * 0.95, 0.004), V2(r * 0.55, 0.008), V2(0.001, 0.009)], segments: hi ? 16 : 6, seamTile: 0.02, material: steel), part,
                    Xform(translation: at, rotation: simd_quatf(angle: .pi / 2, axis: X)))
            }
            func piston(_ part: String, from a: V3, to b: V3) {
                let m = (a + b) * 0.5
                let barrel = [a, V3(a.x * 0.6 + m.x * 0.4, a.y * 0.6 + m.y * 0.4, a.z * 0.6 + m.z * 0.4)]
                put(Prim.tube(barrel, radii: [0.026, 0.026], sides: sides, seamTile: 0.04, material: steel, capEnd: true), part)
                put(Prim.tube([barrel[1], b], radii: [0.012, 0.012], sides: sides, seamTile: 0.04, material: rod, capEnd: true), part)
                ring(part, a, major: 0.026, minor: 0.006, dark)
            }

            // MARK: Roll cage: four tube arch over the head with amber beacon on top
            do {
                let hoop = [V3(-0.2, -0.05, -0.05), V3(-0.22, 0.2, -0.06), V3(-0.12, 0.38, -0.05), V3(0.12, 0.38, -0.05), V3(0.22, 0.2, -0.06), V3(0.2, -0.05, -0.05)]
                put(Prim.tube(hoop, radii: hoop.map { _ in 0.015 }, sides: sides, seamTile: 0.05, material: paint, capEnd: true), "cage")
                for sx in [Float(-1), 1] {
                    put(Prim.tube([V3(sx * 0.2, 0.22, -0.06), V3(sx * 0.2, 0.28, 0.1), V3(sx * 0.16, 0.2, 0.2)], radii: [0.012, 0.012, 0.012], sides: sides, seamTile: 0.05, material: paint, capEnd: true), "cage")
                }
                put(Prim.tube([V3(-0.12, 0.38, -0.05), V3(-0.1, 0.4, 0.1), V3(0.1, 0.4, 0.1), V3(0.12, 0.38, -0.05)], radii: [0.012, 0.012, 0.012, 0.012], sides: sides, seamTile: 0.05, material: paint, capEnd: true), "cage")
                // Beacon base and lens: dark housing (option 0) or lit amber lens (option 1).
                put(Prim.lathe([V2(0.04, 0), V2(0.042, 0.01), V2(0.034, 0.025), V2(0.028, 0.03)], segments: sides, seamTile: 0.05, material: dark), "cage", Xform(translation: V3(0, 0.4, 0.02)))
                let lens = Prim.lathe([V2(0.03, 0), V2(0.032, 0.012), V2(0.028, 0.03), V2(0.016, 0.044), V2(0.001, 0.05)], segments: sides, seamTile: 0.05, material: beaconLit)
                put(lens, "beaconLit", option: 1, Xform(translation: V3(0, 0.03, 0.02)))
                put(Prim.lathe([V2(0.03, 0), V2(0.032, 0.012), V2(0.028, 0.03), V2(0.016, 0.044), V2(0.001, 0.05)], segments: sides, seamTile: 0.05, material: dark), "beaconLit", option: 0, Xform(translation: V3(0, 0.03, 0.02)))
                for sx in [Float(-1), 1] { bolt("cage", V3(sx * 0.2, -0.04, -0.05)) }
            }

            // MARK: Chest frame: plate, harness bars, hip belt of the harness
            do {
                put(Prim.superellipsoid(V3(0.4, 0.5, 0.2), exponent: 3.2, subdivisions: hi ? 6 : 3, material: paint), "chest", Xform(translation: V3(0, -0.14, -0.02)))
                put(Prim.superellipsoid(V3(0.2, 0.14, 0.05), exponent: 3, subdivisions: hi ? 5 : 3, material: steel), "chest", Xform(translation: V3(0, -0.04, 0.12)))
                for sx in [Float(-1), 1] {
                    put(Prim.tube([V3(sx * 0.1, 0.1, 0.1), V3(sx * 0.11, -0.1, 0.14), V3(sx * 0.1, -0.34, 0.1)], radii: [0.016, 0.016, 0.016], sides: sides, seamTile: 0.05, material: dark, capEnd: true), "chest")
                    bolt("chest", V3(sx * 0.15, 0.02, 0.145))
                }
                ring("chest", V3(0, -0.4, -0.02), major: 0.18, minor: 0.016, paint, scale: V3(1, 1, 0.7))
            }

            // MARK: Pelvis ring and hip pistons
            do {
                ring("pelvis", V3(0, 0, 0), major: 0.2, minor: 0.024, paint, scale: V3(1, 1, 0.72))
                ring("pelvis", V3(0, -0.06, 0), major: 0.19, minor: 0.012, dark, scale: V3(1, 1, 0.72))
                for sx in [Float(-1), 1] {
                    piston("pelvis", from: V3(sx * 0.2, 0.02, 0.03), to: V3(sx * 0.2, 0.34, 0.03))
                    bolt("pelvis", V3(sx * 0.2, 0.0, 0.07))
                }
            }

            // MARK: Shoulder bearing, plate and arm piston
            for (sx, name) in [(Float(1), "shoulderL"), (Float(-1), "shoulderR")] {
                let base = V3(sx * 0.235, -0.07, 0)
                put(Prim.lathe([V2(0.11, 0), V2(0.118, 0.012), V2(0.1, 0.045), V2(0.07, 0.068), V2(0.001, 0.08)], segments: sides, seamTile: 0.1, material: paint), name,
                    Xform(translation: base, rotation: simd_quatf(angle: -sx * 0.3, axis: Z), scale: V3(1, 1, 1.12)))
                ring(name, base, major: 0.112, minor: 0.01, steel, tilt: simd_quatf(angle: -sx * 0.3, axis: Z), scale: V3(1, 1, 1.12))
                let upper = [V3(sx * 0.2, -0.05, 0), V3(sx * 0.208, -0.18, 0), V3(sx * Self.elbowX, Self.elbowY, 0)]
                put(Prim.tube(upper, radii: [0.05, 0.048, 0.046], sides: hi ? 32 : 10, seamTile: 0.05, material: paint, capEnd: true), name)
                piston(name, from: V3(sx * 0.29, -0.04, 0.0), to: V3(sx * 0.27, -0.28, 0.0))
                bolt(name, V3(sx * 0.29, -0.02, 0.03))
            }

            // MARK: Forearm sleeve, wrist ring, claw palm; fingers open (option 0) or closed (option 1)
            for (sx, name, openName) in [(Float(1), "clawL", "clawsOpenL"), (Float(-1), "clawR", "clawsOpenR")] {
                let e = V3(sx * Self.elbowX, Self.elbowY, 0)
                put(Prim.tube([e, e + V3(0, -0.13, 0), e + V3(0, -0.26, 0)], radii: [0.055, 0.053, 0.048], sides: hi ? 32 : 10, seamTile: 0.05, material: paint, capEnd: true), name)
                for k in 0..<(hi ? 4 : 2) { ring(name, e + V3(0, -0.04 - 0.05 * Float(k), 0), major: 0.054 - 0.001 * Float(k), minor: 0.005, steel) }
                ring(name, e + V3(0, -0.27, 0), major: 0.05, minor: 0.01, dark)
                put(Prim.superellipsoid(V3(0.12, 0.1, 0.1), exponent: 2.6, subdivisions: hi ? 6 : 3, material: steel), name, Xform(translation: e + V3(0, -0.33, 0)))
                for f in 0..<3 {
                    let a = Float(f) / 3 * 2 * .pi + .pi / 2
                    let dir = V3(cos(a), 0, sin(a))
                    let r = dir * 0.05
                    let open = [e + V3(0, -0.36, 0) + r, e + V3(0, -0.45, 0) + dir * 0.085, e + V3(0, -0.54, 0) + dir * 0.1]
                    let closed = [e + V3(0, -0.36, 0) + r, e + V3(0, -0.46, 0) + dir * 0.06, e + V3(0, -0.53, 0) + dir * 0.012]
                    put(Prim.tube(open, radii: [0.016, 0.013, 0.006], sides: hi ? 24 : 8, seamTile: 0.03, material: steel, capEnd: true), openName, option: 0)
                    put(Prim.tube(closed, radii: [0.016, 0.013, 0.006], sides: hi ? 24 : 8, seamTile: 0.03, material: steel, capEnd: true), openName, option: 1)
                }
            }
        }

        rig.states = [
            RigState("rest", [:]),
            RigState("beacon", ["beacon": 1], options: ["beaconLit": 1]),
            RigState("clamp", ["beacon": 1, "clamp": 1], options: ["beaconLit": 1, "clawsOpenL": 1, "clawsOpenR": 1]),
            RigState("hydraulic", ["beacon": 1, "hydraulic": 1], options: ["beaconLit": 1]),
            RigState("stomp", ["beacon": 1, "stomp": 1], options: ["beaconLit": 1]),
        ]
        return rig
    }
}
