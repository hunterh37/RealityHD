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

/// Bread loaf: everyday pantry, bakery. A 28 cm batard, 12 cm wide and 12 cm tall: domed crust with three
/// diagonal scores that opened into raised ears, flour dusting, darker blistered patches on the crown and a
/// cut end showing crumb. A few crumbs sit by the cut.
public struct BreadLoaf: RealAsset {
    public static let id = "bread-loaf"
    public static let summary = "Scored crusty loaf with oven-spring ears and a cut end showing crumb."
    public static let tags = ["prop", "interior", "pantry", "food"]
    public static let budget = 9000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 28, distance: 0.62, studio: true)

    /// Crust.
    public var crust: MaterialKey = "food.bread-crust"
    /// Darker blistered crust and ears.
    public var crustDark: MaterialKey = "food.bread-crust-toasted"
    /// Crumb.
    public var crumb: MaterialKey = "food.bread-crumb"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = DD1IPantry.bakery(length: 0.26, hUp: 0.105, hDown: 0.015, w: 0.06, nTop: 3.0, start: .cut, end: .closed(0.2),
                                  slashes: 3, slashHalfLen: 0.026, slashHalfSpan: 0.036, slashRange: 0.38...0.8,
                                  flour: 46, crust: crust, crustDark: crustDark, crumb: crumb, flourKey: "food.flour", seed: seed)
        // Blistered dark patches on the crown.
        for _ in 0..<8 {
            let x = rng.float(-0.09...0.09), z = rng.float(-0.03...0.03)
            m.add(Prim.superellipsoid(V3(rng.float(0.014...0.026), 0.002, rng.float(0.01...0.02)), exponent: 3, subdivisions: 3, material: crustDark),
                  Xform(translation: V3(x, 0.118 - 0.0016 - 0.00003 * z, z)))
        }
        for _ in 0..<7 {
            m.add(Prim.superellipsoid(V3(rng.float(0.002...0.005), 0.002, rng.float(0.002...0.004)), exponent: 3, subdivisions: 2, material: crumb),
                  Xform(translation: V3(rng.float(0.131...0.14), 0.001, rng.float(-0.06...0.06)), rotation: simd_quatf(degrees: rng.float(0...360), axis: .up)))
        }
        // Scorched underside and shallow crust cracks along the shoulders.
        m.add(Prim.superellipsoid(V3(0.2, 0.0035, 0.07), exponent: 4, subdivisions: 4, material: "food.bread-crust-toasted"), Xform(translation: V3(0, 0.0018, 0)))
        for sz: Float in [-1, 1] {
            for _ in 0..<3 {
                let x0 = rng.float(-0.1...0.05)
                m.add(Prim.tube([V3(x0, 0.075, sz * 0.054), V3(x0 + 0.02, 0.071, sz * 0.057), V3(x0 + 0.04, 0.066, sz * 0.059)], radii: [0.0007, 0.0012, 0.0006], sides: 4, seamTile: 0.02, material: crumb))
            }
        }
        let b = m.bounds
        m = m.transformed(Xform(translation: V3(0, -b.min.y, 0)))
        groundAO(&m, height: 0.03, floor: 0.7)
        return LODModel(m)
    }
}
