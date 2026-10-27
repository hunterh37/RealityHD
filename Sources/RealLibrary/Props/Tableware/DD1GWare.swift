import simd
import Foundation

/// Shared helpers for the everyday tableware batch: ring-lofted vessels, chips, grains, flat cutlery blanks.
enum DD1GWare {
    static let glaze: MaterialKey = "ceramic.vitreous"
    static let warmGlaze: MaterialKey = "ceramic.vitreous:EFE8D8"
    static let bisque: MaterialKey = "ceramic.bisque:E6E0D2"
    static let fracture: MaterialKey = "ceramic.bisque:D8C8A6"

    struct Station { var inset: Float; var y: Float; var hf: Float = 0 }

    /// Axis-wise inset of a ring outline: each half-extent shrinks by `inset` (clamped).
    static func inset(_ pts: [V2], _ d: Float) -> [V2] {
        var hx: Float = 1e-6, hy: Float = 1e-6
        for p in pts { hx = max(hx, abs(p.x)); hy = max(hy, abs(p.y)) }
        let fx = max(0.03, (hx - d) / hx), fy = max(0.03, (hy - d) / hy)
        return pts.map { V2($0.x * fx, $0.y * fy) }
    }

    /// Skins a closed profile of stations; the outline function gets the height fraction of each station.
    static func loft(_ outline: (Float) -> [V2], _ st: [(Float, Float, Float)], capStart: Bool = false, capEnd: Bool = false,
                     material: MaterialKey) -> Surface {
        let rings = st.map { s -> [V3] in Prim.ring(inset(outline(s.2), s.0), y: s.1) }
        return Prim.loft(rings, capStart: capStart, capEnd: capEnd, material: material)
    }

    static func lathe(_ p: [V2], segs: Int, _ mat: MaterialKey, tile: Float = 0.3) -> Surface {
        Prim.lathe(p, segments: segs, seamTile: tile, material: mat)
    }

    /// Radius of an outer profile at height y (linear interpolation).
    static func radius(_ pts: [V2], _ y: Float) -> Float {
        for i in 1..<pts.count where pts[i].y >= y && pts[i].y > pts[i - 1].y {
            let t = (y - pts[i - 1].y) / (pts[i].y - pts[i - 1].y)
            return pts[i - 1].x + (pts[i].x - pts[i - 1].x) * t
        }
        return pts.last?.x ?? 0
    }

    /// Unglazed contact band of a round foot ring.
    static func footBand(r: Float, w: Float = 0.0013, segs: Int, y: Float = 0) -> Surface {
        lathe([V2(r - w, y - 0.00005), V2(r + w, y - 0.00005), V2(r + w, y + 0.0003), V2(r - w, y + 0.0003), V2(r - w, y - 0.00005)],
              segs: segs, bisque)
    }

    /// Glaze chip: a bisque-coloured fracture patch on a rim.
    static func chip(_ m: inout Model, at p: V3, size s: Float, yaw: Float) {
        m.add(Prim.roundedBox(V3(s * 1.4, min(s * 0.32, 0.0007), s * 0.6), radius: min(s * 0.14, 0.0003), bevelSegments: 1, material: fracture),
              Xform(translation: p, rotation: simd_quatf(degrees: yaw, axis: V3(0, 1, 0))))
    }

    /// Small soft blob (crust, fleck, grain) with planar UVs in metres.
    static func blob(_ size: V3, exponent: Float = 3, subdivisions: Int = 2, material: MaterialKey) -> Surface {
        var g = Prim.superellipsoid(size, exponent: exponent, subdivisions: subdivisions, material: material)
        g.uvs = g.positions.map { V2($0.x, $0.z) }
        g.computeTangents()
        return g
    }

    /// Loose grains (sugar, salt, peppercorns) lying on the ground plane.
    static func grains(_ m: inout Model, _ rng: inout SeededRNG, center: V3, radiusMin: Float, radiusMax: Float, count: Int,
                       size: Float, angle: ClosedRange<Float> = 0...(2 * .pi), material: MaterialKey, round: Bool = false) {
        for _ in 0..<count {
            let a = rng.float(angle), r = radiusMin + (radiusMax - radiusMin) * sqrt(rng.float())
            let s = size * rng.float(0.7...1.25)
            let dims = round ? V3(s, s, s) : V3(s, s * rng.float(0.7...1.0), s * rng.float(0.8...1.2))
            m.add(blob(dims, exponent: round ? 2 : 3.2, subdivisions: 1, material: material),
                  Xform(translation: center + V3(cos(a) * r, dims.y * 0.5, sin(a) * r),
                        rotation: simd_quatf(degrees: rng.float(0...360), axis: V3(0, 1, 0))))
        }
    }

    /// Outline of a flat blank along +Y: right edge from s0 to s1 (half-width function), then the left edge back.
    static func blank(_ hw: (Float) -> Float, from s0: Float, to s1: Float, step: Float = 0.002) -> [V2] {
        var ss: [Float] = []
        var s = s0
        while s < s1 - 1e-5 { ss.append(s); s += step }
        ss.append(s1)
        var pts = ss.map { V2(hw($0), $0) }
        pts += ss.reversed().map { V2(-hw($0), $0) }
        return Shape2D.deduped(pts)
    }

    /// Splits long segments so deforming the flat cap keeps the bend.
    static func densify(_ poly: [V2], max seg: Float) -> [V2] {
        var out: [V2] = []
        for i in poly.indices {
            let a = poly[i], b = poly[(i + 1) % poly.count]
            let n = max(1, Int(ceil(simd_distance(a, b) / seg)))
            for k in 0..<n { out.append(a + (b - a) * (Float(k) / Float(n))) }
        }
        return out
    }

    /// Extrudes an outline (x, s) into a flat plate lying on XZ: s runs along +Z, thickness along Y centred at 0.
    static func plate(_ outline: [V2], thick: Float, bevel: Float, material: MaterialKey) -> Surface {
        let s = Prim.extrude(outline, depth: thick, bevel: bevel, bevelSegments: 2, material: material)
        return s.transformed(Xform(rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
    }

    static func smooth(_ a: Float, _ b: Float, _ x: Float) -> Float {
        let t = max(0, min(1, (x - a) / (b - a)))
        return t * t * (3 - 2 * t)
    }

    static func plant(_ m: inout Model) {
        let b = m.bounds
        m = m.transformed(Xform(translation: V3(0, -b.min.y, 0)))
    }
}
