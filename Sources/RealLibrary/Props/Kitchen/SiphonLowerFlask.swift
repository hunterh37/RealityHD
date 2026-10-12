import simd
import Foundation

/// Siphon lower flask (Hario TCA-3 class): round borosilicate bowl r 58 mm with a slightly flattened base,
/// a straight 19 mm neck and rolled lip at 0.15 m, 2 mm glass shell, fired-on white 1, 2 and 3 cup lines
/// at their true fill heights, and an optional water fill.
public struct SiphonLowerFlask: RealAsset {
    public static let id = "siphon-lower-flask"
    public static let summary = "Round-bottomed borosilicate siphon lower flask with rolled neck lip, white cup marks and optional water fill."
    public static let tags = ["prop", "kitchen", "glass", "container", "handheld", "water"]
    public static let budget = 9000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 18, distance: 0.95, studio: true)

    /// Bowl outer radius (m).
    public var bowl: Float = 0.058
    /// Neck outer radius (m).
    public var neck: Float = 0.019
    /// Glass wall thickness (m).
    public var wall: Float = 0.002
    /// Water fill as a fraction of the bowl interior height (0 = empty).
    public var fill: Float = 0.55
    public var glass: MaterialKey = "glass.clear"
    public var water: MaterialKey = "food.water:6E8A96"
    public var marking: MaterialKey = "paint.measure-red:F4F4F0"
    public init() {}

    var cy: Float { bowl }
    /// Outer radius of the bowl at height y.
    func outerR(_ y: Float) -> Float { sqrt(max(0, bowl * bowl - (y - cy) * (y - cy))) }

    func outerProfile(_ n: Int) -> [V2] {
        var p: [V2] = [V2(0, 0.0006), V2(0.012, 0.0004)]
        let a0 = -Float.pi / 2 + 0.24, top = asin(min(1, sqrt(1 - (neck + 0.004) * (neck + 0.004) / (bowl * bowl))))
        for i in 0...n { let a = a0 + Float(i) / Float(n) * (top - a0); p.append(V2(cos(a) * bowl, cy + sin(a) * bowl)) }
        let yj = p.last!.y
        p.append(V2(neck + 0.0012, yj + 0.004)); p.append(V2(neck, max(yj + 0.009, 0.112)))
        p.append(V2(neck, 0.145)); p.append(V2(neck + 0.0015, 0.1468)); p.append(V2(0.021, 0.1485)); p.append(V2(0.0205, 0.1499))
        return p
    }

    /// Water level height for a volume in ml (inner sphere, ignoring the flattened base).
    func level(ml: Float) -> Float {
        let R = bowl - wall
        var h: Float = 0
        while h < 2 * R && Float.pi * h * h * (3 * R - h) / 3 * 1e6 < ml { h += 0.0002 }
        return cy - R + h
    }

    func model(segs: Int, detail: Bool) -> Model {
        var m = Model(name: Self.id)
        let outer = outerProfile(detail ? 16 : 9)
        var pts = outer
        pts.append(V2(0.0192, 0.1502)); pts.append(V2(neck - wall * 0.9, 0.1488))
        let innerUp = siphonInset(Array(outer.dropLast(4)), wall)
        var inner = Array(innerUp.reversed())
        inner[inner.count - 1] = V2(0, wall + 0.0006)
        pts.append(contentsOf: inner)
        m.add(Prim.lathe(Shape2D.deduped(pts), segments: segs, seamTile: 0.3, material: glass))
        // Water: inner bowl below the level, capped by a flat surface.
        if fill > 0 {
            let R = bowl - wall - 0.0004
            let ly = cy - R + min(fill, 0.97) * 2 * R
            var wp: [V2] = [V2(0, wall + 0.001)]
            let a1 = asin(max(-1, min(1, (ly - cy) / R)))
            for i in 0...(detail ? 14 : 8) { let a = -Float.pi / 2 + 0.25 + Float(i) / Float(detail ? 14 : 8) * (a1 + Float.pi / 2 - 0.25); wp.append(V2(cos(a) * R, cy + sin(a) * R)) }
            wp.append(V2(0, ly))
            m.add(Prim.lathe(Shape2D.deduped(wp), segments: segs, seamTile: 0.2, material: water))
        }
        // Capacity marks facing +Z with labels.
        var mc = MeasuringCup(); mc.marking = marking
        for (k, ml) in [(1, Float(120)), (2, 240), (3, 360)] {
            let y = level(ml: ml), r = outerR(y) + 0.0002
            m.add(Prim.torus(major: r, minor: 0.0005, segments: detail ? 16 : 8, sides: 4, arc: 0.55, minorY: 0.0003, material: marking),
                  Xform(translation: V3(0, y, 0), rotation: simd_quatf(angle: -.pi / 2 - 0.275, axis: .up)))
            if detail { mc.label(&m, "\(k) CUP", y: y + 0.0045, angle: -.pi / 2 - 0.2, radius: outerR(y + 0.0045)) }
        }
        groundAO(&m, height: 0.02, floor: 0.75)
        return m
    }

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [model(segs: 48, detail: true), model(segs: 24, detail: false)], switchDistances: [3])
    }
}
