import simd
import Foundation

/// Canyon wall for flight courses, seeded. `face`: one continuous sandstone cliff lofted along a polyline
/// (x, z): every cross-section is a front cliff profile, a caprock top and a rougher back, displaced by
/// layered noise, warped strata ledges with undercut soft beds, an overhanging caprock lip and vertical
/// gullies; the ends taper into buttresses and the foot flares into a scree apron. `pillar`: the same
/// section swept around a circle of the given radius. Talus of `debris-rock` blocks lies at the foot.
public struct CanyonWall: RealAsset {
    public static let id = "canyon-wall"
    public static let summary = "Canyon wall, seeded: one lofted sandstone cliff along a polyline (or a pillar) with strata ledges, caprock overhang, gullies and debris-rock talus."
    public static let tags = ["prop", "aerospace", "outdoor", "rock", "desert", "stone"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 12, distance: 1.0)

    public enum Kind: Sendable { case face, pillar }
    public var kind: Kind = .face
    /// Face: polyline in the XZ plane (meters); the cliff face looks toward the left normal (+Z for +X runs).
    public var polyline: [V2] = [V2(-20, -1.2), V2(0, 1.3), V2(20, -1.2)]
    /// Height in meters (face or pillar).
    public var height: Float = 18
    /// Pillar radius in meters.
    public var radius: Float = 12
    /// Wall thickness as a fraction of the height (face).
    public var depthRatio: Float = 0.45
    public var material: MaterialKey = "rock.sandstone:B47A55"
    /// Soft, recessed beds.
    public var softMaterial: MaterialKey = "rock.redstone"
    /// Talus blocks at the foot.
    public var talus = 7
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        let l0 = level(seed: seed, du: 1.6, rows: 76, talusDetail: [9])
        let l1 = level(seed: seed, du: 2.2, rows: 20, talusDetail: [5])
        return LODModel(levels: [l0, l1], switchDistances: [height * 8])
    }

    /// Path samples (point, left normal, arc length) and whether the path is closed.
    func path(du duMin: Float) -> ([(V2, V2, Float)], Bool) {
        // keep about 26 sections at LOD0 so course-length walls stay in budget
        let length = kind == .pillar ? 2 * .pi * radius
            : zip(polyline, polyline.dropFirst()).reduce(Float(0)) { $0 + simd_length($1.1 - $1.0) }
        let du = max(duMin, length / (length > 60 ? 23 : 26) * (duMin / 1.6))
        var pts: [V2]
        let closed = kind == .pillar
        if closed {
            let n = max(24, Int(2 * .pi * radius / du))
            pts = (0..<n).map { k in let a = Float(k) / Float(n) * 2 * .pi; return V2(cos(a), sin(a)) * radius }
        } else {
            pts = []
            for i in 0..<(polyline.count - 1) {
                let a = polyline[i], b = polyline[i + 1], len = simd_length(b - a)
                let n = max(1, Int(len / du))
                for k in 0..<n { pts.append(a + (b - a) * (Float(k) / Float(n))) }
            }
            pts.append(polyline.last!)
            // round the corners a little so the normals turn smoothly
            pts = pts.indices.map { i in i == 0 || i == pts.count - 1 ? pts[i] : (pts[i - 1] + pts[i] * 2 + pts[i + 1]) / 4 }
        }
        var out: [(V2, V2, Float)] = []
        var s: Float = 0
        for i in pts.indices {
            if i > 0 { s += simd_length(pts[i] - pts[i - 1]) }
            let prev = pts[closed ? (i - 1 + pts.count) % pts.count : max(0, i - 1)]
            let next = pts[closed ? (i + 1) % pts.count : min(pts.count - 1, i + 1)]
            let t = simd_normalize(next - prev)
            // pillar: face looks outward; face: left of travel
            let n = closed ? simd_normalize(pts[i]) : V2(-t.y, t.x)
            out.append((pts[i], n, s))
        }
        return (out, closed)
    }

    func level(seed: UInt64, du: Float, rows: Int, talusDetail: [Int]) -> Model {
        var rng = SeededRNG(seed: seed &+ 0xCA9)
        let ns = UInt32(truncatingIfNeeded: seed &* 0x9E37_79B9)
        let H = height
        let (samples, closed) = path(du: du)
        let total = samples.last!.2
        let depth = kind == .pillar ? radius * 0.85 : H * depthRatio
        let bed = max(0.7, H * 0.06), phase = rng.float(0...1)
        let capY = H * rng.float(0.84...0.9)

        /// Outward offset of the cliff face at arc length s and height y (meters, + = toward the viewer side).
        func relief(_ s: Float, _ y: Float, back: Bool) -> Float {
            let p = V3(s, y, back ? 37 : 0)
            var o = Noise.fbm(p * (1 / (H * 0.5)), octaves: 4, seed: ns) * H * 0.12       // big buttresses and bays
            o += Noise.ridged(p * (1 / (H * 0.12)), octaves: 3, seed: ns &+ 1) * H * 0.035 // fracture relief
            // vertical gullies
            let g = 0.5 + 0.5 * Noise.perlin(V3(s / (H * 0.3), y / (H * 2), back ? 5 : 1), seed: ns &+ 2)
            o -= smoothstep(0.58, 0.8, g) * H * 0.22
            // joint cracks: narrow vertical slots
            let j = abs(Noise.perlin(V3(s / (H * 0.09), 0.5, back ? 7 : 3), seed: ns &+ 9))
            o -= (1 - smoothstep(0.0, 0.06, j)) * H * 0.04
            // strata: warped bed lines, hard beds stand proud, soft beds undercut
            let b = y / bed + phase + 0.6 * Noise.fbm(V3(s / (H * 0.6), 0, back ? 3 : 0), octaves: 2, seed: ns &+ 3)
            let i = b.rounded(.down), t = b - i
            let hard = 0.5 + 0.5 * Noise.perlin(V3(i * 0.618 + 0.31, 0.27, 0.73), seed: ns &+ 4)
            o += (hard - 0.5) * H * 0.06 - smoothstep(0.84, 0.95, t) * H * 0.04
            // caprock: overhanging lip, slope recess just under it
            if y > capY - H * 0.05 { o += H * 0.03 * smoothstep(capY - H * 0.05, capY, y) }
            o -= H * 0.02 * smoothstep(capY - H * 0.2, capY - H * 0.06, y) * (1 - smoothstep(capY - H * 0.06, capY - H * 0.04, y))
            // foot: scree apron flares out
            o += H * 0.05 * pow(max(0, 1 - y / (H * 0.1)), 2)
            return o
        }

        // section around the ring: front bottom -> front top -> cap -> back top -> back bottom
        var s = Surface(material: material)
        var ringCount = 0
        for (k, smp) in samples.enumerated() {
            let (p, n, arc) = smp
            // buttress taper at open ends
            let endT = closed ? 1 : min(smoothstep(0, H * 0.3, arc), smoothstep(0, H * 0.3, total - arc))
            let half = depth / 2 * (0.25 + 0.75 * endT)
            let topH = H * (0.7 + 0.3 * endT) * (0.92 + 0.12 * Noise.fbm(V3(arc / (H * 0.8), 0, 9), octaves: 3, seed: ns &+ 6))
            var ring: [(Float, Float)] = []  // (offset along n, y)
            for r in 0...rows {
                let y = topH * Float(r) / Float(rows)
                ring.append((half + relief(arc, y, back: false) * (0.35 + 0.65 * endT), y))
            }
            for c in 1..<6 {
                let t = Float(c) / 6
                ring.append((half * (1 - 2 * t) + Noise.fbm(V3(arc / 6, t * 3, 4), octaves: 2, seed: ns &+ 7) * 0.4,
                             topH + 0.15 * sin(t * .pi) + Noise.fbm(V3(arc / 4, t * 2, 2), octaves: 3, seed: ns &+ 8) * H * 0.035))
            }
            if closed {
                ring.append((-half + 0.2, topH * 0.98)); ring.append((-half + 0.2, 0))
            } else {
                for r in stride(from: rows, through: 0, by: -1) {
                    let y = topH * Float(r) / Float(rows)
                    ring.append((-(half + relief(arc, y, back: true) * 0.7 * (0.35 + 0.65 * endT)), y))
                }
            }
            ringCount = ring.count
            var v: Float = 0
            for (j, q) in ring.enumerated() {
                if j > 0 { v += hypot(q.0 - ring[j - 1].0, q.1 - ring[j - 1].1) }
                let pos = V3(p.x + n.x * q.0, max(0, q.1), p.y + n.y * q.0)
                _ = s.add(pos, V3(0, 1, 0), V2(arc, v))
            }
            if k > 0 {
                let a0 = UInt32((k - 1) * ringCount), a1 = UInt32(k * ringCount)
                for j in 0..<(ringCount - 1) {
                    let i0 = a0 + UInt32(j), i1 = a1 + UInt32(j)
                    s.quad(i0, i0 + 1, i1 + 1, i1)
                }
                // close the ring bottom (back bottom to front bottom) is on the ground: skip
            }
        }
        if closed {
            let last = UInt32((samples.count - 1) * ringCount)
            for j in 0..<(ringCount - 1) { let i0 = last + UInt32(j), i1 = UInt32(j); s.quad(i0, i0 + 1, i1 + 1, i1) }
        }
        let quadIndexCount = s.indices.count
        // end caps for open faces: fan over the (tapered) end sections
        if !closed {
            for (k, flip) in [(0, true), (samples.count - 1, false)] {
                let base = UInt32(k * ringCount)
                let c = s.positions[Int(base)..<Int(base) + ringCount].reduce(V3.zero, +) / Float(ringCount)
                let ci = s.add(c, V3(0, 1, 0), V2(0, 0))
                for j in 0..<(ringCount - 1) {
                    if flip { s.tri(ci, base + UInt32(j + 1), base + UInt32(j)) } else { s.tri(ci, base + UInt32(j), base + UInt32(j + 1)) }
                }
            }
        }
        // orientation check: front faces must point along +n at mid height
        s.recomputeNormals()
        let mid = (samples.count / 2) * ringCount + rows / 2
        let nn = samples[samples.count / 2].1
        if simd_dot(s.normals[mid], V3(nn.x, 0, nn.y)) < 0 { s = s.flipped() }
        s.computeTangents()
        s.bakeCavityAO()
        // soft beds take a darker, redder sandstone so color and ledges agree
        func bedIndex(_ arc: Float, _ y: Float) -> Float {
            (y / bed + phase + 0.6 * Noise.fbm(V3(arc / (H * 0.6), 0, 0), octaves: 2, seed: ns &+ 3)).rounded(.down)
        }
        var hardIdx: [UInt32] = [], softIdx: [UInt32] = []
        var t = 0
        while t < s.indices.count {
            // ring quads are two triangles: classify both by the quad centroid so bed edges stay straight
            let n = t < quadIndexCount ? 6 : 3
            let ids = Array(s.indices[t..<min(s.indices.count, t + n)])
            let y = ids.reduce(Float(0)) { $0 + s.positions[Int($1)].y } / Float(ids.count)
            let arc = ids.reduce(Float(0)) { $0 + s.uvs[Int($1)].x } / Float(ids.count)
            let i = bedIndex(arc, y)
            let hard = 0.5 + 0.5 * Noise.perlin(V3(i * 0.618 + 0.31, 0.27, 0.73), seed: ns &+ 4)
            if hard < 0.45 && y < capY - 0.5 { softIdx += ids } else { hardIdx += ids }
            t += n
        }
        var soft = s
        soft.material = softMaterial; soft.indices = softIdx
        s.indices = hardIdx
        var m = Model(name: Self.id)
        m.add(s, .identity)
        if !softIdx.isEmpty { m.add(soft, .identity) }

        // talus: debris-rock blocks at the foot of the face
        for t in 0..<talus {
            let smp = samples[rng.int(0...(samples.count - 1))]
            let (p, n, arc) = smp
            let out = depth / 2 + relief(arc, 0.3, back: false) + rng.float(0.5...2.5)
            var rock = DebrisRock()
            rock.radius = 2; rock.detail = talusDetail + talusDetail + talusDetail
            let lvl = rock.build(seed: seed &+ UInt64(700 + t)).levels[0]
            let sc = rng.float(0.6...1.2) * min(1, H / 18)
            for var surf in lvl.surfaces {
                surf.material = material
                m.add(surf, Xform(translation: V3(p.x + n.x * out, 0, p.y + n.y * out),
                                   rotation: simd_quatf(angle: rng.float(0...6), axis: V3(0, 1, 0)), scale: V3(repeating: sc)))
            }
        }
        groundAO(&m, height: 1.2)
        return m
    }
}
