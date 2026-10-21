import simd
import Foundation

/// Range distance sign: club range yardage marker, white board with black block digits (public var yards, default 20) and a YD bar, weathered cedar post. Parts: post, board, digits, post cap, bolts.
public struct DistanceSign: RealAsset {
    public static let id = "distance-sign"
    public static let summary = "Range distance marker: painted pine board with raised yardage digits on a cedar post, param yards."
    public static let tags = ["prop", "archery", "outdoor", "sign", "wood"]
    public static let budget = 10000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.6, 1.4, 0.1)
    /// Yardage shown on the board (1 to 3 digits).
    public var yards = 20
    /// Digit height in meters.
    public var digitHeight: Float = 0.24
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let cedar: MaterialKey = "wood.cedar-weathered", paint: MaterialKey = "wood.barn-white", zinc: MaterialKey = "metal.galvanized"
        let black: MaterialKey = "plastic.black"
        let postW: Float = 0.10, postD: Float = 0.06, postH: Float = 1.38
        let boardW: Float = 0.60, boardH: Float = 0.50, boardT: Float = 0.018, boardY: Float = 0.84
        let boardZ = postD / 2 - 0.001 + boardT / 2
        // Post: grain runs vertically (plank along X rotated upright).
        let vert = simd_quatf(degrees: 90, axis: V3(0, 0, 1))
        let post = plank(postH, postD, postW, bevel: 0.004, material: cedar)
        m.add(post, Xform(translation: V3(0, postH / 2, 0), rotation: vert).jittered(&rng))
        // Post cap: sloped cedar cap with galvanized flashing.
        m.add(plank(0.13, 0.09, 0.012, bevel: 0.004, material: cedar), Xform(translation: V3(0, postH + 0.008, 0)).jittered(&rng))
        m.add(Prim.roundedBox(V3(0.135, 0.002, 0.095), radius: 0.0008, bevelSegments: 1, material: zinc), Xform(translation: V3(0, postH + 0.0145, 0)))
        // Board: two painted planks edge to edge with a hairline seam, along X (grain on U).
        for k in 0..<2 {
            let h = boardH / 2 - 0.0015
            let sy = boardY + (k == 0 ? h / 2 : boardH - h / 2)
            m.add(plank(boardW, h, boardT, bevel: 0.0025, material: paint),
                  Xform(translation: V3(0, sy, boardZ), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        }
        // Raised black seven-segment digits.
        let digits = Array(String(max(0, min(999, yards)))).compactMap { Int(String($0)) }
        let segMap: [[Bool]] = [  // a b c d e f g
            [true, true, true, true, true, true, false], [false, true, true, false, false, false, false],
            [true, true, false, true, true, false, true], [true, true, true, true, false, false, true],
            [false, true, true, false, false, true, true], [true, false, true, true, false, true, true],
            [true, false, true, true, true, true, true], [true, true, true, false, false, false, false],
            [true, true, true, true, true, true, true], [true, true, true, true, false, true, true]]
        let dh = digitHeight, dw = dh * 0.55, st = dh * 0.15, gap = dh * 0.22, tz: Float = 0.005
        let total = Float(digits.count) * dw + Float(digits.count - 1) * gap
        let cy = boardY + boardH * 0.58, zf = boardZ + boardT / 2 + tz / 2 - 0.0008
        for (n, d) in digits.enumerated() {
            let cx = -total / 2 + dw / 2 + Float(n) * (dw + gap)
            let segs: [(Float, Float, Float, Float)] = [   // dx, dy, w, h
                (0, dh / 2 - st / 2, dw, st), (dw / 2 - st / 2, dh / 4, st, dh / 2 - st / 2), (dw / 2 - st / 2, -dh / 4, st, dh / 2 - st / 2),
                (0, -dh / 2 + st / 2, dw, st), (-dw / 2 + st / 2, -dh / 4, st, dh / 2 - st / 2), (-dw / 2 + st / 2, dh / 4, st, dh / 2 - st / 2),
                (0, 0, dw - 2 * st + 0.004, st)]
            for (i, sg) in segs.enumerated() where segMap[d][i] {
                m.add(Prim.roundedBox(V3(sg.2, sg.3, tz), radius: 0.0012, bevelSegments: 1, material: black),
                      Xform(translation: V3(cx + sg.0, cy + sg.1, zf)))
            }
        }
        // YD bar under the digits with a Y and D picked out in black.
        let by = boardY + 0.095
        m.add(Prim.roundedBox(V3(0.22, 0.012, tz), radius: 0.0012, bevelSegments: 1, material: black), Xform(translation: V3(0, by, zf)))
        // Bolts through the board into the post.
        for y in [boardY + 0.035, boardY + boardH - 0.035] {
            hexBolt(&m, at: V3(0, y, boardZ + boardT / 2 - 0.0005), normal: V3(0, 0, 1), size: 0.011, material: zinc)
        }
        groundAO(&m)
        return LODModel(m)
    }
}
