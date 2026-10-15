import simd
import Foundation

/// Flemish/Dutch Colonial stepped (crow-step) gable parapet, 2.4 x 1.4 x 0.35 m: Flemish bond brick wall with vitrified
/// header diamonds, a sandstone string course, five sandstone coping stones per side, a stone-ringed attic oculus,
/// wrought iron wall anchors, a ball finial on the apex and lead flashing under the copings. Base on y = 0 (the roofline).
public struct SteppedGableParapet: RealAsset {
    public static let id = "stepped-gable-parapet"
    public static let summary = "Dutch Colonial stepped gable parapet, 2.4 x 1.4 m: brick wall, sandstone copings on each step, string course, oculus, iron wall anchors, ball finial."
    public static let tags = ["prop", "architecture", "facade", "roof", "brick", "stone"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 26, elevation: 12, distance: 3.6)

    /// Overall width at the base in meters.
    public var width: Float = 2.4
    /// Wall thickness under the copings in meters.
    public var wall: Float = 0.29
    /// Brick.
    public var brick: MaterialKey = "brick.red"
    /// Older common brick used for patched courses.
    public var patch: MaterialKey = "brick.common"
    /// Vitrified headers.
    public var header: MaterialKey = "brick.red:3B2F3A"
    /// Dressed sandstone for copings and string course.
    public var stone: MaterialKey = "stone.sandstone"
    /// Soot and lime staining.
    public var stain: MaterialKey = "stone.limestone-sooted"
    public var iron: MaterialKey = "metal.wrought-iron"
    public var lead: MaterialKey = "metal.tinned-copper"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let hw = width / 2, T = wall
        let steps = 5, tread: Float = 0.2, rise: Float = 0.21, y0: Float = 0.32
        func stepY(_ k: Int) -> Float { y0 + Float(k) * rise }

        // Stepped outline (right half mirrored), then the brick wall extruded through its thickness.
        var right: [V2] = [V2(hw, 0), V2(hw, stepY(0))]
        for k in 0..<steps {
            let x = hw - Float(k + 1) * tread
            right.append(V2(x, stepY(k)))
            if k < steps - 1 { right.append(V2(x, stepY(k + 1))) }
        }
        // Apex plateau at x = +-(hw - steps * tread) = 0.2 wide each side.
        let outline = right + right.reversed().map { V2(-$0.x, $0.y) }
        let wallOutline = Shape2D.deduped(outline)
        m.add(Prim.extrude(wallOutline, depth: T, bevel: 0.004, bevelSegments: 1, material: brick), Xform(translation: V3(0, 0, 0)))

        func topAt(_ x: Float) -> Float {
            let ax = abs(x)
            let k = min(steps - 1, max(0, Int((hw - ax) / tread)))
            return ax >= hw ? 0 : stepY(k)
        }
        // Flemish bond: vitrified headers (short dark faces) alternating along every other course.
        var row = 0
        var yy: Float = 0.1125
        while yy < stepY(steps - 1) - 0.05 {
            var x: Float = -hw + 0.13 + (row % 2 == 0 ? 0 : 0.11)
            while x < hw - 0.1 {
                if topAt(x) > yy + 0.05 && rng.float(0...1) < 0.42 {
                    for s: Float in [-1, 1] {
                        m.add(Prim.extrude(Shape2D.rect(0.1, 0.06), depth: 0.003, bevel: 0.0005, bevelSegments: 1, material: header),
                              Xform(translation: V3(x, yy, s * (T / 2 + 0.0008)), rotation: s > 0 ? .identity : FA.q(180, FA.Y)))
                    }
                }
                x += 0.22
            }
            yy += 0.075
            row += 1
        }
        // Tonal variation: over-burnt and underfired bricks, rising damp and moss at the base, efflorescence under the string course.
        let tones: [MaterialKey] = ["brick.red:9C4733", "brick.red:6E2F26", "brick.red:B5663F", patch]
        for _ in 0..<38 {
            let x = rng.float(-hw + 0.15...hw - 0.15)
            let y = rng.float(0.06...stepY(steps - 1) - 0.08)
            if y > topAt(x) - 0.06 || (y > 0.19 && y < 0.3) { continue }
            let s: Float = rng.float(0...1) < 0.5 ? 1 : -1
            m.add(Prim.extrude(Shape2D.rect(0.215, 0.065), depth: 0.003, bevel: 0.0005, bevelSegments: 1, material: tones[Int(rng.float(0...3.99))]),
                  Xform(translation: V3(x, y, s * (T / 2 + 0.001)), rotation: s > 0 ? .identity : FA.q(180, FA.Y)))
        }
        for s: Float in [-1, 1] {
            FA.box(&m, V3(width - 0.04, 0.1, 0.003), V3(0, 0.07, s * (T / 2 + 0.0008)), "brick.red:5A2E26", r: 0.0008)
            for _ in 0..<7 {
                let x = rng.float(-hw + 0.1...hw - 0.1)
                m.add(Prim.extrude(Shape2D.rect(rng.float(0.05...0.14), rng.float(0.02...0.06)), depth: 0.003, bevel: 0.0005, bevelSegments: 1, material: "brick.common:566B3A"),
                      Xform(translation: V3(x, 0.03, s * (T / 2 + 0.0022)), rotation: s > 0 ? .identity : FA.q(180, FA.Y)))
            }
            for _ in 0..<6 {
                let x = rng.float(-hw + 0.1...hw - 0.1), h = rng.float(0.04...0.1)
                m.add(Prim.extrude(Shape2D.rect(rng.float(0.015...0.04), h), depth: 0.002, bevel: 0.0004, bevelSegments: 1, material: "stone.limestone:E6E0D2"),
                      Xform(translation: V3(x, 0.19 - h / 2, s * (T / 2 + 0.0012)), rotation: s > 0 ? .identity : FA.q(180, FA.Y)))
            }
        }

        // String course: projecting sandstone band with a drip, across the full width.
        let bh = T / 2 + 0.03
        let band: [V2] = [V2(-bh, 0), V2(bh, 0), V2(bh, 0.012), V2(bh - 0.018, 0.02), V2(bh - 0.018, 0.085),
                          V2(-bh + 0.018, 0.085), V2(-bh + 0.018, 0.02), V2(-bh, 0.012)]
        FA.run(&m, band, length: width, at: V3(0, 0.2, 0), stone, bevel: 0.002)
        FA.box(&m, V3(width - 0.02, 0.004, T + 0.07), V3(0, 0.2 + 0.0855, 0), lead, r: 0.001)

        // Attic oculus: stone ring with four keyblocks and a dark glazed centre.
        let oc = V3(0, 0.82, T / 2)
        let R: Float = 0.17
        FA.cylZ(&m, r: R, h: 0.02, at: V3(0, oc.y, T / 2 - 0.012), "glass.pane", bevel: 0.001, segments: 28)
        m.add(Prim.torus(major: R + 0.04, minor: 0.032, segments: 30, sides: 10, material: stone),
              Xform(translation: V3(0, oc.y, T / 2 + 0.002), rotation: FA.q(90, FA.X)))
        for k in 0..<4 {
            let a = Float(k) * .pi / 2 + .pi / 4
            FA.box(&m, V3(0.075, 0.1, 0.045), V3(cos(a) * (R + 0.04), oc.y + sin(a) * (R + 0.04), T / 2 + 0.01), stone, r: 0.004,
                   rot: FA.q(Float(k) * 90 + 45, FA.Z))
        }
        for a in [Float(0), 90] {
            let r = a * .pi / 180
            FA.rod(&m, V3(-cos(r) * R, oc.y - sin(r) * R, T / 2 + 0.002), V3(cos(r) * R, oc.y + sin(r) * R, T / 2 + 0.002), r: 0.007, iron, sides: 6)
        }
        // Mirror the oculus ring on the back face.
        m.add(Prim.torus(major: R + 0.04, minor: 0.032, segments: 30, sides: 10, material: stone),
              Xform(translation: V3(0, oc.y, -T / 2 - 0.002), rotation: FA.q(90, FA.X)))

        // Copings: one weathered sandstone block per step, overhanging 25 mm each side, with a lead flashing strip below.
        let cd = T + 0.06
        for k in 0..<steps {
            let xr = hw - Float(k) * tread          // outer edge of the tread
            let xl = xr - tread
            let cxr = (xr + xl) / 2 + (k == 0 ? 0.0 : 0.0)
            let top = stepY(k)
            for s: Float in [-1, 1] {
                let cw = tread + (k == 0 ? 0.0125 : 0.025)
                let cx = s * (k == 0 ? (xr + xl - 0.0125) / 2 : cxr)
                FA.box(&m, V3(cw, 0.012, cd + 0.01), V3(cx, top + 0.006, 0), lead, r: 0.001)
                m.add(Prim.loft([Prim.ring(Shape2D.rect(cw, cd), y: 0), Prim.ring(Shape2D.rect(cw, cd), y: 0.035),
                                 Prim.ring(Shape2D.rect(cw - 0.012, cd - 0.07), y: 0.056)], capStart: true, capEnd: true, material: stone),
                      Xform(translation: V3(cx, top + 0.012, 0)))
                // Drip stain and soot on the brick under each tread.
                FA.box(&m, V3(0.09 + rng.float(0...0.05), 0.07 + rng.float(0...0.05), 0.003), V3(cx + rng.float(-0.04...0.04), top - 0.05, T / 2 + 0.0012), stain, r: 0.001)
            }
        }
        // Apex coping across the 0.4 m top plateau, then the finial: plinth, neck and ball.
        let ax = hw - Float(steps) * tread
        let topY = stepY(steps - 1)
        FA.box(&m, V3(2 * ax + 0.05, 0.012, cd + 0.01), V3(0, topY + 0.006, 0), lead, r: 0.001)
        m.add(Prim.loft([Prim.ring(Shape2D.rect(2 * ax + 0.05, cd), y: 0), Prim.ring(Shape2D.rect(2 * ax + 0.05, cd), y: 0.035),
                         Prim.ring(Shape2D.rect(2 * ax + 0.038, cd - 0.07), y: 0.056)], capStart: true, capEnd: true, material: stone),
              Xform(translation: V3(0, topY + 0.012, 0)))
        let fy = topY + 0.07
        m.add(Prim.lathe([V2(0, 0), V2(0.095, 0), V2(0.095, 0.02), V2(0.075, 0.034), V2(0.075, 0.06), V2(0.05, 0.075), V2(0.04, 0.09), V2(0.0, 0.09)],
                         segments: 20, seamTile: 0.1, material: stone), Xform(translation: V3(0, fy, 0)))
        FC.bead(&m, r: 0.055, at: V3(0, fy + 0.138, 0), stone, sub: 5)
        FC.bead(&m, r: 0.012, at: V3(0, fy + 0.2, 0), iron, sub: 3)

        // Wrought iron wall anchors (S and straight): bar through the wall with end plates and bolt heads, on the front face.
        for (x, y, a) in [(Float(-0.62), Float(0.62), Float(0)), (0.62, 0.62, 0), (0, 0.46, 0)] {
            _ = a
            for s: Float in [-1, 1] {
                let c = V3(x, y, s * (T / 2 + 0.006))
                FA.box(&m, V3(0.2, 0.026, 0.012), c, iron, r: 0.003)
                FA.box(&m, V3(0.026, 0.1, 0.012), c, iron, r: 0.003)
                for (dx, dy) in [(Float(0.075), Float(0)), (-0.075, 0), (0, 0.04), (0, -0.04)] {
                    FC.bead(&m, r: 0.011, at: c + V3(dx, dy, s * 0.007), iron, sub: 2)
                }
            }
        }

        func slab(_ w: Float, _ h: Float, _ d: Float, _ c: V3, _ mat: MaterialKey) {
            m.add(Prim.extrude(Shape2D.rect(w, h), depth: d, bevel: min(0.002, d * 0.3), bevelSegments: 1, material: mat), Xform(translation: c))
        }
        // Corner quoins: long and short sandstone blocks alternating up the outer corners to the first coping.
        for sx: Float in [-1, 1] {
            for k in 0..<4 {
                let long = k % 2 == 0
                let w: Float = long ? 0.22 : 0.13
                let y = 0.0 + 0.075 * Float(k) + 0.0375
                if y + 0.0375 > 0.3 { continue }
                for sz: Float in [-1, 1] {
                    slab(w, 0.07, 0.012, V3(sx * (hw - w / 2), y, sz * (T / 2 + 0.0035)), stone)
                }
            }
        }
        // Stone date cartouche above the string course: panel with a raised frame and a cartouche boss.
        for s: Float in [-1, 1] {
            let zf = s * (T / 2 + 0.004)
            slab(0.34, 0.12, 0.008, V3(0, 0.5, zf), stone)
            slab(0.28, 0.07, 0.006, V3(0, 0.5, s * (T / 2 + 0.01)), "stone.limestone:D8D0BC")
            for i in 0..<4 {
                slab(0.03, 0.04, 0.004, V3(-0.09 + Float(i) * 0.06, 0.5, s * (T / 2 + 0.0135)), "stone.limestone:6E6A5E")
            }
        }
        // Ball finials on the outer end of the second and fourth steps.
        for k in [1, 3] {
            for s: Float in [-1, 1] {
                let x = s * (hw - Float(k) * tread - 0.07)
                let top = stepY(k) + 0.068
                m.add(Prim.lathe([V2(0, 0), V2(0.04, 0), V2(0.04, 0.012), V2(0.028, 0.022), V2(0, 0.024)], segments: 14, seamTile: 0.1, material: stone),
                      Xform(translation: V3(x, top, 0)))
                FC.bead(&m, r: 0.036, at: V3(x, top + 0.058, 0), stone, sub: 4)
            }
        }

        groundAO(&m, height: 0.12, floor: 0.82)
        return LODModel(FC.place(m))
    }
}
