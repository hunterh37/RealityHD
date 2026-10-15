import simd
import Foundation

/// Entry door set with sidelight, 1.35 m x 2.25 m overall: 860 x 2120 x 45 mm six-panel raised-panel slab in navy paint
/// (lock rail at handle height), a 280 mm frosted sidelight with a raised lower panel and glazing beads, brick-mould
/// casing and a head cap on both faces, split jamb, mullion, three brass butt hinges, brass lever on roses, a deadbolt
/// (keyed cylinder outside, thumbturn inside), brass kick plate and an oak sill with a brass strip. Origin at the bottom
/// center of the opening, hinge on -X, the leaf swings in toward +Z, sidelight on +X.
public struct FrontDoor: RealArticulated {
    public static let id = "front-door"
    public static let summary = "Six-panel entry door with a frosted sidelight: painted navy raised-panel slab, brick mould casing, brass handle, deadbolt, kick plate, sill."
    public static let tags = ["structure", "floorplan", "home", "wood", "glass", "metal", "interior", "door", "articulated"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 6, distance: 1.45, studio: true)

    /// Overall width, height and depth including casing (m); the planner reads the width and height.
    public var width: Float = 1.35
    public var height: Float = 2.25
    public var depth: Float = 0.2
    public var leafWidth: Float = 0.86
    public var leafThickness: Float = 0.045
    /// Slab paint (tint with :RRGGBB).
    public var slabPaint: MaterialKey = "wood.painted-shaker-worn:1F3A4A"
    public var trimPaint: MaterialKey = "wood.painted-shaker:D9D4C7"
    public var sidelightGlass: MaterialKey = "glass.frosted"
    public var hardware: MaterialKey = "metal.brass-aged"
    /// Lever height above the floor (m).
    public var handleHeight: Float = 0.93
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [8])
        let T = leafThickness
        var c = DoorKit.Casing(openW: 0, openH: 0, wallT: depth - 0.045, material: trimPaint)
        c.casingW = 0.07; c.casingT = 0.02; c.capOver = 0.01; c.capH = 0.02
        c.openW = width - 2 * (c.reveal + c.casingW + c.capOver)
        c.openH = height - c.reveal - c.casingW - c.capH
        let gap: Float = 0.004, sill: Float = 0.022
        let W = leafWidth
        let xl = -c.openW / 2 + gap                   // leaf hinge edge
        let xr = xl + W                              // leaf free edge
        let cx = (xl + xr) / 2
        let yb = sill + 0.003, yt = c.openH - 0.008, H = yt - yb
        let leafY = (yb + yt) / 2
        let zb: Float = -0.025, zf = zb + T, zMid = (zb + zf) / 2
        c.stopZ = zb - 0.003
        let hingeX = -c.openW / 2 + 0.0004
        let ss = hardware

        for l in 0..<2 {
            var m = Model(name: Self.id)
            c.build(&m, detail: l == 0)
            rig.base[l] = m
        }
        // Sill: oak threshold with a brass weatherstrip.
        let th = DoorKit.box(V3(c.openW, sill - 0.006, c.wallT + 0.03), V3(0, (sill - 0.006) / 2, 0), "wood.oak", r: 0.003)
        let strip = DoorKit.box(V3(c.openW - 0.004, 0.006, 0.06), V3(0, sill - 0.003, zb + T / 2 + 0.01), ss, r: 0.0015)
        for l in 0..<2 { rig.base[l].add(th.0, th.1); rig.base[l].add(strip.0, strip.1) }

        // Mullion between the leaf and the sidelight, then the sidelight frame and glass.
        let mx0 = xr + gap, mw: Float = 0.04
        let sx0 = mx0 + mw, sx1 = c.openW / 2
        func addBase(_ p: DoorKit.Piece, detail: Bool = false) {
            rig.base[0].add(p.0, p.1); if !detail { rig.base[1].add(p.0, p.1) }
        }
        addBase(DoorKit.vbox(V3(mw, c.openH - sill, c.wallT), V3(mx0 + mw / 2, (c.openH + sill) / 2, 0), trimPaint, r: 0.002))
        let sw = sx1 - sx0, sst: Float = 0.04
        let sT: Float = 0.04, sz = zMid
        for sxn: Float in [0, 1] {
            addBase(DoorKit.vbox(V3(sst, yt - yb, sT), V3(sxn == 0 ? sx0 + sst / 2 : sx1 - sst / 2, leafY, sz), slabPaint, r: 0.0025))
        }
        let inner = sw - 2 * sst + 0.004
        addBase(DoorKit.box(V3(inner, 0.08, sT), V3((sx0 + sx1) / 2, yt - 0.04, sz), slabPaint, r: 0.0025))
        addBase(DoorKit.box(V3(inner, 0.14, sT), V3((sx0 + sx1) / 2, yb + 0.07, sz), slabPaint, r: 0.0025))
        addBase(DoorKit.box(V3(inner, 0.08, sT), V3((sx0 + sx1) / 2, yb + 0.55, sz), slabPaint, r: 0.0025))
        DoorKit.addBase(&rig, DoorKit.panelPieces(x0: sx0 + sst, x1: sx1 - sst, y0: yb + 0.14, y1: yb + 0.51, zc: sz, mat: slabPaint, raised: true, beadRadius: 0, raisedSeg: 1))
        let gy0 = yb + 0.59, gy1 = yt - 0.08
        addBase(DoorKit.box(V3(sw - 2 * sst + 0.004, gy1 - gy0 + 0.004, 0.006), V3((sx0 + sx1) / 2, (gy0 + gy1) / 2, sz), sidelightGlass, r: 0))
        // Glazing beads on both faces.
        for side: Float in [-1, 1] {
            let bz = sz + side * 0.011
            for (size, ctr) in [(V3(sw - 2 * sst, 0.018, 0.012), V3((sx0 + sx1) / 2, gy0 + 0.009, bz)),
                                (V3(sw - 2 * sst, 0.018, 0.012), V3((sx0 + sx1) / 2, gy1 - 0.009, bz)),
                                (V3(0.018, gy1 - gy0 - 0.036, 0.012), V3(sx0 + sst + 0.009, (gy0 + gy1) / 2, bz)),
                                (V3(0.018, gy1 - gy0 - 0.036, 0.012), V3(sx1 - sst - 0.009, (gy0 + gy1) / 2, bz))] {
                addBase(DoorKit.box(size, ctr, slabPaint, r: 0), detail: true)
            }
        }

        // Leaf.
        rig.part("leaf", pivot: V3(hingeX, 0, zf - 0.002), joint: .hinge(axis: V3(0, -1, 0), 0...100, duration: 1.5))
        let stile: Float = 0.125, top: Float = 0.14, bottom: Float = 0.22
        for sxn: Float in [-1, 1] {
            let s = DoorKit.vbox(V3(stile, H, T), V3(cx + sxn * (W / 2 - stile / 2), leafY, zMid), slabPaint, r: 0.0032)
            rig.add(s.0, s.1, to: "leaf")
        }
        let mid = DoorKit.vbox(V3(stile * 0.8, H - top - bottom + 0.004, T - 0.002), V3(cx, (yb + bottom + yt - top) / 2, zMid), slabPaint, r: 0.003)
        rig.add(mid.0, mid.1, to: "leaf")
        let railW = W - 2 * stile + 0.004
        // Rails: bottom, lock rail (centered on the handle), mid rail, top.
        let lockY0 = handleHeight - 0.065, lockY1 = handleHeight + 0.135
        let midY0: Float = 1.50, midY1: Float = 1.64
        for (y0, y1) in [(yb, yb + bottom), (lockY0, lockY1), (midY0, midY1), (yt - top, yt)] {
            let r = DoorKit.box(V3(railW, y1 - y0, T), V3(cx, (y0 + y1) / 2, zMid), slabPaint, r: 0.0032)
            rig.add(r.0, r.1, to: "leaf")
        }
        let px0 = xl + stile, px1 = xr - stile
        let rows: [(Float, Float)] = [(yb + bottom, lockY0), (lockY1, midY0), (midY1, yt - top)]
        for (a, b) in [(px0, cx - stile * 0.4), (cx + stile * 0.4, px1)] {
            for (y0, y1) in rows {
                DoorKit.panel(&rig, to: "leaf", x0: a, x1: b, y0: y0, y1: y1, zc: zMid, T: T, mat: slabPaint, raised: true, beadRadius: 0, raisedSeg: 1)
            }
        }
        // Brass kick plate, both faces, and a scuff on the plate side.
        for side: Float in [-1, 1] {
            let kp = DoorKit.box(V3(W - 0.12, 0.14, 0.002), V3(cx, yb + 0.1, side > 0 ? zf + 0.001 : zb - 0.001), ss, r: 0.001)
            rig.add(kp.0, kp.1, to: "leaf")
            let screwY = yb + 0.12
            for dx: Float in [-1, 1] {
                rig.add(Prim.cylinder(radius: 0.0035, height: 0.0015, bevel: 0.0007, segments: 8, bevelSegments: 1, material: ss),
                        Xform(translation: V3(cx + dx * (W / 2 - 0.07), screwY + 0.07, side > 0 ? zf + 0.002 : zb - 0.002), rotation: facing(V3(0, 0, side))), to: "leaf", lods: 0...0)
            }
        }

        // Story detail: boot scuffs on the kick plate and the paint below it.
        for (dx, dy, w) in [(Float(-0.12), Float(0.05), Float(0.1)), (Float(0.1), Float(0.1), Float(0.07))] {
            let sc = DoorKit.box(V3(w, 0.02, 0.0006), V3(cx + dx, yb + dy, zf + 0.0023), "decal.rubber-scuff", r: 0)
            rig.add(sc.0, sc.1, to: "leaf", lods: 0...0)
        }
        // Hardware: brass hinges, lever, deadbolt.
        DoorKit.hinges(&rig, leaf: "leaf", side: -1, pinX: hingeX, pinZ: zf - 0.002, ys: [0.3, 1.13, 1.96], length: 0.1, knuckle: 0.0065, plate: 0.03, mat: ss)
        DoorKit.lever(&rig, leaf: "leaf", hingeSide: -1, edgeX: xr, y: handleHeight, zFront: zf, zBack: zb, mat: ss, strikeX: xr + gap + 0.0005)
        let hx = xr - 0.06, dy = handleHeight + 0.125
        for side: Float in [1, -1] {
            let face = side > 0 ? zf : zb
            let n = V3(0, 0, side)
            let rose = Prim.lathe([V2(0, 0), V2(0.032, 0), V2(0.032, 0.004), V2(0.029, 0.009), V2(0.02, 0.0135), V2(0, 0.0135)], segments: 24, seamTile: 0.05, material: ss)
            rig.add(rose, Xform(translation: V3(hx, dy, face), rotation: facing(n)), to: "leaf")
            if side < 0 {
                rig.add(Prim.cylinder(radius: 0.012, height: 0.004, bevel: 0.001, segments: 18, bevelSegments: 1, material: "metal.brushed-nickel"),
                        Xform(translation: V3(hx, dy, face - 0.0135), rotation: facing(n)), to: "leaf", lods: 0...0)
                rig.add(Prim.roundedBox(V3(0.0026, 0.011, 0.002), radius: 0.0008, bevelSegments: 1, material: "plastic.black"),
                        Xform(translation: V3(hx, dy, face - 0.0175)), to: "leaf", lods: 0...0)
            } else {
                // Thumbturn: flat paddle on a short neck.
                rig.add(Prim.cylinder(radius: 0.007, height: 0.013, bevel: 0.001, segments: 14, bevelSegments: 1, material: ss),
                        Xform(translation: V3(hx, dy, face + 0.0135), rotation: facing(n)), to: "leaf", lods: 0...0)
                rig.add(Prim.roundedBox(V3(0.034, 0.014, 0.008), radius: 0.003, bevelSegments: 1, material: ss),
                        Xform(translation: V3(hx, dy, face + 0.0255)), to: "leaf")
            }
        }

        groundAO(&rig, height: 0.15, floor: 0.6)
        rig.states = [RigState("closed"), RigState("ajar", ["leaf": 25]), RigState("open", ["leaf": 90]),
                      RigState("unlatched", ["handle": -40])]
        return rig
    }
}
