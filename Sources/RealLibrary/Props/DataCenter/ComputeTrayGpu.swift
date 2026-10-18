import simd
import Foundation

/// GPU compute tray: Clean new hardware, satin brushed aluminium, green PCB visible with lid lifted.. Parts: chassis, lid, slide rails, GPU modules, cold plates, copper tubing, quick disconnects, front handles, PCB, DIMMs.
public struct ComputeTrayGpu: RealAsset {
    public static let id = "compute-tray-gpu"
    public static let summary = "2U liquid-cooled GPU compute tray: brushed aluminium chassis, four GPU cold plates with copper tubing to rear blind-mate quick disconnects, PCB, fan-less, removable lid and slide rails."
    public static let tags = ["prop"]
    public static let budget = 12000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth). Expose every knob a scene might tune.
    public var size = V3(0.44, 0.09, 0.9)
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        // Brief materials: metal.aluminum-brushed metal.copper copper.polished plastic.pcb metal.nickel plastic.matte. Gate: realityhd gate compute-tray-gpu. Boards: plank()/board() along +X (grain on U).
        // Turned parts: turned(). Bevel every hard edge; jitter assembled parts.
        m.add(Prim.roundedBox(size, radius: 0.01, bevelSegments: 2, material: "metal.aluminum-brushed"),
              Xform(translation: V3(0, size.y / 2, 0)).jittered(&rng))
        groundAO(&m)
        return LODModel(m)
    }
}
