import simd
import Foundation

/// Quick disconnect: new brushed stainless dry-break liquid cooling coupling, UQD style, blue supply ring. Parts: stainless body, knurled sleeve, color ring, barbed hose tail, EPDM hose stub, latch button, poppet face.
public struct QuickDisconnect: RealArticulated {
    public static let id = "quick-disconnect"
    public static let summary = "Dry-break liquid cooling quick disconnect: knurled sleeve, color ring, barbed tail, hose stub, latch; the sleeve slides when coupled."
    public static let tags = ["prop", "handheld", "articulated"]
    public static let budget = 1500
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Hose tail at -z, poppet face at +z.
    public var size = V3(0.03, 0.03, 0.08)
    /// Color ring: blue for supply, red for return.
    public var ring: MaterialKey = "plastic.matte:1F6FD0"
    /// Body, barbs and sleeve metal.
    public var metal: MaterialKey = "metal.stainless:D2D6DA"
    /// EPDM hose stub.
    public var hose: MaterialKey = "rubber.tubing:1A1A1A"
    /// Sleeve travel when coupled, meters.
    public var travel: Float = 0.008
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 1, switchDistances: [])
        var base = Model(name: Self.id)
        let cy = size.y / 2
        let q = simd_quatf(degrees: 90, axis: V3(1, 0, 0))   // lathe +Y becomes +Z
        func axial(_ pts: [(Float, Float)], z0: Float, seg: Int = 14, mat: MaterialKey) -> (Surface, Xform) {
            (Prim.lathe(pts.map { V2($0.0, $0.1) }, segments: seg, seamTile: 0.02, material: mat), Xform(translation: V3(0, cy, z0), rotation: q))
        }
        // Hose stub with a slight bulge, then barbs under its end.
        let (h, hx) = axial([(0, 0), (0.0072, 0), (0.0090, 0.0015), (0.0092, 0.0055), (0.0088, 0.0098), (0.0072, 0.0105)], z0: -0.04, seg: 10, mat: hose)
        base.add(h, hx)
        var barb: [(Float, Float)] = [(0.0062, 0)]
        for k in 0..<3 {
            let y = 0.0040 + Float(k) * 0.0032
            barb += [(0.0062, y - 0.0022), (0.0086, y), (0.0070, y + 0.0004)]
        }
        barb += [(0.0070, 0.0125)]
        let (b, bx) = axial(barb, z0: -0.034, seg: 10, mat: metal)
        base.add(b, bx)
        // Body: hex collar, shoulder, main barrel, nose with poppet.
        let (body, bodyX) = axial([(0, 0), (0.0090, 0), (0.0105, 0.001), (0.0105, 0.0285), (0.0100, 0.030), (0.0100, 0.052), (0.0092, 0.0535), (0.0090, 0.0605), (0.0080, 0.0615), (0, 0.0615)], z0: -0.0215, mat: metal)
        base.add(body, bodyX)
        base.add(Prim.cylinder(radius: 0.0124, height: 0.0052, bevel: 0, segments: 6, material: metal),
                 Xform(translation: V3(0, cy, -0.0171), rotation: q))
        // Poppet: dark seat ring and a small steel poppet recessed in the nose.
        let (seat, seatX) = axial([(0, 0), (0.0068, 0), (0.0068, 0.0004), (0, 0.0004)], z0: 0.0396, seg: 12, mat: "plastic.matte:0A0A0B")
        base.add(seat, seatX)
        let (pop, popX) = axial([(0, 0), (0.0034, 0), (0.0036, 0.0006), (0.0030, 0.0012), (0, 0.0012)], z0: 0.0394, seg: 12, mat: "metal.steel")
        base.add(pop, popX)
        // Color ring seated against the collar.
        let (rg, rgX) = axial([(0.0104, 0), (0.0125, 0), (0.0128, 0.0008), (0.0128, 0.0032), (0.0125, 0.004), (0.0104, 0.004)], z0: -0.0115, seg: 16, mat: ring)
        base.add(rg, rgX)
        // Latch button on top with a ridge and a pin hole.
        base.add(Prim.roundedBox(V3(0.0075, 0.0032, 0.0085), radius: 0.0010, bevelSegments: 1, material: ring),
                 Xform(translation: V3(0, cy + 0.0118, -0.0026)))
        base.add(cuboid(V3(0.0045, 0.0005, 0.0008), material: "plastic.matte:101112"), Xform(translation: V3(0, cy + 0.0136, -0.0026)))
        groundAO(&base)
        rig.base[0] = base

        // Sleeve: knurled collar that slides back on the body when coupled.
        let s0: Float = 0.0095, sL: Float = 0.0255
        rig.part("sleeve", pivot: V3(0, cy, s0), joint: .slide(axis: V3(0, 0, -1), 0...travel, duration: 0.5))
        let (sl, slX) = axial([(0.0112, 0), (0.0128, 0), (0.0134, 0.0008), (0.0134, 0.0095), (0.0128, 0.0105), (0.0128, sL - 0.0025), (0.0120, sL - 0.0008), (0.0104, sL), (0.0104, 0.0125), (0.0112, 0.0125)], z0: s0, mat: metal)
        rig.add(sl, slX, to: "sleeve")
        // Axial knurl ribs on the grip section, plus a smooth band at the front.
        let n = 15
        for i in 0..<n {
            let a = Float(i) / Float(n) * 2 * .pi
            let r: Float = 0.0136
            rig.add(cuboid(V3(0.0011, 0.0013, 0.0125), material: metal),
                    Xform(translation: V3(cos(a) * r, cy + sin(a) * r, s0 + 0.0125), rotation: simd_quatf(angle: a, axis: V3(0, 0, 1))), to: "sleeve")
        }
        // Reference tick on the sleeve front.
        rig.add(cuboid(V3(0.0012, 0.0003, 0.0035), material: "plastic.matte:101112"), Xform(translation: V3(0, cy + 0.0129, s0 + sL - 0.006)), to: "sleeve")
        rig.states = [RigState("uncoupled"), RigState("coupled", ["sleeve": travel])]
        return rig
    }
}
