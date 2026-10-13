import simd
import Foundation

/// Topwater popper, 70 mm body, lying on its flank: turned body tapering to the tail, concave cupped
/// mouth with the line tie in the cup, bone white paint with a red throat, darker back, 3D eyes, belly
/// and tail trebles, feather and flash dressing on the tail treble.
/// Anchor: `lineTie` (wire eye in the cup).
public struct LureTopwaterPopper: RealAsset, RealAnchored {
    public static let id = "lure-topwater-popper"
    public static let summary = "Topwater popper 70 mm body: cupped mouth, painted eyes, two trebles, feathered rear hook."
    public static let tags = ["prop", "fishing", "handheld", "plastic"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 40, distance: 1.0, studio: true)

    /// Body colour (sRGB hex), bone white.
    public var bodyColor: UInt32 = 0xE9E2CC
    /// Back colour.
    public var backColor: UInt32 = 0x5A6650
    /// Throat colour.
    public var throatColor: UInt32 = 0xB82A22
    /// Feather colour.
    public var featherColor: UInt32 = 0xE6E2D6
    /// Body length (m).
    public var length: Float = 0.07
    public init() {}

    /// Body radius at t (0 tail, 1 face).
    func radius(_ t: Float) -> Float { 0.0042 + 0.0068 * pow(sin(.pi / 2 * min(1, t / 0.72)), 0.8) - 0.0012 * max(0, (t - 0.8) / 0.2) }

    var tieSwim: V3 { V3(length / 2 - 0.0028, -0.001, 0) }
    public static var anchors: [String: RealAnchor] {
        let a = Self(), (_, x) = a.model(seed: 1)
        return ["lineTie": RealAnchor(x.point(a.tieSwim), direction: x.rotation.act(V3(1, 0, 0)))]
    }

    func model(seed: UInt64) -> (Model, Xform) {
        var rng = SeededRNG(seed: seed)
        let L = length, x0 = -L / 2
        let paint: MaterialKey = "paint.lure-worn:" + String(format: "%06X", bodyColor)
        let back: MaterialKey = "paint.lure:" + String(format: "%06X", backColor)
        let red: MaterialKey = "paint.lure:" + String(format: "%06X", throatColor)
        let hookMat: MaterialKey = "metal.hook:2A2C30"
        var body: [Surface] = []
        // Turned body with a cupped face: profile up to the rim, then down into the cup.
        var prof: [V2] = [V2(0, 0)]
        for i in 0...20 { let t = Float(i) / 20; prof.append(V2(radius(t), L * t)) }
        let rimR = radius(1)
        prof += [V2(rimR * 0.97, L + 0.0004), V2(rimR * 0.82, L - 0.0012), V2(rimR * 0.5, L - 0.0034), V2(0, L - 0.0042)]
        body.append(RodKit.lathe(prof, x0: x0, y: 0, seg: 32, tile: 0.03, paint))
        // Paint over the base coat: copies of the turned body that sit 0.5 % proud where the colour shows and
        // sink inside elsewhere (darker back on top, red throat under the chin).
        let base = body[0]
        func shell(_ mat: MaterialKey, keep: @escaping (V3, Float) -> Bool) -> Surface {
            var c = base
            c.material = mat
            c.deform { p in
                let r = simd_length(V2(p.y, p.z)), up = r > 1e-5 ? p.y / r : 0
                let f: Float = keep(p, up) ? 1.006 : 0.9
                return V3(p.x, p.y * f, p.z * f)
            }
            return c
        }
        body.append(shell(back) { p, up in up > 0.5 && p.x < L / 2 - 0.0015 })
        body.append(shell(red) { p, up in up < -0.35 && p.x > L / 2 - 0.016 && p.x < L / 2 - 0.0015 })
        // Story: hook rash where the belly treble swings against the paint, and a chipped rim on the cup.
        for k in 0..<6 {
            let x = k < 4 ? rng.float(-0.004...0.016) : L / 2 - rng.float(0.001...0.003)
            let a = k < 4 ? rng.float(-2.4 ... -0.7) : rng.float(0...6.28)
            let r = radius(0.5 + x / L) * 1.002
            let n = V3(0, cos(a), sin(a))
            body.append(Prim.superellipsoid(V3(rng.float(0.0012...0.0026), 0.0004, rng.float(0.0008...0.0016)), exponent: 2.6, subdivisions: 3, material: "paint.lure:9A9282")
                .transformed(Xform(translation: V3(x, 0, 0) + n * r, rotation: simd_quatf(from: V3(0, 1, 0), to: n))))
        }
        // Eyes.
        for side: Float in [-1, 1] {
            body += LureKit.eye(at: V3(x0 + L * 0.82, 0.0022, side * radius(0.82) * 0.97), n: V3(0.15, 0.2, side), r: 0.0032, iris: "paint.lure:E0C040")
        }
        // Line tie screw eye in the cup.
        body.append(LureKit.wireEye(at: tieSwim - V3(0.0012, 0, 0), normal: V3(1, 0, 0), r: 0.0017, wire: 0.00045, mat: "metal.hook"))
        // Hooks: belly hanger, tail hanger with dressing.
        var hooks: [(pivot: V3, surfaces: [Surface])] = []
        for (hx, normal, dressed) in [(Float(0.006), V3(0, -1, 0), false), (x0 - 0.0005, V3(-1, 0, 0), true)] {
            let base = normal.y < 0 ? V3(hx, -radius(0.6), 0) : V3(hx, 0, 0)
            body.append(LureKit.wireEye(at: base, normal: normal, r: 0.0016, wire: 0.0004, mat: "metal.hook"))
            let ring = base + normal * 0.0045
            body += LureKit.splitRing(at: ring, r: 0.0027, wire: 0.00035, mat: "metal.hook")
            let eye = ring + normal * 0.003 + V3(0, -0.0015, 0)
            var s = LureKit.treble(shank: 0.012, gap: 0.0075, wire: 0.00055, mat: hookMat).map { $0.transformed(Xform(translation: eye + V3(0, -0.0012, 0), rotation: simd_quatf(angle: rng.float(-0.3...0.3), axis: V3(0, 1, 0)))) }
            if dressed {
                // Feathers: flattened tapered tubes flaring back from the shank, plus a few flash strands.
                for k in 0..<26 {
                    let a = Float(k) / 26 * 2 * .pi
                    let len = rng.float(0.022...0.03)
                    let dir = simd_normalize(V3(-1, -0.25 + 0.3 * sin(a), 0.35 * cos(a)))
                    let p0 = eye + V3(0, -0.004, 0)
                    let mid = p0 + dir * len * 0.5 + V3(0, -0.002, 0), end = p0 + dir * len + V3(0, rng.float(-0.003...0.001), 0)
                    let mat: MaterialKey = k % 5 == 0 ? "paint.lure-holo:D8C070" : "rubber.skirt:" + String(format: "%06X", featherColor)
                    s.append(Prim.tube([p0, mid, end], radii: [0.0006, 0.0008, 0.0001], sides: 4, seamTile: 0.01, material: mat))
                }
                s.append(Prim.cylinder(radius: 0.0016, height: 0.004, bevel: 0.0005, segments: 10, bevelSegments: 1, material: red).transformed(Xform(translation: eye + V3(0, -0.0035, 0), rotation: simd_quatf(angle: .pi, axis: V3(1, 0, 0)))))
            }
            hooks.append((pivot: eye, surfaces: s))
        }
        return LureKit.layOnSide(body: body, hooks: hooks, droop: -0.42, name: Self.id)
    }

    public func build(seed: UInt64) -> LODModel {
        var (m, _) = model(seed: seed)
        groundAO(&m, height: 0.012, floor: 0.55)
        return LODModel(m)
    }
}
