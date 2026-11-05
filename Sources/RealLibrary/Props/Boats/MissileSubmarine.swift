import simd
import Foundation

/// Ballistic missile submarine, 84 m: smooth lofted hull (64 stations, 48 radial points) in wet black anechoic tile with a red
/// boot topping stripe, streamlined sail with a periscope and a radar mast, folding sail hydroplanes, cruciform stern planes and
/// rudders, a shrouded seven blade propeller on stator struts and 12 curved missile hatch doors on the casing (two rows of six).
/// Bow toward +Z, up +Y, origin at the waterline centre (hull axis at y -1.6, casing top at +3.0, sail top at +11, sail centre z 14).
/// Hatch doors sit aft of the sail at x = +-1.5, z = -4 - 2.9 * row; door index is row * 2 (port, +X) or row * 2 + 1 (starboard).
/// Joints: `hatch` 0...1 (all doors swing open 95 degrees outward), `planes` -1...1 (-1 dives: sail planes leading edge down
/// 30 degrees and stern planes trailing edge down 20 degrees), `periscope` 0...1 (periscope rises 5 m, radar mast 3.4 m) and
/// `prop` 0...1 (propeller turns one full revolution).
public struct MissileSubmarine: RealArticulated {
    public static let id = "missile-submarine"
    public static let summary = "84 m missile submarine with wet black hull, red boot topping, sail, folding planes, rudders, shrouded propeller, 12 hatch doors and joints hatch, planes, periscope, prop."
    public static let tags = ["prop", "vehicle", "boat", "submarine", "military", "marine", "outdoor", "articulated"]
    public static let budget = 14_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 50, elevation: 10, distance: 1.0, studio: true)

    /// Hull, sail and planes (wet black tile).
    public var hull: MaterialKey = "plastic.gloss:14181B"
    /// Boot topping stripe.
    public var boot: MaterialKey = "plastic.gloss:7A1815"
    /// Missile hatch doors.
    public var door: MaterialKey = "metal.painted:23282C"
    /// Missile tube recess under the doors.
    public var well: MaterialKey = "metal.anodized-black"
    /// Rudders and stern planes.
    public var fin: MaterialKey = "metal.painted:1B1F22"
    /// Propeller blades and spinner.
    public var propeller: MaterialKey = "metal.bronze-cast"
    /// Pump-jet shroud and stator struts.
    public var shroud: MaterialKey = "metal.painted:2A2E31"
    /// Periscope and mast tubes.
    public var tube: MaterialKey = "metal.stainless"
    /// Periscope head and radar cap.
    public var optics: MaterialKey = "metal.anodized-black"
    /// Periscope lens.
    public var lens: MaterialKey = "glass.tinted:0F1A22"
    public init() {}

    private static let R: Float = 4.6
    private static let axisY: Float = -1.6
    private static let hatchX: Float = 1.5
    private static let sailZ: Float = 14
    private static let sailBase: Float = 1.5
    private static let sailTop: Float = 11
    private static let tailZ: Float = -42
    private static let rotorZ: Float = -43

    private struct Rng {
        var s: UInt64
        mutating func f() -> Float {
            s = s &* 6364136223846793005 &+ 1442695040888963407
            return Float((s >> 40) & 0xFFFFFF) / Float(0x1000000)
        }
    }

    // MARK: Profile

    private static func smooth(_ x: Float) -> Float { let t = min(max(x, 0), 1); return t * t * (3 - 2 * t) }

    /// Hull radius at z (bow +42, stern -42).
    private static func hullR(_ z: Float) -> Float {
        if z > 28 {
            let u = min(1, (z - 28) / 14)
            return max(R * pow(max(0, 1 - u * u), 0.55), 0.03 * R)
        }
        if z < -22 {
            let u = min(1, (-22 - z) / 20)
            return R * (0.17 + 0.83 * pow(0.5 + 0.5 * cos(.pi * u), 1.3))
        }
        return R
    }

    /// Reverses ring point order when the ring winding opposes the loft direction (Prim.loft expects them aligned).
    private static func oriented(_ rings: [[V3]]) -> [[V3]] {
        let n = rings[0].count
        let mid = rings[rings.count / 2]
        let mc = mid.reduce(V3.zero, +) / Float(n)
        var nrm = V3.zero
        for i in 0..<n { nrm += simd_cross(mid[i] - mc, mid[(i + 1) % n] - mc) }
        let c0 = rings[0].reduce(V3.zero, +) / Float(n), c1 = rings[rings.count - 1].reduce(V3.zero, +) / Float(n)
        return simd_dot(nrm, c1 - c0) < 0 ? rings.map { Array($0.reversed()) } : rings
    }

    /// Skins aligned rings into one Surface per material (cell picks the material), closing both ends with fans.
    private static func skin(_ rings: [[V3]], mats: [MaterialKey], cell: (Int, Int) -> Int) -> [Surface] {
        let n = rings[0].count, rc = rings.count
        var u: [[Float]] = [], v: [Float] = [0]
        for r in 0..<rc {
            var row: [Float] = [0]
            for k in 1...n { row.append(row[k - 1] + simd_distance(rings[r][k % n], rings[r][(k - 1) % n])) }
            u.append(row)
            if r > 0 {
                let ca = rings[r].reduce(V3.zero, +) / Float(n), cb = rings[r - 1].reduce(V3.zero, +) / Float(n)
                v.append(v[r - 1] + simd_distance(ca, cb))
            }
        }
        var surfs = mats.map { Surface(material: $0) }
        var maps = [[Int: UInt32]](repeating: [:], count: mats.count)
        func vtx(_ m: Int, _ r: Int, _ k: Int) -> UInt32 {
            let key = r * (n + 1) + k
            if let id = maps[m][key] { return id }
            let id = surfs[m].add(rings[r][k % n], .up, V2(u[r][k], v[r]))
            maps[m][key] = id
            return id
        }
        for r in 0..<(rc - 1) {
            for k in 0..<n {
                let m = cell(r, k)
                let a = vtx(m, r, k), b = vtx(m, r, k + 1), c = vtx(m, r + 1, k + 1), d = vtx(m, r + 1, k)
                surfs[m].quad(a, b, c, d)
            }
        }
        for (r, atStart) in [(0, true), (rc - 1, false)] {
            let c = rings[r].reduce(V3.zero, +) / Float(n)
            let ci = surfs[0].add(c, .up, V2(0, v[r]))
            for k in 0..<n {
                let a = vtx(0, r, k), b = vtx(0, r, k + 1)
                if atStart { surfs[0].tri(b, a, ci) } else { surfs[0].tri(a, b, ci) }
            }
        }
        return surfs.filter { !$0.indices.isEmpty }.map { s in
            var o = s
            o.recomputeNormals(weldSeams: true)
            o.computeTangents()
            return o
        }
    }

    // MARK: Sail

    private static func sailRing(_ y: Float, scale: Float, points n: Int) -> [V3] {
        let t = min(max((y - sailBase) / (sailTop - sailBase - 0.7), 0), 1)
        let chord = (9.0 - 2.4 * t) * scale, thick = (3.0 - 0.8 * t) * scale
        let zc = sailZ + 0.35 * t
        let e: Float = 2.4
        return (0..<n).map { k in
            let a = 2 * Float.pi * Float(k) / Float(n)
            let s = sin(a), c = cos(a)
            let x = thick / 2 * (s < 0 ? -1 : 1) * pow(abs(s), 2 / e)
            let z = zc + chord / 2 * (c < 0 ? -1 : 1) * pow(abs(c), 2 / e)
            return V3(x, y, z)
        }
    }

    // MARK: Curved hatch door and recess (closed solids following the hull)

    /// Closed solid over hull polar angles psi0...psi1 (from vertical, degrees, signed by side), z - half...z + half.
    private static func casingPatch(psi0: Float, psi1: Float, top: Float, bottom: Float, z: Float, half: Float, chamfer: Float, arc: Int) -> Surface {
        func ring(_ zz: Float, _ inset: Float, _ shrink: Float) -> [V3] {
            var pts: [V3] = []
            let a0 = psi0 + (psi1 - psi0) * shrink, a1 = psi1 - (psi1 - psi0) * shrink
            for k in 0...arc {
                let a = radians(a0 + (a1 - a0) * Float(k) / Float(arc))
                let r = top - inset
                pts.append(V3(r * sin(a), axisY + r * cos(a), zz))
            }
            for k in stride(from: arc, through: 0, by: -1) {
                let a = radians(a0 + (a1 - a0) * Float(k) / Float(arc))
                pts.append(V3(bottom * sin(a), axisY + bottom * cos(a), zz))
            }
            return pts
        }
        var rings: [[V3]] = []
        if chamfer > 0 {
            rings = [ring(z - half, chamfer, 0.02), ring(z - half + chamfer, 0, 0), ring(z + half - chamfer, 0, 0), ring(z + half, chamfer, 0.02)]
        } else {
            rings = [ring(z - half, 0, 0), ring(z + half, 0, 0)]
        }
        return Prim.loft(oriented(rings), capStart: true, capEnd: true, material: "")
    }

    // MARK: Rig

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [120])
        let X = V3(1, 0, 0), Y = V3(0, 1, 0), Z = V3(0, 0, 1)
        var rng = Rng(s: seed &* 2654435761 &+ 41)
        let ax = V3(0, Self.axisY, 0)

        // Drivers first so mimics resolve.
        _ = rig.part("hatch", pivot: .zero, joint: .hinge(axis: X, 0...1, duration: 1.4))
        _ = rig.part("planes", pivot: .zero, joint: .hinge(axis: X, -1...1, duration: 2.0))
        _ = rig.part("periscope", pivot: .zero, joint: .hinge(axis: X, 0...1, duration: 4.0))
        _ = rig.part("prop", pivot: .zero, joint: .hinge(axis: X, 0...1, duration: 2.5))

        // Hatch doors: two rows of six. Port (+X) hinges at its outboard edge and opens by a negative rotation about +Z.
        let psiIn = asin(0.5 / Self.R) * 180 / .pi, psiOut = asin(2.5 / Self.R) * 180 / .pi
        let doorTop = Self.R + 0.07
        var hinges: [V3] = []
        var zs: [Float] = []
        for row in 0..<6 { zs.append(-4 - 2.9 * Float(row)) }
        for row in 0..<6 {
            for s in 0..<2 {
                let side: Float = s == 0 ? 1 : -1
                let a = radians(psiOut) * side
                let hinge = V3(doorTop * sin(a), Self.axisY + doorTop * cos(a), zs[row])
                hinges.append(hinge)
                _ = rig.part("hatchDoor\(row * 2 + s)", pivot: hinge,
                             joint: Joint(.revolute, axis: Z, range: -100...100, mimic: .init("hatch", ratio: -side * 95)))
            }
        }
        _ = rig.part("sailPlaneL", pivot: V3(2.0, 6.5, 16.0), joint: Joint(.revolute, axis: X, range: -40...40, mimic: .init("planes", ratio: -30)))
        _ = rig.part("sailPlaneR", pivot: V3(-2.0, 6.5, 16.0), joint: Joint(.revolute, axis: X, range: -40...40, mimic: .init("planes", ratio: -30)))
        _ = rig.part("sternPlaneL", pivot: V3(3.0, Self.axisY, -34), joint: Joint(.revolute, axis: X, range: -40...40, mimic: .init("planes", ratio: 20)))
        _ = rig.part("sternPlaneR", pivot: V3(-3.0, Self.axisY, -34), joint: Joint(.revolute, axis: X, range: -40...40, mimic: .init("planes", ratio: 20)))
        _ = rig.part("periscopeMast", pivot: V3(0.5, 5, 15.2), joint: Joint(.prismatic, axis: Y, range: 0...5, mimic: .init("periscope", ratio: 5)))
        _ = rig.part("radarMast", pivot: V3(-0.5, 5, 14.4), joint: Joint(.prismatic, axis: Y, range: 0...3.4, mimic: .init("periscope", ratio: 3.4)))
        _ = rig.part("propRotor", pivot: V3(0, Self.axisY, Self.rotorZ), joint: Joint(.revolute, axis: Z, range: 0...360, mimic: .init("prop", ratio: 360)))

        let phase = rng.f() * 2 * .pi / 7
        let strutPhase = rng.f() * 0.2

        for l in 0..<2 {
            let stations = [64, 32][l], radial = [48, 24][l]

            // Hull: bow to stern, black tile with a red boot topping band around the waterline.
            var rings: [[V3]] = []
            for i in 0..<stations {
                let z = 42 * cos(.pi * Float(i) / Float(stations - 1))
                let r = Self.hullR(z)
                rings.append((0..<radial).map { k in
                    let a = 2 * Float.pi * Float(k) / Float(radial)
                    return V3(r * cos(a), Self.axisY + r * sin(a), z)
                })
            }
            let hr = Self.oriented(rings)
            let bootCell: (Int, Int) -> Int = { r, k in
                let p = (hr[r][k].y + hr[r][(k + 1) % radial].y + hr[r + 1][k].y + hr[r + 1][(k + 1) % radial].y) / 4
                return p > -1.15 && p < -0.25 ? 1 : 0
            }
            for s in Self.skin(hr, mats: [hull, boot], cell: bootCell) { rig.base[l].add(s) }

            // Sail.
            let sn = [32, 16][l]
            var ys: [Float] = []
            let nb = [14, 7][l]
            for i in 0..<nb { ys.append(Self.sailBase + (Self.sailTop - 0.7 - Self.sailBase) * Float(i) / Float(nb - 1)) }
            var sr: [[V3]] = ys.map { Self.sailRing($0, scale: 1, points: sn) }
            sr.append(Self.sailRing(Self.sailTop - 0.42, scale: 0.94, points: sn))
            sr.append(Self.sailRing(Self.sailTop - 0.14, scale: 0.80, points: sn))
            sr.append(Self.sailRing(Self.sailTop, scale: 0.52, points: sn))
            var sail = Prim.loft(Self.oriented(sr), capEnd: true, material: hull)
            sail.material = hull
            rig.base[l].add(sail)

            // Collars where the masts leave the sail top.
            for (mx, mz) in [(Float(0.5), Float(15.2)), (Float(-0.5), Float(14.4))] {
                let c = Prim.lathe([V2(0, 0), V2(0.34, 0), V2(0.34, 0.10), V2(0.22, 0.17), V2(0.15, 0.17)], segments: [16, 10][l], seamTile: 0.1, material: tube)
                rig.base[l].add(c, Xform(translation: V3(mx, Self.sailTop - 0.12, mz)))
            }

            // Hatch doors and recesses.
            for row in 0..<6 {
                for s in 0..<2 {
                    let side: Float = s == 0 ? 1 : -1
                    let name = "hatchDoor\(row * 2 + s)"
                    let p0 = psiIn * side, p1 = psiOut * side
                    var d = Self.casingPatch(psi0: p0, psi1: p1, top: doorTop, bottom: Self.R - 0.12, z: zs[row], half: 1.1, chamfer: l == 0 ? 0.05 : 0, arc: [5, 3][l])
                    d.material = door
                    rig.add(d, to: name, lods: l...l)
                    if l == 0 {
                        var w = Self.casingPatch(psi0: p0 - side * 1.6, psi1: p1 + side * 1.6, top: Self.R + 0.025, bottom: Self.R - 0.2, z: zs[row], half: 1.26, chamfer: 0, arc: 5)
                        w.material = well
                        rig.base[l].add(w)
                    }
                }
            }

            // Sail planes: planform in (span, chord), chord positive aft.
            for side: Float in [1, -1] {
                let o = Shape2D.rounded([V2(0, -0.75), V2(3.2, -0.42), V2(3.2, 0.38), V2(0, 1.0)].map { V2($0.x * side, $0.y) }, radius: 0.06, segments: [2, 1][l])
                let pl = Prim.extrude(o, depth: 0.16, bevel: 0.04, bevelSegments: 1, material: hull)
                rig.add(pl, Xform(translation: V3(side * 1.0, 6.5, 16.0), rotation: simd_quatf(degrees: -90, axis: X)), to: side > 0 ? "sailPlaneL" : "sailPlaneR", lods: l...l)
            }

            // Stern planes.
            for side: Float in [1, -1] {
                let o = Shape2D.rounded([V2(0, -2.3), V2(4.0, -1.2), V2(4.0, 0.7), V2(0, 1.3)].map { V2($0.x * side, $0.y) }, radius: 0.08, segments: [2, 1][l])
                let pl = Prim.extrude(o, depth: 0.2, bevel: 0.05, bevelSegments: 1, material: fin)
                rig.add(pl, Xform(translation: V3(side * 1.2, Self.axisY, -34), rotation: simd_quatf(degrees: -90, axis: X)), to: side > 0 ? "sternPlaneL" : "sternPlaneR", lods: l...l)
            }

            // Rudders (upper and lower), planform in (z, y), extruded across x.
            let up: [V2] = [V2(-32.0, -1.0), V2(-34.2, 2.6), V2(-37.6, 2.6), V2(-38.8, -1.0)]
            let low: [V2] = up.map { V2($0.x, -3.2 - $0.y) }
            for o in [up, low] {
                let ru = Prim.extrude(Shape2D.rounded(o, radius: 0.1, segments: [2, 1][l]), depth: 0.28, bevel: 0.07, bevelSegments: 1, material: fin)
                rig.base[l].add(ru, Xform(rotation: simd_quatf(degrees: -90, axis: Y)))
            }

            // Tail hub, pump-jet shroud and stator struts.
            let rotY = simd_quatf(degrees: -90, axis: X)
            rig.base[l].add(Prim.lathe([V2(0.78, 0), V2(0.70, 1.0)], segments: [32, 16][l], seamTile: 0.2, material: shroud),
                            Xform(translation: V3(0, Self.axisY, Self.tailZ), rotation: rotY))
            let sp: [V2] = [V2(2.22, 0), V2(2.52, 0.25), V2(2.62, 1.0), V2(2.56, 2.4), V2(2.2, 3.5),
                            V2(2.02, 3.1), V2(2.02, 2.0), V2(2.1, 0.7), V2(2.22, 0)]
            rig.base[l].add(Prim.lathe(sp, segments: [48, 24][l], seamTile: 0.3, material: shroud),
                            Xform(translation: V3(0, Self.axisY, -40.9), rotation: rotY))
            if l == 0 {
                for i in 0..<7 {
                    let ang = 2 * Float.pi * (Float(i) + strutPhase) / 7
                    let c = ax + V3(cos(ang), sin(ang), 0) * 1.4 + V3(0, 0, -42.45)
                    let st = Prim.superellipsoid(V3(1.5, 0.1, 0.8), exponent: 6, subdivisions: 1, material: shroud)
                    rig.base[l].add(st, Xform(translation: c, rotation: simd_quatf(angle: ang, axis: Z)))
                }
            }

            // Propeller: spinner and seven skewed blades with pitch.
            let centre = V3(0, Self.axisY, Self.rotorZ)
            rig.add(Prim.lathe([V2(0.70, 0), V2(0.72, 0.5), V2(0.64, 1.4), V2(0.40, 2.2), V2(0, 2.7)], segments: [32, 16][l], seamTile: 0.2, material: propeller),
                    Xform(translation: centre, rotation: rotY), to: "propRotor", lods: l...l)
            let blade: [V2] = [V2(-0.24, 0.35), V2(0.30, 0.35), V2(0.52, 1.2), V2(0.34, 2.0), V2(-0.08, 2.0), V2(-0.40, 1.2)]
            let bs = Prim.extrude(Shape2D.rounded(blade, radius: 0.06, segments: [2, 1][l]), depth: 0.07, bevel: 0.02, bevelSegments: 1, material: propeller)
            for i in 0..<7 {
                let ang = phase + 2 * Float.pi * Float(i) / 7
                let q = simd_quatf(angle: ang, axis: Z) * simd_quatf(degrees: 35, axis: Y)
                rig.add(bs, Xform(translation: centre + V3(0, 0, -0.9), rotation: q), to: "propRotor", lods: l...l)
            }

            // Periscope and radar mast: tube from deep in the sail to above the sail top, head on top.
            let sides = [16, 8][l]
            let pp = V3(0.5, 0, 15.2), rp = V3(-0.5, 0, 14.4)
            rig.add(Prim.tube([V3(pp.x, 4, pp.z), V3(pp.x, 10.6, pp.z)], radii: [0.12, 0.12], sides: sides, seamTile: 0.2, material: tube),
                    to: "periscopeMast", lods: l...l)
            rig.add(Prim.superellipsoid(V3(0.42, 0.5, 0.62), exponent: 4, subdivisions: [3, 2][l], material: optics),
                    Xform(translation: V3(pp.x, 10.85, pp.z)), to: "periscopeMast", lods: l...l)
            rig.add(Prim.superellipsoid(V3(0.2, 0.2, 0.1), exponent: 2, subdivisions: [2, 1][l], material: lens),
                    Xform(translation: V3(pp.x, 10.85, pp.z + 0.31)), to: "periscopeMast", lods: l...l)
            rig.add(Prim.tube([V3(rp.x, 4, rp.z), V3(rp.x, 10.4, rp.z)], radii: [0.09, 0.09], sides: sides, seamTile: 0.2, material: tube),
                    to: "radarMast", lods: l...l)
            rig.add(Prim.cylinder(radius: 0.3, height: 0.18, bevel: 0.04, segments: [24, 12][l], bevelSegments: 1, material: optics),
                    Xform(translation: V3(rp.x, 10.4, rp.z)), to: "radarMast", lods: l...l)
        }

        rig.states = [
            RigState("rest"),
            RigState("periscope-up", ["periscope": 1]),
            RigState("launch", ["hatch": 1, "periscope": 1]),
            RigState("dive", ["planes": -1]),
            RigState("climb", ["planes": 1, "periscope": 1]),
            RigState("prop-quarter", ["prop": 0.25]),
        ]
        rig.defaultState = "rest"
        return rig
    }
}
