import simd
import Foundation

/// Accordion hurricane shutter: mill-finish aluminum blades with a raised rib and rolled hinge knuckles,
/// closed across a window opening between header and sill tracks, with the folded stack at the jamb, a
/// pull handle, a hasp and a brass padlock. Wall plane at z = 0.
public struct AccordionHurricaneShutter: RealAsset {
    public static let id = "accordion-hurricane-shutter"
    public static let summary = "Aluminum accordion hurricane shutter 1.2 x 1.5 m: interlocking ribbed blades, header and sill tracks, folded stack, padlocked hasp."
    public static let tags = ["prop", "architecture", "facade", "metal"]
    public static let budget = 11_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 8, distance: 1.9)

    /// Overall width and height (m).
    public var width: Float = 1.2
    public var height: Float = 1.5
    /// Blade width across the face (m) and sheet thickness.
    public var blade: Float = 0.073
    public var sheet: Float = 0.0022
    public var aluminum: MaterialKey = "metal.aluminum"
    public var track: MaterialKey = "metal.anodized-worn"
    public var steel: MaterialKey = "metal.stainless"
    public var brass: MaterialKey = "metal.brass-aged"
    public init() {}

    /// Ribbed blade section in (x, -z): web with a raised centre rib, returned edges at the knuckles.
    private func section(_ p: Float, _ t: Float) -> [V2] {
        let front: [(Float, Float)] = [(0, 0), (0.010, 0), (0.019, 0.007), (p - 0.019, 0.007), (p - 0.010, 0), (p, 0)]
        var pts = front.map { V2($0.0, -$0.1) }
        pts += front.reversed().map { V2($0.0 - ($0.0 == 0 ? -0.0005 : 0), -($0.1 - t)) }
        return pts
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = width, H = height, p = blade, t = sheet
        let yLo: Float = 0.045, yHi = H - 0.06, bh = yHi - yLo
        let x0 = -W / 2, zPlane: Float = 0.07
        let stackW: Float = 0.152
        // Closed blades from the stack to the leading edge.
        let closedStart = x0 + stackW + 0.012
        let n = Int(((x0 + W - 0.03) - closedStart) / p)
        let pitch = ((x0 + W - 0.03) - closedStart) / Float(n)
        for i in 0..<n {
            let bx = closedStart + Float(i) * pitch
            let mat: MaterialKey = (i == 3) ? "metal.aluminum-cast" : rng.pick([aluminum, aluminum, "metal.aluminum-brushed", "metal.satin-aluminum"])
            m.add(Prim.extrude(section(pitch, t), depth: bh, bevel: 0.0005, bevelSegments: 1, material: mat),
                  Xform(translation: V3(bx, yLo + bh / 2, zPlane), rotation: FA.q(-90, FA.X)))
            // Rolled hinge knuckle at the left edge of each blade.
            FA.rod(&m, V3(bx, yLo + 0.004, zPlane - 0.003), V3(bx, yHi - 0.004, zPlane - 0.003), r: 0.0045, i % 5 == 2 ? "metal.galvanized-aged" : aluminum, sides: 8)
            // Salt-spray rust weep running down the ridge from a rivet line at the top.
            if rng.chance(0.55) {
                let len = rng.float(0.08...0.34)
                FA.box(&m, V3(rng.float(0.005...0.010), len, 0.0007), V3(bx + pitch / 2, yHi - 0.03 - len / 2, zPlane + 0.0074), "metal.rust", r: 0.0002)
            }
            if rng.chance(0.35) {
                let len = rng.float(0.05...0.16)
                FA.box(&m, V3(pitch * 0.5, len, 0.0006), V3(bx + pitch / 2, yLo + 0.03 + len / 2, zPlane + 0.0005), "metal.galvanized-aged", r: 0.0002)
            }
        }
        let lead = closedStart + Float(n) * pitch
        FA.rod(&m, V3(lead, yLo + 0.004, zPlane - 0.003), V3(lead, yHi - 0.004, zPlane - 0.003), r: 0.0045, aluminum, sides: 8)
        // Folded accordion stack: blades alternately angled about Y.
        let leg: Float = 0.062, adv: Float = 0.0347, zc: Float = 0.05
        for k in 0..<4 {
            let ang: Float = (k % 2 == 0) ? 56 : -56
            let cx = x0 + 0.012 + (Float(k) + 0.5) * adv
            m.add(Prim.extrude([V2(-leg / 2, -0.0015), V2(leg / 2, -0.0015), V2(leg / 2, 0.0007), V2(-leg / 2, 0.0007)],
                               depth: bh, bevel: 0.0005, bevelSegments: 1, material: k == 2 ? "metal.galvanized-aged" : aluminum),
                  Xform(translation: V3(cx, yLo + bh / 2, zc), rotation: FA.q(ang, FA.Y) * FA.q(-90, FA.X)))
        }
        for k in 0...4 {
            let kx = x0 + 0.012 + Float(k) * adv
            let kzv: Float = zc + ((k % 2 == 0) ? 1 : -1) * leg * sin(Float(56) * .pi / 180) / 2
            FA.rod(&m, V3(kx, yLo + 0.004, kzv), V3(kx, yHi - 0.004, kzv), r: 0.0045, aluminum, sides: 8)
        }
        // Nylon glide shoes under the stack knuckles and pin caps on top.
        for k in 0...4 {
            let kx = x0 + 0.012 + Float(k) * adv
            let kzv: Float = zc + ((k % 2 == 0) ? 1 : -1) * leg * sin(Float(56) * .pi / 180) / 2
            FA.box(&m, V3(0.016, 0.012, 0.016), V3(kx, 0.038, kzv), "plastic.black", r: 0.003)
            FC.bead(&m, r: 0.0052, at: V3(kx, yHi + 0.002, kzv), steel, sub: 3)
        }
        // Jamb post carrying the stack, anchored to the wall.
        FA.box(&m, V3(0.03, bh + 0.02, 0.022), V3(x0 + 0.015, yLo + bh / 2, 0.011), track, r: 0.002)
        // Header track: boxed channel with a drip lip and a row of masonry screws.
        FA.box(&m, V3(W, 0.06, 0.10), V3(0, H - 0.03, 0.05), track, r: 0.004)
        FA.box(&m, V3(W - 0.01, 0.012, 0.098), V3(0, H - 0.066, 0.049), track, r: 0.002)
        FA.box(&m, V3(W - 0.02, 0.014, 0.014), V3(0, H - 0.05, 0.097), "metal.aluminum-cast", r: 0.003)
        for i in 0..<9 {
            let x = x0 + 0.07 + Float(i) * (W - 0.14) / 8
            FA.cylZ(&m, r: 0.0065, h: 0.004, at: V3(x, H - 0.03, 0.1), steel, bevel: 0.0012, segments: 10)
            FA.box(&m, V3(0.008, 0.0012, 0.0012), V3(x, H - 0.03, 0.1045), "metal.tool-ground", r: 0.0003)
        }
        // Header end caps with their own screws.
        for sx: Float in [-1, 1] {
            FA.box(&m, V3(0.006, 0.064, 0.104), V3(sx * (W / 2 + 0.001), H - 0.03, 0.05), "metal.anodized", r: 0.0015)
            FA.cylZ(&m, r: 0.0035, h: 0.003, at: V3(sx * (W / 2 + 0.001), H - 0.03, 0.09), steel, bevel: 0.0008, segments: 8)
        }
        // Sill track: low channel with drain slots, leading-edge keeper.
        FA.box(&m, V3(W, 0.032, 0.10), V3(0, 0.016, 0.05), track, r: 0.003)
        FA.box(&m, V3(W - 0.02, 0.012, 0.012), V3(0, 0.038, 0.074), track, r: 0.002)
        FA.box(&m, V3(W - 0.02, 0.012, 0.012), V3(0, 0.038, 0.05), track, r: 0.002)
        for i in 0..<6 {
            let x = x0 + 0.25 + Float(i) * 0.14
            FA.box(&m, V3(0.05, 0.004, 0.003), V3(x, 0.019, 0.1007), "metal.parkerized", r: 0.0005)
        }
        for x in [x0 + 0.1, x0 + W / 2, x0 + W - 0.1] as [Float] {
            FA.cylZ(&m, r: 0.0065, h: 0.004, at: V3(x, 0.016, 0.1), steel, bevel: 0.0012, segments: 10)
        }
        // Leading edge: closing bar with pull handle and hasp.
        let lx = x0 + W - 0.015
        FA.box(&m, V3(0.03, bh, 0.034), V3(lx, yLo + bh / 2, zPlane + 0.005), track, r: 0.003)
        FA.box(&m, V3(0.034, 0.004, 0.012), V3(lx, yLo + bh / 2 + 0.02, zPlane + 0.026), steel, r: 0.0012)
        m.add(barHandle(length: 0.16, standoff: 0.03, radius: 0.0065, material: steel),
              Xform(translation: V3(lx, yLo + bh * 0.45, zPlane + 0.022), rotation: FA.q(90, FA.Z)))
        // Hasp on the closing bar with a staple on the jamb face of the wall return, and a brass padlock.
        let hy = yLo + 0.28
        FA.box(&m, V3(0.036, 0.09, 0.004), V3(lx, hy, zPlane + 0.024), steel, r: 0.0015)
        FA.cylZ(&m, r: 0.0035, h: 0.006, at: V3(lx, hy + 0.03, zPlane + 0.026), steel, bevel: 0.001, segments: 8)
        FA.cylZ(&m, r: 0.0035, h: 0.006, at: V3(lx, hy - 0.03, zPlane + 0.026), steel, bevel: 0.001, segments: 8)
        FA.box(&m, V3(0.042, 0.052, 0.020), V3(lx, hy - 0.075, zPlane + 0.03), brass, r: 0.006)
        m.add(Prim.torus(major: 0.013, minor: 0.0035, segments: 20, sides: 8, arc: 180, material: steel),
              Xform(translation: V3(lx, hy - 0.046, zPlane + 0.03), rotation: FA.q(90, FA.X)))
        FA.cylZ(&m, r: 0.004, h: 0.002, at: V3(lx, hy - 0.085, zPlane + 0.041), "metal.steel", bevel: 0.0008, segments: 10)
        _ = rng.float()
        groundAO(&m, height: 0.12, floor: 0.75)
        return LODModel(FC.place(m))
    }
}
