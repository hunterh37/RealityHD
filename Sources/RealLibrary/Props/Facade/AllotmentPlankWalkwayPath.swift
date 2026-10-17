import simd
import Foundation

/// Allotment plank walkway path: reclaimed 225 x 38 mm scaffold planks laid across three 75 x 50 mm
/// timber bearers sunk into the soil, galvanized hoop bands on the plank ends, nail heads over each
/// bearer, trodden soil verges with weeds pushing up through the gaps.
public struct AllotmentPlankWalkwayPath: RealAsset {
    public static let id = "allotment-plank-walkway-path"
    public static let summary = "Allotment walkway of weathered scaffold planks nailed across sunken timber bearers, banded ends, soil verges with weeds between the boards."
    public static let tags = ["prop", "architecture", "facade", "ground", "wood"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 32, distance: 2.8, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(2.0, 0.1, 2.0)
    /// Plank count across the walkway.
    public var planks: Int = 5
    /// Plank width and thickness (m).
    public var plankWidth: Float = 0.225
    public var plankThick: Float = 0.038
    /// Plank material.
    public var plankMaterial: MaterialKey = "wood.weathered"
    /// Bearer material.
    public var bearerMaterial: MaterialKey = "wood.pine-aged"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let sd = UInt32(truncatingIfNeeded: rng.int(0...99_999))
        let w = size.x, d = size.z, base: Float = 0.03
        func h(_ p: V2) -> Float { base + 0.008 * Noise.fbm(V3(p.x * 5, 0, p.y * 5), octaves: 3, seed: sd) }
        var m = Model(name: Self.id)
        AK.field(&m, w: w, d: d, base: base, segments: 20, material: "ground.dirt:5A4532", h)
        let gap: Float = 0.022
        let span = Float(planks) * plankWidth + Float(planks - 1) * gap
        let bearerTop = base + 0.012
        // Bearers along Z, half sunk.
        let bx: [Float] = [-0.78, 0.02, 0.8]
        for (i, x) in bx.enumerated() {
            var r = rng.fork(100 + i)
            m.add(Prim.roundedBox(V3(0.075, 0.05, span + 0.12), radius: 0.004, bevelSegments: 2, material: bearerMaterial),
                  Xform(translation: V3(x + r.float(-0.01...0.01), bearerTop - 0.025, 0), rotation: simd_quatf(degrees: r.float(-1...1), axis: .up)))
        }
        let y0 = bearerTop + plankThick / 2
        for i in 0..<planks {
            var r = rng.fork(i)
            let z = -span / 2 + plankWidth / 2 + Float(i) * (plankWidth + gap) + r.float(-0.006...0.006)
            let len = w - 0.03 - r.float(0...0.05)
            let xo = r.float(-0.015...0.015)
            let mat: MaterialKey = i == 2 ? "wood.pine-aged" : plankMaterial
            let tilt = simd_quatf(degrees: r.float(-0.8...0.8), axis: V3(1, 0, 0)) * simd_quatf(degrees: r.float(-0.6...0.6), axis: .up)
            m.add(plank(len, plankWidth - 0.002, plankThick, bevel: 0.005, material: mat),
                  Xform(translation: V3(xo, y0 + r.float(0...0.003), z), rotation: tilt))
            // Hoop bands 45 mm from each end, nailed.
            for s: Float in [-1, 1] {
                let cx = xo + s * (len / 2 - 0.05)
                m.add(Prim.roundedBox(V3(0.024, plankThick + 0.003, plankWidth + 0.003), radius: 0.0012, bevelSegments: 1, material: "metal.galvanized-aged"),
                      Xform(translation: V3(cx, y0, z), rotation: tilt))
                rivet(&m, at: V3(cx, y0 + plankThick / 2 + 0.0015, z + 0.07), normal: .up, radius: 0.003, material: "metal.galvanized-aged")
                rivet(&m, at: V3(cx, y0 + plankThick / 2 + 0.0015, z - 0.07), normal: .up, radius: 0.003, material: "metal.galvanized-aged")
            }
            // Two nails into each bearer.
            for x in bx { for k: Float in [-0.06, 0.06] {
                rivet(&m, at: V3(x + r.float(-0.01...0.01), y0 + plankThick / 2 + 0.001, z + k), normal: .up, radius: 0.0035, height: 0.0015, segments: 8, material: "metal.rust")
            }}
            // Split at one plank end.
            if i == 1 {
                m.add(Prim.roundedBox(V3(0.14, 0.006, 0.004), radius: 0.001, bevelSegments: 1, material: "wood.endgrain-weathered"),
                      Xform(translation: V3(xo + len / 2 - 0.08, y0 + plankThick / 2 - 0.002, z + 0.03)))
            }
        }
        // Weeds and moss in gaps and along the verges.
        for k in 0..<(planks - 1) {
            let z = -span / 2 + Float(k + 1) * (plankWidth + gap) - gap / 2
            for j in 0..<6 {
                var r = rng.fork(300 + k * 9 + j)
                AK.weed(&m, at: V3(r.float(-0.9...0.9), bearerTop - 0.005, z), height: r.float(0.045...0.062), count: 14, rng: &r)
            }
        }
        for j in 0..<26 {
            var r = rng.fork(400 + j)
            let side: Float = r.chance(0.5) ? -1 : 1
            let p = V2(r.float(-0.88...0.88), side * r.float(span / 2 + 0.04...d / 2 - 0.09))
            if j % 3 == 0 { AK.stone(&m, at: p, y: h(p) - 0.004, size: r.float(0.015...0.035), rng: &r) }
            else {
                // Dandelion and plantain rosettes: flat lobed leaves round a crown.
                let n = r.int(5...8), len = r.float(0.06...0.09)
                let mat: MaterialKey = r.chance(0.5) ? "plant.stem:4F6B32" : "plant.stem:5E7A3A"
                for k in 0..<n {
                    m.add(AK.leaf(V3(p.x, h(p) - 0.002, p.y), yaw: Float(k) / Float(n) * 6.283 + r.float(-0.3...0.3), length: len * r.float(0.8...1.1),
                                  width: len * 0.32, lean: r.float(0.9...1.0), curl: 0.1, fold: 0.15, segments: 4, material: mat))
                }
            }
        }
        for j in 0..<8 {
            var r = rng.fork(500 + j)
            let p = V2(r.float(-0.92...0.92), (r.chance(0.5) ? -1 : 1) * r.float(span / 2 + 0.06...d / 2 - 0.06))
            AK.clod(&m, at: p, y: h(p) - 0.006, size: r.float(0.02...0.04), rng: &r, material: AK.dryClod)
        }
        var lite = Model(name: Self.id + "-lite")
        AK.field(&lite, w: w, d: d, base: base, segments: 6, material: "ground.dirt:5A4532") { _ in base }
        lite.add(Prim.roundedBox(V3(w - 0.04, plankThick, span), radius: 0.004, bevelSegments: 1, material: plankMaterial), Xform(translation: V3(0, y0, 0)))
        return AK.finish(&m, lite: lite, ao: 0.06)
    }
}
