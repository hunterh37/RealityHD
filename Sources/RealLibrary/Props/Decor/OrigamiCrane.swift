import simd
import Foundation

/// Origami crane, 0.6 m wingspan, folded from one square sheet of washi. Every fold is a flat triangular facet by design;
/// the sheet is paper PBR (fibre normal, high roughness, translucency) with a pale reverse side. Origin at the body centre,
/// beak +Z, up +Y. Hexagonal-diamond body, two swept wings with a leading-edge crease, V-folded neck with a beak, V-folded tail.
///
/// Authored pose is the finished crane. Joints: `flap` -1...1 (both wings hinge 50 degrees about the shoulder line, positive
/// raises the tips), `fold` 0...1 (staged crease sequence: flat square, diagonal triangle, bird base, finished crane; the
/// finished parts appear at 0.7), `neck` -1...1 (neck pitch 25 degrees about the neck base, positive lowers the head).
/// All three are empty drivers; parts mimic them. 1 LOD.
public struct OrigamiCrane: RealArticulated {
    public static let id = "origami-crane"
    public static let summary = "0.6 m wingspan origami crane of washi paper with crisp folded facets, joints flap, fold, neck; fold 0 is a flat square sheet."
    public static let tags = ["prop", "decor", "paper", "articulated", "outdoor"]
    public static let budget = 3_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 22, distance: 1.1, studio: true)

    /// Outer face of the sheet (washi tint). Replace the hex to tint the crane.
    public var washi: MaterialKey = "paper.sheet:D9503F"
    /// Reverse side of the sheet, seen on the belly and wing undersides.
    public var inner: MaterialKey = "paper.sheet:F1EADB"
    public init() {}

    static let side: Float = 0.5
    static let neckBase = V3(0, 0.03, 0.09)
    static let shoulder = V3(0.03, 0.05, -0.02)

    /// Flat-shaded two-sided paper: each triangle gets its own vertices and normal, the reverse face goes to `back`.
    struct Paper {
        var front: Surface, back: Surface
        init(front: MaterialKey, back: MaterialKey) { self.front = Surface(material: front); self.back = Surface(material: back) }

        /// Fan-triangulated polygon. The front face points away from `inside` (default: a point below, so normals face up).
        mutating func facet(_ p: [V3], inside: V3? = nil) {
            guard p.count >= 3 else { return }
            for i in 1..<(p.count - 1) {
                var a = p[0], b = p[i], c = p[i + 1]
                var n = simd_cross(b - a, c - a)
                let len = simd_length(n)
                if len < 1e-9 { continue }
                n /= len
                let cen = (a + b + c) / 3
                let ref = inside ?? (cen - V3(0, 1, 0))
                if simd_dot(n, cen - ref) < 0 { swap(&b, &c); n = -n }
                let u = n.anyPerpendicular, v = simd_cross(n, u)
                func uv(_ q: V3) -> V2 { V2(simd_dot(q, u), simd_dot(q, v)) * 2.5 }
                let f0 = front.add(a, n, uv(a)), f1 = front.add(b, n, uv(b)), f2 = front.add(c, n, uv(c))
                front.tri(f0, f1, f2)
                a -= n * 0.0004; b -= n * 0.0004; c -= n * 0.0004
                let g0 = back.add(a, -n, uv(a)), g1 = back.add(b, -n, uv(b)), g2 = back.add(c, -n, uv(c))
                back.tri(g0, g2, g1)
            }
        }

        /// V-folded strip along a path: ridge on the path, edges `w` to each side and `drop` lower.
        mutating func strip(_ path: [V3], widths: [Float], drop: Float) {
            for i in 0..<(path.count - 1) {
                let p0 = path[i], p1 = path[i + 1], w0 = widths[i], w1 = widths[i + 1]
                for s: Float in [-1, 1] {
                    let e0 = p0 + V3(s * w0, -drop * (w0 > 0 ? 1 : 0), 0), e1 = p1 + V3(s * w1, -drop * (w1 > 0 ? 1 : 0), 0)
                    facet([p0, p1, e1, e0])
                }
            }
        }

        mutating func finish() -> [Surface] {
            front.computeTangents(); back.computeTangents()
            return [front, back]
        }
    }

    func wing(_ s: Float) -> Paper {
        var p = Paper(front: washi, back: inner)
        func P(_ x: Float, _ y: Float, _ z: Float) -> V3 { V3(s * x, y, z) }
        let a = P(0.03, 0.05, 0.05), b = P(0.03, 0.05, -0.10)
        let c = P(0.15, 0.072, 0.015), d = P(0.17, 0.066, -0.125)
        let t = P(0.30, 0.095, -0.15), m = P(0.12, 0.088, -0.045)
        let lead = P(0.09, 0.062, 0.035), tr = P(0.20, 0.082, -0.07)
        p.facet([a, lead, m]); p.facet([lead, c, m]); p.facet([c, tr, m]); p.facet([c, t, tr])
        p.facet([tr, t, d]); p.facet([d, m, tr]); p.facet([d, b, m]); p.facet([b, a, m])
        // Folded-over leading edge layer.
        p.facet([lead, c, P(0.15, 0.079, 0.004)]); p.facet([c, t, P(0.21, 0.092, -0.06)])
        return p
    }

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 1, switchDistances: [])
        let X = V3(1, 0, 0), Y = V3(0, 1, 0), Z = V3(0, 0, 1)
        let nb = Self.neckBase

        for (name, range, dur): (String, ClosedRange<Float>, Float) in [("flap", -1...1, 0.6), ("fold", 0...1, 4.0), ("neck", -1...1, 1.0)] {
            _ = rig.part(name, pivot: .zero, joint: .hinge(axis: Y, range, duration: dur))
        }
        _ = rig.part("shell", pivot: .zero, joint: .fixed, options: 4)
        _ = rig.part("wingL", pivot: Self.shoulder, joint: Joint(.revolute, axis: Z, range: -50...50, mimic: .init("flap", ratio: 50)), options: 2)
        _ = rig.part("wingR", pivot: V3(-Self.shoulder.x, Self.shoulder.y, Self.shoulder.z),
                     joint: Joint(.revolute, axis: Z, range: -50...50, mimic: .init("flap", ratio: -50)), options: 2)
        _ = rig.part("neckPitch", pivot: nb, joint: Joint(.revolute, axis: X, range: -25...25, mimic: .init("neck", ratio: 25)), options: 2)
        rig.optionLinks = [
            RigOptionLink(part: "shell", joint: "fold", thresholds: [0.2, 0.45, 0.7]),
            RigOptionLink(part: "wingL", joint: "fold", thresholds: [0.7]),
            RigOptionLink(part: "wingR", joint: "fold", thresholds: [0.7]),
            RigOptionLink(part: "neckPitch", joint: "fold", thresholds: [0.7]),
        ]

        func put(_ p: inout Paper, _ part: String, option: Int) {
            for s in p.finish() where !s.isEmpty { rig.add(s, to: part, option: option) }
        }

        // Stage 0: flat square sheet with a slightly raised centre so the diagonal creases read.
        var s0 = Paper(front: washi, back: inner)
        let h = Self.side / 2
        let corners = [V3(-h, 0, -h), V3(h, 0, -h), V3(h, 0, h), V3(-h, 0, h)]
        let c0 = V3(0, 0.0015, 0)
        for i in 0..<4 { s0.facet([corners[i], corners[(i + 1) % 4], c0]) }
        put(&s0, "shell", option: 0)

        // Stage 1: folded on the diagonal, a right triangle two layers thick.
        var s1 = Paper(front: washi, back: inner)
        let l = V3(-h * 1.4142, 0.004, 0), r = V3(h * 1.4142, 0.004, 0), ap = V3(0, 0.004, h * 1.4142 * 0.5 + 0.0), mid = V3(0, 0.011, 0.02)
        s1.facet([l, ap, mid]); s1.facet([ap, r, mid]); s1.facet([r, l, mid])
        put(&s1, "shell", option: 1)

        // Stage 2: bird base, a kite with a raised centre ridge and two lifted front petals.
        var s2 = Paper(front: washi, back: inner)
        let fr = V3(0, 0.03, 0.25), bk = V3(0, 0.03, -0.25), lf = V3(-0.14, 0.012, 0), rt = V3(0.14, 0.012, 0)
        let rf = V3(0, 0.045, 0.06), rb = V3(0, 0.045, -0.12)
        s2.facet([fr, rf, lf]); s2.facet([fr, rt, rf]); s2.facet([rf, rb, lf]); s2.facet([rf, rt, rb])
        s2.facet([bk, lf, rb]); s2.facet([bk, rb, rt])
        s2.facet([fr, V3(0.02, 0.10, 0.24), V3(-0.02, 0.10, 0.24)])
        s2.facet([bk, V3(0.02, 0.09, -0.24), V3(-0.02, 0.09, -0.24)])
        put(&s2, "shell", option: 2)

        // Stage 3: finished body and tail.
        var body = Paper(front: washi, back: inner)
        let o = V3.zero
        let rf3 = V3(0, 0.055, 0.08), rb3 = V3(0, 0.05, -0.10), kf = V3(0, -0.05, 0.075), kb = V3(0, -0.045, -0.10)
        for s: Float in [-1, 1] {
            let sm = V3(s * 0.052, 0.0, -0.02)
            body.facet([rf3, rb3, sm], inside: o)
            body.facet([kb, kf, sm], inside: o)
            body.facet([rf3, sm, kf], inside: o)
            body.facet([rb3, kb, sm], inside: o)
            // Lapped side crease on the body.
            body.facet([V3(s * 0.052, 0, -0.02), V3(s * 0.04, 0.025, 0.05), V3(s * 0.045, -0.02, 0.03)], inside: o)
        }
        body.strip([V3(0, 0.03, -0.09), V3(0, 0.07, -0.17), V3(0, 0.115, -0.22), V3(0, 0.13, -0.27)],
                   widths: [0.03, 0.022, 0.012, 0], drop: 0.012)
        put(&body, "shell", option: 3)

        // Wings.
        for (name, s) in [("wingL", Float(1)), ("wingR", Float(-1))] {
            var w = wing(s)
            put(&w, name, option: 1)
        }

        // Neck and head with beak.
        var neck = Paper(front: washi, back: inner)
        neck.strip([nb, V3(0, 0.09, 0.14), V3(0, 0.15, 0.18), V3(0, 0.185, 0.215), V3(0, 0.165, 0.255)],
                   widths: [0.026, 0.020, 0.015, 0.011, 0], drop: 0.012)
        neck.facet([V3(0, 0.185, 0.215), V3(0.011, 0.173, 0.215), V3(0, 0.165, 0.255)])
        neck.facet([V3(0, 0.185, 0.215), V3(0, 0.165, 0.255), V3(-0.011, 0.173, 0.215)])
        put(&neck, "neckPitch", option: 1)

        rig.defaultState = "crane"
        rig.states = [
            RigState("crane", ["fold": 1]),
            RigState("flat", ["fold": 0]),
            RigState("diagonal", ["fold": 0.3]),
            RigState("bird-base", ["fold": 0.55]),
            RigState("wings-up", ["fold": 1, "flap": 1]),
            RigState("wings-down", ["fold": 1, "flap": -1]),
            RigState("head-down", ["fold": 1, "neck": 1]),
            RigState("head-up", ["fold": 1, "neck": -1]),
            RigState("glide", ["fold": 1, "flap": 0.2, "neck": -0.3]),
        ]
        return rig
    }
}
