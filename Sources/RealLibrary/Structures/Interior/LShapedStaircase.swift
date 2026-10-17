import simd
import Foundation

/// L-shaped staircase with a quarter landing, 2.0 x 3.0 x 3.2 m footprint and rise. Ten risers climb 1.875 m along
/// -Z to a square oak landing; six more turn right along +X to the upper floor (16 risers of 187.5 mm in all, wall
/// stringers on the outer sides, cut stringers, balusters and an oak handrail on the inside of the turn, a corner
/// newel carried to the floor). The 0.8 m flight width is what the 16 treads of 0.25 m or more allow in this
/// footprint. Origin bottom center.
public struct LShapedStaircase: RealAsset {
    public static let id = "l-shaped-staircase"
    public static let summary = "L-shaped staircase, 16 risers, 3.0 m rise, quarter landing: oak treads and landing, painted risers, wall and cut stringers, balusters, handrail."
    public static let tags = ["structure", "floorplan", "interior", "stair", "wood"]
    public static let budget = 12_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 40, elevation: 22, distance: 1.25, studio: true)

    /// Flight width (m).
    public var width: Float = 0.8
    /// Risers in the first flight up to the landing; the rest turn right.
    public var lowerRisers = 10
    /// Going of the second flight (m).
    public var upperGoing: Float = 0.25
    /// Total depth along Z (m).
    public var depth: Float = 3.2
    public var railMaterial: MaterialKey = "wood.oak:9A6E40"
    public init() {}

    func model(lod: Int, seed: UInt64) -> Model {
        var m = Model(name: Self.id)
        let n = 16, R: Float = 3.0 / Float(n)
        let n1 = lowerRisers, n2 = n - n1
        let W = width
        let g1 = (depth - W) / Float(n1 - 1)
        let uL = Float(n1 - 1) * g1                         // landing nosing line
        let landY = Float(n1) * R
        var f1 = StairFlight()
        f1.treadSeg = 1; f1.width = W; f1.risers = n1; f1.rise = R; f1.going = g1; f1.stub = 0; f1.lod = lod; f1.railMat = railMaterial
        f1.newelEnd = true; f1.endU = uL + 0.057; f1.endBaseY = 0
        f1.endPostTopY = landY + R + f1.railHeight + 0.06
        var f2 = StairFlight()
        f2.treadSeg = 1; f2.width = W; f2.risers = n2; f2.rise = R; f2.going = upperGoing; f2.stub = 0; f2.lod = lod; f2.railMat = railMaterial
        f2.newelStart = false; f2.railStartU = 0.003; f2.shortenFirst = false
        f2.newelEnd = true; f2.endU = Float(n2 - 1) * upperGoing + f2.nose - 0.057; f2.endBaseY = Float(n2 - 1) * R - 0.01

        // Plan: flight 1 left edge at x0; landing x0...xe; flight 2 climbs +X from xe - 0.06.
        let x0: Float = -(W + (Float(n2 - 1) * upperGoing + f2.nose + f2.riserT + 0.012 - 0.06)) / 2
        let xe = x0 + W
        let c1 = x0 + W / 2
        m.add(f1.build(seed: seed), Xform(translation: V3(c1, 0, 0)))
        let zc = -(uL + W / 2)
        m.add(f2.build(seed: seed &+ 1), Xform(translation: V3(xe - 0.06, landY, zc), rotation: simd_quatf(degrees: -90, axis: .up)))
        var land = StairLanding(x0: x0, x1: xe, zFront: -uL, zBack: -uL - W, topY: landY)
        land.wallLeft = true; land.wallBack = true; land.wallRight = false; land.fasciaRight = true; land.lod = lod
        m.add(land.build())
        return m
    }

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [model(lod: 0, seed: seed).centeredXZ(), model(lod: 1, seed: seed).centeredXZ()], switchDistances: [8])
    }
}
