import simd
import Foundation

/// Parkman Bandstand, Boston Common (1912): round Greek Revival bandstand, 13 m across. Granite platform
/// with a molded cap and front steps, eight white-painted Ionic columns, architrave, frieze and dentil
/// cornice ring, low lead-grey dome with a finial, iron railing between the columns. Centered on X/Z,
/// base at y = 0, steps toward +Z.
public struct ParkmanBandstand: RealAsset {
    public static let id = "parkman-bandstand"
    public static let summary = "Round Greek Revival bandstand, 13 m: stone platform with steps, eight Ionic columns, entablature and a low dome, painted white."
    public static let tags = ["structure", "architecture", "park", "outdoor", "stone", "roof"]
    public static let budget = 30000
    public static let author = "hunterh37"
    public static let preview = PreviewHint(azimuth: 25, elevation: 10, distance: 1.0)

    /// Platform radius (m).
    public var radius: Float = 5.6
    /// Platform height above grade (m).
    public var platformHeight: Float = 1.2
    /// Column height including base and capital (m).
    public var columnHeight: Float = 4.6
    /// Number of columns.
    public var columns = 8
    /// Granite for the platform and steps.
    public var stone: MaterialKey = "stone.cast-grey:9C988F"
    /// White paint on columns and entablature.
    public var paint: MaterialKey = "wood.painted-exterior:EEEDE8"
    /// Dome covering.
    public var dome: MaterialKey = "paint.stucco:BDBDB6"
    /// Railing iron.
    public var iron: MaterialKey = "metal.wrought-iron"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        let R = radius, ph = platformHeight
        // Platform: plinth course, drum wall, molded cap.
        var p = ArchProfile(V2(0, 0))
        p.to(V2(R + 0.25, 0)); p.fillet(0.25); p.step(-0.12); p.cavetto(0.08, -0.06, segments: 3)
        p.to(V2(R, ph - 0.22)); p.step(0.1); p.ovolo(0.1, 0.1, segments: 3); p.fillet(0.08); p.step(-0.02)
        p.to(V2(0, ph))
        m.add(ArchTrimKit.lathe(p, segments: 56, material: stone, seamTile: 1, maxSeg: 2))
        // Ashlar joints on the drum wall.
        for jy in [Float(0.55), 0.85] {
            m.add(Prim.torus(major: R - 0.003, minor: 0.01, segments: 48, sides: 3, material: stone), Xform(translation: V3(0, jy, 0)))
        }
        // Front steps toward +Z, flanked by cheek blocks.
        let n = 6, rise = ph / Float(n), tread: Float = 0.32, sw: Float = 3.2
        for i in 0..<n {
            let h = rise * Float(i + 1)
            let d = Float(n - i) * tread
            m.add(Prim.roundedBox(V3(sw, h, d + 0.3), radius: 0.02, bevelSegments: 1, material: stone),
                  Xform(translation: V3(0, h / 2, R - 0.3 + (d + 0.3) / 2)))
        }
        for s: Float in [-1, 1] {
            let len = Float(n) * tread + 0.3
            m.add(Prim.roundedBox(V3(0.4, ph + 0.15, len), radius: 0.03, bevelSegments: 2, material: stone),
                  Xform(translation: V3(s * (sw / 2 + 0.2), (ph + 0.15) / 2, R - 0.3 + len / 2)))
        }
        // Columns on a ring just inside the platform edge.
        let cr = R - 0.55
        let colTop = ph + columnHeight
        let col = ionic(height: columnHeight, diameter: 0.46)
        let stepAngle = 2 * Float.pi / Float(columns)
        for i in 0..<columns {
            let a = (Float(i) + 0.5) * stepAngle
            m.add(col, Xform(translation: V3(sin(a) * cr, ph, cos(a) * cr), rotation: simd_quatf(angle: a, axis: V3(0, 1, 0))))
        }
        // Railing between columns, open at the front bay over the steps.
        for i in 0..<columns {
            let a0 = (Float(i) + 0.5) * stepAngle, a1 = a0 + stepAngle
            let mid = (a0 + a1) / 2
            if abs(remainder(mid, 2 * .pi)) < 0.1 { continue }
            let span: Float = 0.12
            let rail = stride(from: a0 + span, through: a1 - span, by: (a1 - a0 - 2 * span) / 8).map { V3(sin($0) * cr, 0, cos($0) * cr) }
            for (yy, rr) in [(Float(0.95), Float(0.028)), (0.12, 0.02)] {
                m.add(Prim.tube(rail.map { $0 + V3(0, ph + yy, 0) }, radii: Array(repeating: rr, count: rail.count), sides: 6, seamTile: 0.2, material: iron))
            }
            let k = 14
            for j in 0...k {
                let a = a0 + span + (a1 - a0 - 2 * span) * Float(j) / Float(k)
                let b = V3(sin(a) * cr, ph, cos(a) * cr)
                m.add(Prim.tube([b + V3(0, 0.1, 0), b + V3(0, 0.95, 0)], radii: [0.011, 0.011], sides: 4, seamTile: 0.1, material: iron, capEnd: false))
            }
        }
        // Entablature ring: architrave fasciae, frieze, dentil course, corona and cyma.
        let ri = cr - 0.42, ro = cr + 0.38
        var e = ArchProfile(V2(ri, colTop))
        e.to(V2(ro, colTop)); e.fillet(0.2); e.step(0.03); e.fillet(0.18); e.step(0.03); e.fillet(0.08)
        e.step(-0.04); e.fillet(0.5)                    // frieze
        e.step(0.05); e.ovolo(0.08, 0.06, segments: 3)              // bed molding
        let dentY = e.end.y
        e.fillet(0.12); e.step(0.28); e.fillet(0.18)   // corona over dentils
        e.cymaRecta(0.16, 0.16, segments: 3)
        let corniceTop = e.end.y
        e.to(V2(ri, corniceTop))
        e.to(V2(ri, colTop))
        m.add(ArchTrimKit.lathe(e, segments: 56, material: paint, seamTile: 1, maxSeg: 2))
        // Dentils under the corona.
        let outerR = e.points.filter { abs($0.y - dentY) < 0.01 }.map(\.x).max() ?? ro
        let dn = 96
        let dent = cuboid(V3(0.09, 0.11, 0.12), material: paint)
        for j in 0..<dn {
            let a = Float(j) / Float(dn) * 2 * .pi
            m.add(dent, Xform(translation: V3(sin(a), 0, cos(a)) * (outerR + 0.04) + V3(0, dentY + 0.065, 0), rotation: simd_quatf(angle: a, axis: V3(0, 1, 0))))
        }
        // Soffit ceiling inside the ring.
        m.add(Prim.cylinder(radius: ri + 0.02, height: 0.06, bevel: 0.005, segments: 48, bevelSegments: 1, material: paint), Xform(translation: V3(0, colTop + 0.05, 0)))
        // Low dome: blocking course, then a shallow spherical cap ribbed into 16 bays, with a finial.
        let dR = ro + 0.05, dH: Float = 1.25
        var d: [V2] = [V2(0, corniceTop), V2(dR, corniceTop), V2(dR, corniceTop + 0.18)]
        for i in 1...12 {
            let t = Float(i) / 12
            d.append(V2(dR * cos(t * .pi / 2) + 0.0001, corniceTop + 0.18 + dH * sin(t * .pi / 2)))
        }
        var domeS = Prim.lathe(d, segments: 48, seamTile: 2, material: dome)
        domeS.displace { q, nn in
            let a = atan2(q.z, q.x)
            return 0.015 * pow(abs(cos(a * 8)), 18) * saturate(nn.y * 2)
        }
        m.add(domeS)
        let top = corniceTop + 0.18 + dH
        m.add(turned([(0, 0), (0.32, 0), (0.32, 0.06), (0.18, 0.12), (0.14, 0.3), (0.2, 0.42), (0.08, 0.6), (0.05, 0.75), (0, 0.85)], segments: 20, material: paint),
              Xform(translation: V3(0, top - 0.04, 0)))
        // Floor inside the ring.
        m.add(Prim.cylinder(radius: R - 0.05, height: 0.02, bevel: 0.004, segments: 48, bevelSegments: 1, material: "wood.painted-exterior:8C8A84"), Xform(translation: V3(0, ph - 0.01, 0)))
        ArchTrimKit.weather(&m, seed: seed, amount: 0.35)
        groundAO(&m, height: 0.6, floor: 0.55)
        return LODModel(ArchTrimKit.ground(m))
    }

    /// Ionic column: attic base on a plinth, plain painted shaft with entasis, echinus, volute pair, abacus.
    func ionic(height H: Float, diameter: Float) -> Surface {
        var m = Model(name: "col")
        let r = diameter / 2, mat = paint
        m.add(Prim.roundedBox(V3(diameter * 1.4, r * 0.45, diameter * 1.4), radius: 0.01, bevelSegments: 1, material: mat), Xform(translation: V3(0, r * 0.225, 0)))
        var b = ArchProfile(V2(0, r * 0.45))
        b.to(V2(r * 1.22, r * 0.45)); b.torus(r * 0.13, segments: 4); b.step(-r * 0.1); b.scotia(r * 0.14, depth: r * 0.06, segments: 3); b.torus(r * 0.09, segments: 4)
        b.step(-(b.end.x - r * 1.02)); b.cavetto(r * 0.06, -r * 0.03, segments: 3)
        let by = b.end.y
        b.to(V2(0, by))
        m.add(ArchTrimKit.lathe(b, segments: 14, material: mat, maxSeg: 1))
        let abH = r * 0.18, volR = r * 0.4, capH = r * 0.75
        let shaftTop = H - capH, r1 = r * 0.86
        var sp = ArchProfile(V2(r, by - 0.004))
        for i in 1...8 {
            let t = Float(i) / 8
            let e = t < 0.33 ? 0 : pow((t - 0.33) / 0.67, 1.6)
            sp.push(V2(r + (r1 - r) * e, by + (shaftTop + 0.004 - by) * t), sharp: false)
        }
        m.add(ArchTrimKit.lathe(sp, segments: 16, material: mat, seamTile: 1, maxSeg: 1))
        var c = ArchProfile(V2(0, shaftTop))
        c.to(V2(r1, shaftTop)); c.torus(r * 0.05, segments: 3); c.step(-r * 0.01); c.ovolo(r * 0.2, r * 0.18, segments: 3)
        c.to(V2(0, c.end.y))
        m.add(ArchTrimKit.lathe(c, segments: 14, material: mat, maxSeg: 1))
        let vy = H - abH - volR * 0.95, span = r1 + volR * 0.5, bandZ = r1
        m.add(cuboid(V3(2 * span, volR * 0.9, 2 * bandZ), material: mat), Xform(translation: V3(0, H - abH - volR * 0.45, 0)))
        let vol = ArchTrimKit.volute(radius: volR, turns: 1.75, wire: r * 0.03, material: mat)
        for s in [Float(-1), 1] {
            m.add(Prim.cylinder(radius: volR, height: 2 * bandZ, bevel: 0.006, segments: 10, bevelSegments: 1, material: mat),
                  Xform(translation: V3(s * span, vy, -bandZ), rotation: simd_quatf(angle: .pi / 2, axis: V3(1, 0, 0))))
            m.add(vol, Xform(translation: V3(s * span, vy, bandZ + 0.002)))
        }
        let side = 2 * (span + volR * 0.3)
        m.add(Prim.roundedBox(V3(side, abH, side), radius: abH * 0.3, bevelSegments: 1, material: mat), Xform(translation: V3(0, H - abH / 2, 0)))
        var s = Surface(material: mat)
        for x in m.surfaces { s.append(x) }
        return s
    }
}
