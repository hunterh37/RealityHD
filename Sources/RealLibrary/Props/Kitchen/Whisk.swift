import simd
import Foundation

/// 30 cm kitchen whisk lying on its side: six nested loops of 1.7 mm stainless wire crossing at the
/// tip, a ferrule where they enter a ribbed stainless handle, and an end cap with a hanging ring.
/// Rests on the balloon and the handle end so the axis tilts about 5 degrees. Length along Z.
public struct Whisk: RealAsset {
    public static let id = "whisk"
    public static let summary = "30 cm whisk: six stainless wire loops, ferrule, ribbed stainless handle with end cap and hanging ring."
    public static let tags = ["prop", "interior", "kitchen", "metal", "tool", "handheld", "cookware"]
    public static let budget = 10000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 35, distance: 0.6, studio: true)

    /// Balloon length from ferrule to tip (m).
    public var balloonLength: Float = 0.17
    /// Balloon radius at the widest point (m).
    public var balloonRadius: Float = 0.030
    /// Number of wire loops (two wires each).
    public var loops = 6
    /// Wire radius (m).
    public var wire: Float = 0.00085
    /// Handle length (m).
    public var handleLength: Float = 0.125
    /// Wire finish.
    public var wireMaterial: MaterialKey = "metal.surgical"
    /// Handle finish.
    public var handleMaterial: MaterialKey = "metal.stainless"
    public init() {}

    func radiusAt(_ w: Float) -> Float { balloonRadius / 0.47 * w * pow(max(0, 1 - w * w), 0.6) }

    func model(steps: Int, sides: Int, segments: Int) -> Model {
        var m = Model(name: Self.id)
        let L = balloonLength, H = handleLength
        for k in 0..<loops {
            let a = Float(k) / Float(loops) * .pi
            let tipX = L - Float(k) * wire * 2.1
            let path = (0...steps).map { i -> V3 in
                let w = -0.985 + 1.97 * Float(i) / Float(steps)
                let x = tipX * (1 - pow(abs(w), 2.4))
                let r = radiusAt(w) * (1 - Float(k) * 0.01)
                return V3(x, r * cos(a), r * sin(a))
            }
            m.add(Prim.tube(path, radii: path.map { _ in wire }, sides: sides, seamTile: 0.02, material: wireMaterial, capEnd: true))
        }
        let prof: [(Float, Float)] = [(0, -0.002), (0.0066, -0.002), (0.0079, 0.004), (0.0079, 0.018), (0.0072, 0.021), (0.0082, 0.027),
                                      (0.0098, 0.055), (0.0100, 0.085), (0.0092, H - 0.012), (0.0088, H - 0.005), (0.0070, H),
                                      (0.0035, H + 0.0015), (0, H + 0.0017)]
        let toX = simd_quatf(angle: .pi / 2, axis: V3(0, 0, 1))
        m.add(turned(prof, segments: segments, material: handleMaterial, seamTile: 0.06, grainVertical: true), Xform(rotation: toX))
        for (y, r): (Float, Float) in [(0.0215, 0.0073), (0.0045, 0.0079), (0.052, 0.0097), (0.058, 0.0099), (0.064, 0.0100)] {
            m.add(Prim.torus(major: r, minor: 0.0005, segments: segments, sides: 5, material: handleMaterial),
                  Xform(translation: V3(-y, 0, 0), rotation: toX))
        }
        m.add(Prim.torus(major: 0.0075, minor: 0.0012, segments: segments, sides: 6, material: wireMaterial),
              Xform(translation: V3(-(H + 0.0017 + 0.0072), 0, 0), rotation: simd_quatf(angle: .pi / 2, axis: V3(1, 0, 0))))
        return m
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let xb = balloonLength * 0.6
        let tilt = asin((balloonRadius - 0.0098) / (xb + handleLength))
        let m = model(steps: 70, sides: 6, segments: 28).transformed(Xform(rotation: simd_quatf(angle: tilt, axis: V3(0, 0, 1))))
        return DD1BKit.finish(m, rng: &rng)
    }
}
