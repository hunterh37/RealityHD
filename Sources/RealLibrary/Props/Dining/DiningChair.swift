import simd
import Foundation

/// Slat-back wooden dining chair, 47 x 92 x 55 cm, seat at 46 cm: raked rear posts carrying a top rail and
/// four bowed slats, a solid seat with a rounded front edge, tapered front legs, apron rails with dowel pegs,
/// side and front stretchers and black felt-pad glides.
public struct DiningChair: RealAsset {
    public static let id = "dining-chair"
    public static let summary = "Slat-back wooden dining chair: raked rear posts, four bowed slats, solid seat, tapered legs, stretchers."
    public static let tags = ["prop", "floorplan", "dining", "furniture", "wood", "interior"]
    public static let budget = 6000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 14, distance: 1.0, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.47, 0.92, 0.55)
    /// Frame wood.
    public var wood: MaterialKey = "wood.beech-stained"
    /// Seat wood (a shade darker, more worn).
    public var seatWood: MaterialKey = "wood.beech-stained:C99E68"
    /// Dowel end-grain.
    public var endGrain: MaterialKey = "wood.endgrain"
    /// Glide material.
    public var felt: MaterialKey = "plastic.black"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [model(seed: seed, detail: true), model(seed: seed, detail: false)], switchDistances: [4])
    }

    func model(seed: UInt64, detail: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = size.x, H = size.y
        let seatTop: Float = 0.46, seatT: Float = 0.03
        let fx = W / 2 - 0.0195, fz: Float = 0.257          // front leg centre
        let rx: Float = 0.2                                // rear post centre x
        func postZ(_ y: Float) -> Float { y <= seatTop ? -0.218 - 0.004 * y / seatTop : -0.222 - 0.03 * (y - seatTop) / (H - seatTop) }
        // Front legs: tapered, grain along the leg.
        for s: Float in [-1, 1] {
            let path = [V3(s * fx, 0, fz), V3(s * fx, 0.15, fz), V3(s * fx, 0.3, fz), V3(s * fx, seatTop - seatT, fz)]
            m.add(Prim.sweep(Shape2D.roundedRect(0.036, 0.036, radius: 0.004, segments: 1), along: path, up: V3(0, 0, 1),
                             scales: [0.72, 0.82, 0.92, 1], caps: true, grainAlongPath: true, material: wood))
        }
        // Rear posts: raked, rising to the top rail.
        for s: Float in [-1, 1] {
            let ys: [Float] = [0, 0.15, 0.3, seatTop, 0.6, 0.76, H - 0.014]
            let path = ys.map { V3(s * rx, $0, postZ($0)) }
            m.add(Prim.sweep(Shape2D.roundedRect(0.034, 0.03, radius: 0.004, segments: 1), along: path, up: V3(0, 0, 1),
                             scales: [0.72, 0.8, 0.9, 1, 1, 1, 0.92], caps: true, grainAlongPath: true, material: wood))
        }
        // Seat: solid board with a rounded front edge and a slight dish.
        let seatW = W - 0.02, seatD: Float = 0.485, seatZ: Float = 0.0375
        // Two glued boards, the left one worn lighter.
        let halfW = (seatW - 0.002) / 2
        for (i, sx) in ([-1, 1] as [Float]).enumerated() {
            var board = Prim.roundedBox(V3(halfW, seatT, seatD), radius: 0.006, bevelSegments: 3, material: i == 0 ? "wood.beech-stained:D6B27C" : seatWood)
            board.deform { p in
                let fxn = (p.x + sx * halfW / 2) / (seatW / 2), fzn = p.z / (seatD / 2)
                return p - V3(0, (p.y > 0 ? 1 : 0.3) * 0.004 * max(0, 1 - fxn * fxn) * max(0, 1 - fzn * fzn), 0)
            }
            m.add(board, Xform(translation: V3(sx * (halfW / 2 + 0.001), seatTop - seatT / 2, seatZ)))
        }
        // Aprons under the seat, with dowel pegs through the legs.
        let aprY = seatTop - seatT - 0.03
        m.add(Prim.roundedBox(V3(2 * fx - 0.036, 0.055, 0.02), radius: 0.004, bevelSegments: 1, material: wood), Xform(translation: V3(0, aprY, fz)))
        m.add(Prim.roundedBox(V3(2 * rx - 0.034, 0.055, 0.02), radius: 0.004, bevelSegments: 1, material: wood), Xform(translation: V3(0, aprY, postZ(aprY))))
        for s: Float in [-1, 1] {
            let z0 = postZ(aprY), len = fz - z0
            m.add(Prim.roundedBox(V3(0.02, 0.055, len), radius: 0.004, bevelSegments: 1, material: wood),
                  Xform(translation: V3(s * (fx + rx) / 2, aprY, (fz + z0) / 2)))
            if detail {
                for (px, pz) in [(s * fx, fz), (s * rx, postZ(aprY))] {
                    m.add(Prim.cylinder(radius: 0.0045, height: 0.002, bevel: 0.0005, segments: 8, bevelSegments: 1, material: endGrain),
                          Xform(translation: V3(px + s * 0.018, aprY + 0.01, pz), rotation: simd_quatf(degrees: -s * 90, axis: V3(0, 0, 1))))
                }
            }
        }
        // Stretchers: H-frame low on the legs.
        for s: Float in [-1, 1] {
            let z0 = postZ(0.17)
            m.add(Prim.sweep(Shape2D.circle(0.011, segments: 8), along: [V3(s * fx, 0.17, fz), V3(s * rx, 0.17, z0)], caps: true, grainAlongPath: true, material: wood))
        }
        m.add(Prim.sweep(Shape2D.circle(0.0105, segments: 8), along: [V3(-fx, 0.2, fz), V3(fx, 0.2, fz)], caps: true, grainAlongPath: true, material: wood))
        // Back: top rail and four bowed slats between the posts.
        let slats: [(y: Float, h: Float)] = [(0.575, 0.06), (0.655, 0.06), (0.735, 0.06), (0.805, 0.06)]
        for (i, sl) in slats.enumerated() {
            let half = rx - 0.012
            let pts = (0...10).map { k -> V3 in
                let x = -half + 2 * half * Float(k) / 10
                return V3(x, sl.y, postZ(sl.y) - 0.016 * (1 - pow(x / half, 2)) + 0.004)
            }
            // Slat section: tall and thin, tilted with the rake.
            m.add(Prim.sweep(Shape2D.roundedRect(sl.h, 0.012, radius: 0.003, segments: 1), along: pts, up: V3(0, 1, 0), caps: true, grainAlongPath: true,
                             material: i == 3 ? wood : wood))
        }
        let topPts = (0...12).map { k -> V3 in
            let x = -rx + 2 * rx * Float(k) / 12
            return V3(x, H - 0.045, postZ(H - 0.045) - 0.014 * (1 - pow(x / rx, 2)) + 0.002)
        }
        m.add(Prim.sweep(Shape2D.roundedRect(0.085, 0.022, radius: 0.007, segments: 2), along: topPts, up: V3(0, 1, 0), caps: true, grainAlongPath: true, material: wood))
        // Through pegs where the slats and top rail enter the posts.
        if detail {
            for s in [-1, 1] as [Float] {
                for y in slats.map({ $0.y }) + [H - 0.045] {
                    m.add(Prim.cylinder(radius: 0.0045, height: 0.0025, bevel: 0.0005, segments: 8, bevelSegments: 1, material: endGrain),
                          Xform(translation: V3(s * (rx + 0.017), y, postZ(y)), rotation: simd_quatf(degrees: -s * 90, axis: V3(0, 0, 1))))
                }
            }
        }
        // Felt glides.
        for (x, z) in [(fx, fz), (-fx, fz), (rx, postZ(0)), (-rx, postZ(0))] {
            m.add(Prim.cylinder(radius: 0.014, height: 0.004, bevel: 0.001, segments: 10, bevelSegments: 1, material: felt),
                  Xform(translation: V3(x, 0, z + rng.float(-0.001...0.001))))
        }
        groundAO(&m, height: 0.15, floor: 0.5)
        return m
    }
}
