import simd
import Foundation

/// Allotment leek trench bed: a spade-dug trench across the plot with the spoil heaped along its
/// north side ready for earthing up, a row of leeks in the trench floor (blanched white shafts,
/// V-folded blue-green leaf fans), a second row freshly dibbed into open holes, and a pair of
/// weathered scaffold planks laid as a walking board with a cleat screwed across each end.
public struct AllotmentLeekTrenchBed: RealAsset {
    public static let id = "allotment-leek-trench-bed"
    public static let summary = "Leek bed: a spade-dug trench with the spoil heaped alongside, leeks dibbed in rows with blanched shafts and blue-green fans, a board path."
    public static let tags = ["prop", "architecture", "facade", "ground", "garden", "outdoor", "wood"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 32, distance: 2.8, studio: true)

    /// Tile footprint (m).
    public var width: Float = 2.0
    public var depth: Float = 2.0
    /// Trench centre line (z), width and depth below the bed surface (m).
    public var trenchZ: Float = 0.1
    public var trenchWidth: Float = 0.3
    public var trenchDepth: Float = 0.085
    /// Leeks per row.
    public var leeksPerRow: Int = 9
    /// Leek leaf material (tinted stem shader, blue-green).
    public var leaf: MaterialKey = "plant.stem:3E5A48"
    /// Blanched shaft material.
    public var shaft: MaterialKey = "plant.stem:D8D6BC"
    /// Walking board material.
    public var plank: MaterialKey = "wood.weathered"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let sd = UInt32(truncatingIfNeeded: rng.int(0...99_999))
        let w = width, d = depth, base: Float = 0.07
        let dibZ: Float = -0.4
        func h(_ p: V2) -> Float {
            let lump = 0.008 * Noise.fbm(V3(p.x * 8, 0, p.y * 8), octaves: 4, seed: sd) + 0.004 * Noise.ridged(V3(p.x * 25, 0, p.y * 25), octaves: 2, seed: sd + 1)
            let tz = (p.y - trenchZ) / (trenchWidth / 2)
            let wob = 0.1 * Noise.fbm(V3(p.x * 2, 0, 0), octaves: 2, seed: sd + 2)
            let trench = -trenchDepth * pow(max(0, 1 - pow(abs(tz + wob), 4)), 0.6)
            let sz = (p.y - (trenchZ + trenchWidth / 2 + 0.17)) / 0.17
            let spoil = 0.05 * AK.ridge(sz) * (1 + 0.25 * Noise.fbm(V3(p.x * 3, 0, 0), octaves: 2, seed: sd + 3))
            let e = min(w / 2 - abs(p.x), d / 2 - abs(p.y))
            let f = max(0, min(1, (e - 0.04) / 0.1))
            return base + (trench + spoil) * f + lump
        }
        var m = Model(name: Self.id)
        AK.field(&m, w: w, d: d, base: base, segments: 40, h)
        func leek(_ c: V2, y: Float, scale: Float, r: inout SeededRNG, holeDepth: Float) {
            let shaftH = 0.075 * scale
            let rad = 0.011 * scale
            m.add(Prim.cylinder(radius: rad, height: shaftH + holeDepth, bevel: 0.002, segments: 8, material: shaft),
                  Xform(translation: V3(c.x, y - holeDepth, c.y), rotation: simd_quatf(degrees: r.float(-4...4), axis: V3(1, 0, 0))))
            let top = V3(c.x, y + shaftH - 0.01, c.y)
            let fan = r.float(0...(2 * .pi))
            for k in 0..<5 {
                let side: Float = k % 2 == 0 ? 1 : -1
                let yaw = fan + (side > 0 ? 0 : .pi) + r.float(-0.2...0.2)
                m.add(AK.leaf(top + V3(0, Float(k) * 0.006, 0), yaw: yaw, length: r.float(0.09...0.12) * scale, width: 0.026 * scale,
                              lean: 0.15 + Float(k) * 0.05, curl: r.float(0.6...1.1), fold: 0.35, segments: 4, twoSided: true, material: leaf))
            }
        }
        // Trench row: leeks well up, the spoil waiting to be drawn back round them.
        for i in 0..<leeksPerRow {
            var r = rng.fork(i)
            let x = -w / 2 + 0.17 + (Float(i) + r.float(-0.12...0.12)) * (w - 0.34) / Float(leeksPerRow - 1)
            let c = V2(x, trenchZ + r.float(-0.02...0.02))
            leek(c, y: h(c) - 0.005, scale: r.float(0.9...1.02), r: &r, holeDepth: 0.03)
        }
        // Dibbed row: young leeks dropped into 15 cm dibber holes, shafts in shadow.
        for i in 0..<leeksPerRow {
            var r = rng.fork(100 + i)
            let x = -w / 2 + 0.17 + (Float(i) + r.float(-0.1...0.1)) * (w - 0.34) / Float(leeksPerRow - 1)
            let c = V2(x, dibZ)
            let y = h(c)
            // Hole: dark open ring of soil around the shaft.
            m.add(Prim.lathe([V2(0.024, 0.004), V2(0.021, 0.001), V2(0.017, -0.004), V2(0.015, -0.03), V2(0.0, -0.032)].reversed(),
                             segments: 12, seamTile: 0.1, material: "ground.dirt:2A1E14"), Xform(translation: V3(c.x, y, c.y)))
            leek(c, y: y - 0.01, scale: r.float(0.65...0.8), r: &r, holeDepth: 0.03)
        }
        // Clods on the spoil heap and loose crumb at the trench lip.
        for i in 0..<40 {
            var r = rng.fork(3000 + i)
            let p = V2(r.float(-w / 2 + 0.1...w / 2 - 0.1), trenchZ + trenchWidth / 2 + r.float(0.03...0.32))
            AK.clod(&m, at: p, y: h(p) - 0.006, size: r.float(0.03...0.07), rng: &r, material: r.chance(0.3) ? AK.dryClod : AK.clod)
        }
        for i in 0..<16 {
            var r = rng.fork(4000 + i)
            let p = V2(r.float(-w / 2 + 0.06...w / 2 - 0.06), r.float(-d / 2 + 0.06...d / 2 - 0.06))
            AK.stone(&m, at: p, y: h(p) - 0.004, size: r.float(0.015...0.04), rng: &r)
        }
        // Walking board: two scaffold planks with a cleat screwed across each end.
        let pz: Float = -0.78, pw: Float = 0.225, pt: Float = 0.038
        let py = base + 0.012
        for (k, off) in [-pw / 2 - 0.003, pw / 2 + 0.003].enumerated() {
            var r = rng.fork(6000 + k)
            m.add(RealLibrary.plank(1.8, pw, pt, bevel: 0.004, material: plank),
                  Xform(translation: V3(r.float(-0.02...0.02), py + pt / 2, pz + off), rotation: simd_quatf(degrees: r.float(-0.8...0.8), axis: .up)))
        }
        for sx: Float in [-1, 1] {
            let cx = sx * 0.78
            m.add(RealLibrary.plank(0.47, 0.07, 0.022, bevel: 0.003, material: "wood.pine-aged"),
                  Xform(translation: V3(cx, py + pt + 0.011, pz), rotation: simd_quatf(degrees: 90, axis: .up)))
            for zz: Float in [-0.17, -0.06, 0.06, 0.17] {
                AK.screw(&m, at: V3(cx, py + pt + 0.0225, pz + zz), normal: .up)
            }
        }
        // Soil trodden onto the boards.
        for i in 0..<10 {
            var r = rng.fork(7000 + i)
            AK.clod(&m, at: V2(r.float(-0.8...0.8), pz + r.float(-0.2...0.2)), y: py + pt - 0.002, size: r.float(0.012...0.025), rng: &r, sub: 1)
        }
        var lite = Model(name: Self.id + "-lite")
        AK.field(&lite, w: w, d: d, base: base, segments: 28, h)
        lite.add(RealLibrary.plank(1.8, pw * 2, pt, material: plank), Xform(translation: V3(0, py + pt / 2, pz)))
        return AK.finish(&m, lite: lite, ao: 0.1)
    }
}
