import simd
import Foundation

/// Back-end-of-line interconnect stack at 1e6x scale (0.5 x 1.0 x 0.5 m): silicon substrate with tungsten contacts under
/// twelve copper metal layers in low-k dielectric. Wire pitch and thickness widen from m01 to m12, routing alternates
/// along x and z, vias bridge the layers, and each layer steps back from the front so every wiring plane is exposed.
/// Parts: substrate, m01 ... m12; state "exploded" lifts the layers apart.
public struct InterconnectStackCutaway: RealArticulated {
    public static let id = "interconnect-stack-cutaway"
    public static let summary = "BEOL interconnect stack cutaway at 1e6x scale: 12 copper metal layers with vias in low-k dielectric, pitch widening upward; explodes by layer."
    public static let tags = ["prop", "chiplab", "micro-scale", "articulated"]
    public static let budget = 8000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 38, elevation: 22, distance: 2.6, studio: true)

    /// Metal layer count.
    public var layers = 12
    public var wire: MaterialKey = "metal.copper"
    public var plug: MaterialKey = "metal.tungsten"
    public var dielectric: MaterialKey = "oxide.lowk"
    public var silicon: MaterialKey = "silicon.die-edge"
    public init() {}

    /// Flat-faced prism, 12 triangles.
    func box(_ s: V3, _ r: Float, _ mat: MaterialKey) -> Surface {
        let hx = s.x / 2, hy = s.y / 2
        return Prim.extrude([V2(-hx, -hy), V2(hx, -hy), V2(hx, hy), V2(-hx, hy)], depth: s.z, bevel: 0, bevelSegments: 1, material: mat)
    }

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 1)
        rig.base[0] = Model(name: Self.id)
        let W: Float = 0.5, D: Float = 0.5, subT: Float = 0.06
        let n = layers
        // Layer heights grow 1.0x to 2.6x; total fills the 1 m height with a thin passivation cap.
        let weights = (0..<n).map { 1 + 1.6 * Float($0) / Float(n - 1) }
        let avail: Float = 1.0 - subT - 0.02
        let unit = avail / weights.reduce(0, +)
        let gap: Float = 0.0015

        _ = rig.part("substrate", pivot: V3(0, 0, 0), joint: .slide(axis: V3(0, -1, 0), 0...0.15, duration: 0.9))
        rig.add(box(V3(W, subT, D), 0.004, silicon), Xform(translation: V3(0, subT / 2, 0)), to: "substrate")

        var y = subT
        var prevLines: [Float] = []   // positions across the previous layer's routing direction
        var prevW: Float = 0.02
        var exploded: [String: Float] = ["substrate": 0.15]
        for i in 0..<n {
            let f = Float(i) / Float(n - 1)
            let h = weights[i] * unit - gap
            let name = String(format: "m%02d", i + 1)
            let spread = Float(i + 1) * 0.045
            _ = rig.part(name, pivot: V3(0, y, 0), joint: .slide(axis: V3(0, 1, 0), 0...spread, duration: 0.9))
            exploded[name] = spread

            // Stair-step cutaway: each layer stops further back, exposing the wiring plane of the layer below.
            let zf = D / 2 - Float(i) * 0.03
            let zb = -D / 2
            let depth = zf - zb
            let zm = (zf + zb) / 2
            rig.add(box(V3(W, h, depth), 0.003, dielectric), Xform(translation: V3(0, y + gap + h / 2, zm)), to: name)

            // Lines in the upper 60% of the layer, pitch and size widening upward.
            let pitch: Float = 0.026 + 0.075 * f
            let lw = pitch * 0.42
            let lh = h * 0.6
            let lineY = y + gap + h - lh / 2 + 0.003
            let alongX = i % 2 == 0
            var pos: [Float] = []
            let span = alongX ? depth - 0.03 : W - 0.03
            let count = max(3, Int(span / pitch))
            let start = (alongX ? zb + 0.03 + (span - Float(count - 1) * pitch) / 2 : -W / 2 + 0.015 + (span - Float(count - 1) * pitch) / 2)
            for k in 0..<count { pos.append(start + Float(k) * pitch) }
            if alongX {
                for z in pos {
                    rig.add(box(V3(W + 0.004, lh, lw), min(0.003, lw / 3), i == n - 1 ? wire : wire), Xform(translation: V3(0, lineY, z)), to: name)
                }
            } else {
                for x in pos {
                    rig.add(box(V3(lw, lh, depth + 0.004), min(0.003, lw / 3), wire), Xform(translation: V3(x, lineY, zm + 0.002)), to: name)
                }
            }

            // Vias under this layer's lines, landing on the layer below's lines (tungsten contacts on the substrate for m01).
            let viaR = max(0.006, min(lw, prevW) * 0.32)
            let viaBase = y - 0.0005
            let viaTop = lineY - lh / 2 + 0.001
            var v = 0
            if alongX {
                // x-lines at z=pos; lower layer ran along z at x = prevLines.
                let xs: [Float] = i == 0 ? stride(from: -0.18 as Float, through: 0.18, by: 0.12).map { $0 } : prevLines
                for (a, x) in xs.enumerated() where a % 2 == (i / 2) % 2 {
                    for (b, z) in pos.enumerated() where (a + b) % 3 == 0 && z < zf - 0.02 {
                        rig.add(Prim.lathe([V2(viaR, 0), V2(viaR * 0.9, viaTop - viaBase)], segments: 6, seamTile: 1, material: i == 0 ? plug : wire),
                                Xform(translation: V3(x, viaBase, z)), to: name)
                        v += 1
                    }
                }
            } else {
                // z-lines at x=pos; lower layer ran along x at z = prevLines.
                for (a, z) in prevLines.enumerated() where z < zf - 0.02 {
                    for (b, x) in pos.enumerated() where (a + b) % 3 == 0 {
                        rig.add(Prim.lathe([V2(viaR, 0), V2(viaR * 0.9, viaTop - viaBase)], segments: 6, seamTile: 1, material: wire),
                                Xform(translation: V3(x, viaBase, z)), to: name)
                        v += 1
                    }
                }
            }
            prevLines = pos
            prevW = lw

            // Top layer: bond pads rising above the cap.
            if i == n - 1 {
                for x: Float in [-0.14, 0.14] {
                    rig.add(box(V3(0.12, 0.012, 0.12), 0.004, wire), Xform(translation: V3(x, y + gap + h + 0.004, zf - 0.09)), to: name)
                }
            }
            y += h + gap
        }
        rig.states = [RigState("assembled"), RigState("exploded", exploded)]
        return rig
    }
}
