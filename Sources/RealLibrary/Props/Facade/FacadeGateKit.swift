import simd
import Foundation

/// Helpers for gate, pier and fence props (lib-n6b). Same units as `FA`; pieces are authored with
/// the run along X, height along Y and thickness along Z, then seated with `FC.place`.
enum FG {
    static let tau: Float = 2 * .pi

    /// Square or flat bar between two axis-aligned points.
    static func bar(_ m: inout Model, from a: V3, to b: V3, w: Float, d: Float, _ mat: MaterialKey, r: Float = 0.002) {
        let c = (a + b) / 2
        let s = V3(max(abs(b.x - a.x), w), max(abs(b.y - a.y), w), max(abs(b.z - a.z), d))
        FA.box(&m, s, c, mat, r: r)
    }
    /// Round picket rod along Y.
    static func picket(_ m: inout Model, x: Float, y0: Float, y1: Float, z: Float, r: Float, _ mat: MaterialKey, sides: Int = 10) {
        FA.rod(&m, V3(x, y0, z), V3(x, y1, z), r: r, mat, sides: sides)
    }
    /// Flat spiral scroll in the XY plane: radius shrinks from r0 to r0 * 0.22 over `turns`.
    static func scroll(_ m: inout Model, c: V3, r0: Float, turns: Float, start: Float, dir: Float, wire: Float, _ mat: MaterialKey, tail: V3? = nil) {
        var pts: [V3] = []
        let n = Int(turns * 9) + 2
        for i in 0...n {
            let t = Float(i) / Float(n)
            let a = (start + dir * t * turns * 360) * .pi / 180
            let r = r0 * (1 - 0.78 * t)
            pts.append(c + V3(cos(a) * r, sin(a) * r, 0))
        }
        if let t = tail { pts.insert(t, at: 0) }
        FA.path(&m, pts, r: wire, mat, sides: 6)
        FC.bead(&m, r: wire * 1.5, at: pts.last!, mat)
    }
    /// Crossed spear head: two perpendicular leaf blades on a collar and ferrule ball.
    static func spear(_ m: inout Model, x: Float, y: Float, z: Float, h: Float, w: Float, _ mat: MaterialKey) {
        let leaf: [V2] = [V2(0, 0), V2(w * 0.5, h * 0.3), V2(w * 0.42, h * 0.5), V2(0, h), V2(-w * 0.42, h * 0.5), V2(-w * 0.5, h * 0.3)]
        for k in 0..<2 {
            m.add(Prim.extrude(leaf, depth: 0.008, bevel: 0, bevelSegments: 1, material: mat),
                  Xform(translation: V3(x, y, z), rotation: FA.q(Float(k) * 90, FA.Y)))
        }
        FC.bead(&m, r: w * 0.32, at: V3(x, y, z), mat, sub: 1)
    }
    /// Turned ball-and-neck finial on a post top.
    static func ballFinial(_ m: inout Model, at c: V3, r: Float, _ mat: MaterialKey) {
        let prof: [V2] = [V2(0.0001, 0), V2(r * 0.9, 0), V2(r * 0.9, 0.006), V2(r * 0.55, 0.014), V2(r * 0.55, 0.03),
                          V2(r * 0.8, 0.036), V2(r * 0.8, 0.042), V2(r * 0.4, 0.05)]
        m.add(Prim.lathe(prof, segments: 20, seamTile: 0.2, material: mat), Xform(translation: c))
        let cy = 0.05 + r * 0.9
        m.add(Prim.superellipsoid(V3(repeating: r * 1.8), exponent: 2, subdivisions: 10, material: mat), Xform(translation: c + V3(0, cy, 0)))
    }
    /// Strap hinge: flat strap along X from the pintle eye, with rivets.
    static func strapHinge(_ m: inout Model, at c: V3, length: Float, dirX: Float, w: Float, _ mat: MaterialKey) {
        FA.box(&m, V3(length, w, 0.006), c + V3(dirX * length / 2, 0, 0), mat, r: 0.0015)
        FA.cylZ(&m, r: w * 0.55, h: w * 1.2, at: c + V3(0, 0, -w * 0.6), mat, bevel: 0.0015, segments: 14)
        for i in 1...3 {
            FC.bead(&m, r: 0.004, at: c + V3(dirX * length * Float(i) / 3.6, 0, 0.0065), mat, sub: 2)
        }
    }
    /// Square frustum (plinth chamfer, cap pyramid) from half-width w0 at y0 to w1 at y1, centered on x/z.
    static func frustum(_ m: inout Model, w0: Float, w1: Float, y0: Float, y1: Float, d0: Float? = nil, d1: Float? = nil,
                        at c: V3 = .zero, _ mat: MaterialKey, capTop: Bool = true) {
        let a = Prim.ring(Shape2D.rect(w0, d0 ?? w0), y: y0), b = Prim.ring(Shape2D.rect(w1, d1 ?? w1), y: y1)
        m.add(Prim.loft([a, b], capStart: true, capEnd: capTop, material: mat), Xform(translation: c))
    }
    /// Turned urn finial profile (r, y) standing on y = 0, total height h.
    static func urn(_ m: inout Model, at c: V3, r: Float, h: Float, _ mat: MaterialKey) {
        let k = h
        let prof: [V2] = [V2(0.0001, 0), V2(r * 0.7, 0), V2(r * 0.7, k * 0.05), V2(r * 0.45, k * 0.1), V2(r * 0.45, k * 0.18),
                          V2(r * 0.85, k * 0.3), V2(r, k * 0.45), V2(r * 0.9, k * 0.6), V2(r * 0.55, k * 0.72),
                          V2(r * 0.6, k * 0.76), V2(r * 0.3, k * 0.8), V2(r * 0.22, k * 0.86), V2(r * 0.34, k * 0.92), V2(0.0001, k)]
        m.add(Prim.lathe(prof, segments: 20, seamTile: 0.2, material: mat), Xform(translation: c))
    }
    /// Seats the model with its lowest point on y = 0 and bounds centered on X and Z.
    static func seat(_ m: Model) -> Model { FC.place(m) }
}

extension SIMD3 where Scalar == Float {
    /// Rotates the vector by a quaternion (rotating a face-local offset around the Y axis).
    func rotated(by q: simd_quatf) -> SIMD3<Float> { q.act(self) }
}

extension FG {
    /// Unbeveled thin slab (joint slot, streak, stain patch): 12 triangles.
    static func slab(_ m: inout Model, _ size: V3, _ c: V3, _ mat: MaterialKey, rot: simd_quatf = .identity) {
        m.add(Prim.extrude(Shape2D.rect(size.x, size.y), depth: size.z, bevel: 0, bevelSegments: 1, material: mat),
              Xform(translation: c, rotation: rot))
    }
    /// Axis-aligned slab placed on a pier face: `face` 0...3 rotates around Y, `u` along the face, `y` height,
    /// `out` the offset from the pier centre along the face normal.
    static func faceSlab(_ m: inout Model, face: Int, size: V3, u: Float, y: Float, out: Float, _ mat: MaterialKey) {
        let rot = FA.q(Float(face) * 90, FA.Y)
        slab(&m, size, V3(u, y, out).rotated(by: rot), mat, rot: rot)
    }
}

extension FG {
    /// Flat-profile board bent along an arc in the XY plane at depth z: segmental arch with half-width `a`,
    /// rise `s`, springing at `y0`; board `thick` along Z and `depth` radially. Returns the centreline points.
    @discardableResult
    static func archBoard(_ m: inout Model, a: Float, rise s: Float, y0: Float, z: Float, thick: Float, depth: Float,
                          _ mat: MaterialKey, steps: Int = 14) -> [V3] {
        let R = (a * a + s * s) / (2 * s), cy = y0 + s - R, t0 = asin(a / R)
        var pts: [V3] = []
        for i in 0...steps {
            let t = -t0 + 2 * t0 * Float(i) / Float(steps)
            pts.append(V3(R * sin(t), cy + R * cos(t), z))
        }
        m.add(Prim.sweep(Shape2D.rect(thick, depth), along: pts, up: V3(0, 0, 1), caps: true, grainAlongPath: true, material: mat))
        return pts
    }
    /// Pointed picket outline (flat, extruded along Z) standing on y = 0.
    static func pointedPicket(_ m: inout Model, x: Float, y: Float, w: Float, h: Float, tip: Float, z: Float, thick: Float, _ mat: MaterialKey) {
        let o: [V2] = [V2(-w / 2, 0), V2(w / 2, 0), V2(w / 2, h), V2(0, h + tip), V2(-w / 2, h)]
        m.add(Prim.extrude(o, depth: thick, bevel: 0.0015, bevelSegments: 1, material: mat), Xform(translation: V3(x, y, z)))
    }
    /// Diagonal lattice of thin laths clipped to a rectangle in the YZ plane at x (z0..z1, y0..y1).
    static func lattice(_ m: inout Model, x: Float, z0: Float, z1: Float, y0: Float, y1: Float, pitch: Float, lath: Float,
                        _ mat: MaterialKey) {
        let w = z1 - z0, h = y1 - y0
        for dir in [-1, 1] as [Float] {
            let layer: Float = dir > 0 ? 0 : lath * 1.1
            var c: Float = dir > 0 ? -h : 0
            let cEnd: Float = dir > 0 ? w : w + h
            while c < cEnd {
                // dir > 0: z = z0 + c + (y - y0); dir < 0: z = z0 + c - (y - y0).
                let lo: Float = dir > 0 ? max(0, -c) : max(0, c - w)
                let hi: Float = dir > 0 ? min(h, w - c) : min(h, c)
                if hi - lo > 0.02 {
                    let ya = y0 + lo, yb = y0 + hi
                    let za = z0 + c + dir * lo, zb = z0 + c + dir * hi
                    let len = ((yb - ya) * (yb - ya) + (zb - za) * (zb - za)).squareRoot()
                    let ang = atan2(zb - za, yb - ya) * 180 / .pi
                    FG.slab(&m, V3(lath, len, lath * 0.8), V3(x + layer, (ya + yb) / 2, (za + zb) / 2), mat, rot: FA.q(-ang, FA.X))
                }
                c += pitch
            }
        }
    }
}

extension FG {
    /// Vertical board outline extruded along Z with the grain running along Y (UVs swapped), dog-eared top corners.
    static func verticalBoard(_ m: inout Model, x: Float, y0: Float, y1: Float, w: Float, z: Float, thick: Float,
                              ear: Float = 0, _ mat: MaterialKey, round: Float = 0) {
        var o: [V2]
        if ear > 0 {
            o = [V2(-w / 2, 0), V2(w / 2, 0), V2(w / 2, y1 - y0 - ear), V2(w / 2 - ear, y1 - y0), V2(-w / 2 + ear, y1 - y0), V2(-w / 2, y1 - y0 - ear)]
        } else {
            o = Shape2D.rect(w, y1 - y0).map { V2($0.x, $0.y + (y1 - y0) / 2) }
        }
        var s = Prim.extrude(o, depth: thick, bevel: 0.0012, bevelSegments: 1, material: mat)
        s.uvs = s.uvs.map { V2($0.y * 1.8, $0.x * 1.8) }
        s.computeTangents()
        m.add(s, Xform(translation: V3(x, y0, z)))
    }
}
