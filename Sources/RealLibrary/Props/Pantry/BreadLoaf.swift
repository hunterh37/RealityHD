import simd
import Foundation

/// Shared helpers for the DD1I pantry props.
enum DD1IPantry {
    /// Super-elliptical section centered at the origin: half-extents `a` (first axis) by `b`, exponent `ex`.
    static func superSection(_ a: Float, _ b: Float, ex: Float, segs: Int = 36) -> [V2] {
        (0..<segs).map { k in
            let t = Float(k) / Float(segs) * 2 * .pi
            let c = cos(t), s = sin(t)
            return V2(a * (c < 0 ? -1 : 1) * pow(abs(c), 2 / ex), b * (s < 0 ? -1 : 1) * pow(abs(s), 2 / ex))
        }
    }

    /// D-shaped bread section: domed top (`hUp`), flatter belly (`hDown`), half width `w`.
    static func breadSection(hUp: Float, hDown: Float, w: Float, nTop: Float, segs: Int = 36) -> [V2] {
        (0..<segs).map { k in
            let t = Float(k) / Float(segs) * 2 * .pi
            let u = cos(t), v = sin(t)
            let a = u >= 0 ? hUp * pow(u, 2 / nTop) : -hDown * pow(-u, 2 / 5)
            let b = w * (v < 0 ? -1 : 1) * pow(abs(v), 2 / (u >= 0 ? nTop : 5))
            return V2(a, b)
        }
    }

    enum End { case closed(Float), cut }

    /// Baked loaf along +X (start end at x = 0 side). Crust loft with scored slashes (crumb in the cut, raised
    /// ear on one lip), flour dusting, and a cut/torn end filled with crumb.
    static func bakery(length L: Float, hUp: Float, hDown: Float, w: Float, nTop: Float, start: End, end: End,
                       slashes: Int, slashHalfLen: Float, slashHalfSpan: Float, slashRange: ClosedRange<Float>,
                       torn: Bool = false, flour: Int, crust: MaterialKey, crustDark: MaterialKey, crumb: MaterialKey, flourKey: MaterialKey,
                       seed: UInt64) -> Model {
        var rng = SeededRNG(seed: seed)
        let sd = Float(seed % 97)
        func fall(_ e: End, _ x: Float) -> Float {
            switch e {
            case .cut: return 1
            case .closed(let f): return pow(sin(Float.pi / 2 * min(1, max(0.0001, x / f))), 0.5)
            }
        }
        func scale(_ t: Float) -> Float { fall(start, t) * fall(end, 1 - t) }
        func belly(_ t: Float) -> Float { 1 - 0.07 * pow(abs(2 * t - 1), 2) }   // slight spindle
        func topY(_ t: Float, _ z: Float) -> Float {
            let s = scale(t) * belly(t), ww = w * s
            let v2 = pow(min(1, abs(z) / max(ww, 1e-5)), nTop)
            return hUp * s * pow(sqrt(max(0, 1 - v2)), 2 / nTop)
        }
        let n = 36, rings = max(18, Int(L * 90))
        var rs: [[V3]] = []
        for i in 0...rings {
            let t = Float(i) / Float(rings)
            let s = scale(t) * belly(t)
            let sec = breadSection(hUp: hUp * s, hDown: hDown * s, w: w * s, nTop: nTop, segs: n)
            rs.append(Prim.ring(sec, y: t * L))
        }
        // Crust in four lengthwise bake zones with slightly different tints (same displacement field, so no steps).
        let tints: [String] = ["B06C36", "C07A42", "BB7640", "AE6A35"].map { crust + ":" + $0 }
        var bodies: [Surface] = []
        let zones = 4
        for z in 0..<zones {
            let lo = rings * z / zones, hi = rings * (z + 1) / zones
            var seg = Prim.loft(Array(rs[lo...hi]), capStart: z == 0, capEnd: z == zones - 1, material: tints[z])
            seg.displace { p, _ in
                let jag: Float = torn && p.y < 0.03 ? 0.0045 * (1 - p.y / 0.03) * sin(p.x * 310 + p.z * 190 + sd) * sin(p.z * 270 + 1.3) : 0
                return 0.0007 * sin(p.x * 150 + p.y * 40 + sd) * sin(p.z * 130 + p.x * 55) + 0.0004 * sin(p.y * 260 + p.z * 90) + jag
            }
            bodies.append(seg)
        }
        var pre = Model(name: "bakery")
        for body in bodies { pre.add(body) }
        // Cut / torn end: crumb disc set 1.5 mm into the open end.
        if case .cut = start {
            let sec = breadSection(hUp: hUp * 0.985, hDown: hDown * 0.985, w: w * 0.985, nTop: nTop, segs: n)
            var disc = Prim.extrude(sec, depth: 0.004, bevel: 0.0012, bevelSegments: 1, material: crumb)
            disc.displace { p, _ in (torn ? 0.003 : 0.0009) * sin(p.x * 210 + p.y * 170) * (torn ? sin(p.x * 90 + 0.5) : 1) }
            pre.add(disc, Xform(translation: V3(0, torn ? 0.007 : 0.0005, 0), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        }
        // Scoring: crumb in the groove, raised ear along one lip.
        for k in 0..<slashes {
            let tc = slashes == 1 ? 0.5 : slashRange.lowerBound + (slashRange.upperBound - slashRange.lowerBound) * Float(k) / Float(slashes - 1)
            let jit = rng.float(-0.01...0.01)
            var groove: [V3] = [], ear: [V3] = [], gr: [Float] = [], er: [Float] = []
            let steps = 8
            for i in 0...steps {
                let u = Float(i) / Float(steps) * 2 - 1
                let z = u * slashHalfSpan, y = tc * L + u * slashHalfLen + jit
                let t = min(0.98, max(0.02, y / L))
                groove.append(V3(topY(t, z) - 0.0008, y, z))
                let ez = z + 0.0075
                ear.append(V3(topY(t, ez) + 0.0016, y + 0.0006, ez))
                let e = sin(Float.pi * Float(i) / Float(steps))
                gr.append(0.0016 + 0.0006 * e)
                er.append(0.0006 + 0.0034 * pow(e, 0.7))
            }
            pre.add(Prim.tube(groove, radii: gr, sides: 5, seamTile: 0.02, material: crumb))
            pre.add(Prim.tube(ear, radii: er, sides: 6, seamTile: 0.02, material: crustDark))
        }
        // Flour dusting: flat specks on the crown.
        for _ in 0..<flour {
            let t = rng.float(0.1...0.9)
            let ww = w * scale(t) * belly(t)
            let z = rng.float(-0.8...0.8) * ww
            let r = rng.float(0.0025...0.0075)
            let prof: [V2] = [V2(0, 0.0004), V2(r * 0.8, 0.0003), V2(r, 0)]
            pre.add(Prim.lathe(prof, segments: 7, seamTile: 0.05, material: flourKey),
                    Xform(translation: V3(topY(t, z) - 0.0002, t * L, z), rotation: simd_quatf(degrees: -90, axis: V3(0, 0, 1)) * simd_quatf(degrees: 0, axis: .up)))
        }
        var m = Model(name: "loaf")
        m.add(pre, Xform(rotation: simd_quatf(degrees: 90, axis: V3(0, 0, 1))))
        let b = m.bounds
        return m.transformed(Xform(translation: V3(-(b.min.x + b.max.x) / 2, -b.min.y, -(b.min.z + b.max.z) / 2)))
    }
}

/// Bread loaf: everyday pantry, bakery. A 28 cm sourdough batard, 12 cm wide and 11 cm tall, resting on
/// a flattened, scorched belly. One lofted crust shell carries the whole surface story in displacement:
/// three diagonal scores opened by oven spring into grooves with a raised ear on one lip, blistered
/// bubbles, fine shoulder cracks and banneton ridges on the flanks. The groove floors are lighter blond
/// crust strips, flour lies in specks along the banneton lines and the crown, and the loaf is cut at one
/// end to show an open crumb face, with crumbs fallen beside it. LOD1 drops flour and crumbs.
public struct BreadLoaf: RealAsset {
    public static let id = "bread-loaf"
    public static let summary = "Sourdough batard, 28 cm: lofted crust with three opened scores and ears, blisters, flour specks, cut end showing crumb, crumbs."
    public static let tags = ["prop", "interior", "pantry", "food"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 28, distance: 1.15, studio: true)

    /// Loaf length, width and height (m).
    public var size = V3(0.28, 0.14, 0.12)
    /// Crust.
    public var crust: MaterialKey = "food.bread-crust"
    /// Lighter crust inside the opened scores.
    public var crustBlond: MaterialKey = "food.bun-crust"
    /// Crumb face.
    public var crumb: MaterialKey = "food.bread-crumb"
    /// Flour specks.
    public var flour: MaterialKey = "food.flour"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(seed, edge: 0.0042, hi: true), level(seed, edge: 0.0085, hi: false)], switchDistances: [3])
    }

    func level(_ seed: UInt64, edge: Float, hi: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        let sd = UInt32(truncatingIfNeeded: seed)
        let L = size.x, H = size.y, W = size.z / 2
        // Built along +Y (s = 0 tapered heel, s = 1 cut end), then laid along +X.
        let cutS: Float = 0.93
        var shell = FoodMesh.sections(edge: edge, length: L, seamTile: 0.1, material: crust) { s in
            let u = s * cutS
            let taper = pow(sin(Float.pi * u), 0.42)
            return (H * 0.5 * max(0.04, taper), W * max(0.04, pow(sin(Float.pi * u), 0.36)), 2.5, .zero)
        }
        // Scores: three diagonal slashes across the crown (center x along, angle across).
        struct Score { var c: Float; var half: Float; var ang: Float }
        let scores = (0..<3).map { k in Score(c: L * (0.3 + 0.2 * Float(k)) + rng.float(-0.006...0.006), half: 0.034, ang: rng.float(0.35...0.5)) }
        func scoreField(_ y: Float, _ z: Float) -> (Float, Float) {
            // Returns (groove depth 0...1, ear lift 0...1) for a point on the crown (y along, z across).
            var g: Float = 0, e: Float = 0
            for sc in scores {
                let dy = y - sc.c, ca = cos(sc.ang), sa = sin(sc.ang)
                let along = dy * ca + z * sa, across = -dy * sa + z * ca
                let lenF = 1 - smoothstep(sc.half * 0.75, sc.half, abs(along))
                let width = 0.0065 * (1 - pow(along / sc.half, 2))
                g = max(g, lenF * exp(-pow(across / max(width, 0.0008), 2)))
                e = max(e, lenF * exp(-pow((across - width * 1.6) / 0.0035, 2)))
            }
            return (g, e)
        }
        shell.deform { p in
            var q = p
            // Flattened belly: compress everything below the waist.
            if q.x > H * 0.1 { q.x = H * 0.1 + (q.x - H * 0.1) * 0.42 }
            return q
        }
        shell.displace { p, n in
            // Local frame: p.y along, -p.x up, p.z across.
            let up = -n.x
            var d: Float = 0
            if up > 0.25 {
                let (g, e) = scoreField(p.y, p.z)
                d += -0.0065 * g + 0.0032 * e
            }
            // Blisters: small domed bubbles on the upper crust.
            let w = Noise.worley(p * 160, seed: sd &+ 3)
            d += 0.0007 * max(0, 0.35 - w.f1) * smoothstep(0.0, 0.6, up)
            // Banneton ridges on the flanks and fine cracks on the shoulders.
            let side = 1 - abs(up)
            d += 0.0005 * sin(p.y * 260 + 2 * Noise.perlin(p * 40, seed: sd &+ 4)) * side * side
            d += 0.0009 * Noise.fbm(p * 45, octaves: 4, seed: sd &+ 5)
            return d
        }
        var m = Model(name: Self.id)
        m.add(FoodMesh.layAlongX(shell))
        // Groove floors: blond crust strips laid along each score.
        var blond = Surface(material: crustBlond)
        func crownPoint(_ y: Float, _ z: Float) -> V3 {
            let u = y / L * cutS
            let hh = H * 0.5 * pow(sin(Float.pi * u), 0.42), ww = W * pow(sin(Float.pi * u), 0.36)
            let zz = min(abs(z) / max(ww, 1e-4), 0.999)
            let x = hh * pow(1 - pow(zz, 2.5), 1 / 2.5)
            return V3(-x, y, z)
        }
        for sc in scores {
            let pts = (0...8).map { k -> V3 in
                let a = (Float(k) / 8 * 2 - 1) * sc.half * 0.82
                let y = sc.c + a * cos(sc.ang), z = a * sin(sc.ang)
                return crownPoint(y, z) + V3(0.0042, 0, 0)
            }
            let strip = FoodMesh.tube(pts, radii: pts.indices.map { 0.0045 * sqrt(max(0.15, 1 - pow(Float($0) / 4 - 1, 2))) }, sides: hi ? 10 : 6,
                                      endBulge: 0.6, seamTile: 0.03, material: crustBlond)
            blond.append(strip)
        }
        m.add(FoodMesh.layAlongX(blond))
        // Cut end: crumb face just inside the crust rim.
        let face = Shape2D.superellipse(H * 0.5 * pow(sin(Float.pi * cutS), 0.42) * 2 - 0.004, W * pow(sin(Float.pi * cutS), 0.36) * 2 - 0.004, exponent: 2.5)
        var cf = Prim.extrude(face, depth: 0.004, bevel: 0.0008, bevelSegments: 1, material: crumb)
        cf.deform { q in
            var r = q
            if r.x > H * 0.1 { r.x = H * 0.1 + (r.x - H * 0.1) * 0.42 }
            return r
        }
        cf.displace { q, n in n.z < -0.7 ? 0.0006 * Noise.fbm(q * 220, octaves: 2, seed: sd &+ 6) : 0 }
        // Extrude runs along Z; turn it so the face looks along the loaf axis (+Y local), then lay along X.
        var cfY = cf
        cfY.positions = cf.positions.map { V3($0.x, -$0.z + L - 0.0016, $0.y) }
        cfY.normals = cf.normals.map { V3($0.x, -$0.z, $0.y) }
        cfY.computeTangents()
        m.add(FoodMesh.layAlongX(cfY))
        // Flour: flat specks on the crown and along the banneton ridges.
        if hi {
            var fl = Surface(material: flour)
            let src = shell
            for _ in 0..<700 {
                let i = rng.int(0...(src.positions.count - 1))
                let p = src.positions[i], n = src.normals[i]
                let up = -n.x
                if up < 0.1 || rng.chance(up > 0.7 ? 0.5 : 0.2) { continue }
                let (g, _) = scoreField(p.y, p.z)
                if g > 0.2 { continue }
                let r = rng.float(0.0003...0.0009)
                let t = simd_normalize(simd_cross(n, V3(0, 0, 1)) + V3(0, 1e-4, 0)), b = simd_cross(n, t)
                let c = p + n * 0.00035 + t * rng.float(-0.002...0.002) + b * rng.float(-0.002...0.002)
                let k = fl.positions.count
                for j in 0..<5 {
                    let a = Float(j) / 5 * 2 * .pi + rng.float(-0.3...0.3)
                    _ = fl.add(c + (t * cos(a) + b * sin(a)) * r * rng.float(0.6...1.2), n, V2(Float(j) * 0.001, 0))
                }
                let cc = fl.add(c + n * 0.0001, n, V2(0, 0))
                for j in 0..<5 { fl.tri(cc, UInt32(k + j), UInt32(k + (j + 1) % 5)) }
            }
            fl.computeTangents()
            m.add(FoodMesh.layAlongX(fl))
        }
        m = GroceryKit.plant(m)
        // Crumbs fallen by the cut end.
        if hi {
            let bb = m.bounds
            for i in 0..<6 {
                var r = rng.fork(i + 40)
                let s = r.float(0.0018...0.0045)
                m.add(Prim.superellipsoid(V3(s, s * 0.7, s * 0.85), exponent: 2.6, subdivisions: 1, material: i < 2 ? crust : crumb),
                      Xform(translation: V3(bb.max.x + r.float(0.003...0.025), s * 0.33, r.float(-0.04...0.04)),
                            rotation: simd_quatf(angle: r.float(0...6.28), axis: V3(0, 1, 0))))
            }
        }
        groundAO(&m, height: 0.03, floor: 0.65)
        return m
    }
}
