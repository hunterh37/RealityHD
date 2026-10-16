import simd
import Foundation

/// Trail camera, 13.5 x 9.5 x 6.5 cm: camo polymer body with latch and gasket, dark front plate with a glass lens,
/// frosted PIR window, two 12-LED infrared arrays and a status LED, back strap slots with a nylon strap and buckle,
/// python-lock lug, tripod socket on the base.
public struct TrailCamera: RealAsset {
    public static let id = "trail-camera"
    public static let summary = "Trail camera, 13.5 x 9.5 cm: camo body, glass lens, PIR window, IR LED arrays, latch, gasket, strap slots and buckle."
    public static let tags = ["prop", "hunting", "outdoor", "plastic"]
    public static let budget = 11_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 12, distance: 1.1)

    /// Body width, height and depth in meters.
    public var size = V3(0.135, 0.095, 0.065)
    /// Body color (sRGB hex); camo leaves are tinted from it.
    public var bodyColor: UInt32 = 0x59613F
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = size.x, H = size.y, D = size.z
        let body = "plastic.trailcam:" + HuntCampKit.hex(bodyColor)
        let cy = H / 2
        // Housing: two shells with a gasket between them.
        m.add(Prim.roundedBox(V3(W, H, D * 0.56), radius: 0.009, bevelSegments: 3, material: body), Xform(translation: V3(0, cy, -D * 0.22)))
        m.add(Prim.roundedBox(V3(W - 0.002, H - 0.002, D * 0.44), radius: 0.009, bevelSegments: 3, material: body), Xform(translation: V3(0, cy, D * 0.28)))
        m.add(Prim.roundedBox(V3(W + 0.0015, H + 0.0015, 0.004), radius: 0.0045, bevelSegments: 1, material: "rubber.silicone"), Xform(translation: V3(0, cy, D * 0.055)))
        // Camo: leaves on the sides, top and lower back, three tints.
        let tints = ["plastic.trailcam:2E3524", "plastic.trailcam:7E7250", "plastic.trailcam:454C32", "plastic.trailcam:3A2E22"]
        for i in 0..<32 {
            let l = rng.float(0.014...0.03), w = l * rng.float(0.35...0.55)
            let leaf = Prim.extrude(HuntCampKit.leaf(l, w), depth: 0.0012, bevel: 0.0003, bevelSegments: 1, material: tints[i % tints.count])
            let rz = rng.float(0...360)
            switch i % 3 {
            case 0:   // top face, normal +Y
                m.add(leaf, Xform(translation: V3(rng.float(-W / 2 + 0.012...W / 2 - 0.012), H + 0.0004, rng.float(-D / 2 + 0.01...D / 2 - 0.01)),
                                  rotation: simd_quatf(degrees: -90, axis: V3(1, 0, 0)) * simd_quatf(degrees: rz, axis: V3(0, 0, 1))))
            case 1:   // sides, normal +-X
                let s: Float = rng.chance(0.5) ? 1 : -1
                m.add(leaf, Xform(translation: V3(s * (W / 2 + 0.0004), rng.float(0.015...H - 0.015), rng.float(-D / 2 + 0.012...D / 2 - 0.012)),
                                  rotation: simd_quatf(degrees: 90 * s, axis: V3(0, 1, 0)) * simd_quatf(degrees: rz, axis: V3(0, 0, 1))))
            default:  // back face, normal -Z
                m.add(leaf, Xform(translation: V3(rng.float(-W / 2 + 0.012...W / 2 - 0.012), rng.float(0.015...H - 0.015), -D / 2 - 0.0004 + 0.0012 * 0),
                                  rotation: simd_quatf(degrees: 180, axis: V3(0, 1, 0)) * simd_quatf(degrees: rz, axis: V3(0, 0, 1))))
            }
        }
        // Front plate, fascia ring and glass lens.
        let fz = D / 2
        m.add(Prim.roundedBox(V3(W - 0.018, H - 0.016, 0.004), radius: 0.004, bevelSegments: 2, material: "plastic.trailcam:25271F"), Xform(translation: V3(0, cy - 0.002, fz + 0.0005)))
        let lensC = V3(0, cy - 0.003, fz + 0.002)
        m.add(turned([(0.0, 0.0), (0.0205, 0.0), (0.0205, 0.004), (0.0175, 0.0065), (0.0175, 0.0), (0, 0)], segments: 28, material: "plastic.black"),
              Xform(translation: lensC, rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        m.add(turned([(0.0, 0.0), (0.0172, 0.0), (0.0172, 0.0015), (0.0145, 0.0042), (0.0095, 0.0062), (0.0, 0.0068)], segments: 28, material: "glass.curtain"),
              Xform(translation: lensC + V3(0, 0, 0.0026), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        m.add(turned([(0.0, 0.0), (0.0085, 0.0), (0.0085, 0.0008), (0.004, 0.0016), (0, 0.0018)], segments: 16, material: "plastic.black"),
              Xform(translation: lensC + V3(0, 0, 0.0074), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        // PIR window above the lens, a status LED beside it.
        m.add(Prim.superellipsoid(V3(0.036, 0.016, 0.009), exponent: 4, subdivisions: 10, material: "plastic.trailcam:B4B1A2"), Xform(translation: V3(0, cy + 0.034, fz + 0.0022)))
        m.add(Prim.roundedBox(V3(0.04, 0.019, 0.002), radius: 0.003, bevelSegments: 1, material: "plastic.black"), Xform(translation: V3(0, cy + 0.034, fz + 0.0006)))
        m.add(turned([(0, 0), (0.0016, 0), (0.0016, 0.0012), (0, 0.0018)], segments: 10, material: "emissive.led-green"),
              Xform(translation: V3(0.036, cy + 0.034, fz + 0.002), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        // IR LED arrays: 2 x 6 on each side of the lens, each in a dark reflector.
        for s: Float in [-1, 1] {
            m.add(Prim.roundedBox(V3(0.028, 0.044, 0.002), radius: 0.003, bevelSegments: 1, material: "plastic.black"), Xform(translation: V3(s * 0.045, cy - 0.003, fz + 0.0022)))
            for r in 0..<6 {
                for c in 0..<2 {
                    let p = V3(s * 0.045 + (Float(c) - 0.5) * 0.0105, cy - 0.003 + (Float(r) - 2.5) * 0.0068, fz + 0.0032)
                    m.add(turned([(0, 0), (0.0026, 0), (0.0026, 0.0008), (0.0018, 0.0014), (0, 0.0015)], segments: 10, material: "plastic.trailcam:3A1212"),
                          Xform(translation: p, rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
                }
            }
        }
        // Latch on the right side: base block, hasp and pull tab. Hinge barrel on the left.
        m.add(Prim.roundedBox(V3(0.007, 0.034, 0.016), radius: 0.002, bevelSegments: 1, material: "plastic.black"), Xform(translation: V3(W / 2 + 0.003, cy, -0.002)))
        m.add(Prim.roundedBox(V3(0.004, 0.02, 0.012), radius: 0.0015, bevelSegments: 1, material: "plastic.black"), Xform(translation: V3(W / 2 + 0.008, cy, 0.004)))
        HuntCampKit.rod(&m, V3(-W / 2 - 0.002, cy - 0.03, 0.0), V3(-W / 2 - 0.002, cy + 0.03, 0.0), r: 0.004, sides: 8, mat: "plastic.black")
        // Python lock lug and tripod socket on the base, strap slots on the back.
        m.add(Prim.torus(major: 0.006, minor: 0.0016, segments: 14, sides: 6, material: "metal.screw-zinc"), Xform(translation: V3(0.04, -0.0005, -0.01)))
        m.add(turned([(0.0, 0.0), (0.0085, 0.0), (0.0085, 0.0015), (0.0, 0.0015)], segments: 14, material: "metal.screw-zinc"),
              Xform(translation: V3(-0.03, -0.0004, 0.0), rotation: simd_quatf(degrees: 180, axis: V3(1, 0, 0))))
        for y in [cy + 0.028, cy - 0.028] as [Float] {
            m.add(Prim.roundedBox(V3(0.082, 0.012, 0.003), radius: 0.0012, bevelSegments: 2, material: "plastic.black"), Xform(translation: V3(0, y, -D / 2 - 0.0008)))
        }
        // Strap through both slots, tails with a buckle on the right.
        for (i, y) in [cy + 0.028, cy - 0.028].enumerated() {
            let z0 = -D / 2 - 0.0034
            let path = catmull([V3(-0.052, y, z0), V3(0.0, y, z0 - 0.0015), V3(0.055, y, z0)], per: 4)
            m.add(Prim.sweep(Shape2D.rect(0.025, 0.0035), along: path, up: V3(0, 1, 0), material: "fabric.webbing:3A3F2C"))
        }
        // Plate screws at the four corners, microphone pinhole, and a dust-and-mud splash along the lower edge.
        for sx: Float in [-1, 1] { for sy: Float in [-1, 1] {
            m.add(turned([(0, 0), (0.0021, 0), (0.0021, 0.0010), (0.0014, 0.0014), (0, 0.0018)], segments: 10, material: "metal.screw-zinc"),
                  Xform(translation: V3(sx * (W / 2 - 0.0135), cy - 0.002 + sy * (H / 2 - 0.0135), fz + 0.0025), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        } }
        m.add(turned([(0, 0), (0.0012, 0), (0.0012, 0.0008), (0, 0.0008)], segments: 8, material: "plastic.black"),
              Xform(translation: V3(-0.02, cy + 0.03, fz + 0.0025), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        var mr = rng.fork(77)
        for i in 0..<10 {
            let sz = V3(mr.float(0.008...0.02), mr.float(0.004...0.009), mr.float(0.0008...0.0016))
            let x = mr.float(-W / 2 + 0.01...W / 2 - 0.01), y = mr.float(0.006...0.034)
            m.add(Prim.superellipsoid(sz, exponent: 2.4, subdivisions: 3, material: i % 3 == 0 ? "ground.dirt" : "plastic.trailcam:3E3426"),
                  Xform(translation: V3(x, y, fz + 0.0006 + (i % 2 == 0 ? 0 : 0)), rotation: simd_quatf(degrees: mr.float(-25...25), axis: V3(0, 0, 1))))
        }
        // Label strip on the back.
        m.add(Prim.roundedBox(V3(0.03, 0.012, 0.0006), radius: 0.001, bevelSegments: 1, material: "plastic.trailcam:A9A596"), Xform(translation: V3(-0.032, cy - 0.01, -D / 2 - 0.0007)))
        groundAO(&m, height: 0.02, floor: 0.9)
        return LODModel(m)
    }
}
