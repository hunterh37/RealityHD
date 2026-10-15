import simd
import Foundation

/// Robert Gould Shaw and Massachusetts 54th Regiment Memorial, Beacon St. opposite the State House
/// (Saint-Gaudens bronze 1897, frame by McKim, Mead & White). A 3.4 m x 4.3 m bronze high relief of
/// Shaw on horseback beside his marching infantry, a drummer boy leading and an allegorical angel above,
/// set in a pink granite aedicule: inscribed base, flanking pilasters, entablature and cornice. Behind,
/// a paved terrace with a turned-baluster balustrade looks over the Common.
public struct ShawMemorial: RealAsset {
    public static let id = "shaw-memorial"
    public static let summary = "Saint-Gaudens bronze relief of Shaw and the 54th Massachusetts in a granite aedicule with pilasters, cornice, terrace and balustrade."
    public static let tags = ["structure", "architecture", "stone", "metal", "park", "outdoor"]
    public static let budget = 30_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 8, distance: 1.0)

    /// Terrace width (X) in meters.
    public var width: Float = 7.6
    /// Terrace depth (Z) in meters, relief face to balustrade.
    public var depth: Float = 4.2
    /// Bronze relief panel width in meters.
    public var reliefWidth: Float = 4.3
    /// Bronze relief panel height in meters.
    public var reliefHeight: Float = 3.4
    /// Number of marching soldiers in the relief.
    public var soldiers = 24
    /// Granite frame material key.
    public var granite: MaterialKey = "stone.granite-curb:AE978C"
    /// Terrace paving material key.
    public var paving: MaterialKey = "stone.granite-paver"
    /// Relief bronze material key.
    public var bronze: MaterialKey = "metal.bronze-weathered"
    /// Verdigris-streaked bronze for raised, rain-washed parts.
    public var verdigris: MaterialKey = "metal.bronze-weathered:4E6B58"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let hx = width / 2, hz = depth / 2
        let terraceH: Float = 0.3
        func box(_ size: V3, _ c: V3, _ mat: MaterialKey, _ r: Float = 0.03) {
            m.add(Prim.roundedBox(size, radius: r, bevelSegments: 1, material: mat), Xform(translation: c))
        }
        // Terrace: granite platform with a front step.
        box(V3(width, terraceH, depth), V3(0, terraceH / 2, 0), paving, 0.02)
        box(V3(width - 0.4, 0.14, 0.35), V3(0, 0.07, hz + 0.17), granite, 0.015)

        // Aedicule wall at the front of the terrace.
        let wallD: Float = 0.9
        let zBack = hz - wallD, zFront = hz - 0.12
        let zMid = (zBack + zFront) / 2
        let frameW = reliefWidth + 2 * 0.62
        let base0 = terraceH, baseH: Float = 0.95
        let r0 = base0 + baseH, r1 = r0 + reliefHeight
        // Base: plinth course, die with inscription, cap moulding.
        box(V3(frameW + 0.5, 0.28, wallD + 0.2), V3(0, base0 + 0.14, zMid), granite)
        box(V3(frameW + 0.3, baseH - 0.4, wallD), V3(0, base0 + 0.28 + (baseH - 0.4) / 2, zMid), granite)
        box(V3(frameW + 0.42, 0.12, wallD + 0.12), V3(0, r0 - 0.06, zMid), granite)
        // Incised inscription lines on the die.
        var ir = rng.fork(7)
        for row in 0..<3 {
            var x = -frameW / 2 + 0.5
            let y = base0 + 0.45 + Float(row) * 0.12
            while x < frameW / 2 - 0.5 {
                let w = ir.float(0.08...0.3)
                m.add(Prim.extrude(Shape2D.rect(min(w, frameW / 2 - 0.5 - x), 0.05), depth: 0.006, bevel: 0, bevelSegments: 0, material: "stone.granite-curb:5E4A44"),
                      Xform(translation: V3(x + w / 2, y, zFront + 0.1 + 0.002)))
                x += w + ir.float(0.05...0.09)
            }
        }
        // Back wall carrying the relief (recessed), and the pilasters.
        box(V3(frameW, reliefHeight, wallD - 0.1), V3(0, r0 + reliefHeight / 2, zMid - 0.05), granite)
        for s in [Float(-1), 1] {
            let px = s * (reliefWidth / 2 + 0.31)
            box(V3(0.56, 0.22, 0.24), V3(px, r0 + 0.11, zFront + 0.02), granite)
            box(V3(0.48, reliefHeight - 0.5, 0.18), V3(px, r0 + 0.22 + (reliefHeight - 0.5) / 2, zFront), granite)
            // Sunken panel on each pilaster face.
            box(V3(0.3, reliefHeight - 0.9, 0.02), V3(px, r0 + reliefHeight / 2, zFront + 0.085), "stone.granite-curb:A5807A", 0.004)
            box(V3(0.58, 0.1, 0.24), V3(px, r1 - 0.23, zFront + 0.02), granite)
            box(V3(0.62, 0.14, 0.28), V3(px, r1 - 0.11, zFront + 0.03), granite)
        }
        // Entablature: architrave, frieze, dentil-less cornice with a blocking course.
        box(V3(frameW + 0.1, 0.3, wallD + 0.12), V3(0, r1 + 0.15, zMid + 0.02), granite)
        box(V3(frameW + 0.1, 0.36, wallD + 0.06), V3(0, r1 + 0.48, zMid), granite)
        box(V3(frameW + 0.5, 0.12, wallD + 0.4), V3(0, r1 + 0.72, zMid + 0.08), granite)
        box(V3(frameW + 0.38, 0.1, wallD + 0.3), V3(0, r1 + 0.83, zMid + 0.05), granite)
        box(V3(frameW - 0.6, 0.22, wallD - 0.2), V3(0, r1 + 0.99, zMid), granite)

        // Bronze laurel wreaths on the frieze above each pilaster, with ribbon tails.
        for s in [Float(-1), 1] {
            let c = V3(s * (reliefWidth / 2 + 0.31), r1 + 0.48, zMid + wallD / 2 + 0.05)
            var w = Prim.torus(major: 0.13, minor: 0.035, segments: 18, sides: 6, material: bronze)
            w.displace { p, n in 0.012 * sin(atan2(p.z, p.x) * 18) }
            m.add(w, Xform(translation: c, rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
            for t in [Float(-1), 1] {
                m.add(Prim.tube([c + V3(t * 0.03, -0.12, 0.01), c + V3(t * 0.09, -0.2, 0.012), c + V3(t * 0.08, -0.27, 0.01)], radii: [0.016, 0.014, 0.01], sides: 4, seamTile: 0.2, material: verdigris))
            }
        }
        // Bronze relief.
        let pz = zFront - 0.04                     // back plate face
        box(V3(reliefWidth, reliefHeight, 0.06), V3(0, r0 + reliefHeight / 2, pz - 0.01), bronze, 0.01)
        // Bronze frame moulding around the plate.
        for s in [Float(-1), 1] {
            box(V3(0.06, reliefHeight + 0.06, 0.1), V3(s * (reliefWidth / 2 + 0.01), r0 + reliefHeight / 2, pz), bronze, 0.01)
            box(V3(reliefWidth + 0.08, 0.06, 0.1), V3(0, s > 0 ? r1 : r0 + 0.02, pz), bronze, 0.01)
        }
        // Ground line ledge.
        box(V3(reliefWidth - 0.02, 0.08, 0.32), V3(0, r0 + 0.08, pz + 0.16), bronze, 0.01)
        let gy = r0 + 0.12
        let rel: Float = 0.55                      // relief flattening in Z

        // Marching soldiers: three ranks, flattened toward the plate.
        func soldier(_ x: Float, _ zOff: Float, _ h: Float, _ phase: Float, _ r: inout SeededRNG) {
            var f = Model(name: "soldier")
            let hip = V3(0, 0.5 * h, 0)
            let stride = 0.16 * h * sin(phase)
            for leg in [Float(-1), 1] {
                let foot = V3(leg * stride, 0.02, leg * 0.04 * h)
                let knee = V3(leg * stride * 0.5 + 0.03 * h, 0.27 * h, leg * 0.04 * h)
                f.add(Prim.tube([hip + V3(0, 0, leg * 0.04 * h), knee, foot], radii: [0.055 * h, 0.042 * h, 0.035 * h], sides: 6, seamTile: 0.2, material: bronze))
                f.add(Prim.superellipsoid(V3(0.13, 0.05, 0.06) * h, exponent: 2.5, subdivisions: 2, material: bronze), Xform(translation: foot + V3(0.04 * h, 0.01 * h, 0)))
            }
            f.add(Prim.superellipsoid(V3(0.2, 0.36, 0.16) * h, exponent: 2.6, subdivisions: 3, material: bronze), Xform(translation: V3(0.01 * h, 0.7 * h, 0)))
            f.add(Prim.superellipsoid(V3(0.1, 0.13, 0.11) * h, exponent: 2.2, subdivisions: 2, material: bronze), Xform(translation: V3(0.02 * h, 0.94 * h, 0)))
            // Kepi with forward-tilted crown and peak.
            f.add(Prim.cylinder(radius: 0.06 * h, height: 0.08 * h, bevel: 0.004, segments: 8, bevelSegments: 1, material: bronze),
                  Xform(translation: V3(0.0, 0.99 * h, 0), rotation: simd_quatf(degrees: -14, axis: V3(0, 0, 1))))
            // Blanket roll and knapsack.
            f.add(Prim.roundedBox(V3(0.15, 0.2, 0.1) * h, radius: 0.015, bevelSegments: 1, material: bronze), Xform(translation: V3(-0.12 * h, 0.72 * h, 0)))
            f.add(Prim.tube([V3(-0.1, 0.86, -0.08) * h, V3(0.08, 0.84, 0.06) * h], radii: [0.035 * h, 0.035 * h], sides: 6, seamTile: 0.2, material: bronze))
            // Rifle at the shoulder, sloping back, with the carrying arm.
            let butt = V3(0.12, 0.62, 0.06) * h, muzzle = V3(-0.14, 1.42, 0.06) * h
            f.add(Prim.tube([butt, muzzle], radii: [0.022 * h, 0.012 * h], sides: 5, seamTile: 0.2, material: r.chance(0.3) ? verdigris : bronze))
            f.add(Prim.tube([V3(0.06, 0.84, 0.06) * h, V3(0.14, 0.7, 0.08) * h, butt + V3(0, 0.04 * h, 0)], radii: [0.035 * h, 0.03 * h, 0.03 * h], sides: 6, seamTile: 0.2, material: bronze))
            m.add(f, Xform(translation: V3(x, gy, pz + zOff), scale: V3(1, 1, rel)))
        }
        var sr = rng.fork(11)
        let ranks: [(z: Float, h: Float, dx: Float)] = [(0.06, 1.62, 0.18), (0.16, 1.7, 0.0), (0.27, 1.76, 0.1)]
        var count = 0
        let x0 = -reliefWidth / 2 + 0.25, x1 = reliefWidth / 2 - 0.25
        for (ri, rk) in ranks.enumerated() {
            var x = x0 + rk.dx
            while x < x1 && count < soldiers {
                // The front rank stays clear of the horse and the drummer.
                if ri == 2 && x > -0.75 && x < 1.75 { x += 0.36; continue }
                soldier(x, rk.z, rk.h * sr.float(0.97...1.03), x * 4.5 + Float(ri), &sr)
                count += 1
                x += sr.float(0.33...0.4)
            }
        }
        // Drummer boy leading at the right.
        do {
            let dx: Float = 1.85, h: Float = 1.35
            soldier(dx, 0.3, h, 1.1, &sr)
            m.add(Prim.cylinder(radius: 0.14, height: 0.2, bevel: 0.01, segments: 12, bevelSegments: 1, material: bronze),
                  Xform(translation: V3(dx + 0.12, gy + 0.55, pz + 0.38), rotation: simd_quatf(degrees: 70, axis: V3(1, 0, 0)), scale: V3(1, 1, rel)))
        }
        // Shaw on horseback, front rank centre-right.
        do {
            var hm = Model(name: "horse")
            let hb = V3(0.45, 1.25, 0)
            hm.add(Prim.superellipsoid(V3(1.45, 0.62, 0.5), exponent: 2.3, subdivisions: 5, material: bronze), Xform(translation: hb))
            hm.add(Prim.tube([hb + V3(0.55, 0.15, 0), hb + V3(0.8, 0.5, 0), hb + V3(0.95, 0.72, 0)], radii: [0.24, 0.17, 0.13], sides: 8, seamTile: 0.3, material: bronze))
            hm.add(Prim.superellipsoid(V3(0.52, 0.22, 0.2), exponent: 2.2, subdivisions: 3, material: bronze),
                   Xform(translation: hb + V3(1.13, 0.62, 0), rotation: simd_quatf(degrees: -55, axis: V3(0, 0, 1))))
            hm.add(Prim.superellipsoid(V3(0.06, 0.14, 0.05), exponent: 2, subdivisions: 2, material: bronze), Xform(translation: hb + V3(0.98, 0.94, 0.04)))
            // Mane ridge and tail.
            hm.add(Prim.tube([hb + V3(0.6, 0.33, 0), hb + V3(0.85, 0.72, 0)], radii: [0.06, 0.04], sides: 5, seamTile: 0.3, material: bronze))
            hm.add(Prim.tube([hb + V3(-0.7, 0.15, 0), hb + V3(-0.85, -0.2, 0), hb + V3(-0.82, -0.55, 0)], radii: [0.07, 0.08, 0.04], sides: 6, seamTile: 0.3, material: bronze))
            // Legs mid-stride.
            let legs: [(V3, Float, Float)] = [(V3(0.95, 0, 0.12), 0.25, 1), (V3(0.85, 0, -0.12), -0.1, 1), (V3(-0.35, 0, 0.12), -0.2, -1), (V3(-0.25, 0, -0.12), 0.15, -1)]
            for (top, swing, fr) in legs {
                let t = hb + top + V3(0, -0.15, 0)
                let knee = V3(t.x + swing * 0.5 + fr * 0.03, 0.55, t.z)
                let hoof = V3(t.x + swing, 0.05, t.z)
                hm.add(Prim.tube([t, knee, hoof], radii: [0.11, 0.055, 0.05], sides: 6, seamTile: 0.3, material: bronze))
                hm.add(Prim.cylinder(radius: 0.065, height: 0.08, bevel: 0.01, segments: 8, bevelSegments: 1, material: bronze), Xform(translation: hoof + V3(0, -0.05, 0)))
            }
            // Saddle cloth and rider.
            hm.add(Prim.roundedBox(V3(0.5, 0.3, 0.56), radius: 0.04, bevelSegments: 1, material: bronze), Xform(translation: hb + V3(0.05, 0.18, 0)))
            let seat = hb + V3(0.1, 0.38, 0)
            hm.add(Prim.superellipsoid(V3(0.32, 0.6, 0.26), exponent: 2.5, subdivisions: 3, material: bronze), Xform(translation: seat + V3(0, 0.32, 0)))
            hm.add(Prim.tube([seat + V3(0.05, 0.02, 0.2), seat + V3(0.25, -0.2, 0.24), seat + V3(0.2, -0.55, 0.24)], radii: [0.08, 0.06, 0.05], sides: 6, seamTile: 0.3, material: bronze))
            hm.add(Prim.superellipsoid(V3(0.15, 0.19, 0.16), exponent: 2.2, subdivisions: 3, material: bronze), Xform(translation: seat + V3(0.04, 0.74, 0)))
            hm.add(Prim.cylinder(radius: 0.1, height: 0.1, bevel: 0.01, segments: 10, bevelSegments: 1, material: bronze), Xform(translation: seat + V3(0.02, 0.82, 0), rotation: simd_quatf(degrees: -10, axis: V3(0, 0, 1))))
            // Sword held down and forward, reins arm.
            hm.add(Prim.tube([seat + V3(0.08, 0.55, 0.16), seat + V3(0.25, 0.3, 0.22), seat + V3(0.42, 0.22, 0.24)], radii: [0.055, 0.045, 0.04], sides: 6, seamTile: 0.3, material: bronze))
            hm.add(Prim.tube([seat + V3(0.42, 0.22, 0.26), seat + V3(1.0, -0.1, 0.28)], radii: [0.014, 0.008], sides: 4, seamTile: 0.3, material: verdigris))
            m.add(hm, Xform(translation: V3(0.0, gy, pz + 0.3), scale: V3(1, 1, rel)))
        }
        // Allegorical angel floating above, arm outstretched with an olive branch.
        do {
            var a = Model(name: "angel")
            a.add(Prim.superellipsoid(V3(1.15, 0.3, 0.26), exponent: 2.2, subdivisions: 4, material: bronze), Xform(rotation: simd_quatf(degrees: 8, axis: V3(0, 0, 1))))
            a.add(Prim.superellipsoid(V3(0.16, 0.18, 0.16), exponent: 2.2, subdivisions: 3, material: bronze), Xform(translation: V3(0.62, 0.12, 0)))
            a.add(Prim.tube([V3(0.4, 0.05, 0.1), V3(0.75, -0.05, 0.14), V3(1.05, -0.12, 0.14)], radii: [0.05, 0.04, 0.03], sides: 6, seamTile: 0.3, material: bronze))
            a.add(Prim.tube([V3(1.05, -0.12, 0.15), V3(1.2, -0.05, 0.15), V3(1.32, -0.12, 0.15)], radii: [0.02, 0.015, 0.01], sides: 4, seamTile: 0.3, material: verdigris))
            // Drapery trailing behind.
            a.add(Prim.tube([V3(-0.5, 0, 0), V3(-0.85, -0.12, 0), V3(-1.1, -0.05, 0)], radii: [0.14, 0.09, 0.03], sides: 6, seamTile: 0.3, material: bronze))
            // Wings: fanned feather blades.
            for k in 0..<6 {
                let len: Float = 0.95 - Float(k) * 0.1
                let blade = Shape2D.deduped([V2(0, -0.05), V2(len * 0.8, -0.04), V2(len, 0), V2(len * 0.8, 0.05), V2(0, 0.05)])
                let w = Prim.extrude(blade, depth: 0.04, bevel: 0.01, bevelSegments: 1, material: bronze)
                a.add(w, Xform(translation: V3(0.15, 0.12, -0.04), rotation: simd_quatf(degrees: 150 - Float(k) * 9, axis: V3(0, 0, 1))))
            }
            m.add(a, Xform(translation: V3(-0.2, r1 - 0.62, pz + 0.12), scale: V3(1, 1, rel)))
        }

        // Terrace balustrade: back and both sides, turned balusters between rails and end piers.
        let balH: Float = 0.9
        let baluster: [(Float, Float)] = [(0, 0), (0.06, 0), (0.06, 0.05), (0.045, 0.08), (0.075, 0.25), (0.07, 0.36), (0.035, 0.52),
                                          (0.045, 0.56), (0.03, 0.6), (0.04, 0.64), (0.04, 0.66), (0, 0.66)]
        let bal = turned(baluster.map { ($0.0, $0.1) }, segments: 6, material: granite)
        let runs: [(V3, V3)] = [(V3(-hx + 0.2, 0, -hz + 0.2), V3(hx - 0.2, 0, -hz + 0.2)),
                                (V3(-hx + 0.2, 0, -hz + 0.2), V3(-hx + 0.2, 0, zBack - 0.1)),
                                (V3(hx - 0.2, 0, -hz + 0.2), V3(hx - 0.2, 0, zBack - 0.1))]
        for (a, b) in runs {
            let d = b - a, len = simd_length(d), dir = d / len
            let along = abs(dir.x) > 0.5
            let mid = (a + b) / 2
            let sz = along ? V3(len + 0.3, 0.14, 0.3) : V3(0.3, 0.14, len + 0.3)
            box(sz, V3(mid.x, terraceH + 0.07, mid.z), granite)
            box(along ? V3(len + 0.34, 0.12, 0.34) : V3(0.34, 0.12, len + 0.34), V3(mid.x, terraceH + balH - 0.06, mid.z), granite)
            let n = Int(len / 0.26)
            for i in 1..<n {
                let p = a + dir * (Float(i) * len / Float(n))
                m.add(bal, Xform(translation: V3(p.x, terraceH + 0.14, p.z)))
            }
            for p in [a, b] { box(V3(0.44, balH + 0.08, 0.44), V3(p.x, terraceH + (balH + 0.08) / 2, p.z), granite) }
        }
        // Back (Common side) face: raised frame around a sunken tablet with the regiment roll in incised lines.
        let zb = zMid - 0.05 - (wallD - 0.1) / 2
        let tabW = reliefWidth - 0.4, tabH = reliefHeight - 0.9
        let tabC = r0 + reliefHeight / 2 + 0.1
        for s in [Float(-1), 1] {
            box(V3(0.16, tabH + 0.32, 0.06), V3(s * (tabW / 2 + 0.08), tabC, zb - 0.03), granite, 0.01)
            box(V3(tabW + 0.32, 0.16, 0.06), V3(0, tabC + s * (tabH / 2 + 0.08), zb - 0.03), granite, 0.01)
        }
        for s in [Float(-1), 1] {
            box(V3(0.48, reliefHeight - 0.5, 0.12), V3(s * (reliefWidth / 2 + 0.31), r0 + 0.22 + (reliefHeight - 0.5) / 2, zb - 0.06), granite)
        }
        var br = rng.fork(31)
        for row in 0..<14 {
            let y = tabC + tabH / 2 - 0.25 - Float(row) * 0.13
            for col in 0..<3 {
                let w = br.float(0.5...1.0)
                let cx = -tabW / 2 + 0.35 + Float(col) * (tabW - 0.4) / 3 + w / 2
                m.add(Prim.extrude(Shape2D.rect(w, 0.035), depth: 0.006, bevel: 0, bevelSegments: 0, material: "stone.granite-curb:5E4A44"),
                      Xform(translation: V3(cx, y, zb - 0.002)))
            }
        }
        // Rain-washed verdigris streaks below the relief ledge onto the granite.
        for i in 0..<5 {
            var r = rng.fork(200 + i)
            let x = r.float(-reliefWidth / 2...reliefWidth / 2)
            m.add(Prim.extrude(Shape2D.rect(r.float(0.04...0.1), 0.6), depth: 0.004, bevel: 0, bevelSegments: 0, material: "metal.copper-patina:7FA08E"),
                  Xform(translation: V3(x, r0 - 0.42, zFront + 0.1 + 0.003)))
        }
        groundAO(&m, height: 0.6)
        return LODModel(m)
    }
}
