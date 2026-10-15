import simd
import Foundation

/// Front-load washing machine, 27 in: white enamel cabinet on black feet, control fascia with a
/// detergent drawer, display, buttons and a cycle dial, a round bezel around the drum opening with a
/// dark rubber boot, and a left-hinged porthole door with a chrome ring and a domed glass window. The
/// stainless drum with lifters shows when the door is open. Door joint `door` (0...-170 degrees), dial
/// joint `dial` (0...330 degrees).
public struct WashingMachine: RealArticulated {
    public static let id = "washing-machine"
    public static let summary = "Front-load washing machine, 27 in: white cabinet, porthole door with chrome ring and glass dome, drawer, display and dial fascia."
    public static let tags = ["prop", "floorplan", "laundry", "appliance", "metal", "interior", "articulated"]
    public static let budget = 9000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 14, distance: 2.6, studio: true)

    /// Overall size in meters including the door dome (x width, y height, z depth).
    public var size = V3(0.69, 0.98, 0.79)
    /// Cabinet enamel.
    public var enamel: MaterialKey = "metal.powder-white"
    /// Drum center height.
    public var drumY: Float = 0.47
    public init() {}

    /// Door dome standoff in front of the front plate.
    static let domeOut: Float = 0.071

    public func rig(seed: UInt64) -> Rig {
        var rng = SeededRNG(seed: seed)
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [5])
        let W = size.x, H = size.y, D = size.z
        let zp = D / 2 - Self.domeOut             // front plate plane
        let zBack = -D / 2
        let cy = drumY
        let white: MaterialKey = "plastic.white"
        let dark: MaterialKey = "plastic.matte:1C1C1E"
        let boot: MaterialKey = "rubber.silicone-gray:2A2A2C"
        let stripLo: Float = 0.86
        let plate: Float = 0.012
        let hole: Float = 0.2

        func rb(_ s: V3, _ c: V3, _ mat: MaterialKey, r: Float = 0.003) -> (Surface, Xform) {
            (r <= 0.0025 ? cuboid(s, material: mat) : Prim.roundedBox(s, radius: r, bevelSegments: 1, material: mat), Xform(translation: c))
        }
        /// Revolve a profile (r, height along the opening axis) around +Z at (x, y, z).
        func disc(_ prof: [V2], _ c: V3, _ mat: MaterialKey, segs: Int, flip: Bool = false) -> (Surface, Xform) {
            var s = Prim.lathe(prof, segments: segs, seamTile: 0.5, material: mat)
            if flip { s = s.flipped() }
            return (s, Xform(translation: c, rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        }

        for l in 0..<2 {
            let hi = l == 0
            let segs = hi ? 40 : 20
            var m = Model(name: Self.id)
            func add(_ b: (Surface, Xform)) { m.add(b.0, b.1) }
            let zl = zp - zBack, zc = (zBack + zp) / 2
            // Cabinet: sides, top, back, base.
            for sx: Float in [-1, 1] { add(rb(V3(0.018, H - 0.02, zl), V3(sx * (W / 2 - 0.009), 0.02 + (H - 0.02) / 2, zc), enamel, r: 0.004)) }
            add(rb(V3(W, 0.02, zl), V3(0, H - 0.01, zc), enamel, r: 0.005))
            add(rb(V3(W - 0.036, H - 0.04, 0.01), V3(0, 0.02 + (H - 0.04) / 2, zBack + 0.005), enamel, r: 0.002))
            add(rb(V3(W - 0.036, 0.012, zl - 0.02), V3(0, 0.026, zc), dark, r: 0.002))
            for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
                m.add(Prim.cylinder(radius: 0.02, height: 0.025, bevel: 0.004, segments: 10, bevelSegments: 1, material: dark), Xform(translation: V3(sx * (W / 2 - 0.04), 0, zc + sz * (zl / 2 - 0.04))))
            }}
            // Front plate with a square hole behind the bezel.
            let fz = zp - plate / 2
            let fxl = (W - 2 * hole) / 2
            let frontH = stripLo - 0.03
            for sx: Float in [-1, 1] { add(rb(V3(fxl, frontH, plate), V3(sx * (hole + fxl / 2), 0.03 + frontH / 2, fz), enamel, r: 0.003)) }
            add(rb(V3(2 * hole, stripLo - (cy + hole), plate), V3(0, (stripLo + cy + hole) / 2, fz), enamel, r: 0.002))
            add(rb(V3(2 * hole, cy - hole - 0.03, plate), V3(0, (cy - hole + 0.03) / 2, fz), enamel, r: 0.002))
            // Drum: stainless cylinder with a lip and three lifters, boot and bezel.
            add(disc([V2(0.15, 0), V2(0.19, -0.015), V2(0.19, -0.30), V2(0, -0.30)], V3(0, cy, zp - 0.004), "metal.stainless", segs: segs, flip: true))
            add(disc([V2(0.15, 0), V2(0.17, -0.014), V2(0.19, -0.014), V2(0.19, -0.016)], V3(0, cy, zp - 0.004), "metal.stainless", segs: segs))
            if hi { for i in 0..<3 {
                let a = Float(i) * 2 * .pi / 3
                m.add(rb(V3(0.04, 0.26, 0.02), V3(0, 0, 0), "metal.stainless", r: 0.004).0, Xform(translation: V3(sin(a) * 0.178, cy + cos(a) * 0.178, zp - 0.15), rotation: simd_quatf(angle: -a, axis: V3(0, 0, 1)) * simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
            }}
            m.add(Prim.torus(major: 0.168, minor: 0.022, segments: segs, sides: hi ? 10 : 6, material: boot),
                  Xform(translation: V3(0, cy, zp + 0.002), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
            add(disc([V2(0.17, 0), V2(0.285, 0), V2(0.285, 0.008), V2(0.278, 0.012), V2(0.17, 0.012)], V3(0, cy, zp), white, segs: segs))
            // Control fascia: top strip with drawer, display, buttons and the dial pedestal.
            let sh = H - stripLo
            add(rb(V3(W - 0.018, sh, 0.034), V3(0, stripLo + sh / 2, zp - 0.017 + 0.004), white, r: 0.005))
            add(rb(V3(0.19, 0.075, 0.004), V3(-W / 2 + 0.13, stripLo + sh / 2 - 0.002, zp + 0.0025), "plastic.matte:E4E6E8", r: 0.002))
            add(rb(V3(0.15, 0.012, 0.004), V3(-W / 2 + 0.13, stripLo + sh / 2 - 0.016, zp + 0.0045), "plastic.matte:9EA2A6", r: 0.002))
            add(rb(V3(0.09, 0.034, 0.003), V3(0.03, stripLo + sh / 2 + 0.01, zp + 0.0025), "screen.off", r: 0.002))
            add(rb(V3(0.05, 0.016, 0.002), V3(0.03, stripLo + sh / 2 + 0.01, zp + 0.0045), "emissive.led-green:7FB8FF", r: 0.001))
            if hi { for i in 0..<4 {
                m.add(Prim.cylinder(radius: 0.008, height: 0.004, bevel: 0.001, segments: 10, bevelSegments: 1, material: "plastic.matte:C8CACD"),
                      Xform(translation: V3(-0.03 + Float(i) * 0.04, stripLo + 0.025, zp + 0.003), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
            }}
            rig.base[l] = m
        }

        // Dial: chrome-ringed knob at the right of the fascia.
        let dc = V3(W / 2 - 0.09, stripLo + (H - stripLo) / 2, zp + 0.002)
        rig.part("dial", pivot: dc, joint: .hinge(axis: V3(0, 0, 1), 0...330, duration: 0.8))
        rig.add(Prim.cylinder(radius: 0.03, height: 0.018, bevel: 0.004, segments: 24, bevelSegments: 1, material: "metal.satin-aluminum"), Xform(translation: dc, rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))), to: "dial")
        rig.add(cuboid(V3(0.004, 0.02, 0.002), material: white), Xform(translation: dc + V3(0, 0.015, 0.0185)), to: "dial", lods: 0...0)

        // Door: round porthole, hinge at the left edge.
        let dx: Float = 0.235
        rig.part("door", pivot: V3(-dx, cy, zp + 0.01), joint: .hinge(axis: .up, -170...0, duration: 1.4))
        let dcen = V3(0, cy, zp + 0.003)
        func dAdd(_ prof: [V2], _ mat: MaterialKey, _ segs: Int, flip: Bool = false, lods: ClosedRange<Int>? = nil) {
            var s = Prim.lathe(prof, segments: segs, seamTile: 0.5, material: mat)
            if flip { s = s.flipped() }
            rig.add(s, Xform(translation: dcen, rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))), to: "door", lods: lods)
        }
        // Chrome ring (closed section), white inner ring, glass dome.
        dAdd([V2(0.15, 0), V2(0.236, 0), V2(0.236, 0.034), V2(0.222, 0.046), V2(0.15, 0.04)], "metal.satin-aluminum", 40, lods: 0...0)
        dAdd([V2(0.15, 0), V2(0.236, 0), V2(0.236, 0.034), V2(0.222, 0.046), V2(0.15, 0.04)], "metal.satin-aluminum", 20, lods: 1...1)
        dAdd([V2(0.15, 0.036), V2(0.17, 0.038), V2(0.19, 0.03), V2(0.15, 0.02)], white, 32, lods: 0...0)
        dAdd([V2(0.152, 0.02), V2(0.15, 0.045), V2(0.13, 0.062), V2(0.08, 0.067), V2(0.0, 0.068)], "glass.tinted", 36, lods: 0...0)
        dAdd([V2(0.152, 0.02), V2(0.13, 0.062), V2(0.0, 0.068)], "glass.tinted", 18, lods: 1...1)
        dAdd([V2(0.15, 0.002), V2(0.15, 0.02)], "rubber.silicone-gray:2A2A2C", 28, lods: 0...0)
        // Latch hook on the free edge.
        rig.add(Prim.roundedBox(V3(0.02, 0.05, 0.012), radius: 0.003, bevelSegments: 1, material: "plastic.matte:C8CACD"), Xform(translation: dcen + V3(dx + 0.016, 0, 0.044)), to: "door", lods: 0...0)

        // Hinge knuckles on the left edge.
        for hy: Float in [-0.12, 0.12] {
            rig.add(Prim.roundedBox(V3(0.022, 0.07, 0.02), radius: 0.004, bevelSegments: 1, material: "metal.satin-aluminum"), Xform(translation: V3(-dx - 0.016, cy + hy, zp + 0.012)), to: "door", lods: 0...0)
        }
        groundAO(&rig, height: 0.15, floor: 0.7)
        rig.states = [RigState("closed"), RigState("door-open", ["door": -115])]
        _ = rng.float()
        return rig
    }
}
