import simd
import Foundation

/// Plush toy cat, 30 cm tall sitting: white and orange fuzzy pile, glossy eyes, pink nose, triangular ears and
/// a curled tail. Faces +Z.
public struct PlushCat: RealAsset {
    public static let id = "plush-cat"
    public static let summary = "Plush cat toy: 30 cm sitting, fuzzy white and orange pile, glossy eyes, pink nose, triangular ears, curled tail."
    public static let tags = ["prop", "toy", "handheld"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 12)

    /// Main pile fabric key.
    public var white = "fabric.plush-white"
    /// Patch pile fabric key.
    public var orange = "fabric.plush-orange"
    /// Fur noise amplitude as a fraction of radius.
    public var fuzz: Float = 0.035
    public init() {}

    static func puff(_ size: V3, _ mat: String, sub: Int = 9, amp: Float, ph: Float, exponent: Float = 2.4) -> Surface {
        Prim.superellipsoid(size, exponent: exponent, subdivisions: sub, material: mat, bulge: { d in
            let n = sin(d.x * 17 + ph) * sin(d.y * 19 - ph) + sin(d.z * 23 + d.x * 11 + ph * 2) * 0.7
            return 1 + amp * n
        })
    }

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        func add(_ s: Surface, _ p: V3, rx: Float = 0, ry: Float = 0, rz: Float = 0) {
            let q = simd_quatf(angle: ry, axis: V3(0, 1, 0)) * simd_quatf(angle: rx, axis: V3(1, 0, 0)) * simd_quatf(angle: rz, axis: V3(0, 0, 1))
            m.add(s, Xform(translation: p, rotation: q))
        }
        // Body pear, haunches, chest.
        add(Self.puff(V3(0.17, 0.18, 0.16), white, sub: 9, amp: fuzz, ph: 1), V3(0, 0.092, 0))
        add(Self.puff(V3(0.175, 0.178, 0.165), "fabric.fuzz-white", sub: 6, amp: fuzz, ph: 1), V3(0, 0.092, 0))
        add(Self.puff(V3(0.07, 0.1, 0.12), orange, sub: 8, amp: fuzz, ph: 3), V3(0.07, 0.06, -0.012))
        add(Self.puff(V3(0.07, 0.1, 0.12), orange, sub: 8, amp: fuzz, ph: 4), V3(-0.07, 0.06, -0.012))
        add(Self.puff(V3(0.1, 0.1, 0.07), orange, sub: 8, amp: fuzz, ph: 5), V3(0.0, 0.15, -0.05))   // back saddle
        // Front paws.
        for sx: Float in [-1, 1] {
            add(Self.puff(V3(0.04, 0.07, 0.05), white, sub: 7, amp: fuzz, ph: 6 + sx), V3(sx * 0.03, 0.035, 0.075))
            add(Self.puff(V3(0.05, 0.03, 0.07), white, sub: 7, amp: fuzz, ph: 8 + sx), V3(sx * 0.07, 0.015, 0.045))
        }
        // Head, fuzz halo, forehead and cheek patches, muzzle.
        let yh: Float = 0.215
        add(Self.puff(V3(0.16, 0.135, 0.135), white, sub: 10, amp: fuzz, ph: 2), V3(0, yh, 0.005))
        add(Self.puff(V3(0.166, 0.14, 0.14), "fabric.fuzz-white", sub: 6, amp: fuzz, ph: 2), V3(0, yh, 0.005))
        add(Self.puff(V3(0.08, 0.07, 0.1), orange, sub: 8, amp: fuzz, ph: 7), V3(0.045, yh + 0.036, -0.006), rz: -0.3)
        add(Self.puff(V3(0.08, 0.07, 0.1), orange, sub: 8, amp: fuzz, ph: 9), V3(-0.045, yh + 0.036, -0.006), rz: 0.3)
        add(Self.puff(V3(0.07, 0.05, 0.05), white, sub: 10, amp: fuzz * 0.6, ph: 10), V3(0, yh - 0.03, 0.058))
        // Ears: squashed cones, orange outside, pink inside.
        for sx: Float in [-1, 1] {
            let cone: [V2] = [V2(0.0006, 0.045), V2(0.012, 0.03), V2(0.026, 0.01), V2(0.033, 0.0), V2(0.0006, 0.0)]
            let outer = Prim.lathe(cone, segments: 16, seamTile: 1, material: orange).transformed(Xform(scale: V3(1, 1, 0.42)))
            let inner = Prim.lathe(cone, segments: 16, seamTile: 1, material: "fabric.plush-pink").transformed(Xform(scale: V3(0.68, 0.8, 0.3)))
            add(outer, V3(sx * 0.058, yh + 0.052, -0.004), rx: 0.12, rz: -sx * 0.32)
            add(inner, V3(sx * 0.058 - sx * 0.003, yh + 0.052, 0.006), rx: 0.12, rz: -sx * 0.32)
        }
        // Eyes: glossy dark beads with a small catchlight.
        for sx: Float in [-1, 1] {
            add(Prim.superellipsoid(V3(0.024, 0.028, 0.014), exponent: 2, subdivisions: 8, material: "plastic.gloss:14100C"),
                V3(sx * 0.037, yh + 0.004, 0.066), ry: sx * 0.35)
            add(Prim.superellipsoid(V3(0.006, 0.006, 0.004), exponent: 2, subdivisions: 5, material: "plastic.gloss:FFFFFF"),
                V3(sx * 0.037 + 0.004, yh + 0.012, 0.0725), ry: sx * 0.35)
        }
        // Nose: small rounded triangle, pink.
        add(Prim.superellipsoid(V3(0.017, 0.012, 0.012), exponent: 3, subdivisions: 8, material: "plastic.gloss:E58A9C"), V3(0, yh - 0.012, 0.0755))
        // Tail: curled sweep from the rump around the right side, orange with a white tip.
        var pts: [V3] = []
        for i in 0...10 {
            let t = Float(i) / 10
            let a = Float.pi * (0.9 + 1.0 * t)
            pts.append(V3(0.08 * cos(a) + 0.02, 0.012 + 0.07 * t * t, -0.07 + 0.13 * sin(a) * 0.9 - 0.06 * (1 - t)))
        }
        let path = catmull(pts, per: 2)
        let radii = (0..<path.count).map { i -> Float in
            let t = Float(i) / Float(path.count - 1)
            return 0.021 - 0.005 * t * t + (t > 0.97 ? -0.004 : 0)
        }
        m.add(Prim.tube(path, radii: radii, sides: 10, seamTile: 1, material: orange, capEnd: true), Xform())
        let tip = Array(path.suffix(8)), tipR = Array(radii.suffix(8)).map { $0 + 0.0015 }
        m.add(Prim.tube(tip, radii: tipR, sides: 10, seamTile: 1, material: white, capEnd: true), Xform())
        groundAO(&m)
        return LODModel(m)
    }
}
