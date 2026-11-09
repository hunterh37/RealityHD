import simd
import Foundation

/// Left canvas high-top sneaker worn on the foot (sole 8.2 cm below the ankle, toes +Z): dingy cream duck canvas upper with a
/// grime tide line, creased toe box, yellowed rubber foxing and toe bumper with dirt in the lip, eight eyelet pairs with black
/// laces, padded tongue, rolled collar, a blank ankle patch with two vent eyelets and saddle stitching. The bow is untied
/// and one lace tail trails down the outside of the shoe to a metal aglet.
public struct HighTopSneakerWorn: RealAsset {
    public static let id = "high-top-sneaker-worn"
    public static let summary = "Worn canvas high-top sneaker: grimy canvas, creased toe box, yellowed rubber foxing, eyelets, untied black laces."
    public static let tags = ["prop", "wearable", "worn", "footwear", "fabric", "rubber"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 40, elevation: 14, distance: 0.9, ground: false, studio: true)

    /// Canvas upper.
    public var canvas: MaterialKey = "fabric.canvas:C9C0A8"
    /// Grime band wicked up from the foxing.
    public var grime: MaterialKey = "fabric.canvas:AFA38A"
    /// Yellowed foxing tape and toe bumper (dirt collects on upward faces).
    public var foxing: MaterialKey = "rubber.tire-worn:DDD0AE"
    /// Outsole rubber.
    public var outsole: MaterialKey = "rubber.tire-worn"
    /// Laces.
    public var lace: MaterialKey = "fabric.canvas:2A2928"
    /// Eyelets.
    public var eyelet: MaterialKey = "metal.nickel-worn"
    /// Collar lining.
    public var lining: MaterialKey = "fabric.canvas:5C5448"
    public init() {}

    typealias F = FootKit

    static let prof: [FootKit.Station] = [
        .init(y: -0.056, zb: -0.076, zf: 0.205, sx: 0.97), .init(y: -0.040, zb: -0.074, zf: 0.193, sx: 0.94),
        .init(y: -0.028, zb: -0.072, zf: 0.172, sx: 0.90), .init(y: -0.014, zb: -0.070, zf: 0.142, sx: 0.86),
        .init(y: 0.000, zb: -0.068, zf: 0.110, sx: 0.83), .init(y: 0.015, zb: -0.066, zf: 0.086, sx: 0.81),
        .init(y: 0.035, zb: -0.064, zf: 0.068, sx: 0.80), .init(y: 0.060, zb: -0.062, zf: 0.058, sx: 0.82),
    ]

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let n = 68
        let prof = Self.prof
        let ys: [Float] = [-0.056, -0.050, -0.044, -0.038, -0.032, -0.026, -0.020, -0.014, -0.008, -0.002, 0.005, 0.013, 0.021, 0.030, 0.039, 0.048, 0.055, 0.060]

        // Foxing tape and outsole.
        let soleProf: [F.Station] = [
            .init(y: -0.082, zb: -0.080, zf: 0.203, sx: 0.96, grow: -0.002), .init(y: -0.080, zb: -0.080, zf: 0.206, sx: 1.0, grow: 0.001),
            .init(y: -0.074, zb: -0.082, zf: 0.208, sx: 1.0, grow: 0.0018), .init(y: -0.064, zb: -0.082, zf: 0.207, sx: 1.0, grow: 0.0020),
            .init(y: -0.056, zb: -0.078, zf: 0.208, sx: 0.99, grow: 0.0010),
        ]
        func soleRings(_ ys: [Float]) -> [[V3]] { ys.map { F.ring(n, F.interp(soleProf, $0)) } }
        m.add(F.sprung(Prim.loft(soleRings([-0.082, -0.080]), capStart: true, capEnd: false, material: outsole)))
        var fox = Prim.loft(soleRings([-0.080, -0.077, -0.074, -0.069, -0.064, -0.060, -0.056]), capStart: false, capEnd: true, material: foxing)
        fox.displace { p, _ in 0.00045 * Noise.fbm(p * 70, octaves: 3) + 0.0003 * sin(p.z * 320 + p.x * 40) * smoothstep(0.12, 0.2, p.z) }
        m.add(F.sprung(fox))

        // Racing stripe round the foxing.
        let stripe = Prim.loft([-0.0705, -0.0685, -0.0665, -0.0645].map { F.ring(n, F.interp(soleProf, $0), grow: 0.0004) }, capStart: false, capEnd: false, material: "rubber.tire-worn:8E2B26")
        m.add(F.sprung(stripe))

        // Canvas upper, creased across the toe box where the foot flexes, with the lace gap pressed in down the middle.
        var upper = Prim.loft(F.rings(n, prof, ys), capStart: false, capEnd: false, material: canvas)
        upper.displace { p, _ in
            let toe = smoothstep(0.08, 0.13, p.z) * (1 - smoothstep(0.17, 0.20, p.z))
            let crease = -0.0011 * (0.5 + 0.5 * sin(p.z * 230 + 3 * Noise.fbm(p * 18, octaves: 2))) * toe * smoothstep(-0.05, -0.01, p.y)
            let gap = -0.0016 * (1 - smoothstep(0.004, 0.011, abs(p.x))) * smoothstep(-0.03, 0.0, p.y) * smoothstep(0.0, 0.03, p.z)
            return crease + gap + 0.00035 * Noise.fbm(p * 150, octaves: 2)
        }
        m.add(F.sprung(upper))
        // Grime tide line wicked up the canvas from the foxing.
        var band = Prim.loft(F.rings(n, prof, [-0.056, -0.053, -0.050, -0.047, -0.044, -0.041, -0.038, -0.035], grow: 0.0004), capStart: false, capEnd: false, material: grime)
        band.displace { p, _ in 0.0002 * Noise.fbm(p * 90, octaves: 2) }
        m.add(F.sprung(band))

        // Toe bumper.
        var bump = Prim.superellipsoid(V3(0.072, 0.030, 0.040), exponent: 3.0, subdivisions: 5, material: foxing)
        let bo = V3(0, -0.050, 0.181)
        bump.deform { F.spring($0 + bo) - bo }
        m.add(bump, Xform(translation: bo))

        // Collar roll and dark lining.
        let collar = F.ring(n, F.interp(prof, 0.060), grow: 0.0014)
        m.add(Prim.sweep(Shape2D.circle(0.0050, segments: 8), along: collar, up: .up, closedPath: true, caps: false, material: canvas))
        let inner = Prim.loft([F.ring(n, F.interp(prof, 0.060), grow: -0.0030), F.ring(n, F.interp(prof, 0.044), grow: -0.0035), F.ring(n, F.interp(prof, 0.026), grow: -0.0038), F.ring(n, F.interp(prof, 0.012), grow: -0.0040)],
                              capStart: false, capEnd: true, material: lining).flipped()
        m.add(inner)

        // Padded tongue rising from the lace gap.
        let tongueAt = F.front(prof, y: 0.030, x: 0).p
        m.add(Prim.superellipsoid(V3(0.040, 0.011, 0.072), exponent: 3.2, subdivisions: 5, material: canvas),
              Xform(translation: tongueAt + V3(0, 0.010, 0.004), rotation: simd_quatf(angle: 0.80, axis: V3(1, 0, 0))))

        // Eyelets and criss-cross laces.
        let rows = 8
        let yE: [Float] = (0..<rows).map { -0.012 + 0.0095 * Float($0) }
        func ePt(_ i: Int, _ side: Float, _ lift: Float) -> (p: V3, n: V3) { F.front(prof, y: yE[i], x: side * 0.0185, lift: lift) }
        for i in 0..<rows {
            for s: Float in [-1, 1] {
                let e = ePt(i, s, 0.0003)
                m.add(Prim.torus(major: 0.0030, minor: 0.00105, segments: 10, sides: 5, material: eyelet), Xform(translation: e.p, rotation: facing(e.n)))
                m.add(Prim.cylinder(radius: 0.0027, height: 0.0004, bevel: 0.0001, segments: 12, bevelSegments: 1, material: "plastic.black"),
                      Xform(translation: e.p - e.n * 0.0004, rotation: facing(e.n)))
            }
        }
        for i in 0..<(rows - 1) {
            for (a, b) in [(Float(-1), Float(1)), (Float(1), Float(-1))] {
                let p0 = ePt(i, a, 0.0014), p1 = ePt(i + 1, b, 0.0014)
                let mid = F.front(prof, y: (yE[i] + yE[i + 1]) / 2, x: 0, lift: 0.0034 + (a < 0 ? 0.0012 : 0)).p
                let path = catmull([p0.p, mid, p1.p], per: 4)
                m.add(Prim.tube(path, radii: path.map { _ in 0.0016 }, sides: 5, seamTile: 0.01, material: lace, capEnd: false))
            }
        }
        // Untied bow knot, two sagging loops and one tail trailing down the outside to an aglet.
        let top = ePt(rows - 1, 1, 0.0014)
        let topL = ePt(rows - 1, -1, 0.0014)
        let knot = F.front(prof, y: 0.052, x: 0, lift: 0.0045).p
        m.add(Prim.superellipsoid(V3(0.010, 0.006, 0.008), exponent: 2, subdivisions: 4, material: lace), Xform(translation: knot))
        for (e, s) in [(top.p, Float(1)), (topL.p, Float(-1))] {
            let path = catmull([e, (e + knot) / 2 + V3(0, 0.002, 0), knot], per: 4)
            m.add(Prim.tube(path, radii: path.map { _ in 0.0016 }, sides: 5, seamTile: 0.01, material: lace, capEnd: false))
            let loop = catmull([knot, knot + V3(s * 0.012, 0.004, 0.006), knot + V3(s * 0.026, -0.004, 0.012), knot + V3(s * 0.020, -0.012, 0.014), knot + V3(s * 0.008, -0.008, 0.008), knot], per: 5)
            m.add(Prim.tube(loop, radii: loop.map { _ in 0.0014 }, sides: 5, seamTile: 0.01, material: lace, capEnd: false))
        }
        let tail: [V3] = [knot, F.front(prof, y: 0.040, x: 0.010, lift: 0.0030).p, F.front(prof, y: 0.022, x: 0.026, lift: 0.0030).p,
                          F.front(prof, y: 0.000, x: 0.037, lift: 0.0035).p, V3(0.047, -0.026, 0.060), V3(0.053, -0.046, 0.066), V3(0.055, -0.060, 0.060)]
        let tp = catmull(tail, per: 5)
        m.add(Prim.tube(tp, radii: tp.map { _ in 0.0015 }, sides: 5, seamTile: 0.01, material: lace, capEnd: false))
        m.add(Prim.cylinder(radius: 0.0019, height: 0.014, bevel: 0.0005, segments: 10, bevelSegments: 1, material: "metal.nickel-worn"),
              Xform(translation: V3(0.0555, -0.0735, 0.058)))

        // Blank ankle patch on the inner side with two vent eyelets.
        let patch = Prim.lathe([V2(0, 0), V2(0.0185, 0), V2(0.0190, 0.0008), V2(0.0178, 0.0016), V2(0.0110, 0.0018), V2(0, 0.0018)], segments: 40, seamTile: 0.03, material: foxing)
        let pa = F.ring(200, F.interp(prof, 0.022))
        let side = pa.filter { $0.x < -0.02 && abs($0.z + 0.004) < 0.01 }.min { $0.x < $1.x } ?? V3(-0.04, 0.022, -0.004)
        m.add(patch, Xform(translation: V3(side.x + 0.0004, 0.022, side.z), rotation: facing(V3(-1, 0, 0))))
        for dy: Float in [-0.008, 0.008] {
            m.add(Prim.torus(major: 0.0030, minor: 0.00105, segments: 10, sides: 5, material: eyelet),
                  Xform(translation: V3(side.x - 0.0020, 0.022 + dy, side.z), rotation: facing(V3(-1, 0, 0))))
        }

        // Saddle stitching along the foxing seam.
        let seam = F.ring(n, F.interp(prof, -0.0535), grow: 0.0008)
        m.add(F.sprung(stitches(along: seam + [seam[0]], normal: { simd_normalize(V3($0.x, 0, $0.z - 0.067)) }, pitch: 0.0058, thread: 0.00045, material: "fabric.canvas:7A6F5A")))
        _ = rng.float()
        return LODModel(m)
    }
}
