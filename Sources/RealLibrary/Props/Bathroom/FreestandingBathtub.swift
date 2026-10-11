import simd
import Foundation

/// Freestanding slipper bathtub: glossy egg-shaped tub whose back (-X) rises to 0.62 m and slopes down to
/// a 0.46 m foot end, rolled rim, four nickel ball feet, chrome drain with stopper and overflow plate, and a
/// floor-mounted filler column with a gooseneck spout and two lever handles at the +X end.
public struct FreestandingBathtub: RealAsset {
    public static let id = "freestanding-bathtub"
    public static let summary = "Freestanding slipper bathtub: glossy egg-shaped tub with a raised back, nickel feet, chrome drain and overflow, floor-mounted filler column with lever handles."
    public static let tags = ["prop", "floorplan", "bathroom", "plumbing", "ceramic", "interior"]
    public static let budget = 7500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 26, distance: 3.4, studio: true)

    /// Overall size in meters (x length, y height, z width).
    public var size = V3(1.7, 0.62, 0.8)
    public var shell: MaterialKey = "ceramic.vitreous"
    public var chrome: MaterialKey = "metal.chrome"
    /// Rim height at the raised back (-X) and at the foot end.
    public var backRim: Float = 0.612
    public var footRim: Float = 0.46
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        func make(_ lod: Int) -> Model {
            var m = Model(name: Self.id)
            let hi = lod == 0
            let N = hi ? 56 : 28
            let L: Float = 1.55, a = L / 2, b = size.z / 2
            let x0: Float = -0.85 + a                       // tub center x
            let yb: Float = 0.07, floorY: Float = 0.13
            func rimAt(_ x: Float) -> Float { footRim + (backRim - footRim) * (1 - smoothstep(-0.85, 0.2, x)) }
            func widthAt(_ x: Float) -> Float { 1 - 0.11 * smoothstep(-0.35, 0.75, x) }
            /// Plan point of the unit superellipse at index i, inset by `inset` meters, with the egg width taper.
            func plan(_ i: Int, _ inset: Float) -> V2 {
                let t = Float(i) / Float(N) * 2 * .pi
                let c = cos(t), s = sin(t)
                let e: Float = 2.5
                let ux = (c < 0 ? -1 : 1) * pow(abs(c), 2 / e), uz = (s < 0 ? -1 : 1) * pow(abs(s), 2 / e)
                let ax = max(0.01, a - inset), bz = max(0.01, b - inset)
                let x = x0 + ux * ax
                return V2(x, -uz * bz * widthAt(x))        // +angle toward -z, counter-clockwise from above
            }
            func ring(inset: Float, frac: Float, base: Float) -> [V3] {
                (0..<N).map { i in
                    let p = plan(i, inset)
                    return V3(p.x, base + frac * (rimAt(p.x) - base), p.y)
                }
            }
            // Outer shell bottom to rim, then the rim top and the dish down to the floor.
            let outer: [[V3]] = [ring(inset: 0.24, frac: 0, base: yb), ring(inset: 0.11, frac: 0.1, base: yb), ring(inset: 0.035, frac: 0.28, base: yb),
                                  ring(inset: 0.0, frac: 0.55, base: yb), ring(inset: 0.0, frac: 0.88, base: yb), ring(inset: 0.007, frac: 0.97, base: yb),
                                  ring(inset: 0.02, frac: 1.0, base: yb)]
            let rimInner: [[V3]] = [ring(inset: 0.06, frac: 1.0, base: yb), ring(inset: 0.068, frac: 0.97, base: yb)]
            let dish: [[V3]] = [ring(inset: 0.085, frac: 0.78, base: floorY), ring(inset: 0.14, frac: 0.42, base: floorY), ring(inset: 0.22, frac: 0.14, base: floorY),
                                ring(inset: 0.3, frac: 0.0, base: floorY)]
            m.add(Prim.loft(outer, capStart: true, material: shell))
            m.add(Prim.loft([outer.last!] + rimInner + dish, capEnd: true, material: shell))
            // Rolled rim bead.
            m.add(Prim.sweep(Shape2D.circle(0.016, ry: 0.0085, segments: hi ? 10 : 6), along: ring(inset: 0.04, frac: 1.0, base: yb).map { $0 + V3(0, -0.0006, 0) }, up: V3(0, 1, 0), closedPath: true, material: shell))
            // Feet: four nickel ball feet under the shell.
            for (fx, fz) in [(x0 - 0.46, -0.2), (x0 - 0.46, 0.2), (x0 + 0.46, -0.16), (x0 + 0.46, 0.16)] as [(Float, Float)] {
                m.add(Prim.lathe([V2(0.001, 0), V2(0.03, 0), V2(0.036, 0.008), V2(0.026, 0.026), V2(0.03, 0.045), V2(0.02, 0.07), V2(0.001, 0.0705)], segments: hi ? 16 : 8, seamTile: 0.05, material: "metal.brushed-nickel"),
                      Xform(translation: V3(fx, 0, fz)))
            }
            // Drain and overflow near the foot end.
            let dx = x0 + 0.42
            m.add(Prim.lathe([V2(0.0345, 0.0003), V2(0.068, 0.0003), V2(0.07, 0.0007), V2(0.0345, 0.0007)], segments: hi ? 28 : 12, seamTile: 0.05, material: "plastic.matte:CDBFA3"), Xform(translation: V3(dx, floorY, 0)))
            m.add(Prim.lathe([V2(0.001, 0.0005), V2(0.034, 0.0005), V2(0.037, 0.002), V2(0.032, 0.0045), V2(0.001, 0.0045)], segments: hi ? 22 : 10, seamTile: 0.05, material: chrome), Xform(translation: V3(dx, floorY, 0)))
            m.add(Prim.lathe([V2(0.001, 0.0045), V2(0.022, 0.0045), V2(0.024, 0.0075), V2(0.001, 0.0085)], segments: hi ? 18 : 8, seamTile: 0.05, material: "metal.stainless"), Xform(translation: V3(dx, floorY, 0)))
            // Overflow plate on the inner wall of the foot end (wall normal faces -X, tilted).
            let ovp = plan(N / 2 + 0, 0.14)
            _ = ovp
            let ox = x0 + a - 0.15, oy: Float = 0.33
            m.add(Prim.lathe([V2(0.001, 0), V2(0.034, 0), V2(0.034, 0.003), V2(0.028, 0.006), V2(0.001, 0.0065)], segments: hi ? 20 : 10, seamTile: 0.05, material: chrome),
                  Xform(translation: V3(ox, oy, 0), rotation: simd_quatf(degrees: 90 + 22, axis: V3(0, 0, 1))))
            // Floor-mounted filler column at the foot end.
            let fx: Float = 0.78
            m.add(Prim.lathe([V2(0.001, 0), V2(0.06, 0), V2(0.062, 0.004), V2(0.056, 0.012), V2(0.034, 0.022), V2(0.024, 0.04), V2(0.001, 0.04)], segments: hi ? 24 : 12, seamTile: 0.05, material: chrome),
                  Xform(translation: V3(fx, 0, 0)))
            let column = [V3(fx, 0.035, 0), V3(fx, 0.25, 0), V3(fx, 0.45, 0), V3(fx - 0.004, 0.55, 0), V3(fx - 0.04, 0.598, 0), V3(fx - 0.1, 0.6, 0), V3(fx - 0.16, 0.566, 0), V3(fx - 0.19, 0.52, 0)]
            let path = catmull(column, per: hi ? 5 : 2)
            let np = path.count
            m.add(Prim.tube(path, radii: (0..<np).map { i in 0.0185 - 0.004 * Float(i) / Float(np - 1) }, sides: hi ? 18 : 8, seamTile: 0.05, material: chrome))
            m.add(Prim.cylinder(radius: 0.0155, height: 0.01, bevel: 0.0015, segments: hi ? 16 : 8, material: chrome), Xform(translation: path[np - 1] + V3(0, -0.006, 0)))
            // Two lever handles on a hub block.
            m.add(Prim.cylinder(radius: 0.026, height: 0.05, bevel: 0.006, segments: hi ? 20 : 10, material: chrome), Xform(translation: V3(fx, 0.3, 0)))
            for sz: Float in [-1, 1] {
                let h = catmull([V3(fx, 0.325, sz * 0.02), V3(fx, 0.335, sz * 0.045), V3(fx, 0.34, sz * 0.085), V3(fx, 0.33, sz * 0.115)], per: hi ? 4 : 2)
                m.add(Prim.tube(h, radii: h.indices.map { i in i < h.count - 2 ? Float(0.0065) : Float(0.0088) }, sides: hi ? 12 : 6, seamTile: 0.03, material: chrome))
            }
            // Caulk-free floor contact: dark rubber pads under the feet.
            groundAO(&m, height: 0.25, floor: 0.6)
            return m
        }
        return LODModel(levels: [make(0), make(1)], switchDistances: [6])
    }
}
