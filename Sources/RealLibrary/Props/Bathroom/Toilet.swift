import simd
import Foundation

/// Close-coupled toilet: two-piece vitreous china. Elongated skirted bowl on a floor flange, tank with
/// an overhanging lid, chrome front flush lever, duroplast seat ring and closed lid on hinge posts,
/// bolt caps and a gasket seam between tank and bowl. Back at z = -0.35, front +Z.
public struct Toilet: RealAsset {
    public static let id = "toilet"
    public static let summary = "Two-piece elongated toilet: skirted bowl, tank and lid, chrome front lever, seat and lid down."
    public static let tags = ["prop", "floorplan", "bathroom", "plumbing", "ceramic", "interior"]
    public static let budget = 7500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 18, distance: 1.9, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.38, 0.79, 0.7)
    /// China body.
    public var china: MaterialKey = "ceramic.vitreous"
    /// Seat and lid (duroplast).
    public var seat: MaterialKey = "plastic.gloss:F0EEE6"
    /// Bowl rim height above the floor.
    public var rimHeight: Float = 0.385
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        func make(_ lod: Int) -> Model {
            var m = Model(name: Self.id)
            let hi = lod == 0
            let seg = hi ? 28 : 12
            let back = -size.z / 2, front = size.z / 2
            let rim = rimHeight
            func ring(_ hw: Float, _ fr: Float, _ re: Float, _ rr: Float, _ y: Float) -> [V3] {
                Prim.ring(BathFit.dOutline(hw: hw, front: fr, rear: re, rr: rr, nFront: hi ? 10 : 5), y: y)
            }
            // Floor flange (plinth) under the skirt.
            m.add(Prim.loft([ring(0.140, front - 0.07, back + 0.09, 0.03, 0.0), ring(0.143, front - 0.07, back + 0.09, 0.03, 0.01),
                             ring(0.140, front - 0.068, back + 0.09, 0.03, 0.016)], capStart: true, capEnd: true, material: china))
            // Skirted bowl and trapway.
            let rows: [(Float, Float, Float, Float, Float)] = [
                (rim, 0.176, front - 0.005, back + 0.045, 0.025), (rim - 0.012, 0.179, front, back + 0.04, 0.025),
                (rim - 0.05, 0.178, front - 0.005, back + 0.04, 0.03), (0.24, 0.17, front - 0.012, back + 0.05, 0.04),
                (0.14, 0.158, front - 0.035, back + 0.06, 0.05), (0.07, 0.136, front - 0.06, back + 0.08, 0.05),
                (0.02, 0.128, front - 0.08, back + 0.1, 0.05)]
            m.add(Prim.loft(rows.reversed().map { ring($0.1, $0.2, $0.3, $0.4, $0.0) }, capStart: true, capEnd: true, material: china))
            // Rim shelf the seat rests on, a touch inside the outer wall.
            m.add(Prim.loft([ring(0.150, front - 0.03, back + 0.2, 0.03, rim), ring(0.150, front - 0.03, back + 0.2, 0.03, rim + 0.0015)], capEnd: true, material: china))
            // Tank: body, gasket, lid.
            let tw: Float = 0.37, td: Float = 0.185, th: Float = 0.375
            let tankZ = back + td / 2
            m.add(Prim.roundedBox(V3(tw, th, td), radius: 0.014, bevelSegments: hi ? 3 : 1, material: china),
                  Xform(translation: V3(0, rim + th / 2 - 0.002, tankZ)))
            m.add(Prim.roundedBox(V3(tw - 0.07, 0.014, td - 0.04), radius: 0.005, bevelSegments: 1, material: "plastic.matte:E8E8E4"),
                  Xform(translation: V3(0, rim + 0.004, tankZ)))
            let lidY = rim + th - 0.002
            m.add(Prim.roundedBox(V3(size.x, 0.032, td + 0.012), radius: 0.011, bevelSegments: hi ? 3 : 1, material: china),
                  Xform(translation: V3(0, lidY + 0.016, tankZ + 0.002)))
            // Raised lid panel and flared tank foot.
            m.add(Prim.roundedBox(V3(size.x - 0.05, 0.003, td - 0.03), radius: 0.0018, bevelSegments: 1, material: china),
                  Xform(translation: V3(0, lidY + 0.0315, tankZ + 0.002)))
            m.add(Prim.roundedBox(V3(tw + 0.008, 0.022, td + 0.006), radius: 0.008, bevelSegments: hi ? 2 : 1, material: china),
                  Xform(translation: V3(0, rim + 0.0095, tankZ)))
            // Flush lever on the front face, left side.
            let fz = back + td
            let lx: Float = -0.12, ly: Float = rim + th - 0.075
            m.add(Prim.lathe([V2(0.001, 0), V2(0.019, 0), V2(0.019, 0.0025), V2(0.015, 0.006), V2(0.001, 0.0065)], segments: seg, seamTile: 0.05, material: "metal.chrome"),
                  Xform(translation: V3(lx, ly, fz - 0.0008), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
            let lever = catmull([V3(lx, ly, fz + 0.006), V3(lx, ly, fz + 0.022), V3(lx + 0.012, ly + 0.002, fz + 0.026), V3(lx + 0.045, ly + 0.003, fz + 0.026), V3(lx + 0.075, ly + 0.003, fz + 0.026)], per: hi ? 4 : 2)
            let lr = lever.indices.map { i in i < lever.count - 3 ? Float(0.0055) : Float(0.0075) }
            m.add(Prim.tube(lever, radii: lr, sides: hi ? 12 : 6, seamTile: 0.03, material: "metal.chrome"))
            // Seat ring and lid.
            let sy = rim + 0.002
            let seatPath = Prim.ring(BathFit.dOutline(hw: 0.158, front: front - 0.029, rear: back + 0.24, rr: 0.03, nFront: hi ? 12 : 6), y: sy + 0.0135)
            m.add(Prim.sweep(Shape2D.roundedRect(0.027, 0.056, radius: 0.012, segments: hi ? 3 : 2), along: seatPath, up: V3(0, 1, 0), closedPath: true, material: seat))
            let lidRings: [[V3]] = [(0.0, 0.182, 0.0), (0.011, 0.182, 0.0), (0.0185, 0.172, 0.006), (0.021, 0.16, 0.02)].enumerated().map { (i, r) in
                Prim.ring(BathFit.dOutline(hw: r.1, front: front - 0.006 - r.2, rear: back + 0.205 + r.2 * 0.6, rr: 0.035, nFront: hi ? 10 : 5), y: sy + 0.0285 + r.0)
            }
            m.add(Prim.loft(lidRings, capStart: true, capEnd: true, material: seat))
            // Caulk bead around the floor flange.
            let bead = Prim.ring(BathFit.dOutline(hw: 0.1535, front: front - 0.0665, rear: back + 0.0865, rr: 0.0335, nFront: hi ? 10 : 5), y: 0.0035)
            m.add(Prim.sweep(Shape2D.circle(0.0035, ry: 0.0028, segments: hi ? 8 : 5), along: bead, up: V3(0, 1, 0), closedPath: true, material: "plastic.matte:D6D1BE"))
            // Supply line and angle stop behind the bowl, left.
            let sx: Float = -0.135, sz = back + 0.012
            m.add(Prim.tube([V3(sx, rim + 0.002, sz), V3(sx, rim - 0.02, sz), V3(sx, 0.17, sz)], radii: [0.0045, 0.0045, 0.0045], sides: hi ? 10 : 6, seamTile: 0.03, material: "metal.chrome"))
            m.add(Prim.cylinder(radius: 0.011, height: 0.03, bevel: 0.003, segments: hi ? 14 : 8, material: "metal.chrome"), Xform(translation: V3(sx, 0.145, sz)))
            m.add(Prim.roundedBox(V3(0.026, 0.01, 0.006), radius: 0.003, bevelSegments: 1, material: "metal.chrome"), Xform(translation: V3(sx, 0.16, sz + 0.0125)))
            // Hinge caps.
            for k: Float in [-1, 1] {
                m.add(Prim.cylinder(radius: 0.0085, height: 0.03, bevel: 0.002, segments: hi ? 12 : 6, material: "metal.satin-aluminum"),
                      Xform(translation: V3(k * 0.12, rim + 0.0285, back + 0.19), rotation: simd_quatf(degrees: 90, axis: V3(0, 0, 1))))
            }
            // Hinge posts and bumpers.
            let hz = back + 0.2
            for sx: Float in [-1, 1] {
                m.add(Prim.roundedBox(V3(0.034, 0.026, 0.03), radius: 0.008, bevelSegments: 2, material: "plastic.white"),
                      Xform(translation: V3(sx * 0.12, rim + 0.016, hz - 0.01)))
                m.add(Prim.cylinder(radius: 0.011, height: 0.0036, bevel: 0.0015, segments: 10, material: "rubber.silicone:222222"),
                      Xform(translation: V3(sx * 0.1, rim - 0.0005, front - 0.075)))
                // Bolt caps on the flange.
                m.add(Prim.cylinder(radius: 0.0125, height: 0.013, bevel: 0.004, segments: 12, material: "plastic.white"),
                      Xform(translation: V3(sx * 0.112, 0.016, -0.045)))
            }
            groundAO(&m, height: 0.2, floor: 0.6)
            return m
        }
        return LODModel(levels: [make(0), make(1)], switchDistances: [5])
    }
}
