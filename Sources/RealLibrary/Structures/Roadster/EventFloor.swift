import simd
import Foundation

/// Event floor: 60 x 40 m dark sealed concrete (#0B0D0C) with white painted lines, an X across the
/// floor and a drive-lane line down the long axis. Top surface at y = 0, centered on the origin.
public struct EventFloor: RealAsset {
    public static let id = "event-floor"
    public static let summary = "60 x 40 m dark sealed concrete event floor with white painted lines: crossing X and a drive lane line."
    public static let tags = ["structure", "concrete"]
    public static let budget = 5000
    public static let author = "realityhd"

    /// Floor size in meters (x width, z depth).
    public var size = V2(60, 40)
    /// Slab thickness in meters (below y = 0).
    public var thickness: Float = 0.2
    /// Paint line width in meters.
    public var lineWidth: Float = 0.10
    /// X of the drive lane line running along Z.
    public var laneX: Float = 14
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        // Circular sealed-concrete floor, stepped toward black beyond 25 m (no visible slab edge).
        let rings: [(Float, Float, MaterialKey)] = [(29, -0.003, "concrete.sealed-void"), (20, -0.002, "concrete.sealed-void"), (14, -0.001, "concrete.sealed-dim")]
        for (r, y, mat) in rings {
            m.add(Prim.lathe([V2(0, y - 0.2), V2(r, y - 0.2), V2(r, y), V2(0, y)], segments: 96, seamTile: 2.4, material: mat), Xform())
        }
        m.add(Prim.lathe([V2(0, -0.2), V2(9, -0.2), V2(9, 0), V2(0, 0)], segments: 96, seamTile: 2.4, material: "concrete.sealed-dark"), Xform())
        let paint: MaterialKey = "metal.painted:E6E6E6"
        let diag = (size.x * size.x + size.y * size.y).squareRoot() * 0.5
        let ang = atan2(size.y, size.x) * 180 / .pi
        for s: Float in [-1, 1] {
            m.add(cuboid(V3(diag, 0.004, lineWidth), material: paint), Xform(translation: V3(0, 0.002, 0), rotation: simd_quatf(degrees: s * ang, axis: .up)))
        }
        m.add(cuboid(V3(size.x - 4, 0.004, lineWidth), material: paint), Xform(translation: V3(0, 0.002, 0)))
        // Drive lane line parallel to the ramp travel axis (-Z), beside the landing zone.
        m.add(cuboid(V3(lineWidth, 0.004, size.y - 4), material: paint), Xform(translation: V3(laneX, 0.002, 0)))
        return LODModel(m)
    }
}
