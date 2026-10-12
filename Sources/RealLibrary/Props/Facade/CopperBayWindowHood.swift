import simd
import Foundation

/// Victorian canted bay window hood, 2.2 m wide: three-facet hipped standing-seam copper roof over a
/// painted timber fascia, cove bed mould and dentil course. Wall plane at z = 0, hood projects toward +Z.
public struct CopperBayWindowHood: RealAsset {
    public static let id = "copper-bay-window-hood"
    public static let summary = "Victorian canted bay window hood, 2.2 m: standing-seam copper hip roof, rolled hips, bracket-dentil cornice, finial."
    public static let tags = ["prop", "architecture", "facade", "metal", "wood", "trim"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 18, distance: 2.3)

    /// Width at the wall in meters.
    public var width: Float = 2.2
    /// Projection of the front facet in meters.
    public var projection: Float = 0.82
    /// Weathered copper pans.
    public var pan: MaterialKey = "metal.copper:3E2417"
    /// Bright replacement pan.
    public var freshPan: MaterialKey = "metal.copper"
    /// Painted timber.
    public var timber: MaterialKey = "wood.painted-exterior:E6DFC8"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        _ = seed
        var m = Model(name: Self.id)
        let hw = width / 2 - 0.02, fw: Float = 0.55, D = projection
        let eaveY: Float = 0.15, ridgeY: Float = 0.55
        let e0 = V3(-hw, eaveY, 0.0), e1 = V3(-fw, eaveY, D), e2 = V3(fw, eaveY, D), e3 = V3(hw, eaveY, 0.0)
        let w1 = V3(-fw, ridgeY, 0.02), w2 = V3(fw, ridgeY, 0.02)

        // Roof facets in standing-seam pans. Front is a trapezoid, the canted sides are triangles meeting at the hips.
        let bright = 7
        FL.pans(&m, a0: e1, a1: e2, b0: w1, b1: w2, count: 10, thick: 0.004,
                { $0 == bright ? freshPan : ($0 % 3 == 1 ? "metal.copper-patina" : pan) }, seam: pan, seamR: 0.0055)
        FL.pans(&m, a0: e0, a1: e1, b0: w1, b1: w1, count: 6, thick: 0.004, { _ in pan }, seam: pan, seamR: 0.0055)
        FL.pans(&m, a0: e2, a1: e3, b0: w2, b1: w2, count: 6, thick: 0.004, { _ in pan }, seam: pan, seamR: 0.0055)

        // Rolled hips: copper roll over a batten, rising from each front corner to the wall ridge.
        let lift = V3(0, 0.012, 0)
        for (a, b) in [(e1, w1), (e2, w2)] {
            FA.rod(&m, a + lift, b + lift, r: 0.014, "metal.copper", sides: 10)
            let d = simd_normalize(b - a)
            for i in 1..<5 {
                let p = a + (b - a) * (Float(i) / 5) + lift
                m.add(Prim.torus(major: 0.0145, minor: 0.0035, segments: 8, sides: 4, material: "metal.copper-patina"),
                      Xform(translation: p, rotation: simd_quatf(from: V3(0, 1, 0), to: d)))
            }
        }
        // Ridge flashing at the wall with a welted lip, and step flashing up each canted edge.
        FA.box(&m, V3(fw * 2 + 0.06, 0.055, 0.006), V3(0, ridgeY - 0.012, 0.012), "metal.copper-patina", r: 0.0015,
               rot: FA.q(-32, FA.X))
        for (a, b, s) in [(e0, w1, Float(1)), (e3, w2, Float(-1))] {
            for i in 0..<8 {
                let t = (Float(i) + 0.5) / 8
                let p = a + (b - a) * t
                FA.box(&m, V3(0.06, 0.048, 0.004), V3(p.x + s * 0.016, p.y + 0.02, 0.012), "metal.copper-patina", r: 0.001,
                       rot: FA.q(-s * 28, FA.Z))
            }
        }

        // Eave outline segments: (start, end) with fascia below the roof edge.
        let outline = [(e0, e1), (e1, e2), (e2, e3)]
        func seg(_ a: V3, _ b: V3, _ off: Float, _ y: Float, size: V3, _ mat: MaterialKey, r: Float = 0.003) {
            let d = b - a, len = simd_length(SIMD2<Float>(d.x, d.z))
            let yaw = -atan2(d.z, d.x)
            let n = V3(-d.z, 0, d.x) / len // outward-left normal; flip so it faces away from the bay
            let out = (n.z >= 0 ? n : -n)
            let c = (a + b) / 2 + out * off
            FA.box(&m, V3(len + size.x, size.y, size.z), V3(c.x, y, c.z), mat, r: r, rot: simd_quatf(angle: yaw, axis: V3(0, 1, 0)))
        }
        for (a, b) in outline {
            // Fascia board with a flush top rail, cove bed mould under the roof, drip edge over it.
            seg(a, b, 0.0, 0.075, size: V3(0.0, 0.11, 0.028), timber, r: 0.003)
            seg(a, b, 0.012, 0.145, size: V3(0.0, 0.026, 0.026), timber, r: 0.009)
            seg(a, b, 0.018, eaveY + 0.006, size: V3(0.0, 0.006, 0.014), "metal.copper", r: 0.0025)
            // Dentil course: small blocks hung from the fascia.
            let d = b - a, len = simd_length(SIMD2<Float>(d.x, d.z))
            let dir = simd_normalize(V3(d.x, 0, d.z))
            let n = abs(Int(len / 0.072))
            let outN = V3(-dir.z, 0, dir.x)
            let out = outN.z >= 0 ? outN : -outN
            let yaw = -atan2(d.z, d.x)
            for i in 0..<n {
                let t = (Float(i) + 0.5) / Float(n)
                let p = a + (b - a) * t + out * 0.026
                FA.box(&m, V3(0.022, 0.026, 0.02), V3(p.x, 0.108, p.z), timber, r: 0.002, rot: simd_quatf(angle: yaw, axis: V3(0, 1, 0)))
            }
        }
        // Fascia bottom rail (bead).
        for (a, b) in outline { seg(a, b, 0.004, 0.012, size: V3(0.0, 0.024, 0.032), timber, r: 0.008) }

        // Corner posts under the fascia joints.
        for p in [e0, e1, e2, e3] { FA.box(&m, V3(0.04, 0.12, 0.04), V3(p.x, 0.075, p.z), timber, r: 0.004) }
        for (a, b) in outline {
            let d = b - a
            let yaw = -atan2(d.z, d.x)
            let nrm = V3(-d.z, 0, d.x)
            let out = simd_normalize(nrm.z >= 0 ? nrm : -nrm)
            for t: Float in [0.18, 0.5, 0.82] {
                let p = a + d * t + out * 0.0295
                let rot = simd_quatf(angle: yaw, axis: V3(0, 1, 0)) * FA.q(90, FA.X)
                m.add(Prim.torus(major: 0.011, minor: 0.0028, segments: 10, sides: 4, material: "metal.brass-aged"),
                      Xform(translation: V3(p.x, 0.078, p.z), rotation: rot))
                FC.bead(&m, r: 0.006, at: V3(p.x, 0.078, p.z) + out * 0.003, "metal.brass-aged", sub: 3)
            }
        }

        // Pierced copper ridge cresting along the wall ridge: rail with trefoil finials every 0.1 m.
        let crestY = ridgeY + 0.03
        FA.rod(&m, V3(-fw - 0.02, crestY, 0.03), V3(fw + 0.02, crestY, 0.03), r: 0.005, "metal.copper", sides: 6)
        let trefoil: [V2] = [V2(-0.003, 0), V2(0.003, 0), V2(0.004, 0.02), V2(0.014, 0.03), V2(0.012, 0.045), V2(0.0, 0.04),
                             V2(-0.012, 0.045), V2(-0.014, 0.03), V2(-0.004, 0.02)]
        for i in 0..<9 {
            let x = -fw + 0.0 + Float(i) * (fw * 2) / 8
            m.add(Prim.extrude(trefoil, depth: 0.005, bevel: 0.0006, bevelSegments: 1, material: "metal.copper-patina"), Xform(translation: V3(x, crestY, 0.03)))
            FA.rod(&m, V3(x, ridgeY - 0.008, 0.03), V3(x, crestY, 0.03), r: 0.003, "metal.copper", sides: 5)
        }
        // Scrolled timber brackets under the eave at the wall corners: ogee profile with a bead on the front edge.
        var bp: [V2] = [V2(0, 0.0), V2(0.018, 0.0)]
        bp += FL.ogee(from: V2(0.018, 0.0), to: V2(0.13, 0.145), steps: 10)
        bp += [V2(0.13, 0.15), V2(0, 0.15)]
        for sx: Float in [-1, 1] {
            let cx = sx * hw
            FA.side(&m, Shape2D.deduped(bp), thick: 0.032, at: V3(cx, 0, 0), timber, bevel: 0.002)
            var sp: [V3] = []
            for i in 0...14 {
                let t = Float(i) / 14, a = t * 2.4 * .pi, r = 0.022 * (1 - t * 0.8)
                sp.append(V3(cx + sx * 0.019, 0.04 + sin(a) * r, 0.03 + cos(a) * r))
            }
            m.add(Prim.tube(sp, radii: sp.indices.map { 0.005 - 0.0025 * Float($0) / 14 }, sides: 5, seamTile: 0.15, material: timber, capEnd: true))
        }

        // Finial: turned base, ball and spike on the front ridge crest, bolted through the pans.
        let top = V3(0, ridgeY + 0.012, 0.02)
        m.add(Prim.lathe([V2(0.0, 0), V2(0.026, 0), V2(0.026, 0.008), V2(0.016, 0.016), V2(0.01, 0.03), V2(0.016, 0.042), V2(0.0, 0.05)],
                         segments: 14, seamTile: 0.1, material: "wood.painted-exterior"), Xform(translation: top))
        FA.ball(&m, r: 0.022, at: top + V3(0, 0.075, 0), "metal.brass-aged")
        m.add(Prim.lathe([V2(0.0, 0), V2(0.006, 0), V2(0.0035, 0.045), V2(0, 0.06)], segments: 8, seamTile: 0.1, material: "metal.brass-aged"),
              Xform(translation: top + V3(0, 0.095, 0)))

        groundAO(&m, height: 0.06, floor: 0.9)
        return LODModel(FA.centerZ(m))
    }
}
