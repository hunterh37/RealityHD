import simd
import Foundation

/// Monster truck at 6 m long and 3.8 m wide: four 2.7 m tread-block tyres on beadlock rims, fabricated tube
/// frame with four-link bars, chrome coilover shocks, fibreglass pickup body with flame livery, rollcage,
/// exhaust stacks and an emissive roof light bar. Origin at the centre of mass, nose +Z, up +Y, driver side +X.
/// Ground plane sits at y = -1.55.
///
/// Parts (degrees or meters): `pitch` (-25...25, nose up positive, body and frame tilt about the centre of mass),
/// `suspension` (0...0.4 m, shock rods slide into the shock bodies), `steer` and `steer.right` (-35...35, mimic),
/// `spin` (0...360, rear-left wheel) with `spin.rr`, `spin.fl`, `spin.fr` as mimics.
/// States: `parked`, `steer-left`, `steer-right`, `compressed`, `nose-up`, `nose-down`.
public struct MonsterTruck: RealArticulated {
    public static let id = "monster-truck"
    public static let summary = "Monster truck: 2.7 m tread-block tyres, tube frame, chrome coilover shocks, flame-livery pickup body, rollcage and roof light bar."
    public static let tags = ["prop", "vehicle", "articulated", "outdoor", "road", "metal", "rubber", "glass"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 12, distance: 1.1)

    /// Body paint (tint with `:RRGGBB`).
    public var paint: MaterialKey = "paint.car-clearcoat:B3121A"
    /// Flame livery, outer and inner tongues.
    public var flameOrange: MaterialKey = "paint.car-clearcoat:FF6A00"
    public var flameYellow: MaterialKey = "paint.car-clearcoat:FFC21A"
    /// Tyre outer radius, meters (2.7 m tall).
    public var tireRadius: Float = 1.35
    /// Tyre width, meters.
    public var tireWidth: Float = 1.05
    /// Hub centre distance from the centreline, meters (outer tyre faces at 1.9 m).
    public var halfTrack: Float = 1.375
    /// Axle distance from the centre of mass along Z, meters.
    public var halfBase: Float = 1.6
    /// Axle height, meters.
    public var axleY: Float = -0.2
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [25])
        let wob = Float(seed % 97) / 97
        let tint: MaterialKey = "metal.painted:23252A"
        let X = V3(1, 0, 0), Y = V3(0, 1, 0), Z = V3(0, 0, 1)
        let axles: [(String, Float, Float)] = [("fl", 1, 1), ("fr", -1, 1), ("rl", 1, -1), ("rr", -1, -1)]

        rig.part("pitch", pivot: V3(0, 0.3, 0), joint: .hinge(axis: V3(-1, 0, 0), -25...25, duration: 1.5))
        rig.part("suspension", parent: "pitch", pivot: V3(0, axleY, 0), joint: .slide(axis: Y, 0...0.4, duration: 1.2))
        rig.part("steer", pivot: V3(halfTrack, axleY, halfBase), joint: .hinge(axis: Y, -35...35, duration: 1.0))
        rig.part("steer.right", pivot: V3(-halfTrack, axleY, halfBase), joint: Joint(.revolute, axis: Y, range: -35...35, mimic: Joint.Mimic("steer")))
        rig.part("spin", pivot: V3(halfTrack, axleY, -halfBase), joint: .hinge(axis: X, 0...360, duration: 1.0))
        rig.part("spin.rr", pivot: V3(-halfTrack, axleY, -halfBase), joint: Joint(.revolute, axis: X, range: 0...360, mimic: Joint.Mimic("spin")))
        rig.part("spin.fl", parent: "steer", pivot: V3(halfTrack, axleY, halfBase), joint: Joint(.revolute, axis: X, range: 0...360, mimic: Joint.Mimic("spin")))
        rig.part("spin.fr", parent: "steer.right", pivot: V3(-halfTrack, axleY, halfBase), joint: Joint(.revolute, axis: X, range: 0...360, mimic: Joint.Mimic("spin")))

        for l in 0..<2 {
            let lo = l...l, hi = l == 0
            let sides = hi ? 8 : 5
            func pipe(_ pts: [V3], _ r: Float, _ mat: MaterialKey, to part: String) {
                rig.add(HK.pipe(pts, r: r, sides: hi ? max(sides, 8) : 5, mat: mat), to: part, lods: lo)
            }

            // MARK: static chassis (axles, differentials, driveshafts).
            for (zs, _) in [(halfBase, 0), (-halfBase, 0)] {
                rig.base[l].add(HK.cyl(r: 0.17, len: 2 * halfTrack - tireWidth + 0.2, at: V3(0, axleY, zs), axis: X, mat: "metal.painted:1A1B1C", seg: hi ? 16 : 8), .identity)
                rig.base[l].add(Prim.superellipsoid(V3(0.7, 0.62, 0.62), exponent: 3, subdivisions: hi ? 2 : 1, material: "metal.painted:1A1B1C"), Xform(translation: V3(0, axleY, zs + (zs > 0 ? 0.08 : -0.08))))
            }
            rig.base[l].add(HK.cyl(r: 0.07, len: 2 * halfBase, at: V3(0, axleY + 0.05, 0), axis: Z, mat: "metal.steel", seg: hi ? 12 : 6), .identity)

            // MARK: tube frame (pitch): rails, cross members, four-link bars, bumper hoops.
            for sx: Float in [-1, 1] {
                pipe([V3(sx * 0.55, 0.3, -2.7), V3(sx * 0.55, 0.3, 2.7)], 0.09, tint, to: "pitch")
                pipe([V3(sx * 0.55, 0.3, 2.7), V3(sx * 0.55, 0.62, 3.0)], 0.07, tint, to: "pitch")
                pipe([V3(sx * 0.55, 0.3, -2.7), V3(sx * 0.55, 0.62, -3.0)], 0.07, tint, to: "pitch")
                pipe([V3(sx * 0.55, 0.62, 3.0), V3(sx * 0.35, 0.62, 3.1), V3(sx * 0.0, 0.62, 3.1)], 0.07, "metal.chrome", to: "pitch")
                pipe([V3(sx * 0.55, 0.62, -3.0), V3(sx * 0.35, 0.62, -3.1), V3(0, 0.62, -3.1)], 0.07, "metal.chrome", to: "pitch")
                for (zs, dir) in [(halfBase, Float(-1)), (-halfBase, Float(1))] {
                    for dy: Float in [0.0, 0.32] {
                        pipe([V3(sx * 0.5, axleY + 0.05 + dy, zs), V3(sx * 0.55, 0.3 + dy * 0.1, zs + dir * 1.0)], 0.05, tint, to: "pitch")
                    }
                }
                // Nerf bars and body mounts.
                pipe([V3(sx * 1.0, 1.3, -2.0), V3(sx * 1.0, 1.3, 2.0)], 0.05, "metal.chrome", to: "pitch")
                pipe([V3(sx * 0.55, 0.3, -1.0), V3(sx * 0.95, 1.3, -1.0)], 0.05, tint, to: "pitch")
                pipe([V3(sx * 0.55, 0.3, 1.0), V3(sx * 0.95, 1.3, 1.0)], 0.05, tint, to: "pitch")
            }
            for z in [-2.2, -0.4, 1.4, 2.5] as [Float] {
                pipe([V3(-0.55, 0.3, z), V3(0.55, 0.3, z)], 0.06, tint, to: "pitch")
            }

            // MARK: coilover shocks: chrome body and spring on pitch, rod on suspension.
            for (_, sx, sz) in axles {
                let x = sx * 0.78, z = sz * (halfBase - 0.35)
                rig.add(HK.cyl(r: 0.08, len: 0.7, at: V3(x, 0.7, z), axis: Y, mat: "metal.chrome", seg: hi ? 16 : 8), to: "pitch", lods: lo)
                rig.add(HK.cyl(r: 0.11, len: 0.12, at: V3(x, 1.08, z), axis: Y, mat: "metal.painted:C9A227", seg: hi ? 16 : 8), to: "pitch", lods: lo)
                rig.add(HK.cyl(r: 0.045, len: 0.9, at: V3(x, axleY + 0.45, z), axis: Y, mat: "metal.chrome", seg: hi ? 16 : 8), to: "suspension", lods: lo)
                if hi {
                    let helix = (0...20).map { i -> V3 in
                        let t = Float(i) / 20, a = t * 2.5 * 2 * .pi
                        return V3(x + 0.15 * cos(a), 0.4 + 0.65 * t, z + 0.15 * sin(a))
                    }
                    pipe(helix, 0.018, "metal.painted:D9B21E", to: "pitch")
                }
            }

            // MARK: fibreglass pickup body.
            rig.add(HK.box(V3(2.0, 0.7, 5.8), V3(0, 1.65, 0), paint, r: 0.2, seg: hi ? 3 : 1), to: "pitch", lods: lo)
            rig.add(HK.box(V3(1.9, 0.32, 1.7), V3(0, 2.15, 1.95), paint, r: 0.1, seg: hi ? 2 : 1), to: "pitch", lods: lo)
            rig.add(HK.box(V3(0.5, 0.12, 0.7), V3(0, 2.38, 2.0), "plastic.matte:1A1B1C", r: 0.04, seg: 1), to: "pitch", lods: lo)
            rig.add(Prim.superellipsoid(V3(1.9, 1.05, 2.1), exponent: 4.5, subdivisions: hi ? 3 : 2, material: paint), Xform(translation: V3(0, 2.75, -0.45)), to: "pitch", lods: lo)
            rig.add(HK.box(V3(1.5, 0.5, 0.05), V3(0, 2.95, 0.6), "glass.tinted", r: 0.02, seg: 1, rot: simd_quatf(angle: -0.45, axis: X)), to: "pitch", lods: lo)
            rig.add(HK.box(V3(1.5, 0.42, 0.05), V3(0, 2.95, -1.5), "glass.tinted", r: 0.02, seg: 1, rot: simd_quatf(angle: 0.35, axis: X)), to: "pitch", lods: lo)
            for sx: Float in [-1, 1] {
                rig.add(HK.box(V3(0.05, 0.42, 1.3), V3(sx * 0.93, 2.95, -0.45), "glass.tinted", r: 0.02, seg: 1), to: "pitch", lods: lo)
                // Chrome grille, headlamps, bed rails and wheel-arch flares.
                rig.add(HK.box(V3(0.3, 0.26, 0.06), V3(sx * 0.65, 2.1, 2.82), "emissive.signal-white", r: 0.02, seg: 1), to: "pitch", lods: lo)
                rig.add(HK.box(V3(0.08, 0.5, 1.9), V3(sx * 0.96, 2.2, -2.0), paint, r: 0.03, seg: 1), to: "pitch", lods: lo)
                rig.add(HK.box(V3(0.22, 0.06, 1.7), V3(sx * 0.99, 1.9, 1.2), "plastic.matte:1A1B1C", r: 0.02, seg: 1), to: "pitch", lods: lo)
                rig.add(HK.box(V3(0.14, 0.2, 0.05), V3(sx * 0.9, 1.75, -2.93), "emissive.signal-red", r: 0.01, seg: 1), to: "pitch", lods: lo)
            }
            rig.add(HK.box(V3(1.4, 0.45, 0.07), V3(0, 1.95, 2.84), "metal.chrome", r: 0.03, seg: 1), to: "pitch", lods: lo)
            rig.add(HK.box(V3(1.25, 0.32, 0.05), V3(0, 1.95, 2.88), "plastic.gloss:0E0F10", r: 0.01, seg: 1), to: "pitch", lods: lo)
            rig.add(HK.box(V3(1.9, 0.5, 0.08), V3(0, 2.2, -2.95), paint, r: 0.03, seg: 1), to: "pitch", lods: lo)

            // MARK: flame livery tongues (outer orange, inner yellow) on both flanks.
            let count = hi ? 5 : 3
            for sx: Float in [-1, 1] {
                for (mat, scale) in [(flameOrange, Float(1)), (flameYellow, 0.62)] {
                    for k in 0..<count {
                        let f = Float(k) / Float(count), jitter = 0.12 * sin(Float(k) * 2.3 + wob * 6)
                        let len = (0.9 + 0.5 * (1 - f) + jitter) * scale
                        let z0 = 2.7 - Float(k) * (hi ? 1.0 : 1.6)
                        let y0 = 1.5 + 0.1 * scale
                        let path = (0..<6).map { i -> V3 in
                            let t = Float(i) / 5
                            return V3(sx * 1.002, y0 + 0.28 * t * t * scale + 0.06 * sin(t * 5 + Float(k)) * scale, z0 - len * t)
                        }
                        let radii = (0..<6).map { i -> Float in 0.085 * scale * (1 - Float(i) / 5) + 0.004 }
                        rig.add(Prim.tube(path, radii: radii, sides: hi ? 5 : 4, seamTile: 0.2, material: mat), to: "pitch", lods: lo)
                    }
                }
            }

            // MARK: rollcage, roof light bar, exhaust stacks.
            for z in [0.5, -1.4] as [Float] {
                pipe([V3(-0.9, 2.3, z), V3(-0.85, 3.1, z), V3(0.85, 3.1, z), V3(0.9, 2.3, z)], 0.04, tint, to: "pitch")
            }
            pipe([V3(-0.85, 3.1, 0.5), V3(-0.85, 3.1, -1.4)], 0.04, tint, to: "pitch")
            pipe([V3(0.85, 3.1, 0.5), V3(0.85, 3.1, -1.4)], 0.04, tint, to: "pitch")
            rig.add(HK.box(V3(1.7, 0.22, 0.24), V3(0, 3.42, 0.15), "plastic.gloss:121314", r: 0.05, seg: 1), to: "pitch", lods: lo)
            for k in 0..<6 {
                rig.add(cuboid(V3(0.22, 0.16, 0.05), material: "emissive.signal-white"), Xform(translation: V3(-0.65 + Float(k) * 0.26, 3.42, 0.285)), to: "pitch", lods: lo)
            }
            for sx: Float in [-1, 1] {
                pipe([V3(sx * 0.6, 3.15, 0.15), V3(sx * 0.6, 3.32, 0.15)], 0.03, "metal.chrome", to: "pitch")
                pipe([V3(sx * 1.05, 1.4, -1.5), V3(sx * 1.08, 2.5, -1.5), V3(sx * 1.08, 3.55, -1.55)], 0.1, "metal.chrome", to: "pitch")
                rig.add(HK.cyl(r: 0.14, len: 0.18, at: V3(sx * 1.08, 3.55, -1.55), axis: Y, mat: "metal.chrome", seg: hi ? 24 : 10), to: "pitch", lods: lo)
            }
        }

        // MARK: wheels.
        Self.addWheel(&rig, "spin", hub: V3(halfTrack, axleY, -halfBase), side: 1, self)
        Self.addWheel(&rig, "spin.rr", hub: V3(-halfTrack, axleY, -halfBase), side: -1, self)
        Self.addWheel(&rig, "spin.fl", hub: V3(halfTrack, axleY, halfBase), side: 1, self)
        Self.addWheel(&rig, "spin.fr", hub: V3(-halfTrack, axleY, halfBase), side: -1, self)
        for (part, sx) in [("steer", Float(1)), ("steer.right", -1)] {
            for l in 0..<2 {
                rig.add(HK.box(V3(0.28, 0.55, 0.42), V3(sx * (halfTrack - tireWidth / 2 - 0.1), axleY, halfBase), "metal.painted:1A1B1C", r: 0.04, seg: 1), to: part, lods: l...l)
            }
        }

        rig.lights.append(RigLight(name: "headlamp.left", kind: .spot(inner: 18, outer: 42), part: "pitch", position: V3(0.65, 2.1, 2.9), direction: V3(0, -0.08, 1),
                                   color: V3(1, 0.95, 0.85), intensity: 3000, attenuationRadius: 30))
        rig.lights.append(RigLight(name: "headlamp.right", kind: .spot(inner: 18, outer: 42), part: "pitch", position: V3(-0.65, 2.1, 2.9), direction: V3(0, -0.08, 1),
                                   color: V3(1, 0.95, 0.85), intensity: 3000, attenuationRadius: 30))
        rig.lights.append(RigLight(name: "roofbar", part: "pitch", position: V3(0, 3.5, 0.6), direction: V3(0, 0, 1),
                                   color: V3(1, 0.97, 0.9), intensity: 1800, attenuationRadius: 12))

        groundAO(&rig, height: 0.3)
        rig.states = [
            RigState("parked"),
            RigState("steer-left", ["steer": 30]),
            RigState("steer-right", ["steer": -30]),
            RigState("compressed", ["suspension": 0.4]),
            RigState("nose-up", ["pitch": 25, "suspension": 0.1]),
            RigState("nose-down", ["pitch": -25, "suspension": 0.3]),
        ]
        return rig
    }

    /// One tread-block tyre on a beadlock rim, built around the hub with its axis along X.
    private static func addWheel(_ rig: inout Rig, _ part: String, hub: V3, side: Float, _ s: MonsterTruck) {
        let R = s.tireRadius, hw = s.tireWidth / 2
        let flipX = simd_quatf(angle: .pi / 2, axis: V3(0, 0, 1))
        for l in 0..<2 {
            let hi = l == 0, lo = l...l
            let seg = hi ? 48 : 24, lugs = hi ? 48 : 24
            // Carcass: sidewall bulge, shoulder radii, flat crown under the lugs.
            let profile: [V2] = [V2(0.66, -hw), V2(R * 0.72, -hw - 0.02), V2(R * 0.9, -hw + 0.02), V2(R - 0.06, -hw + 0.1), V2(R - 0.02, -hw + 0.2),
                                 V2(R - 0.02, hw - 0.2), V2(R - 0.06, hw - 0.1), V2(R * 0.9, hw - 0.02), V2(R * 0.72, hw + 0.02), V2(0.66, hw)]
            rig.add(Prim.lathe(profile, segments: seg, seamTile: 0.25, material: "rubber.truck-tire"), Xform(translation: hub, rotation: flipX), to: part, lods: lo)
            // Rim: dished disc with a chrome lip.
            let rim: [V2] = [V2(0, -hw + 0.08), V2(0.5, -hw + 0.08), V2(0.66, -hw + 0.02), V2(0.66, hw - 0.02), V2(0.5, hw - 0.08), V2(0, hw - 0.08)]
            rig.add(Prim.lathe(rim, segments: hi ? 32 : 16, seamTile: 0.25, material: "metal.painted:1A1B1C"), Xform(translation: hub, rotation: flipX), to: part, lods: lo)
            rig.add(Prim.lathe([V2(0.6, hw - 0.02), V2(0.69, hw - 0.04), V2(0.69, hw - 0.1), V2(0.6, hw - 0.1)], segments: hi ? 32 : 16, seamTile: 0.25, material: "metal.chrome"),
                    Xform(translation: V3(0, 0, 0) + hub, rotation: flipX), to: part, lods: lo)
            for k in 0..<(hi ? 8 : 4) {
                let a = Float(k) / Float(hi ? 8 : 4) * 2 * .pi, r: Float = 0.58
                rig.add(HK.cyl(r: 0.035, len: 0.06, at: hub + V3(side * (hw - 0.07), r * cos(a), r * sin(a)), axis: V3(1, 0, 0), mat: "metal.chrome", seg: 6), to: part, lods: lo)
            }
            // Tread blocks: one lug per step around the crown, 48 radial positions.
            for k in 0..<lugs {
                let a = Float(k) / Float(lugs) * 2 * .pi, r = R + 0.03
                rig.add(cuboid(V3(2 * hw - 0.2, 0.12, hi ? 0.11 : 0.2), material: "rubber.truck-tire"),
                        Xform(translation: hub + V3(0, r * cos(a), r * sin(a)), rotation: simd_quatf(angle: a, axis: V3(1, 0, 0))), to: part, lods: lo)
            }
        }
    }
}
