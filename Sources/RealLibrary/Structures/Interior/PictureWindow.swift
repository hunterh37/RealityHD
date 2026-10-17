import simd
import Foundation

/// Fixed picture window, 1.8 x 1.2 x 0.2 m: painted wood frame (jambs, head, sloped exterior sill with drip nose),
/// interior stool, apron and casing, exterior brickmould, double glazing with a spacer, applied 3 x 2 grilles with
/// a matching spacer bar, glazing stops and a caulk bead. Origin at the sill center, thickness on Z, interior +Z.
public struct PictureWindow: RealAsset {
    public static let id = "picture-window"
    public static let summary = "Fixed picture window, 1.8 x 1.2 m: painted wood frame, sloped sill, stool and casing, double glazing, divided-lite grilles."
    public static let tags = ["structure", "floorplan", "interior", "window", "glass", "wood"]
    public static let budget = 12_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 8, distance: 1.1, studio: true)

    /// Casing outer width and overall height (m).
    public var width: Float = 1.8
    public var height: Float = 1.2
    /// Painted wood for frame, casing and grilles.
    public var paint: MaterialKey = "wood.painted-shaker:E8E3D6"
    /// Stool (interior sill) and exterior sill material: more worn, slightly yellowed paint.
    public var sillMaterial: MaterialKey = "wood.painted-shaker-worn:D9D5C8"
    /// Stool (interior sill) material.
    public var stoolMaterial: MaterialKey = "wood.painted-shaker-worn:E2DBC6"
    public var glass: MaterialKey = "glass.clear"
    /// Grille lites across and down.
    public var cols = 3
    public var rows = 2
    public init() {}

    func model(lod: Int, seed: UInt64) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let seg = lod == 0 ? 2 : 1
        func add(_ p: WindowKit.Part) { m.add(p.0, p.1) }
        func box(_ s: V3, _ c: V3, _ mat: MaterialKey, r: Float = 0.002) -> WindowKit.Part { WindowKit.box(s, c, mat, r: r, seg: seg) }
        let W = width, H = height
        let sillTop: Float = 0.075, jw: Float = 0.065, jz: Float = 0.06
        let frameW = W - 0.18                      // jamb outer width
        let headTop = H - 0.05                     // frame head top
        let ox = frameW / 2 - jw                    // opening half width
        let oy0 = sillTop, oy1 = headTop - jw

        // Sill block with sloped top and drip nose, stool and apron.
        let s = WindowKit.sill(width: W - 0.08, inner: jz, out: 0.1, rise: sillTop, nose: 0.035, material: sillMaterial)
        m.add(s.0, s.1)
        add(box(V3(W, 0.03, 0.1), V3(0, sillTop + 0.015, 0.05), stoolMaterial, r: 0.006))
        add(box(V3(frameW + 0.06, 0.075, 0.02), V3(0, 0.0375, jz + 0.012), paint, r: 0.002))

        // Frame: jambs and head.
        for sx: Float in [-1, 1] {
            add(box(V3(jw, headTop - sillTop, 2 * jz), V3(sx * (frameW / 2 - jw / 2), (headTop + sillTop) / 2, 0), paint))
            // Interior casing and exterior brickmould.
            add(box(V3(0.065, headTop - 0.01 - 0.105, 0.02), V3(sx * (frameW / 2 + 0.0325 - 0.012), (headTop - 0.01 + 0.105) / 2, jz + 0.01), paint))
            add(box(V3(0.04, headTop + 0.02 - sillTop, 0.016), V3(sx * (frameW / 2 + 0.02 - 0.004), (headTop + 0.02 + sillTop) / 2, -jz - 0.008), sillMaterial))
        }
        add(box(V3(frameW - 2 * jw + 0.002, jw, 2 * jz), V3(0, headTop - jw / 2, 0), paint))
        // Head casing with a small cap molding.
        add(box(V3(frameW + 0.14, 0.07, 0.02), V3(0, headTop - 0.01, jz + 0.01), paint, r: 0.003))
        add(box(V3(frameW + 0.18, 0.025, 0.035), V3(0, H - 0.0125, jz + 0.0175), paint, r: 0.005))
        add(box(V3(frameW + 0.08, 0.03, 0.016), V3(0, headTop + 0.01, -jz - 0.008), sillMaterial))

        // Fixed sash set in the frame with a 3 mm margin, then the insulated unit, beads and spacer.
        let sw: Float = 0.05, sd: Float = 0.05
        let sx0 = ox - 0.003, sy0 = oy0 + 0.003, sy1 = oy1 - 0.003
        for sx: Float in [-1, 1] {
            add(box(V3(sw, sy1 - sy0, sd), V3(sx * (sx0 - sw / 2), (sy0 + sy1) / 2, 0), paint, r: 0.003))
        }
        for (y, d) in [(sy0 + sw / 2, Float(1)), (sy1 - sw / 2, -1)] {
            _ = d
            add(box(V3(2 * (sx0 - sw) + 0.002, sw, sd), V3(0, y, 0), paint, r: 0.003))
        }
        let gx = sx0 - sw, gy0 = sy0 + sw, gy1 = sy1 - sw
        let gw = 2 * gx + 0.03, gh = gy1 - gy0 + 0.03, gcy = (gy0 + gy1) / 2
        for z: Float in [-0.01, 0.01] {
            add(box(V3(gw, gh, 0.004), V3(0, gcy, z), glass, r: 0.001))
        }
        let sp: Float = 0.012
        for sx: Float in [-1, 1] {
            m.add(cuboid(V3(sp, gy1 - gy0, 0.016), material: "rubber"), Xform(translation: V3(sx * (gx - sp / 2 + 0.002), gcy, 0)))
            for z: Float in [-1, 1] {
                add(box(V3(0.014, gy1 - gy0, 0.012), V3(sx * (gx - 0.007 + 0.001), gcy, z * 0.0215), paint, r: 0.002))
            }
        }
        for y in [gy0 + sp / 2 - 0.002, gy1 - sp / 2 + 0.002] {
            m.add(cuboid(V3(2 * gx, sp, 0.016), material: "rubber"), Xform(translation: V3(0, y, 0)))
        }
        for y in [gy0 + 0.007 - 0.001, gy1 - 0.007 + 0.001] {
            for z: Float in [-1, 1] { add(box(V3(2 * gx, 0.014, 0.012), V3(0, y, z * 0.0215), paint, r: 0.002)) }
        }
        // Applied grilles inside the beads.
        let lw = 2 * gx - 0.028, lh = gy1 - gy0 - 0.028
        for p in WindowKit.grille(cols: cols, rows: rows, w: lw, h: lh, cy: gcy, bar: 0.026, zFaces: lod == 0 ? [-0.0185, 0.0185] : [0.0185],
                                  depth: 0.009, zMid: lod == 0 ? 0 : nil, midDepth: 0.016, mat: paint, midMat: "rubber") { add(p) }
        // Drip cap over the exterior head.
        add(box(V3(frameW + 0.1, 0.012, 0.03), V3(0, headTop + 0.03, -jz - 0.014), sillMaterial, r: 0.003))
        if lod == 0 {
            // Caulk bead along the exterior brickmould and a weep cover on the sill.
            for sx: Float in [-1, 1] {
                add(box(V3(0.005, headTop + 0.02 - sillTop, 0.004), V3(sx * (frameW / 2 + 0.043), (headTop + 0.02 + sillTop) / 2, -jz - 0.016), "rubber", r: 0.0015))
            }
            for dx: Float in [-0.55, 0.55] {
                add(box(V3(0.04, 0.004, 0.012), V3(dx, sillTop + 0.002, -jz + 0.01), "plastic.matte", r: 0.0015))
            }
            // Painted-over lock-screw heads on the interior jambs.
            for sx: Float in [-1, 1] {
                for y in [0.35, 0.85] as [Float] {
                    m.add(Prim.cylinder(radius: 0.005, height: 0.003, bevel: 0.001, segments: 10, bevelSegments: 1, material: "metal.brushed-nickel"),
                          Xform(translation: V3(sx * (ox + 0.0005), y, 0.045), rotation: simd_quatf(degrees: sx * -90, axis: V3(0, 0, 1))))
                }
            }
        }
        _ = rng.float()
        groundAO(&m, height: 0.06, floor: 0.75)
        return m
    }

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [model(lod: 0, seed: seed), model(lod: 1, seed: seed)], switchDistances: [6])
    }
}
