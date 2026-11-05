import simd
import Foundation

/// 1775 pierced-tin signal lantern, 34 cm: cylindrical tin body with hand-punched stars and diamonds (about 500
/// dimples), rolled rims and solder lines, a hinged side door with latch, flat base with candle socket, conical
/// cap with vent chimney and ring finial, wire bail, and a beeswax candle. Joints `flame` 0...1 (switch follower:
/// teardrop flame, glowing punches, point light) and `door` 0...100 degrees. States lit, unlit, lit-open.
public struct SignalLantern: RealArticulated {
    public static let id = "signal-lantern"
    public static let summary = "1775 pierced-tin signal lantern, 34 cm: punched star and diamond body, conical cap with chimney, hinged door, wire bail and a candle that glows through the holes."
    public static let tags = ["prop", "metal", "light", "antique", "handheld", "glowing", "articulated"]
    public static let budget = 9000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 205, elevation: 10, distance: 1.1, studio: true)

    /// Tarnished tin for body, door and cap.
    public var tin: MaterialKey = "metal.galvanized-aged"
    /// Brighter tin for rims and edges.
    public var tinBright: MaterialKey = "metal.galvanized"
    /// Solder seams.
    public var solder: MaterialKey = "metal.tinned-copper"
    /// Iron wire for the bail and hinge pins.
    public var iron: MaterialKey = "metal.iron"
    /// Beeswax candle.
    public var wax: MaterialKey = "plastic.matte:E3B95A"
    /// Glow through the punches and the flame body.
    public var glow: MaterialKey = "emissive.warm"
    /// Flame outer halo.
    public var halo: MaterialKey = "emissive.amber"
    /// Body radius (m).
    public var radius: Float = 0.066
    public init() {}

    static let yBase: Float = 0.014, yTop: Float = 0.2255
    static let doorHalf: Float = 30 * .pi / 180

    public func rig(seed: UInt64) -> Rig {
        var rng = SeededRNG(seed: seed)
        var rig = Rig(name: Self.id, lods: 1)
        let R = radius, y0 = Self.yBase, y1 = Self.yTop, dh = Self.doorHalf
        func pt(_ r: Float, _ th: Float, _ y: Float) -> V3 { V3(r * sin(th), y, r * cos(th)) }
        func arc(_ r: Float, _ a: Float, _ b: Float, _ y: Float, _ n: Int) -> [V3] { (0...n).map { pt(r, a + (b - a) * Float($0) / Float(n), y) } }

        /// Curved sheet between two angles; triangles are wound to match the radial normal.
        func sheet(_ r: Float, _ a: Float, _ b: Float, _ n: Int, outward: Bool, material: MaterialKey) -> Surface {
            var s = Surface(material: material)
            let sign: Float = outward ? 1 : -1
            for i in 0...n {
                let th = a + (b - a) * Float(i) / Float(n)
                let nn = V3(sin(th), 0, cos(th)) * sign
                _ = s.add(pt(r, th, y0), nn, V2(th * R, y0))
                _ = s.add(pt(r, th, y1), nn, V2(th * R, y1))
            }
            for i in 0..<n {
                let k = UInt32(i * 2)
                if outward { s.quad(k, k + 2, k + 3, k + 1) } else { s.quad(k, k + 1, k + 3, k + 2) }
            }
            s.computeTangents()
            return s
        }
        /// Thin edge strip joining the outer and inner sheet at one angle.
        func edge(_ th: Float, _ rOut: Float, _ rIn: Float, material: MaterialKey) -> Surface {
            var s = Surface(material: material)
            let nn = V3(cos(th), 0, -sin(th))
            for r in [rIn, rOut] { _ = s.add(pt(r, th, y0), nn, V2(r, y0)); _ = s.add(pt(r, th, y1), nn, V2(r, y1)) }
            s.quad(0, 2, 3, 1); s.quad(0, 1, 3, 2)
            s.computeTangents()
            return s
        }
        /// Cone dimple punched into the wall: rim on the surface, apex pushed inward. `rot` turns the whole pattern (rad).
        func dimples(_ pts: [(th: Float, y: Float, r: Float)], rBase: Float, material: MaterialKey, rot: Float = 0) -> Surface {
            var s = Surface(material: material)
            let sides = 4
            for p in pts {
                let th = p.th + rot
                let n = V3(sin(th), 0, cos(th)), t = V3(cos(th), 0, -sin(th))
                let c = pt(rBase, th, p.y)
                let apex = s.add(c - n * 0.0016, n, V2(th * R, p.y))
                var ring: [UInt32] = []
                for k in 0..<sides {
                    let f = Float(k) / Float(sides) * 2 * .pi
                    let d = t * cos(f) + V3(0, 1, 0) * sin(f)
                    ring.append(s.add(c + d * p.r, simd_normalize(n * p.r - d * 0.0016), V2(th * R + cos(f) * p.r, p.y + sin(f) * p.r)))
                }
                for k in 0..<sides { s.tri(ring[k], ring[(k + 1) % sides], apex) }
            }
            // Orient every triangle outward (apex points in, so the visible side faces along the normal).
            for i in stride(from: 0, to: s.indices.count, by: 3) {
                let a = Int(s.indices[i]), b = Int(s.indices[i + 1]), c = Int(s.indices[i + 2])
                let g = simd_cross(s.positions[b] - s.positions[a], s.positions[c] - s.positions[a])
                if simd_dot(g, s.normals[a] + s.normals[b] + s.normals[c]) < 0 { s.indices.swapAt(i + 1, i + 2) }
            }
            s.computeTangents()
            return s
        }

        // MARK: punch layout (angle, height, radius), hand-punched so sizes and spacing wander a little.
        var punches: [(th: Float, y: Float, r: Float)] = []
        func punch(_ th: Float, _ y: Float, _ r: Float) {
            punches.append((th + rng.float(-0.004...0.004), y + rng.float(-0.0006...0.0006), r * rng.vary(1, 0.1)))
        }
        for band in [Float(0.0285), 0.2115] {
            for i in 0..<25 { punch(dh + 0.04 + Float(i) * (2 * .pi - 2 * dh - 0.08) / 24, band, 0.0013) }
        }
        for j in 2...10 {
            let thc = Float(j) * 30 * .pi / 180
            for k in 0..<5 {
                let yc = 0.0455 + 0.0385 * Float(k)
                if (j + k) % 2 == 0 {
                    // Five-point star: tips at 0.0105, inner points at 0.0045, plus the centre punch.
                    punch(thc, yc, 0.0017)
                    for p in 0..<10 {
                        let a = Float(p) / 10 * 2 * .pi, rr: Float = p % 2 == 0 ? 0.0105 : 0.0046
                        punch(thc + sin(a) * rr / R, yc + cos(a) * rr, p % 2 == 0 ? 0.0014 : 0.0012)
                    }
                } else {
                    // Diamond outline: four corners, four edge midpoints, centre.
                    punch(thc, yc, 0.0019)
                    let cs: [(Float, Float)] = [(0, 0.0105), (0.0085, 0), (0, -0.0105), (-0.0085, 0)]
                    for c in 0..<4 {
                        let a = cs[c], b = cs[(c + 1) % 4]
                        punch(thc + a.0 / R, yc + a.1, 0.0015)
                        punch(thc + (a.0 + b.0) / 2 / R, yc + (a.1 + b.1) / 2, 0.0011)
                    }
                }
            }
        }
        let lean = -1 * Float.pi / 180   // the flame joint turns option 1 by +1 degree; pre-turn so lit punches land on the dark ones
        let dimR = R + 0.0003

        // MARK: base, socket, body wall, rims, seams
        var m = rig.base[0]
        m.add(turned([(0, 0), (0.0705, 0), (0.0725, 0.0018), (0.0728, 0.0075), (0.0695, 0.0118), (R + 0.0012, y0 - 0.0004),
                      (R - 0.0012, y0), (0, y0)], segments: 40, material: tinBright))
        m.add(turned([(0.0152, y0 - 0.0005), (0.0164, 0.0185), (0.0172, 0.026), (0.0158, 0.0268), (0.0148, 0.0262), (0.0142, 0.019), (0.0136, y0)],
                     segments: 32, material: tinBright))
        // Wax pool and candle (burned down a little, cupped top, wick, one drip).
        let cr: Float = 0.0124, top: Float = rng.vary(0.118, 0.04)
        m.add(turned([(0, 0.0185), (cr + 0.0004, 0.0185), (cr, 0.024), (cr, top - 0.003), (cr * 0.96, top), (cr * 0.7, top - 0.0022),
                      (0.0025, top - 0.0042), (0, top - 0.0042)], segments: 32, material: wax))
        m.add(Prim.tube([V3(0, top - 0.005, 0), V3(0.0004, top + 0.003, 0), V3(0.0016, top + 0.0075, 0.0003)],
                        radii: [0.0008, 0.0007, 0.0005], sides: 6, seamTile: 0.01, material: "metal.iron"))
        let da = rng.float(0...(2 * .pi)), dd = V3(cos(da), 0, sin(da))
        m.add(Prim.tube((0..<5).map { i -> V3 in let t = Float(i) / 4; return dd * (cr + 0.0009 + 0.0007 * t) + V3(0, top - 0.002 - t * 0.04, 0) },
                        radii: [0.0016, 0.0019, 0.0021, 0.0024, 0.0027], sides: 6, seamTile: 0.01, material: wax))
        // Body wall: outer and inner sheet, edges at the door opening, solder seam at the back.
        let a0 = dh, a1 = 2 * Float.pi - dh
        m.add(sheet(R, a0, a1, 40, outward: true, material: tin))
        m.add(sheet(R - 0.0008, a0, a1, 40, outward: false, material: tin))
        m.add(edge(a0, R, R - 0.0008, material: tinBright)); m.add(edge(a1, R, R - 0.0008, material: tinBright))
        for y in [y0 + 0.0006, y1 - 0.0006] {
            m.add(Prim.tube(arc(R + 0.0006, a0, a1, y, 24), radii: Array(repeating: 0.0017, count: 25), sides: 5, seamTile: 0.02, material: tinBright, capEnd: true))
        }
        m.add(Prim.tube([pt(R + 0.0009, .pi, y0 + 0.002), pt(R + 0.0009, .pi, y1 - 0.002)], radii: [0.0013, 0.0013], sides: 6, seamTile: 0.02, material: solder))
        for y in stride(from: Float(0.078), through: 0.17, by: 0.046) {
            m.add(Prim.tube(arc(R + 0.0004, 2.2, 4.08, y, 12), radii: Array(repeating: 0.0007, count: 13), sides: 4, seamTile: 0.02, material: solder))
        }
        // Hinge pins on the door edge.
        let hp = pt(R + 0.0014, -dh, 0)
        for y in [Float(0.036), 0.12, 0.2] {
            m.add(Prim.cylinder(radius: 0.0028, height: 0.016, bevel: 0.0007, segments: 10, bevelSegments: 1, material: iron), Xform(translation: V3(hp.x, y, hp.z)))
        }

        // MARK: cap, chimney, finial
        let cap: [(Float, Float)] = [(0.0668, y1 - 0.0004), (0.0700, y1), (0.0830, 0.2278), (0.0852, 0.2292), (0.0832, 0.2304), (0.0795, 0.2310),
                                     (0.0640, 0.2352), (0.0500, 0.2420), (0.0380, 0.2500), (0.0310, 0.2570), (0.0270, 0.2625), (0.0230, 0.2665), (0.0185, 0.2688), (0.0150, 0.2692)]
        m.add(turned(cap, segments: 32, material: tin))
        m.add(Prim.tube(arc(0.0690, 0, 2 * Float.pi, y1 + 0.0012, 30).dropLast(), radii: Array(repeating: 0.0011, count: 30), sides: 4, seamTile: 0.02, material: solder, capEnd: false))
        m.add(turned([(0.0156, 0.2680), (0.0150, 0.2740), (0.0146, 0.2890), (0.0166, 0.2902), (0.0170, 0.2920), (0.0150, 0.2928), (0.0120, 0.2900)], segments: 24, material: tinBright))
        for k in 0..<8 {
            let a = Float(k) / 8 * 2 * .pi + 0.2
            m.add(cuboid(V3(0.0042, 0.0075, 0.0009), material: "metal.iron"),
                  Xform(translation: V3(sin(a) * 0.0148, 0.2815, cos(a) * 0.0148), rotation: simd_quatf(degrees: a * 180 / .pi, axis: V3(0, 1, 0))))
        }
        for k in 0..<4 {
            let a = Float(k) / 4 * 2 * .pi + .pi / 4
            m.add(Prim.tube([V3(sin(a) * 0.0165, 0.2925, cos(a) * 0.0165), V3(sin(a) * 0.0165, 0.2972, cos(a) * 0.0165)], radii: [0.0013, 0.0013], sides: 6, seamTile: 0.01, material: tinBright))
        }
        m.add(turned([(0, 0.3090), (0.0070, 0.3068), (0.0140, 0.3032), (0.0225, 0.2985), (0.0232, 0.2972), (0.0215, 0.2967), (0, 0.2967)], segments: 28, material: tin))
        m.add(Prim.torus(major: 0.0108, minor: 0.0016, segments: 28, sides: 6, material: tinBright),
              Xform(translation: V3(0, 0.3090 + 0.0108 - 0.0012, 0), rotation: simd_quatf(degrees: 90, axis: V3(0, 0, 1))))

        // MARK: bail wire and eyelets
        let bx: Float = 0.0872, by0: Float = 0.2335, byTop: Float = 0.3385
        let bail = (0...28).map { i -> V3 in
            let t = Float(i) / 28 * .pi
            return V3(-bx * cos(t), by0 + (byTop - by0) * sin(t), 0)
        }
        m.add(Prim.tube(bail, radii: Array(repeating: 0.0015, count: bail.count), sides: 6, seamTile: 0.02, material: iron))
        for s in [Float(-1), 1] {
            m.add(Prim.torus(major: 0.0036, minor: 0.0011, segments: 14, sides: 6, material: iron),
                  Xform(translation: V3(s * 0.0848, by0 - 0.0006, 0), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        }
        rig.base[0] = m

        // MARK: door part (hinged at the left edge, swings outward)
        let hinge = pt(R, -dh, 0)
        rig.part("door", pivot: V3(hinge.x, 0, hinge.z), joint: .hinge(axis: V3(0, -1, 0), 0...100, duration: 0.7))
        rig.add(sheet(R, -dh, dh, 8, outward: true, material: tin), to: "door")
        rig.add(sheet(R - 0.0008, -dh, dh, 8, outward: false, material: tin), to: "door")
        rig.add(edge(-dh, R, R - 0.0008, material: tinBright), to: "door"); rig.add(edge(dh, R, R - 0.0008, material: tinBright), to: "door")
        for y in [y0 + 0.0006, y1 - 0.0006] {
            rig.add(Prim.tube(arc(R + 0.0006, -dh, dh, y, 8), radii: Array(repeating: 0.0017, count: 9), sides: 6, seamTile: 0.02, material: tinBright), to: "door")
        }
        rig.add(Prim.tube([pt(R + 0.0008, dh - 0.01, y0 + 0.002), pt(R + 0.0008, dh - 0.01, y1 - 0.002)], radii: [0.0012, 0.0012], sides: 6, seamTile: 0.02, material: tinBright), to: "door")
        var dp: [(th: Float, y: Float, r: Float)] = []
        for (k, yc) in [Float(0.06), 0.108, 0.156].enumerated() {
            dp.append((0, yc, 0.0017))
            for p in 0..<(k == 1 ? 8 : 10) {
                let n = k == 1 ? 8 : 10
                let a = Float(p) / Float(n) * 2 * .pi, rr: Float = k == 1 ? 0.0095 : (p % 2 == 0 ? 0.0105 : 0.0046)
                dp.append((sin(a) * rr / R, yc + cos(a) * rr, 0.0013))
            }
        }
        rig.add(dimples(dp, rBase: dimR, material: "metal.iron"), to: "door")
        let latch = pt(R + 0.0012, dh - 0.045, 0.108)
        rig.add(Prim.roundedBox(V3(0.007, 0.022, 0.0016), radius: 0.0005, bevelSegments: 1, material: iron),
                Xform(translation: V3(latch.x, 0.108, latch.z), rotation: simd_quatf(degrees: (dh - 0.045) * 180 / .pi, axis: V3(0, 1, 0))), to: "door")
        let knob = pt(R + 0.0036, dh - 0.045, 0.108)
        rig.add(Prim.cylinder(radius: 0.0028, height: 0.0034, bevel: 0.0008, segments: 12, bevelSegments: 1, material: "metal.brass-aged"),
                Xform(translation: V3(knob.x, 0.108 - 0.0017, knob.z)).self, to: "door")

        // MARK: flame part: option 0 dark punches, option 1 glowing punches, teardrop flame, halo.
        rig.part("flame", pivot: V3(0, top + 0.008, 0), joint: .hinge(axis: .up, 0...1, duration: 0.3), options: 2)
        rig.add(dimples(punches, rBase: dimR, material: "metal.iron"), to: "flame")
        let turn = Xform(rotation: simd_quatf(angle: lean, axis: V3(0, 1, 0)))
        rig.add(dimples(punches, rBase: dimR, material: glow), turn, to: "flame", option: 1)
        let fy = top + 0.0045
        func teardrop(_ h: Float, _ w: Float, _ material: MaterialKey) -> Surface {
            let prof: [V2] = (0...12).map { i in
                let t = Float(i) / 12
                let r = w * pow(sin(.pi * pow(t, 0.7)), 1.0) * (1 - 0.35 * t)
                return V2(i == 12 ? 0 : max(r, i == 0 ? 0 : 0.0003), h * t)
            }
            return Prim.lathe(prof, segments: 14, seamTile: 0.02, material: material, swapUV: false)
        }
        rig.add(teardrop(0.034, 0.0072, halo), Xform(translation: V3(0.0003, fy, 0)), to: "flame", option: 1)
        rig.add(teardrop(0.026, 0.0046, glow), Xform(translation: V3(0.0003, fy + 0.0012, 0)), to: "flame", option: 1)
        rig.lights = [RigLight(name: "flame-glow", kind: .point, part: "flame", option: 1, position: V3(0, fy + 0.016, 0),
                               color: V3(1.0, 0.58, 0.24), intensity: 420, attenuationRadius: 1.8)]
        rig.optionLinks = [RigOptionLink(part: "flame", joint: "flame", thresholds: [0.5])]
        rig.states = [RigState("lit", ["flame": 1], options: ["flame": 1]), RigState("unlit"), RigState("lit-open", ["flame": 1, "door": 100], options: ["flame": 1])]
        groundAO(&rig, height: 0.1, floor: 0.6)
        return rig
    }
}
