import simd
import Foundation

/// Shared helpers for the Lunar theme: paraboloid dish skin, mesh wheel, Artemis-style color keys.
enum LunarKit {
    static let white: MaterialKey = "metal.powder-white"
    static let silver: MaterialKey = "metal.aluminum-brushed"
    static let gold: MaterialKey = "insulation.foil-gold"
    static let orange: MaterialKey = "metal.painted:E8641A"
    static let dark: MaterialKey = "plastic.matte:2A2C2E"
    static let toZ = simd_quatf(angle: .pi / 2, axis: V3(1, 0, 0))    // lathe +Y -> +Z

    /// Thin paraboloid shell opening toward +Y (vertex at origin), focal length f, rim radius R.
    static func dish(R: Float, f: Float, thick t: Float, segments: Int, rings: Int, front: MaterialKey, back: MaterialKey) -> [Surface] {
        func y(_ r: Float) -> Float { r * r / (4 * f) }
        var fp: [V2] = [], bp: [V2] = []
        for i in 0...rings { let r = R * Float(i) / Float(rings); fp.append(V2(max(r, 0.0001), y(r))) }
        for i in 0...rings { let r = R * Float(rings - i) / Float(rings); bp.append(V2(max(r, 0.0001), y(r) - t)) }
        let fs = Prim.lathe(fp, segments: segments, seamTile: 0.5, material: front).flipped()
        let bs = Prim.lathe(bp, segments: segments, seamTile: 0.5, material: back).flipped()
        let rim = Prim.lathe([V2(R, y(R)), V2(R + 0.002, y(R) - t / 2), V2(R, y(R) - t)], segments: segments, seamTile: 0.5, material: back)
        return [fs, bs, rim]
    }

    /// Open-mesh rover wheel, axis along X, centre at c.
    static func wheel(_ m: inout Model, at c: V3, radius r: Float, width w: Float, side: Float, grousers: Int, lod: Int) {
        let sg = lod == 0 ? 24 : 12
        let rot = simd_quatf(angle: -.pi / 2, axis: V3(0, 0, 1))
        m.add(Prim.lathe([V2(r * 0.78, -w / 2), V2(r - 0.004, -w / 2 + 0.003), V2(r, -w / 2 + 0.008), V2(r, w / 2 - 0.008), V2(r - 0.004, w / 2 - 0.003), V2(r * 0.78, w / 2)],
                         segments: sg, seamTile: 0.3, material: silver), Xform(translation: c, rotation: rot))
        m.add(Prim.lathe([V2(0.03, side * w / 2), V2(0.05, side * w / 2 - 0.01), V2(r * 0.8, side * (w / 2 - 0.012)), V2(r * 0.8, side * w / 2 - side * 0.016), V2(0.03, side * w / 2 - side * 0.02)],
                         segments: sg, seamTile: 0.3, material: white), Xform(translation: c, rotation: rot))
        m.add(Prim.cylinder(radius: 0.045, height: 0.05, bevel: 0.004, segments: 16, material: orange),
              Xform(translation: c + V3(side * (w / 2 - 0.01), 0, 0), rotation: rot * simd_quatf(angle: side > 0 ? 0 : .pi, axis: V3(1, 0, 0))))
        if lod == 0 {
            for k in 0..<grousers {
                let a = Float(k) / Float(grousers) * 2 * .pi
                let p = c + V3(0, sin(a) * (r + 0.004), cos(a) * (r + 0.004))
                m.add(Prim.roundedBox(V3(w - 0.01, 0.012, 0.012), radius: 0.002, bevelSegments: 0, material: silver),
                      Xform(translation: p, rotation: simd_quatf(angle: -a, axis: V3(1, 0, 0))))
            }
        }
    }
}
