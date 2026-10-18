import simd
import Foundation

/// 300 mm silicon wafer: polished prime wafer, 775 um thick, notch and laser ID, selectable process state.
public struct Wafer300mm: RealAsset {
    public static let id = "wafer-300mm"
    public static let summary = "300 mm silicon wafer with notch, selectable process state."
    public static let tags = ["prop", "semiconductor", "handheld"]
    public static let budget = 2000
    public static let author = "realityhd"

    /// Wafer diameter in meters.
    public var diameter: Float = 0.3
    /// Wafer thickness in meters (SEMI 775 um).
    public var thickness: Float = 0.000775
    /// Process state: bare, oxide, patterned or metal.
    public var state = "patterned"
    /// Die pitch in meters for the patterned state (26 x 33 mm field).
    public var dieSize = V2(0.026, 0.033)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let mat: String
        switch state {
        case "oxide": mat = "silicon.thinfilm-oxide"
        case "patterned": mat = "silicon.thinfilm"
        case "metal": mat = "silicon.thinfilm-metal"
        default: mat = "silicon.thinfilm"
        }
        let r = diameter / 2
        // Outline with a V notch (3 mm deep, enlarged for visibility) at +Z after the flat rotation.
        var pts: [V2] = []
        let n = 96
        let notchA: Float = 0.04
        for i in 0..<n {
            let a = Float(i) / Float(n) * 2 * .pi
            let d = a - 1.5 * .pi
            if abs(atan2(sin(d), cos(d))) < notchA { continue }
            pts.append(V2(cos(a) * r, sin(a) * r))
        }
        let ia = pts.firstIndex { $0.y < -r * 0.99 } ?? 0
        pts.insert(V2(0, -r + 0.006), at: min(ia + 1, pts.count))
        let disc = Prim.extrude(Shape2D.deduped(pts), depth: thickness, bevel: 0.0004, bevelSegments: 1, material: "silicon.thinfilm")
        let flat = simd_quatf(degrees: -90, axis: V3(1, 0, 0))
        m.add(disc, Xform(translation: V3(0, thickness / 2, 0), rotation: flat))
        let top = thickness + 0.00001
        // Bare-silicon exclusion ring (3 mm) with bevel highlight, notch gap left open.
        var ring = Surface(material: "silicon.bare")
        let r0 = r - 0.0032, r1 = r - 0.0002
        let seg = 120
        for k in 0..<seg {
            let a0 = Float(k) / Float(seg) * 2 * .pi, a1 = Float(k + 1) / Float(seg) * 2 * .pi
            let am = (a0 + a1) / 2
            if abs(atan2(sin(am - 0.5 * .pi), cos(am - 0.5 * .pi))) < 0.07 { continue }
            let up = V3(0, 1, 0)
            let p0 = ring.add(V3(cos(a0) * r0, top, sin(a0) * r0), up, V2(a0, 0)), p1 = ring.add(V3(cos(a0) * r1, top, sin(a0) * r1), up, V2(a0, 1))
            let p2 = ring.add(V3(cos(a1) * r1, top, sin(a1) * r1), up, V2(a1, 1)), p3 = ring.add(V3(cos(a1) * r0, top, sin(a1) * r0), up, V2(a1, 0))
            ring.quad(p0, p3, p2, p1)
        }
        ring.computeTangents()
        m.add(ring, Xform(translation: .zero))
        // Laser ID: two rows of dot-matrix marks beside the notch, plus faint handling marks, as flat quads.
        var rr = rng
        var marks = Surface(material: "silicon.mark")
        func mq(_ cx: Float, _ cz: Float, _ hx: Float, _ hz: Float, _ ang: Float) {
            let c = cos(ang), s = sin(ang), y = top + 0.00001, nn = V3(0, 1, 0)
            func pt(_ u: Float, _ v: Float) -> V3 { V3(cx + u * c - v * s, y, cz + u * s + v * c) }
            let q = [pt(-hx, hz), pt(hx, hz), pt(hx, -hz), pt(-hx, -hz)].map { marks.add($0, nn, V2($0.x, $0.z)) }
            marks.quad(q[0], q[1], q[2], q[3])
        }
        for row in 0..<2 {
            for c in 0..<12 {
                if rr.float() < 0.2 { continue }
                mq(0.006 + Float(c) * 0.0022, r - 0.0105 - Float(row) * 0.0028, 0.0009, 0.001, 0)
            }
        }
        for _ in 0..<7 {
            let a = rr.float() * 2 * .pi, rad = 0.04 + rr.float() * 0.1
            mq(cos(a) * rad, sin(a) * rad, 0.008 + rr.float() * 0.02, 0.00025, a + .pi / 2 + (rr.float() - 0.5) * 0.4)
        }
        marks.computeTangents()
        m.add(marks, Xform(translation: .zero))
        if state == "patterned" {
            // Reticle fields of 2 x 2 dies; each die takes one of four interference tints.
            var groups = (0..<4).map { Surface(material: "silicon.die-" + ["a", "b", "c", "d"][$0]) }
            var scribe = Surface(material: "silicon.thinfilm")
            let gap: Float = 0.0006
            let cols = Int((diameter - 0.012) / dieSize.x), rows = Int((diameter - 0.012) / dieSize.y)
            for i in 0..<cols {
                for j in 0..<rows {
                    let x = (Float(i) - Float(cols - 1) / 2) * dieSize.x
                    let z = (Float(j) - Float(rows - 1) / 2) * dieSize.y
                    if simd_length(V2(abs(x) + dieSize.x / 2, abs(z) + dieSize.y / 2)) > r - 0.0042 { continue }
                    let rad = simd_length(V2(x, z)) / r
                    let g = min(3, Int(rad * 3.2) + ((i / 2 + j / 2) % 2 == 0 ? 0 : 0))
                    // Wider lane at reticle field borders.
                    let gl: Float = (i % 2 == 0 ? gap * 2 : gap), gr: Float = (i % 2 == 1 ? gap * 2 : gap)
                    let gt: Float = (j % 2 == 0 ? gap * 2 : gap), gb: Float = (j % 2 == 1 ? gap * 2 : gap)
                    let x0 = x - dieSize.x / 2 + gl / 2 + 0.0004, x1 = x + dieSize.x / 2 - gr / 2 - 0.0004
                    let z0 = z - dieSize.y / 2 + gt / 2 + 0.0004, z1 = z + dieSize.y / 2 - gb / 2 - 0.0004
                    let y = thickness + 0.00002
                    let nrm = V3(0, 1, 0)
                    // Die body split into array core and a darker-tinted periphery strip.
                    let split = z0 + (z1 - z0) * 0.22
                    for (za, zb, gi) in [(z0, split, (g + 1) % 4), (split, z1, g)] {
                        let i0 = groups[gi].add(V3(x0, y, zb), nrm, V2(x0, zb)), i1 = groups[gi].add(V3(x1, y, zb), nrm, V2(x1, zb))
                        let i2 = groups[gi].add(V3(x1, y, za), nrm, V2(x1, za)), i3 = groups[gi].add(V3(x0, y, za), nrm, V2(x0, za))
                        groups[gi].quad(i0, i1, i2, i3)
                    }
                    _ = scribe
                }
            }
            for k in 0..<4 { groups[k].computeTangents(); m.add(groups[k], Xform(translation: .zero)) }
        }
        _ = rng.float()
        return LODModel(m)
    }
}
