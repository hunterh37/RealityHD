import simd
import Foundation

/// Helpers for the building-services facade props (meters, vents, hose bibbs, chargers). Same frame as `FA`:
/// wall plane at z = 0, piece projecting toward +Z.
enum FS {
    /// Rounded-rectangle plate, front face at z = c.z + t / 2, centered on c.
    static func plate(_ m: inout Model, _ w: Float, _ h: Float, _ t: Float, radius: Float = 0.004, at c: V3, _ mat: MaterialKey, bevel: Float = 0.0015) {
        m.add(Prim.extrude(Shape2D.roundedRect(w, h, radius: radius), depth: t, bevel: bevel, bevelSegments: 1, material: mat),
              Xform(translation: c))
    }
    /// Pan-head screw with a slot, axis along n.
    static func screw(_ m: inout Model, at p: V3, normal n: V3 = FA.Z, r: Float = 0.0028, mat: MaterialKey = "metal.screw-zinc") {
        rivet(&m, at: p, normal: n, radius: r, height: r * 0.55, segments: 10, material: mat)
    }
    static func screws(_ m: inout Model, _ pts: [V3], normal n: V3 = FA.Z, r: Float = 0.0028, mat: MaterialKey = "metal.screw-zinc") {
        for p in pts { screw(&m, at: p, normal: n, r: r, mat: mat) }
    }
    /// Ring in the XY plane (axis +Z) at c.
    static func ringZ(_ m: inout Model, r: Float, wire: Float, at c: V3, _ mat: MaterialKey, segments: Int = 40, sides: Int = 8) {
        m.add(Prim.torus(major: r, minor: wire, segments: segments, sides: sides, material: mat), Xform(translation: c, rotation: FA.q(90, FA.X)))
    }
    /// Rectangular panel with a circular opening of radius r (square strips plus four concave corner fillers).
    static func roundHolePanel(_ m: inout Model, w: Float, h: Float, hole r: Float, t: Float, at c: V3, _ mat: MaterialKey, bevel: Float = 0.0015) {
        let sx = (w / 2 - r), sy = (h / 2 - r)
        FA.box(&m, V3(sx, h, t), V3(c.x - r - sx / 2, c.y, c.z), mat, r: bevel)
        FA.box(&m, V3(sx, h, t), V3(c.x + r + sx / 2, c.y, c.z), mat, r: bevel)
        FA.box(&m, V3(2 * r, sy, t), V3(c.x, c.y + r + sy / 2, c.z), mat, r: bevel)
        FA.box(&m, V3(2 * r, sy, t), V3(c.x, c.y - r - sy / 2, c.z), mat, r: bevel)
        var arc: [V2] = []
        for i in 1..<10 { let a = Float(i) / 10 * .pi / 2; arc.append(V2(r * sin(a), r * cos(a))) }
        for (qx, qy) in [(1, 1), (-1, 1), (1, -1), (-1, -1)] as [(Float, Float)] {
            let pts = ([V2(r, 0), V2(r, r), V2(0, r)] + arc).map { V2($0.x * qx, $0.y * qy) }
            m.add(Prim.extrude(pts, depth: t, bevel: bevel * 0.5, bevelSegments: 1, material: mat), Xform(translation: c))
        }
    }
    /// Moulded plastic blade: tapered paddle outline in XY, twisted by pitch about its length.
    static func blade(_ m: inout Model, length: Float, root: Float, tip: Float, thick: Float, angle: Float, pitch: Float, at c: V3, _ mat: MaterialKey) {
        let pts: [V2] = [V2(0.012, -root * 0.5), V2(length * 0.55, -root * 0.62), V2(length, -tip * 0.5), V2(length, tip * 0.5),
                         V2(length * 0.55, root * 0.38), V2(0.012, root * 0.5)]
        let q = FA.q(angle, FA.Z) * FA.q(pitch, FA.X)
        m.add(Prim.extrude(Shape2D.rounded(pts, radius: 0.01), depth: thick, bevel: thick * 0.4, bevelSegments: 1, material: mat),
              Xform(translation: c, rotation: q))
    }
    /// Fan guard: concentric wire rings and radial spokes, centered on c, front plane at c.z.
    static func fanGuard(_ m: inout Model, r: Float, rings: Int, spokes: Int, wire: Float = 0.0018, at c: V3, _ mat: MaterialKey) {
        for i in 1...rings { ringZ(&m, r: r * Float(i) / Float(rings), wire: wire, at: c, mat, segments: 36 + i * 4, sides: 6) }
        for k in 0..<spokes {
            let a = Float(k) / Float(spokes) * 2 * .pi
            FA.rod(&m, c + V3(cos(a), sin(a), 0) * (r * 0.1), c + V3(cos(a), sin(a), 0) * r, r: wire, mat, sides: 6)
        }
    }
}

extension FS {
    /// Thin weathering streak (rust bleed, grime, water stain) lying on a +Z face at z.
    static func streak(_ m: inout Model, x: Float, top: Float, w: Float, h: Float, z: Float, _ mat: MaterialKey = "metal.rust") {
        FA.box(&m, V3(w, h, 0.0012), V3(x, top - h / 2, z), mat, r: 0.0004)
    }
    /// Quick registered detail: sheet-metal mounting ears with slotted holes on both sides of a box, at wall z.
    static func ears(_ m: inout Model, width: Float, y: Float, _ mat: MaterialKey = "metal.galvanized") {
        for s in [Float(-1), 1] {
            FA.box(&m, V3(0.03, 0.016, 0.0025), V3(s * (width / 2 - 0.004), y, 0.00125), mat, r: 0.0008)
            FS.screw(&m, at: V3(s * (width / 2 - 0.004), y, 0.0025), r: 0.003)
        }
    }
}

extension FS {
    /// J1772 connector handle docked plug-down in a holster cup. `base` is the cup bottom centre; axis +Y; front toward +Z.
    static func dockedHandle(_ m: inout Model, base b: V3) {
        m.add(Prim.cylinder(radius: 0.034, height: 0.05, bevel: 0.004, segments: 14, material: "plastic.black"), Xform(translation: b))
        m.add(Prim.cylinder(radius: 0.031, height: 0.004, bevel: 0.001, segments: 14, material: "metal.stainless"), Xform(translation: b + V3(0, 0.05, 0)))
        m.add(Prim.superellipsoid(V3(0.058, 0.1, 0.05), exponent: 2.4, subdivisions: 5, material: "plastic.black"), Xform(translation: b + V3(0, 0.108, 0)))
        FA.box(&m, V3(0.02, 0.04, 0.01), b + V3(0, 0.12, 0.028), "plastic.medical-grey", r: 0.003)
        m.add(Prim.cylinder(radius: 0.027, height: 0.03, bevel: 0.003, segments: 14, material: "plastic.medical-grey"), Xform(translation: b + V3(0, 0.052, 0)))
        m.add(Prim.cylinder(radius: 0.0215, height: 0.012, bevel: 0.001, segments: 14, material: "rubber.silicone"), Xform(translation: b + V3(0, 0.044, 0)))
        for i in 0..<3 {
            m.add(Prim.torus(major: 0.0275 - Float(i) * 0.001, minor: 0.0025, segments: 14, sides: 5, material: "rubber.silicone"),
                  Xform(translation: b + V3(0, 0.15 + Float(i) * 0.004, 0)))
        }
    }
}

extension FS {
    /// Pipe along a polyline with every corner replaced by a bend of radius ~`bend` (fitting elbows).
    static func pipe(_ m: inout Model, _ pts: [V3], r: Float, _ mat: MaterialKey, bend: Float = 0.03, sides: Int = 12) {
        guard pts.count > 2 else { FA.path(&m, pts, r: r, mat, sides: sides); return }
        var out: [V3] = [pts[0]]
        for i in 1..<(pts.count - 1) {
            let a = pts[i - 1], b = pts[i], c = pts[i + 1]
            let da = simd_normalize(a - b), dc = simd_normalize(c - b)
            let k = min(bend, simd_length(a - b) * 0.45, simd_length(c - b) * 0.45)
            for j in 0...6 {   // quadratic bezier through the corner
                let t = Float(j) / 6, u = 1 - t
                out.append(u * u * (b + da * k) + 2 * u * t * b + t * t * (b + dc * k))
            }
        }
        out.append(pts[pts.count - 1])
        FA.path(&m, out, r: r, mat, sides: sides)
    }
    /// Hex nut or coupling, axis along n, across-flats `af`, length h, centred at p.
    static func nut(_ m: inout Model, at p: V3, axis n: V3, af: Float, h: Float, _ mat: MaterialKey) {
        let hex = Shape2D.rounded(Shape2D.polygon(sides: 6, radius: af / sqrt(3)), radius: af * 0.05, segments: 1)
        m.add(Prim.extrude(hex, depth: h, bevel: min(af * 0.06, h * 0.3), bevelSegments: 1, material: mat),
              Xform(translation: p, rotation: facing(n) * FA.q(-90, FA.X)))
    }
    /// Cylinder along an arbitrary axis, base centre at p.
    static func cyl(_ m: inout Model, r: Float, h: Float, at p: V3, axis n: V3, _ mat: MaterialKey, bevel: Float = 0.002, segments: Int = 18) {
        m.add(Prim.cylinder(radius: r, height: h, bevel: bevel, segments: segments, bevelSegments: 1, material: mat), Xform(translation: p, rotation: facing(n)))
    }
}
