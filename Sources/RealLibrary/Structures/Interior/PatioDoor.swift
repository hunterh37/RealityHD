import simd
import Foundation

/// Sliding patio door, 1.83 m x 2.1 m x 0.18 m: black anodized aluminum frame (head, 70 mm jambs, sill with twin tracks and
/// weep slots), a fixed panel on the outer track and a sliding panel on the inner track, each with 50 mm stiles, 8 mm glass
/// in silicone gaskets, an overlapping interlock stile with pile weatherstrip, a hook handle with a turning lever and a jamb
/// strike. Origin at the bottom center of the opening; the slider runs toward -X over the fixed panel.
public struct PatioDoor: RealArticulated {
    public static let id = "patio-door"
    public static let summary = "Six-foot sliding patio door: black aluminum frame, fixed and sliding glass panels on twin sill tracks, hook handle, rubber interlock."
    public static let tags = ["structure", "floorplan", "home", "glass", "metal", "interior", "door", "articulated"]
    public static let budget = 5000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 6, distance: 1.7, studio: true)

    public var width: Float = 1.83
    public var height: Float = 2.1
    public var depth: Float = 0.18
    public var frame: MaterialKey = "metal.anodized-black"
    public var glass: MaterialKey = "glass.pane"
    public var gasket: MaterialKey = "rubber.silicone"
    public var trackMaterial: MaterialKey = "metal.satin-aluminum"
    /// Slide travel of the sliding panel (m).
    public var travel: Float = 0.82
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [8])
        let W = width, H = height, D = depth
        let jamb: Float = 0.07, headH: Float = 0.075, sillH: Float = 0.045
        let inner = W - 2 * jamb
        let pw = (inner + 0.04) / 2                 // panel width with 40 mm interlock overlap
        let py0 = sillH + 0.006, py1 = H - headH + 0.03
        let ph = py1 - py0
        let zFixed: Float = -0.032, zSlide: Float = 0.032, pt: Float = 0.04
        func box(_ s: V3, _ c: V3, _ m: MaterialKey, r: Float = 0.0015) -> DoorKit.Piece { DoorKit.box(s, c, m, r: r) }

        for l in 0..<2 {
            var m = Model(name: Self.id)
            func add(_ p: DoorKit.Piece) { m.add(p.0, p.1) }
            // Head: box section with two track channels and trim lips.
            add(box(V3(W, headH, D), V3(0, H - headH / 2, 0), frame, r: 0.002))
            if l == 0 {
                for z in [zFixed, zSlide] {
                    add(box(V3(inner, 0.004, 0.05), V3(0, H - headH - 0.001, z), "plastic.black", r: 0))
                }
            }
            // Jambs: 70 mm box sections with a stop strip toward each panel and a weather pile strip.
            for sx: Float in [-1, 1] {
                add(box(V3(jamb, H - headH - sillH, D), V3(sx * (W / 2 - jamb / 2), sillH + (H - headH - sillH) / 2, 0), frame, r: 0.002))
                if l == 0 {
                    for z in [zFixed, zSlide] {
                        add(box(V3(0.008, H - headH - sillH - 0.02, 0.04), V3(sx * (inner / 2 - 0.002), (H + sillH - headH) / 2, z), gasket, r: 0))
                    }
                }
            }
            // Sill: aluminum body, a sloped exterior lip, two raised track rails and weep slots.
            add(box(V3(W, sillH, D), V3(0, sillH / 2, 0), frame, r: 0.002))
            add(box(V3(inner, 0.012, 0.016), V3(0, sillH + 0.006, -D / 2 + 0.02), frame, r: 0.002))
            for z in [zFixed, zSlide] {
                m.add(Prim.roundedBox(V3(inner, 0.014, 0.01), radius: 0.0025, bevelSegments: 1, material: trackMaterial),
                      Xform(translation: V3(0, sillH + 0.007, z)))
                if l == 0 {
                    for k in 0..<4 {
                        let x = (Float(k) - 1.5) * 0.38
                        add(box(V3(0.06, 0.002, 0.012), V3(x, sillH + 0.0005, z + (z < 0 ? -0.022 : 0.022)), "plastic.black", r: 0))
                    }
                }
            }
            // Interior trim lip around the frame on the +Z face.
            add(box(V3(W, 0.022, 0.012), V3(0, H - 0.011, D / 2 - 0.006 + 0.0003), frame, r: 0.0015))
            if l == 0 {
                // Strike plate on the right jamb at lock height.
                add(box(V3(0.003, 0.16, 0.03), V3(inner / 2 + 0.0005, 1.0, zSlide + 0.002), trackMaterial, r: 0.001))
                add(box(V3(0.004, 0.03, 0.012), V3(inner / 2 + 0.0008, 1.0, zSlide + 0.002), "plastic.black", r: 0))
            }
            rig.base[l] = m
        }

        // One panel: aluminum stiles and rails around a glass lite in silicone gaskets.
        func panel(part: String, cx: Float, z: Float, lock: Bool) {
            let st: Float = 0.05, tr: Float = 0.06, br: Float = 0.1
            let cy = (py0 + py1) / 2
            let li = DoorKit.vbox(V3(st, ph, pt), V3(cx - pw / 2 + st / 2, cy, z), frame, r: 0.002)
            let ri = DoorKit.vbox(V3(lock ? 0.065 : st, ph, pt), V3(cx + pw / 2 - (lock ? 0.065 : st) / 2, cy, z), frame, r: 0.002)
            let top = box(V3(pw - 2 * st + 0.002, tr, pt), V3(cx, py1 - tr / 2, z), frame, r: 0.002)
            let bot = box(V3(pw - 2 * st + 0.002, br, pt), V3(cx, py0 + br / 2, z), frame, r: 0.002)
            for p in [li, ri, top, bot] { rig.add(p.0, p.1, to: part) }
            let gx0 = cx - pw / 2 + st, gx1 = cx + pw / 2 - (lock ? 0.065 : st), gy0 = py0 + br, gy1 = py1 - tr
            let pane = box(V3(gx1 - gx0 + 0.006, gy1 - gy0 + 0.006, 0.008), V3((gx0 + gx1) / 2, (gy0 + gy1) / 2, z), glass, r: 0)
            rig.add(pane.0, pane.1, to: part)
            // Gaskets: thin black frame on both faces.
            for s: Float in [-1, 1] {
                let gz = z + s * 0.0075
                for (size, ctr) in [(V3(gx1 - gx0, 0.012, 0.005), V3((gx0 + gx1) / 2, gy0 + 0.006, gz)),
                                    (V3(gx1 - gx0, 0.012, 0.005), V3((gx0 + gx1) / 2, gy1 - 0.006, gz)),
                                    (V3(0.012, gy1 - gy0 - 0.024, 0.005), V3(gx0 + 0.006, (gy0 + gy1) / 2, gz)),
                                    (V3(0.012, gy1 - gy0 - 0.024, 0.005), V3(gx1 - 0.006, (gy0 + gy1) / 2, gz))] {
                    let g = box(size, ctr, gasket, r: 0)
                    rig.add(g.0, g.1, to: part, lods: 0...0)
                }
            }
            // Glazing screws along the bottom rail, a drainage notch.
            if true {
                for k in 0..<5 {
                    let x = cx - pw / 2 + 0.15 + Float(k) * (pw - 0.3) / 4
                    rig.add(Prim.cylinder(radius: 0.003, height: 0.001, bevel: 0.0004, segments: 8, bevelSegments: 1, material: trackMaterial),
                            Xform(translation: V3(x, py0 + 0.03, z + pt / 2), rotation: facing(V3(0, 0, 1))), to: part, lods: 0...0)
                }
            }
        }
        let fixedCx = -inner / 2 + pw / 2
        let slideCx = inner / 2 - pw / 2
        rig.part("slider", pivot: V3(slideCx, 1, zSlide), joint: .slide(axis: V3(-1, 0, 0), 0...travel, duration: 1.6))
        panel(part: "slider", cx: slideCx, z: zSlide, lock: true)
        // Fixed panel is static (base). Build into a scratch rig part-less: use a fixed joint part.
        rig.part("fixed", pivot: V3(fixedCx, 1, zFixed), joint: Joint(.fixed))
        panel(part: "fixed", cx: fixedCx, z: zFixed, lock: false)
        // Pile weatherstrip on the interlock edges.
        let pile1 = box(V3(0.006, ph - 0.1, 0.026), V3(fixedCx + pw / 2 + 0.003, (py0 + py1) / 2, zFixed), "plastic.black", r: 0)
        rig.add(pile1.0, pile1.1, to: "fixed", lods: 0...0)

        // Hook handle on the slider's lock stile (interior face) with a turning lever, and an exterior flush pull.
        let hx = slideCx + pw / 2 - 0.0325, hy: Float = 1.0
        let zi = zSlide + pt / 2
        let plate = box(V3(0.046, 0.26, 0.006), V3(hx, hy, zi + 0.003), trackMaterial, r: 0.002)
        rig.add(plate.0, plate.1, to: "slider")
        let hook = Prim.tube(catmull([V3(hx, hy + 0.05, zi + 0.006), V3(hx, hy + 0.05, zi + 0.024), V3(hx, hy + 0.01, zi + 0.027), V3(hx, hy - 0.06, zi + 0.024), V3(hx, hy - 0.07, zi + 0.012)], per: 4),
                             radii: Array(repeating: 0.0085, count: 17), sides: 10, seamTile: 0.05, material: trackMaterial)
        rig.add(hook, to: "slider")
        rig.part("latch", parent: "slider", pivot: V3(hx, hy + 0.09, zi + 0.0085), joint: .hinge(axis: V3(0, 0, 1), -80...0, duration: 0.4))
        let lever = box(V3(0.016, 0.085, 0.01), V3(hx, hy + 0.09 - 0.0425, zi + 0.0145), trackMaterial, r: 0.003)
        rig.add(lever.0, lever.1, to: "latch")
        rig.add(Prim.cylinder(radius: 0.011, height: 0.006, bevel: 0.002, segments: 14, bevelSegments: 1, material: trackMaterial),
                Xform(translation: V3(hx, hy + 0.09, zi + 0.006), rotation: facing(V3(0, 0, 1))), to: "latch")
        // Exterior pull plate on the -Z face of the slider stile.
        let pull = box(V3(0.03, 0.18, 0.006), V3(hx, hy, zSlide - pt / 2 - 0.003), trackMaterial, r: 0.002)
        rig.add(pull.0, pull.1, to: "slider", lods: 0...0)

        // Story detail: grit and scuffs along the interior track and on the lower rail.
        for (dx, w) in [(Float(-0.52), Float(0.18)), (Float(0.12), Float(0.12)), (Float(0.55), Float(0.2))] {
            let g = box(V3(w, 0.004, 0.012), V3(dx, sillH + 0.0145, zSlide), "decal.rubber-scuff", r: 0)
            rig.base[0].add(g.0, g.1)
        }
        groundAO(&rig, height: 0.15, floor: 0.6)
        rig.states = [RigState("closed"), RigState("open", ["slider": travel, "latch": -80])]
        return rig
    }
}
