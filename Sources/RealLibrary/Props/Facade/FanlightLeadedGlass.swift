import simd
import Foundation

/// Federal semi-elliptical fanlight, 1.6 x 0.8 m: painted pine frame with an outer ovolo moulding and inner bead, eleven
/// radiating muntins from a reeded half-round hub, two concentric tracery arcs, leaded clear glass with lead cames
/// and a repair quarry, a carved keystone with patera, impost blocks with bellflower husk drops and a drip-capped
/// sill rail. Paint is chalked and chipped at the sill and imposts, with a grime line along the sill.
public struct FanlightLeadedGlass: RealAsset {
    public static let id = "fanlight-leaded-glass"
    public static let summary = "Federal semi-elliptical fanlight over a door: painted wood frame with radiating muntins and tracery arcs, leaded clear glass and a carved keystone."
    public static let tags = ["prop", "architecture", "facade", "window", "wood", "glass"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 8, distance: 2.8)

    /// Overall frame width (m).
    public var width: Float = 1.6
    /// Rise of the ellipse above the sill rail (m).
    public var rise: Float = 0.68
    /// Number of radiating muntins.
    public var ribs = 11
    /// Painted frame (Federal cream, chalked).
    public var paint: MaterialKey = "wood.painted-exterior:E4D9BF"
    /// Muntins and tracery, repainted a lighter cream than the frame.
    public var muntinPaint: MaterialKey = "wood.painted-exterior:F2EBD9"
    /// Weathered paint at the sill and imposts.
    public var worn: MaterialKey = "wood.painted-shaker-worn:BDB091"
    /// Lead cames.
    public var lead: MaterialKey = "metal.painted:4F5155"
    /// Glass.
    public var glass: MaterialKey = "glass.clear"
    /// Keystone and patera stone.
    public var stone: MaterialKey = "stone.cast-stone"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let rx = width / 2, ry = rise, sillH: Float = 0.06, cy = sillH
        let zc: Float = 0.07, depth: Float = 0.14
        func ell(_ a: Float, _ ix: Float, _ iy: Float, z: Float) -> V3 { V3(cos(a) * (rx - ix), cy + sin(a) * (ry - iy), z) }
        func arc(_ ix: Float, _ iy: Float, z: Float, n: Int = 44) -> [V3] { (0...n).map { ell(Float($0) / Float(n) * .pi, ix, iy, z: z) } }

        // Frame: ovolo outer moulding with a stepped back, swept along the semi-ellipse.
        let frameProfile: [V2] = [V2(-0.05, -0.03), V2(0.03, -0.03), V2(0.047, -0.021), V2(0.05, -0.008), V2(0.05, 0.006), V2(0.04, 0.012),
                                  V2(0.04, 0.03), V2(-0.05, 0.03)]
        m.add(Prim.sweep(frameProfile, along: arc(0.032, 0.032, z: zc), up: FA.Z, grainAlongPath: true, material: paint))
        // Inner glazing bead on the front.
        m.add(Prim.sweep(FJ.beadProfile(0.008, segments: 4), along: arc(0.066, 0.066, z: zc + 0.048), up: FA.Z, material: paint))
        // Glass: one semi-ellipse quad.
        var gl: [V2] = []
        for i in 0...44 { let a = Float(i) / 44 * .pi; gl.append(V2(cos(a) * (rx - 0.066), cy + sin(a) * (ry - 0.066))) }
        m.add(Prim.extrude(Shape2D.deduped(gl), depth: 0.006, bevel: 0.0008, bevelSegments: 1, material: glass), Xform(translation: V3(0, 0, zc + 0.002)))

        // Hub: half-round reeded boss, rim beads.
        var hub: [V2] = []
        for i in 0...24 { let a = Float(i) / 24 * .pi; hub.append(V2(cos(a) * 0.105, sin(a) * 0.105)) }
        m.add(Prim.extrude(Shape2D.deduped(hub), depth: 0.05, bevel: 0.004, bevelSegments: 2, material: paint), Xform(translation: V3(0, cy, zc + 0.02)))
        for k in 0..<9 {
            let a = (Float(k) + 0.5) / 9 * .pi
            FJ.slab(&m, V3(0.006, 0.07, 0.004), V3(cos(a) * 0.058, cy + sin(a) * 0.058, zc + 0.047), paint, rot: FA.q(a * 180 / .pi - 90, FA.Z))
        }
        FA.cylZ(&m, r: 0.02, h: 0.012, at: V3(0, cy + 0.015, zc + 0.045), stone, bevel: 0.002, segments: 16)
        // Radiating muntins from the hub to the frame, each with a tapered end and lead came shadow lines beside it.
        for k in 0..<ribs {
            let a = (Float(k) + 0.5) / Float(ribs) * .pi
            let p0 = V2(cos(a) * 0.10, cy + sin(a) * 0.095), p1 = V2(cos(a) * (rx - 0.07), cy + sin(a) * (ry - 0.07))
            let len = simd_length(p1 - p0), mid = (p0 + p1) / 2, ang = atan2(p1.y - p0.y, p1.x - p0.x) * 180 / .pi
            FJ.slab(&m, V3(len, 0.014, 0.030), V3(mid.x, mid.y, zc + 0.024), muntinPaint, rot: FA.q(ang, FA.Z))
            FJ.slab(&m, V3(len, 0.006, 0.006), V3(mid.x, mid.y, zc + 0.041), muntinPaint, rot: FA.q(ang, FA.Z))
        }
        // Concentric tracery arcs at two radii, with beaded fronts.
        for f: Float in [0.40, 0.68] {
            let pts = (0...40).map { i -> V3 in let a = Float(i) / 40 * .pi; return V3(cos(a) * (rx - 0.066) * f, cy + sin(a) * (ry - 0.066) * f, zc + 0.026) }
            m.add(Prim.sweep([V2(-0.014, -0.007), V2(0.014, -0.007), V2(0.014, 0.007), V2(-0.014, 0.007)], along: pts, up: FA.Z, material: muntinPaint))
            m.add(Prim.sweep(FJ.beadProfile(0.004, segments: 3), along: pts.map { V3($0.x, $0.y, $0.z + 0.014) }, up: FA.Z, material: paint))
        }
        // Lead cames: pointed-oval petals between the ribs, built from arcs between rib-midpoints at three radii.
        for i in 0..<(ribs - 1) {
            let a0 = (Float(i) + 0.5) / Float(ribs) * .pi, a1 = (Float(i) + 1.5) / Float(ribs) * .pi, am = (a0 + a1) / 2
            for (f0, f1) in [(0.18, 0.40), (0.40, 0.68), (0.68, 1.0)] as [(Float, Float)] {
                func pt(_ a: Float, _ f: Float) -> V2 { V2(cos(a) * (rx - 0.066) * f, cy + sin(a) * (ry - 0.066) * f) }
                let mid0 = pt(am, (f0 + f1) / 2 + 0.0)
                for (s, e) in [(pt(a0, f0), mid0), (pt(a1, f0), mid0), (pt(a0, f1), mid0), (pt(a1, f1), mid0)] {
                    let d = e - s, len = simd_length(d)
                    if f0 < 0.2, s.y < cy + 0.05 { continue }
                    FJ.slab(&m, V3(len, 0.0035, 0.005), V3((s.x + e.x) / 2, (s.y + e.y) / 2, zc + 0.006), lead,
                            rot: FA.q(atan2(d.y, d.x) * 180 / .pi, FA.Z))
                }
            }
        }
        // Repair quarry in older, slightly green glass.
        FJ.slab(&m, V3(0.06, 0.05, 0.0035), V3(0.31, cy + 0.19, zc + 0.0075), "glass.tinted", rot: FA.q(52, FA.Z))

        // Keystone at the crown and carved patera, impost blocks at the springing with husk drops.
        m.add(Prim.extrude([V2(-0.06, 0), V2(0.06, 0), V2(0.048, 0.1), V2(-0.048, 0.1)], depth: 0.06, bevel: 0.004, bevelSegments: 2, material: stone),
              Xform(translation: V3(0, cy + ry - 0.04, zc + 0.045)))
        m.add(Prim.torus(major: 0.026, minor: 0.006, segments: 20, sides: 6, material: stone), Xform(translation: V3(0, cy + ry + 0.0, zc + 0.072), rotation: FA.q(90, FA.X)))
        FC.bead(&m, r: 0.007, at: V3(0, cy + ry + 0.0, zc + 0.073), stone, sub: 4)
        for e: Float in [-1, 1] {
            let ix = e * (rx - 0.055)
            FA.box(&m, V3(0.11, 0.1, depth - 0.01), V3(ix, sillH + 0.05 - 0.0, (depth - 0.01) / 2), paint, r: 0.004)
            FA.box(&m, V3(0.125, 0.014, depth), V3(ix, sillH + 0.107, depth / 2), paint, r: 0.0035)       // impost cap
            FJ.slab(&m, V3(0.09, 0.012, 0.004), V3(ix, sillH + 0.012, depth - 0.003), paint)               // base fillet
            m.add(Prim.torus(major: 0.022, minor: 0.0045, segments: 20, sides: 6, material: paint), Xform(translation: V3(ix, sillH + 0.056, depth - 0.003), rotation: FA.q(90, FA.X)))
            FC.bead(&m, r: 0.011, at: V3(ix, sillH + 0.056, depth + 0.0005), paint, sub: 4)
            // Husk drops: five graduated beads on a thread.
            for h in 0..<5 {
                FC.bead(&m, r: 0.0065 - Float(h) * 0.0006, at: V3(ix + e * 0.0, sillH - 0.001 - 0.0, depth - 0.0), worn, sub: 2)
                _ = h
            }
        }
        // Sill rail: drip-capped board with bead, face nails and a grime line.
        FA.box(&m, V3(width, 0.044, depth), V3(0, 0.022, depth / 2), worn, r: 0.004)
        FA.box(&m, V3(width + 0.012, 0.016, depth + 0.012), V3(0, 0.052, depth / 2 + 0.006 - 0.0), paint, r: 0.004)
        FJ.slab(&m, V3(width - 0.02, 0.0012, 0.014), V3(0, 0.0605, depth - 0.02), "wood.painted-shaker-worn:8E8573")
        m.add(Prim.sweep(FJ.beadProfile(0.006, segments: 4), along: [V3(-rx + 0.02, 0.028, depth), V3(rx - 0.02, 0.028, depth)], up: FA.Y, material: paint))
        for i in 0..<12 {
            let x = -rx + 0.16 + Float(i) * (width - 0.32) / 11
            rivet(&m, at: V3(x, 0.036, depth + 0.0005), normal: FA.Z, radius: 0.0028, segments: 6, material: "metal.steel")
        }
        // Face-nail heads along the arc frame, filled and painted.
        for i in 0..<10 {
            let a = (Float(i) + 0.5) / 10 * .pi
            let p = ell(a, 0.012, 0.012, z: zc + 0.05)
            rivet(&m, at: p, normal: FA.Z, radius: 0.0025, segments: 6, material: worn)
        }
        // Paint chips where the weather and hands reach: sill front, impost faces and low frame ends.
        FJ.chips(&m, spots: [V3(-0.55, 0.028, 0), V3(0.2, 0.034, 0), V3(0.6, 0.03, 0), V3(-rx + 0.055, 0.12, 0), V3(rx - 0.055, 0.12, 0)],
                 face: depth + 0.0003, "wood.weathered", rng: &rng, each: 5)
        FJ.chips(&m, spots: [V3(rx - 0.032, 0.14, 0), V3(rx - 0.032, 0.26, 0), V3(-rx + 0.032, 0.17, 0), V3(-rx + 0.032, 0.30, 0), V3(rx - 0.034, 0.40, 0)],
                 face: zc + 0.05, "wood.weathered", rng: &rng, each: 5)
        // Larger paint failures: flaked patches down to grey primer and wood at the sill, imposts and lower frame ends.
        func peel(_ c: V3, _ w: Float, _ h: Float, _ mat: MaterialKey) {
            let pts = Shape2D.rounded([V2(-w / 2, -h / 2), V2(w / 2, -h * 0.4), V2(w * 0.45, h / 2), V2(-w * 0.1, h * 0.45), V2(-w / 2, h * 0.15)], radius: 0.004, segments: 1)
            m.add(Prim.extrude(pts, depth: 0.0012, bevel: 0.0003, bevelSegments: 1, material: mat),
                  Xform(translation: V3(c.x, c.y, c.z + 0.0006), rotation: FA.q(rng.float(-14...14), FA.Z)))
        }
        for (x, y, w, h) in [(-0.62, 0.024, 0.11, 0.026), (-0.18, 0.02, 0.07, 0.022), (0.33, 0.026, 0.13, 0.025), (0.71, 0.022, 0.06, 0.02)] as [(Float, Float, Float, Float)] {
            peel(V3(x, y, depth), w, h, "wood.weathered")
            peel(V3(x + 0.01, y + 0.001, depth + 0.0008), w * 0.55, h * 0.5, "wood.painted-shaker-worn:7C7566")
        }
        for e: Float in [-1, 1] { peel(V3(e * (rx - 0.055) + 0.012, 0.08, depth), 0.05, 0.05, "wood.weathered"); peel(V3(e * (rx - 0.05), 0.07, depth + 0.0008), 0.025, 0.03, "wood.painted-shaker-worn:7C7566") }
        for (x, y, w, h) in [(rx - 0.032, 0.20, 0.03, 0.12), (-rx + 0.032, 0.25, 0.03, 0.10), (rx - 0.033, 0.46, 0.025, 0.07)] as [(Float, Float, Float, Float)] {
            peel(V3(x, y, zc + 0.05), w, h, "wood.weathered")
        }
        // Alligatored paint along the arc crown where sun and rain hit hardest.
        for i in 0..<11 {
            let a = (Float(i) + 0.3 + rng.float(0...0.5)) / 11 * .pi
            let p = ell(a, 0.034 + rng.float(-0.006...0.006), 0.034 + rng.float(-0.006...0.006), z: zc + 0.05)
            let tan = a * 180 / .pi + 90
            let w = rng.float(0.03...0.07), h = rng.float(0.01...0.02)
            let pts = Shape2D.rounded([V2(-w / 2, -h / 2), V2(w / 2, -h * 0.4), V2(w * 0.45, h / 2), V2(-w * 0.1, h * 0.45)], radius: 0.003, segments: 1)
            m.add(Prim.extrude(pts, depth: 0.0012, bevel: 0.0003, bevelSegments: 1, material: i % 3 == 0 ? "wood.painted-shaker-worn:7C7566" : "wood.weathered"),
                  Xform(translation: V3(p.x, p.y, p.z + 0.0006), rotation: FA.q(tan, FA.Z)))
        }
        // Grime streaks running down from the impost caps and the sill ends.
        for e: Float in [-1, 1] { FJ.slab(&m, V3(0.014, 0.1, 0.0012), V3(e * (rx - 0.02), 0.11, depth + 0.0006), "wood.painted-shaker-worn:6A6252") }
        // Dust and soot gathered on the glass ledge above the sill rail.
        FJ.slab(&m, V3(width - 0.14, 0.012, 0.0045), V3(0, sillH + 0.008, zc + 0.0062), "wood.painted-shaker-worn:6F6757")
        groundAO(&m, height: 0.1, floor: 0.9)
        return LODModel(FC.place(m))
    }
}
