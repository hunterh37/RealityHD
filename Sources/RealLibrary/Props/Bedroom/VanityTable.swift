import simd
import Foundation

/// Vanity (dressing table), 100 x 140 x 45 cm: mahogany top with a rounded edge at 75 cm, three apron drawers with
/// brass knobs, four turned tapered legs with collars, two upright posts with brass pivot knobs carrying an arched
/// swivel mirror (framed, silvered glass) and a perfume bottle and trinket tray on the top. Front faces +Z.
public struct VanityTable: RealAsset {
    public static let id = "vanity-table"
    public static let summary = "Mahogany dressing table with three apron drawers, turned legs and an arched swivel mirror on posts, with a perfume bottle and trinket tray."
    public static let tags = ["prop", "floorplan", "bedroom", "furniture", "wood", "glass", "interior"]
    public static let budget = 7500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 12, distance: 1.2, studio: true)

    /// Overall size in meters (x width, y height, z depth), knobs included.
    public var size = V3(1.0, 1.4, 0.45)
    /// Table and mirror frame wood.
    public var wood: MaterialKey = "wood.mahogany"
    /// Knobs and pivots.
    public var brass: MaterialKey = "metal.brass-aged"
    /// Mirror glass.
    public var mirror: MaterialKey = "metal.chrome"
    /// Top surface height in meters.
    public var topHeight: Float = 0.75
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [model(seed: seed, detail: true), model(seed: seed, detail: false)], switchDistances: [4])
    }

    func model(seed: UInt64, detail: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = size.x, H = size.y
        let knobProj: Float = 0.028
        let D = size.z - knobProj                 // table depth before knobs
        let topT: Float = 0.032, ty = topHeight
        let zShift: Float = -knobProj / 2
        func z(_ v: Float) -> Float { v + zShift }
        // Top with a rounded edge.
        m.add(Prim.roundedBox(V3(W, topT, D), radius: 0.008, bevelSegments: 2, material: wood), Xform(translation: V3(0, ty - topT / 2, z(0))))
        // Apron rails and drawer recess.
        let apronH: Float = 0.12, aY = ty - topT - apronH / 2
        let lx = W / 2 - 0.045, lz = D / 2 - 0.045
        m.add(Prim.roundedBox(V3(W - 0.1, apronH, 0.02), radius: 0.003, bevelSegments: 1, material: wood), Xform(translation: V3(0, aY, z(-lz))))
        for s: Float in [-1, 1] {
            m.add(Prim.roundedBox(V3(0.02, apronH, D - 0.1), radius: 0.003, bevelSegments: 1, material: wood), Xform(translation: V3(s * lx, aY, z(0))))
        }
        m.add(cuboid(V3(W - 0.1, apronH - 0.01, 0.03), material: wood), Xform(translation: V3(0, aY, z(lz - 0.03))))
        // End stiles beside the drawer row.
        let rowW: Float = 0.2 + 0.4 + 0.2 + 0.016
        let stileW = (W - 0.1 - rowW) / 2
        for s in [Float(-1), 1] {
            m.add(Prim.roundedBox(V3(stileW + 0.02, apronH - 0.012, 0.018), radius: 0.003, bevelSegments: 1, material: wood),
                  Xform(translation: V3(s * (rowW / 2 + stileW / 2 - 0.01), aY, z(D / 2 - 0.009))))
        }
        // Three drawers on the front apron.
        let fw = [0.2, 0.4, 0.2] as [Float], gap: Float = 0.004
        let total = fw.reduce(0, +) + gap * 4
        var x0 = -total / 2 + gap
        for w in fw {
            let cx = x0 + w / 2
            let fz = z(D / 2 - 0.009)
            m.add(Prim.roundedBox(V3(w, apronH - 0.012, 0.018), radius: 0.003, bevelSegments: 1, material: wood), Xform(translation: V3(cx, aY, fz + rng.float(-0.0005...0.0005))))
            if detail {
                let loop = Shape2D.roundedRect(w - 0.03, apronH - 0.04, radius: 0.004, segments: 2).map { V3(cx + $0.x, aY + $0.y, fz + 0.0095) }
                m.add(Prim.sweep(Shape2D.circle(0.0016, segments: 4), along: loop, closedPath: true, caps: false, material: wood))
            }
            m.add(CaseworkKit.knob(radius: 0.015, material: brass), Xform(translation: V3(cx, aY, fz + 0.009), rotation: facing(V3(0, 0, 1))))
            x0 += w + gap
        }
        // Turned tapered legs with collars.
        let legH = ty - topT
        for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
            let prof: [(Float, Float)] = [(0, 0), (0.014, 0), (0.016, 0.012), (0.019, 0.05), (0.022, legH * 0.4), (0.026, legH * 0.62), (0.033, legH * 0.68), (0.026, legH * 0.72), (0.03, legH - 0.12), (0.034, legH - 0.11), (0.03, legH - 0.1), (0.032, legH), (0, legH)]
            m.add(turned(prof, segments: detail ? 16 : 10, material: wood, grainVertical: true), Xform(translation: V3(sx * lx, 0, z(sz * lz))))
        }}
        // Posts with pivot knobs, arched mirror between them.
        let mirrorZ = z(-D / 2 + 0.07)
        let mw: Float = 0.62, mTop = H, mBot: Float = 0.9
        let postX = mw / 2 + 0.045
        for s: Float in [-1, 1] {
            m.add(Prim.roundedBox(V3(0.04, 0.5, 0.04), radius: 0.005, bevelSegments: 1, material: wood), Xform(translation: V3(s * postX, ty + 0.25, mirrorZ)))
            m.add(Prim.lathe([V2(0, 0), V2(0.02, 0), V2(0.02, 0.004), V2(0.012, 0.012), V2(0, 0.014)], segments: 14, seamTile: 0.05, material: brass),
                  Xform(translation: V3(s * (postX - 0.02), ty + 0.3, mirrorZ), rotation: facing(V3(-s, 0, 0))))
            m.add(Prim.lathe([V2(0, 0), V2(0.012, 0), V2(0.009, 0.012), V2(0.014, 0.02), V2(0, 0.022)], segments: 10, seamTile: 0.05, material: brass),
                  Xform(translation: V3(s * (postX + 0.02), ty + 0.3, mirrorZ), rotation: facing(V3(s, 0, 0))))
            // Post finial.
            m.add(turned([(0, 0), (0.012, 0), (0.015, 0.012), (0.01, 0.028), (0, 0.036)], segments: 10, material: wood, grainVertical: true), Xform(translation: V3(s * postX, ty + 0.5, mirrorZ)))
        }
        // Arched mirror frame outline (x width, y height from the bottom), centered on x.
        func arch(_ w: Float, _ h: Float, rise: Float) -> [V2] {
            var pts: [V2] = [V2(-w / 2, 0), V2(w / 2, 0), V2(w / 2, h - rise)]
            for k in 1..<14 { let a = Float.pi * Float(k) / 14; pts.append(V2(cos(a) * w / 2, h - rise + sin(a) * rise)) }
            pts.append(V2(-w / 2, h - rise))
            return pts
        }
        let mh = mTop - mBot
        let outer = Shape2D.rounded(arch(mw, mh, rise: 0.14), radius: 0.01, segments: 2)
        let inner = Shape2D.rounded(arch(mw - 0.07, mh - 0.07, rise: 0.12), radius: 0.008, segments: 2).map { $0 + V2(0, 0.035) }
        m.add(Prim.extrude(outer, depth: 0.028, bevel: 0.006, bevelSegments: 2, material: wood), Xform(translation: V3(0, mBot, mirrorZ)))
        m.add(Prim.extrude(inner, depth: 0.004, bevel: 0.0008, bevelSegments: 1, material: mirror), Xform(translation: V3(0, mBot, mirrorZ + 0.0145)))
        // Perfume bottle and trinket tray on the top.
        let tz = z(D / 2 - 0.1)
        m.add(Prim.lathe([V2(0, 0), V2(0.032, 0), V2(0.034, 0.004), V2(0.034, 0.075), V2(0.02, 0.09), V2(0.009, 0.095), V2(0.009, 0.108), V2(0, 0.108)], segments: detail ? 16 : 8, seamTile: 0.1, material: "glass.tinted"),
              Xform(translation: V3(-0.32, ty, tz)))
        m.add(Prim.lathe([V2(0, 0), V2(0.014, 0), V2(0.014, 0.03), V2(0, 0.032)], segments: 10, seamTile: 0.05, material: brass), Xform(translation: V3(-0.32, ty + 0.108, tz)))
        m.add(Prim.roundedBox(V3(0.2, 0.014, 0.13), radius: 0.005, bevelSegments: 1, material: "wood.walnut"), Xform(translation: V3(0.3, ty + 0.007, tz), rotation: simd_quatf(degrees: 8, axis: .up)))
        if detail {
            m.add(Prim.torus(major: 0.018, minor: 0.0025, segments: 14, sides: 5, material: brass), Xform(translation: V3(0.27, ty + 0.0165, tz - 0.01)))
            m.add(Prim.torus(major: 0.012, minor: 0.002, segments: 12, sides: 5, material: brass), Xform(translation: V3(0.33, ty + 0.016, tz + 0.015)))
        }
        groundAO(&m, height: 0.2, floor: 0.55)
        return m
    }
}
