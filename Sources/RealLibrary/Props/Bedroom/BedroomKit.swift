import simd
import Foundation

/// Geometry shared by the bedroom pack: tapered square legs, draped bedding, pillows and a full bed
/// assembly parameterised by `BedSpec` (queen, king and twin differ only in the spec).
enum BedroomKit {
    /// Square tapered leg from y = 0 to `height`, `top` and `bottom` full widths, rounded arrises.
    static func taperedLeg(height: Float, top: Float, bottom: Float, radius: Float = 0.004, material: MaterialKey) -> Surface {
        let rings = [Float(0), 0.5, 1].map { t -> [V3] in
            let w = bottom + (top - bottom) * t
            return Prim.ring(Shape2D.roundedRect(w, w, radius: radius, segments: 2), y: height * t)
        }
        var s = Prim.loft(rings, capStart: true, capEnd: true, material: material)
        // Wood grain runs vertically: swap UVs.
        s.uvs = s.uvs.map { V2($0.y, $0.x) }
        s.computeTangents()
        return s
    }

    /// Soft fabric drape over a mattress: a superellipsoid whose overhang is pulled in to a thin skirt that hangs
    /// close to the mattress sides and foot, with fbm wrinkles. Local origin at the top-center of the mattress plan
    /// (x across, z along); the top surface sits at y = 0.
    static func drape(width w: Float, length len: Float, thick: Float, hang: Float, material: MaterialKey,
                      subdivisions: Int, wrinkle: Float, seed: UInt32, skirt: Float = 0.2) -> Surface {
        let ex: Float = 0.12
        var s = Prim.superellipsoid(V3(w + 2 * ex, thick + hang, len + 2 * ex), exponent: 5, subdivisions: subdivisions, material: material)
        let hy = (thick + hang) / 2
        s.deform { p in
            var q = p
            q.y = p.y - hy + thick
            let ax = abs(p.x), az = abs(p.z)
            // Fold wrinkles: noise displaces mostly along y on top and along x on the hanging sides.
            let nz = Noise.fbm(V3(p.x * 3.5, p.y * 4, p.z * 3.2), octaves: 3, seed: seed)
            let topW = smoothstep(-0.02, 0.0, q.y + 0.0)
            q.y += (nz - 0.5) * wrinkle * (0.4 + 0.6 * topW)
            let fold = Noise.fbm(V3(p.z * 9, p.y * 3, 0), octaves: 2, seed: seed &+ 7)
            if ax > w / 2 { q.x = sgn(p.x) * (w / 2 + 0.016 + (ax - w / 2) * skirt + max(0, fold) * wrinkle * 0.3 + (0.5 + 0.5 * sin(p.z * 13 + fold * 5)) * 0.016 * smoothstep(0.0, -0.12, q.y)) }
            if az > len / 2 { q.z = sgn(p.z) * (len / 2 + 0.016 + (az - len / 2) * skirt) }
            // Soften the shoulder: lower the surface a little as it approaches the edge.
            let ex2 = smoothstep(0.55, 1.0, max(ax / (w / 2), az / (len / 2)))
            if q.y > -0.05 { q.y -= ex2 * 0.03 }
            return q
        }
        return s
    }

    /// Bed pillow: soft superellipsoid with tapered edges and pinched corners.
    static func pillow(width w: Float, depth d: Float, height h: Float, material: MaterialKey, subdivisions: Int, seed: UInt32, pinch: Float = 0.5) -> Surface {
        var s = Prim.superellipsoid(V3(w, h, d), exponent: 3.2, subdivisions: subdivisions, material: material)
        s.deform { p in
            let fx = abs(p.x) / (w / 2), fz = abs(p.z) / (d / 2)
            let edge = max(fx, fz)
            let corner = fx * fz
            var q = p
            q.y *= 1 - 0.45 * smoothstep(0.5, 1.0, edge)
            // Pinch corners inward, slight middle pillow.
            q.x *= 1 - pinch * 0.06 * corner
            q.z *= 1 - pinch * 0.06 * corner
            q.y += 0.01 * (1 - fx * fx) * (1 - fz * fz) * (p.y > 0 ? 1 : 0)
            q.y += (Noise.fbm(V3(p.x * 9, 0, p.z * 9), octaves: 2, seed: seed) - 0.5) * 0.012 * (p.y > 0 ? 1 : 0)
            return q
        }
        return s
    }

    /// Closed loop (rounded rectangle in plan) for piping seams.
    static func plan(_ w: Float, _ l: Float, y: Float, z: Float, r: Float) -> [V3] {
        Shape2D.roundedRect(w, l, radius: r, segments: 4).map { V3($0.x, y, z - $0.y) }
    }
}

/// Parameters for `BedroomKit.bed`.
struct BedSpec {
    var width: Float, length: Float, headHeight: Float
    var mattressWidth: Float, mattressLength: Float
    var mattressHeight: Float = 0.28
    var wood: MaterialKey = "wood.oak"
    /// Upholstered headboard material; nil builds a solid wood panel headboard.
    var upholstery: MaterialKey? = nil
    var channels: Int = 7
    var footboardHeight: Float = 0.40
    var mattressCover: MaterialKey = "fabric.linen:EFECE5"
    var sheet: MaterialKey = "fabric.linen:F4F2EC"
    var duvet: MaterialKey = "fabric.linen:D9D2C3"
    var throwBlanket: MaterialKey? = nil
    var pillowCount: Int = 2
    var pillowCase: MaterialKey = "fabric.linen:F7F5F0"
    var decor: [MaterialKey] = []
    /// Made bed (true) shows duvet; false leaves the bare mattress.
    var made: Bool = true
}

extension BedroomKit {
    static func bed(_ sp: BedSpec, seed: UInt64, detail: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        let s32 = UInt32(truncatingIfNeeded: seed)
        var m = Model(name: "bed")
        let W = sp.width, L = sp.length, wood = sp.wood
        let railT: Float = 0.035, railTop: Float = 0.30, railBot: Float = 0.12
        let headT: Float = 0.08
        let zHead = -L / 2 + headT                     // front face of the headboard
        let mW = min(sp.mattressWidth, W - 2 * railT - 0.004), mL = sp.mattressLength
        let mH = sp.mattressHeight
        let deckY: Float = 0.27
        let mTop = deckY + mH
        // --- Legs
        let legX = W / 2 - 0.03
        let legTop: Float = railTop + 0.005
        for sx: Float in [-1, 1] {
            for (zi, z) in [-L / 2 + 0.035, L / 2 - 0.025].enumerated() {
                let tall: Float = zi == 0 ? (sp.upholstery == nil ? sp.headHeight : 0.34) : (sp.footboardHeight > 0 ? sp.footboardHeight + 0.06 : legTop)
                m.add(BedroomKit.taperedLeg(height: tall, top: zi == 0 ? 0.06 : 0.05, bottom: zi == 0 ? 0.045 : 0.04, material: wood),
                      Xform(translation: V3(sx * legX, 0, z)))
            }
        }
        // --- Side rails and deck
        for sx: Float in [-1, 1] {
            let (b, x) = board(from: V3(sx * (W / 2 - railT / 2 - 0.005), (railTop + railBot) / 2, -L / 2 + 0.07),
                               to: V3(sx * (W / 2 - railT / 2 - 0.005), (railTop + railBot) / 2, L / 2 - 0.07), width: railTop - railBot, thick: railT, up: V3(sx, 0, 0), bevel: 0.004, material: wood)
            m.add(b, x)
        }
        m.add(cuboid(V3(W - 2 * railT - 0.01, 0.02, L - headT - 0.06), material: "wood.plywood"),
              Xform(translation: V3(0, deckY - 0.01, (zHead + L / 2 - 0.04) / 2)))
        // Ledger strip under each rail the deck rests on.
        for sx: Float in [-1, 1] {
            m.add(plank(L - 0.3, 0.03, 0.03, bevel: 0.002, material: wood),
                  Xform(translation: V3(sx * (W / 2 - railT - 0.017), deckY - 0.035, 0.0), rotation: simd_quatf(degrees: 90, axis: .up)))
        }
        // --- Headboard
        if let up = sp.upholstery {
            let hbBottom: Float = 0.2, hbH = sp.headHeight - hbBottom
            let n = sp.channels, gap: Float = 0.004
            let cw = (W - 2 * 0.012 - Float(n - 1) * gap) / Float(n)
            m.add(Prim.roundedBox(V3(W - 0.02, hbH - 0.03, 0.05), radius: 0.008, bevelSegments: 2, material: wood),
                  Xform(translation: V3(0, hbBottom + hbH / 2 - 0.01, -L / 2 + 0.04)))
            for i in 0..<n {
                let x = -W / 2 + 0.012 + cw / 2 + Float(i) * (cw + gap)
                m.add(Prim.roundedBox(V3(cw, hbH, headT - 0.02), radius: 0.03, bevelSegments: 2, material: up),
                      Xform(translation: V3(x, hbBottom + hbH / 2, -L / 2 + 0.01 + (headT - 0.02) / 2 + 0.03)))
            }
            // Wooden top cap trim.
            m.add(plank(W - 0.02, headT - 0.03, 0.025, bevel: 0.006, material: wood),
                  Xform(translation: V3(0, sp.headHeight - 0.0125, -L / 2 + 0.06)))
            // Seam piping along the channel gaps.
            if detail {
                for i in 1..<n {
                    let x = -W / 2 + 0.012 + Float(i) * (cw + gap) - gap / 2
                    m.add(Prim.tube([V3(x, hbBottom + 0.03, zHead + 0.0005), V3(x, sp.headHeight - 0.05, zHead + 0.0005)], radii: [0.0025, 0.0025], sides: 5, seamTile: 0.05, material: wood))
                }
            }
        } else {
            // Solid wood panel headboard with raised panel and cap.
            let hb: Float = sp.headHeight
            m.add(Prim.roundedBox(V3(W - 0.1, hb - 0.2, headT - 0.03), radius: 0.006, bevelSegments: 2, material: wood),
                  Xform(translation: V3(0, 0.2 + (hb - 0.2) / 2 - 0.03, -L / 2 + 0.04)))
        }
        // --- Footboard
        if sp.footboardHeight > 0 {
            let fh = sp.footboardHeight
            let (b, x) = board(from: V3(-(W / 2 - 0.06), (0.16 + fh) / 2, L / 2 - 0.025), to: V3(W / 2 - 0.06, (0.16 + fh) / 2, L / 2 - 0.025),
                               width: fh - 0.16, thick: 0.03, up: V3(0, 0, 1), bevel: 0.004, material: wood)
            m.add(b, x)
            m.add(plank(W - 0.1, 0.05, 0.03, bevel: 0.006, material: wood), Xform(translation: V3(0, fh + 0.01, L / 2 - 0.025)))
            // Raised panel on the outside face, bordered by a thin bead.
            m.add(Prim.roundedBox(V3(W - 0.26, fh - 0.28, 0.012), radius: 0.004, bevelSegments: 2, material: wood),
                  Xform(translation: V3(0, (0.16 + fh) / 2 - 0.005, L / 2 - 0.006)))
            if detail {
                let bw = W - 0.26 - 0.02, bh = fh - 0.28 - 0.02
                let loop = Shape2D.roundedRect(bw, bh, radius: 0.01, segments: 3).map { V3($0.x, (0.16 + fh) / 2 - 0.005 + $0.y, L / 2 - 0.0005) }
                m.add(Prim.sweep(Shape2D.circle(0.0025, segments: 5), along: loop, closedPath: true, caps: false, material: wood))
            }
        }
        // --- Mattress
        let mz = zHead + 0.012 + mL / 2
        m.add(Prim.roundedBox(V3(mW, mH, mL), radius: 0.045, bevelSegments: 2, material: sp.mattressCover),
              Xform(translation: V3(0, deckY + mH / 2, mz)))
        if detail {
            // Tape-edge piping around the top and bottom borders.
            for yy: Float in [mTop - 0.045, deckY + 0.045] {
                m.add(Prim.sweep(Shape2D.circle(0.0045, segments: 6), along: BedroomKit.plan(mW + 0.002, mL + 0.002, y: yy, z: mz, r: 0.045),
                                 closedPath: true, caps: false, material: sp.mattressCover))
            }
        }
        guard sp.made else { groundAO(&m, height: 0.18, floor: 0.5); return m }
        // --- Fitted sheet band at head and made bedding
        let headZ = zHead + 0.012
        let duvetLen = mL - 0.40
        let dz = headZ + 0.40 + duvetLen / 2 + 0.005
        let duvetS = BedroomKit.drape(width: mW, length: duvetLen, thick: 0.1, hang: 0.34, material: sp.duvet,
                                      subdivisions: detail ? 12 : 6, wrinkle: 0.06, seed: s32, skirt: 0.14)
        m.add(duvetS, Xform(translation: V3(0, mTop - 0.012 + 0.0, dz)))
        // Top sheet folded back over the duvet at the pillow end.
        let foldZ = headZ + 0.40 + 0.09
        var fold = Prim.superellipsoid(V3(mW - 0.03, 0.05, 0.2), exponent: 4, subdivisions: detail ? 6 : 4, material: sp.sheet)
        fold.deform { p in
            var q = p
            q.y += (Noise.fbm(V3(p.x * 6, 0, p.z * 8), octaves: 2, seed: s32 &+ 3) - 0.5) * 0.012
            q.z += sin(p.x * 14) * 0.006
            return q
        }
        m.add(fold, Xform(translation: V3(0, mTop + 0.1 - 0.012 - 0.002 + 0.02, foldZ)))
        // --- Pillows against the headboard
        let pw: Float = min(0.72, (mW - 0.1) / Float(max(1, sp.pillowCount) / 1 > 1 ? Float(sp.pillowCount) : 1) - (sp.pillowCount > 1 ? 0.02 : 0))
        let pc = max(1, sp.pillowCount)
        let pwUse = pc == 1 ? min(0.58, mW - 0.1) : min(0.74, (mW - 0.06) / Float(pc) - 0.01)
        _ = pw
        for i in 0..<pc {
            let x = (Float(i) - Float(pc - 1) / 2) * (pwUse + 0.015)
            let tilt = simd_quatf(degrees: -(14 + rng.float(-2...2)), axis: V3(1, 0, 0)) * simd_quatf(degrees: rng.float(-1.5...1.5), axis: .up)
            m.add(BedroomKit.pillow(width: pwUse, depth: 0.5, height: 0.17, material: sp.pillowCase, subdivisions: detail ? 6 : 4, seed: s32 &+ UInt32(i)),
                  Xform(translation: V3(x, mTop + 0.105, headZ + 0.20), rotation: tilt))
        }
        // Decorative cushions in front of the sleeping pillows.
        for (i, mat) in sp.decor.enumerated() {
            let x = (Float(i) - Float(sp.decor.count - 1) / 2) * 0.46
            let tilt = simd_quatf(degrees: -(30 + rng.float(-3...3)), axis: V3(1, 0, 0)) * simd_quatf(degrees: rng.float(-8...8), axis: .up)
            m.add(BedroomKit.pillow(width: 0.4, depth: 0.4, height: 0.12, material: mat, subdivisions: detail ? 5 : 3, seed: s32 &+ 40 &+ UInt32(i), pinch: 1),
                  Xform(translation: V3(x, mTop + 0.17, headZ + 0.54), rotation: tilt))
        }
        // --- Folded throw across the foot
        if let th = sp.throwBlanket {
            let tl: Float = 0.42
            let tz = headZ + mL - tl / 2 - 0.02
            m.add(BedroomKit.drape(width: mW - 0.03, length: tl, thick: 0.035, hang: 0.26, material: th, subdivisions: detail ? 7 : 4, wrinkle: 0.012, seed: s32 &+ 5, skirt: 0.1),
                  Xform(translation: V3(0, mTop + 0.1 - 0.012 + 0.02, tz)))
        }
        groundAO(&m, height: 0.18, floor: 0.5)
        return m
    }
}

func sgn(_ x: Float) -> Float { x < 0 ? -1 : 1 }
