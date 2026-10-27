import simd
import Foundation

/// Teacup and saucer, 14 cm: bone china cup with looped handle on a saucer with a centre well, gilt rim lines. Story: tea ring inside the cup and a drip in the saucer.
public struct TeacupAndSaucer: RealAsset {
    public static let id = "teacup-and-saucer"
    public static let summary = "Teacup and saucer, 14 cm: translucent bone china, looped handle, saucer well, thin gilt rim, tea stain ring."
    public static let tags = ["prop", "interior", "tableware", "ceramic"]
    public static let budget = 13000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 30, distance: 1.15, studio: true)

    /// Saucer diameter (m).
    public var saucerDiameter: Float = 0.14
    /// Cup rim diameter (m).
    public var cupDiameter: Float = 0.082
    /// Cup height (m).
    public var cupHeight: Float = 0.0615
    /// Saucer well floor height (m).
    public var wellY: Float = 0.0085
    /// Bone china, bisque foot, gilt, tea.
    public var china: MaterialKey = "ceramic.vitreous:F6F2E7"
    public var foot: MaterialKey = "ceramic.bisque:E8E0CF"
    public var gilt: MaterialKey = "metal.gold"
    public var tea: MaterialKey = "ceramic.vitreous:9C6A35"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Saucer.
        let sh: Float = 0.017, sr = saucerDiameter / 2
        let sp = DD1ETableware.plate(diameter: saucerDiameter, height: sh, wellRadius: 0.031, wellY: wellY, rimWidth: 0.027, thickness: 0.003, edgeRadius: 0.0017)
        m.add(DD1ETableware.lathe(sp, china, segments: 56))
        m.add(DD1ETableware.lathe(DD1ETableware.footRing(0.031), foot))
        m.add(DD1ETableware.lathe(DD1ETableware.annulus(sr - 0.0068, sr - 0.0052, y: sh - 0.0003, thick: 0.0005), gilt))
        // Drip puddle in the well beside the cup.
        let da: Float = -1.1, dr: Float = 0.0565
        m.add(Prim.superellipsoid(V3(0.016, 0.0007, 0.0085), exponent: 2.3, subdivisions: 8, material: tea),
              Xform(translation: V3(dr * cos(da), sh - 0.0010, -dr * sin(da)), rotation: simd_quatf(degrees: da * 180 / .pi, axis: V3(0, 1, 0))))
        // Cup, seated in the well on its foot ring.
        let cup = DD1ETableware.Bowl(D: cupDiameter, H: cupHeight, footR: 0.0245, footH: 0.0035, wall: 0.0026)
        var cm = Model(name: "cup")
        cm.add(DD1ETableware.lathe(cup.profile(steps: 10), china, segments: 48))
        cm.add(DD1ETableware.lathe(DD1ETableware.footRing(0.0245), foot, segments: 48))
        let t0 = cup.theta(innerY: cupHeight - 0.018)
        cm.add(DD1ETableware.lathe(cup.innerBand(t0, t0 + 0.07, thick: 0.0005), tea, segments: 48))
        cm.add(DD1ETableware.lathe(cup.innerBand(0.0, 0.3, thick: 0.0004), "ceramic.vitreous:B88A55", segments: 48))
        cm.add(DD1ETableware.lathe(DD1ETableware.annulus(0.0005, cup.r0, y: 0.0035 + 0.0026, thick: 0.0004), "ceramic.vitreous:B88A55", segments: 48))
        // Gilt line on the lip.
        let R = cupDiameter / 2
        cm.add(DD1ETableware.lathe([V2(R - 0.0020, cupHeight - 0.0006), V2(R - 0.0006, cupHeight - 0.0006), V2(R - 0.0006, cupHeight + 0.0002), V2(R - 0.0020, cupHeight + 0.0002), V2(R - 0.0020, cupHeight - 0.0006)], gilt, segments: 48))
        // Looped handle on +X: oval section swept along a squared ear, thinner at the middle.
        let y1: Float = cupHeight - 0.008, y2: Float = 0.016
        let x1 = cup.outerRadius(at: y1) - 0.0018, x2 = cup.outerRadius(at: y2) - 0.0018
        let ym = (y1 + y2) / 2, bh = (y1 - y2) / 2
        var ctrl: [V3] = []
        for k in 0...10 {
            let t = Float(k) / 10, th = Float.pi / 2 - t * .pi
            let c = cos(th), sgn: Float = c < 0 ? -1 : 1
            ctrl.append(V3(x1 + (x2 - x1) * t + 0.026 * sgn * pow(abs(c), 0.7), ym + bh * 1.02 * sin(th), 0))
        }
        let path = catmull(ctrl, per: 4)
        let scales: [Float] = path.indices.map { i in let u = abs(Float(i) / Float(path.count - 1) - 0.5) * 2; return 0.82 + 0.28 * pow(u, 2) }
        cm.add(Prim.sweep(Shape2D.circle(0.0046, ry: 0.0031, segments: 12), along: path, up: V3(0, 0, 1), scales: scales, caps: true, material: china))
        m.add(cm, Xform(translation: V3(0, wellY, 0)))
        _ = rng.float()
        DD1ETableware.finish(&m, aoHeight: 0.014)
        return LODModel(m)
    }
}
