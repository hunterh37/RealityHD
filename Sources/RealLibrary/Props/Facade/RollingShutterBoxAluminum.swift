import simd
import Foundation

/// Roller shutter box, 1.4 m long, 0.3 m tall, 0.3 m projection: a powder-coated extruded aluminium housing with a
/// quarter-round front, a recessed exit slot in the underside lined with brush seals and carrying the slat curtain
/// down out of the box, a full-length inspection hatch with a finger groove and four screws, bolted end caps, short
/// extruded guide-rail stubs at both ends with brush strips, and a silicone bead along the wall joint. Wear: chalked
/// coat, grime run from the slot, chipped corners showing bare aluminium, pitting at the end caps, rust at screws.
public struct RollingShutterBoxAluminum: RealAsset {
    public static let id = "rolling-shutter-box-aluminum"
    public static let summary = "Aluminium roller shutter box 1.4x0.3x0.3 m: extruded housing, hatch, end caps, guide stubs."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 10, distance: 2.3)

    /// Powder coat of the housing and hatch.
    public var coat: MaterialKey = "metal.painted:E3DFD0"
    /// Bare extrusions (guides, caps).
    public var alu: MaterialKey = "metal.aluminum-brushed"
    /// Curtain slats.
    public var slat: MaterialKey = "metal.powdercoat-worn"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let L: Float = 1.392, capT: Float = 0.004
        let yb: Float = 0.058, yt: Float = 0.294, D: Float = 0.296
        let r: Float = 0.05                                                       // front quarter-round radius
        let slotZ0: Float = 0.188, slotZ1: Float = 0.238, slotDepth: Float = 0.026

        // Housing profile (z out from the wall, y up): flat top, quarter-round front, flat underside with the slot recess.
        var prof: [V2] = [V2(0, yb), V2(slotZ0, yb), V2(slotZ0, yb + slotDepth), V2(slotZ1, yb + slotDepth), V2(slotZ1, yb), V2(D - 0.02, yb), V2(D, yb + 0.012)]
        prof += [V2(D, yt - r)]
        for k in 1...8 {
            let a = Float(k) / 8 * (.pi / 2)
            prof.append(V2(D - r + r * cos(a), yt - r + r * sin(a)))
        }
        prof.append(V2(0, yt))
        FO.colX(&m, prof, x0: -L / 2, x1: L / 2, coat, bevel: 0.0025)

        // Slot interior: dark void, brush seals on both lips, curtain emerging as a slatted strip.
        FJ.slab(&m, V3(L - 0.02, 0.001, slotZ1 - slotZ0 - 0.004), V3(0, yb + slotDepth - 0.0005, (slotZ0 + slotZ1) / 2), "plastic.black")
        for z in [slotZ0 + 0.004, slotZ1 - 0.004] as [Float] {
            FJ.slab(&m, V3(L - 0.02, 0.016, 0.004), V3(0, yb + 0.002 + 0.006, z), "plastic.black")
        }
        let zc = (slotZ0 + slotZ1) / 2
        let nSlat = 1, pitch: Float = 0.0415
        for i in 0..<nSlat {
            let y = yb - 0.002 - Float(i) * pitch
            // Each slat is a rounded-section lath with a hook seam: body plus a lighter edge bead.
            FA.box(&m, V3(L - 0.1, pitch * 0.9, 0.012), V3(0, y - pitch * 0.45, zc), slat, r: 0.0025)
            FJ.slab(&m, V3(L - 0.1, 0.004, 0.003), V3(0, y - 0.003, zc + 0.0075), alu)
        }
        FA.box(&m, V3(L - 0.1, 0.012, 0.015), V3(0, yb - 0.002 - Float(nSlat) * pitch + 0.0, zc), "metal.anodized-black", r: 0.003)

        // Inspection hatch: a full-length plate in a rebate on the front face, with a seal gap, finger groove and screws.
        let hy0: Float = yb + 0.05, hy1: Float = yt - r + 0.005
        let hh = hy1 - hy0
        FA.box(&m, V3(L - 0.08, hh, 0.004), V3(0, (hy0 + hy1) / 2, D + 0.0018), coat, r: 0.0018)
        for sy: Float in [-1, 1] { FJ.slab(&m, V3(L - 0.07, 0.0022, 0.0016), V3(0, (hy0 + hy1) / 2 + sy * (hh / 2 + 0.0014), D + 0.0004), "plastic.black") }
        for sx: Float in [-1, 1] { FJ.slab(&m, V3(0.0022, hh + 0.006, 0.0016), V3(sx * (L / 2 - 0.04 + 0.0014), (hy0 + hy1) / 2, D + 0.0004), "plastic.black") }
        FJ.slab(&m, V3(0.35, 0.007, 0.0016), V3(0, hy0 + 0.012, D + 0.0043), "plastic.black")                        // finger groove
        for sx: Float in [-1, 1] { for sy: Float in [-1, 1] {
            let p = V3(sx * (L / 2 - 0.065), (hy0 + hy1) / 2 + sy * (hh / 2 - 0.016), D + 0.0038)
            FA.cylZ(&m, r: 0.0052, h: 0.0024, at: p, "metal.screw-zinc", bevel: 0.0008, segments: 8)
            FJ.slab(&m, V3(0.0058, 0.0009, 0.0006), V3(p.x, p.y, p.z + 0.0025), "metal.tool-ground")                  // slot
        }}

        // End caps: plate of the same section, fixing screws, rounded plastic shoulder.
        for e: Float in [-1, 1] {
            let x0 = e > 0 ? L / 2 : -L / 2 - capT, x1 = e > 0 ? L / 2 + capT : -L / 2
            FO.colX(&m, prof.map { V2($0.x, $0.y) }, x0: x0, x1: x1, alu, bevel: 0.0014)
            let xs = e * (L / 2 + capT)
            for (z, y) in [(0.03, yb + 0.03), (0.03, yt - 0.03), (D - 0.03, yb + 0.04), (D - 0.1, yt - 0.03)] as [(Float, Float)] {
                m.add(Prim.cylinder(radius: 0.0055, height: 0.0028, bevel: 0.0009, segments: 8, bevelSegments: 1, material: "metal.screw-zinc"),
                      Xform(translation: V3(xs, y, z), rotation: FA.q(-90 * e, FA.Z)))
            }
        }

        // Guide rail stubs: extruded U-channels dropping below the box, brush strips, rivets, a bead at the mouth.
        for e: Float in [-1, 1] {
            let gx = e * (L / 2 - 0.045)
            let inner = e * 0.0
            FA.box(&m, V3(0.052, yb + 0.012, 0.006), V3(gx, (yb + 0.012) / 2 + 0.0, slotZ0 - 0.005 + inner), alu, r: 0.0015)
            FA.box(&m, V3(0.052, yb + 0.012, 0.006), V3(gx, (yb + 0.012) / 2, slotZ1 + 0.005), alu, r: 0.0015)
            FA.box(&m, V3(0.006, yb + 0.012, slotZ1 - slotZ0 + 0.016), V3(gx + e * 0.023, (yb + 0.012) / 2, zc), alu, r: 0.0015)
            FA.box(&m, V3(0.018, yb, 0.003), V3(gx - e * 0.004, yb / 2, slotZ0 + 0.0), "plastic.black", r: 0.0008)
            FA.box(&m, V3(0.018, yb, 0.003), V3(gx - e * 0.004, yb / 2, slotZ1 - 0.0), "plastic.black", r: 0.0008)
            rivet(&m, at: V3(gx + e * 0.026, 0.026, zc + 0.002), normal: V3(e, 0, 0), radius: 0.003, segments: 8, material: "metal.steel")
        }

        // Silicone bead along the wall joint and top rear edge, with a sagged section.
        FA.rod(&m, V3(-L / 2 + 0.01, yt + 0.001, 0.003), V3(L / 2 - 0.01, yt + 0.001, 0.003), r: 0.0032, "plastic.white", sides: 6)

        // Wear: chalked coat patches, grime run from the slot over the front, chipped corners, pitting, rust at screws.
        for _ in 0..<10 {
            FJ.slab(&m, V3(rng.float(0.05...0.2), rng.float(0.004...0.012), 0.0014), V3(rng.float(-0.65...0.65), rng.float(yb + 0.02...yt - r), D + 0.0006), "stone.limestone-sooted")
        }
        for _ in 0..<8 {
            FJ.slab(&m, V3(rng.float(0.006...0.012), rng.float(0.03...0.09), 0.0014), V3(rng.float(-0.65...0.65), rng.float(yb + 0.04...yb + 0.12), D + 0.0006), "metal.rust-grime")
        }
        for e: Float in [-1, 1] {
            FJ.slab(&m, V3(0.03, 0.01, 0.0014), V3(e * (L / 2 - 0.016), yb + 0.012, D + 0.0003), "metal.aluminum-brushed")            // chipped bottom corner
            FJ.slab(&m, V3(0.0014, 0.028, 0.03), V3(e * (L / 2 + capT + 0.0004), yb + 0.05, 0.05), "stone.limestone")              // pitting on the cap
            for _ in 0..<3 {
                FJ.slab(&m, V3(0.0014, rng.float(0.01...0.03), rng.float(0.01...0.03)), V3(e * (L / 2 + capT + 0.0004), rng.float(yb + 0.04...yt - 0.05), rng.float(0.05...D - 0.06)), "stone.limestone")
            }
        }
        for _ in 0..<5 {
            FJ.slab(&m, V3(rng.float(0.05...0.16), 0.0016, rng.float(0.05...0.12)), V3(rng.float(-0.6...0.6), yt + 0.0004, rng.float(0.06...D - 0.1)), "stone.limestone-sooted")   // grime on the top
        }
        groundAO(&m, height: 0.1, floor: 0.7)
        return LODModel(FC.place(m))
    }
}
