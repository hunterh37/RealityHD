import simd
import Foundation

/// Neoprene ankle weight worn on the left ankle (y -4.3 to +3.2 cm): ten quilted sand pockets in two rows that bulge between
/// pinched stitched seams, black grosgrain binding on both rims, a flat loop panel at the front closed by a wide overlapping
/// strap whose end has lifted off its hook pad, and a nylon hang tab with a D-ring at the back. The hook pad is clogged with
/// lint and one long dark hair, and the lower pocket row has darkened with sweat and floor grime.
public struct AnkleWeightStrap: RealAsset {
    public static let id = "ankle-weight-strap"
    public static let summary = "Worn ankle weight: quilted sand pockets, binding, overlapping hook-and-loop strap with a lifted lint-clogged end, D-ring tab."
    public static let tags = ["prop", "wearable", "worn", "fabric", "sports", "fitness"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 14, distance: 0.6, ground: false, studio: true)

    /// Upper pocket row fabric.
    public var upperFabric: MaterialKey = "fabric.nylon:3D4F69"
    /// Lower pocket row fabric, sweat and grime darkened.
    public var lowerFabric: MaterialKey = "fabric.nylon:2A3546"
    /// Rim binding.
    public var binding: MaterialKey = "fabric.grosgrain:17181B"
    /// Loop-side strap.
    public var strap: MaterialKey = "fabric.nylon:50627E"
    /// Hook pad.
    public var hook: MaterialKey = "fabric.felt:BEBCB2"
    /// Quilting thread.
    public var thread: MaterialKey = "fabric.canvas:AEB4BE"
    public init() {}

    static let a: Float = 0.0345, b: Float = 0.0400
    static func N(_ ph: Float) -> V3 { simd_normalize(V3(sin(ph) / a, 0, cos(ph) / b)) }
    static func P(_ ph: Float, _ y: Float, _ off: Float) -> V3 { V3(a * sin(ph), y, b * cos(ph)) + N(ph) * (off + 0.0045 * (y + 0.005) / 0.0375) }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        typealias A = AnkleWeightStrap
        let yLo: Float = -0.038, yHi: Float = 0.032, yMid: Float = (yLo + yHi) / 2
        let ph0: Float = 0.55, ph1: Float = 0.55 + 2 * Float.pi - 0.20
        let panelEnd: Float = 1.50
        let base: Float = 0.0015
        let pinch: Float = 0.0025

        // Inner liner (visible from inside) over the whole open ring.
        m.add(WristKit.grid(72, 6, flip: false, material: "fabric.knit:20232A") { u, v in A.P(ph0 + (ph1 - ph0) * u, yLo + (yHi - yLo) * v, base) })

        // Flat loop panel where the strap closes.
        var panel = WristKit.grid(20, 14, flip: true, material: strap) { u, v in A.P(ph0 + (panelEnd - ph0) * u, yLo + (yHi - yLo) * v, base + 0.0030) }
        panel.displace { p, _ in 0.0003 * Noise.fbm(p * 120, octaves: 2) }
        m.add(panel)

        // Quilted pockets: five columns in two rows, pinched at the seams.
        let cols = 5
        for row in 0..<2 {
            let y0 = row == 0 ? yLo : yMid, y1 = row == 0 ? yMid : yHi
            let mat = row == 0 ? lowerFabric : upperFabric
            var g = WristKit.grid(cols * 14, 8, flip: true, material: mat) { u, v in
                let fu = (u * Float(cols)).truncatingRemainder(dividingBy: 1)
                let f = (u >= 1) ? 1 : fu
                let bulge = pow(max(0, sin(Float.pi * f)), 0.55) * pow(max(0, sin(Float.pi * v)), 0.55)
                return A.P(panelEnd + (ph1 - panelEnd) * u, y0 + (y1 - y0) * v, base + pinch + 0.0058 * bulge * (0.85 + 0.30 * Noise.perlin(V3(u * 40, Float(row) * 3, 0))))
            }
            g.displace { p, _ in 0.00035 * Noise.fbm(p * 150, octaves: 3) + 0.0009 * Noise.fbm(p * 45, octaves: 2) }
            m.add(g)
        }
        // Quilting thread in the seams.
        let thr: (V3) -> V3 = { simd_normalize(V3($0.x / (A.a * A.a), 0, $0.z / (A.b * A.b))) }
        for c in 0...cols {
            let ph = panelEnd + (ph1 - panelEnd) * Float(c) / Float(cols)
            let pts = (0...20).map { A.P(ph, yLo + (yHi - yLo) * Float($0) / 20, base + pinch + 0.0007) }
            m.add(stitches(along: pts, normal: thr, pitch: 0.0032, thread: 0.00045, material: thread))
        }
        let midPath = (0...120).map { A.P(panelEnd + (ph1 - panelEnd) * Float($0) / 120, yMid, base + pinch + 0.0007) }
        m.add(stitches(along: midPath, normal: thr, pitch: 0.0032, thread: 0.00045, material: thread))

        // Binding on both rims, over the open ring.
        for y in [yLo, yHi] {
            let path = (0...90).map { A.P(ph0 + (ph1 - ph0) * Float($0) / 90, y, base + 0.0030) }
            m.add(Prim.sweep(Shape2D.circle(0.0022, segments: 6), along: path, up: .up, closedPath: false, caps: true, material: binding))
        }

        // Hook pad on the panel with lint and a hair.
        let hookA: Float = 0.80, hookB: Float = 1.42
        var pad = WristKit.grid(14, 10, flip: true, material: hook) { u, v in A.P(hookA + (hookB - hookA) * u, yLo + 0.010 + (yHi - yLo - 0.020) * v, base + 0.0046) }
        pad.displace { p, _ in 0.0004 * Noise.fbm(p * 400, octaves: 2) }
        m.add(pad)
        for _ in 0..<10 {
            let ph = hookA + 0.25 + rng.float(0...0.34)
            let y = yLo + 0.014 + rng.float(0...(yHi - yLo - 0.028))
            let p = A.P(ph, y, base + 0.0056)
            let t = V3(cos(ph), 0, -sin(ph) * 0.8)
            let d = simd_normalize(t) * rng.float(0.003...0.006) + V3(0, rng.float(-0.003...0.003), 0)
            let path = catmull([p, p + d * 0.5 + A.N(ph) * 0.0012, p + d], per: 3)
            m.add(Prim.tube(path, radii: path.map { _ in 0.00028 }, sides: 4, seamTile: 0.01, material: "fabric.fuzz-white", capEnd: false))
        }
        let hair = (0...12).map { k -> V3 in
            let t = Float(k) / 12
            return A.P(hookA + 0.10 + 0.40 * t, yMid + 0.010 * sin(t * 5), base + 0.0054 + 0.0012 * sin(t * 9))
        }
        m.add(Prim.tube(hair, radii: hair.map { _ in 0.00018 }, sides: 4, seamTile: 0.01, material: "plastic.black", capEnd: false))

        // Closing strap overlapping the pad, lifted and curling at the free end.
        let tA: Float = 0.02, tB: Float = 1.06
        func tOff(_ ph: Float) -> Float { base + 0.0085 + 0.0032 * (1 - smoothstep(0.25, 0.5, ph)) + 0.0003 }
        var tail = WristKit.grid(30, 12, flip: true, material: strap) { u, v in
            let ph = tA + (tB - tA) * u
            let lift = 0.0130 * pow(smoothstep(0.62, 1.0, u), 1.6) + 0.0032 * (1 - smoothstep(0.25, 0.5, ph))
            let curl = 0.0025 * sin(v * Float.pi) * smoothstep(0.80, 1.0, u)
            let y = yLo + 0.004 + (yHi - yLo - 0.008) * v
            return A.P(ph, y, base + 0.0085 + lift + curl)
        }
        m.add(tail)
        // Tail underside so the lifted end has thickness.
        if false { m.add(WristKit.grid(30, 12, flip: false, material: strap) { u, v in
            let ph = tA + (tB - tA) * u
            let lift = 0.0130 * pow(smoothstep(0.62, 1.0, u), 1.6) + 0.0032 * (1 - smoothstep(0.25, 0.5, ph))
            let curl = 0.0025 * sin(v * Float.pi) * smoothstep(0.80, 1.0, u)
            let y = yLo + 0.004 + (yHi - yLo - 0.008) * v
            return A.P(ph, y, base + 0.0085 + lift + curl - 0.0016)
        }) }
        // Stitched bar tack where the strap leaves the body, and edge stitching.
        for ph in [tA + 0.06, tA + 0.12] {
            let pts = (0...12).map { A.P(ph, yLo + 0.006 + (yHi - yLo - 0.012) * Float($0) / 12, tOff(ph)) }
            m.add(stitches(along: pts, normal: thr, pitch: 0.0030, thread: 0.0004, material: thread))
        }
        for y in [yLo + 0.0055, yHi - 0.0055] {
            let pts = (0...40).map { A.P(tA + 0.06 + (tB - tA - 0.40) * Float($0) / 40, y, tOff(tA + 0.06 + (tB - tA - 0.40) * Float($0) / 40)) }
            m.add(stitches(along: pts, normal: thr, pitch: 0.0032, thread: 0.0004, material: thread))
        }

        // Hang tab with a D-ring at the back.
        let pb: Float = Float.pi + 0.05
        let tabPath = catmull([A.P(pb, yHi - 0.012, base + 0.0090), A.P(pb, yHi + 0.002, base + 0.0110), A.P(pb, yHi + 0.008, base + 0.0140), A.P(pb, yHi + 0.004, base + 0.0170)], per: 5)
        m.add(Prim.sweep(Shape2D.roundedRect(0.014, 0.0022, radius: 0.0006, segments: 2), along: tabPath, up: V3(1, 0, 0), caps: true, material: strap))
        let dpos = A.P(pb, yHi + 0.007, base + 0.0165)
        m.add(Prim.torus(major: 0.0055, minor: 0.0012, segments: 28, sides: 8, material: "metal.nickel-worn"),
              Xform(translation: dpos, rotation: simd_quatf(angle: Float.pi / 2, axis: V3(1, 0, 0))))
        m.add(stitches(along: (0...8).map { V3(-0.005 + 0.00125 * Float($0), yHi - 0.006, A.P(pb, 0, base + 0.0100).z) }, normal: { _ in V3(0, 0, -1) }, pitch: 0.0030, thread: 0.0004, material: thread))
        return LODModel(m)
    }
}
