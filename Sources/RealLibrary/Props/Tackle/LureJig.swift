import simd
import Foundation

/// 3/8 oz football jig lying on its side: painted lead head with a 90-degree line tie and eyes, black
/// heavy-wire hook riding point up, fiber weed guard, wire collar, flared silicone skirt.
/// Anchor: `lineTie` (eye on top of the head).
public struct LureJig: RealAsset, RealAnchored {
    public static let id = "lure-jig"
    public static let summary = "3/8 oz skirted jig: painted lead head, eye, fiber weed guard, silicone skirt, black hook."
    public static let tags = ["prop", "fishing", "handheld", "metal", "rubber"]
    public static let budget = 10600
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 45, distance: 1.0, studio: true)

    /// Head paint colour (sRGB hex).
    public var headColor: UInt32 = 0x4A5226
    /// Skirt colours: main and accent strands.
    public var skirtColor: UInt32 = 0x56602C
    public var skirtAccent: UInt32 = 0xB07030
    /// Skirt strand count.
    public var strands: Int = 40
    public init() {}

    var tieSwim: V3 { V3(0.0045, 0.0088, 0) }
    public static var anchors: [String: RealAnchor] {
        let a = Self(), (_, x) = a.model(seed: 1)
        return ["lineTie": RealAnchor(x.point(a.tieSwim), direction: x.rotation.act(V3(0, 1, 0)))]
    }

    func model(seed: UInt64) -> (Model, Xform) {
        var rng = SeededRNG(seed: seed)
        let head: MaterialKey = "paint.lure-worn:" + String(format: "%06X", headColor)
        let hookMat: MaterialKey = "metal.hook:202226"
        var body: [Surface] = []
        // Football head: elongated, flattened sides, slightly pointed nose.
        var h = Prim.superellipsoid(V3(0.018, 0.0135, 0.0105), exponent: 2.2, subdivisions: 10, material: head)
        h.deform { p in V3(p.x, p.y * (1 - 0.18 * max(0, p.x / 0.009)), p.z * (1 - 0.12 * max(0, p.x / 0.009))) }
        body.append(h)
        // Story: paint knocked off the nose and belly by rocks, bare lead showing.
        for _ in 0..<7 {
            let a = rng.float(3.6...5.8), b = rng.float(0.5...1.3)
            let n = simd_normalize(V3(cos(b) * 0.9 + 0.3, sin(b) * cos(a), sin(b) * sin(a)))
            let p = n * V3(0.009, 0.00675, 0.00525) * 0.985
            body.append(Prim.superellipsoid(V3(rng.float(0.0014...0.0028), 0.0005, rng.float(0.001...0.002)), exponent: 2.4, subdivisions: 3, material: "metal.cast-iron:6A6C70")
                .transformed(Xform(translation: p, rotation: simd_quatf(from: V3(0, 1, 0), to: n))))
        }
        for side: Float in [-1, 1] {
            body += LureKit.eye(at: V3(0.004, 0.0015, side * 0.0049), n: V3(0.2, 0.1, side), r: 0.0019, iris: "paint.lure:D8C23A")
        }
        // Line tie eye on top of the head.
        body.append(Prim.torus(major: 0.0021, minor: 0.0006, segments: 14, sides: 6, material: hookMat).transformed(Xform(translation: tieSwim + V3(0, -0.0012, 0), rotation: simd_quatf(angle: .pi / 2, axis: V3(1, 0, 0)))))
        // Hook: shank out the back of the head, bend up, point forward (rides point up).
        let flip = simd_quatf(angle: .pi, axis: V3(1, 0, 0)) * simd_quatf(angle: -.pi / 2, axis: V3(0, 0, 1))
        body += LureKit.hook(shank: 0.034, gap: 0.0125, wire: 0.00075, mat: hookMat, eye: false).map { $0.transformed(Xform(translation: V3(0.004, -0.0005, 0), rotation: flip)) }
        // Collar: wire wrap behind the head.
        body.append(Prim.helix(radius: 0.0018, pitch: 0.0011, turns: 3, wire: 0.00035, perTurn: 12, sides: 4, material: "metal.chrome").transformed(Xform(translation: V3(-0.0085, -0.0005, 0), rotation: simd_quatf(angle: .pi / 2, axis: V3(0, 0, 1)))))
        body.append(Prim.cylinder(radius: 0.0024, height: 0.0035, bevel: 0.0006, segments: 14, bevelSegments: 1, material: "rubber.skirt:202020").transformed(Xform(translation: V3(-0.0095, -0.0005, 0), rotation: simd_quatf(angle: .pi / 2, axis: V3(0, 0, 1)))))
        // Weed guard: fiber bundle from the head top angled back over the point.
        for k in 0..<9 {
            let z = (Float(k) - 4) * 0.00055
            let p0 = V3(-0.002, 0.004, z), p1 = V3(-0.024, 0.0175 + rng.float(-0.001...0.001), z * 2.2)
            body.append(Prim.tube([p0, (p0 + p1) / 2 + V3(0, 0.0025, 0), p1], radii: [0.00032, 0.0003, 0.00026], sides: 4, seamTile: 0.01, material: "plastic.black"))
        }
        // Skirt: flat silicone strands flaring from the collar past the bend.
        for k in 0..<strands {
            let a = Float(k) / Float(strands) * 2 * .pi + rng.float(-0.06...0.06)
            let len = rng.float(0.05...0.058)
            let mat: MaterialKey = "rubber.skirt:" + String(format: "%06X", k % 5 == 2 ? skirtAccent : skirtColor)
            var path: [V3] = []
            let wave = rng.float(0.6...1.4), phase = rng.float(0...6.28), sag = rng.float(0.5...1.2)
            for i in 0...8 {
                let t = Float(i) / 8
                let r = 0.0028 + 0.012 * pow(t, 0.6)
                // Lying on the flank (+Z swim is the ground): strands collapse toward the ground and splay in Y.
                let wob = 0.0012 * t * sin(t * 6 * wave + phase)
                path.append(V3(-0.0095 - len * t, -0.0005 + r * cos(a) * 1.15 + wob, r * sin(a) * (1 - 0.6 * t) + 0.0045 * sag * t * t))
            }
            body.append(Prim.sweep(Shape2D.roundedRect(0.0011, 0.00045, radius: 0.0002, segments: 1), along: path, up: simd_normalize(V3(0, cos(a), sin(a))), caps: false, material: mat))
        }
        return LureKit.layOnSide(body: body, hooks: [], name: Self.id)
    }

    public func build(seed: UInt64) -> LODModel {
        var (m, _) = model(seed: seed)
        groundAO(&m, height: 0.012, floor: 0.55)
        return LODModel(m)
    }
}
