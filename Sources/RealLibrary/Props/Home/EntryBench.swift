import simd
import Foundation

/// Entry shoe storage bench, 110 x 45 x 38 cm: a diamond-tufted linen cushion on a seat board, two cut-out
/// end panels with foot blocks, two slatted shoe shelves, front and rear rails and bolted joints.
public struct EntryBench: RealAsset {
    public static let id = "entry-bench"
    public static let summary = "Entry shoe storage bench, 1.1 m: tufted cushion seat, cut-out end panels, two slatted shoe shelves."
    public static let tags = ["prop", "floorplan", "home", "furniture", "wood", "fabric", "interior"]
    public static let budget = 7000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 20, distance: 1.1, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(1.1, 0.45, 0.38)
    /// Frame wood.
    public var wood: MaterialKey = "wood.beech-stained:D6B27C"
    /// Cushion fabric.
    public var fabric: MaterialKey = "fabric.linen:6E7B6B"
    /// Bolt metal.
    public var metal: MaterialKey = "metal.brushed-nickel"
    /// Number of slats per shelf.
    public var slatCount = 6
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [model(seed: seed, detail: true), model(seed: seed, detail: false)], switchDistances: [4])
    }

    func model(seed: UInt64, detail: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = size.x, D = size.z
        let panelT: Float = 0.025, seatBoardT: Float = 0.022, cushT: Float = 0.045
        let boardTop = size.y - cushT, panelH = boardTop - seatBoardT
        // End panels with foot blocks.
        let hd = D / 2
        let outline = Shape2D.rounded([V2(-hd, 0), V2(-hd + 0.05, 0), V2(-hd + 0.05, 0.045), V2(hd - 0.05, 0.045), V2(hd - 0.05, 0), V2(hd, 0),
                                       V2(hd, panelH), V2(-hd, panelH)], radius: 0.006, segments: 1)
        for s: Float in [-1, 1] {
            m.add(Prim.extrude(outline, depth: panelT, bevel: 0.003, bevelSegments: 1, material: wood),
                  Xform(translation: V3(s * (W / 2 - panelT / 2), 0, 0), rotation: simd_quatf(degrees: 90, axis: .up)))
        }
        // Seat board.
        m.add(Prim.roundedBox(V3(W, seatBoardT, D), radius: 0.005, bevelSegments: 2, material: wood), Xform(translation: V3(0, boardTop - seatBoardT / 2, 0)))
        // Front and rear rails under the seat.
        let innerW = W - 2 * panelT
        for z in [-(D / 2 - 0.02), D / 2 - 0.02] as [Float] {
            m.add(Prim.roundedBox(V3(innerW, 0.05, 0.016), radius: 0.003, bevelSegments: 1, material: wood),
                  Xform(translation: V3(0, boardTop - seatBoardT - 0.025, z)))
        }
        // Two slatted shelves.
        let n = slatCount, span = D - 0.05, pitch = span / Float(n), slatW = pitch - 0.012
        for y in [0.125, 0.26] as [Float] {
            // Side cleats carrying the slats.
            for s: Float in [-1, 1] {
                m.add(Prim.roundedBox(V3(D - 0.06, 0.016, 0.02), radius: 0.002, bevelSegments: 1, material: wood),
                      Xform(translation: V3(s * (innerW / 2 - 0.008), y - 0.014, 0), rotation: simd_quatf(degrees: 90, axis: .up)))
            }
            for i in 0..<n {
                let z = -span / 2 + pitch * (Float(i) + 0.5)
                m.add(Prim.roundedBox(V3(innerW - 0.002, 0.014, slatW), radius: 0.002, bevelSegments: 1, material: wood), Xform(translation: V3(rng.float(-0.0015...0.0015), y, z)))
            }
        }
        // Cushion: board, tufted top, piping.
        let cw = W - 0.04, cd = D - 0.04
        m.add(Prim.roundedBox(V3(cw, cushT - 0.01, cd), radius: 0.014, bevelSegments: 3, material: fabric), Xform(translation: V3(0, boardTop + (cushT - 0.01) / 2, 0)))
        let (panel, pts) = tuftedPanel(width: cw - 0.05, height: cd - 0.05, spacing: V2(0.2, 0.13), puff: 0.014, edgeTuck: 0.03,
                                       cell: detail ? 0.045 : 0.07, material: fabric)
        let tx = Xform(translation: V3(0, size.y - 0.0125, 0), rotation: simd_quatf(degrees: -90, axis: V3(1, 0, 0)))
        m.add(panel, tx)
        if detail {
            buttons(&m, pts, tx, radius: 0.009, material: fabric)
            let ring = Shape2D.roundedRect(cw - 0.004, cd - 0.004, radius: 0.02, segments: 3).map { V3($0.x, boardTop + 0.003, -$0.y) }
            m.add(Prim.sweep(Shape2D.circle(0.0035, segments: 5), along: ring, closedPath: true, caps: false, material: fabric))
            let top = Shape2D.roundedRect(cw - 0.004, cd - 0.004, radius: 0.02, segments: 3).map { V3($0.x, size.y - 0.012, -$0.y) }
            m.add(Prim.sweep(Shape2D.circle(0.0045, segments: 5), along: top, closedPath: true, caps: false, material: fabric))
            // Bolts through the end panels.
            for s: Float in [-1, 1] {
                for (y, z) in [(boardTop - seatBoardT - 0.025, D / 2 - 0.02), (boardTop - seatBoardT - 0.025, -(D / 2 - 0.02)), (0.125, 0.0), (0.26, 0.0)] as [(Float, Float)] {
                    hexBolt(&m, at: V3(s * (W / 2 - 0.0035), y, z), normal: V3(s, 0, 0), size: 0.011, material: metal)
                }
            }
        }
        groundAO(&m, height: 0.14, floor: 0.5)
        return m
    }
}
