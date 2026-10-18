import simd
import Foundation

/// Classic 42U air-cooled rack: light grey powder coat, mesh doors, mixed 1U/2U servers with open fan faces, blanking panels, vertical PDUs.
public struct RackAir42u: RealArticulated {
    public static let id = "rack-air-42u"
    public static let summary = "Classic 42U air-cooled server rack: light-grey frame, mesh doors, mixed 1U/2U servers with visible fans, blanking panels, vertical PDUs, TOR switch."
    public static let tags = ["prop", "articulated"]
    public static let budget = 15000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Front faces +Z.
    public var size = V3(0.6, 2.0, 1.2)
    /// Front door opening angle in the default state (degrees).
    public var frontDoorAngle: Float = 0
    /// Rear door opening angle in the default state (degrees).
    public var rearDoorAngle: Float = 0
    /// Rack frame and door frame material.
    public var frameMaterial: MaterialKey = "metal.powdercoat:B4B7BB"
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        var base = RackAi1mw()
        base.size = size
        base.stackUnits = 42
        base.stackBase = 0.095
        base.baseHeight = 0.09
        base.frontDoorAngle = frontDoorAngle
        base.rearDoorAngle = rearDoorAngle
        base.frameMaterial = frameMaterial
        base.airServers = true
        base.liquidCooled = false
        var r = base.rig(seed: seed)
        r.name = Self.id
        return r
    }
}
