import simd
import Foundation

/// Water heater: 40 gallon gas tank, white enamel jacket, light scuffs near the base.. Parts: enamel tank jacket with top rim and base skirt, galvanized draft hood and flue stub, hot and cold copper nipples with brass unions and shutoff, brass T&P relief valve with lever and discharge pipe, gas control with thermostat dial and pilot window, burner access door with screws, rating plate and warning labels, drain valve.
public struct WaterHeater: RealAsset {
    public static let id = "water-heater"
    public static let summary = "40 gallon gas water heater with enamel jacket, flue draft hood, copper unions, relief valve and discharge pipe, and gas control."
    public static let tags = ["prop", "floorplan", "laundry", "plumbing", "appliance", "metal", "interior"]
    public static let budget = 12_000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.55, 1.5, 0.55)
    /// Jacket enamel color.
    public var jacketColor: UInt32 = 0xE3DFD3
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [make(seed: seed, lite: false), make(seed: seed, lite: true)], switchDistances: [5])
    }

    private func make(seed: UInt64, lite: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let jacket = String(format: "metal.powdercoat:%06X", jacketColor)
        let R: Float = 0.24
        func pipe(_ pts: [V3], _ r: Float, _ mat: MaterialKey) -> Surface {
            Prim.tube(pts, radii: pts.map { _ in r }, sides: 12, seamTile: 0.05, material: mat)
        }
        func along(_ dir: V3) -> simd_quatf { simd_quatf(from: V3(0, 1, 0), to: dir.normalized) }
        func cyl(_ r: Float, _ h: Float, _ mat: MaterialKey, at: V3, dir: V3 = V3(0, 1, 0), seg: Int = 14, bevel: Float = 0.001) {
            m.add(Prim.cylinder(radius: r, height: h, bevel: bevel, segments: lite ? max(6, seg / 2) : seg, bevelSegments: 1, material: mat), Xform(translation: at, rotation: along(dir)))
        }
        func hexNut(_ at: V3, r: Float, h: Float, mat: MaterialKey) {
            let hex = Shape2D.rounded(Shape2D.polygon(sides: 6, radius: r), radius: r * 0.08, segments: 1)
            m.add(Prim.extrude(hex, depth: h, bevel: 0.0008, bevelSegments: 1, material: mat), Xform(translation: at, rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        }
        func box(_ s: V3, _ r: Float, _ mat: MaterialKey, at: V3) {
            m.add(Prim.roundedBox(s, radius: r, bevelSegments: 1, material: mat), Xform(translation: at))
        }

        // Base skirt, jacket, rims, seam bands.
        m.add(turned([(0, 0.0), (0.222, 0.0), (0.228, 0.006), (0.228, 0.09), (0.2365, 0.094), (0.2405, 0.1), (0.2405, 0.12), (R, 0.125)], segments: lite ? 24 : 48, material: "metal.painted:3A3A3C", seamTile: 0.4))
        m.add(turned([(R, 0.12), (R, 1.31), (0.236, 1.318), (0.228, 1.332), (0.205, 1.352), (0.16, 1.366), (0.1, 1.372), (0, 1.374)], segments: lite ? 28 : 56, material: jacket, seamTile: 0.5))
        m.add(turned([(0.2375, 1.296), (0.2435, 1.30), (0.2435, 1.312), (0.2375, 1.316)], segments: lite ? 28 : 56, material: jacket, seamTile: 0.5))
        m.add(turned([(0.2375, 0.146), (0.2425, 0.15), (0.2425, 0.158), (0.2375, 0.162)], segments: lite ? 28 : 56, material: jacket, seamTile: 0.5))

        // Draft hood and flue stub.
        m.add(turned([(0.0, 1.368), (0.105, 1.368), (0.105, 1.384), (0.092, 1.40), (0.074, 1.43), (0.062, 1.44), (0, 1.44)], segments: lite ? 16 : 32, material: "metal.galvanized-aged", seamTile: 0.3))
        for k in 0..<4 {
            let a = Float(k) / 4 * 2 * .pi + .pi / 4
            m.add(Prim.roundedBox(V3(0.02, 0.026, 0.006), radius: 0.001, bevelSegments: 1, material: "metal.galvanized-aged"),
                  Xform(translation: V3(cos(a) * 0.104, 1.376, sin(a) * 0.104), rotation: simd_quatf(angle: -a, axis: V3(0, 1, 0))))
        }
        m.add(turned([(0.056, 1.43), (0.056, 1.5), (0.0525, 1.5), (0.0525, 1.43)], segments: lite ? 14 : 28, material: "metal.galvanized-aged", seamTile: 0.3))
        m.add(turned([(0.0, 1.43), (0.062, 1.43), (0.062, 1.462), (0.056, 1.462)], segments: lite ? 14 : 28, material: "metal.galvanized-aged", seamTile: 0.3))
        for k in 0..<(lite ? 0 : 3) {
            let a = Float(k) / 3 * 2 * .pi
            cyl(0.003, 0.003, "metal.screw-zinc", at: V3(cos(a) * 0.0625, 1.447, sin(a) * 0.0625), dir: V3(cos(a), 0, sin(a)), seg: 8, bevel: 0.0006)
        }

        // Water nipples with brass unions; cold (left) has a ball valve, hot (right) straight copper.
        for x in [Float(-0.115), 0.115] {
            let z: Float = -0.1
            m.add(turned([(0, 1.368), (0.03, 1.368), (0.027, 1.382), (0.02, 1.388), (0, 1.388)], segments: lite ? 9 : 18, material: "metal.painted:3A3A3C", seamTile: 0.1), Xform(translation: V3(x, 0, z)))
            cyl(0.0125, 0.05, "metal.copper", at: V3(x, 1.38, z), seg: 14)
            cyl(0.0175, 0.006, "metal.brass-aged", at: V3(x, 1.392, z), seg: 16)
            hexNut(V3(x, 1.405, z), r: 0.0215, h: 0.014, mat: "metal.brass-aged")
            cyl(0.0175, 0.005, "metal.brass-aged", at: V3(x, 1.412, z), seg: 16)
        }
        do {
            let x: Float = -0.115, z: Float = -0.1
            box(V3(0.036, 0.04, 0.036), 0.008, "metal.brass-aged", at: V3(x, 1.442, z))
            cyl(0.012, 0.024, "metal.copper", at: V3(x, 1.458, z))
            cyl(0.0045, 0.014, "metal.brass-aged", at: V3(x + 0.019, 1.442, z), dir: V3(1, 0, 0), seg: 10)
            box(V3(0.034, 0.006, 0.012), 0.002, "plastic.matte", at: V3(x + 0.032, 1.442, z))
            cyl(0.0125, 0.064, "metal.copper", at: V3(0.115, 1.42, z))
            for xx in [Float(-0.115), 0.115] { // horizontal runs back toward the wall, with elbows
                box(V3(0.03, 0.03, 0.03), 0.01, "metal.copper", at: V3(xx, 1.472, z))
                cyl(0.0115, 0.17, "metal.copper", at: V3(xx, 1.472, z), dir: V3(0, 0, -1))
                cyl(0.016, 0.004, "metal.copper", at: V3(xx, 1.472, -0.2715), dir: V3(0, 0, -1), seg: 14)
            }
        }

        // Relief valve (brass) on the right side with discharge pipe down the jacket.
        do {
            let y: Float = 1.15, px: Float = 0.2625
            cyl(0.017, 0.016, "metal.brass-aged", at: V3(R - 0.004, y, 0), dir: V3(1, 0, 0), seg: 16)
            box(V3(0.022, 0.05, 0.044), 0.006, "metal.brass-aged", at: V3(R + 0.01, y - 0.004, 0))
            cyl(0.013, 0.026, "metal.brass-aged", at: V3(R + 0.01, y + 0.018, 0), seg: 14)
            box(V3(0.006, 0.006, 0.05), 0.002, "metal.chrome", at: V3(R + 0.014, y + 0.049, 0))
            box(V3(0.008, 0.012, 0.01), 0.002, "metal.brass-aged", at: V3(R + 0.014, y + 0.043, 0))
            m.add(pipe([V3(R + 0.01, y - 0.03, 0), V3(px, y - 0.036, 0), V3(px, y - 0.06, 0), V3(px, 0.1, 0)], 0.0095, "metal.copper"))
            for yy in [Float(0.85), 0.5, 0.2] {
                m.add(turned([(0.0, 0), (0.0125, 0), (0.0125, 0.008), (0.0, 0.008)], segments: lite ? 6 : 12, material: "metal.galvanized-aged", seamTile: 0.1), Xform(translation: V3(px, yy, 0)))
                box(V3(0.02, 0.008, 0.024), 0.001, "metal.galvanized-aged", at: V3(px - 0.012, yy + 0.004, 0))
            }
        }

        // Front: burner access door, gas control, dial, pilot window, gas line, labels.
        do {
            m.add(curvedPanel(w: 0.19, h: 0.15, t: 0.004, r: R, mat: jacket), Xform(translation: V3(0, 0.17, 0)))
            for k in 0..<(lite ? 2 : 5) { // louvered combustion air slots
                m.add(curvedPanel(w: 0.12, h: 0.008, t: 0.0042, r: R, mat: "metal.painted:1E1E20"), Xform(translation: V3(0, 0.2 + Float(k) * 0.022, 0)))
            }
            for (sx, sy) in (lite ? [] : [(Float(-0.082), Float(0.01)), (0.082, 0.01), (-0.082, 0.14), (0.082, 0.14)]) {
                let a = asin(sx / R)
                cyl(0.0045, 0.003, "metal.screw-zinc", at: V3(R * sin(a), 0.17 + sy, R * cos(a) + 0.004 - 0.0005), dir: V3(sin(a), 0, cos(a)), seg: 10, bevel: 0.0008)
            }
            box(V3(0.13, 0.085, 0.03), 0.006, "metal.painted:2E2E30", at: V3(0, 0.4, R + 0.007))
            cyl(0.028, 0.012, "plastic.black", at: V3(0, 0.4, R + 0.022), dir: V3(0, 0, 1), seg: 24, bevel: 0.002)
            box(V3(0.004, 0.024, 0.006), 0.001, "plastic.white", at: V3(0, 0.412, R + 0.0335))
            for k in 0..<(lite ? 0 : 5) {
                let a = (Float(k) / 4 - 0.5) * 1.6
                box(V3(0.002, 0.006, 0.001), 0.0004, "plastic.white", at: V3(sin(a) * 0.04, 0.4 + cos(a) * 0.04, R + 0.0225))
            }
            cyl(0.011, 0.006, "glass.clear", at: V3(-0.046, 0.372, R + 0.022), dir: V3(0, 0, 1), seg: 14)
            cyl(0.007, 0.008, "metal.painted:C8302B", at: V3(0.046, 0.38, R + 0.022), dir: V3(0, 0, 1), seg: 12, bevel: 0.002)
            // Gas supply stub with shutoff.
            m.add(pipe([V3(-0.06, 0.4, R + 0.005), V3(-0.2, 0.4, R + 0.005)], 0.0095, "metal.cast-iron-worn"))
            box(V3(0.032, 0.03, 0.032), 0.006, "metal.brass-aged", at: V3(-0.14, 0.4, R + 0.005))
            box(V3(0.05, 0.006, 0.012), 0.002, "metal.painted:C8302B", at: V3(-0.14, 0.42, R + 0.005))
            cyl(0.0125, 0.012, "metal.cast-iron-worn", at: V3(-0.2, 0.4, R + 0.005), dir: V3(1, 0, 0), seg: 12)
            // Rating plate and warning labels.
            m.add(curvedPanel(w: 0.13, h: 0.1, t: 0.0015, r: R, mat: "label.inspection"), Xform(translation: V3(0, 0.62, 0)))
            m.add(curvedPanel(w: 0.07, h: 0.09, t: 0.0015, r: R, mat: "label.hazard-small"), Xform(translation: V3(0.12, 0.86, 0), rotation: simd_quatf(degrees: -30, axis: V3(0, 1, 0))))
            m.add(curvedPanel(w: 0.10, h: 0.06, t: 0.0015, r: R, mat: "plastic.yellow"), Xform(translation: V3(-0.1, 0.9, 0), rotation: simd_quatf(degrees: 25, axis: V3(0, 1, 0))))
        }
        // Drain valve, lower left.
        cyl(0.013, 0.022, "metal.brass-aged", at: V3(-R + 0.002, 0.17, 0), dir: V3(-1, 0, 0), seg: 14)
        cyl(0.009, 0.014, "plastic.black", at: V3(-R - 0.02, 0.17, 0), dir: V3(-1, 0, 0), seg: 10)
        // Anode plug and second hex plug on the dome, vertical jacket seam on the back, paper tag on the relief pipe.
        hexNut(V3(0.07, 1.3745, 0.12), r: 0.019, h: 0.012, mat: "metal.painted:8A8C90")
        hexNut(V3(-0.07, 1.3745, 0.13), r: 0.016, h: 0.01, mat: "metal.brass-aged")
        m.add(curvedPanel(w: 0.014, h: 1.17, t: 0.0025, r: R, mat: jacket), Xform(translation: V3(0, 0.14, 0), rotation: simd_quatf(degrees: 180, axis: V3(0, 1, 0))))
        box(V3(0.004, 0.05, 0.034), 0.001, "label.inspection", at: V3(0.2565, 0.97, 0.0))
        // Seeped-water stain ring on the skirt from the relief pipe discharge.
        m.add(turned([(0.2, 0.0), (0.231, 0.0), (0.231, 0.0015), (0.2, 0.0015)], segments: lite ? 16 : 32, material: "metal.rust", seamTile: 0.3), Xform(translation: V3(0, 0.0005, 0)))
        _ = rng.float()
        groundAO(&m, height: 0.2, floor: 0.55)
        return m
    }
}

/// Rectangular panel wrapped on a vertical cylinder of radius `r` (axis through the origin), centered on +Z,
/// base at y = 0, `t` thick outward.
fileprivate func curvedPanel(w: Float, h: Float, t: Float, r: Float, mat: MaterialKey, segs: Int = 8) -> Surface {
    let a = asin(min(0.99, w / 2 / r))
    var outline: [V2] = []
    for k in 0...segs { let q = -a + 2 * a * Float(k) / Float(segs); outline.append(V2((r + t) * sin(q), -(r + t) * cos(q))) }
    for k in 0...segs { let q = a - 2 * a * Float(k) / Float(segs); outline.append(V2((r - 0.002) * sin(q), -(r - 0.002) * cos(q))) }
    return Prim.loft([Prim.ring(outline, y: 0), Prim.ring(outline, y: h)], capStart: true, capEnd: true, material: mat)
}
