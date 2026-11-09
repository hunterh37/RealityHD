import simd
import Foundation

/// Over-ear wireless headphones worn on an average adult head, origin at head centre (ear height): anodised
/// gunmetal headband arching over the crown with a stitched leatherette pad, notched aluminium extension
/// sliders, forked yokes with pivot pins, soft-touch graphite ear cups with brushed aluminium face plates,
/// oval protein-leather ear cushions with mesh baffles, USB-C port, mic ports, power button and LED.
public struct WirelessHeadphonesWorn: RealAsset {
    public static let id = "wireless-headphones-worn"
    public static let summary = "Worn over-ear wireless headphones: gunmetal band, stitched pad, notched sliders, graphite cups, leatherette cushions."
    public static let tags = ["prop", "wearable", "worn", "headwear", "electronics", "metal", "leather"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 38, elevation: 12, distance: 0.8, ground: false, studio: true)

    /// Headband and yoke metal.
    public var frame: MaterialKey = "metal.anodized-gunmetal"
    /// Extension sliders and face plates.
    public var alu: MaterialKey = "metal.aluminum-brushed"
    /// Cup shells.
    public var shell: MaterialKey = "plastic.matte:2A2B2E"
    /// Pad and cushion leatherette.
    public var pad: MaterialKey = "plastic.soft-touch:202124"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var m = Model(name: Self.id)
        let zc: Float = -0.012, cy: Float = -0.008
        let cx: Float = 0.1115, cyBand: Float = 0.02, ry: Float = 0.112
        func bandPt(_ t: Float, _ k: Float = 1) -> V3 { V3(cx * k * cos(t), cyBand + ry * k * sin(t), zc) }
        func bandN(_ t: Float) -> V3 { simd_normalize(V3(cos(t) / cx, sin(t) / ry, 0)) }
        let t0: Float = 16.6 * .pi / 180
        // Headband: gunmetal strip over the crown, ear to ear.
        let n = 40
        let ts = (0...n).map { t0 + (Float.pi - 2 * t0) * Float($0) / Float(n) }
        m.add(Prim.sweep(Shape2D.roundedRect(0.024, 0.0036, radius: 0.0016, segments: 2), along: ts.map { bandPt($0) }, up: V3(0, 0, 1), material: frame))
        // Headband pad: tapered stitched leatherette under the crown.
        let pts = (0...36).map { 40 * Float.pi / 180 + (100 * Float.pi / 180) * Float($0) / 36 }
        let padPath = pts.map { bandPt($0, 0.905) }
        let sc = (0...36).map { i -> Float in let u = Float(i) / 36; return 0.6 + 0.4 * pow(sin(u * .pi), 0.45) }
        m.add(Prim.sweep(Shape2D.superellipse(0.036, 0.014, exponent: 3, segments: 20), along: padPath, up: V3(0, 0, 1), scales: sc, material: pad))
        var detail = Model(name: "stitching")
        for dz: Float in [-0.0125, 0.0125] {
            let path = pts.indices.map { i -> V3 in
                let t = pts[i], p = padPath[i], nn = bandN(t)
                return V3(p.x - nn.x * 0.0060 * sc[i], p.y - nn.y * 0.0060 * sc[i], zc + dz * sc[i])
            }
            detail.add(stitches(along: path, normal: { _ in V3(0, -1, 0) }, pitch: 0.0045, thread: 0.0006, material: "fabric.canvas:8A8A8E"))
        }
        for sx: Float in [-1, 1] {
            func side(_ t: Float, _ k: Float = 1) -> V3 { let p = bandPt(t, k); return V3(sx * p.x, p.y, p.z) }
            // Extension slider sleeve with notch ticks.
            let sl = (0...10).map { t0 + (24 * Float.pi / 180) * Float($0) / 10 }
            m.add(Prim.sweep(Shape2D.roundedRect(0.027, 0.0054, radius: 0.0022, segments: 3), along: sl.map { side($0) }, up: V3(0, 0, 1), material: alu))
            for k in 0..<5 {
                let t = t0 + (4 + 4.4 * Float(k)) * .pi / 180
                let nn = bandN(t), nx = V3(sx * nn.x, nn.y, 0)
                let rotZ = sx > 0 ? t + .pi / 2 : .pi - t - .pi / 2
                m.add(Prim.roundedBox(V3(0.0012, 0.0009, 0.0125), radius: 0.0003, bevelSegments: 1, material: "metal.anodized-black"),
                      Xform(translation: side(t) + nx * 0.0028, rotation: simd_quatf(angle: rotZ, axis: V3(0, 0, 1))))
            }
        }
        // Cups, yokes, cushions.
        let x0: Float = 0.092, depth: Float = 0.030
        let table: [(Float, Float)] = [(0, 0.078), (0.003, 0.083), (0.007, 0.0865), (0.012, 0.087), (0.018, 0.0855), (0.023, 0.0805), (0.027, 0.0735), (0.0295, 0.0665), (0.030, 0.064)]
        let rings = table.map { a, v in Prim.ring(Shape2D.superellipse(v * 0.765, v, exponent: 2.6, segments: 48), y: a) }
        for sx: Float in [-1, 1] {
            let rot = simd_quatf(degrees: -sx * 90, axis: V3(0, 0, 1))
            // Cup shell, rotated so the cushion plane faces the head.
            m.add(Prim.loft(rings, capEnd: true, material: shell), Xform(translation: V3(sx * x0, cy, zc), rotation: rot))
            // Face plate: gunmetal bezel and brushed aluminium disc.
            let yRot = simd_quatf(degrees: 90, axis: .up)
            m.add(Prim.extrude(Shape2D.superellipse(0.050, 0.064, exponent: 2.4, segments: 40), depth: 0.0016, bevel: 0.0005, bevelSegments: 2, material: frame),
                  Xform(translation: V3(sx * (x0 + depth - 0.0004), cy, zc), rotation: yRot))
            m.add(Prim.extrude(Shape2D.superellipse(0.040, 0.054, exponent: 2.4, segments: 40), depth: 0.0034, bevel: 0.0009, bevelSegments: 2, material: alu),
                  Xform(translation: V3(sx * (x0 + depth + 0.0003), cy, zc), rotation: yRot))
            // Cushion: oval ring of protein leather plus a mesh baffle in the ear opening.
            let oval = (0..<48).map { k -> V3 in
                let a = Float(k) / 48 * 2 * .pi
                return V3(sx * 0.0865, cy + 0.0325 * cos(a), zc + 0.022 * sin(a))
            }
            m.add(Prim.sweep(Shape2D.superellipse(0.022, 0.017, exponent: 2.4, segments: 12), along: oval, up: V3(1, 0, 0), closedPath: true, caps: false, material: pad))
            m.add(Prim.extrude(Shape2D.superellipse(0.034, 0.054, exponent: 2.2, segments: 32), depth: 0.0016, bevel: 0.0004, bevelSegments: 1, material: "fabric.mesh:0E0E10"),
                  Xform(translation: V3(sx * 0.0925, cy, zc), rotation: yRot))
            detail.add(stitches(along: oval.indices.map { i -> V3 in let a = Float(i) / 48 * 2 * .pi; return V3(sx * 0.0752, cy + 0.0325 * cos(a), zc + 0.022 * sin(a)) } + [V3(sx * 0.0752, cy + 0.0325, zc)],
                                normal: { _ in V3(sx, 0, 0) }, pitch: 0.0045, thread: 0.0005, material: "fabric.canvas:5A5A5E"))
            // Yoke: forked arm around the cup from the slider end, with pivot pins into the cup sides.
            let xy = sx * 0.1068
            let arc = (0...20).map { i -> V3 in
                let f = (-8 + 196 * Float(i) / 20) * .pi / 180
                return V3(xy, cy + 0.060 * sin(f), zc + 0.0405 * cos(f))
            }
            m.add(Prim.sweep(Shape2D.roundedRect(0.0042, 0.009, radius: 0.0018, segments: 2), along: arc, up: V3(1, 0, 0), material: frame))
            for e in [arc[0], arc[20]] {
                let front = e.z > zc
                m.add(Prim.cylinder(radius: 0.0046, height: 0.011, bevel: 0.001, segments: 20, bevelSegments: 2, material: alu),
                      Xform(translation: V3(xy, e.y, e.z + (front ? 0.003 : -0.003)), rotation: simd_quatf(degrees: front ? -90 : 90, axis: V3(1, 0, 0))))
            }
        }
        // Left cup: USB-C port and two mic ports on the lower rim. Right cup: power button and status LED.
        let rimY = cy - 0.0435, rimX: Float = x0 + 0.014
        let down = simd_quatf(degrees: 90, axis: V3(1, 0, 0))
        m.add(Prim.extrude(Shape2D.roundedRect(0.0105, 0.0042, radius: 0.0019, segments: 3), depth: 0.0012, bevel: 0.0003, bevelSegments: 1, material: alu),
              Xform(translation: V3(rimX, rimY + 0.0003, zc), rotation: down))
        m.add(Prim.extrude(Shape2D.roundedRect(0.0082, 0.0026, radius: 0.0012, segments: 3), depth: 0.0014, bevel: 0.0001, bevelSegments: 1, material: "plastic.black"),
              Xform(translation: V3(rimX, rimY + 0.0001, zc), rotation: down))
        for dz: Float in [0.012, 0.018] {
            m.add(Prim.cylinder(radius: 0.0008, height: 0.0008, bevel: 0.0002, segments: 10, bevelSegments: 1, material: "plastic.black"),
                  Xform(translation: V3(rimX - 0.008, rimY + 0.0004, zc + dz), rotation: simd_quatf(degrees: 180, axis: V3(1, 0, 0))))
        }
        m.add(Prim.roundedBox(V3(0.0035, 0.0038, 0.011), radius: 0.0012, bevelSegments: 2, material: "plastic.matte:3A3B3F"),
              Xform(translation: V3(-rimX, rimY - 0.0006, zc - 0.002)))
        m.add(Prim.cylinder(radius: 0.00085, height: 0.0008, bevel: 0.0002, segments: 10, bevelSegments: 1, material: "emissive.led-green"),
              Xform(translation: V3(-rimX, rimY + 0.0003, zc + 0.012), rotation: simd_quatf(degrees: 180, axis: V3(1, 0, 0))))
        var full = m
        full.add(detail)
        return LODModel(levels: [full, m], switchDistances: [4])
    }
}
