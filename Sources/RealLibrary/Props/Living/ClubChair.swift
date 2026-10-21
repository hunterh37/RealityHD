import simd
import Foundation

/// Leather tub club chair, 80 x 82 x 84 cm: one curved wall wraps the back and both arms (high at the
/// back, lower toward the arm fronts), the inner back is button-tufted on a diamond lattice, a welted loose
/// seat cushion sits on a front rail, brass nailheads run along the base and four turned walnut feet.
public struct ClubChair: RealAsset {
    public static let id = "club-chair"
    public static let summary = "Leather tub club chair: curved wrap-around back and arms, button-tufted back, welted seat cushion, nailhead trim."
    public static let tags = ["prop", "floorplan", "living", "furniture", "fabric", "leather", "interior"]
    public static let budget = 8000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 16, distance: 1.1, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.8, 0.82, 0.84)
    /// Frame leather.
    public var leather: MaterialKey = "leather.tan"
    /// Seat cushion leather (more worn).
    public var seatLeather: MaterialKey = "leather.oxblood-worn"
    /// Foot wood.
    public var wood: MaterialKey = "wood.walnut"
    /// Nailhead metal.
    public var nails: MaterialKey = "metal.brass-aged"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [model(seed: seed, detail: true), model(seed: seed, detail: false)], switchDistances: [5])
    }

    func model(seed: UInt64, detail: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = size.x, D = size.z, H = size.y
        let wall: Float = 0.14, legH: Float = 0.14
        let A = W / 2 - wall / 2, B = D / 2 - wall / 2 - 0.01, zf = D / 2 - wall / 2 - 0.01
        let r: Float = 0.17
        // U-shaped centerline in plan: left arm front -> back -> right arm front.
        var path2: [V2] = [V2(-A, zf), V2(-A, -B + r)]
        for k in 1...8 { let a = Float.pi + Float(k) / 8 * Float.pi / 2; path2.append(V2(-A + r + cos(a) * r, -B + r + sin(a) * r)) }
        for k in 0...8 { let a = Float.pi * 1.5 + Float(k) / 8 * Float.pi / 2; path2.append(V2(A - r + cos(a) * r, -B + r + sin(a) * r)) }
        path2.append(V2(A, zf))
        let pts2 = resample(path2.map { V3($0.x, 0, $0.y) }, spacing: 0.035)
        // Arc length parameter and wall height: tall at the back, lower at the arms.
        var arc: [Float] = [0]
        for i in 1..<pts2.count { arc.append(arc[i - 1] + simd_distance(pts2[i], pts2[i - 1])) }
        let total = arc.last!
        let backTop = H, armTop: Float = 0.62, wallBottom = legH
        func topAt(_ i: Int) -> Float {
            let u = arc[i] / total                                   // 0 left front, 0.5 back centre
            let f = smoothstep(0.12, 0.38, 0.5 - abs(u - 0.5))      // 0 at the arms, 1 over the back
            return armTop + (backTop - armTop) * f
        }
        let baseH = backTop - wallBottom
        var scales: [Float] = [], path: [V3] = []
        for i in pts2.indices {
            let hgt = topAt(i) - wallBottom
            let s = hgt / baseH
            scales.append(s)
            path.append(V3(pts2[i].x, wallBottom + hgt / 2, pts2[i].z))
        }
        let section = Shape2D.roundedRect(baseH, wall, radius: 0.05, segments: 3)
        m.add(Prim.sweep(section, along: path, up: .up, scales: scales, caps: true, material: leather))
        // Inward normal at a path index (toward the chair centre).
        func inward(_ i: Int) -> V3 {
            let a = pts2[max(0, i - 1)], b = pts2[min(pts2.count - 1, i + 1)]
            let t = simd_normalize(b - a)
            return V3(-t.z, 0, t.x)
        }
        if detail {
            // Button tufting: diamond lattice on the inner wall, columns by arc length, rows by height.
            let rows: [Float] = [0.47, 0.545, 0.62, 0.695, 0.77]
            let colStep: Float = 0.075
            var tufts: [(V3, V3, Int, Int)] = []
            var c = 0
            var u: Float = 0.12
            while u < total - 0.1 {
                let i = min(pts2.count - 1, Int(u / total * Float(pts2.count - 1)))
                for (ri, y) in rows.enumerated() where (ri + c) % 2 == 0 && y < topAt(i) - 0.06 {
                    let s = scales[i]
                    let n = inward(i)
                    let p = V3(pts2[i].x, y, pts2[i].z) + n * (wall * s / 2 + 0.001)
                    tufts.append((p, n, ri, c))
                }
                u += colStep; c += 1
            }
            let btn = Prim.superellipsoid(V3(0.03, 0.016, 0.03), exponent: 2.2, subdivisions: 2, material: leather)
            for (p, n, _, _) in tufts { m.add(btn, Xform(translation: p, rotation: facing(n))) }
            // Pleats between diagonal neighbours.
            for (p, pn, ri, ci) in tufts {
                for (q, qn, rj, cj) in tufts where cj == ci + 1 && abs(rj - ri) == 1 && simd_dot(pn, qn) > 0.985 {
                    m.add(Prim.tube([p, q], radii: [0.0045, 0.0045], sides: 3, seamTile: 0.01, material: leather, capEnd: false))
                }
            }
            // Brass nailhead row along the base of the outer wall.
            let outerPts = pts2.indices.map { i in V3(pts2[i].x, wallBottom + 0.05, pts2[i].z) - inward(i) * (wall * scales[i] / 2 + 0.0005) }
            for (k, p) in resample(outerPts, spacing: 0.05).enumerated() where k > 0 {
                let i = min(pts2.count - 1, Int(Float(k) * 0.05 / total * Float(pts2.count - 1)))
                nailhead(&m, at: p, normal: -inward(i))
            }
        }
        // Front rail, deck and seat cushion.
        m.add(Prim.roundedBox(V3(2 * A - wall + 0.04, 0.2, 0.09), radius: 0.02, bevelSegments: 2, material: leather),
              Xform(translation: V3(0, legH + 0.1, zf - 0.02)))
        m.add(Prim.roundedBox(V3(2 * A - wall + 0.04, 0.17, D - wall - 0.02), radius: 0.02, bevelSegments: 2, material: leather),
              Xform(translation: V3(0, legH + 0.085, -0.01)))
        let cw = 2 * A - wall - 0.02, cd = D - wall - 0.08, ct: Float = 0.14
        let sag = rng.float(0.018...0.026)
        var cush = Prim.superellipsoid(V3(cw, ct, cd), exponent: 5, subdivisions: detail ? 8 : 5, material: seatLeather)
        cush.deform { p in
            let fx = p.x / (cw / 2), fz = p.z / (cd / 2)
            let dip = max(0, 1 - fx * fx) * max(0, 1 - pow(fz - 0.05, 2)) * (p.y > 0 ? 1 : 0.2)
            return p - V3(0, dip * sag + pow(abs(fx), 3) * pow(abs(fz), 3) * (p.y > 0 ? 0.01 : 0), 0)
        }
        let cy = legH + 0.17 + ct / 2 - 0.004
        m.add(cush, Xform(translation: V3(0, cy, 0.02), rotation: simd_quatf(degrees: rng.float(-0.6...0.6), axis: .up)))
        if detail {
            for sign: Float in [1, -1] {
                let yy = sign * (ct / 2 - 0.014)
                let k = pow(max(0, 1 - pow(abs(yy) / (ct / 2), 5)), 1.0 / 5)
                let ring = Shape2D.roundedRect(cw * k - 0.002, cd * k - 0.002, radius: 0.05, segments: 2)
                    .map { V3($0.x, cy + yy - (sign > 0 ? sag * 0.1 : 0), 0.02 - $0.y) }
                m.add(Prim.sweep(Shape2D.circle(0.0045, segments: 5), along: ring, closedPath: true, caps: false, material: seatLeather))
            }
        }
        // Turned feet.
        for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
            let p = V3(sx * (W / 2 - 0.07), 0, sz * (D / 2 - 0.07))
            m.add(turned([(0, 0), (0.019, 0), (0.021, 0.014), (0.025, 0.05), (0.03, 0.095), (0.036, legH + 0.01), (0, legH + 0.01)],
                         segments: 14, material: wood, grainVertical: true), Xform(translation: p))
            m.add(Prim.cylinder(radius: 0.0215, height: 0.012, bevel: 0.002, segments: 12, bevelSegments: 1, material: nails), Xform(translation: p))
        }}
        groundAO(&m, height: 0.2, floor: 0.5)
        return m
    }

    /// Low-poly upholstery nailhead (11 mm dome).
    func nailhead(_ m: inout Model, at p: V3, normal n: V3) {
        let rr: Float = 0.0055
        m.add(Prim.lathe([V2(0, -0.0006), V2(rr, -0.0006), V2(rr * 0.85, 0.0025), V2(0, 0.0036)], segments: 6, seamTile: 0.04, material: nails),
              Xform(translation: p, rotation: facing(n)))
    }
}
