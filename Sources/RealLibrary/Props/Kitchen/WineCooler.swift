import simd
import Foundation

/// Undercounter wine cooler, 24 in: stainless cabinet with a front vent grille, a black control strip
/// with display and buttons, a stainless-framed tinted glass door with a vertical bar handle, and a
/// dark interior lit by an LED strip with five beech slat shelves holding lying bottles with foil
/// capsules.
public struct WineCooler: RealAsset {
    public static let id = "wine-cooler"
    public static let summary = "Undercounter wine cooler, 24 in: stainless-framed tinted glass door, bar handle, beech slat shelves with lying bottles, LED strip, front control strip."
    public static let tags = ["prop", "floorplan", "kitchen", "appliance", "glass", "metal", "wood", "interior"]
    public static let budget = 11800
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 22, elevation: 8, distance: 2.0, studio: true)

    /// Overall size in meters including the handle (x width, y height, z depth).
    public var size = V3(0.6, 0.85, 0.6)
    /// Fraction of shelf slots holding a bottle.
    public var fill: Float = 0.8
    public init() {}

    static func bottle(_ glass: MaterialKey, foil: MaterialKey) -> Surface {
        // Bordeaux bottle lying along +Z (base at z = 0, neck toward +Z), radius 0.037, length 0.3.
        let pts: [V2] = [V2(0, 0), V2(0.033, 0), V2(0.037, 0.012), V2(0.037, 0.16), V2(0.026, 0.205), V2(0.0125, 0.23), V2(0.0125, 0.3), V2(0.0105, 0.3), V2(0.0105, 0.23)]
        var s = Prim.lathe(pts, segments: 8, material: glass)
        s.append(Prim.lathe([V2(0.0132, 0.26), V2(0.0145, 0.262), V2(0.0145, 0.3), V2(0.0132, 0.3)], segments: 8, material: foil))
        s.append(Prim.lathe([V2(0.0377, 0.07), V2(0.0377, 0.15)], segments: 8, material: "paper.sheet:E9E2CF"))
        return s
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        let W = size.x, H = size.y, D = size.z
        let zFront = D / 2 - 0.035
        let doorT: Float = 0.03
        let zDoorBack = zFront - doorT
        let zBack = -D / 2
        let wall: Float = 0.015
        let dark: MaterialKey = "plastic.matte:1C1C1E"
        let kick: Float = 0.065
        let stripLo: Float = 0.775
        let inW = W - 2 * wall

        func rb(_ s: V3, _ c: V3, _ mat: MaterialKey, r: Float = 0.003) -> (Surface, Xform) {
            (r <= 0.0025 ? cuboid(s, material: mat) : Prim.roundedBox(s, radius: r, bevelSegments: 1, material: mat), Xform(translation: c))
        }
        func level(_ hi: Bool) -> Model {
            var m = Model(name: Self.id)
            func add(_ b: (Surface, Xform)) { m.add(b.0, b.1) }
            let zl = zDoorBack - zBack, zc = (zBack + zDoorBack) / 2
            for sx: Float in [-1, 1] { add(rb(V3(wall, H, zl), V3(sx * (W / 2 - wall / 2), H / 2, zc), "metal.stainless", r: 0.005)) }
            add(rb(V3(W, 0.02, zl), V3(0, H - 0.01, zc), "metal.stainless", r: 0.005))
            add(rb(V3(inW, H - 0.03, 0.01), V3(0, H / 2, zBack + 0.005), "metal.galvanized", r: 0.002))
            add(rb(V3(inW, 0.03, zl), V3(0, 0.025, zc), "metal.stainless", r: 0.002))
            // Front vent grille.
            add(rb(V3(W - 0.02, kick - 0.012, 0.012), V3(0, kick / 2 + 0.004, zFront - 0.012), dark, r: 0.003))
            if hi { for i in 0..<5 { add(rb(V3(W - 0.08, 0.004, 0.006), V3(0, 0.014 + Float(i) * 0.011, zFront - 0.005), "metal.anodized", r: 0.001)) } }
            // Cavity.
            let cLo = kick + 0.012, cHi = stripLo - 0.012
            var cav = Prim.roundedBox(V3(inW - 0.03, cHi - cLo, zl - 0.02), radius: 0.008, bevelSegments: 1, material: dark).flipped()
            cav = cav.transformed(Xform(translation: V3(0, (cLo + cHi) / 2, zc - 0.005)))
            m.add(cav)
            // LED strip along the roof front edge.
            add(rb(V3(inW - 0.1, 0.006, 0.012), V3(0, cHi - 0.004, zDoorBack - 0.03), "emissive.warm", r: 0.001))
            // Shelves and bottles.
            let nShelf = 5
            let sd = zl - 0.07, sz = zDoorBack - 0.02 - sd / 2
            let pitch = (cHi - cLo - 0.04) / Float(nShelf)
            for s in 0..<nShelf {
                let y = cLo + 0.03 + Float(s) * pitch
                let slat: Float = 0.05, gap: Float = 0.012
                let n = Int(sd / (slat + gap))
                for i in 0..<n {
                    m.add(hi ? Prim.roundedBox(V3(inW - 0.04, 0.012, slat), radius: 0.0035, bevelSegments: 1, material: "wood.beech-stained") : cuboid(V3(inW - 0.04, 0.012, slat), material: "wood.beech-stained"),
                          Xform(translation: V3(0, y, zDoorBack - 0.02 - slat / 2 - Float(i) * (slat + gap))))
                }
                for sx: Float in [-1, 1] { add(rb(V3(0.012, 0.03, sd), V3(sx * (inW / 2 - 0.03), y - 0.01, sz), "metal.anodized", r: 0.002)) }
                guard hi else { continue }
                // Row of lying bottles, necks to the front.
                let cols = 6
                let span = inW - 0.09
                for c in 0..<cols where s < nShelf - 0 && rng.chance(fill) {
                    let x = -span / 2 + (Float(c) + 0.5) * span / Float(cols)
                    let glass: MaterialKey = rng.chance(0.65) ? "glass.emerald" : (rng.chance(0.5) ? "glass.tinted" : "glass.emerald:3A4A2A")
                    let foil: MaterialKey = rng.pick(["metal.brass-aged", "metal.copper", "metal.stainless", "plastic.matte:6A1420"])
                    let z0 = zDoorBack - 0.02 - 0.3 - rng.float(0...0.04)
                    m.add(Self.bottle(glass, foil: foil),
                          Xform(translation: V3(x, y + 0.006 + 0.037, z0), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))).jittered(&rng, deg: 0.6, offset: 0.002))
                }
            }
            // Control strip: black glass, display, buttons.
            add(rb(V3(W - 0.01, H - stripLo + 0.012, 0.02), V3(0, (stripLo - 0.012 + H) / 2, zFront - 0.01), "metal.stainless", r: 0.004))
            add(rb(V3(W - 0.07, H - stripLo - 0.02, 0.004), V3(0, (stripLo + H) / 2 - 0.002, zFront + 0.0005), "screen.off", r: 0.002))
            add(rb(V3(0.07, 0.02, 0.002), V3(-0.15, (stripLo + H) / 2 - 0.002, zFront + 0.0025), "emissive.led-green:7FB8FF", r: 0.001))
            if hi { for i in 0..<4 {
                m.add(Prim.cylinder(radius: 0.008, height: 0.003, bevel: 0.001, segments: 10, bevelSegments: 1, material: "metal.chrome"),
                      Xform(translation: V3(0.04 + Float(i) * 0.05, (stripLo + H) / 2 - 0.002, zFront + 0.0015), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
            }}
            // Door: stainless frame around a tinted glass pane, gasket, vertical bar handle.
            let dLo = kick + 0.004, dHi = stripLo - 0.004
            let dh = dHi - dLo, dcy = (dLo + dHi) / 2
            let fr: Float = 0.03
            add(rb(V3(W - 0.01, fr, doorT), V3(0, dHi - fr / 2, zFront - doorT / 2), "metal.stainless", r: 0.005))
            add(rb(V3(W - 0.01, fr, doorT), V3(0, dLo + fr / 2, zFront - doorT / 2), "metal.stainless", r: 0.005))
            for sx: Float in [-1, 1] { add(rb(V3(fr, dh - 2 * fr + 0.004, doorT), V3(sx * (W / 2 - 0.005 - fr / 2), dcy, zFront - doorT / 2), "metal.stainless", r: 0.004)) }
            add(rb(V3(W - 0.01 - 2 * fr + 0.004, dh - 2 * fr + 0.004, 0.006), V3(0, dcy, zFront - 0.012), "glass.tinted", r: 0.001))
            add(rb(V3(W - 0.01 - 2 * fr + 0.004, 0.008, 0.01), V3(0, dHi - fr - 0.002, zDoorBack + 0.005), "rubber.silicone-gray", r: 0.001))
            add(rb(V3(W - 0.01 - 2 * fr + 0.004, 0.008, 0.01), V3(0, dLo + fr + 0.002, zDoorBack + 0.005), "rubber.silicone-gray", r: 0.001))
            let hx = -(W / 2 - 0.005 - fr / 2) + 0.0
            let hx2 = W / 2 - 0.005 - fr / 2
            _ = hx
            let hl: Float = 0.5
            m.add(Prim.cylinder(radius: 0.0115, height: hl, bevel: 0.004, segments: 14, bevelSegments: 1, material: "metal.stainless"), Xform(translation: V3(hx2 - 0.005, dcy - hl / 2, zFront + 0.0235)))
            for hy: Float in [-0.2, 0.2] {
                m.add(Prim.cylinder(radius: 0.008, height: 0.0235, bevel: 0.002, segments: hi ? 12 : 6, bevelSegments: 1, material: "metal.stainless"),
                      Xform(translation: V3(hx2 - 0.005, dcy + hy, zFront), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
            }
            groundAO(&m, height: 0.12, floor: 0.65)
            return m
        }
        return LODModel(levels: [level(true), level(false)], switchDistances: [4])
    }
}
