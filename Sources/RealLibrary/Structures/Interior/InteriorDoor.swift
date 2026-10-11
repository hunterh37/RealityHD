import simd
import Foundation

/// Interior two-panel door in a cased opening, 0.94 m x 2.1 m overall: painted MDF slab (790 x 2000 x 35 mm) with
/// stiles, rails, a center stile and two stuck-bead recessed panels, split jamb with rebated stop, flat casing
/// with bead, back band and head cap on both wall faces, three satin-nickel butt hinges, a return lever on round
/// roses both sides, latch and strike. Origin at the bottom center of the opening, hinge on -X, leaf swings to +Z.
public struct InteriorDoor: RealArticulated {
    public static let id = "interior-door"
    public static let summary = "Interior two-panel door in a cased frame: painted slab, three hinges, nickel lever, casing both sides; swings 100 degrees."
    public static let tags = ["structure", "floorplan", "home", "wood", "metal", "interior", "door", "articulated"]
    public static let budget = 10000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 6, distance: 1.2, studio: true)

    /// Overall casing width (m); the planner reads this as the opening width.
    public var width: Float = 0.94
    /// Overall height to the top of the head cap (m).
    public var height: Float = 2.1
    /// Wall thickness plus both casing faces (m).
    public var depth: Float = 0.15
    public var leafThickness: Float = 0.035
    /// Paint and trim material (tint with :RRGGBB).
    public var paint: MaterialKey = "wood.painted-shaker:D6CFC0"
    /// Worn paint for the slab (hands and shoes reach it).
    public var slabPaint: MaterialKey = "wood.painted-shaker-worn:D6CFC0"
    public var hardware: MaterialKey = "metal.brushed-nickel"
    public var hingeMaterial: MaterialKey = "metal.hinge-satin-nickel"
    /// Lever height above the floor (m).
    public var handleHeight: Float = 0.95
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [8])
        let T = leafThickness
        var c = DoorKit.Casing(openW: 0, openH: 0, wallT: depth - 0.041, material: paint)
        c.openW = width - 2 * (c.reveal + c.casingW + c.capOver)
        c.openH = height - c.reveal - c.casingW - c.capH
        let gap: Float = 0.004, undercut: Float = 0.015
        let W = c.openW - 2 * gap
        let H = c.openH - undercut - 0.008
        let leafY = undercut + H / 2
        let zb: Float = -0.016, zf = zb + T       // leaf back/front faces
        let zMid = (zb + zf) / 2
        c.stopZ = zb - 0.003
        let hingeX = -c.openW / 2 + 0.0004

        for l in 0..<2 {
            var m = Model(name: Self.id)
            c.build(&m, detail: l == 0)
            rig.base[l] = m
        }

        // Leaf: hinge on -X, opens toward +Z (right-hand rule about -Y).
        rig.part("leaf", pivot: V3(hingeX, 0, zf - 0.002), joint: .hinge(axis: V3(0, -1, 0), 0...100, duration: 1.3))
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

        // Story detail: a shoe scuff low on the lock side of the bottom rail.
        let scuff = DoorKit.box(V3(0.09, 0.022, 0.0006), V3(W / 2 - 0.19, yb + 0.07, zf + 0.0003), "decal.rubber-scuff", r: 0)
        rig.add(scuff.0, scuff.1, to: "leaf", lods: 0...0)
        // Hardware.
        DoorKit.hinges(&rig, leaf: "leaf", side: -1, pinX: hingeX - 0.0, pinZ: zf - 0.002, ys: [0.26, 1.0, 1.84], mat: hingeMaterial)
        DoorKit.lever(&rig, leaf: "leaf", hingeSide: -1, edgeX: W / 2, y: handleHeight, zFront: zf, zBack: zb, mat: hardware,
                      strikeX: c.openW / 2 + 0.0005)

        groundAO(&rig, height: 0.15, floor: 0.6)
        rig.states = [RigState("closed"), RigState("ajar", ["leaf": 25]), RigState("open", ["leaf": 90]),
                      RigState("unlatched", ["handle": -40])]
        return rig
    }
}
