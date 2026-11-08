import simd
import Foundation

/// Georgian church tower and steeple after Boston's Old North Church (1723, 54 m), modelled at 1:4.5 so it stands 12 m.
/// Flemish-bond brick tower with white wood quoins, string courses and a bevelled cornice, tall arched windows with
/// keystones, blind arches, louvered belfry arches and a small lantern window whose two panes glow warm. Above the
/// balustrade rise two stacked octagonal white-painted wooden stages with pilasters, then a tapering 32-sided spire,
/// a copper-green ball and weathervane. Faces +Z, origin at the base center, 2 LODs.
public struct OldNorthSteeple: RealAsset {
    public static let id = "old-north-steeple"
    public static let summary = "Old North Church steeple, Boston 1:4.5: red brick Georgian tower with white quoins and arched windows, louvered belfry, two octagonal wooden stages, tapering spire and copper weathervane."
    public static let tags = ["prop", "architecture", "building", "brick", "wood", "urban", "antique"]
    public static let budget = 24_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 6, distance: 1.1)

    /// Tower walls (Flemish bond).
    public var brick: MaterialKey = "brick.red"
    /// Quoins, string courses, cornice, octagonal stages, balustrade and spire.
    public var trim: MaterialKey = "wood.painted-exterior:EEECE4"
    /// Plinth.
    public var granite: MaterialKey = "stone.granite-curb"
    /// Dark glazing and louver recesses.
    public var glass: MaterialKey = "screen.off"
    public var iron: MaterialKey = "metal.wrought-iron"
    /// Ball, rod and vane.
    public var copper: MaterialKey = "metal.copper-patina"
    /// Lantern window panes.
    public var glow: MaterialKey = "emissive.warm"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        let a = buildLevel(seed: seed, full: true), b = a.bounds
        let shift = Xform(translation: V3(-(b.min.x + b.max.x) / 2, -b.min.y, -(b.min.z + b.max.z) / 2))
        return LODModel(levels: [a.transformed(shift), buildLevel(seed: seed, full: false).transformed(shift)], switchDistances: [12])
    }

    static func octagon(af: Float) -> [V2] {
        let r = af / 2 / cos(Float.pi / 8)
        return (0..<8).map { k in let t = (Float(k) + 0.5) * .pi / 4; return V2(r * cos(t), r * sin(t)) }
    }

    func buildLevel(seed: UInt64, full: Bool) -> Model {
        typealias K = LandmarkKit
        var m = Model(name: Self.id)
        let hw: Float = 1.75, y0: Float = 0.35, top: Float = 6.95
        func faceXf(_ k: Int) -> Xform {
            let a = Float(k) * .pi / 2
            return Xform(translation: V3(sin(a) * hw, 0, cos(a) * hw), rotation: simd_quatf(angle: a, axis: V3(0, 1, 0)))
        }
        // Plinth and water table.
        m.add(Prim.roundedBox(V3(4.0, 0.35, 4.0), radius: 0.025, bevelSegments: 2, material: granite), Xform(translation: V3(0, 0.175, 0)))
        m.add(Prim.roundedBox(V3(3.74, 0.18, 3.74), radius: 0.025, bevelSegments: 2, material: granite), Xform(translation: V3(0, 0.44, 0)))
        // Brick shaft in meter-gridded quads so grime varies across it.
        m.add(K.gridBox(V3(-hw, y0, -hw), V3(hw, top, hw), cell: 0.9, brick))
        // White wood quoins, long and short blocks alternating by course and face.
        let ch: Float = 0.36, step = full ? 1 : 2
        var q = Surface(material: trim)
        var j = 0, yq = y0 + 0.2
        while yq + ch <= top - 0.05 {
            for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
                let long = (j % 2 == 0) == (sx * sz > 0)
                let lx: Float = long ? 0.62 : 0.34, lz: Float = long ? 0.34 : 0.62
                q.append(K.box(size: V3(lx, ch - 0.03, 0.1), at: V3(sx * (hw - lx / 2 + 0.02), yq + ch / 2, sz * (hw + 0.03)), trim))
                q.append(K.box(size: V3(0.1, ch - 0.03, lz), at: V3(sx * (hw + 0.03), yq + ch / 2, sz * (hw - lz / 2 + 0.02)), trim))
            }}
            j += step; yq += ch * Float(step)
        }
        m.add(q)
        // String courses and belfry sill band, bevelled.
        for (sy, sh, sw) in [(3.62, 0.16, 3.72), (5.05, 0.18, 3.74), (5.14, 0.1, 3.66)] as [(Float, Float, Float)] {
            m.add(Prim.roundedBox(V3(sw, sh, sw), radius: 0.035, bevelSegments: 2, material: trim), Xform(translation: V3(0, sy, 0)))
        }
        // Tall arched windows with keystones: +Z front, second tier all faces; blind arches on the other three faces.
        for k in 0..<4 {
            let f = faceXf(k)
            if k == 0 {
                K.archWindow(&m, x: 0, y0: 0.85, w: 0.95, hs: 1.5, frame: trim, glass: glass, keystone: trim, xf: f)
            } else {
                let outer = K.archOutline(w: 1.2, hs: 1.62, segments: 16).map { $0 - V2(0, 0.12) }
                m.add(Prim.extrude(outer, depth: 0.08, bevel: 0.01, bevelSegments: 1, material: trim),
                      Xform(translation: V3(0, 0.85, 0.04)).landmarkThen(f))
                m.add(Prim.extrude(K.archOutline(w: 0.95, hs: 1.5, segments: 16), depth: 0.04, bevel: 0, bevelSegments: 0, material: "brick.unit-red-dark"),
                      Xform(translation: V3(0, 0.85, 0.08)).landmarkThen(f))
                m.add(K.box(V3(-0.16, 0.85 + 1.5 + 0.47, 0.05), V3(0.16, 0.85 + 1.5 + 0.97, 0.15), trim), f)
            }
            K.archWindow(&m, x: 0, y0: 3.98, w: 0.62, hs: 0.45, frame: trim, glass: glass, keystone: trim, xf: f)
        }
        // Belfry: louvered arches on all four faces, dark recess with raked slats.
        for k in 0..<4 {
            let f = faceXf(k)
            let outer = K.archOutline(w: 1.25, hs: 0.72, segments: 16).map { $0 - V2(0, 0.14) }
            m.add(Prim.extrude(outer, depth: 0.08, bevel: 0.01, bevelSegments: 1, material: trim),
                  Xform(translation: V3(0, 5.3, 0.04)).landmarkThen(f))
            m.add(Prim.extrude(K.archOutline(w: 0.98, hs: 0.72, segments: 16), depth: 0.05, bevel: 0, bevelSegments: 0, material: iron),
                  Xform(translation: V3(0, 5.3, 0.085)).landmarkThen(f))
            m.add(K.box(V3(-0.15, 5.3 + 0.72 + 0.5, 0.05), V3(0.15, 5.3 + 0.72 + 0.98, 0.15), trim), f)
            if full {
                for s in 0..<7 {
                    m.add(Prim.roundedBox(V3(0.96, 0.05, 0.14), radius: 0.01, bevelSegments: 1, material: trim),
                          Xform(translation: V3(0, 5.3 + 0.08 + Float(s) * 0.1, 0.14), rotation: simd_quatf(angle: 0.55, axis: V3(1, 0, 0))).landmarkThen(f))
                }
            } else {
                m.add(K.box(V3(-0.49, 5.45, 0.1), V3(0.49, 5.95, 0.12), trim), f)
            }
        }
        // Lantern window on the +Z belfry face: two joint-free glowing panes behind a white frame.
        do {
            let f = faceXf(0), wy: Float = 6.18, ww: Float = 0.46, wh: Float = 0.42
            m.add(K.box(V3(-ww / 2 - 0.05, wy - 0.05, 0), V3(ww / 2 + 0.05, wy + wh + 0.05, 0.1), trim), f)
            m.add(K.box(V3(-ww / 2, wy, 0.06), V3(ww / 2, wy + wh, 0.09), iron), f)
            for sx: Float in [-1, 1] {
                m.add(K.box(V3(sx > 0 ? 0.03 : -ww / 2 + 0.02, wy + 0.03, 0.09), V3(sx > 0 ? ww / 2 - 0.02 : -0.03, wy + wh - 0.03, 0.105), glow), f)
            }
            m.add(Prim.roundedBox(V3(ww + 0.3, 0.05, 0.16), radius: 0.012, bevelSegments: 1, material: trim), Xform(translation: V3(0, wy - 0.07, 0.07)).landmarkThen(f))
            m.add(K.box(V3(-0.11, wy + wh + 0.05, 0.05), V3(0.11, wy + wh + 0.2, 0.14), trim), f)
        }
        // Cornice with bevelled mouldings and a dentil row.
        m.add(Prim.roundedBox(V3(3.8, 0.12, 3.8), radius: 0.03, bevelSegments: 2, material: trim), Xform(translation: V3(0, top + 0.06, 0)))
        m.add(Prim.roundedBox(V3(3.96, 0.1, 3.96), radius: 0.03, bevelSegments: 2, material: trim), Xform(translation: V3(0, top + 0.2, 0)))
        m.add(Prim.roundedBox(V3(3.9, 0.12, 3.9), radius: 0.035, bevelSegments: 2, material: trim), Xform(translation: V3(0, top + 0.31, 0)))
        if full {
            var d = Surface(material: trim)
            for k in 0..<4 { for i in 0..<20 {
                let x = -1.8 + (Float(i) + 0.5) * 3.6 / 20
                d.append(K.box(size: V3(0.1, 0.09, 0.12), at: V3(x, top + 0.0, hw + 0.15), trim), Xform(rotation: simd_quatf(angle: Float(k) * .pi / 2, axis: V3(0, 1, 0))))
            }}
            m.add(d)
        }
        // Balustrade on the cornice, four runs.
        let by = top + 0.37
        for k in 0..<4 {
            K.balustrade(&m, x0: -1.72, x1: 1.72, y0: by, z: 1.74, height: 0.55, pitch: full ? 0.26 : 0.5, mat: trim,
                         xf: Xform(rotation: simd_quatf(angle: Float(k) * .pi / 2, axis: V3(0, 1, 0))))
        }
        // Octagonal stage 1: plinth, 8 faces with arched windows, corner pilasters, cornice.
        let s1 = by + 0.05, s1h: Float = 1.05, s1af: Float = 2.3
        func octFace(_ k: Int, af: Float) -> Xform {
            let a = Float(k) * .pi / 4
            return Xform(translation: V3(sin(a) * af / 2, 0, cos(a) * af / 2), rotation: simd_quatf(angle: a, axis: V3(0, 1, 0)))
        }
        func octPilasters(_ y: Float, _ h: Float, af: Float, w: Float) {
            let r = af / 2 / cos(Float.pi / 8)
            for k in 0..<8 {
                let a = (Float(k) + 0.5) * .pi / 4
                m.add(Prim.roundedBox(V3(w, h, w), radius: 0.015, bevelSegments: 1, material: trim),
                      Xform(translation: V3(sin(a) * r, y + h / 2, cos(a) * r), rotation: simd_quatf(angle: a, axis: V3(0, 1, 0))))
            }
        }
        m.add(Prim.loft([Prim.ring(Self.octagon(af: s1af + 0.3), y: s1), Prim.ring(Self.octagon(af: s1af + 0.3), y: s1 + 0.16)], capEnd: true, material: trim))
        m.add(Prim.loft([Prim.ring(Self.octagon(af: s1af), y: s1 + 0.16), Prim.ring(Self.octagon(af: s1af), y: s1 + s1h)], material: trim))
        for k in 0..<8 where k % 2 == 0 || full {
            K.archWindow(&m, x: 0, y0: s1 + 0.3, w: 0.5, hs: 0.3, frame: trim, glass: glass, keystone: trim, xf: octFace(k, af: s1af))
        }
        octPilasters(s1 + 0.16, s1h - 0.16, af: s1af, w: 0.14)
        for (dy, dh, daf) in [(s1h, 0.08, s1af + 0.28), (s1h + 0.08, 0.1, s1af + 0.1)] as [(Float, Float, Float)] {
            m.add(Prim.loft([Prim.ring(Self.octagon(af: daf), y: s1 + dy), Prim.ring(Self.octagon(af: daf), y: s1 + dy + dh)], capEnd: true, material: trim))
        }
        // Octagonal stage 2: narrower, pilasters, blind arched panels, cornice.
        let s2 = s1 + s1h + 0.18, s2h: Float = 0.85, s2af: Float = 1.6
        m.add(Prim.loft([Prim.ring(Self.octagon(af: s2af), y: s2), Prim.ring(Self.octagon(af: s2af), y: s2 + s2h)], capStart: true, material: trim))
        octPilasters(s2, s2h, af: s2af, w: 0.1)
        for k in 0..<8 where full || k % 2 == 0 {
            let f = octFace(k, af: s2af)
            m.add(Prim.extrude(K.archOutline(w: 0.4, hs: 0.28, segments: 12), depth: 0.04, bevel: 0, bevelSegments: 0, material: iron),
                  Xform(translation: V3(0, s2 + 0.2, 0.01)).landmarkThen(f))
        }
        for (dy, dh, daf) in [(s2h, 0.08, s2af + 0.24), (s2h + 0.08, 0.08, s2af + 0.08)] as [(Float, Float, Float)] {
            m.add(Prim.loft([Prim.ring(Self.octagon(af: daf), y: s2 + dy), Prim.ring(Self.octagon(af: daf), y: s2 + dy + dh)], capEnd: true, material: trim))
        }
        // Spire: 32-sided loft with slight entasis, collar rings, then ball and weathervane.
        let sp0 = s2 + s2h + 0.16, sp1: Float = 11.4, sides = 32, rows = full ? 16 : 6
        let circle: (Float) -> [V2] = { r in (0..<sides).map { i in let t = Float(i) / Float(sides) * 2 * .pi; return V2(r * cos(t), r * sin(t)) } }
        var rings: [[V3]] = []
        for i in 0...rows {
            let t = Float(i) / Float(rows)
            rings.append(Prim.ring(circle(0.02 + 0.62 * pow(1 - t, 1.3)), y: sp0 + (sp1 - sp0) * t))
        }
        m.add(Prim.loft(rings, capEnd: true, material: trim))
        for t: Float in [0.0, 0.45] {
            let y = sp0 + t * (sp1 - sp0)
            let rr = 0.02 + 0.62 * pow(1 - t, 1.3) + 0.04
            m.add(Prim.lathe([V2(0, y - 0.03), V2(rr, y - 0.03), V2(rr + 0.03, y), V2(rr, y + 0.03), V2(0, y + 0.03)], segments: 32, seamTile: 0.3, material: trim))
        }
        m.add(Prim.lathe((0...12).map { k in let t = Float(k) / 12 * .pi; return V2(0.11 * sin(t), sp1 - 0.03 + 0.11 * (1 - cos(t))) }, segments: 32, seamTile: 0.2, material: copper))
        m.add(Prim.cylinder(radius: 0.012, height: 0.6, bevel: 0.002, segments: 12, material: copper), Xform(translation: V3(0, sp1 + 0.1, 0)))
        let vane: [V2] = [V2(-0.32, 0), V2(0.18, 0), V2(0.34, 0.07), V2(0.18, 0.14), V2(-0.24, 0.14), V2(-0.3, 0.07)]
        m.add(Prim.extrude(Shape2D.deduped(vane), depth: 0.012, bevel: 0.002, bevelSegments: 1, material: copper),
              Xform(translation: V3(0, sp1 + 0.4, 0), rotation: simd_quatf(angle: 0.6, axis: V3(0, 1, 0))))
        m.add(Prim.lathe([V2(0, 0), V2(0.03, 0), V2(0.018, 0.04), V2(0, 0.05)], segments: 16, seamTile: 0.1, material: copper), Xform(translation: V3(0, sp1 + 0.7, 0)))
        groundAO(&m, height: 1.0)
        K.grime(&m, seed: seed, amount: 0.5, splash: 1.0)
        return m
    }
}
