import simd
import Foundation

/// Boston cast-iron acorn gas lamp post (~4 m): moulded bell base, 16-flute tapering column, collar
/// with a ladder rest bar, gas fitter, acorn glass globe with a lit mantle, ventilated copper cap and finial.
public struct BostonAcornLamp: RealAsset {
    public static let id = "boston-acorn-lamp"
    public static let summary = "Boston cast-iron acorn gas lamp post: fluted tapering column on a moulded base, ladder rest bar, acorn glass globe with copper cap and finial."
    public static let tags = ["prop", "light", "metal", "street", "glass", "park"]
    public static let budget = 6000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 8, distance: 1.0)

    /// Overall height to the finial tip in meters.
    public var height: Float = 4.0
    /// Base radius in meters.
    public var baseRadius: Float = 0.2
    /// Ladder bar length in meters.
    public var ladderBar: Float = 0.62
    /// Cast iron material key.
    public var iron: MaterialKey = "metal.wrought-iron"
    /// Weathered iron at the foot.
    public var ironFoot: MaterialKey = "metal.cast-iron-street"
    /// Cap material key.
    public var copper: MaterialKey = "metal.copper-patina"
    /// Globe glass material key.
    public var glass: MaterialKey = "glass.lamp"
    /// Mantle glow material key.
    public var mantle: MaterialKey = "emissive.warm"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let k = height / 4.0
        let br = baseRadius
        // Bell base: plinth, torus moulding, ogee bell, neck ring.
        let base: [(Float, Float)] = [(0, 0), (br, 0), (br, 0.05), (br * 0.94, 0.07), (br * 0.94, 0.1), (br * 0.98, 0.12), (br * 0.9, 0.15),
                                      (br * 0.78, 0.22), (br * 0.62, 0.34), (br * 0.52, 0.46), (br * 0.5, 0.5), (br * 0.6, 0.52), (br * 0.6, 0.56),
                                      (br * 0.46, 0.6), (0.0, 0.6)]
        m.add(turned(base.map { ($0.0, $0.1 * k) }, segments: 40, material: ironFoot))
        // Fluted shaft.
        let y0: Float = 0.58 * k, y1: Float = 2.95 * k
        let r0: Float = 0.078, r1: Float = 0.056
        var shaft: [(Float, Float)] = []
        for i in 0...10 { let t = Float(i) / 10; shaft.append((r0 + (r1 - r0) * t, y0 + (y1 - y0) * t)) }
        var col = turned(shaft, segments: 64, material: iron, grainVertical: true)
        col.deform { p in
            let a = atan2(p.z, p.x)
            let r = simd_length(V2(p.x, p.z))
            if r < 1e-4 { return p }
            let f = 1 - 0.07 * max(0, cos(a * 16))
            return V3(p.x / r * r * f, p.y, p.z / r * r * f)
        }
        m.add(col)
        // Collar under the ladder bar.
        let collar: [(Float, Float)] = [(0, 0), (0.072, 0), (0.08, 0.02), (0.08, 0.05), (0.066, 0.07), (0.07, 0.1), (0.0, 0.1)]
        m.add(turned(collar.map { ($0.0, $0.1 + y1 - 0.02) }, segments: 28, material: iron))
        // Ladder rest bar with acorn ends.
        let barY = y1 + 0.06
        m.add(Prim.tube([V3(-ladderBar / 2, barY, 0), V3(ladderBar / 2, barY, 0)], radii: [0.016, 0.016], sides: 10, seamTile: 0.1, material: iron))
        for s in [Float(-1), 1] {
            var knob = turned([(0, 0), (0.02, 0.0), (0.028, 0.02), (0.024, 0.04), (0.01, 0.055), (0, 0.06)], segments: 12, material: iron)
            knob.deform { V3($0.y, $0.x, $0.z) }
            m.add(knob, Xform(translation: V3(s * ladderBar / 2, barY, 0), scale: V3(s, 1, 1)))
        }
        // Upper neck and gas fitter.
        let fy = y1 + 0.08
        let fitter: [(Float, Float)] = [(0, 0), (0.06, 0), (0.05, 0.06), (0.045, 0.14), (0.07, 0.17), (0.11, 0.2), (0.12, 0.23), (0.0, 0.23)]
        m.add(turned(fitter.map { ($0.0, $0.1 + fy) }, segments: 32, material: iron))
        // Acorn globe.
        let gy = fy + 0.23
        let gH: Float = 0.55 * k
        let acorn: [(Float, Float)] = [(0.0, 0), (0.09, 0), (0.11, 0.015), (0.145, 0.07), (0.172, 0.15), (0.18, 0.22), (0.172, 0.29),
                                       (0.15, 0.36), (0.122, 0.43), (0.097, 0.49), (0.084, 0.53), (0.0, 0.55)]
        let globe = acorn.map { ($0.0, $0.1 / 0.55 * gH) }
        m.add(turned(globe, segments: 36, material: glass), Xform(translation: V3(0, gy, 0)))
        // Mantle and burner.
        m.add(Prim.cylinder(radius: 0.012, height: 0.12, bevel: 0.002, segments: 10, material: iron), Xform(translation: V3(0, gy, 0)))
        m.add(turned([(0, 0), (0.03, 0.0), (0.035, 0.05), (0.028, 0.09), (0.0, 0.1)], segments: 14, material: mantle), Xform(translation: V3(0, gy + 0.12, 0)))
        // Copper cap: band, ventilated dome, finial.
        let cy = gy + gH - 0.03
        let cap: [(Float, Float)] = [(0.0, 0), (0.15, 0.0), (0.155, 0.03), (0.13, 0.04), (0.12, 0.07), (0.095, 0.11), (0.06, 0.14),
                                     (0.04, 0.15), (0.042, 0.17), (0.02, 0.18), (0.024, 0.21), (0.0, 0.23)]
        m.add(turned(cap.map { ($0.0 * 0.72, $0.1 * 0.85) }, segments: 32, material: copper), Xform(translation: V3(0, cy, 0)))
        let rem = height - (cy + 0.195)
        var fin: [(Float, Float)] = [(0, 0), (0.008, 0)]
        for i in 1...6 { let t = Float(i) / 6; fin.append((0.008 + 0.014 * sin(t * .pi), t * max(rem, 0.03) * 0.95)) }
        fin.append((0, max(rem, 0.03)))
        m.add(turned(fin, segments: 12, material: copper), Xform(translation: V3(0, cy + 0.19, 0)))
        // Base door plate (gas cock access) on the bell.
        m.add(Prim.roundedBox(V3(0.09, 0.13, 0.012), radius: 0.004, bevelSegments: 1, material: iron),
              Xform(translation: V3(0, 0.29 * k, br * 0.7), rotation: simd_quatf(degrees: -38, axis: V3(1, 0, 0))).jittered(&rng))
        groundAO(&m, height: 0.4)
        return LODModel(m)
    }
}
