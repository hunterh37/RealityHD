import simd
import Foundation

/// Fluted steel pauldron: a hammered dome cap with a raised ridge, sixteen radial flutes and a brass rolled brim with
/// engraved dash border, a brass rosette boss, four telescoping lames riveted with brass, and a leather arm strap closed
/// by a nickel roller buckle with a tapered tail.
public struct SteelPauldron: RealAsset {
    public static let id = "steel-pauldron"
    public static let summary = "Worn fluted steel pauldron: dome cap, brass brim and rosette, four riveted lames, leather arm strap."
    public static let tags = ["prop", "wearable", "worn", "metal", "leather"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 10, distance: 0.8, ground: false, studio: true)

    /// Dome plate steel.
    public var plate: MaterialKey = "metal.hammer-polished"
    /// Lame steel.
    public var lameSteel: MaterialKey = "metal.cast-iron-worn"
    /// Brim, rosette and rivets.
    public var brass: MaterialKey = "metal.bronze-weathered"
    /// Arm strap leather.
    public var leather: MaterialKey = "leather.oxblood-worn"
    /// Buckle metal.
    public var buckle: MaterialKey = "metal.nickel-worn"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        typealias K = ChestKit
        let thread: MaterialKey = "fabric.canvas:C9B58A"
        let Rd: Float = 0.087, cen = V3(0, -0.012, 0)
        let tiltQ = simd_quatf(angle: -0.30, axis: V3(0, 0, 1))
        func wrap(_ a: Float) -> Float { atan2(sin(a), cos(a)) }
        func phiMax(_ psi: Float) -> Float { let c = cos(psi); return 1.12 + 0.24 * (c > 0 ? c : 0.85 * c) }
        func domeRadius(_ psi: Float, _ v: Float) -> Float {
            let dp = wrap(psi)
            let ridge = 0.0075 * exp(-pow(dp / 0.30, 2)) * smoothstep(0, 0.25, v)
            let flute = 0.0017 * cos(16 * psi) * smoothstep(0.12, 0.42, v) * (1 - 0.8 * smoothstep(0.88, 1, v)) * (1 - 0.6 * exp(-pow(dp / 0.3, 2)))
            let brim = 0.005 * smoothstep(0.86, 1, v)
            let dent = -0.0024 * exp(-(pow(wrap(psi - 1.4) / 0.35, 2) + pow((v - 0.55) / 0.18, 2))) - 0.0016 * exp(-(pow(wrap(psi + 0.9) / 0.25, 2) + pow((v - 0.7) / 0.15, 2)))
            let hammer = 0.0007 * sin(psi * 7 + v * 9) * sin(v * 13 + 1)
            return Rd + ridge + flute + brim + dent + hammer
        }
        func domePt(_ psi: Float, _ v: Float, _ lift: Float = 0) -> V3 {
            let phi = 0.035 + (phiMax(psi) - 0.035) * v
            let d = V3(sin(phi) * cos(psi), cos(phi), sin(phi) * sin(psi))
            return cen + tiltQ.act(d * (domeRadius(psi, v) + lift))
        }
        m.add(ShoulderKit.shell(cols: 56, rows: 12, thick: 0.0026, centre: cen, material: plate) { u, v in domePt(2 * Float.pi * u, v) })

        // Brass rolled brim, engraved dash border and an etched steel line.
        let ringN = 72
        let edge = (0..<ringN).map { domePt(2 * Float.pi * Float($0) / Float(ringN), 1.0, -0.0003) }
        m.add(Prim.sweep(Shape2D.circle(0.0038, segments: 8), along: edge, up: V3(0, 1, 0), closedPath: true, caps: false, material: brass))
        let border = (0...ringN).map { domePt(2 * Float.pi * Float($0 % ringN) / Float(ringN), 0.9, 0.0008) }
        m.add(Prim.sweep(Shape2D.circle(0.0018, segments: 5), along: Array(border.dropLast()), up: V3(0, 1, 0), closedPath: true, caps: false, material: brass))
        let dashRing = (0...ringN).map { domePt(2 * Float.pi * Float($0 % ringN) / Float(ringN), 0.955, 0.0012) }
        m.add(stitches(along: dashRing, normal: { p in simd_normalize(p - cen) }, pitch: 0.0075, thread: 0.0007, material: brass))
        let line2 = (0..<ringN).map { domePt(2 * Float.pi * Float($0) / Float(ringN), 0.78, 0.0004) }
        m.add(Prim.sweep(Shape2D.circle(0.0011, segments: 5), along: line2, up: V3(0, 1, 0), closedPath: true, caps: false, material: buckle))

        // Rosette boss at the apex.
        let apex = domePt(0, 0.0, 0.0)
        let boss = Prim.lathe([V2(0, -0.001), V2(0.017, -0.001), V2(0.017, 0.0016), V2(0.0145, 0.0038), V2(0.0105, 0.0042), V2(0.0092, 0.0062),
                               V2(0.0058, 0.0092), V2(0.0, 0.0104)], segments: 32, seamTile: 0.05, material: brass)
        m.add(boss, Xform(translation: apex + tiltQ.act(V3(0, 0.0005, 0)), rotation: tiltQ))
        let rosetteRing = (0..<32).map { k -> V3 in let a = 2 * Float.pi * Float(k) / 32; return V3(cos(a) * 0.0235, 0.0016, sin(a) * 0.0235) }
        m.add(Prim.sweep(Shape2D.circle(0.0016, segments: 6), along: rosetteRing, up: V3(0, 1, 0), closedPath: true, caps: false, material: lameSteel),
              Xform(translation: apex, rotation: tiltQ))

        // Four telescoping lames.
        for i in 0..<4 {
            let yTop: Float = 0.040 - 0.036 * Float(i)
            let hh: Float = 0.056
            let rTop: Float = 0.063 - 0.003 * Float(i)
            func lp(_ psi: Float, _ v: Float) -> V3 {
                let e = abs(psi) / 1.95
                let hs = hh * (1 - 0.55 * pow(e, 3))
                let r = rTop + 0.009 * v + 0.003 * exp(-pow(psi / 0.55, 2)) + 0.0012 * cos(14 * psi) * smoothstep(0.1, 0.5, v) + 0.0010 * sin(psi * 5 + Float(i) * 2) * sin(v * 3 + Float(i))
                return V3(r * cos(psi), yTop - v * hs, r * sin(psi))
            }
            let lm: MaterialKey = i == 2 ? "metal.parkerized" : (i == 3 ? "metal.rust-grime" : lameSteel)
            m.add(ShoulderKit.shell(cols: 28, rows: 4, thick: 0.0022, centre: V3(0, yTop - hh / 2, 0), material: lm) { u, v in lp(-1.95 + 3.9 * u, v) })
            let bead = (0...28).map { k in lp(-1.95 + 3.9 * Float(k) / 28, 1.0) }
            m.add(Prim.tube(bead, radii: bead.map { _ in 0.0021 }, sides: 5, seamTile: 0.01, material: "metal.heat-tint-light"))
            for psi: Float in [-1.0, 0, 1.0] {
                let p = lp(psi, 0.2)
                rivet(&m, at: p + V3(cos(psi), 0, sin(psi)) * 0.0004, normal: V3(cos(psi), 0, sin(psi)), radius: 0.0032, segments: 6, material: (i == 2 && psi > 0.5) ? "metal.screw-zinc" : brass)
            }
        }

        // Scratches and scuffs.
        var srng = SeededRNG(seed: seed &+ 91)
        for _ in 0..<16 {
            let psi = srng.float(0...(2 * Float.pi)), v = srng.float(0.25...0.8), dpsi = srng.float(-0.05...0.05), dv = srng.float(0.04...0.1)
            let pts = (0...2).map { k in domePt(psi + dpsi * Float(k), v + dv * Float(k), 0.0007) }
            m.add(stitches(along: pts, normal: { simd_normalize($0 - cen) }, pitch: 0.012, thread: 0.0004, material: buckle))
        }
        // Battle gouges: three deep bright slashes across the dome.
        for (psi, v) in [(Float(2.2), Float(0.5)), (2.3, 0.56), (2.4, 0.6)] {
            let pts = (0...3).map { k in domePt(psi + 0.05 * Float(k), v - 0.06 * Float(k), 0.0008) }
            m.add(stitches(along: pts, normal: { simd_normalize($0 - cen) }, pitch: 0.016, thread: 0.0009, material: buckle))
        }
        // Leather arm strap with roller buckle and tail.
        let sy: Float = -0.146, sr: Float = 0.0495, st: Float = 0.0036
        let nb = 48
        let sp = (0..<nb).map { k -> V3 in let a = 2 * Float.pi * Float(k) / Float(nb); return V3(cos(a) * sr, sy, sin(a) * sr) }
        let radial: (V3) -> V3 = { simd_normalize(V3($0.x, 0, $0.z)) }
        m.add(K.ribbon(K.frames(sp, normal: radial, closed: true), width: 0.026, thick: st, radius: 0.0012, segments: 1, closed: true, material: leather))
        let tp = (0...16).map { k -> V3 in let a = 0.08 + 0.95 * Float(k) / 16; return V3(cos(a) * (sr + st * 1.1), sy, sin(a) * (sr + st * 1.1)) }
        let tf = K.frames(tp, normal: radial)
        m.add(K.ribbon(tf, width: 0.024, thick: st, radius: 0.0012, segments: 1, widthScale: { 1 - 0.55 * smoothstep(0.7, 1, $0) }, material: leather))
        for side: Float in [-1, 1] {
            m.add(K.stitch(along: K.offset(tf, w: side * 0.0095, n: st / 2 + 0.0003), normal: radial, pitch: 0.0045, thread: 0.0005, material: thread))
        }
        for k in 0..<4 {
            let a = 0.46 + 0.1 * Float(k)
            let p = V3(cos(a) * (sr + st * 2.1), sy, sin(a) * (sr + st * 2.1))
            m.add(Prim.cylinder(radius: 0.0022, height: 0.0004, bevel: 0.0002, segments: 12, bevelSegments: 1, material: "leather.black"),
                  Xform(translation: p, rotation: simd_quatf(from: .up, to: radial(p))))
        }
        let bx = sr + st * 2.2
        m.add(ShoulderKit.ring(0.034, 0.030, wire: 0.0019, radius: 0.005, sides: 6, material: buckle),
              Xform(translation: V3(bx + 0.002, sy, -0.002), rotation: K.basis(V3(0, 0, 1), V3(0, 1, 0))))
        m.add(Prim.tube([V3(bx + 0.002, sy - 0.015, 0.0), V3(bx + 0.002, sy + 0.015, 0.0)], radii: [0.0022, 0.0022], sides: 8, seamTile: 0.01, material: buckle))
        m.add(Prim.tube([V3(bx + 0.0015, sy, -0.002), V3(bx + 0.0015, sy, 0.016)], radii: [0.0012, 0.0012], sides: 6, seamTile: 0.01, material: buckle))
        for sz: Float in [-0.0035, 0.0035] {
            rivet(&m, at: V3(sr + st * 0.5 + 0.0005, sy + sz * 2.4, -0.026), normal: V3(1, 0, 0), radius: 0.0028, segments: 6, material: brass)
        }
        return LODModel(m)
    }
}
