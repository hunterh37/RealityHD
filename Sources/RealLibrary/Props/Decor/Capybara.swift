import simd
import Foundation

/// Adult capybara sitting, facing +Z: 0.9 m long, 0.5 m high, 0.45 m wide. Barrel body lofted from
/// superellipse sections with atlas fur UVs, boxy muzzle with big glossy nostril pads, jaw slightly open
/// showing the incisors, small rounded ears, dark glossy eyes, big haunches, short front legs and
/// webbed toes, coarse guard-hair strands along the back, shoulders and cheeks.
public struct Capybara: RealAsset {
    public static let id = "capybara"
    public static let summary = "Seated adult capybara: barrel body, boxy muzzle with wet nose and agape jaw showing incisors, small ears and eyes, short legs with webbed toes, coarse brown fur."
    public static let tags = ["prop", "decor", "creature", "outdoor"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 12, distance: 1.9, studio: true)

    /// Coat material (atlas fur; tint is the back color).
    public var fur: MaterialKey = "fauna.fur-short:8A6A48"
    /// Nose, nostril pads, eyes (glossy, wet).
    /// Head coat: darker, dirtier tint for tone variation.
    public var furHead: MaterialKey = "fauna.fur-short:6E5236"
    /// Leg and foot coat: worn lighter tint.
    public var furLeg: MaterialKey = "fauna.fur-short:94775A"
    public var wet: MaterialKey = "plastic.gloss:2A1A16"
    public var eye: MaterialKey = "plastic.gloss:0A0605"
    /// Nails, toe webbing, ear lining, mouth interior.
    public var dark: MaterialKey = "plastic.matte:3A2A22"
    public var mouth: MaterialKey = "plastic.matte:3A1614"
    public var tooth: MaterialKey = "plastic.gloss:D9A864"
    public init() {}

    struct Sec { var z: Float; var cy: Float; var hw: Float; var hh: Float; var e: Float; var cx: Float = 0 }

    /// Lofts superellipse sections along +Z with elliptical end caps. U wraps around from the dorsal line,
    /// V runs v0 (rear) to v1 (front), matching the fauna atlas layout.
    static func loft(_ secs: [Sec], capRear: Float, capFront: Float, segs: Int, per: Int, v0: Float, v1: Float,
                     floorY: Float? = nil, material: MaterialKey) -> Surface {
        func lerpSec(_ i: Int, _ t: Float) -> Sec {
            func cr(_ a: Float, _ b: Float, _ c: Float, _ d: Float) -> Float {
                0.5 * ((2 * b) + (-a + c) * t + (2 * a - 5 * b + 4 * c - d) * t * t + (-a + 3 * b - 3 * c + d) * t * t * t)
            }
            let p0 = secs[max(0, i - 1)], p1 = secs[i], p2 = secs[i + 1], p3 = secs[min(secs.count - 1, i + 2)]
            return Sec(z: p1.z + (p2.z - p1.z) * t, cy: cr(p0.cy, p1.cy, p2.cy, p3.cy), hw: cr(p0.hw, p1.hw, p2.hw, p3.hw),
                       hh: cr(p0.hh, p1.hh, p2.hh, p3.hh), e: cr(p0.e, p1.e, p2.e, p3.e), cx: cr(p0.cx, p1.cx, p2.cx, p3.cx))
        }
        var rings: [Sec] = []
        let capN = 6
        for k in 0..<capN {
            let phi = Float.pi / 2 * (1 - Float(k) / Float(capN))
            var r = secs[0]; let sc = cos(phi)
            r.z -= capRear * sin(phi); r.hw *= sc; r.hh *= sc
            rings.append(r)
        }
        for i in 0..<(secs.count - 1) { for j in 0..<per { rings.append(lerpSec(i, Float(j) / Float(per))) } }
        rings.append(secs[secs.count - 1])
        for k in 1...capN {
            let phi = Float.pi / 2 * Float(k) / Float(capN)
            var r = secs[secs.count - 1]; let sc = cos(phi)
            r.z += capFront * sin(phi); r.hw *= sc; r.hh *= sc
            rings.append(r)
        }
        var s = Surface(material: material)
        let zMin = rings.first!.z, zMax = rings.last!.z
        for r in rings {
            let v = v0 + (v1 - v0) * (r.z - zMin) / (zMax - zMin)
            for k in 0...segs {
                let u = Float(k) / Float(segs), th = u * 2 * .pi
                let sn = sin(th), cs = cos(th), ex = 2 / max(2, r.e)
                var y = r.cy + r.hh * (cs < 0 ? -1 : 1) * pow(abs(cs), ex)
                if let f = floorY { y = max(y, f) }
                let x = r.cx + r.hw * (sn < 0 ? -1 : 1) * pow(abs(sn), ex)
                s.add(V3(x, y, r.z), .up, V2(u, v))
            }
        }
        let row = UInt32(segs + 1)
        for r in 0..<(rings.count - 1) { for k in 0..<segs {
            let a = UInt32(r) * row + UInt32(k)
            s.quad(a, a + row, a + row + 1, a + 1)
        }}
        s.recomputeNormals(weldSeams: true)
        // Orient outward: flip if the signed volume is negative.
        var vol: Float = 0
        for t in stride(from: 0, to: s.indices.count, by: 3) {
            let a = s.positions[Int(s.indices[t])], b = s.positions[Int(s.indices[t + 1])], c = s.positions[Int(s.indices[t + 2])]
            vol += simd_dot(a, simd_cross(b, c))
        }
        if vol < 0 {
            for t in stride(from: 0, to: s.indices.count, by: 3) { s.indices.swapAt(t + 1, t + 2) }
            s.recomputeNormals(weldSeams: true)
        }
        s.computeTangents()
        return s
    }

    /// Ellipsoid-like blob with fur-atlas UVs (u around the long axis from the top, v by z in v0...v1).
    static func blob(_ size: V3, exp: Float, v: ClosedRange<Float>, sub: Int, material: MaterialKey) -> Surface {
        var s = Prim.superellipsoid(size, exponent: exp, subdivisions: sub, material: material)
        let zr = size.z / 2
        for i in s.positions.indices {
            let p = s.positions[i]
            let u = (atan2(p.x, p.y) / (2 * .pi) + 1).truncatingRemainder(dividingBy: 1)
            s.uvs[i] = V2(u, v.lowerBound + (v.upperBound - v.lowerBound) * (p.z / zr * 0.5 + 0.5))
        }
        s.computeTangents()
        return s
    }

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [model(seed: seed, detail: true), model(seed: seed, detail: false)], switchDistances: [5])
    }

    func model(seed: UInt64, detail: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id + (detail ? "" : "-lite"))
        let segs = detail ? 36 : 24, per = 2, sub = detail ? 4 : 3

        // Barrel body (rump at the ground, back rising to the shoulders).
        let bodySecs = [
            Sec(z: -0.37, cy: 0.17, hw: 0.15, hh: 0.15, e: 2.4),
            Sec(z: -0.25, cy: 0.195, hw: 0.19, hh: 0.19, e: 2.6),
            Sec(z: -0.10, cy: 0.215, hw: 0.19, hh: 0.20, e: 2.6),
            Sec(z: 0.04, cy: 0.25, hw: 0.17, hh: 0.19, e: 2.5),
            Sec(z: 0.14, cy: 0.28, hw: 0.145, hh: 0.17, e: 2.4),
        ]
        m.add(Self.loft(bodySecs, capRear: 0.07, capFront: 0.09, segs: segs, per: per, v0: 0.0, v1: 0.78, floorY: 0.012, material: fur))

        // Head in local space (origin at the skull base on the neck line), pitched down slightly.
        var head = Model(name: "head")
        let headSecs = [
            Sec(z: -0.04, cy: 0, hw: 0.088, hh: 0.092, e: 2.4),
            Sec(z: 0.06, cy: 0.005, hw: 0.100, hh: 0.098, e: 2.6),
            Sec(z: 0.17, cy: 0.0, hw: 0.098, hh: 0.092, e: 3.0),
            Sec(z: 0.27, cy: -0.014, hw: 0.090, hh: 0.080, e: 2.7),
            Sec(z: 0.34, cy: -0.024, hw: 0.080, hh: 0.068, e: 2.8),
        ]
        head.add(Self.loft(headSecs, capRear: 0.06, capFront: 0.018, segs: segs, per: per, v0: 0.30, v1: 1.0, material: furHead))
        // Lower jaw hanging a little open, mouth interior behind it.
        let jawSecs = [
            Sec(z: 0.20, cy: -0.112, hw: 0.060, hh: 0.020, e: 3.0),
            Sec(z: 0.30, cy: -0.112, hw: 0.066, hh: 0.019, e: 3.6),
            Sec(z: 0.35, cy: -0.112, hw: 0.060, hh: 0.018, e: 4.0),
        ]
        head.add(Self.loft(jawSecs, capRear: 0.03, capFront: 0.012, segs: detail ? 24 : 16, per: 3, v0: 0.55, v1: 1.0, material: furHead))
        head.add(Prim.roundedBox(V3(0.085, 0.016, 0.12), radius: 0.008, bevelSegments: 2, material: mouth), Xform(translation: V3(0, -0.095, 0.28)))
        // Incisor pairs.
        for sx: Float in [-1, 1] {
            head.add(Prim.roundedBox(V3(0.013, 0.030, 0.009), radius: 0.0035, bevelSegments: 2, material: tooth),
                     Xform(translation: V3(sx * 0.0075, -0.094, 0.346), rotation: simd_quatf(degrees: -4, axis: V3(1, 0, 0))))
            head.add(Prim.roundedBox(V3(0.011, 0.022, 0.008), radius: 0.003, bevelSegments: 2, material: tooth),
                     Xform(translation: V3(sx * 0.0065, -0.104, 0.342)))
        }
        // Nostril pads (big, wet, glossy) and nose bridge.
        for sx: Float in [-1, 1] {
            head.add(Prim.superellipsoid(V3(0.052, 0.040, 0.030), exponent: 2.6, subdivisions: sub, material: wet),
                     Xform(translation: V3(sx * 0.036, -0.004, 0.340), rotation: simd_quatf(degrees: sx * 12, axis: V3(0, 0, 1))))
            // Nostril slit.
            head.add(Prim.superellipsoid(V3(0.020, 0.008, 0.008), exponent: 2, subdivisions: 3, material: eye),
                     Xform(translation: V3(sx * 0.033, -0.002, 0.354), rotation: simd_quatf(degrees: sx * 30, axis: V3(0, 0, 1))))
        }
        head.add(Prim.superellipsoid(V3(0.040, 0.026, 0.020), exponent: 2.4, subdivisions: sub, material: wet), Xform(translation: V3(0, 0.000, 0.344)))
        // Eyes: small, dark, glossy, with a darker surround.
        for sx: Float in [-1, 1] {
            head.add(Prim.superellipsoid(V3(0.030, 0.026, 0.022), exponent: 2.6, subdivisions: sub, material: dark),
                     Xform(translation: V3(sx * 0.090, 0.042, 0.158), rotation: simd_quatf(degrees: sx * -20, axis: V3(0, 1, 0))))
            head.add(Prim.superellipsoid(V3(0.020, 0.020, 0.016), exponent: 2, subdivisions: sub, material: eye),
                     Xform(translation: V3(sx * 0.098, 0.043, 0.162), rotation: simd_quatf(degrees: sx * -20, axis: V3(0, 1, 0))))
        }
        // Ears: small and rounded, set on top and back, dark lining.
        for sx: Float in [-1, 1] {
            let tilt = Xform(translation: V3(sx * 0.066, 0.090, 0.040), rotation: simd_quatf(degrees: sx * 32, axis: V3(0, 0, 1)) * simd_quatf(degrees: -12, axis: V3(1, 0, 0)))
            head.add(Self.blob(V3(0.036, 0.040, 0.016), exp: 2.4, v: 0.8...0.9, sub: sub, material: furHead), tilt)
            var inner = tilt; inner.translation += tilt.direction(V3(sx * 0.3, 0.1, 0.5)) * 0.006
            head.add(Prim.superellipsoid(V3(0.024, 0.028, 0.008), exponent: 2.4, subdivisions: sub, material: dark), inner)
        }
        // Cheek tufts.
        if detail {
            for _ in 0..<30 {
                let sx: Float = rng.float(0...1) < 0.5 ? -1 : 1
                let z = rng.float(0.05...0.22), a = rng.float(0.8...2.2)
                let p = V3(sx * 0.099 * sin(a) * 0.98, 0.092 * cos(a) * 0.9, z)
                let dir = simd_normalize(V3(sx * sin(a), cos(a) * 0.6, -0.9 + rng.float(-0.2...0.2)))
                head.add(Self.strand(p, dir, len: rng.float(0.016...0.026), material: fur))
            }
        }
        let headPos = V3(0, 0.372, 0.10)
        m.add(head, Xform(translation: headPos, rotation: simd_quatf(degrees: 11, axis: V3(1, 0, 0))))

        // Haunches (big hind thighs) and tucked hind feet.
        for sx: Float in [-1, 1] {
            m.add(Self.blob(V3(0.16, 0.29, 0.38), exp: 2.1, v: 0.0...0.35, sub: 7, material: fur),
                  Xform(translation: V3(sx * 0.140, 0.145, -0.255), rotation: simd_quatf(degrees: sx * -4, axis: V3(0, 0, 1))))
            m.add(Self.blob(V3(0.078, 0.034, 0.14), exp: 2.6, v: 0.3...0.5, sub: sub, material: furLeg), Xform(translation: V3(sx * 0.150, 0.017, -0.075)))
            Self.toes(&m, x: sx * 0.150, z: -0.075, count: 3, spread: 0.020, nail: dark, fur: fur, sub: sub, detail: detail)
        }
        // Front legs: short, straight columns, with feet and webbed toes.
        for sx: Float in [-1, 1] {
            let x = sx * 0.105
            let path = [V3(x, 0.31, 0.05), V3(x * 1.12, 0.19, 0.07), V3(x * 1.02, 0.08, 0.14), V3(x, 0.03, 0.165)]
            m.add(Prim.tube(path, radii: [0.078, 0.060, 0.044, 0.041], sides: detail ? 22 : 12, seamTile: 0.1, material: furLeg, capEnd: false).atlasLeg())
            m.add(Self.blob(V3(0.080, 0.034, 0.120), exp: 2.6, v: 0.8...1.0, sub: sub, material: furLeg), Xform(translation: V3(x, 0.017, 0.190)))
            Self.toes(&m, x: x, z: 0.190, count: 4, spread: 0.0185, nail: dark, fur: fur, sub: sub, detail: detail)
        }

        // Elbow tufts on the front legs.
        if detail {
            for sx: Float in [-1, 1] { for _ in 0..<12 {
                let a = rng.float(1.8...4.4)
                let p = V3(sx * 0.105 + 0.062 * sin(a) * (a > 3 ? -sx : sx) * 0.9, 0.22 + rng.float(-0.03...0.03), 0.095 + 0.055 * cos(a))
                m.add(Self.strand(p, simd_normalize(V3(sx * 0.2, -0.5, -0.8 + rng.float(-0.2...0.2))), len: rng.float(0.018...0.028), material: furLeg))
            }}
        }

        // Coarse guard hair along the back, shoulders and flanks.
        if detail {
            for _ in 0..<90 {
                let t = rng.float(0...1)
                let z = -0.36 + t * 0.46
                // Pick an upper-body angle (dorsal bias).
                let a = rng.float(-1.9...1.9)
                let (cy, hw, hh) = Self.bodyAt(z)
                let p = V3(hw * sin(a) * 0.985, cy + hh * cos(a) * 0.985, z)
                if p.y < 0.1 { continue }
                let n = simd_normalize(V3(sin(a) / max(hw, 0.01), cos(a) / max(hh, 0.01) * 0.9, 0))
                let dir = simd_normalize(n + V3(0, 0, -0.8) + V3(rng.float(-0.15...0.15), rng.float(-0.1...0.1), rng.float(-0.15...0.15)))
                m.add(Self.strand(p, dir, len: rng.float(0.022...0.036), material: fur))
            }
        }

        let bb = m.bounds
        m = m.transformed(Xform(translation: V3(-(bb.min.x + bb.max.x) / 2, -bb.min.y, -(bb.min.z + bb.max.z) / 2)))
        groundAO(&m, height: 0.08, floor: 0.5)
        return m
    }

    /// Body section center and half sizes at z (same keyframes as the loft, linear).
    static func bodyAt(_ z: Float) -> (Float, Float, Float) {
        let k: [(Float, Float, Float, Float)] = [(-0.37, 0.17, 0.15, 0.15), (-0.25, 0.195, 0.19, 0.19), (-0.10, 0.215, 0.19, 0.20), (0.04, 0.25, 0.17, 0.19), (0.14, 0.28, 0.145, 0.17)]
        var i = 0
        while i < k.count - 2 && z > k[i + 1].0 { i += 1 }
        let t = max(0, min(1, (z - k[i].0) / (k[i + 1].0 - k[i].0)))
        func l(_ a: Float, _ b: Float) -> Float { a + (b - a) * t }
        return (l(k[i].1, k[i + 1].1), l(k[i].2, k[i + 1].2), l(k[i].3, k[i + 1].3))
    }

    /// One tapered guard hair, rooted just under the coat.
    static func strand(_ p: V3, _ dir: V3, len: Float, material: MaterialKey) -> Surface {
        let a = p - dir * 0.004, b = p + dir * len * 0.5 + V3(0, -len * 0.05, 0), c = p + dir * len + V3(0, -len * 0.15, 0)
        var s = Prim.tube([a, b, c], radii: [0.0018, 0.0013, 0.0003], sides: 3, seamTile: 0.01, material: material, capEnd: false)
        for i in s.uvs.indices { s.uvs[i] = V2(0.1, 0.5) }
        return s
    }

    /// Row of toes with nails and a thin web between them.
    static func toes(_ m: inout Model, x: Float, z: Float, count: Int, spread: Float, nail: MaterialKey, fur: MaterialKey, sub: Int, detail: Bool) {
        let w = spread * Float(count - 1)
        for i in 0..<count {
            let ox = -w / 2 + Float(i) * spread
            m.add(Prim.superellipsoid(V3(spread * 1.05, 0.026, 0.034), exponent: 2.4, subdivisions: 3, material: fur),
                  Xform(translation: V3(x + ox, 0.013, z + 0.060)))
            m.add(Prim.superellipsoid(V3(spread * 0.8, 0.013, 0.016), exponent: 2.4, subdivisions: 2, material: nail),
                  Xform(translation: V3(x + ox, 0.010, z + 0.080)))
        }
        if detail {
            m.add(Prim.superellipsoid(V3(w + spread * 0.9, 0.005, 0.030), exponent: 2.4, subdivisions: 4, material: nail),
                  Xform(translation: V3(x, 0.004, z + 0.062)))
        }
    }
}

extension Surface {
    /// Remaps tube UVs (u around, v along, meters) to fur atlas UVs so the coat scales in meters.
    func atlasLeg() -> Surface {
        var s = self
        let uMax = max(s.uvs.map { $0.x }.max() ?? 1, 1e-4), vMax = max(s.uvs.map { $0.y }.max() ?? 1, 1e-4)
        for i in s.uvs.indices { s.uvs[i] = V2(0.01 + 0.24 * s.uvs[i].x / uMax, 0.30 + 0.50 * s.uvs[i].y / vMax) }
        s.computeTangents()
        return s
    }
}
