import simd
import Foundation

/// Allotment sweetcorn block bed: sweetcorn sown in a 4 x 4 block (block planting for wind pollination)
/// on hoed loam, each plant a jointed stalk with brace roots, arching strap leaves, a branched tassel and
/// one or two husked cobs with brown silks.
public struct AllotmentSweetcornBlockBed: RealAsset {
    public static let id = "allotment-sweetcorn-block-bed"
    public static let summary = "Sweetcorn block bed tile, 2 x 2 m: a 4 x 4 block of mature sweetcorn with strap leaves, tassels and silked cobs over hoed soil."
    public static let tags = ["prop", "architecture", "facade", "ground", "garden", "outdoor"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 22, distance: 3.6, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(2.0, 1.6, 2.0)
    /// Plants per side of the block.
    public var grid = 4
    /// Stalk height (m) above the soil.
    public var stalkHeight: Float = 1.4
    /// Stalk and husk material.
    public var stalk: MaterialKey = "plant.stem:6C8A3C"
    /// Leaf material.
    public var leafMaterial: MaterialKey = "plant.stem:4C7A2C"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let sd = UInt32(truncatingIfNeeded: rng.int(0...99_999))
        let w = size.x, d = size.z, base: Float = 0.03
        var m = Model(name: Self.id)
        let sp: Float = 0.4
        func h(_ p: V2) -> Float {
            // Earthed-up ridges along each row.
            let row = (p.y / sp + Float(grid) / 2 - 0.5).rounded()
            let dz = p.y - (row - Float(grid) / 2 + 0.5) * sp
            let ridge = abs(p.x) < 0.85 && abs(dz) < 0.12 ? 0.03 * ACK.ridge(dz / 0.12) : 0
            return base + ridge + 0.006 * Noise.fbm(V3(p.x * 6, 0, p.y * 6), octaves: 3, seed: sd)
        }
        ACK.field(&m, w: w, d: d, base: base, segments: 28, material: "ground.dirt:4D3824", h)
        var lite = Model(name: Self.id + "-lite")
        ACK.field(&lite, w: w, d: d, base: base, segments: 10, material: "ground.dirt:4D3824", h)
        for i in 0..<grid { for j in 0..<grid {
            var r = rng.fork(i * grid + j)
            let c = V2((Float(i) - Float(grid - 1) / 2) * sp + r.float(-0.03...0.03), (Float(j) - Float(grid - 1) / 2) * sp + r.float(-0.02...0.02))
            let y0 = h(c) - 0.01
            let sh = stalkHeight * r.float(0.88...1.0)
            let bend = V3(r.float(-0.04...0.04), 0, r.float(-0.04...0.04))
            func at(_ t: Float) -> V3 { V3(c.x, y0 + t * sh, c.y) + bend * t * t }
            let stalkPts = (0...6).map { at(Float($0) / 6) }
            let stalkSurf = Prim.tube(stalkPts, radii: [0.016, 0.015, 0.014, 0.012, 0.01, 0.008, 0.005], sides: 7, seamTile: 0.2, material: stalk)
            m.add(stalkSurf); lite.add(stalkSurf)
            // Nodes.
            for k in 1...2 {
                m.add(Prim.torus(major: 0.016 - Float(k) * 0.0014, minor: 0.003, segments: 8, sides: 3, material: "plant.stem:7E8E48"),
                      Xform(translation: at(Float(k) * 0.3)))
            }
            // Brace roots.
            for k in 0..<3 {
                let a = Float(k) * 2.09 + r.float(0...0.6)
                let o = V3(cos(a), 0, sin(a))
                m.add(Prim.tube([at(0.035) + o * 0.012, at(0.012) + o * 0.04, at(0) + o * 0.06 - V3(0, 0.01, 0)], radii: [0.004, 0.0035, 0.003],
                                sides: 4, seamTile: 0.05, material: "plant.stem:9C8C5A"))
            }
            // Strap leaves, alternating sides up the stalk.
            let ny = r.float(0...6.28)
            for k in 0..<8 {
                let t = 0.12 + Float(k) * 0.095
                let yaw = ny + (k % 2 == 0 ? 0 : .pi) + r.float(-0.35...0.35)
                let len = (0.38 + 0.18 * sin(Float(k) / 8 * .pi)) * r.float(0.9...1.1)
                var lf = ACK.leaf(at(t), yaw: yaw, length: len, width: 0.085, lean: r.float(0.35...0.6), curl: r.float(0.9...1.4),
                                  fold: 0.3, segments: 4, twoSided: true, material: k < 2 ? "plant.stem:8C8A4A" : (k == 7 ? "plant.stem:6E8A3A" : leafMaterial))
                lf.positions = lf.positions.map { V3(max(-0.99, min(0.99, $0.x)), $0.y, max(-0.99, min(0.99, $0.z))) }
                m.add(lf)
                if k % 3 == 1 { lite.add(lf) }
            }
            // Tassel: central spike and branches.
            let top = at(1)
            let tassel: MaterialKey = "grass.lawn-thatch:B39A5C"
            m.add(Prim.tube([top, top + V3(0, 0.16, 0)], radii: [0.004, 0.0015], sides: 4, seamTile: 0.05, material: tassel))
            for k in 0..<6 {
                let a = Float(k) * 1.05 + r.float(0...0.4)
                let o = V3(cos(a), 0, sin(a))
                m.add(Prim.tube([top + V3(0, 0.02, 0), top + V3(0, 0.07, 0) + o * 0.05, top + V3(0, 0.06, 0) + o * 0.11], radii: [0.0028, 0.002, 0.001],
                                sides: 3, seamTile: 0.05, material: tassel))
            }
            // Cobs in husks with silks.
            for k in 0..<(r.chance(0.6) ? 2 : 1) {
                let t: Float = 0.45 + Float(k) * 0.1
                let a = ny + .pi / 2 + Float(k) * .pi
                let o = V3(cos(a), 0, sin(a))
                let tilt = simd_quatf(from: .up, to: simd_normalize(V3(0, 1, 0) + o * 0.5))
                let cc = at(t) + o * 0.06 + V3(0, 0.1, 0)
                m.add(Prim.superellipsoid(V3(0.07, 0.26, 0.07), exponent: 2.1, subdivisions: 2, material: "plant.stem:A9B46E") { dir in
                    1 - 0.25 * max(0, dir.y) * max(0, dir.y) }, Xform(translation: cc, rotation: tilt))
                let tip = cc + tilt.act(V3(0, 0.125, 0))
                for s in 0..<4 {
                    let b = Float(s) * 1.57
                    m.add(Prim.tube([tip, tip + V3(cos(b) * 0.025, 0.03, sin(b) * 0.025) + o * 0.02, tip + V3(cos(b) * 0.04, 0.0, sin(b) * 0.04) + o * 0.05],
                                    radii: [0.0012, 0.001, 0.0006], sides: 3, seamTile: 0.05, material: "plant.stem:6E4224"))
                }
            }
        }}
        // Fallen dry lower leaves on the soil.
        for i in 0..<8 {
            var r = rng.fork(600 + i)
            let p = V2(r.float(-0.85...0.85), r.float(-0.85...0.85))
            var lf = ACK.leaf(V3(p.x, h(p) + 0.004, p.y), yaw: r.float(0...6.28), length: r.float(0.3...0.45), width: 0.07, lean: 1.0, curl: 0.05,
                              fold: 0.2, segments: 4, twoSided: true, material: "plant.stem:A08C52")
            lf.positions = lf.positions.map { V3(max(-0.99, min(0.99, $0.x)), max(h(p) + 0.002, $0.y), max(-0.99, min(0.99, $0.z))) }
            m.add(lf)
        }
        // Hoe marks and a few stones.
        for i in 0..<4 {
            var r = rng.fork(700 + i)
            let p = V2(r.float(-0.95...0.95), r.float(-0.95...0.95))
            ACK.stone(&m, at: p, y: h(p) - 0.004, size: r.float(0.012...0.03), rng: &r)
        }
        return ACK.finish(&m, lite: lite, ao: 0.12)
    }
}
