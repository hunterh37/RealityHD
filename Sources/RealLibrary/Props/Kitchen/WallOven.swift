import simd
import Foundation

/// Double wall oven tower, 30 in: stainless shell, two drop-down doors with black glass windows and
/// bar handles, a touch control strip with display and two dials above the upper oven, a divider trim
/// with a vent slot, and two enamel cavities with wire racks, broil elements and lamps. The upper door
/// is the joint `upper-door` (0...90 degrees, hinged at its bottom edge); the lower door is fixed.
public struct WallOven: RealArticulated {
    public static let id = "wall-oven"
    public static let summary = "Double wall oven tower, 30 in: stainless drop-down doors with bar handles and glass windows, touch control strip, two lit racked cavities."
    public static let tags = ["prop", "floorplan", "kitchen", "appliance", "metal", "interior", "articulated"]
    public static let budget = 10000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 10, distance: 3.0, studio: true)

    /// Overall size in meters including handles (x width, y height, z depth).
    public var size = V3(0.76, 1.3, 0.6)
    /// Shell and door skin.
    public var shell: MaterialKey = "metal.stainless"
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        var rng = SeededRNG(seed: seed)
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [6])
        let W = size.x, H = size.y, D = size.z
        let zFront = D / 2 - 0.04
        let doorT: Float = 0.06
        let zDoorBack = zFront - doorT
        let zBack = -D / 2
        let wall: Float = 0.015
        let dark: MaterialKey = "plastic.matte:2A2A2C"
        let enamel: MaterialKey = "metal.oven-enamel"
        let wire: MaterialKey = "metal.rack-powdercoat"
        let gasketM: MaterialKey = "rubber.silicone-gray"
        let lowD: (Float, Float) = (0.015, 0.640)
        let upD: (Float, Float) = (0.690, 1.170)
        let inW = W - 2 * wall
        let dW = W - 2 * wall - 0.004

        func rb(_ s: V3, _ c: V3, _ mat: MaterialKey, r: Float = 0.003) -> (Surface, Xform) {
            (r <= 0.0025 ? cuboid(s, material: mat) : Prim.roundedBox(s, radius: r, bevelSegments: 1, material: mat), Xform(translation: c))
        }
        /// Door in asset space at rest: skin, window, inner panel, gasket, handle.
        func door(_ lo: Float, _ hi: Float, detail: Bool) -> Model {
            var d = Model(name: "door")
            let h = hi - lo, cy = (lo + hi) / 2
            d.add(Prim.roundedBox(V3(dW, h, 0.016), radius: 0.007, bevelSegments: 2, material: shell), Xform(translation: V3(0, cy, zFront - 0.008)))
            // Black glass window.
            d.add(Prim.roundedBox(V3(dW - 0.1, h - 0.13, 0.004), radius: 0.003, bevelSegments: 1, material: "screen.off"), Xform(translation: V3(0, cy - 0.025, zFront + 0.0005)))
            d.add(cuboid(V3(dW - 0.04, h - 0.04, 0.044), material: "metal.stainless-smudged"), Xform(translation: V3(0, cy, zFront - 0.038)))
            d.add(cuboid(V3(dW - 0.08, 0.008, 0.004), material: gasketM), Xform(translation: V3(0, hi - 0.03, zDoorBack - 0.001)))
            d.add(cuboid(V3(dW - 0.08, 0.008, 0.004), material: gasketM), Xform(translation: V3(0, lo + 0.03, zDoorBack - 0.001)))
            for sx: Float in [-1, 1] { d.add(cuboid(V3(0.008, h - 0.08, 0.004), material: gasketM), Xform(translation: V3(sx * (dW / 2 - 0.04), cy, zDoorBack - 0.001))) }
            // Bar handle across the top.
            let hl = dW - 0.16, hy = hi - 0.04
            d.add(Prim.cylinder(radius: 0.0125, height: hl, bevel: 0.004, segments: 16, bevelSegments: 1, material: "metal.stainless"),
                  Xform(translation: V3(-hl / 2, hy, zFront + 0.0275), rotation: simd_quatf(degrees: -90, axis: V3(0, 0, 1))))
            if detail { for sx: Float in [-1, 1] {
                d.add(Prim.cylinder(radius: 0.009, height: 0.0275, bevel: 0.002, segments: 12, bevelSegments: 1, material: "metal.stainless"),
                      Xform(translation: V3(sx * (hl / 2 - 0.03), hy, zFront), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
            }} else { for sx: Float in [-1, 1] { d.add(cuboid(V3(0.016, 0.016, 0.0275), material: "metal.stainless"), Xform(translation: V3(sx * (hl / 2 - 0.03), hy, zFront + 0.0137))) } }
            return d
        }
        func cavity(_ m: inout Model, _ lo: Float, _ hi: Float, racks: [Float], detail: Bool) {
            let zc = (zBack + 0.02 + zDoorBack) / 2
            var cav = Prim.roundedBox(V3(inW - 0.04, hi - lo, zDoorBack - zBack - 0.02), radius: 0.01, bevelSegments: 1, material: enamel).flipped()
            cav = cav.transformed(Xform(translation: V3(0, (lo + hi) / 2, zc)))
            m.add(cav)
            let rw = inW - 0.07, rd = zDoorBack - zBack - 0.08
            for y in racks {
                for sx: Float in [-1, 1] {
                    m.add(cuboid(V3(0.005, 0.005, rd), material: wire), Xform(translation: V3(sx * rw / 2, y, zc)))
                    if detail { m.add(cuboid(V3(0.005, 0.03, 0.005), material: wire), Xform(translation: V3(sx * rw / 2, y - 0.012, zc + rd / 2))) }
                }
                m.add(cuboid(V3(rw, 0.005, 0.005), material: wire), Xform(translation: V3(0, y, zc + rd / 2)))
                m.add(cuboid(V3(rw, 0.005, 0.005), material: wire), Xform(translation: V3(0, y, zc - rd / 2)))
                for i in 1..<(detail ? 14 : 6) { m.add(cuboid(V3(0.004, 0.004, rd), material: wire), Xform(translation: V3(-rw / 2 + Float(i) * rw / (detail ? 14 : 6), y, zc))) }
                if detail { for i in 1..<6 { m.add(cuboid(V3(rw, 0.004, 0.004), material: wire), Xform(translation: V3(0, y, zc - rd / 2 + Float(i) * rd / 6))) } }
            }
            // Bake element and lamp.
            m.add(cuboid(V3(inW - 0.12, 0.008, 0.012), material: "metal.heat-tint"), Xform(translation: V3(0, hi - 0.03, zc)))
            m.add(cuboid(V3(0.03, 0.03, 0.01), material: "emissive.warm"), Xform(translation: V3(-(inW / 2 - 0.045), hi - 0.1, zc - 0.05)))
        }

        for l in 0..<2 {
            let hi = l == 0
            var m = Model(name: Self.id)
            func add(_ b: (Surface, Xform)) { m.add(b.0, b.1) }
            let zl = zDoorBack - zBack, zc = (zBack + zDoorBack) / 2
            for sx: Float in [-1, 1] { add(rb(V3(wall, H - 0.01, zl), V3(sx * (W / 2 - wall / 2), 0.01 + (H - 0.01) / 2, zc), shell, r: 0.005)) }
            add(rb(V3(W, 0.015, zl), V3(0, H - 0.0075, zc), shell, r: 0.005))
            add(rb(V3(inW, H - 0.025, 0.012), V3(0, H / 2, zBack + 0.006), "metal.galvanized", r: 0.002))
            add(rb(V3(inW, 0.012, zl), V3(0, 0.012, zc), shell, r: 0.002))
            add(rb(V3(0.7, 0.012, 0.03), V3(0, 0.006, zFront - 0.04), dark, r: 0.002))
            // Fill between and behind cavities (dividers).
            add(rb(V3(inW, upD.0 - lowD.1 + 0.03, zl - 0.01), V3(0, (lowD.1 + upD.0) / 2, zc - 0.005), shell, r: 0.002))
            // Divider trim with vent slot.
            add(rb(V3(dW, 0.05, 0.016), V3(0, (lowD.1 + upD.0) / 2, zFront - 0.008), shell, r: 0.004))
            add(rb(V3(dW - 0.2, 0.01, 0.004), V3(0, (lowD.1 + upD.0) / 2, zFront + 0.0005), dark, r: 0.002))
            // Control strip above the upper door.
            let cy = (upD.1 + H) / 2 - 0.004
            add(rb(V3(dW, H - upD.1 - 0.008, 0.016), V3(0, cy, zFront - 0.008), shell, r: 0.005))
            add(rb(V3(dW - 0.14, H - upD.1 - 0.04, 0.004), V3(0, cy, zFront + 0.0005), "screen.off", r: 0.002))
            add(rb(V3(0.12, 0.028, 0.002), V3(0, cy + 0.005, zFront + 0.0025), "emissive.led-green:E8E8E0", r: 0.001))
            if hi {
                for i in 0..<4 { m.add(cuboid(V3(0.03, 0.004, 0.002), material: "emissive.led-green:9FB0C0"), Xform(translation: V3(-0.15 + Float(i) * 0.1, cy - 0.032, zFront + 0.0025))) }
                for sx: Float in [-1, 1] {
                    m.add(Prim.cylinder(radius: 0.024, height: 0.022, bevel: 0.004, segments: 20, bevelSegments: 1, material: "metal.stainless"),
                          Xform(translation: V3(sx * 0.3, cy, zFront - 0.002), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
                    m.add(cuboid(V3(0.003, 0.014, 0.002), material: "plastic.white"), Xform(translation: V3(sx * 0.3, cy + 0.01, zFront + 0.0205)))
                }
            }
            cavity(&m, lowD.0 + 0.02, lowD.1 - 0.02, racks: [0.2, 0.36], detail: hi)
            cavity(&m, upD.0 + 0.02, upD.1 - 0.02, racks: [0.82, 0.98], detail: hi)
            if hi { m.add(Prim.roundedBox(V3(0.5, 0.016, 0.36), radius: 0.004, bevelSegments: 1, material: "metal.sheet-pan"), Xform(translation: V3(0.0, 0.2 + 0.0105, zc - 0.01)).jittered(&rng, deg: 0.1, offset: 0.001)) }
            m.add(door(lowD.0, lowD.1, detail: hi))
            rig.base[l] = m
        }

        rig.part("upper-door", pivot: V3(0, upD.0, zFront - doorT / 2), joint: .hinge(axis: V3(1, 0, 0), 0...90, duration: 1.2))
        rig.add(door(upD.0, upD.1, detail: true), to: "upper-door", lod: 0)
        rig.add(door(upD.0, upD.1, detail: false), to: "upper-door", lod: 1)
                groundAO(&rig, height: 0.2, floor: 0.7)
        rig.states = [RigState("closed"), RigState("upper-open", ["upper-door": 90])]
        return rig
    }
}
