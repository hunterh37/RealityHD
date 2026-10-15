import simd
import Foundation

/// Bypass sliding closet doors, 1.8 m x 2.05 m x 0.1 m overall: two painted shaker panels (863 x 1.95 m x 28 mm, 40 mm overlap) on separate
/// tracks, each with stiles, a deep bottom rail, a mid rail and two stuck-bead recessed panels, a satin-aluminum head track with two
/// channels, a floor track with twin ridges, flush oval pulls, hanger brackets with bolts, and flat casing with a head cap on both faces.
/// Origin at the bottom center of the opening; the front panel (+Z track) slides toward -X over the fixed back panel.
public struct SlidingClosetDoors: RealArticulated {
    public static let id = "sliding-closet-doors"
    public static let summary = "Six-foot bypass sliding closet doors: two painted shaker panels on separate tracks, head and floor track, flush pulls, hanger brackets, casing."
    public static let tags = ["structure", "floorplan", "home", "wood", "metal", "interior", "door", "articulated"]
    public static let budget = 8500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 6, distance: 1.8, studio: true)

    public var width: Float = 1.8
    public var height: Float = 2.05
    public var depth: Float = 0.1
    public var panelThickness: Float = 0.028
    public var paint: MaterialKey = "wood.painted-shaker:D3CDBE"
    public var panelPaint: MaterialKey = "wood.painted-shaker-worn:D3CDBE"
    public var track: MaterialKey = "metal.satin-aluminum"
    public var hardware: MaterialKey = "metal.brushed-nickel"
    /// Slide travel of the front panel (m).
    public var travel: Float = 0.85
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [9])
        let T = panelThickness
        var c = DoorKit.Casing(openW: 0, openH: 0, wallT: depth - 0.033, material: paint)
        c.casingW = 0.045; c.casingT = 0.014; c.capOver = 0.006; c.capH = 0.012; c.jambT = 0.017
        c.withStop = false; c.bead = false
        c.openW = width - 2 * (c.reveal + c.casingW + c.capOver)
        c.openH = height - c.reveal - c.casingW - c.capH
        let hx = c.openW / 2
        let pw = hx + 0.02
        let zF: Float = 0.016, zB: Float = -0.016
        let yb: Float = 0.02, yt = c.openH - 0.04
        let H = yt - yb

        for l in 0..<2 {
            var m = Model(name: Self.id)
            c.build(&m, detail: l == 0)
            // Head track: aluminum channel with two guide ridges under the head jamb.
            m.add(cuboid(V3(c.openW, 0.012, 0.062), material: track), Xform(translation: V3(0, c.openH - 0.006, 0)))
            for z in [zB, zF] {
                for dz: Float in [-0.016, 0.016] {
                    m.add(cuboid(V3(c.openW, 0.026, 0.003), material: track), Xform(translation: V3(0, c.openH - 0.025, z + dz)))
                }
            }
            // Floor track: base with twin ridges.
            m.add(Prim.roundedBox(V3(c.openW, 0.006, 0.062), radius: 0.002, bevelSegments: 1, material: track), Xform(translation: V3(0, 0.003, 0)))
            for z in [zB, zF] {
                m.add(Prim.roundedBox(V3(c.openW, 0.012, 0.005), radius: 0.0015, bevelSegments: 1, material: track), Xform(translation: V3(0, 0.012, z)))
            }
            rig.base[l] = m
        }

        func panel(_ part: String, x0: Float, x1: Float, z: Float, pullOnLeft: Bool) {
            let st: Float = 0.07, tr: Float = 0.08, br: Float = 0.16, mr: Float = 0.07
            let cx = (x0 + x1) / 2, cy = (yb + yt) / 2
            for sx: Float in [0, 1] {
                let s = DoorKit.vbox(V3(st, H, T), V3(sx == 0 ? x0 + st / 2 : x1 - st / 2, cy, z), panelPaint, r: 0.003)
                rig.add(s.0, s.1, to: part)
            }
            let rw = x1 - x0 - 2 * st + 0.002
            let midY: Float = yb + 0.78
            for (y0, y1) in [(yb, yb + br), (midY - mr / 2, midY + mr / 2), (yt - tr, yt)] {
                let r = DoorKit.box(V3(rw, y1 - y0, T), V3(cx, (y0 + y1) / 2, z), panelPaint, r: 0.003)
                rig.add(r.0, r.1, to: part)
            }
            for (y0, y1) in [(yb + br, midY - mr / 2), (midY + mr / 2, yt - tr)] {
                DoorKit.panel(&rig, to: part, x0: x0 + st, x1: x1 - st, y0: y0, y1: y1, zc: z, T: T, mat: panelPaint, raised: false)
            }
            // Flush oval pull on the stile at the meeting edge, +Z face.
            let px = pullOnLeft ? x0 + st / 2 : x1 - st / 2
            let oval = Shape2D.rounded([V2(-0.02, -0.055), V2(0.02, -0.055), V2(0.02, 0.055), V2(-0.02, 0.055)], radius: 0.017, segments: 4)
            rig.add(Prim.extrude(oval, depth: 0.003, bevel: 0.0008, bevelSegments: 1, material: hardware),
                    Xform(translation: V3(px, 1.0, z + T / 2 + 0.0013)), to: part)
            rig.add(DoorKit.box(V3(0.012, 0.075, 0.001), V3(px, 1.0, z + T / 2 + 0.0031), "plastic.black", r: 0).0,
                    Xform(translation: V3(px, 1.0, z + T / 2 + 0.0031)), to: part, lods: 0...0)
            // Hanger brackets with a bolt at both top corners.
            for bx in [x0 + 0.11, x1 - 0.11] {
                let plate = DoorKit.box(V3(0.035, 0.07, 0.004), V3(bx, yt - 0.04, z + T / 2 + 0.002), hardware, r: 0.001)
                rig.add(plate.0, plate.1, to: part, lods: 0...0)
                rig.add(Prim.cylinder(radius: 0.005, height: 0.003, bevel: 0.0008, segments: 8, bevelSegments: 1, material: hardware),
                        Xform(translation: V3(bx, yt - 0.04, z + T / 2 + 0.004), rotation: facing(V3(0, 0, 1))), to: part, lods: 0...0)
                // Roller wheel in the head track above the panel.
                rig.add(Prim.cylinder(radius: 0.012, height: 0.01, bevel: 0.002, segments: 10, bevelSegments: 1, material: "plastic.black"),
                        Xform(translation: V3(bx, yt + 0.0, z), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))), to: part, lods: 0...0)
            }
        }
        rig.part("back", pivot: V3(0, 1, zB), joint: Joint(.fixed))
        panel("back", x0: -hx, x1: -hx + pw, z: zB, pullOnLeft: false)
        rig.part("front", pivot: V3(0, 1, zF), joint: .slide(axis: V3(-1, 0, 0), 0...travel, duration: 1.6))
        panel("front", x0: hx - pw, x1: hx, z: zF, pullOnLeft: true)

        // Story detail: grit along the floor track and a scuff on the front panel.
        for (dx, w) in [(Float(-0.5), Float(0.16)), (Float(0.1), Float(0.1)), (Float(0.55), Float(0.2))] {
            rig.base[0].add(cuboid(V3(w, 0.002, 0.01), material: "decal.rubber-scuff"), Xform(translation: V3(dx, 0.0125, zF + 0.012)))
        }
        let sc = DoorKit.box(V3(0.09, 0.02, 0.0006), V3(hx - 0.25, yb + 0.06, zF + T / 2 + 0.0003), "decal.rubber-scuff", r: 0)
        rig.add(sc.0, sc.1, to: "front", lods: 0...0)

        groundAO(&rig, height: 0.15, floor: 0.6)
        rig.states = [RigState("closed"), RigState("open", ["front": travel])]
        return rig
    }
}
