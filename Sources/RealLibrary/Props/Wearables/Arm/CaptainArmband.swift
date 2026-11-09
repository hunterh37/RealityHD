import simd
import Foundation

/// Football captain's armband on the left upper arm: 62 mm elastic band in faded yellow with gathered ripples, black edge
/// binding, a stitched black felt "C" on the outer front, a hook-and-loop overlap with a loose tail on the inside, frayed
/// edges and grass stains along the lower edge.
public struct CaptainArmband: RealAsset {
    public static let id = "captain-armband"
    public static let summary = "Worn football captain armband: yellow elastic band, stitched black C, black binding, grass stains, frayed edge."
    public static let tags = ["prop", "wearable", "worn", "fabric", "sports"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 8, distance: 0.55, ground: false, studio: true)

    /// Elastic band.
    public var band: MaterialKey = "fabric.nylon:D2A724"
    /// Binding and letter.
    public var black: MaterialKey = "fabric.felt:131416"
    /// Band height on the arm (m).
    public var centreY: Float = 0.038
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        typealias A = ArmKit
        let y = centreY, w: Float = 0.062, t: Float = 0.0032
        let base: Float = 0.0012 + t / 2
        let nf: (V3) -> V3 = { A.nrm($0) }
        let thread: MaterialKey = "fabric.canvas:E9E2CC"

        // Elastic band with gathered ripples.
        let f = A.K.frames(A.ring(y: y, off: base, count: 168), normal: nf, closed: true)
        var bandS = A.K.ribbon(f, width: w, thick: t, radius: 0.0012, segments: 1, closed: true, material: band)
        bandS.deform { p in
            let r = V3(p.x, 0, p.z), l = max(simd_length(r), 1e-6)
            let ang = atan2(p.x, p.z)
            return p + r / l * (0.0005 * sin(ang * 22 + p.y * 40) + 0.0003 * sin(ang * 9))
        }
        m.add(bandS)
        // Black binding along both edges, stitched.
        let bw: Float = 0.0075
        for s: Float in [-1, 1] {
            let yy = y + s * (w / 2 - bw / 2 + 0.0004)
            let fb = A.K.frames(A.ring(y: yy, off: base + t / 2 + 0.0006, count: 168, ry: y), normal: nf, closed: true)
            m.add(A.K.ribbon(fb, width: bw, thick: 0.0014, radius: 0.0006, segments: 1, closed: true, material: black))
            var pts = A.ring(y: yy - s * 0.0022, off: base + t / 2 + 0.0016, count: 168, ry: y)
            pts.append(pts[0])
            m.add(stitches(along: pts, normal: nf, pitch: 0.0045, thread: 0.0004, material: thread))
        }
        // Hook-and-loop overlap on the inside of the arm with a loose tail.
        let hp = -Float.pi / 2
        let over = (0...20).map { A.P(hp - 0.9 + 1.6 * Float($0) / 20, y, base + t * 0.5 + 0.0016) }
        let oe = over.last!, tg = A.tangent(hp + 0.7), nn = A.nrm(oe)
        let tail = [oe, oe + tg * 0.010 + nn * 0.0030, oe + tg * 0.021 + nn * 0.0100, oe + tg * 0.030 + nn * 0.0210]
        let fo = A.K.frames(over + Array(tail.dropFirst()), normal: nf)
        m.add(A.K.ribbon(fo, width: w - 0.014, thick: 0.0022, radius: 0.0008, segments: 1, material: "fabric.nylon:CFA61E"))
        let hk = (0...6).map { k -> V3 in oe + tg * (0.003 + 0.0035 * Float(k)) + nn * (0.0018 + 0.0005 * Float(k)) }
        m.add(A.K.ribbon(A.K.frames(hk, normal: { _ in nn }), width: w - 0.026, thick: 0.0010, radius: 0.0004, segments: 1, material: black))

        // Stitched C: opening to the right as seen from outside, centred between front and outer side.
        let th0: Float = 0.9, rb = A.R(y) + base + t / 2
        let cPts = (0...40).map { k -> V3 in
            let phi = (40 + 280 * Float(k) / 40) * Float.pi / 180
            let s = 0.0155 * cos(phi), yy = y + 0.0205 * sin(phi)
            return A.P(th0 + s / rb, yy, base + t / 2 + 0.0011)
        }
        let cf = A.K.frames(cPts, normal: nf)
        let sw: Float = 0.0078
        m.add(A.K.ribbon(cf, width: sw, thick: 0.0016, radius: 0.0006, segments: 1, material: black))
        for s: Float in [-1, 1] {
            m.add(stitches(along: A.K.offset(cf, w: s * (sw / 2 - 0.0013), n: 0.0008 + 0.0003), normal: nf, pitch: 0.0038, thread: 0.00042, material: thread))
        }

        // Grass and mud stains along the lower edge, one faded sweat ring.
        for _ in 0..<13 {
            let th = rng.float(0...(2 * Float.pi))
            let p = A.P(th, y - rng.float(0.006...0.026), base + t / 2 + 0.0002)
            let q = facing(A.nrm(p)) * simd_quatf(angle: rng.float(-0.5...0.5), axis: .up)
            m.add(Prim.superellipsoid(V3(rng.float(0.014...0.032), 0.0008, rng.float(0.007...0.014)), exponent: 2, subdivisions: 3,
                                      material: rng.chance(0.5) ? "fabric.nylon:3F4A1E" : "fabric.nylon:4A3A20"),
                  Xform(translation: p - A.nrm(p) * 0.0002, rotation: q))
        }
        for _ in 0..<3 {
            let p = A.P(rng.float(0.2...2.6), y + rng.float(-0.012...0.012), base + t / 2 + 0.0002)
            let q = facing(A.nrm(p))
            m.add(Prim.superellipsoid(V3(rng.float(0.020...0.030), 0.0007, rng.float(0.012...0.018)), exponent: 2, subdivisions: 3, material: "fabric.nylon:BF9C2A"),
                  Xform(translation: p - A.nrm(p) * 0.0002, rotation: q))
        }
        // Frayed lower and upper edges.
        for s: Float in [-1, 1] {
            let rim = A.ring(y: y + s * w / 2, off: base, count: 96, ry: y)
            A.fray(&m, rng: &rng, from: rim, dir: { _ in V3(0, s, 0) }, count: 40, length: 0.002...0.006, radius: 0.0005, material: band)
        }
        return LODModel(m)
    }
}
