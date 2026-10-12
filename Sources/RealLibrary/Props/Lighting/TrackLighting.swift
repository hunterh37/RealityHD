import simd
import Foundation

/// Ceiling track light, authored in place: a 1.2 m white rail along X whose top touches the ceiling plane at
/// y = 2.6, three track adapters with swivel stems, U yokes with pivot screws and cylindrical heads (cooling fins,
/// stepped reflector, lit lens) aimed at different angles. The lowest point hangs at y = 2.4.
public struct TrackLighting: RealAsset {
    public static let id = "track-lighting"
    public static let summary = "Ceiling track light: 1.2 m white rail with three adjustable cylindrical heads on swivel yokes."
    public static let tags = ["prop", "floorplan", "interior", "ceiling", "light", "metal"]
    public static let budget = 5200
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: -22, distance: 1.5, ground: false, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(1.2, 0.2, 0.1)
    /// Ceiling plane height (m).
    public var ceilingY: Float = 2.6
    /// Head tilts in degrees about X (negative aims toward +Z).
    public var tilts: [Float] = [-21, 10, 21]
    /// Rail and head paint.
    public var paint: MaterialKey = "metal.powder-white"
    /// Head, yoke and adapter paint.
    public var headPaint: MaterialKey = "metal.painted:1C1C1E"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        let top = ceilingY
        let L = size.x
        let railH: Float = 0.026, railW: Float = 0.032
        func make(_ lod: Int) -> Model {
            var m = Model(name: Self.id)
            let rb = top - railH
            // Rail: body, dark conductor insert along the underside, end caps, two mounting clips.
            m.add(Prim.roundedBox(V3(L - 0.008, railH, railW), radius: 0.002, bevelSegments: lod == 0 ? 2 : 1, material: paint), Xform(translation: V3(0, rb + railH / 2, 0)))
            m.add(cuboid(V3(L - 0.02, 0.0012, 0.011), material: "plastic.black"), Xform(translation: V3(0, rb - 0.0002, 0)))
            for s in [-1, 1] as [Float] {
                m.add(cuboid(V3(0.008, railH + 0.002, railW + 0.002), material: paint), Xform(translation: V3(s * (L / 2 - 0.004), rb + railH / 2, 0)))
                m.add(cuboid(V3(0.03, 0.002, 0.018), material: "metal.aluminum-brushed"), Xform(translation: V3(s * 0.4, top - 0.001, 0)))
            }
            let xs: [Float] = [-0.4, 0, 0.4]
            for (i, x) in xs.enumerated() {
                let tilt = tilts[i % tilts.count]
                // Track adapter: block in the slot, locking collar, swivel stem.
                m.add(cuboid(V3(0.034, 0.012, 0.022), material: headPaint), Xform(translation: V3(x, rb - 0.005, 0)))
                m.add(Prim.lathe([V2(0, rb - 0.011), V2(0.011, rb - 0.011), V2(0.011, rb - 0.019), V2(0.0075, rb - 0.021), V2(0.0075, rb - 0.068), V2(0, rb - 0.068)], segments: lod == 0 ? 12 : 8, seamTile: 0.03, material: headPaint), Xform(translation: V3(x, 0, 0)))
                if lod == 0 {
                    // Locking lever on the adapter and a set screw on the stem collar.
                    m.add(Prim.roundedBox(V3(0.016, 0.003, 0.005), radius: 0.001, bevelSegments: 1, material: "metal.aluminum-brushed"), Xform(translation: V3(x + 0.014, rb - 0.0115, 0.0)))
                    rivet(&m, at: V3(x, rb - 0.0165, 0.0112), normal: V3(0, 0, 1), radius: 0.0022, segments: 6, material: "metal.chrome")
                }
                // Yoke: bridge under the stem, two arms down to the pivots.
                let by = rb - 0.072, pivotY = by - 0.043
                let hw: Float = 0.0385
                m.add(cuboid(V3(hw * 2 + 0.004, 0.005, 0.016), material: headPaint), Xform(translation: V3(x, by, 0)))
                for s in [-1, 1] as [Float] {
                    m.add(cuboid(V3(0.003, 0.046, 0.014), material: headPaint), Xform(translation: V3(x + s * hw, by - 0.0225, 0)))
                    if lod == 0 { rivet(&m, at: V3(x + s * (hw + 0.0015), pivotY, 0), normal: V3(s, 0, 0), radius: 0.004, segments: 8, material: "metal.chrome") }
                }
                // Head: can centred on the pivot, front toward -Y before the tilt.
                let q = simd_quatf(degrees: tilt, axis: V3(1, 0, 0))
                func H(_ unused: Float) -> Xform { Xform(translation: V3(x, pivotY, 0), rotation: q) }
                let hl: Float = 0.095, off = -hl / 2
                func p(_ r: Float, _ y: Float) -> V2 { V2(r, y + off) }
                let sg = lod == 0 ? 16 : 10
                var shell: [V2] = [p(0.0295, 0), p(0.0345, 0), p(0.0345, 0.05)]
                if lod == 0 {
                    for k in 0..<4 {
                        let y = 0.052 + Float(k) * 0.0085
                        shell += [p(0.0345, y), p(0.0362, y + 0.001), p(0.0362, y + 0.0045), p(0.0345, y + 0.0055)]
                    }
                }
                shell += [p(0.0335, 0.087), p(0.029, hl - 0.002), p(0, hl)]
                m.add(Prim.lathe(shell, segments: sg, seamTile: 0.15, material: headPaint), H(0))
                // Front trim ring and lit lens at the bottom of a stepped reflector.
                m.add(Prim.lathe([p(0.0275, 0.0), p(0.0295, 0.0), p(0.0295, 0.0035), p(0.0275, 0.0035)], segments: sg, seamTile: 0.1, material: "metal.aluminum-brushed"), H(0))
                m.add(Prim.lathe([p(0.0278, 0.0035), p(0.0262, 0.015), p(0.022, 0.03), p(0.014, 0.045), p(0.011, 0.05)], segments: sg, seamTile: 0.1, material: "metal.aluminum-brushed"), H(0))
                m.add(Prim.cylinder(radius: 0.0165, height: 0.0025, bevel: 0.0005, segments: lod == 0 ? 14 : 8, bevelSegments: 1, material: "emissive.warm"), Xform(translation: V3(x, pivotY, 0) + q.act(V3(0, off + 0.0455, 0)), rotation: q))
            }
            return m
        }
        return LODModel(levels: [make(0), make(1)], switchDistances: [6])
    }
}
