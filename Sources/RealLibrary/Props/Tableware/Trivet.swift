import simd
import Foundation

/// Cast iron trivet, 20 cm across and under 2 cm high: a round openwork casting with an outer rim, a small hub ring, eight
/// S-curved spokes, eight scroll curls between them and three feet under the rim. A casting parting line runs round the
/// rim's outside, seasoned iron shows rust-worn rim tops, and one foot is chipped short.
public struct Trivet: RealAsset {
    public static let id = "trivet"
    public static let summary = "Cast iron trivet: round openwork frame with scrolled spokes, raised rim, three feet, casting seam, rust-worn edges, one chipped foot."
    public static let tags = ["prop", "interior", "tableware", "metal"]
    public static let budget = 12500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 50, distance: 0.8, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.20, 0.02, 0.20)
    /// Casting height above the feet in meters.
    public var castHeight: Float = 0.012
    /// Seasoned cast iron.
    public var iron: MaterialKey = "metal.cast-iron-seasoned"
    /// Worn iron on edges and the hub.
    public var ironWorn: MaterialKey = "metal.cast-iron-worn"
    /// Rust patches.
    public var rust: MaterialKey = "metal.rust-grime"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [model(seed: seed, detail: true), model(seed: seed, detail: false)], switchDistances: [3])
    }

    func model(seed: UInt64, detail: Bool) -> Model {
        var m = Model(name: Self.id)
        let ch = castHeight, footH: Float = size.y - ch - 0.0003, Rm: Float = size.x / 2 - 0.00425
        let circle = { (r: Float, y: Float, n: Int) in (0..<n).map { k -> V3 in let a = Float(k) / Float(n) * 2 * .pi; return V3(cos(a) * r, y, sin(a) * r) } }
        // Outer rim, hub ring and hub boss.
        m.add(DD1HTable.wall(path: circle(Rm, footH, detail ? 72 : 36), h: ch, t: 0.0085, radius: 0.0022, material: iron))
        m.add(DD1HTable.wall(path: circle(0.026, footH + 0.001, detail ? 40 : 24), h: ch - 0.002, t: 0.0065, radius: 0.0018, material: iron))
        m.add(Prim.cylinder(radius: 0.0125, height: ch - 0.001, bevel: 0.0025, segments: detail ? 24 : 14, bevelSegments: 2, material: ironWorn),
              Xform(translation: V3(0, footH + 0.0005, 0)))
        // Spokes: S-curves from hub ring to rim.
        let n = 8
        func pol(_ r: Float, _ a: Float, _ y: Float) -> V3 { V3(cos(a) * r, y, sin(a) * r) }
        let sp = Shape2D.roundedRect(ch - 0.002, 0.0055, radius: 0.0014, segments: 2).map { V2($0.x + (ch - 0.002) / 2, $0.y) }
        // Short bars tie the hub boss to the hub ring.
        for k in 0..<4 {
            let a = (Float(k) / 4 + 0.125) * 2 * .pi
            m.add(Prim.sweep(sp, along: [pol(0.009, a, footH + 0.001), pol(0.0235, a, footH + 0.001)], up: .up, caps: true, material: iron))
        }
        for k in 0..<n {
            let a = Float(k) / Float(n) * 2 * .pi
            let pts = [pol(0.0235, a, footH + 0.001), pol(0.045, a + 0.16, footH + 0.001), pol(0.068, a - 0.12, footH + 0.001), pol(Rm - 0.002, a, footH + 0.001)]
            m.add(Prim.sweep(sp, along: catmull(pts, per: detail ? 6 : 3), up: .up, caps: false, material: iron))
            // Scroll curl springing off the spoke toward the next one, alternating hand.
            let hand: Float = k % 2 == 0 ? 1 : -1
            let start = pol(0.058, a + 0.02, footH + 0.001 + (ch - 0.002) / 2)
            let tang = V3(-sin(a), 0, cos(a)) * hand
            let outward = V3(cos(a), 0, sin(a))
            let c0 = start + tang * 0.0105
            let ang0 = atan2(start.z - c0.z, start.x - c0.x)
            let steps = detail ? 36 : 18
            var curl: [V3] = [], radii: [Float] = []
            for s in 0...steps {
                let f = Float(s) / Float(steps)
                let r = 0.0105 - 0.0078 * f
                let an = ang0 + hand * f * 1.55 * 2 * .pi
                curl.append(V3(c0.x + cos(an) * r, start.y, c0.z + sin(an) * r))
                radii.append(0.0027 - 0.0009 * f)
            }
            _ = outward
            m.add(Prim.tube(curl, radii: radii, sides: detail ? 6 : 4, seamTile: 0.02, material: iron))
        }
        // Parting line round the rim.
        m.add(Prim.torus(major: Rm + 0.00425, minor: 0.0004, segments: detail ? 72 : 36, sides: 4, material: ironWorn),
              Xform(translation: V3(0, footH + ch / 2, 0)))
        // Feet: two intact, one chipped short and canted.
        for k in 0..<3 {
            let a = (90 + Float(k) * 120) * .pi / 180
            let p = V3(cos(a) * Rm, 0, sin(a) * Rm)
            if k == 2 {
                m.add(Prim.cylinder(radius: 0.0078, height: footH * 0.62, bevel: 0.0018, segments: 12, bevelSegments: 2, material: ironWorn),
                      Xform(translation: p, rotation: simd_quatf(degrees: 9, axis: V3(cos(a + .pi / 2), 0, sin(a + .pi / 2)))))
                m.add(Prim.superellipsoid(V3(0.007, 0.0028, 0.0055), exponent: 2.5, subdivisions: 3, material: rust),
                      Xform(translation: p + V3(0.003, footH * 0.62 + 0.0004, -0.002)))
            } else {
                m.add(Prim.cylinder(radius: 0.0078, height: footH + 0.0006, bevel: 0.002, segments: detail ? 14 : 10, bevelSegments: 2, material: iron),
                      Xform(translation: p))
            }
        }
        if detail {
            // Rust patches on the rim top.
            for (deg, len) in [(Float(25), Float(0.016)), (Float(190), Float(0.012)), (Float(305), Float(0.02))] {
                let a = deg * .pi / 180
                m.add(DD1HTable.decal(center: V2(cos(a) * Rm, sin(a) * Rm), rx: len, rz: 0.0034, yaw: a + .pi / 2, lift: 0.0004, rings: 2, material: rust,
                                      height: { _, _ in footH + ch }))
            }
        }
        groundAO(&m, height: 0.02)
        return m
    }
}
