import simd
import Foundation

/// Victorian canted bay window roof, 1.8 m: three-facet standing-seam copper hip with rolled hips, a half-round
/// gutter on the eaves, bracketed timber cornice and soffit, ridge cresting and a turned finial. Wall at z = 0.
public struct CopperBayWindowRoof: RealAsset {
    public static let id = "copper-bay-window-roof"
    public static let summary = "Victorian bay window roof, 1.8 m: standing-seam copper hip, rolled hips, half-round gutter, bracketed cornice, finial."
    public static let tags = ["prop", "architecture", "facade", "metal", "wood", "trim"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 22, distance: 1.6)

    /// Width at the wall in meters.
    public var width: Float = 1.8
    /// Projection of the front facet in meters.
    public var projection: Float = 0.82
    /// Weathered copper pans.
    public var pan: MaterialKey = "metal.copper:4A2C1B"
    /// Bright replacement pan.
    public var freshPan: MaterialKey = "metal.copper"
    /// Patinated copper trim.
    public var patina: MaterialKey = "metal.copper-patina"
    /// Painted timber.
    public var timber: MaterialKey = "wood.painted-exterior:2F4A3A"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let hw = width / 2 - 0.06, fw: Float = 0.42, D = projection
        let eaveY: Float = 0.1, ridgeY: Float = 0.30
        let e0 = V3(-hw, eaveY, 0.0), e1 = V3(-fw, eaveY, D), e2 = V3(fw, eaveY, D), e3 = V3(hw, eaveY, 0.0)
        let w1 = V3(-fw, ridgeY, 0.02), w2 = V3(fw, ridgeY, 0.02)

        // Standing-seam pans, patinated with occasional bright replacements.
        let bright = rng.int(2...7)
        let tones: [MaterialKey] = [pan, "metal.copper:5E3822", "metal.copper:7A4A2C", "metal.copper:3A2217", patina]
        var tr = rng.fork(5)
        let frontTone = (0..<9).map { _ in tones[tr.int(0...4)] }
        let leftTone = (0..<5).map { _ in tones[tr.int(0...3)] }
        let rightTone = (0..<5).map { _ in tones[tr.int(0...3)] }
        FL.pans(&m, a0: e1, a1: e2, b0: w1, b1: w2, count: 9, thick: 0.0035,
                { $0 == bright ? freshPan : frontTone[$0] }, seam: pan, seamR: 0.0075)
        FL.pans(&m, a0: e0, a1: e1, b0: w1, b1: w1, count: 5, thick: 0.0035, { leftTone[$0] }, seam: pan, seamR: 0.0075)
        FL.pans(&m, a0: e2, a1: e3, b0: w2, b1: w2, count: 5, thick: 0.0035, { rightTone[$0] }, seam: pan, seamR: 0.0075)

        // Timber sheathing under the pans so the hips read as a built roof from every side.
        let dn = V3(0, -0.011, 0)
        FL.pans(&m, a0: e1 + dn, a1: e2 + dn, b0: w1 + dn, b1: w2 + dn, count: 1, thick: 0.01, { _ in timber }, seam: timber, seamR: 0.001)
        FL.pans(&m, a0: e0 + dn, a1: e1 + dn, b0: w1 + dn, b1: w1 + dn, count: 1, thick: 0.01, { _ in timber }, seam: timber, seamR: 0.001)
        FL.pans(&m, a0: e2 + dn, a1: e3 + dn, b0: w2 + dn, b1: w2 + dn, count: 1, thick: 0.01, { _ in timber }, seam: timber, seamR: 0.001)
        // Rolled hips with copper roll over a batten and cleat clips.
        let lift = V3(0, 0.012, 0)
        for (a, b) in [(e1, w1), (e2, w2)] {
            FA.rod(&m, a + lift, b + lift, r: 0.013, "metal.copper", sides: 10)
            let d = simd_normalize(b - a)
            for i in 1..<6 {
                let p = a + (b - a) * (Float(i) / 6) + lift
                m.add(Prim.torus(major: 0.0135, minor: 0.003, segments: 8, sides: 4, material: patina),
                      Xform(translation: p, rotation: simd_quatf(from: V3(0, 1, 0), to: d)))
            }
        }
        // Wall flashing with a welted top lip.
        FA.box(&m, V3(fw * 2 + 0.05, 0.05, 0.005), V3(0, ridgeY - 0.01, 0.012), patina, r: 0.0015, rot: FA.q(-35, FA.X))
        for (a, b, s) in [(e0, w1, Float(1)), (e3, w2, Float(-1))] {
            for i in 0..<6 {
                let t = (Float(i) + 0.5) / 6
                let p = a + (b - a) * t
                FA.box(&m, V3(0.055, 0.045, 0.004), V3(p.x + s * 0.014, p.y + 0.018, 0.012), patina, r: 0.001, rot: FA.q(-s * 30, FA.Z))
            }
        }

        // Soffit deck closing the underside, and a wall plate closing the back.
        var deck: [V2] = [V2(-hw + 0.02, 0.0), V2(hw - 0.02, 0.0), V2(fw - 0.01, -D + 0.02), V2(-fw + 0.01, -D + 0.02)]
        if FM.area(deck) < 0 { deck.reverse() }
        m.add(Prim.extrude(deck, depth: 0.018, bevel: 0.002, bevelSegments: 1, material: timber),
              Xform(translation: V3(0, eaveY - 0.012, 0), rotation: FA.q(-90, FA.X)))
        FM.prism(&m, [V2(-hw, eaveY - 0.012), V2(hw, eaveY - 0.012), V2(fw, ridgeY), V2(-fw, ridgeY)], front: 0.018, depth: 0.018, timber, bevel: 0.002)
        // Eave outline: fascia, bed mould, soffit and a half-round gutter.
        let outline = [(e0, e1), (e1, e2), (e2, e3)]
        for (a, b) in outline {
            let d = b - a, len = simd_length(SIMD2<Float>(d.x, d.z))
            let dir = V3(d.x, 0, d.z) / len
            var out = V3(-dir.z, 0, dir.x)
            if out.z < 0 { out = -out }
            let yaw = -atan2(d.z, d.x)
            let ry = simd_quatf(angle: yaw, axis: V3(0, 1, 0))
            func band(_ off: Float, _ y: Float, _ sz: V3, _ mat: MaterialKey, _ r: Float) {
                let c = (a + b) / 2 + out * off
                FA.box(&m, V3(len + 0.03, sz.y, sz.z), V3(c.x, y, c.z), mat, r: r, rot: ry)
            }
            band(0.0, 0.03, V3(0, 0.12, 0.026), timber, 0.003)           // fascia board
            band(0.014, 0.1, V3(0, 0.022, 0.022), timber, 0.008)           // cove bed mould
            band(0.02, eaveY + 0.004, V3(0, 0.005, 0.014), "metal.copper", 0.0025) // drip edge
            band(0.0, -0.045, V3(0, 0.02, 0.06), timber, 0.003)            // soffit board
            // Half-round gutter: tube along the eave just outside the fascia with end caps hidden at the corners.
            let g0 = a + out * 0.052 + V3(0, 0.055, 0), g1 = b + out * 0.052 + V3(0, 0.055, 0)
            m.add(Prim.tube([g0, g1], radii: [0.022, 0.022], sides: 12, seamTile: 0.2, material: patina, capEnd: true))
            // Brackets holding the gutter: copper strap hangers every 0.3 m.
            let k = max(2, Int(len / 0.3))
            for i in 0..<k {
                let t = (Float(i) + 0.5) / Float(k)
                let p = a + (b - a) * t + out * 0.04
                FA.box(&m, V3(0.012, 0.04, 0.02), V3(p.x, 0.058, p.z), "metal.copper", r: 0.002, rot: ry)
            }
            // Rafter tails under the soffit, tapered, every 0.12 m.
            let nt = Int(len / 0.12)
            for i in 0..<nt {
                let t = (Float(i) + 0.5) / Float(nt)
                let p = a + (b - a) * t + out * 0.034
                FA.box(&m, V3(0.034, 0.05, 0.03), V3(p.x, -0.012, p.z), timber, r: 0.004, rot: ry)
            }
        }
        // Scrolled timber brackets under the eave at the wall corners and the front corners: ogee profile with a bead.
        var bp: [V2] = [V2(0, 0.0), V2(0.016, 0.0)]
        bp += FL.ogee(from: V2(0.016, 0.0), to: V2(0.1, 0.11), steps: 8)
        bp += [V2(0.1, 0.114), V2(0, 0.114)]
        for sx: Float in [-1, 1] {
            FA.side(&m, Shape2D.deduped(bp), thick: 0.026, at: V3(sx * (hw - 0.02), -0.052, 0.0), timber, bevel: 0.002)
        }
        // Streak stains under the gutter outlet and along the fascia.
        var st = rng.fork(8)
        for _ in 0..<10 {
            let t = st.float(0...1)
            let p = e1 + (e2 - e1) * t
            FA.box(&m, V3(0.01, st.float(0.03...0.09), 0.0014), V3(p.x, 0.03, p.z + 0.0138), "wood.painted-exterior:1C2A22", r: 0.0004)
        }
        // Failed paint on the fascia: weathered timber showing through at the corners and under the gutter.
        var pw = rng.fork(13)
        for (a, b) in outline {
            let d = b - a, len = simd_length(SIMD2<Float>(d.x, d.z))
            let dir = V3(d.x, 0, d.z) / len
            var out = V3(-dir.z, 0, dir.x)
            if out.z < 0 { out = -out }
            let ry = simd_quatf(angle: -atan2(d.z, d.x), axis: V3(0, 1, 0))
            for _ in 0..<5 {
                let p = a + (b - a) * pw.float(0.05...0.95) + out * 0.0138
                let bare = pw.chance(0.35)
                FA.box(&m, V3(pw.float(0.03...0.09), pw.float(0.02...0.05), 0.0016), V3(p.x, pw.float(-0.02...0.06), p.z), bare ? "wood.weathered:6B6350" : "wood.painted-exterior:5A7360", r: 0.0005, rot: ry)
            }
        }
        // Gutter outlet at the left front corner with a copper downspout stub.
        FA.rod(&m, V3(-fw - 0.028, 0.03, D + 0.06), V3(-fw - 0.028, -0.05, D + 0.06), r: 0.016, patina, sides: 10)
        FA.box(&m, V3(0.05, 0.012, 0.05), V3(-fw - 0.028, -0.053, D + 0.06), "metal.copper", r: 0.003)
        // Corner posts under the fascia joints with brass rosettes.
        for p in [e0, e1, e2, e3] { FA.box(&m, V3(0.04, 0.14, 0.04), V3(p.x, 0.03, p.z), timber, r: 0.004) }
        for p in [e1, e2] {
            m.add(Prim.torus(major: 0.012, minor: 0.003, segments: 10, sides: 4, material: "metal.brass-aged"),
                  Xform(translation: V3(p.x, 0.03, p.z + 0.03), rotation: FA.q(90, FA.X)))
        }
        // Pierced copper cresting: rail with trefoil finials.
        let crestY = ridgeY + 0.026
        FA.rod(&m, V3(-fw - 0.02, crestY, 0.03), V3(fw + 0.02, crestY, 0.03), r: 0.0045, "metal.copper", sides: 6)
        let trefoil: [V2] = [V2(-0.003, 0), V2(0.003, 0), V2(0.004, 0.018), V2(0.013, 0.028), V2(0.011, 0.042), V2(0.0, 0.037),
                             V2(-0.011, 0.042), V2(-0.013, 0.028), V2(-0.004, 0.018)]
        for i in 0..<9 {
            let x = -fw + Float(i) * (fw * 2) / 8
            m.add(Prim.extrude(trefoil, depth: 0.005, bevel: 0.0006, bevelSegments: 1, material: patina), Xform(translation: V3(x, crestY, 0.03)))
            FA.rod(&m, V3(x, ridgeY - 0.008, 0.03), V3(x, crestY, 0.03), r: 0.003, "metal.copper", sides: 5)
        }
        // Finial: turned base, ball and spike, sitting on a copper cup.
        let top = V3(0, ridgeY + 0.004, 0.025)
        m.add(Prim.lathe([V2(0.0, 0), V2(0.03, 0), V2(0.03, 0.008), V2(0.018, 0.018), V2(0.009, 0.032), V2(0.017, 0.044), V2(0.0, 0.05)],
                         segments: 14, seamTile: 0.1, material: "metal.copper"), Xform(translation: top))
        FA.ball(&m, r: 0.02, at: top + V3(0, 0.066, 0), "metal.brass-aged")
        m.add(Prim.lathe([V2(0.0, 0), V2(0.0055, 0), V2(0.003, 0.04), V2(0, 0.055)], segments: 8, seamTile: 0.1, material: "metal.brass-aged"),
              Xform(translation: top + V3(0, 0.085, 0)))
        groundAO(&m, height: 0.05, floor: 0.9)
        return LODModel(FC.seatY(m))
    }
}
