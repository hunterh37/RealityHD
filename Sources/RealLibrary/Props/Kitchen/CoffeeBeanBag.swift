import simd
import Foundation

/// 250 g specialty coffee bag standing on its flat bottom: kraft paper body 130 x 80 mm with side
/// gussets closing to a flat seam, top rolled down twice and held by a tin-tie whose ends fold down
/// at the sides, round one-way degassing valve, blank label, paper crinkles, and a small spill of
/// roasted beans beside it, each bean with its centre crease.
public struct CoffeeBeanBag: RealAsset {
    public static let id = "coffee-bean-bag"
    public static let summary = "250 g kraft paper flat-bottom coffee bag, top rolled with a tin-tie, degassing valve, blank label, beans spilled beside it."
    public static let tags = ["prop", "kitchen", "paper", "container", "food", "handheld"]
    public static let budget = 9000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 25, elevation: 22, studio: true)

    /// Bag front width (x), gusset depth (z) at the base, in meters.
    public var bagWidth: Float = 0.13
    public var bagDepth: Float = 0.08
    /// Height of the bag body where the rolled top begins (m).
    public var rollY: Float = 0.168
    /// Rolled top radius (m), two turns of paper.
    public var rollRadius: Float = 0.0115
    /// Number of spilled beans.
    public var beanCount: Int = 15
    /// Kraft paper.
    public var kraft: MaterialKey = "paper.screwbox-kraft:B08A5E"
    /// Tin-tie wire band.
    public var tinTie: MaterialKey = "metal.galvanized-aged"
    /// Label and valve plastic.
    public var label: MaterialKey = "plastic.matte:F2EFE6"
    public var valve: MaterialKey = "plastic.matte:EDEBE4"
    /// Roasted beans.
    public var bean: MaterialKey = "plastic.gloss:3B2416"
    public init() {}

    func depth(_ y: Float) -> Float {
        let t = smoothstep(rollY * 0.55, rollY, y)
        return bagDepth + (0.012 - bagDepth) * t
    }
    func width(_ y: Float) -> Float { bagWidth * (1 + 0.025 * sin(min(1, y / rollY) * .pi)) }

    func bag(_ m: inout Model, detail: Bool, rng: inout SeededRNG) {
        let st = detail ? 34 : 14, sides = detail ? 56 : 24
        var ys: [Float] = [0, 0.0018, 0.0045]
        for i in 1...st { ys.append(0.0045 + (rollY - 0.0045) * Float(i) / Float(st)) }
        let rings: [[V3]] = ys.enumerated().map { (i, y) in
            let inset: Float = i == 0 ? 0.004 : (i == 1 ? 0.0012 : 0)
            let w = width(y) - inset * 2, d = depth(y) - inset * 2
            let n: Float = 5 + 5 * smoothstep(rollY * 0.5, rollY, y)
            return Prim.ring(Shape2D.superellipse(w, d, exponent: n, segments: sides), y: y)
        }
        var s = Prim.loft(rings, capStart: true, capEnd: false, material: kraft)
        if detail {
            let sd = UInt32(rng.int(0...9999)), rY = rollY, bw = bagWidth
            s.displace { p, n in
                guard p.y > 0.004 else { return 0 }
                let c = Noise.ridged(V3(p.x * 38, p.y * 22, p.z * 38), octaves: 3, seed: sd) - 0.45
                // Gusset fold: sides pull inward as the bag closes to the seam.
                let side = smoothstep(bw * 0.38, bw * 0.5, abs(p.x)) * smoothstep(rY * 0.45, rY, p.y)
                let fold = 0.0009 * sin(p.y * 260 + Noise.perlin(V3(p.x * 30, p.y * 10, 0), seed: sd) * 4) * smoothstep(0.08, 0.15, p.y)
                return (0.0019 * c + fold) * smoothstep(0.004, 0.02, p.y) - 0.006 * side * smoothstep(0.5, 0.9, abs(n.x))
            }
        }
        s.uvs = s.positions.map { V2($0.x + $0.z, $0.y) }
        s.computeTangents()
        m.add(s)
        // Rolled top: two turns as a flattened roll along X, ends showing the turns.
        let rr = rollRadius, ry = rollY + rr * 0.55, rw = width(rollY) - 0.002
        var roll = Prim.cylinder(radius: rr, height: rw, bevel: 0.002, segments: detail ? 22 : 10, bevelSegments: detail ? 2 : 1, material: kraft)
        if detail { roll.displace { p, _ in 0.0004 * Noise.perlin(V3(p.x * 90, p.y * 40, p.z * 90)) } }
        m.add(roll, Xform(translation: V3(-rw / 2, ry, 0), rotation: simd_quatf(angle: -.pi / 2, axis: V3(0, 0, 1)), scale: V3(1, 1, 0.82)))
        // Outer turn edge line along the front of the roll.
        m.add(Prim.roundedBox(V3(rw - 0.004, 0.0028, 0.0012), radius: 0.0004, bevelSegments: 1, material: kraft),
              Xform(translation: V3(0, ry - rr * 0.55, rr * 0.82 - 0.0002), rotation: simd_quatf(angle: 0.5, axis: V3(1, 0, 0))))
        // Tin-tie: band visible along the roll top, ends folded down over the sides.
        m.add(Prim.roundedBox(V3(rw + 0.003, 0.0012, 0.0062), radius: 0.0005, bevelSegments: 1, material: tinTie),
              Xform(translation: V3(0, ry + rr - 0.0003, 0)))
        for sx in [Float(-1), 1] {
            m.add(Prim.roundedBox(V3(0.0012, 0.026, 0.0062), radius: 0.0005, bevelSegments: 1, material: tinTie),
                  Xform(translation: V3(sx * (rw / 2 + 0.0015), ry + rr - 0.013, 0), rotation: simd_quatf(angle: sx * 0.08, axis: V3(0, 0, 1))))
        }
        // Label and valve on the front panel (+Z).
        let ly: Float = 0.062, fz = depth(ly) / 2
        _ = fz
        m.add(labelPatch(w: 0.082, h: 0.062, cy: ly, cols: detail ? 14 : 4, rows: detail ? 8 : 2))
        let vy: Float = 0.118, vz = depth(vy) / 2
        let tilt = atan2(depth(vy - 0.01) / 2 - depth(vy + 0.01) / 2, 0.02)
        let vx = Xform(translation: V3(0, vy, vz + 0.0006), rotation: simd_quatf(angle: .pi / 2 - tilt, axis: V3(1, 0, 0)))
        m.add(Prim.cylinder(radius: 0.0105, height: 0.0012, bevel: 0.0004, segments: detail ? 24 : 10, bevelSegments: 1, material: valve), vx)
        m.add(Prim.cylinder(radius: 0.0052, height: 0.0024, bevel: 0.0007, segments: detail ? 16 : 8, bevelSegments: 1, material: valve), vx)
    }

    /// Front surface z of the undisplaced bag body at (x, y).
    func frontZ(_ x: Float, _ y: Float) -> Float {
        let n: Float = 5 + 5 * smoothstep(rollY * 0.5, rollY, y), hw = width(y) / 2
        return depth(y) / 2 * pow(max(0, 1 - pow(abs(x) / hw, n)), 1 / n)
    }

    /// Paper label conforming to the front panel, 1.6 mm proud to clear the crinkles.
    func labelPatch(w: Float, h: Float, cy: Float, cols: Int, rows: Int) -> Surface {
        var s = Surface(material: label)
        for j in 0...rows { for i in 0...cols {
            let x = -w / 2 + w * Float(i) / Float(cols), y = cy - h / 2 + h * Float(j) / Float(rows)
            _ = s.add(V3(x, y, frontZ(x, y) + 0.0016), V3(0, 0, 1), V2(x, y))
        } }
        let row = UInt32(cols + 1)
        for j in 0..<UInt32(rows) { for i in 0..<UInt32(cols) { let a = j * row + i; s.quad(a, a + 1, a + row + 1, a + row) } }
        s.recomputeNormals()
        s.computeTangents()
        return s
    }

    func beanSurface(detail: Bool) -> Surface {
        Prim.superellipsoid(V3(0.0115, 0.0058, 0.0084), exponent: 2.3, subdivisions: detail ? 4 : 2, material: bean) { d in
            // Centre crease along the flat (top) face, slight belly underneath.
            let crease = detail ? 0.32 * exp(-pow(d.z / 0.14, 2)) * max(0, d.y) * (1 - pow(abs(d.x), 4)) : 0
            return (d.y > 0 ? 0.88 : 1.04) - crease
        }
    }

    func level(detail: Bool, seed: UInt64) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        bag(&m, detail: detail, rng: &rng)
        let b = beanSurface(detail: detail)
        let hb = (b.positions.map { $0.y }.min() ?? 0)
        let ht = (b.positions.map { $0.y }.max() ?? 0)
        var brng = rng.fork(7)
        for i in 0..<beanCount {
            let a = brng.float(-1.2...1.0), r = 0.012 + 0.05 * sqrt(brng.float())
            let x = bagWidth / 2 + 0.018 + r * cos(a) * 0.9, z = 0.012 + r * sin(a) * 0.8
            let up = brng.chance(0.7)
            let rot = simd_quatf(angle: brng.float(0...6.28), axis: V3(0, 1, 0)) * (up ? simd_quatf(angle: 0, axis: V3(1, 0, 0)) : simd_quatf(angle: .pi, axis: V3(1, 0, 0)))
            let y = up ? -hb * 0.97 : ht * 0.97
            _ = i
            m.add(b, Xform(translation: V3(x, y, z), rotation: rot, scale: V3(repeating: brng.float(0.9...1.08))))
        }
        groundAO(&m, height: 0.02, floor: 0.55)
        let bb = m.bounds
        return m.transformed(Xform(translation: V3(-(bb.min.x + bb.max.x) / 2, 0, -(bb.min.z + bb.max.z) / 2)))
    }

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [level(detail: true, seed: seed), level(detail: false, seed: seed)], switchDistances: [3])
    }
}
