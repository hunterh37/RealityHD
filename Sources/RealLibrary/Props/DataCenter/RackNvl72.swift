import simd
import Foundation

/// 2025 NVL72-class liquid-cooled rack: compute trays top and bottom, switch trays in the middle, rear manifold and NVLink spine. Generic, no branding.
public struct RackNvl72: RealArticulated {
    public static let id = "rack-nvl72-2025"
    public static let summary = "72-GPU liquid-cooled rack: 18 compute trays above and below nine NVLink switch trays, power shelves, rear coolant manifolds and NVLink cable spine."
    public static let tags = ["prop", "articulated"]
    public static let budget = 15000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Front faces +Z.
    public var size = V3(0.6, 2.3, 1.2)
    /// Front door opening angle in the default state (degrees).
    public var frontDoorAngle: Float = 0
    /// Rear door opening angle in the default state (degrees).
    public var rearDoorAngle: Float = 0
    /// Rack frame and door frame material.
    public var frameMaterial: MaterialKey = "metal.powdercoat:1B1D21"
    /// Compute and switch tray face material.
    public var trayMaterial: MaterialKey = "metal.powdercoat:3A3D42"
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        var base = RackAi1mw()
        base.size = size
        base.frontDoorAngle = frontDoorAngle
        base.rearDoorAngle = rearDoorAngle
        base.frameMaterial = frameMaterial
        base.trayFaceMaterial = trayMaterial
        base.trayFinCount = 1
        base.trayPortColumns = 0
        base.nvlinkSpine = true
        base.hasFrontDoor = false
        var r = base.rig(seed: seed)
        r.name = Self.id
        return r
    }
}
