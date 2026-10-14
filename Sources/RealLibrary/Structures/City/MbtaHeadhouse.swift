import simd
import Foundation

/// Park Street station headhouse on Boston Common (Tremont Street subway, 1897): coursed granite walls
/// on a granite podium, molded granite cornice, verdigris copper hip roof with a finial, a front stair
/// opening with granite lintel, steps going down between black iron railings into the dark stairwell,
/// and the MBTA "T" disk sign on its post. Entrance faces +Z. Centered on X/Z, base at y = 0.
public struct MbtaHeadhouse: RealAsset {
    public static let id = "mbta-headhouse"
    public static let summary = "Park Street T station headhouse on Boston Common: granite walls, verdigris copper hip roof, stair opening with railings, T sign disk."
    public static let tags = ["structure", "city", "urban", "stone", "park"]
    public static let budget = 15000
    public static let author = "hunter"
    public static let preview = PreviewHint(azimuth: 30, elevation: 10, distance: 1.1)

    /// Footprint width (x) and depth (z) of the walls (m).
    public var footprint = V2(6.0, 4.8)
    /// Wall height to the cornice (m).
    public var wallHeight: Float = 2.8
    /// Stair opening width (m).
    public var openingWidth: Float = 2.4
    public var granite: MaterialKey = "stone.granite-paver"
    public var copper: MaterialKey = "metal.verdigris-roof"
    public var iron: MaterialKey = "metal.wrought-iron"
    public var paving: MaterialKey = "concrete.sidewalk"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        typealias K = LandmarkKit
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let hx = footprint.x / 2, hz = footprint.y / 2, t: Float = 0.45, pod: Float = 0.42, H = wallHeight + pod
        let ow = openingWidth / 2, oh: Float = 2.35 + pod
        // Podium and sidewalk apron.
        m.add(Prim.roundedBox(V3(footprint.x + 0.6, pod, footprint.y + 1.6), radius: 0.03, bevelSegments: 2, material: granite),
              Xform(translation: V3(0, pod / 2, 0.5)))
        // Walls in courses: each course a slightly varied block band, the stair opening cut in the front.
        let courses = 6, ch = wallHeight / Float(courses)
        for c in 0..<courses {
            let y0 = pod + Float(c) * ch + 0.006, y1 = pod + Float(c + 1) * ch - 0.006
            let inset: Float = c == 0 ? -0.04 : rng.float(-0.012...0.0)
            func band(_ lo: V3, _ hi: V3) {
                // Split the course into ashlar blocks along its long axis, joints staggered per course.
                let alongX = hi.x - lo.x >= hi.z - lo.z
                let L = alongX ? hi.x - lo.x : hi.z - lo.z
                var cuts: [Float] = [0]
                var u: Float = c % 2 == 0 ? 1.5 : 0.8
                while u < L - 0.35 { cuts.append(u); u += rng.float(1.4...1.8) }
                cuts.append(L)
                for j in 0..<(cuts.count - 1) {
                    var a = lo, b = hi
                    if alongX { a.x = lo.x + cuts[j] + 0.005; b.x = lo.x + cuts[j + 1] - 0.005 } else { a.z = lo.z + cuts[j] + 0.005; b.z = lo.z + cuts[j + 1] - 0.005 }
                    let bulge = rng.float(-0.008...0.006)
                    let sz = b - a - V3(inset + bulge, 0, inset + bulge) * 2
                    // Chamfered ashlar block: rectangle in XY (x along the course, y up), extruded through the wall.
                    let w = alongX ? sz.x : sz.z, d = alongX ? sz.z : sz.x
                    let blk = Prim.extrude(Shape2D.rect(w, sz.y), depth: d, bevel: 0.018, bevelSegments: 1, material: granite)
                    if alongX { m.add(K.boxUV(blk, Xform(translation: (a + b) / 2))) } else { m.add(K.box(size: sz, at: (a + b) / 2, granite)) }
                }
            }
            band(V3(-hx, y0, -hz), V3(hx, y1, -hz + t))                       // back
            band(V3(-hx, y0, -hz + t + 0.004), V3(-hx + t, y1, hz))            // left
            band(V3(hx - t, y0, -hz + t + 0.004), V3(hx, y1, hz))              // right
            if y1 > oh {
                band(V3(-hx + t + 0.004, y0, hz - t), V3(hx - t - 0.004, y1, hz))
            } else {
                band(V3(-hx + t + 0.004, y0, hz - t), V3(-ow, y1, hz))
                band(V3(ow, y0, hz - t), V3(hx - t - 0.004, y1, hz))
            }
        }
        // Granite lintel over the opening, with a keystone.
        m.add(Prim.roundedBox(V3(openingWidth + 0.7, 0.42, t + 0.08), radius: 0.03, bevelSegments: 2, material: granite), Xform(translation: V3(0, oh + 0.21, hz - t / 2 + 0.04)))
        m.add(Prim.extrude([V2(-0.16, 0), V2(0.16, 0), V2(0.22, 0.5), V2(-0.22, 0.5)], depth: t + 0.14, bevel: 0.01, bevelSegments: 1, material: granite),
              Xform(translation: V3(0, oh + 0.02, hz - t / 2 + 0.06)))
        // Molded cornice.
        var cp = ArchProfile()
        cp.step(0.04); cp.fillet(0.12); cp.cymaReversa(0.08, 0.06); cp.step(0.05); cp.fillet(0.12); cp.cymaRecta(0.1, 0.12); cp.to(V2(0, cp.end.y))
        for k in 0..<4 {
            let a = Float(k) * .pi / 2, along = k % 2 == 0 ? footprint.x : footprint.y, off = k % 2 == 0 ? hz : hx
            m.add(ArchTrimKit.sweep(cp, length: along, material: granite, miterStart: true, miterEnd: true, span: 3),
                  Xform(translation: V3(sin(a) * off, H, cos(a) * off), rotation: simd_quatf(angle: a, axis: V3(0, 1, 0))))
        }
        let ctop = H + cp.maxY
        m.add(K.box(V3(-hx, H, -hz), V3(hx, ctop, hz), granite))
        // Copper hip roof with standing seams, ridge roll and finial.
        let rise: Float = 1.0, ov: Float = 0.12
        m.add(K.hipRoof(hx: hx, z0: -hz, z1: hz, y0: ctop, rise: rise, overhang: ov, mat: copper))
        let ax = hx + ov, az = hz + ov, ridge = ax - az
        for k in 0..<9 {
            let x = -ax + 0.35 + Float(k) * (2 * ax - 0.7) / 8
            for sz: Float in [-1, 1] {
                let xe = max(-ridge, min(ridge, x)), z0 = sz * az, y1 = ctop + rise
                let zt = sz * (az * (1 - min(1, max(0, abs(x) - ridge) / az)))
                if abs(x) > ridge { // hip face near the ends: seam stops at the hip line
                    let tEnd = (ax - abs(x)) / az
                    m.add(Prim.tube([V3(x, ctop + 0.02, z0), V3(x, ctop + rise * tEnd + 0.01, sz * az * (1 - tEnd))], radii: [0.018, 0.018], sides: 4, seamTile: 0.2, material: copper))
                } else {
                    m.add(Prim.tube([V3(x, ctop + 0.02, z0), V3(xe, y1 + 0.01, 0)], radii: [0.018, 0.018], sides: 4, seamTile: 0.2, material: copper))
                }
                _ = zt
            }
        }
        m.add(Prim.tube([V3(-ridge - 0.05, ctop + rise + 0.02, 0), V3(ridge + 0.05, ctop + rise + 0.02, 0)], radii: [0.05, 0.05], sides: 8, seamTile: 0.2, material: copper))
        for (cx, cz) in [(-1, -1), (1, -1), (1, 1), (-1, 1)] as [(Float, Float)] {
            m.add(Prim.tube([V3(cx * ax, ctop, cz * az), V3(cx * ridge, ctop + rise + 0.02, 0)], radii: [0.045, 0.045], sides: 6, seamTile: 0.2, material: copper))
        }
        for sx: Float in [-1, 1] {
            m.add(Prim.lathe([V2(0, 0), V2(0.09, 0), V2(0.06, 0.25), V2(0.12, 0.38), V2(0.03, 0.62), V2(0, 0.66)], segments: 10, seamTile: 0.2, material: copper),
                  Xform(translation: V3(sx * ridge, ctop + rise, 0)))
        }
        // Stairwell: three steps down to sidewalk level inside the podium and a dark descending void.
        let nSteps = 5, stepH = pod / Float(nSteps)
        for k in 0..<nSteps {
            let y1 = pod - Float(k) * stepH, zf = hz - t + 0.02 - Float(k) * 0.3
            m.add(Prim.roundedBox(V3(openingWidth - 0.1, y1, 0.32), radius: 0.012, bevelSegments: 1, material: "stone.granite-curb"),
                  Xform(translation: V3(0, y1 / 2 + 0.006, zf - 0.16)))
        }
        m.add(K.box(V3(-ow + 0.05, 0.012, -hz + t + 0.05), V3(ow - 0.05, 0.02, hz - t - 1.0), "screen.off"))
        m.add(K.box(V3(-hx + t, pod - 0.01, -hz + t), V3(-ow + 0.05, pod + 0.004, hz - t), paving))
        m.add(K.box(V3(ow - 0.05, pod - 0.01, -hz + t), V3(hx - t, pod + 0.004, hz - t), paving))
        m.add(K.box(V3(-ow + 0.05, 0.012, -hz + t + 0.004), V3(ow - 0.05, pod - 0.01, -hz + t + 0.03), "screen.off"))
        // Iron railings either side of the stair well and along the front apron.
        for sx: Float in [-1, 1] {
            let x = sx * (ow - 0.02), zA = hz + 0.4, zB = -hz + t + 0.3
            var posts: [V3] = []
            for k in 0...5 { let z = zA + (zB - zA) * Float(k) / 5; posts.append(V3(x, pod, z)) }
            for p in posts {
                m.add(Prim.cylinder(radius: 0.022, height: 1.0, bevel: 0.004, segments: 8, material: iron), Xform(translation: p))
                m.add(Prim.lathe([V2(0, 0), V2(0.045, 0), V2(0.045, 0.02), V2(0.03, 0.05), V2(0, 0.06)], segments: 8, seamTile: 0.1, material: iron), Xform(translation: p + V3(0, 1.0, 0)))
            }
            m.add(Prim.tube([V3(x, pod + 1.0, zA), V3(x, pod + 1.0, zB)], radii: [0.025, 0.025], sides: 8, seamTile: 0.2, material: iron))
            m.add(Prim.tube([V3(x, pod + 0.15, zA), V3(x, pod + 0.15, zB)], radii: [0.015, 0.015], sides: 6, seamTile: 0.2, material: iron))
            for k in 0..<16 {
                let z = zA + (zB - zA) * (Float(k) + 0.5) / 16
                m.add(Prim.cylinder(radius: 0.009, height: 0.85, bevel: 0, segments: 5, material: iron), Xform(translation: V3(x, pod + 0.15, z)))
            }
        }
        // Wall lanterns flanking the opening: iron arm, glass globe, cap.
        for sx: Float in [-1, 1] {
            let b = V3(sx * (ow + 0.55), pod + 2.1, hz)
            m.add(Prim.tube([b, b + V3(0, 0.08, 0.3), b + V3(0, 0.02, 0.42)], radii: [0.025, 0.02, 0.02], sides: 6, seamTile: 0.2, material: iron))
            m.add(Prim.lathe([V2(0, -0.32), V2(0.05, -0.32), V2(0.13, -0.2), V2(0.15, -0.05), V2(0.11, 0.02), V2(0, 0.03)], segments: 12, seamTile: 0.2, material: "glass.frosted"),
                  Xform(translation: b + V3(0, 0, 0.42)))
            m.add(Prim.lathe([V2(0, 0.02), V2(0.17, 0.02), V2(0.05, 0.16), V2(0.02, 0.22), V2(0, 0.24)], segments: 12, seamTile: 0.2, material: iron),
                  Xform(translation: b + V3(0, 0, 0.42)))
            m.add(Prim.roundedBox(V3(0.16, 0.24, 0.04), radius: 0.01, bevelSegments: 1, material: iron), Xform(translation: b + V3(0, 0.02, 0.02)))
        }
        // Copper cresting along the ridge.
        for k in 0...6 {
            let x = -ridge + Float(k) * (2 * ridge) / 6
            m.add(Prim.tube([V3(x, ctop + rise + 0.05, 0), V3(x, ctop + rise + 0.3, 0)], radii: [0.012, 0.012], sides: 4, seamTile: 0.2, material: copper))
        }
        m.add(Prim.tube([V3(-ridge, ctop + rise + 0.3, 0), V3(ridge, ctop + rise + 0.3, 0)], radii: [0.015, 0.015], sides: 4, seamTile: 0.2, material: copper))
        // MBTA "T" disk on a post at the front corner.
        let sp = V3(-hx - 0.05, pod, hz + 0.65), poleH: Float = 3.6
        m.add(Prim.cylinder(radius: 0.06, height: poleH, bevel: 0.01, segments: 12, material: iron), Xform(translation: sp))
        m.add(Prim.lathe([V2(0, 0), V2(0.13, 0), V2(0.13, 0.12), V2(0.08, 0.2), V2(0, 0.2)], segments: 12, seamTile: 0.2, material: iron), Xform(translation: sp))
        let dc = sp + V3(0, poleH - 0.1, 0), face = simd_quatf(angle: .pi / 2, axis: V3(1, 0, 0))
        m.add(Prim.cylinder(radius: 0.42, height: 0.06, bevel: 0.01, segments: 32, material: iron), Xform(translation: dc + V3(0, 0, -0.03), rotation: face))
        m.add(Prim.cylinder(radius: 0.37, height: 0.08, bevel: 0.006, segments: 32, material: "plastic.white"), Xform(translation: dc + V3(0, 0, -0.04), rotation: face))
        for sz: Float in [-1, 1] {
            m.add(Prim.roundedBox(V3(0.44, 0.11, 0.012), radius: 0.004, bevelSegments: 1, material: "plastic.black"), Xform(translation: dc + V3(0, 0.15, sz * 0.045)))
            m.add(Prim.roundedBox(V3(0.12, 0.42, 0.012), radius: 0.004, bevelSegments: 1, material: "plastic.black"), Xform(translation: dc + V3(0, -0.04, sz * 0.045)))
        }
        groundAO(&m, height: 0.6)
        K.grime(&m, seed: seed, amount: 0.5, splash: 1.0)
        return LODModel(ArchTrimKit.ground(m))
    }
}
