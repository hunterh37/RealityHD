import simd
import Foundation

/// Frost-free hose bib in a wall box: painted flange frame with screws and a caulk bead, galvanized box shell
/// and rear plate, brass frost-free sillcock with a vacuum breaker spout and a red wheel handle, a left-hinged
/// stainless door swung open about 95 degrees with a lock cylinder, hinge knuckles and a weep slot. Wall plane z = 0.
public struct FrostFreeHoseBibBox: RealAsset {
    public static let id = "frost-free-hose-bib-box"
    public static let summary = "Frost-free hose bib in a wall box: painted flange frame with caulk bead, galvanized shell, brass frost-free sillcock with vacuum breaker and red wheel handle, hinged stainless door swung open with lock cylinder and hinge knuckles."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 12000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 34, elevation: 14, distance: 1.0)

    /// Frame paint.
    public var frame: MaterialKey = "metal.painted:DAD7CB"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let cy: Float = 0.1, W: Float = 0.2, op: Float = 0.136, ft: Float = 0.012   // overall, opening, flange thickness
        let strip = (W - op) / 2, depth: Float = 0.082
        // Flange frame: four strips with bevelled edges, hinge-side relief, caulk bead on the outer edge.
        FA.box(&m, V3(W, strip, ft), V3(0, cy + op / 2 + strip / 2, ft / 2), frame, r: 0.0025)
        FA.box(&m, V3(W, strip, ft), V3(0, cy - op / 2 - strip / 2, ft / 2), frame, r: 0.0025)
        FA.box(&m, V3(strip, op, ft), V3(-op / 2 - strip / 2, cy, ft / 2), frame, r: 0.0025)
        FA.box(&m, V3(strip, op, ft), V3(op / 2 + strip / 2, cy, ft / 2), frame, r: 0.0025)
        for (x, y) in [(-0.083, 0.183), (0.083, 0.183), (-0.083, 0.017), (0.083, 0.017)] as [(Float, Float)] { FS.screw(&m, at: V3(x, y, ft), r: 0.0042, mat: "metal.stainless") }
        FA.box(&m, V3(W + 0.002, 0.003, 0.0035), V3(0, cy + W / 2 - 0.0015, 0.0018), "plastic.white", r: 0.0012)
        FA.box(&m, V3(W + 0.002, 0.003, 0.0035), V3(0, cy - W / 2 + 0.0015, 0.0018), "plastic.white", r: 0.0012)
        // Galvanized shell: four walls behind the opening, and the rear plate with a weep slot.
        let t: Float = 0.003
        FA.box(&m, V3(op, t, depth), V3(0, cy + op / 2 - t / 2, ft + depth / 2 - 0.004), "metal.galvanized-aged", r: 0.0008)
        FA.box(&m, V3(op, t, depth), V3(0, cy - op / 2 + t / 2, ft + depth / 2 - 0.004), "metal.galvanized-aged", r: 0.0008)
        FA.box(&m, V3(t, op, depth), V3(-op / 2 + t / 2, cy, ft + depth / 2 - 0.004), "metal.galvanized-aged", r: 0.0008)
        FA.box(&m, V3(t, op, depth), V3(op / 2 - t / 2, cy, ft + depth / 2 - 0.004), "metal.galvanized-aged", r: 0.0008)
        FA.box(&m, V3(op, op, 0.004), V3(0, cy, 0.002), "plastic.black", r: 0.0008)
        FA.box(&m, V3(0.05, 0.004, 0.0012), V3(0, cy - op / 2 + 0.0036, ft + 0.0004), "plastic.black", r: 0.001)   // weep slot in the floor lip
        // Frost-free sillcock: long body tube from the rear, rear escutcheon, bonnet, vacuum breaker spout, wheel.
        let ty = cy + 0.012, zEnd: Float = 0.08
        FS.cyl(&m, r: 0.0255, h: 0.006, at: V3(0, ty, 0.004), axis: FA.Z, "metal.brass-aged", bevel: 0.002, segments: 22)
        FS.cyl(&m, r: 0.0115, h: zEnd - 0.01, at: V3(0, ty, 0.01), axis: FA.Z, "metal.brass-aged", bevel: 0.0015, segments: 18)
        FS.cyl(&m, r: 0.0138, h: 0.012, at: V3(0, ty, 0.026), axis: FA.Z, "metal.brass", bevel: 0.002, segments: 18)
        FS.cyl(&m, r: 0.0172, h: 0.024, at: V3(0, ty, zEnd - 0.022), axis: FA.Z, "metal.brass-aged", bevel: 0.003, segments: 20)
        FS.nut(&m, at: V3(0, ty, zEnd + 0.004), axis: FA.Z, af: 0.026, h: 0.01, "metal.brass")
        FS.cyl(&m, r: 0.0045, h: 0.02, at: V3(0, ty, zEnd + 0.009), axis: FA.Z, "metal.stainless", bevel: 0.0008, segments: 10)
        // Spout: vertical outlet below the bonnet with vacuum breaker cap and hose thread.
        FS.cyl(&m, r: 0.0128, h: 0.034, at: V3(0, ty - 0.034, zEnd - 0.02), axis: FA.Y, "metal.brass-aged", bevel: 0.002, segments: 20)
        for i in 0..<4 { m.add(Prim.torus(major: 0.0128, minor: 0.0011, segments: 18, sides: 5, material: "metal.brass"), Xform(translation: V3(0, ty - 0.034 + Float(i) * 0.0027, zEnd - 0.02))) }
        FS.cyl(&m, r: 0.0152, h: 0.016, at: V3(0, ty - 0.0, zEnd - 0.02), axis: FA.Y, "metal.brass", bevel: 0.0025, segments: 22)
        FS.cyl(&m, r: 0.0122, h: 0.006, at: V3(0, ty + 0.016, zEnd - 0.02), axis: FA.Y, "metal.brass-aged", bevel: 0.002, segments: 18)
        // Wheel handle on the stem axis (+Z): hub, rim, four spokes.
        let wz = zEnd + 0.03
        FS.cyl(&m, r: 0.0105, h: 0.013, at: V3(0, ty, wz - 0.006), axis: FA.Z, "metal.painted:A82A22", bevel: 0.002, segments: 16)
        FS.ringZ(&m, r: 0.0385, wire: 0.0042, at: V3(0, ty, wz + 0.0), "metal.painted:A82A22", segments: 40, sides: 8)
        for k in 0..<4 {
            let a = Float(k) * .pi / 2 + 0.35
            FA.box(&m, V3(0.04, 0.0058, 0.0085), V3(cos(a) * 0.0235, ty + sin(a) * 0.0235, wz), "metal.painted:A82A22", r: 0.002, rot: FA.q(a * 180 / .pi, FA.Z))
        }
        FS.nut(&m, at: V3(0, ty, wz + 0.009), axis: FA.Z, af: 0.013, h: 0.007, "metal.brass")
        // Door: stainless leaf hinged on the left edge of the opening, swung open about 95 degrees, with a rolled edge,
        // lock cylinder, latch tongue, two hinge knuckles and a stop.
        let hx = -op / 2 - 0.002, hz: Float = ft + 0.002
        let ang: Float = -95
        var door = Model(name: "door")
        FA.box(&door, V3(0.132, 0.138, 0.0045), V3(0.066, 0, 0.0), "metal.stainless-smudged", r: 0.0018)
        FA.box(&door, V3(0.12, 0.126, 0.0025), V3(0.066, 0, -0.0028), "metal.painted:C8C5BA", r: 0.001)
        FA.cylZ(&door, r: 0.0095, h: 0.0035, at: V3(0.116, -0.0, 0.002), "metal.brass", bevel: 0.0012, segments: 18)
        FA.box(&door, V3(0.0016, 0.008, 0.0018), V3(0.116, 0.0, 0.0058), "plastic.black", r: 0.0004)
        FA.box(&door, V3(0.02, 0.012, 0.003), V3(0.12, 0.0, -0.0062), "metal.galvanized-aged", r: 0.001)
        for y in [Float(-0.048), 0.048] {
            FS.cyl(&door, r: 0.0042, h: 0.028, at: V3(-0.002, y - 0.014, 0.0), axis: FA.Y, "metal.stainless", bevel: 0.0008, segments: 10)
        }
        FS.screws(&door, [V3(0.016, 0.05, 0.0025), V3(0.016, -0.05, 0.0025), V3(0.114, 0.055, 0.0025), V3(0.114, -0.055, 0.0025)], r: 0.0025, mat: "metal.screw-zinc")
        let rot = FA.q(ang, FA.Y)
        m.add(door, Xform(translation: V3(hx, cy, hz + 0.0045), rotation: rot))
        // Door leaf hinge brackets on the frame and the pin heads.
        for y in [Float(0.048), -0.048] {
            FA.box(&m, V3(0.014, 0.03, 0.004), V3(hx - 0.0035, cy + y, ft + 0.002), "metal.stainless", r: 0.001)
            FS.cyl(&m, r: 0.0042, h: 0.028, at: V3(hx, cy + y - 0.014, ft + 0.0035), axis: FA.Y, "metal.stainless", bevel: 0.0008, segments: 10)
        }
        // Weathering: hard-water scale on the spout, rust bloom on the shell and flange screws, verdigris at the bonnet.
        FS.cyl(&m, r: 0.0131, h: 0.004, at: V3(0, ty - 0.034, zEnd - 0.02), axis: FA.Y, "metal.painted:CFCBBE", bevel: 0.0008, segments: 18)
        FS.cyl(&m, r: 0.0176, h: 0.003, at: V3(0, ty, zEnd - 0.003), axis: FA.Z, "metal.copper-patina", bevel: 0.0006, segments: 18)
        for (x, y) in [(-0.083, 0.183), (0.083, 0.183), (-0.083, 0.017), (0.083, 0.017)] as [(Float, Float)] {
            FS.streak(&m, x: x + rng.float(-0.002...0.002), top: y - 0.004, w: 0.004, h: rng.float(0.006...0.012), z: ft + 0.0004, "metal.rust")
        }
        _ = rng.float(0...1)
        groundAO(&m, height: 0.03, floor: 0.9)
        return LODModel(FC.place(m))
    }
}
