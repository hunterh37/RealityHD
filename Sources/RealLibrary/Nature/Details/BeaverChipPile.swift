import simd
import Foundation

/// Pile of beaver-cut wood chips on trampled mud, 35 cm across and 5 cm high, pale curved slivers 4 to 11 cm long.
public struct BeaverChipPile: RealAsset {
    public static let id = "beaver-chip-pile"
    public static let summary = "Pile of beaver-cut wood chips on trampled mud, 35 cm across, pale curved slivers 4 to 11 cm long."
    public static let tags = ["nature", "wood", "ground"]
    public static let budget = 2400
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 50, distance: 0.7)
    public init() {}

    struct Chip { var pos: V3, yaw: Float, pitch: Float, roll: Float, len: Float, wid: Float, thick: Float, bend: Float, cup: Float, tone: Int }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let Rp: Float = 0.17
        var chips: [Chip] = []
        for _ in 0..<38 {
            let d = rng.inDisc(radius: Rp), f = 1 - simd_length(d) / Rp
            let tilt = 0.15 + 0.35 * f
            chips.append(Chip(pos: V3(d.x, 0.007 + 0.034 * pow(f, 1.1) * rng.float(0.4...1), d.y), yaw: rng.float(0...(2 * .pi)),
                              pitch: rng.float(-tilt...tilt), roll: rng.float(-tilt...tilt), len: rng.float(0.04...0.11), wid: rng.float(0.012...0.026),
                              thick: rng.float(0.003...0.006), bend: rng.float(0.004...0.014), cup: rng.float(0.002...0.006), tone: rng.int(0...2)))
        }
        let outline = DetailKit11.Harmonics(&rng, count: 4, lowest: 2)
        func level(nu: Int, nv: Int, mudSegs: Int) -> Model {
            var mud = Surface(material: "ground.mud:4A3A2B")
            let c = mud.add(V3(0, 0.012, 0), V3(0, 1, 0), V2(0.5, 0.5))
            var ring: [UInt32] = []
            for k in 0...mudSegs {
                let a = Float(k % mudSegs) / Float(mudSegs) * 2 * .pi, r = (Rp + 0.03) * (1 + 0.14 * outline(a))
                ring.append(mud.add(V3(cos(a) * r, 0.001, sin(a) * r), V3(0, 1, 0), V2(0.5 + cos(a) * r * 2, 0.5 + sin(a) * r * 2)))
            }
            for k in 0..<mudSegs { mud.tri(c, ring[k + 1], ring[k]) }
            var tones = [Surface(material: "wood.pine:EBD9AE"), Surface(material: "wood.pine:D2B887"), Surface(material: "wood.pine:B8966A")]
            var unders = [Surface(material: "wood.pine:C9AE80"), Surface(material: "wood.pine:B49A6E"), Surface(material: "wood.pine:9E825A")]
            for ch in chips {
                let L = ch.len, W = ch.wid
                let (t, u) = DetailKit11.slab(nu: nu, nv: nv, uvScale: V2(L, W), topMaterial: "wood.pine", underMaterial: "wood.pine", thickness: { _, _ in ch.thick }, point: { a, b in
                    let hw = W / 2 * pow(sin(Float.pi * (0.04 + 0.92 * a)), 0.55) * (a < 0.5 ? 1 : 0.85)
                    let z = (2 * b - 1) * hw
                    let y = ch.bend * (1 - pow(2 * a - 1, 2)) + ch.cup * pow(2 * b - 1, 2)
                    return V3((a - 0.5) * L, y, z)
                })
                let x = Xform(translation: ch.pos, rotation: simd_quatf(angle: ch.yaw, axis: V3(0, 1, 0)) * simd_quatf(angle: ch.pitch, axis: V3(0, 0, 1)) * simd_quatf(angle: ch.roll, axis: V3(1, 0, 0)))
                tones[ch.tone].append(t, x); unders[ch.tone].append(u, x)
            }
            var m = Model(name: Self.id)
            m.add(mud)
            for var s in tones + unders { s.computeTangents(); m.add(s) }
            var mm = m
            groundAO(&mm)
            return mm
        }
        let hi = level(nu: 3, nv: 2, mudSegs: 24), lo = level(nu: 2, nv: 1, mudSegs: 12)
        return LODModel(levels: [hi, lo], switchDistances: [1.5])
    }
}
