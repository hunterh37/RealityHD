import simd
import Foundation

/// Precast concrete slab paving tile, 2 x 2 m: 600 x 600 x 40 mm hydraulically pressed concrete
/// slabs with arrissed edges, laid stack-bond on a sand-cement bed with pointed mortar joints, tonal
/// variation between slabs, one cracked slab that rocks, and a rust-brown leaf stain.
public struct PrecastConcreteSlabPaving: RealAsset {
    public static let id = "precast-concrete-slab-paving"
    public static let summary = "Precast concrete slab paving tile, 2 x 2 m: 600 x 600 x 40 mm pressed slabs with arrissed edges and mortar joints on a sand-cement bed."
    public static let tags = ["prop", "architecture", "facade", "ground", "stone", "concrete"]
    public static let budget = 6000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 40, distance: 2.4, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(2.0, 0.06, 2.0)
    /// Slab module (m).
    public var module: Float = 0.6
    /// Slab thickness (m).
    public var thickness: Float = 0.04
    /// Joint width (m).
    public var joint: Float = 0.008
    /// Slab tones (sRGB hex).
    public var tones: [UInt32] = [0xA7A49D, 0x9D9A93, 0xAFACA4, 0x96938B, 0xA29E95]
    /// Slab concrete.
    public var concrete: MaterialKey = "concrete.smooth"
    /// Joint mortar.
    public var mortar: MaterialKey = "concrete.rough:7E7A72"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let g = joint, top = size.y, hx = size.x / 2, hz = size.z / 2
        // Grid starts offset so the tile shows full slabs plus cut slabs at two edges.
        let off: Float = 0.1
        let crack = (rng.int(0...2), rng.int(0...2))
        var xs: [Float] = [-hx]; var x = -hx + off
        while x < hx - 0.01 { xs.append(x); x += module }
        xs.append(hx)
        var zs: [Float] = [-hz]; var z = -hz + off + 0.2
        while z < hz - 0.01 { zs.append(z); z += module }
        zs.append(hz)
        for i in 0..<(xs.count - 1) { for j in 0..<(zs.count - 1) {
            let x0 = xs[i] + g / 2, x1 = xs[i + 1] - g / 2, z0 = zs[j] + g / 2, z1 = zs[j + 1] - g / 2
            guard x1 - x0 > 0.03, z1 - z0 > 0.03 else { continue }
            let mat = rng.chance(0.25) ? "concrete.rough:\(String(format: "%06X", rng.pick([0x8C8981, 0x84817A, 0x7E7B74])))" : "\(concrete):\(String(format: "%06X", rng.pick(tones)))"
            if i == crack.0 + 1 && j == crack.1 + 1 {
                // Cracked slab: two pieces split on a diagonal, one dropped and tilted.
                let a = V2(x0, z0 + (z1 - z0) * 0.3), b = V2(x1, z0 + (z1 - z0) * 0.62)
                let n = simd_normalize(V2(-(b - a).y, (b - a).x))
                let quad = FPK.rect((x0 + x1) / 2, (z0 + z1) / 2, x1 - x0, z1 - z0)
                FPK.piece(&m, FPK.clipHalf(quad, o: a + n * 0.003, n: -n), top: top, thick: thickness, bevel: 0.004, mat, tilt: 0.2, rng: &rng)
                FPK.piece(&m, FPK.clipHalf(quad, o: a - n * 0.003, n: n), top: top - 0.004, thick: thickness, bevel: 0.004, mat, tilt: 0.9, rng: &rng)
            } else {
                FPK.piece(&m, FPK.rect((x0 + x1) / 2, (z0 + z1) / 2, x1 - x0, z1 - z0), top: top + rng.float(-0.001...0.001),
                          thick: thickness, bevel: 0.004, mat, tilt: 0.15, rng: &rng)
            }
        }}
        // Leaf stain: a faint rust-brown print on one slab.
        for _ in 0..<5 {
        let lc = V2(rng.float(-0.8...0.8), rng.float(-0.8...0.8)), ly = rng.float(0...6.28), ls = rng.float(0.8...1.4)
        GK.poly(&m, (0..<14).map { k in
            let a = Float(k) / 14 * 2 * .pi, r = 0.045 * ls * (1 - 0.55 * pow(abs(cos(a)), 3)) * (1 + 0.1 * sin(a * 6))
            let p = V2(cos(a) * r * 1.6, sin(a) * r)
            return lc + V2(p.x * cos(ly) - p.y * sin(ly), p.x * sin(ly) + p.y * cos(ly))
        }, top: top + 0.0004, "concrete.rough:8A7A64", thick: 0.0006)
        }
        // Lichen spots: small grey-green crusts on the less trafficked edge slabs.
        for k in 0..<26 {
            var r = rng.fork(900 + k)
            let c = V2(r.float(-0.95...0.95), r.float(0.55...0.95)), rad = r.float(0.008...0.022)
            GK.poly(&m, (0..<9).map { i in let a = Float(i) / 9 * 2 * .pi; return c + V2(cos(a), sin(a)) * rad * (1 + 0.2 * sin(a * 3 + Float(k))) },
                    top: top + 0.0002, ["concrete.rough:6F7468", "concrete.rough:8E9284", "concrete.rough:5E5F58"][r.int(0...2)], thick: 0.0005)
        }
        // Pointed mortar joints, recessed 3 mm, over the sand-cement bed.
        GK.slab(&m, w: size.x - 0.004, d: size.z - 0.004, h: top - 0.003, mortar, r: 0.002)
        groundAO(&m, height: 0.04, floor: 0.75)
        var lite = Model(name: Self.id + "-lite")
        lite.add(Prim.roundedBox(V3(size.x, top, size.z), radius: 0.004, bevelSegments: 1, material: concrete), Xform(translation: V3(0, top / 2, 0)))
        return LODModel(levels: [m, lite], switchDistances: [10])
    }
}
