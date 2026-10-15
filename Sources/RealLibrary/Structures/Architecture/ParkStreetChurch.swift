import simd
import Foundation

/// Park Street Church (Peter Banner, 1809) at the corner of the Common: red brick Georgian nave with
/// two tiers of round-headed windows under a slate gable, brick tower and lower wings with an Ionic
/// porch, then the white painted-wood steeple: belfry stage with louvered arches and urns, clock
/// stage with four dials, Corinthian rotunda, attic drum, octagonal spire, ball and weathervane.
/// Facade faces +Z. Centered on X/Z, base at y = 0.
public struct ParkStreetChurch: RealAsset {
    public static let id = "park-street-church"
    public static let summary = "Park Street Church, Boston: red brick Georgian nave and tower, white multi-stage wooden steeple 66 m, porches, arched windows, clock faces."
    public static let tags = ["structure", "architecture", "building", "brick", "wood"]
    public static let budget = 30000
    public static let author = "hunter"
    public static let preview = PreviewHint(azimuth: 28, elevation: 6, distance: 1.05)

    /// Nave width (m).
    public var naveWidth: Float = 22
    /// Nave length behind the tower (m).
    public var naveLength: Float = 40
    /// Height to the tip of the weathervane (m).
    public var totalHeight: Float = 66
    public var brick: MaterialKey = "brick.red"
    public var trim: MaterialKey = "wood.trim-weathered"
    public var glass: MaterialKey = "screen.off"
    public var granite: MaterialKey = "stone.granite-curb"
    public var roof: MaterialKey = "metal.roofing"
    public var iron: MaterialKey = "metal.wrought-iron"
    public var gilt: MaterialKey = "metal.brass-aged"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        let a = buildLevel(seed: seed, full: true), b = a.bounds
        let shift = Xform(translation: V3(-(b.min.x + b.max.x) / 2, -b.min.y, -(b.min.z + b.max.z) / 2))
        return LODModel(levels: [a.transformed(shift), buildLevel(seed: seed, full: false).transformed(shift)], switchDistances: [60])
    }

    func buildLevel(seed: UInt64, full: Bool) -> Model {
        typealias K = LandmarkKit
        var m = Model(name: Self.id)
        let hx = naveWidth / 2, zb = -naveLength, eave: Float = 13, rise: Float = 5.5
        // Nave walls, granite base, eave cornice, brick gable infill, slate roof planes.
        m.add(K.gridBox(V3(-hx, 0, zb), V3(hx, eave, 0), cell: 2.0, brick))
        m.add(K.box(V3(-hx - 0.1, 0, zb - 0.1), V3(hx + 0.1, 0.8, 0.1), granite))
        m.add(Prim.roundedBox(V3(naveWidth + 0.9, 0.6, naveLength + 0.9), radius: 0.05, bevelSegments: 1, material: trim),
              Xform(translation: V3(0, eave + 0.3, zb / 2)))
        let gable: [V2] = [V2(-hx, 0), V2(hx, 0), V2(0, rise)]
        m.add(Prim.extrude(gable, depth: naveLength - 0.4, bevel: 0, bevelSegments: 0, material: brick), Xform(translation: V3(0, eave + 0.6, zb / 2)))
        let slope = atan2(rise, hx), slab = hx / cos(slope) + 0.7
        for sx: Float in [-1, 1] {
            m.add(Prim.roundedBox(V3(slab, 0.25, naveLength + 0.8), radius: 0.04, bevelSegments: 1, material: roof),
                  Xform(translation: V3(sx * (hx / 2 - 0.05), eave + 0.6 + rise / 2 + 0.15, zb / 2), rotation: simd_quatf(angle: -sx * slope, axis: V3(0, 0, 1))))
        }
        // String course between window tiers, brick pilasters between bays, ridge cap.
        m.add(Prim.roundedBox(V3(naveWidth + 0.24, 0.32, naveLength - 0.1), radius: 0.04, bevelSegments: 1, material: trim), Xform(translation: V3(0, 5.9, zb / 2 - 0.05)))
        for sx: Float in [-1, 1] { for k in 0..<7 {
            let z = -6.7 - Float(k) * 5.6
            m.add(K.box(V3(sx > 0 ? hx : -hx - 0.2, 0.8, z - 0.45), V3(sx > 0 ? hx + 0.2 : -hx, eave, z + 0.45), brick))
        }}
        m.add(Prim.tube([V3(0, eave + 0.6 + rise + 0.2, zb - 0.3), V3(0, eave + 0.6 + rise + 0.2, -0.2)], radii: [0.14, 0.14], sides: 8, seamTile: 0.3, material: roof))
        // Rear gable rake trim.
        K.pediment(&m, w: naveWidth + 0.4, rise: rise, y0: eave + 0.6, z0: zb - 0.4, z1: zb - 0.05, mat: trim, tympanum: brick)
        // Nave windows, two tiers of round heads on both sides, three on the back.
        for sx: Float in [-1, 1] { for k in 0..<6 {
            let z = -9.5 - Float(k) * 5.6
            let xf = Xform(translation: V3(sx * hx, 0, z), rotation: simd_quatf(angle: sx * .pi / 2, axis: V3(0, 1, 0)))
            K.archWindow(&m, x: 0, y0: 1.8, w: 1.5, hs: 2.6, frame: trim, glass: glass, keystone: full ? trim : nil, xf: xf)
            K.archWindow(&m, x: 0, y0: 6.6, w: 1.8, hs: 3.6, frame: trim, glass: glass, keystone: full ? trim : nil, xf: xf)
        }}
        for x in [-6.0, 0, 6.0] as [Float] {
            K.archWindow(&m, x: x, y0: 6.6, w: 1.8, hs: 3.6, frame: trim, glass: glass,
                         xf: Xform(translation: V3(0, 0, zb), rotation: simd_quatf(angle: .pi, axis: V3(0, 1, 0))))
        }
        // Front wings flanking the tower, with arched doors and windows.
        let tw: Float = 5, tz: Float = 6.5, wingH: Float = 10
        for sx: Float in [-1, 1] {
            let x0 = sx > 0 ? tw : -hx, x1 = sx > 0 ? hx : -tw
            m.add(K.box(V3(x0, 0, 0), V3(x1, wingH, 3.5), brick))
            m.add(K.box(V3(x0 - 0.1, 0, -0.1), V3(x1 + 0.1, 0.8, 3.6), granite))
            m.add(Prim.roundedBox(V3(x1 - x0 + 0.5, 0.5, 3.9), radius: 0.04, bevelSegments: 1, material: trim), Xform(translation: V3((x0 + x1) / 2, wingH + 0.25, 1.75)))
            if full { K.balustrade(&m, x0: x0 + 0.2, x1: x1 - 0.2, y0: wingH + 0.5, z: 3.4, height: 0.9, mat: trim) }
            let cx = (x0 + x1) / 2
            K.archWindow(&m, x: cx, y0: 0.8, w: 1.7, hs: 2.4, frame: trim, glass: glass, keystone: trim, xf: Xform(translation: V3(0, 0, 3.5)))
            K.archWindow(&m, x: cx, y0: 5.4, w: 1.6, hs: 2.4, frame: trim, glass: glass, keystone: trim, xf: Xform(translation: V3(0, 0, 3.5)))
            // Nave gable shoulders above the wings.
            m.add(K.box(V3(x0, wingH, -0.2), V3(x1, eave, 0.2), brick))
        }
        // Brick tower with quoined corners and a white Ionic porch.
        let towerTop: Float = 23
        m.add(K.gridBox(V3(-tw, 0, 0), V3(tw, towerTop, tz), cell: 1.6, brick))
        m.add(K.box(V3(-tw - 0.1, 0, -0.1), V3(tw + 0.1, 0.8, tz + 0.1), granite))
        for sx: Float in [-1, 1] { for k in 0..<10 where k % 2 == 0 {
            let y = 0.8 + Float(k) * 2.2
            m.add(K.box(V3(sx > 0 ? tw - 0.6 : -tw - 0.06, y, tz - 0.6), V3(sx > 0 ? tw + 0.06 : -tw + 0.6, y + 2.1, tz + 0.06), brick))
        }}
        K.archWindow(&m, x: 0, y0: 9.5, w: 2.2, hs: 3.8, frame: trim, glass: glass, keystone: trim, xf: Xform(translation: V3(0, 0, tz)))
        K.archWindow(&m, x: 0, y0: 16.2, w: 1.8, hs: 2.6, frame: trim, glass: glass, keystone: trim, xf: Xform(translation: V3(0, 0, tz)))
        for sx: Float in [-1, 1] {
            K.archWindow(&m, x: 0, y0: 16.2, w: 1.8, hs: 2.6, frame: trim, glass: glass, keystone: trim,
                         xf: Xform(translation: V3(sx * tw, 0, tz / 2), rotation: simd_quatf(angle: sx * .pi / 2, axis: V3(0, 1, 0))))
        }
        m.add(Prim.roundedBox(V3(2 * tw + 0.7, 0.8, tz + 0.7), radius: 0.05, bevelSegments: 1, material: trim), Xform(translation: V3(0, towerTop + 0.4, tz / 2)))
        // Porch: four Ionic columns on a granite stylobate, entablature, doorway.
        let pz = tz + 2.6, pH: Float = 6.5
        m.add(Prim.roundedBox(V3(9.6, 0.5, 3.4), radius: 0.03, bevelSegments: 1, material: granite), Xform(translation: V3(0, 0.25, tz + 1.6)))
        for k in 0..<2 { m.add(Prim.roundedBox(V3(7.4, 0.17, 0.4), radius: 0.02, bevelSegments: 1, material: granite), Xform(translation: V3(0, 0.085 + Float(k) * 0.17, tz + 3.5 - Float(k) * 0.35))) }
        let ion = K.column(height: pH, diameter: 0.7, corinthian: false, mat: trim, segments: full ? 12 : 8)
        for x in [-3.9, -1.4, 1.4, 3.9] as [Float] { m.add(ion, Xform(translation: V3(x, 0.5, pz))) }
        for x in [-3.9, 3.9] as [Float] { m.add(K.box(size: V3(0.75, pH, 0.2), at: V3(x, 0.5 + pH / 2, tz + 0.1), trim)) }
        m.add(K.box(V3(-4.4, 0.5 + pH, tz), V3(4.4, 0.5 + pH + 1.0, pz + 0.45), trim))
        m.add(Prim.roundedBox(V3(9.3, 0.4, pz - tz + 0.8), radius: 0.04, bevelSegments: 1, material: trim), Xform(translation: V3(0, pH + 1.7, (tz + pz) / 2 + 0.2)))
        if full { K.balustrade(&m, x0: -4.4, x1: 4.4, y0: pH + 1.9, z: pz + 0.2, height: 0.8, mat: trim) }
        K.archWindow(&m, x: 0, y0: 0.5, w: 2.0, hs: 3.2, frame: trim, glass: glass, keystone: trim, xf: Xform(translation: V3(0, 0, tz)))
        // Belfry stage: white wood, corner pilasters, louvered arches, cornice and urns.
        let s1 = towerTop + 0.8, s1w: Float = 8, s1h: Float = 7.2, sz = tz / 2
        m.add(K.gridBox(V3(-s1w / 2, s1, sz - s1w / 2), V3(s1w / 2, s1 + s1h, sz + s1w / 2), cell: 1.2, trim))
        for k in 0..<4 {
            let a = Float(k) * .pi / 2, rot = simd_quatf(angle: a, axis: V3(0, 1, 0))
            let face = Xform(translation: V3(sin(a) * s1w / 2, 0, sz + cos(a) * s1w / 2), rotation: rot)
            K.archWindow(&m, x: 0, y0: s1 + 1.2, w: 2.6, hs: 3.0, frame: trim, glass: glass, keystone: trim, xf: face)
            if full { for j in 0..<6 {
                m.add(K.box(size: V3(2.5, 0.08, 0.3), at: .zero, trim),
                      Xform(translation: V3(0, s1 + 1.6 + Float(j) * 0.55, 0.2), rotation: simd_quatf(angle: 0.5, axis: V3(1, 0, 0))).landmarkThen(face))
            }}
            for sx: Float in [-1, 1] {
                m.add(K.box(size: V3(0.7, s1h, 0.25), at: V3(sx * (s1w / 2 - 0.35), s1 + s1h / 2, 0.12), trim), face)
            }
        }
        m.add(Prim.roundedBox(V3(s1w + 0.8, 0.7, s1w + 0.8), radius: 0.06, bevelSegments: 1, material: trim), Xform(translation: V3(0, s1 + s1h + 0.35, sz)))
        let urn = Prim.lathe([V2(0, 0), V2(0.35, 0), V2(0.2, 0.2), V2(0.45, 0.6), V2(0.3, 1.0), V2(0.12, 1.1), V2(0.15, 1.35), V2(0, 1.4)], segments: 10, seamTile: 0.3, material: trim)
        for (ux, uz) in [(-1, -1), (1, -1), (1, 1), (-1, 1)] as [(Float, Float)] {
            m.add(urn, Xform(translation: V3(ux * (s1w / 2 + 0.1), s1 + s1h + 0.7, sz + uz * (s1w / 2 + 0.1))))
        }
        // Clock stage with four dials.
        let s2 = s1 + s1h + 0.7, s2w: Float = 6.2, s2h: Float = 5
        m.add(K.gridBox(V3(-s2w / 2, s2, sz - s2w / 2), V3(s2w / 2, s2 + s2h, sz + s2w / 2), cell: 1.0, trim))
        for k in 0..<4 {
            let a = Float(k) * .pi / 2
            let face = Xform(translation: V3(sin(a) * s2w / 2, s2 + s2h / 2, sz + cos(a) * s2w / 2), rotation: simd_quatf(angle: a, axis: V3(0, 1, 0)))
            m.add(Prim.cylinder(radius: 1.25, height: 0.12, bevel: 0.02, segments: 32, material: iron), Xform(rotation: simd_quatf(angle: .pi / 2, axis: V3(1, 0, 0))).landmarkThen(face))
            m.add(Prim.cylinder(radius: 1.12, height: 0.16, bevel: 0.01, segments: 32, material: "plastic.white"), Xform(rotation: simd_quatf(angle: .pi / 2, axis: V3(1, 0, 0))).landmarkThen(face))
            for h in 0..<12 {
                let t = Float(h) / 12 * 2 * .pi
                m.add(K.box(size: V3(0.06, 0.22, 0.03), at: .zero, iron), Xform(translation: V3(sin(t) * 0.95, cos(t) * 0.95, 0.17), rotation: simd_quatf(angle: -t, axis: V3(0, 0, 1))).landmarkThen(face))
            }
            m.add(K.box(V3(-0.04, 0, 0.17), V3(0.04, 0.85, 0.21), iron), Xform(rotation: simd_quatf(angle: -0.9, axis: V3(0, 0, 1))).landmarkThen(face))
            m.add(K.box(V3(-0.05, 0, 0.21), V3(0.05, 0.6, 0.25), iron), Xform(rotation: simd_quatf(angle: 2.2, axis: V3(0, 0, 1))).landmarkThen(face))
        }
        m.add(Prim.roundedBox(V3(s2w + 0.7, 0.6, s2w + 0.7), radius: 0.05, bevelSegments: 1, material: trim), Xform(translation: V3(0, s2 + s2h + 0.3, sz)))
        // Corinthian rotunda.
        let s3 = s2 + s2h + 0.6, s3h: Float = 5.6
        m.add(Prim.lathe([V2(0, s3), V2(2.0, s3), V2(2.0, s3 + s3h), V2(0, s3 + s3h)], segments: 20, seamTile: 0.6, material: trim), Xform(translation: V3(0, 0, sz)))
        m.add(Prim.lathe([V2(0, s3 - 0.1), V2(3.0, s3 - 0.1), V2(3.0, s3 + 0.3), V2(0, s3 + 0.3)], segments: 24, seamTile: 0.6, material: trim), Xform(translation: V3(0, 0, sz)))
        let cor = K.column(height: s3h - 0.3, diameter: 0.42, corinthian: true, mat: trim, segments: full ? 10 : 6)
        for k in 0..<8 {
            let a = Float(k) / 8 * 2 * .pi + .pi / 8
            m.add(cor, Xform(translation: V3(sin(a) * 2.6, s3 + 0.3, sz + cos(a) * 2.6)))
            if k % 2 == 0 {
                K.archWindow(&m, x: 0, y0: s3 + 1, w: 0.9, hs: 2.4, frame: trim, glass: glass,
                             xf: Xform(translation: V3(sin(a + .pi / 8) * 1.98, 0, sz + cos(a + .pi / 8) * 1.98), rotation: simd_quatf(angle: a + .pi / 8, axis: V3(0, 1, 0))))
            }
        }
        m.add(Prim.lathe([V2(0, s3 + s3h), V2(3.0, s3 + s3h), V2(3.2, s3 + s3h + 0.5), V2(3.25, s3 + s3h + 0.9), V2(0, s3 + s3h + 0.9)], segments: 24, seamTile: 0.6, material: trim), Xform(translation: V3(0, 0, sz)))
        // Attic drum, octagonal spire, ball, vane.
        let s4 = s3 + s3h + 0.9
        m.add(Prim.lathe([V2(0, s4), V2(2.2, s4), V2(2.2, s4 + 2.4), V2(2.45, s4 + 2.6), V2(2.45, s4 + 2.9), V2(0, s4 + 2.9)], segments: 16, seamTile: 0.6, material: trim), Xform(translation: V3(0, 0, sz)))
        let spBase = s4 + 2.9, spTop = totalHeight - 2.6
        let spH = spTop - spBase - 0.4
        for k in 0..<8 {
            let a0 = Float(k) / 8 * 2 * .pi, a1 = Float(k + 1) / 8 * 2 * .pi
            var f = Surface(material: trim)
            let p0 = V3(1.75 * cos(a0), spBase + 0.4, sz - 1.75 * sin(a0)), p1 = V3(1.75 * cos(a1), spBase + 0.4, sz - 1.75 * sin(a1))
            let top = V3(0, spTop, sz), q0 = V3(0.06 * cos(a0), spTop - 0.01, sz - 0.06 * sin(a0)), q1 = V3(0.06 * cos(a1), spTop - 0.01, sz - 0.06 * sin(a1))
            let n = simd_normalize(simd_cross(p1 - p0, q0 - p0))
            let u = simd_normalize(p1 - p0), v = simd_cross(n, u)
            let ids = [p0, p1, q1, q0].map { p in f.add(p, n, V2(simd_dot(p, u), simd_dot(p, v))) }
            f.quad(ids[0], ids[1], ids[2], ids[3]); f.computeTangents()
            m.add(f)
        }
        m.add(Prim.lathe([V2(0, spBase), V2(1.95, spBase), V2(1.95, spBase + 0.4), V2(0, spBase + 0.4)], segments: 8, seamTile: 1, material: trim),
              Xform(translation: V3(0, 0, sz)))
        m.add(Prim.lathe((0...8).map { k in let t = Float(k) / 8 * .pi; return V2(0.35 * sin(t), spTop + 0.2 + 0.35 * (1 - cos(t))) }, segments: 12, seamTile: 0.3, material: gilt), Xform(translation: V3(0, 0, sz)))
        m.add(Prim.cylinder(radius: 0.04, height: 2.1, bevel: 0, segments: 6, material: iron), Xform(translation: V3(0, spTop - 0.2, sz)))
        m.add(Prim.extrude([V2(-0.9, 0), V2(0.6, 0), V2(0.9, 0.18), V2(0.6, 0.36), V2(-0.7, 0.36), V2(-0.55, 0.18)], depth: 0.03, bevel: 0, bevelSegments: 0, material: gilt),
              Xform(translation: V3(0, totalHeight - 1.0, sz), rotation: simd_quatf(angle: 0.6, axis: V3(0, 1, 0))))
        groundAO(&m, height: 1.0)
        K.grime(&m, seed: seed, amount: 0.55)
        return m
    }
}
