import simd
import Foundation

/// Military dog tag necklace: 60 cm stainless ball chain (3.4 mm beads, 147 individually swelled beads) with a bead
/// connector at the nape, two stamped 51 x 28.5 mm stainless tags hanging at the sternum on the chain, raised rim,
/// embossed text rows, black rubber silencer on the front tag, and the rear tag swung off at an angle.
public struct DogTagChain: RealAsset {
    public static let id = "dog-tag-chain"
    public static let summary = "Worn dog tags on a stainless ball chain: two stamped tags, rubber silencer, bead connector."
    public static let tags = ["prop", "wearable", "worn", "jewelry", "metal", "stainless"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 16, elevation: 12, distance: 0.7, ground: false, studio: true)

    /// Chain beads.
    public var chainMetal: MaterialKey = "metal.stainless"
    /// Tag stainless.
    public var tagMetal: MaterialKey = "metal.stainless-smudged"
    /// Silencer rubber.
    public var rubber: MaterialKey = "rubber.insulating-black"
    public init() {}

    /// CCW plate outline with a hairline keyhole slit from the top edge to the hole.
    static func plate(w: Float, h: Float, r: Float, holeY: Float, holeR: Float) -> [V2] {
        let cx = w / 2 - r, cy = h / 2 - r
        var p: [V2] = []
        func arc(_ c: V2, _ a0: Float, _ a1: Float) { for k in 0...6 { let a = a0 + (a1 - a0) * Float(k) / 6; p.append(c + V2(cos(a), sin(a)) * r) } }
        arc(V2(cx, -cy), -.pi / 2, 0)
        arc(V2(cx, cy), 0, .pi / 2)
        let sl: Float = 0.00016
        let a0 = asin(sl / holeR)
        p.append(V2(sl, h / 2))
        for k in 0...28 {
            let a = (Float.pi / 2 - a0) - (2 * Float.pi - 2 * a0) * Float(k) / 28
            p.append(V2(0, holeY) + V2(cos(a), sin(a)) * holeR)
        }
        p.append(V2(-sl, h / 2))
        arc(V2(-cx, cy), .pi / 2, .pi)
        arc(V2(-cx, -cy), .pi, 1.5 * .pi)
        return p
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let rx: Float = 0.068, rz0: Float = 0.064
        func point(_ th: Float) -> V3 {
            let f = (1 + cos(th)) / 2
            return V3(sin(th) * (rx + 0.014 * f), 0.004 - 0.19 * pow(f, 1.7), cos(th) * (rz0 + 0.03 * pow(f, 1.5)))
        }
        let delta: Float = 0.05
        var dense: [V3] = [], thetas: [Float] = []
        let steps = 1400
        for k in 0...steps {
            let th = -Float.pi + delta + (2 * Float.pi - 2 * delta) * Float(k) / Float(steps)
            dense.append(point(th)); thetas.append(th)
        }
        var cum: [Float] = [0]
        for i in 1..<dense.count { cum.append(cum[i - 1] + simd_distance(dense[i - 1], dense[i])) }
        let total = cum.last!
        func at(_ s: Float) -> (V3, Float) {
            var lo = 0, hi = cum.count - 1
            while hi - lo > 1 { let mid = (lo + hi) / 2; if cum[mid] <= s { lo = mid } else { hi = mid } }
            let t = (s - cum[lo]) / max(cum[hi] - cum[lo], 1e-9)
            return (lerp(dense[lo], dense[hi], t), lerp(thetas[lo], thetas[hi], t))
        }
        // Ball chain: swelling tube, five rings per bead near the front and four at the back.
        let pitch: Float = 0.0052, rb: Float = 0.0024
        func beadRun(_ b0: Int, _ b1: Int, per: Int, sides: Int) {
            var path: [V3] = [], radii: [Float] = []
            for b in b0..<b1 { for k in 0..<per {
                let u = (Float(k) + 0.5) / Float(per)
                path.append(at(0.006 + (Float(b) + u) * pitch).0)
                radii.append(rb * (0.42 + 0.58 * sqrt(max(0, sin(.pi * u)))))
            }}
            if path.count > 1 { m.add(Prim.tube(path, radii: radii, sides: sides, seamTile: 0.01, material: chainMetal, capEnd: true)) }
        }
        var sA: Float = 0, sB: Float = total
        for i in 0..<thetas.count { if abs(thetas[i]) < 1.5 { sA = cum[i]; break } }
        for i in stride(from: thetas.count - 1, through: 0, by: -1) { if abs(thetas[i]) < 1.5 { sB = cum[i]; break } }
        let nBeads = Int((total - 0.012) / pitch)
        let bA = max(1, Int((sA - 0.006) / pitch)), bB = min(nBeads - 1, Int((sB - 0.006) / pitch))
        beadRun(0, bA + 1, per: 3, sides: 6)
        beadRun(bA, bB + 1, per: 5, sides: 8)
        beadRun(bB, nBeads, per: 3, sides: 6)
        // Connector barrel at the nape.
        let e1 = dense.last!, e0 = dense.first!
        let barrel = Prim.lathe([V2(0, -0.0042), V2(0.0014, -0.0042), V2(0.0021, -0.0036), V2(0.0022, -0.003), V2(0.0022, 0.003), V2(0.0021, 0.0036),
                                 V2(0.0014, 0.0042), V2(0, 0.0042)], segments: 24, seamTile: 0.01, material: chainMetal)
        m.add(barrel, Xform(translation: (e0 + e1) / 2, rotation: simd_quatf(degrees: 90, axis: V3(0, 0, 1))))
        // Tags hang with the chain through the hole at the apex.
        let w: Float = 0.0285, h: Float = 0.051, holeY = h / 2 - 0.0046
        let apex = dense[dense.count / 2]
        let outline = Self.plate(w: w, h: h, r: 0.0065, holeY: holeY, holeR: 0.0022)
        func rr(_ w: Float, _ h: Float, _ r: Float, z: Float) -> [V3] {
            var out: [V3] = []
            let cx = w / 2 - r, cy = h / 2 - r
            for (c, a0) in [(V2(cx, -cy), -Float.pi / 2), (V2(cx, cy), 0), (V2(-cx, cy), Float.pi / 2), (V2(-cx, -cy), Float.pi)] as [(V2, Float)] {
                for k in 0...6 { let a = a0 + (Float.pi / 2) * Float(k) / 6; out.append(V3(c.x + cos(a) * r, c.y + sin(a) * r, z)) }
            }
            out.append(out[0])
            return out
        }
        func tag(roll: Float, tilt: Float, zOff: Float, lines: Int, silencer: Bool) {
            let q = simd_quatf(angle: roll, axis: V3(0, 0, 1)) * simd_quatf(angle: tilt, axis: V3(1, 0, 0))
            let pivot = q.act(V3(0, holeY, 0))
            let X = Xform(translation: apex - pivot + V3(0, 0, zOff), rotation: q)
            var tm = Model(name: "tag")
            tm.add(Prim.extrude(outline, depth: 0.0012, bevel: 0.0004, bevelSegments: 2, material: tagMetal))
            // Raised stamped rim.
            tm.add(Prim.sweep(Shape2D.circle(0.00045, ry: 0.0004, segments: 8), along: rr(w - 0.0034, h - 0.0034, 0.0045, z: 0.0006).dropLast().map { $0 },
                              up: V3(0, 0, 1), closedPath: true, caps: false, material: tagMetal))
            // Embossed text rows: letter blocks of varying width.
            let rows = lines
            for row in 0..<rows {
                let y = 0.0105 - Float(row) * 0.0062
                let chars = row == 0 ? 8 : (row == rows - 1 ? 6 : 9)
                let rowW = Float(chars) * 0.0021
                for c in 0..<chars {
                    if rng.float(0...1) < 0.13 { continue }
                    let x = -rowW / 2 + (Float(c) + 0.5) * 0.0021
                    let gw: Float = rng.float(0...1) < 0.3 ? 0.0006 : 0.0013
                    let g = Shape2D.rounded([V2(-gw / 2, -0.0015), V2(gw / 2, -0.0015), V2(gw / 2, 0.0015), V2(-gw / 2, 0.0015)], radius: 0.0001, segments: 1)
                    tm.add(Prim.extrude(g, depth: 0.0008, bevel: 0.0001, bevelSegments: 1, material: tagMetal), Xform(translation: V3(x, y, 0.0009)))
                }
            }
            if silencer {
                tm.add(Prim.sweep(Shape2D.circle(0.0018, ry: 0.0012, segments: 10), along: rr(w + 0.0024, h + 0.0024, 0.0077, z: 0).dropLast().map { $0 },
                                  up: V3(0, 0, 1), closedPath: true, caps: false, material: rubber))
            }
            m.add(tm, X)
        }
        tag(roll: 0.2, tilt: 0.05, zOff: -0.0016, lines: 3, silencer: false)
        tag(roll: -0.02, tilt: -0.09, zOff: 0.0016, lines: 5, silencer: true)
        return LODModel(m)
    }
}
