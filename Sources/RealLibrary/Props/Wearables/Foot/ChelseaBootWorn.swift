import simd
import Foundation

/// Left chelsea boot worn on the foot (sole 8.2 cm below the ankle, 15.7 cm tall): creased brown leather with a rounded toe,
/// welted leather sole with stitching, stacked heel with a black rubber lift, elastic gussets piped in leather on both sides,
/// a stitched back pull tab and a bound collar with a tan lining. The outer corner of the replaced heel lift is worn down at an angle.
public struct ChelseaBootWorn: RealAsset {
    public static let id = "chelsea-boot-worn"
    public static let summary = "Worn chelsea boot: creased brown leather, elastic gussets, welt stitching, stacked heel with a worn rubber lift, pull tab."
    public static let tags = ["prop", "wearable", "worn", "footwear", "leather"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 55, elevation: 10, distance: 0.9, ground: false, studio: true)

    /// Boot upper leather.
    public var leather: MaterialKey = "leather.tan:5E3C22"
    /// Sole and heel stack leather.
    public var soleLeather: MaterialKey = "leather.oxblood-worn:3B2518"
    /// Lining and pull tab.
    public var tan: MaterialKey = "leather.tan"
    /// Elastic gusset.
    public var elastic: MaterialKey = "fabric.grosgrain:1E1F21"
    /// Heel lift rubber.
    public var rubber: MaterialKey = "rubber.tire-worn"
    public init() {}

    typealias F = FootKit

    static let prof: [FootKit.Station] = [
        .init(y: -0.056, zb: -0.076, zf: 0.208, sx: 0.97), .init(y: -0.045, zb: -0.074, zf: 0.206, sx: 0.97),
        .init(y: -0.030, zb: -0.072, zf: 0.200, sx: 0.95), .init(y: -0.015, zb: -0.070, zf: 0.178, sx: 0.92),
        .init(y: 0.000, zb: -0.068, zf: 0.134, sx: 0.88), .init(y: 0.015, zb: -0.066, zf: 0.090, sx: 0.81),
        .init(y: 0.035, zb: -0.062, zf: 0.062, sx: 0.78), .init(y: 0.055, zb: -0.060, zf: 0.058, sx: 0.78),
        .init(y: 0.075, zb: -0.058, zf: 0.058, sx: 0.80),
    ]

    /// Point on the outline at height `y` and depth `z` on the `sgn` side (+1 outer / left, -1 inner).
    static func side(_ y: Float, _ z: Float, _ sgn: Float, grow: Float = 0) -> V3 {
        let pts = F.ring(400, F.interp(prof, y), grow: grow)
        for k in 0..<pts.count {
            let a = pts[k], b = pts[(k + 1) % pts.count]
            if a.x * sgn > 0 && b.x * sgn > 0 && (a.z - z) * (b.z - z) <= 0 && a.z != b.z {
                return lerp(a, b, (z - a.z) / (b.z - a.z))
            }
        }
        return V3(sgn * 0.04, y, z)
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let n = 88
        /// Toe spring plus a pitch that puts heel and ball on the same floor.
        func lay(_ x: Surface) -> Surface { var t = x; t.deform { F.spring($0) + V3(0, -0.019 * smoothstep(-0.05, 0.12, $0.z) * (1 - smoothstep(-0.01, 0.02, $0.y)), 0) }; return t }
        let prof = Self.prof
        let ys: [Float] = [-0.058, -0.052, -0.044, -0.036, -0.028, -0.020, -0.012, -0.004, 0.004, 0.012, 0.020, 0.030, 0.040, 0.050, 0.060, 0.068, 0.075]

        // Welted sole.
        let soleProf: [F.Station] = [
            .init(y: -0.0620, zb: -0.080, zf: 0.210, sx: 0.98, grow: 0.002), .init(y: -0.0585, zb: -0.081, zf: 0.213, sx: 1.0, grow: 0.0036),
            .init(y: -0.0565, zb: -0.080, zf: 0.211, sx: 1.0, grow: 0.0034), .init(y: -0.0540, zb: -0.077, zf: 0.207, sx: 0.98, grow: 0.0012),
        ]
        var sole = Prim.loft([-0.0620, -0.0605, -0.0585, -0.0565, -0.0540].map { F.ring(n, F.interp(soleProf, $0)) }, capStart: true, capEnd: true, material: soleLeather)
        sole.displace { p, _ in 0.0004 * Noise.fbm(p * 80, octaves: 3) }
        m.add(lay(sole))

        // Stacked heel: three leather lifts and a black rubber top lift, outer corner worn at an angle.
        let heelProf: [F.Station] = [.init(y: -0.082, zb: -0.078, zf: -0.026, sx: 0.60), .init(y: -0.056, zb: -0.080, zf: -0.022, sx: 0.64)]
        var stack = Prim.loft([-0.0800, -0.0770, -0.0735, -0.0700, -0.0675, -0.0640, -0.0600].map { F.ring(n, F.interp(heelProf, $0), e: 3.4) }, capStart: true, capEnd: true, material: soleLeather)
        stack.displace { p, _ in 0.0003 * Noise.fbm(p * 90, octaves: 2) + 0.0006 * sin(p.y * 900) }
        m.add(stack)
        var tap = Prim.loft([-0.0835, -0.0800, -0.0775].map { F.ring(n, F.interp(heelProf, $0), e: 3.4) }, capStart: true, capEnd: true, material: rubber)
        tap.deform { p in V3(p.x, p.y + 0.0042 * smoothstep(0.004, 0.030, p.x), p.z) }
        m.add(tap)

        // Leather upper with creases across the vamp and a soft grain wobble.
        var upper = Prim.loft(F.rings(n, prof, ys), capStart: false, capEnd: false, material: leather)
        upper.displace { p, _ in
            let vamp = smoothstep(0.075, 0.115, p.z) * (1 - smoothstep(0.175, 0.20, p.z)) * smoothstep(-0.052, -0.026, p.y)
            let crease = -0.0014 * pow(0.5 + 0.5 * sin(p.z * 260 + 4 * Noise.fbm(p * 16, octaves: 2)), 2) * vamp
            let ankle = smoothstep(0.012, 0.03, p.y) * (1 - smoothstep(0.055, 0.075, p.y))
            let fold = -0.0010 * sin(p.y * 220 + 2 * Noise.fbm(p * 12, octaves: 2)) * ankle
            return crease + fold + 0.0004 * Noise.fbm(p * 110, octaves: 3)
        }
        m.add(lay(upper))

        // Vamp and toe cap seams with stitching.
        for (y0, amp, x0) in [(Float(0.012), Float(0.016), Float(0.040)), (Float(-0.030), Float(0.014), Float(0.036))] {
            let pts = (0...24).map { k -> V3 in
                let x = -x0 + 2 * x0 * Float(k) / 24
                return F.front(prof, y: y0 + amp * pow(x / x0, 2), x: x, lift: 0.0003).p
            }
            m.add(lay(Prim.tube(pts, radii: pts.map { _ in 0.0009 }, sides: 5, seamTile: 0.01, material: soleLeather, capEnd: false)))
            m.add(lay(stitches(along: pts.map { $0 + V3(0, 0.0045, 0.0) }, normal: { simd_normalize(V3($0.x * 6, 0.6, 1)) }, pitch: 0.0034, thread: 0.0004, material: "fabric.canvas:C9B27E")))
        }

        // Bound collar and tan lining.
        let collar = F.ring(n, F.interp(prof, 0.075), grow: 0.0006)
        m.add(Prim.sweep(Shape2D.circle(0.0028, segments: 8), along: collar, up: .up, closedPath: true, caps: false, material: leather))
        m.add(Prim.loft([0.075, 0.058, 0.040, 0.024].map { F.ring(n, F.interp(prof, $0), grow: $0 == 0.075 ? -0.0028 : -0.0034) },
                        capStart: false, capEnd: true, material: tan).flipped())

        // Elastic gussets on both sides, piped in leather and stitched.
        let yb: Float = 0.020, yt: Float = 0.0765, zc: Float = -0.002
        for sg: Float in [-1, 1] {
            func gp(_ u: Float, _ v: Float, _ lift: Float) -> V3 {
                let hw = 0.0300 * sqrt(max(0, 1 - pow(1 - v, 2)))
                let z = zc + (u * 2 - 1) * hw
                let y = yb + (yt - yb) * v
                return Self.side(y, z, sg, grow: lift)
            }
            var g = WristKit.grid(14, 16, flip: sg < 0, material: elastic) { u, v in gp(u, v, 0.0011) }
            g.displace { p, _ in 0.0005 * sin(p.y * 520) }
            m.add(g)
            // Leather piping down both edges and round the rounded bottom.
            var bound: [V3] = []
            for k in 0...40 { bound.append(gp(0, 1 - Float(k) / 40, 0.0013)) }
            for k in 1...40 { bound.append(gp(1, Float(k) / 40, 0.0013)) }
            m.add(Prim.tube(bound, radii: bound.map { _ in 0.0014 }, sides: 6, seamTile: 0.01, material: leather, capEnd: false))
            m.add(stitches(along: (0...30).map { gp(0.07, 1 - Float($0) / 30 * 0.92, 0.0022) }, normal: { _ in V3(sg, 0, 0) }, pitch: 0.0035, thread: 0.0004, material: "fabric.canvas:A8895A"))
        }

        // Pull tab sewn at the back, looping above the collar and folding back inside.
        let zbk: (Float) -> Float = { F.interp(prof, $0).zb - 0.0012 }
        let tabPath = catmull([V3(0, 0.040, zbk(0.040)), V3(0, 0.066, zbk(0.066) - 0.0008), V3(0, 0.086, zbk(0.075) - 0.0030),
                               V3(0, 0.096, zbk(0.075) + 0.0030), V3(0, 0.086, zbk(0.075) + 0.0100), V3(0, 0.066, zbk(0.066) + 0.0110)], per: 6)
        m.add(Prim.sweep(Shape2D.roundedRect(0.022, 0.0030, radius: 0.0008, segments: 2), along: tabPath, up: V3(1, 0, 0), caps: true, material: tan))
        m.add(stitches(along: (0...8).map { V3(-0.009 + 0.00225 * Float($0), 0.044, zbk(0.044) - 0.0018) }, normal: { _ in V3(0, 0, -1) }, pitch: 0.0030, thread: 0.0004, material: "fabric.canvas:C9B27E"))

        // Welt stitching.
        let welt = F.ring(n, F.interp(soleProf, -0.0560), grow: 0.0009)
        m.add(lay(stitches(along: welt + [welt[0]], normal: { simd_normalize(V3($0.x, 0, $0.z - 0.067)) }, pitch: 0.0040, thread: 0.00045, material: "fabric.canvas:C9B27E")))
        _ = rng.float()
        return LODModel(m)
    }
}
