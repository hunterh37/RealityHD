import simd
import Foundation

/// French Provincial Juliet balcony, 1.2 m wide and 0.2 m deep, 1.0 m high: a handrail bowed on a half ellipse (round
/// tube with a flat cap), a flat bottom rail, two panels of spiral scrolls (two large tapered spirals, a ring and two curls
/// each), a centre medallion (ring, quatrefoil, gilt boss), plain balusters with collars, and two square end posts with
/// gilt ball finials on wall plates. Black paint is chipped to rust on the rail top and plates, one baluster is a rusty
/// replacement, the bolts bleed rust. Wall plane at z = 0.
public struct JulietBalconyIronScroll: RealAsset {
    public static let id = "juliet-balcony-iron-scroll"
    public static let summary = "French Provincial Juliet balcony, 1.2 m: bowed iron rail with spiral scroll panels, medallion, gilt finials, wall plates."
    public static let tags = ["prop", "architecture", "facade", "trim", "metal"]
    public static let budget = 14500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 8, distance: 1.9)

    /// Rail span in meters.
    public var span: Float = 1.14
    /// Bow depth of the front.
    public var bow: Float = 0.15
    /// Black paint.
    public var iron: MaterialKey = "metal.painted:1E1F23"
    /// Gilding.
    public var gilt: MaterialKey = "metal.gold-leaf"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [make(seed: seed, lite: false), make(seed: seed, lite: true)], switchDistances: [4])
    }

    func make(seed: UInt64, lite: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let hw = span / 2, B = bow
        let sides = lite ? 5 : 6
        func zc(_ x: Float) -> Float { B * max(0, 1 - (x / hw) * (x / hw)).squareRoot() }
        func P(_ x: Float, _ y: Float, _ dz: Float = 0) -> V3 { V3(x, y, zc(x) + dz + 0.03) }
        func bx(_ s: V3, _ c: V3, _ mat: MaterialKey, r: Float = 0.002, rot: simd_quatf = .identity) { FA.box(&m, s, c, mat, r: r, rot: rot) }
        func tube(_ pts: [V3], r0: Float, r1: Float, _ mat: MaterialKey) {
            m.add(Prim.tube(pts, radii: pts.indices.map { r0 + (r1 - r0) * Float($0) / Float(max(1, pts.count - 1)) }, sides: sides, seamTile: 0.15, material: mat, capEnd: true))
        }
        func spiral(_ c: V2, r0: Float, turns: Float, a0: Float, dir: Float, wire: Float = 0.0075) {
            let n = lite ? 10 : 18
            var pts: [V3] = []
            for i in 0...n {
                let t = Float(i) / Float(n)
                let a = (a0 + dir * turns * 360 * t) * .pi / 180
                let r = r0 * (1 - 0.9 * t)
                pts.append(P(c.x + r * cos(a), c.y + r * sin(a)))
            }
            tube(pts, r0: wire, r1: wire * 0.55, iron)
            // Tight curl end: gilt button.
            if !lite, let l = pts.last { m.add(Prim.superellipsoid(V3(repeating: wire * 2.6), exponent: 2, subdivisions: 2, material: gilt), Xform(translation: l)) }
        }
        func ring(_ c: V2, r: Float, wire: Float = 0.0055) {
            let n = lite ? 10 : 18
            var pts: [V3] = []
            for i in 0...n { let a = Float(i) / Float(n) * 2 * .pi; pts.append(P(c.x + r * cos(a), c.y + r * sin(a))) }
            tube(pts, r0: wire, r1: wire, iron)
        }
        func bar(_ x: Float, _ y0: Float, _ y1: Float, r: Float = 0.0065, _ mat: MaterialKey? = nil) {
            FA.rod(&m, P(x, y0), P(x, y1), r: r, mat ?? iron, sides: sides)
        }
        func collar(_ x: Float, _ y: Float, r: Float = 0.0105) {
            m.add(Prim.cylinder(radius: r, height: 0.011, bevel: 0.002, segments: lite ? 6 : 8, bevelSegments: 1, material: iron), Xform(translation: P(x, y - 0.0055)))
        }

        // Rails.
        let topY: Float = 0.95, botY: Float = 0.14
        let nx = lite ? 16 : 30
        let xs = (0...nx).map { -hw + 2 * hw * Float($0) / Float(nx) }
        FA.path(&m, xs.map { P($0, topY) }, r: 0.0165, iron, sides: lite ? 8 : 10)
        let cap: [V2] = [V2(-0.003, -0.027), V2(0.003, -0.027), V2(0.006, -0.02), V2(0.006, 0.02), V2(0.003, 0.027), V2(-0.003, 0.027), V2(-0.006, 0.02), V2(-0.006, -0.02)]
        m.add(Prim.sweep(cap, along: xs.map { P($0, topY + 0.0195) }, up: FA.Y, material: iron))
        let flat: [V2] = [V2(-0.014, -0.006), V2(0.014, -0.006), V2(0.014, 0.006), V2(-0.014, 0.006)]
        m.add(Prim.sweep(flat, along: xs.map { P($0, botY) }, up: FA.Y, material: iron))
        FA.path(&m, xs.map { P($0, botY + 0.03) }, r: 0.0045, iron, sides: 6)

        // Scroll panels.
        for sx: Float in [-1, 1] {
            let c = sx * 0.29
            spiral(V2(c, 0.755), r0: 0.10, turns: 1.2, a0: 90, dir: -sx)
            spiral(V2(c, 0.335), r0: 0.10, turns: 1.2, a0: -90, dir: sx)
            ring(V2(c, 0.545), r: 0.052)
            bar(c, topY - 0.012, 0.86)
            bar(c, botY + 0.012, 0.235)
            bar(c, 0.595, 0.64, r: 0.0055)
            bar(c, 0.45, 0.495, r: 0.0055)
            collar(c, 0.865); collar(c, 0.23)
            spiral(V2(c - 0.152, 0.545), r0: 0.04, turns: 1.1, a0: 0, dir: sx, wire: 0.0055)
            spiral(V2(c + 0.152, 0.545), r0: 0.04, turns: 1.1, a0: 180, dir: -sx, wire: 0.0055)
            // Borders: balusters at the panel edges and in the end bay.
            for x in [sx * 0.475, sx * 0.535, sx * 0.115] {
                let rusty = sx > 0 && x == sx * 0.495 && !lite
                bar(x, botY + 0.005, topY - 0.005, r: 0.0068, rusty ? "metal.rust" : iron)
                collar(x, botY + 0.025); collar(x, topY - 0.03)
                if x == sx * 0.535 || x == sx * 0.475 { m.add(Prim.superellipsoid(V3(0.024, 0.032, 0.024), exponent: 2, subdivisions: 2, material: iron), Xform(translation: P(x, 0.55))) }
            }
        }
        // Centre medallion.
        ring(V2(0, 0.545), r: 0.072, wire: 0.0065)
        if !lite {
            for (dx, dy) in [(0.04 as Float, 0 as Float), (-0.04, 0), (0, 0.04), (0, -0.04)] { ring(V2(dx, 0.545 + dy), r: 0.026, wire: 0.0045) }
        }
        m.add(Prim.superellipsoid(V3(repeating: 0.04), exponent: 2, subdivisions: 3, material: gilt), Xform(translation: P(0, 0.545, 0.004)))
        bar(0, topY - 0.012, 0.62); bar(0, botY + 0.012, 0.47)
        m.add(Prim.superellipsoid(V3(0.032, 0.044, 0.032), exponent: 2, subdivisions: 3, material: gilt), Xform(translation: P(0, 0.80)))
        m.add(Prim.superellipsoid(V3(0.032, 0.044, 0.032), exponent: 2, subdivisions: 3, material: gilt), Xform(translation: P(0, 0.29)))
        collar(0, 0.625); collar(0, 0.465)

        // End posts, plates, finials.
        for sx: Float in [-1, 1] {
            let x = sx * (hw + 0.0)
            bx(V3(0.026, 0.985, 0.026), V3(x, 0.4925, 0.03), iron, r: 0.003)
            bx(V3(0.04, 0.03, 0.04), V3(x, 0.965, 0.03), iron, r: 0.004)
            m.add(Prim.superellipsoid(V3(repeating: 0.044), exponent: 2, subdivisions: 3, material: gilt), Xform(translation: V3(x, 0.985, 0.03)))
            for y in [0.22 as Float, 0.75] {
                bx(V3(0.075, 0.16, 0.010), V3(x, y, 0.005), "metal.painted:2B2C31", r: 0.002)
                for dy: Float in [-0.05, 0.05] { hexBolt(&m, at: V3(x, y + dy, 0.0105), normal: FA.Z, size: 0.014, material: "metal.rust") }
                if !lite { bx(V3(0.008, rng.float(0.05...0.1), 0.0012), V3(x + 0.004, y - 0.1, 0.0106), "metal.rust", r: 0.0003) }
            }
            // Rail ends meet the post.
            bx(V3(0.036, 0.012, 0.036), V3(x, topY, 0.03), iron, r: 0.002)
        }
        // Paint chips to rust on the rail top, rust bloom at the post feet and the bottom rail.
        if !lite {
            for sx: Float in [-1, 1] {
                bx(V3(0.029, 0.16, 0.029), V3(sx * hw, 0.08, 0.03), "metal.rust", r: 0.002)
                bx(V3(0.031, 0.02, 0.031), V3(sx * hw, 0.17, 0.03), "metal.painted:3A2A22", r: 0.002)
            }
            for k in 0..<5 {
                let x = -hw + 0.12 + Float(k) * (span - 0.24) / 4 + rng.float(-0.03...0.03)
                bx(V3(rng.float(0.06...0.12), 0.0035, 0.0125), P(x, botY + 0.0072, 0), "metal.rust", r: 0.001)
            }
            for k in 0..<10 {
                let x = -hw + 0.1 + Float(k) * (span - 0.2) / 9 + rng.float(-0.02...0.02)
                bx(V3(0.07, 0.0018, 0.012), P(x, topY + 0.0198 + 0.0055 + 0.0, 0), "metal.rust", r: 0.0006)
            }
        }

        groundAO(&m, height: 0.08, floor: 0.75)
        return FC.place(m)
    }
}
