import simd
import Foundation

/// Siphon upper globe (Hario TCA-3 class) standing on its stem tip: the halogen-siphon-bar lathe profile
/// (7.5 mm stem, flared neck, r 66 mm sphere, rolled rim) as a 1.6 mm glass shell, a rubber gasket 0.10 m
/// above the tip, and the flannel filter on its stainless frame at the bowl bottom with a ball chain and
/// spring hook hanging down the stem to the tip.
public struct SiphonUpperGlobe: RealAsset {
    public static let id = "siphon-upper-globe"
    public static let summary = "Siphon coffee upper glass globe with long stem, rubber gasket, flannel filter and ball chain hook down the stem."
    public static let tags = ["prop", "kitchen", "glass", "handheld"]
    public static let budget = 7000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 15, distance: 0.95, studio: true)

    /// Glass wall thickness (m).
    public var wall: Float = 0.0016
    /// Gasket height above the stem tip (m).
    public var gasketY: Float = 0.10
    public var glass: MaterialKey = "glass.clear"
    public var gasket: MaterialKey = "rubber"
    public var steel: MaterialKey = "metal.stainless"
    /// Flannel cloth, lightly coffee tinted.
    public var cloth: MaterialKey = "fabric.linen:D9CBB4"
    public init() {}

    /// Outer profile, identical to HalogenSiphonBar with top = 0.11.
    static func outerProfile() -> [V2] {
        let top: Float = 0.11
        var gp: [V2] = [V2(0.0075, top - 0.11), V2(0.0078, top - 0.02), V2(0.0105, top + 0.004), V2(0.0115, top + 0.012)]
        let r: Float = 0.066, cy = top + 0.012 + r * 0.92
        for i in 1...10 { let a = -Float.pi / 2 + 0.4 + Float(i) / 10 * (.pi - 0.55); gp.append(V2(cos(a) * r, cy + sin(a) * r)) }
        gp.append(V2(0.026, cy + r * 0.985)); gp.append(V2(0.0265, cy + r + 0.006)); gp.append(V2(0.0285, cy + r + 0.008))
        return gp
    }

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [model(seed: seed, segs: 40, detail: true), model(seed: seed, segs: 20, detail: false)], switchDistances: [3])
    }

    func model(seed: UInt64, segs: Int, detail: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let outer = Self.outerProfile()
        let rimTop = outer.last!.y
        // Rolled rim: outer lip curls over to the inner wall.
        let lip = [V2(0.0293, rimTop - 0.0006), V2(0.0296, rimTop - 0.0018), V2(0.0289, rimTop - 0.003), V2(0.0276, rimTop - 0.0028)]
        var shellPts = outer
        shellPts.append(contentsOf: lip)
        // Inner wall: the outer profile offset inward, walked back down to the stem tip.
        let inner = siphonInset(outer.dropLast(), wall).reversed()
        shellPts.append(contentsOf: inner)
        shellPts.append(V2(0.0075 - wall * 0.5, -0.0000))
        m.add(Prim.lathe(Shape2D.deduped(shellPts), segments: segs, seamTile: 0.3, material: glass))
        // Gasket on the stem.
        m.add(Prim.torus(major: 0.0098, minor: 0.0016, segments: detail ? 20 : 10, sides: 6, material: gasket), Xform(translation: V3(0, gasketY, 0)))
        m.add(Prim.lathe([V2(0.0081, gasketY - 0.004), V2(0.0094, gasketY - 0.003), V2(0.0094, gasketY + 0.003), V2(0.0081, gasketY + 0.004)],
                         segments: detail ? 20 : 10, seamTile: 0.1, material: gasket))
        // Filter at the bowl bottom: stainless frame, flannel pad, centre boss.
        let fy: Float = 0.1295
        var pad = Prim.lathe(siphonPad(radius: 0.0275, height: 0.005), segments: detail ? 36 : 16, seamTile: 0.08, material: cloth)
        let ph = rng.float(0...6)
        pad.displace { p, _ in p.y > 0 ? 0.0003 * sin(p.x * 260 + ph) * cos(p.z * 230) : 0 }
        m.add(pad, Xform(translation: V3(0, fy, 0), rotation: simd_quatf(angle: rng.float(0...6), axis: .up)))
        m.add(Prim.torus(major: 0.0265, minor: 0.0009, segments: detail ? 28 : 12, sides: 5, material: steel), Xform(translation: V3(0, fy + 0.0006, 0)))
        m.add(Prim.cylinder(radius: 0.0035, height: 0.0025, bevel: 0.0006, segments: 12, material: steel), Xform(translation: V3(0, fy + 0.0045, 0)))
        // Ball chain down the stem, spring and hook at the tip.
        let springTop: Float = 0.026
        if detail {
            var y = fy - 0.001
            var k = 0
            while y > springTop {
                let off = V3(0.0006 * sin(Float(k) * 0.7), 0, 0.0006 * cos(Float(k) * 0.5))
                m.add(Prim.cubeSphere(subdivisions: 1, material: steel) { $0 * 0.0011 }, Xform(translation: V3(0, y, 0) + off))
                y -= 0.0026; k += 1
            }
        } else {
            m.add(Prim.tube([V3(0, fy, 0), V3(0, springTop, 0)], radii: [0.0008, 0.0008], sides: 4, seamTile: 0.05, material: steel))
        }
        m.add(Prim.helix(radius: 0.0036, pitch: 0.0011, turns: 14, wire: 0.00045, perTurn: detail ? 12 : 6, sides: 4, material: steel),
              Xform(translation: V3(0, springTop - 0.0165, 0)))
        // Hook: wire from the spring down and curled up at the stem tip.
        var hook: [V3] = [V3(0.0036, springTop - 0.0165, 0), V3(0.002, 0.007, 0), V3(0.0, 0.003, 0)]
        for i in 0...6 { let a = Float.pi + Float(i) / 6 * Float.pi; hook.append(V3(0.0025 * cos(a) + 0.0025, 0.0025 + 0.0022 * sin(a), 0)) }
        m.add(Prim.tube(hook, radii: hook.map { _ in 0.0005 }, sides: 5, seamTile: 0.05, material: steel))
        groundAO(&m, height: 0.02, floor: 0.8)
        return m
    }
}

/// Offset a lathe profile inward (toward the axis side of travel) by `d`, keeping r > 0.
func siphonInset(_ p: [V2], _ d: Float) -> [V2] {
    p.indices.map { i in
        let a = p[max(0, i - 1)], b = p[min(p.count - 1, i + 1)]
        let t = simd_normalize(b - a)
        let n = V2(t.y, -t.x)
        let q = p[i] - n * d
        return V2(max(0.0005, q.x), q.y)
    }
}

/// Lathe profile of a soft round flannel pad, base at y = 0.
func siphonPad(radius r: Float, height h: Float) -> [V2] {
    var p: [V2] = [V2(0, 0), V2(r * 0.8, 0)]
    for i in 0...6 { let a = -Float.pi / 2 + Float(i) / 6 * Float.pi; p.append(V2(r * 0.8 + r * 0.2 * cos(a), h * 0.5 + h * 0.5 * sin(a))) }
    p.append(V2(r * 0.5, h * 1.05)); p.append(V2(0, h * 1.08))
    return Shape2D.deduped(p)
}
