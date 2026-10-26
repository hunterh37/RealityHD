import simd
import Foundation

/// Dutch Renaissance Flemish gable, 2.2 x 2.0 x 0.4 m: a 340 mm brick wall with an ogee-scrolled two-tier outline, individual
/// sandstone copings following the curve, sandstone bands and corner quoins, applied volutes, an arched attic window with
/// keystone and sill, a diaper of vitrified headers, wrought iron anchor plates, shoulder ball finials and an apex obelisk.
/// Base on y = 0 (the roofline).
public struct FlemishScrolledGable: RealAsset {
    public static let id = "flemish-scrolled-gable"
    public static let summary = "Dutch Renaissance Flemish gable, 2.2 x 2.0 m: brick body, scrolled S-curve shoulders, sandstone bands, volutes, attic window, pediment, finials, iron anchors."
    public static let tags = ["prop", "architecture", "facade", "roof", "brick", "stone"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 26, elevation: 10, distance: 3.3)

    /// Overall width at the base in meters.
    public var width: Float = 2.1
    /// Brick wall thickness in meters.
    public var wall: Float = 0.3
    public var brick: MaterialKey = "brick.red:A2503B"
    /// Vitrified header bricks.
    public var header: MaterialKey = "brick.red:3B2F3A"
    /// Dressed sandstone.
    public var stone: MaterialKey = "stone.sandstone:C4AF88"
    public var iron: MaterialKey = "metal.wrought-iron"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let hw = width / 2, T = wall, zf = T / 2

        // Right half of the outline: vertical flank, lower ogee shoulder, upper tier, second scroll, segmental pediment.
        let ctrl: [V3] = [V3(hw, 0.85, 0), V3(hw, 0.93, 0), V3(1.0, 1.01, 0), V3(0.87, 1.05, 0), V3(0.8, 1.11, 0), V3(0.8, 1.2, 0),
                          V3(0.72, 1.25, 0), V3(0.62, 1.29, 0), V3(0.58, 1.35, 0), V3(0.58, 1.46, 0), V3(0.54, 1.54, 0), V3(0.46, 1.59, 0),
                          V3(0.4, 1.64, 0), V3(0.4, 1.7, 0), V3(0.3, 1.74, 0), V3(0.15, 1.78, 0), V3(0, 1.79, 0)]
        let curve = catmull(ctrl, per: 4).map { V2($0.x, $0.y) }
        var right: [V2] = [V2(hw, 0)] + curve
        right = Shape2D.deduped(right)
        let outline = Shape2D.deduped(right + right.dropLast().reversed().map { V2(-$0.x, $0.y) })
        m.add(Prim.extrude(outline, depth: T, bevel: 0.004, bevelSegments: 1, material: brick))

        // Diaper of vitrified headers in the lower body and tonal brick patches.
        for s: Float in [-1, 1] {
            let z = s * (zf + 0.0012)
            var row = 0
            var y: Float = 0.16
            while y < 0.78 {
                var x: Float = -hw + 0.16 + (row % 2 == 0 ? 0 : 0.14)
                while x < hw - 0.12 {
                    FO8.slab(&m, 0.1, 0.06, 0.0025, V3(x, y, z), header, bevel: 0.0006)
                    x += 0.34
                }
                y += 0.26
                row += 1
            }
        }
        let tones: [MaterialKey] = ["brick.red:9C4733", "brick.red:6E2F26", "brick.red:B5663F", "brick.common"]
        for _ in 0..<12 {
            let y = rng.float(0.1...1.4)
            let x = rng.float(-1...1)
            if abs(x) > FO8.halfWidth(right, at: y) - 0.1 { continue }
            let s: Float = rng.chance(0.5) ? 1 : -1
            FO8.slab(&m, 0.22, 0.065, 0.0028, V3(x, y, s * (zf + 0.0022)), tones[rng.int(0...3)], bevel: 0.0006)
        }

        // Sandstone bands across the wall at the four stage lines (width follows the outline).
        for (y, h) in [(Float(0.46), Float(0.07)), (0.8, 0.07), (1.28, 0.06)] {
            let w = min(FO8.halfWidth(right, at: y), FO8.halfWidth(right, at: y + h)) * 2 - 0.012
            for s: Float in [-1, 1] {
                FO8.slab(&m, w, h, 0.03, V3(0, y + h / 2, s * (zf + 0.005)), stone, bevel: 0.003)
                FO8.slab(&m, w - 0.01, 0.01, 0.04, V3(0, y - 0.003, s * (zf + 0.005)), "stone.limestone-sooted", bevel: 0.002)
            }
        }
        // Corner quoins: long and short sandstone blocks up each flank.
        for sx: Float in [-1, 1] {
            for k in 0..<10 {
                let long = k % 2 == 0
                let w: Float = long ? 0.26 : 0.15
                let y = 0.0 + Float(k) * 0.078
                if y + 0.07 > 0.85 { continue }
                for sz: Float in [-1, 1] {
                    FO8.slab(&m, w, 0.07, 0.016, V3(sx * (hw - w / 2), y + 0.035, sz * (zf + 0.0045)), stone, bevel: 0.002)
                }
            }
        }

        // Copings: one sandstone stone per ~140 mm along the curve, overhanging the wall 25 mm per side.
        var last = right[right.count - curve.count - 1]
        var acc: [V2] = [last]
        for p in curve.dropFirst() {
            if simd_distance(p, last) >= 0.13 || p == curve.last! { acc.append(p); last = p }
        }
        for i in 0..<(acc.count - 1) {
            let a = acc[i], b = acc[i + 1]
            let d = b - a, len = simd_length(d)
            if len < 0.03 { continue }
            let ang = atan2(d.y, d.x)
            let n = V2(d.y, -d.x) / len
            let c = (a + b) / 2 + n * 0.0225
            for s: Float in [-1, 1] {
                let cx = s * c.x
                let rot = FA.q((s > 0 ? ang : Float.pi - ang) * 180 / .pi, FA.Z)
                m.add(Prim.extrude(Shape2D.rect(len + 0.012, 0.045), depth: T + 0.05, bevel: 0.004, bevelSegments: 1, material: stone),
                      Xform(translation: V3(cx, c.y, 0), rotation: rot))
            }
        }

        // Volutes: applied sandstone scrolls on both faces at the two shoulders.
        func volute(_ cx: Float, _ cy: Float, _ r0: Float, _ s: Float, _ sx: Float) {
            var pts: [V3] = [], radii: [Float] = []
            for k in 0...22 {
                let t = Float(k) / 22
                let a = t * 3.1 * .pi + 0.4, r = r0 * (1 - 0.82 * t)
                pts.append(V3(sx * (cx + r * cos(a)), cy + r * sin(a), s * (zf + 0.015)))
                radii.append(0.017 - 0.009 * t)
            }
            m.add(Prim.tube(pts, radii: radii, sides: 8, seamTile: 0.15, material: stone, capEnd: true))
            m.add(Prim.superellipsoid(V3(0.04, 0.04, 0.026), exponent: 2, subdivisions: 4, material: stone),
                  Xform(translation: V3(sx * cx, cy, s * (zf + 0.015))))
        }
        for s: Float in [-1, 1] {
            for sx: Float in [-1, 1] {
                volute(0.89, 0.93, 0.12, s, sx)
                volute(0.4, 1.42, 0.085, s, sx)
            }
        }

        // Attic window: dressed arched surround, dark glazing with a mullion and transom, keystone and projecting sill.
        func arch(_ w: Float, _ h: Float) -> [V2] {
            var p: [V2] = [V2(-w / 2, 0), V2(w / 2, 0)]
            let r = w / 2
            for k in 0...12 {
                let a = Float(k) / 12 * .pi
                p.append(V2(r * cos(a), h - r + r * sin(a)))
            }
            return Shape2D.deduped(p)
        }
        let wy: Float = 0.9
        for s: Float in [-1, 1] {
            let z = s * (zf + 0.004)
            m.add(Prim.extrude(arch(0.34, 0.54), depth: 0.016, bevel: 0.003, bevelSegments: 1, material: stone), Xform(translation: V3(0, wy - 0.02, z)))
            m.add(Prim.extrude(arch(0.22, 0.4), depth: 0.006, bevel: 0.001, bevelSegments: 1, material: "metal.painted:20211F"), Xform(translation: V3(0, wy + 0.05, s * (zf + 0.0105))))
            m.add(Prim.extrude(arch(0.2, 0.37), depth: 0.004, bevel: 0.0008, bevelSegments: 1, material: "glass.pane"), Xform(translation: V3(0, wy + 0.06, s * (zf + 0.0135))))
            FA.box(&m, V3(0.012, 0.28, 0.01), V3(0, wy + 0.2, s * (zf + 0.0165)), "wood.painted-exterior:E8E4D8", r: 0.002)
            FA.box(&m, V3(0.2, 0.012, 0.01), V3(0, wy + 0.22, s * (zf + 0.0165)), "wood.painted-exterior:E8E4D8", r: 0.002)
            FA.box(&m, V3(0.06, 0.07, 0.03), V3(0, wy + 0.5, s * (zf + 0.012)), stone, r: 0.003)
            FA.box(&m, V3(0.42, 0.03, 0.05), V3(0, wy - 0.035, s * (zf + 0.02)), stone, r: 0.003)
        }

        // Wrought iron anchor plates: cross bars with bolt heads at the four corners of each plate.
        for (x, y) in [(Float(-0.6), Float(0.62)), (0.6, 0.62), (-0.46, 1.1), (0.46, 1.1)] {
            for s: Float in [-1, 1] {
                let z = s * (zf + 0.009)
                FO8.slab(&m, 0.2, 0.026, 0.012, V3(x, y, z), iron, bevel: 0.003)
                FO8.slab(&m, 0.026, 0.1, 0.012, V3(x, y, z), iron, bevel: 0.003)
                for (dx, dy) in [(Float(0.075), Float(0)), (-0.075, 0), (0, 0.04), (0, -0.04)] {
                    FC.bead(&m, r: 0.011, at: V3(x + dx, y + dy, z + s * 0.007), iron, sub: 2)
                }
                FO8.slab(&m, 0.014, 0.1 + rng.float(0...0.06), 0.0022, V3(x + 0.015, y - 0.12, s * (zf + 0.0035)), "brick.red:3A2622", bevel: 0.0005)
            }
        }

        // Finials: obelisk on the apex, ball and pedestal at each shoulder where the scroll starts.
        func pedestal(_ x: Float, _ y: Float, _ w: Float, _ h: Float) {
            let rings = [Prim.ring(Shape2D.rect(w, w), y: 0), Prim.ring(Shape2D.rect(w, w), y: h * 0.18),
                         Prim.ring(Shape2D.rect(w * 0.72, w * 0.72), y: h * 0.22), Prim.ring(Shape2D.rect(w * 0.3, w * 0.3), y: h)]
            m.add(Prim.loft(rings, capStart: true, capEnd: true, material: stone), Xform(translation: V3(x, y, 0)))
        }
        pedestal(0, 1.79 + 0.045, 0.12, 0.12)
        FC.bead(&m, r: 0.022, at: V3(0, 1.79 + 0.045 + 0.14, 0), stone, sub: 4)
        for sx: Float in [-1, 1] {
            pedestal(sx * (hw - 0.09), 0.85, 0.15, 0.17)
            FC.bead(&m, r: 0.05, at: V3(sx * (hw - 0.09), 0.85 + 0.17 + 0.04, 0), stone, sub: 5)
        }

        // Weathering: soot below the copings, efflorescence at the base, moss and lichen on the bands, drip stains below the sill.
        FO8.patches(&m, &rng, count: 8, xr: -0.9...0.9, yr: 0.1...0.4, w: 0.04...0.12, h: 0.04...0.14, zFace: zf + 0.0035,
                   mats: ["brick.mortar-lime", "stone.limestone:BFB9A6", "brick.common:566B3A"])
        FO8.patches(&m, &rng, count: 6, xr: -0.7...0.7, yr: 1.3...1.75, w: 0.03...0.07, h: 0.05...0.15, zFace: zf + 0.0035,
                   mats: ["stone.limestone:6F6B5C", "brick.red:4A2A24"])
        for s: Float in [-1, 1] {
            FO8.slab(&m, 0.05, 0.22, 0.003, V3(-0.12, 0.74, s * (zf + 0.0045)), "stone.limestone:6A665A", bevel: 0.0008)
            FO8.slab(&m, 0.04, 0.16, 0.003, V3(0.11, 0.76, s * (zf + 0.0045)), "stone.limestone:6A665A", bevel: 0.0008)
        }

        // Rain streaks under the copings, spalled bricks, rising damp with a green band at the base, a bird-limed coping.
        for s: Float in [-1, 1] {
            for k in 0..<5 {
                let x = -0.8 + Float(k) * 0.4 + rng.float(-0.05...0.05)
                let top: Float = FO8.halfWidth(right, at: 1.2) > abs(x) ? 1.25 : 0.84
                FO8.slab(&m, rng.float(0.025...0.045), rng.float(0.16...0.3), 0.0024, V3(x, top - 0.14, s * (zf + 0.0062)), "brick.red:4B2A22", bevel: 0.0005)
            }
            FO8.slab(&m, width - 0.12, 0.05, 0.0026, V3(0, 0.14, s * (zf + 0.0058)), "stone.limestone:7C8160", bevel: 0.0008)
            // Plinth course: sandstone footing projecting 25 mm with a weathered chamfer top and a soot line at the foot.
            FO8.slab(&m, width + 0.02, 0.09, 0.05, V3(0, 0.045, s * zf), stone, bevel: 0.004)
            FO8.slab(&m, width + 0.0, 0.03, 0.054, V3(0, 0.015, s * (zf + 0.0)), "stone.limestone-sooted", bevel: 0.002)
            for k in 0..<4 {
                FO8.slab(&m, 0.1 + rng.float(0...0.05), 0.06, 0.003, V3(-0.7 + Float(k) * 0.45 + rng.float(-0.05...0.05), 0.2 + rng.float(0...0.5), s * (zf + 0.0035)), "brick.common:7D5B4A", bevel: 0.0006)
            }
        }

        groundAO(&m, height: 0.12, floor: 0.82)
        return LODModel(FC.place(m))
    }
}
