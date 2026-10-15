import simd
import Foundation

/// Medium-diving crankbait, 65 mm body, lying on its flank: lofted hollow plastic body with a painted
/// back and belly, holographic foil flank inserts under clear coat, 3D eyes, gill mark, clear diving lip
/// with the line tie on it, belly and tail hangers with split rings and two #4 trebles.
/// Anchor: `lineTie` (wire eye on the lip, pointing forward).
public struct LureCrankbait: RealAsset, RealAnchored {
    public static let id = "lure-crankbait"
    public static let summary = "Medium-diving crankbait 65 mm body: holographic shad finish, clear lip, two treble hooks."
    public static let tags = ["prop", "fishing", "handheld", "plastic"]
    public static let budget = 12700
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 40, distance: 1.0, studio: true)

    /// Back colour (sRGB hex).
    public var backColor: UInt32 = 0x2F4A2A
    /// Belly colour.
    public var bellyColor: UInt32 = 0xE8E2CF
    /// Holographic flank tint.
    public var flankColor: UInt32 = 0xC9D4D8
    /// Body length (m) and depth.
    public var length: Float = 0.065
    public var depth: Float = 0.027
    public init() {}

    /// Body half-depth and half-width at t (0 tail, 1 nose).
    func section(_ t: Float) -> (d: Float, w: Float) {
        let s = pow(max(0, sin(.pi * pow(t, 0.72))), 0.62)
        let tail = max(0.12, s)
        return (depth / 2 * tail, depth * 0.32 * max(0.16, s))
    }

    var tieSwim: V3 { V3(length / 2 + 0.0015, -depth * 0.26 - 0.0028, 0) }

    public static var anchors: [String: RealAnchor] {
        let a = Self(), (_, x) = a.model(seed: 1)
        return ["lineTie": RealAnchor(x.point(a.tieSwim), direction: x.rotation.act(V3(1, 0, 0)))]
    }

    func model(seed: UInt64) -> (Model, Xform) {
        var rng = SeededRNG(seed: seed)
        let L = length, x0 = -L / 2
        let back: MaterialKey = "paint.lure-worn:" + String(format: "%06X", backColor)
        let belly: MaterialKey = "paint.lure:" + String(format: "%06X", bellyColor)
        let holo: MaterialKey = "paint.lure-holo:" + String(format: "%06X", flankColor)
        let hookMat: MaterialKey = "metal.hook:2A2C30"
        var body: [Surface] = []
        // Body: loft along the axis (built along +Y, then turned onto +X). Lower body belly colour, upper back.
        // Shells share the body section; `keep` says which part of the section (vertical / half-depth) shows,
        // the rest is pulled inside the body so the painted back and belly read as paint over the foil.
        func loft(_ scale: Float, _ mat: MaterialKey, _ t0: Float, _ t1: Float, keep: @escaping (Float) -> Bool) -> Surface {
            var rings: [[V3]] = []
            let n = 22
            for i in 0...n {
                let t = t0 + (t1 - t0) * Float(i) / Float(n)
                let (d, w) = section(t)
                let outline = Shape2D.superellipse(2 * d, 2 * w, exponent: 2.3, segments: 40).map { p -> V2 in
                    keep(-p.x / d) ? p * scale : p * 0.9
                }
                rings.append(Prim.ring(outline, y: L * t))
            }
            return Prim.loft(rings, capStart: true, capEnd: true, material: mat).transformed(Xform(translation: V3(x0, 0, 0), rotation: RodKit.alongX))
        }
        body.append(loft(1, holo, 0.0, 1.0) { _ in true })
        // Painted back over the top third, cream belly under the bottom quarter.
        body.append(loft(1.006, back, 0.0, 1.0) { $0 > 0.42 })
        body.append(loft(1.006, belly, 0.0, 1.0) { $0 < -0.55 })
        // Story: paint chipped off the nose and chin where the lure bangs rocks, primer white showing.
        for k in 0..<5 {
            let t = rng.float(0.86...0.97), (d, w) = section(t)
            let a = rng.float(-0.9...0.9)
            let p = V3(x0 + L * t, d * cos(a) * 0.98 * (k < 3 ? 1 : -1), w * sin(a) * 0.98)
            let n = simd_normalize(V3(0.6, p.y / max(d, 1e-4), p.z / max(w, 1e-4)))
            body.append(Prim.superellipsoid(V3(rng.float(0.0014...0.0028), 0.0005, rng.float(0.0012...0.002)), exponent: 2.6, subdivisions: 3, material: "paint.lure:EDEBE2")
                .transformed(Xform(translation: p, rotation: simd_quatf(from: V3(0, 1, 0), to: n))))
        }
        // Eyes and gill mark near the nose.
        for side: Float in [-1, 1] {
            let t: Float = 0.83
            body += LureKit.eye(at: V3(x0 + L * t, depth * 0.08, side * section(t).w * 0.9), n: V3(0.15, 0.1, side), r: 0.0034, iris: "paint.lure:D8B23A")
            body.append(Prim.superellipsoid(V3(0.0009, depth * 0.3, 0.0006), exponent: 2.5, subdivisions: 4, material: "paint.lure:9A2420")
                .transformed(Xform(translation: V3(x0 + L * 0.74, -0.002, side * section(0.74).w * 0.97), rotation: simd_quatf(angle: -0.25, axis: V3(0, 0, 1)))))
        }
        // Clear lip from the chin, angled down and forward; line tie wire on it.
        let lipOutline = Shape2D.rounded([V2(0, -0.0068), V2(0.017, -0.0088), V2(0.0205, 0), V2(0.017, 0.0088), V2(0, 0.0068)], radius: 0.004)
        let lipQ = simd_quatf(angle: -0.5, axis: V3(0, 0, 1)) * simd_quatf(angle: .pi / 2, axis: V3(1, 0, 0))
        body.append(Prim.extrude(lipOutline, depth: 0.0013, bevel: 0.0004, bevelSegments: 1, material: "plastic.lip-clear")
            .transformed(Xform(translation: V3(L / 2 - 0.006, -depth * 0.26, 0), rotation: lipQ)))
        body.append(LureKit.wireEye(at: tieSwim - V3(0, 0.0012, 0), normal: V3(0.48, 0.88, 0), r: 0.0018, wire: 0.00045, mat: "metal.hook"))
        // Hangers with split rings and trebles (belly and tail).
        var hooks: [(pivot: V3, surfaces: [Surface])] = []
        for (hx, hy, normal) in [(Float(0.004), -section(0.56).d, V3(0, -1, 0)), (L / 2 * -1 - 0.001, 0.0, V3(-1, 0, 0))] {
            let base = V3(hx, hy, 0)
            body.append(LureKit.wireEye(at: base, normal: normal, r: 0.0016, wire: 0.0004, mat: "metal.hook"))
            let ring = base + normal * 0.0045
            body += LureKit.splitRing(at: ring, r: 0.0028, wire: 0.00035, mat: "metal.hook")
            let eye = ring + normal * 0.003 + V3(0, -0.0015, 0)
            let tr = LureKit.treble(shank: 0.012, gap: 0.0075, wire: 0.00055, mat: hookMat).map { $0.transformed(Xform(translation: eye + V3(0, -0.0012, 0), rotation: simd_quatf(angle: rng.float(-0.3...0.3), axis: V3(0, 1, 0)))) }
            hooks.append((pivot: eye, surfaces: tr))
        }
        return LureKit.layOnSide(body: body, hooks: hooks, droop: -0.42, name: Self.id)
    }

    public func build(seed: UInt64) -> LODModel {
        var (m, _) = model(seed: seed)
        groundAO(&m, height: 0.012, floor: 0.55)
        return LODModel(m)
    }
}
