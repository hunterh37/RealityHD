import simd
import Foundation

/// Hall tree: entryway hall tree, 0.8 x 1.8 x 0.4 m, painted warm white with an oak seat and slats. Parts: shaker back frame with recessed panels and an
/// arched mirror, a hook rail with five double brass hooks, a top shelf on corbels under an arched crest with turned finials, a storage bench with a
/// hinged oak lid on brass butt hinges and a paneled front, a lower oak slat shoe shelf, and a galvanized drip tray. Wall mount: back at z = -depth / 2.
public struct HallTree: RealAsset {
    public static let id = "hall-tree"
    public static let summary = "Entry hall tree, 0.8 x 1.8 x 0.4 m: paneled back with coat hooks and top shelf, bench seat, lower shoe shelf and drip tray."
    public static let tags = ["prop", "floorplan", "decor", "wood", "furniture", "interior"]
    public static let budget = 14000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 32, elevation: 12, distance: 3.6, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.8, 1.8, 0.4)
    /// Painted frame and panels.
    public var paint: MaterialKey = "wood.painted-shaker:DDD4C2"
    /// Worn paint where boots and bags hit the lower frame.
    public var paintWorn: MaterialKey = "wood.painted-shaker-worn:D6CCB8"
    /// Seat lid and shoe slats.
    public var oak: MaterialKey = "wood.oak"
    /// Hooks, hinges and screws.
    public var brass: MaterialKey = "metal.brass-aged"
    /// Drip tray.
    public var tray: MaterialKey = "metal.galvanized"
    /// Mirror silvering.
    public var mirror: MaterialKey = "metal.chrome:9AA5A8"
    public init() {}

    /// Closed arch outline (counterclockwise): flat sill, straight sides, round top rising `rise` above the shoulders.
    private func arch(_ w: Float, _ h: Float, _ rise: Float, _ n: Int) -> [V2] {
        var pts: [V2] = [V2(-w / 2, 0), V2(w / 2, 0)]
        let sh = h - rise
        for k in 0...n {
            let a = Float(k) / Float(n) * .pi
            pts.append(V2(w / 2 * cos(a), sh + rise * sin(a)))
        }
        return pts
    }

    public func build(seed: UInt64) -> LODModel {
        func make(_ hi: Bool) -> Model {
            var rng = SeededRNG(seed: seed)
            var m = Model(name: Self.id)
            let W = size.x, D = size.z
            let zb = -D / 2, zf = D / 2
            let bv = 1
            func box(_ sz: V3, _ c: V3, _ key: MaterialKey, r: Float = 0.0025, jitter: Bool = false) {
                var x = Xform(translation: c)
                if jitter { x = x.jittered(&rng) }
                m.add(Prim.roundedBox(sz, radius: min(r, sz.x / 2.1, sz.y / 2.1, sz.z / 2.1), bevelSegments: bv, material: key), x)
            }
            // ---- Back frame: stiles to the floor, a recessed panel board, rails in front of it.
            let stileW: Float = 0.07, backT: Float = 0.03
            let bz = zb + backT / 2
            for s: Float in [-1, 1] {
                box(V3(stileW, 0.47, backT), V3(s * (W / 2 - stileW / 2), 0.235, bz), paintWorn)
                box(V3(stileW, 1.15, backT), V3(s * (W / 2 - stileW / 2), 0.47 + 0.575, bz), paint)
            }
            let innerW = W - 2 * stileW
            box(V3(innerW + 0.01, 1.58, 0.012), V3(0, 0.8, zb + 0.006 + 0.0005), paint, r: 0.001)
            // Rails: lower (above the seat), hook rail, mirror sill, top rail.
            box(V3(innerW, 0.075, backT), V3(0, 0.515, bz), paint)
            let hookRailY: Float = 1.2
            box(V3(innerW, 0.13, backT + 0.014), V3(0, hookRailY, bz + 0.007), paint, r: 0.004)
            // Beaded edge on the hook rail.
            box(V3(innerW, 0.006, 0.006), V3(0, hookRailY + 0.065, zb + backT + 0.014 - 0.002), paint, r: 0.0025)
            box(V3(innerW, 0.006, 0.006), V3(0, hookRailY - 0.065, zb + backT + 0.014 - 0.002), paint, r: 0.0025)
            box(V3(innerW, 0.04, backT), V3(0, 1.61, bz), paint)
            // Center muntin and recessed panel frames between the lower rail and the hook rail.
            box(V3(0.05, 0.545, backT), V3(0, 0.8225, bz), paint)
            for s: Float in [-1, 1] {
                let cx = s * (innerW / 4 + 0.0125)
                let pw = innerW / 2 - 0.05 / 2 - 0.02
                // Raised molding frame around the recess (four thin strips).
                let ph: Float = 0.49, py: Float = 0.8225
                let mt: Float = 0.014, mz = zb + 0.012 + mt / 2
                box(V3(pw, mt, mt), V3(cx, py + ph / 2 - mt / 2, mz + 0.004), paint, r: 0.002)
                box(V3(pw, mt, mt), V3(cx, py - ph / 2 + mt / 2, mz + 0.004), paint, r: 0.002)
                box(V3(mt, ph, mt), V3(cx - pw / 2 + mt / 2, py, mz + 0.004), paint, r: 0.002)
                box(V3(mt, ph, mt), V3(cx + pw / 2 - mt / 2, py, mz + 0.004), paint, r: 0.002)
            }
            // ---- Mirror: arched glass in a painted arched frame above the hook rail.
            let mw: Float = 0.46, mh: Float = 0.24, my: Float = 1.315
            let frameO = arch(mw + 0.07, mh + 0.07, 0.2, hi ? 16 : 8)
            m.add(Prim.extrude(Shape2D.rounded(frameO, radius: 0.004, segments: 2), depth: 0.016, bevel: 0.004, bevelSegments: bv, material: paint),
                  Xform(translation: V3(0, my - 0.03, zb + backT / 2 + 0.002)))
            m.add(Prim.extrude(Shape2D.rounded(arch(mw, mh, 0.15, hi ? 16 : 8), radius: 0.003, segments: 2), depth: 0.006, bevel: 0.0045, bevelSegments: bv, material: mirror),
                  Xform(translation: V3(0, my, zb + backT / 2 + 0.0105)))
            // ---- Top shelf on corbels, arched crest above, finials on the shelf ends.
            let shY: Float = 1.645
            let shDepth: Float = 0.15
            box(V3(W, 0.032, shDepth), V3(0, shY, zb + shDepth / 2), paint, r: 0.006)
            box(V3(W, 0.008, 0.008), V3(0, shY - 0.014, zb + shDepth - 0.004), paint, r: 0.003)
            for s: Float in [-1, 1] {
                let corbel = Shape2D.rounded([V2(0, 0), V2(0.1, 0), V2(0.1, 0.012), V2(0.02, 0.07), V2(0, 0.07)], radius: 0.004, segments: 2)
                m.add(Prim.extrude(corbel, depth: 0.028, bevel: 0.003, bevelSegments: bv, material: paint),
                      Xform(translation: V3(s * 0.33, shY - 0.016 - 0.07, zb + 0.0), rotation: simd_quatf(angle: -.pi / 2, axis: .up)))
            }
            // Crest board: arched top, up to y = 1.8.
            let crest: [V2] = {
                var p: [V2] = [V2(-W / 2, 0), V2(W / 2, 0), V2(W / 2, 0.04)]
                let n = hi ? 18 : 8
                for k in 0...n {
                    let t = Float(k) / Float(n)
                    let x = (W / 2) * (1 - 2 * t)
                    let ax = abs(x) / (W / 2)
                    p.append(V2(x, 0.04 + 0.1 * (1 - ax * ax) * (1 - 0.15 * ax)))
                }
                p.append(V2(-W / 2, 0.04))
                return p
            }()
            m.add(Prim.extrude(Shape2D.rounded(crest, radius: 0.004, segments: 2), depth: 0.026, bevel: 0.004, bevelSegments: bv, material: paint),
                  Xform(translation: V3(0, shY + 0.016 + 0.0, zb + 0.013)))
            for s: Float in [-1, 1] {
                let base = shY + 0.016
                let prof: [(Float, Float)] = [(0, 0), (0.016, 0), (0.016, 0.006), (0.011, 0.012), (0.008, 0.02), (0.0085, 0.032), (0.016, 0.044), (0.019, 0.056), (0.015, 0.068),
                                              (0.007, 0.078), (0.004, 0.092), (0.0025, 0.104), (0, 1.8 - base)]
                m.add(turned(prof, segments: hi ? 20 : 10, material: paint, seamTile: 0.1), Xform(translation: V3(s * 0.385, base, zb + 0.065)))
            }
            // ---- Hooks: five double brass hooks on the hook rail.
            let hookFace = zb + backT + 0.014
            for k in 0..<5 {
                let hx = (Float(k) - 2) * 0.13
                box(V3(0.02, 0.062, 0.006), V3(hx, hookRailY, hookFace + 0.002), brass, r: 0.0025)
                let big = catmull([V3(hx, hookRailY - 0.004, hookFace + 0.004), V3(hx, hookRailY - 0.004, hookFace + 0.035), V3(hx, hookRailY + 0.004, hookFace + 0.062),
                                   V3(hx, hookRailY + 0.03, hookFace + 0.07)], per: 3)
                m.add(Prim.tube(big, radii: big.map { _ in 0.0042 }, sides: hi ? 8 : 5, seamTile: 0.02, material: brass, capEnd: true))
                m.add(Prim.superellipsoid(V3(0.014, 0.014, 0.014), exponent: 2, subdivisions: hi ? 2 : 1, material: brass), Xform(translation: big.last! + V3(0, 0.003, 0)))
                let small = catmull([V3(hx, hookRailY - 0.02, hookFace + 0.004), V3(hx, hookRailY - 0.02, hookFace + 0.022), V3(hx, hookRailY - 0.012, hookFace + 0.04)], per: 3)
                m.add(Prim.tube(small, radii: small.map { _ in 0.0036 }, sides: hi ? 8 : 5, seamTile: 0.02, material: brass, capEnd: true))
                m.add(Prim.superellipsoid(V3(0.011, 0.011, 0.011), exponent: 2, subdivisions: hi ? 2 : 1, material: brass), Xform(translation: small.last! + V3(0, 0.002, 0)))
            }
            // ---- Bench: side panels to the floor, slatted oak shoe shelf, paneled chest front, hinged oak lid.
            let benchTop: Float = 0.43
            let sideZ0 = zb + backT, sideZ1: Float = zf - 0.02
            let sideD = sideZ1 - sideZ0
            for s: Float in [-1, 1] {
                // Side panel with a rounded toe cut: two boxes (upper chest side, lower legs).
                box(V3(0.022, benchTop, sideD), V3(s * (W / 2 - 0.011), benchTop / 2, sideZ0 + sideD / 2), paintWorn, r: 0.003)
            }
            // Kick rail at the back of the cubby and a rear toe strip.
            box(V3(W - 0.044, 0.07, 0.016), V3(0, 0.05, zb + backT + 0.008), paintWorn, r: 0.002)
            // Shoe shelf: seven oak slats along Z.
            let shelfY: Float = 0.105
            let slatW: Float = 0.0965, gap: Float = 0.0105
            for k in 0..<7 {
                let sx = (Float(k) - 3) * (slatW + gap)
                m.add(Prim.roundedBox(V3(slatW, 0.02, sideD - 0.02), radius: 0.003, bevelSegments: bv, material: oak),
                      Xform(translation: V3(sx, shelfY, sideZ0 + sideD / 2 + 0.01)).jittered(&rng))
            }
            for zc in [sideZ0 + 0.05, sideZ1 - 0.07] {
                box(V3(W - 0.044, 0.02, 0.026), V3(0, shelfY - 0.018, zc), paintWorn, r: 0.002)
            }
            // Chest: bottom board, back wall, front frame with recessed panel.
            let chestB: Float = 0.27
            box(V3(W - 0.044, 0.016, sideD), V3(0, chestB + 0.008, sideZ0 + sideD / 2), paint, r: 0.002)
            let fz = sideZ1 - 0.011
            let fh = benchTop - chestB
            box(V3(W - 0.044, 0.04, 0.022), V3(0, chestB + 0.02, fz), paint, r: 0.003)
            box(V3(W - 0.044, 0.036, 0.022), V3(0, benchTop - 0.018, fz), paint, r: 0.003)
            for s: Float in [-1, 1] {
                box(V3(0.05, fh, 0.022), V3(s * (W / 2 - 0.022 - 0.025), chestB + fh / 2, fz), paint, r: 0.003)
            }
            box(V3(W - 0.044 - 0.1, fh - 0.076, 0.01), V3(0, chestB + fh / 2, fz - 0.006), paint, r: 0.0015)
            let pm: Float = 0.007
            box(V3(W - 0.044 - 0.1 - 0.02, pm, pm), V3(0, chestB + 0.04 + 0.0, fz + 0.002), paint, r: 0.002)
            box(V3(W - 0.044 - 0.1 - 0.02, pm, pm), V3(0, benchTop - 0.036 - 0.0, fz + 0.002), paint, r: 0.002)
            // Lid: oak plank, rounded edges, overhanging the front by 2 cm.
            let lidT: Float = 0.036
            let lidZ0 = zb + backT + 0.002, lidZ1 = zf
            m.add(Prim.roundedBox(V3(W, lidT, lidZ1 - lidZ0), radius: 0.007, bevelSegments: hi ? 3 : 2, material: oak),
                  Xform(translation: V3(0, benchTop + lidT / 2 + 0.001, (lidZ0 + lidZ1) / 2)))
            // Butt hinges at the back edge: knuckle, two leaves, screws.
            for hx: Float in [-0.27, 0.27] {
                let hy = benchTop + lidT + 0.001
                m.add(Prim.cylinder(radius: 0.0048, height: 0.06, bevel: 0.0008, segments: hi ? 10 : 6, material: brass),
                      Xform(translation: V3(hx - 0.03, hy + 0.0016, lidZ0 + 0.004), rotation: simd_quatf(degrees: -90, axis: V3(0, 0, 1))))
                box(V3(0.06, 0.0016, 0.028), V3(hx, hy + 0.0008, lidZ0 + 0.019), brass, r: 0.0006)
                box(V3(0.06, 0.028, 0.0016), V3(hx, hy - 0.014, lidZ0 - 0.0), brass, r: 0.0006)
                for dx: Float in [-0.02, 0.02] {
                    m.add(Prim.cylinder(radius: 0.0026, height: 0.0014, bevel: 0.0004, segments: 8, material: brass), Xform(translation: V3(hx + dx, hy + 0.0016, lidZ0 + 0.022)))
                }
            }
            // Pull cleats: brass bin pull on the chest front.
            m.add(barHandle(length: 0.1, standoff: 0.018, radius: 0.0035, material: brass),
                  Xform(translation: V3(0, chestB + fh * 0.5, fz + 0.011), rotation: simd_quatf(degrees: 0, axis: .up)))
            // ---- Drip tray: galvanized boot and umbrella tray on the shoe shelf, right side.
            let tx: Float = 0.17, ty = shelfY + 0.01, tz = sideZ0 + sideD / 2 + 0.01
            let tw: Float = 0.32, td: Float = 0.22, th: Float = 0.032, tt: Float = 0.0022
            box(V3(tw, tt, td), V3(tx, ty + tt / 2, tz), tray, r: 0.0008)
            for s: Float in [-1, 1] {
                box(V3(tw, th, tt), V3(tx, ty + th / 2, tz + s * (td / 2 - tt / 2)), tray, r: 0.0008)
                box(V3(tt, th, td), V3(tx + s * (tw / 2 - tt / 2), ty + th / 2, tz), tray, r: 0.0008)
                m.add(Prim.cylinder(radius: 0.0035, height: tw, bevel: 0.0006, segments: 8, material: tray),
                      Xform(translation: V3(tx - tw / 2, ty + th, tz + s * (td / 2 - tt / 2)), rotation: simd_quatf(degrees: -90, axis: V3(0, 0, 1))))
            }
            // Boot-tray ribs.
            for k in 0..<5 {
                box(V3(0.008, 0.007, td - 0.03), V3(tx - 0.12 + Float(k) * 0.06, ty + tt + 0.0035, tz), tray, r: 0.001)
            }
            // ---- Planted: lowest point y = 0, back plane at z = -depth / 2, centered in X.
            let bb = m.bounds
            m = m.transformed(Xform(translation: V3(-(bb.min.x + bb.max.x) / 2, -bb.min.y, 0)))
            groundAO(&m, height: 0.12, floor: 0.6)
            return m
        }
        return LODModel(levels: [make(true), make(false)], switchDistances: [5])
    }
}
