import simd
import Foundation

/// Mission clay tile ridge: Mission Revival barrel-tile roof section, 3.0 m of ridge on a 28 degree pitch. Tapered
/// terracotta pan and cover tiles lap in two courses from the eaves to a mortar-bedded ridge of half-round tiles,
/// with exposed cedar rafter tails over a stucco wall and stucco rake parapets with coping at both ends. Colour
/// variation per tile, chips, a cracked cover tile, lichen, soot and white efflorescence age it.
public struct MissionClayTileRidge: RealAsset {
    public static let id = "mission-clay-tile-ridge"
    public static let summary = "Mission clay tile ridge, 3.0 m: tapered barrel pan and cover tiles on a mortar-bedded ridge with half-round ridge tiles, rafter tails and stucco rake parapets."
    public static let tags = ["prop", "architecture", "facade", "roofline", "roof"]
    public static let budget = 15_000
    public static let author = "realityhd"

    /// Ridge length in meters.
    public var length: Float = 3.0
    /// Stucco colour (sRGB hex tint).
    public var stucco: MaterialKey = "concrete.smooth:E4D8C0"
    public init() {}

    /// Hollow barrel tile along local +Y, arch up along local -Z. Width and height taper from the start to the end.
    static func tile(w0: Float, w1: Float, h0: Float, h1: Float, wall: Float, length: Float, convex: Bool, mat: MaterialKey, pts: Int = 6) -> Surface {
        func outline(_ w: Float, _ h: Float) -> [V2] {
            let sgn: Float = convex ? 1 : -1
            var outer: [V2] = [], inner: [V2] = []
            for k in 0..<pts {
                let a = Float.pi * Float(k) / Float(pts - 1)
                outer.append(V2(w / 2 * cos(a), sgn * h * sin(a)))
                inner.append(V2((w / 2 - wall) * cos(a), sgn * (h - wall) * sin(a)))
            }
            return outer + inner.reversed()
        }
        return Prim.loft([Prim.ring(outline(w0, h0), y: 0), Prim.ring(outline(w1, h1), y: length)], material: mat)
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let half = length / 2
        let th: Float = 28 * .pi / 180, sn = sin(th), cs = cos(th)
        let R: Float = 0.17, yE: Float = 0.12
        let L = R / cs
        let yPeak = yE + R * tan(th)
        // Point on the roof plane: s side (+1 front, -1 back), x along the ridge, t up-slope from the eave, h normal.
        func P(_ s: Float, _ x: Float, _ t: Float, _ h: Float = 0) -> V3 {
            V3(x, yE + t * sn + h * cs, s * (R - t * cs + h * sn))
        }
        func slabRot(_ s: Float) -> simd_quatf { FA.q(s * deg(th), FA.X) }
        func deg(_ r: Float) -> Float { r * 180 / .pi }
        func decal(_ s: Float, _ size: V3, x: Float, t: Float, h: Float, _ mat: MaterialKey) {
            RK.plate(&m, size, P(s, x, t, h), mat, rot: slabRot(s))
        }
        // Rotation taking a tile's local frame (X across, Y up-slope, -Z up out of the roof) onto side s.
        func tileRot(_ s: Float, yaw: Float = 0) -> simd_quatf {
            let u = V3(0, sn, -s * cs), n = V3(0, cs, s * sn)
            let a: V3 = s > 0 ? V3(-1, 0, 0) : V3(1, 0, 0)
            let q = simd_quatf(simd_float3x3(columns: (a, u, -n)))
            return yaw == 0 ? q : simd_quatf(angle: yaw, axis: n) * q
        }
        let clay = ["B8603A", "C5703F", "A9552F", "D07F4C", "B0583B", "9E4B2E", "C0683F", "B35E36", "7E4630", "D99A6E", "8A4A32", "CF8A5C"]
        func clayMat(_ r: inout SeededRNG) -> MaterialKey { "ceramic.terracotta:" + r.pick(clay) }
        let mortar: MaterialKey = "concrete.smooth:CDBFA4"
        let wood: MaterialKey = "wood.cedar"

        // Stucco wall under the eaves, rake parapets with sloped coping, and exposed rafter tails.
        FA.box(&m, V3(length - 0.2, yE - 0.012, 0.24), V3(0, (yE - 0.012) / 2, 0), stucco, r: 0.003)
        let apex = yPeak + 0.07
        let parapet: [V2] = [V2(-0.17, 0), V2(0.17, 0), V2(0.17, yE + 0.045), V2(0, apex), V2(-0.17, yE + 0.045)]
        let coping: [V2] = [V2(-0.185, yE + 0.04), V2(0, apex + 0.012), V2(0.185, yE + 0.04), V2(0.185, yE + 0.028), V2(0, apex), V2(-0.185, yE + 0.028)]
        for e: Float in [-1, 1] {
            FA.run(&m, parapet.map { V2($0.x + 0.17, $0.y) }, length: 0.1, at: V3(e * (half - 0.05), 0, -0.17), stucco, bevel: 0.003)
            FA.run(&m, coping.map { V2($0.x + 0.185, $0.y) }, length: 0.125, at: V3(e * (half - 0.0575), 0, -0.185), "stone.cast-stone", bevel: 0.0025)
            // Drip stain under the coping and a hairline crack.
            RK.plate(&m, V3(0.0012, 0.06, 0.07), V3(e * (half - 0.0995), 0.17, 0.09), "stone.limestone-sooted")
        }
        // Plinth, string course and galvanized step flashing where tiles meet the parapets.
        FA.box(&m, V3(length - 0.2, 0.024, 0.256), V3(0, 0.012, 0), "concrete.smooth:CFC3AC", r: 0.003)
        FA.box(&m, V3(length - 0.2, 0.012, 0.25), V3(0, yE - 0.052, 0), "concrete.smooth:EADFC9", r: 0.003)
        for e: Float in [-1, 1] {
            for s: Float in [-1, 1] {
                FA.box(&m, V3(0.004, 0.03, L + 0.01), P(s, e * (half - 0.108), L / 2 + 0.0, 0.0), "metal.galvanized-aged", r: 0.0008, rot: slabRot(s))
                FA.box(&m, V3(0.03, 0.0035, L + 0.01), P(s, e * (half - 0.123), L / 2, 0.004), "metal.galvanized-aged", r: 0.0008, rot: slabRot(s))
            }
        }
        // Rafter tails: cedar, 45 x 75 mm with a bevel cut, every 0.3 m under the tile eaves, front and back.
        let tail: [V2] = [V2(0, 0), V2(0.05, 0), V2(0.062, 0.014), V2(0.05, 0.072), V2(0, 0.072)]
        let nTails = Int(((length - 0.3) / 0.3).rounded(.down))
        for s: Float in [-1, 1] {
            for k in 0...nTails {
                var r = rng.fork(40 + k + (s > 0 ? 0 : 100))
                let x = -Float(nTails) * 0.15 + Float(k) * 0.3
                let prof = s > 0 ? tail : tail.map { V2(-$0.x, $0.y) }
                FA.run(&m, prof, length: 0.045, at: V3(x, yE - 0.082 + r.float(-0.001...0.001), s * 0.105), r.chance(0.3) ? "wood.cedar-weathered" : wood, bevel: 0.0012)
            }
            // Birdstop strip and mortar infill beneath the eave line.
            RK.plate(&m, V3(length - 0.24, 0.02, 0.012), V3(0, yE - 0.02, s * (R - 0.012)), mortar)
        }

        // Pan and cover tiles in two staggered courses. Pans are concave troughs, covers span the joints.
        let pitch: Float = 0.105
        let cols = Int((length - 0.24) / pitch)
        let x0 = -Float(cols) * pitch / 2
        let hp: Float = 0.016, hc: Float = 0.034
        let hCov: Float = 0.004 + hp * 0.94 + hc * 0.95
        let courses: [(t: Float, len: Float, lift: Float)] = [(-0.01, 0.14, 0.0), (0.085, L - 0.085 + 0.01, 0.007)]
        for s: Float in [-1, 1] {
            for (ci, c) in courses.enumerated() {
                for k in 0..<cols {
                    var r = rng.fork(1000 + (s > 0 ? 0 : 500) + ci * 120 + k)
                    let xc = x0 + (Float(k) + 0.5) * pitch + r.float(-0.0012...0.0012)
                    let tj = c.t + r.float(-0.004...0.004)
                    // Pan: base lies on the underlay, edges rise.
                    var pan = Self.tile(w0: 0.1, w1: 0.088, h0: hp, h1: hp, wall: 0.006, length: c.len, convex: false, mat: clayMat(&r), pts: 5)
                    pan.computeTangents()
                    m.add(pan, Xform(translation: P(s, xc, tj, 0.004 + hp + c.lift), rotation: tileRot(s, yaw: r.float(-0.012...0.012))))
                    // Cover tile over the joint to the next column.
                    let missing = (s > 0 && ci == 1 && k == 18)
                    if missing {
                        decal(s, V3(0.085, 0.0008, 0.15), x: xc + pitch / 2, t: 0.16, h: 0.004 + hp * 0.94 + c.lift + 0.001, "roofing.shingle-granule:1E1E20")
                        for bt: Float in [0.1, 0.19] {
                            FA.box(&m, V3(0.1, 0.006, 0.03), P(s, xc + pitch / 2, bt, 0.012 + c.lift), "wood.deadwood", r: 0.001, rot: slabRot(s))
                        }
                    }
                    if k < cols - 1 && !missing {
                        let xj = xc + pitch / 2 + r.float(-0.0012...0.0012)
                        var cov = Self.tile(w0: 0.09, w1: 0.07, h0: hc, h1: hc * 0.85, wall: 0.006, length: c.len, convex: true, mat: clayMat(&r), pts: 6)
                        cov.computeTangents()
                        m.add(cov, Xform(translation: P(s, xj, tj + (ci == 0 ? 0.004 : 0), 0.004 + hp * 0.94 + c.lift), rotation: tileRot(s, yaw: r.float(-0.015...0.015))))
                        // Mortar gob closing the cover tile end at the eave (birdstop), and chips on lower lips.
                        if ci == 0 {
                            decal(s, V3(0.06, 0.024, 0.01), x: xj, t: tj + 0.004, h: 0.0225, mortar)
                        }
                        if r.chance(0.12) {
                            decal(s, V3(r.float(0.012...0.022), 0.0008, r.float(0.008...0.016)), x: xj + r.float(-0.02...0.02), t: tj + r.float(0.0...0.02), h: hCov + c.lift, "ceramic.bisque")
                        }
                    }
                }
            }
        }

        // Cracked cover tile: broken in two across the middle with a dark crack line and a missing corner.
        do {
            let s: Float = 1
            let xj = x0 + 7.5 * pitch + pitch / 2
            decal(s, V3(0.07, 0.0006, 0.004), x: xj, t: 0.15, h: hCov + 0.007, "metal.cast-iron")
            decal(s, V3(0.03, 0.0006, 0.02), x: xj + 0.02, t: 0.18, h: hCov + 0.007, "stone.limestone-sooted")
        }

        // Ridge: mortar bed beads along both slopes, half-round ridge tiles lapping from -x, and end closures.
        let yR = yPeak + 0.018
        FA.box(&m, V3(length - 0.18, 0.026, 0.1), V3(0, yPeak + 0.012, 0), mortar, r: 0.004)
        for s: Float in [-1, 1] {
            var br = rng.fork(2000 + Int(s + 2))
            var x = -half + 0.12
            while x < half - 0.1 {
                let ln = br.float(0.04...0.1)
                RK.plate(&m, V3(ln, 0.012, 0.012), V3(x + ln / 2, yPeak + 0.005, s * 0.058), "concrete.smooth:C2B496", rot: .identity)
                x += ln + br.float(0.005...0.03)
            }
        }
        let rt: Float = 0.185
        let nR = Int(ceil((length - 0.3) / rt)) + 1
        for i in 0..<nR {
            var r = rng.fork(3000 + i)
            let xs = -half + 0.09 + Float(i) * rt
            let len = min(0.21, half - 0.09 - xs)
            if len < 0.1 { continue }
            var rp = Self.tile(w0: 0.105, w1: 0.09, h0: 0.05, h1: 0.043, wall: 0.008, length: len, convex: true, mat: clayMat(&r), pts: 8)
            rp.computeTangents()
            let lift = Float(i % 2) * 0.006
            // Local Y along +X, arch up along +Y: X maps to -Z.
            let q = simd_quatf(simd_float3x3(columns: (V3(0, 0, -1), V3(1, 0, 0), V3(0, -1, 0))))
            m.add(rp, Xform(translation: V3(xs, yR + lift, 0), rotation: q))
            if r.chance(0.5) {
                RK.plate(&m, V3(r.float(0.02...0.05), 0.0008, 0.012), V3(xs + r.float(0.04...0.15), yR + lift + 0.05, r.float(-0.02...0.02)), "ceramic.bisque")
            }
        }
        // Mortar fillets at each ridge tile joint.
        for i in 1..<nR {
            let xs = -half + 0.09 + Float(i) * rt
            if xs > half - 0.2 { continue }
            FA.box(&m, V3(0.014, 0.012, 0.11), V3(xs + 0.002, yR + 0.04, 0), mortar, r: 0.003)
        }

        // Weathering on the field: lichen, soot and efflorescence streaks, moss at the eave.
        let lichen: [MaterialKey] = ["roofing.shingle-granule:7A8466", "roofing.shingle-granule:A2A585", "roofing.shingle-granule:8C7F54"]
        for s: Float in [-1, 1] {
            for _ in 0..<40 {
                let cx = rng.float(-half + 0.2...half - 0.2), ct = rng.float(0.02...0.17)
                decal(s, V3(rng.float(0.012...0.045), 0.0005, rng.float(0.01...0.03)), x: cx, t: ct, h: hCov + (ct > 0.1 ? 0.007 : 0), rng.pick(lichen))
            }
            for _ in 0..<14 {
                let cx = rng.float(-half + 0.2...half - 0.2)
                decal(s, V3(rng.float(0.004...0.012), 0.0005, rng.float(0.05...0.1)), x: cx, t: rng.float(0.1...0.15), h: hCov + 0.007, "brick.unit-efflorescent")
            }
        }
        // Moss in the pan troughs at the eave and soot along the ridge line.
        for s: Float in [-1, 1] {
            for _ in 0..<12 {
                decal(s, V3(rng.float(0.01...0.025), 0.0006, rng.float(0.02...0.05)), x: rng.float(-half + 0.2...half - 0.2), t: rng.float(-0.005...0.04), h: 0.004 + hp * 0.5, "concrete.river-algae")
            }
        }
        // Stucco wall stains: soot below the tail line and algae at the base.
        for s: Float in [-1, 1] {
            for _ in 0..<8 {
                let x = rng.float(-half + 0.2...half - 0.2), h = rng.float(0.02...0.07)
                RK.plate(&m, V3(rng.float(0.012...0.035), h, 0.0006), V3(x, yE - 0.012 - h / 2 - 0.015, s * 0.1205), "stone.limestone-sooted")
            }
            for _ in 0..<4 {
                RK.plate(&m, V3(rng.float(0.05...0.12), rng.float(0.01...0.025), 0.0006), V3(rng.float(-half + 0.2...half - 0.2), 0.012, s * 0.1208), "concrete.river-algae")
            }
        }

        groundAO(&m, height: 0.06, floor: 0.85)
        return LODModel(m)
    }
}
