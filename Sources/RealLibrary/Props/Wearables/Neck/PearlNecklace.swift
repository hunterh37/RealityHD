import simd
import Foundation

/// Graduated cultured pearl necklace, princess length (46 cm), worn at the collarbone: 55 individually knotted
/// pearls from 8.4 mm at the centre to 6 mm at the nape, each with a slight surface lumpiness and a one-in-eleven
/// baroque pearl, silk knots between, and a gold box clasp with fishhook tongue at the back.
public struct PearlNecklace: RealAsset {
    public static let id = "pearl-necklace"
    public static let summary = "Worn graduated pearl necklace: knotted individual pearls, slight irregularity, gold box clasp."
    public static let tags = ["prop", "wearable", "worn", "jewelry", "pearl", "gold"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 18, elevation: 16, distance: 0.62, ground: false, studio: true)

    /// Pearl body colour.
    public var pearl: MaterialKey = "plastic.gloss:F1E9DB"
    /// Clasp metal.
    public var metal: MaterialKey = "metal.gold"
    /// Silk knot.
    public var silk: MaterialKey = "fabric.nylon:CFC6B4"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let rx: Float = 0.068, rz0: Float = 0.063
        func point(_ th: Float) -> V3 {
            let f = (1 + cos(th)) / 2
            return V3(sin(th) * (rx + 0.01 * f), 0.004 - 0.082 * pow(f, 1.45), cos(th) * (rz0 + 0.02 * pow(f, 1.5)))
        }
        let delta: Float = 0.10
        var dense: [V3] = [], thetas: [Float] = []
        let steps = 1200
        for k in 0...steps {
            let th = -Float.pi + delta + (2 * Float.pi - 2 * delta) * Float(k) / Float(steps)
            dense.append(point(th)); thetas.append(th)
        }
        var cum: [Float] = [0]
        for i in 1..<dense.count { cum.append(cum[i - 1] + simd_distance(dense[i - 1], dense[i])) }
        let total = cum.last!
        func at(_ s: Float) -> (V3, Float) {
            var lo = 0, hi = cum.count - 1
            while hi - lo > 1 { let mid = (lo + hi) / 2; if cum[mid] <= s { lo = mid } else { hi = mid } }
            let t = (s - cum[lo]) / max(cum[hi] - cum[lo], 1e-9)
            return (lerp(dense[lo], dense[hi], t), lerp(thetas[lo], thetas[hi], t))
        }
        func radius(_ th: Float) -> Float { 0.0030 + 0.0012 * (1 + cos(th)) / 2 }
        let tints = ["E9D8C0", "E3D1B8", "EDDDC8", "E7D6BE"]
        var surfaces: [String: Surface] = [:]
        var s: Float = 0.004
        var idx = 0
        var prevR: Float = 0
        var prevP: V3? = nil
        while true {
            let (_, thGuess) = at(min(s, total))
            var r = radius(thGuess)
            let baroque = idx % 11 == 7
            if baroque { r *= 0.93 }
            if s + r > total - 0.003 { break }
            let c = s + r + (prevP == nil ? 0 : 0)
            let (p, th) = at(c)
            let n = abs(th) < 1.4 ? 5 : 3
            let key = "\(n)-\(idx % 4)"
            let ph1 = rng.float(0...6), ph2 = rng.float(0...6)
            let sq: Float = baroque ? 0.9 : 0.985
            let ball = Prim.cubeSphere(subdivisions: n, material: "ceramic.vitreous:" + tints[idx % 4]) { d in
                let lump = 1 + (baroque ? 0.06 : 0.016) * sin(d.x * 5 + ph1) * sin(d.y * 4 + ph2) + 0.006 * sin(d.z * 9 + ph1)
                return V3(d.x, d.y * sq, d.z) * (r * lump)
            }
            _ = key
            surfaces[key, default: Surface(material: "ceramic.vitreous:" + tints[idx % 4])].append(ball, Xform(translation: p, rotation: simd_quatf(angle: rng.float(0...6), axis: simd_normalize(V3(rng.float(-1...1), rng.float(0.1...1), rng.float(-1...1))))))
            // Silk knot in the gap before the next pearl.
            let kc = c + r + 0.00055
            let (kp, _) = at(kc)
            let knot = Prim.cubeSphere(subdivisions: 1, material: silk) { d in d * 0.0009 * V3(1, 0.8, 1) }
            m.add(knot, Xform(translation: kp))
            prevR = r; prevP = p
            s = c + r + 0.0011
            idx += 1
        }
        _ = prevR
        for (_, v) in surfaces { m.add(v) }
        // Gold box clasp at the back and fishhook tongue, with end cones (bead tips) on each side.
        let eR = dense.last!, eL = dense.first!
        let tip = Prim.lathe([V2(0, 0.0016), V2(0.0012, 0.0014), V2(0.0028, 0.0006), V2(0.0031, 0), V2(0.0028, -0.0006), V2(0.0008, -0.0014), V2(0, -0.0016)],
                             segments: 32, seamTile: 0.01, material: metal)
        let rot = simd_quatf(degrees: 90, axis: V3(0, 0, 1))
        m.add(tip, Xform(translation: eR, rotation: rot))
        m.add(tip, Xform(translation: eL, rotation: rot))
        let box = Prim.roundedBox(V3(0.0082, 0.0048, 0.0036), radius: 0.0011, bevelSegments: 3, material: metal)
        m.add(box, Xform(translation: eR + V3(-0.0058, 0, 0)))
        let face = Prim.roundedBox(V3(0.0058, 0.0033, 0.0007), radius: 0.0003, bevelSegments: 2, material: "metal.gold-leaf")
        m.add(face, Xform(translation: eR + V3(-0.0058, 0, 0.0019)))
        let tongue = catmull([V3(0.0008, 0, 0), V3(-0.0025, 0.0006, 0), V3(-0.0048, 0, 0), V3(-0.0058, -0.0012, 0)], per: 5)
        m.add(Prim.tube(tongue, radii: tongue.map { _ in 0.00065 }, sides: 10, seamTile: 0.01, material: metal),
              Xform(translation: eL + V3(0.0022, 0, 0)))
        return LODModel(m)
    }
}
