import simd
import Foundation

/// 60 x 30 in alcove bathtub: enameled steel tub with a rounded rim, front apron and tile flange on the
/// back and ends, sloped basin, chrome drain with stopper and overflow plate, wall-mounted tub spout and
/// a valve escutcheon with lever handle. Back against the wall at z = -0.38, front apron at +Z, rim 0.41 m.
public struct AlcoveBathtub: RealAsset {
    public static let id = "alcove-bathtub"
    public static let summary = "60 x 30 in alcove bathtub: enameled steel tub with front apron and tile flange, chrome drain and overflow, wall-mounted tub spout and valve trim."
    public static let tags = ["prop", "floorplan", "bathroom", "plumbing", "ceramic", "metal", "interior"]
    public static let budget = 7000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 28, distance: 3.2, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(1.53, 0.6, 0.76)
    public var enamel: MaterialKey = "ceramic.vitreous"
    public var chrome: MaterialKey = "metal.chrome"
    /// Rim height above the floor.
    public var rimHeight: Float = 0.41
    /// Drain center on the basin floor (x).
    public var drainX: Float = -0.52
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        func make(_ lod: Int) -> Model {
            var m = Model(name: Self.id)
            let hi = lod == 0
            let W = size.x, D = size.z, rim = rimHeight
            let back = -D / 2
            let seg = hi ? 5 : 3
            func ring(_ w: Float, _ d: Float, _ r: Float, _ y: Float) -> [V3] { Prim.ring(Shape2D.roundedRect(w, d, radius: r, segments: seg), y: y) }
            let basin: [(Float, Float, Float, Float)] = [(1.40, 0.63, 0.09, 0.36), (1.35, 0.58, 0.12, 0.25), (1.24, 0.48, 0.15, 0.12), (1.16, 0.42, 0.17, 0.07)]
            let rows: [[V3]] = [
                ring(W - 0.06, D - 0.05, 0.035, 0.0), ring(W - 0.06, D - 0.05, 0.035, 0.014), ring(W - 0.03, D - 0.03, 0.045, 0.034), ring(W - 0.016, D - 0.016, 0.05, 0.2),
                ring(W - 0.016, D - 0.016, 0.05, rim - 0.034), ring(W - 0.012, D - 0.012, 0.05, rim - 0.022), ring(W, D, 0.05, rim - 0.01),
                ring(W - 0.006, D - 0.006, 0.05, rim - 0.0015), ring(W - 0.014, D - 0.014, 0.05, rim),
                ring(W - 0.1, D - 0.1, 0.06, rim), ring(W - 0.11, D - 0.11, 0.07, rim - 0.006)]
            // Patch the basin rows' heights (ring() above placed all at 0.3; rebuild with the real y).
            var all = Array(rows[0..<11])
            for b in basin { all.append(ring(b.0 * W / 1.53, b.1 * D / 0.76, b.2, b.3)) }
            m.add(Prim.loft(Array(all[0...8]), capStart: true, material: enamel))
            m.add(Prim.loft(Array(all[8...]), capEnd: true, material: enamel))
            // Tile flange along the back and both ends.
            m.add(Prim.roundedBox(V3(W, 0.034, 0.014), radius: 0.003, bevelSegments: 1, material: enamel), Xform(translation: V3(0, rim + 0.016, back + 0.007)))
            for sx: Float in [-1, 1] {
                m.add(Prim.roundedBox(V3(0.014, 0.034, D - 0.016), radius: 0.003, bevelSegments: 1, material: enamel), Xform(translation: V3(sx * (W / 2 - 0.007), rim + 0.016, 0.0)))
            }
            // Sculpted apron panel with a rolled lower bead.
            m.add(Prim.roundedBox(V3(W - 0.3, 0.24, 0.006), radius: 0.012, bevelSegments: hi ? 2 : 1, material: enamel), Xform(translation: V3(0, 0.21, D / 2 - 0.0055)))
            // Rust and limescale ring around the drain.
            m.add(Prim.lathe([V2(0.0345, 0.0003), V2(0.07, 0.0003), V2(0.072, 0.0007), V2(0.0345, 0.0007)], segments: hi ? 28 : 12, seamTile: 0.05, material: "plastic.matte:CDBFA3"),
                  Xform(translation: V3(drainX, 0.07, 0.0)))
            // Drain and stopper.
            let dc = V3(drainX, 0.07, 0.0)
            m.add(Prim.lathe([V2(0.001, 0.0005), V2(0.034, 0.0005), V2(0.037, 0.002), V2(0.032, 0.0045), V2(0.001, 0.0045)], segments: hi ? 22 : 10, seamTile: 0.05, material: chrome), Xform(translation: dc))
            m.add(Prim.lathe([V2(0.001, 0.0045), V2(0.022, 0.0045), V2(0.024, 0.0075), V2(0.001, 0.0085)], segments: hi ? 18 : 8, seamTile: 0.05, material: "metal.stainless"), Xform(translation: dc))
            // Overflow plate on the back wall of the basin (wall leans: z from the 0.36 and 0.25 rows).
            let ovY: Float = 0.30
            let ovZ = back + 0.05 + (0.1 * (D / 0.76)) * 0.0 + 0.0
            _ = ovZ
            let wallZ = -(0.63 * D / 0.76 / 2) + (0.58 * D / 0.76 / 2 - 0.63 * D / 0.76 / 2) * ((ovY - 0.36) / (0.25 - 0.36)) * -1 * -1
            m.add(Prim.lathe([V2(0.001, 0), V2(0.036, 0), V2(0.036, 0.003), V2(0.03, 0.006), V2(0.001, 0.0065)], segments: hi ? 20 : 10, seamTile: 0.05, material: chrome),
                  Xform(translation: V3(drainX - 0.1, ovY, wallZ + 0.006), rotation: simd_quatf(degrees: 90 - 12, axis: V3(1, 0, 0))))
            m.add(Prim.cylinder(radius: 0.011, height: 0.008, bevel: 0.003, segments: hi ? 12 : 6, material: chrome),
                  Xform(translation: V3(drainX - 0.1, ovY + 0.0015, wallZ + 0.0125), rotation: simd_quatf(degrees: 90 - 12, axis: V3(1, 0, 0))))
            // Wall-mounted tub spout (drain end) and valve trim, both on the back wall plane.
            let sx: Float = drainX - 0.03, sy: Float = 0.53
            m.add(Prim.lathe([V2(0.001, 0), V2(0.04, 0), V2(0.04, 0.003), V2(0.034, 0.008), V2(0.027, 0.02), V2(0.001, 0.02)], segments: hi ? 20 : 10, seamTile: 0.05, material: chrome),
                  Xform(translation: V3(sx, sy, back), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
            let spout = catmull([V3(sx, sy, back + 0.015), V3(sx, sy + 0.001, back + 0.07), V3(sx, sy - 0.006, back + 0.125), V3(sx, sy - 0.03, back + 0.15)], per: hi ? 5 : 2)
            m.add(Prim.tube(spout, radii: spout.indices.map { i in 0.016 - 0.003 * Float(i) / Float(spout.count - 1) }, sides: hi ? 16 : 8, seamTile: 0.05, material: chrome))
            m.add(Prim.cylinder(radius: 0.0155, height: 0.012, bevel: 0.0015, segments: hi ? 16 : 8, material: chrome),
                  Xform(translation: V3(sx, sy - 0.036, back + 0.15), rotation: simd_quatf(degrees: 180, axis: V3(1, 0, 0))))
            // Diverter pull on top of the spout.
            m.add(Prim.cylinder(radius: 0.005, height: 0.022, bevel: 0.0015, segments: hi ? 10 : 6, material: chrome), Xform(translation: V3(sx, sy + 0.016, back + 0.06)))
            m.add(Prim.cylinder(radius: 0.008, height: 0.006, bevel: 0.002, segments: hi ? 12 : 6, material: chrome), Xform(translation: V3(sx, sy + 0.036, back + 0.06)))
            let vx: Float = drainX + 0.33
            m.add(Prim.lathe([V2(0.001, 0), V2(0.058, 0), V2(0.058, 0.003), V2(0.05, 0.009), V2(0.034, 0.014), V2(0.001, 0.014)], segments: hi ? 24 : 10, seamTile: 0.05, material: chrome),
                  Xform(translation: V3(vx, sy + 0.01, back), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
            m.add(Prim.lathe([V2(0.001, 0), V2(0.018, 0), V2(0.016, 0.018), V2(0.012, 0.028), V2(0.001, 0.029)], segments: hi ? 16 : 8, seamTile: 0.05, material: chrome),
                  Xform(translation: V3(vx, sy + 0.01, back + 0.014), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
            let lever = catmull([V3(vx, sy + 0.01, back + 0.04), V3(vx + 0.01, sy + 0.012, back + 0.05), V3(vx + 0.04, sy + 0.012, back + 0.058), V3(vx + 0.065, sy + 0.01, back + 0.058)], per: hi ? 4 : 2)
            m.add(Prim.tube(lever, radii: lever.indices.map { i in i < lever.count - 2 ? Float(0.0065) : Float(0.0085) }, sides: hi ? 12 : 6, seamTile: 0.03, material: chrome))
            // Caulk bead around the tub foot.
            if hi {
                let bead = Prim.ring(Shape2D.roundedRect(W - 0.03, D - 0.01, radius: 0.035, segments: 3), y: 0.003)
                m.add(Prim.sweep(Shape2D.circle(0.003, ry: 0.0025, segments: 6), along: bead, up: V3(0, 1, 0), closedPath: true, material: "plastic.matte:D6D1BE"))
            }
            groundAO(&m, height: 0.2, floor: 0.6)
            return m
        }
        return LODModel(levels: [make(0), make(1)], switchDistances: [6])
    }
}
