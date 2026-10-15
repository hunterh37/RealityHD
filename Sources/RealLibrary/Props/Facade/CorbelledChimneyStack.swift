import simd
import Foundation

/// Tudor Revival corbelled chimney stack, 0.9 x 2.4 m: red brick base with vitrified header diaper diamonds, sandstone
/// weathering, four corbel courses under a stone platform, twin twisted octagonal brick shafts with moulded stone caps and
/// drip, lead flashing apron and soot staining at the tops. Base on y = 0 (the roof surface), centered on X/Z.
public struct CorbelledChimneyStack: RealAsset {
    public static let id = "corbelled-chimney-stack"
    public static let summary = "Tudor Revival chimney stack, 0.9 x 2.4 m: red brick base with diaper header diamonds, corbelled courses, twin twisted octagonal shafts, stone cap."
    public static let tags = ["prop", "architecture", "facade", "roof", "brick", "stone"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 34, elevation: 14, distance: 4.2)

    /// Brick.
    public var brick: MaterialKey = "brick.red"
    /// Common brick for the sooted upper shafts.
    public var sooted: MaterialKey = "brick.common"
    /// Vitrified (burnt blue-black) headers.
    public var header: MaterialKey = "brick.red:231C2B"
    /// Dressed stone.
    public var stone: MaterialKey = "stone.sandstone"
    /// Soot-darkened stone.
    public var darkStone: MaterialKey = "stone.limestone-sooted"
    /// Lead flashing.
    public var lead: MaterialKey = "metal.tinned-copper"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let bw: Float = 0.72                        // base stack plan
        let yWeather: Float = 0.9                  // sandstone weathering
        let yCorbel: Float = 1.3                   // underside of the first corbel course
        let courseH: Float = 0.07
        let yPlat = yCorbel + 4 * courseH           // top of the corbels

        // Brick base and upper stack, with the weathering course between.
        FA.box(&m, V3(bw, yWeather, bw), V3(0, yWeather / 2, 0), brick, r: 0.006)
        weathering(&m, at: yWeather, half: bw / 2 + 0.03, stone: stone)
        let ySh0 = yWeather + 0.085
        FA.box(&m, V3(bw - 0.01, yCorbel - ySh0 + 0.02, bw - 0.01), V3(0, (ySh0 + yCorbel) / 2 + 0.01, 0), brick, r: 0.006)

        // Diaper pattern: vitrified header diamonds on all four faces of the base and the upper stack.
        for (y0, y1) in [(Float(0.22), yWeather - 0.08), (ySh0 + 0.07, yCorbel - 0.05)] {
            var row = 0
            var y = y0
            while y <= y1 {
                let n = 5
                for i in 0..<n {
                    let off: Float = row % 2 == 0 ? 0 : 0.5
                    let u = -bw / 2 + 0.07 + (Float(i) + off) * (bw - 0.14) / Float(n - (row % 2 == 0 ? 1 : 0)) + (row % 2 == 0 ? 0 : 0)
                    if abs(u) > bw / 2 - 0.05 { continue }
                    for f in 0..<4 {
                        let (n3, t3): (V3, V3) = [(V3(0, 0, 1), V3(1, 0, 0)), (V3(1, 0, 0), V3(0, 0, -1)),
                                                  (V3(0, 0, -1), V3(-1, 0, 0)), (V3(-1, 0, 0), V3(0, 0, 1))][f]
                        let c = n3 * (bw / 2 + 0.0015) + t3 * u + V3(0, y, 0)
                        let yaw = simd_quatf(from: V3(0, 0, 1), to: n3)
                        m.add(Prim.extrude([V2(-0.05, 0), V2(0, -0.05), V2(0.05, 0), V2(0, 0.05)], depth: 0.004, bevel: 0.0005, bevelSegments: 1, material: header),
                              Xform(translation: c, rotation: yaw))
                    }
                }
                y += 0.12
                row += 1
            }
        }

        // Tonal variation: scattered over-burnt and underfired bricks, plus lime runs below the weathering course.
        let faces: [(V3, V3)] = [(V3(0, 0, 1), V3(1, 0, 0)), (V3(1, 0, 0), V3(0, 0, -1)), (V3(0, 0, -1), V3(-1, 0, 0)), (V3(-1, 0, 0), V3(0, 0, 1))]
        let tones: [MaterialKey] = ["brick.red:9C4733", "brick.red:6E2F26", "brick.red:B5663F", "brick.common"]
        for _ in 0..<46 {
            let (n3, t3) = faces[Int(rng.float(0...3.99))]
            let y = rng.float(0.08...(yCorbel - 0.06))
            if y > yWeather - 0.02 && y < ySh0 + 0.03 { continue }
            let u = rng.float(-bw / 2 + 0.12...bw / 2 - 0.12)
            let c = n3 * (bw / 2 + 0.001) + t3 * u + V3(0, y, 0)
            m.add(Prim.extrude(Shape2D.rect(0.215, 0.065), depth: 0.003, bevel: 0.0005, bevelSegments: 1, material: tones[Int(rng.float(0...3.99))]),
                  Xform(translation: c, rotation: simd_quatf(from: V3(0, 0, 1), to: n3)))
        }
        for (n3, t3) in faces {
            for _ in 0..<3 {
                let u = rng.float(-bw / 2 + 0.08...bw / 2 - 0.08), h = rng.float(0.08...0.2)
                m.add(Prim.extrude(Shape2D.rect(rng.float(0.02...0.05), h), depth: 0.002, bevel: 0.0004, bevelSegments: 1, material: "stone.limestone:E6E0D2"),
                      Xform(translation: n3 * (bw / 2 + 0.0012) + t3 * u + V3(0, yWeather - h / 2 - 0.02, 0), rotation: simd_quatf(from: V3(0, 0, 1), to: n3)))
            }
        }

        // Four corbel courses, each stepping out 0.02 m, the third a moulded roll course in dark stone.
        for k in 0..<4 {
            let w = bw + 0.04 * Float(k + 1) + (k == 3 ? 0.03 : 0)
            let y0 = yCorbel + courseH * Float(k)
            if k == 2 {
                FA.box(&m, V3(w, courseH - 0.003, w), V3(0, y0 + courseH / 2, 0), stone, r: 0.005)
            } else {
                // Chamfered brick corbel: the underside is cut back at 45 degrees.
                m.add(Prim.loft([Prim.ring(Shape2D.rect(w - 0.036, w - 0.036), y: 0), Prim.ring(Shape2D.rect(w, w), y: 0.018),
                                 Prim.ring(Shape2D.rect(w, w), y: courseH - 0.003)], capStart: true, capEnd: true, material: brick),
                      Xform(translation: V3(0, y0, 0)))
            }
            FA.box(&m, V3(w + 0.004, 0.004, w + 0.004), V3(0, y0 + courseH - 0.0015, 0), "stone.limestone", r: 0.001)
        }
        // Stone platform with a drip edge, sloped to shed water to the shafts.
        let pw = bw + 0.04 * 4 + 0.03 + 0.03
        let platTop = yPlat + 0.05
        FA.box(&m, V3(pw, 0.03, pw), V3(0, yPlat + 0.015, 0), stone, r: 0.004)
        FA.box(&m, V3(pw - 0.012, 0.004, pw - 0.012), V3(0, yPlat - 0.002, 0), darkStone, r: 0.001)
        m.add(Prim.loft([Prim.ring(Shape2D.rect(pw - 0.01, pw - 0.01), y: 0), Prim.ring(Shape2D.rect(0.74, 0.34), y: 0.02)],
                        capEnd: true, material: stone), Xform(translation: V3(0, yPlat + 0.03, 0)))

        // Twin twisted octagonal shafts with moulded caps.
        let shaftH: Float = 0.67
        for s: Float in [-1, 1] {
            let cx = s * 0.22
            let base = V3(cx, platTop, 0)
            FA.box(&m, V3(0.34, 0.03, 0.34), V3(cx, platTop + 0.0, 0), stone, r: 0.004)
            // Octagonal base plinth, then the twisting shaft: eight facets turning 135 degrees.
            var rings: [[V3]] = []
            let steps = 16
            for i in 0...steps {
                let t = Float(i) / Float(steps)
                let ang = t * 135 * .pi / 180
                let pts = Shape2D.polygon(sides: 8, radius: 0.16).map { V2($0.x * cos(ang) - $0.y * sin(ang), $0.x * sin(ang) + $0.y * cos(ang)) }
                rings.append(Prim.ring(pts, y: t * shaftH))
            }
            let split = 8   // upper shaft is soot-darkened brick
            m.add(Prim.loft(Array(rings[0...split]), capStart: false, capEnd: false, material: brick), Xform(translation: base + V3(0, 0.01, 0)))
            m.add(Prim.loft(Array(rings[split...]), capStart: false, capEnd: false, material: "brick.red:3A2822"), Xform(translation: base + V3(0, 0.01, 0)))
            let yTop = platTop + 0.01 + shaftH
            // Moulded cap: neck fillet, cove, abacus slab with drip, in sandstone.
            m.add(Prim.loft([Prim.ring(Shape2D.polygon(sides: 8, radius: 0.165), y: 0), Prim.ring(Shape2D.polygon(sides: 8, radius: 0.165), y: 0.012),
                             Prim.ring(Shape2D.polygon(sides: 8, radius: 0.19), y: 0.026), Prim.ring(Shape2D.polygon(sides: 8, radius: 0.19), y: 0.05),
                             Prim.ring(Shape2D.polygon(sides: 8, radius: 0.225), y: 0.056), Prim.ring(Shape2D.polygon(sides: 8, radius: 0.225), y: 0.08)],
                            capStart: true, capEnd: true, material: stone), Xform(translation: V3(cx, yTop, 0)))
            // Soot and a flue opening.
            m.add(Prim.loft([Prim.ring(Shape2D.polygon(sides: 8, radius: 0.12), y: 0), Prim.ring(Shape2D.polygon(sides: 8, radius: 0.12), y: 0.002)],
                            capStart: true, capEnd: true, material: "plastic.black"), Xform(translation: V3(cx, yTop + 0.0805, 0)))
            for k in 0..<5 {
                let a = rng.float(0...(2 * .pi))
                FA.box(&m, V3(0.03, 0.07, 0.004), V3(cx + cos(a) * 0.222, yTop + 0.04, sin(a) * 0.222), darkStone, r: 0.001,
                       rot: simd_quatf(angle: -a + .pi / 2, axis: FA.Y))
                _ = k
            }
        }

        // Lead flashing apron and step flashing around the base, tied back with brass-capped screws.
        FA.box(&m, V3(0.9, 0.006, 0.9), V3(0, 0.003, 0), lead, r: 0.001)
        for s: Float in [-1, 1] {
            FA.box(&m, V3(bw + 0.012, 0.15, 0.006), V3(0, 0.075, s * (bw / 2 + 0.003)), lead, r: 0.001)
            FA.box(&m, V3(0.006, 0.15, bw + 0.012), V3(s * (bw / 2 + 0.003), 0.075, 0), lead, r: 0.001)
            for i in 0..<6 {
                let x = -bw / 2 + 0.06 + Float(i) * (bw - 0.12) / 5
                FC.bead(&m, r: 0.006, at: V3(x, 0.14, s * (bw / 2 + 0.008)), "metal.brass-aged", sub: 2)
            }
        }
        // Wrought iron anchor plates with bolt heads on the upper stack.
        for s: Float in [-1, 1] {
            let y: Float = 1.1
            FA.box(&m, V3(0.12, 0.022, 0.008), V3(s * 0.15, y, bw / 2 + 0.004), "metal.wrought-iron", r: 0.002)
            FA.box(&m, V3(0.022, 0.12, 0.008), V3(s * 0.15, y, bw / 2 + 0.004), "metal.wrought-iron", r: 0.002)
            for (dx, dy) in [(Float(0.05), Float(0)), (-0.05, 0), (0, 0.05), (0, -0.05)] {
                FC.bead(&m, r: 0.008, at: V3(s * 0.15 + dx, y + dy, bw / 2 + 0.009), "metal.wrought-iron", sub: 2)
            }
        }

        groundAO(&m, height: 0.25, floor: 0.7)
        return LODModel(FC.place(m))
    }

    /// Sandstone weathering: a sloped offset with a drip, around all four sides of the stack.
    private func weathering(_ m: inout Model, at y: Float, half: Float, stone: MaterialKey) {
        m.add(Prim.loft([Prim.ring(Shape2D.rect(half * 2, half * 2), y: 0), Prim.ring(Shape2D.rect(half * 2 - 0.004, half * 2 - 0.004), y: 0.018),
                         Prim.ring(Shape2D.rect(half * 2 - 0.09, half * 2 - 0.09), y: 0.085)], capStart: true, capEnd: true, material: stone),
              Xform(translation: V3(0, y, 0)))
    }
}
