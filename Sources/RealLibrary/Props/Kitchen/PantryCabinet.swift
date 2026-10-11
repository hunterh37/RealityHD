import simd
import Foundation

/// Tall 24 in pantry cabinet: painted plywood carcass on a recessed toe kick, two pairs of five-piece
/// shaker doors (lower and upper, full overlay with 3 mm reveals) with recessed panels, and vertical
/// brushed-nickel bar pulls at the meeting stiles.
public struct PantryCabinet: RealAsset {
    public static let id = "pantry-cabinet"
    public static let summary = "Tall 24 in pantry cabinet: painted shaker doors in upper and lower pairs, nickel bar pulls, recessed toe kick, face reveals."
    public static let tags = ["prop", "floorplan", "kitchen", "furniture", "wood", "metal", "interior"]
    public static let budget = 7000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 8, distance: 3.4, studio: true)

    /// Overall size in meters including the pulls (x width, y height, z depth).
    public var size = V3(0.6, 2.2, 0.6)
    /// Paint (sRGB hex tint on `wood.painted-shaker`).
    public var color: UInt32 = 0xE9E6DD
    /// Height where the lower door pair ends.
    public var splitY: Float = 1.12
    public var hardware: MaterialKey = "metal.brushed-nickel"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let W = size.x, H = size.y, D = size.z
        let paint: MaterialKey = "wood.painted-shaker:" + String(format: "%06X", color)
        let dark: MaterialKey = "plastic.matte:1C1C1E"
        let doorT: Float = 0.019, kick: Float = 0.1, recess: Float = 0.07
        let pullOut: Float = 0.022
        let zDoor = D / 2 - pullOut - 0.0045          // door face
        let zBack = -D / 2
        let side: Float = 0.018
        let reveal: Float = 0.003

        func level(_ hi: Bool) -> Model {
            var m = Model(name: Self.id)
            let zl = zDoor - doorT - zBack, zc = (zBack + zDoor - doorT) / 2
            // Carcass.
            for sx: Float in [-1, 1] {
                m.add(Prim.roundedBox(V3(side, H - kick, zl), radius: 0.002, bevelSegments: 1, material: paint), Xform(translation: V3(sx * (W / 2 - side / 2), kick + (H - kick) / 2, zc)))
            }
            m.add(Prim.roundedBox(V3(W, side, zl), radius: 0.002, bevelSegments: 1, material: paint), Xform(translation: V3(0, H - side / 2, zc)))
            m.add(cuboid(V3(W - 2 * side, H - kick - side, 0.01), material: "wood.plywood"), Xform(translation: V3(0, kick + (H - kick - side) / 2, zBack + 0.005)))
            m.add(cuboid(V3(W - 2 * side, side, zl), material: "wood.plywood"), Xform(translation: V3(0, kick + side / 2, zc)))
            // Side panel recess (applied shaker panel) and a light-rail crown at the top front.
            if hi { for sx: Float in [-1, 1] {
                m.add(Prim.roundedBox(V3(0.006, H - kick - 0.2, zl - 0.12), radius: 0.002, bevelSegments: 1, material: paint), Xform(translation: V3(sx * (W / 2), kick + (H - kick) / 2, zc)))
            }}
            m.add(Prim.roundedBox(V3(W, 0.03, 0.02), radius: 0.004, bevelSegments: 2, material: paint), Xform(translation: V3(0, H - 0.015, zDoor + 0.002 - 0.0)))
            // Dark interior seen through the reveals.
            var cav = cuboid(V3(W - 2 * side, H - kick - 2 * side, zl - 0.02), material: dark).flipped()
            cav = cav.transformed(Xform(translation: V3(0, (kick + side + H - side) / 2, zc)))
            m.add(cav)
            // Toe kick, recessed.
            m.add(Prim.roundedBox(V3(W - 0.02, kick, 0.018), radius: 0.002, bevelSegments: 1, material: dark), Xform(translation: V3(0, kick / 2, zDoor - doorT - recess)))
            // Doors: lower pair, upper pair.
            var di = 0
            for (lo, hiY) in [(kick + reveal, splitY - reveal / 2), (splitY + reveal / 2, H)] {
                let dh = hiY - lo
                let dw = (W - 3 * reveal) / 2
                for sx: Float in [-1, 1] {
                    let cx = sx * (reveal / 2 + dw / 2)
                    let jit = hi ? rng.float(-0.0006...0.0006) : 0
                    let dc = V3(cx, (lo + hiY) / 2 + jit, zDoor - doorT / 2)
                    let st: Float = 0.055
                    // Five-piece frame: two stiles, two rails, recessed panel.
                    for ex: Float in [-1, 1] {
                        m.add(Prim.roundedBox(V3(st, dh, doorT), radius: 0.0025, bevelSegments: 1, material: paint), Xform(translation: dc + V3(ex * (dw / 2 - st / 2), 0, 0)))
                    }
                    for ey: Float in [-1, 1] {
                        m.add(Prim.roundedBox(V3(dw - 2 * st + 0.002, st, doorT), radius: 0.0025, bevelSegments: 1, material: paint), Xform(translation: dc + V3(0, ey * (dh / 2 - st / 2), 0)))
                    }
                    m.add(cuboid(V3(dw - 2 * st + 0.004, dh - 2 * st + 0.004, 0.008), material: paint), Xform(translation: dc + V3(0, 0, -doorT / 2 + 0.004)))
                    if hi {
                        // Shaker panel inner bead: a thin frame proud of the recessed panel.
                        let bw = dw - 2 * st + 0.004, bh = dh - 2 * st + 0.004
                        m.add(cuboid(V3(bw, 0.003, 0.003), material: paint), Xform(translation: dc + V3(0, bh / 2 - 0.0015, -doorT / 2 + 0.0095)))
                        m.add(cuboid(V3(bw, 0.003, 0.003), material: paint), Xform(translation: dc + V3(0, -bh / 2 + 0.0015, -doorT / 2 + 0.0095)))
                    }
                    // Vertical bar pull at the meeting stile, 0.15 m, placed near the pair's inner edge and mid height.
                    let px = sx * (reveal / 2 + 0.03)
                    let py = di < 2 ? hiY - 0.14 : lo + 0.14
                    var pull = barHandle(length: 0.128, standoff: pullOut, radius: 0.0045, overhang: 0.014, material: hardware)
                    pull = pull.transformed(Xform(translation: V3(px, py, zDoor), rotation: simd_quatf(degrees: 90, axis: V3(0, 0, 1))))
                    if hi { m.add(pull) } else { m.add(cuboid(V3(0.01, 0.17, 0.01), material: hardware), Xform(translation: V3(px, py, zDoor + pullOut))) }
                    di += 1
                }
            }
            groundAO(&m, height: 0.2, floor: 0.7)
            return m
        }
        return LODModel(levels: [level(true), level(false)], switchDistances: [5])
    }
}
