import simd
import Foundation

/// Pocket door in a cased opening, 0.94 m x 2.1 m overall: painted two-panel slab (790 x 2000 x 35 mm) that slides along -X into
/// the wall, flush oval pulls on both faces, an edge pull on the leading edge, flat casing with bead, back band and head cap on
/// both wall faces, a right jamb with stop and strike, no jamb on the pocket side, and a nylon floor guide. Origin at the bottom
/// center of the opening; the slab slides 0.8 m toward -X.
public struct PocketDoor: RealArticulated {
    public static let id = "pocket-door"
    public static let summary = "Pocket door in a cased opening: painted two-panel slab that slides left into the wall, flush pulls, edge pull, head casing, floor guide."
    public static let tags = ["structure", "floorplan", "home", "wood", "metal", "interior", "door", "articulated"]
    public static let budget = 6000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 6, distance: 1.2, studio: true)

    public var width: Float = 0.94
    public var height: Float = 2.1
    public var depth: Float = 0.15
    public var leafThickness: Float = 0.035
    public var paint: MaterialKey = "wood.painted-shaker:D6CFC0"
    public var slabPaint: MaterialKey = "wood.painted-shaker-worn:D6CFC0"
    public var hardware: MaterialKey = "metal.brushed-nickel"
    /// Slide travel into the wall (m).
    public var travel: Float = 0.8
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [8])
        let T = leafThickness
        var c = DoorKit.Casing(openW: 0, openH: 0, wallT: depth - 0.041, material: paint)
        c.leftJamb = false
        c.openW = width - 2 * (c.reveal + c.casingW + c.capOver)
        c.openH = height - c.reveal - c.casingW - c.capH
        let gap: Float = 0.004, undercut: Float = 0.015
        let W = c.openW - 2 * gap
        let H = c.openH - undercut - 0.008
        let leafY = undercut + H / 2
        let zMid: Float = 0.0, zf = zMid + T / 2, zb = zMid - T / 2
        c.stopZ = zb - 0.003
        for l in 0..<2 {
            var m = Model(name: Self.id)
            c.build(&m, detail: l == 0)
            rig.base[l] = m
        }
        // Floor guide at the pocket mouth and the strike plate on the right jamb.
        for l in 0..<2 {
            rig.base[l].add(Prim.roundedBox(V3(0.012, 0.016, 0.024), radius: 0.002, bevelSegments: 1, material: "plastic.black"),
                            Xform(translation: V3(-W / 2 + 0.02, 0.008, 0)))
            rig.base[l].add(Prim.roundedBox(V3(0.002, 0.11, 0.024), radius: 0.0008, bevelSegments: 1, material: hardware),
                            Xform(translation: V3(c.openW / 2 + 0.0005, 0.95, 0)))
        }

        rig.part("leaf", pivot: V3(0, 1, zMid), joint: .slide(axis: V3(-1, 0, 0), 0...travel, duration: 1.4))
        let stile: Float = 0.115, top: Float = 0.12, bottom: Float = 0.2
        let yb = undercut, yt = undercut + H
        for sx: Float in [-1, 1] {
            let s = DoorKit.vbox(V3(stile, H, T), V3(sx * (W / 2 - stile / 2), leafY, zMid), slabPaint, r: 0.0032)
            rig.add(s.0, s.1, to: "leaf")
        }
        let mid = DoorKit.vbox(V3(stile, H - top - bottom + 0.004, T - 0.002), V3(0, (yb + bottom + yt - top) / 2, zMid), slabPaint, r: 0.003)
        rig.add(mid.0, mid.1, to: "leaf")
        let railW = W - 2 * stile + 0.004
        let tr = DoorKit.box(V3(railW, top, T), V3(0, yt - top / 2, zMid), slabPaint, r: 0.0032)
        let br = DoorKit.box(V3(railW, bottom, T), V3(0, yb + bottom / 2, zMid), slabPaint, r: 0.0032)
        rig.add(tr.0, tr.1, to: "leaf"); rig.add(br.0, br.1, to: "leaf")
        let px0 = -W / 2 + stile, px1 = W / 2 - stile
        for (a, b) in [(px0, -stile / 2), (stile / 2, px1)] {
            DoorKit.panel(&rig, to: "leaf", x0: a, x1: b, y0: yb + bottom, y1: yt - top, zc: zMid, T: T, mat: slabPaint, raised: false)
        }
        // Flush pulls: oval brushed-nickel plate with a dark recess, mortised 12 mm from the leading edge's stile.
        let ox = W / 2 - stile / 2, oy: Float = 0.95
        for side: Float in [1, -1] {
            let face = side > 0 ? zf : zb
            let oval = Shape2D.rounded([V2(-0.022, -0.055), V2(0.022, -0.055), V2(0.022, 0.055), V2(-0.022, 0.055)], radius: 0.018, segments: 4)
            rig.add(Prim.extrude(oval, depth: 0.003, bevel: 0.0008, bevelSegments: 1, material: hardware),
                    Xform(translation: V3(ox, oy, face + side * 0.0013)), to: "leaf")
            let recess = Shape2D.rounded([V2(-0.012, -0.04), V2(0.012, -0.04), V2(0.012, 0.04), V2(-0.012, 0.04)], radius: 0.01, segments: 3)
            rig.add(Prim.extrude(recess, depth: 0.001, bevel: 0.0002, bevelSegments: 1, material: "plastic.black"),
                    Xform(translation: V3(ox, oy, face + side * 0.0031)), to: "leaf", lods: 0...0)
        }
        // Edge pull plate on the leading edge and a latch hook slot.
        let ep = DoorKit.box(V3(0.002, 0.14, 0.022), V3(W / 2 + 0.0008, oy, zMid), hardware, r: 0.0008)
        rig.add(ep.0, ep.1, to: "leaf", lods: 0...0)
        rig.add(Prim.roundedBox(V3(0.003, 0.09, 0.008), radius: 0.001, bevelSegments: 1, material: "plastic.black"),
                Xform(translation: V3(W / 2 + 0.0015, oy, zMid)), to: "leaf", lods: 0...0)
        // Story detail: boot scuff on the bottom rail.
        let sc = DoorKit.box(V3(0.09, 0.022, 0.0006), V3(W / 2 - 0.2, yb + 0.07, zf + 0.0003), "decal.rubber-scuff", r: 0)
        rig.add(sc.0, sc.1, to: "leaf", lods: 0...0)

        groundAO(&rig, height: 0.15, floor: 0.6)
        rig.states = [RigState("closed"), RigState("open", ["leaf": travel])]
        return rig
    }
}
