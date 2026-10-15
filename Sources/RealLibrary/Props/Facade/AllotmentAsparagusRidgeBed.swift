import simd
import Foundation

/// Allotment asparagus bed: three earthed-up ridges along X over established crowns, spring spears
/// (green with purple-tinged scale tips) pushing through the ridge tops, two crowns already left to
/// fern with tall feathery fronds, straw tucked in the furrows and a painted row-marker stake.
public struct AllotmentAsparagusRidgeBed: RealAsset {
    public static let id = "allotment-asparagus-ridge-bed"
    public static let summary = "Asparagus bed of earthed-up ridges with fresh spears and feathery fern on established crowns, furrows between, a row marker."
    public static let tags = ["prop", "architecture", "facade", "ground", "wood"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 28, distance: 3.0, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(2.0, 0.5, 2.0)
    /// Ridge count.
    public var ridges: Int = 3
    /// Ridge height above the furrows (m).
    public var ridgeHeight: Float = 0.13
    /// Spear material.
    public var spear: MaterialKey = "plant.stem:6E8F3C"
    /// Fern material.
    public var fern: MaterialKey = "plant.stem:5F8A3A"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let sd = UInt32(truncatingIfNeeded: rng.int(0...99_999))
        let w = size.x, d = size.z, base: Float = 0.03
        let pitch = d / Float(ridges)
        func ridgeT(_ z: Float) -> Float {
            let u = (z + d / 2) / pitch - 0.5
            return AK.ridge(1.6 * (u - u.rounded()))
        }
        func h(_ p: V2) -> Float {
            let edge = min(1, (w / 2 - abs(p.x)) / 0.15)
            return base + 0.01 + 0.03 * (1 - edge) + edge * ridgeHeight * ridgeT(p.y) + 0.008 * Noise.fbm(V3(p.x * 5, 0, p.y * 5), octaves: 3, seed: sd)
        }
        var m = Model(name: Self.id)
        AK.grid(&m, w: w, d: d, base: base + 0.035, nx: 18, nz: 54, h)
        // Spears through the ridge crowns.
        for k in 0..<ridges {
            let z = -d / 2 + (Float(k) + 0.5) * pitch
            for i in 0..<14 {
                var r = rng.fork(100 + k * 20 + i)
                let p = V2(-0.85 + Float(i) * 0.13 + r.float(-0.03...0.03), z + r.float(-0.06...0.06))
                if (k == 1 && abs(p.x + 0.35) < 0.12) || (k == 2 && abs(p.x - 0.45) < 0.12) { continue }
                let y = h(p) - 0.01
                let ht = r.float(0.05...0.2), rad = r.float(0.005...0.0075)
                let lean = V3(r.float(-0.015...0.015), 0, r.float(-0.015...0.015))
                let top = V3(p.x, y + ht, p.y) + lean
                m.add(Prim.tube([V3(p.x, y, p.y), V3(p.x, y + ht * 0.5, p.y) + lean * 0.4, top], radii: [rad, rad * 0.95, rad * 0.85], sides: 6, seamTile: 0.04, material: spear))
                // Tight scale-leaf tip and a few scale bracts down the stem.
                // Tight scale-leaf tip: blunt turned bud.
                var tip = Prim.superellipsoid(V3(rad * 2.1, rad * 3.6, rad * 2.1), exponent: 2, subdivisions: 1, material: "plant.stem:7A5A6A")
                tip.uvs = tip.positions.map { V2(atan2($0.z, $0.x) * rad, $0.y) }
                tip.computeTangents()
                m.add(tip, Xform(translation: top + V3(0, rad * 1.2, 0)))
                for b in 1..<1 {
                    let bp = V3(p.x, y + ht * Float(b) * 0.24, p.y) + lean * Float(b) * 0.2
                    let a = Float(b) * 2.1 + r.float(0...1)
                    m.add(AK.leaflet(bp + V3(cos(a), 0, sin(a)) * rad * 0.9, dir: V3(cos(a) * 0.3, 1, sin(a) * 0.3), length: rad * 2.2, width: rad * 1.4, cup: 0.4, material: "plant.stem:6A6A3E"))
                }
                if ht > 0.17 { AK.clod(&m, at: p + V2(0.02, 0.01), y: h(p), size: 0.025, rng: &r) }
            }
        }
        // Two crowns left to fern: stems branching into feathery cladode sprays.
        for (c, (cx, ck)) in [(Float(-0.35), 1), (Float(0.45), 2)].enumerated() {
            var r = rng.fork(500 + c)
            let cz = -d / 2 + (Float(ck) + 0.5) * pitch
            for sIdx in 0..<8 {
                let root = V3(cx + r.float(-0.04...0.04), h(V2(cx, cz)) - 0.01, cz + r.float(-0.04...0.04))
                let ht = r.float(0.27...0.34) - (h(V2(cx, cz)) - base - 0.1)
                let lean = V3(r.float(-0.14...0.14), 0, r.float(-0.14...0.14))
                let path = catmull([root, root + V3(0, ht * 0.5, 0) + lean * 0.3, root + V3(0, ht, 0) + lean], per: 3)
                m.add(Prim.tube(path, radii: path.indices.map { 0.006 * (1 - 0.6 * Float($0) / Float(path.count - 1)) }, sides: 5, seamTile: 0.05, material: fern))
                for b in 0..<10 {
                    let t = 0.25 + Float(b) * 0.072
                    let bp = root + V3(0, ht * t, 0) + lean * t * t
                    let a = Float(b) * 2.4 + Float(sIdx)
                    let dir = simd_normalize(V3(cos(a), 0.4, sin(a)))
                    let blen = 0.23 * (1.1 - t * 0.6)
                    m.add(Prim.tube([bp, bp + dir * blen], radii: [0.0018, 0.001], sides: 3, seamTile: 0.05, material: fern))
                    // Needle-like cladodes in whorls along each branch: thin double-sided slivers.
                    var needles = Surface(material: c == 1 ? "plant.stem:A39A4A" : "plant.stem:6F9E45")
                    for n in 0..<5 {
                        let np = bp + dir * blen * (0.14 + Float(n) * 0.18)
                        for q in 0..<4 {
                            let qa = Float(q) * 1.57 + Float(n) * 0.7
                            let side = simd_normalize(simd_cross(dir, V3(cos(qa), sin(qa), 0.3)))
                            let tipP = np + side * r.float(0.03...0.042) + dir * 0.012
                            let wv = simd_normalize(simd_cross(side, dir)) * 0.0011
                            let nn = simd_normalize(simd_cross(tipP - np, wv))
                            let i0 = needles.add(np - wv, nn, V2(0, 0)), i1 = needles.add(np + wv, nn, V2(0.002, 0)), i2 = needles.add(tipP, nn, V2(0.001, 0.03))
                            needles.tri(i0, i1, i2); needles.tri(i0, i2, i1)
                        }
                    }
                    needles.computeTangents()
                    m.add(needles)
                }
            }
        }
        // Straw tucked in the furrows.
        var straw = Surface(material: "grass.dry")
        for i in 0..<50 {
            var r = rng.fork(800 + i)
            let k = r.int(0...(ridges))
            let z = -d / 2 + Float(k) * pitch + r.float(-0.08...0.08)
            let p = V2(r.float(-0.9...0.9), min(d / 2 - 0.09, max(-d / 2 + 0.09, z)))
            let a = r.float(-0.6...0.6), len = r.float(0.06...0.14)
            let c = V3(p.x, h(p) + 0.003, p.y), dv = V3(cos(a), 0, sin(a)) * len / 2
            straw.append(Prim.tube([c - dv, c + dv + V3(0, 0.004, 0)], radii: [0.0016, 0.0016], sides: 3, seamTile: 0.03, material: "grass.dry", capEnd: false))
        }
        m.add(straw)
        // Row marker: painted softwood stake with a pencilled name band.
        let mp = V2(-0.93, -d / 2 + 0.5 * pitch)
        m.add(Prim.roundedBox(V3(0.025, 0.3, 0.012), radius: 0.003, bevelSegments: 2, material: "wood.painted-exterior:E8E2D0"),
              Xform(translation: V3(mp.x, h(mp) + 0.1, mp.y), rotation: simd_quatf(degrees: 4, axis: V3(0, 0, 1))))
        m.add(Prim.roundedBox(V3(0.022, 0.06, 0.0125), radius: 0.001, bevelSegments: 1, material: "wood.painted-exterior:3E5A3A"),
              Xform(translation: V3(mp.x + 0.016, h(mp) + 0.22, mp.y), rotation: simd_quatf(degrees: 4, axis: V3(0, 0, 1))))
        for i in 0..<14 {
            var r = rng.fork(900 + i)
            let p = V2(r.float(-0.9...0.9), r.float(-0.92...0.92))
            if i % 2 == 0 { AK.stone(&m, at: p, y: h(p) - 0.004, size: r.float(0.012...0.03), rng: &r) }
            else { AK.weed(&m, at: V3(p.x, h(p) - 0.002, p.y), height: r.float(0.04...0.07), count: 10, rng: &r) }
        }
        var lite = Model(name: Self.id + "-lite")
        AK.grid(&lite, w: w, d: d, base: base + 0.035, nx: 6, nz: 24, h)
        return AK.finish(&m, lite: lite, ao: 0.1)
    }
}
