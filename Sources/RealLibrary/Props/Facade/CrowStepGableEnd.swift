import simd
import Foundation

/// Scottish Baronial crow-step gable end, 2.4 x 1.8 x 0.4 m: random sandstone rubble in four tones with dressed ashlar margins and
/// alternating corner quoins, a corbiestep coping on every tread over lead flashing, skewputts at the foot of the slope, a moulded
/// string course, a pedimented window with mullion and sill, an apex chimney stack with a moulded cap and two clay cans, iron tie
/// plates, rain streaks, lichen and soot. Base on y = 0 (the roofline).
public struct CrowStepGableEnd: RealAsset {
    public static let id = "crow-step-gable-end"
    public static let summary = "Scottish Baronial crow-step gable end, 2.4 x 1.8 m: sandstone rubble with ashlar margins, corbiestep copings, skewputts, apex stack, window, flashing."
    public static let tags = ["prop", "architecture", "facade", "roof", "stone"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 10, distance: 3.6)

    /// Overall width at the base in meters.
    public var width: Float = 2.4
    /// Wall thickness in meters.
    public var wall: Float = 0.3
    /// Rubble sandstone tones.
    public var rubble: [MaterialKey] = ["stone.sandstone", "stone.sandstone:C9B48E", "stone.sandstone:B49A74", "stone.brownstone", "stone.sandstone:D4C3A0", "stone.sandstone:9E8A6B"]
    /// Dressed ashlar for copings, quoins, margins and the window.
    public var ashlar: MaterialKey = "stone.sandstone:D8C9A6"
    public var lead: MaterialKey = "metal.galvanized-aged"
    public var iron: MaterialKey = "metal.wrought-iron"
    public var pot: MaterialKey = "ceramic.terracotta"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let hw = width / 2, T = wall, zf = T / 2
        let steps = 5, tread: Float = 0.2, rise: Float = 0.2, y0: Float = 0.4
        func stepY(_ k: Int) -> Float { y0 + Float(k) * rise }
        func stepAt(_ x: Float) -> Int { min(steps - 1, max(0, Int((hw - abs(x)) / tread))) }
        func topAt(_ x: Float) -> Float { abs(x) >= hw ? 0 : stepY(stepAt(x)) }

        // Body: crow-stepped outline extruded through the wall.
        var right: [V2] = [V2(hw, 0), V2(hw, stepY(0))]
        for k in 0..<steps {
            let x = hw - Float(k + 1) * tread
            right.append(V2(x, stepY(k)))
            if k < steps - 1 { right.append(V2(x, stepY(k + 1))) }
        }
        let outline = Shape2D.deduped(right + right.reversed().map { V2(-$0.x, $0.y) })
        m.add(Prim.extrude(outline, depth: T, bevel: 0.004, bevelSegments: 1, material: "stone.sandstone:6E6350"))

        // Rubble field on both faces, clipped to the steps, with a gap left for the quoins.
        let zc = zf + 0.002
        for s: Float in [-1, 1] {
            FO8.courses(&m, &rng, xr: (-hw + 0.01)...(hw - 0.01), yr: 0.1...(stepY(steps - 1)), course: 0.125, block: 0.3, z: s * zc, depth: 0.008,
                       mats: rubble, top: { topAt($0) - 0.012 })
        }

        // Corner quoins up the outer flank and dressed margins up every riser.
        for sx: Float in [-1, 1] {
            for k in 0..<4 {
                let long = k % 2 == 0
                let w: Float = long ? 0.24 : 0.14
                let y = 0.0 + Float(k) * 0.1
                if y + 0.1 > y0 - 0.02 { continue }
                for sz: Float in [-1, 1] {
                    FO8.slab(&m, w, 0.092, 0.018, V3(sx * (hw - w / 2), y + 0.05, sz * (zf + 0.005)), ashlar, bevel: 0.0025)
                }
            }
            for k in 1..<steps {
                let ya = stepY(k - 1) + 0.03, yb = stepY(k) - 0.02
                for sz: Float in [-1, 1] {
                    FO8.slab(&m, 0.07, yb - ya, 0.016, V3(sx * (hw - Float(k) * tread - 0.05), (ya + yb) / 2, sz * (zf + 0.0043)), ashlar, bevel: 0.0025)
                }
            }
        }

        // String course.
        let band: [V2] = [V2(0, 0), V2(0.05, 0), V2(0.05, 0.012), V2(0.042, 0.02), V2(0.042, 0.06), V2(0.05, 0.068), V2(0.05, 0.08), V2(0, 0.08)]
        FO8.runBoth(&m, band, length: width - 0.02, y: 0.3, zWall: zf, ashlar, bevel: 0.002)

        // Corbiestep copings over lead flashing; the apex coping spans the plateau.
        let cd = T + 0.06
        func coping(_ cx: Float, _ w: Float, _ y: Float) {
            m.add(Prim.loft([Prim.ring(Shape2D.rounded(Shape2D.rect(w, cd), radius: 0.004, segments: 1), y: 0),
                             Prim.ring(Shape2D.rounded(Shape2D.rect(w, cd), radius: 0.004, segments: 1), y: 0.04),
                             Prim.ring(Shape2D.rounded(Shape2D.rect(w - 0.026, cd - 0.026), radius: 0.004, segments: 1), y: 0.062)],
                            capStart: true, capEnd: true, material: ashlar),
                  Xform(translation: V3(cx, y, 0)))
        }
        for k in 0..<steps - 1 {
            let xr = hw - Float(k) * tread, xl = xr - tread
            let top = stepY(k)
            for s: Float in [-1, 1] {
                let w = tread + (k == 0 ? 0.0 : 0.03)
                let cx = s * (k == 0 ? (xr + xl) / 2 - 0.0 : (xr + xl) / 2 + 0.0)
                FA.box(&m, V3(w - 0.006, 0.006, T + 0.04), V3(cx, top + 0.003, 0), lead, r: 0.001)
                coping(cx, w, top + 0.006)
                for z: Float in [-1, 1] {
                    FA.box(&m, V3(w - 0.02, 0.026, 0.004), V3(cx, top - 0.01, z * (zf + 0.004)), lead, r: 0.001)
                }
            }
        }
        let ax = hw - Float(steps - 1) * tread
        FA.box(&m, V3(2 * ax - 0.006, 0.006, T + 0.04), V3(0, stepY(steps - 1) + 0.003, 0), lead, r: 0.001)
        coping(0, 2 * ax + 0.03, stepY(steps - 1) + 0.006)
        let roofTop = stepY(steps - 1) + 0.006 + 0.062

        // Skewputts: carved kneelers at the foot of the slope, a corbelled block under the lowest coping.
        for sx: Float in [-1, 1] {
            let prof: [V2] = [V2(-0.12, 0), V2(0.12, 0), V2(0.12, 0.09), V2(0.06, 0.09), V2(-0.02, 0.07), V2(-0.12, 0.02)]
            m.add(Prim.extrude(Shape2D.deduped(prof.map { V2($0.x * -sx, $0.y) }), depth: T + 0.07, bevel: 0.004, bevelSegments: 1, material: ashlar),
                  Xform(translation: V3(sx * (hw - 0.12), stepY(0) - 0.08, 0)))
        }

        // Apex chimney stack: rubble faces, moulded cap, mortar flaunching and two clay cans.
        let sy = roofTop
        let sw: Float = 0.36, sd: Float = 0.26
        m.add(Prim.extrude(Shape2D.rect(sw, 0.26), depth: sd, bevel: 0.003, bevelSegments: 1, material: "stone.sandstone:6E6350"),
              Xform(translation: V3(0, sy + 0.13, 0)))
        for s: Float in [-1, 1] {
            FO8.courses(&m, &rng, xr: -sw / 2...sw / 2, yr: sy...(sy + 0.26), course: 0.0867, block: 0.2, z: s * (sd / 2 + 0.002), depth: 0.008, mats: rubble, top: { _ in 99 })
        }
        let capY = sy + 0.26
        m.add(Prim.loft([Prim.ring(Shape2D.rect(sw + 0.08, sd + 0.08), y: 0), Prim.ring(Shape2D.rect(sw + 0.08, sd + 0.08), y: 0.022),
                         Prim.ring(Shape2D.rect(sw + 0.02, sd + 0.02), y: 0.04)], capStart: true, capEnd: true, material: ashlar),
              Xform(translation: V3(0, capY, 0)))
        FA.box(&m, V3(sw - 0.04, 0.012, sd - 0.04), V3(0, capY + 0.045, 0), "brick.mortar-lime", r: 0.004)
        for x: Float in [-0.09, 0.09] {
            m.add(Prim.lathe([V2(0, 0), V2(0.05, 0), V2(0.047, 0.03), V2(0.04, 0.1), V2(0.041, 0.17), V2(0.052, 0.178), V2(0.052, 0.2), V2(0.04, 0.2), V2(0.0, 0.2)],
                             segments: 16, seamTile: 0.1, material: pot), Xform(translation: V3(x, capY + 0.04, 0)))
        }

        // Window: dressed jambs, lintel and a triangular pediment, sill, dark glazing with mullion and transom.
        let wy: Float = 0.5, ww: Float = 0.3, wh: Float = 0.44
        for s: Float in [-1, 1] {
            let z = s * (zf + 0.006)
            FO8.slab(&m, ww + 0.12, wh + 0.1, 0.014, V3(0, wy + wh / 2, z), ashlar, bevel: 0.003)
            FO8.slab(&m, ww, wh, 0.01, V3(0, wy + wh / 2, s * (zf + 0.0135)), "metal.painted:1E1F20", bevel: 0.001)
            FO8.slab(&m, ww - 0.03, wh - 0.03, 0.006, V3(0, wy + wh / 2, s * (zf + 0.0175)), "glass.pane", bevel: 0.0005)
            FO8.slab(&m, 0.016, wh - 0.03, 0.01, V3(0, wy + wh / 2, s * (zf + 0.021)), "wood.painted-exterior:E8E4D8", bevel: 0.002)
            FO8.slab(&m, ww - 0.03, 0.016, 0.01, V3(0, wy + wh * 0.62, s * (zf + 0.021)), "wood.painted-exterior:E8E4D8", bevel: 0.002)
            m.add(Prim.extrude([V2(-0.11, 0), V2(0.11, 0), V2(0, 0.075)], depth: 0.03, bevel: 0.003, bevelSegments: 1, material: ashlar),
                  Xform(translation: V3(0, wy + wh + 0.05 + 0.002, s * (zf + 0.012))))
            FA.box(&m, V3(ww + 0.16, 0.026, 0.05), V3(0, wy - 0.045, s * (zf + 0.022)), ashlar, r: 0.003)
        }

        // Iron tie plates with bolts and a rust run below.
        for (x, y) in [(Float(-0.72), Float(0.55)), (0.72, 0.55), (-0.42, 0.86), (0.42, 0.86)] {
            for s: Float in [-1, 1] {
                let z = s * (zf + 0.0095)
                FO8.slab(&m, 0.2, 0.026, 0.012, V3(x, y, z), iron, bevel: 0.003)
                FO8.slab(&m, 0.026, 0.1, 0.012, V3(x, y, z), iron, bevel: 0.003)
                for (dx, dy) in [(Float(0.075), Float(0)), (-0.075, 0), (0, 0.04), (0, -0.04)] {
                    FC.bead(&m, r: 0.011, at: V3(x + dx, y + dy, z + s * 0.007), iron, sub: 2)
                }
                FO8.slab(&m, 0.02, 0.1 + rng.float(0...0.08), 0.0022, V3(x + 0.01, y - 0.12, s * (zf + 0.0105)), "stone.sandstone:6B4A33", bevel: 0.0005)
            }
        }

        // Weathering: rain streaks under every coping, lichen, soot and a damp band at the foot.
        for s: Float in [-1, 1] {
            for k in 0..<steps - 1 {
                for sx: Float in [-1, 1] {
                    let x = sx * (hw - Float(k) * tread - 0.1)
                    FO8.slab(&m, rng.float(0.02...0.04), rng.float(0.12...0.22), 0.0022, V3(x + rng.float(-0.03...0.03), stepY(k) - 0.11, s * (zf + 0.0105)),
                            "stone.sandstone:5E5240", bevel: 0.0005)
                }
            }
            FO8.slab(&m, width - 0.1, 0.05, 0.0026, V3(0, 0.145, s * (zf + 0.0106)), "stone.sandstone:6C6F4C", bevel: 0.001)
            // Plinth: dressed footing course projecting 25 mm, with a sooted drip line at the foot.
            FO8.slab(&m, width + 0.02, 0.09, 0.05, V3(0, 0.045, s * zf), ashlar, bevel: 0.004)
            FO8.slab(&m, width, 0.03, 0.054, V3(0, 0.015, s * zf), "stone.sandstone:6E6350", bevel: 0.002)
        }
        FO8.patches(&m, &rng, count: 10, xr: -1.0...1.0, yr: 0.15...0.7, w: 0.06...0.14, h: 0.04...0.09, zFace: zf + 0.0106,
                   mats: ["stone.sandstone:8E9266", "stone.sandstone:A59F7C", "stone.sandstone:B8AE8E"])

        groundAO(&m, height: 0.12, floor: 0.82)
        return LODModel(FC.place(m))
    }
}
