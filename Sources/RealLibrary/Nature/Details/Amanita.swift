import simd
import Foundation

/// Single fly agaric, 12 cm cap on a 9.5 cm stalk: domed red cap with an inrolled margin and 40 white
/// warts, cream gills, hanging ring skirt, swollen scaly bulb base, and 18 curled dry leaves around it.
public struct Amanita: RealAsset {
    public static let id = "amanita"
    public static let summary = "Single red fly agaric, 12 cm cap with white warts, gills, hanging ring skirt, bulb base and surrounding leaf litter; 2 LODs."
    public static let tags = ["nature", "fungus", "plant"]
    public static let budget = 3_600
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 20, distance: 0.45)

    public init() {}

    public func build(seed: UInt64) -> LODModel {
        DetailKit04.lods { lod in
            var rng = SeededRNG(seed: seed)
            let ns = UInt32(truncatingIfNeeded: seed)
            var m = Model(name: Self.id)
            let seg = lod == 0 ? 24 : 12, bands = lod == 0 ? 8 : 4
            let R: Float = 0.06, y0: Float = 0.095, H = R * 0.62
            func irregular(_ s: inout Surface, amt: Float, f: Float) {
                s.deform { v in
                    let a = atan2(v.z, v.x)
                    let k = 1 + amt * (Noise.perlin(V3(cos(a), v.y * f, sin(a)) * 3, seed: ns) + 0.6 * sin(2 * a + 1.3))
                    return V3(v.x * k, v.y, v.z * k)
                }
            }
            // Cap: rim to apex, outward normals; margin rolls under.
            func capPoint(_ ph: Float) -> V2 { V2(R * pow(cos(ph), 0.8), y0 + 0.1 * R + H * sin(ph)) }
            var cap: [V2] = [V2(R * 0.9, y0 + 0.01 * R), V2(R * 0.985, y0 + 0.05 * R)]
            for k in 1...bands { var p = capPoint(Float(k) / Float(bands) * .pi / 2); if k == bands { p.x = 0 }; cap.append(p) }
            var capS = Prim.lathe(cap, segments: seg, seamTile: 0.08, material: "fungus.cap:c4201a")
            irregular(&capS, amt: 0.03, f: 20)
            m.add(capS)
            // Gills.
            var gills = Prim.lathe([V2(0.011, y0 + 0.012), V2(R * 0.9, y0 + 0.002)], segments: seg, seamTile: 0.03, material: "fungus.gills:efe6cf")
            irregular(&gills, amt: 0.03, f: 20)
            m.add(gills)
            // Warts: flattened white cones oriented to the cap normal.
            for i in 0..<(lod == 0 ? 40 : 20) {
                var wr = rng.fork(i)
                let ph = wr.float(0.08...1.25), a = wr.float(0...6.28)
                let p = capPoint(ph), q = capPoint(ph + 0.02)
                let dr = q.x - p.x, dy = q.y - p.y
                let n2 = V2(dy, -dr) / max(1e-6, simd_length(V2(dy, -dr)))
                let nrm = V3(n2.x * cos(a), n2.y, n2.x * sin(a)).normalized
                let w = wr.float(0.0022...0.0048) * (1.15 - ph * 0.4)
                let wart = Prim.lathe([V2(w, 0), V2(w * 0.8, w * 0.35), V2(w * 0.35, w * 0.55), V2(0, w * 0.6)], segments: lod == 0 ? 9 : 5,
                                      seamTile: 0.01, material: "fungus.stalk:f6f2e6")
                let pos = V3(p.x * cos(a), p.y, p.x * sin(a)) - nrm * 0.0012
                m.add(wart, Xform(translation: pos, rotation: simd_quatf(from: .up, to: nrm) * simd_quatf(angle: wr.float(0...6), axis: .up), scale: V3(1, 1, wr.float(0.8...1.2))))
            }
            // Stalk with bulb.
            var stalk = Prim.lathe([V2(0.012, -0.004), V2(0.024, 0.004), V2(0.0265, 0.018), V2(0.0225, 0.032), V2(0.0145, 0.046), V2(0.0125, 0.07), V2(0.0115, y0 + 0.012)],
                                   segments: lod == 0 ? 14 : 8, seamTile: 0.04, material: "fungus.stalk:ece5d2")
            irregular(&stalk, amt: 0.035, f: 30)
            m.add(stalk)
            // Ring skirt, both faces, drooping and ragged.
            let ringTop = V2(0.0125, 0.08), ringEdge = V2(0.033, 0.052)
            for (prof, off) in [([ringTop, V2(0.022, 0.066), ringEdge], Float(0)), ([ringEdge - V2(0.0008, 0.0008), V2(0.022, 0.065), ringTop - V2(0, 0.001)], Float(-0.0008))] {
                var skirt = Prim.lathe(prof.map { V2($0.x + off, $0.y) }, segments: lod == 0 ? 20 : 10, seamTile: 0.04, material: "fungus.stalk:f2eddc")
                skirt.deform { v in
                    let a = atan2(v.z, v.x), edge = max(0, (simd_length(V2(v.x, v.z)) - 0.02) / 0.013)
                    return V3(v.x, v.y - 0.004 * edge * (0.5 + 0.5 * sin(5 * a + 0.7)) - 0.003 * edge * Noise.perlin(V3(a * 2, 1, 0), seed: ns), v.z)
                }
                m.add(skirt)
            }
            // Leaf litter.
            for i in 0..<(lod == 0 ? 18 : 10) {
                var lr = rng.fork(200 + i)
                let p = lr.inDisc(radius: 0.13)
                if simd_length(p) < 0.03 { continue }
                let c = PlantKit.cell(lr.int(0...15), cols: 4, rows: 4)
                var b = PlantKit.Blade()
                b.length = lr.float(0.05...0.1); b.width = b.length; b.yaw = lr.float(0...6.28)
                let d = V3(cos(b.yaw), 0, sin(b.yaw))
                b.root = V3(p.x, 0.002 + Float(i) * 0.0004, p.y) - d * b.length / 2
                b.constantWidth = true; b.tipWidth = 1
                b.lean = lr.float(1.42...1.56); b.curl = lr.float(-0.05...0.08); b.segments = 1; b.fold = lod == 0 ? lr.float(-0.15...0.04) : 0
                b.u = V2(c.origin.x, c.origin.x + c.size.x); b.v = V2(c.origin.y, c.origin.y + c.size.y)
                b.weight = V2(0, 0); b.ao = V2(0.75, 0.9); b.upNormal = 0.2
                m.add(PlantKit.blade(b, material: "litter.dry"))
            }
            PlantKit.finish(&m)
            groundAO(&m, height: 0.05, floor: 0.6)
            return m
        }
    }
}
