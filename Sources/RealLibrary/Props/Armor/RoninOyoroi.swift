import simd
import Foundation

/// Ronin o-yoroi kit, life size for a 1.75 m wearer: a lacquered black and crimson lamellar cuirass with silk lacing and a
/// two tier skirt of hanging plates, layered shoulder plates, studded forearm splints, a tiered kabuto with a swept neck
/// guard, flared wing plates and a crescent crest, an oni face mask with tusks and eye sockets, a back banner pole and a katana
/// in a scabbard at the left hip that can be drawn in the right hand. Original shapes only: no crests, no clan marks.
/// Origin at the neck base, face toward +Z, up +Y, wearer's left = +X.
///
/// Kit parts (pivots in asset space): `helmet` (0, 0, 0), `chest` (0, -0.18, 0.12), `back` (0, -0.20, -0.12),
/// `shoulderL` / `shoulderR` (+-0.20, -0.05, 0), `gauntletL` / `gauntletR` (+-0.215, -0.31, 0) with the forearm along -Y.
///
/// Joints (set with `setJoints`), all 0...1 empty drivers: `menpo` (mask eye glow, follower `menpoGlow` option 0 dark
/// sockets, option 1 emissive), `katana` (draw, followers `sayaHilt` on the chest option 0 sheathed sword, option 1 empty
/// scabbard, and `bladeDrawn` on gauntletR option 1 a 0.7 m blade held along -Y), `crest` (helm crest shine, follower
/// `crestShine` option 0 aged brass, option 1 polished gold), `petals` (empty driver for the lens sakura storm). Followers
/// switch when the joint passes 0.05. 2 LODs.
public struct RoninOyoroi: RealArticulated {
    public static let id = "ronin-oyoroi"
    public static let summary = "Ronin o-yoroi kit: black and crimson lacquered lamellar cuirass with silk lacing, layered shoulder plates, kabuto with oni mask and crest, back banner pole and a drawable katana."
    public static let tags = ["prop", "metal", "lacquer", "articulated", "glowing"]
    public static let budget = 20_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 8, distance: 1.0)

    /// Black lacquer plates.
    public var black: MaterialKey = "paint.car-clearcoat:0D0D10"
    /// Crimson lacquer plates and mask.
    public var crimson: MaterialKey = "paint.car-clearcoat:8E1220"
    /// Silk lacing cord.
    public var cord: MaterialKey = "fabric.grosgrain:A3192B"
    /// Under garment sleeves.
    public var cloth: MaterialKey = "fabric.canvas:17171C"
    /// Gloves and straps.
    public var leather: MaterialKey = "leather.black"
    /// Polished crest and fittings.
    public var gold: MaterialKey = "metal.gold"
    /// Aged crest.
    public var brass: MaterialKey = "metal.brass-aged"
    /// Mirror steel blade.
    public var blade: MaterialKey = "metal.mirror-polish"
    /// Guards, rivets and ferrules.
    public var steel: MaterialKey = "metal.steel"
    /// Mask tusks.
    public var tusk: MaterialKey = "ceramic.bisque"
    /// Dark sockets and scabbard.
    public var dark: MaterialKey = "plastic.black"
    /// Lit eye sockets.
    public var eyeGlow: MaterialKey = "emissive.signal-red"
    public init() {}

    static let elbowX: Float = 0.215
    static let elbowY: Float = -0.31

    /// Torso half width at height `y` (asset space).
    static func torsoRadius(_ y: Float) -> Float { 0.2 + (y + 0.10) * 0.07 }
    static let torsoDepth: Float = 0.62

    /// Rounded rectangle outline in the XY plane.
    static func plateOutline(w: Float, h: Float, cut: Float) -> [V2] {
        let x = w / 2, y = h / 2, c = min(cut, min(x, y) * 0.9)
        return [V2(-x + c, -y), V2(x - c, -y), V2(x, -y + c), V2(x, y - c), V2(x - c, y), V2(-x + c, y), V2(-x, y - c), V2(-x, -y + c)]
    }

    /// Bowl profile (radius, y) from the rim up over the crown.
    func domeProfile(rx: Float, y0: Float, ry: Float, hi: Bool) -> [V2] {
        let n = hi ? 16 : 7
        var p: [V2] = [V2(rx * 0.97, y0 - 0.012), V2(rx, y0)]
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

        for name in ["menpo", "katana", "crest", "petals"] {
            _ = rig.part(name, pivot: .zero, joint: .hinge(axis: Y, 0...1, duration: 0.5))
        }
        let pivots: [(String, V3)] = [
            ("helmet", V3(0, 0, 0)), ("chest", V3(0, -0.18, 0.12)), ("back", V3(0, -0.20, -0.12)),
            ("shoulderL", V3(0.20, -0.05, 0)), ("shoulderR", V3(-0.20, -0.05, 0)),
            ("gauntletL", V3(Self.elbowX, Self.elbowY, 0)), ("gauntletR", V3(-Self.elbowX, Self.elbowY, 0)),
        ]
        for (name, p) in pivots { _ = rig.part(name, pivot: p, joint: .fixed) }
        _ = rig.part("menpoGlow", parent: "helmet", pivot: V3(0, 0.12, 0.1), joint: .fixed, options: 2)
        _ = rig.part("crestShine", parent: "helmet", pivot: V3(0, 0.25, 0.04), joint: .fixed, options: 2)
        _ = rig.part("sayaHilt", parent: "chest", pivot: V3(0.19, -0.6, 0.12), joint: .fixed, options: 2)
        _ = rig.part("bladeDrawn", parent: "gauntletR", pivot: V3(-Self.elbowX, Self.elbowY - 0.3, 0), joint: .fixed, options: 2)
        rig.optionLinks = [
            RigOptionLink(part: "menpoGlow", joint: "menpo", thresholds: [0.05]),
            RigOptionLink(part: "crestShine", joint: "crest", thresholds: [0.05]),
            RigOptionLink(part: "sayaHilt", joint: "katana", thresholds: [0.05]),
            RigOptionLink(part: "bladeDrawn", joint: "katana", thresholds: [0.05]),
        ]

        for l in 0..<2 {
            let hi = l == 0
            let sides = hi ? 48 : 16
            func put(_ s: Surface, _ part: String, option: Int = 0, _ x: Xform = .identity) {
                rig.add(s, x, to: part, option: option, lods: l...l)
            }
            func ring(_ part: String, _ at: V3, major: Float, minor: Float, _ mat: MaterialKey, option: Int = 0, scale: V3 = V3(1, 1, 1)) {
                put(Prim.torus(major: major, minor: minor, segments: hi ? 48 : 16, sides: hi ? 8 : 5, material: mat), part, option: option,
                    Xform(translation: at, scale: scale))
            }
            func plate(_ part: String, w: Float, h: Float, d: Float, _ mat: MaterialKey, at: V3, yaw: Float = 0, roll: Float = 0, pitch: Float = 0) {
                let q = simd_quatf(angle: yaw, axis: Y) * simd_quatf(angle: roll, axis: Z) * simd_quatf(angle: pitch, axis: X)
                put(Prim.extrude(Self.plateOutline(w: w, h: h, cut: min(w, h) * 0.18), depth: d, bevel: 0.003, bevelSegments: hi ? 2 : 1, material: mat), part,
                    Xform(translation: at, rotation: q))
            }
            func lamp(_ part: String, _ at: V3, option: Int, _ mat: MaterialKey, r: Float) {
                put(Prim.lathe([V2(r, 0), V2(r * 0.9, 0.004), V2(r * 0.5, 0.008), V2(0.001, 0.01)], segments: hi ? 24 : 8, seamTile: 0.02, material: mat), part,
                    option: option, Xform(translation: at, rotation: simd_quatf(angle: .pi / 2, axis: X)))
            }

            // MARK: Helmet: bowl, rim band, tiered neck guard, wing plates, crest, mask
            do {
                put(Prim.lathe(domeProfile(rx: 0.118, y0: 0.1, ry: 0.15, hi: hi), segments: sides, seamTile: 0.1, material: black), "helmet",
                    Xform(translation: V3(0, 0, 0.004), scale: V3(1, 1, 1.08)))
                ring("helmet", V3(0, 0.1, 0.004), major: 0.12, minor: 0.008, gold, scale: V3(1, 1, 1.08))
                ring("helmet", V3(0, 0.15, 0.004), major: 0.108, minor: 0.004, crimson, scale: V3(1, 1, 1.08))
                // Neck guard: four flaring lacquer tiers laced with cord.
                for k in 0..<4 {
                    let top = 0.1 - 0.045 * Float(k)
                    let r0 = 0.125 + 0.028 * Float(k), r1 = r0 + 0.026
                    let prof = [V2(r1, 0), V2(r1 + 0.005, 0.006), V2(r0 + 0.005, 0.04), V2(r0, 0.046)]
                    put(Prim.lathe(prof, segments: sides, seamTile: 0.1, material: k % 2 == 0 ? black : crimson), "helmet",
                        Xform(translation: V3(0, top - 0.046, -0.01), scale: V3(1, 1, 1.0)))
                    ring("helmet", V3(0, top - 0.002, -0.01), major: r0 + 0.004, minor: 0.0035, cord)
                }
                // Wing plates flare out from the brow.
                for sx in [Float(-1), 1] {
                    plate("helmet", w: 0.085, h: 0.075, d: 0.008, crimson, at: V3(sx * 0.13, 0.145, 0.07), yaw: sx * 1.05, roll: -sx * 0.45)
                    plate("helmet", w: 0.075, h: 0.05, d: 0.008, black, at: V3(sx * 0.15, 0.1, 0.06), yaw: sx * 1.05, roll: -sx * 0.45)
                }
                // Crest: crescent horns rising from a boss. Aged brass (option 0) or polished gold (option 1).
                for o in 0..<2 {
                    let m = o == 0 ? brass : gold
                    put(Prim.lathe([V2(0.001, 0), V2(0.026, 0.004), V2(0.03, 0.012), V2(0.02, 0.022), V2(0.001, 0.026)], segments: hi ? 32 : 10, seamTile: 0.05, material: m),
                        "crestShine", option: o, Xform(translation: V3(0, 0.255, 0.1), rotation: simd_quatf(angle: .pi / 2, axis: X)))
                    for sx in [Float(-1), 1] {
                        let n = hi ? 10 : 5
                        let path = (0..<n).map { i -> V3 in
                            let u = Float(i) / Float(n - 1)
                            return V3(sx * (0.025 + 0.15 * sin(u * 1.35)), 0.255 + 0.19 * u - 0.03 * u * u, 0.108 + 0.03 * u)
                        }
                        let radii = (0..<n).map { i -> Float in 0.011 * (1 - Float(i) / Float(n - 1)) + 0.002 }
                        put(Prim.tube(path, radii: radii, sides: hi ? 48 : 12, seamTile: 0.04, material: m, capEnd: true), "crestShine", option: o)
                    }
                }
                // Oni mask: crimson face, brow ridge, nose, tusks, mouth slit, eye sockets.
                put(Prim.superellipsoid(V3(0.092, 0.082, 0.05), exponent: 2.6, subdivisions: hi ? 6 : 3, material: crimson), "helmet", Xform(translation: V3(0, 0.082, 0.098)))
                put(Prim.superellipsoid(V3(0.098, 0.022, 0.034), exponent: 2.4, subdivisions: hi ? 5 : 3, material: crimson), "helmet", Xform(translation: V3(0, 0.148, 0.128)))
                put(Prim.superellipsoid(V3(0.02, 0.034, 0.03), exponent: 2.4, subdivisions: hi ? 5 : 3, material: crimson), "helmet", Xform(translation: V3(0, 0.1, 0.15)))
                put(Prim.superellipsoid(V3(0.05, 0.007, 0.012), exponent: 2.4, subdivisions: hi ? 4 : 2, material: dark), "helmet", Xform(translation: V3(0, 0.036, 0.142)))
                for sx in [Float(-1), 1] {
                    put(Prim.lathe([V2(0.011, 0), V2(0.009, 0.02), V2(0.004, 0.045), V2(0.001, 0.058)], segments: hi ? 24 : 8, seamTile: 0.03, material: tusk), "helmet",
                        Xform(translation: V3(sx * 0.04, 0.04, 0.146), rotation: simd_quatf(angle: -0.25, axis: X)))
                    put(Prim.superellipsoid(V3(0.03, 0.014, 0.02), exponent: 2.6, subdivisions: hi ? 4 : 2, material: dark), "helmet", Xform(translation: V3(sx * 0.04, 0.128, 0.138)))
                    lamp("menpoGlow", V3(sx * 0.04, 0.128, 0.146), option: 0, dark, r: 0.015)
                    lamp("menpoGlow", V3(sx * 0.04, 0.128, 0.146), option: 1, eyeGlow, r: 0.015)
                    // Chin cord to the neck guard.
                    put(Prim.tube([V3(sx * 0.1, 0.1, 0.08), V3(sx * 0.1, 0.03, 0.09), V3(sx * 0.06, -0.02, 0.1)], radii: [0.004, 0.004, 0.004], sides: hi ? 16 : 5, seamTile: 0.02, material: cord, capEnd: true), "helmet")
                }
            }

            // MARK: Chest: gorget, seven lamellar bands, lacing, front medallion, two tier skirt, scabbard
            do {
                for k in 0..<7 {
                    let top = -0.10 - 0.07 * Float(k)
                    let rt = Self.torsoRadius(top), rb = Self.torsoRadius(top - 0.07)
                    let prof = [V2(rb, 0), V2(rb + 0.006, 0.006), V2(rt + 0.006, 0.062), V2(rt, 0.07)]
                    put(Prim.lathe(prof, segments: sides, seamTile: 0.1, material: k % 2 == 0 ? black : crimson), "chest",
                        Xform(translation: V3(0, top - 0.07, 0), scale: V3(1, 1, Self.torsoDepth)))
                }
                for k in [0, 2, 4, 6] {
                    let y = -0.10 - 0.07 * Float(k) - 0.07
                    ring("chest", V3(0, y, 0), major: Self.torsoRadius(y) + 0.006, minor: 0.0035, cord, scale: V3(1, 1, Self.torsoDepth))
                }
                // Vertical silk laces down the front and back.
                for sz in [Float(1), -1] {
                    for sx in [Float(-0.14), -0.07, 0, 0.07, 0.14] {
                        let n = hi ? 6 : 3
                        let path = (0..<n).map { i -> V3 in
                            let y = -0.1 - 0.49 * Float(i) / Float(n - 1)
                            let r = Self.torsoRadius(y) + 0.009
                            let z = sqrt(max(0, 1 - (sx / r) * (sx / r))) * r * Self.torsoDepth
                            return V3(sx, y, sz * z)
                        }
                        put(Prim.tube(path, radii: path.map { _ in 0.0032 }, sides: hi ? 48 : 8, seamTile: 0.02, material: cord, capEnd: true), "chest")
                    }
                }
                put(Prim.lathe([V2(0.001, 0), V2(0.045, 0.004), V2(0.05, 0.012), V2(0.03, 0.02), V2(0.001, 0.024)], segments: hi ? 32 : 10, seamTile: 0.05, material: gold), "chest",
                    Xform(translation: V3(0, -0.2, 0.128), rotation: simd_quatf(angle: .pi / 2, axis: X)))
                // Gorget collar, two flaring tiers.
                for k in 0..<2 {
                    let y = -0.01 - 0.04 * Float(k)
                    let prof = [V2(0.15 + 0.03 * Float(k), 0), V2(0.152 + 0.03 * Float(k), 0.006), V2(0.12 + 0.03 * Float(k), 0.038), V2(0.118 + 0.03 * Float(k), 0.042)]
                    put(Prim.lathe(prof, segments: sides, seamTile: 0.1, material: k == 0 ? crimson : black), "chest",
                        Xform(translation: V3(0, y - 0.04, 0), scale: V3(1, 1, 0.8)))
                }
                // Kusazuri skirt: two tiers of hanging plates around the waist.
                let count = hi ? 12 : 8
                for tier in 0..<2 {
                    let y = -0.66 - 0.085 * Float(tier)
                    for i in 0..<count {
                        let a = Float(i) / Float(count) * 2 * .pi + (tier == 1 ? .pi / Float(count) : 0)
                        let r = Self.torsoRadius(-0.6) + 0.012 + 0.018 * Float(tier)
                        plate("chest", w: 0.13 * 12 / Float(count) * 0.92, h: 0.1, d: 0.008, (i + tier) % 2 == 0 ? black : crimson,
                              at: V3(r * sin(a), y, r * Self.torsoDepth * cos(a) * 1.05), yaw: a, pitch: 0.12)
                    }
                    ring("chest", V3(0, y + 0.05, 0), major: Self.torsoRadius(-0.6) + 0.012 + 0.018 * Float(tier), minor: 0.004, gold, scale: V3(1, 1, Self.torsoDepth * 1.05))
                }
                // Scabbard on the wearer's left hip, hilt forward (option 0 holds the sword, option 1 the empty scabbard).
                let hilt = V3(0.19, -0.6, 0.13), tip = V3(0.25, -1.28, -0.2)
                let mid = (hilt + tip) / 2 + V3(0.008, 0, 0)
                put(Prim.tube([hilt + (tip - hilt) * 0.2, mid, tip], radii: [0.019, 0.018, 0.012], sides: hi ? 48 : 12, seamTile: 0.04, material: black, capEnd: true), "chest")
                put(Prim.torus(major: 0.02, minor: 0.004, segments: hi ? 48 : 16, sides: hi ? 8 : 5, material: gold), "chest",
                    Xform(translation: hilt + (tip - hilt) * 0.22, rotation: simd_quatf(from: Y, to: simd_normalize(tip - hilt)) * simd_quatf(angle: 0, axis: Y)))
                put(Prim.tube([hilt, hilt + (tip - hilt) * 0.2], radii: [0.015, 0.016], sides: hi ? 48 : 12, seamTile: 0.04, material: cord, capEnd: true), "sayaHilt", option: 0)
                put(Prim.lathe([V2(0.001, 0), V2(0.03, 0.002), V2(0.032, 0.006), V2(0.001, 0.008)], segments: hi ? 32 : 10, seamTile: 0.05, material: steel), "sayaHilt", option: 0,
                    Xform(translation: hilt + (tip - hilt) * 0.2, rotation: simd_quatf(from: Y, to: simd_normalize(tip - hilt))))
                put(Prim.lathe([V2(0.001, 0), V2(0.02, 0.002), V2(0.019, 0.01), V2(0.001, 0.012)], segments: hi ? 32 : 10, seamTile: 0.05, material: gold), "sayaHilt", option: 1,
                    Xform(translation: hilt + (tip - hilt) * 0.2, rotation: simd_quatf(from: Y, to: simd_normalize(tip - hilt))))
            }

            // MARK: Back: banner pole with a plain crimson banner, lacing bow, back plate rim
            do {
                put(Prim.tube([V3(0.02, -0.7, -0.2), V3(0.02, -0.2, -0.22), V3(0.02, 0.5, -0.22)], radii: [0.008, 0.008, 0.006], sides: hi ? 48 : 12, seamTile: 0.04, material: dark, capEnd: true), "back")
                put(Prim.tube([V3(0.02, 0.5, -0.22), V3(0.16, 0.5, -0.22)], radii: [0.005, 0.005], sides: hi ? 48 : 12, seamTile: 0.04, material: dark, capEnd: true), "back")
                put(Prim.extrude(Self.plateOutline(w: 0.13, h: 0.62, cut: 0.012), depth: 0.004, bevel: 0.0015, bevelSegments: 1, material: crimson), "back",
                    Xform(translation: V3(0.09, 0.2, -0.225)))
                put(Prim.lathe([V2(0.001, 0), V2(0.014, 0.004), V2(0.016, 0.012), V2(0.001, 0.018)], segments: hi ? 24 : 8, seamTile: 0.03, material: gold), "back",
                    Xform(translation: V3(0.02, 0.51, -0.22)))
                // Lacing bow with two loops and two tails.
                for sx in [Float(-1), 1] {
                    ring("back", V3(sx * 0.035, -0.12, -0.19), major: 0.032, minor: 0.005, cord)
                    put(Prim.tube([V3(0, -0.12, -0.19), V3(sx * 0.03, -0.19, -0.2), V3(sx * 0.05, -0.3, -0.19)], radii: [0.006, 0.005, 0.004], sides: hi ? 16 : 5, seamTile: 0.02, material: cord, capEnd: true), "back")
                }
            }

            // MARK: Shoulders: four stepped plates per side and a laced upper arm
            for (sx, name) in [(Float(1), "shoulderL"), (Float(-1), "shoulderR")] {
                for k in 0..<4 {
                    let y = -0.04 - 0.062 * Float(k)
                    plate(name, w: 0.2 - 0.008 * Float(k), h: 0.066, d: 0.01, k % 2 == 0 ? black : crimson,
                          at: V3(sx * (0.27 + 0.012 * Float(k)), y, 0), yaw: 0, roll: -sx * (0.5 + 0.05 * Float(k)))
                    put(Prim.tube([V3(sx * (0.22 + 0.01 * Float(k)), y + 0.028, 0.03), V3(sx * (0.22 + 0.01 * Float(k)), y - 0.034, 0.03)], radii: [0.0035, 0.0035],
                                  sides: hi ? 48 : 8, seamTile: 0.02, material: cord, capEnd: true), name)
                }
                put(Prim.tube([V3(sx * 0.2, -0.05, 0), V3(sx * 0.208, -0.18, 0), V3(sx * Self.elbowX, Self.elbowY, 0)], radii: [0.056, 0.052, 0.048],
                              sides: hi ? 48 : 12, seamTile: 0.05, material: cloth, capEnd: true), name)
                ring(name, V3(sx * 0.206, -0.15, 0), major: 0.054, minor: 0.005, cord)
            }

            // MARK: Forearms: cloth sleeve, four lacquer splints, cuff ring, leather glove
            for (sx, name) in [(Float(1), "gauntletL"), (Float(-1), "gauntletR")] {
                let e = V3(sx * Self.elbowX, Self.elbowY, 0)
                put(Prim.tube([e, e + V3(0, -0.12, 0), e + V3(0, -0.23, 0)], radii: [0.048, 0.045, 0.039], sides: hi ? 48 : 12, seamTile: 0.05, material: cloth, capEnd: true), name)
                for k in 0..<4 {
                    let y = -0.04 - 0.045 * Float(k)
                    let r = 0.05 - 0.002 * Float(k)
                    put(Prim.lathe([V2(r, 0), V2(r + 0.004, 0.004), V2(r + 0.004, 0.034), V2(r, 0.038)], segments: sides, seamTile: 0.08, material: k % 2 == 0 ? black : crimson), name,
                        Xform(translation: e + V3(0, y - 0.038, 0)))
                }
                ring(name, e + V3(0, -0.215, 0), major: 0.043, minor: 0.006, gold)
                put(Prim.superellipsoid(V3(0.09, 0.11, 0.065), exponent: 2.4, subdivisions: hi ? 6 : 3, material: leather), name, Xform(translation: e + V3(0, -0.325, 0.004)))
                plate(name, w: 0.075, h: 0.085, d: 0.008, black, at: e + V3(0, -0.31, 0.04), pitch: -0.08)
                for f in 0..<4 {
                    let x = (Float(f) - 1.5) * 0.02
                    put(Prim.tube([e + V3(x, -0.37, 0.015), e + V3(x, -0.41, 0.028), e + V3(x, -0.437, 0.025)], radii: [0.0095, 0.009, 0.0075], sides: hi ? 16 : 5, seamTile: 0.02, material: leather, capEnd: true), name)
                }
            }

            // MARK: Drawn katana in the right hand (option 1), wrist cord (option 0). Blade 0.7 m along -Y.
            do {
                let e = V3(-Self.elbowX, Self.elbowY, 0)
                let g = e + V3(0, -0.3, 0)
                put(Prim.tube([g + V3(0, -0.04, 0.03), g + V3(0, -0.07, 0.04)], radii: [0.003, 0.003], sides: hi ? 16 : 5, seamTile: 0.02, material: cord, capEnd: true), "bladeDrawn", option: 0)
                // Handle wrapped in silk, guard, then the curved blade.
                put(Prim.tube([g + V3(0, 0.05, 0), g + V3(0, -0.08, 0), g + V3(0, -0.2, 0)], radii: [0.0165, 0.0155, 0.015], sides: hi ? 48 : 12, seamTile: 0.04, material: cord, capEnd: true), "bladeDrawn", option: 1)
                put(Prim.lathe([V2(0.001, 0), V2(0.02, 0.0), V2(0.04, 0.002), V2(0.043, 0.005), V2(0.04, 0.008), V2(0.001, 0.01)], segments: hi ? 48 : 12, seamTile: 0.05, material: gold), "bladeDrawn", option: 1,
                    Xform(translation: g + V3(0, -0.2, 0), rotation: simd_quatf(angle: .pi, axis: X)))
                let n = hi ? 14 : 6
                let path = (0..<n).map { i -> V3 in
                    let u = Float(i) / Float(n - 1)
                    return g + V3(0, -0.21 - 0.7 * u, 0.045 * u * u)
                }
                let prof: [V2] = [V2(0.0, -0.0015), V2(0.011, -0.0015), V2(0.0125, 0.0), V2(0.011, 0.0015), V2(-0.002, 0.0015), V2(-0.0045, 0.0)]
                put(Prim.sweep(prof, along: path, scales: path.indices.map { i in 1 - 0.3 * Float(i) / Float(n - 1) }, material: blade), "bladeDrawn", option: 1)
            }
        }

        rig.states = [
            RigState("rest", [:]),
            RigState("menpo", ["menpo": 1], options: ["menpoGlow": 1]),
            RigState("katana", ["menpo": 1, "katana": 1], options: ["menpoGlow": 1, "sayaHilt": 1, "bladeDrawn": 1]),
            RigState("crest", ["menpo": 1, "katana": 1, "crest": 1], options: ["menpoGlow": 1, "sayaHilt": 1, "bladeDrawn": 1, "crestShine": 1]),
            RigState("petals", ["menpo": 1, "crest": 1, "petals": 1], options: ["menpoGlow": 1, "crestShine": 1]),
        ]
        return rig
    }
}
