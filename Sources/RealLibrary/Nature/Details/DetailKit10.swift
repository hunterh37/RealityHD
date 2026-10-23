import simd
import Foundation

/// Shared builders for details group 10.
enum DetailKit10 {
    /// Ellipsoid blob at `c` with semi-axes `r`, optionally rotated.
    static func blob(_ c: V3, _ r: V3, rot: simd_quatf = .identity, sub: Int = 2, material: MaterialKey) -> Surface {
        Prim.cubeSphere(subdivisions: sub, material: material) { d in c + rot.act(V3(d.x * r.x, d.y * r.y, d.z * r.z)) }
    }

    /// Leaf card with a pointed tip; yaw about Y, lean from vertical.
    static func leaf(root: V3, yaw: Float, length: Float, width: Float, lean: Float, curl: Float, fold: Float = 0.1,
                     weight: Float = 0.5, phase: Float = 0, rng: inout SeededRNG) -> Surface {
        var b = PlantKit.Blade()
        b.root = root; b.yaw = yaw; b.length = length; b.width = width; b.lean = lean; b.curl = curl
        b.fold = fold; b.belly = 0.5; b.tipWidth = 0.1; b.segments = 3
        b.weight = V2(weight * 0.5, weight); b.phase = phase; b.ao = V2(0.6, 1)
        return PlantKit.blade(b, material: "leaf.rose:5E9030")
    }

    /// Dry litter cards scattered in a disc, used under husks and stumps.
    static func litter(_ m: inout Model, radius: Float, count: Int, rng: inout SeededRNG, tint: String = "litter.dry") {
        for i in 0..<count {
            let p = rng.inDisc(radius: radius)
            let c = PlantKit.cell(rng.int(0...15), cols: 4, rows: 4)
            var b = PlantKit.Blade()
            b.length = rng.float(0.04...0.08); b.width = b.length
            b.yaw = rng.float(0...6.28)
            let d = V3(cos(b.yaw), 0, sin(b.yaw))
            b.root = V3(p.x, 0.002 + Float(i) * 0.0003, p.y) - d * b.length / 2
            b.constantWidth = true; b.tipWidth = 1
            b.lean = rng.float(1.42...1.56); b.curl = rng.float(-0.05...0.08); b.segments = 1; b.fold = rng.float(-0.15...0.03)
            b.u = V2(c.origin.x, c.origin.x + c.size.x); b.v = V2(c.origin.y, c.origin.y + c.size.y)
            b.weight = V2(0, 0); b.ao = V2(0.75, 0.9); b.upNormal = 0.2
            m.add(PlantKit.blade(b, material: MaterialKey(tint)))
        }
    }
}
