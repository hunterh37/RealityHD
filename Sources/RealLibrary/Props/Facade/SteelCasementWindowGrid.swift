import simd
import Foundation

/// Steel casement window grid, Modernism: a 1.4 m square Crittall-style window in powder-coated steel
/// with a 3 x 3 grid of lights, two opening casements with espagnolette handles and butt hinges,
/// putty-bead glazing, fixing lugs with zinc screws and a pressed sill. Paint is chipped and rusting at
/// the lower corners.
public struct SteelCasementWindowGrid: RealAsset {
    public static let id = "steel-casement-window-grid"
    public static let summary = "Steel casement window grid, 1.4 m: slim frame, 3 x 3 lights, two opening casements, handles, hinges, sill."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 5000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 8, distance: 3.6)

    /// Frame paint.
    public var paint: MaterialKey = "metal.powdercoat:23282D"
    /// Worn paint at hand and weather contact.
    public var worn: MaterialKey = "metal.powdercoat-worn"
    /// Glazing.
    public var glass: MaterialKey = "glass.pane"
    /// Handles and hinge pins.
    public var chrome: MaterialKey = "metal.chrome"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W: Float = 1.4, H: Float = 1.4, D: Float = 0.06, f: Float = 0.032
        let sillH: Float = 0.014
        let cy = sillH + (H - sillH) / 2
        let ih = H - sillH
        // Outer frame: Z-section approximated by a deep web and an inner glazing flange.
        for e: Float in [-1, 1] {
            FA.box(&m, V3(f, ih, D), V3(e * (W / 2 - f / 2), cy, D / 2), paint, r: 0.0015)
            FA.box(&m, V3(0.012, ih - 2 * f, 0.016), V3(e * (W / 2 - f - 0.006), cy, 0.008), paint, r: 0.001)
        }
        FA.box(&m, V3(W - 2 * f + 0.004, f, D), V3(0, sillH + f / 2, D / 2), worn, r: 0.0015)
        FA.box(&m, V3(W - 2 * f + 0.004, f, D), V3(0, H - f / 2, D / 2), paint, r: 0.0015)
        // Pressed sill with a drip nose.
        FA.run(&m, [V2(0, 0), V2(0.1, 0), V2(0.1, 0.006), V2(0.094, 0.01), V2(0.04, sillH), V2(0, sillH)], length: W, "metal.galvanized-aged", bevel: 0.0008)
        let iw = W - 2 * f, ihh = H - sillH - 2 * f
        let x0 = -iw / 2, yb = sillH + f
        // Grid of lights: two vertical and two horizontal tee-bar muntins.
        let mun: Float = 0.017
        let cols = 3, rows = 3
        let lw = (iw - Float(cols - 1) * mun) / Float(cols), lh = (ihh - Float(rows - 1) * mun) / Float(rows)
        FJ.slab(&m, V3(iw, ihh, 0.004), V3(0, yb + ihh / 2, 0.026), glass)
        for c in 1..<cols {
            let x = x0 + Float(c) * lw + (Float(c) - 0.5) * mun
            FJ.slab(&m, V3(mun, ihh + 0.004, 0.042), V3(x, yb + ihh / 2, 0.021), paint)
            FJ.slab(&m, V3(0.006, ihh, 0.01), V3(x, yb + ihh / 2, 0.047), paint)
        }
        for r in 1..<rows {
            let y = yb + Float(r) * lh + (Float(r) - 0.5) * mun
            FJ.slab(&m, V3(iw + 0.004, mun, 0.042), V3(0, y, 0.021), r == 1 ? worn : paint)
            FJ.slab(&m, V3(iw, 0.006, 0.01), V3(0, y, 0.047), paint)
        }
        // Putty bead around each light.
        for c in 0..<cols { for r in 0..<rows {
            let cx = x0 + lw / 2 + Float(c) * (lw + mun), cyy = yb + lh / 2 + Float(r) * (lh + mun)
            FJ.mouldedFrame(&m, cx: cx, cy: cyy, w: lw, h: lh, z: 0.038, profile: FJ.beadProfile(0.0035, segments: 3), "metal.satin-aluminum", r: 0.002)
        }}
        // Two opening casements (top-left and centre-right lights): inner sash frame proud of the grid, hinge knuckles, handle.
        let opens: [(Int, Int)] = [(0, 2), (2, 1)]
        for (c, r) in opens {
            let cx = x0 + lw / 2 + Float(c) * (lw + mun), cyy = yb + lh / 2 + Float(r) * (lh + mun)
            let s: Float = 0.014
            for e: Float in [-1, 1] {
                FJ.slab(&m, V3(s, lh + 0.012, 0.014), V3(cx + e * (lw / 2 - s / 2 + 0.002), cyy, 0.056), paint)
                FJ.slab(&m, V3(lw + 0.012, s, 0.014), V3(cx, cyy + e * (lh / 2 - s / 2 + 0.002), 0.056), paint)
            }
            let hx = cx + (c == 0 ? 1 : -1) * (lw / 2 - 0.016)
            FA.cylZ(&m, r: 0.008, h: 0.01, at: V3(hx, cyy, 0.062), chrome, bevel: 0.0012, segments: 12)
            FA.box(&m, V3(0.014, 0.075, 0.007), V3(hx, cyy - 0.03, 0.074), chrome, r: 0.0025)
            let hinge = cx + (c == 0 ? -1 : 1) * (lw / 2 + 0.002)
            for yy in [cyy - lh / 2 + 0.05, cyy + lh / 2 - 0.05] {
                FA.cylZ(&m, r: 0.0055, h: 0.03, at: V3(hinge, yy - 0.015, 0.048), chrome, bevel: 0.0008, segments: 8)
                FA.cylZ(&m, r: 0.0055, h: 0.03, at: V3(hinge, yy - 0.015, 0.048), chrome, bevel: 0.0008, segments: 8)
            }
        }
        // Fixing lugs with zinc screws on each jamb.
        for e: Float in [-1, 1] { for y in [Float(0.28), 0.7, 1.12] {
            FA.box(&m, V3(0.028, 0.045, 0.004), V3(e * (W / 2 - 0.012), y, D + 0.001), paint, r: 0.0008)
            FA.cylZ(&m, r: 0.0045, h: 0.003, at: V3(e * (W / 2 - 0.012), y, D + 0.003), "metal.screw-zinc", bevel: 0.0006, segments: 8)
        }}
        // Rust at the lower corners and chipped paint on the sill rail.
        for e: Float in [-1, 1] {
            FJ.slab(&m, V3(rng.float(0.02...0.04), rng.float(0.05...0.12), 0.001), V3(e * (W / 2 - f / 2), sillH + 0.06, D + 0.0005), "metal.rust")
        }
        FJ.slab(&m, V3(0.1, 0.012, 0.001), V3(-0.3, sillH + 0.018, D + 0.0005), "metal.rust")
        FJ.slab(&m, V3(0.06, 0.008, 0.001), V3(0.35, sillH + 0.024, D + 0.0005), "metal.rust")
        groundAO(&m, height: 0.1, floor: 0.85)
        return LODModel(FC.place(m))
    }
}
