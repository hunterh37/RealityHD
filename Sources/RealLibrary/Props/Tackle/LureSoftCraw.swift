import simd
import Foundation

/// Soft plastic craw, 90 mm, lying belly down: segmented tail ending in a fan (the rigging end), wider
/// thorax with a carapace ridge, head with long antennae and whisker legs, two flat flapping pincers.
/// Salted green pumpkin with black and copper flake. Anchor: `lineTie` (tail tip where the hook enters).
public struct LureSoftCraw: RealAsset, RealAnchored {
    public static let id = "lure-soft-craw"
    public static let summary = "Soft plastic craw 90 mm: segmented body, two flat pincers, antennae and legs, green pumpkin flake."
    public static let tags = ["prop", "fishing", "handheld", "plastic"]
    public static let budget = 6200
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 50, distance: 1.0, studio: true)

    /// Plastic colour (sRGB hex).
    public var color: UInt32 = 0x4A5226
    /// Claw tip colour (dipped).
    public var tipColor: UInt32 = 0xB8562A
    public init() {}

    static let tailX: Float = 0.03
    public static var anchors: [String: RealAnchor] {
        let (_, shift, y) = Self().model(seed: 1)
        return ["lineTie": RealAnchor(V3(tailX + 0.008, y, 0) + shift, direction: V3(1, 0, 0))]
    }

    public func build(seed: UInt64) -> LODModel { LODModel(model(seed: seed).0) }

    /// Model, the centring shift applied, and the body axis height before the shift.
    func model(seed: UInt64) -> (Model, V3, Float) {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let mat: MaterialKey = "plastic.soft-bait:" + String(format: "%06X", color)
        let tip: MaterialKey = "plastic.soft-bait:" + String(format: "%06X", tipColor)
        // Body: loft from the tail tip (+X) to the head (-X), flattened sections, segment ridges on the tail.
        let x1 = Self.tailX, x0: Float = -0.026
        var rings: [[V3]] = []
        let n = 40
        for i in 0...n {
            let t = 1 - Float(i) / Float(n)
            let x = x1 + (x0 - x1) * t
            var w: Float = 0.0042 + 0.0055 * min(1, t / 0.55)        // tail widens toward the thorax
            if t > 0.55 { w = 0.0097 - 0.004 * pow((t - 0.55) / 0.45, 1.5) }
            if t < 0.5 { w += 0.0005 * max(0, sin(t * 22 * .pi)) }    // tail segments
            let h = w * 0.72
            rings.append(Prim.ring(Shape2D.superellipse(2 * h, 2 * w, exponent: 2.4), y: x).map { V3($0.x, $0.y, $0.z) })
        }
        // Built along +Y, turn onto X (head at -X). Lathe +Y -> +X rotation keeps the order tail -> head.
        var body = Prim.loft(rings, capStart: true, capEnd: true, material: mat)
        body.deform { p in V3(p.y, -p.x, p.z) }
        let b = body.bounds
        m.add(body, Xform(translation: V3(0, -b.min.y + 0.0002, 0)))
        let cy = -b.min.y + 0.0002
        // Tail fan.
        let fan = Shape2D.rounded([V2(0, -0.0035), V2(0.009, -0.007), V2(0.011, 0), V2(0.009, 0.007), V2(0, 0.0035)], radius: 0.002)
        m.add(Prim.extrude(fan, depth: 0.0018, bevel: 0.0006, bevelSegments: 1, material: mat), Xform(translation: V3(x1 - 0.002, 0.0011, 0), rotation: simd_quatf(angle: .pi / 2, axis: V3(1, 0, 0))))
        // Carapace ridge on the thorax.
        m.add(Prim.superellipsoid(V3(0.02, 0.003, 0.004), exponent: 2.5, subdivisions: 5, material: mat), Xform(translation: V3(-0.012, cy + 0.0052, 0)))
        // Pincers: arm, then a flat paddle claw with a split tip, splayed out on the ground.
        for side: Float in [-1, 1] {
            let spread = side * rng.float(0.32...0.42)
            let q = simd_quatf(angle: spread, axis: V3(0, 1, 0))
            let base = V3(x0 + 0.004, cy - 0.001, side * 0.003)
            let elbow = base + q.act(V3(-0.012, -0.0015, 0))
            m.add(Prim.tube([base, elbow], radii: [0.0024, 0.0019], sides: 8, seamTile: 0.02, material: mat))
            var claw = Prim.superellipsoid(V3(0.03, 0.0028, 0.015), exponent: 2.3, subdivisions: 8, material: mat)
            claw.deform { p in V3(p.x, p.y, p.z * (1 - 0.35 * max(0, -p.x / 0.016))) }
            m.add(claw, Xform(translation: elbow + q.act(V3(-0.0155, 0, 0)) + V3(0, 0, 0), rotation: q))
            // Split tip: two short dipped fingers.
            for f: Float in [-1, 1] {
                let s = elbow + q.act(V3(-0.03, 0, f * 0.0025))
                m.add(Prim.tube([s, s + q.act(V3(-0.006, 0, f * 0.0012))], radii: [0.0014, 0.0004], sides: 6, seamTile: 0.01, material: tip))
            }
        }
        // Antennae and walking legs.
        for side: Float in [-1, 1] {
            var ant: [V3] = []
            for i in 0...8 { let t = Float(i) / 8; ant.append(V3(x0 + 0.002 - 0.045 * t, cy + 0.001 - 0.0015 * t, side * (0.0015 + 0.02 * t * t))) }
            m.add(Prim.tube(ant, radii: ant.indices.map { 0.0007 - 0.0005 * Float($0) / 8 }, sides: 5, seamTile: 0.01, material: mat))
            for k in 0..<4 {
                let lx = -0.004 - Float(k) * 0.0045
                let p0 = V3(lx, cy - 0.002, side * 0.006)
                let p1 = p0 + V3(rng.float(-0.003...0.003), -0.0015, side * rng.float(0.008...0.011))
                m.add(Prim.tube([p0, (p0 + p1) / 2 + V3(0, 0.001, 0), p1], radii: [0.0006, 0.0005, 0.0002], sides: 5, seamTile: 0.01, material: mat))
            }
        }
        // Base at y = 0, centred.
        let bb = m.bounds
        let shift = V3(-(bb.min.x + bb.max.x) / 2, -bb.min.y, -(bb.min.z + bb.max.z) / 2)
        var out = Model(name: Self.id)
        for s in m.surfaces { out.add(s, Xform(translation: shift)) }
        groundAO(&out, height: 0.008, floor: 0.55)
        return (out, shift, cy)
    }
}
