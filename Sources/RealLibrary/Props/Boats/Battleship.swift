import simd
import Foundation

/// Battleship, 60 m stem to stern at 1:1 hull scale: lofted hull of 64 station intervals with a flared, raked
/// bow and clipper stern (haze grey topsides, red boot-topping and anti-fouling, rust streaks under the hawse
/// pipes and scuppers), steel deck, deck rails with stanchions, anchors, a tiered tower bridge with glazing, a mast
/// with a rotating radar dish, an oval raked funnel and three twin turrets (two forward, one aft superfiring
/// on a raised barbette) with 48-sided barrels. Origin at the waterline amidships, bow toward +Z, port = +X.
/// Keel at y = -3.2, deck 3.6 m amidships. 2 LODs.
///
/// Articulation: `turret` -1...1 yaws every turret 60 degrees, `elevate` 0...1 lifts every barrel pair 0 to 40
/// degrees, `recoil` 0...1 slides barrels back 1.2 m, `radar` 0...1 turns the radar dish one revolution.
public struct Battleship: RealArticulated {
    public static let id = "battleship"
    public static let summary = "60 m battleship: lofted flared hull, tower bridge with radar, three twin turrets with 48-sided barrels, funnel, rails and anchors."
    public static let tags = ["prop", "vehicle", "boat", "harbor", "outdoor", "metal", "articulated"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 48, elevation: 12, distance: 1.1)

    /// Half length of the hull (m).
    public var halfLength: Float = 30
    /// Half beam amidships (m).
    public var halfBeam: Float = 4.6
    /// Keel depth below the waterline amidships (m).
    public var draft: Float = 3.2
    /// Radial segments of every gun barrel at LOD0.
    public var barrelSides = 48
    /// Topsides, haze grey navy paint.
    public var hullGrey: MaterialKey = "metal.painted:6F767B"
    /// Superstructure and turrets, lighter grey.
    public var superGrey: MaterialKey = "metal.painted:858C90"
    /// Boot-topping and anti-fouling.
    public var bootRed: MaterialKey = "metal.painted:7B1D17"
    /// Weathered deck planking.
    public var deck: MaterialKey = "wood.weathered"
    /// Rust streaks.
    public var rust: MaterialKey = "metal.rust"
    /// Funnel soot cap, rails and fittings.
    public var iron: MaterialKey = "metal.iron"
    /// Barrel steel.
    public var barrelSteel: MaterialKey = "metal.blued-steel"
    /// Bridge glazing.
    public var glass: MaterialKey = "glass.tinted"
    public init() {}

    static let elevMax: Float = 40
    static let recoilMax: Float = 1.2
    static let yawMax: Float = 60
    static let radarPivot = V3(0, 22.2, 2.5)

    // MARK: Hull shape (t = z / halfLength, v = 0 keel ... 1 sheer)

    func widthAt(_ t: Float) -> Float {
        let a = abs(t)
        let f: Float = t >= 0 ? pow(max(0, 1 - pow(a, 2.2)), 0.7) : pow(max(0, 1 - pow(a, 3.0)), 0.55)
        return max(0.02, halfBeam * f)
    }
    func sheerY(_ t: Float) -> Float { 3.6 + 2.0 * pow(max(t, 0), 2.4) + 0.5 * pow(max(-t, 0), 2.6) }
    func keelY(_ t: Float) -> Float {
        let rise: Float = t >= 0 ? 2.9 * pow(smoothstep(0.45, 1, t), 1.6) : 2.2 * pow(smoothstep(0.6, 1, -t), 1.6)
        return -draft + rise
    }
    func hullPoint(_ t: Float, _ v: Float, _ side: Float, off: Float = 0) -> V3 {
        let k = keelY(t), h = sheerY(t) - k
        let flare = 1 + 0.22 * smoothstep(0.1, 0.9, t) * smoothstep(0.45, 1, v)
        let x = side * (widthAt(t) * pow(max(v, 0), 0.3) * flare + off)
        return V3(x, k + v * h, t * halfLength)
    }
    func vSplit(_ t: Float) -> Float {
        let k = keelY(t)
        return min(0.98, max(0.02, (0.3 - k) / (sheerY(t) - k)))
    }
    func stations(_ n: Int) -> [Float] {
        (0...n).map { i in let s = Float(i) / Float(n) * 2 - 1; return 0.5 * s + 0.5 * sin(s * .pi / 2) }
    }
    func rad(_ d: Float) -> Float { d * .pi / 180 }

    func orient(_ s: inout Surface, _ center: (V3) -> V3) {
        WoodParts.orientOutward(&s, center: center)
        s.recomputeNormals(weldSeams: false)
        s.computeTangents()
    }

    // MARK: Rig

    public func rig(seed: UInt64) -> Rig {
        var rng = SeededRNG(seed: seed)
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [60])
        let X = V3(1, 0, 0), Y = V3(0, 1, 0), Z = V3(0, 0, 1)
        let L = halfLength

        // Drivers first so mimics resolve.
        _ = rig.part("turret", pivot: .zero, joint: .hinge(axis: Y, -1...1, duration: 3.0))
        _ = rig.part("elevate", pivot: .zero, joint: .hinge(axis: Y, 0...1, duration: 2.5))
        _ = rig.part("recoil", pivot: .zero, joint: .hinge(axis: Y, 0...1, duration: 0.5))
        _ = rig.part("radar", pivot: .zero, joint: .hinge(axis: Y, 0...1, duration: 6.0))

        // Turret layout: (name, z, barbette height above deck).
        struct Mount { var z: Float; var lift: Float; var deckY: Float; var center: V3; var trunnion: V3 }
        func mount(_ z: Float, _ lift: Float) -> Mount {
            let dy = sheerY(z / L)
            let c = V3(0, dy + lift, z)
            return Mount(z: z, lift: lift, deckY: dy, center: c, trunnion: c + V3(0, 1.25, 2.2))
        }
        let mounts = [mount(19, 0.7), mount(11.5, 2.2), mount(-15, 0.7)]
        for (i, mt) in mounts.enumerated() {
            let n = i + 1
            _ = rig.part("turret\(n)", pivot: mt.center, joint: Joint(.revolute, axis: Y, range: -Self.yawMax...Self.yawMax, mimic: .init("turret", ratio: Self.yawMax)))
            _ = rig.part("elev\(n)", parent: "turret\(n)", pivot: mt.trunnion,
                         joint: Joint(.revolute, axis: X, range: -Self.elevMax...0, mimic: .init("elevate", ratio: -Self.elevMax)))
            _ = rig.part("guns\(n)", parent: "elev\(n)", pivot: mt.trunnion,
                         joint: Joint(.prismatic, axis: Z, range: -Self.recoilMax...0, mimic: .init("recoil", ratio: -Self.recoilMax)))
        }
        _ = rig.part("radarDish", pivot: Self.radarPivot, joint: Joint(.revolute, axis: Y, range: 0...360, mimic: .init("radar", ratio: 360)))

        for l in 0..<2 {
            let hi = l == 0
            var m = Model(name: Self.id)

            // MARK: Hull plating, boot-topping and deck.
            let ts = stations(hi ? 64 : 24)
            for side: Float in [1, -1] {
                for lower in [true, false] {
                    var rows: [[V3]] = [], uvs: [[V2]] = []
                    let cols = lower ? (hi ? 4 : 3) : (hi ? 6 : 4)
                    for t in ts {
                        let vs = vSplit(t)
                        var r: [V3] = [], u: [V2] = []
                        for j in 0..<cols {
                            let f = Float(j) / Float(cols - 1)
                            let v = lower ? vs * f : vs + (1 - vs) * f
                            let p = hullPoint(t, v, side)
                            r.append(p)
                            u.append(V2(p.z, p.y * 0.8 + (side > 0 ? 0 : 7)))
                        }
                        rows.append(r); uvs.append(u)
                    }
                    var s = WoodParts.grid(rows, uvs: uvs, material: lower ? bootRed : hullGrey)
                    orient(&s) { p in V3(0, 1.0, p.z) }
                    m.add(s)
                }
            }
            do {
                var rows: [[V3]] = [], uvs: [[V2]] = []
                let cols = hi ? 5 : 3
                for t in ts {
                    let hw = hullPoint(t, 1, 1).x, y = sheerY(t)
                    var r: [V3] = [], u: [V2] = []
                    for j in 0..<cols {
                        let x = -hw + 2 * hw * Float(j) / Float(cols - 1)
                        r.append(V3(x, y, t * L)); u.append(V2(t * L, x))
                    }
                    rows.append(r); uvs.append(u)
                }
                var s = WoodParts.grid(rows, uvs: uvs, material: deck)
                orient(&s) { p in V3(0, p.y - 6, p.z) }
                m.add(s)
            }

            // MARK: Rust streaks under hawse pipes and scuppers.
            if hi {
                for side: Float in [1, -1] {
                    for _ in 0..<16 {
                        let t = rng.float(-0.9...0.88)
                        let drop = rng.float(0.12...0.3)
                        let dt = rng.float(0.004...0.009)
                        var rows: [[V3]] = [], uvs: [[V2]] = []
                        for i in 0...3 {
                            let f = Float(i) / 3
                            let v = 0.995 - drop * f, k = 1 - 0.6 * f
                            var r: [V3] = [], u: [V2] = []
                            for (c, o) in [(Float(-1), Float(0.012)), (0, 0.02), (1, 0.012)] {
                                let p = hullPoint(t + c * dt * k, v, side, off: o)
                                r.append(p); u.append(V2(c * 0.4, f * 2))
                            }
                            rows.append(r); uvs.append(u)
                        }
                        var s = WoodParts.grid(rows, uvs: uvs, material: rust)
                        orient(&s) { p in V3(0, 1.0, p.z) }
                        m.add(s)
                    }
                }
            }

            // MARK: Deck rails and stanchions.
            do {
                let n = hi ? 24 : 10
                for side: Float in [1, -1] {
                    let pts = stations(n).map { t -> V3 in
                        let tt = t * 0.88
                        var p = hullPoint(tt, 1, side, off: -0.12); p.y = sheerY(tt)
                        return p
                    }
                    for h: Float in hi ? [0.5, 1.0] : [1.0] {
                        let path = pts.map { $0 + V3(0, h, 0) }
                        m.add(Prim.tube(path, radii: path.map { _ in 0.035 }, sides: hi ? 5 : 4, seamTile: 0.1, material: iron, capEnd: true))
                    }
                    if hi {
                        for i in stride(from: 0, to: pts.count, by: 2) {
                            m.add(Prim.tube([pts[i], pts[i] + V3(0, 1.0, 0)], radii: [0.04, 0.04], sides: 4, seamTile: 0.1, material: iron, capEnd: true))
                        }
                    }
                }
            }

            // MARK: Anchors and hawse pipes, capstan and bollards.
            if hi {
                for side: Float in [1, -1] {
                    let a = hullPoint(0.72, 0.8, side, off: 0.1)
                    m.add(Prim.tube([a, a + V3(0, -1.6, 0)], radii: [0.09, 0.09], sides: 8, seamTile: 0.1, material: iron, capEnd: true))
                    m.add(Prim.tube([a + V3(-0.5, -0.3, 0), a + V3(0.5, -0.3, 0)], radii: [0.05, 0.05], sides: 6, seamTile: 0.1, material: iron, capEnd: true))
                    for sx: Float in [-1, 1] {
                        m.add(Prim.tube([a + V3(0, -1.6, 0), a + V3(sx * 0.55, -1.25, 0)], radii: [0.08, 0.05], sides: 6, seamTile: 0.1, material: iron, capEnd: true))
                    }
                    let hp = hullPoint(0.72, 0.82, side, off: 0.015)
                    m.add(Prim.lathe([V2(0.001, 0), V2(0.2, 0.01), V2(0.18, 0.04), V2(0.001, 0.05)], segments: 16, seamTile: 0.2, material: iron),
                          Xform(translation: hp, rotation: simd_quatf(angle: rad(-side * 90), axis: Z)))
                }
                m.add(Prim.lathe([V2(0.5, 0), V2(0.42, 0.5), V2(0.55, 0.65), V2(0.55, 0.8), V2(0.001, 0.8)], segments: 24, seamTile: 0.3, material: iron),
                      Xform(translation: V3(0, sheerY(0.85), 0.85 * L)))
                for (z, sx) in [(Float(24), Float(-1)), (24, 1), (-22, -1), (-22, 1)] {
                    m.add(Prim.lathe([V2(0.18, 0), V2(0.12, 0.2), V2(0.2, 0.34), V2(0.001, 0.36)], segments: 12, seamTile: 0.2, material: iron),
                          Xform(translation: V3(sx * 2.3, sheerY(z / L), z)))
                }
            }

            // MARK: Tower bridge.
            do {
                let cz: Float = 3.0, d0 = sheerY(cz / L)
                func box(_ size: V3, _ c: V3) {
                    m.add(Prim.roundedBox(size, radius: 0.12, bevelSegments: 1, material: superGrey), Xform(translation: c))
                }
                box(V3(6.6, 4.2, 8.0), V3(0, d0 + 2.1, cz))
                box(V3(5.6, 3.2, 6.4), V3(0, d0 + 4.2 + 1.6, cz))
                box(V3(6.8, 1.9, 5.4), V3(0, d0 + 7.4 + 0.95, cz))
                box(V3(4.2, 1.6, 3.6), V3(0, d0 + 9.3 + 0.8, cz))
                let g = V3(5.9, 0.7, 0.06)
                m.add(cuboid(g, material: glass), Xform(translation: V3(0, d0 + 8.35, cz + 2.72)))
                m.add(cuboid(V3(3.8, 0.6, 0.06), material: glass), Xform(translation: V3(0, d0 + 10.1, cz + 1.83)))
                if hi {
                    for k in 0..<4 {
                        let x = -2.1 + Float(k) * 1.4
                        m.add(cuboid(V3(0.7, 0.6, 0.06), material: glass), Xform(translation: V3(x, d0 + 5.8, cz + 3.23)))
                        m.add(cuboid(V3(0.7, 0.6, 0.06), material: glass), Xform(translation: V3(x, d0 + 2.4, cz + 4.03)))
                    }
                }
                let mz = Self.radarPivot.z
                let top = d0 + 10.9
                let path = [V3(0, top, mz), V3(0, top + 4.5, mz), V3(0, 22.2, mz)]
                m.add(Prim.tube(path, radii: [0.35, 0.25, 0.14], sides: hi ? 12 : 6, seamTile: 0.5, material: iron, capEnd: true))
                m.add(Prim.tube([V3(-2.0, 21.0, mz), V3(2.0, 21.0, mz)], radii: [0.06, 0.06], sides: hi ? 8 : 4, seamTile: 0.2, material: iron, capEnd: true))
                m.add(Prim.tube([V3(0, 22.2, mz), V3(0, 25.0, mz)], radii: [0.09, 0.03], sides: hi ? 8 : 4, seamTile: 0.2, material: iron, capEnd: true))
            }

            // MARK: Funnel.
            do {
                let c = V3(0, sheerY(-5.5 / L), -5.5)
                let prof: [V2] = [V2(1.9, 0), V2(1.7, 3.0), V2(1.4, 6.0), V2(1.4, 6.4), V2(0.001, 6.4)]
                m.add(Prim.lathe(prof, segments: hi ? 40 : 16, seamTile: 0.5, material: superGrey),
                      Xform(translation: c, rotation: simd_quatf(angle: rad(-8), axis: X), scale: V3(1, 1, 1.5)))
                m.add(Prim.lathe([V2(1.45, 5.3), V2(1.5, 5.3), V2(1.5, 6.45), V2(1.0, 6.45), V2(0.001, 6.4)], segments: hi ? 40 : 16, seamTile: 0.5, material: iron),
                      Xform(translation: c, rotation: simd_quatf(angle: rad(-8), axis: X), scale: V3(1, 1, 1.5)))
            }

            // MARK: Turret barbettes (static).
            for mt in mounts {
                let r: Float = 2.7
                m.add(Prim.lathe([V2(r + 0.2, mt.deckY), V2(r, mt.deckY + 0.15), V2(r, mt.center.y + 0.05), V2(r - 0.1, mt.center.y + 0.1)],
                                 segments: hi ? 48 : 20, seamTile: 0.5, material: superGrey))
            }
            rig.base[l] = m

            // MARK: Turrets, cradles and barrels.
            for (i, mt) in mounts.enumerated() {
                let n = i + 1
                let c = mt.center
                rig.add(Prim.superellipsoid(V3(5.0, 2.4, 6.2), exponent: 5, subdivisions: hi ? 5 : 3, material: superGrey),
                        Xform(translation: c + V3(0, 1.2, 0)), to: "turret\(n)", lods: l...l)
                rig.add(Prim.lathe([V2(0.001, 0), V2(1.2, 0.0), V2(1.2, 0.08), V2(0.001, 0.08)], segments: hi ? 24 : 10, seamTile: 0.3, material: iron),
                        Xform(translation: c + V3(0.0, 2.4, -1.0)), to: "turret\(n)", lods: l...l)
                let tr = mt.trunnion
                rig.add(cuboid(V3(2.9, 1.1, 0.8), material: superGrey), Xform(translation: tr + V3(0, 0, 1.0)), to: "elev\(n)", lods: l...l)
                for sx: Float in [-0.85, 0.85] {
                    let p0 = tr + V3(sx, 0, -1.0)
                    let path = [p0, tr + V3(sx, 0, 1.9), tr + V3(sx, 0, 5.5), tr + V3(sx, 0, 9.5)]
                    rig.add(Prim.tube(path, radii: [0.46, 0.4, 0.33, 0.27], sides: hi ? barrelSides : 20, seamTile: 0.6, material: barrelSteel, capEnd: true),
                            to: "guns\(n)", lods: l...l)
                    rig.add(Prim.tube([tr + V3(sx, 0, 8.6), tr + V3(sx, 0, 9.9)], radii: [0.33, 0.33], sides: hi ? barrelSides : 20, seamTile: 0.6, material: iron, capEnd: true),
                            to: "guns\(n)", lods: l...l)
                }
            }

            // MARK: Radar dish and pedestal (rotates about the mast).
            let rp = Self.radarPivot
            rig.add(Prim.tube([rp, rp + V3(0, 0.9, 0)], radii: [0.22, 0.18], sides: hi ? 10 : 6, seamTile: 0.3, material: iron, capEnd: true), to: "radarDish", lods: l...l)
            let dish: [V2] = [V2(0.001, 0), V2(0.6, 0.07), V2(1.2, 0.3), V2(1.9, 0.75), V2(1.93, 0.78), V2(1.25, 0.35), V2(0.6, 0.11), V2(0.001, 0.04)]
            rig.add(Prim.lathe(dish, segments: hi ? 32 : 14, seamTile: 0.5, material: superGrey),
                    Xform(translation: rp + V3(0, 1.9, 0.35), rotation: simd_quatf(angle: rad(90), axis: X)), to: "radarDish", lods: l...l)
            rig.add(Prim.tube([rp + V3(0, 1.9, 0.35), rp + V3(0, 1.9, 1.5)], radii: [0.05, 0.05], sides: hi ? 6 : 4, seamTile: 0.1, material: iron, capEnd: true), to: "radarDish", lods: l...l)
        }

        rig.lights.append(RigLight(name: "masthead", position: V3(0, 25.0, Self.radarPivot.z), color: V3(1, 0.95, 0.85), intensity: 300, attenuationRadius: 10))

        rig.states = [
            RigState("stowed", ["turret": 0, "elevate": 0, "recoil": 0, "radar": 0]),
            RigState("slew-port", ["turret": 1, "elevate": 0.3, "radar": 0.25]),
            RigState("slew-starboard", ["turret": -1, "elevate": 0.3, "radar": 0.75]),
            RigState("elevated", ["turret": 0, "elevate": 1, "radar": 0.5]),
            RigState("fire", ["turret": 0, "elevate": 0.6, "recoil": 1, "radar": 0.5]),
        ]
        return rig
    }
}
