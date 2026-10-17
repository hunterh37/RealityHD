import simd
import Foundation

/// French-door refrigerator, 36 in counter depth: stainless doors with rounded edges and vertical bar
/// handles over rubber gaskets, a pull-out freezer drawer with a horizontal bar handle, a toe kick grille,
/// hinge caps on top, and a lit white interior with glass shelves, crisper bins and door bins. The two
/// doors are the joints `left-door` and `right-door` (0...110 degrees outward).
public struct Refrigerator: RealArticulated {
    public static let id = "refrigerator"
    public static let summary = "French-door refrigerator, 36 in: stainless doors with bar handles, freezer drawer, lit interior with glass shelves and door bins."
    public static let tags = ["prop", "floorplan", "kitchen", "appliance", "metal", "interior", "articulated"]
    public static let budget = 13000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 12, distance: 3.2, studio: true)

    /// Overall size in meters including handles (x width, y height, z depth).
    public var size = V3(0.91, 1.78, 0.79)
    /// Door skin.
    public var door: MaterialKey = "metal.stainless"
    /// Cabinet sides and top.
    public var body: MaterialKey = "metal.stainless"
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        var rng = SeededRNG(seed: seed)
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [6])
        let W = size.x, H = size.y, D = size.z
        let handleOut: Float = 0.04
        let zFront = D / 2 - handleOut            // door and drawer front plane
        let doorT: Float = 0.065
        let zDoorBack = zFront - doorT            // gasket plane
        let zBack = -D / 2
        let kick: Float = 0.085
        let freezerTop: Float = 0.575
        let doorLo: Float = 0.585, doorHi = H - 0.008
        let wall: Float = 0.04
        let dark: MaterialKey = "plastic.matte:2A2A2C"
        let white: MaterialKey = "plastic.white"
        let gasketM: MaterialKey = "rubber.silicone-gray"
        let inW = W - 2 * wall
        let inLo = freezerTop + 0.03, inHi = H - 0.04
        let dw = (W - 0.004 - 0.005) / 2
        let dh = doorHi - doorLo, dcy = (doorLo + doorHi) / 2

        func rb(_ s: V3, _ c: V3, _ mat: MaterialKey, r: Float = 0.003, seg: Int = 1) -> (Surface, Xform) {
            (r <= 0.0025 ? cuboid(s, material: mat) : Prim.roundedBox(s, radius: r, bevelSegments: seg, material: mat), Xform(translation: c))
        }
        func post(_ m: inout Model, _ x: Float, _ y: Float, _ z0: Float, _ len: Float, _ r: Float, _ mat: MaterialKey) {
            m.add(Prim.cylinder(radius: r, height: len, bevel: r * 0.3, segments: 12, bevelSegments: 1, material: mat),
                  Xform(translation: V3(x, y, z0), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        }
        /// Open-top tray: floor, front wall, two ends (back is the door liner).
        func tray(_ m: inout Model, x: Float, y: Float, zBackFace: Float, w: Float, h: Float, d: Float, mat: MaterialKey) {
            let t: Float = 0.004
            m.add(cuboid(V3(w, t, d), material: mat), Xform(translation: V3(x, y, zBackFace - d / 2)))
            m.add(cuboid(V3(w, h, t), material: mat), Xform(translation: V3(x, y + h / 2, zBackFace - d + t / 2)))
            for sx: Float in [-1, 1] {
                m.add(cuboid(V3(t, h * 0.9, d), material: mat), Xform(translation: V3(x + sx * (w / 2 - t / 2), y + h * 0.45, zBackFace - d / 2)))
            }
        }

        for l in 0..<2 {
            let hi = l == 0
            var m = Model(name: Self.id)
            func add(_ b: (Surface, Xform)) { m.add(b.0, b.1) }
            let zc = (zBack + zDoorBack) / 2, zl = zDoorBack - zBack
            // Outer cabinet: sides, top, back.
            for sx: Float in [-1, 1] {
                add(rb(V3(wall, H - kick, zl), V3(sx * (W / 2 - wall / 2), kick + (H - kick) / 2, zc), body, r: 0.006))
            }
            add(rb(V3(W, 0.03, zl), V3(0, H - 0.023, zc), body, r: 0.006))
            add(rb(V3(inW, H - kick - 0.03, 0.02), V3(0, kick + (H - kick - 0.03) / 2, zBack + 0.01), "metal.galvanized", r: 0.002, seg: 1))
            // Toe kick plate and base.
            add(rb(V3(W - 0.03, kick - 0.004, zl - 0.07), V3(0, kick / 2 + 0.002, zc - 0.02), dark, r: 0.002, seg: 1))
            let kickFront = zFront - 0.035
            add(rb(V3(W - 0.06, kick - 0.01, 0.012), V3(0, kick / 2 + 0.002, kickFront), "plastic.matte:3A3A3D", r: 0.002, seg: 1))
            if hi {
                for i in 0..<9 {
                    add(rb(V3(W - 0.14, 0.0035, 0.006), V3(0, 0.014 + Float(i) * 0.0088, kickFront + 0.007), "plastic.matte:1C1C1E", r: 0.001, seg: 1))
                }
                for sx: Float in [-1, 1] {
                    m.add(Prim.cylinder(radius: 0.02, height: 0.006, bevel: 0.002, segments: 12, bevelSegments: 1, material: dark),
                          Xform(translation: V3(sx * (W / 2 - 0.05), 0, zBack + 0.07)))
                }
            }
            // Fresh-food liner (inside faces), with front frame.
            var cav = Prim.roundedBox(V3(inW, inHi - inLo, zl - 0.02), radius: 0.012, bevelSegments: 2, material: white).flipped()
            cav = cav.transformed(Xform(translation: V3(0, (inLo + inHi) / 2, (zBack + 0.02 + zDoorBack) / 2)))
            m.add(cav)
            // Freezer section block behind the drawer, and the mullion strip between sections.
            add(rb(V3(inW + 0.01, freezerTop - kick + 0.01, zl - 0.03), V3(0, (kick + freezerTop) / 2, zc + 0.005), white, r: 0.004, seg: 1))
            add(rb(V3(W - 0.008, 0.03, 0.012), V3(0, freezerTop + 0.0075, zDoorBack - 0.006), white, r: 0.003, seg: 1))
            add(rb(V3(W - 0.008, 0.01, 0.006), V3(0, freezerTop + 0.012, zDoorBack + 0.0005), gasketM, r: 0.002, seg: 1))
            // Face frame in white around the fresh-food opening.
            for sx: Float in [-1, 1] {
                add(rb(V3(0.012, inHi - inLo, 0.006), V3(sx * (inW / 2 - 0.002), (inLo + inHi) / 2, zDoorBack - 0.001), white, r: 0.002, seg: 1))
            }
            // Light strip under the top.
            add(rb(V3(0.4, 0.008, 0.02), V3(0, inHi - 0.004, zDoorBack - 0.05), "emissive.warm", r: 0.002, seg: 1))
            // Glass shelves: tempered glass in a white trim frame, spaced up the cavity.
            let shelfYs: [Float] = [0.93, 1.19, 1.45]
            let shelfD = zl - 0.17, shelfZ = zDoorBack - 0.05 - shelfD / 2
            for y in shelfYs {
                add(rb(V3(inW - 0.012, 0.006, shelfD), V3(0, y, shelfZ), "glass.clear", r: 0.0015, seg: 1))
                add(rb(V3(inW - 0.012, 0.014, 0.012), V3(0, y + 0.004, shelfZ + shelfD / 2 - 0.006), white, r: 0.003, seg: 1))
                add(rb(V3(0.012, 0.014, shelfD), V3(-(inW - 0.012) / 2 + 0.006, y + 0.004, shelfZ), white, r: 0.003, seg: 1))
                add(rb(V3(0.012, 0.014, shelfD), V3((inW - 0.012) / 2 - 0.006, y + 0.004, shelfZ), white, r: 0.003, seg: 1))
                if hi { for sx: Float in [-1, 1] {
                    add(rb(V3(0.008, 0.03, 0.02), V3(sx * (inW / 2 - 0.004), y - 0.015, shelfZ - shelfD / 2 + 0.02), white, r: 0.002, seg: 1))
                }}
            }
            // Crisper bins: two clear drawers with white fronts and finger pulls.
            let bx = inW / 4 - 0.002
            for sx: Float in [-1, 1] {
                let cx = sx * bx
                let bd = zl - 0.18, bz = zDoorBack - 0.07 - bd / 2
                add(rb(V3(inW / 2 - 0.02, 0.003, bd), V3(cx, inLo + 0.045, bz), "plastic.clear", r: 0.001, seg: 1))
                add(rb(V3(inW / 2 - 0.02, 0.17, 0.004), V3(cx, inLo + 0.12, zDoorBack - 0.07 - bd), "plastic.clear", r: 0.0015, seg: 1))
                add(rb(V3(0.004, 0.17, bd), V3(cx - (inW / 4 - 0.01), inLo + 0.12, bz), "plastic.clear", r: 0.0015, seg: 1))
                add(rb(V3(0.004, 0.17, bd), V3(cx + (inW / 4 - 0.01), inLo + 0.12, bz), "plastic.clear", r: 0.0015, seg: 1))
                add(rb(V3(inW / 2 - 0.02, 0.1, 0.012), V3(cx, inLo + 0.09, zDoorBack - 0.06), white, r: 0.004, seg: 2))
                add(rb(V3(0.1, 0.02, 0.008), V3(cx, inLo + 0.125, zDoorBack - 0.052), "plastic.matte:D8D8D8", r: 0.004, seg: 1))
            }
            // Contents: jug, bottles and a produce bag, placed once.
            if hi {
                let y1 = shelfYs[0] + 0.003
                m.add(Prim.cylinder(radius: 0.045, height: 0.2, bevel: 0.01, segments: 16, material: "plastic.frosted"), Xform(translation: V3(-0.2, y1, shelfZ + 0.05)))
                m.add(Prim.cylinder(radius: 0.012, height: 0.02, bevel: 0.004, segments: 12, material: "plastic.white"), Xform(translation: V3(-0.2, y1 + 0.2, shelfZ + 0.05)))
                for i in 0..<3 {
                    let bxx: Float = 0.05 + Float(i) * 0.075
                    m.add(Prim.cylinder(radius: 0.03, height: 0.2, bevel: 0.01, segments: 14, material: "glass.emerald"), Xform(translation: V3(bxx, shelfYs[1] + 0.003, shelfZ + 0.04 + rng.float(-0.03...0.03))))
                }
                m.add(Prim.roundedBox(V3(0.22, 0.14, 0.2), radius: 0.03, bevelSegments: 2, material: "plastic.frosted"), Xform(translation: V3(0.12, shelfYs[2] + 0.073, shelfZ + 0.02)))
            }
            // Freezer drawer: stainless front, gasket, dark runners, horizontal bar handle.
            let fy = (kick + 0.005 + freezerTop) / 2, fh = freezerTop - kick - 0.005
            add(rb(V3(W - 0.006, fh, 0.045), V3(0, fy, zFront - 0.0225), door, r: 0.008))
            add(rb(V3(W - 0.06, fh - 0.05, 0.02), V3(0, fy, zDoorBack - 0.003), white, r: 0.004, seg: 1))
            add(rb(V3(W - 0.04, 0.012, 0.012), V3(0, kick + 0.008, zDoorBack + 0.001), gasketM, r: 0.003, seg: 1))
            if hi {
                let hy = freezerTop - 0.07
                let hl = W - 0.2
                m.add(Prim.cylinder(radius: 0.0125, height: hl, bevel: 0.004, segments: 16, material: "metal.stainless"),
                      Xform(translation: V3(-hl / 2, hy, zFront + 0.0275), rotation: simd_quatf(degrees: -90, axis: V3(0, 0, 1))))
                for sx: Float in [-1, 1] { post(&m, sx * (hl / 2 - 0.03), hy, zFront, 0.0275, 0.009, "metal.stainless") }
            }
            // Hinge caps on the top corners.
            if hi { for sx: Float in [-1, 1] {
                add(rb(V3(0.06, 0.012, 0.055), V3(sx * (W / 2 - 0.045), H - 0.006, zDoorBack - 0.02), dark, r: 0.004, seg: 1))
            }}
            rig.base[l] = m
        }

        // Doors: pivots on the outer vertical edges at the gasket plane.
        let px = W / 2 - 0.0025
        rig.part("left-door", pivot: V3(-px, dcy, zDoorBack), joint: .hinge(axis: .up, -110...0, duration: 1.1))
        rig.part("right-door", pivot: V3(px, dcy, zDoorBack), joint: .hinge(axis: .up, 0...110, duration: 1.1))
        for (name, sx) in [("left-door", Float(-1)), ("right-door", Float(1))] {
            let cx = sx * (0.0025 + dw / 2)
            // Skin and inner liner.
            rig.add(Prim.roundedBox(V3(dw, dh, 0.024), radius: 0.009, bevelSegments: 2, material: door), Xform(translation: V3(cx, dcy, zFront - 0.012)).jittered(&rng, deg: 0.02, offset: 0.0002), to: name)
            rig.add(Prim.roundedBox(V3(dw - 0.012, dh - 0.012, doorT - 0.024), radius: 0.006, bevelSegments: 2, material: white), Xform(translation: V3(cx, dcy, zFront - 0.024 - (doorT - 0.024) / 2)), to: name)
            // Gasket frame on the closing face.
            let gz = zDoorBack + 0.0015
            var g = Model(name: "gasket")
            g.add(cuboid(V3(dw - 0.03, 0.016, 0.006), material: gasketM), Xform(translation: V3(cx, dcy + dh / 2 - 0.016, gz)))
            g.add(cuboid(V3(dw - 0.03, 0.016, 0.006), material: gasketM), Xform(translation: V3(cx, dcy - dh / 2 + 0.016, gz)))
            for ex: Float in [-1, 1] { g.add(cuboid(V3(0.016, dh - 0.03, 0.006), material: gasketM), Xform(translation: V3(cx + ex * (dw / 2 - 0.022), dcy, gz))) }
            rig.add(g, to: name, lod: 0)
            rig.add(g, to: name, lod: 1)
            // Door bins: three clear trays with white rails on the inner face.
            var bins = Model(name: "bins")
            for (i, by) in [dcy - 0.33, dcy - 0.02, dcy + 0.29].enumerated() {
                tray(&bins, x: cx, y: by, zBackFace: zDoorBack - 0.002, w: dw - 0.1, h: i == 0 ? 0.12 : 0.1, d: 0.055, mat: "plastic.clear")
                bins.add(cuboid(V3(dw - 0.1, 0.012, 0.006), material: white), Xform(translation: V3(cx, by + (i == 0 ? 0.12 : 0.1), zDoorBack - 0.058)))
            }
            rig.add(bins, to: name, lod: 0)
            // Vertical bar handle near the meeting edge, 0.7 m, on two standoffs.
            let hx = sx * (0.0025 + 0.05)
            var h = Model(name: "handle")
            h.add(Prim.cylinder(radius: 0.0125, height: 0.7, bevel: 0.004, segments: 16, bevelSegments: 1, material: "metal.stainless"),
                  Xform(translation: V3(hx, 0.95, zFront + 0.0275)))
            for hy: Float in [0.99, 1.61] { post(&h, hx, hy, zFront, 0.0275, 0.009, "metal.stainless") }
            rig.add(h, to: name, lod: 0)
            rig.add(h, to: name, lod: 1)
        }
        // Touch control on the left door.
        rig.add(Prim.roundedBox(V3(0.11, 0.05, 0.004), radius: 0.004, bevelSegments: 2, material: "screen.off"), Xform(translation: V3(-0.38 + 0.12, 1.69, zFront + 0.001)), to: "left-door", lods: 0...0)
        rig.add(cuboid(V3(0.03, 0.006, 0.0015), material: "emissive.indicator"), Xform(translation: V3(-0.26, 1.69, zFront + 0.0035)), to: "left-door", lods: 0...0)

        groundAO(&rig, height: 0.3, floor: 0.6)
        rig.states = [RigState("closed"), RigState("left-open", ["left-door": -110]),
                      RigState("right-open", ["right-door": 110]), RigState("both-open", ["left-door": -110, "right-door": 110])]
        return rig
    }
}
