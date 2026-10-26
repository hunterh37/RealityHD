import simd
import Foundation

/// Art Deco Crittall steel window, 1.4 x 1.6 m: welded Z-section steel frame with a fixed four-light transom over two
/// opening casements of 2 x 3 lights. Each casement hangs on three butt hinges with an espagnolette rod, a cranked
/// handle, rod guides and keepers; glazing sits in putty beads. Fixing lugs screw to the jambs. The cast concrete
/// sill carries a drip and a throat. Cream paint is crazed and flaking, rust blooms along the bottom rails and
/// bleeds onto the sill.
public struct CrittallSteelWindow: RealAsset {
    public static let id = "crittall-steel-window"
    public static let summary = "Art Deco Crittall steel casement window: slim painted steel frame in a grid of lights, two opening casements with espagnolette fasteners, putty-glazed glass and a concrete sill."
    public static let tags = ["prop", "architecture", "facade", "window", "metal", "glass"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 6, distance: 3.0)

    /// Overall width and height (m).
    public var width: Float = 1.4
    public var height: Float = 1.6
    /// Window paint (cream, chalked).
    public var paint: MaterialKey = "metal.painted:D8D3C2"
    /// Paint showing through to primer along the rails.
    public var primer: MaterialKey = "metal.painted:8B8A84"
    public var rust: MaterialKey = "metal.rust"
    public var glass: MaterialKey = "glass.clear"
    public var concrete: MaterialKey = "concrete.smooth"
    public var steel: MaterialKey = "metal.steel"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = width - 0.02, H = height, y0: Float = 0.04, fz: Float = 0.075       // frame width, top, base, frame depth
        let jw: Float = 0.04                                                         // outer frame face width
        let sillD: Float = 0.12

        // Concrete sill: sloped top, drip lip and throat.
        FA.run(&m, [V2(0, 0), V2(sillD, 0), V2(sillD, 0.012), V2(sillD - 0.012, 0.018), V2(sillD - 0.012, 0.03), V2(sillD, 0.036), V2(0.025, 0.048), V2(0, 0.048)],
               length: width, at: V3(0, 0, 0), concrete, bevel: 0.0025)
        // Efflorescence and rust bleed on the sill.
        for i in 0..<5 {
            let sx = -0.5 + Float(i) * 0.26 + rng.float(-0.04...0.04)
            FJ.slab(&m, V3(rng.float(0.02...0.05), 0.0012, rng.float(0.05...0.09)), V3(sx, 0.0425 + 0.0, 0.07), "metal.rust")
        }

        // Outer frame: Z-section as a face member plus an inner lip, welded at the corners.
        let hFrame = H - y0
        for e: Float in [-1, 1] {
            FA.box(&m, V3(jw, hFrame, 0.044), V3(e * (W / 2 - jw / 2), y0 + hFrame / 2, 0.022 + 0.004), paint, r: 0.002)
            FA.box(&m, V3(0.014, hFrame - 0.08, 0.022), V3(e * (W / 2 - jw - 0.007), y0 + hFrame / 2, 0.044 + 0.004 + 0.011), paint, r: 0.0015)
        }
        for (y, mat) in [(y0 + jw / 2, primer), (H - jw / 2, paint)] as [(Float, MaterialKey)] {
            FA.box(&m, V3(W - 2 * jw + 0.004, jw, 0.044), V3(0, y, 0.026), mat, r: 0.002)
            FA.box(&m, V3(W - 2 * jw - 0.02, 0.014, 0.022), V3(0, y + (y < 0.5 ? 1 : -1) * (jw / 2 + 0.007 - 0.0), 0.059), paint, r: 0.0015)
        }
        // Weld beads at the four corners.
        for sx: Float in [-1, 1] { for (y, s) in [(y0 + jw, Float(1)), (H - jw, Float(-1))] as [(Float, Float)] {
            FC.bead(&m, r: 0.006, at: V3(sx * (W / 2 - jw), y, 0.05), steel, sub: 2); _ = s
        } }
        // Transom bar and the transom's four fixed lights.
        let yT: Float = 1.20, hT = H - jw - yT - 0.0
        FA.box(&m, V3(W - 2 * jw + 0.004, 0.034, 0.044), V3(0, yT, 0.026), paint, r: 0.002)
        FJ.sash(&m, cx: 0, cy: (yT + 0.017 + H - jw) / 2, w: W - 2 * jw, h: H - jw - yT - 0.017, z0: 0.01, thick: 0.05, stile: 0.012, cols: 4, rows: 1, bar: 0.012, paint, glass: glass)
        _ = hT

        // Two casements below the transom: stiles, rails, 2 x 3 lights, putty beads around every light.
        let cyBot = y0 + jw, cyTop = yT - 0.017, ch = cyTop - cyBot, cw = (W - 2 * jw) / 2 - 0.0015
        for e: Float in [-1, 1] {
            let cx = e * (cw / 2 + 0.002)
            FJ.sash(&m, cx: cx, cy: (cyBot + cyTop) / 2, w: cw, h: ch, z0: 0.03, thick: 0.044, stile: 0.03, cols: 2, rows: 3, bar: 0.013, paint, glass: glass)
            // Putty beads: one thin frame per light.
            let iw = cw - 0.06, ih = ch - 0.06
            for c in 0..<2 { for r in 0..<3 {
                let px = cx - iw / 2 + iw * (Float(c) + 0.5) / 2, py = cyBot + 0.03 + ih * (Float(r) + 0.5) / 3
                FJ.mouldedFrame(&m, cx: px, cy: py, w: iw / 2 - 0.02, h: ih / 3 - 0.02, z: 0.0735, profile: FJ.beadProfile(0.003, segments: 3), "metal.painted:C9C2AC", r: 0.002)
            } }
            // Butt hinges on the outer stile: three, each two leaves and a pin.
            let hx = e * (W / 2 - jw - 0.001)
            for t: Float in [0.12, 0.5, 0.88] {
                let hy = cyBot + ch * t
                FA.box(&m, V3(0.036, 0.07, 0.004), V3(hx - e * 0.01, hy, 0.0765), steel, r: 0.0008)
                FA.rod(&m, V3(hx + e * 0.003, hy - 0.036, 0.0775), V3(hx + e * 0.003, hy + 0.036, 0.0775), r: 0.0052, steel, sides: 10)
                for dy: Float in [-0.022, 0.022] { rivet(&m, at: V3(hx - e * 0.016, hy + dy, 0.0785), normal: FA.Z, radius: 0.0032, segments: 6, material: steel) }
            }
        }
        // Espagnolette on the left casement's meeting stile: rod, two guides, cranked handle and top/bottom keepers.
        let ex: Float = -0.003 - 0.012
        FA.rod(&m, V3(ex, cyBot + 0.06, 0.0765), V3(ex, cyTop - 0.06, 0.0765), r: 0.0034, steel, sides: 8)
        for y in [cyBot + 0.2, cyTop - 0.2] {
            FA.box(&m, V3(0.014, 0.03, 0.006), V3(ex, y, 0.0762), steel, r: 0.001)
            rivet(&m, at: V3(ex, y, 0.0795), normal: FA.Z, radius: 0.003, segments: 6, material: steel)
        }
        let hy = (cyBot + cyTop) / 2 - 0.03
        FA.box(&m, V3(0.016, 0.034, 0.008), V3(ex, hy, 0.0785), steel, r: 0.002)
        FA.path(&m, [V3(ex, hy, 0.083), V3(ex, hy, 0.094), V3(ex + 0.0, hy - 0.01, 0.1), V3(ex + 0.075, hy - 0.012, 0.1)], r: 0.0058, steel, sides: 8)
        FC.bead(&m, r: 0.0085, at: V3(ex + 0.078, hy - 0.012, 0.1), steel, sub: 3)
        for y in [cyBot + 0.015, cyTop - 0.015] { FA.box(&m, V3(0.012, 0.02, 0.012), V3(ex, y, 0.056), steel, r: 0.001) }
        // Casement stay: pivoting bar on the bottom rail with a peg.
        FA.box(&m, V3(0.3, 0.012, 0.004), V3(0.32, cyBot + 0.016, 0.0765), steel, r: 0.0012, rot: FA.q(2, FA.Z))
        FA.cylZ(&m, r: 0.004, h: 0.012, at: V3(0.46, cyBot + 0.019, 0.0715), steel, bevel: 0.001, segments: 8)
        // Fixing lugs: steel straps screwed to the jambs.
        for e: Float in [-1, 1] { for y: Float in [0.30, 0.82, 1.38] {
            FA.box(&m, V3(0.036, 0.02, 0.004), V3(e * (W / 2 - 0.018), y, 0.0765), steel, r: 0.001)
            rivet(&m, at: V3(e * (W / 2 - 0.018), y, 0.0785), normal: FA.Z, radius: 0.003, segments: 6, material: "metal.screw-zinc")
        } }

        // Wear: rust blooming on the bottom rails, flaked paint on the jambs and rails, streaks onto the sill.
        let fzFront: Float = 0.0735
        for e: Float in [-1, 1] {
            FJ.peel(&m, at: V3(e * 0.31, y0 + 0.058, 0.0765), w: 0.06, h: 0.018, rust, rng: &rng)
            FJ.peel(&m, at: V3(e * 0.52, y0 + 0.07, 0.0765), w: 0.04, h: 0.014, rust, rng: &rng)
            FJ.peel(&m, at: V3(e * (W / 2 - jw / 2), 0.18, 0.0735), w: 0.02, h: 0.06, primer, rng: &rng)
            FJ.peel(&m, at: V3(e * (W / 2 - jw / 2), 0.22, 0.0736), w: 0.014, h: 0.03, rust, rng: &rng)
            FJ.peel(&m, at: V3(e * (W / 2 - jw / 2), 1.30, 0.0735), w: 0.022, h: 0.05, primer, rng: &rng)
            FJ.streak(&m, x: e * 0.31, top: y0 + 0.04, length: 0.09, width: 0.012, z: 0.12 - 0.0, rust)
        }
        FJ.peel(&m, at: V3(-0.2, yT, 0.0735), w: 0.07, h: 0.014, primer, rng: &rng)
        FJ.peel(&m, at: V3(0.3, y0 + 0.02, 0.0735), w: 0.05, h: 0.016, rust, rng: &rng)
        FJ.chips(&m, spots: [V3(-0.60, 0.7, 0), V3(0.60, 1.0, 0), V3(0.0, yT - 0.0, 0)], face: 0.0743, primer, rng: &rng, each: 4)
        // Heavier failure: flaked paint along the stiles and glazing bars, rust at the transom bar ends, one cracked light.
        for _ in 0..<14 {
            let e: Float = rng.chance(0.5) ? -1 : 1
            FJ.peel(&m, at: V3(e * (W / 2 - jw / 2) + rng.float(-0.006...0.006), rng.float(0.15...1.5), 0.0735), w: rng.float(0.014...0.026), h: rng.float(0.03...0.09),
                    rng.chance(0.45) ? rust : primer, rng: &rng)
        }
        for e: Float in [-1, 1] {
            FJ.peel(&m, at: V3(e * 0.64, yT, 0.0735), w: 0.05, h: 0.026, rust, rng: &rng)
            FJ.peel(&m, at: V3(e * 0.33, yT, 0.0735), w: 0.08, h: 0.014, primer, rng: &rng)
            FJ.peel(&m, at: V3(e * 0.33, 0.13, 0.0735), w: 0.10, h: 0.03, primer, rng: &rng)
        }
        for k in 0..<4 {
            let ang = Float(k) * 70 - 20
            FJ.slab(&m, V3(0.12 - Float(k) * 0.02, 0.0014, 0.001), V3(0.31 + 0.02 * Float(k % 2), 0.78, 0.0522), "glass.frosted", rot: FA.q(ang, FA.Z))
        }
        // Dirt line along the glass edge above the bottom rail of each casement.
        for e: Float in [-1, 1] { FJ.slab(&m, V3(0.52, 0.016, 0.0006), V3(e * 0.33, y0 + jw + 0.03 + 0.008, 0.0515), "metal.painted:5B574B") }
        _ = fzFront; _ = fz
        groundAO(&m, height: 0.12, floor: 0.85)
        return LODModel(FC.place(m))
    }
}
