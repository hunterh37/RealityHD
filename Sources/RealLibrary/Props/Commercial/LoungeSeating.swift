import simd
import Foundation

/// Lobby lounge seating, 2.4 m wide: a three-seat low-back sofa in grey-green fabric (1.92 m) on a walnut plinth with tapered walnut feet, three loose seat cushions with piping and a sitting sag, three back cushions made of four channel pillows each, one upholstered arm slab on the left, a rust accent cushion leaning in the left corner and a 0.44 m round walnut-top side table on brushed-nickel legs beside the open right end. Back at -Z, seats face +Z.
public struct LoungeSeating: RealAsset {
    public static let id = "lounge-seating"
    public static let summary = "Lounge seating, 2.4 m: three-seat low-back sofa with wood plinth, accent cushion and round side table."
    public static let tags = ["prop", "floorplan", "commercial", "living", "furniture", "fabric", "wood", "interior"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 16, distance: 4.0, studio: true)

    /// Overall size in meters (x width including the side table, y height, z depth).
    public var size = V3(2.4, 0.8, 0.9)
    /// Sofa upholstery.
    public var fabric: MaterialKey = "fabric.upholstery:7E8A8F"
    /// Slightly more worn seat cushions.
    public var seatFabric: MaterialKey = "fabric.upholstery:788387"
    /// Plinth, feet and table top.
    public var wood: MaterialKey = "wood.walnut"
    /// Table legs.
    public var nickel: MaterialKey = "metal.brushed-nickel"
    /// Accent cushion.
    public var accent: MaterialKey = "fabric.canvas:B4623A"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [model(seed: seed, detail: true), model(seed: seed, detail: false)], switchDistances: [5])
    }

    func model(seed: UInt64, detail: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let bs = detail ? 2 : 1
        func box(_ sz: V3, _ c: V3, _ key: MaterialKey, r: Float = 0.02) {
            m.add(Prim.roundedBox(sz, radius: min(r, sz.x / 2.2, sz.y / 2.2, sz.z / 2.2), bevelSegments: bs, material: key), Xform(translation: c))
        }
        let D: Float = 0.9
        let x0: Float = -1.2, x1: Float = 0.72            // sofa ends
        let armW: Float = 0.14
        let sofaW = x1 - x0, cx = (x0 + x1) / 2
        let legH: Float = 0.07, plinthTop: Float = 0.15
        // Feet: tapered walnut cones under the plinth corners and the middle.
        for fx in [x0 + 0.1, cx, x1 - 0.1] as [Float] {
            for fz in [-D / 2 + 0.08, D / 2 - 0.08] as [Float] {
                m.add(turned([(0, 0), (0.022, 0), (0.03, legH * 0.5), (0.034, legH), (0, legH)], segments: detail ? 14 : 8, material: wood, grainVertical: true),
                      Xform(translation: V3(fx, 0, fz)))
            }
        }
        // Plinth, set in from the upholstery.
        box(V3(sofaW - 0.05, plinthTop - legH, D - 0.05), V3(cx, (legH + plinthTop) / 2, 0), wood, r: 0.008)
        // Upholstered base under the seat cushions.
        let baseTop: Float = 0.32
        box(V3(sofaW, baseTop - plinthTop, D), V3(cx, (plinthTop + baseTop) / 2, 0), fabric, r: 0.03)
        // Back panel behind the cushions, and the left arm slab.
        let backD: Float = 0.14, backTop: Float = 0.6
        box(V3(sofaW, backTop - plinthTop, backD), V3(cx, (plinthTop + backTop) / 2, -D / 2 + backD / 2), fabric, r: 0.04)
        box(V3(armW, 0.62 - plinthTop, D), V3(x0 + armW / 2, (plinthTop + 0.62) / 2, 0), fabric, r: 0.045)
        // Seam piping up the front of the arm slab and along the base.
        if detail {
            let pipe = [V3(x0 + armW + 0.002, baseTop - 0.004, D / 2 - 0.004), V3(x1 - 0.004, baseTop - 0.004, D / 2 - 0.004)]
            m.add(Prim.tube(pipe, radii: [0.004, 0.004], sides: 6, seamTile: 0.03, material: fabric, capEnd: true))
        }
        // Seat cushions.
        let inner0 = x0 + armW, innerW = x1 - inner0
        let cw = innerW / 3 - 0.006, cd: Float = 0.58, ch: Float = 0.14
        let czc = D / 2 - cd / 2 - 0.003
        for i in 0..<3 {
            let sag = rng.float(0.008...0.02)
            var cushion = Prim.superellipsoid(V3(cw, ch, cd), exponent: 6, subdivisions: detail ? 9 : 5, material: i == 1 ? seatFabric : fabric)
            cushion.deform { p in
                let fx = p.x / (cw / 2), fz = p.z / (cd / 2)
                let dip = max(0, 1 - fx * fx) * max(0, 1 - pow(fz - 0.05, 2)) * (p.y > 0 ? 1 : 0.2)
                return p - V3(0, dip * sag, 0)
            }
            let x = inner0 + (Float(i) + 0.5) * innerW / 3
            m.add(cushion, Xform(translation: V3(x, baseTop + ch / 2 - 0.004, czc), rotation: simd_quatf(degrees: rng.float(-0.8...0.8), axis: V3(0, 1, 0))))
            if detail {
                // Piping around the top edge.
                let k = pow(max(0, 1 - pow((ch / 2 - 0.02) / (ch / 2), 6)), 1.0 / 6)
                let ring = Shape2D.roundedRect(cw * k - 0.002, cd * k - 0.002, radius: 0.05, segments: 4).map { V3(x + $0.x, baseTop + ch - 0.024 - sag * 0.1, czc - $0.y) }
                m.add(Prim.sweep(Shape2D.circle(0.0036, segments: 6), along: ring, closedPath: true, caps: false, material: i == 1 ? seatFabric : fabric))
            }
        }
        // Back cushions: each a row of four channel pillows leaning back a few degrees.
        let bh: Float = 0.4, bd: Float = 0.15
        let lean = simd_quatf(degrees: -9, axis: V3(1, 0, 0))
        for i in 0..<3 {
            let x = inner0 + (Float(i) + 0.5) * innerW / 3
            let pw = (innerW / 3 - 0.006) / 4
            for k in 0..<4 {
                var p = Prim.superellipsoid(V3(pw + 0.012, bh, bd), exponent: 5, subdivisions: detail ? 6 : 4, material: fabric)
                p.deform { q in
                    // Puff the pillow outward in the middle of its height.
                    let t = q.y / (bh / 2)
                    return q + V3(0, 0, (1 - t * t) * 0.012 * (q.z > 0 ? 1 : 0.3))
                }
                let px = x - (innerW / 3 - 0.006) / 2 + pw * (Float(k) + 0.5)
                m.add(p, Xform(translation: V3(px, baseTop + bh / 2 - 0.0, -D / 2 + backD + bd / 2 - 0.03), rotation: lean))
            }
        }
        // Accent cushion leaning on the arm slab in the left seat.
        var throwCushion = Prim.superellipsoid(V3(0.4, 0.4, 0.12), exponent: 3.4, subdivisions: detail ? 9 : 5, material: accent)
        throwCushion.deform { q in
            let fx = q.x / 0.2, fy = q.y / 0.2
            return q + V3(0, 0, (1 - fx * fx) * (1 - fy * fy) * 0.025 * (q.z > 0 ? 1 : -0.4))
        }
        m.add(throwCushion, Xform(translation: V3(inner0 + 0.24, baseTop + 0.28, -0.08 + rng.float(-0.01...0.01)),
                                  rotation: simd_quatf(degrees: -24, axis: V3(1, 0, 0)) * simd_quatf(degrees: 12 + rng.float(-3...3), axis: V3(0, 0, 1)) * simd_quatf(degrees: 45, axis: V3(0, 0, 1))))
        // Side table: walnut top on three tapered nickel legs with a ring stretcher.
        let tx: Float = 0.98, tz: Float = -0.18, tr: Float = 0.22, th: Float = 0.5
        m.add(Prim.cylinder(radius: tr, height: 0.028, bevel: 0.006, segments: detail ? 36 : 16, material: wood),
              Xform(translation: V3(tx, th - 0.028, tz)))
        m.add(Prim.cylinder(radius: tr - 0.03, height: 0.012, bevel: 0.003, segments: detail ? 28 : 12, material: nickel),
              Xform(translation: V3(tx, th - 0.04, tz)))
        for k in 0..<3 {
            let a = Float(k) * 2 * .pi / 3 + 0.4
            let top = V3(tx + cos(a) * (tr - 0.07), th - 0.04, tz + sin(a) * (tr - 0.07))
            let bot = V3(tx + cos(a) * (tr - 0.012), 0.008, tz + sin(a) * (tr - 0.012))
            m.add(Prim.tube([bot, top], radii: [0.0085, 0.0125], sides: detail ? 10 : 6, seamTile: 0.1, material: nickel, capEnd: true))
            m.add(Prim.cylinder(radius: 0.011, height: 0.008, bevel: 0.002, segments: 8, material: "plastic.black:222222"),
                  Xform(translation: V3(bot.x, 0, bot.z)))
        }
        m.add(Prim.torus(major: tr - 0.04, minor: 0.005, segments: detail ? 32 : 14, sides: 6, material: nickel),
              Xform(translation: V3(tx, 0.2, tz)))
        groundAO(&m, height: 0.2, floor: 0.55)
        let bb = m.bounds
        m = m.transformed(Xform(translation: V3(-(bb.min.x + bb.max.x) / 2, -bb.min.y, -(bb.min.z + bb.max.z) / 2)))
        return m
    }
}
