import simd
import Foundation

/// Fuel tank, medium: 1.25 m stack tank, 2.0 m tall. Brushed aluminum barrel with weld beads, painted skirts with
/// stringers, steel stack rings with bolt circles, fill port and placard.
public struct FuelTankM: RealAsset {
    public static let id = "fuel-tank-m"
    public static let summary = "Liquid fuel tank, 1.25 m by 2 m: brushed aluminum barrel with weld seams, stringers, stack rings top and bottom, fill port."
    public static let tags = ["prop", "aerospace", "metal", "container"]
    public static let budget = 10000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 12, distance: 1.0, studio: true)

    /// Tank diameter in meters.
    public var diameter: Float = 1.25
    /// Tank height in meters, stack ring to stack ring.
    public var height: Float = 2.0
    /// Barrel skin.
    public var barrel: MaterialKey = "metal.aluminum-brushed"
    /// Skirt paint.
    public var skirt: MaterialKey = "metal.painted:F2F2F0"
    /// Roll-pattern stripe paint.
    public var stripe: MaterialKey = "metal.powdercoat:1C1C1E"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        fuelTankLOD(radius: diameter / 2, height: height, stripes: false, barrel: barrel, skirt: skirt, stripe: stripe, seed: seed)
    }
}
