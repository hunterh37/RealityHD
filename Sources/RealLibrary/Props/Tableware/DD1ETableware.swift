import simd
import Foundation

/// Shared turned-ceramic builders for plates, bowls, cups and saucers.
enum DD1ETableware {
    /// Closed lathe profile of a plate or coupe: underside centre, foot, edge roll, rim top, cove, well, centre.
    static func plate(diameter D: Float, height H: Float, wellRadius wr: Float, wellY wy: Float,
                      rimWidth: Float, thickness t: Float = 0.0045, edgeRadius er: Float = 0.0024) -> [V2] {
        let R = D / 2, rimIn = R - rimWidth
        var p: [V2] = [V2(0, 0.0032), V2(wr * 0.7, 0.0026), V2(wr - 0.004, 0.0024), V2(wr - 0.0025, 0.0006),
                       V2(wr - 0.0012, 0), V2(wr + 0.0012, 0), V2(wr + 0.0028, 0.0008),
                       V2(wr + 0.008, wy - t + 0.0012)]
        for k in 1...6 {
            let f = Float(k) / 6
            p.append(V2(wr + 0.008 + (rimIn - wr - 0.004) * f, wy - t + 0.0012 + (H - wy - 0.0018) * (1 - pow(1 - f, 2))))
        }
        p.append(V2(R - 0.008, H - t + 0.0005))
        p.append(V2(R - er, H - 2 * er + 0.0002))
        let ec = V2(R - er, H - er)
        for k in 1...7 {
            let a = -Float.pi / 2 + Float(k) / 8 * .pi
            p.append(ec + V2(er * cos(a), er * sin(a)))
        }
        p.append(V2(R - er, H))
        p.append(V2(R - 0.008, H - 0.0004))
        p.append(V2(rimIn + 0.004, H - 0.0012))
        for k in 1...8 {
            let f = Float(k) / 8
            let x = rimIn + 0.004 - (rimIn + 0.004 - wr) * f
            let y = (H - 0.0012) - (H - 0.0012 - wy) * (0.5 - 0.5 * cos(f * .pi))
            p.append(V2(x, y))
        }
        p.append(V2(wr * 0.6, wy)); p.append(V2(wr * 0.25, wy)); p.append(V2(0, wy))
        return p
    }

    /// Thin closed ring (r0...r1) resting on a flat at y, for stains and scuffs.
    static func annulus(_ r0: Float, _ r1: Float, y: Float, thick: Float = 0.0003) -> [V2] {
        [V2(r0, y - 0.0001), V2(r1, y - 0.0001), V2(r1, y + thick), V2(r0, y + thick), V2(r0, y - 0.0001)]
    }

    /// Thin band on the sloped flat rim of a plate from radius r0 to r1.
    static func rimBand(diameter D: Float, height H: Float, rimWidth: Float, _ r0: Float, _ r1: Float, thick: Float = 0.0003) -> [V2] {
        let R = D / 2, ra = R - 0.008, rb = R - rimWidth + 0.004
        func s(_ r: Float) -> Float { (H - 0.0004) + (-0.0008) * (ra - r) / (ra - rb) }
        return [V2(r0, s(r0) - 0.0001), V2(r1, s(r1) - 0.0001), V2(r1, s(r1) + thick), V2(r0, s(r0) + thick), V2(r0, s(r0) - 0.0001)]
    }

    /// Unglazed contact ring under a foot of radius r.
    static func footRing(_ r: Float) -> [V2] {
        [V2(r - 0.0013, -0.00005), V2(r + 0.0013, -0.00005), V2(r + 0.0013, 0.0002), V2(r - 0.0013, 0.0002), V2(r - 0.0013, -0.00005)]
    }

    /// Curved bowl: quarter-ellipse wall from the foot to a vertical rolled lip, constant wall thickness.
    struct Bowl {
        var D: Float, H: Float, footR: Float
        var footH: Float = 0.004
        var wall: Float = 0.0045
        var R: Float { D / 2 }
        var r0: Float { footR + 0.003 }
        var yTop: Float { H - wall / 2 }
        func outer(_ th: Float) -> V2 { V2(r0 + (R - r0) * sin(th), footH + (yTop - footH) * (1 - cos(th))) }
        func normal(_ th: Float) -> V2 {
            let d = V2((R - r0) * cos(th), (yTop - footH) * sin(th))
            return V2(d.y, -d.x) / max(simd_length(d), 1e-6)
        }
        func inner(_ th: Float) -> V2 { outer(th) - normal(th) * wall }
        /// Wall angle whose inner surface is at height y.
        func theta(innerY y: Float) -> Float {
            var best: Float = 0, bd: Float = .infinity
            for k in 0...200 { let th = Float(k) / 200 * .pi / 2; let d = abs(inner(th).y - y); if d < bd { bd = d; best = th } }
            return best
        }
        /// Outer radius at height y.
        func outerRadius(at y: Float) -> Float {
            var best: Float = r0, bd: Float = .infinity
            for k in 0...200 { let th = Float(k) / 200 * .pi / 2; let o = outer(th); let d = abs(o.y - y); if d < bd { bd = d; best = o.x } }
            return best
        }
        func profile(steps: Int = 14) -> [V2] {
            let fr = footR
            var p: [V2] = [V2(0, footH + 0.0012), V2(fr - 0.004, footH + 0.0012), V2(fr - 0.003, 0.0006),
                           V2(fr - 0.0013, 0), V2(fr + 0.0013, 0), V2(fr + 0.003, 0.0006)]
            for k in 0...steps { p.append(outer(Float(k) / Float(steps) * .pi / 2)) }
            let c = V2(R - wall / 2, yTop)
            for k in 1...7 { let a = Float(k) / 8 * .pi; p.append(c + V2(wall / 2 * cos(a), wall / 2 * sin(a))) }
            for k in stride(from: steps, through: 0, by: -1) { p.append(inner(Float(k) / Float(steps) * .pi / 2)) }
            p.append(V2(r0 * 0.5, footH + wall)); p.append(V2(0, footH + wall))
            return p
        }
        /// Thin closed band hugging the inner wall between wall angles a and b.
        func innerBand(_ a: Float, _ b: Float, thick: Float = 0.0003, steps: Int = 3) -> [V2] {
            var top: [V2] = [], bot: [V2] = []
            for k in 0...steps {
                let th = a + (b - a) * Float(k) / Float(steps), n = normal(th), s = outer(th) - n * wall
                bot.append(s + n * 0.00005); top.append(s - n * thick)
            }
            let q = bot + top.reversed()
            return q + [q[0]]
        }
    }

    static func lathe(_ p: [V2], _ mat: MaterialKey, segments: Int = 64) -> Surface {
        Prim.lathe(p, segments: segments, seamTile: 0.3, material: mat)
    }

    /// Drops the model onto y = 0 and bakes contact AO.
    static func finish(_ m: inout Model, aoHeight: Float = 0.012) {
        let b = m.bounds
        m = m.transformed(Xform(translation: V3(0, -b.min.y, 0)))
        groundAO(&m, height: aoHeight, floor: 0.7)
    }
}
