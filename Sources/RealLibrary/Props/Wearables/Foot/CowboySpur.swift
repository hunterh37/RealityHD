import simd
import Foundation

/// Left cowboy spur buckled on the boot heel (heel band 4.5 cm above the sole, shank trailing behind the heel): blued steel
/// heel band with a dipped back and silver scroll inlay, a goose-neck shank with silver collars and a forked yoke, a
/// twelve point rowel on a pin, buttons at the band ends, and a pair of dark leather instep straps with punched holes, a
/// roller buckle and a scalloped nickel concho. The rowel is rusted and one point has snapped off to a stub.
public struct CowboySpur: RealAsset {
    public static let id = "cowboy-spur"
    public static let summary = "Worn cowboy spur: blued steel heel band with silver inlay, goose-neck shank, rusted rowel with a broken point, leather straps, buckle and concho."
    public static let tags = ["prop", "wearable", "worn", "metal", "leather", "western"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 120, elevation: 12, distance: 0.7, ground: false, studio: true)

    /// Heel band, shank and yoke steel.
    public var steel: MaterialKey = "metal.blued-steel"
    /// Rowel steel.
    public var rowel: MaterialKey = "metal.rust-grime"
    /// Silver inlay and concho.
    public var silver: MaterialKey = "metal.nickel"
    /// Buttons and buckle.
    public var brass: MaterialKey = "metal.brass-aged"
    /// Strap leather.
    public var leather: MaterialKey = "leather.baseball-dirty:3E2C22"
    public init() {}

    typealias K = ChestKit
    typealias B = ChelseaBootWorn

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let yb: Float = -0.045, zc: Float = -0.040, ha: Float = 0.0405, hb: Float = 0.0360
        func bandPt(_ psi: Float, _ off: Float, _ dy: Float = 0) -> V3 {
            let y = yb + 0.0070 * (1 - cos(psi)) + dy
            let n = simd_normalize(V3(sin(psi) / ha, 0, -cos(psi) / hb))
            return V3(ha * sin(psi), y, zc - hb * cos(psi)) + n * off
        }
        let bandNormal: (V3) -> V3 = { simd_normalize(V3($0.x / (ha * ha), 0, ($0.z - zc) / (hb * hb))) }
        let psiMax: Float = 1.78
        // Heel band: a steel ribbon wider at the back, with a thin polished edge bead.
        let bandPath = (0...72).map { bandPt(-psiMax + 2 * psiMax * Float($0) / 72, 0.0020) }
        m.add(K.ribbon(K.frames(bandPath, normal: bandNormal), width: 0.0135, thick: 0.0034, radius: 0.0012, segments: 2,
                       widthScale: { 1 + 0.30 * exp(-pow(($0 - 0.5) / 0.22, 2)) }, material: steel))
        // Silver scroll inlay along the band centre, and edge lines.
        let scroll = (0...90).map { k -> V3 in
            let t = Float(k) / 90
            let psi = -1.55 + 3.10 * t
            return bandPt(psi, 0.0040, 0.0036 * sin(t * 22) * (0.4 + 0.6 * sin(t * Float.pi)))
        }
        m.add(Prim.tube(scroll, radii: scroll.map { _ in 0.00042 }, sides: 4, seamTile: 0.01, material: silver, capEnd: false))
        for dy: Float in [-0.0052, 0.0052] {
            let edge = (0...72).map { bandPt(-1.62 + 3.24 * Float($0) / 72, 0.0039, dy * (1 + 0.20 * exp(-pow(Float($0) / 72 - 0.5, 2) / 0.05))) }
            m.add(Prim.tube(edge, radii: edge.map { _ in 0.00035 }, sides: 4, seamTile: 0.01, material: silver, capEnd: false))
        }
        for s: Float in [-1, 1] {
            for k in 0..<3 {
                let psi = s * (0.55 + Float(k) * 0.34)
                m.add(Prim.torus(major: 0.0020, minor: 0.00038, segments: 14, sides: 4, material: silver),
                      Xform(translation: bandPt(psi, 0.0040), rotation: facing(bandNormal(bandPt(psi, 0)))))
            }
        }

        // Buttons at the band ends.
        for s: Float in [-1, 1] {
            let p = bandPt(s * psiMax, 0.0038)
            let n = bandNormal(p)
            m.add(Prim.lathe([V2(0, 0), V2(0.0050, 0), V2(0.0052, 0.0008), V2(0.0042, 0.0024), V2(0.0020, 0.0032), V2(0, 0.0034)], segments: 20, seamTile: 0.02, material: brass),
                  Xform(translation: p, rotation: facing(n)))
        }

        // Goose-neck shank trailing behind the heel, tapered, with silver collars and a forked yoke.
        let shankPts = catmull([V3(0, yb - 0.001, -0.0745), V3(0, yb - 0.003, -0.090), V3(0, yb - 0.007, -0.104), V3(0, yb - 0.016, -0.115), V3(0, yb - 0.027, -0.122)], per: 7)
        let shR = shankPts.indices.map { 0.0041 - 0.0012 * Float($0) / Float(shankPts.count - 1) }
        m.add(Prim.tube(shankPts, radii: shR, sides: 12, seamTile: 0.02, material: steel, capEnd: true))
        for k in [6, 16] {
            let i = min(shankPts.count - 2, k)
            let t = simd_normalize(shankPts[i + 1] - shankPts[i])
            m.add(Prim.torus(major: shR[i] + 0.0003, minor: 0.00055, segments: 22, sides: 6, material: silver),
                  Xform(translation: shankPts[i], rotation: facing(t)))
        }
        let yc = shankPts.last!
        let hubC = yc + V3(0, -0.0065, -0.0035)
        for s: Float in [-1, 1] {
            let prong = catmull([yc + V3(0, 0, 0), yc + V3(s * 0.0040, -0.0020, -0.0010), hubC + V3(s * 0.0048, 0.0010, 0)], per: 4)
            m.add(Prim.tube(prong, radii: prong.map { _ in 0.0019 }, sides: 8, seamTile: 0.02, material: steel))
        }
        m.add(Prim.cylinder(radius: 0.0012, height: 0.0125, bevel: 0.0003, segments: 12, bevelSegments: 1, material: "metal.nickel-worn"),
              Xform(translation: hubC - V3(0.00625, 0, 0), rotation: simd_quatf(angle: -Float.pi / 2, axis: V3(0, 0, 1))))

        // Twelve point rowel, rusted, with one point snapped off.
        var star: [V2] = []
        let teeth = 12
        for k in 0..<(teeth * 2) {
            let tooth = k / 2
            let outer = k % 2 == 0
            let r: Float = outer ? (tooth == 5 ? 0.0128 : 0.0186) : 0.0112
            let ang = Float(k) * Float.pi / Float(teeth) + (outer ? 0 : 0.02)
            star.append(V2(cos(ang) * r, sin(ang) * r))
        }
        var rw = Prim.extrude(Shape2D.rounded(star, radius: 0.0004), depth: 0.0022, bevel: 0.0005, bevelSegments: 2, material: rowel)
        rw.displace { p, _ in 0.00025 * Noise.fbm(p * 220, octaves: 3) }
        m.add(rw, Xform(translation: hubC, rotation: simd_quatf(angle: Float.pi / 2, axis: V3(0, 1, 0))))
        for s: Float in [-1, 1] {
            m.add(Prim.lathe([V2(0, 0), V2(0.0042, 0), V2(0.0044, 0.0006), V2(0.0036, 0.0013), V2(0, 0.0015)], segments: 18, seamTile: 0.02, material: "metal.nickel-worn"),
                  Xform(translation: hubC + V3(s * 0.0012, 0, 0), rotation: facing(V3(s, 0, 0))))
        }

        // Instep straps over the (invisible) boot: leave the buttons, climb the ankle and cross the instep.
        let prof = B.prof
        func strap(_ sg: Float, crossing: Bool) -> (f: [K.Frame], pts: [V3]) {
            var ctl: [V3] = [bandPt(sg * psiMax, 0.0030) + V3(0, 0, 0)]
            ctl.append(B.side(-0.030, -0.010, sg, grow: 0.0030))
            ctl.append(B.side(-0.022, 0.022, sg, grow: 0.0030))
            ctl.append(B.side(-0.013, 0.052, sg, grow: 0.0028))
            let xs: [Float] = crossing ? [0.040, 0.030, 0.018, 0.006, -0.006, -0.020] : [0.040, 0.030, 0.018, 0.004]
            for (i, xv) in xs.enumerated() {
                let y: Float = -0.008 + 0.012 * Float(i) / Float(xs.count - 1)
                let lift: Float = 0.0030 + (crossing ? 0.0036 * smoothstep(0.012, -0.004, xv) : 0)
                ctl.append(FootKit.front(prof, y: y, x: sg * xv, lift: lift).p)
            }
            let pts = catmull(ctl, per: 5)
            let nf: (V3) -> V3 = { p in
                let n = simd_normalize(V3(p.x, 0, p.z - 0.030))
                let up = smoothstep(0.05, 0.11, p.z) * 0.9
                return simd_normalize(n * (1 - up) + V3(0, up, 0))
            }
            return (K.frames(pts, normal: nf), pts)
        }
        let left = strap(1, crossing: false)
        let right = strap(-1, crossing: true)
        func crease(_ s: Surface) -> Surface { var t = s; t.displace { p, _ in 0.0005 * Noise.fbm(p * 140, octaves: 3) + 0.0004 * sin(p.x * 420 + p.z * 160) }; return t }
        m.add(crease(K.ribbon(left.f, width: 0.0165, thick: 0.0042, radius: 0.0016, segments: 2, material: leather)))
        m.add(crease(K.ribbon(right.f, width: 0.0165, thick: 0.0034, radius: 0.0012, segments: 1, widthScale: { 1 - 0.45 * smoothstep(0.90, 1.0, $0) }, material: leather)))
        for st in [left, right] {
            for off: Float in [-0.0062, 0.0062] {
                let line = st.f.map { $0.p + $0.w * off + $0.n * 0.0018 }
                m.add(stitches(along: line, normal: { _ in V3(0, 1, 0) }, pitch: 0.0038, thread: 0.0004, material: "fabric.canvas:C9B27E"))
            }
        }
        // Punched holes near the free tail.
        let rf = right.f
        for k in 0..<4 {
            let f = rf[min(rf.count - 1, rf.count - 3 - k * 3)]
            m.add(Prim.cylinder(radius: 0.0016, height: 0.0006, bevel: 0.0001, segments: 12, bevelSegments: 1, material: "plastic.black"),
                  Xform(translation: f.p + f.n * 0.0016, rotation: facing(f.n)))
        }
        // Roller buckle at the end of the left strap, tongue through the right strap.
        let lf = left.f.last!
        let bq = K.basis(lf.w, lf.t)
        m.add(K.ring(0.0250, 0.0195, wire: 0.0012, radius: 0.0030, sides: 8, material: brass),
              Xform(translation: lf.p + lf.t * 0.0080 + lf.n * 0.0024, rotation: bq))
        m.add(Prim.cylinder(radius: 0.0011, height: 0.0200, bevel: 0.0003, segments: 10, bevelSegments: 1, material: brass),
              Xform(translation: lf.p + lf.t * 0.0060 + lf.n * 0.0030 - lf.w * 0.0100, rotation: bq * simd_quatf(angle: -Float.pi / 2, axis: V3(0, 0, 1))))

        // Scalloped nickel concho on the left strap.
        let cf = left.f[left.f.count - 8]
        var lobes: [V2] = []
        for k in 0..<48 {
            let a = Float(k) * 2 * Float.pi / 48
            lobes.append(V2(cos(a), sin(a)) * (0.0165 + 0.0011 * sin(a * 12)))
        }
        let cq = facing(cf.n)
        m.add(Prim.extrude(lobes, depth: 0.0016, bevel: 0.0005, bevelSegments: 2, material: silver),
              Xform(translation: cf.p + cf.n * 0.0038, rotation: cq * simd_quatf(angle: Float.pi / 2, axis: V3(1, 0, 0))))
        m.add(Prim.lathe([V2(0, 0), V2(0.0120, 0), V2(0.0121, 0.0006), V2(0.0110, 0.0010), V2(0.0070, 0.0022), V2(0.0036, 0.0030), V2(0, 0.0031)], segments: 28, seamTile: 0.02, material: "metal.nickel-worn"),
              Xform(translation: cf.p + cf.n * 0.0050, rotation: cq))
        m.add(Prim.torus(major: 0.0132, minor: 0.00045, segments: 36, sides: 4, material: silver),
              Xform(translation: cf.p + cf.n * 0.0052, rotation: cq))
        _ = rng.float()
        return LODModel(m)
    }
}
