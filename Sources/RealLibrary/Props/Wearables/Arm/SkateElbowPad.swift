import simd
import Foundation

/// Skate elbow pad on an average adult left elbow: black neoprene sleeve (18 cm, bound rims), a 10.5 cm domed hard plastic
/// cap over the point of the elbow (back, -Z) with three ribs and four nickel rivets, and two elastic straps with a hook-and-loop
/// overlap and a loose tail at the front. The cap is ground down with pale kerb scuffs and the sleeve rims fray.
public struct SkateElbowPad: RealAsset {
    public static let id = "skate-elbow-pad"
    public static let summary = "Worn skate elbow pad: neoprene sleeve, scuffed domed cap with ribs and rivets, elastic velcro straps."
    public static let tags = ["prop", "wearable", "worn", "plastic", "fabric"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 215, elevation: 10, distance: 0.6, ground: false, studio: true)

    /// Neoprene sleeve.
    public var neoprene: MaterialKey = "fabric.nylon:1A1C20"
    /// Hard cap.
    public var cap: MaterialKey = "plastic.gloss:2A2D33"
    /// Elastic strap webbing.
    public var webbing: MaterialKey = "fabric.nylon:17191C"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        typealias A = ArmKit
        let y0: Float = -0.088, y1: Float = 0.092
        let ro: Float = 0.0048, ri: Float = 0.0008

        // Sleeve: closed lathe loop with rolled rims.
        var loop: [V2] = []
        for k in 0...6 { let y = y0 + (y1 - y0) * Float(k) / 6; loop.append(V2(A.R(y) + ro, y)) }
        loop.append(V2(A.R(y1) + ro - 0.0010, y1 + 0.0012))
        loop.append(V2(A.R(y1) + ri + 0.0010, y1 + 0.0012))
        for k in 0...6 { let y = y1 - (y1 - y0) * Float(k) / 6; loop.append(V2(A.R(y) + ri, y)) }
        loop.append(V2(A.R(y0) + ri + 0.0010, y0 - 0.0012))
        loop.append(V2(A.R(y0) + ro - 0.0010, y0 - 0.0012))
        loop.append(loop[0])
        var sleeve = Prim.lathe(loop, segments: 44, seamTile: 0.03, material: neoprene)
        sleeve.displace { p, _ in 0.0004 * Noise.fbm(p * 90, octaves: 2) }
        m.add(sleeve)
        let bind: MaterialKey = "fabric.nylon:2E3238"
        for y in [y1 + 0.0006, y0 - 0.0006] {
            m.add(Prim.torus(major: A.R(y) + 0.0030, minor: 0.0014, segments: 40, sides: 6, material: bind), Xform(translation: V3(0, y, 0)))
        }
        // Sleeve seam on the inside of the arm.
        let seam = (0...30).map { A.P(-Float.pi / 2, y0 + 0.006 + (y1 - y0 - 0.012) * Float($0) / 30, ro + 0.0003) }
        m.add(stitches(along: seam, normal: { A.nrm($0) }, pitch: 0.0045, thread: 0.0005, material: "fabric.canvas:5A5E66"))

        // Hard cap on the elbow point.
        func e(_ a: Float, _ b: Float) -> Float {
            let wa = pow(max(0, 1 - pow(abs(a), 3.5)), 0.55), wb = pow(max(0, 1 - pow(abs(b), 3.5)), 0.55)
            return 0.0035 + 0.0215 * wa * wb
        }
        func capPt(_ a: Float, _ b: Float, _ off: Float = 0) -> V3 { A.P(Float.pi + a * 1.05, b * 0.052, ro + e(a, b) + off) }
        func capN(_ a: Float, _ b: Float) -> V3 {
            let h: Float = 0.01
            let du = capPt(a + h, b) - capPt(a - h, b), dv = capPt(a, b + h) - capPt(a, b - h)
            var n = simd_normalize(simd_cross(du, dv))
            if simd_dot(n, A.nrm(capPt(a, b))) < 0 { n = -n }
            return n
        }
        var capS = ShoulderKit.shell(cols: 26, rows: 20, thick: 0.003, centre: V3(0, 0, 0), material: cap) { u, v in capPt(2 * u - 1, 2 * v - 1) }
        capS.displace { p, _ in 0.00025 * Noise.fbm(p * 140, octaves: 2) }
        m.add(capS)
        for b: Float in [-0.46, 0, 0.46] {
            let pts = (0...22).map { k -> V3 in capPt(-0.72 + 1.44 * Float(k) / 22, b, 0.0004) }
            m.add(Prim.tube(pts, radii: pts.map { _ in 0.0016 }, sides: 8, seamTile: 0.01, material: cap, capEnd: true))
        }
        for (a, b) in [(Float(-0.74), Float(-0.74)), (0.74, -0.74), (-0.74, 0.74), (0.74, 0.74)] {
            let p = capPt(a, b)
            rivet(&m, at: p, normal: capN(a, b), radius: 0.0042, segments: 14, material: "metal.nickel-worn")
        }
        // Kerb scuffs: pale ground-down patches on the dome.
        for _ in 0..<9 {
            let a = rng.float(-0.65...0.65), b = rng.float(-0.65...0.65)
            let p = capPt(a, b, 0.0001), n = capN(a, b)
            let q = facing(n) * simd_quatf(angle: rng.float(0...Float.pi), axis: .up)
            m.add(Prim.superellipsoid(V3(rng.float(0.012...0.030), 0.0010, rng.float(0.004...0.008)), exponent: 2, subdivisions: 3, material: "plastic.matte:8A8D93"),
                  Xform(translation: p - n * 0.0003, rotation: q))
        }

        // Chalky grime patches on the sleeve.
        for _ in 0..<8 {
            let p = A.P(rng.float(0.3...2.8), rng.float(-0.075...0.08), ro + 0.0002)
            let q = facing(A.nrm(p)) * simd_quatf(angle: rng.float(0...Float.pi), axis: .up)
            m.add(Prim.superellipsoid(V3(rng.float(0.010...0.022), 0.0007, rng.float(0.008...0.016)), exponent: 2, subdivisions: 2, material: "fabric.nylon:44474D"),
                  Xform(translation: p - A.nrm(p) * 0.0002, rotation: q))
        }
        // Elastic straps with hook-and-loop closure at the front.
        let sw: Float = 0.026, st: Float = 0.0032
        let strapOff = ro + st / 2 + 0.0004
        for y in [Float(0.071), -0.065] {
            let f = A.K.frames(A.ring(y: y, off: strapOff, count: 72), normal: { A.nrm($0) }, closed: true)
            m.add(A.K.ribbon(f, width: sw, thick: st, radius: 0.0012, segments: 1, closed: true, material: webbing))
            for side: Float in [-1, 1] {
                var pts = A.K.offset(f, w: side * (sw / 2 - 0.0034), n: st / 2 + 0.0003)
                pts.append(pts[0])
                m.add(stitches(along: pts, normal: { A.nrm($0) }, pitch: 0.0050, thread: 0.00045, material: "fabric.canvas:6C7078"))
            }
            // Loop pad overlap and loose tail.
            let over = (0...16).map { A.P(-0.45 + 1.45 * Float($0) / 16, y, strapOff + st * 0.5 + 0.0012) }
            let end = over.last!, tg = A.tangent(1.0), nn = A.nrm(end)
            let tail = [end, end + tg * 0.010 + nn * 0.0025, end + tg * 0.022 + nn * 0.0085, end + tg * 0.032 + nn * 0.0185]
            let fo = A.K.frames(over + Array(tail.dropFirst()), normal: { A.nrm($0) })
            m.add(A.K.ribbon(fo, width: sw - 0.002, thick: 0.0024, radius: 0.0009, segments: 1, material: "fabric.nylon:50545B"))
            let hook = (0...5).map { k -> V3 in end + tg * (0.004 + 0.003 * Float(k)) + nn * (0.0020 + 0.0004 * Float(k)) }
            m.add(A.K.ribbon(A.K.frames(hook, normal: { _ in nn }), width: sw - 0.006, thick: 0.0012, radius: 0.0005, segments: 1, material: "fabric.nylon:222428"))
        }

        // Frayed sleeve rims.
        for y in [y1, y0] {
            let rim = (0..<64).map { A.P(2 * Float.pi * Float($0) / 64, y, ro - 0.0005) }
            A.fray(&m, rng: &rng, from: rim, dir: { _ in V3(0, y > 0 ? 1 : -1, 0) }, count: 22, length: 0.003...0.008, radius: 0.00045, material: neoprene)
        }
        return LODModel(m)
    }
}
