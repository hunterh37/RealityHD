import simd
import Foundation

/// Ribbed knit beanie worn on an average adult head (57 cm), origin at head centre: double-layer folded cuff
/// 68 mm deep with 36 raised ribs, slouched stockinette crown, yarn pom-pom with loose strands, stitched
/// leather brand label on the cuff front and a snagged yarn loop on the left side. Pulled down over the ears.
public struct KnitBeanieWorn: RealAsset {
    public static let id = "knit-beanie-worn"
    public static let summary = "Worn ribbed knit beanie: folded rib cuff, slouched crown, yarn pom-pom, stitched leather label."
    public static let tags = ["prop", "wearable", "worn", "headwear", "fabric", "leather"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 12, distance: 0.75, ground: false, studio: true)

    /// Knit yarn.
    public var yarn: MaterialKey = "fabric.knit:34404F"
    /// Pom-pom yarn.
    public var pomYarn: MaterialKey = "fabric.plush-white:E6DFD0"
    /// Label leather.
    public var label: MaterialKey = "leather.tan"
    /// Folded cuff depth (m).
    public var cuffHeight: Float = 0.068
    /// Pom-pom radius (m).
    public var pomRadius: Float = 0.036
    public init() {}

    /// Closed lathe loop (outer shell plus inner wall) from an outer profile running base to apex.
    static func shellLoop(_ outer: [V2], wall: Float) -> [V2] {
        var inner: [V2] = []
        for i in outer.indices {
            let a = outer[max(0, i - 1)], b = outer[min(outer.count - 1, i + 1)]
            let d = b - a, l = max(simd_length(d), 1e-6)
            let n = V2(d.y, -d.x) / l
            inner.append(V2(max(0, outer[i].x - n.x * wall), outer[i].y - n.y * wall))
        }
        return outer + inner.reversed() + [outer[0]]
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let oval: Float = 1.2625
        func skullX(_ y: Float) -> Float { let t = (y - 0.02) / 0.095; return 0.08 * sqrt(max(0, 1 - t * t)) }
        func bodyR(_ y: Float) -> Float { skullX(y) + 0.0055 }
        let topY: Float = 0.136
        /// Lathe space (round, base on y = 0) to head space: oval, pulled down over the ears, slouched back.
        func place(_ p: V3) -> V3 {
            var q = V3(p.x, p.y, p.z * oval)
            let w = 1 - smoothstep(0, 0.14, p.y)
            q.y += (-0.018 + 0.066 * smoothstep(0.05, 1.0, q.z / 0.1)) * w
            let s = smoothstep(0.06, topY, p.y)
            q.z -= 0.03 * s * s
            return q
        }
        // Body: stockinette crown, 4 mm double wall.
        var outer: [V2] = []
        for k in 0...6 { let y = Float(k) / 6 * 0.07; outer.append(V2(bodyR(y), y)) }
        let r0 = outer.last!.x
        for k in 1...10 { let a = Float(k) / 10 * .pi / 2; outer.append(V2(r0 * cos(a), 0.07 + (topY - 0.07) * sin(a))) }
        var body = Prim.lathe(Self.shellLoop(outer, wall: 0.004), segments: 64, seamTile: 0.035, material: yarn)
        body.deform { p in
            let a = atan2(-p.z, p.x), r = simd_length(V2(p.x, p.z))
            let f = smoothstep(0.03, 0.1, p.y) * (1 - smoothstep(0.125, topY, p.y) * 0.6)
            let nr = r * (1 + 0.016 * f * sin(a * 6 + p.y * 30 + 0.7) + 0.008 * f * sin(a * 11 - p.y * 55))
            return place(V3(nr * cos(a), p.y, -nr * sin(a)))
        }
        m.add(body)
        // Cuff: folded rib band, rounded fold at the base and a rolled top edge, 36 raised ribs.
        let t: Float = 0.0075, h = cuffHeight
        var cp: [V2] = []
        let c0 = V2(bodyR(0) + t / 2, t / 2)
        for k in 0...5 { let a = Float.pi + Float(k) / 5 * .pi; cp.append(c0 + V2(cos(a), sin(a)) * (t / 2)) }
        for k in 1...6 { let y = t / 2 + (h - t) * Float(k) / 6; cp.append(V2(bodyR(y) + t, y)) }
        let c1 = V2(bodyR(h - t / 2) + t / 2, h - t / 2)
        for k in 1...5 { let a = Float(k) / 5 * .pi; cp.append(c1 + V2(cos(a), sin(a)) * (t / 2)) }
        for k in 1...3 { let y = h - t / 2 - (h - t) * Float(k) / 3; cp.append(V2(bodyR(y), y)) }
        cp.append(cp[0])
        var cuff = Prim.lathe(cp, segments: 144, seamTile: 0.035, material: yarn)
        cuff.deform { p in
            let r = simd_length(V2(p.x, p.z)), a = atan2(-p.z, p.x)
            let outerness = smoothstep(bodyR(p.y) + 0.003, bodyR(p.y) + 0.0066, r)
            let nr = r + 0.0011 * cos(a * 36) * outerness
            return place(V3(nr * cos(a), p.y, -nr * sin(a)))
        }
        m.add(cuff)
        // Pom-pom: lumpy yarn ball with loose strands, sitting on the slouched apex.
        let pomC = place(V3(0, topY + 0.014, 0))
        let pom = Prim.cubeSphere(subdivisions: 12, material: pomYarn) { d in
            let n = sin(d.x * 37 + d.y * 11) * sin(d.y * 41 - d.z * 13) * sin(d.z * 29 + d.x * 17)
            return d * (pomRadius * (1 + 0.07 * n))
        }
        m.add(pom, Xform(translation: pomC))
        for _ in 0..<170 {
            let zc = rng.float(-1...1), a = rng.float(0...(2 * .pi)), rr = sqrt(1 - zc * zc)
            let d = V3(rr * cos(a), zc, rr * sin(a))
            let side = simd_normalize(d.anyPerpendicular) * rng.float(0.002...0.005)
            let p0 = pomC + d * pomRadius * 0.92, p1 = pomC + d * pomRadius * 1.1 + side
            m.add(Prim.tube([p0, p1], radii: [0.0014, 0.0006], sides: 3, seamTile: 0.01, material: pomYarn, capEnd: false))
        }
        // Tie ring where the pom is gathered onto the crown.
        let tie = Prim.torus(major: 0.011, minor: 0.0035, segments: 24, sides: 8, material: yarn)
        m.add(tie, Xform(translation: place(V3(0, topY - 0.001, 0))))
        // Stitched leather label, front left of the cuff.
        let ang: Float = 24 * .pi / 180, ly = h * 0.5
        let lr = bodyR(ly) + t + 0.0013
        let lp = place(V3(lr * sin(ang), ly, lr * cos(ang)))
        let n = simd_normalize(V3(sin(ang), 0, cos(ang) / oval))
        let yaw = atan2(n.x, n.z)
        let q = simd_quatf(angle: yaw, axis: .up)
        m.add(Prim.roundedBox(V3(0.034, 0.016, 0.003), radius: 0.0009, bevelSegments: 2, material: label), Xform(translation: lp, rotation: q))
        m.add(Prim.extrude(Shape2D.polygon(sides: 3, radius: 0.0042), depth: 0.0006, bevel: 0.0001, bevelSegments: 1, material: "metal.brass-aged"),
              Xform(translation: lp + n * 0.0017, rotation: q))
        let tt = V3(cos(yaw), 0, -sin(yaw))
        var loop: [V3] = []
        for (dx, dy) in [(-0.0155, -0.0065), (0.0155, -0.0065), (0.0155, 0.0065), (-0.0155, 0.0065), (-0.0155, -0.0065)] as [(Float, Float)] {
            loop.append(lp + tt * dx + V3(0, dy, 0) + n * 0.0016)
        }
        m.add(stitches(along: loop, normal: { _ in n }, pitch: 0.0028, thread: 0.0005, material: "fabric.canvas:E8DCC0"))
        // Story detail: a snagged yarn loop pulled out of the left side.
        let sp = place(V3(bodyR(0.085) * 0.97, 0.085, 0.01))
        let sn = simd_normalize(V3(1, 0.1, 0))
        let snag = catmull([sp, sp + sn * 0.006 + V3(0, 0.006, 0), sp + sn * 0.012 + V3(0, 0.002, 0.008), sp + sn * 0.007 + V3(0, -0.006, 0.012), sp + sn * 0.0005 + V3(0, -0.004, 0.006)], per: 4)
        m.add(Prim.tube(snag, radii: snag.map { _ in 0.0009 }, sides: 5, seamTile: 0.01, material: yarn, capEnd: false))
        return LODModel(m)
    }
}
