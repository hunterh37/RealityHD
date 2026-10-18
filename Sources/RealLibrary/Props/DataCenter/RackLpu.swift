import simd
import Foundation

/// LPU rack: Inference hall, slate powder coat 2A2D33, slotted doors, dense tray faces, new-install. Parts: frame, slotted doors, dense compute trays, manifold, PDUs, casters.
public struct RackLpu: RealArticulated {
    public static let id = "rack-lpu"
    public static let summary = "Air-cooled LPU inference rack: slate powder coat, slotted perforated doors, 18 dense tray slots, U rails, PDUs, TOR switch."
    public static let tags = ["prop", "articulated"]
    public static let budget = 15000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Front faces +Z.
    public var size = V3(0.6, 2.4, 1.4)
    /// Number of named 1U tray slots (up to 18).
    public var trayCount = 18
    /// Front door opening angle in the default state (degrees).
    public var frontDoorAngle: Float = 0
    /// Rear door opening angle in the default state (degrees).
    public var rearDoorAngle: Float = 0
    /// Rack frame and door frame material.
    public var frameMaterial: MaterialKey = "metal.powdercoat:2A2D33"
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        var base = RackAi1mw()
        base.size = size
        base.trayCount = trayCount
        base.frontDoorAngle = frontDoorAngle
        base.rearDoorAngle = rearDoorAngle
        base.frameMaterial = frameMaterial
        base.trayFinCount = 6
        base.trayPortColumns = 3
        base.slottedDoors = true
        base.liquidCooled = false
        var r = base.rig(seed: seed)
        r.name = Self.id
        return r
    }
}
