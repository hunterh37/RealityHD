import simd
import Foundation

/// Water pitcher: everyday tableware, glass. Parts: thick glass base, pulled pouring spout lip, applied loop handle with thumb rest, water fill, limescale ring at the waterline, ice cubes.
public struct WaterPitcher: RealAsset {
    public static let id = "water-pitcher"
    public static let summary = "Glass water pitcher: thick base, spout lip, applied handle, half full of water with ice and a limescale ring."
    public static let tags = ["prop", "interior", "glass", "container", "kitchen"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 40, elevation: 18, studio: true)

    /// Overall size in meters (x width, y height, z depth including spout and handle).
    public var size = V3(0.12, 0.25, 0.17)
    /// Glass material.
    public var glass: MaterialKey = "glass.clear"
    /// Water material.
    public var water: MaterialKey = "glass.water-clear"
    /// Limescale material.
    public var scale: MaterialKey = "glass.frosted"
    /// Water level as a fraction of the inner height.
    public var fill: Float = 0.62
    public init() {}

    static let outer: [V2] = [V2(0, 0.0075), V2(0.022, 0.0066), V2(0.043, 0.0030), V2(0.0535, 0.0), V2(0.0570, 0.0035), V2(0.0585, 0.012),
                              V2(0.0600, 0.060), V2(0.0603, 0.110), V2(0.0592, 0.170), V2(0.0575, 0.2300), V2(0.0570, 0.2494)]

    func make(_ seg: Int, _ detail: Bool) -> Model {
        var rng = SeededRNG(seed: 7)
        var m = Model(name: Self.id)
        let off = V3(0, 0, 0.011)
        let H: Float = 0.2494, wall: Float = 0.0034, floorY: Float = 0.016
        var body = Prim.lathe(DD1FTableware.shell(outer: Self.outer, wall: wall, floorY: floorY, smooth: 2), segments: seg, seamTile: 0.2, material: glass)
        // Pulled spout: the rim bulges out toward +Z and dips.
        body.deform { p in
            let r = (p.x * p.x + p.z * p.z).squareRoot()
            guard p.y > 0.19, r > 0.01 else { return p }
            let a = atan2(p.z, p.x) - .pi / 2
            let da = atan2(sin(a), cos(a))
            let s = exp(-(da * da) / 0.18) * smoothstep(0.19, H, p.y)
            let k = 1 + 0.16 * s * (p.z > 0 ? 1 : 0)
            return V3(p.x * (1 - 0.22 * s), p.y - 0.014 * s, p.z * k + 0.008 * s)
        }
        m.add(body, Xform(translation: off))
        func ri(_ y: Float) -> Float { DD1FTableware.radius(Self.outer, at: y) - wall - 0.0004 }
        let wy = floorY + (H - 0.02 - floorY) * fill
        m.add(Prim.lathe([V2(0, floorY + 0.0003), V2(ri(floorY) - 0.004, floorY + 0.0003), V2(ri(floorY + 0.004), floorY + 0.004), V2(ri(wy), wy - 0.002), V2(ri(wy) - 0.0015, wy), V2(0, wy)],
                         segments: seg, seamTile: 0.2, material: water), Xform(translation: off))
        // Limescale ring on the inner wall at the old waterline, plus a scuffed foot ring.
        m.add(DD1FTableware.band([V2(ri(wy + 0.012) - 0.0001, wy + 0.012), V2(ri(wy + 0.0085) - 0.0004, wy + 0.0085), V2(ri(wy + 0.005) - 0.0001, wy + 0.005)], segments: seg, material: scale), Xform(translation: off))
        m.add(Prim.lathe([V2(0.0537, 0.0001), V2(0.0572, 0.0035), V2(0.0587, 0.0085)], segments: seg, seamTile: 0.2, material: scale), Xform(translation: off))
        for i in 0..<3 {
            let sz = rng.float(0.024...0.028)
            let a = Float(i) * 2.1 + 0.4
            let q = simd_quatf(degrees: rng.float(0...60), axis: .up) * simd_quatf(degrees: rng.float(-14...14), axis: V3(1, 0, 0))
            m.add(Prim.superellipsoid(V3(sz, sz * 0.92, sz), exponent: 6, subdivisions: detail ? 3 : 2, material: "glass.ice"),
                  Xform(translation: V3(cos(a) * 0.022, wy - sz * 0.35 + Float(i % 2) * 0.004, sin(a) * 0.022) + off, rotation: q))
        }
        // Handle on -Z: loop with a thumb rest at the top.
        let ctrl = [V2(0.0550, 0.2160), V2(0.0715, 0.2290), V2(0.0875, 0.2140), V2(0.0935, 0.1700), V2(0.0905, 0.1050), V2(0.0790, 0.0720), V2(0.0572, 0.0640)]
        m.add(DD1FTableware.loop(ctrl, dir: V3(0, 0, -1), section: V2(0.0105, 0.0075), detail: detail, flare: 0.5, material: glass), Xform(translation: off))
        m.add(Prim.superellipsoid(V3(0.012, 0.007, 0.022), exponent: 2.4, subdivisions: detail ? 4 : 2, material: glass), Xform(translation: V3(0, 0.2325, -0.072) + off))
        groundAO(&m, height: 0.04, floor: 0.7)
        return m
    }

    public func build(seed: UInt64) -> LODModel {
        _ = seed
        return LODModel(levels: [make(64, true), make(32, false)], switchDistances: [3.5])
    }
}
