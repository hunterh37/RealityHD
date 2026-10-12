import simd
import Foundation

/// Bamboo siphon stirring paddle, 190 mm long, lying flat: thin handle with a raised node ring,
/// widening to a 22 mm flat blade that thins toward a rounded paddle end. Grain runs along the
/// length; the blade tip carries a light coffee stain.
public struct BambooPaddle: RealAsset {
    public static let id = "bamboo-paddle"
    public static let summary = "Bamboo siphon stirring paddle, 190 mm: flat tapered blade with rounded tip, node ring on the handle, coffee stain on the blade."
    public static let tags = ["prop", "kitchen", "wood", "tool", "handheld"]
    public static let budget = 2500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 35, distance: 1.1, studio: true)

    /// Overall length (m).
    public var length: Float = 0.19
    /// Blade width at its widest (m).
    public var bladeWidth: Float = 0.022
    /// Handle width (m).
    public var handleWidth: Float = 0.0105
    /// Handle thickness (m).
    public var thickness: Float = 0.0052
    /// Node ring position from the handle end, as a fraction of length.
    public var nodeAt: Float = 0.33
    /// Coffee stain reach from the blade end (m); 0 = clean.
    public var stainReach: Float = 0.045
    /// Bamboo material (splat layer carries the stain).
    public var wood: MaterialKey = "wood.beech-spoon"
    public init() {}

    func width(_ t: Float) -> Float {
        // t 0 handle end ... 1 blade end
        var w = handleWidth + (bladeWidth - handleWidth) * smoothstep(0.42, 0.72, t)
        let node = exp(-pow((t - nodeAt) / 0.012, 2))
        w += 0.0016 * node
        // rounded ends
        let e0 = min(1, t * length / (handleWidth * 0.5)), e1 = min(1, (1 - t) * length / (bladeWidth * 0.5))
        w *= sqrt(max(0.03, 1 - pow(1 - e0, 2))) * sqrt(max(0.03, 1 - pow(1 - e1, 2)))
        return w
    }
    func thick(_ t: Float) -> Float {
        var h = thickness - (thickness - 0.0021) * smoothstep(0.45, 0.98, t)
        h += 0.0013 * exp(-pow((t - nodeAt) / 0.006, 2)) - 0.0004 * exp(-pow((t - nodeAt - 0.016) / 0.008, 2))
        return h
    }

    func model(stations: Int, sides: Int) -> Model {
        let L = length
        var ts: [Float] = (0...stations).map { Float($0) / Float(stations) }
        ts = ts.map { 0.0015 + 0.997 * $0 }
        let rings: [[V3]] = ts.map { t in
            let w = width(t), h = thick(t)
            return Shape2D.superellipse(w, h, exponent: 3.2, segments: sides).map { p in
                V3(t * L - L / 2, h / 2 + p.y, p.x)
            }
        }
        var s = Prim.loft(rings, capStart: true, capEnd: true, material: wood)
        if let i = s.positions.indices.max(by: { s.positions[$0].y < s.positions[$1].y }), s.normals[i].y < 0 { s = s.flipped() }
        s.uvs = s.positions.map { V2($0.x, $0.z + $0.y) }
        s.computeTangents()
        let reach = stainReach, half = L / 2
        s.paintSplat { p in reach <= 0 ? 0 : smoothstep(half - reach * (1 + 0.25 * sin(p.z * 260)), half - reach * 0.3, p.x) * (0.55 + 0.35 * smoothstep(0.003, 0.0, p.y)) }
        var m = Model(name: Self.id)
        m.add(s)
        let lowY = m.bounds.min.y
        var out = Model(name: Self.id)
        for s in m.surfaces { out.surfaces.append(s.transformed(Xform(translation: V3(0, -lowY, 0)))) }
        groundAO(&out, height: 0.006, floor: 0.6)
        return out
    }

    public func build(seed: UInt64) -> LODModel {
        _ = seed
        return LODModel(levels: [model(stations: 60, sides: 18), model(stations: 28, sides: 10)], switchDistances: [2])
    }
}
