import simd
import Foundation

/// Electric standing desk, 1.5 x 0.75 m top at 1.1 m (full standing height): maple desktop with rounded corners and a slightly worn front edge, two telescoping two-stage matte white steel columns on C-foot bases with glides, an under-desk crossbar with two motor boxes, a control keypad on the front edge and a wire cable tray with a grommet.
public struct StandingDesk: RealAsset {
    public static let id = "standing-desk"
    public static let summary = "Sit-stand desk at full standing height, 1.5 m: maple top, white two-stage steel legs, crossbar, keypad."
    public static let tags = ["prop", "floorplan", "office", "furniture", "wood", "metal", "interior"]
    public static let budget = 14_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 20, distance: 2.6, studio: true)

    /// Overall size in meters (x width, y height at standing position, z depth). Front is +Z.
    public var size = V3(1.5, 1.1, 0.75)
    /// Desktop thickness (m).
    public var topThickness: Float = 0.025
    /// Desktop surface.
    public var top: MaterialKey = "wood.maple-natural"
    /// Frame powder coat.
    public var frame: MaterialKey = "metal.powdercoat:ECEBE7"
    /// Keypad, glides and motor housings.
    public var plastic: MaterialKey = "plastic.matte:1C1D20"
    /// Satin aluminum trim.
    public var trim: MaterialKey = "metal.satin-aluminum"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [model(seed: seed, detail: true), model(seed: seed, detail: false)], switchDistances: [4])
    }

    func model(seed: UInt64, detail: Bool) -> Model {
        func box(_ m: inout Model, _ sz: V3, _ c: V3, _ key: MaterialKey, r: Float = 0.003) {
            m.add(Prim.roundedBox(sz, radius: min(r, sz.x / 2.2, sz.y / 2.2, sz.z / 2.2), bevelSegments: detail ? 2 : 1, material: key), Xform(translation: c))
        }
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let w = size.x, h = size.y, d = size.z, t = topThickness
        let topY = h - t
        // Desktop: rounded-corner slab (extruded plan outline, laid flat).
        let outline = Shape2D.roundedRect(w, d, radius: 0.03)
        m.add(Prim.extrude(outline, depth: t, bevel: 0.004, bevelSegments: 2, material: top),
              Xform(translation: V3(0, topY + t / 2, 0), rotation: simd_quatf(degrees: -90, axis: V3(1, 0, 0))))
        // Worn front edge: a slightly lighter strip where forearms rest.
        box(&m, V3(0.9, 0.0008, 0.07), V3(rng.float(-0.05...0.05), h + 0.0002, d / 2 - 0.07), "wood.bench-maple", r: 0.0003)
        // Coffee ring and a darker forearm-worn band along the front edge.
        m.add(Prim.torus(major: 0.038, minor: 0.0016, segments: 28, sides: 4, material: "paint.wall:8A6A48"),
              Xform(translation: V3(0.18 + rng.float(-0.05...0.05), h + 0.0008, 0.08)))
        box(&m, V3(0.6, 0.0006, 0.05), V3(-0.25, h + 0.0001, d / 2 - 0.035), "wood.hammer-hickory-grimy", r: 0.0002)
        // Underside frame rails (wood stringers hidden by the steel): steel U-channel under the top.
        let legX = w / 2 - 0.12
        for s: Float in [-1, 1] {
            let x = s * legX
            // C-foot: base bar along Z with a glide at each end.
            let footLen = d - 0.14
            box(&m, V3(0.07, 0.04, footLen), V3(x, 0.04, 0), frame, r: 0.008)
            for e: Float in [-1, 1] {
                m.add(Prim.cylinder(radius: 0.022, height: 0.012, bevel: 0.002, segments: 14, material: plastic),
                      Xform(translation: V3(x, 0, e * (footLen / 2 - 0.05))))
            }
            // Telescoping column: outer stage, step ring, inner stage.
            box(&m, V3(0.075, 0.46, 0.09), V3(x, 0.04 + 0.23, 0), frame, r: 0.012)
            box(&m, V3(0.082, 0.012, 0.097), V3(x, 0.5, 0), trim, r: 0.004)
            box(&m, V3(0.062, 0.5, 0.076), V3(x, 0.5 + 0.25 - 0.01, 0), frame, r: 0.01)
            box(&m, V3(0.07, 0.01, 0.084), V3(x, 0.99, 0), trim, r: 0.003)
            // Top mounting plate.
            box(&m, V3(0.1, 0.012, 0.3), V3(x, topY - 0.006 - 0.003, 0), frame, r: 0.004)
            // Motor box behind each column.
            box(&m, V3(0.07, 0.11, 0.12), V3(x, topY - 0.07, -0.13), plastic, r: 0.012)
            box(&m, V3(0.05, 0.003, 0.05), V3(x, topY - 0.0165, -0.13), trim, r: 0.001)
        }
        // Crossbar between the columns, under the top.
        box(&m, V3(2 * legX - 0.1, 0.045, 0.035), V3(0, topY - 0.07, 0.02), frame, r: 0.008)
        box(&m, V3(2 * legX - 0.1, 0.012, 0.06), V3(0, topY - 0.0245, 0.02), frame, r: 0.003)
        // Front-edge keypad: small bracket under the top, rounded display body on the lip.
        let kx: Float = 0.52 + rng.float(-0.02...0.02)
        box(&m, V3(0.13, 0.022, 0.055), V3(kx, topY - 0.011, d / 2 - 0.045), plastic, r: 0.006)
        box(&m, V3(0.11, 0.004, 0.035), V3(kx, topY + 0.002, d / 2 - 0.04), "screen.lcd", r: 0.001)
        for i in 0..<4 {
            m.add(Prim.cylinder(radius: 0.0045, height: 0.0025, bevel: 0.0008, segments: 10, material: trim),
                  Xform(translation: V3(kx - 0.036 + Float(i) * 0.024, topY - 0.0005, d / 2 - 0.018), rotation: simd_quatf(degrees: 180, axis: V3(1, 0, 0))))
        }
        // Cable tray: wire basket along the rear underside with hanger brackets.
        let trayW = w - 0.5
        let trayZ = -d / 2 + 0.11
        let trayY = topY - 0.1
        for e in 0..<5 {
            let z = trayZ + (Float(e) - 2) * 0.012
            m.add(Prim.tube([V3(-trayW / 2, trayY, z), V3(trayW / 2, trayY, z)], radii: [0.0015, 0.0015], sides: 6, seamTile: 0.02, material: "metal.powdercoat:26272A", capEnd: true))
        }
        for s: Float in [-1, 1] {
            box(&m, V3(0.01, 0.1 - 0.006, 0.012), V3(s * (trayW / 2 - 0.1), trayY + 0.05 - 0.003, trayZ), "metal.powdercoat:26272A", r: 0.002)
            box(&m, V3(0.01, 0.012, 0.07), V3(s * trayW / 2, trayY - 0.004, trayZ), "metal.powdercoat:26272A", r: 0.002)
        }
        // Power strip lying in the tray, with its cord and zip ties.
        box(&m, V3(0.3, 0.035, 0.055), V3(0.1, trayY + 0.022, trayZ), "plastic.white", r: 0.008)
        for i in 0..<5 {
            box(&m, V3(0.03, 0.004, 0.03), V3(-0.01 + Float(i) * 0.055, trayY + 0.0415, trayZ), plastic, r: 0.002)
        }
        for i in 0..<3 {
            let x = -0.3 + Float(i) * 0.12
            m.add(Prim.torus(major: 0.012, minor: 0.0012, segments: 10, sides: 4, material: "plastic.white"),
                  Xform(translation: V3(x, trayY + 0.0035, trayZ - 0.02 + Float(i) * 0.02), rotation: simd_quatf(degrees: 90, axis: V3(0, 0, 1))))
        }
        // Cable grommet in the rear of the top, with a black cap ring and slot.
        let gx = -0.35 + rng.float(-0.03...0.03)
        m.add(Prim.torus(major: 0.03, minor: 0.003, segments: detail ? 20 : 10, sides: detail ? 6 : 4, material: plastic),
              Xform(translation: V3(gx, h - 0.002, -d / 2 + 0.1)))
        // Dangling power lead through the grommet, a short run to the left motor.
        let lead = catmull([V3(gx, h - 0.01, -d / 2 + 0.1), V3(gx - 0.02, topY - 0.05, -d / 2 + 0.11), V3(-legX, topY - 0.1, -0.13)], per: 6)
        m.add(Prim.tube(lead, radii: lead.map { _ in 0.004 }, sides: 6, seamTile: 0.02, material: "plastic.black", capEnd: true))
        groundAO(&m)
        let bb = m.bounds
        m = m.transformed(Xform(translation: V3(-(bb.min.x + bb.max.x) / 2, -bb.min.y, -(bb.min.z + bb.max.z) / 2)))
        return m
    }
}
