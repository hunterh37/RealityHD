import simd
import Foundation

/// Gas furnace: Residential upflow furnace, beige-grey enamel cabinet, mild scuffing at the corners and base.. Parts: painted sheet-steel cabinet with rolled edges, raised-panel blower door with quarter-turn latches, control door with sight glass and status light, tapered supply plenum with flange lip, galvanized flue collar and vent stub, return-air grille on the side with slats, black iron gas line with shutoff and drip leg, wiring junction box, rating plate and warning labels.
public struct GasFurnace: RealAsset {
    public static let id = "gas-furnace"
    public static let summary = "Upflow gas furnace: sheet-steel cabinet with blower and control doors, supply plenum, flue collar, side return grille, gas line and labels."
    public static let tags = ["prop", "floorplan", "laundry", "hvac", "appliance", "metal", "interior"]
    public static let budget = 9000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.55, 1.0, 0.7)
    /// Cabinet enamel color.
    public var cabinetColor: UInt32 = 0xCFCDC6
    /// Door enamel color.
    public var doorColor: UInt32 = 0xDAD8D0
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [make(seed: seed, lite: false), make(seed: seed, lite: true)], switchDistances: [5])
    }

    private func make(seed: UInt64, lite: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let cab = String(format: "metal.powdercoat:%06X", cabinetColor)
        let door = String(format: "metal.powdercoat:%06X", doorColor)
        let W: Float = 0.51, D: Float = 0.672, H: Float = 0.86
        func along(_ dir: V3) -> simd_quatf { simd_quatf(from: V3(0, 1, 0), to: dir.normalized) }
        func cyl(_ r: Float, _ h: Float, _ mat: MaterialKey, at: V3, dir: V3 = V3(0, 1, 0), seg: Int = 14, bevel: Float = 0.001) {
            m.add(Prim.cylinder(radius: r, height: h, bevel: bevel, segments: lite ? max(6, seg / 2) : seg, bevelSegments: 1, material: mat), Xform(translation: at, rotation: along(dir)))
        }
        func box(_ s: V3, _ r: Float, _ mat: MaterialKey, at: V3) {
            m.add(Prim.roundedBox(s, radius: r, bevelSegments: 1, material: mat), Xform(translation: at))
        }
        func pipe(_ pts: [V3], _ r: Float, _ mat: MaterialKey) -> Surface {
            Prim.tube(pts, radii: pts.map { _ in r }, sides: lite ? 8 : 12, seamTile: 0.05, material: mat)
        }

        // Cabinet shell: rolled-edge box with a toe base.
        m.add(Prim.roundedBox(V3(W, H - 0.03, D), radius: 0.006, bevelSegments: 2, material: cab), Xform(translation: V3(0, 0.03 + (H - 0.03) / 2, 0)))
        m.add(Prim.roundedBox(V3(W - 0.02, 0.03, D - 0.02), radius: 0.004, bevelSegments: 1, material: "metal.painted:3A3A3C"), Xform(translation: V3(0, 0.015, 0)))
        // Top flange lip around the plenum base.
        m.add(Prim.roundedBox(V3(W - 0.02, 0.008, D - 0.02), radius: 0.003, bevelSegments: 1, material: cab), Xform(translation: V3(0, H + 0.003, 0)))

        // Doors on the front (+Z): lower blower door and upper control door.
        let zf = D / 2
        func doorPlate(w: Float, h: Float, y: Float, mat: MaterialKey) {
            let outline = Shape2D.rounded([V2(-w / 2, 0), V2(w / 2, 0), V2(w / 2, h), V2(-w / 2, h)], radius: 0.008)
            m.add(Prim.extrude(outline, depth: 0.008, bevel: 0.002, bevelSegments: 1, material: mat), Xform(translation: V3(0, y, zf + 0.001)))
            let inner = Shape2D.rounded([V2(-w / 2 + 0.03, 0.03), V2(w / 2 - 0.03, 0.03), V2(w / 2 - 0.03, h - 0.03), V2(-w / 2 + 0.03, h - 0.03)], radius: 0.006)
            m.add(Prim.extrude(inner, depth: 0.003, bevel: 0.0012, bevelSegments: 1, material: mat), Xform(translation: V3(0, y, zf + 0.0055)))
        }
        doorPlate(w: 0.46, h: 0.43, y: 0.05, mat: door)   // blower door
        doorPlate(w: 0.46, h: 0.34, y: 0.5, mat: door)    // control door
        // Quarter-turn latches on the blower door.
        for sx in [Float(-0.19), 0.19] {
            cyl(0.011, 0.006, "metal.screw-zinc", at: V3(sx, 0.44, zf + 0.009), dir: V3(0, 0, 1), seg: 14)
            box(V3(0.016, 0.003, 0.003), 0.0008, "metal.cast-iron-worn", at: V3(sx, 0.44, zf + 0.0155))
        }
        // Louver strip high on the blower door.
        for k in 0..<(lite ? 2 : 6) {
            box(V3(0.2, 0.004, 0.003), 0.001, "metal.painted:1E1E20", at: V3(0, 0.37 + Float(k) * 0.0095, zf + 0.0105))
        }
        // Control door: sight glass, status light, inspection label.
        box(V3(0.12, 0.06, 0.003), 0.004, "metal.painted:1E1E20", at: V3(-0.1, 0.76, zf + 0.0095))
        box(V3(0.1, 0.045, 0.004), 0.004, "glass.clear", at: V3(-0.1, 0.76, zf + 0.0115))
        cyl(0.0065, 0.004, "emissive.led-green", at: V3(-0.1, 0.705, zf + 0.0105), dir: V3(0, 0, 1), seg: 10, bevel: 0.0008)
        box(V3(0.12, 0.09, 0.0015), 0.0006, "label.inspection", at: V3(0.1, 0.72, zf + 0.0105))
        box(V3(0.09, 0.05, 0.0015), 0.0006, "label.hazard-small", at: V3(0.1, 0.62, zf + 0.0105))
        for sx in [Float(-0.2), 0.2] { for sy in [Float(0.53), 0.81] where !lite {
            cyl(0.0042, 0.003, "metal.screw-zinc", at: V3(sx, sy, zf + 0.009), dir: V3(0, 0, 1), seg: 8, bevel: 0.0007)
        }}
        // Door seams are shadow gaps: dark strips between the two doors and around.
        box(V3(0.47, 0.004, 0.002), 0.0005, "metal.painted:1E1E20", at: V3(0, 0.485, zf + 0.0005))

        // Stamped side panels (raised rectangles) on the right side; left carries the grille.
        do {
            let outline = Shape2D.rounded([V2(-0.28, 0), V2(0.28, 0), V2(0.28, 0.7), V2(-0.28, 0.7)], radius: 0.01)
            m.add(Prim.extrude(outline, depth: 0.003, bevel: 0.0012, bevelSegments: 1, material: cab),
                  Xform(translation: V3(W / 2 + 0.0005, 0.07, 0), rotation: simd_quatf(degrees: 90, axis: V3(0, 1, 0))))
            // Vertical rolled corner trims on the front edges.
            for sx in [Float(-1), 1] { box(V3(0.012, H - 0.03, 0.012), 0.004, cab, at: V3(sx * (W / 2 - 0.003), 0.03 + (H - 0.03) / 2, zf - 0.003)) }
        }
        // Supply plenum: tapered sheet-metal box above the cabinet, set back from the front.
        let plenumH: Float = 1.0 - H - 0.007
        box(V3(0.47, plenumH, 0.54), 0.004, "metal.galvanized-aged", at: V3(0, H + 0.007 + plenumH / 2, -0.07))
        // Plenum duct flange lip at the top and seams.
        m.add(Prim.extrude(Shape2D.rect(0.47, 0.52), depth: 0.006, bevel: 0.0015, bevelSegments: 1, material: "metal.galvanized-aged"),
              Xform(translation: V3(0, 0.989, -0.08), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        if !lite {
            for k in 0..<2 { // cross-break ribs on the plenum front
                for sg in [Float(-1), 1] {
                    m.add(Prim.roundedBox(V3(0.003, 0.12, 0.0045), radius: 0.001, bevelSegments: 1, material: "metal.galvanized-aged"),
                          Xform(translation: V3(Float(k) * 0.2 - 0.1, 0.935, 0.2), rotation: simd_quatf(degrees: sg * 30, axis: V3(0, 0, 1))))
                }
            }
            for k in 0..<5 { // standing seams and TDC cleats
                box(V3(0.003, 0.09, 0.003), 0.001, "metal.galvanized-aged", at: V3(-0.18 + Float(k) * 0.09, 0.935, 0.2))
            }
        }
        // Flue collar and vent stub, forward of the plenum on the cabinet top.
        let fx: Float = 0.13, fz: Float = 0.25
        m.add(turned([(0.0, H), (0.056, H), (0.056, H + 0.012), (0.049, H + 0.02), (0.049, H + 0.11), (0.0, H + 0.11)], segments: lite ? 12 : 28, material: "metal.galvanized-aged", seamTile: 0.3), Xform(translation: V3(fx, 0.003, fz)))
        m.add(turned([(0.052, H + 0.11), (0.052, H + 0.125), (0.047, H + 0.125), (0.047, H + 0.11)], segments: lite ? 12 : 28, material: "metal.galvanized-aged", seamTile: 0.3), Xform(translation: V3(fx, 0.003, fz)))

        // Return air grille on the left side (-X) with slats.
        let xl = -W / 2
        box(V3(0.008, 0.4, 0.44), 0.003, cab, at: V3(xl - 0.002, 0.3, 0.0))
        for k in 0..<(lite ? 5 : 14) {
            let n = lite ? 5 : 14
            let y = 0.12 + Float(k) * (0.36 / Float(n - 1))
            m.add(Prim.roundedBox(V3(0.012, 0.007, 0.4), radius: 0.0018, bevelSegments: 1, material: "metal.painted:1E1E20"),
                  Xform(translation: V3(xl - 0.0075, y, 0), rotation: simd_quatf(degrees: 25, axis: V3(0, 0, 1))))
        }
        // Gas line on the right side: stub into cabinet, shutoff, drip leg, vertical riser.
        let xr = W / 2
        let gx: Float = 0.2625
        m.add(pipe([V3(xr - 0.01, 0.3, -0.12), V3(gx, 0.3, -0.12), V3(gx, 0.3, -0.2), V3(gx, 0.62, -0.2)], 0.0095, "metal.cast-iron-worn"))
        box(V3(0.03, 0.03, 0.03), 0.006, "metal.brass-aged", at: V3(gx, 0.3, -0.16))
        box(V3(0.012, 0.006, 0.05), 0.002, "metal.painted:C8302B", at: V3(gx, 0.3, -0.16 + 0.0))
        cyl(0.0125, 0.06, "metal.cast-iron-worn", at: V3(gx, 0.24, -0.2))
        cyl(0.0145, 0.01, "metal.cast-iron-worn", at: V3(gx, 0.24, -0.2), seg: 6)
        // Wiring junction box with conduit stub on the right side, upper rear.
        box(V3(0.022, 0.1, 0.1), 0.003, "metal.painted:8A8C90", at: V3(xr + 0.008, 0.72, -0.18))
        cyl(0.007, 0.05, "metal.galvanized-aged", at: V3(xr + 0.008, 0.77, -0.18), seg: 10)
        // Condensate/inducer details: rear-top exhaust stub and wire grommet.
        box(V3(0.04, 0.04, 0.012), 0.004, "plastic.black", at: V3(-0.1, 0.55, -zf - 0.004))
        _ = rng.float()
        groundAO(&m, height: 0.18, floor: 0.55)
        return m
    }
}
