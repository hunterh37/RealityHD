import simd
import Foundation

/// Gothic Revival oriel corbel, 300 mm wide, 500 mm tall, 400 mm projection: a hex-plan ashlar block skinned from
/// stepped courses (abacus, ogee neck, roll mouldings, cavetto cone and a pendant boss), arrises cut with a 2 mm
/// chamfer, a carved trefoil roundel on the front of the top course, a lime bed joint on the top face with a lead-filled
/// dowel hole, and a soot-stained, mossy underside. Wear: drip stains under each ledge, moss on the ledges, a chipped
/// arris on the abacus.
public struct OrielBayWindowCorbel: RealAsset {
    public static let id = "oriel-bay-window-corbel"
    public static let summary = "Gothic Revival oriel corbel 0.3x0.5x0.4 m: stepped moulded stone cone with trefoil face."
    public static let tags = ["prop", "architecture", "facade", "stone", "decor"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 12, distance: 1.7)

    /// Plan half-width at the top course (m).
    public var halfWidth: Float = 0.15
    /// Projection from the wall at the top course (m).
    public var projection: Float = 0.4
    /// Stone.
    public var stone: MaterialKey = "stone.sandstone"
    /// Soot and drip stain.
    public var soot: MaterialKey = "stone.brownstone-sooted"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let rx = halfWidth, rz = projection
        let top: Float = 0.491

        // Profile: (height, plan scale). Pairs at the same height are the horizontal ledges of the stepped mouldings.
        var prof: [(Float, Float)] = [
            (0.000, 0.10), (0.004, 0.115), (0.012, 0.135), (0.030, 0.15), (0.050, 0.14), (0.064, 0.115), (0.074, 0.105), (0.088, 0.105),
        ]
        for k in 1...10 {                       // cavetto cone, concave flare
            let t = Float(k) / 10
            prof.append((0.088 + 0.19 * t, 0.105 + 0.52 * t * t))
        }
        prof += [(0.286, 0.64), (0.286, 0.70), (0.298, 0.715), (0.310, 0.70), (0.310, 0.66),         // lower roll moulding
                 (0.326, 0.69), (0.340, 0.76), (0.352, 0.80), (0.356, 0.80),                          // ogee up to the top course
                 (0.360, 0.87), (0.366, 0.90), (0.436, 0.90), (0.440, 0.92),                     // fillet, top course, bed
                 (0.445, 0.99), (0.452, 1.0), (top - 0.004, 1.0), (top, 0.995)]                      // abacus with chamfered cap
        // Hex plan with 2 mm arris chamfers: every plan corner becomes two points.
        func plan(_ s: Float) -> [V2] {
            let a = rx * s, b = rz * s, f: Float = 0.78, c: Float = 0.003
            let corners: [(V2, V2, V2)] = [
                (V2(-a, 0), V2(-a, 0), V2(-a, b * 0.30)),
                (V2(-a, b * 0.30), V2(-a, 0), V2(-a * f, b)),
                (V2(-a * f, b), V2(-a, b * 0.30), V2(a * f, b)),
                (V2(a * f, b), V2(-a * f, b), V2(a, b * 0.30)),
                (V2(a, b * 0.30), V2(a * f, b), V2(a, 0)),
            ]
            var pts: [V2] = [V2(-a, c * 2)]
            for (p, prev, next) in corners.dropFirst() {
                let d0 = simd_normalize(prev - p), d1 = simd_normalize(next - p)
                pts.append(p + d0 * c)
                pts.append(p + d1 * c)
            }
            pts.append(V2(a, c * 2))
            return pts.map { V2($0.x, -$0.y) }.reversed()          // outline y runs to -Z; keep winding CCW
        }
        var rings = prof.map { Prim.ring(plan($0.1), y: $0.0) }
        // Repeated-y pairs are exact ledges; nudge one point so quads keep area.
        for i in 1..<prof.count where prof[i].0 == prof[i - 1].0 {
            rings[i] = rings[i].map { V3($0.x, $0.y + 0.0004, $0.z) }
        }
        var body = Prim.loft(rings, capStart: true, capEnd: true, material: stone).flipped()
        body.uvs = body.positions.map { V2($0.x + $0.z, $0.y) }
        body.computeTangents()
        m.add(body)

        // Lime bed joint on top (same hex plan), a sooted film, and a lead-filled dowel hole.
        func slabLoft(_ y0: Float, _ y1: Float, _ sc: Float, _ mat: MaterialKey) -> Surface {
            Prim.loft([Prim.ring(plan(sc), y: y0), Prim.ring(plan(sc), y: y1)], capStart: true, capEnd: true, material: mat).flipped()
        }
        m.add(slabLoft(top, top + 0.003, 0.99, "stone.limestone"))
        m.add(slabLoft(top + 0.003, top + 0.0042, 0.9, soot))
        let hz = rz * 0.6
        m.add(Prim.cylinder(radius: 0.017, height: 0.0016, bevel: 0.0005, segments: 14, bevelSegments: 1, material: "wood.charred"),
              Xform(translation: V3(0, top + 0.0042, hz)))
        m.add(Prim.cylinder(radius: 0.012, height: 0.0018, bevel: 0.0005, segments: 12, bevelSegments: 1, material: "metal.tinned-copper"),
              Xform(translation: V3(0, top + 0.0056, hz)))

        // Trefoil roundel carved on the front of the top course.
        let zf = rz * 0.9 - 0.001, cy: Float = 0.401
        m.add(Prim.torus(major: 0.033, minor: 0.0028, segments: 24, sides: 6, material: stone),
              Xform(translation: V3(0, cy, zf), rotation: FA.q(90, FA.X)))
        for k in 0..<3 {
            let a = Float(k) / 3 * 2 * .pi + .pi / 2
            let cx = cos(a) * 0.0135, cyy = cy - 0.002 + sin(a) * 0.0135
            m.add(Prim.superellipsoid(V3(0.025, 0.025, 0.008), exponent: 2, subdivisions: 5, material: stone),
                  Xform(translation: V3(cx, cyy, zf + 0.003)))
            // Cusp between lobes: small rotated wedge.
            let b = a + .pi / 3
            FJ.slab(&m, V3(0.006, 0.015, 0.004), V3(cos(b) * 0.02, cy - 0.002 + sin(b) * 0.02, zf + 0.001), stone, rot: FA.q(b * 180 / .pi - 90, FA.Z))
        }
        FC.bead(&m, r: 0.004, at: V3(0, cy - 0.002, zf + 0.0075), stone, sub: 4)
        // Recessed dark spandrel behind the lobes gives the carving relief.
        m.add(Prim.cylinder(radius: 0.029, height: 0.002, bevel: 0.0006, segments: 24, bevelSegments: 1, material: soot),
              Xform(translation: V3(0, cy, zf - 0.0004), rotation: FA.q(90, FA.X)))

        // Wear: drip stains under each ledge, moss on ledges and in the cavetto, a chipped abacus arris.
        for i in 0..<6 {
            let x = (i % 2 == 0 ? -1 : 1) * rng.float(0.045...0.1)
            m.add(Prim.superellipsoid(V3(rng.float(0.006...0.012), rng.float(0.025...0.055), 0.003), exponent: 2, subdivisions: 3, material: soot), Xform(translation: V3(x, rng.float(0.378...0.425), rz * 0.9 + 0.0005)))
        }
        for sgn: Float in [-1, 1] {
            m.add(Prim.superellipsoid(V3(0.05, 0.004, 0.05), exponent: 2, subdivisions: 4, material: "stone.granite-moss"), Xform(translation: V3(sgn * rx * 0.7, 0.3125, rz * 0.62), rotation: FA.q(rng.float(-15...15), FA.Y)))
            m.add(Prim.superellipsoid(V3(0.04, 0.004, 0.026), exponent: 2, subdivisions: 4, material: "stone.granite-moss"), Xform(translation: V3(sgn * rx * 0.65, 0.3585, rz * 0.7)))
        }
        groundAO(&m, height: 0.12, floor: 0.8)
        return LODModel(FC.place(m))
    }
}
