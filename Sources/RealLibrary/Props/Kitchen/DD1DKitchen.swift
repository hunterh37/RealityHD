import simd
import Foundation

/// Shared construction helpers for the DD1D countertop appliance batch.
enum DD1DKitchen {
    static let dark: MaterialKey = "plastic.matte:1C1C1E"
    static let rubber: MaterialKey = "rubber.silicone-gray"

    /// Rounded box with centre c.
    static func box(_ m: inout Model, _ s: V3, _ c: V3, _ mat: MaterialKey, r: Float = 0.003) {
        m.add(Prim.roundedBox(s, radius: min(r, s.min() * 0.45), bevelSegments: 1, material: mat), Xform(translation: c))
    }

    /// Cylinder along +Y standing on base centre c.
    static func cyl(_ m: inout Model, r: Float, h: Float, at c: V3, _ mat: MaterialKey, bevel: Float = 0.002, seg: Int = 32) {
        m.add(Prim.cylinder(radius: r, height: h, bevel: min(bevel, r * 0.4, h * 0.4), segments: seg, bevelSegments: 2, material: mat), Xform(translation: c))
    }

    /// Cylinder along +Z starting at c (front-facing knobs, posts).
    static func cylZ(_ m: inout Model, r: Float, len: Float, at c: V3, _ mat: MaterialKey, bevel: Float = 0.0015, seg: Int = 20) {
        m.add(Prim.cylinder(radius: r, height: len, bevel: min(bevel, r * 0.4, len * 0.4), segments: seg, bevelSegments: 2, material: mat),
              Xform(translation: c, rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
    }

    /// Cylinder along +X from c.
    static func cylX(_ m: inout Model, r: Float, len: Float, at c: V3, _ mat: MaterialKey, bevel: Float = 0.0015, seg: Int = 16) {
        m.add(Prim.cylinder(radius: r, height: len, bevel: min(bevel, r * 0.4, len * 0.4), segments: seg, bevelSegments: 2, material: mat),
              Xform(translation: c, rotation: simd_quatf(degrees: -90, axis: V3(0, 0, 1))))
    }

    /// Revolved body about +Y at c; profile of (radius, y).
    static func lathe(_ m: inout Model, _ p: [(Float, Float)], at c: V3, _ mat: MaterialKey, seg: Int = 40) {
        m.add(Prim.lathe(p.map { V2($0.0, $0.1) }, segments: seg, seamTile: 0.2, material: mat), Xform(translation: c))
    }

    /// Four rubber feet under a w x d footprint. Returns foot height.
    @discardableResult
    static func feet(_ m: inout Model, w: Float, d: Float, inset: Float = 0.025, h: Float = 0.010, r: Float = 0.010, zc: Float = 0) -> Float {
        for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
            cyl(&m, r: r, h: h, at: V3(sx * (w / 2 - inset), 0, zc + sz * (d / 2 - inset)), rubber, bevel: 0.003, seg: 14)
        } }
        return h
    }

    /// Front-facing control knob: skirt, grip, pointer mark. c is on the front face.
    static func dial(_ m: inout Model, at c: V3, r: Float, mat: MaterialKey, mark: MaterialKey = "plastic.white") {
        cylZ(&m, r: r * 1.18, len: 0.002, at: c, "plastic.matte:2A2A2C", seg: 24)
        cylZ(&m, r: r, len: 0.011, at: c + V3(0, 0, 0.001), mat, bevel: 0.003, seg: 20)
        box(&m, V3(r * 0.16, r * 0.62, 0.0015), c + V3(0, r * 0.45, 0.0118), mark, r: 0.0004)
    }

    /// Row of small keys along X on a front face.
    static func keys(_ m: inout Model, n: Int, at c: V3, pitch: Float, size: V3, mat: MaterialKey) {
        for i in 0..<n { box(&m, size, c + V3((Float(i) - Float(n - 1) / 2) * pitch, 0, size.z / 2), mat, r: 0.002) }
    }

    /// Small lit display window with a lit segment strip.
    static func display(_ m: inout Model, at c: V3, w: Float, h: Float) {
        box(&m, V3(w, h, 0.002), c + V3(0, 0, 0.001), "screen.off", r: 0.001)
        box(&m, V3(w * 0.7, h * 0.4, 0.0015), c + V3(0, 0, 0.0027), "emissive.led-red", r: 0.0005)
    }

    /// Thin dark panel gap (seam) so shells read as assembled parts.
    static func seam(_ m: inout Model, _ s: V3, _ c: V3) {
        m.add(cuboid(s, material: dark), Xform(translation: c))
    }

    /// Two-post bar handle along X: bar at standoff from the face point c, facing +Z.
    static func barHandle(_ m: inout Model, at c: V3, length: Float, standoff: Float, r: Float, mat: MaterialKey) {
        cylX(&m, r: r, len: length, at: c + V3(-length / 2, 0, standoff), mat, bevel: r * 0.4)
        for sx: Float in [-1, 1] {
            cylZ(&m, r: r * 0.85, len: standoff, at: c + V3(sx * (length / 2 - r * 2), 0, 0), mat, bevel: 0.001, seg: 12)
        }
    }

    /// Power cord leaving the back at height y, curving to the floor and out.
    static func cord(_ m: inout Model, from p: V3, to q: V3) {
        let mid = V3((p.x + q.x) / 2, 0.004, (p.z + q.z) / 2 - 0.004)
        let path = catmull([p, p + V3(0, 0, -0.012), mid, q], per: 5)
        m.add(Prim.tube(path, radii: path.map { _ in 0.0035 }, sides: 8, seamTile: 0.05, material: "rubber.silicone-gray", capEnd: true), Xform())
        cylZ(&m, r: 0.006, len: 0.02, at: p + V3(0, 0, -0.018), dark, seg: 12)
    }

    /// Ring of vent slots (thin dark boxes) on a +Z / -Z face; z is the face plane.
    static func vents(_ m: inout Model, n: Int, at c: V3, pitch: Float, size: V3) {
        for i in 0..<n { seam(&m, size, c + V3((Float(i) - Float(n - 1) / 2) * pitch, 0, 0)) }
    }

    /// Flattened organic blob (spill, crumb, splatter) centred at c.
    static func blob(_ m: inout Model, _ c: V3, _ s: V3, _ mat: MaterialKey, yaw: Float = 0) {
        m.add(Prim.superellipsoid(s, exponent: 2.4, subdivisions: 2, material: mat),
              Xform(translation: c, rotation: simd_quatf(degrees: yaw, axis: V3(0, 1, 0))))
    }

    /// Vertical drip on a +Z facing wall: head blob plus a thin run of length len hanging down.
    static func drip(_ m: inout Model, at c: V3, w: Float, len: Float, _ mat: MaterialKey) {
        m.add(Prim.superellipsoid(V3(w, len, 0.0024), exponent: 2.2, subdivisions: 2, material: mat), Xform(translation: c - V3(0, len / 2, 0)))
        m.add(Prim.superellipsoid(V3(w * 2.2, w * 2.2, 0.003), exponent: 2, subdivisions: 2, material: mat), Xform(translation: c))
    }
}
