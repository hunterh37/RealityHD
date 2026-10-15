import simd
import Foundation

/// Massachusetts State House (Charles Bulfinch, 1798), the Beacon Street block facing the Common:
/// red brick Federal main block with granite water table, a projecting arcaded brick base carrying a
/// two-storey white Corinthian loggia with entablature and pediment, cornice and balustrades, a white
/// drum with pilasters, the gilded dome, and a white lantern capped by a gilded pine cone.
/// Facade faces +Z. Centered on X/Z, base at y = 0.
public struct MassachusettsStateHouse: RealAsset {
    public static let id = "massachusetts-state-house"
    public static let summary = "Massachusetts State House, Beacon Hill facade block: arcaded brick base, Corinthian loggia, pediment, 16 m gilded dome on a drum, lantern with pine cone."
    public static let tags = ["structure", "architecture", "building", "brick", "metal"]
    public static let budget = 30000
    public static let author = "hunter"
    public static let preview = PreviewHint(azimuth: 20, elevation: 8, distance: 1.1)

    /// Main block width (m).
    public var width: Float = 52
    /// Height of the main block to the top of the cornice (m).
    public var cornice: Float = 20
    /// Dome outer diameter (m).
    public var domeDiameter: Float = 16
    /// Number of arches in the base arcade.
    public var arches = 7
    public var brick: MaterialKey = "brick.red"
    public var trim: MaterialKey = "wood.trim-weathered"
    public var gold: MaterialKey = "metal.gold-leaf"
    public var glass: MaterialKey = "screen.off"
    public var granite: MaterialKey = "stone.granite-curb"
    public var roof: MaterialKey = "metal.roofing"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        let a = buildLevel(seed: seed, full: true), b = a.bounds
        let shift = Xform(translation: V3(-(b.min.x + b.max.x) / 2, -b.min.y, -(b.min.z + b.max.z) / 2))
        return LODModel(levels: [a.transformed(shift), buildLevel(seed: seed, full: false).transformed(shift)], switchDistances: [60])
    }

    func buildLevel(seed: UInt64, full: Bool) -> Model {
        typealias K = LandmarkKit
        var m = Model(name: Self.id)
        let hx = width / 2, zf: Float = 4, zb: Float = -14, H = cornice
        let px: Float = 14.2, zp: Float = 13, baseH: Float = 7.4
        // Main block: brick walls on a granite water table, white belt course and cornice.
        m.add(K.gridBox(V3(-hx, 0, zb), V3(hx, H - 0.8, zf), cell: 3.0, brick))
        m.add(K.box(V3(-hx - 0.12, 0, zb - 0.12), V3(hx + 0.12, 1.1, zf + 0.12), granite))
        m.add(Prim.roundedBox(V3(width + 0.4, 0.3, zf - zb + 0.4), radius: 0.05, bevelSegments: 1, material: trim),
              Xform(translation: V3(0, baseH + 0.15, (zf + zb) / 2)))
        m.add(Prim.roundedBox(V3(width + 1.2, 0.9, zf - zb + 1.2), radius: 0.08, bevelSegments: 1, material: trim),
              Xform(translation: V3(0, H - 0.4, (zf + zb) / 2)))
        m.add(K.box(V3(-hx, H, zb), V3(hx, H + 0.4, zf), brick))
        m.add(K.hipRoof(hx: hx - 0.5, z0: zb + 0.5, z1: zf - 0.5, y0: H + 0.4, rise: 3.2, overhang: 0, mat: roof))
        // Brick chimney stacks with white caps on the roof slopes.
        for (cx, cz) in [(-19, -9), (19, -9), (-19, 0), (19, 0)] as [(Float, Float)] {
            m.add(K.box(V3(cx - 0.8, H, cz - 0.5), V3(cx + 0.8, H + 4.6, cz + 0.5), brick))
            m.add(Prim.roundedBox(V3(1.9, 0.3, 1.3), radius: 0.03, bevelSegments: 1, material: trim), Xform(translation: V3(cx, H + 4.75, cz)))
        }
        // Side-bay balustrades over the cornice.
        if full {
            for sx: Float in [-1, 1] {
                K.balustrade(&m, x0: sx > 0 ? px : -hx + 0.3, x1: sx > 0 ? hx - 0.3 : -px, y0: H, z: zf - 0.1, mat: trim)
            }
        }
        // Brick pilasters between the side-bay window stacks, granite steps up to the arcade.
        for sx: Float in [-1, 1] { for x in [15.0, 18.2, 21.4, 24.6] as [Float] {
            m.add(K.box(V3(sx * x - 0.35, 1.1, zf), V3(sx * x + 0.35, H - 0.8, zf + 0.18), brick))
        }}
        for k in 0..<3 {
            let d = Float(k) * 0.42
            m.add(Prim.roundedBox(V3(2 * px - 4 - Float(k) * 0.8, 0.17, 1.4 - d), radius: 0.02, bevelSegments: 1, material: granite),
                  Xform(translation: V3(0, 0.085 + Float(k) * 0.17, zp + 0.9 - d / 2)))
        }
        // Brick quoins at the corners.
        for sx: Float in [-1, 1] { for k in 0..<12 where k % 2 == 0 {
            let y = 1.1 + Float(k) * 1.5
            let a = sx * hx, b = sx * (hx - 0.9)
            m.add(K.box(V3(min(a, b), y, zf), V3(max(a, b), y + 1.45, zf + 0.06), brick))
        }}
        // Windows: front side bays, ends and back.
        let rows: [(Float, Float)] = [(1.7, 2.8), (7.6, 3.6), (12.6, 3.0), (16.6, 1.8)]
        let side: [Float] = [16.6, 19.8, 23.0]
        for (y0, h) in rows {
            for sx: Float in [-1, 1] { for x in side {
                K.window(&m, x: sx * x, y0: y0, w: 1.5, h: h, frame: trim, glass: glass, lintel: h > 2 ? granite : nil,
                         muntins: full, xf: Xform(translation: V3(0, 0, zf)))
            }}
            if !full { continue }
            for k in 0..<8 {
                let x = -hx + 3 + Float(k) * (width - 6) / 7
                K.window(&m, x: x, y0: y0, w: 1.5, h: h, frame: trim, glass: glass, lintel: nil, muntins: false,
                         xf: Xform(translation: V3(0, 0, zb), rotation: simd_quatf(angle: .pi, axis: V3(0, 1, 0))))
            }
            for sx: Float in [-1, 1] { for k in 0..<4 {
                let z = zb + 2.5 + Float(k) * (zf - zb - 5) / 3
                K.window(&m, x: 0, y0: y0, w: 1.5, h: h, frame: trim, glass: glass, lintel: nil, muntins: false,
                         xf: Xform(translation: V3(sx * hx, 0, z), rotation: simd_quatf(angle: sx * .pi / 2, axis: V3(0, 1, 0))))
            }}
        }
        // Central pavilion: arcaded brick base projecting to zp.
        let bayW = 2 * px / Float(arches), archW = bayW * 0.66, spring: Float = 4.1
        m.add(K.box(V3(-px, 0, zf), V3(px, baseH, zp - 1.2), brick))   // back of the arcade porch
        m.add(K.box(V3(-px - 0.1, 0, zf), V3(px + 0.1, 0.5, zp + 0.1), granite))
        for k in 0..<arches {
            let cx = -px + bayW * (Float(k) + 0.5)
            // Pier pair and spandrel around each arch.
            let outline: [V2] = {
                var o = [V2(-bayW / 2, 0), V2(-archW / 2, 0)]
                for j in 0...10 { let a = .pi - Float(j) / 10 * .pi; o.append(V2(archW / 2 * cos(a), spring + archW / 2 * sin(a))) }
                o.removeLast(); o.append(V2(archW / 2, spring)); o.append(V2(archW / 2, 0)); o.append(V2(bayW / 2, 0))
                o.append(V2(bayW / 2, baseH)); o.append(V2(-bayW / 2, baseH))
                return o
            }()
            m.add(Prim.extrude(outline, depth: 1.2, bevel: 0.0, bevelSegments: 0, material: brick),
                  Xform(translation: V3(cx, 0.5, zp - 0.6)))
            // White keystone and impost band.
            m.add(K.box(size: V3(0.45, 0.7, 0.2), at: V3(cx, 0.5 + spring + archW / 2 + 0.25, zp + 0.05), trim))
            m.add(K.box(size: V3(bayW - archW + 0.16, 0.22, 0.14), at: V3(cx - bayW / 2 + (bayW - archW) / 4, 0.5 + spring, zp + 0.02), trim))
            m.add(K.box(size: V3((bayW - archW) / 2 + 0.16, 0.22, 0.14), at: V3(cx + bayW / 2 - (bayW - archW) / 4, 0.5 + spring, zp + 0.02), trim))
            // Shadowed doorway at the back of the arcade.
            if full { K.archWindow(&m, x: cx, y0: 0.5, w: archW * 0.6, hs: 2.4, frame: trim, glass: glass, xf: Xform(translation: V3(0, 0, zp - 1.2))) }
        }
        for sx: Float in [-1, 1] { m.add(K.box(V3(sx > 0 ? px - 0.01 : -px - 0.6, 0, zf), V3(sx > 0 ? px + 0.6 : -px + 0.01, baseH + 0.5, zp), brick)) }
        // Loggia deck and white cornice band.
        m.add(Prim.roundedBox(V3(2 * px + 1.5, 0.55, zp - zf + 0.5), radius: 0.06, bevelSegments: 1, material: trim),
              Xform(translation: V3(0, baseH + 0.27, (zp + zf) / 2 + 0.2)))
        let colY = baseH + 0.55, colH: Float = 9.6, colZ = zp - 1.2
        let xs: [Float] = [-13.2, -11.4, -6.2, -2.1, 2.1, 6.2, 11.4, 13.2]
        let col = K.column(height: colH, diameter: 0.95, corinthian: true, mat: trim, segments: full ? 12 : 8)
        for x in xs {
            m.add(col, Xform(translation: V3(x, colY, colZ)))
            m.add(K.box(size: V3(1.4, 0.5, 1.4), at: V3(x, colY + 0.25, colZ), trim))
        }
        // Loggia back wall windows (two storeys, five bays) and pilasters behind the columns.
        for x in [-8.7, -4.15, 0, 4.15, 8.7] as [Float] {
            K.window(&m, x: x, y0: colY + 0.8, w: 1.7, h: 3.8, frame: trim, glass: glass, lintel: trim, muntins: full, xf: Xform(translation: V3(0, 0, zf)))
            K.window(&m, x: x, y0: colY + 5.9, w: 1.7, h: 2.8, frame: trim, glass: glass, lintel: nil, muntins: full, xf: Xform(translation: V3(0, 0, zf)))
        }
        for x in xs { m.add(K.box(size: V3(0.8, colH, 0.15), at: V3(x, colY + colH / 2, zf + 0.07), trim)) }
        // Entablature and pediment.
        let ey = colY + colH
        m.add(K.box(V3(-px, ey, zf), V3(px, ey + 1.0, zp - 0.6), trim))
        m.add(Prim.roundedBox(V3(2 * px + 0.8, 0.55, zp - zf + 0.4), radius: 0.05, bevelSegments: 1, material: trim),
              Xform(translation: V3(0, ey + 1.25, (zf + zp) / 2 - 0.4)))
        if full {
            var dent = Surface(material: trim)
            var x = -px + 0.2
            while x < px - 0.1 { dent.append(K.box(V3(x, ey + 0.82, zp - 0.6), V3(x + 0.14, ey + 0.98, zp - 0.45), trim)); x += 0.3 }
            m.add(dent)
        }
        let py = ey + 1.5
        K.pediment(&m, w: 2 * px, rise: 4.0, y0: py, z0: zf, z1: zp - 0.6, mat: trim, tympanum: trim)
        // Lunette in the tympanum.
        m.add(Prim.extrude(K.archOutline(w: 2.4, hs: 0).map { V2($0.x, $0.y) }, depth: 0.1, bevel: 0.01, bevelSegments: 1, material: glass),
              Xform(translation: V3(0, py + 0.5, zp - 0.85)))
        // Drum, dome, lantern, pine cone.
        let dz: Float = -5, dr = domeDiameter / 2, drumY = H + 0.4, drumH: Float = 6
        let seg = full ? 40 : 24
        m.add(Prim.lathe([V2(0, drumY), V2(dr + 1, drumY), V2(dr + 1, drumY + drumH), V2(0, drumY + drumH)], segments: seg, seamTile: 1, material: trim),
              Xform(translation: V3(0, 0, dz)))
        m.add(Prim.lathe([V2(0, drumY + drumH), V2(dr + 1.5, drumY + drumH), V2(dr + 1.6, drumY + drumH + 0.35), V2(dr + 1.2, drumY + drumH + 0.7), V2(0, drumY + drumH + 0.7)],
                         segments: seg, seamTile: 1, material: trim), Xform(translation: V3(0, 0, dz)))
        let nP = 16
        for k in 0..<nP {
            let a = Float(k) / Float(nP) * 2 * .pi + .pi / Float(nP)
            let rot = simd_quatf(angle: a, axis: V3(0, 1, 0))
            m.add(K.box(size: V3(0.6, drumH, 0.3), at: .zero, trim), Xform(translation: V3(sin(a) * (dr + 1.1), drumY + drumH / 2, dz + cos(a) * (dr + 1.1)), rotation: rot))
            if k % 2 == 0 {
                let b = a + .pi / Float(nP)
                K.archWindow(&m, x: 0, y0: drumY + 1.5, w: 1.1, hs: 2.2, frame: trim, glass: glass,
                             xf: Xform(translation: V3(sin(b) * (dr + 0.98), 0, dz + cos(b) * (dr + 0.98)), rotation: simd_quatf(angle: b, axis: V3(0, 1, 0))))
            }
        }
        let domeY = drumY + drumH + 0.7
        var dp: [V2] = []
        for k in 0...16 { let t = Float(k) / 16 * .pi / 2; dp.append(V2(dr * cos(t), domeY + dr * 0.95 * sin(t))) }
        m.add(Prim.lathe(dp, segments: seg, seamTile: 1.5, material: gold), Xform(translation: V3(0, 0, dz)))
        // Raised ribs on the dome.
        if full {
            for k in 0..<12 {
                let a = Float(k) / 12 * 2 * .pi
                let pts = (2...15).map { j -> V3 in let t = Float(j) / 16 * .pi / 2; return V3(sin(a) * dr * cos(t) * 1.004, domeY + dr * 0.95 * sin(t), dz + cos(a) * dr * cos(t) * 1.004) }
                m.add(Prim.tube(pts, radii: pts.map { _ in 0.07 }, sides: 3, seamTile: 0.5, material: gold))
            }
        }
        let ly = domeY + dr * 0.95 - 0.3
        m.add(Prim.lathe([V2(0, ly), V2(2.6, ly), V2(2.6, ly + 0.5), V2(0, ly + 0.5)], segments: 24, seamTile: 0.6, material: trim), Xform(translation: V3(0, 0, dz)))
        m.add(Prim.lathe([V2(0, ly + 0.5), V2(1.75, ly + 0.5), V2(1.75, ly + 4.2), V2(0, ly + 4.2)], segments: 20, seamTile: 0.6, material: glass), Xform(translation: V3(0, 0, dz)))
        let lc = K.column(height: 3.7, diameter: 0.26, corinthian: false, mat: trim, segments: 8)
        for k in 0..<8 { let a = Float(k) / 8 * 2 * .pi; m.add(lc, Xform(translation: V3(sin(a) * 2.2, ly + 0.5, dz + cos(a) * 2.2))) }
        m.add(Prim.lathe([V2(0, ly + 4.2), V2(2.6, ly + 4.2), V2(2.75, ly + 4.6), V2(2.5, ly + 4.85), V2(0, ly + 4.85)], segments: 24, seamTile: 0.6, material: trim), Xform(translation: V3(0, 0, dz)))
        var cap: [V2] = []
        for k in 0...8 { let t = Float(k) / 8 * .pi / 2; cap.append(V2(2.1 * cos(t), ly + 4.85 + 1.5 * sin(t))) }
        m.add(Prim.lathe(cap, segments: 24, seamTile: 0.6, material: trim), Xform(translation: V3(0, 0, dz)))
        // Gilded pine cone on a short stem.
        let cy = ly + 6.3
        var cone: [V2] = [V2(0, cy), V2(0.25, cy), V2(0.25, cy + 0.3)]
        for k in 0...10 { let t = Float(k) / 10; cone.append(V2(0.55 * sin(.pi * (0.12 + 0.88 * t)) * (1 - 0.4 * t), cy + 0.3 + 1.6 * t)) }
        cone.append(V2(0, cy + 1.95))
        var pc = Prim.lathe(cone, segments: 16, seamTile: 0.3, material: gold)
        if full {
            pc.positions = pc.positions.map { p in
                let r = simd_length(V2(p.x, p.z)); guard r > 0.05 else { return p }
                let a = atan2(p.z, p.x), bump = 1 + 0.12 * max(0, sin(a * 8 + p.y * 18))
                return V3(p.x * bump, p.y, p.z * bump)
            }
            pc.recomputeNormals(); pc.computeTangents()
        }
        m.add(pc, Xform(translation: V3(0, 0, dz)))
        groundAO(&m, height: 1.0)
        K.grime(&m, seed: seed, amount: 0.55)
        return m
    }
}
