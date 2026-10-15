import simd
import Foundation

/// Interior French door pair in a cased opening, 1.5 m x 2.1 m overall: two painted pine leaves (673 x 2000 x 35 mm) with 70 mm
/// stiles, a deep bottom rail, a 3 x 5 grid of lites (muntins on both faces over 8 mm glass with stuck beads), three satin-nickel
/// butt hinges per leaf, a lever on the active right leaf, flush bolts, a strike and an astragal on the passive left leaf, a split
/// jamb and flat casing with bead and head cap on both faces. Origin at the bottom center of the opening; both leaves swing toward +Z.
public struct InteriorFrenchDoors: RealArticulated {
    public static let id = "interior-french-doors"
    public static let summary = "Interior French door pair in a cased opening: two 15-lite glazed leaves with muntins, three hinges each, lever, flush bolts, astragal, casing."
    public static let tags = ["structure", "floorplan", "home", "wood", "glass", "metal", "interior", "door", "articulated"]
    public static let budget = 9000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 26, elevation: 6, distance: 1.5, studio: true)

    public var width: Float = 1.5
    public var height: Float = 2.1
    public var depth: Float = 0.15
    public var leafThickness: Float = 0.035
    public var paint: MaterialKey = "wood.painted-shaker:D6CFC0"
    public var leafPaint: MaterialKey = "wood.painted-shaker-worn:D6CFC0"
    public var glass: MaterialKey = "glass.pane"
    public var hardware: MaterialKey = "metal.brushed-nickel"
    public var hingeMaterial: MaterialKey = "metal.hinge-satin-nickel"
    /// Lites across and up each leaf.
    public var litesAcross = 3
    public var litesHigh = 5
    public var handleHeight: Float = 0.95
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [8])
        let T = leafThickness
        var c = DoorKit.Casing(openW: 0, openH: 0, wallT: depth - 0.041, material: paint)
        c.openW = width - 2 * (c.reveal + c.casingW + c.capOver)
        c.openH = height - c.reveal - c.casingW - c.capH
        c.withStop = false
        let gap: Float = 0.004, undercut: Float = 0.015
        let lw = (c.openW - 2 * gap - 0.004) / 2
        let H = c.openH - undercut - 0.008
        let yb = undercut, yt = undercut + H
        let zb: Float = -0.016, zf = zb + T, zMid = (zb + zf) / 2
        for l in 0..<2 {
            var m = Model(name: Self.id)
            c.build(&m, detail: l == 0)
            // Head stop strip and the floor-to-head side stops on the back (-Z) side of the leaves.
            for sx: Float in [-1, 1] {
                m.add(cuboid(V3(0.014, c.openH, 0.012), material: paint), Xform(translation: V3(sx * (c.openW / 2 - 0.007), c.openH / 2, zb - 0.0075)))
            }
            m.add(cuboid(V3(c.openW - 0.028, 0.014, 0.012), material: paint), Xform(translation: V3(0, c.openH - 0.007, zb - 0.0075)))
            rig.base[l] = m
        }

        let xL0 = -c.openW / 2 + gap, xL1 = xL0 + lw
        let xR1 = c.openW / 2 - gap, xR0 = xR1 - lw
        let hingeXL = -c.openW / 2 + 0.0004, hingeXR = c.openW / 2 - 0.0004
        rig.part("leafL", pivot: V3(hingeXL, 0, zf - 0.002), joint: .hinge(axis: V3(0, -1, 0), 0...100, duration: 1.4))
        rig.part("leafR", pivot: V3(hingeXR, 0, zf - 0.002), joint: .hinge(axis: V3(0, 1, 0), 0...100, duration: 1.4))

        func leaf(_ part: String, x0: Float, x1: Float) {
            let st: Float = 0.07, tr: Float = 0.07, br: Float = 0.16
            let cx = (x0 + x1) / 2, cy = (yb + yt) / 2
            for sx: Float in [0, 1] {
                let s = DoorKit.vbox(V3(st, H, T), V3(sx == 0 ? x0 + st / 2 : x1 - st / 2, cy, zMid), leafPaint, r: 0.003)
                rig.add(s.0, s.1, to: part)
            }
            let rw = x1 - x0 - 2 * st + 0.002
            let t1 = DoorKit.box(V3(rw, tr, T), V3(cx, yt - tr / 2, zMid), leafPaint, r: 0.003)
            let b1 = DoorKit.box(V3(rw, br, T), V3(cx, yb + br / 2, zMid), leafPaint, r: 0.003)
            rig.add(t1.0, t1.1, to: part); rig.add(b1.0, b1.1, to: part)
            let gx0 = x0 + st, gx1 = x1 - st, gy0 = yb + br, gy1 = yt - tr
            let pane = DoorKit.box(V3(gx1 - gx0 + 0.004, gy1 - gy0 + 0.004, 0.008), V3((gx0 + gx1) / 2, (gy0 + gy1) / 2, zMid), glass, r: 0)
            rig.add(pane.0, pane.1, to: part)
            // Stuck beads around the glass, both faces.
            for s: Float in [-1, 1] {
                let bz = zMid + s * 0.0095
                for (size, ctr) in [(V3(gx1 - gx0, 0.014, 0.011), V3(cx, gy0 + 0.007, bz)), (V3(gx1 - gx0, 0.014, 0.011), V3(cx, gy1 - 0.007, bz)),
                                    (V3(0.014, gy1 - gy0 - 0.028, 0.011), V3(gx0 + 0.007, (gy0 + gy1) / 2, bz)), (V3(0.014, gy1 - gy0 - 0.028, 0.011), V3(gx1 - 0.007, (gy0 + gy1) / 2, bz))] {
                    let b = DoorKit.box(size, ctr, leafPaint, r: 0)
                    rig.add(b.0, b.1, to: part, lods: 0...0)
                }
                // Muntins on the face.
                let mz = zMid + s * 0.0085
                for i in 1..<litesAcross {
                    let x = gx0 + Float(i) * (gx1 - gx0) / Float(litesAcross)
                    let mu = DoorKit.box(V3(0.02, gy1 - gy0, 0.01), V3(x, (gy0 + gy1) / 2, mz), leafPaint, r: 0)
                    rig.add(mu.0, mu.1, to: part)
                }
                for j in 1..<litesHigh {
                    let y = gy0 + Float(j) * (gy1 - gy0) / Float(litesHigh)
                    let mu = DoorKit.box(V3(gx1 - gx0, 0.02, 0.01), V3(cx, y, mz + s * 0.0005), leafPaint, r: 0)
                    rig.add(mu.0, mu.1, to: part)
                }
            }
        }
        leaf("leafL", x0: xL0, x1: xL1)
        leaf("leafR", x0: xR0, x1: xR1)

        // Astragal on the passive leaf's front edge covering the meeting joint.
        let ast = DoorKit.vbox(V3(0.032, H - 0.01, 0.012), V3(xL1 - 0.008, (yb + yt) / 2, zf + 0.006 - 0.0005), leafPaint, r: 0.003)
        rig.add(ast.0, ast.1, to: "leafL")
        // Flush bolts (top and bottom) and the strike on the passive leaf edge.
        for by in [yt - 0.2, yb + 0.2] {
            let bp = DoorKit.box(V3(0.0025, 0.12, 0.018), V3(xL1 + 0.001, by, zMid), hardware, r: 0.0008)
            rig.add(bp.0, bp.1, to: "leafL", lods: 0...0)
            rig.add(Prim.roundedBox(V3(0.003, 0.05, 0.006), radius: 0.001, bevelSegments: 1, material: "plastic.black"),
                    Xform(translation: V3(xL1 + 0.0015, by, zMid)), to: "leafL", lods: 0...0)
        }
        let sk = DoorKit.box(V3(0.0025, 0.11, 0.024), V3(xL1 + 0.001, handleHeight, zMid), hardware, r: 0.0008)
        rig.add(sk.0, sk.1, to: "leafL", lods: 0...0)

        DoorKit.hinges(&rig, leaf: "leafL", side: -1, pinX: hingeXL, pinZ: zf - 0.002, ys: [0.26, 1.0, 1.84], mat: hingeMaterial, finials: false, knuckleSegments: 8)
        DoorKit.hinges(&rig, leaf: "leafR", side: 1, pinX: hingeXR, pinZ: zf - 0.002, ys: [0.26, 1.0, 1.84], mat: hingeMaterial, finials: false, knuckleSegments: 8)
        DoorKit.lever(&rig, leaf: "leafR", hingeSide: 1, edgeX: xR0, y: handleHeight, zFront: zf, zBack: zb, mat: hardware, strikeInBase: false)
        // Story detail: boot scuff on the bottom rail.
        let sc = DoorKit.box(V3(0.09, 0.022, 0.0006), V3(xR0 + 0.16, yb + 0.07, zf + 0.0003), "decal.rubber-scuff", r: 0)
        rig.add(sc.0, sc.1, to: "leafR", lods: 0...0)

        groundAO(&rig, height: 0.15, floor: 0.6)
        rig.states = [RigState("closed"), RigState("ajar", ["leafR": 35]), RigState("open", ["leafL": 95, "leafR": 95]),
                      RigState("unlatched", ["handle": -40])]
        return rig
    }
}
