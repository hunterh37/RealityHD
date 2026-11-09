import simd
import Foundation

/// Cotton bandana folded into a 62 mm band and tied behind an average adult head, origin at head centre:
/// the band sits high on the brow and drops toward the nape, pleated by the tie, with a folded top edge, hem
/// stitching, printed white border lines and a dashed centre line, a twisted double knot at the back and two
/// tapering tails that hang past the shoulders.
public struct BandanaHeadwrap: RealAsset {
    public static let id = "bandana-headwrap"
    public static let summary = "Worn red cotton bandana tied as a headwrap: pleated folded band, printed borders, back knot with two tails."
    public static let tags = ["prop", "wearable", "worn", "headwear", "fabric"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 150, elevation: 10, distance: 0.8, ground: false, studio: true)

    /// Dyed cotton.
    public var cotton: MaterialKey = "fabric.canvas:B3261E"
    /// Printed border ink.
    public var ink: MaterialKey = "fabric.canvas:F2EEE4"
    /// Folded band depth (m).
    public var bandHeight: Float = 0.062
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let oval: Float = 1.2625, h = bandHeight, t: Float = 0.0021
        func skullX(_ y: Float) -> Float { let q = (y - 0.02) / 0.095; return 0.08 * sqrt(max(0, 1 - q * q)) }
        func ycOf(_ phi: Float) -> Float { 0.056 - 0.030 * (1 - cos(phi)) / 2 }
        let ph1 = rng.float(0...6.28)
        /// Pre-deformation ring point at angle `phi` (0 = front), offset `dy` up from the band centre.
        func ringPt(_ i: Int, _ n: Int, dy: Float, dr: Float) -> V3 {
            let phi = Float(i) / Float(n) * 2 * .pi, yc = ycOf(phi)
            let r = skullX(yc) + 0.0055 + dr
            return V3(r * sin(phi), yc + dy, r * oval * cos(phi))
        }
        /// Fit the band to the skull taper, then pleat it.
        func shape(_ p: V3) -> V3 {
            let phi = atan2(p.x, p.z / oval)
            let f = (skullX(p.y) + 0.0055) / (skullX(ycOf(phi)) + 0.0055)
            var q = V3(p.x * f, p.y, p.z * f)
            let dir = simd_normalize(V3(q.x, 0, q.z / (oval * oval)))
            let pleat = 0.0022 * sin(20 * phi + 1.8 * sin(3 * phi + ph1)) * (0.55 + 0.45 * sin(p.y * 55)) + 0.0006 * sin(p.y * 210 + 7 * phi)
            q += dir * pleat
            return q
        }
        let n = 112
        // Folded band: sampled across its depth so the pleats and wrinkles have vertices to bend.
        var prof: [V2] = []
        for k in 0...8 { prof.append(V2(-h / 2 + h * Float(k) / 8, t)) }
        prof += [V2(h / 2 + 0.0012, t * 0.5), V2(h / 2 + 0.0012, -t * 0.5)]
        for k in 0...8 { prof.append(V2(h / 2 - h * Float(k) / 8, -t)) }
        prof += [V2(-h / 2 - 0.0008, -t * 0.4), V2(-h / 2 - 0.0008, t * 0.4)]
        let ring = (0..<n).map { ringPt($0, n, dy: 0, dr: 0) }
        var band = Prim.sweep(prof, along: ring, up: V3(0, 1, 0), closedPath: true, caps: false, material: cotton)
        band.deform { shape($0) }
        m.add(band)
        // Printed ink: two solid border lines.
        for dy: Float in [h / 2 - 0.0085, -h / 2 + 0.0085] {
            let path = (0...n).map { shape(ringPt($0 % n, n, dy: dy, dr: t + 0.0003)) }
            m.add(Prim.tube(path, radii: path.map { _ in 0.0013 }, sides: 6, seamTile: 0.02, material: ink, capEnd: false))
        }
        // Grime along the lower edge where the band rubs the brow.
        let gp = (0..<96).map { ringPt($0, 96, dy: -h / 2 + 0.0075, dr: 0.0004) }
        var grime = Prim.sweep(Shape2D.roundedRect(0.0135, 2 * t + 0.0006, radius: 0.0012, segments: 2), along: gp, up: V3(0, 1, 0), closedPath: true, caps: false, material: "fabric.canvas:7A1B15")
        grime.deform { shape($0) }
        m.add(grime)
        var detail = Model(name: "stitching")
        func stitched(_ dy: Float, pitch: Float, thread: Float, mat: MaterialKey) {
            let path = (0...n).map { shape(ringPt($0 % n, n, dy: dy, dr: t + 0.0004)) }
            detail.add(stitches(along: path, normal: { p in V3(p.x, 0, p.z / (oval * oval)) }, pitch: pitch, thread: thread, material: mat))
        }
        stitched(0, pitch: 0.0065, thread: 0.0008, mat: ink)                     // printed dashed centre line
        stitched(h / 2 - 0.0042, pitch: 0.0046, thread: 0.0005, mat: "fabric.canvas:E2D6C2")   // hem stitching
        // Knot at the back: lumpy core plus two crossing twists.
        let kc = V3(0, ycOf(.pi) + 0.004, -(skullX(ycOf(.pi)) + 0.0055) * oval - 0.012)
        var core = Prim.superellipsoid(V3(0.038, 0.032, 0.03), exponent: 3, subdivisions: 8, material: cotton)
        core.displace { p, _ in 0.0014 * sin(p.x * 330 + p.y * 120) * sin(p.y * 260 - p.z * 140) }
        m.add(core, Xform(translation: kc))
        for s: Float in [-1, 1] {
            let tw = catmull([V3(-s * 0.019, -0.009, 0.004), V3(-s * 0.006, -0.001, 0.0095), V3(s * 0.007, 0.01, 0.0095), V3(s * 0.02, 0.017, 0.004)].map { $0 + kc }, per: 6)
            m.add(Prim.tube(tw, radii: tw.indices.map { 0.0075 - 0.0012 * sin(Float($0) / Float(tw.count - 1) * .pi) }, sides: 14, seamTile: 0.04, material: cotton, capEnd: true))
        }
        // Two tails: tapering cloth corners with a wave and a half twist.
        for s: Float in [-1, 1] {
            let pathC = catmull([V3(s * 0.006, 0.012, -0.0), V3(s * 0.016, -0.014, -0.012), V3(s * 0.028, -0.048, -0.016), V3(s * 0.033, -0.085, -0.012), V3(s * 0.03, -0.118, -0.004)].map { $0 + V3(0, kc.y, kc.z) }, per: 5)
            let cnt = pathC.count
            let path = pathC.indices.map { i -> V3 in let u = Float(i) / Float(cnt - 1); return pathC[i] + V3(0.004 * sin(u * 9 + s), 0, 0.003 * sin(u * 7)) }
            let scales = path.indices.map { i -> Float in let u = Float(i) / Float(cnt - 1); return max(0.07, 1 - 0.93 * pow(u, 1.5)) }
            m.add(Prim.sweep(Shape2D.superellipse(0.075, 0.0034, exponent: 6, segments: 14), along: path, up: V3(1, 0, 0), scales: scales, material: cotton))
        }
        var full = m
        full.add(detail)
        return LODModel(levels: [full, m], switchDistances: [4])
    }
}
