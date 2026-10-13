import simd
import Foundation

/// Ozark river gravel bar, 26 m long (along +X, the flow) and 9 m wide: a low whaleback of rounded chert and
/// sandstone gravel rising 0.55 m above its toe, coarse cobble armor at the upstream head (-X) fining to pea
/// gravel at the tail, a dry crest and a dark wet band at the waterline, shallow flood swales. The toe sinks
/// below y = 0 so the bar meets water or ground without a seam. 2 LODs.
public struct GravelBar: RealAsset {
    public static let id = "gravel-bar"
    public static let summary = "River gravel bar, 26 x 9 m: low whaleback of rounded gravel, cobble head, fine tail, wet waterline band, flood swales, 2 LODs."
    public static let tags = ["nature", "ground", "rock", "water", "river"]
    public static let budget = 30_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 30, distance: 0.8)

    /// Length along the flow (+X) and width in meters.
    public var length: Float = 26
    public var width: Float = 9
    /// Crest height above the toe in meters.
    public var crest: Float = 0.55
    /// Loose cobbles on the surface.
    public var cobbles = 170
    /// Fraction of the bar (from the rim inward) that reads wet.
    public var wetBand: Float = 0.12
    public var material: MaterialKey = "ground.river-gravel"
    public var wetMaterial: MaterialKey = "ground.river-gravel-wet"
    public var lodDistances: [Float] = [35]
    public init() {}

    /// Bar surface height at (x, z) in asset space, for placing things on the bar.
    public func height(x: Float, z: Float, seed: UInt64) -> Float {
        let ns = UInt32(truncatingIfNeeded: seed) &+ 3
        let a = length / 2, b = width / 2
        let t = sqrt((x / a) * (x / a) + (z / b) * (z / b))
        return surfaceHeight(V2(x, z), t: t, ns: ns) + 0.14
    }

    func surfaceHeight(_ p: V2, t: Float, ns: UInt32) -> Float {
        // Whaleback, crest shifted toward the head and the bank side (-Z); the toe dips below 0.
        let q = V2(p.x / (length / 2) + 0.15, p.y / (width / 2) + 0.2)
        let dome = max(0, 1 - simd_length_squared(q * V2(0.95, 1.05)))
        var h = crest * pow(dome, 0.7)
        // Flood swales: shallow troughs running with the flow.
        h -= 0.06 * smoothstep(0.2, 0.6, Noise.fbm(V3(p.x * 0.05, 0.3, p.y * 0.35), octaves: 2, seed: ns))
        h += Noise.fbm(V3(p.x * 0.6, 0.7, p.y * 0.6), octaves: 3, seed: ns &+ 1) * 0.03
        return h - smoothstep(0.85, 1, t) * 0.12
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let ns = UInt32(truncatingIfNeeded: seed) &+ 3
        let a = length / 2, b = width / 2
        func outline(_ ang: Float) -> Float {
            let e = 1 / sqrt(pow(cos(ang) / a, 2) + pow(sin(ang) / b, 2))
            return e * (1 + 0.12 * cos(ang)) * (1 + Noise.fbm(V3(cos(ang) * 2, sin(ang) * 2, 0.5), octaves: 3, seed: ns &+ 7) * 0.3)
        }
        func bed(rings: Int, sectors: Int) -> [Surface] {
            let s = GroundMesh.disc(material: material, rings: rings, sectors: sectors, outline: outline) { p, t in surfaceHeight(p, t: t, ns: ns) }
            // Wet band: triangles near the rim (low) move to the wet material.
            let (dry, wet) = ConiferBuild.split(s, material: wetMaterial) { c in
                c.y < crest * wetBand * 0.8 + Noise.fbm(V3(c.x * 0.4, 0, c.z * 0.4), octaves: 2, seed: ns &+ 9) * 0.04
            }
            return [dry, wet].map { var x = $0; x.occlusion = x.positions.map { 0.82 + 0.18 * smoothstep(-0.1, crest * 0.5, $0.y) }; x.computeTangents(); return x }
        }
        var m0 = Model(name: Self.id), m1 = Model(name: Self.id)
        for s in bed(rings: 30, sectors: 96) { m0.add(s) }
        for s in bed(rings: 14, sectors: 48) { m1.add(s) }
        // Loose cobbles: coarse at the head (-X), finer toward the tail.
        var cob0 = Surface(material: "rock.cobble-dry"), cob1 = Surface(material: "rock.cobble-dry")
        var wet0 = Surface(material: "rock.cobble-wet"), wet1 = Surface(material: "rock.cobble-wet")
        for i in 0..<cobbles {
            let ang = rng.float(0...(2 * .pi)), rr = sqrt(rng.float()) * 0.97
            let p = V2(cos(ang), sin(ang)) * outline(ang) * rr
            let head = smoothstep(0.6, -0.8, p.x / a)
            let sz = rng.float(0.05...0.1) + head * rng.float(0...0.12)
            let size = V3(sz, sz * rng.float(0.35...0.5), sz * rng.float(0.65...0.85))
            let si = UInt32(truncatingIfNeeded: i) &+ ns
            let y = surfaceHeight(p, t: rr, ns: ns) + size.y * rng.float(0.05...0.3)
            let x = Xform(translation: V3(p.x, y, p.y), rotation: simd_quatf(degrees: rng.float(-30...30), axis: .up) * simd_quatf(degrees: rng.float(-10...10), axis: V3(0, 0, 1)))
            let isWet = y < crest * wetBand
            for (lod, sub) in [(0, 3), (1, 2)] {
                if lod == 1 && sz < 0.09 { continue }
                var s = Prim.cubeSphere(subdivisions: sub, material: "rock.cobble-dry") { d in
                    simd_normalize(d) * (1 + Noise.fbm(d * 1.5, octaves: 2, seed: si) * 0.2) * size
                }
                s.recomputeNormals(); s.computeTangents()
                switch (lod, isWet) {
                case (0, false): cob0.append(s, x)
                case (0, true): wet0.append(s, x)
                case (_, false): cob1.append(s, x)
                default: wet1.append(s, x)
                }
            }
        }
        for var s in [cob0, wet0] where !s.isEmpty { s.occlusion = s.positions.map { _ in 0.85 }; m0.add(s) }
        for var s in [cob1, wet1] where !s.isEmpty { s.occlusion = s.positions.map { _ in 0.85 }; m1.add(s) }
        // Lift so the sunken toe sits at y = 0.
        let up = Xform(translation: V3(0, 0.14, 0))
        return LODModel(levels: [m0.transformed(up), m1.transformed(up)], switchDistances: lodDistances)
    }
}
