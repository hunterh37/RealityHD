import simd
import Foundation

/// 18 m bipedal combat mech: chamfered painted armour plates (`plate` white, `accent` orange), gunmetal frame, chrome hydraulic
/// pistons, a glowing chest reactor, amber eye visor, tinted cockpit canopy, two shoulder missile pods (six missiles each) and a
/// heavy cannon on the left (+X) forearm. Origin on the ground between the feet, front +Z, feet flat at y = 0.
/// Joints (set with `setJoints`): `walk` 0...1 sweeps one stride (0.5 neutral stance, 0 left leg trailing and right leg leading,
/// 1 the reverse; legs, knees, ankles, counter-swinging arms and torso twist follow; drive it 0 to 1 to 0 for a full cycle),
/// `aim` -1...1 (cannon arm yaw, +1 toward +X), `pods` 0...1 (both pod lids open) and `head` -1...1 (yaw toward +X).
public struct TitanMech: RealArticulated {
    public static let id = "titan-mech"
    public static let summary = "Titan mech, 18 m: white and orange chamfered armour, hydraulic pistons, glowing chest reactor, amber visor, missile pods, arm cannon, walking rig."
    public static let tags = ["prop", "vehicle", "robot", "mech", "metal", "outdoor", "articulated"]
    public static let budget = 28_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 6, distance: 1.1, studio: true)

    /// Main armour plates.
    public var plate: MaterialKey = "metal.painted:E9EAE6"
    /// Accent armour plates and stripes.
    public var accent: MaterialKey = "metal.painted:E4571B"
    /// Structural frame, joints and housings.
    public var frame: MaterialKey = "metal.anodized-gunmetal"
    /// Hydraulic piston rods.
    public var rod: MaterialKey = "metal.chrome"
    /// Hoses and seals.
    public var hose: MaterialKey = "rubber.tubing"
    /// Cockpit canopy glass.
    public var glass: MaterialKey = "glass.lens-coated:0A0E14"
    /// Chest reactor core.
    public var reactor: MaterialKey = "emissive.thruster-cyan"
    /// Eye visor.
    public var visor: MaterialKey = "emissive.amber"
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        _ = seed
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [90])
        let rotX90 = simd_quatf(degrees: 90, axis: V3(1, 0, 0))     // lathe +Y -> +Z
        let rotZ90 = simd_quatf(degrees: 90, axis: V3(0, 0, 1))     // lathe +Y -> -X
        var lod = 0
        func sub(_ n: Int) -> Int { lod == 0 ? n : max(3, n / 2) }
        func seg(_ n: Int) -> Int { lod == 0 ? n : max(8, n / 2) }
        func put(_ s: Surface, _ x: Xform = .identity, _ part: String? = nil) {
            if let part { rig.add(s, x, to: part, lods: lod...lod) } else { rig.base[lod].add(s, x) }
        }
        func at(_ p: V3, _ q: simd_quatf = .identity) -> Xform { Xform(translation: p, rotation: q) }
        /// Smooth superellipsoid armour block.
        func block(_ size: V3, _ e: Float, _ n: Int, _ mat: MaterialKey, _ p: V3, _ part: String?, _ q: simd_quatf = .identity) {
            put(Prim.superellipsoid(size, exponent: e, subdivisions: sub(n), material: mat), at(p, q), part)
        }
        /// Chamfered front plate: octagonal outline extruded with a rounded bevel, facing +Z (`q` reorients).
        func slab(_ w: Float, _ h: Float, _ cut: Float, _ depth: Float, _ mat: MaterialKey, _ p: V3, _ part: String?, _ q: simd_quatf = .identity) {
            let hw = w / 2, hh = h / 2
            let o: [V2] = [V2(-hw + cut, -hh), V2(hw - cut, -hh), V2(hw, -hh + cut), V2(hw, hh - cut), V2(hw - cut, hh), V2(-hw + cut, hh), V2(-hw, hh - cut), V2(-hw, -hh + cut)]
            put(Prim.extrude(Shape2D.rounded(o, radius: cut * 0.3, segments: lod == 0 ? 3 : 1), depth: depth, bevel: min(0.12, depth * 0.4), bevelSegments: lod == 0 ? 2 : 1, material: mat), at(p, q), part)
        }
        /// Hydraulic piston: dark sleeve and chrome rod between two points, with end collars.
        func piston(_ a: V3, _ b: V3, _ r: Float, sleeve: Float = 0.55, _ sleevePart: String?, _ rodPart: String?) {
            let m = a + (b - a) * sleeve
            let sides = lod == 0 ? 20 : 8
            put(Prim.tube([a, m], radii: [r * 1.35, r * 1.35], sides: sides, seamTile: 0.3, material: frame), .identity, sleevePart)
            put(Prim.tube([m - (b - a) * 0.04, b], radii: [r * 0.62, r * 0.62], sides: sides, seamTile: 0.3, material: rod), .identity, rodPart)
            put(Prim.superellipsoid(V3(r * 3.1, r * 3.1, r * 3.1), exponent: 2, subdivisions: sub(5), material: frame), at(a), sleevePart)
            put(Prim.superellipsoid(V3(r * 2.6, r * 2.6, r * 2.6), exponent: 2, subdivisions: sub(5), material: frame), at(b), rodPart)
        }
        /// Cylinder along +Y between y = 0 and h, lathe with rounded rims.
        func drum(_ r: Float, _ h: Float, _ mat: MaterialKey, _ p: V3, _ part: String?, _ q: simd_quatf = .identity, bevel: Float = 0.08) {
            put(Prim.cylinder(radius: r, height: h, bevel: bevel, segments: seg(40), bevelSegments: lod == 0 ? 3 : 1, material: mat), at(p, q), part)
        }

        // Control joints (no geometry) and the walking hierarchy.
        rig.part("walk", pivot: V3(0, 9, 0), joint: .hinge(axis: V3(0, 0, 1), 0...1, duration: 1.2))
        rig.part("aim", pivot: V3(0, 9, 0), joint: .hinge(axis: V3(0, 0, 1), -1...1, duration: 1.0))
        rig.part("pods", pivot: V3(0, 9, 0), joint: .hinge(axis: V3(0, 0, 1), 0...1, duration: 1.6))
        rig.part("head", pivot: V3(0, 9, 0), joint: .hinge(axis: V3(0, 0, 1), -1...1, duration: 0.8))
        let sides: [(name: String, s: Float)] = [("L", 1), ("R", -1)]
        for (n, s) in sides {
            // Left (+X): thigh = 30 - 60 walk; right is the mirror.
            let k: Float = s > 0 ? -1 : 1
            rig.part("thigh\(n)", pivot: V3(s * 2.1, 9.0, 0), joint: Joint(.revolute, axis: V3(1, 0, 0), range: -45...45, mimic: .init("walk", ratio: k * 60, offset: -k * 30)))
            rig.part("shin\(n)", parent: "thigh\(n)", pivot: V3(s * 2.1, 5.1, 0.4), joint: Joint(.revolute, axis: V3(1, 0, 0), range: -5...50, mimic: .init("walk", ratio: s > 0 ? -30 : 30, offset: s > 0 ? 30 : 0)))
            rig.part("foot\(n)", parent: "shin\(n)", pivot: V3(s * 2.1, 1.3, 0.1), joint: Joint(.revolute, axis: V3(1, 0, 0), range: -75...75, mimic: .init("walk", ratio: s * 90, offset: s > 0 ? -60 : 30)))
        }
        rig.part("torso", pivot: V3(0, 10.0, 0), joint: Joint(.revolute, axis: V3(0, 1, 0), range: -12...12, mimic: .init("walk", ratio: 10, offset: -5)))
        rig.part("headTurn", parent: "torso", pivot: V3(0, 15.3, 0.2), joint: Joint(.revolute, axis: V3(0, 1, 0), range: -60...60, mimic: .init("head", ratio: 45)))
        rig.part("armSwingL", parent: "torso", pivot: V3(3.9, 14.3, 0), joint: Joint(.revolute, axis: V3(1, 0, 0), range: -25...25, mimic: .init("walk", ratio: 36, offset: -18)))
        rig.part("armAimL", parent: "armSwingL", pivot: V3(3.9, 14.3, 0), joint: Joint(.revolute, axis: V3(0, 1, 0), range: -50...50, mimic: .init("aim", ratio: 38)))
        rig.part("armSwingR", parent: "torso", pivot: V3(-3.9, 14.3, 0), joint: Joint(.revolute, axis: V3(1, 0, 0), range: -25...25, mimic: .init("walk", ratio: -36, offset: 18)))
        rig.part("podLidL", parent: "torso", pivot: V3(4.45, 16.55, -0.9), joint: Joint(.revolute, axis: V3(0, 0, 1), range: -115...0, mimic: .init("pods", ratio: -105)))
        rig.part("podLidR", parent: "torso", pivot: V3(-4.45, 16.55, -0.9), joint: Joint(.revolute, axis: V3(0, 0, 1), range: 0...115, mimic: .init("pods", ratio: 105)))

        for l in 0..<2 {
            lod = l
            // Pelvis and waist (static).
            block(V3(6.2, 1.9, 3.9), 8, 12, plate, V3(0, 9.6, 0), nil)
            block(V3(4.6, 1.3, 3.5), 6, 8, frame, V3(0, 8.9, 0), nil)
            slab(2.2, 1.5, 0.4, 0.4, accent, V3(0, 9.55, 1.95), nil)
            slab(2.0, 1.7, 0.4, 0.35, accent, V3(0, 9.55, -2.0), nil, simd_quatf(degrees: 180, axis: V3(0, 1, 0)))
            for s: Float in [-1, 1] {
                block(V3(1.2, 2.2, 3.0), 8, 8, plate, V3(s * 3.35, 9.3, 0), nil)
                block(V3(2.0, 2.0, 2.0), 2, 9, frame, V3(s * 2.1, 9.0, 0), nil)       // hip ball
            }
            // Torso: waist ring, chest, collar, backpack.
            drum(1.9, 0.9, frame, V3(0, 10.0, 0), "torso")
            for y: Float in [10.3, 10.6] { put(Prim.torus(major: 1.95, minor: 0.09, segments: seg(48), sides: lod == 0 ? 12 : 5, material: rod), at(V3(0, y, 0)), "torso") }
            block(V3(6.6, 4.8, 4.4), 5, 16, plate, V3(0, 12.9, 0), "torso")
            block(V3(7.4, 1.4, 3.6), 6, 10, frame, V3(0, 15.1, 0), "torso")
            slab(5.0, 2.0, 0.7, 0.55, accent, V3(0, 14.3, 2.15), "torso")                // upper chest chevron
            slab(2.0, 2.6, 0.5, 0.35, plate, V3(-2.2, 11.9, 2.1), "torso")
            slab(2.0, 2.6, 0.5, 0.35, plate, V3(2.2, 11.9, 2.1), "torso")
            for s: Float in [-1, 1] {                                                    // flank intake grilles
                for i in 0..<(lod == 0 ? 4 : 2) {
                    put(Prim.roundedBox(V3(0.18, 0.2, 2.4), radius: 0.05, bevelSegments: lod == 0 ? 2 : 1, material: frame), at(V3(s * 3.34, 11.5 + Float(i) * 0.38, 0.2)), "torso")
                }
            }
            // Reactor: housing, lens, rim, vanes.
            let rc = V3(0, 12.2, 2.2)
            put(Prim.lathe(Profile.smooth([V2(0, 0), V2(1.1, 0), V2(1.2, 0.08), V2(1.2, 0.30), V2(1.0, 0.40), V2(0.8, 0.30)], per: lod == 0 ? 3 : 1), segments: seg(48), material: frame), at(rc - V3(0, 0, 0.12), rotX90), "torso")
            put(Prim.lathe([V2(0, 0), V2(0.84, 0), V2(0.9, 0.04), V2(0.9, 0.1), V2(0, 0.1)], segments: seg(48), material: reactor), at(rc + V3(0, 0, 0.18), rotX90), "torso")
            put(Prim.torus(major: 1.0, minor: 0.1, segments: seg(48), sides: lod == 0 ? 14 : 6, material: rod), at(rc + V3(0, 0, 0.3), rotX90), "torso")
            put(Prim.torus(major: 0.5, minor: 0.05, segments: seg(36), sides: lod == 0 ? 10 : 5, material: frame), at(rc + V3(0, 0, 0.30), rotX90), "torso")
            if l == 0 {
                for i in 0..<6 {
                    let a = Float(i) * .pi / 3
                    put(Prim.roundedBox(V3(0.07, 0.8, 0.07), radius: 0.02, bevelSegments: 1, material: frame),
                        at(rc + V3(cos(a) * 0.5, sin(a) * 0.5, 0.32), simd_quatf(angle: a - .pi / 2, axis: V3(0, 0, 1))), "torso")
                }
            }
            // Backpack engine block with exhausts and shoulder vents.
            block(V3(4.0, 3.6, 2.0), 7, 10, frame, V3(0, 13.0, -3.0), "torso")
            for s: Float in [-1, 1] {
                put(Prim.lathe(Profile.smooth([V2(0.0, 0.0), V2(0.7, 0.0), V2(0.62, 0.8), V2(0.8, 1.4), V2(0.74, 1.5), V2(0.0, 1.5)], per: 2), segments: seg(32), material: frame),
                    at(V3(s * 1.1, 13.0, -4.0), simd_quatf(degrees: -90, axis: V3(1, 0, 0))), "torso")
                drum(0.28, 1.2, hose, V3(s * 4.9, 15.2, -1.8), "torso")                     // steam vent stack
            }
            // Shoulders, pods.
            for (n, s) in sides {
                block(V3(2.5, 2.2, 3.1), 6, 11, accent, V3(s * 4.0, 14.9, 0), "torso")
                block(V3(1.8, 1.8, 1.8), 2, 9, frame, V3(s * 3.9, 14.3, 0), "armSwing\(n)")  // shoulder ball
                // Pod tray (lid is a separate part), missiles.
                let pc = V3(s * 3.75, 16.0, -0.9)
                put(Prim.roundedBox(V3(1.7, 0.2, 3.3), radius: 0.06, bevelSegments: lod == 0 ? 2 : 1, material: frame), at(pc - V3(0, 0.55, 0)), "torso")
                for w: Float in [-1, 1] { put(Prim.roundedBox(V3(0.14, 1.0, 3.3), radius: 0.05, bevelSegments: lod == 0 ? 2 : 1, material: plate), at(pc + V3(w * 0.78, 0, 0)), "torso") }
                put(Prim.roundedBox(V3(1.7, 1.0, 0.14), radius: 0.05, bevelSegments: lod == 0 ? 2 : 1, material: plate), at(pc - V3(0, 0, 1.58)), "torso")
                for row in 0..<2 {
                    for col in 0..<3 {
                        let mp = pc + V3((Float(col) - 1) * 0.47, -0.22 + Float(row) * 0.46, 0.0)
                        let body: [V2] = [V2(0, 0), V2(0.2, 0), V2(0.2, 2.0), V2(0.17, 2.35), V2(0.10, 2.72), V2(0, 2.95)]
                        put(Prim.lathe(Profile.smooth(body, per: lod == 0 ? 2 : 1), segments: seg(20), material: plate), at(mp - V3(0, 0, 1.35), rotX90), "torso")
                        put(Prim.lathe([V2(0.205, 0.5), V2(0.205, 0.8), V2(0.2, 0.8), V2(0.2, 0.5)], segments: seg(20), material: accent), at(mp - V3(0, 0, 1.35), rotX90), "torso")
                        if l == 0 { put(Prim.lathe([V2(0.0, 0.0), V2(0.12, 0.0), V2(0.13, 0.03), V2(0.0, 0.03)], segments: 12, material: reactor), at(mp + V3(0, 0, 1.58), rotX90), "torso") }
                    }
                }
                // Lid: hinge edge at the outboard side, plate sits inboard of the pivot.
                let lidC = V3(s * 3.75, 16.55, -0.9)
                block(V3(1.9, 0.26, 3.5), 8, 9, plate, lidC, "podLid\(n)")
                slab(1.2, 2.6, 0.3, 0.1, accent, lidC + V3(0, 0.15, 0), "podLid\(n)", simd_quatf(degrees: -90, axis: V3(1, 0, 0)))
                put(Prim.cylinder(radius: 0.1, height: 3.5, bevel: 0.03, segments: seg(16), bevelSegments: 1, material: frame), at(V3(s * 4.45, 16.55, 0.85), simd_quatf(degrees: -90, axis: V3(1, 0, 0))), "podLid\(n)")
            }
            // Head: neck on torso, head on headTurn.
            drum(0.9, 0.8, frame, V3(0, 15.4, 0.1), "torso")
            block(V3(2.8, 2.0, 3.0), 5, 12, plate, V3(0, 16.45, 0.3), "headTurn")
            slab(2.6, 0.7, 0.25, 0.3, accent, V3(0, 17.3, 1.35), "headTurn", simd_quatf(degrees: -22, axis: V3(1, 0, 0)))
            block(V3(2.1, 0.42, 0.35), 8, 9, visor, V3(0, 16.45, 1.72), "headTurn")          // visor strip
            block(V3(2.5, 0.2, 0.3), 8, 6, frame, V3(0, 16.45, 1.66), "headTurn")
            block(V3(2.2, 1.0, 2.0), 3, 12, glass, V3(0, 17.35, -0.2), "headTurn")           // cockpit canopy
            put(Prim.torus(major: 1.0, minor: 0.06, segments: seg(36), sides: lod == 0 ? 8 : 4, material: rod), at(V3(0, 16.98, -0.2)), "headTurn")
            for s: Float in [-1, 1] {
                block(V3(0.7, 1.3, 1.5), 6, 7, accent, V3(s * 1.5, 16.35, 0.05), "headTurn")  // cheek plates
                put(Prim.tube([V3(s * 0.9, 17.6, -1.0), V3(s * 1.1, 19.0, -1.3)], radii: [0.05, 0.03], sides: lod == 0 ? 8 : 4, seamTile: 0.2, material: frame), .identity, "headTurn")
            }
            // Arms.
            // Right arm (-X): hanging upper and fore armour, fist.
            do {
                let x: Float = -3.9
                block(V3(1.6, 3.0, 1.7), 6, 10, plate, V3(x, 12.75, 0), "armSwingR")
                block(V3(1.5, 1.5, 1.5), 2, 8, frame, V3(x, 11.1, 0.05), "armSwingR")
                block(V3(2.0, 3.3, 2.2), 6, 11, plate, V3(x, 9.4, 0.15), "armSwingR")
                slab(1.5, 2.4, 0.35, 0.3, accent, V3(x, 9.6, 1.3), "armSwingR")
                block(V3(1.7, 1.3, 1.9), 7, 8, frame, V3(x, 7.4, 0.25), "armSwingR")           // wrist and gripper
                for i in 0..<3 { block(V3(0.4, 0.9, 1.1), 6, 5, frame, V3(x + (Float(i) - 1) * 0.5, 6.5, 0.7), "armSwingR") }
                piston(V3(x - 0.95, 12.2, 0.0), V3(x - 0.95, 10.2, 0.55), 0.14, "armSwingR", "armSwingR")
            }
            // Left arm (+X): upper arm, forearm cannon on the aim yaw part.
            do {
                let x: Float = 3.9
                block(V3(1.6, 3.0, 1.7), 6, 10, plate, V3(x, 12.75, 0), "armSwingL")
                block(V3(1.6, 1.6, 1.6), 2, 8, frame, V3(x, 11.1, 0.0), "armAimL")
                block(V3(2.0, 2.0, 3.4), 6, 11, plate, V3(x, 11.1, 1.8), "armAimL")           // cannon housing
                slab(1.4, 1.2, 0.3, 0.3, accent, V3(x, 12.2, 1.9), "armAimL", simd_quatf(degrees: -90, axis: V3(1, 0, 0)))
                let barrel: [V2] = [V2(0.62, 3.4), V2(0.52, 3.6), V2(0.46, 4.2), V2(0.46, 6.2), V2(0.62, 6.3), V2(0.62, 6.9), V2(0.52, 7.0), V2(0.30, 7.0), V2(0.30, 6.6)]
                put(Prim.lathe(Profile.smooth(barrel, per: lod == 0 ? 2 : 1), segments: seg(40), material: frame), at(V3(x, 11.1, 0), rotX90), "armAimL")
                for z: Float in [4.0, 4.6, 5.2] {
                    put(Prim.torus(major: 0.55, minor: 0.07, segments: seg(40), sides: lod == 0 ? 10 : 5, material: accent), at(V3(x, 11.1, z), rotX90), "armAimL")
                }
                put(Prim.torus(major: 0.48, minor: 0.05, segments: seg(36), sides: lod == 0 ? 8 : 4, material: reactor), at(V3(x, 11.1, 3.65), rotX90), "armAimL")
                for sgn: Float in [-1, 1] {
                    piston(V3(x + sgn * 0.85, 11.9, 2.2), V3(x + sgn * 0.85, 11.2, 4.6), 0.12, "armAimL", "armAimL")
                }
            }
            // Elbow and shoulder pistons from torso.
            piston(V3(4.7, 14.9, -0.3), V3(4.75, 12.6, -0.6), 0.14, "torso", "armSwingL")
            // Legs.
            for (n, s) in sides {
                let x = s * 2.1
                let th = "thigh\(n)", sh = "shin\(n)", ft = "foot\(n)"
                block(V3(2.2, 4.3, 2.5), 7, 12, plate, V3(x, 7.1, 0.1), th)
                slab(1.6, 3.0, 0.45, 0.3, accent, V3(x, 7.2, 1.38), th)
                block(V3(2.6, 1.3, 2.6), 6, 8, frame, V3(x, 8.75, -0.1), th)
                // Thigh pistons front, with the rods landing on the shin plate.
                piston(V3(x + s * 0.75, 8.6, 1.6), V3(x + s * 0.75, 5.6, 1.5), 0.17, th, sh)
                piston(V3(x, 8.5, -1.45), V3(x, 4.6, -1.15), 0.2, sleeve: 0.5, th, sh)
                // Knee: joint drum on the shin part, cap plate.
                put(Prim.cylinder(radius: 0.85, height: 2.7, bevel: 0.1, segments: seg(40), bevelSegments: lod == 0 ? 3 : 1, material: frame), at(V3(x + 1.35, 5.1, 0.4), rotZ90), sh)
                block(V3(2.0, 1.5, 1.6), 6, 9, accent, V3(x, 5.2, 1.45), sh)
                block(V3(2.1, 4.0, 2.6), 6, 12, plate, V3(x, 3.1, 0.15), sh)
                slab(1.5, 2.6, 0.4, 0.28, accent, V3(x, 3.2, 1.5), sh, simd_quatf(degrees: 8, axis: V3(1, 0, 0)))
                block(V3(1.6, 1.4, 1.5), 6, 8, frame, V3(x, 1.5, -0.65), sh)                 // ankle housing
                if l == 0 {
                    for i in 0..<3 { block(V3(2.15, 0.12, 2.65), 10, 4, frame, V3(x, 2.0 + Float(i) * 0.55, 0.15), sh) }  // calf seams
                }
                // Foot.
                block(V3(1.9, 1.5, 1.9), 2, 8, frame, V3(x, 1.3, 0.1), ft)                    // ankle ball
                block(V3(2.9, 1.0, 4.6), 7, 12, plate, V3(x, 0.5, 0.95), ft)
                block(V3(3.0, 0.5, 4.8), 10, 8, frame, V3(x, 0.25, 0.95), ft)                // sole
                slab(2.0, 1.8, 0.4, 0.35, accent, V3(x, 0.98, 2.1), ft, simd_quatf(degrees: -84, axis: V3(1, 0, 0)))  // toe cap
                block(V3(1.7, 0.6, 1.4), 6, 7, accent, V3(x, 1.15, -0.3), ft)                // heel cap
                for tx: Float in [-0.85, 0, 0.85] { block(V3(0.7, 0.6, 1.0), 6, 6, frame, V3(x + tx, 0.35, 3.25), ft) }  // toes
            }
            // Hip and torso cabling.
            for s: Float in [-1, 1] {
                put(Prim.tube([V3(s * 1.6, 11.0, 1.3), V3(s * 2.0, 10.0, 1.7), V3(s * 2.3, 9.2, 1.4)], radii: [0.12, 0.12, 0.12], sides: lod == 0 ? 10 : 5, seamTile: 0.2, material: hose), .identity, nil)
            }
        }

        rig.lights = [RigLight(name: "reactor", kind: .point, part: "torso", position: V3(0, 12.2, 3.0), color: V3(0.35, 0.85, 1.0), intensity: 1500, attenuationRadius: 22)]
        rig.states = [
            RigState("rest", ["walk": 0.5]),
            RigState("stride-left", ["walk": 0]),
            RigState("stride-right", ["walk": 1]),
            RigState("aim-left", ["walk": 0.5, "aim": -1]),
            RigState("aim-right", ["walk": 0.5, "aim": 1]),
            RigState("pods-open", ["walk": 0.5, "pods": 1]),
            RigState("look-left", ["walk": 0.5, "head": -1]),
            RigState("look-right", ["walk": 0.5, "head": 1]),
        ]
        groundAO(&rig, height: 1.5)
        return rig
    }
}
