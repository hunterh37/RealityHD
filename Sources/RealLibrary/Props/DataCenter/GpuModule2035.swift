import simd
import Foundation

/// GPU module 2035: OAM-style liquid-cooled accelerator module, green PCB, nickel lid, copper cold plate lifted above the package.
public struct GpuModule2035: RealArticulated {
    public static let id = "gpu-module-2035"
    public static let summary = "OAM-style GPU module with PCB, lidded package, HBM stacks, connectors and an articulated cold plate that lifts off."
    public static let tags = ["prop", "articulated"]
    public static let budget = 8000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 30, distance: 0.45, studio: true)

    /// Overall size in meters (x width, y height seated, z depth).
    public var size = V3(0.12, 0.023, 0.18)
    /// Package lid material key.
    public var lid: MaterialKey = "metal.nickel"
    /// Cold plate base material key.
    public var copper: MaterialKey = "copper.polished"
    /// Travel of the cold plate lift in meters.
    public var lift: Float = 0.045
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        var rng = SeededRNG(seed: seed)
        var rig = Rig(name: Self.id, lods: 1)
        let W = size.x, D = size.z
        let pcbT: Float = 0.0016
        func base(_ s: Surface, _ p: V3, _ r: simd_quatf = .identity) { rig.base[0].add(s, Xform(translation: p, rotation: r)) }
        func rb(_ s: V3, _ r: Float, _ mat: MaterialKey) -> Surface { r < 0.0013 && min(s.x, s.y, s.z) < 0.005 ? cuboid(s, material: mat) : Prim.roundedBox(s, radius: r, bevelSegments: 1, material: mat) }
        // PCB with rounded corners, solder-mask green, mounting holes as dark rings.
        base(Prim.extrude(Shape2D.rounded(Shape2D.rect(W, D), radius: 0.004, segments: 3), depth: pcbT, bevel: 0.0003, bevelSegments: 1, material: "plastic.pcb"),
             V3(0, pcbT / 2, 0), simd_quatf(degrees: 90, axis: V3(1, 0, 0)))
        // Package: substrate, 8 HBM stacks, die under lid, capacitors on the substrate edge.
        let sub = V3(0.078, 0.0012, 0.092)
        let subC = V3(0, pcbT + 0.0006, -0.006)
        base(rb(sub, 0.0006, "plastic.matte:2B3A2A"), subC)
        for sx: Float in [-1, 1] { for k in 0..<4 {
            base(rb(V3(0.0115, 0.0008, 0.0105), 0.0003, "metal.anodized-black"), V3(sx * 0.0305, pcbT + 0.0012 + 0.0004, subC.z - 0.033 + Float(k) * 0.022))
            base(rb(V3(0.0115, 0.00015, 0.0105), 0.0001, "metal.tungsten-carbide"), V3(sx * 0.0305, pcbT + 0.0012 + 0.0009, subC.z - 0.033 + Float(k) * 0.022))
        } }
        base(rb(V3(0.05, 0.0009, 0.05), 0.0004, "metal.anodized-black"), V3(0, pcbT + 0.0012 + 0.00045, subC.z))
        // Lid with stepped rim and etched marking plate.
        let lidY = pcbT + 0.0012 + 0.0009
        base(rb(V3(0.054, 0.0016, 0.054), 0.0012, lid), V3(0, lidY + 0.0008, subC.z))
        base(rb(V3(0.042, 0.0004, 0.042), 0.0006, lid), V3(0, lidY + 0.0016 + 0.0002, subC.z))
        base(rb(V3(0.022, 0.0002, 0.006), 0.0001, "metal.stainless"), V3(0.006, lidY + 0.0020, subC.z + 0.014))
        for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
            base(rb(V3(0.0036, 0.0008, 0.0036), 0.0004, lid), V3(sx * 0.0275, lidY + 0.0004 + 0.0004, subC.z + sz * 0.0275))
        } }
        // Decoupling capacitors on the substrate rim and VRM chokes on the PCB.
        for i in 0..<14 {
            let sx: Float = i % 2 == 0 ? -1 : 1
            base(rb(V3(0.0016, 0.0008, 0.0008), 0.0002, "metal.brass"), V3(sx * 0.0345, pcbT + 0.0012 + 0.0004 + 0.0001, subC.z - 0.04 + Float(i / 2) * 0.0125))
        }
        for sx: Float in [-1, 1] { for k in 0..<4 {
            let p = V3(sx * 0.049, pcbT, subC.z - 0.036 + Float(k) * 0.024)
            base(rb(V3(0.009, 0.0042, 0.0085), 0.0008, "plastic.matte:1A1B1E"), p + V3(0, 0.0021, 0))
            base(rb(V3(0.009, 0.0004, 0.002), 0.0002, "metal.nickel"), p + V3(0, 0.0044, 0.0028))
        } }
        for i in 0..<9 {
            base(rb(V3(0.0022, 0.0035, 0.0022), 0.0006, "metal.aluminum"), V3(-0.045 + Float(i) * 0.0112, pcbT + 0.00175, 0.074))
        }
        // Edge connectors (two OAM blocks) on the rear short edge, signal pins visible.
        for sx: Float in [-1, 1] {
            base(rb(V3(0.04, 0.0062, 0.008), 0.0006, "plastic.matte:D8D2B8"), V3(sx * 0.028, pcbT + 0.0031, -D / 2 + 0.006))
            for k in 0..<10 { base(rb(V3(0.0014, 0.0004, 0.0014), 0.0002, "metal.brass"), V3(sx * 0.028 - 0.0165 + Float(k) * 0.0037, pcbT + 0.0064, -D / 2 + 0.006)) }
        }
        // Corner standoffs for the cold plate screws.
        let sp: [V3] = [V3(-0.049, 0, 0.078), V3(0.049, 0, 0.078), V3(-0.049, 0, -0.076), V3(0.049, 0, -0.076)]
        for p in sp {
            base(Prim.cylinder(radius: 0.0038, height: 0.0085, bevel: 0.0004, segments: 10, material: "metal.brass"), V3(p.x, pcbT, p.z))
            base(Prim.cylinder(radius: 0.0031, height: 0.0075, bevel: 0.0003, segments: 8, material: "metal.stainless"), V3(p.x, pcbT + 0.0085, p.z))
        }
        // Cold plate lift: copper base, nickel cover, barbed ports, four captive screws.
        rig.part("cold-plate-lift", pivot: V3(0, 0, 0), joint: .slide(axis: V3(0, 1, 0), 0...lift, duration: 0.9))
        let cy: Float = 0.0100
        func lp(_ s: Surface, _ p: V3, _ r: simd_quatf = .identity) { rig.add(s, Xform(translation: p, rotation: r), to: "cold-plate-lift") }
        lp(Prim.extrude(Shape2D.rounded(Shape2D.rect(W - 0.012, 0.15), radius: 0.005, segments: 3), depth: 0.003, bevel: 0.0007, bevelSegments: 1, material: copper),
           V3(0, cy + 0.0015, -0.0), simd_quatf(degrees: 90, axis: V3(1, 0, 0)))
        lp(rb(V3(0.074, 0.0046, 0.1), 0.002, "metal.nickel"), V3(0, cy + 0.003 + 0.0023, 0))
        lp(rb(V3(0.062, 0.0016, 0.088), 0.001, "metal.nickel"), V3(0, cy + 0.0076 + 0.0008, 0))
        for (sz, cap) in [(Float(-1), "plastic.matte:2A5CB8"), (Float(1), "plastic.matte:B51D17")] {
            let pz = sz * 0.034
            lp(Prim.cylinder(radius: 0.0042, height: 0.003, bevel: 0.0004, segments: 10, material: "metal.nickel"), V3(0.012, cy + 0.0085, pz))
            lp(Prim.lathe([V2(0.0034, 0), V2(0.0046, 0.001), V2(0.0046, 0.0016), V2(0.0034, 0.0026)], segments: 10, material: "metal.nickel"), V3(0.012, cy + 0.0112, pz))
            lp(Prim.cylinder(radius: 0.0044, height: 0.0016, bevel: 0.0005, segments: 10, material: cap), V3(0.012, cy + 0.0128, pz))
        }
        for p in sp {
            lp(Prim.cylinder(radius: 0.0026, height: 0.0016, bevel: 0.0004, segments: 10, material: "metal.nickel"), V3(p.x, cy + 0.0035, p.z))
            lp(Prim.cylinder(radius: 0.0011, height: 0.011, bevel: 0.0002, segments: 8, material: "metal.nickel"), V3(p.x, cy - 0.0085, p.z))
        }
        // Silicone thermal gasket ring under the plate.
        lp(rb(V3(0.066, 0.0008, 0.094), 0.0004, "plastic.matte:3A3C40"), V3(0, cy - 0.0004, 0))
        // Story detail: fingerprint-smudged corner chip in the PCB mask.
        base(rb(V3(0.004, 0.0002, 0.003), 0.0001, "metal.copper"), V3(-0.054, pcbT + 0.0001, -0.083))
        _ = rng.float()
        groundAO(&rig, height: 0.02, floor: 0.6)
        rig.states = [RigState("seated", ["cold-plate-lift": 0]), RigState("lifted", ["cold-plate-lift": lift])]
        rig.defaultState = "seated"
        return rig
    }
}
