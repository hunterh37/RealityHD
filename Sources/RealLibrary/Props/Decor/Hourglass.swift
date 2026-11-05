import simd
import Foundation

/// Desk hourglass, 20 cm: two blown-glass bulbs between turned walnut end plates held by three turned brass posts.
/// Fine golden sand sits as a mound in the lower bulb with a thin stream falling through the neck and a funnel of sand left above.
/// Seeds vary the mound height and post angle.
public struct Hourglass: RealAsset {
    public static let id = "hourglass"
    public static let summary = "Desk hourglass, 20 cm: two blown-glass bulbs between turned walnut end plates held by three brass posts, fine sand mound and thin stream."
    public static let tags = ["prop", "decor", "glass", "wood", "metal", "antique"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 10, studio: true)

    /// Overall height in meters.
    public var height: Float = 0.2
    /// End plate radius (m).
    public var plateRadius: Float = 0.0425
    /// Glass material.
    public var glass: MaterialKey = "glass.clear"
    /// End plate wood.
    public var wood: MaterialKey = "wood.walnut"
    /// Posts, collars.
    public var brass: MaterialKey = "metal.brass"
    /// Sand grains.
    public var sand: MaterialKey = "food.sugar:C48E3E"
    public init() {}

    /// Outer bulb radius over u = distance from the neck as a fraction of the half span (0 neck, 1 end).
    static let bulb: [(Float, Float)] = [
        (0, 0.0036), (0.06, 0.0066), (0.14, 0.0125), (0.25, 0.0200), (0.38, 0.0262), (0.52, 0.0292), (0.65, 0.0292),
        (0.78, 0.0268), (0.88, 0.0225), (0.945, 0.0170), (0.985, 0.0095), (1.0, 0)]

    func make(_ seg: Int, _ detail: Bool, _ rng: inout SeededRNG) -> Model {
        var m = Model(name: Self.id)
        let ym = height / 2, plateT: Float = 0.014, H = ym - plateT, wall: Float = 0.0016
        // Glass: closed hollow shell, outer curve bottom to top, then the inner curve back down.
        func lowerHalf(_ shrink: Float, _ per: Int) -> [V2] {
            let span = H - (shrink > 0 ? 0.0018 : 0)
            let pts = Self.bulb.reversed().map { V2(max(0, $0.1 - shrink), ym - $0.0 * span) }
            return Profile.smooth(pts, per: per).map { V2(max(0, $0.x), $0.y) }
        }
        let lowOut = lowerHalf(0, detail ? 2 : 1), lowIn = lowerHalf(wall, 1)
        let upOut = lowOut.reversed().dropFirst().map { V2($0.x, 2 * ym - $0.y) }
        let upIn = lowIn.reversed().dropFirst().map { V2($0.x, 2 * ym - $0.y) }
        var shell = lowOut + upOut
        shell += Array((lowIn + upIn).reversed())
        m.add(Prim.lathe(shell, segments: seg, seamTile: 0.1, material: glass))
        // Wall radius of the inner glass at height y (lower half), for fitting sand.
        func ri(_ y: Float) -> Float {
            let p = lowIn
            if y <= p[0].y { return p[0].x }
            for i in 1..<p.count where p[i].y >= y {
                let t = (y - p[i - 1].y) / max(1e-6, p[i].y - p[i - 1].y)
                return p[i - 1].x + (p[i].x - p[i - 1].x) * t
            }
            return p[p.count - 1].x
        }
        // Lower sand: wall, then an angle-of-repose cone, peak just under the neck stream.
        let peak = rng.float(0.052...0.064), k: Float = 0.62
        var hitY = peak - 0.02
        for _ in 0..<40 { hitY = peak - ri(hitY) * k }
        var lower: [V2] = []
        let y0 = lowIn[0].y + 0.0004
        var y = y0
        while y < hitY { lower.append(V2(max(0, ri(y) - 0.0003), y)); y += 0.003 }
        let hitR = ri(hitY) - 0.0003
        for i in 0...6 {
            let r = hitR * (1 - Float(i) / 6)
            let wob = 0.0008 * sin(Float(i) * 2.1 + 1) * (r / hitR)
            lower.append(V2(r, peak - r * k + wob))
        }
        if lower.first!.x > 0 { lower.insert(V2(0, y0), at: 0) }
        m.add(Prim.lathe(lower, segments: seg * 7 / 16, seamTile: 0.03, material: sand))
        // Upper residual sand: funnel dish sloping to the neck.
        let yw = ym + 0.028
        var upper: [V2] = []
        var yy = ym + 0.0015
        while yy < yw { upper.append(V2(max(0.0006, ri(2 * ym - yy) - 0.0003), yy)); yy += 0.003 }
        let wallR = ri(2 * ym - yw) - 0.0003
        for i in 1...5 {
            let t = Float(i) / 5
            let r = wallR * (1 - t) + 0.0008 * t
            upper.append(V2(r, yw - 0.026 * pow(t, 0.7) * (1 - 0.12 * t)))
        }
        m.add(Prim.lathe(upper, segments: seg * 7 / 16, seamTile: 0.03, material: sand))
        // Stream: thin tapering thread from the neck to the mound peak.
        m.add(Prim.lathe([V2(0.0003, peak + 0.0005), V2(0.00055, peak + 0.004), V2(0.0006, ym - 0.012), V2(0.0007, ym - 0.002), V2(0.0008, ym + 0.003), V2(0.0004, ym + 0.0042)],
                         segments: 16, seamTile: 0.01, material: sand))
        // End assemblies: walnut plate, brass cup, mirrored for the top.
        let plate = turned([(0, 0), (0.0395, 0), (0.0418, 0.0012), (0.0422, 0.003), (0.0422, 0.006), (0.0408, 0.0075), (0.0414, 0.0086),
                            (0.0398, 0.0100), (0.0402, 0.0115), (0.0388, 0.0128), (0.0380, 0.0140), (0, 0.0140)],
                           segments: seg / 2 + 4, material: wood, seamTile: 0.12)
        let cup = turned([(0, 0.0140), (0.0235, 0.0140), (0.0247, 0.0149), (0.0247, 0.0212), (0.0240, 0.0224), (0.0224, 0.0222),
                          (0.0218, 0.0180), (0.0, 0.0165)], segments: seg / 2, material: brass, seamTile: 0.05)
        let top = Xform(translation: V3(0, 2 * ym, 0), rotation: simd_quatf(degrees: 180, axis: V3(1, 0, 0)))
        for x in [Xform(), top] { m.add(plate, x); m.add(cup, x) }
        // Three turned brass posts, baluster profile mirrored about mid height.
        let half: [(Float, Float)] = [(0.0030, 0), (0.0036, 0.003), (0.0036, 0.006), (0.0027, 0.009), (0.0022, 0.014), (0.0022, 0.040),
                                      (0.0029, 0.045), (0.0022, 0.050), (0.0022, 0.070), (0.0038, 0.079), (0.0023, 0.086)]
        let postProfile = half.map { ($0.0, plateT + $0.1) } + half.reversed().dropFirst().map { ($0.0, 2 * ym - plateT - $0.1) }
        let pa = rng.float(0...0.3)
        for i in 0..<3 {
            let a = pa + Float(i) * 2 * .pi / 3 + .pi / 2
            m.add(turned([(0, plateT - 0.002)] + postProfile + [(0, 2 * ym - plateT + 0.002)], segments: detail ? 14 : 8, material: brass, seamTile: 0.02),
                  Xform(translation: V3(cos(a) * 0.0365, 0, sin(a) * 0.0365)))
        }
        // Story detail: a few spilled grains on the lower plate.
        if detail {
            for _ in 0..<4 {
                let a = rng.float(0...(2 * .pi)), r = rng.float(0.030...0.039), s = rng.float(0.0006...0.0011)
                m.add(Prim.superellipsoid(V3(s, s * 0.7, s), exponent: 2.4, subdivisions: 2, material: sand),
                      Xform(translation: V3(cos(a) * r, plateT + s * 0.3, sin(a) * r), rotation: simd_quatf(degrees: rng.float(0...180), axis: V3(0, 1, 0))))
            }
        }
        groundAO(&m, height: 0.03, floor: 0.7)
        return m
    }

    public func build(seed: UInt64) -> LODModel {
        var r1 = SeededRNG(seed: seed), r2 = SeededRNG(seed: seed)
        return LODModel(levels: [make(64, true, &r1), make(32, false, &r2)], switchDistances: [3])
    }
}
