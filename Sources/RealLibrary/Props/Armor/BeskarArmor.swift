import simd
import Foundation

/// Beskar armor kit for a 1.75 m wearer: brushed silver plates with beveled rims, rivets and seam grooves, a T-visor
/// bucket helmet with a dorsal ridge, jetpack on the back with twin bell nozzles, wrist flamethrower on the left
/// gauntlet, pop-up rocket in the right shoulder. Origin at the neck base when assembled, +Z front, +X wearer's left.
/// Each part is modelled in assembled space and pivots at its body joint so a lens can reparent it to that joint.
///
/// Parts: `helmet`, `chest`, `back`, `shoulderL`, `shoulderR`, `gauntletL`, `gauntletR`.
/// Joints (0...1): `visor` lights the T-visor, `thrust` lights the jet flames, `flame` lights the wrist flame,
/// `rocket` raises the shoulder rocket 0.2 m out of its tube.
public struct BeskarArmor: RealArticulated {
    public static let id = "beskar-armor"
    public static let summary = "Brushed silver beskar armor kit: T-visor helmet, chest and abdomen plates, pauldrons, gauntlets, jetpack, wrist flamethrower and shoulder rocket."
    public static let tags = ["prop", "fantasy", "metal", "articulated"]
    public static let budget = 20_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 8, distance: 1.0)

    /// Armor plates, brushed silver.
    public var plateMat: MaterialKey = "metal.stainless"
    /// Helmet bucket, jetpack housing, rocket body.
    public var bodyMat: MaterialKey = "metal.titanium"
    /// Seam grooves, nozzles, launcher housing.
    public var darkMat: MaterialKey = "metal.iron"
    /// Belt, pouches.
    public var leatherMat: MaterialKey = "leather.black"
    /// Rivet heads.
    public var rivetMat: MaterialKey = "metal.chrome"
    /// Rocket nose and band.
    public var paintMat: MaterialKey = "metal.painted:A82A1E"
    public var visorDark: MaterialKey = "glass.lens-coated"
    public var visorLit: MaterialKey = "emissive.warm"
    public var flameMat: MaterialKey = "emissive.flame"
    public init() {}

    static let rocketLift: Float = 0.2

    // MARK: helpers

    func aim(_ d: V3) -> simd_quatf {
        let n = simd_normalize(d)
        if n.y < -0.9999 { return simd_quatf(angle: .pi, axis: V3(1, 0, 0)) }
        return simd_quatf(from: V3(0, 1, 0), to: n)
    }

    /// Sample positions across a plate, dense toward the rim where the bevel rolls.
    func samples(_ hi: Bool) -> [Float] {
        let inner = hi ? 3 : 1
        let mid: [Float] = (0...inner).map { -0.8 + 1.6 * Float($0) / Float(inner) }
        let edge: [Float] = [0.9, 0.95, 0.985, 1.0]
        return edge.reversed().map { -$0 } + mid + edge
    }

    /// Curved plate in local XY facing +Z: superellipse outline (rounded corners), rim rolled back by `t` into an
    /// inner skin so the edge has real thickness and a bevel. z = -(kx x^2 + ky y^2) bends it around the body.
    func plate(_ w: Float, _ h: Float, kx: Float, ky: Float, t: Float = 0.007, hi: Bool, _ mat: MaterialKey) -> Surface {
        let ss = samples(hi), n = ss.count
        func pt(_ sx: Float, _ sy: Float, inner: Bool) -> V3 {
            let m = max(abs(sx), abs(sy))
            let r = pow(pow(abs(sx), 4) + pow(abs(sy), 4), 0.25)
            let k: Float = r > 1e-6 ? m / r : 1
            let x = sx * k * w / 2, y = sy * k * h / 2
            let e = saturate((m - 0.9) / 0.1)
            return V3(x, y, -(kx * x * x + ky * y * y) - (inner ? t : t * e * e))
        }
        var s = Surface(material: mat)
        for side in 0..<2 {
            let base = UInt32(s.positions.count)
            for sx in ss { for sy in ss {
                let p = pt(sx, sy, inner: side == 1)
                s.add(p, V3(0, 0, side == 0 ? 1 : -1), V2(p.x * 2.2, p.y * 2.2))
            }}
            let wd = UInt32(n)
            for i in 0..<(n - 1) { for j in 0..<(n - 1) {
                let a = base + UInt32(i * n + j)
                if side == 0 { s.quad(a, a + wd, a + wd + 1, a + 1) } else { s.quad(a, a + 1, a + wd + 1, a + wd) }
            }}
        }
        s.recomputeNormals(weldSeams: false)
        s.computeTangents()
        return s
    }

    /// Places a local plate: +Z to `n`, local X along `wide` projected onto the plate plane.
    func place(_ s: Surface, _ p: V3, _ n: V3, wide: V3 = V3(1, 0, 0)) -> Surface {
        let z = simd_normalize(n)
        var x = wide - z * simd_dot(wide, z)
        if simd_length(x) < 1e-4 { x = V3(0, 1, 0) - z * z.y }
        x = simd_normalize(x)
        let y = simd_cross(z, x)
        return s.transformed(Xform(translation: p, rotation: simd_quatf(simd_float3x3(columns: (x, y, z)))))
    }

    /// Closed-ring skin over `rows` x `seg` with a parametric point; faces oriented away from `center`.
    func skin(rows: Int, seg: Int, mat: MaterialKey, uvScale: V2, point: (Float, Float) -> V3, center: (V3) -> V3) -> Surface {
        var s = Surface(material: mat)
        for i in 0...rows { for k in 0...seg {
            let t = Float(i) / Float(rows), u = Float(k) / Float(seg)
            s.add(point(t, u * 2 * .pi), .up, V2(u * uvScale.x, t * uvScale.y))
        }}
        let row = UInt32(seg + 1)
        for i in 0..<rows { for k in 0..<seg {
            let a = UInt32(i) * row + UInt32(k)
            s.quad(a, a + 1, a + row + 1, a + row)
        }}
        WoodParts.orientOutward(&s, center: center)
        s.recomputeNormals(weldSeams: false)
        s.computeTangents()
        return s
    }

    func superPow(_ c: Float, _ e: Float) -> Float { (c < 0 ? -1 : 1) * pow(abs(c), 2 / e) }

    /// Helmet bucket surface, t 0 = neck opening, 1 = crown; a = 0 wearer's left, pi/2 front.
    func helmetPoint(_ t: Float, _ a: Float) -> V3 {
        let dome: Float = t > 0.68 ? sqrt(max(0.0004, 1 - pow((t - 0.68) / 0.32, 2))) : 1
        let f = (0.8 + 0.2 * smoothstep(0, 0.2, t)) * dome
        let e: Float = 2.6
        return V3(0.105 * f * superPow(cos(a), e), 0.02 + 0.30 * t, 0.012 + 0.122 * f * superPow(sin(a), e))
    }
    func helmetOut(_ t: Float, _ a: Float, _ off: Float) -> V3 {
        let p = helmetPoint(t, a)
        return p + simd_normalize(V3(p.x, (p.y - 0.17) * 0.5, p.z - 0.012)) * off
    }

    func seam(_ path: [V3], _ r: Float, hi: Bool, _ mat: MaterialKey) -> Surface {
        Prim.tube(path, radii: path.map { _ in r }, sides: hi ? 8 : 5, seamTile: 0.05, material: mat, capEnd: true)
    }

    func rivet(_ p: V3, _ n: V3, r: Float = 0.0045) -> Surface {
        let h = r * 0.75
        let prof = [V2(r, 0), V2(r * 0.92, h * 0.5), V2(r * 0.55, h * 0.92), V2(0, h)]
        return Prim.lathe(prof, segments: 8, seamTile: 0.05, material: rivetMat).transformed(Xform(translation: p, rotation: aim(n)))
    }

    func flameCone(length: Float, radius: Float) -> Surface {
        let prof = [V2(0, 0), V2(radius * 0.8, 0), V2(radius, length * 0.1), V2(radius * 0.85, length * 0.35),
                    V2(radius * 0.5, length * 0.65), V2(radius * 0.2, length * 0.88), V2(0, length)]
        return Prim.lathe(prof, segments: 24, seamTile: 0.1, material: flameMat)
    }

    // MARK: rig

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [3])
        let Y = V3(0, 1, 0), Z = V3(0, 0, 1)

        // Drivers first so mimics and option links resolve.
        for d in ["visor", "thrust", "flame", "rocket"] { _ = rig.part(d, pivot: .zero, joint: .hinge(axis: Y, 0...1, duration: 0.4)) }

        rig.part("helmet", pivot: .zero, joint: .fixed)
        rig.part("visorGlow", parent: "helmet", pivot: .zero, joint: .fixed, options: 2)
        rig.part("chest", pivot: V3(0, -0.15, 0.09), joint: .fixed)
        rig.part("back", pivot: V3(0, -0.12, -0.10), joint: .fixed)
        rig.part("jetFlame", parent: "back", pivot: V3(0, -0.44, -0.19), joint: .fixed, options: 2)
        rig.part("shoulderL", pivot: V3(0.19, -0.04, 0), joint: .fixed)
        rig.part("shoulderR", pivot: V3(-0.19, -0.04, 0), joint: .fixed)
        let rocketBase = V3(-0.205, 0, -0.03)
        rig.part("rocketBody", parent: "shoulderR", pivot: rocketBase + V3(0, -0.095, 0),
                 joint: Joint(.prismatic, axis: Y, range: 0...Self.rocketLift, mimic: .init("rocket", ratio: Self.rocketLift)))
        rig.part("gauntletL", pivot: V3(0.222, -0.34, 0), joint: .fixed)
        rig.part("wristFlame", parent: "gauntletL", pivot: V3(0.268, -0.52, 0.04), joint: .fixed, options: 2)
        rig.part("gauntletR", pivot: V3(-0.222, -0.34, 0), joint: .fixed)
        rig.optionLinks = [RigOptionLink(part: "visorGlow", joint: "visor", thresholds: [0.5]),
                           RigOptionLink(part: "jetFlame", joint: "thrust", thresholds: [0.5]),
                           RigOptionLink(part: "wristFlame", joint: "flame", thresholds: [0.5])]

        let wristDir = simd_normalize(V3(0, -0.9, 0.42))
        let wristBase = V3(0.268, -0.52, 0.04)

        for l in 0..<2 {
            let hi = l == 0
            func add(_ s: Surface, _ part: String, option: Int = 0) { rig.add(s, to: part, option: option, lods: l...l) }
            func rv(_ p: V3, _ n: V3, _ part: String, r: Float = 0.0045) { if hi { add(rivet(p, n, r: r), part) } }

            // MARK: helmet
            let rows = hi ? 18 : 9, seg = hi ? 36 : 18
            add(skin(rows: rows, seg: seg, mat: bodyMat, uvScale: V2(0.7, 0.45), point: helmetPoint,
                     center: { p in V3(0, min(p.y, 0.2), 0.012) }), "helmet")
            add(Prim.torus(major: 0.098, minor: 0.011, segments: hi ? 40 : 20, sides: 8, material: leatherMat)
                .transformed(Xform(translation: V3(0, 0.03, 0.01))), "helmet")
            // Dorsal ridge over the crown.
            do {
                let n = hi ? 9 : 5
                var pts: [V3] = []
                for i in 0...n { let t = 0.7 + 0.3 * Float(i) / Float(n); pts.append(helmetOut(t, .pi / 2, 0.004)) }
                for i in 1...n { let t = 1.0 - 0.3 * Float(i) / Float(n); pts.append(helmetOut(t, 3 * .pi / 2, 0.004)) }
                let radii: [Float] = pts.indices.map { 0.005 + 0.007 * sin(Float($0) / Float(pts.count - 1) * .pi) }
                add(Prim.tube(pts, radii: radii, sides: hi ? 12 : 6, seamTile: 0.05, material: plateMat, capEnd: true), "helmet")
            }
            // Brow band and cheek seams.
            let brow = (0...10).map { helmetOut(0.69, .pi / 2 + (Float($0) - 5) * 0.15, 0.004) }
            add(seam(brow, 0.0055, hi: hi, plateMat), "helmet")
            for sgn: Float in [1, -1] {
                let cheek = (0...6).map { helmetOut(0.08 + 0.4 * Float($0) / 6, .pi / 2 + sgn * 0.95, 0.002) }
                add(seam(cheek, 0.0028, hi: hi, darkMat), "helmet")
                let ear = place(plate(0.07, 0.085, kx: 6, ky: 4, hi: hi, plateMat), V3(sgn * 0.109, 0.15, 0.005), V3(sgn, 0, 0), wide: Z)
                add(ear, "helmet")
                rv(V3(sgn * 0.113, 0.17, 0.025), V3(sgn, 0, 0), "helmet")
                rv(V3(sgn * 0.113, 0.13, -0.015), V3(sgn, 0, 0), "helmet")
            }
            // T-visor: dark glass at rest (option 0), emissive when lit (option 1).
            do {
                let bandRows = hi ? 3 : 1, bandSeg = hi ? 12 : 6
                for opt in 0..<2 {
                    let mat = opt == 0 ? visorDark : visorLit
                    var band = Surface(material: mat)
                    // Horizontal bar, then the vertical stem.
                    for (t0, t1, aSpan, lowT) in [(Float(0.55), Float(0.66), Float(0.72), Float(0)), (0.22, 0.55, 0.13, 0.3)] {
                        let base = UInt32(band.positions.count)
                        for i in 0...bandRows { for k in 0...bandSeg {
                            let v = Float(i) / Float(bandRows), u = Float(k) / Float(bandSeg)
                            let t = lerp(t0, t1, v)
                            // Stem narrows toward the chin; the bar is full width.
                            let span = aSpan * (lowT > 0 ? lerp(0.55, 1, v) : 1)
                            let p = helmetOut(t, .pi / 2 + (u - 0.5) * 2 * span, 0.0025)
                            band.add(p, simd_normalize(V3(p.x, 0, p.z - 0.012)), V2(u, v))
                        }}
                        let row = UInt32(bandSeg + 1)
                        for i in 0..<bandRows { for k in 0..<bandSeg {
                            let a = base + UInt32(i) * row + UInt32(k)
                            band.quad(a, a + row, a + row + 1, a + 1)
                        }}
                    }
                    band.recomputeNormals(weldSeams: false)
                    band.computeTangents()
                    add(band, "visorGlow", option: opt)
                }
            }

            // MARK: chest and abdomen
            add(Prim.torus(major: 0.115, minor: 0.016, segments: hi ? 40 : 20, sides: 8, material: bodyMat)
                .transformed(Xform(translation: V3(0, -0.012, 0.0), scale: V3(1, 1, 0.82))), "chest")
            for sgn: Float in [1, -1] {
                let pec = plate(0.175, 0.17, kx: 2.6, ky: 0.9, hi: hi, plateMat)
                add(place(pec, V3(sgn * 0.098, -0.15, 0.108), V3(sgn * 0.22, 0.12, 1)), "chest")
                let rib = plate(0.19, 0.2, kx: 3.0, ky: 0.6, hi: hi, plateMat)
                add(place(rib, V3(sgn * 0.178, -0.24, 0.0), V3(sgn, -0.04, 0.12), wide: Z), "chest")
                rv(V3(sgn * 0.045, -0.095, 0.128), V3(sgn * 0.2, 0.1, 1), "chest")
                rv(V3(sgn * 0.15, -0.095, 0.115), V3(sgn * 0.5, 0.1, 1), "chest")
                rv(V3(sgn * 0.045, -0.205, 0.123), V3(sgn * 0.2, 0.1, 1), "chest")
                rv(V3(sgn * 0.15, -0.205, 0.11), V3(sgn * 0.5, 0.1, 1), "chest")
                rv(V3(sgn * 0.186, -0.17, 0.05), V3(sgn, 0, 0.2), "chest")
            }
            // Center keel and abdomen bands.
            add(seam((0...6).map { V3(0, -0.04 - 0.045 * Float($0), 0.122) }, 0.004, hi: hi, darkMat), "chest")
            for k in 0..<3 {
                let y = -0.338 - 0.072 * Float(k)
                let band = plate(0.27 - 0.012 * Float(k), 0.078, kx: 3.4, ky: 0, t: 0.006, hi: hi, plateMat)
                add(place(band, V3(0, y, 0.106 - 0.003 * Float(k)), V3(0, -0.14, 1)), "chest")
                add(seam((0...8).map { i in let x = -0.12 + 0.03 * Float(i); return V3(x, y + 0.038, 0.098 - 0.003 * Float(k) - 3.4 * x * x) }, 0.0024, hi: hi, darkMat), "chest")
                rv(V3(-0.1 + 0.0, y, 0.1 - 0.003 * Float(k) - 3.4 * 0.01), V3(0, 0, 1), "chest", r: 0.004)
                rv(V3(0.1, y, 0.1 - 0.003 * Float(k) - 3.4 * 0.01), V3(0, 0, 1), "chest", r: 0.004)
            }
            // Belt, buckle plate, pouches.
            add(Prim.torus(major: 0.14, minor: 0.017, segments: hi ? 40 : 20, sides: 8, material: leatherMat)
                .transformed(Xform(translation: V3(0, -0.565, 0), scale: V3(1.05, 1, 0.82))), "chest")
            add(place(plate(0.06, 0.05, kx: 2, ky: 0, t: 0.005, hi: hi, bodyMat), V3(0, -0.565, 0.115), Z), "chest")
            if hi { for sgn: Float in [1, -1] {
                add(Prim.roundedBox(V3(0.05, 0.06, 0.035), radius: 0.008, bevelSegments: 2, material: leatherMat)
                    .transformed(Xform(translation: V3(sgn * 0.085, -0.6, 0.095))), "chest")
            }}

            // MARK: back and jetpack
            add(place(plate(0.3, 0.3, kx: 2.4, ky: 0.5, hi: hi, plateMat), V3(0, -0.17, -0.113), V3(0, 0, -1)), "back")
            add(Prim.roundedBox(V3(0.15, 0.30, 0.09), radius: 0.02, bevelSegments: 2, material: bodyMat)
                .transformed(Xform(translation: V3(0, -0.19, -0.19))), "back")
            for sy: Float in [-0.12, -0.28] { for sx: Float in [-0.05, 0.05] {
                add(cuboid(V3(0.03, 0.03, 0.04), material: darkMat).transformed(Xform(translation: V3(sx, sy, -0.133))), "back")
            }}
            let tank = [V2(0, -0.365), V2(0.03, -0.36), V2(0.042, -0.345), V2(0.042, -0.05), V2(0.034, -0.035), V2(0.02, -0.028), V2(0, -0.025)]
            let bell = [V2(0.026, -0.35), V2(0.03, -0.37), V2(0.036, -0.40), V2(0.043, -0.44), V2(0.04, -0.44), V2(0.032, -0.40), V2(0.025, -0.37), V2(0.022, -0.35)]
            for sgn: Float in [1, -1] {
                let c = V3(sgn * 0.10, 0, -0.19)
                add(Prim.lathe(tank, segments: hi ? 40 : 20, seamTile: 0.1, material: plateMat).transformed(Xform(translation: c)), "back")
                add(Prim.lathe(bell, segments: hi ? 32 : 16, seamTile: 0.1, material: darkMat).transformed(Xform(translation: c)), "back")
                add(flameCone(length: 0.42, radius: 0.04).transformed(Xform(translation: V3(sgn * 0.10, -0.44, -0.19), rotation: aim(V3(0, -1, 0)))), "jetFlame", option: 1)
                add(seam((0...4).map { V3(sgn * 0.06 + 0, -0.10 - 0.05 * Float($0), -0.236) }, 0.003, hi: hi, darkMat), "back")
                rv(V3(sgn * 0.13, -0.19, -0.136 - 0.0), V3(sgn * 0.3, 0, -1), "back")
            }
            rv(V3(-0.12, -0.04, -0.115), V3(0, 0, -1), "back"); rv(V3(0.12, -0.04, -0.115), V3(0, 0, -1), "back")
            rv(V3(-0.12, -0.30, -0.115), V3(0, 0, -1), "back"); rv(V3(0.12, -0.30, -0.115), V3(0, 0, -1), "back")

            // MARK: pauldrons and shoulder rocket
            for sgn: Float in [1, -1] {
                let name = sgn > 0 ? "shoulderL" : "shoulderR"
                for k in 0..<3 {
                    let th = radians([48, 68, 86][k])
                    let n = simd_normalize(V3(sgn * sin(th), cos(th), 0))
                    let c = V3(sgn * 0.19, -0.035, 0) + n * 0.085 + V3(0, -0.014 * Float(k), 0)
                    add(place(plate(0.17 - 0.012 * Float(k), 0.115, kx: 4.5, ky: 3, hi: hi, plateMat), c, n, wide: Z), name)
                    rv(c + n * 0.003 + V3(0, 0, 0.05), n, name); rv(c + n * 0.003 + V3(0, 0, -0.05), n, name)
                }
            }
            do {
                let housing = [V2(0.029, -0.10), V2(0.036, -0.10), V2(0.036, 0.045), V2(0.033, 0.05), V2(0.029, 0.05), V2(0.029, -0.10)]
                add(Prim.lathe(housing, segments: hi ? 32 : 16, seamTile: 0.1, material: darkMat).transformed(Xform(translation: rocketBase)), "shoulderR")
                add(Prim.torus(major: 0.034, minor: 0.005, segments: hi ? 32 : 16, sides: 8, material: bodyMat)
                    .transformed(Xform(translation: rocketBase + V3(0, 0.05, 0))), "shoulderR")
                // Rocket, modelled at its popped-down rest in part space (pivot at its base).
                let o = rocketBase + V3(0, -0.095, 0)
                let bodyP = [V2(0, 0), V2(0.02, 0), V2(0.02, 0.1)]
                let noseP = [V2(0.02, 0.1), V2(0.0185, 0.108), V2(0.012, 0.125), V2(0.005, 0.137), V2(0, 0.145)]
                let segs = hi ? 32 : 16
                add(Prim.lathe(bodyP, segments: segs, seamTile: 0.05, material: bodyMat).transformed(Xform(translation: o)), "rocketBody")
                add(Prim.lathe(noseP, segments: segs, seamTile: 0.05, material: paintMat).transformed(Xform(translation: o)), "rocketBody")
                add(Prim.lathe([V2(0.0204, 0.03), V2(0.0204, 0.045)], segments: segs, seamTile: 0.05, material: paintMat, swapUV: false)
                    .transformed(Xform(translation: o)), "rocketBody")
                for i in 0..<4 {
                    let a = Float(i) * .pi / 2
                    let q = simd_quatf(angle: a, axis: Y)
                    add(cuboid(V3(0.012, 0.03, 0.003), material: paintMat).transformed(Xform(translation: o + q.act(V3(0.024, 0.02, 0)), rotation: q)), "rocketBody")
                }
            }

            // MARK: gauntlets
            for sgn: Float in [1, -1] {
                let name = sgn > 0 ? "gauntletL" : "gauntletR"
                let cx: Float = sgn * 0.222
                func rad(_ t: Float) -> Float { lerp(0.052, 0.040, t) + 0.006 * smoothstep(0.85, 1, t) }
                let sleeve = skin(rows: hi ? 7 : 3, seg: hi ? 36 : 18, mat: bodyMat, uvScale: V2(0.4, 0.5), point: { t, a in
                    V3(cx + rad(t) * superPow(cos(a), 2.4), -0.36 - 0.24 * t, 0.9 * rad(t) * superPow(sin(a), 2.4))
                }, center: { p in V3(cx, p.y, 0) })
                add(sleeve, name)
                add(Prim.torus(major: rad(1), minor: 0.006, segments: hi ? 40 : 20, sides: 8, material: plateMat)
                    .transformed(Xform(translation: V3(cx, -0.60, 0))), name)
                add(place(plate(0.2, 0.095, kx: 0.5, ky: 8, hi: hi, plateMat), V3(cx + sgn * 0.043, -0.47, 0.012), V3(sgn, 0, 0.35), wide: Y), name)
                add(place(plate(0.1, 0.075, kx: 0.5, ky: 8, hi: hi, plateMat), V3(cx + sgn * 0.038, -0.365, 0.01), V3(sgn, 0.3, 0.3), wide: Y), name)
                rv(V3(cx + sgn * 0.052, -0.40, 0.03), V3(sgn, 0, 0.35), name); rv(V3(cx + sgn * 0.046, -0.54, 0.03), V3(sgn, 0, 0.35), name)
            }
            // Wrist flamethrower on the left gauntlet.
            add(Prim.roundedBox(V3(0.05, 0.12, 0.045), radius: 0.011, bevelSegments: 2, material: darkMat)
                .transformed(Xform(translation: V3(0.268, -0.485, 0.02))), "gauntletL")
            let nozzle = [V2(0.013, 0), V2(0.017, 0.012), V2(0.02, 0.05), V2(0.024, 0.07), V2(0.02, 0.07), V2(0.015, 0.05), V2(0.011, 0.012)]
            add(Prim.lathe(nozzle, segments: hi ? 28 : 14, seamTile: 0.1, material: bodyMat)
                .transformed(Xform(translation: wristBase, rotation: aim(wristDir))), "gauntletL")
            add(flameCone(length: 0.42, radius: 0.026).transformed(Xform(translation: wristBase + wristDir * 0.07, rotation: aim(wristDir))), "wristFlame", option: 1)
        }

        // Lights switch on with their option.
        rig.lights.append(RigLight(name: "visor", part: "visorGlow", option: 1, position: V3(0, 0.2, 0.2), color: V3(1, 0.55, 0.22), intensity: 60, attenuationRadius: 1.2))
        rig.lights.append(RigLight(name: "jet", part: "jetFlame", option: 1, position: V3(0, -0.6, -0.19), color: V3(1, 0.6, 0.28), intensity: 1800, attenuationRadius: 4))
        rig.lights.append(RigLight(name: "wrist", part: "wristFlame", option: 1, position: wristBase + wristDir * 0.3, color: V3(1, 0.62, 0.3), intensity: 900, attenuationRadius: 3))

        rig.states = [
            RigState("stowed"),
            RigState("visor-lit", ["visor": 1], options: ["visorGlow": 1]),
            RigState("jetpack", ["visor": 1, "thrust": 1], options: ["visorGlow": 1, "jetFlame": 1]),
            RigState("flamethrower", ["visor": 1, "flame": 1], options: ["visorGlow": 1, "wristFlame": 1]),
            RigState("rocket-up", ["visor": 1, "rocket": 1], options: ["visorGlow": 1]),
            RigState("full", ["visor": 1, "thrust": 1, "flame": 1, "rocket": 1], options: ["visorGlow": 1, "jetFlame": 1, "wristFlame": 1]),
        ]
        return rig
    }
}
