import simd
import Foundation

/// Straight maple rolling pin: turned barrel with shoulder grooves, tapered handles, one replacement handle in darker wood.
public struct RollingPin: RealAsset {
    public static let id = "rolling-pin"
    public static let summary = "Straight maple rolling pin with a lathe-turned barrel and two tapered end handles, flour dust and a dark ring at the handle."
    public static let tags = ["prop", "interior", "kitchen", "wood", "maple"]
    public static let budget = 10000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 22, distance: 0.8, studio: true)

    /// Barrel radius (m).
    public var barrelRadius: Float = 0.03
    /// Barrel wood.
    public var wood: MaterialKey = "wood.maple-natural"
    /// Handle wood.
    public var handleWood: MaterialKey = "wood.beech-stained"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let r = barrelRadius
        let total: Float = 0.45, hl: Float = 0.085
        let bStart = hl, bEnd = total - hl
        // Barrel with eased ends.
        let barrel = turned([(0, bStart), (r * 0.8, bStart), (r * 0.96, bStart + 0.004), (r, bStart + 0.012), (r, bEnd - 0.012),
                             (r * 0.96, bEnd - 0.004), (r * 0.8, bEnd), (0, bEnd)], segments: 48, material: wood, grainVertical: true)
        // Handles: neck, swell, rounded end.
        func handle(_ flip: Bool, _ mat: MaterialKey) -> Surface {
            let hr: Float = 0.0105
            let pts: [(Float, Float)] = [(0, 0), (0.012, 0), (0.0155, 0.004), (0.016, 0.028), (0.0145, 0.055), (hr, 0.075), (0.0125, 0.081), (0.009, 0.085), (0, 0.0858)]
            let ys = pts.map { (a, b) in (a, flip ? total - b : b) }
            return turned(ys, segments: 28, material: mat, grainVertical: true)
        }
        var rolled = Model(name: "pin")
        rolled.add(barrel)
        rolled.add(handle(false, handleWood))
        rolled.add(handle(true, wood))
        // Shoulder grooves and dark wear rings.
        for y in [bStart + 0.0175, bEnd - 0.0175] {
            rolled.add(Prim.torus(major: r * 0.995, minor: 0.0007, segments: 48, sides: 5, material: "wood.walnut-oiled"), Xform(translation: V3(0, y, 0)))
        }
        for y in [bStart - 0.006, bEnd + 0.006] {
            rolled.add(Prim.torus(major: 0.0142, minor: 0.0009, segments: 32, sides: 5, material: "wood.walnut-oiled"), Xform(translation: V3(0, y, 0)))
        }
        // Hand-worn grip sleeves, end-grain tips with a hanging hole, steel axle collars at the barrel ends.
        for (y, flip) in [(0.022, false), (total - 0.022 - 0.03, true)] as [(Float, Bool)] {
            _ = flip
            rolled.add(Prim.cylinder(radius: 0.0162, height: 0.03, bevel: 0.003, segments: 28, material: "wood.walnut-oiled"), Xform(translation: V3(0, y, 0)))
        }
        for (y, up) in [(0.0856, true), (total - 0.0856, false)] as [(Float, Bool)] {
            rolled.add(Prim.cylinder(radius: 0.0088, height: 0.0008, bevel: 0.0002, segments: 20, material: "wood.endgrain"), Xform(translation: V3(0, up ? y - 0.0008 : y, 0)))
            rolled.add(Prim.torus(major: 0.0035, minor: 0.0009, segments: 14, sides: 5, material: "wood.walnut-oiled"), Xform(translation: V3(0, up ? y : y, 0)))
        }
        for y in [bStart + 0.0005, bEnd - 0.0005] {
            rolled.add(Prim.torus(major: 0.013, minor: 0.0016, segments: 24, sides: 6, material: "metal.steel"), Xform(translation: V3(0, y, 0)))
        }
        // Lay along Z resting on the table.
        m.add(rolled, Xform(translation: V3(0, r, -total / 2), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))).jittered(&rng))
        m = DD1CKitchen.ground(m)
        groundAO(&m, height: 0.01, floor: 0.5)
        return LODModel(m)
    }
}
