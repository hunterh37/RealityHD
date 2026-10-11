import simd
import Foundation

/// Sliding barn door, 1.9 m x 2.3 m x 0.1 m overall: five vertical walnut planks (950 x 2150 x 32 mm, 1.5 mm joints) braced by a
/// Z of top, bottom and diagonal battens, two black steel strap hangers with wheels riding a flat top rail (1.9 m, 50 x 8 mm) on four
/// standoff posts with end stops, a vertical bar pull and a floor guide. Origin at the bottom center of the opening; the slab hangs
/// 20 mm above the floor and slides toward +X along the rail (rail spans x -0.5...1.4).
public struct BarnDoor: RealArticulated {
    public static let id = "barn-door"
    public static let summary = "Sliding barn door: five-plank walnut slab with Z-brace battens, black strap hangers on a flat top rail with standoffs, floor guide and pull."
    public static let tags = ["structure", "floorplan", "home", "wood", "metal", "interior", "door", "articulated"]
    public static let budget = 6000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 6, distance: 1.9, studio: true)

    /// Slab width and height (m).
    public var slabWidth: Float = 0.95
    public var slabHeight: Float = 2.15
    public var railLength: Float = 1.9
    public var slabMaterial: MaterialKey = "wood.walnut"
    public var steel: MaterialKey = "metal.powdercoat:202225"
    public var bolt: MaterialKey = "metal.steel"
    /// Slide travel along +X (m).
    public var travel: Float = 0.9
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        var rng = SeededRNG(seed: seed)
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [8])
        let W = slabWidth, H = slabHeight
        let y0: Float = 0.02, y1 = y0 + H
        let pz0: Float = -0.012, pz1: Float = 0.014           // plank faces
        let bz1: Float = 0.026                                 // batten front
        let railZ0: Float = 0.030, railZ1: Float = 0.038
        let railTop: Float = 2.24, railH: Float = 0.05
        let rx0: Float = -0.5, rx1 = rx0 + railLength
        let wallZ: Float = -0.038
        let wheelR: Float = 0.03

        // MARK: static: rail, standoffs, stops, floor guide
        for l in 0..<2 {
            var m = Model(name: Self.id)
            let rail = DoorKit.box(V3(railLength, railH, railZ1 - railZ0), V3((rx0 + rx1) / 2, railTop - railH / 2, (railZ0 + railZ1) / 2), steel, r: 0.0015)
            m.add(rail.0, rail.1)
            // Standoff posts and wall rosettes.
            for px in [rx0 + 0.12, rx0 + 0.55, rx1 - 0.55, rx1 - 0.12] {
                m.add(Prim.cylinder(radius: 0.012, height: railZ0 - wallZ, bevel: 0.002, segments: l == 0 ? 14 : 8, bevelSegments: 1, material: steel),
                      Xform(translation: V3(px, railTop - railH / 2, wallZ), rotation: facing(V3(0, 0, 1))))
                m.add(Prim.cylinder(radius: 0.022, height: 0.004, bevel: 0.001, segments: l == 0 ? 16 : 8, bevelSegments: 1, material: steel),
                      Xform(translation: V3(px, railTop - railH / 2, wallZ), rotation: facing(V3(0, 0, 1))))
                m.add(Prim.cylinder(radius: 0.011, height: 0.006, bevel: 0.0015, segments: l == 0 ? 14 : 8, bevelSegments: 1, material: bolt),
                      Xform(translation: V3(px, railTop - railH / 2, railZ1), rotation: facing(V3(0, 0, 1))))
            }
            // End stops: blocks with a black rubber bumper.
            for (sx, dir) in [(rx0 + 0.015, Float(1)), (rx1 - 0.015, Float(-1))] {
                let b = DoorKit.box(V3(0.03, 0.04, 0.03), V3(sx, railTop - railH / 2, (railZ0 + railZ1) / 2), steel, r: 0.002)
                m.add(b.0, b.1)
                m.add(cuboid(V3(0.012, 0.03, 0.02), material: "rubber"), Xform(translation: V3(sx + dir * 0.02, railTop - railH / 2, (railZ0 + railZ1) / 2)))
            }
            // Floor guide: nylon block in the slab's bottom slot.
            m.add(Prim.roundedBox(V3(0.018, 0.018, 0.012), radius: 0.002, bevelSegments: 1, material: "plastic.black"),
                  Xform(translation: V3(0.0, 0.009, (pz0 + pz1) / 2)))
            m.add(Prim.cylinder(radius: 0.012, height: 0.002, bevel: 0.0005, segments: l == 0 ? 12 : 8, bevelSegments: 1, material: bolt),
                  Xform(translation: V3(0.0, 0.0, (pz0 + pz1) / 2 + 0.014)))
            rig.base[l] = m
        }

        // MARK: slab
        rig.part("door", pivot: V3(0, 1, 0), joint: .slide(axis: V3(1, 0, 0), 0...travel, duration: 1.8))
        let n = 5
        let pg: Float = 0.0015
        let pwid = (W - Float(n - 1) * pg) / Float(n)
        for i in 0..<n {
            let x = -W / 2 + pwid / 2 + Float(i) * (pwid + pg)
            let dz = rng.float(-0.0006...0.0006)
            let p = DoorKit.vbox(V3(pwid, H, pz1 - pz0), V3(x, (y0 + y1) / 2, (pz0 + pz1) / 2 + dz), slabMaterial, r: 0.0025)
            rig.add(p.0, p.1, to: "door")
        }
        // Z-brace on the front face: top, bottom battens and the diagonal between them.
        let bw: Float = 0.1, bt = bz1 - pz1
        let zc = (pz1 + bz1) / 2
        let topY = y1 - 0.2, botY = y0 + 0.2
        let bx = W - 0.1
        for by in [topY, botY] {
            let b = DoorKit.box(V3(bx, bw, bt), V3(0, by, zc), slabMaterial, r: 0.003)
            rig.add(b.0, b.1, to: "door")
        }
        let dxl = bx - 0.1, dyl = topY - botY
        let len = (dxl * dxl + dyl * dyl).squareRoot()
        let ang = atan2(dyl, dxl)
        let diag = DoorKit.box(V3(len + 0.06, bw, bt), V3(0, (topY + botY) / 2, zc), slabMaterial, r: 0.003)
        rig.add(diag.0, Xform(translation: diag.1.translation, rotation: simd_quatf(angle: -ang, axis: V3(0, 0, 1))), to: "door")
        // Batten screws.
        for (sx, by) in [(-bx / 2 + 0.03, topY), (bx / 2 - 0.03, topY), (-bx / 2 + 0.03, botY), (bx / 2 - 0.03, botY)] {
            rig.add(Prim.cylinder(radius: 0.0045, height: 0.0012, bevel: 0.0004, segments: 8, bevelSegments: 1, material: bolt),
                    Xform(translation: V3(sx, by, bz1), rotation: facing(V3(0, 0, 1))), to: "door", lods: 0...0)
        }

        // MARK: hangers: strap, wheel, axle bolt
        let strapOutline = Shape2D.rounded([V2(-0.025, 0), V2(0.025, 0), V2(0.025, 0.15), V2(0.0, 0.18), V2(-0.025, 0.15)], radius: 0.006, segments: 3)
        for hx in [-0.3, Float(0.3)] {
            let hy = y1 - 0.14                       // strap bottom on the slab face
            rig.add(Prim.extrude(strapOutline, depth: 0.006, bevel: 0.0012, bevelSegments: 1, material: steel),
                    Xform(translation: V3(hx, hy, bz1 + 0.003)), to: "door")
            // Wheel: 60 mm, rolls on the rail top.
            let wy = railTop + wheelR
            let wheel = Prim.lathe([V2(0, -0.007), V2(wheelR - 0.004, -0.007), V2(wheelR, -0.0035), V2(wheelR - 0.003, -0.001), V2(wheelR - 0.003, 0.001), V2(wheelR, 0.0035), V2(wheelR - 0.004, 0.007), V2(0, 0.007)],
                                   segments: 24, seamTile: 0.05, material: "rubber")
            rig.add(wheel, Xform(translation: V3(hx, wy, railZ1 + 0.002), rotation: facing(V3(0, 0, 1))), to: "door")
            // Strap extension up to the axle (second plate behind the wheel sits against the rail face).
            rig.add(DoorKit.box(V3(0.04, wy - hy - 0.17, 0.006), V3(hx, hy + 0.17 + (wy - hy - 0.17) / 2, bz1 + 0.003), steel, r: 0.001).0,
                    Xform(translation: V3(hx, hy + 0.17 + (wy - hy - 0.17) / 2, bz1 + 0.003)), to: "door")
            rig.add(Prim.cylinder(radius: 0.008, height: 0.016, bevel: 0.001, segments: 12, bevelSegments: 1, material: bolt),
                    Xform(translation: V3(hx, wy, bz1 + 0.004), rotation: facing(V3(0, 0, 1))), to: "door")
            rig.add(Prim.cylinder(radius: 0.012, height: 0.004, bevel: 0.0012, segments: 16, bevelSegments: 1, material: bolt),
                    Xform(translation: V3(hx, wy, railZ1 + 0.0095), rotation: facing(V3(0, 0, 1))), to: "door")
            for by in [hy + 0.03, hy + 0.09] {
                rig.add(Prim.cylinder(radius: 0.007, height: 0.004, bevel: 0.001, segments: 6, bevelSegments: 1, material: bolt),
                        Xform(translation: V3(hx, by, bz1 + 0.006), rotation: facing(V3(0, 0, 1))), to: "door", lods: 0...0)
            }
        }

        // MARK: vertical bar pull near the leading edge
        let px = W / 2 - 0.13, py: Float = 1.0
        rig.add(Prim.cylinder(radius: 0.011, height: 0.4, bevel: 0.005, segments: 14, bevelSegments: 2, material: steel),
                Xform(translation: V3(px, py - 0.2, bz1 + 0.026)), to: "door")
        for dy: Float in [-0.15, 0.15] {
            rig.add(Prim.cylinder(radius: 0.008, height: 0.026 - 0.002, bevel: 0.001, segments: 10, bevelSegments: 1, material: steel),
                    Xform(translation: V3(px, py + dy, bz1), rotation: facing(V3(0, 0, 1))), to: "door")
        }
        // Story detail: pale wear where hands pull the edge.
        let sc = DoorKit.box(V3(0.06, 0.016, 0.0006), V3(px - 0.02, y0 + 0.07, pz1 + 0.0003), "decal.rubber-scuff", r: 0)
        rig.add(sc.0, sc.1, to: "door", lods: 0...0)

        groundAO(&rig, height: 0.12, floor: 0.6)
        rig.states = [RigState("closed"), RigState("open", ["door": travel])]
        return rig
    }
}
