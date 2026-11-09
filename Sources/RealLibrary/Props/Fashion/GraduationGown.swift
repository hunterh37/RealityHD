import simd
import Foundation

/// Upper section of a graduation gown (worn under a face): a sloped shoulder yoke around a 160 mm neck
/// opening, the upper chest with a front opening edged by satin facings, knife pleats that deepen as they
/// fall, and bell sleeve tops. 0.55 m across the shoulders, 0.45 m tall. Front +Z, centred on X/Z, base at
/// y = 0; the neck hole centre sits at `neckCenter` (anchor `gown.neck`). Yoke and body share the
/// `fabric.gown` slot, trim uses `fabric.gown-trim`.
public struct GraduationGown: RealAnchored {
    public static let id = "graduation-gown"
    public static let summary = "Upper section of a graduation gown, 0.55 m shoulders: yoke, front opening with facings, falling pleats, bell sleeve tops. Neck anchor gown.neck."
    public static let tags = ["prop", "fashion", "apparel", "graduation", "garment"]
    public static let budget = 32_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 14, distance: 1.25, studio: true)

    /// Shoulder width, section height and neck opening diameter (m).
    public var shoulderWidth: Float = 0.55
    public var height: Float = 0.45
    public var neckDiameter: Float = 0.16
    /// Number of pleats around the body.
    public var pleats: Int = 14
    /// Fabric color (sRGB hex). The default black uses the untinted keys.
    public var color: UInt32 = 0x111114
    public init() {}

    var fabric: MaterialKey { color == 0x111114 ? "fabric.gown" : MaterialKey(stringLiteral: String(format: "fabric.gown:%06X", color)) }
    var trimKey: MaterialKey { color == 0x111114 ? "fabric.gown-trim" : MaterialKey(stringLiteral: String(format: "fabric.gown-trim:%06X", color)) }

    /// Neck hole centre in asset space (base at y = 0).
    public var neckCenter: V3 { V3(0, height, 0) }

    public static var anchors: [String: RealAnchor] {
        let p = Self().build(seed: 0).anchors["gown.neck"]?.translation ?? Self().neckCenter
        return ["gown.neck": RealAnchor(p, direction: V3(0, 1, 0))]
    }

    private static let ringN = 160
    /// Front of the garment in ring angle space (Prim ring convention: angle pi/2 is -Z, so 3pi/2 is +Z).
    private static let front: Float = 3 * .pi / 2

    private func wrap(_ a: Float) -> Float { var d = a.truncatingRemainder(dividingBy: 2 * .pi); if d > .pi { d -= 2 * .pi }; if d < -.pi { d += 2 * .pi }; return d }

    /// Torso ring in neck-origin space: superellipse (a, b, n), pleats of depth `pleat`, front crease.
    private func torsoRing(y: Float, a: Float, b: Float, e: Float, pleat: Float, crease: Float, frontDrop: Float = 0) -> [V3] {
        let n = Self.ringN
        return (0..<n).map { k in
            let t = Float(k) / Float(n) * 2 * .pi
            let c = cos(t), s = sin(t), ex = 2 / e
            var p = V2(a * (c < 0 ? -1 : 1) * pow(abs(c), ex), b * (s < 0 ? -1 : 1) * pow(abs(s), ex))
            // Knife pleats: asymmetric fold profile, strongest front and back, none at the side seams.
            let ph = Float(pleats) * t
            let fold = sin(ph) + 0.35 * sin(2 * ph + 0.6)
            let weight = 0.25 + 0.75 * abs(s)
            var r: Float = 1 + pleat * fold * weight
            // Front opening: the two fronts meet in a crease that turns inward.
            let d = wrap(t - Self.front)
            r -= crease * exp(-(d / 0.045) * (d / 0.045))
            p *= r
            let drop = frontDrop * max(0, -s) * max(0, -s)
            return V3(p.x, y - drop, -p.y)
        }
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let half = shoulderWidth / 2, rn = neckDiameter / 2, H = height

        // Yoke: neck opening (front dipped 2 cm) sloping out to the shoulder line.
        var yoke: [[V3]] = []
        for i in 0...8 {
            let t = Float(i) / 8, ts = t * t * (3 - 2 * t)
            let a = rn + (half * 0.86 - rn) * ts, b = rn * 0.94 + (0.125 - rn * 0.94) * ts
            let y = -0.040 * t - 0.035 * t * t * t - 0.012 * sin(t * .pi) * abs(cos(Float(i)))
            yoke.append(torsoRing(y: y, a: a, b: b, e: 2 + 0.7 * t, pleat: 0, crease: 0.015 * t, frontDrop: 0.020 * (1 - t)))
        }
        m.add(Prim.loft(yoke, material: fabric))

        // Body: from the yoke seam down to the cut, widening slightly, pleats deepening as they fall.
        var body: [[V3]] = []
        for i in 0...14 {
            let t = Float(i) / 14
            let y = -0.075 - (H - 0.075) * t
            let a = half * 0.86 + 0.018 * t, b = 0.125 + 0.028 * t
            body.append(torsoRing(y: y, a: a, b: b, e: 2.7 - 0.3 * t, pleat: 0.004 + 0.040 * pow(t, 0.8), crease: 0.015 + 0.02 * t))
        }
        // Natural hang: a little sway of the hem.
        let sway = rng.vary(0, 0.004)
        var bodyS = Prim.loft(body, material: fabric)
        bodyS.deform { p in V3(p.x + sway * max(0, -p.y - 0.2), p.y, p.z) }
        m.add(bodyS)

        // Yoke seam welt where body meets yoke.
        let seam = yoke[8].map { $0 * V3(1.004, 1, 1.004) + V3(0, -0.0005, 0) }
        m.add(Prim.sweep(Shape2D.circle(0.0009, segments: 8), along: seam, closedPath: true, caps: false, material: fabric))

        // Bell sleeve tops: hang from the shoulder points, flaring, with soft pleats.
        for sx: Float in [-1, 1] {
            let start = V3(sx * (half - 0.075), -0.060, -0.004)
            let dir = simd_normalize(V3(sx * 0.10, -1, 0.03))
            let u = simd_normalize(simd_cross(dir, V3(0, 0, 1))), v = simd_normalize(simd_cross(u, dir))
            var rings: [[V3]] = []
            let n = 120
            for i in 0...12 {
                let t = Float(i) / 12
                let c = start + dir * (0.33 * t)
                let rad = 0.058 + 0.052 * pow(t, 1.3)
                let pd = 0.03 * pow(t, 1.1)
                rings.append((0..<n).map { k in
                    let a = Float(k) / Float(n) * 2 * .pi
                    let r = rad * (1 + pd * sin(9 * a + 0.4 * sx))
                    // Flatten toward the body so the sleeve top lies against the shoulder.
                    return c + u * (cos(a) * r * 0.92) + v * (sin(a) * r)
                })
            }
            if sx < 0 { rings = rings.map { Array($0.reversed()) } }
            m.add(Prim.loft(rings, material: fabric))
            // Rolled hem at the sleeve bottom.
            m.add(Prim.sweep(Shape2D.circle(0.0024, segments: 8), along: rings[12], closedPath: true, caps: false, material: fabric))
        }

        // Trim: neck binding and the two front facings running down from the neck.
        let neckPath = yoke[0].map { $0 * V3(1.01, 1, 1.01) }
        m.add(Prim.sweep(Shape2D.rounded(Shape2D.rect(0.012, 0.005), radius: 0.0018), along: neckPath, up: V3(0, 1, 0),
                         closedPath: true, caps: false, material: trimKey))
        for side: Float in [-1, 1] {
            let k = Int((Self.front + side * 0.075) / (2 * .pi) * Float(Self.ringN)) % Self.ringN
            var path: [V3] = yoke.map { $0[k] }
            path += body.dropFirst().map { $0[k] }
            path = path.map { p in
                let r = simd_normalize(V3(p.x, 0, p.z))
                return p + r * 0.003
            }
            path = catmull(path, per: 3)
            m.add(Prim.sweep(Shape2D.rounded(Shape2D.rect(0.004, 0.032), radius: 0.0015), along: path, up: V3(0, 0, 1),
                             caps: true, material: trimKey))
        }

        // Neck at origin while building; shift so the cut sits on y = 0.
        let b = m.bounds
        m = m.transformed(Xform(translation: V3(0, -b.min.y, 0)))
        var lod = LODModel(m)
        // Neck centre: built at y = 0, now at -b.min.y.
        lod.anchors["gown.neck"] = Xform(translation: V3(0, -b.min.y, 0))
        return lod
    }
}
