import simd
import Foundation

/// Mars data-center dome, 20 x 10 x 20 m: frequency-3 geodesic dome (radius 7 m) of white panels in aluminum struts with
/// red dust accumulated on the lower panels, tinted glazing near the crown, a pressurized annex with airlock on +X, a
/// radiator bank on stands at -Z, a vent mast, and a red dust ground with drifts and rocks. Base y = 0, centred on X/Z.
public struct MarsDCDome: RealAsset {
    public static let id = "mars-dc-dome"
    public static let summary = "Mars data center: geodesic dome with red dust on lower panels, pressurized annex and radiators."
    public static let tags = ["prop", "space", "datacenter", "ground"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 26, distance: 1.0, studio: true)

    /// Dome radius (m).
    public var radius: Float = 7
    public var ground: MaterialKey = "dust.mars"
    public var film: MaterialKey = "dust.mars-film"
    public var panel: MaterialKey = "thermal.radiator-white"
    public var strut: MaterialKey = "metal.aluminum-brushed"
    public var glazing: MaterialKey = "glass.tinted"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let R = radius
        func height(_ p: V2) -> Float {
            let r = simd_length(p)
            var h = 0.1 + 0.06 * sin(p.x * 0.7 + 0.4) * cos(p.y * 0.9) + 0.03 * sin(p.x * 2.3 - p.y * 1.7)
            h += 0.45 * exp(-pow((r - (R + 0.5)) / 0.9, 2))       // dust drift hugging the footing
            let e = max(abs(p.x), abs(p.y)); if e > 8.5 { h = 0.1 + (h - 0.1) * max(0, 1 - (e - 8.5) / 1.5) }
            return h
        }
        m.add(Prim.terrain(size: V2(20, 20), segments: 40, material: ground) { height($0) })
        // Geodesic hemisphere: icosahedron subdivided to frequency 3, kept where the face centre is above the base.
        let t: Float = (1 + sqrt(5)) / 2
        var vs: [V3] = [V3(-1, t, 0), V3(1, t, 0), V3(-1, -t, 0), V3(1, -t, 0), V3(0, -1, t), V3(0, 1, t), V3(0, -1, -t), V3(0, 1, -t), V3(t, 0, -1), V3(t, 0, 1), V3(-t, 0, -1), V3(-t, 0, 1)].map { simd_normalize($0) }
        let fi: [[Int]] = [[0,11,5],[0,5,1],[0,1,7],[0,7,10],[0,10,11],[1,5,9],[5,11,4],[11,10,2],[10,7,6],[7,1,8],[3,9,4],[3,4,2],[3,2,6],[3,6,8],[3,8,9],[4,9,5],[2,4,11],[6,2,10],[8,6,7],[9,8,1]]
        // Rotate so a vertex points up (pentagon crown).
        let up = simd_quatf(from: vs[0], to: V3(0, 1, 0))
        vs = vs.map { up.act($0) }
        let N = 3
        var tris: [(V3, V3, V3)] = []
        for f in fi {
            let a = vs[f[0]], b = vs[f[1]], c = vs[f[2]]
            func P(_ i: Int, _ j: Int) -> V3 { simd_normalize(a + (b - a) * (Float(i) / Float(N)) + (c - a) * (Float(j) / Float(N))) }
            for i in 0..<N { for j in 0..<(N - i) {
                tris.append((P(i, j), P(i + 1, j), P(i, j + 1)))
                if i + j < N - 1 { tris.append((P(i + 1, j), P(i + 1, j + 1), P(i, j + 1))) }
            } }
        }
        let cut: Float = 0.03
        var edges = Set<String>()
        func key(_ a: V3, _ b: V3) -> String {
            let ka = "\(Int(a.x * 1000)),\(Int(a.y * 1000)),\(Int(a.z * 1000))", kb = "\(Int(b.x * 1000)),\(Int(b.y * 1000)),\(Int(b.z * 1000))"
            return ka < kb ? ka + "|" + kb : kb + "|" + ka
        }
        var dustLine = [Float]()
        for (a, b, c) in tris {
            let cen = (a + b + c) / 3
            if cen.y < cut || min(a.y, min(b.y, c.y)) < -0.01 { continue }
            let A = a * R, B = b * R, C = c * R
            let ctr = cen * R
            let n = simd_normalize(cen)
            let u = simd_normalize(B - A), w = simd_cross(n, u)
            // Shrink toward centroid for the strut gap, then express in the panel plane.
            func loc(_ p: V3) -> V2 { let q = ctr + (p - ctr) * 0.93; return V2(simd_dot(q - ctr, u), simd_dot(q - ctr, w)) }
            let outline = [loc(A), loc(B), loc(C)]
            let h = ctr.y / R
            let mat: MaterialKey
            if h < 0.34 { mat = film }
            else if h < 0.5 { mat = rng.chance(0.55) ? film : "\(panel):D8C4B2" }
            else if h < 0.66 { mat = rng.chance(0.25) ? "\(panel):E0CDBD" : "\(panel):DEDDD6" }
            else if h > 0.86 && rng.chance(0.6) { mat = glazing }
            else { mat = "\(panel):\(["E6E6E0", "E2E2DB", "E9E9E4"][rng.int(0...2)])" }
            let s = Prim.extrude(outline, depth: 0.06, bevel: 0.006, bevelSegments: 1, material: mat)
            let basis = simd_float3x3(columns: (u, w, n))
            m.add(s, Xform(translation: ctr, rotation: simd_quatf(basis)))
            for (p, q) in [(A, B), (B, C), (C, A)] {
                let k = key(p, q)
                if edges.insert(k).inserted {
                    let low = (p.y + q.y) / (2 * R) < 0.3
                    m.add(OK.rod(p, q, r: 0.04, low ? "metal.aluminum-brushed" : strut, sides: 4))
                }
            }
            dustLine.append(h)
        }
        // Footing ring and node balls.
        m.add(Prim.torus(major: R + 0.05, minor: 0.12, segments: 48, sides: 6, material: "concrete.smooth"), Xform(translation: V3(0, 0.1, 0)))
        // Dome airlock vestibule on +X side leading to the annex, annex pressure cylinder, door, windows.
        let ax: Float = 3.8, ar: Float = 2.0, al: Float = 4.6
        m.add(Prim.cylinder(radius: ar, height: al, bevel: 0.06, segments: 22, bevelSegments: 1, material: panel + ":E3E3DD"), Xform(translation: V3(ax, ar + 0.05, 0), rotation: OK.qx))
        for k in 1..<4 {
            m.add(Prim.torus(major: ar + 0.02, minor: 0.04, segments: 22, sides: 4, material: strut), Xform(translation: V3(ax + Float(k) * al / 4, ar + 0.05, 0), rotation: OK.qx))
        }
        // Dust film on the annex lower half: low shell band.
        m.add(Prim.lathe([V2(ar + 0.012, 0), V2(ar + 0.02, 0.5), V2(ar + 0.012, 0.9)], segments: 22, seamTile: 1.0, material: film), Xform(translation: V3(ax, ar + 0.05, 0), rotation: OK.qx))
        m.add(Prim.cylinder(radius: 0.62, height: 0.07, bevel: 0.01, segments: 20, bevelSegments: 1, material: "plastic.matte:2A2D33"), Xform(translation: V3(ax + al, ar + 0.05, 0), rotation: OK.qx))
        m.add(Prim.torus(major: 0.7, minor: 0.05, segments: 20, sides: 6, material: "metal.titanium"), Xform(translation: V3(ax + al + 0.03, ar + 0.05, 0), rotation: OK.qx))
        for z: Float in [-1.2, 1.2] {
            let (a, x) = OK.box(V3(0.7, 0.36, 0.04), V3(ax + 2.4, ar + 0.6, z * 1.7 * 0.85), glazing, r: 0.01); _ = (a, x)
        }
        // Access steps.
        for k in 0..<3 { let (a, x) = OK.box(V3(0.5, 0.15, 1.4), V3(ax + al + 0.6 + Float(k) * 0.5, 0.075 + Float(2 - k) * 0.0 + Float(2 - k) * 0.15, 0), "metal.aluminum-brushed", r: 0.006); m.add(a, x) }
        // Radiator bank at -Z on stands, with glowing coolant header.
        for i in 0..<10 {
            let x = -4.0 + Float(i) * 0.62
            m.add(Prim.extrude(Shape2D.rect(0.05, 2.4), depth: 3.0, bevel: 0.004, bevelSegments: 1, material: "thermal.radiator-white:E0DDD6"), Xform(translation: V3(x, 1.7, -8.4)))
        }
        for x: Float in [-4.3, 1.9] { for z: Float in [-9.8, -7.0] { m.add(OK.rod(V3(x, 0, z), V3(x, 0.45, z), r: 0.05, strut, sides: 6)) } }
        let (hdr, hx) = OK.box(V3(6.4, 0.14, 0.14), V3(-1.2, 0.45, -8.4), "thermal.radiator-glow", r: 0.01); m.add(hdr, hx)
        // Vent mast with weather head on the crown.
        m.add(OK.rod(V3(0, R - 0.05, 0), V3(0, 9.2, 0), r: 0.05, strut, sides: 8))
        m.add(Prim.lathe([V2(0, 0), V2(0.35, 0.05), V2(0.45, 0.2)], segments: 14, seamTile: 1.0, material: "thermal.radiator-white"), Xform(translation: V3(0, 9.0, 0), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        // Dust drifts against the footing and rocks.
        for _ in 0..<14 {
            let a = rng.float(0...(2 * .pi)), r = R + rng.float(0.5...1.2)
            if cos(a) > 0.55 && abs(sin(a)) < 0.45 { continue }
            let s = rng.float(0.7...1.5)
            m.add(Prim.superellipsoid(V3(s * 1.4, s * 0.28, s), exponent: 2.4, subdivisions: 4, material: film), Xform(translation: V3(r * cos(a), 0.1, r * sin(a)), rotation: simd_quatf(angle: -a, axis: V3(0, 1, 0))))
        }
        for _ in 0..<16 {
            let p = V2(rng.float(-9...9), rng.float(-9...9)); if simd_length(p) < R + 1.5 || (p.y < -6.5) { continue }
            let s = rng.float(0.12...0.5)
            m.add(Prim.superellipsoid(V3(s, s * 0.65, s * 0.85), exponent: 3, subdivisions: 4, material: "rock.basalt"), Xform(translation: V3(p.x, height(p) + s * 0.15, p.y), rotation: simd_quatf(degrees: rng.float(0...360), axis: V3(0, 1, 0))))
        }
        groundAO(&m, height: 0.1, floor: 0.7)
        return LODModel(m)
    }
}
