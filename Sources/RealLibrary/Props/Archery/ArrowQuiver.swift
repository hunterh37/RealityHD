import simd
import Foundation

/// Arrow quiver: traditional hunting side quiver, tan leather, arrows with barred feather fletching in two colors, standing upright. Parts: leather body, stitching, belt strap, arrow shafts, fletching, nocks, bottom cap.
public struct ArrowQuiver: RealAsset {
    public static let id = "arrow-quiver"
    public static let summary = "Leather side quiver, 0.7 m: stitched tube with belt strap and eight fletched target arrows."
    public static let tags = ["prop", "archery", "handheld", "leather"]
    public static let budget = 10000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.19, 0.75, 0.21)
    /// Leather body height in meters (arrows stand proud of the mouth).
    public var bodyHeight: Float = 0.5
    /// Outer body radius at the mouth in meters.
    public var bodyRadius: Float = 0.088
    /// Number of arrows.
    public var arrowCount = 8
    /// Fletching colours (hex tints), alternating per arrow.
    public var fletchTints: [String] = ["E0561A", "F2F0E8"]
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let H = bodyHeight, R = bodyRadius, wall: Float = 0.004
        let leather: MaterialKey = "leather.tan", dark: MaterialKey = "leather.black"
        // Tapered stitched tube, open at the top, slightly narrower at the base.
        let body = Prim.lathe([V2(0, 0.012), V2(R * 0.86, 0.012), V2(R * 0.9, 0.03), V2(R * 0.97, H * 0.5), V2(R, H - 0.004), V2(R - 0.001, H),
                               V2(R - wall, H), V2(R - wall - 0.001, H - 0.01), V2(R * 0.84, 0.04), V2(0, 0.04)],
                              segments: 40, seamTile: 0.2, material: leather)
        m.add(body, .identity)
        // Bottom cap: dark leather disc with a welt ring.
        m.add(Prim.cylinder(radius: R * 0.9, height: 0.026, bevel: 0.006, segments: 40, material: dark), Xform(translation: V3(0, 0, 0)))
        // Mouth welt (rolled edge) in dark leather.
        m.add(Prim.torus(major: R - 0.002, minor: 0.0045, segments: 40, sides: 8, material: dark), Xform(translation: V3(0, H - 0.003, 0)))
        // Back seam stitched up the side (+Z side faces the viewer), plus a stitched line at both ends.
        func radiusAt(_ y: Float) -> Float { y < H * 0.5 ? R * (0.9 + 0.07 * y / (H * 0.5)) : R * 0.97 + (R - R * 0.97) * (y - H * 0.5) / (H * 0.5) }
        for off: Float in [-0.007, 0.007] {
            let seam = (0..<30).map { i -> V3 in let y = 0.05 + (H - 0.075) * Float(i) / 29; let r = radiusAt(y) + 0.0004; let a = Float.pi / 2 + off / r; return V3(cos(a) * r, y, sin(a) * r) }
            m.add(stitches(along: seam, normal: { p in simd_normalize(V3(p.x, 0, p.z)) }, material: "fabric.canvas:E8DCC0"), .identity)
        }
        // Raised seam welt strip under the stitches.
        let strip = (0..<12).map { i -> V3 in let y = 0.04 + (H - 0.06) * Float(i) / 11; return V3(0, y, radiusAt(y) - 0.001) }
        m.add(Prim.tube(strip, radii: strip.map { _ in 0.0035 }, sides: 6, seamTile: 0.05, material: leather, capEnd: true), .identity)
        // Stitch rings at base cap and below the mouth.
        for y: Float in [0.045, H - 0.035] {
            let ring = (0..<90).map { i -> V3 in let a = Float(i) / 90 * 2 * .pi; let r = radiusAt(y) + 0.0004; return V3(cos(a) * r, y, sin(a) * r) }
            m.add(stitches(along: ring + [ring[0]], normal: { p in simd_normalize(V3(p.x, 0, p.z)) }, pitch: 0.005, material: "fabric.canvas:E8DCC0"), .identity)
        }
        // Belt strap on the back (-Z): flat plate with a loop for a belt, brass-free bolt rivets.
        let backZ = -radiusAt(0.25)
        m.add(HuntKit.box(V3(0, 0.30, backZ - 0.004), V3(0.05, 0.30, 0.008), r: 0.003, leather), .identity)
        m.add(HuntKit.box(V3(0, 0.21, backZ - 0.016), V3(0.05, 0.012, 0.030), r: 0.004, dark), .identity)
        m.add(HuntKit.box(V3(0, 0.42, backZ - 0.012), V3(0.05, 0.012, 0.022), r: 0.004, dark), .identity)
        m.add(HuntKit.box(V3(0, 0.315, backZ - 0.028), V3(0.052, 0.19, 0.008), r: 0.003, dark), .identity)
        for y: Float in [0.23, 0.40] { rivet(&m, at: V3(0, y, backZ - 0.0325), normal: V3(0, 0, -1), radius: 0.005, material: "metal.bolt-bright") }
        // Eight arrows standing in the tube, nocks up, fletching proud of the mouth.
        let L: Float = 0.68, r: Float = 0.0036, top: Float = size.y - 0.005
        for i in 0..<arrowCount {
            var a = rng.fork(i)
            let (px, pz): (Float, Float)
            if i == 0 { (px, pz) = (0.005, 0.0) } else {
                let frac: Float = Float(i - 1) / Float(max(arrowCount - 1, 1))
                let jit: Float = a.float(-0.02...0.02)
                let ang: Float = (frac + jit) * 2 * Float.pi
                (px, pz) = (cos(ang) * 0.046, sin(ang) * 0.046)
            }
            let tiltX = a.float(-4...4), tiltZ = a.float(-4...4)
            let drop = a.float(0...0.01)
            let q = simd_quatf(degrees: tiltZ, axis: V3(0, 0, 1)) * simd_quatf(degrees: tiltX, axis: V3(1, 0, 0))
                * simd_quatf(angle: -.pi / 2, axis: V3(0, 0, 1)) * simd_quatf(degrees: a.float(0...360), axis: V3(1, 0, 0))
            let world = Xform(translation: V3(px, top - drop, pz), rotation: q)
            let t0 = fletchTints[i % fletchTints.count], t1 = fletchTints[(i + 1) % fletchTints.count]
            func add(_ s: Surface, _ x: Xform = .identity) { m.add(s.transformed(x), world) }
            add(Prim.tube([V3(0.008, 0, 0), V3(L, 0, 0)], radii: [r, r], sides: 8, seamTile: 0.02, material: "plastic.carbon-shaft", capEnd: true))
            add(HuntKit.axial([(0, 0), (0, r), (0.002, r * 1.35), (0.009, r * 1.28), (0.0125, r), (0.0125, 0)], seg: 8, tile: 0.02, "plastic.fletching:F2F0E8"))
            for (s, x) in HuntKit.vanes(x0: 0.04, len: 0.09, r: r, h: 0.011, tints: [t0, t1, t1]) { add(s, x) }
            add(HuntKit.axial([(0, 0), (0, r * 1.06), (0.006, r * 1.06), (0.006, 0)], at: V3(0.034, 0, 0), seg: 8, tile: 0.02, "plastic.fletching:" + t0))
            add(HuntKit.axial([(0, 0), (0, r * 1.06), (0.006, r * 1.06), (0.006, 0)], at: V3(0.13, 0, 0), seg: 8, tile: 0.02, "plastic.fletching:" + t0))
            add(HuntKit.axial([(0, 0), (0, r * 1.2), (0.012, r * 1.2), (0.03, r * 0.2), (0.03, 0)], at: V3(L - 0.012, 0, 0), seg: 8, tile: 0.02, "metal.bolt-bright"))
        }
        groundAO(&m)
        return LODModel(m)
    }
}
