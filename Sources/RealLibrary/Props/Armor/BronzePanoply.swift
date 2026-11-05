import simd
import Foundation

/// Bronze panoply, one hoplite kit: hammered bronze muscle cuirass and back plate with leather pteruges, crested
/// Corinthian helm with a horsehair crest, layered pauldrons, banded vambraces with elbow cops, a crimson wool cape
/// lofted as a folded strip, a round hoplon with a raised lambda on the left forearm and a 2.1 m spear in the right
/// hand. Authored assembled on a 1.75 m body: origin at the neck base, +Y up, face toward +Z, kit +X = person left.
/// Each part keeps its own pivot (helmet at the neck base, chest at the sternum, back between the shoulder blades,
/// shoulders at the shoulder joints, gauntlets at the elbows) so a lens can reparent and spring-follow it. 2 LODs.
///
/// Joints (driver parts, values as the lens passes them): `cape` -1...1 (sway, 20 degrees), `crest` -1...1 (helm
/// crest sway, 12 degrees), `shield` 0...1 (raise 0.2 m), `spear` 0...1 (tilt 77 degrees and push 0.55 m).
/// Parts: helmet, crest, chest, back, shoulderL, shoulderR, gauntletL, gauntletR, shield, spear, cape. Greaves omitted
/// (the armor kit contract has no leg part).
public struct BronzePanoply: RealArticulated {
    public static let id = "bronze-panoply"
    public static let summary = "Hoplite bronze panoply: hammered muscle cuirass, crested Corinthian helm, red cape, pauldrons, vambraces, hoplon shield and spear."
    public static let tags = ["prop", "fantasy", "metal", "fabric", "leather", "articulated"]
    public static let budget = 20_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 6, distance: 1.25)

    /// Hammered bronze plate, rims and fittings.
    public var bronze: MaterialKey = "metal.brass-aged:9A6B34"
    /// Spear head.
    public var iron: MaterialKey = "metal.iron"
    /// Cape and crest.
    public var capeCloth: MaterialKey = "fabric.wool:A3201A"
    public var crestHair: MaterialKey = "fabric.velvet:A8241B"
    /// Pteruges, belt, straps and spear grip.
    public var leather: MaterialKey = "leather.tan:6A4528"
    /// Spear shaft.
    public var shaft: MaterialKey = "wood.oak:8A6A44"
    public init() {}

    // MARK: Shape tables (y down the torso)

    static let ty: [Float] = [0.015, -0.02, -0.07, -0.16, -0.29, -0.42, -0.50, -0.565]
    static let tw: [Float] = [0.072, 0.125, 0.180, 0.178, 0.160, 0.148, 0.146, 0.152]
    static let td: [Float] = [0.050, 0.070, 0.094, 0.108, 0.100, 0.090, 0.088, 0.094]
    static let hy: [Float] = [-0.035, -0.01, 0.03, 0.07, 0.11, 0.14, 0.17, 0.20, 0.23, 0.255, 0.272]
    static let hr: [Float] = [0.122, 0.108, 0.103, 0.105, 0.111, 0.115, 0.116, 0.112, 0.100, 0.076, 0.001]
    static let elbowL = V3(0.235, -0.34, 0)
    static let elbowR = V3(-0.235, -0.34, 0)
    static let shieldC = V3(0.27, -0.47, 0.17)
    static let hand = V3(-0.235, -0.61, 0.07)

    static func rad(_ d: Float) -> Float { d * .pi / 180 }
    static func tab(_ xs: [Float], _ vs: [Float], _ x: Float) -> Float {
        for i in 0..<(xs.count - 1) {
            let a = xs[i], b = xs[i + 1]
            if (x - a) * (x - b) <= 0 {
                let t = (x - a) / (b - a), s = 0.5 * t + 0.5 * t * t * (3 - 2 * t)
                return vs[i] + (vs[i + 1] - vs[i]) * s
            }
        }
        return abs(x - xs[0]) < abs(x - xs[xs.count - 1]) ? vs[0] : vs[vs.count - 1]
    }
    func gauss(_ x: Float, _ y: Float, _ cx: Float, _ cy: Float, _ sx: Float, _ sy: Float) -> Float {
        exp(-(pow((x - cx) / sx, 2) + pow((y - cy) / sy, 2)))
    }

    // MARK: Torso, helm, cape, vambrace and hoplon surfaces

    func frontRelief(_ p: V3) -> Float {
        let x = abs(p.x), y = p.y
        var h = 0.016 * gauss(x, y, 0.088, -0.125, 0.055, 0.045)
        h -= 0.0045 * gauss(x, y, 0, -0.2, 0.010, 0.28)
        h -= 0.006 * gauss(x, y, 0.07, -0.188, 0.08, 0.009)
        for k in 0..<3 { h += 0.009 * gauss(x, y, 0.038, -0.285 - 0.062 * Float(k), 0.03, 0.022) }
        h += 0.005 * gauss(x, y, 0.15, -0.32, 0.04, 0.07)
        return h
    }
    func backRelief(_ p: V3) -> Float {
        let x = abs(p.x), y = p.y
        return -0.005 * gauss(x, y, 0, -0.25, 0.010, 0.25) + 0.012 * gauss(x, y, 0.09, -0.12, 0.05, 0.05)
            + 0.007 * gauss(x, y, 0.12, -0.28, 0.05, 0.07)
    }
    /// Torso surface point: height y, angle a from +Z toward +X, offset along the surface normal.
    func torso(_ y: Float, _ a: Float, _ off: Float = 0) -> V3 {
        let w = Self.tab(Self.ty, Self.tw, y), d = Self.tab(Self.ty, Self.td, y)
        let sa = sin(a), ca = cos(a)
        var p = V3(w * sa, y, d * ca)
        let n = simd_normalize(V3(sa / max(w, 0.01), 0, ca / max(d, 0.01)))
        let relief = frontRelief(p) * smoothstep(0, 0.35, ca) + backRelief(p) * smoothstep(0, 0.35, -ca)
        p += n * (off + relief)
        return p
    }
    func torsoNormal(_ p: V3) -> V3 {
        let w = Self.tab(Self.ty, Self.tw, p.y), d = Self.tab(Self.ty, Self.td, p.y)
        return simd_normalize(V3(p.x / (w * w), 0, p.z / (d * d)))
    }
    func helm(_ y: Float, _ a: Float, inset: Float = 0) -> V3 {
        var r = Self.tab(Self.hy, Self.hr, y)
        r += 0.03 * (1 - smoothstep(-0.035, 0.02, y)) * smoothstep(1.4, 2.4, abs(a))
        r += 0.008 * exp(-pow((abs(a) - 1.2) / 0.3, 2)) * (1 - smoothstep(0.02, 0.12, y))
        r = max(0.001, r - inset)
        return V3(r * sin(a), y, 0.015 + r * cos(a) * 1.04)
    }
    func hoplonY(_ r: Float) -> Float {
        let t = min(r / 0.40, 1)
        var y = 0.014 + 0.062 * (1 - t * t)
        y += 0.004 * exp(-pow((r - 0.335) / 0.007, 2)) + 0.004 * exp(-pow((r - 0.24) / 0.007, 2))
        y += 0.012 * exp(-pow(r / 0.05, 2))
        return y
    }
    func vambrace(_ y: Float) -> Float {
        let t = (y + 0.27) / 0.27
        var r = 0.039 + 0.021 * pow(max(t, 0), 0.8)
        for b: Float in [-0.075, -0.145, -0.215] { r += 0.005 * exp(-pow((y - b) / 0.011, 2)) }
        return r + 0.006 * exp(-pow((y + 0.265) / 0.012, 2))
    }

    /// Quad grid over (u, v) in 0...1, oriented away from `center`. `inset` > 0 builds the inner liner facing inward.
    func gridSurf(_ nu: Int, _ nv: Int, _ mat: MaterialKey, center: (V3) -> V3, inset: Float = 0, _ f: (Float, Float) -> V3) -> Surface {
        var rows: [[V3]] = [], uvs: [[V2]] = []
        var vArc: Float = 0
        var prev0: V3? = nil
        for i in 0...nv {
            let v = Float(i) / Float(nv)
            var r: [V3] = [], u: [V2] = []
            var arc: Float = 0
            var last: V3? = nil
            for j in 0...nu {
                var p = f(Float(j) / Float(nu), v)
                if inset != 0 { p -= simd_normalize(p - center(p)) * inset }
                if let l = last { arc += simd_distance(l, p) }
                last = p
                if j == 0 { if let q = prev0 { vArc += simd_distance(q, p) }; prev0 = p }
                r.append(p); u.append(V2(arc, vArc))
            }
            rows.append(r); uvs.append(u)
        }
        var s = WoodParts.grid(rows, uvs: uvs, material: mat)
        WoodParts.orientOutward(&s, center: center)
        if inset != 0 { for k in stride(from: 0, to: s.indices.count, by: 3) { s.indices.swapAt(k + 1, k + 2) } }
        s.recomputeNormals(weldSeams: false)
        s.computeTangents()
        return s
    }
    /// Closed path around the boundary of a grid, every `step`-th sample (nu and nv even).
    func border(_ nu: Int, _ nv: Int, _ f: (Float, Float) -> V3) -> [V3] {
        var pts: [V3] = []
        let fu = Float(nu), fv = Float(nv)
        for j in stride(from: 0, through: nu, by: 2) { pts.append(f(Float(j) / fu, 0)) }
        for i in stride(from: 2, through: nv, by: 2) { pts.append(f(1, Float(i) / fv)) }
        for j in stride(from: nu - 2, through: 0, by: -2) { pts.append(f(Float(j) / fu, 1)) }
        for i in stride(from: nv - 2, to: 0, by: -2) { pts.append(f(0, Float(i) / fv)) }
        pts.append(pts[0])
        return pts
    }
    func roll(_ path: [V3], _ r: Float, sides: Int, _ mat: MaterialKey) -> Surface {
        Prim.tube(path, radii: Array(repeating: r, count: path.count), sides: sides, seamTile: 0.05, material: mat, capEnd: false)
    }

    // MARK: Rig

    public func rig(seed: UInt64) -> Rig {
        var rng = SeededRNG(seed: seed)
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [3])
        let X = V3(1, 0, 0), Y = V3(0, 1, 0), Z = V3(0, 0, 1)
        let eL = Self.elbowL, eR = Self.elbowR, C = Self.shieldC, H = Self.hand
        let foldA = rng.float() * 6.28, foldB = rng.float() * 6.28
        let jit: [Float] = (0..<64).map { _ in rng.float() }

        // Kit parts (fixed) and joint drivers. Drivers first so mimics resolve.
        _ = rig.part("helmet", pivot: V3(0, 0, 0), joint: .fixed)
        _ = rig.part("chest", pivot: V3(0, -0.17, 0.09), joint: .fixed)
        _ = rig.part("back", pivot: V3(0, -0.17, -0.07), joint: .fixed)
        _ = rig.part("shoulderL", pivot: V3(0.19, -0.04, 0), joint: .fixed)
        _ = rig.part("shoulderR", pivot: V3(-0.19, -0.04, 0), joint: .fixed)
        _ = rig.part("gauntletL", pivot: eL, joint: .fixed)
        _ = rig.part("gauntletR", pivot: eR, joint: .fixed)
        _ = rig.part("crest", parent: "helmet", pivot: V3(0, 0.23, 0), joint: .hinge(axis: Z, -1...1, duration: 0.6))
        _ = rig.part("crestSway", parent: "crest", pivot: V3(0, 0.23, 0),
                     joint: Joint(.revolute, axis: Z, range: -12...12, mimic: .init("crest", ratio: 12)))
        _ = rig.part("cape", pivot: V3(0, -0.03, -0.105), joint: .hinge(axis: X, -1...1, duration: 1.2))
        _ = rig.part("capeSway", parent: "cape", pivot: V3(0, -0.03, -0.105),
                     joint: Joint(.revolute, axis: X, range: -20...20, mimic: .init("cape", ratio: 20)))
        _ = rig.part("shield", parent: "gauntletL", pivot: eL, joint: .hinge(axis: X, 0...1, duration: 0.5))
        _ = rig.part("shieldRaise", parent: "shield", pivot: eL,
                     joint: Joint(.prismatic, axis: Y, range: 0...0.2, mimic: .init("shield", ratio: 0.2)))
        _ = rig.part("spear", parent: "gauntletR", pivot: H, joint: .hinge(axis: X, 0...1, duration: 0.4))
        _ = rig.part("spearTilt", parent: "spear", pivot: H,
                     joint: Joint(.revolute, axis: X, range: 0...80, mimic: .init("spear", ratio: 77)))
        _ = rig.part("spearPush", parent: "spearTilt", pivot: H,
                     joint: Joint(.prismatic, axis: Y, range: 0...0.55, mimic: .init("spear", ratio: 0.55)))

        for l in 0..<2 {
            let hi = l == 0
            let q = hi ? 1 : 2
            func R(_ n: Int) -> Int { max(4, (n / q) / 2 * 2) }
            let sides = hi ? 6 : 4
            func put(_ s: Surface, _ part: String, _ x: Xform = .identity) { rig.add(s, x, to: part, lods: l...l) }
            let rivet = Prim.lathe([V2(0.001, 0), V2(0.008, 0.0005), V2(0.006, 0.0045), V2(0.001, 0.0062)], segments: 6, seamTile: 0.02, material: bronze)
            /// Bronze rivet heads at world points, facing `n`.
            func rivets(_ pts: [(V3, V3)], _ part: String, scale: Float = 1) {
                guard hi else { return }
                for (p, n) in pts {
                    put(rivet, part, Xform(translation: p - n * 0.0008, rotation: simd_quatf(from: Y, to: simd_normalize(n)), scale: V3(repeating: scale)))
                }
            }
            let axisC: (V3) -> V3 = { V3(0, $0.y, 0) }

            // MARK: Cuirass front, back plate, seams, rivets.
            do {
                let nu = R(32), nv = R(24)
                let ya = Self.ty[0], yb = Self.ty[Self.ty.count - 1]
                let ff: (Float, Float) -> V3 = { u, v in self.torso(ya + v * (yb - ya), Self.rad(-97 + 194 * u)) }
                put(gridSurf(nu, nv, bronze, center: axisC, ff), "chest")
                put(gridSurf(R(16), R(10), bronze, center: axisC, inset: 0.007, ff), "chest")
                put(roll(border(nu, nv, ff), 0.0055, sides: sides, bronze), "chest")
                let bu = R(24), bv = R(12)
                let bf: (Float, Float) -> V3 = { u, v in self.torso(-0.01 + v * (yb + 0.01), Self.rad(97 + 166 * u)) }
                put(gridSurf(bu, bv, bronze, center: axisC, bf), "back")
                put(gridSurf(R(12), R(6), bronze, center: axisC, inset: 0.007, bf), "back")
                put(roll(border(bu, bv, bf), 0.0055, sides: sides, bronze), "back")
                // Waist seams: raised bead across each plate.
                let fseam = (0...R(24)).map { self.torso(-0.47, Self.rad(-97 + 194 * Float($0) / Float(R(24))), 0.002) }
                put(roll(fseam, 0.004, sides: 5, bronze), "chest")
                let bseam = (0...R(16)).map { self.torso(-0.47, Self.rad(97 + 166 * Float($0) / Float(R(16))), 0.002) }
                put(roll(bseam, 0.004, sides: 5, bronze), "back")
                var rp: [(V3, V3)] = []
                for y: Float in stride(from: -0.10, through: -0.50, by: -0.0667) {
                    for sgn: Float in [-1, 1] { let p = torso(y, sgn * Self.rad(92)); rp.append((p, torsoNormal(p))) }
                }
                rivets(rp, "chest")
                var bp: [(V3, V3)] = []
                for y: Float in stride(from: -0.12, through: -0.48, by: -0.072) {
                    for sgn: Float in [-1, 1] { let p = torso(y, sgn * Self.rad(102) + (sgn > 0 ? 0 : 2 * .pi)); bp.append((p, torsoNormal(p))) }
                }
                rivets(bp, "back")

                // Leather pteruges around the waist and a rolled belt.
                let n = hi ? 20 : 12
                let ys: [Float] = [-0.55, -0.64, -0.74, -0.84], sc: [Float] = [1.0, 1.03, 1.08, 1.14]
                var studs: [(V3, V3)] = []
                for k in 0..<n {
                    let phi = 2 * .pi * (Float(k) + 0.5) / Float(n)
                    let base = torso(-0.56, phi)
                    let nrm = torsoNormal(base)
                    let tan = simd_normalize(simd_cross(Y, nrm))
                    var centers: [V3] = []
                    let rings: [[V3]] = ys.indices.map { i in
                        let c = V3(base.x * sc[i], ys[i], base.z * sc[i]) + nrm * 0.004 * Float(i)
                        centers.append(c)
                        let hw: Float = 0.0225 - 0.002 * Float(i), th: Float = 0.004
                        return [c - tan * hw - nrm * th, c + tan * hw - nrm * th, c + tan * hw + nrm * th, c - tan * hw + nrm * th]
                    }
                    var s = Prim.loft(rings, capStart: false, capEnd: false, material: leather)
                    WoodParts.orientOutward(&s) { p in centers.min(by: { simd_distance($0, p) < simd_distance($1, p) })! }
                    s.recomputeNormals(weldSeams: false); s.computeTangents()
                    put(s, "chest")
                    if k % 2 == 0 { studs.append((centers[0] + nrm * 0.005, nrm)) }
                }
                rivets(studs, "chest", scale: 1.1)
                let belt = (0...R(40)).map { torso(-0.545, 2 * .pi * Float($0) / Float(R(40)), 0.006) }
                put(roll(belt, 0.012, sides: hi ? 8 : 5, leather), "chest")
            }

            // MARK: Corinthian helm: cut face opening, nose bar, inner liner, brow and rim rolls, crest.
            do {
                let nu = 64, nv = 12
                func shellH(inset: Float, cols: Int) -> Surface {
                    var s = Surface(material: bronze)
                    let yA = Self.hy[0], yB = Self.hy[Self.hy.count - 1]
                    var arcV: Float = 0
                    var last0: V3? = nil
                    for i in 0...nv {
                        let y = yA + (yB - yA) * Float(i) / Float(nv)
                        var arcU: Float = 0
                        var last: V3? = nil
                        for k in 0...cols {
                            let a = (Float(k) / Float(cols) - 0.5) * 2 * .pi
                            let p = helm(y, a, inset: inset)
                            if let lp = last { arcU += simd_distance(lp, p) }
                            last = p
                            if k == 0 { if let q = last0 { arcV += simd_distance(q, p) }; last0 = p }
                            s.add(p, .up, V2(arcU, arcV))
                        }
                    }
                    let w = UInt32(cols + 1)
                    for i in 0..<nv { for k in 0..<cols {
                        let ac = (Float(k) + 0.5) / Float(cols) * 2 * .pi - .pi
                        let nose = abs(ac) < 0.06 && i >= 2
                        if i < 8 && abs(ac) < Self.rad(45) && !nose { continue }
                        let a = UInt32(i) * w + UInt32(k)
                        s.quad(a, a + 1, a + w + 1, a + w)
                    }}
                    WoodParts.orientOutward(&s) { V3(0, $0.y, 0.015) }
                    if inset != 0 { for t in stride(from: 0, to: s.indices.count, by: 3) { s.indices.swapAt(t + 1, t + 2) } }
                    s.recomputeNormals(weldSeams: false); s.computeTangents()
                    return s
                }
                put(shellH(inset: 0, cols: nu), "helmet")
                put(shellH(inset: 0.007, cols: nu), "helmet")
                // Rolled edges: brow, cheek edges, nose bar edge and neck guard rim.
                func hp(_ y: Float, _ deg: Float) -> V3 { helm(y, Self.rad(deg)) + simd_normalize(V3(sin(Self.rad(deg)), 0, cos(Self.rad(deg)))) * 0.002 }
                let brow = stride(from: Float(-45), through: 45, by: 7.5).map { hp(0.17, $0) }
                put(roll(brow, 0.007, sides: sides, bronze), "helmet")
                for sgn: Float in [-1, 1] {
                    let cheek = stride(from: Float(0.17), through: -0.035, by: -0.034).map { hp($0, sgn * 45) }
                    put(roll(cheek, 0.0055, sides: sides, bronze), "helmet")
                    let nose = stride(from: Float(0.17), through: 0.016, by: -0.026).map { hp($0, sgn * 3.2) }
                    put(roll(nose, 0.004, sides: 5, bronze), "helmet")
                }
                let neck = stride(from: Float(45), through: 315, by: 11.25).map { hp(-0.035, $0) }
                put(roll(neck, 0.0065, sides: sides, bronze), "helmet")
                let chin = stride(from: Float(-45), through: 45, by: 15).map { hp(-0.035, $0) }
                put(roll(chin, 0.0055, sides: 5, bronze), "helmet")

                // Crest stand (driver part) and horsehair (swaying part).
                let arc = catmull([V3(0, 0.222, 0.108), V3(0, 0.262, 0.075), V3(0, 0.284, 0.015), V3(0, 0.272, -0.055),
                                   V3(0, 0.235, -0.108), V3(0, 0.185, -0.135)], per: hi ? 4 : 2)
                put(Prim.tube(arc, radii: arc.map { _ in 0.011 }, sides: hi ? 8 : 5, seamTile: 0.04, material: bronze, capEnd: true), "crest")
                var rings: [[V3]] = []
                for (i, c) in arc.enumerated() {
                    let t = Float(i) / Float(arc.count - 1)
                    let up = simd_normalize(c - V3(0, 0.12, 0.015))
                    let h: Float = 0.06 + 0.035 * sin(.pi * t) + 0.012 * jit[i % jit.count]
                    let w: Float = 0.017 + 0.006 * sin(.pi * t)
                    rings.append([c - X * (w * 0.5) + up * 0.006, c - X * w + up * (h * 0.5), c - X * (w * 0.5) + up * h,
                                  c + X * (w * 0.5) + up * h, c + X * w + up * (h * 0.5), c + X * (w * 0.5) + up * 0.006])
                }
                var hair = Prim.loft(rings, capStart: true, capEnd: true, material: crestHair)
                WoodParts.orientOutward(&hair) { p in arc.min(by: { simd_distance($0, p) < simd_distance($1, p) })! }
                hair.recomputeNormals(weldSeams: false); hair.computeTangents()
                put(hair, "crestSway")
            }

            // MARK: Pauldrons: three overlapping lames per shoulder with rolled edges and rivets.
            let lames: [(xi: Float, xo: Float, cy: Float, r: Float)] = [(0.115, 0.215, -0.075, 0.082), (0.145, 0.240, -0.105, 0.092), (0.165, 0.255, -0.135, 0.102)]
            for (side, name) in [(Float(1), "shoulderL"), (Float(-1), "shoulderR")] {
                for (k, m) in lames.enumerated() {
                    let f: (Float, Float) -> V3 = { u, v in
                        let th = Self.rad(-105 + 210 * u)
                        let r = m.r * (0.88 + 0.12 * v)
                        let drop = 0.035 * v * v * (1 + 0.4 * Float(k))
                        return V3(side * (m.xi + v * (m.xo - m.xi)), m.cy + r * 0.92 * cos(th) - drop, r * 1.12 * sin(th))
                    }
                    let ctr: (V3) -> V3 = { V3($0.x, m.cy, 0) }
                    let nu = R(12), nv = R(6)
                    put(gridSurf(nu, nv, bronze, center: ctr, f), name)
                    put(gridSurf(R(6), R(4), bronze, center: ctr, inset: 0.006, f), name)
                    put(roll(border(nu, nv, f), 0.0045, sides: sides, bronze), name)
                    var rp: [(V3, V3)] = []
                    for u: Float in [0.3, 0.7] { let p = f(u, 0.55); rp.append((p, simd_normalize(p - ctr(p)))) }
                    rivets(rp, name)
                }
            }

            // MARK: Vambraces with bands, bore, wrist flare, elbow cops and rivets.
            for (side, name, e) in [(Float(1), "gauntletL", eL), (Float(-1), "gauntletR", eR)] {
                let ys: [Float] = hi ? [-0.27, -0.258, -0.235, -0.215, -0.195, -0.165, -0.145, -0.125, -0.095, -0.075, -0.055, -0.03, 0]
                                     : [-0.27, -0.235, -0.195, -0.145, -0.095, -0.055, 0]
                put(Prim.lathe(ys.map { V2(vambrace($0), $0) }, segments: hi ? 36 : 16, seamTile: 0.1, material: bronze), name, Xform(translation: e))
                let bore: [Float] = [0, -0.135, -0.27]
                put(Prim.lathe(bore.map { V2(vambrace($0) - 0.0045, $0) }, segments: hi ? 24 : 12, seamTile: 0.1, material: bronze), name, Xform(translation: e))
                let cup: [V2] = [V2(0.058, 0), V2(0.060, 0.012), V2(0.052, 0.028), V2(0.036, 0.040), V2(0.018, 0.047), V2(0.001, 0.049)]
                put(Prim.lathe(cup, segments: hi ? 24 : 12, seamTile: 0.1, material: bronze), name,
                    Xform(translation: e + V3(0, 0.02, 0), rotation: simd_quatf(from: Y, to: -Z)))
                var rp: [(V3, V3)] = []
                for k in 0..<6 {
                    let a = 2 * .pi * Float(k) / 6
                    let n = V3(cos(a), 0, sin(a))
                    rp.append((e + V3(0, -0.255, 0) + n * (vambrace(-0.255) + 0.001), n))
                }
                rivets(rp, name)
                _ = side
            }

            // MARK: Cape: folded wool strip (two shells) with a collar roll and a bronze-tone hem trim.
            do {
                let nu = R(20), nv = R(14)
                let cf: (Float, Float) -> V3 = { u, v in
                    let hw = 0.17 + 0.14 * pow(v, 0.8)
                    let x = (2 * u - 1) * hw
                    let fold = 0.022 * sin(x * 34 + v * 3 + foldA) * smoothstep(0.05, 0.4, v) + 0.012 * sin(x * 61 - v * 2 + foldB) * smoothstep(0.1, 0.5, v)
                    let y = -0.03 - 1.19 * v - 0.04 * (x / hw) * (x / hw) * v
                    let z = -0.105 - 0.10 * smoothstep(0, 0.18, v) - 0.07 * v + fold
                    return V3(x, y, z)
                }
                put(gridSurf(nu, nv, capeCloth, center: { V3($0.x, $0.y, $0.z - 3) }) { u, v in cf(u, v) + V3(0, 0, 0.003) }, "capeSway")
                put(gridSurf(nu, nv, capeCloth, center: { V3($0.x, $0.y, $0.z + 3) }) { u, v in cf(u, v) - V3(0, 0, 0.003) }, "capeSway")
                let hem = (0...nu).map { cf(Float($0) / Float(nu), 1) }
                put(roll(hem, 0.006, sides: 5, bronze), "capeSway")
                let collar = catmull([V3(-0.17, -0.05, -0.085), V3(-0.08, -0.03, -0.095), V3(0.08, -0.03, -0.095), V3(0.17, -0.05, -0.085)], per: hi ? 4 : 2)
                put(roll(collar, 0.012, sides: hi ? 8 : 5, capeCloth), "cape")
            }

            // MARK: Hoplon: dished bronze face with rolled rim, concentric ridges, liner, lambda, rivets and arm straps.
            do {
                let qS = simd_quatf(angle: .pi / 2, axis: X)
                let xf = Xform(translation: C, rotation: qS)
                var prof: [V2] = [V2(0.424, -0.010), V2(0.4355, -0.002), V2(0.4355, 0.007), V2(0.424, 0.0125)]
                let rs: [Float] = hi ? [0.395, 0.355, 0.335, 0.322, 0.29, 0.25, 0.24, 0.23, 0.17, 0.11, 0.06, 0.001] : [0.395, 0.335, 0.25, 0.17, 0.08, 0.001]
                prof += rs.map { V2($0, hoplonY($0)) }
                var face = Prim.lathe(prof, segments: hi ? 56 : 24, seamTile: 0.2, material: bronze)
                WoodParts.orientOutward(&face) { _ in V3(0, -0.3, 0) }
                face.recomputeNormals(); face.computeTangents()
                put(face, "shieldRaise", xf)
                let inner: [V2] = [0.001, 0.09, 0.17, 0.25, 0.33, 0.40].map { V2($0, hoplonY($0) - 0.012) }
                var liner = Prim.lathe(inner, segments: hi ? 40 : 16, seamTile: 0.2, material: bronze)
                WoodParts.orientOutward(&liner) { _ in V3(0, 0.6, 0) }
                liner.recomputeNormals(); liner.computeTangents()
                put(liner, "shieldRaise", xf)
                // Raised lambda.
                for sgn: Float in [-1, 1] {
                    let pts: [V3] = (0...6).map { i in
                        let s = Float(i) / 6
                        let x = sgn * 0.16 * pow(s, 1.15), z = -0.19 + 0.40 * s
                        return V3(x, hoplonY(simd_length(V2(x, z))) + 0.010, z)
                    }
                    put(Prim.tube(pts, radii: pts.indices.map { 0.015 - 0.003 * Float($0) / 6 }, sides: hi ? 10 : 6, seamTile: 0.05, material: bronze, capEnd: true), "shieldRaise", xf)
                }
                var rp: [(V3, V3)] = []
                for k in 0..<16 {
                    let a = 2 * .pi * Float(k) / 16
                    let lp = V3(0.41 * sin(a), hoplonY(0.41) + 0.001, 0.41 * cos(a))
                    rp.append((C + qS.act(lp), qS.act(Y)))
                }
                rivets(rp, "shieldRaise", scale: 1.3)
                // Arm straps from the vambrace to the shield back.
                for y: Float in [-0.40, -0.55] {
                    put(Prim.tube([V3(0.235, y, 0.05), V3(0.25, y, 0.11), V3(0.265, y, 0.17)], radii: [0.013, 0.012, 0.012], sides: hi ? 8 : 5, seamTile: 0.04, material: leather, capEnd: true), "shieldRaise")
                }
            }

            // MARK: Spear: ash shaft, leather grip, iron socket and leaf blade, bronze butt spike.
            do {
                let sx = H.x, sz = H.z
                var sh = Prim.tube([V3(sx, -1.07, sz), V3(sx, -0.20, sz), V3(sx, 0.68, sz)], radii: [0.016, 0.0165, 0.014], sides: hi ? 16 : 8, seamTile: 0.1, material: shaft, capEnd: true)
                sh.uvs = sh.uvs.map { V2($0.y, $0.x) }; sh.computeTangents()
                put(sh, "spearPush")
                put(Prim.tube([V3(sx, -0.68, sz), V3(sx, -0.54, sz)], radii: [0.0195, 0.0195], sides: hi ? 12 : 6, seamTile: 0.05, material: leather, capEnd: true), "spearPush")
                let socket: [V2] = [V2(0.020, 0.66), V2(0.0185, 0.69), V2(0.0215, 0.72), V2(0.017, 0.76), V2(0.011, 0.78)]
                put(Prim.lathe(socket, segments: hi ? 16 : 8, seamTile: 0.05, material: iron), "spearPush", Xform(translation: V3(sx, 0, sz)))
                let butt: [V2] = [V2(0.001, -1.17), V2(0.010, -1.12), V2(0.018, -1.085), V2(0.020, -1.065)]
                put(Prim.lathe(butt, segments: hi ? 12 : 6, seamTile: 0.05, material: bronze), "spearPush", Xform(translation: V3(sx, 0, sz)))
                let nb = hi ? 8 : 4
                var centers: [V3] = []
                let bladeRings: [[V3]] = (0...nb).map { i in
                    let t = Float(i) / Float(nb)
                    let c = V3(sx, 0.76 + 0.23 * t, sz)
                    centers.append(c)
                    let hw = 0.038 * sin(.pi * pow(max(t, 0.0001), 0.62)) * (1 - 0.25 * t) + 0.002
                    let th: Float = 0.007 * (1 - 0.8 * t) + 0.0015
                    return [c - X * hw, c - X * hw * 0.4 + Z * th, c + X * hw * 0.4 + Z * th, c + X * hw, c + X * hw * 0.4 - Z * th, c - X * hw * 0.4 - Z * th]
                }
                var blade = Prim.loft(bladeRings, capStart: false, capEnd: true, material: iron)
                WoodParts.orientOutward(&blade) { p in V3(sx, p.y, sz) }
                blade.recomputeNormals(weldSeams: false); blade.computeTangents()
                put(blade, "spearPush")
            }
        }

        rig.states = [
            RigState("stand", ["cape": 0, "crest": 0, "shield": 0, "spear": 0]),
            RigState("guard", ["cape": 0, "crest": 0, "shield": 1, "spear": 0]),
            RigState("thrust", ["cape": 0.6, "crest": 0.5, "shield": 0.3, "spear": 1]),
            RigState("sway-left", ["cape": -1, "crest": -1, "shield": 0, "spear": 0]),
            RigState("sway-right", ["cape": 1, "crest": 1, "shield": 0, "spear": 0]),
        ]
        return rig
    }
}
