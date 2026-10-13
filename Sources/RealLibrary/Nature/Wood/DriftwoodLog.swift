import simd
import Foundation

/// Flood-stranded sycamore driftwood log, 5 m long, 50 to 28 cm thick: bark stripped by the current to
/// silver-grey checked wood with a few brown bark scraps, snapped top, broken branch stubs, rounded
/// weathered butt. Lies on a gravel bar or wedged in a logjam. 3 LODs.
public struct DriftwoodLog: RealAsset {
    public static let id = "driftwood-log"
    public static let summary = "Driftwood log, 5 m: bark stripped to silver checked wood, brown bark scraps, snapped top, branch stubs, 3 LODs."
    public static let tags = ["nature", "wood", "river"]
    public static let budget = 3_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 22, distance: 0.8)

    public var length: Float = 5
    public var buttDiameter: Float = 0.5
    public var topDiameter: Float = 0.28
    public var branchStubs = 5
    public var wood: MaterialKey = "wood.driftwood"
    public var bark: MaterialKey = "bark.sycamore-lower"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        FallenLog().with {
            $0.length = length; $0.buttDiameter = buttDiameter; $0.topDiameter = topDiameter
            $0.peeled = 0.6; $0.branchStubs = branchStubs; $0.sink = 0.03
            $0.bark = bark; $0.wood = wood; $0.end = "wood.driftwood-end"
        }.build(seed: seed)
    }
}
