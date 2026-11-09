import simd
import Foundation

/// Black leather choker (12 mm strap, 2.6 mm thick) closed with a brass roller buckle at the nape: saddle stitched
/// along both edges, overlapping tapered tail with five punched holes and a keeper loop. A brass O-ring at the front
/// carries a silver crescent moon pendant with a green cabochon on a jump ring.
public struct LeatherChokerPendant: RealAsset {
    public static let id = "leather-choker-pendant"
    public static let summary = "Worn leather choker: stitched strap, brass buckle, punched tail, silver crescent pendant."
    public static let tags = ["prop", "wearable", "worn", "jewelry", "leather", "metal"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 18, elevation: 8, distance: 0.55, ground: false, studio: true)

    /// Strap leather.
    public var leather: MaterialKey = "leather.black"
    /// Buckle and ring metal.
    public var brass: MaterialKey = "metal.brass-aged"
    /// Pendant metal.
    public var silver: MaterialKey = "metal.nickel-worn"
    /// Strap width (m).
    public var width: Float = 0.012
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        let rx: Float = 0.0605, rz: Float = 0.0565, t: Float = 0.0026
        let y0: Float = 0.046
        func yAt(_ th: Float) -> Float { y0 - 0.007 * (1 + cos(th)) / 2 }
        func P(_ th: Float, _ off: Float, y dy: Float = 0) -> V3 { V3(sin(th) * (rx + off), yAt(th) + dy, cos(th) * (rz + off)) }
        func tangent(_ th: Float) -> V3 { simd_normalize(P(th + 0.001, 0) - P(th - 0.001, 0)) }
        func radial(_ th: Float) -> V3 { simd_normalize(V3(sin(th) / rx, 0, cos(th) / rz)) }
        let prof = Shape2D.roundedRect(width, t, radius: 0.0011, segments: 3)
        // Base strap: full loop at the strap centre radius.
        let base = (0..<132).map { P(2 * Float.pi * Float($0) / 132, t / 2) }
        m.add(Prim.sweep(prof, along: base, up: .up, closedPath: true, caps: false, material: leather))
        // Overlapping tail at the nape: tapers to a rounded point, runs forward past the buckle.
        let tailA: Float = .pi - 0.95, tailB: Float = .pi + 0.16
        let tailN = 40
        var tailPath: [V3] = [], scales: [Float] = []
        for k in 0..<tailN {
            let u = Float(k) / Float(tailN - 1)
            let th = tailA + (tailB - tailA) * u
            tailPath.append(P(th, t * 1.5 + 0.0003))
            let tip = smoothstep(0.0, 0.14, u)
            scales.append(0.5 + 0.5 * sqrt(tip))
        }
        m.add(Prim.sweep(prof, along: tailPath, up: .up, scales: scales, caps: true, material: leather))
        // Punched holes on the tail (dark inserts, slightly proud of the surface).
        for k in 0..<5 {
            let th = tailA + 0.2 + Float(k) * 0.115
            let p = P(th, t * 2.5 + 0.0004)
            let n = radial(th)
            let hole = Prim.cylinder(radius: 0.0019, height: 0.0004, bevel: 0.0002, segments: 24, bevelSegments: 1, material: "leather.oxblood-worn")
            m.add(hole, Xform(translation: p - n * 0.0002, rotation: simd_quatf(from: .up, to: n)))
        }
        // Saddle stitches along both edges of the exposed strap.
        let thread: MaterialKey = "fabric.canvas:E8DCC0"
        for side: Float in [-1, 1] {
            let path = (0..<108).map { P(2 * Float.pi * Float($0) / 108, t + 0.0003, y: side * (width / 2 - 0.0015)) }
            var pts = path; pts.append(path[0])
            m.add(stitches(along: pts, normal: { radial(atan2($0.x, $0.z)) }, pitch: 0.0034, thread: 0.00045, material: thread))
        }
        // Keeper loop around both layers.
        let kTh: Float = .pi + 0.02
        let keeper = (0..<9).map { P(kTh - 0.04 + 0.08 * Float($0) / 8, t * 2.5 + 0.0016) }
        m.add(Prim.sweep(Shape2D.roundedRect(width + 0.0014, 0.0016, radius: 0.0007, segments: 2), along: keeper, up: .up, caps: true, material: leather))
        // Roller buckle frame at the nape, lying in the strap plane.
        let bTh: Float = .pi + 0.34
        let tt = tangent(bTh), bp = P(bTh, t * 0.5)
        let b2 = simd_normalize(simd_cross(tt, .up))
        let bq = simd_quatf(simd_float3x3(columns: (tt, .up, b2)))
        let frame = Shape2D.roundedRect(0.0165, width + 0.0035, radius: 0.0022, segments: 5).map { V3($0.x, $0.y, 0) }
        m.add(Prim.sweep(Shape2D.circle(0.00115, ry: 0.00105, segments: 12), along: frame, up: V3(0, 0, 1), closedPath: true, caps: false, material: brass),
              Xform(translation: bp, rotation: bq))
        m.add(Prim.tube([V3(-0.0095, 0, 0.0004), V3(0.0095, 0, 0.0004)], radii: [0.0011, 0.0011], sides: 10, seamTile: 0.01, material: brass),
              Xform(translation: bp + tt * -0.0003, rotation: bq))
        // Tongue pin crossing the strap into a hole.
        let pin = catmull([V3(-0.006, 0, 0), V3(0.0, 0.0006, 0.0014), V3(0.0075, 0, 0.0012)], per: 6)
        m.add(Prim.tube(pin, radii: pin.map { _ in 0.00085 }, sides: 8, seamTile: 0.01, material: brass),
              Xform(translation: bp + b2 * (t * 1.6), rotation: simd_quatf(simd_float3x3(columns: (tt, .up, b2)))))
        // Front: slotted strap carries a brass O-ring; the pendant hangs from it.
        let fp = P(0, t)
        let oRing = Prim.torus(major: 0.0052, minor: 0.00115, segments: 40, sides: 10, material: brass)
        m.add(oRing, Xform(translation: fp + V3(0, -0.0028, 0.0042), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        let slot = Prim.roundedBox(V3(0.0058, 0.0012, 0.0006), radius: 0.0003, bevelSegments: 1, material: "leather.oxblood-worn")
        m.add(slot, Xform(translation: fp + V3(0, 0, 0.0006)))
        // Crescent pendant outline: outer disc minus an offset disc, opening upward.
        let R: Float = 0.0115, r: Float = 0.0096, d: Float = 0.0046
        let ix = (R * R - r * r + d * d) / (2 * d), iy = sqrt(R * R - ix * ix)
        let phi = atan2(iy, ix), psi = atan2(iy, ix - d)
        var cres: [V2] = []
        for k in 0...40 { let a = phi + (2 * Float.pi - 2 * phi) * Float(k) / 40; cres.append(V2(cos(a), sin(a)) * R) }
        for k in 1..<40 { let a = (2 * Float.pi - psi) - (2 * Float.pi - 2 * psi) * Float(k) / 40; cres.append(V2(d + cos(a) * r, sin(a) * r)) }
        let cq = simd_quatf(degrees: 25, axis: V3(0, 0, 1))
        let pc = fp + V3(0, -0.0212, 0.0052)
        m.add(Prim.extrude(Shape2D.deduped(cres), depth: 0.0026, bevel: 0.0007, bevelSegments: 3, material: silver),
              Xform(translation: pc, rotation: cq))
        let bail = Prim.torus(major: 0.0028, minor: 0.0007, segments: 32, sides: 8, material: silver)
        m.add(bail, Xform(translation: pc + V3(0, 0.0123, 0), rotation: simd_quatf(degrees: 90, axis: V3(0, 0, 1))))
        let gem = Prim.cubeSphere(subdivisions: 8, material: "glass.emerald") { dd in V3(dd.x, dd.y, dd.z * 0.55) * 0.0029 }
        m.add(gem, Xform(translation: pc + V3(-0.0075, -0.0035, 0.0004)))
        let bezel = Prim.torus(major: 0.0030, minor: 0.00055, segments: 36, sides: 8, material: silver)
        m.add(bezel, Xform(translation: pc + V3(-0.0075, -0.0035, 0.0010), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        return LODModel(m)
    }
}
