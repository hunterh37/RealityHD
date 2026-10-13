import simd
import Foundation

/// 60 x 36 in walk-in shower: low-profile acrylic tray with sloped floor and round drain, one fixed frameless
/// glass panel at the +X end with chrome wall and base channels and a stabilizer bar back to the wall, wall-arm
/// rain head, valve with lever, and a slide bar with hand shower and hose. Back wall at z = -0.45; the front
/// and left side stay open. Glass tops at 2.0 m.
public struct WalkInShower: RealAsset {
    public static let id = "walk-in-shower"
    public static let summary = "60 x 36 in walk-in shower: low-profile tray, fixed frameless glass panel with stabilizer bar, rain head, slide-bar hand shower and valve."
    public static let tags = ["prop", "floorplan", "bathroom", "plumbing", "glass", "interior"]
    public static let budget = 7000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 14, distance: 3.8, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(1.5, 2.0, 0.9)
    public var tray: MaterialKey = "ceramic.vitreous"
    public var glass: MaterialKey = "glass.shelter"
    public var chrome: MaterialKey = "metal.chrome"
    /// Tray curb height.
    public var curb: Float = 0.035
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        func make(_ lod: Int) -> Model {
            var m = Model(name: Self.id)
            let hi = lod == 0
            let W = size.x, D = size.z, hx = W / 2, hz = D / 2
            let t = curb
            func ring(_ inset: Float, _ y: Float) -> [V3] {
                Prim.ring(Shape2D.roundedRect(W - 2 * inset, D - 2 * inset, radius: 0.03 + inset * 0.5, segments: hi ? 3 : 2), y: y)
            }
            let rows: [[V3]] = [ring(0.012, 0), ring(0.0, 0.012), ring(0.0, t - 0.005), ring(0.004, t), ring(0.045, t), ring(0.06, t - 0.01), ring(0.12, 0.02), ring(0.3, 0.014)]
            m.add(Prim.loft(Array(rows[0...3]), capStart: true, material: tray))
            m.add(Prim.loft(Array(rows[3...]), capEnd: true, material: tray))
            // Round drain, off-center toward the glass.
            let dc = V3(0.25, 0.014, 0.0)
            m.add(Prim.lathe([V2(0.001, 0.0005), V2(0.055, 0.0005), V2(0.059, 0.002), V2(0.053, 0.0045), V2(0.001, 0.0045)], segments: hi ? 28 : 12, seamTile: 0.05, material: "metal.stainless"), Xform(translation: dc))
            if hi {
                for r in [0.016, 0.034] as [Float] {
                    m.add(Prim.lathe([V2(r - 0.0025, 0.0043), V2(r + 0.0025, 0.0043), V2(r + 0.0025, 0.0055), V2(r - 0.0025, 0.0055)], segments: 24, seamTile: 0.05, material: "plastic.black"), Xform(translation: dc))
                }
                m.add(Prim.lathe([V2(0.059, 0.0003), V2(0.105, 0.0003), V2(0.107, 0.0007), V2(0.059, 0.0007)], segments: 28, seamTile: 0.05, material: "plastic.matte:D4C8B0"), Xform(translation: dc))
            }
            // Fixed panel at +X: 10 mm glass from the back wall channel to the front edge.
            let gb = t + 0.002, gt = size.y, gh = gt - gb, gy = (gb + gt) / 2
            let th: Float = 0.01
            let pl = D - 0.03
            m.add(Prim.roundedBox(V3(th, gh, pl), radius: 0.0015, bevelSegments: 1, material: glass), Xform(translation: V3(hx - 0.02, gy, 0.012)))
            // Wall channel (back edge), base channel, and the front edge cap.
            m.add(Prim.roundedBox(V3(0.026, gh, 0.016), radius: 0.004, bevelSegments: 1, material: chrome), Xform(translation: V3(hx - 0.02, gy, -hz + 0.008)))
            m.add(Prim.roundedBox(V3(0.026, 0.028, pl + 0.016), radius: 0.004, bevelSegments: 1, material: chrome), Xform(translation: V3(hx - 0.02, t + 0.014, 0.012 - 0.004)))
            // Stabilizer bar from the panel top back to the wall, with wall flange and glass clamp.
            let bar = [V3(hx - 0.02, gt - 0.07, 0.3), V3(hx - 0.12, gt - 0.07, 0.15), V3(0.35, gt - 0.07, -hz + 0.015)]
            m.add(Prim.tube(bar, radii: [0.009, 0.009, 0.009], sides: hi ? 10 : 6, seamTile: 0.04, material: chrome))
            m.add(Prim.cylinder(radius: 0.022, height: 0.008, bevel: 0.002, segments: hi ? 14 : 8, material: chrome),
                  Xform(translation: V3(0.35, gt - 0.07, -hz), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
            m.add(Prim.roundedBox(V3(0.03, 0.05, 0.026), radius: 0.006, bevelSegments: hi ? 2 : 1, material: chrome), Xform(translation: V3(hx - 0.02, gt - 0.07, 0.3)))
            // Back-wall plumbing: rain head on an arm, valve, slide bar with hand shower.
            BathFit.showerHead(&m, wall: V3(0.2, 1.93, -hz), reach: 0.38, headRadius: 0.125, tilt: 6, hi: hi)
            BathFit.valveTrim(&m, at: V3(-0.25, 1.05, -hz), hi: hi)
            let bx: Float = -0.25 + 0.0
            let slideX: Float = 0.62
            _ = bx
            for y in [0.98, 1.88] as [Float] {
                m.add(Prim.cylinder(radius: 0.016, height: 0.03, bevel: 0.003, segments: hi ? 12 : 8, material: chrome),
                      Xform(translation: V3(slideX, y, -hz), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
            }
            m.add(Prim.tube([V3(slideX, 0.98, -hz + 0.032), V3(slideX, 1.88, -hz + 0.032)], radii: [0.0095, 0.0095], sides: hi ? 12 : 6, seamTile: 0.04, material: chrome))
            // Hand shower in its slider holder at 1.45 m, hose hanging to the wall outlet.
            let hy: Float = 1.45
            m.add(Prim.roundedBox(V3(0.032, 0.05, 0.034), radius: 0.008, bevelSegments: hi ? 2 : 1, material: chrome), Xform(translation: V3(slideX, hy, -hz + 0.032)))
            m.add(Prim.lathe([V2(0.001, 0), V2(0.012, 0), V2(0.0125, 0.16), V2(0.016, 0.2), V2(0.03, 0.222), V2(0.034, 0.236), V2(0.001, 0.238)], segments: hi ? 18 : 8, seamTile: 0.05, material: chrome),
                  Xform(translation: V3(slideX, hy - 0.12, -hz + 0.062)))
            m.add(Prim.lathe([V2(0.001, 0.0), V2(0.03, 0.0), V2(0.03, 0.002), V2(0.001, 0.002)], segments: hi ? 18 : 8, seamTile: 0.05, material: "rubber.silicone:262626"),
                  Xform(translation: V3(slideX, hy - 0.12 + 0.236, -hz + 0.062)))
            let outlet = V3(slideX - 0.18, 0.55, -hz)
            m.add(Prim.lathe([V2(0.001, 0), V2(0.03, 0), V2(0.03, 0.003), V2(0.02, 0.012), V2(0.001, 0.012)], segments: hi ? 18 : 8, seamTile: 0.05, material: chrome),
                  Xform(translation: outlet, rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
            let hose = catmull([V3(slideX, hy - 0.12, -hz + 0.062), V3(slideX - 0.02, hy - 0.32, -hz + 0.1), V3(slideX - 0.12, 0.8, -hz + 0.13), V3(slideX - 0.2, 0.6, -hz + 0.09), outlet + V3(0, 0, 0.02)], per: hi ? 5 : 2)
            m.add(Prim.tube(hose, radii: Array(repeating: 0.0065, count: hose.count), sides: hi ? 8 : 5, seamTile: 0.03, material: "metal.stainless"))
            // Glass-mounted hook with a squeegee hanging inside the panel (story detail).
            let hxp = hx - 0.025
            m.add(Prim.cylinder(radius: 0.017, height: 0.006, bevel: 0.002, segments: hi ? 14 : 8, material: chrome),
                  Xform(translation: V3(hxp, 1.55, 0.2), rotation: simd_quatf(degrees: 90, axis: V3(0, 0, 1))))
            let hook = catmull([V3(hxp - 0.004, 1.55, 0.2), V3(hxp - 0.03, 1.55, 0.2), V3(hxp - 0.04, 1.565, 0.2)], per: 3)
            m.add(Prim.tube(hook, radii: [0.0055, 0.0055, 0.0055, 0.0055, 0.0055, 0.0055, 0.0055, 0.0055, 0.0055, 0.0055].prefix(hook.count).map { $0 }, sides: hi ? 8 : 5, seamTile: 0.03, material: chrome))
            m.add(Prim.roundedBox(V3(0.012, 0.19, 0.016), radius: 0.004, bevelSegments: 1, material: "plastic.matte:2C2C2C"), Xform(translation: V3(hxp - 0.046, 1.46, 0.2)))
            m.add(Prim.roundedBox(V3(0.016, 0.012, 0.24), radius: 0.003, bevelSegments: 1, material: "rubber.silicone:222222"), Xform(translation: V3(hxp - 0.046, 1.355, 0.2)))
            groundAO(&m, height: 0.2, floor: 0.7)
            return m
        }
        return LODModel(levels: [make(0), make(1)], switchDistances: [6])
    }
}
