import simd
import Foundation

/// Hell rider biker leathers kit, life size for a 1.75 m wearer. A black leather jacket with raised lapels, chrome studs and
/// shoulder spikes, studded leather sleeves with chrome cuffs, a belt with a coiled chain, and a head that is a chrome-bone
/// skull under a removable flesh shell. Original shapes, no logos. Origin at the neck base, face toward +Z, up +Y,
/// wearer's left = +X.
///
/// Kit parts (pivots in asset space): `helmet` (0, 0, 0) is the head, `chest` (0, -0.18, 0.12), `back` (0, -0.20, -0.12),
/// `shoulderL` / `shoulderR` (+-0.20, -0.05, 0), `gauntletL` / `gauntletR` (+-0.215, -0.31, 0) with the forearm along -Y.
///
/// Joints (set with `setJoints`), all 0...1 empty drivers: `skull` (flesh to bone, followers `fleshHead` option 0 intact
/// flesh shell, option 1 burnt away), `flame` (head fire size, follower `crownCracks` lights ember cracks on the cranium),
/// `chain` (chain whip, follower `chainLash` adds a 0.9 m chain along -Y of gauntletR), `stare` (eye sockets blaze,
/// follower `socketGlow` option 0 dark plugs, option 1 emissive). Followers switch when the joint passes 0.05. 2 LODs.
public struct HellriderLeathers: RealArticulated {
    public static let id = "hellrider-leathers"
    public static let summary = "Hell rider biker leathers kit: studded black leather jacket, shoulder spikes, chrome cuffs, belt chain, and a chrome-bone skull head with blazing eye sockets."
    public static let tags = ["prop", "metal", "leather", "articulated", "glowing"]
    public static let budget = 20_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 8, distance: 1.0)

    /// Jacket, sleeves, belt and boots.
    public var leather: MaterialKey = "leather.black"
    /// Studs, spikes, cuffs and buckle.
    public var chrome: MaterialKey = "metal.chrome"
    /// Skull.
    public var bone: MaterialKey = "anatomy.bone"
    /// Flesh shell over the skull.
    public var flesh: MaterialKey = "anatomy.muscle"
    /// Chain links.
    public var chainMat: MaterialKey = "metal.steel"
    /// Eye socket blaze.
    public var blaze: MaterialKey = "emissive.led-red"
    /// Ember cracks on the cranium.
    public var ember: MaterialKey = "emissive.ember"
    public init() {}

    static let elbowX: Float = 0.215
    static let elbowY: Float = -0.31
    static let shoulderX: Float = 0.20

    func rad(_ d: Float) -> Float { d * .pi / 180 }

    /// Chrome stud: low dome.
    func stud(_ part: String, _ at: V3, _ dir: V3, hi: Bool, rig: inout Rig, lod l: Int) {
        let s = Prim.lathe([V2(0.0075, 0), V2(0.0062, 0.003), V2(0.0035, 0.0058), V2(0.001, 0.0072)], segments: hi ? 12 : 6, seamTile: 0.02, material: chrome)
        rig.add(s, Xform(translation: at, rotation: simd_quatf(from: V3(0, 1, 0), to: simd_normalize(dir))), to: part, option: 0, lods: l...l)
    }

    /// Spike cone along +Y, 48 sides at LOD0.
    func spike(radius r: Float, height h: Float, hi: Bool) -> Surface {
        Prim.lathe([V2(r, 0), V2(r * 0.82, h * 0.2), V2(r * 0.5, h * 0.55), V2(r * 0.18, h * 0.85), V2(0.001, h)], segments: hi ? 48 : 12, seamTile: 0.03, material: chrome)
    }

    // MARK: Rig

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [3])
        let X = V3(1, 0, 0), Y = V3(0, 1, 0), Z = V3(0, 0, 1)
        let flipX = simd_quatf(angle: .pi, axis: X)
        let hip = V3(0, -0.53, 0)

        // Drivers first so option links resolve.
        for name in ["skull", "flame", "chain", "stare"] {
            _ = rig.part(name, pivot: .zero, joint: .hinge(axis: Y, 0...1, duration: 0.5))
        }
        let pivots: [(String, V3)] = [
            ("helmet", V3(0, 0, 0)), ("chest", V3(0, -0.18, 0.12)), ("back", V3(0, -0.20, -0.12)),
            ("shoulderL", V3(Self.shoulderX, -0.05, 0)), ("shoulderR", V3(-Self.shoulderX, -0.05, 0)),
            ("gauntletL", V3(Self.elbowX, Self.elbowY, 0)), ("gauntletR", V3(-Self.elbowX, Self.elbowY, 0)),
        ]
        for (name, p) in pivots { _ = rig.part(name, pivot: p, joint: .fixed) }
        _ = rig.part("fleshHead", parent: "helmet", pivot: V3(0, 0.15, 0), joint: .fixed, options: 2)
        _ = rig.part("socketGlow", parent: "helmet", pivot: V3(0, 0.17, 0.09), joint: .fixed, options: 2)
        _ = rig.part("crownCracks", parent: "helmet", pivot: V3(0, 0.25, 0), joint: .fixed, options: 2)
        _ = rig.part("chainLash", parent: "gauntletR", pivot: V3(-Self.elbowX, Self.elbowY - 0.28, 0), joint: .fixed, options: 2)
        rig.optionLinks = [
            RigOptionLink(part: "fleshHead", joint: "skull", thresholds: [0.05]),
            RigOptionLink(part: "socketGlow", joint: "stare", thresholds: [0.05]),
            RigOptionLink(part: "crownCracks", joint: "flame", thresholds: [0.05]),
            RigOptionLink(part: "chainLash", joint: "chain", thresholds: [0.05]),
        ]

        for l in 0..<2 {
            let hi = l == 0
            let sides = hi ? 48 : 16
            func put(_ s: Surface, _ part: String, option: Int = 0, _ x: Xform = .identity) {
                rig.add(s, x, to: part, option: option, lods: l...l)
            }
            func studs(_ part: String, _ pts: [V3], _ dir: V3) {
                guard hi else { return }
                for p in pts { stud(part, p, dir, hi: hi, rig: &rig, lod: l) }
            }
            /// Chain of `n` torus links hanging along -Y from `from`, alternating link planes.
            func chain(_ part: String, option: Int, from: V3, n: Int, pitch: Float, major: Float, minor: Float) {
                for k in 0..<n {
                    let turn = simd_quatf(angle: Float(k % 2) * .pi / 2, axis: Y)
                    let lay = simd_quatf(angle: .pi / 2, axis: X)
                    put(Prim.torus(major: major, minor: minor, segments: hi ? 20 : 10, sides: hi ? 8 : 4, material: chainMat), part, option: option,
                        Xform(translation: from + V3(0, -pitch * Float(k), 0), rotation: turn * lay, scale: V3(1.3, 1, 1)))
                }
            }

            // MARK: Head: chrome-bone skull, flesh shell, sockets, cracks
            do {
                // Cranium, brow ridge, cheekbones, nose cavity, jaw and teeth.
                put(Prim.superellipsoid(V3(0.17, 0.2, 0.22), exponent: 2.2, subdivisions: hi ? 7 : 3, material: bone), "helmet", Xform(translation: V3(0, 0.185, -0.005)))
                put(Prim.superellipsoid(V3(0.15, 0.03, 0.07), exponent: 2.4, subdivisions: hi ? 6 : 3, material: bone), "helmet", Xform(translation: V3(0, 0.178, 0.085)))
                for sx in [Float(-1), 1] {
                    put(Prim.superellipsoid(V3(0.04, 0.03, 0.04), exponent: 2.2, subdivisions: hi ? 5 : 3, material: bone), "helmet",
                        Xform(translation: V3(sx * 0.075, 0.11, 0.07), rotation: simd_quatf(angle: sx * 0.3, axis: Y)))
                }
                put(Prim.superellipsoid(V3(0.032, 0.05, 0.03), exponent: 2.6, subdivisions: hi ? 5 : 3, material: bone), "helmet", Xform(translation: V3(0, 0.12, 0.1)))
                put(Prim.superellipsoid(V3(0.135, 0.07, 0.15), exponent: 2.4, subdivisions: hi ? 6 : 3, material: bone), "helmet", Xform(translation: V3(0, 0.065, 0.03)))
                put(Prim.superellipsoid(V3(0.05, 0.036, 0.045), exponent: 2.4, subdivisions: hi ? 5 : 3, material: bone), "helmet", Xform(translation: V3(0, 0.032, 0.095)))
                for k in 0..<6 {
                    let x = (Float(k) - 2.5) * 0.02
                    put(Prim.superellipsoid(V3(0.014, 0.022, 0.012), exponent: 2.4, subdivisions: hi ? 4 : 2, material: chrome), "helmet",
                        Xform(translation: V3(x, 0.085, 0.092 - 0.003 * abs(Float(k) - 2.5))))
                }
                // Eye sockets: dark plugs (option 0) or blazing (option 1).
                for sx in [Float(-1), 1] {
                    let at = V3(sx * 0.04, 0, 0)
                    put(Prim.superellipsoid(V3(0.05, 0.045, 0.03), exponent: 2.2, subdivisions: hi ? 5 : 3, material: leather), "socketGlow", option: 0, Xform(translation: at))
                    put(Prim.superellipsoid(V3(0.044, 0.04, 0.026), exponent: 2.2, subdivisions: hi ? 5 : 3, material: blaze), "socketGlow", option: 1, Xform(translation: at))
                }
                // Flesh shell (option 0) over the face; option 1 is bare bone.
                put(Prim.superellipsoid(V3(0.2, 0.31, 0.25), exponent: 2.2, subdivisions: hi ? 7 : 3, material: flesh), "fleshHead", option: 0, Xform(translation: V3(0, 0.0, 0.0)))
                // Ember cracks across the cranium (lit with the flame joint).
                for k in 0..<5 {
                    let a = (Float(k) - 2) * rad(28)
                    let n = hi ? 6 : 3
                    let path = (0..<n).map { i -> V3 in
                        let u = Float(i) / Float(n - 1)
                        return V3(sin(a) * (0.05 + 0.07 * u), 0.0 + 0.06 * u + 0.012 * sin(u * 9 + Float(k)), cos(a) * (0.07 + 0.02 * u))
                    }
                    put(Prim.tube(path, radii: path.map { _ in 0.0026 }, sides: hi ? 8 : 4, seamTile: 0.02, material: ember, capEnd: true), "crownCracks", option: 1)
                }
                // Leather collar, raised.
                put(Prim.lathe([V2(0.07, 0), V2(0.1, 0.012), V2(0.115, 0.055), V2(0.098, 0.085)], segments: sides, seamTile: 0.1, material: leather), "helmet",
                    Xform(translation: V3(0, -0.05, -0.01)))
            }

            // MARK: Jacket
            do {
                put(Prim.superellipsoid(V3(0.37, 0.78, 0.25), exponent: 2.4, subdivisions: hi ? 6 : 3, material: leather), "chest", Xform(translation: V3(0, -0.38, 0)))
                // Lapels folded back with chrome studs along the edge.
                for sx in [Float(-1), 1] {
                    put(Prim.superellipsoid(V3(0.1, 0.24, 0.025), exponent: 2.6, subdivisions: hi ? 5 : 3, material: leather), "chest",
                        Xform(translation: V3(sx * 0.085, -0.08, 0.128), rotation: simd_quatf(angle: sx * rad(-22), axis: Z) * simd_quatf(angle: rad(-12), axis: X)))
                    studs("chest", (0..<6).map { V3(sx * (0.045 + 0.018 * Float($0)), -0.01 - 0.038 * Float($0), 0.146) }, Z)
                }
                // Zipper and belt.
                put(Prim.tube([V3(0, -0.2, 0.137), V3(0, -0.45, 0.137), V3(0, -0.52, 0.134)], radii: [0.006, 0.006, 0.006], sides: hi ? 12 : 4, seamTile: 0.02, material: chrome, capEnd: true), "chest")
                put(Prim.torus(major: 0.18, minor: 0.017, segments: hi ? 64 : 24, sides: hi ? 12 : 6, material: leather), "chest", Xform(translation: hip, scale: V3(1, 1, 0.72)))
                put(Prim.superellipsoid(V3(0.075, 0.05, 0.016), exponent: 3, subdivisions: hi ? 5 : 3, material: chrome), "chest", Xform(translation: hip + V3(0, 0, 0.13)))
                // Chain coiled on the belt (left hip).
                if hi { chain("chest", option: 0, from: hip + V3(0.13, 0.02, 0.09), n: 6, pitch: 0.021, major: 0.014, minor: 0.0034) }
                // Back panel with a studded rear patch.
                put(Prim.superellipsoid(V3(0.34, 0.5, 0.06), exponent: 2.6, subdivisions: hi ? 6 : 3, material: leather), "back", Xform(translation: V3(0, -0.2, -0.065)))
                studs("back", (0..<7).map { V3(-0.12 + 0.04 * Float($0), -0.04, -0.1) }, -Z)
                studs("back", (0..<7).map { V3(-0.12 + 0.04 * Float($0), -0.36, -0.1) }, -Z)
            }

            // MARK: Shoulders: leather yoke, chrome spike cluster
            for (sx, name) in [(Float(1), "shoulderL"), (Float(-1), "shoulderR")] {
                let tiltZ = simd_quatf(angle: -sx * 0.3, axis: Z)
                let base = V3(sx * 0.235, -0.07, 0)
                put(Prim.tube([V3(sx * 0.2, -0.05, 0), V3(sx * 0.208, -0.18, 0), V3(sx * Self.elbowX, Self.elbowY, 0)], radii: [0.052, 0.049, 0.045], sides: hi ? 24 : 8, seamTile: 0.05, material: leather, capEnd: true), name)
                put(Prim.lathe([V2(0.105, 0), V2(0.112, 0.01), V2(0.102, 0.035), V2(0.08, 0.055), V2(0.045, 0.07), V2(0.001, 0.076)], segments: sides, seamTile: 0.1, material: leather),
                    name, Xform(translation: base, rotation: tiltZ, scale: V3(1, 1, 1.1)))
                put(Prim.torus(major: 0.108, minor: 0.006, segments: hi ? 48 : 16, sides: hi ? 10 : 5, material: chrome), name,
                    Xform(translation: base + V3(0, 0.004, 0), rotation: tiltZ, scale: V3(1, 1, 1.1)))
                let spikeAt: [(V3, Float, Float)] = [(V3(0, 0.07, 0), 0.016, 0.075), (V3(sx * 0.05, 0.05, 0.06), 0.012, 0.055), (V3(sx * 0.05, 0.05, -0.06), 0.012, 0.055), (V3(sx * 0.09, 0.03, 0), 0.012, 0.05)]
                for (k, s) in spikeAt.enumerated() {
                    let dir = simd_normalize(V3(sx * (k == 0 ? 0.25 : 0.7), 1, k == 1 ? 0.55 : (k == 2 ? -0.55 : 0)))
                    put(spike(radius: s.1, height: s.2, hi: hi), name, Xform(translation: base + s.0, rotation: simd_quatf(from: Y, to: dir)))
                    put(Prim.lathe([V2(0.022, 0), V2(0.02, 0.006), V2(0.016, 0.01)], segments: hi ? 24 : 8, seamTile: 0.03, material: chrome), name,
                        Xform(translation: base + s.0, rotation: simd_quatf(from: Y, to: dir)))
                }
            }

            // MARK: Sleeves: studded leather, chrome cuff; the chain whip extends from the right fist
            for (sx, name) in [(Float(1), "gauntletL"), (Float(-1), "gauntletR")] {
                let e = V3(sx * Self.elbowX, Self.elbowY, 0)
                put(Prim.tube([e, e + V3(0, -0.12, 0), e + V3(0, -0.25, 0)], radii: [0.047, 0.044, 0.04], sides: hi ? 24 : 8, seamTile: 0.05, material: leather, capEnd: true), name)
                put(Prim.lathe([V2(0.056, 0), V2(0.06, 0.012), V2(0.054, 0.05), V2(0.048, 0.1)], segments: sides, seamTile: 0.08, material: leather),
                    name, Xform(translation: e, rotation: flipX))
                // Chrome cuff at the wrist.
                put(Prim.lathe([V2(0.042, 0), V2(0.05, 0.004), V2(0.05, 0.026), V2(0.043, 0.03)], segments: sides, seamTile: 0.05, material: chrome), name,
                    Xform(translation: e + V3(0, -0.272, 0), rotation: flipX))
                studs(name, (0..<5).map { e + V3(sx * 0.048, -0.06 - 0.042 * Float($0), 0) }, X * sx)
                // Elbow spike.
                put(spike(radius: 0.014, height: 0.06, hi: hi), name, Xform(translation: e + V3(sx * 0.04, -0.01, -0.02), rotation: simd_quatf(from: Y, to: simd_normalize(V3(sx, 0.2, -0.5)))))
                // Fist: leather glove.
                put(Prim.superellipsoid(V3(0.08, 0.1, 0.09), exponent: 2.6, subdivisions: hi ? 6 : 3, material: leather), name, Xform(translation: e + V3(0, -0.32, 0.005)))
                put(Prim.superellipsoid(V3(0.08, 0.02, 0.02), exponent: 2.8, subdivisions: hi ? 5 : 3, material: chrome), name, Xform(translation: e + V3(0, -0.345, 0.045)))
            }
            // Whip: handle ring at the right fist, chain along -Y, hooked end spike (0.9 m).
            put(Prim.torus(major: 0.02, minor: 0.004, segments: hi ? 32 : 12, sides: hi ? 10 : 5, material: chainMat), "chainLash", option: 0,
                Xform(translation: V3(0, 0.0, 0.0), rotation: simd_quatf(angle: .pi / 2, axis: X)))
            chain("chainLash", option: 1, from: V3(0, -0.02, 0), n: hi ? 18 : 7, pitch: hi ? 0.05 : 0.13, major: hi ? 0.014 : 0.03, minor: hi ? 0.0034 : 0.007)
            put(spike(radius: 0.016, height: 0.08, hi: hi), "chainLash", option: 1,
                Xform(translation: V3(0, hi ? -0.9 : -0.9, 0), rotation: flipX))
        }

        rig.states = [
            RigState("rest", [:]),
            RigState("stare", ["stare": 1], options: ["socketGlow": 1]),
            RigState("skull", ["skull": 1, "stare": 1], options: ["fleshHead": 1, "socketGlow": 1]),
            RigState("blaze", ["skull": 1, "stare": 1, "flame": 1], options: ["fleshHead": 1, "socketGlow": 1, "crownCracks": 1]),
            RigState("whip", ["skull": 1, "stare": 1, "flame": 1, "chain": 1], options: ["fleshHead": 1, "socketGlow": 1, "crownCracks": 1, "chainLash": 1]),
        ]
        return rig
    }
}
