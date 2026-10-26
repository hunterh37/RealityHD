import simd
import Foundation

/// High-tech tensile canopy, 5 m square: a PTFE-coated glass-fibre membrane drawn up to a steel mast with a
/// clamped ring collar, edges sagging inward and lifting between four corner points, welded radial seams,
/// a stainless edge cable running in a sewn sleeve, corner clamp plates with shackles, fork heads,
/// turnbuckle sleeves and tension rods down to galvanized anchor plates bolted to the floor. Dust gathers
/// toward the low corners, stainless is lightly water-stained, mast base shows rust bloom at the bolts.
public struct TensileMembraneCanopy: RealAsset {
    public static let id = "tensile-membrane-canopy"
    public static let summary = "High-tech tensile canopy, 5 m square: PTFE membrane cone tensioned between a steel mast, edge cables and corner anchor plates."
    public static let tags = ["prop", "architecture", "facade", "metal", "fabric"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 16, distance: 1.9, studio: true)

    /// Plan half-diagonal offset of each corner clamp (m).
    public var cornerReach: Float = 2.12
    /// Corner, edge-lift and peak heights (m).
    public var cornerHeight: Float = 0.95
    public var edgeLift: Float = 0.38
    public var peakHeight: Float = 1.9
    /// Membrane colour (sRGB hex).
    public var membraneColor: UInt32 = 0xE9E7DF
    public var steel: MaterialKey = "metal.stainless"
    public var mast: MaterialKey = "metal.powder-white"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let R = cornerReach
        let N = 24
        func pt(_ iu: Int, _ iv: Int) -> V3 {
            let u = Float(iu) / Float(N) * 2 - 1, v = Float(iv) / Float(N) * 2 - 1
            let au = abs(u), av = abs(v)
            let x = u * R * (1 - 0.095 * pow(au, 8) * (1 - v * v) * 1.0 - 0.0)
            let z = v * R * (1 - 0.095 * pow(av, 8) * (1 - u * u))
            let mm = pow(pow(au, 3.5) + pow(av, 3.5), 1 / 3.5)
            let f = pow(max(0, 1 - mm), 1.35)
            let y = cornerHeight + (peakHeight - cornerHeight) * f
                + edgeLift * ((1 - u * u) * pow(av, 7) + (1 - v * v) * pow(au, 7))
            return V3(x, y, z)
        }
        func idx(_ i: Int, _ j: Int) -> UInt32 { UInt32(j * (N + 1) + i) }
        let Z = 6
        let mats: [MaterialKey] = (0..<Z).map { z in
            let t = Float(z) / Float(Z - 1)
            return FSH.canvas(membraneColor, fade: 0.06 * (1 - t), dirt: 0.02 + 0.3 * t)
        }
        var layers = mats.map { Surface(material: $0) }
        for z in 0..<Z { for j in 0...N { for i in 0...N { let p = pt(i, j); _ = layers[z].add(p, .up, V2(p.x, p.z)) } } }
        for j in 0..<N { for i in 0..<N {
            let p = (pt(i, j) + pt(i + 1, j + 1)) / 2
            let t = max(0, min(0.999, (peakHeight - p.y) / (peakHeight - cornerHeight + 0.15) * 0.95))
            let z = min(Z - 1, Int(t * Float(Z)))
            layers[z].quad(idx(i, j), idx(i, j + 1), idx(i + 1, j + 1), idx(i + 1, j))
        } }
        for z in 0..<Z where !layers[z].indices.isEmpty {
            layers[z].recomputeNormals(weldSeams: true)
            layers[z].computeTangents()
            m.add(layers[z])
            m.add(layers[z].flipped(), Xform(translation: V3(0, -0.003, 0)))
        }
        // Welded radial seams: diagonals and mid lines, as thin raised strips.
        let seamMat = FSH.canvas(membraneColor, dirt: 0.38)
        let lines: [(Int, Int) -> (Int, Int)] = [
            { t, _ in (t, t) }, { t, n in (t, n - t) }, { t, n in (t, n / 2) }, { t, n in (n / 2, t) },
        ]
        for l in lines {
            let path = (3...(N - 3)).map { t -> V3 in let (i, j) = l(t, N); return pt(i, j) + V3(0, 0.0035, 0) }
            m.add(Prim.tube(path, radii: Array(repeating: 0.0042, count: path.count), sides: 4, seamTile: 0.1, material: seamMat, capEnd: true))
        }
        // Edge sleeve and stainless cable along the four edges.
        for e in 0..<4 {
            let path: [V3] = (0...N).map { t in
                switch e {
                case 0: return pt(t, 0)
                case 1: return pt(N, t)
                case 2: return pt(N - t, N)
                default: return pt(0, N - t)
                }
            }
            let up = path.map { $0 + V3(0, 0.006, 0) }
            m.add(Prim.tube(up, radii: Array(repeating: 0.019, count: up.count), sides: 6, seamTile: 0.1, material: FSH.canvas(membraneColor, dirt: 0.28), capEnd: true))
            m.add(Prim.tube(up, radii: Array(repeating: 0.0075, count: up.count), sides: 5, seamTile: 0.05, material: steel, capEnd: true))
        }
        // Mast with base plate, gussets, ring collar and cap.
        let mh: Float = 2.0
        m.add(Prim.cylinder(radius: 0.085, height: mh - 0.09, bevel: 0.004, segments: 18, bevelSegments: 1, material: mast), Xform(translation: V3(0, 0.02, 0)))
        m.add(Prim.cylinder(radius: 0.24, height: 0.022, bevel: 0.003, segments: 20, bevelSegments: 1, material: "metal.galvanized-aged"))
        for k in 0..<8 {
            let a = Float(k) / 8 * 2 * .pi
            FSH.nut(&m, at: V3(cos(a) * 0.19, 0.022, sin(a) * 0.19), normal: FA.Y, size: 0.026, "metal.rust")
        }
        for k in 0..<4 {
            let a = Float(k) / 4 * 2 * .pi + .pi / 4
            let g: [V2] = [V2(0.085, 0.02), V2(0.2, 0.02), V2(0.085, 0.3)]
            m.add(Prim.extrude(g, depth: 0.012, bevel: 0.002, bevelSegments: 1, material: mast), Xform(translation: V3(0, 0, 0), rotation: simd_quatf(angle: a, axis: FA.Y)))
        }
        m.add(Prim.cylinder(radius: 0.14, height: 0.07, bevel: 0.006, segments: 20, bevelSegments: 1, material: steel), Xform(translation: V3(0, peakHeight - 0.075, 0)))
        m.add(Prim.torus(major: 0.18, minor: 0.016, segments: 24, sides: 8, material: steel), Xform(translation: V3(0, peakHeight - 0.045, 0)))
        m.add(Prim.cylinder(radius: 0.1, height: 0.05, bevel: 0.01, segments: 18, bevelSegments: 1, material: mast), Xform(translation: V3(0, mh - 0.06, 0)))
        FC.bead(&m, r: 0.045, at: V3(0, mh - 0.02, 0), steel, sub: 4)
        // Corner assemblies.
        for (sx, sz) in [(1, 1), (-1, 1), (-1, -1), (1, -1)] as [(Float, Float)] {
            let outD = simd_normalize(V3(sx, 0, sz))
            let C = pt(sx > 0 ? N : 0, sz > 0 ? N : 0)
            let rot = simd_quatf(angle: atan2(-outD.z, outD.x), axis: FA.Y)
            // Clamp plates sandwiching the membrane corner, with bolts.
            for dy: Float in [0.012, -0.012] {
                m.add(Prim.extrude(Shape2D.rounded([V2(-0.13, -0.09), V2(0.0, -0.13), V2(0.17, 0), V2(0.0, 0.13), V2(-0.13, 0.09)], radius: 0.012, segments: 2), depth: 0.012, bevel: 0.002, bevelSegments: 1, material: steel),
                      Xform(translation: C + V3(0, dy, 0), rotation: rot * FA.q(-90, FA.X)))
            }
            for (a, b) in [(-0.07, -0.05), (-0.07, 0.05), (0.04, -0.06), (0.04, 0.06), (0.1, 0)] as [(Float, Float)] {
                let off = outD * a + V3(-outD.z, 0, outD.x) * b
                FSH.nut(&m, at: C + off + V3(0, 0.018, 0), normal: FA.Y, size: 0.016, "metal.stainless")
            }
            // Shackle and fork head.
            let tip = C + outD * 0.17 + V3(0, 0, 0)
            let axis = simd_normalize(simd_cross(FA.Y, outD))
            m.add(Prim.torus(major: 0.032, minor: 0.008, segments: 16, sides: 6, material: steel), Xform(translation: tip + outD * 0.02, rotation: facing(axis)))
            // Rod down and out to the anchor.
            let anchor = V3(sx * 2.26, 0.032, sz * 2.26)
            let rodTop = tip + outD * 0.06 - V3(0, 0.03, 0)
            let dir = simd_normalize(anchor - rodTop)
            let rodBot = anchor - dir * 0.05
            // Fork head: two cheek plates and a pin.
            for s: Float in [-1, 1] {
                FA.box(&m, V3(0.05, 0.05, 0.008), rodTop - dir * 0.025 + V3(-outD.z, 0, outD.x) * s * 0.018, steel, r: 0.002, rot: rot)
            }
            FA.rod(&m, rodTop - dir * 0.04, rodTop - dir * 0.04 + V3(-outD.z, 0, outD.x) * 0.045 - V3(-outD.z, 0, outD.x) * 0.0225, r: 0.007, steel, sides: 6)
            FA.rod(&m, rodTop, rodBot, r: 0.0135, steel, sides: 8)
            // Turnbuckle sleeve with flats and lock nuts.
            let tbMid = rodTop + (rodBot - rodTop) * 0.42
            FA.rod(&m, tbMid - dir * 0.1, tbMid + dir * 0.1, r: 0.0235, steel, sides: 8)
            for s: Float in [-1, 1] { FA.rod(&m, tbMid + dir * s * 0.105, tbMid + dir * s * 0.125, r: 0.0205, steel, sides: 6) }
            // Anchor plate with four bolts and a clevis lug.
            FA.box(&m, V3(0.3, 0.03, 0.3), V3(anchor.x, 0.015, anchor.z), "metal.galvanized-aged", r: 0.004, rot: rot)
            for (a, b) in [(-1, -1), (-1, 1), (1, -1), (1, 1)] as [(Float, Float)] {
                let off = outD * a * 0.12 + V3(-outD.z, 0, outD.x) * b * 0.12
                FSH.nut(&m, at: V3(anchor.x, 0.03, anchor.z) + off, normal: FA.Y, size: 0.024, "metal.rust")
            }
            for s: Float in [-1, 1] {
                FA.box(&m, V3(0.05, 0.075, 0.01), V3(anchor.x, 0.07, anchor.z) + V3(-outD.z, 0, outD.x) * s * 0.02 - dir * 0.0, steel, r: 0.002, rot: rot)
            }
            // dust and water stain on the plate
            FA.box(&m, V3(0.09, 0.0015, 0.09), V3(anchor.x, 0.031, anchor.z) - outD * 0.08, "metal.rust-grime", r: 0.0004, rot: rot)
        }
        _ = rng.float()
        groundAO(&m, height: 0.1, floor: 0.8)
        return LODModel(FC.place(m))
    }
}
