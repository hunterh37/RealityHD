import simd
import Foundation

/// Fiber patch cord LC: OM4 aqua duplex LC-LC fiber patch cord, 2 m, zipcord loosely looped, uniboot clip, white ceramic ferrules, translucent dust caps, small flag label. Parts: aqua duplex zipcord jacket, LC duplex connector body at each end, uniboot clip, latch tabs, white ceramic ferrules, translucent dust caps, small flag label.
public struct FiberPatchLc: RealAsset {
    public static let id = "fiber-patch-lc"
    public static let summary = "OM4 aqua duplex LC fiber patch cord, 2 m, with uniboot LC connectors, ceramic ferrules, dust caps and a flag label."
    public static let tags = ["prop", "handheld"]
    public static let budget = 2000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.02, 0.01, 2.0)
    /// Single fiber cable radius in meters (2.0 mm simplex leg of the zipcord).
    public var legRadius: Float = 0.0014
    /// Sideways swing of the loose waves in meters.
    public var swing: Float = 0.0075
    /// OM4 aqua jacket.
    public var jacket: MaterialKey = "plastic.jacket:2CC7D6"
    /// Connector housing, boot and clip.
    public var housing: MaterialKey = "plastic.matte:2CC7D6"
    /// Zirconia ferrule.
    public var ferrule: MaterialKey = "ceramic.vitreous"
    /// Translucent dust cap.
    public var cap: MaterialKey = "plastic.clear"
    /// Flag label stock.
    public var labelStock: MaterialKey = "plastic.matte:F2F2F2"
    public init() {}

    static let tail: Float = 0.07   // tip-to-cord distance of one connector
    static let cy: Float = 0.0045   // connector axis height

    func xAt(_ z: Float, _ ph: Float) -> Float {
        let u = (z + size.z / 2) / size.z
        let env = min(1, sin(.pi * min(max(u, 0), 1)) * 6)
        return swing * sin(2 * .pi * 4.5 * u + ph) * env
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let half = size.z / 2
        let r = legRadius, cy = Self.cy, tail = Self.tail
        let ph = Float(rng.next() % 628) / 100
        func box(_ s: V3, _ c: V3, r rr: Float = 0, mat: MaterialKey) {
            if rr == 0 { m.add(cuboid(s, material: mat), Xform(translation: c)); return }
            m.add(Prim.roundedBox(s, radius: min(rr, min(s.x, min(s.y, s.z)) * 0.4), bevelSegments: 1, material: mat), Xform(translation: c))
        }
        // Zipcord: two legs side by side joined by a thin web, lifting from the floor to connector height at each end.
        let z0 = -half + tail, z1 = half - tail
        var ctrl: [V3] = []
        var z = z0
        while z < z1 { ctrl.append(V3(xAt(z, ph), 0, z)); z += 0.25 }
        ctrl.append(V3(0, 0, z1))
        let pts = catmull(ctrl, per: 2)
        for side: Float in [-1, 1] {
            var path: [V3] = []
            for p in pts {
                let d = min(p.z - z0, z1 - p.z)
                let lift = max(0, 1 - d / 0.06)
                let sep = r * (1 + 0.8 * lift * lift)
                path.append(V3(p.x + side * sep, r + (cy - r) * lift * lift, p.z))
            }
            m.add(Prim.tube(path, radii: Array(repeating: r, count: path.count), sides: 6, seamTile: 0.02, material: jacket))
        }
        for k in 0..<(pts.count - 1) where k % 3 == 0 {
            let a = pts[k], b = pts[k + 1]
            let d = min(a.z - z0, z1 - a.z)
            if d > 0.06 { m.add(cuboid(V3(2 * r, 0.0006, (b.z - a.z) * 1.02), material: jacket), Xform(translation: V3((a.x + b.x) / 2, r, (a.z + b.z) / 2))) }
        }
        // LC duplex connectors. e = +1 at +z, tip points outward.
        for e: Float in [-1, 1] {
            func zs(_ s: Float) -> Float { e * (half - s) }   // z at distance s from the tip
            // Dust caps over white ceramic ferrules.
            for sx: Float in [-1, 1] {
                let x = sx * 0.003125
                m.add(Prim.tube([V3(x, cy, zs(0.0004)), V3(x, cy, zs(0.0070))], radii: [0.00125, 0.00125], sides: 6, seamTile: 0.01, material: ferrule))
                m.add(Prim.tube([V3(x, cy, zs(0)), V3(x, cy, zs(0.0115))], radii: [0.0018, 0.0021], sides: 6, seamTile: 0.01, material: cap))
                // Simplex housing, latch hinge and raised tab.
                box(V3(0.0056, 0.0065, 0.0165), V3(x, cy, zs(0.0072 + 0.00825)), r: 0.0007, mat: housing)
                box(V3(0.0042, 0.0007, 0.0030), V3(x, cy + 0.0036, zs(0.0105)), mat: housing)
                box(V3(0.0044, 0.0006, 0.0100), V3(x, cy + 0.0044, zs(0.0185)), mat: housing)
                box(V3(0.0034, 0.0012, 0.0014), V3(x, cy + 0.0040, zs(0.0235)), mat: housing)
                // Boot leg tapering into the cable.
                m.add(Prim.tube([V3(x * 0.55, cy, zs(0.0230)), V3(x * 0.55, cy, zs(0.0400)), V3(x * 0.55, cy, zs(0.0560)), V3(x * 0.8, cy, zs(tail))],
                                radii: [0.0030, 0.0028, 0.0021, r * 1.25], sides: 6, seamTile: 0.02, material: housing))
            }
            // Uniboot clip: bridge across both bodies and a united boot block.
            box(V3(0.0124, 0.0014, 0.0120), V3(0, cy + 0.0030, zs(0.0140)), mat: housing)
            box(V3(0.0124, 0.0014, 0.0120), V3(0, cy - 0.0030, zs(0.0140)), mat: housing)
            box(V3(0.0128, 0.0068, 0.0110), V3(0, cy, zs(0.0290)), r: 0.0014, mat: housing)
            // Polarity and ID marks on the boot top.
            box(V3(0.0040, 0.0003, 0.0060), V3(0.0, cy + 0.0036, zs(0.0290)), mat: "plastic.matte:E9EEF0")
        }
        // Flag label: wrap band on the zipcord plus a folded flag standing off the side, with printed lines.
        let lz: Float = -half + 0.30
        let lx = xAt(lz, ph)
        box(V3(4 * r + 0.0008, 2 * r + 0.0008, 0.014), V3(lx, r, lz), mat: labelStock)
        box(V3(0.009, 0.0005, 0.018), V3(lx, 2 * r + 0.0010, lz + 0.001), mat: labelStock)
        for k in 0..<3 {
            let w: Float = 0.010 - 0.002 * Float(rng.next() % 3)
            m.add(cuboid(V3(w, 0.0002, 0.0012), material: "plastic.matte:111214"), Xform(translation: V3(lx, 2 * r + 0.00135, lz - 0.005 + Float(k) * 0.0045)))
        }
        // Wear: grey drag scuffs on the jacket.
        for k in 0..<4 {
            let sz = -half + 0.3 + Float(rng.next() % 1000) / 1000 * (size.z - 0.6)
            m.add(cuboid(V3(0.0008, 0.0002, 0.015 + Float(rng.next() % 20) / 1000), material: "plastic.matte:6FA9B0"), Xform(translation: V3(xAt(sz, ph) + (k % 2 == 0 ? -1 : 1) * r, 2 * r - 0.0002, sz)))
        }
        groundAO(&m)
        return LODModel(m)
    }
}
