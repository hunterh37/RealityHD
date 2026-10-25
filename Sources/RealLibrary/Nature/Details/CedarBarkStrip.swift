import simd
import Foundation

/// One peeled strip of shaggy cedar bark, 40 cm long and 7 to 9 cm wide, curled along its length on the ground.
public struct CedarBarkStrip: RealAsset {
    public static let id = "cedar-bark-strip"
    public static let summary = "Peeled 40 cm strip of shaggy red cedar bark curled on the ground, with frayed fibrous edges and a smooth tan inner face."
    public static let tags = ["nature", "wood", "ground"]
    public static let budget = 1_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 40, distance: 0.7)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let nu = 20, nv = 8, th: Float = 0.004
        let len = rng.float(0.38...0.42), wid = rng.float(0.07...0.09)
        let ph = rng.float(0...6.28), ph2 = rng.float(0...6.28), ph3 = rng.float(0...6.28)
        let roll = rng.float(1.9...2.4), yaw = rng.float(-0.5...0.5)
        var outer = Surface(material: "bark.cypress:8C5A3E"), inner = Surface(material: "bark.cypress:B87C52")
        var cols: [Float] = []
        func pt(_ i: Int, _ j: Int, off: Float) -> V3 {
            let u = Float(i) / Float(nu), v = Float(j) / Float(nv) - 0.5
            let frayed = 1 - 0.14 * sin(u * 11 + ph) * sin(u * 5 + ph2) - 0.1 * abs(sin(u * 27 + ph3 + Float(j))) * (abs(v) * 2)
            let w = v * wid * frayed * (1 - 0.3 * pow(abs(u - 0.5) * 2, 3))
            let k = roll * (0.7 + 0.6 * u) + 0.3 * sin(u * 3 + ph)
            let R = max(wid * 0.5 / k, 0.012)
            let a = w / R
            let rr = R + off
            let p = V3(u * len - len / 2, rr * (1 - cos(a)) + 0.006 + 0.012 * sin(u * 2.2 + ph2) * u, rr * sin(a))
            var q = simd_quatf(angle: yaw, axis: .up).act(p)
            q.y = max(q.y, 0.001)
            return q
        }
        for j in 0...nv { for i in 0...nu {
            let u = Float(i) / Float(nu), v = Float(j) / Float(nv)
            outer.add(pt(i, j, off: th), .up, V2(u * len, v * wid))
            inner.add(pt(i, j, off: 0), .up, V2(u * len, v * wid))
            cols.append(0)
        }}
        let row = UInt32(nu + 1)
        for j in 0..<nv { for i in 0..<nu {
            let a = UInt32(j) * row + UInt32(i)
            outer.quad(a, a + 1, a + row + 1, a + row)
            inner.quad(a + row, a + row + 1, a + 1, a)
        }}
        outer.recomputeNormals(); inner.recomputeNormals()
        outer.computeTangents(); inner.computeTangents()
        m.add(outer); m.add(inner)
        // shaggy fiber tufts hanging off the long edges
        var fib = Surface(material: "bark.cypress:6E4028")
        for _ in 0..<14 {
            let i = rng.int(1...(nu - 1)), j = rng.chance(0.5) ? 0 : nv
            let a = pt(i, j, off: th * 0.5), b = pt(i + 1, j, off: th * 0.5)
            let out = V3(0, 0, j == 0 ? -1 : 1)
            let tip = (a + b) / 2 + simd_quatf(angle: yaw, axis: .up).act(out) * rng.float(0.008...0.016)
            let n = V3(0, 1, 0), base = fib.positions.count
            fib.add(a, n, V2(0, 0)); fib.add(b, n, V2(0.006, 0)); fib.add(V3(tip.x, max(tip.y - 0.004, 0.001), tip.z), n, V2(0.01, 0.02))
            fib.tri(UInt32(base), UInt32(base + 1), UInt32(base + 2)); fib.tri(UInt32(base + 2), UInt32(base + 1), UInt32(base))
        }
        m.add(fib)
        groundAO(&m, height: 0.03, floor: 0.65)
        PlantKit.finish(&m)
        return LODModel(levels: [DetailKit12.settle(m, sink: 0.002)], switchDistances: [])
    }
}
