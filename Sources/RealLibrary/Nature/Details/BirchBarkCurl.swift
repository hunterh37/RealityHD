import simd
import Foundation

/// Three curls of peeled paper birch bark, 10-18 cm long, white outside and tan inside, 1 mm thick.
public struct BirchBarkCurl: RealAsset {
    public static let id = "birch-bark-curl"
    public static let summary = "Three curled strips of peeled paper birch bark, 10-18 cm, white outside, tan inside, with dark lenticels."
    public static let tags = ["nature", "wood", "ground"]
    public static let budget = 3_200
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 40, distance: 0.7)
    public init() {}

    func curl(_ m: inout Model, at o: V3, yaw: Float, len: Float, wid: Float, roll: Float, rng: inout SeededRNG) {
        let nu = 14, nv = 10, th: Float = 0.0012
        var outer = Surface(material: "bark.birch"), inner = Surface(material: "bark.birch:C48E5C")
        let ph = rng.float(0...6.28), ph2 = rng.float(0...6.28)
        func pt(_ i: Int, _ j: Int, off: Float) -> V3 {
            let u = Float(i) / Float(nu), v = Float(j) / Float(nv) - 0.5
            // ragged edge: width narrows with noise, ends torn
            let edge = 1 - 0.18 * sin(u * 9 + ph) * sin(u * 4 + ph2) - 0.25 * pow(abs(u - 0.5) * 2, 3)
            let w = v * wid * edge
            // curl: strip rolls up around its long axis more toward one end
            let k = roll * (0.6 + 0.8 * u) + 0.4 * sin(u * 3 + ph)
            let R = 1 / max(0.001, abs(k)) * wid * 0.5
            let a = w / max(R, 0.004) * (k > 0 ? 1 : -1)
            let rr = max(R, 0.004) + off
            let x = u * len - len / 2
            let yl = rr * (1 - cos(a)) * 1, zl = rr * sin(a)
            let p = V3(x, yl + 0.004 + 0.01 * sin(u * 2.4 + ph2) * 0.5, zl)
            let q = simd_quatf(angle: yaw, axis: .up)
            var r = q.act(p) + o
            r.y = max(r.y, 0.001)
            return r
        }
        for j in 0...nv { for i in 0...nu {
            let u = Float(i) / Float(nu), v = Float(j) / Float(nv)
            outer.add(pt(i, j, off: th), .up, V2(u * len, v * wid))
            inner.add(pt(i, j, off: -th * 0.2), .up, V2(u * len, v * wid))
        }}
        let row = UInt32(nu + 1)
        for j in 0..<nv { for i in 0..<nu {
            let a = UInt32(j) * row + UInt32(i)
            outer.quad(a, a + 1, a + row + 1, a + row)
            inner.quad(a + row, a + row + 1, a + 1, a)
        }}
        outer.recomputeNormals(); inner.recomputeNormals()
        m.add(outer); m.add(inner)
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        curl(&m, at: V3(0, 0, 0), yaw: rng.float(-0.4...0.4), len: rng.float(0.15...0.18), wid: rng.float(0.07...0.085), roll: 1.6, rng: &rng)
        curl(&m, at: V3(0.02, 0, 0.1), yaw: rng.float(0.6...1.4), len: rng.float(0.11...0.14), wid: rng.float(0.05...0.065), roll: -1.2, rng: &rng)
        curl(&m, at: V3(-0.05, 0, -0.09), yaw: rng.float(-1.2...(-0.4)), len: rng.float(0.1...0.12), wid: rng.float(0.04...0.055), roll: 2.0, rng: &rng)
        // lenticel dashes on outer face of first curl are carried by the bark.birch texture; add dry leaf scraps
        for _ in 0..<4 {
            let p = rng.inDisc(radius: 0.14)
            var b = PlantKit.Blade()
            b.root = V3(p.x, 0.0005, p.y); b.yaw = rng.float(0...6.28); b.length = rng.float(0.03...0.05); b.width = rng.float(0.02...0.03)
            b.lean = 1.5; b.curl = 0.1; b.segments = 3; b.tipWidth = 0.1; b.belly = 0.6; b.weight = V2(0, 0)
            m.add(PlantKit.blade(b, material: "leaf.birch:A08030"))
        }
        groundAO(&m, height: 0.03, floor: 0.65)
        PlantKit.finish(&m)
        return LODModel(levels: [m], switchDistances: [])
    }
}
