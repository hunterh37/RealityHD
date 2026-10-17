import simd
import Foundation

/// Shared detailing for the camera props (CanonR50, SonyA7IV, FujiX100VI): worn-edge chips that follow the
/// rounded edges of a box, grease smudges, a coated lens glass stack with inner element rings, an LCD glass
/// surround with a raised bezel lip, and a soft contact shadow. Everything returns (Surface, Xform) pairs or
/// surfaces for the caller to place, so each prop keeps its own part names and states.
enum CameraKit {
    /// Dull bare magnesium alloy showing through worn paint.
    static let chipMaterial: MaterialKey = "metal.magnesium-worn"
    /// Near-black coated glass.
    static let glass: MaterialKey = "glass.lens-coated"

    // MARK: wear

    /// One box edge to wear. `axis` is the edge direction (0 x, 1 y, 2 z); `sa`/`sb` (+1 or -1) pick the two
    /// faces that meet there, on the other two axes in ascending order.
    struct Edge {
        var axis: Int, sa: Float, sb: Float, density: Float
        init(_ axis: Int, _ sa: Float, _ sb: Float, density: Float = 1) { self.axis = axis; self.sa = sa; self.sb = sb; self.density = density }
    }

    /// Irregular rounded chip outline: 7 to 8 jittered points around an ellipse, corners filleted.
    static func chipOutline(_ rng: inout SeededRNG, length: Float, width: Float) -> [V2] {
        let n = rng.int(7...8), phase = rng.float(0...(2 * .pi))
        var pts: [V2] = []
        for i in 0..<n {
            let a = phase + 2 * Float.pi * Float(i) / Float(n)
            let j = rng.float(0.62...1.12)
            pts.append(V2(cos(a) * length / 2 * j, sin(a) * width / 2 * j))
        }
        return Shape2D.rounded(pts, radius: min(length, width) * 0.28, segments: 1)
    }

    /// Chips of bare metal on the rounded edges of a rounded box. Chips cluster along each edge, vary in size
    /// and sit on the bevel arc at varying depth, so they read as paint knocked off a corner.
    static func boxWear(_ rng: inout SeededRNG, center c: V3, size s: V3, radius r: Float, edges: [Edge],
                        perMeter: Float = 120, length: ClosedRange<Float> = 0.0011...0.0040,
                        material: MaterialKey = chipMaterial) -> [(Surface, Xform)] {
        var out: [(Surface, Xform)] = []
        for e in edges {
            let others = [0, 1, 2].filter { $0 != e.axis }
            var nA = V3(0, 0, 0), nB = V3(0, 0, 0), dir = V3(0, 0, 0)
            nA[others[0]] = e.sa; nB[others[1]] = e.sb; dir[e.axis] = 1
            let edgePt = c + nA * (s[others[0]] / 2) + nB * (s[others[1]] / 2)
            let arcC = edgePt - (nA + nB) * r
            let len = s[e.axis] - 2 * r
            guard len > 0.002 else { continue }
            let count = max(1, Int(len * perMeter * e.density))
            let clusters = (0..<max(1, count / 4)).map { _ in rng.float(-0.45...0.45) }
            for _ in 0..<count {
                var t = rng.chance(0.3) ? rng.float(-0.5...0.5) : rng.pick(clusters) + rng.float(-0.08...0.08)
                t = min(0.5, max(-0.5, t))
                let th = rng.float(0.26...0.74) * (.pi / 2)
                let n = nA * cos(th) + nB * sin(th)
                let p = arcC + dir * (t * len) + n * (r + 0.00004)
                let l = rng.float(length), w = min(0.0016, l * rng.float(0.35...0.85))
                let jit = rng.float(-0.45...0.45)
                let ex = dir * cos(jit) + simd_cross(n, dir) * sin(jit)
                let ey = simd_cross(n, ex)
                let q = simd_quatf(simd_float3x3(columns: (ex, ey, n)))
                let surf = Prim.extrude(chipOutline(&rng, length: l, width: w), depth: 0.0004, bevel: 0, bevelSegments: 1, material: material)
                out.append((surf, Xform(translation: p, rotation: q)))
            }
        }
        return out
    }

    /// Flat grease/finger smudges: very thin ovals lying on a plane, for a sheen change on a plate.
    static func smudges(_ rng: inout SeededRNG, center c: V3, normal n: V3, along u: V3, extent: V2, count: Int,
                        material: MaterialKey, size: ClosedRange<Float> = 0.0040...0.0110) -> [(Surface, Xform)] {
        let v = simd_cross(n, u)
        var out: [(Surface, Xform)] = []
        for _ in 0..<count {
            let a = rng.float(size), b = a * rng.float(0.35...0.7)
            let p = c + u * rng.float(-extent.x / 2...extent.x / 2) + v * rng.float(-extent.y / 2...extent.y / 2) + n * 0.00006
            let yaw = rng.float(-0.8...0.8)
            let ex = u * cos(yaw) + v * sin(yaw)
            let q = simd_quatf(simd_float3x3(columns: (ex, simd_cross(n, ex), n)))
            out.append((Prim.extrude(Shape2D.circle(a / 2, ry: b / 2, segments: 10), depth: 0.00012, bevel: 0, bevelSegments: 1, material: material), Xform(translation: p, rotation: q)))
        }
        return out
    }

    // MARK: lens glass

    /// Front lens stack in lens-local space (axis +Y, front at +Y; place with the lens transform). Stepped inner
    /// barrel with a metal ledge ring, a recessed coated front element (violet rim, teal center, amber-blue
    /// center spot) and a dark element-cell ring on the dome, so the bore reads as glass behind glass.
    static func lensGlass(rimY: Float, floorY: Float, boreR R: Float, lod: Int) -> [Surface] {
        let seg = lod == 0 ? 36 : 20
        let d = rimY - floorY
        let ink: MaterialKey = "plastic.matte:0A0B0D", ring: MaterialKey = "metal.magnesium-worn"
        let y1 = rimY - 0.30 * d, y2 = rimY - 0.55 * d
        let rw = R * 0.996, rs = R * 0.93, rd = R * 0.86
        var out: [Surface] = []
        out.append(Prim.lathe([V2(rw, rimY), V2(rw, y1), V2(rs, y1), V2(rs, y2)], segments: seg, seamTile: 0.1, material: ink))
        out.append(Prim.lathe([V2(rw, y1 + 0.00002), V2(rs, y1 + 0.00002)], segments: seg, seamTile: 0.1, material: ring))
        out.append(Prim.lathe([V2(rs, y2 + 0.00002), V2(rd * 0.97, y2 + 0.00002)], segments: seg, seamTile: 0.1, material: ring))
        let sag = 0.18 * d
        func dome(_ r: Float) -> Float { y2 + sag * (1 - (r / rd) * (r / rd)) }
        if lod == 0 {
            let rs1: [Float] = [1, 0.82, 0.62].map { $0 * rd }, rs2: [Float] = [0.62, 0.40, 0.18, 0].map { $0 * rd }
            out.append(Prim.lathe(rs1.map { V2($0, dome($0)) }, segments: seg, seamTile: 0.1, material: "glass.lens-coated:2A1A5A"))
            out.append(Prim.lathe(rs2.map { V2($0, dome($0)) }, segments: seg, seamTile: 0.1, material: "glass.lens-coated:0B3037"))
            out.append(Prim.lathe([0.16, 0.08, 0].map { V2($0 * rd, dome($0 * rd) + 0.00003) }, segments: 20, seamTile: 0.1, material: "glass.lens-coated:1F3F8F"))
            out.append(Prim.lathe([V2(0.52 * rd, dome(0.52 * rd) + 0.00004), V2(0.46 * rd, dome(0.46 * rd) + 0.00004)], segments: seg, seamTile: 0.1, material: ink))
        } else {
            let rr: [Float] = [1, 0.6, 0.25, 0].map { $0 * rd }
            out.append(Prim.lathe(rr.map { V2($0, dome($0)) }, segments: seg, seamTile: 0.1, material: "glass.lens-coated:0B2A38"))
        }
        return out
    }

    // MARK: LCD

    /// Glass border and raised bezel lip around the LCD active area, in asset space at rest. `z` is the glass
    /// plane (screenRect z), `inner` the active area, `glassMargin` the coated glass border width, `lip` the raised
    /// bezel rim outside it. Four thin strips each; the active-area quad itself is left to the prop.
    static func lcdSurround(center c: V2, z: Float, inner: V2, glassMargin gm: Float = 0.0014, lip: Float = 0.0007,
                            lipMaterial: MaterialKey = "plastic.gloss:101114") -> [Surface] {
        var out: [Surface] = []
        func ring(_ w0: Float, _ w1: Float, _ zc: Float, _ th: Float, _ m: MaterialKey) {
            let ox = inner.x / 2 + w1, oy = inner.y / 2 + w1, ix = inner.x / 2 + w0, iy = inner.y / 2 + w0, wd = w1 - w0
            let r: Float = min(0.0008, wd * 0.4)
            for sy: Float in [-1, 1] {
                out.append(Prim.roundedBox(V3(2 * ox, wd, th), radius: r, bevelSegments: 1, material: m).transformed(Xform(translation: V3(c.x, c.y + sy * (iy + wd / 2), zc))))
            }
            for sx: Float in [-1, 1] {
                out.append(Prim.roundedBox(V3(wd, 2 * iy, th), radius: r, bevelSegments: 1, material: m).transformed(Xform(translation: V3(c.x + sx * (ix + wd / 2), c.y, zc))))
            }
            _ = ox; _ = oy
        }
        ring(0, gm, z + 0.00012, 0.00024, "glass.lens-coated:0A1C26")
        ring(gm, gm + lip, z + 0.00020, 0.00040, lipMaterial)
        return out
    }

    // MARK: grounding

    /// Soft contact shadow: three stacked translucent rounded rectangles, each larger than the last, just above
    /// the floor under the body footprint.
    static func contactShadow(center c: V3, size: V2) -> [Surface] {
        var out: [Surface] = []
        for (i, m) in ([0.0015, 0.0030, 0.0046] as [Float]).enumerated() {
            let w = size.x + 2 * m, dp = size.y + 2 * m
            let s = Prim.extrude(Shape2D.roundedRect(w, dp, radius: 0.004 + m, segments: 4), depth: 0.00003, bevel: 0, bevelSegments: 1, material: "shadow.contact")
            out.append(s.transformed(Xform(translation: V3(c.x, 0.00012 + Float(i) * 0.00004, c.z), rotation: simd_quatf(degrees: -90, axis: V3(1, 0, 0)))))
        }
        return out
    }
}
