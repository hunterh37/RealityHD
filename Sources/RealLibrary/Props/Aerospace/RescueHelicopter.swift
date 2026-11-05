import simd
import Foundation

/// Orange and white search and rescue helicopter, 15.8 m fuselage (nose z +6.4, tail z -9.4) under a 14 m, five blade main rotor,
/// four blade tail rotor, skids, wraparound cockpit glass, chin searchlight with an emissive lens, sliding cargo door and a hoist
/// boom with a 12 m telescoping cable and rescue basket. Origin at the fuselage centre, nose +Z, up +Y, right side (+X) carries
/// the door and hoist.
/// Joints: `rotor` 0...1 (main rotor one turn, tail rotor three turns), `light` -1...1 (searchlight yaw +-45 degrees, positive
/// swings toward +X), `hoist` 0...1 (cable pays out 0 to 12 m, basket follows), `door` 0...1 (door slides 1.5 m aft) and `pitch`
/// -1...1 (whole airframe, positive is nose down, 10 degrees each way).
public struct RescueHelicopter: RealArticulated {
    public static let id = "rescue-helicopter"
    public static let summary = "Orange and white rescue helicopter: 5 blade rotor, tail rotor, skids, cockpit glass, searchlight, sliding door, hoist cable with basket and joints rotor, light, hoist, door, pitch."
    public static let tags = ["prop", "vehicle", "aerospace", "helicopter", "rescue", "outdoor", "articulated"]
    public static let budget = 14_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 40, elevation: 16, distance: 1.15, studio: true)

    /// Upper fuselage, cowling, door and tank sponsons (recolour knob).
    public var paint: MaterialKey = "paint.car-clearcoat:F2570A"
    /// Belly, boom underside and tail fin trim.
    public var trim: MaterialKey = "paint.car-clearcoat:EEF1F2"
    /// Cockpit and cabin glass.
    public var glass: MaterialKey = "glass.cabin"
    /// Rotor blades and dark fittings.
    public var blade: MaterialKey = "plastic.matte:17181A"
    /// Cabin interior shadow and seats.
    public var interior: MaterialKey = "plastic.matte:101113"
    /// Hubs, mounts, exhausts and searchlight housing.
    public var hardware: MaterialKey = "metal.anodized-gunmetal"
    /// Skids, hoist boom, basket frame.
    public var frame: MaterialKey = "metal.aluminum"
    /// Hoist cable.
    public var cable: MaterialKey = "metal.steel"
    /// Skid feet.
    public var foot: MaterialKey = "rubber"
    /// Searchlight lens.
    public var lens: MaterialKey = "emissive.signal-white"
    /// Port navigation light (+X side).
    public var navLeft: MaterialKey = "emissive.signal-red"
    /// Starboard navigation light (-X side).
    public var navRight: MaterialKey = "emissive.signal-green"
    /// Tail light.
    public var navTail: MaterialKey = "emissive.signal-white"
    public init() {}

    private static let noseZ: Float = 6.4
    private static let tailZ: Float = -9.4
    private static let hub = V3(0, 2.1, 0)
    private static let tailHub = V3(0.34, 2.05, -9.0)
    private static let lightPivot = V3(0, -0.95, 5.2)
    /// Hoist cable top at rest (inside the drum), cable x and z.
    private static let hoistTop = V3(1.9, 0.6, 0.6)
    private static let cableSegments = 12
    private static let ringN = 48
    private static let exponent: Float = 2.6
    private static let doorZ: ClosedRange<Float> = -2.7 ... -0.3

    private struct Rng {
        var s: UInt64
        mutating func f() -> Float {
            s = s &* 6364136223846793005 &+ 1442695040888963407
            return Float((s >> 40) & 0xFFFFFF) / Float(0x1000000)
        }
    }

    // MARK: Fuselage sections

    /// Station z values, dense near the nose and through the aft blend.
    private static let stations: [Float] = {
        var z: [Float] = []
        for i in 0...9 { z.append(3.0 + 3.4 * cos(Float(i) / 9 * .pi / 2)) }
        z += [2.2, 1.4, 0.6, -0.3, -1.0, -1.7, -2.7, -3.0]
        var t: Float = -3.5
        while t > -9.4 + 0.01 { z.append(t); t -= 0.5 }
        z.append(-9.4)
        return z
    }()

    /// Half width, roof y and floor y at z, plus nose scale.
    private static func section(_ z: Float) -> (a: Float, top: Float, bottom: Float, scale: Float) {
        var a: Float = 1.35, top: Float = 1.25, bottom: Float = -1.15, s: Float = 1
        if z > 3.0 {
            let q = (z - 3.0) / 3.4
            s = max(0.02, sqrt(max(0, 1 - q * q)))
        } else if z < -3.0 {
            let u = smoothstep(0, 1, min(1, (-3.0 - z) / 3.0))
            a = lerp(1.35, 0.46, u); top = lerp(1.25, 1.3, u); bottom = lerp(-1.15, 0.4, u)
            if z < -6.0 {
                let w = min(1, (-6.0 - z) / 3.4)
                a = lerp(0.46, 0.2, w); top = lerp(1.3, 1.15, w); bottom = lerp(0.4, 0.75, w)
            }
        }
        return (a, top, bottom, s)
    }

    private static func spow(_ v: Float) -> Float { (v < 0 ? -1 : 1) * pow(abs(v), 2 / exponent) }

    /// Closed ring at z, counter-clockwise in XY, `grow` inflates the section by a fraction (overlay skins).
    private static func ring(_ z: Float, grow: Float = 0) -> [V3] {
        let sec = section(z)
        let cy = (sec.top + sec.bottom) / 2, hh = (sec.top - sec.bottom) / 2
        return (0..<ringN).map { k in
            let ph = Float(k) / Float(ringN) * 2 * .pi
            let x = sec.a * sec.scale * spow(cos(ph)) * (1 + grow)
            let y = cy * sec.scale + hh * sec.scale * spow(sin(ph)) * (1 + grow)
            return V3(x, y, z)
        }
    }

    /// Open band of a ring set between ring indices `kLo...kHi` (wrapping), over stations `rs`.
    private static func band(_ rings: [[V3]], _ kLo: Int, _ kHi: Int, material: MaterialKey) -> Surface {
        let n = rings[0].count, R = rings.count
        let mid = rings[R / 2]
        let mc = mid.reduce(V3.zero, +) / Float(n)
        var nrm = V3.zero
        for i in 0..<n { nrm += simd_cross(mid[i] - mc, mid[(i + 1) % n] - mc) }
        let c0 = rings[0].reduce(V3.zero, +) / Float(n), c1 = rings[R - 1].reduce(V3.zero, +) / Float(n)
        let flip = simd_dot(nrm, c1 - c0) < 0
        var s = Surface(material: material)
        var ids: [[UInt32]] = []
        var v: Float = 0
        for r in 0..<R {
            if r > 0 { v += simd_distance(rings[r][0], rings[r - 1][0]) }
            var row: [UInt32] = []
            var u: Float = 0
            for k in kLo...kHi {
                let p = rings[r][((k % n) + n) % n]
                if k > kLo { u += simd_distance(p, rings[r][(((k - 1) % n) + n) % n]) }
                row.append(s.add(p, .up, V2(u, v)))
            }
            ids.append(row)
        }
        for r in 0..<(R - 1) {
            for k in 0..<(kHi - kLo) {
                let a = ids[r][k], b = ids[r][k + 1], c = ids[r + 1][k + 1], d = ids[r + 1][k]
                flip ? s.quad(b, a, d, c) : s.quad(a, b, c, d)
            }
        }
        s.recomputeNormals(weldSeams: false)
        s.computeTangents()
        return s
    }

    // MARK: Outlines

    /// Rotor blade planform in XY, root at `root`, tip rounded at `root + len`, slightly broader at the leading edge.
    private static func bladeOutline(root: Float, len: Float, chord: Float, tipChord: Float, n: Int) -> [V2] {
        var low: [V2] = [], high: [V2] = []
        for i in 0...n {
            let t = Float(i) / Float(n)
            let c = lerp(chord, tipChord, t)
            let x = root + len * t
            low.append(V2(x, -c * 0.42))
            high.append(V2(x, c * 0.58))
        }
        let tx = root + len
        let r = tipChord * 0.5
        let cy = (-tipChord * 0.42 + tipChord * 0.58) / 2
        var arc: [V2] = []
        for k in 1..<5 {
            let a = Float(k) / 5 * .pi
            arc.append(V2(tx + sin(a) * r, cy - cos(a) * r))
        }
        return low + arc + high.reversed()
    }

    // MARK: Rig

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [60])
        let X = V3(1, 0, 0), Y = V3(0, 1, 0), Z = V3(0, 0, 1)
        var rng = Rng(s: seed &* 2654435761 &+ 113)

        // Drivers first so mimics resolve.
        _ = rig.part("rotor", pivot: .zero, joint: .hinge(axis: X, 0...1, duration: 3.0))
        _ = rig.part("light", pivot: .zero, joint: .hinge(axis: X, -1...1, duration: 0.8))
        _ = rig.part("hoist", pivot: .zero, joint: .hinge(axis: X, 0...1, duration: 4.0))
        _ = rig.part("door", pivot: .zero, joint: .hinge(axis: X, 0...1, duration: 1.4))
        _ = rig.part("pitch", pivot: .zero, joint: .hinge(axis: X, -1...1, duration: 1.2))

        _ = rig.part("airframe", pivot: V3(0, 0.6, 0), joint: Joint(.revolute, axis: X, range: -12...12, mimic: .init("pitch", ratio: 10)))
        _ = rig.part("mainRotor", parent: "airframe", pivot: Self.hub, joint: Joint(.revolute, axis: Y, range: -360...360, mimic: .init("rotor", ratio: 360)))
        _ = rig.part("tailRotor", parent: "airframe", pivot: Self.tailHub, joint: Joint(.revolute, axis: X, range: -1080...1080, mimic: .init("rotor", ratio: -1080)))
        _ = rig.part("searchlight", parent: "airframe", pivot: Self.lightPivot, joint: Joint(.revolute, axis: Y, range: -45...45, mimic: .init("light", ratio: 45)))
        _ = rig.part("cargoDoor", parent: "airframe", pivot: V3(1.35, 0, -1.5), joint: Joint(.prismatic, axis: -Z, range: 0...1.5, mimic: .init("door", ratio: 1.5)))
        let top = Self.hoistTop
        for k in 0..<Self.cableSegments {
            _ = rig.part("cable\(k)", parent: "airframe", pivot: top,
                         joint: Joint(.prismatic, axis: -Y, range: 0...Float(k + 1), mimic: .init("hoist", ratio: Float(k + 1))))
        }
        _ = rig.part("basket", parent: "airframe", pivot: top, joint: Joint(.prismatic, axis: -Y, range: 0...12, mimic: .init("hoist", ratio: 12)))

        // Rings are shared by every LOD pass; counts differ per LOD through station thinning.
        let allZ = Self.stations
        let blades = Self.bladeOutline(root: 0.95, len: 6.05, chord: 0.36, tipChord: 0.3, n: 12)
        let tailBlade = Self.bladeOutline(root: 0.16, len: 1.15, chord: 0.24, tipChord: 0.17, n: 6)
        let finPts: [V2] = Shape2D.rounded([V2(7.4, 1.22), V2(8.2, 2.5), V2(9.05, 3.05), V2(9.6, 3.0), V2(9.62, 0.95), V2(9.2, 0.8), V2(7.4, 0.8)], radius: 0.14, segments: 4)

        for l in 0..<2 {
            func sg(_ a: Int, _ b: Int) -> Int { l == 0 ? a : b }
            func add(_ s: Surface, _ x: Xform = .identity, to part: String = "airframe", option: Int = 0) {
                rig.add(s, x, to: part, option: option, lods: l...l)
            }
            func cx(_ c: V3, _ h: Float, _ q: simd_quatf = .identity) -> Xform { Xform(translation: c - q.act(V3(0, h / 2, 0)), rotation: q) }
            let zs = l == 0 ? allZ : allZ.enumerated().filter { $0.offset % 2 == 0 || $0.offset == allZ.count - 1 }.map(\.element)

            // Fuselage: orange upper skin, white belly band, shared 48 point rings.
            let rings = zs.map { Self.ring($0) }
            add(Self.band(rings, -4, 28, material: paint))
            add(Self.band(rings, 28, 44, material: trim))

            // Cockpit glass over the nose and front cabin windows (upper arc).
            let glassZ = zs.filter { $0 >= 1.0 && $0 <= 6.3 }
            if glassZ.count >= 2 {
                let gr = glassZ.reversed().map { Self.ring($0, grow: 0.012) }
                add(Self.band(Array(gr), 3, 21, material: glass))
            }
            // Cabin side windows, both sides, forward of the door.
            let winZ = zs.filter { $0 >= -0.2 && $0 <= 1.45 }
            if winZ.count >= 2 {
                let wr = winZ.reversed().map { Self.ring($0, grow: 0.01) }
                add(Self.band(Array(wr), -2, 3, material: glass))
                add(Self.band(Array(wr), 21, 26, material: glass))
            }
            // Dark cabin opening under the door, then the door skin.
            let doorStations = zs.filter { Self.doorZ.contains($0) }
            if doorStations.count >= 2 {
                let dz = doorStations.reversed()
                add(Self.band(dz.map { Self.ring($0, grow: 0.004) }, -4, 5, material: interior))
                let skin = dz.map { Self.ring($0, grow: 0.016) }
                add(Self.band(skin, -4, 5, material: paint), to: "cargoDoor")
                let wz = dz.filter { $0 >= -2.4 && $0 <= -0.7 }
                if wz.count >= 2 { add(Self.band(wz.map { Self.ring($0, grow: 0.022) }, -1, 3, material: glass), to: "cargoDoor") }
                // Handle and rail.
                add(Prim.roundedBox(V3(0.05, 0.05, 0.32), radius: 0.02, bevelSegments: sg(2, 1), material: hardware), Xform(translation: V3(1.4, -0.28, -2.45)), to: "cargoDoor")
                add(Prim.tube([V3(1.37, -0.88, -3.8), V3(1.37, -0.88, 0.0)], radii: [0.025, 0.025], sides: sg(12, 8), seamTile: 0.25, material: hardware, capEnd: true))
            }

            // Tank sponsons low on each side with navigation lights.
            for sx: Float in [1, -1] {
                add(Prim.superellipsoid(V3(0.55, 0.5, 2.1), exponent: 2.6, subdivisions: sg(6, 3), material: trim), Xform(translation: V3(sx * 1.36, -0.78, 1.1)))
                add(Prim.superellipsoid(V3(0.14, 0.14, 0.2), exponent: 2, subdivisions: sg(4, 2), material: sx > 0 ? navLeft : navRight), Xform(translation: V3(sx * 1.4, -0.62, 2.05)))
            }
            add(Prim.superellipsoid(V3(0.2, 0.18, 0.22), exponent: 2, subdivisions: sg(4, 2), material: navTail), Xform(translation: V3(0, 1.1, -9.68)))

            // Flight deck interior seen through the glass.
            for sx: Float in [1, -1] {
                add(Prim.roundedBox(V3(0.55, 0.1, 0.55), radius: 0.04, bevelSegments: sg(2, 1), material: interior), Xform(translation: V3(sx * 0.5, -0.6, 2.7)))
                add(Prim.roundedBox(V3(0.52, 0.85, 0.12), radius: 0.05, bevelSegments: sg(2, 1), material: interior), Xform(translation: V3(sx * 0.5, -0.1, 2.38), rotation: simd_quatf(degrees: -8, axis: X)))
            }
            add(Prim.roundedBox(V3(2.0, 0.34, 0.55), radius: 0.07, bevelSegments: sg(3, 1), material: interior), Xform(translation: V3(0, 0.2, 4.3), rotation: simd_quatf(degrees: -14, axis: X)))

            // Engine cowling, transmission fairing, exhausts.
            add(Prim.superellipsoid(V3(2.15, 0.95, 3.7), exponent: 3, subdivisions: sg(8, 4), material: paint), Xform(translation: V3(0, 1.5, -0.7)))
            add(Prim.superellipsoid(V3(1.2, 0.55, 1.4), exponent: 2.6, subdivisions: sg(6, 3), material: trim), Xform(translation: V3(0, 1.62, 1.35)))
            for sx: Float in [1, -1] {
                add(Prim.cylinder(radius: 0.14, height: 0.7, bevel: 0.02, segments: sg(24, 10), bevelSegments: sg(2, 1), material: hardware),
                    cx(V3(sx * 0.6, 1.75, -2.55), 0.7, simd_quatf(degrees: -105, axis: X)))
            }
            add(Prim.cylinder(radius: 0.22, height: 0.4, bevel: 0.03, segments: sg(32, 14), bevelSegments: sg(2, 1), material: hardware), cx(V3(0, 1.98, 0), 0.4))

            // Boom end: horizontal stabiliser, tail fin, tail gearbox, tail skid.
            add(Prim.roundedBox(V3(3.0, 0.07, 0.85), radius: 0.03, bevelSegments: sg(2, 1), material: trim), Xform(translation: V3(0, 0.95, -8.1)))
            add(Prim.extrude(finPts, depth: 0.12, bevel: 0.035, bevelSegments: sg(3, 1), material: paint),
                Xform(translation: .zero, rotation: simd_quatf(degrees: 90, axis: Y)))
            add(Prim.superellipsoid(V3(0.34, 0.5, 0.6), exponent: 2.4, subdivisions: sg(5, 3), material: hardware), Xform(translation: V3(0.1, 1.95, -9.05)))
            add(Prim.tube([V3(0, 0.78, -8.7), V3(0, 0.35, -9.05), V3(0, 0.3, -9.35)], radii: [0.045, 0.04, 0.035], sides: sg(12, 8), seamTile: 0.25, material: hardware, capEnd: true))

            // Landing skids: two tubes with upturned toes, forward and aft struts, cross tubes.
            for sx: Float in [1, -1] {
                var bar: [V3] = []
                let n = sg(14, 8)
                for k in 0...n {
                    let t = Float(k) / Float(n)
                    let z = -3.3 + 6.9 * t
                    let toe = pow(max(0, (t - 0.82) / 0.18), 2) * 0.45 + pow(max(0, (0.12 - t) / 0.12), 2) * 0.12
                    bar.append(V3(sx * 1.55, -2.0 + toe, z))
                }
                add(Prim.tube(bar, radii: bar.map { _ in 0.055 }, sides: sg(20, 10), seamTile: 0.25, material: frame, capEnd: true))
                for sz: Float in [1.9, -1.9] {
                    let a = V3(sx * 1.0, -0.92, sz)
                    let b = V3(sx * 1.55, -1.98, sz)
                    add(Prim.tube([a, lerp(a, b, 0.5) + V3(sx * 0.05, 0, 0), b], radii: [0.05, 0.05, 0.05], sides: sg(16, 8), seamTile: 0.25, material: frame, capEnd: true))
                    add(Prim.superellipsoid(V3(0.2, 0.12, 0.7), exponent: 2.4, subdivisions: sg(5, 3), material: foot), Xform(translation: V3(sx * 1.55, -2.0, sz)))
                }
            }
            for sz: Float in [1.9, -1.9] {
                add(Prim.tube([V3(-1.55, -1.5, sz), V3(0, -1.46, sz), V3(1.55, -1.5, sz)], radii: [0.045, 0.045, 0.045], sides: sg(14, 8), seamTile: 0.25, material: frame, capEnd: true))
            }

            // Main rotor: hub, five sleeves, five blades with orange tips.
            add(Prim.cylinder(radius: 0.36, height: 0.22, bevel: 0.05, segments: sg(40, 16), bevelSegments: sg(3, 1), material: hardware), cx(V3(0, Self.hub.y - 0.09, 0), 0.22), to: "mainRotor")
            add(Prim.lathe([V2(0, 0), V2(0.26, 0), V2(0.24, 0.05), V2(0.14, 0.12), V2(0, 0.15)], segments: sg(32, 12), seamTile: 0.25, material: hardware), Xform(translation: V3(0, Self.hub.y + 0.12, 0)), to: "mainRotor")
            let lay = simd_quatf(degrees: -90, axis: X)
            for b in 0..<5 {
                let yaw = simd_quatf(degrees: Float(b) * 72, axis: Y)
                let pitchQ = simd_quatf(degrees: 7 + rng.f() * 1.5, axis: X)
                let at = V3(0, Self.hub.y, 0)
                add(Prim.cylinder(radius: 0.085, height: 0.7, bevel: 0.015, segments: sg(16, 8), bevelSegments: 1, material: hardware),
                    Xform(translation: at + yaw.act(V3(0.27, 0, 0)), rotation: yaw * simd_quatf(degrees: -90, axis: Z)), to: "mainRotor")
                add(Prim.extrude(blades, depth: 0.04, bevel: 0.013, bevelSegments: sg(2, 1), material: blade),
                    Xform(translation: at, rotation: yaw * pitchQ * lay), to: "mainRotor")
                add(Prim.roundedBox(V3(0.55, 0.046, 0.33), radius: 0.015, bevelSegments: sg(2, 1), material: paint),
                    Xform(translation: at + (yaw * pitchQ).act(V3(6.75, 0, 0)), rotation: yaw * pitchQ), to: "mainRotor")
            }

            // Tail rotor: hub and four blades in the YZ plane.
            add(Prim.cylinder(radius: 0.09, height: 0.14, bevel: 0.02, segments: sg(20, 10), bevelSegments: sg(2, 1), material: hardware),
                cx(Self.tailHub + V3(0.06, 0, 0), 0.14, simd_quatf(degrees: 90, axis: Z)), to: "tailRotor")
            let cyc = simd_quatf(angle: 2 * .pi / 3, axis: V3(1, 1, 1).normalized)
            for b in 0..<4 {
                let spin = simd_quatf(degrees: Float(b) * 90, axis: X)
                let pitchQ = simd_quatf(degrees: 12, axis: X)
                add(Prim.extrude(tailBlade, depth: 0.025, bevel: 0.008, bevelSegments: sg(2, 1), material: blade),
                    Xform(translation: Self.tailHub + V3(0.12, 0, 0), rotation: spin * cyc * pitchQ), to: "tailRotor")
            }

            // Searchlight turret under the chin: swivel, lamp can, bezel, emissive lens.
            let lp = Self.lightPivot
            add(Prim.cylinder(radius: 0.26, height: 0.14, bevel: 0.025, segments: sg(32, 14), bevelSegments: sg(2, 1), material: hardware), cx(lp + V3(0, 0.02, 0), 0.14), to: "searchlight")
            add(Prim.superellipsoid(V3(0.5, 0.46, 0.62), exponent: 2.6, subdivisions: sg(6, 3), material: hardware), Xform(translation: lp + V3(0, -0.28, 0.1)), to: "searchlight")
            let fwd = simd_quatf(degrees: 90, axis: X)
            add(Prim.cylinder(radius: 0.2, height: 0.05, bevel: 0.01, segments: sg(32, 14), bevelSegments: 1, material: frame), cx(lp + V3(0, -0.28, 0.4), 0.05, fwd), to: "searchlight")
            add(Prim.cylinder(radius: 0.165, height: 0.03, bevel: 0.004, segments: sg(32, 14), bevelSegments: 1, material: lens), cx(lp + V3(0, -0.28, 0.43), 0.03, fwd), to: "searchlight")
            if l == 0 {
                rig.lights.append(RigLight(name: "searchlight", kind: .spot(inner: 4, outer: 9), part: "searchlight", position: lp + V3(0, -0.28, 0.45),
                                           direction: V3(0, -0.2, 1), color: V3(1, 0.97, 0.9), intensity: 60000, attenuationRadius: 120))
            }

            // Hoist: roof bracket, boom arm, brace, drum housing.
            let ht = Self.hoistTop
            add(Prim.tube([V3(0.8, 1.2, 0.55), V3(1.4, 1.28, 0.58), V3(ht.x, 1.3, ht.z)], radii: [0.09, 0.075, 0.07], sides: sg(24, 10), seamTile: 0.25, material: frame, capEnd: true))
            add(Prim.tube([V3(1.3, 0.35, 0.62), V3(1.65, 0.85, 0.62), V3(ht.x, 1.25, ht.z)], radii: [0.05, 0.05, 0.05], sides: sg(16, 8), seamTile: 0.25, material: frame, capEnd: true))
            add(Prim.cylinder(radius: 0.15, height: 1.2, bevel: 0.03, segments: sg(32, 14), bevelSegments: sg(2, 1), material: hardware), cx(V3(ht.x, 1.1, ht.z), 1.2))
            add(Prim.cylinder(radius: 0.2, height: 0.08, bevel: 0.015, segments: sg(32, 14), bevelSegments: 1, material: frame), cx(V3(ht.x, 0.5, ht.z), 0.08))

            // Cable: twelve 1 m telescoping segments, tucked in the drum at rest (span ht.y ... ht.y + 1 shifted down by k+1 times hoist).
            for k in 0..<Self.cableSegments {
                add(Prim.tube([V3(ht.x, ht.y, ht.z), V3(ht.x, ht.y + 1.0, ht.z)], radii: [0.022, 0.022], sides: sg(12, 6), seamTile: 0.1, material: cable, capEnd: true), to: "cable\(k)")
            }

            // Rescue basket: hook, bridle, orange floor, rim rails, posts. Rest span is y = ht.y - 1 ... ht.y.
            let bc = V3(ht.x, ht.y - 1.0, ht.z)
            let hw: Float = 0.33, hl: Float = 0.5, bh: Float = 0.5
            let rim = sg(10, 6)
            add(Prim.torus(major: 0.06, minor: 0.012, segments: sg(24, 12), sides: sg(10, 6), material: frame), Xform(translation: V3(ht.x, ht.y - 0.02, ht.z), rotation: simd_quatf(degrees: 90, axis: X)), to: "basket")
            for (cx, cz) in [(hw, hl), (-hw, hl), (hw, -hl), (-hw, -hl)] {
                add(Prim.tube([V3(ht.x, ht.y - 0.04, ht.z), bc + V3(cx, bh, cz)], radii: [0.012, 0.012], sides: rim, seamTile: 0.1, material: cable, capEnd: true), to: "basket")
            }
            add(Prim.roundedBox(V3(hw * 2, 0.05, hl * 2), radius: 0.02, bevelSegments: sg(2, 1), material: paint), Xform(translation: bc + V3(0, 0.05, 0)), to: "basket")
            for h: Float in [0.05, bh * 0.5, bh] {
                let r: [V3] = [V3(hw, h, hl), V3(-hw, h, hl), V3(-hw, h, -hl), V3(hw, h, -hl), V3(hw, h, hl)]
                for e in 0..<4 {
                    add(Prim.tube([bc + r[e], bc + r[e + 1]], radii: [0.02, 0.02], sides: sg(12, 6), seamTile: 0.1, material: frame, capEnd: true), to: "basket")
                }
            }
            for (cx, cz) in [(hw, hl), (-hw, hl), (hw, -hl), (-hw, -hl)] {
                add(Prim.tube([bc + V3(cx, 0.05, cz), bc + V3(cx, bh, cz)], radii: [0.022, 0.022], sides: sg(12, 6), seamTile: 0.1, material: frame, capEnd: true), to: "basket")
                add(Prim.superellipsoid(V3(0.06, 0.06, 0.06), exponent: 2, subdivisions: sg(3, 2), material: frame), Xform(translation: bc + V3(cx, bh, cz)), to: "basket")
            }
            for s: Float in [1, -1] {
                add(Prim.tube([bc + V3(s * hw, 0.05, 0), bc + V3(s * hw, bh, 0)], radii: [0.016, 0.016], sides: rim, seamTile: 0.1, material: frame, capEnd: true), to: "basket")
            }
        }

        rig.states = [
            RigState("rest"),
            RigState("hover", ["rotor": 0.25]),
            RigState("search", ["rotor": 0.5, "light": 0.6, "pitch": 0.15]),
            RigState("lock", ["rotor": 0.75, "light": 0, "pitch": 0.3]),
            RigState("hoist-down", ["rotor": 0.5, "hoist": 1, "door": 1, "pitch": 0.1]),
            RigState("depart", ["rotor": 0.25, "light": -0.6, "pitch": 1]),
        ]
        rig.defaultState = "hover"
        return rig
    }
}
