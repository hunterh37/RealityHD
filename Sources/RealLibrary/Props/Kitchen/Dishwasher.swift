import simd
import Foundation

/// Built-in 24 in dishwasher: stainless door with a black control strip, indicator lights and a bar
/// handle, hinged at the bottom edge (joint `door`, 0...90 degrees); stainless tub with a spray arm, a
/// lower wire rack of plates and a cutlery basket, an upper rack with cups, and a toe kick.
public struct Dishwasher: RealArticulated {
    public static let id = "dishwasher"
    public static let summary = "Built-in 24 in dishwasher: stainless drop-down door with control strip and bar handle, steel tub, wire racks with plates and cups."
    public static let tags = ["prop", "floorplan", "kitchen", "appliance", "metal", "interior", "articulated"]
    public static let budget = 9000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 14, distance: 2.1, studio: true)

    /// Overall size in meters including the handle (x width, y height, z depth).
    public var size = V3(0.6, 0.86, 0.6)
    /// Door skin.
    public var door: MaterialKey = "metal.stainless"
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        var rng = SeededRNG(seed: seed)
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [5])
        let W = size.x, H = size.y, D = size.z
        let handleOut: Float = 0.04
        let zFront = D / 2 - handleOut
        let doorT: Float = 0.05
        let zDoorBack = zFront - doorT
        let zBack = -D / 2
        let kick: Float = 0.09
        let wall: Float = 0.012
        let dark: MaterialKey = "plastic.matte:2A2A2C"
        let wire: MaterialKey = "metal.rack-powdercoat"
        let tubM: MaterialKey = "metal.stainless-smudged"
        let inW = W - 2 * wall

        func rb(_ s: V3, _ c: V3, _ mat: MaterialKey, r: Float = 0.003) -> (Surface, Xform) {
            (r <= 0.0025 ? cuboid(s, material: mat) : Prim.roundedBox(s, radius: r, bevelSegments: 1, material: mat), Xform(translation: c))
        }
        /// Wire rack: perimeter frame, floor grid and rows of tines.
        func rack(_ m: inout Model, y: Float, w: Float, d: Float, zc: Float, h: Float, tines: Bool) {
            let t: Float = 0.005
            for sx: Float in [-1, 1] {
                m.add(cuboid(V3(t, t, d), material: wire), Xform(translation: V3(sx * w / 2, y, zc)))
                m.add(cuboid(V3(t, h, t), material: wire), Xform(translation: V3(sx * w / 2, y + h / 2, zc + d / 2)))
                m.add(cuboid(V3(t, h, t), material: wire), Xform(translation: V3(sx * w / 2, y + h / 2, zc - d / 2)))
                m.add(cuboid(V3(t, t, d), material: wire), Xform(translation: V3(sx * w / 2, y + h, zc)))
            }
            for sz: Float in [-1, 1] {
                m.add(cuboid(V3(w, t, t), material: wire), Xform(translation: V3(0, y, zc + sz * d / 2)))
                m.add(cuboid(V3(w, t, t), material: wire), Xform(translation: V3(0, y + h, zc + sz * d / 2)))
            }
            for i in 1..<9 { m.add(cuboid(V3(t * 0.8, t * 0.8, d), material: wire), Xform(translation: V3(-w / 2 + Float(i) * w / 9, y, zc))) }
            for i in 1..<6 { m.add(cuboid(V3(w, t * 0.8, t * 0.8), material: wire), Xform(translation: V3(0, y, zc - d / 2 + Float(i) * d / 6))) }
            if tines {
                for i in 0..<9 {
                    m.add(cuboid(V3(t * 0.7, h * 0.9, t * 0.7), material: wire), Xform(translation: V3(-w / 2 + (Float(i) + 0.5) * w / 9, y + h * 0.45, zc + d / 2 - 0.06)))
                }
            }
        }

        for l in 0..<2 {
            let hi = l == 0
            var m = Model(name: Self.id)
            func add(_ b: (Surface, Xform)) { m.add(b.0, b.1) }
            let zl = zDoorBack - zBack, zc = (zBack + zDoorBack) / 2
            for sx: Float in [-1, 1] { add(rb(V3(wall, H - kick, zl), V3(sx * (W / 2 - wall / 2), kick + (H - kick) / 2, zc), "metal.stainless", r: 0.004)) }
            add(rb(V3(W, 0.02, zl), V3(0, H - 0.01, zc), "metal.stainless", r: 0.004))
            add(rb(V3(inW, H - kick, 0.01), V3(0, kick + (H - kick) / 2, zBack + 0.005), "metal.galvanized", r: 0.002))
            add(rb(V3(W - 0.02, 0.012, zl), V3(0, kick + 0.006, zc), "metal.stainless", r: 0.002))
            // Kick plate with a shadow gap above the door.
            add(rb(V3(W - 0.02, kick - 0.004, 0.012), V3(0, kick / 2 + 0.002, zDoorBack + 0.01), dark, r: 0.003))
            // Tub interior (stainless, inside faces).
            let tubLo = kick + 0.02, tubHi = H - 0.025
            var tub = Prim.roundedBox(V3(inW - 0.01, tubHi - tubLo, zl - 0.03), radius: 0.015, bevelSegments: 2, material: tubM).flipped()
            tub = tub.transformed(Xform(translation: V3(0, (tubLo + tubHi) / 2, zc - 0.005)))
            m.add(tub)
            // Racks, spray arm, contents.
            let rw = inW - 0.05, rd = zl - 0.09, rz = zc - 0.01
            rack(&m, y: 0.17, w: rw, d: rd, zc: rz, h: 0.11, tines: hi)
            rack(&m, y: 0.46, w: rw - 0.02, d: rd - 0.06, zc: rz - 0.02, h: 0.07, tines: false)
            add(rb(V3(0.4, 0.014, 0.05), V3(0, 0.425, rz), "plastic.white", r: 0.005))
            add(rb(V3(0.03, 0.03, 0.03), V3(0, 0.44, rz), "plastic.white", r: 0.005))
            add(rb(V3(0.4, 0.012, 0.045), V3(0, 0.12, rz - 0.02), "plastic.white", r: 0.005))
            // Cutlery basket on the right of the lower rack.
            if hi {
                add(rb(V3(0.12, 0.1, 0.2), V3(0.19, 0.225, rz + 0.1), "plastic.matte:8E9094", r: 0.006))
                for i in 0..<4 {
                    let x = -0.17 + Float(i) * 0.075
                    m.add(Prim.cylinder(radius: 0.13, height: 0.012, bevel: 0.004, segments: 22, bevelSegments: 1, material: "ceramic.vitreous"),
                          Xform(translation: V3(x - 0.04, 0.235, rz - 0.05), rotation: simd_quatf(degrees: 90, axis: V3(0, 0, 1)) * simd_quatf(degrees: 8, axis: V3(0, 1, 0))))
                }
                for i in 0..<3 {
                    m.add(Prim.cylinder(radius: 0.04, height: 0.09, bevel: 0.004, segments: 14, bevelSegments: 1, material: "glass.clear"),
                          Xform(translation: V3(-0.14 + Float(i) * 0.12, 0.557, rz + rng.float(-0.04...0.04)), rotation: simd_quatf(degrees: 180, axis: V3(1, 0, 0))))
                }
            }
            rig.base[l] = m
        }

        // Door: hinge along the bottom edge, opens down toward +Z.
        let doorLo = kick + 0.004, doorH = H - doorLo, dcy = doorLo + doorH / 2
        rig.part("door", pivot: V3(0, doorLo, zFront - doorT / 2), joint: .hinge(axis: V3(1, 0, 0), 0...90, duration: 1.2))
        rig.add(Prim.roundedBox(V3(W - 0.004, doorH, 0.02), radius: 0.006, bevelSegments: 2, material: door), Xform(translation: V3(0, dcy, zFront - 0.01)).jittered(&rng, deg: 0.02, offset: 0.0002), to: "door")
        rig.add(cuboid(V3(W - 0.03, doorH - 0.04, 0.03), material: "metal.stainless-smudged"), Xform(translation: V3(0, dcy, zFront - 0.035)), to: "door")
        // Gasket and detergent dispenser on the inner face.
        var g = Model(name: "gasket")
        let gz = zDoorBack - 0.001
        g.add(cuboid(V3(W - 0.04, 0.014, 0.008), material: "rubber.silicone-gray"), Xform(translation: V3(0, doorLo + doorH - 0.03, gz)))
        g.add(cuboid(V3(W - 0.04, 0.014, 0.008), material: "rubber.silicone-gray"), Xform(translation: V3(0, doorLo + 0.03, gz)))
        for sx: Float in [-1, 1] { g.add(cuboid(V3(0.014, doorH - 0.06, 0.008), material: "rubber.silicone-gray"), Xform(translation: V3(sx * (W / 2 - 0.025), dcy, gz))) }
        g.add(Prim.roundedBox(V3(0.12, 0.09, 0.016), radius: 0.008, bevelSegments: 2, material: "plastic.white"), Xform(translation: V3(0.12, dcy + 0.12, gz - 0.006)))
        g.add(Prim.roundedBox(V3(0.07, 0.07, 0.01), radius: 0.006, bevelSegments: 1, material: "plastic.matte:8E9094"), Xform(translation: V3(-0.14, dcy + 0.12, gz - 0.004)))
        rig.add(g, to: "door", lod: 0)
        rig.add(g, to: "door", lod: 1)
        // Control strip, display and buttons along the top lip.
        let sy = H - 0.04
        rig.add(Prim.roundedBox(V3(W - 0.05, 0.05, 0.008), radius: 0.004, bevelSegments: 2, material: "screen.off"), Xform(translation: V3(0, sy, zFront + 0.002)), to: "door")
        rig.add(cuboid(V3(0.04, 0.012, 0.002), material: "emissive.led-green"), Xform(translation: V3(-0.2, sy, zFront + 0.0065)), to: "door", lods: 0...0)
        for i in 0..<5 {
            rig.add(Prim.cylinder(radius: 0.007, height: 0.003, bevel: 0.001, segments: 10, bevelSegments: 1, material: "metal.chrome"),
                    Xform(translation: V3(-0.07 + Float(i) * 0.05, sy, zFront + 0.0055), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))), to: "door", lods: 0...0)
        }
        // Bar handle on two standoffs.
        let hy = H - 0.12, hl: Float = 0.48
        var h = Model(name: "handle")
        h.add(Prim.cylinder(radius: 0.0125, height: hl, bevel: 0.004, segments: 16, bevelSegments: 1, material: "metal.stainless"),
              Xform(translation: V3(-hl / 2, hy, zFront + 0.0275), rotation: simd_quatf(degrees: -90, axis: V3(0, 0, 1))))
        for sx: Float in [-1, 1] {
            h.add(Prim.cylinder(radius: 0.009, height: 0.0275, bevel: 0.002, segments: 12, bevelSegments: 1, material: "metal.stainless"),
                  Xform(translation: V3(sx * (hl / 2 - 0.03), hy, zFront), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        }
        rig.add(h, to: "door", lod: 0)
        rig.add(h, to: "door", lod: 1)

        groundAO(&rig, height: 0.15, floor: 0.6)
        rig.states = [RigState("closed"), RigState("open", ["door": 90])]
        return rig
    }
}
