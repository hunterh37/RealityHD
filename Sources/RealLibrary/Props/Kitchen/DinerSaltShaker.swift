import simd
import Foundation

/// Diner salt shaker: pressed glass body 5 cm across and 9 cm tall with a thick base, a chrome screw cap with a ribbed skirt and a flat
/// top plate pierced by seven real holes, a dark liner under the plate, salt fill with crystals against the glass and a few spilled grains.
public struct DinerSaltShaker: RealAsset {
    public static let id = "diner-salt-shaker"
    public static let summary = "Classic diner glass salt shaker, 9 cm tall, 5 cm across, with a chrome perforated cap, salt fill and crystals, and a few spilled grains."
    public static let tags = ["prop", "kitchen", "tableware", "glass", "metal", "interior", "handheld"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 22, studio: true)

    /// Overall size in meters (x width, y height, z depth). The body, cap and fill scale from the fixed profile; this is the reference size.
    public var size = V3(0.05, 0.09, 0.05)
    /// Glass wall thickness (m).
    public var wall: Float = 0.0031
    /// Glass body.
    public var glass: MaterialKey = "glass.clear"
    /// Cap metal.
    public var chrome: MaterialKey = "metal.stainless-smudged:EEF2F8"
    /// Salt fill and crystals.
    public var salt: MaterialKey = "food.sugar:F2F0EA"
    public init() {}

    private static let bodyOuter: [V2] = [
        V2(0, 0.0050), V2(0.0190, 0.0050), V2(0.0226, 0.0014), V2(0.0244, 0.0000), V2(0.0251, 0.0040), V2(0.0250, 0.0120),
        V2(0.0240, 0.0300), V2(0.0228, 0.0460), V2(0.0221, 0.0600), V2(0.0215, 0.0680), V2(0.0212, 0.0745),
    ]

    private func radius(_ pts: [V2], _ y: Float) -> Float {
        for i in 1..<pts.count where pts[i].y >= y && pts[i].y != pts[i - 1].y {
            let t = (y - pts[i - 1].y) / (pts[i].y - pts[i - 1].y)
            return pts[i - 1].x + (pts[i].x - pts[i - 1].x) * t
        }
        return pts.last?.x ?? 0
    }

    /// Flat top plate with 7 holes (centre plus ring of 6), built as one bridged polygon.
    private func plate(radius R: Float, y: Float, segs: Int, material: MaterialKey) -> (Surface, [V2]) {
        let nOuter = 48, nHole = 16
        let ringR: Float = 0.0074, hr: Float = 0.00125
        let step = 2 * Float.pi / Float(nOuter)
        var outer: [V2] = (0..<nOuter).map { V2(cos(Float($0) * step) * R, sin(Float($0) * step) * R) }
        func hole(_ c: V2, _ rot: Float) -> [V2] {      // clockwise, vertex 0 at angle rot
            (0..<nHole).map { k in
                let a = rot - Float(k) * 2 * .pi / Float(nHole)
                return c + V2(cos(a), sin(a)) * hr
            }
        }
        func bridged(_ poly: [V2], at i: Int, _ h: [V2], from s: Int) -> [V2] {
            var out = Array(poly[0...i])
            for k in 0..<h.count { out.append(h[(s + k) % h.count]) }
            out.append(h[s]); out.append(poly[i])
            out += poly[(i + 1)...]
            return out
        }
        var centres: [V2] = []
        // Ring holes in descending outer index so earlier indices stay valid.
        for j in (0..<6).reversed() {
            let a = Float(j) * .pi / 3
            let c = V2(cos(a), sin(a)) * ringR
            centres.append(c)
            var h = hole(c, a)                       // vertex 0 points outward
            if j == 0 {
                let ctr = hole(.zero, 0)             // centre hole bridged to the inward vertex of hole 0
                h = bridged(h, at: nHole / 2, ctr, from: 0)
            }
            outer = bridged(outer, at: j * (nOuter / 6), h, from: 0)
        }
        centres.append(.zero)
        let tris = Shape2D.triangulate(outer)
        var s = Surface(material: material)
        for p in outer { _ = s.add(V3(p.x, y, p.y), .up, V2(p.x, p.y)) }
        var t = 0
        while t + 2 < tris.count { s.tri(tris[t], tris[t + 2], tris[t + 1]); t += 3 }
        s.occlusion = Array(repeating: 1, count: s.positions.count)
        s.computeTangents()
        return (s, centres)
    }

    func level(segs: Int, detail: Bool, seed: UInt64) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let outer = Profile.smooth(Self.bodyOuter, per: detail ? 2 : 2)
        // Glass body: smooth lathe, thick floor, rounded rim at the neck.
        m.add(Prim.lathe(Profile.shell(outer, wall: wall, floor: 0.0125), segments: segs, seamTile: 0.1, material: glass))
        // Salt fill.
        let fillTop: Float = 0.0665
        var fill: [V2] = [V2(0, fillTop + 0.0030), V2(0.0070, fillTop + 0.0022), V2(0.0130, fillTop + 0.0008)]
        fill.append(V2(radius(outer, fillTop) - wall - 0.0002, fillTop - 0.0006))
        fill.append(V2(radius(outer, 0.0110) - wall - 0.0002, 0.0112))
        fill.append(V2(0, 0.0108))
        m.add(Prim.lathe(fill, segments: segs, seamTile: 0.03, material: salt))
        // Salt crystals pressed against the inside of the glass.
        let nCrystal = detail ? 80 : 0
        for _ in 0..<nCrystal {
            let y = rng.float(0.0125...(fillTop - 0.003))
            let a = rng.float(0...(2 * .pi))
            let r = radius(outer, y) - wall - 0.0008
            let s = rng.float(0.0011...0.0020)
            let q = simd_quatf(degrees: rng.float(0...360), axis: V3(0, 1, 0)) * simd_quatf(degrees: rng.float(-25...25), axis: V3(1, 0, 0))
            m.add(DinerSaltShaker.crystal(s, rng.float(0...1), salt),
                  Xform(translation: V3(cos(a) * r, y, sin(a) * r), rotation: q))
        }
        // Chrome cap: ribbed skirt, tapered shoulder, raised rim around a flat top. Inner wall returns down.
        func cy(_ y: Float) -> Float { 0.0640 + (y - 0.0578) * (0.0900 - 0.0640) / (0.0900 - 0.0578) }
        let capOuter: [V2] = Profile.smooth([
            V2(0.0233, cy(0.0578)), V2(0.0240, cy(0.0582)), V2(0.0239, cy(0.0596)), V2(0.0236, cy(0.0600)), V2(0.0239, cy(0.0608)), V2(0.0236, cy(0.0612)),
            V2(0.0239, cy(0.0620)), V2(0.0236, cy(0.0624)), V2(0.0238, cy(0.0636)), V2(0.0236, cy(0.0700)), V2(0.0226, cy(0.0775)), V2(0.0204, cy(0.0842)),
            V2(0.0180, cy(0.0880)), V2(0.0170, cy(0.0893)), V2(0.0166, cy(0.0900)), V2(0.0161, cy(0.0900)), V2(0.0158, cy(0.0894)),
        ], per: detail ? 2 : 1)
        let capSegs = detail ? 56 : 24
        var capPts = capOuter
        capPts.append(V2(0.0158, cy(0.0884)))
        capPts.append(V2(0.0175, cy(0.0855))); capPts.append(V2(0.0200, cy(0.0790))); capPts.append(V2(0.0220, cy(0.0710)))
        capPts.append(V2(0.0222, cy(0.0640))); capPts.append(V2(0.0225, cy(0.0578))); capPts.append(V2(0.0233, cy(0.0578)))
        var cap = Prim.lathe(capPts, segments: capSegs, seamTile: 0.1, material: chrome)
        cap.recomputeNormals(weldSeams: true)
        m.add(cap)
        // Perforated top plate and the dark liner below it.
        let plateY = cy(0.0888)
        let (pl, centres) = plate(radius: 0.0160, y: plateY, segs: segs, material: chrome)
        m.add(pl)
        for c in centres {
            // Hole wall: short inward-facing tube through the plate thickness.
            let wallS = Prim.lathe([V2(0.00125, plateY), V2(0.00125, plateY - 0.0007)], segments: detail ? 16 : 8, seamTile: 0.01, material: chrome).flipped()
            m.add(wallS, Xform(translation: V3(c.x, 0, c.y)))
        }
        m.add(Prim.lathe([V2(0, plateY - 0.0009), V2(0.0158, plateY - 0.0009)], segments: segs, seamTile: 0.03, material: "metal.parkerized").flipped())
        m.add(Prim.lathe([V2(0, plateY - 0.0009), V2(0.0158, plateY - 0.0009)], segments: segs, seamTile: 0.03, material: "metal.parkerized"))
        // Spilled grains and a small drift at the base.
        let nGrain = detail ? 44 : 8
        for _ in 0..<nGrain {
            let a = rng.float(-0.5...1.4)
            let d = 0.0256 + pow(rng.float(0...1), 1.4) * 0.0045
            let s = rng.float(0.0009...0.0016)
            m.add(DinerSaltShaker.crystal(s, rng.float(0...1), salt),
                  Xform(translation: V3(cos(a) * d, s * 0.45, sin(a) * d), rotation: simd_quatf(degrees: rng.float(0...360), axis: V3(0, 1, 0))))
        }
        if detail {
            for k in 0..<5 {
                let a = 0.2 + Float(k) * 0.26
                let d = 0.0262 + rng.float(0...0.003)
                m.add(DinerSaltShaker.crystal(0.0011, 0.5, salt), Xform(translation: V3(cos(a) * d, 0.0010, sin(a) * d)))
            }
        }
        // Salt crust where the cap skirt meets the glass.
        m.add(Prim.lathe([V2(0.0214, cy(0.0560)), V2(0.0230, cy(0.0568)), V2(0.0242, cy(0.0578)), V2(0.0226, cy(0.0580)), V2(0.0214, cy(0.0566))], segments: detail ? 48 : 20, seamTile: 0.03, material: salt))
        groundAO(&m, height: 0.006, floor: 0.8)
        return m
    }

    /// One salt crystal: a slightly irregular cube, rounded at the corners.
    static func crystal(_ s: Float, _ v: Float, _ mat: MaterialKey) -> Surface {
        var g = Prim.superellipsoid(V3(s, s * (0.75 + 0.25 * v), s * (0.85 + 0.2 * v)), exponent: 5, subdivisions: 1, material: mat)
        g.uvs = g.positions.map { V2($0.x, $0.z) }
        g.computeTangents()
        return g
    }

    public func build(seed: UInt64) -> LODModel {
        let lod0 = level(segs: 64, detail: true, seed: seed)
        let lod1 = level(segs: 28, detail: false, seed: seed)
        return LODModel(levels: [lod0, lod1], switchDistances: [1.5])
    }
}
