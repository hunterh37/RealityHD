import simd
import Foundation

/// Rolladen shutter box: a white PVC roller-shutter housing with a rounded front, inspection hatch with
/// screw caps, end caps, a brush-sealed slot, aluminum guide rails, two visible slats on a rubber-sealed
/// end bar and a belt winder with its webbing strap. Wall plane at z = 0.
public struct RolladenShutterBox: RealAsset {
    public static let id = "rolladen-shutter-box"
    public static let summary = "Central European Rolladen roller shutter box 1.5 m: PVC housing with inspection hatch, end caps, aluminum guide rails, slats, belt winder."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 7_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 10, distance: 1.7)

    /// Housing length (m), height and depth.
    public var length: Float = 1.5
    public var boxHeight: Float = 0.17
    public var depth: Float = 0.28
    public var pvc: MaterialKey = "plastic.white:DDD8C6"
    public var pvcAged: MaterialKey = "plastic.white:CFC7B0"
    public var rail: MaterialKey = "metal.powder-white"
    public var slat: MaterialKey = "metal.powder-white:E4E2DA"
    public init() {}

    /// Housing section (x out from the wall, y up): flat back, flat top, quarter-round front-bottom.
    private func housing(_ d: Float, _ h: Float) -> [V2] {
        var pts: [V2] = []
        let rr: Float = 0.085, tr: Float = 0.012
        pts.append(V2(0, 0))
        pts.append(V2(d - rr, 0))
        for i in 1...8 {   // front-bottom quarter round
            let a = Float(i) / 8 * (.pi / 2)
            pts.append(V2(d - rr + rr * sin(a), rr - rr * cos(a)))
        }
        pts.append(V2(d, h - tr))
        for i in 1...3 {
            let a = Float(i) / 4 * (.pi / 2)
            pts.append(V2(d - tr + tr * cos(a), h - tr + tr * sin(a)))
        }
        pts.append(V2(d - tr, h))
        pts.append(V2(0, h))
        return pts
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let L = length, hb = boxHeight, d = depth
        let yB: Float = 0.30 - hb            // underside of the housing
        let lx = L / 2 - 0.035               // guide-rail centre
        // Housing extrusion and end caps.
        FA.run(&m, housing(d, hb), length: L - 0.012, at: V3(0, yB, 0), pvc, bevel: 0.0015)
        for s: Float in [-1, 1] {
            m.add(Prim.extrude(housing(d + 0.004, hb + 0.003), depth: 0.008, bevel: 0.002, bevelSegments: 1, material: pvcAged),
                  Xform(translation: V3(s * (L / 2 - 0.004), yB - 0.0015, -0.002), rotation: FA.q(-90, FA.Y)))
        }
        // Inspection hatch: a plate with a recessed seam and capped screws, set into the front face.
        let hw: Float = 1.18, hh: Float = 0.09, hy = yB + hb * 0.58
        FA.box(&m, V3(hw, hh, 0.003), V3(-0.08, hy, d + 0.0005), pvcAged, r: 0.0012)
        FA.box(&m, V3(hw + 0.006, 0.0035, 0.0014), V3(-0.08, hy + hh / 2 + 0.002, d + 0.0005), "plastic.black", r: 0.0003)
        FA.box(&m, V3(hw + 0.006, 0.0035, 0.0014), V3(-0.08, hy - hh / 2 - 0.002, d + 0.0005), "plastic.black", r: 0.0003)
        for e: Float in [-1, 1] {
            FA.box(&m, V3(0.0035, hh + 0.006, 0.0014), V3(-0.08 + e * (hw / 2 + 0.002), hy, d + 0.0005), "plastic.black", r: 0.0003)
        }
        for i in 0..<5 {
            let x = -0.08 - hw / 2 + 0.06 + Float(i) * (hw - 0.12) / 4
            FA.cylZ(&m, r: 0.0075, h: 0.004, at: V3(x, hy + hh / 2 - 0.016, d + 0.0012), "plastic.white:D8D2BF", bevel: 0.0012, segments: 12)
            FA.cylZ(&m, r: 0.0075, h: 0.004, at: V3(x, hy - hh / 2 + 0.016, d + 0.0012), "plastic.white:D8D2BF", bevel: 0.0012, segments: 12)
        }
        // Grime streaks under the hatch screws and along the lower curve.
        for i in 0..<5 {
            let x = -0.08 - hw / 2 + 0.06 + Float(i) * (hw - 0.12) / 4
            if rng.chance(0.7) {
                let len = rng.float(0.02...0.06)
                FA.box(&m, V3(0.006, len, 0.0006), V3(x, hy - hh / 2 + 0.016 - 0.008 - len / 2, d + 0.0009), "plastic.white:B7AD92", r: 0.0002)
            }
        }
        // Slot underneath at the front with a black brush seal.
        FA.box(&m, V3(L - 0.04, 0.012, 0.030), V3(0, yB + 0.003, d - 0.095), "plastic.black", r: 0.003)
        FA.box(&m, V3(L - 0.04, 0.007, 0.012), V3(0, yB - 0.0025, d - 0.095), "plastic.matte", r: 0.002)
        // Guide rails: aluminum U-channels with a brush insert, running from the housing to the sill.
        let railH = yB - 0.001, rz: Float = d - 0.095
        for s: Float in [-1, 1] {
            FA.box(&m, V3(0.034, railH, 0.003), V3(s * lx, railH / 2, rz - 0.0215), rail, r: 0.001)
            FA.box(&m, V3(0.003, railH, 0.044), V3(s * (lx - 0.0155), railH / 2, rz), rail, r: 0.001)
            FA.box(&m, V3(0.003, railH, 0.044), V3(s * (lx + 0.0155), railH / 2, rz), rail, r: 0.001)
            FA.box(&m, V3(0.006, railH - 0.01, 0.034), V3(s * (lx - 0.011), railH / 2, rz + 0.002), "plastic.black", r: 0.0012)
            FA.cylZ(&m, r: 0.0042, h: 0.003, at: V3(s * lx, 0.03, rz - 0.0215 - 0.0005), "metal.screw-zinc", bevel: 0.0008, segments: 8)
        }
        // Curtain: two slats with ventilation slots and a rubber-sealed end bar hanging in the rails.
        let cw = (lx - 0.0155) * 2 - 0.006
        let slatProfile: [V2] = [V2(-0.0045, -0.018), V2(0.0045, -0.018), V2(0.0058, -0.012), V2(0.0058, 0.012), V2(0.0045, 0.018), V2(-0.0045, 0.018)]
        for k in 0..<3 {
            let y = yB - 0.025 - Float(k) * 0.036
            if y < 0.07 { break }
            m.add(Prim.extrude(slatProfile, depth: cw, bevel: 0.0008, bevelSegments: 1, material: slat),
                  Xform(translation: V3(0, y, rz), rotation: FA.q(-90, FA.Y)))
            for i in 0..<18 {
                FA.box(&m, V3(0.036, 0.0028, 0.0012), V3(-cw / 2 + 0.06 + Float(i) * (cw - 0.12) / 17, y + 0.004, rz + 0.0062), "plastic.black", r: 0.0004)
            }
        }
        FA.box(&m, V3(cw, 0.032, 0.017), V3(0, 0.026, rz), rail, r: 0.003)
        FA.box(&m, V3(cw - 0.01, 0.006, 0.020), V3(0, 0.008, rz), "rubber.tire", r: 0.002)
        for s: Float in [-1, 1] {
            FA.box(&m, V3(0.012, 0.022, 0.012), V3(s * (cw / 2 - 0.015), 0.06, rz + 0.0), "plastic.black", r: 0.002)
        }
        // Belt winder: recessed plate on the front with a webbing strap hanging to a pull loop.
        let bx = L / 2 - 0.09, by = yB + 0.095
        FA.box(&m, V3(0.062, 0.115, 0.004), V3(bx, by, d + 0.0005), pvcAged, r: 0.003)
        FA.box(&m, V3(0.036, 0.075, 0.003), V3(bx, by + 0.004, d + 0.003), "plastic.white:CFC9B6", r: 0.004)
        FA.box(&m, V3(0.024, 0.010, 0.004), V3(bx, by - 0.012, d + 0.0045), "plastic.black", r: 0.002)
        FA.box(&m, V3(0.021, 0.34 * 0.5, 0.0035), V3(bx, by - 0.012 - 0.085, d + 0.0045), "fabric.webbing:7A7468", r: 0.0006)
        FA.box(&m, V3(0.026, 0.020, 0.008), V3(bx, by - 0.012 - 0.19, d + 0.006), "plastic.black", r: 0.004)
        _ = rng.float()
        groundAO(&m, height: 0.08, floor: 0.8)
        return LODModel(FC.place(m))
    }
}
