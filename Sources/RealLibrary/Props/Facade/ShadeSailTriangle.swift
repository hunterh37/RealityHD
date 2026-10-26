import simd
import Foundation

/// Triangular HDPE shade sail, about 3.8 m sides: a knitted sand fabric panel with edges that sag inward
/// between three corners set at different heights (hyperbolic-paraboloid twist), a sewn webbing hem with
/// stitch rows, triple-layer corner reinforcement patches with stainless grommets, D-rings, shackles,
/// turnbuckles on eye bolts and a wall eye plate at each corner. Faded centre, dirtier corners and edges.
public struct ShadeSailTriangle: RealAsset {
    public static let id = "shade-sail-triangle"
    public static let summary = "Triangular HDPE shade sail, 4 m sides, tensioned from three stainless corner rings with turnbuckles and wall eye plates."
    public static let tags = ["prop", "architecture", "facade", "metal", "fabric"]
    public static let budget = 13000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 28, distance: 1.9, studio: true)

    /// Side length between corner rings (m).
    public var side: Float = 3.2
    /// Corner heights above the lowest corner (m): twist of the sail.
    public var cornerHeights: [Float] = [0.015, 0.0, 0.01]
    /// Edge sag as a fraction of edge length.
    public var sag: Float = 0.10
    /// Fabric colour (sRGB hex).
    public var fabricColor: UInt32 = 0xB7A98F
    public var steel: MaterialKey = "metal.stainless"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let s = side, h = s * 1.02
        let c2: [V2] = [V2(-s / 2, -h / 3), V2(s / 2, -h / 3), V2(0, 2 * h / 3)]
        let hts = cornerHeights
        let N = 22
        let cen = V2(0, 0)
        // Barycentric grid with edge sag toward the centre.
        func pt(_ i: Int, _ j: Int) -> V3 {
            let a = Float(i) / Float(N), b = Float(j) / Float(N), c = 1 - a - b
            var p = c2[0] * c + c2[1] * a + c2[2] * b
            let k0 = max(0, 1 - 3 * c), k1 = max(0, 1 - 3 * a), k2 = max(0, 1 - 3 * b)
            let pull = (a * b * k0 * k0 + b * c * k1 * k1 + a * c * k2 * k2) * 4 * sag * 1.9
            p += (cen - p) * min(pull, 0.95)
            let y = hts[0] * c + hts[1] * a + hts[2] * b - 0.05 * (a * b * c) * 9 - 0.01 * sin(a * 9) * sin(b * 7)
            return V3(p.x, y, p.y)
        }
        func idx(_ i: Int, _ j: Int) -> UInt32 { UInt32(j * (N + 1) - j * (j - 1) / 2 + i) }
        let Z = 6
        let zoneMats: [MaterialKey] = (0..<Z).map { z in
            let t = Float(z) / Float(Z - 1)
            return FSH.canvas(fabricColor, fade: 0.2 * (1 - t), dirt: 0.04 + 0.36 * t, family: "fabric.nylon")
        }
        var layers: [Surface] = zoneMats.map { Surface(material: $0) }
        for z in 0..<Z {
            for j in 0...N { for i in 0...(N - j) {
                let p = pt(i, j)
                _ = layers[z].add(p, .up, V2(p.x, p.z) * 1.0)
            } }
        }
        for j in 0..<N { for i in 0..<(N - j) {
            let a = Float(i) / Float(N), b = Float(j) / Float(N), c = 1 - a - b
            let cornerNear = max(a, max(b, c)), edgeNear = min(a, min(b, c))
            let t = max(0, min(1, max((cornerNear - 0.5) / 0.45, (0.12 - edgeNear) / 0.12 * 0.5 + (rng.float() * 0.06))))
            let z = min(Z - 1, Int(t * Float(Z)))
            layers[z].tri(idx(i, j), idx(i + 1, j), idx(i, j + 1))
            if i + j + 1 < N { layers[z].tri(idx(i + 1, j), idx(i + 1, j + 1), idx(i, j + 1)) }
        } }
        for z in 0..<Z where !layers[z].indices.isEmpty {
            layers[z].recomputeNormals(weldSeams: true)
            layers[z].computeTangents()
            m.add(layers[z])
            m.add(layers[z].flipped(), Xform(translation: V3(0, -0.0025, 0)))
        }
        // Edge webbing: tube along each curved edge, with a stitch row inside it.
        let web = "fabric.webbing"
        func edge(_ k0: Int, _ k1: Int) -> [V3] {
            (0...N).map { t in
                let f = Float(t) / Float(N)
                // corner indices: 0 -> (a0,b0), 1 -> (a1,b0), 2 -> (a0,b1)
                let ab: [V2] = [V2(0, 0), V2(1, 0), V2(0, 1)]
                let q = ab[k0] * (1 - f) + ab[k1] * f
                let i = Int((q.x * Float(N)).rounded()), j = Int((q.y * Float(N)).rounded())
                return pt(i, j)
            }
        }
        for (k0, k1) in [(0, 1), (1, 2), (2, 0)] {
            let e = edge(k0, k1)
            let up = e.map { $0 + V3(0, 0.003, 0) }
            m.add(Prim.tube(up, radii: Array(repeating: 0.0085, count: up.count), sides: 6, seamTile: 0.1, material: web, capEnd: true))
            // stitch row 22 mm inside the hem
            let inner = e.map { p -> V3 in let d = simd_normalize(V3(-p.x, 0, -p.z)); return p + d * 0.022 + V3(0, 0.0025, 0) }
            m.add(stitches(along: inner, normal: { _ in V3(0, 1, 0) }, pitch: 0.03, thread: 0.0009, material: "fabric.canvas:6B5F4A"), Xform())
        }
        // Corners: reinforcement patches, grommet, D-ring, shackle, eye bolt, turnbuckle, wall eye plate.
        for k in 0..<3 {
            let C = pt(k == 1 ? N : 0, k == 2 ? N : 0)
            let out = simd_normalize(V3(c2[k].x, 0, c2[k].y))
            let rot = simd_quatf(angle: atan2(-out.z, out.x), axis: V3(0, 1, 0))
            for layer in 0..<3 {
                let L: Float = 0.2 - Float(layer) * 0.045
                let tri: [V2] = [V2(0.0, -L * 0.62), V2(-L * 0.18, 0), V2(0.0, L * 0.62), V2(L, 0)]
                m.add(Prim.extrude(Shape2D.rounded(tri.reversed(), radius: 0.01, segments: 1), depth: 0.004, bevel: 0.0008, bevelSegments: 1, material: web),
                      Xform(translation: C - out * (L * 0.88) + V3(0, 0.004 + Float(layer) * 0.004, 0) , rotation: rot * FA.q(-90, FA.X)))
            }
            let ringC = C + out * 0.034 + V3(0, 0.006, 0)
            // D-ring through the grommet.
            let axis = simd_normalize(simd_cross(V3(0, 1, 0), out))
            m.add(Prim.torus(major: 0.025, minor: 0.0055, segments: 18, sides: 6, material: steel), Xform(translation: ringC, rotation: facing(axis)))
            FC.bead(&m, r: 0.013, at: C + V3(0, 0.014, 0) - out * 0.04, steel, sub: 4)
            // Shackle, eye bolt, turnbuckle (two threaded rods, body with flats), second eye bolt.
            let p0 = ringC + out * 0.045
            FA.rod(&m, p0, p0 + out * 0.07, r: 0.0055, steel, sides: 6)
            let t0 = p0 + out * 0.07, t1 = t0 + out * 0.16
            FA.rod(&m, t0, t1, r: 0.0125, steel, sides: 8)
            FA.box(&m, V3(0.028, 0.03, 0.026), (t0 + t1) / 2, steel, r: 0.004, rot: rot)
            let p3 = t1 + out * 0.09
            FA.rod(&m, t1, p3, r: 0.0055, steel, sides: 6)
            m.add(Prim.torus(major: 0.016, minor: 0.0055, segments: 12, sides: 5, material: steel), Xform(translation: t1 + out * 0.01, rotation: facing(axis)))
            m.add(Prim.torus(major: 0.016, minor: 0.0055, segments: 12, sides: 5, material: steel), Xform(translation: p3, rotation: facing(axis)))
            // Wall eye plate with four bolts and a pad eye.
            let wp = p3 + out * 0.025
            FA.box(&m, V3(0.012, 0.075, 0.1), wp + out * 0.006, "metal.galvanized-aged", r: 0.003, rot: rot)
            for (dy, dz) in [(-1, -1), (-1, 1), (1, -1), (1, 1)] as [(Float, Float)] {
                let off = V3(0, dy * 0.03, 0) + V3(-out.z, 0, out.x) * dz * 0.035
                hexBolt(&m, at: wp - out * 0.002 + off, normal: -out, size: 0.016, material: "metal.screw-zinc")
            }
            m.add(Prim.torus(major: 0.014, minor: 0.0055, segments: 14, sides: 6, material: steel), Xform(translation: wp - out * 0.02, rotation: facing(axis)))
            // water stain (rust-free): dark patch on the fabric by the corner
            FA.box(&m, V3(0.12, 0.0012, 0.12), C - out * 0.32 + V3(0, 0.0025 + 0.0, 0), FSH.canvas(fabricColor, dirt: 0.6, family: "fabric.nylon"), r: 0.0004, rot: rot)
        }
        _ = rng.float()
        groundAO(&m, height: 0.02, floor: 0.9)
        return LODModel(FC.place(m))
    }
}
