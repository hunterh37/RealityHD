import simd
import Foundation

/// Skamp-style 10 ft (3.05 m) riveted aluminum jon boat, 1.2 m beam, 0.38 m sides: flat bottom with a
/// raked bow, square stern transom with a wooden motor board, olive painted exterior over mill aluminum,
/// rolled gunwale rails, two box bench seats, floor ribs, two clamp-on rod holders, an 8 lb mushroom
/// anchor on a rope coil. Bow is +X. Named points in `anchors`: `motorMount` (bow transom top center),
/// `seatBow`, `seatStern` (bench top centers), `rodHolderPort`, `rodHolderStarboard`, `anchorRope`.
public struct SkampBoat: RealAsset {
    public static let id = "skamp-boat"
    public static let summary = "10 ft aluminum jon boat: flat bottom, raked bow, olive painted hull, rolled gunwales, two bench seats, rod holders, mushroom anchor."
    public static let tags = ["prop", "vehicle", "metal", "boat", "river"]
    public static let budget = 14_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 145, elevation: 28, distance: 0.9)

    /// Overall length, beam at the gunwales and side height in meters.
    public var length: Float = 3.05
    public var beam: Float = 1.2
    public var depth: Float = 0.38
    /// Bottom width (chine to chine) amidships.
    public var bottomWidth: Float = 0.86
    /// How far the bottom rises at the bow, meters.
    public var bowRise: Float = 0.26
    public var hullPaint: MaterialKey = "metal.boat-paint"
    public var aluminum: MaterialKey = "metal.boat-aluminum"
    public var motorBoard: MaterialKey = "wood.weathered"
    public init() {}

    /// Seat top height above the hull bottom.
    var seatHeight: Float { depth * 0.78 }
    var seatX: (bow: Float, stern: Float) { (length * 0.2, -length * 0.32) }

    /// Named attachment points in asset space (bow +X, waterline about y = 0.1).
    public var anchors: [String: Xform] {
        let L = length, W = beam / 2
        return [
            "motorMount": Xform(translation: V3(L / 2 - 0.02, depth + 0.02, 0)),
            "seatBow": Xform(translation: V3(seatX.bow, seatHeight + 0.01, 0)),
            "seatStern": Xform(translation: V3(seatX.stern, seatHeight + 0.01, 0)),
            "rodHolderPort": Xform(translation: V3(-L * 0.18, depth + 0.1, -W + 0.02)),
            "rodHolderStarboard": Xform(translation: V3(-L * 0.18, depth + 0.1, W - 0.02)),
            "anchorRope": Xform(translation: V3(L * 0.38, 0.05, 0.18)),
        ]
    }

    /// Bottom height, bottom half-width and gunwale half-width at station x.
    func station(_ x: Float) -> (bot: Float, wb: Float, wg: Float, top: Float) {
        let L = length, t = (x + L / 2) / L
        let rake = pow(smoothstep(0.62, 1, t), 1.5)
        let bow = smoothstep(0.8, 1, t)
        let wb = bottomWidth / 2 * (0.94 + 0.06 * sin(t * .pi)) - bow * 0.05
        let wg = beam / 2 * (0.97 + 0.03 * sin(t * .pi)) - bow * 0.1
        return (rake * bowRise, wb, wg, depth + 0.035 * t * t)
    }

    /// Half section from keel center to gunwale (z, y), port side mirrored.
    func section(_ x: Float) -> [V2] {
        let s = station(x)
        let side = { (f: Float) -> V2 in V2(s.wb + (s.wg - s.wb) * f, s.bot + 0.035 + (s.top - s.bot - 0.035) * f) }
        var pts: [V2] = [V2(0, s.bot), V2(s.wb * 0.5, s.bot), V2(s.wb - 0.03, s.bot), V2(s.wb - 0.005, s.bot + 0.012)]
        // Strake: a pressed rib 1/3 up the side.
        pts += [side(0), side(0.3), side(0.34) + V2(0.006, 0), side(0.38), side(0.7), side(1)]
        return pts
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let L = length
        func full(_ x: Float) -> [V2] { let h = section(x); return h.reversed().map { V2(-$0.x, $0.y) } + h.dropFirst() }
        func skin(_ stations: Int, material: MaterialKey) -> Surface {
            var s = Surface(material: material)
            let cols = full(0).count
            for i in 0...stations {
                let x = -L / 2 + L * Float(i) / Float(stations)
                let sec = full(x)
                var v: Float = 0
                for (k, p) in sec.enumerated() {
                    if k > 0 { v += simd_distance(p, sec[k - 1]) }
                    _ = s.add(V3(x, p.y, p.x), .up, V2(x, v))
                }
            }
            let c = UInt32(cols)
            for i in 0..<UInt32(stations) { for k in 0..<(c - 1) { s.quad(i * c + k, i * c + k + 1, (i + 1) * c + k + 1, (i + 1) * c + k) } }
            s.recomputeNormals(weldSeams: false)
            return s
        }
        var m = Model(name: Self.id)
        // Outer painted skin facing out, inner bare aluminum skin 2.5 mm inside it facing in.
        var o = skin(28, material: hullPaint)
        if let k = o.positions.indices.min(by: { o.positions[$0].y < o.positions[$1].y }), o.normals[k].y > 0 { o = o.flipped() }
        var inner = o
        inner.material = aluminum
        inner.displace { _, _ in -0.0025 }
        inner = inner.flipped()
        o.computeTangents(); inner.computeTangents()
        m.add(o); m.add(inner)
        // Transoms: stern plate with a wooden motor board, bow plate.
        for (x, dir) in [(-L / 2, Float(-1)), (L / 2, Float(1))] {
            let outline = full(x)
            let plate = Prim.extrude(outline, depth: 0.004, bevel: 0.001, bevelSegments: 1, material: aluminum)
            m.add(plate, Xform(translation: V3(x - dir * 0.002, 0, 0), rotation: simd_quatf(angle: .pi / 2, axis: .up)))
        }
        let st = station(-L / 2)
        m.add(Prim.roundedBox(V3(0.03, 0.2, st.wg * 1.1), radius: 0.006, bevelSegments: 1, material: motorBoard), Xform(translation: V3(-L / 2 + 0.02, depth - 0.11, 0)))
        // Rolled gunwale rails along both sides and across both transoms.
        let rail: (Float) -> [V3] = { side in stride(from: -L / 2, through: L / 2 + 0.001, by: L / 16).map { x in let s = station(x); return V3(x, s.top + 0.004, side * (s.wg + 0.004)) } }
        for side: Float in [-1, 1] {
            let p = rail(side)
            m.add(Prim.tube(p, radii: p.map { _ in 0.011 }, sides: 8, seamTile: 0.05, material: aluminum))
        }
        for x in [-L / 2, L / 2] {
            let s = station(x)
            m.add(Prim.tube([V3(x, s.top + 0.004, -s.wg - 0.004), V3(x, s.top + 0.004, s.wg + 0.004)], radii: [0.012, 0.012], sides: 8, seamTile: 0.05, material: aluminum))
        }
        // Floor ribs (extruded hat channels across the bottom).
        for i in 0..<6 {
            let x = -L / 2 + 0.3 + Float(i) * (L * 0.55) / 5
            let s = station(x)
            m.add(Prim.roundedBox(V3(0.05, 0.022, s.wb * 2 - 0.08), radius: 0.006, bevelSegments: 1, material: aluminum), Xform(translation: V3(x, s.bot + 0.013, 0)))
        }
        // Box bench seats with flotation boxes under them.
        for x in [seatX.bow, seatX.stern] {
            let s = station(x)
            let f = (seatHeight - s.bot) / (s.top - s.bot)
            let half = s.wb + (s.wg - s.wb) * f - 0.006
            m.add(Prim.roundedBox(V3(0.27, 0.022, half * 2), radius: 0.008, bevelSegments: 2, material: aluminum), Xform(translation: V3(x, seatHeight - 0.011, 0)))
            m.add(Prim.roundedBox(V3(0.25, seatHeight - s.bot - 0.03, half * 2 - 0.12), radius: 0.01, bevelSegments: 1, material: aluminum), Xform(translation: V3(x, (seatHeight + s.bot) / 2 - 0.012, 0)))
            rivetRow(&m, along: [V3(x - 0.12, seatHeight + 0.001, -half + 0.03), V3(x - 0.12, seatHeight + 0.001, half - 0.03)], spacing: 0.12, normal: { _ in .up }, material: aluminum)
            rivetRow(&m, along: [V3(x + 0.12, seatHeight + 0.001, -half + 0.03), V3(x + 0.12, seatHeight + 0.001, half - 0.03)], spacing: 0.12, normal: { _ in .up }, material: aluminum)
        }
        // Rivet rows along the chines and the strake.
        for side: Float in [-1, 1] {
            let chine = stride(from: -L / 2 + 0.05, through: L / 2 - 0.1, by: L / 12).map { x -> V3 in let s = station(x); return V3(x, s.bot + 0.02, side * (s.wb + 0.003)) }
            rivetRow(&m, along: chine, spacing: 0.1, normal: { _ in V3(0, -0.3, side) }, material: aluminum)
        }
        // Clamp-on rod holders on both gunwales behind the stern seat, angled out and aft.
        for side: Float in [-1, 1] {
            let a = anchors[side < 0 ? "rodHolderPort" : "rodHolderStarboard"]!.translation
            let dir = simd_normalize(V3(-0.5, 1, side * 0.45))
            let base = a - dir * 0.12
            m.add(Prim.tube([base, base + dir * 0.24], radii: [0.021, 0.024], sides: 12, seamTile: 0.05, material: "plastic.black", capEnd: false))
            m.add(Prim.roundedBox(V3(0.06, 0.07, 0.03), radius: 0.006, bevelSegments: 1, material: "plastic.black"),
                  Xform(translation: V3(a.x, depth - 0.01, side * (station(a.x).wg + 0.01))))
        }
        // Mushroom anchor on a rope coil near the bow.
        let ap = anchors["anchorRope"]!.translation
        let sb = station(ap.x).bot
        m.add(Prim.lathe([V2(0.004, 0), V2(0.1, 0.0), V2(0.105, 0.012), V2(0.06, 0.05), V2(0.016, 0.06), V2(0.016, 0.3), V2(0.03, 0.31), V2(0.03, 0.33), V2(0, 0.335)],
                         segments: 18, material: "metal.painted:2B2D2F"), Xform(translation: V3(ap.x - 0.05, sb + 0.17, ap.z), rotation: simd_quatf(degrees: 90, axis: V3(0, 0, 1)) * simd_quatf(degrees: 180, axis: V3(1, 0, 0))))
        for k in 0..<4 {
            let r = 0.11 + Float(k) * 0.012
            m.add(Prim.torus(major: r, minor: 0.006, segments: 22, sides: 6, material: "fabric.canvas:C8B98A"),
                  Xform(translation: V3(ap.x - 0.05, sb + 0.012 + Float(k) * 0.011, -ap.z + rng.float(-0.01...0.01))))
        }
        // Drain plug on the stern transom.
        m.add(Prim.cylinder(radius: 0.018, height: 0.02, bevel: 0.004, segments: 12, material: "metal.brass-aged"),
              Xform(translation: V3(-L / 2 - 0.004, st.bot + 0.05, 0.15), rotation: simd_quatf(degrees: 90, axis: V3(0, 0, 1))))
        groundAO(&m, height: 0.12)
        return LODModel(m)
    }
}
