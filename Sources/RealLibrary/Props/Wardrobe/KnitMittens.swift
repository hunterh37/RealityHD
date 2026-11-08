import simd
import Foundation

/// Pair of hand-knit wool mittens lying flat, each 27 cm long and 11 cm wide: red body with two white cable
/// columns crossing every 3 cm and a red center cable, white 7 cm 2x2 ribbed cuff, gusset thumb. The left mitten
/// lies offset and turned against the right one.
public struct KnitMittens: RealAsset {
    public static let id = "knit-mittens"
    public static let summary = "Pair of red and white cable-knit wool mittens, 27 cm, ribbed cuffs and thumbs, lying offset."
    public static let tags = ["prop", "interior", "wardrobe", "fabric", "winter"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 48, distance: 0.95, studio: true)

    public var body: MaterialKey = "fabric.knit"
    public var accent: MaterialKey = "fabric.knit:EEE8DC"
    /// Mitten length, cuff to tip (m).
    public var length: Float = 0.27
    /// Palm width, flat (m).
    public var width: Float = 0.108
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let right = mitten(&rng, mirror: 1)
        let left = mitten(&rng, mirror: -1)
        m.add(right, Xform(translation: V3(0.062, 0, 0.0), rotation: simd_quatf(degrees: -8, axis: .up)))
        m.add(left, Xform(translation: V3(-0.07, 0.0, 0.045), rotation: simd_quatf(degrees: 14, axis: .up)))
        let b = m.bounds
        m = m.transformed(Xform(translation: V3(-(b.min.x + b.max.x) / 2, -b.min.y, -(b.min.z + b.max.z) / 2)))
        groundAO(&m, height: 0.02, floor: 0.6)
        return LODModel(m)
    }

    /// One mitten built upright along +Y (cuff at y 0, palm facing -Z), then laid flat with the back of the hand up.
    private func mitten(_ rng: inout SeededRNG, mirror: Float) -> Model {
        var m = Model(name: "mitten")
        let L = length, W = width, cuff: Float = 0.07
        // Half width and half thickness along the length.
        func hw(_ y: Float) -> Float {
            if y < cuff { return W * 0.43 - 0.004 * sin(y / cuff * .pi) }
            let t = (y - cuff) / (L - cuff)
            let base = W * 0.5 * (0.88 + 0.12 * sin(min(1, t * 1.6) * .pi / 2))
            let tip = t > 0.72 ? sqrt(max(0, 1 - pow((t - 0.72) / 0.28, 2))) : 1
            return max(0.002, base * tip)
        }
        func ht(_ y: Float) -> Float {
            let t = y / L
            let tip = t > 0.78 ? sqrt(max(0, 1 - pow((t - 0.78) / 0.22, 2))) : 1
            return max(0.0015, (0.017 - 0.003 * t) * tip)
        }
        // Body loft: superellipse sections, 2x2 rib wobble on the cuff.
        func rings(y0: Float, y1: Float, n: Int, ribs: Bool) -> [[V3]] {
            (0...n).map { k in
                let y = y0 + (y1 - y0) * Float(k) / Float(n)
                let pts = Shape2D.superellipse(hw(y) * 2, ht(y) * 2, exponent: 2.4, segments: 48)
                let rib: (V2) -> V2 = { p in
                    guard ribs else { return p }
                    let a = atan2(p.y, p.x)
                    return p * (1 + 0.05 * max(0, sin(a * 12)))
                }
                return Prim.ring(pts.map(rib), y: y)
            }
        }
        m.add(Prim.loft(rings(y0: 0, y1: cuff, n: 8, ribs: true), capStart: true, material: accent))
        m.add(Prim.loft(rings(y0: cuff - 0.002, y1: L, n: 30, ribs: false), capEnd: true, material: body))
        // Cuff turn-back roll at the opening.
        m.add(Prim.loft(rings(y0: 0.0, y1: 0.006, n: 1, ribs: true).map { $0.map { V3($0.x * 1.06, $0.y, $0.z * 1.2) } }, capStart: true, material: accent))
        // Thumb: tapered tube from the side gusset, angled out.
        let tx = mirror * hw(0.11) * 0.82
        var tpath: [V3] = [], trad: [Float] = []
        for k in 0...9 {
            let t = Float(k) / 9
            tpath.append(V3(tx + mirror * (0.022 * t + 0.01 * t * t), 0.098 + 0.07 * t, 0.002 - 0.003 * t))
            trad.append(0.0155 * (t < 0.8 ? 1 - 0.18 * t : sqrt(max(0.02, 1 - pow((t - 0.8) / 0.2, 2))) * 0.86))
        }
        var thumb = Prim.tube(tpath, radii: trad, sides: 32, seamTile: 0.06, material: body)
        thumb.deform { p in V3(p.x, p.y, p.z * 0.72) }
        m.add(thumb)
        // Cable columns on the back of the hand (+Z face): two strands crossing, white on the sides, red in the center.
        for (cx, mat) in [(Float(-0.026), accent), (0.026, accent)] as [(Float, MaterialKey)] {
            for phase: Float in [0, .pi] {
                var path: [V3] = [], radii: [Float] = []
                let y0 = cuff + 0.006, y1 = L * 0.82
                for k in 0...36 {
                    let y = y0 + (y1 - y0) * Float(k) / 36
                    let x = cx * hw(y) / (W * 0.5) + 0.0042 * sin((y - y0) / 0.03 * 2 * .pi + phase)
                    let z = ht(y) * sqrt(max(0, 1 - pow(abs(x) / hw(y), 2.4))) + 0.0012 + 0.0006 * cos((y - y0) / 0.03 * 2 * .pi + phase)
                    path.append(V3(x, y, z)); radii.append(0.0034)
                }
                m.add(Prim.tube(path, radii: radii, sides: 8, seamTile: 0.02, material: mat))
            }
        }
        // White stripe rings above the cuff.
        for y: Float in [cuff + 0.004] {
            let pts = Shape2D.superellipse(hw(y) * 2 + 0.003, ht(y) * 2 + 0.003, exponent: 2.4, segments: 48)
            m.add(Prim.loft([Prim.ring(pts, y: y), Prim.ring(pts, y: y + 0.006)], material: accent))
        }
        // Lay flat: back of hand up, slight sag and per-mitten jitter.
        let sag = rng.float(0.002...0.005)
        var out = Model(name: "mitten")
        for var s in m.surfaces {
            s.deform { p in V3(p.x, p.y, p.z * 0.92 - sag * pow(p.y / L - 0.5, 2) * 4) }
            out.add(s, Xform(rotation: simd_quatf(degrees: -90, axis: V3(1, 0, 0))))
        }
        return out
    }
}
