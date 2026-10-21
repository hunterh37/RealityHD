import simd
import Foundation

/// Allotment strawberry plastic mulch: a 2 m square bed of two raised soil ridges covered in black
/// polythene, its edges dug into slit trenches along the furrows. Strawberry plants grow through
/// cross-cut slits: crowns of long-stalked trifoliate serrate leaves, white flowers, green and
/// ripening berries resting on tucked straw, and a few stones to stop the sheet lifting.
public struct AllotmentStrawberryPlasticMulch: RealAsset {
    public static let id = "allotment-strawberry-plastic-mulch"
    public static let summary = "2 m square strawberry bed of two ridges under black polythene mulch, plants through cross-cut slits, straw tucked under ripening fruit."
    public static let tags = ["prop", "architecture", "facade", "ground", "garden", "outdoor"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 34, distance: 2.6, studio: true)

    /// Tile footprint (m).
    public var width: Float = 2.0
    public var depth: Float = 2.0
    /// Furrow / margin soil height (m).
    public var base: Float = 0.03
    /// Ridge height above the furrow (m).
    public var ridgeHeight: Float = 0.08
    /// Ridge width at the base (m).
    public var ridgeWidth: Float = 0.75
    /// Plants per ridge row.
    public var plantsPerRow: Int = 3
    /// Polythene sheet.
    public var film: MaterialKey = "plastic.matte:1A1B1D"
    /// Leaf colour.
    public var leafColor: MaterialKey = "plant.stem:3D6B2A"
    /// Soil.
    public var soil: MaterialKey = "ground.dirt:4A3725"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let sd = UInt32(truncatingIfNeeded: rng.int(0...99_999))
        let w = width, d = depth
        let ridgeX: [Float] = [-0.48, 0.48]
        let rw = ridgeWidth / 2
        func ridgeProfile(_ x: Float) -> Float {
            var best: Float = 0
            for c in ridgeX { best = max(best, AK.ridge((x - c) / rw)) }
            return pow(best, 0.6)
        }
        func zFade(_ z: Float) -> Float { max(0, min(1, (d / 2 - abs(z) - 0.05) / 0.12)) }
        func soilH(_ p: V2) -> Float {
            let lump = 0.01 * Noise.fbm(V3(p.x * 6, 0, p.y * 6), octaves: 4, seed: sd) + 0.004 * Noise.ridged(V3(p.x * 25, 0, p.y * 25), octaves: 2, seed: sd + 1)
            let e = min(w / 2 - abs(p.x), d / 2 - abs(p.y))
            let k = max(0, min(1, (e - 0.04) / 0.08))
            return base + (ridgeHeight * ridgeProfile(p.x) * zFade(p.y) + lump + 0.008) * k
        }
        var m = Model(name: Self.id)
        AK.grid(&m, w: w, d: d, base: base, nx: 32, nz: 16, material: soil, soilH)
        // Film over each ridge: drapes with soft wrinkles, edges tucked under soil at the furrow.
        let filmHalf = rw + 0.04
        for (ri, cx) in ridgeX.enumerated() {
            let nx = 16, nz = 14
            let fd = d - 0.16
            var s = Surface(material: film)
            func fh(_ x: Float, _ z: Float) -> Float {
                let p = V2(cx + x, z)
                let wr = 0.004 * Noise.fbm(V3(p.x * 5, Float(ri), p.y * 1.6), octaves: 2, seed: sd + 3)
                    + 0.0025 * sin(p.y * 22 + 3 * Noise.fbm(V3(p.x * 2, 0, p.y * 2), octaves: 2, seed: sd + 4)) * AK.ridge(x / filmHalf)
                let tuck = max(0, (abs(x) - rw + 0.03) / 0.07)
                return soilH(p) + 0.003 + wr - 0.02 * tuck * tuck
            }
            for j in 0...nz { for i in 0...nx {
                let x = (Float(i) / Float(nx) - 0.5) * 2 * filmHalf, z = (Float(j) / Float(nz) - 0.5) * fd
                s.add(V3(cx + x, fh(x, z), z), .up, V2(cx + x, -z))
            }}
            let row = UInt32(nx + 1)
            for j in 0..<UInt32(nz) { for i in 0..<UInt32(nx) {
                let a = j * row + i
                s.quad(a, a + row, a + row + 1, a + 1)
            }}
            s.recomputeNormals(weldSeams: false)
            s.computeTangents()
            m.add(s)
            // Soil heeled back over the tucked edges.
            for sx: Float in [-1, 1] {
                for k in 0..<12 {
                    var r = rng.fork(ri * 100 + Int(sx + 1) * 40 + k)
                    let p = V2(cx + sx * (filmHalf - r.float(0.0...0.03)), -fd / 2 + Float(k) / 11 * fd + r.float(-0.02...0.02))
                    AK.clod(&m, at: p, y: soilH(p) - 0.006, size: r.float(0.02...0.04), rng: &r, sub: 1)
                }
                // Ends folded down at the bed ends.
            }
            // Plants through cross-cut slits.
            for pi in 0..<plantsPerRow {
                for lane: Float in [-0.17, 0.17] {
                    var r = rng.fork(ri * 1000 + pi * 10 + Int(lane > 0 ? 1 : 0))
                    let z = -fd / 2 + 0.22 + (Float(pi) + (lane > 0 ? 0.5 : 0)) * (fd - 0.44) / (Float(plantsPerRow) - 0.5)
                    let c = V2(cx + lane + r.float(-0.02...0.02), z)
                    let y = fh(c.x - cx, c.y)
                    // Slit flaps folded back.
                    for a: Float in [r.chance(0.5) ? 45 : 135, r.chance(0.5) ? 225 : 315] {
                        let rad = (a + r.float(-10...10)) * .pi / 180
                        let tip = V3(c.x + cos(rad) * 0.06, y + 0.012, c.y + sin(rad) * 0.06)
                        m.add(Prim.extrude([V2(0, -0.025), V2(0.06, 0), V2(0, 0.025)], depth: 0.0008, bevel: 0.0002, bevelSegments: 1, material: film),
                              Xform(translation: V3(c.x, y + 0.006, c.y), rotation: simd_quatf(angle: -rad, axis: .up) * simd_quatf(degrees: 90, axis: V3(1, 0, 0)) * simd_quatf(degrees: -12, axis: V3(0, 1, 0))))
                        _ = tip
                    }
                    // Soil in the planting hole.
                    m.add(Prim.superellipsoid(V3(0.045, 0.008, 0.045), exponent: 2.5, subdivisions: 1, material: soil), Xform(translation: V3(c.x, y + 0.001, c.y)))
                    plant(&m, at: V3(c.x, y + 0.004, c.y), rng: &r)
                }
            }
        }
        // Stones weighing the film at the ends.
        for i in 0..<6 {
            var r = rng.fork(7000 + i)
            let cx = ridgeX[i % 2]
            let p = V2(cx + r.float(-rw + 0.05...rw - 0.05), (i < 3 ? -1 : 1) * r.float(d / 2 - 0.2...d / 2 - 0.1))
            AK.stone(&m, at: p, y: soilH(p) + 0.004, size: r.float(0.05...0.09), rng: &r)
        }
        for i in 0..<5 {
            var r = rng.fork(7500 + i)
            let p = V2(r.float(-0.1...0.1), r.float(-d / 2 + 0.15...d / 2 - 0.15))
            AK.weed(&m, at: V3(p.x, soilH(p) - 0.003, p.y), height: r.float(0.05...0.09), count: 14, rng: &r,
                    material: r.chance(0.5) ? "grass.lawn" : "grass.dry")
        }
        var lite = Model(name: Self.id + "-lite")
        AK.field(&lite, w: w, d: d, base: base, segments: 36, material: film, soilH)
        return AK.finish(&m, lite: lite, ao: 0.07)
    }

    /// Strawberry crown: trifoliate leaves on hairy petioles, a truss of berries on straw, a flower.
    private func plant(_ m: inout Model, at c: V3, rng r: inout SeededRNG) {
        let n = r.int(4...5)
        for k in 0..<n {
            let yaw = Float(k) / Float(n) * 2 * .pi + r.float(-0.3...0.3)
            let L = r.float(0.07...0.1)
            let out = r.float(0.35...0.6)
            let dir = V3(cos(yaw), 0, sin(yaw))
            let top = c + dir * (L * out) + V3(0, L * (1 - out * 0.5), 0)
            let path = catmull([c, c + dir * (L * out * 0.2) + V3(0, L * 0.5, 0), top], per: 2)
            m.add(Prim.tube(path, radii: Array(repeating: 0.0013, count: path.count), sides: 3, seamTile: 0.03, material: "plant.stem:5E7A36", capEnd: true))
            // Three serrate leaflets fanned at the petiole tip.
            let sc = r.float(0.8...1.1)
            for (j, off) in ([-0.75, 0, 0.75] as [Float]).enumerated() {
                let ldir = V3(cos(yaw + off), r.float(0.05...0.25), sin(yaw + off))
                let len = (j == 1 ? 0.05 : 0.044) * sc
                m.add(AK.leaflet(top, dir: ldir, length: len, width: len * 0.75, cup: 0.25,
                                 material: r.chance(0.15) ? "plant.stem:7A6A2E" : leafColor))
            }
        }
        // Fruit truss lying out on a straw pad.
        let ty = r.float(0...(2 * .pi))
        let tdir = V3(cos(ty), 0, sin(ty))
        let pad = c + tdir * 0.11
        for k in 0..<8 {
            var q = r.fork(k)
            let a = q.float(0...(2 * .pi)), rr = q.float(0...0.06)
            let p0 = pad + V3(cos(a) * rr, -0.003 + q.float(0...0.006), sin(a) * rr)
            let b = q.float(0...(2 * .pi))
            let len = q.float(0.04...0.09)
            m.add(Prim.tube([p0, p0 + V3(cos(b) * len, q.float(-0.003...0.004), sin(b) * len)], radii: [0.0012, 0.0012], sides: 3,
                            seamTile: 0.05, material: "straw.hay", capEnd: true))
        }
        let berries = r.chance(0.3) ? 3 : 2
        for k in 0..<berries {
            let a = ty + Float(k - berries / 2) * 0.5
            let p = pad + V3(cos(a) * 0.03, 0.012, sin(a) * 0.03)
            m.add(Prim.tube(catmull([c + V3(0, 0.04, 0), c + tdir * 0.05 + V3(0, 0.05, 0), p + V3(0, 0.012, 0)], per: 2),
                            radii: Array(repeating: 0.0011, count: 5), sides: 3, seamTile: 0.03, material: "plant.stem:6E8A3E", capEnd: true))
            let ripe = r.float()
            let mat: MaterialKey = ripe < 0.45 ? "food.strawberry" : ripe < 0.75 ? "food.strawberry:E8A070" : "food.strawberry:C9D88A"
            let s = r.float(0.75...1.1)
            let prof: [V2] = [V2(0.0004, 0), V2(0.004 * s, 0.003 * s), V2(0.009 * s, 0.011 * s), V2(0.011 * s, 0.019 * s),
                              V2(0.01 * s, 0.025 * s), V2(0.005 * s, 0.028 * s), V2(0.0004, 0.0285 * s)]
            let rot = simd_quatf(degrees: 180 - r.float(40...70), axis: simd_normalize(simd_cross(V3(0, 1, 0), tdir) + V3(0.001, 0, 0)))
            let berry = Prim.lathe(prof, segments: 8, seamTile: 0.03, material: mat)
            m.add(berry, Xform(translation: p + V3(0, 0.012, 0), rotation: rot))
            // Calyx.
            let top = p + V3(0, 0.012, 0)
            for j in 0..<3 {
                let b = Float(j) / 3 * 2 * .pi
                m.add(AK.leaflet(top, dir: V3(cos(b), 0.3, sin(b)), length: 0.009, width: 0.004, cup: 0.1, material: leafColor))
            }
        }
        // White flower on some plants.
        guard r.chance(0.5) else { return }
        let fp = c + V3(-tdir.x * 0.05, 0.075, -tdir.z * 0.05)
        m.add(Prim.tube([c + V3(0, 0.02, 0), fp], radii: [0.001, 0.001], sides: 3, seamTile: 0.03, material: "plant.stem:6E8A3E", capEnd: true))
        for j in 0..<5 {
            let b = Float(j) / 5 * 2 * .pi
            m.add(AK.leaflet(fp, dir: V3(cos(b), 0.15, sin(b)), length: 0.011, width: 0.009, cup: 0.15, material: "plastic.matte:F2F0E6"))
        }
        m.add(Prim.superellipsoid(V3(0.006, 0.003, 0.006), exponent: 2, subdivisions: 1, material: "plastic.matte:E2C23A"), Xform(translation: fp + V3(0, 0.001, 0)))
    }
}
