import simd
import Foundation

/// Hickory nuts, 3 cm: five pale ridged nuts among four split husk quarters, dark rind with pale inner face.
public struct HickoryNuts: RealAsset {
    public static let id = "hickory-nuts"
    public static let summary = "Five hickory nuts, 3 cm, with four split dark husk quarters lying open on the ground; 2 LODs."
    public static let tags = ["nature", "plant", "ground"]
    public static let budget = 7_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 50, distance: 0.5)
    public init() {}

    /// One husk valve: a curved shell, pole along -X, convex side up (+Y), thick rind with sutures.
    static func valve(R: Float, thick: Float, sweep: Float, polarMax: Float, n: Int, rng: inout SeededRNG) -> [Surface] {
        func rows(_ rad: Float, _ pm: Float) -> [[V3]] {
            (0...n).map { i in
                let th = pm * Float(i) / Float(n)
                return (0...n).map { k in
                    let e = Float(k) / Float(n)
                    let ph = Float.pi / 2 + (e - 0.5) * sweep
                    let rib = 1 + 0.1 * smoothstep(0.78, 1, abs(e - 0.5) * 2) + 0.03 * sin(th * 9 + Float(k) * 1.3)
                    let r = rad * rib * (1 + 0.04 * sin(th * 5 + ph * 3))
                    return V3(-cos(th), sin(th) * sin(ph), sin(th) * cos(ph)) * r
                }
            }
        }
        let ro = rows(R, polarMax), ri = rows(R - thick, polarMax - 0.06)
        let uv = (0...n).map { i in (0...n).map { k in V2(Float(k) / Float(n) * 0.04, Float(i) / Float(n) * 0.04) } }
        var o = WoodParts.grid(ro, uvs: uv, material: "bark.dead:3B2B1D")
        var inn = WoodParts.grid(ri, uvs: uv, material: "bark.dead:8C7050")
        WoodParts.orientOutward(&o) { _ in .zero }
        WoodParts.orientOutward(&inn) { _ in .zero }
        for t in stride(from: 0, to: inn.indices.count, by: 3) { inn.indices.swapAt(t + 1, t + 2) }
        o.recomputeNormals(weldSeams: false); inn.recomputeNormals(weldSeams: false)
        var out = [o, inn]
        let edgeMat: MaterialKey = "bark.dead:6A5238"
        out.append(DetailKit21.strip(ro.map { $0[0] }, ri.map { $0[0] }, material: edgeMat))
        out.append(DetailKit21.strip(ro.map { $0[n] }, ri.map { $0[n] }, material: edgeMat))
        out.append(DetailKit21.strip(ro[n], ri[n], material: edgeMat))
        return out
    }

    public func build(seed: UInt64) -> LODModel {
        DetailKit07.lods(seed: seed, switchAt: 3) { lod, rng in
            var all: [Surface] = []
            var spots: [V2] = []
            func spot(_ rad: Float, _ sep: Float) -> V2 {
                var p = rng.inDisc(radius: rad), t = 0
                while t < 40, spots.contains(where: { simd_distance($0, p) < sep }) { p = rng.inDisc(radius: rad); t += 1 }
                spots.append(p); return p
            }
            for _ in 0..<4 {
                let p = spot(0.12, 0.05)
                var parts = Self.valve(R: rng.float(0.019...0.023), thick: 0.0028, sweep: rng.float(1.35...1.6), polarMax: rng.float(1.75...2.05), n: lod == 0 ? 8 : 4, rng: &rng)
                let roll = rng.float(-0.9...0.9), pitch = rng.float(-0.35...0.5)
                parts = DetailKit21.put(parts, yaw: rng.float(0...6.28), tilt: V2(roll, pitch), at: .zero)
                DetailKit21.dropTo(&parts, y: 0.0005)
                DetailKit07.shift(&parts, V3(p.x, 0, p.y))
                all += parts
            }
            let nutTints = ["C9AB7C", "BE9C6C", "D2B88C", "B08C5E", "C4A272"]
            for i in 0..<5 {
                let p = spot(0.11, 0.032)
                let rad = V3(rng.float(0.0125...0.0145), rng.float(0.015...0.0175), rng.float(0.0115...0.0135))
                var nut = DetailKit15.blob(at: .zero, radii: rad, lump: 0.1, fine: 0.03, sub: lod == 0 ? 8 : 4, material: MaterialKey("wood.walnut:" + nutTints[i]), rng: &rng, ridges: 4, ridgeDepth: 0.05)
                // Pointed tip toward +Y.
                for j in nut.positions.indices {
                    let up = max(0, nut.positions[j].y / rad.y)
                    nut.positions[j].x *= 1 - 0.35 * up * up; nut.positions[j].z *= 1 - 0.35 * up * up
                }
                nut.recomputeNormals(weldSeams: false)
                var parts = [nut]
                parts = DetailKit21.put(parts, yaw: rng.float(0...6.28), tilt: V2(rng.float(-1.4...1.4), rng.float(-1.4...1.4)), at: .zero)
                DetailKit21.dropTo(&parts, y: 0.0005)
                DetailKit07.shift(&parts, V3(p.x, 0, p.y))
                all += parts
            }
            DetailKit07.settle(&all, sink: 0.003, center: true)
            return DetailKit21.finish(Self.id, all, aoHeight: 0.025, floor: 0.55)
        }
    }
}
