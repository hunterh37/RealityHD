import simd
import Foundation

/// U-shaped staircase with a half landing, 2.1 x 3.0 x 3.6 m footprint and rise. Eleven risers climb 2.06 m along
/// -Z beside a 0.1 m stair well, a 2.1 x 1.0 m oak landing turns the run, and five more climb back along +Z
/// (16 risers of 187.5 mm in all). Wall skirts on the outer sides, cut stringers, balusters and an oak handrail
/// on the well side, corner newel carried to the floor. Origin bottom center.
public struct UShapedStaircase: RealAsset {
    public static let id = "u-shaped-staircase"
    public static let summary = "U-shaped staircase, 16 risers, 3.0 m rise, half landing: oak treads and landing, painted risers, wall and cut stringers, balusters, handrail."
    public static let tags = ["structure", "floorplan", "interior", "stair", "wood"]
    public static let budget = 12_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 38, elevation: 22, distance: 1.2, studio: true)

    /// Width of each flight (m).
    public var width: Float = 1.0
    /// Stair well between the flights (m).
    public var well: Float = 0.1
    /// Risers in the first flight up to the landing.
    public var lowerRisers = 11
    /// Tread going (m).
    public var going: Float = 0.26
    /// Landing depth along Z (m).
    public var landingDepth: Float = 1.0
    public var railMaterial: MaterialKey = "wood.oak:9A6E40"
    public init() {}

    func model(lod: Int, seed: UInt64) -> Model {
        var m = Model(name: Self.id)
        let n = 16, R: Float = 3.0 / Float(n)
        let n1 = lowerRisers, n2 = n - n1
        let W = width, g = going
        let uL = Float(n1 - 1) * g
        let landY = Float(n1) * R
        let xc = W / 2 + well / 2
        var a = StairFlight()
        a.treadSeg = 1; a.width = W; a.risers = n1; a.rise = R; a.going = g; a.stub = 0; a.lod = lod; a.railMat = railMaterial
        a.newelEnd = true; a.endU = uL + 0.057; a.endBaseY = 0
        var b = StairFlight()
        b.treadSeg = 1; b.width = W; b.risers = n2; b.rise = R; b.going = g; b.stub = 0; b.lod = lod; b.railMat = railMaterial
        b.newelEnd = true; b.endU = Float(n2 - 1) * g + b.nose - 0.057; b.endBaseY = Float(n2 - 1) * R - 0.01
        m.add(a.build(seed: seed), Xform(translation: V3(-xc, 0, 0)))
        m.add(b.build(seed: seed &+ 1), Xform(translation: V3(xc, landY, -uL - 0.06), rotation: simd_quatf(degrees: 180, axis: .up)))
        let half = W + well / 2
        var land = StairLanding(x0: -half, x1: half, zFront: -uL, zBack: -uL - landingDepth, topY: landY)
        land.wallLeft = true; land.wallRight = true; land.wallBack = true; land.frontFasciaX = (-well / 2)...half; land.lod = lod
        m.add(land.build())
        return m
    }

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [model(lod: 0, seed: seed).centeredXZ(), model(lod: 1, seed: seed).centeredXZ()], switchDistances: [8])
    }
}
