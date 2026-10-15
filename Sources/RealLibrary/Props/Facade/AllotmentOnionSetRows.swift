import simd
import Foundation

/// Allotment onion set rows: a 2 m square bed raked to a fine tilth with rows of onion sets pushed
/// in so only the papery necks show, a few weeks on with hollow green shoots. A garden line on
/// pegs marks the last row and white plastic labels stand at the row ends.
public struct AllotmentOnionSetRows: RealAsset {
    public static let id = "allotment-onion-set-rows"
    public static let summary = "2 m square allotment bed raked to fine tilth with five rows of onion sets showing green shoots, a garden line and row labels."
    public static let tags = ["prop", "architecture", "facade", "ground", "garden", "outdoor", "wood"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 34, distance: 2.6, studio: true)

    /// Tile footprint (m).
    public var width: Float = 2.0
    public var depth: Float = 2.0
    /// Number of set rows.
    public var rows: Int = 5
    /// Row spacing (m).
    public var spacing: Float = 0.3
    /// Set spacing along a row (m).
    public var setSpacing: Float = 0.15
    /// Raked tilth soil.
    public var tilth: MaterialKey = "ground.dirt:4E3A28"
    /// Onion skin (golden brown, papery).
    public var skin: MaterialKey = "food.onion-skin:B98A50"
    /// Shoot colour.
    public var shoot: MaterialKey = "plant.stem:3F7A2A"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let sd = UInt32(truncatingIfNeeded: rng.int(0...99_999))
        let w = width, d = depth, base: Float = 0.04
        let z0 = -Float(rows - 1) * spacing / 2
        func h(_ p: V2) -> Float {
            let u = (p.y - z0) / spacing
            let k = (u - u.rounded()) * spacing
            let inBed = u.rounded() >= 0 && u.rounded() <= Float(rows - 1) && abs(p.x) < w / 2 - 0.1
            // Soil drawn up slightly along each row where the sets were firmed in.
            let firm: Float = inBed ? 0.016 * max(0, 1 - pow(abs(k) / 0.06, 2)) - 0.006 * max(0, 1 - pow((abs(k) - 0.09) / 0.04, 2)) : 0
            let rake = 0.0035 * sin(p.x * 2 * .pi / 0.06 + 3 * Noise.fbm(V3(0, 0, p.y * 1.5), octaves: 2, seed: sd + 1))
            let tl = 0.006 * Noise.fbm(V3(p.x * 6, 0, p.y * 6), octaves: 4, seed: sd + 2) + 0.003 * Noise.ridged(V3(p.x * 30, 0, p.y * 30), octaves: 2, seed: sd + 3)
            let e = min(w / 2 - abs(p.x), d / 2 - abs(p.y))
            let f = max(0, min(1, (e - 0.04) / 0.08))
            return base + (firm + rake + tl + 0.006) * f
        }
        var m = Model(name: Self.id)
        AK.grid(&m, w: w, d: d, base: base, nx: 36, nz: 22, material: tilth, h)
        // Onion set: teardrop bulb, two thirds buried, dry neck tuft, shoots from the neck.
        let n = Int((w - 0.24) / setSpacing) + 1
        for row in 0..<rows {
            let zc = z0 + Float(row) * spacing
            for i in 0..<n {
                var r = rng.fork(row * 1000 + i)
                if r.chance(0.04) { continue } // a set taken by birds
                let x = -w / 2 + 0.12 + (Float(i) + r.float(-0.15...0.15)) * setSpacing
                let p = V2(x, zc + r.float(-0.008...0.008))
                let s = r.float(0.85...1.2)
                let rad = 0.011 * s, ht = 0.026 * s
                let prof: [V2] = [V2(0.0005, 0), V2(rad * 0.9, ht * 0.25), V2(rad, ht * 0.45),
                                  V2(rad * 0.6, ht * 0.75), V2(rad * 0.14, ht), V2(0.0005, ht * 1.04)]
                let y = h(p) - ht * r.float(0.55...0.7)
                let tilt = simd_quatf(degrees: r.float(-10...10), axis: V3(1, 0, 0)) * simd_quatf(degrees: r.float(-10...10), axis: V3(0, 0, 1))
                m.add(Prim.lathe(prof, segments: 5, seamTile: 0.03, material: r.chance(0.3) ? "food.onion-skin:9A6F3E" : skin),
                      Xform(translation: V3(p.x, y, p.y), rotation: tilt))
                let neck = V3(p.x, y, p.y) + tilt.act(V3(0, ht, 0))
                // Dry neck: a few papery wisps.
                for k in 0..<1 {
                    let a = r.float(0...(2 * .pi))
                    m.add(Prim.tube([neck, neck + V3(cos(a) * 0.004, 0.01, sin(a) * 0.004)], radii: [0.0009, 0.0004], sides: 3,
                                    seamTile: 0.02, material: "food.onion-skin:C9A46E", capEnd: true), Xform(translation: V3(0, Float(k) * 0.0005, 0)))
                }
                // Hollow shoots, two to four, bowing outward.
                let leaves = r.chance(0.2) ? 3 : 2
                for k in 0..<leaves {
                    let a = Float(k) / Float(leaves) * 2 * .pi + r.float(-0.5...0.5)
                    let L = r.float(0.045...0.07) * s
                    let bend = r.float(0.35...0.8)
                    let pts = [neck, neck + V3(cos(a) * L * 0.1 * bend, L * 0.5, sin(a) * L * 0.1 * bend),
                               neck + V3(cos(a) * L * 0.45 * bend, L * 0.88, sin(a) * L * 0.45 * bend),
                               neck + V3(cos(a) * L * 0.8 * bend, L * (0.95 - bend * 0.3), sin(a) * L * 0.8 * bend)]
                    let path = catmull(pts, per: 2)
                    let radii = path.indices.map { j -> Float in 0.0034 * (1 - 0.65 * Float(j) / Float(path.count - 1)) }
                    m.add(Prim.tube(path, radii: radii, sides: 4, seamTile: 0.03, material: k == 0 && r.chance(0.3) ? "plant.stem:9AA05A" : shoot, capEnd: true))
                }
            }
        }
        // Garden line along the last row: pegs and taut jute twine.
        let lz = z0 + Float(rows - 1) * spacing + 0.06
        let pegX = w / 2 - 0.06
        let pegTop = base + 0.085
        for sx: Float in [-1, 1] {
            var r = rng.fork(9000 + Int(sx + 1))
            let px = sx * pegX
            m.add(Prim.roundedBox(V3(0.025, pegTop - base + 0.03, 0.025), radius: 0.003, bevelSegments: 1, material: "wood.pine-aged"),
                  Xform(translation: V3(px, (pegTop + base - 0.03) / 2, lz), rotation: simd_quatf(degrees: r.float(-6...6), axis: V3(0, 0, 1))))
            for k in 0..<3 {
                m.add(Prim.torus(major: 0.016, minor: 0.0025, segments: 12, sides: 4, material: "sack.jute"), Xform(translation: V3(px, pegTop - 0.028 - Float(k) * 0.005, lz)))
            }
        }
        let lineY = pegTop - 0.033
        m.add(Prim.tube([V3(-pegX + 0.016, lineY, lz), V3(0, lineY - 0.003, lz), V3(pegX - 0.016, lineY, lz)], radii: [0.0012, 0.0012, 0.0012],
                        sides: 4, seamTile: 0.05, material: "sack.jute", capEnd: true))
        // Row labels with pencilled variety names.
        for row in 0..<rows {
            var r = rng.fork(9500 + row)
            let zc = z0 + Float(row) * spacing + 0.04
            let x = -w / 2 + 0.07
            let tilt = simd_quatf(degrees: r.float(-10...10), axis: V3(1, 0, 0)) * simd_quatf(degrees: r.float(-8...8), axis: V3(0, 0, 1))
            m.add(Prim.extrude([V2(-0.009, 0), V2(0.009, 0), V2(0.009, 0.1), V2(0, 0.112), V2(-0.009, 0.1)],
                               depth: 0.0015, bevel: 0.0003, bevelSegments: 1, material: "plastic.white"),
                  Xform(translation: V3(x, base - 0.03, zc), rotation: simd_quatf(degrees: 90, axis: .up) * tilt))
            m.add(Prim.roundedBox(V3(0.0004, 0.03, 0.011), radius: 0.0001, bevelSegments: 1, material: "plastic.matte:6A6A6A"),
                  Xform(translation: V3(x + 0.001, base + 0.045, zc), rotation: tilt))
        }
        for i in 0..<10 {
            var r = rng.fork(12000 + i)
            let p = V2(r.float(-w / 2 + 0.05...w / 2 - 0.05), r.float(-d / 2 + 0.05...d / 2 - 0.05))
            AK.stone(&m, at: p, y: h(p) - 0.003, size: r.float(0.01...0.028), rng: &r)
        }
        for i in 0..<12 {
            var r = rng.fork(13000 + i)
            let p = V2(r.float(-w / 2 + 0.06...w / 2 - 0.06), r.float(-d / 2 + 0.06...d / 2 - 0.06))
            AK.clod(&m, at: p, y: h(p) - 0.002, size: r.float(0.01...0.022), rng: &r, sub: 1)
        }
        var lite = Model(name: Self.id + "-lite")
        AK.field(&lite, w: w, d: d, base: base, segments: 36, material: tilth, h)
        return AK.finish(&m, lite: lite, ao: 0.06)
    }
}
