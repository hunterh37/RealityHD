import simd
import Foundation

/// Digital alarm clock, 15 x 8 x 7 cm: wedge body with a tilted tinted display window, red seven-segment
/// time (7:30) with a colon, a wide snooze bar on the sloped top, three small set buttons and rubber feet.
public struct AlarmClock: RealAsset {
    public static let id = "alarm-clock"
    public static let summary = "Bedside digital alarm clock: wedge body, red LED time digits, snooze bar."
    public static let tags = ["prop", "floorplan", "bedroom", "electronics", "plastic", "interior", "handheld"]
    public static let budget = 2500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 22, distance: 1.15, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.15, 0.08, 0.07)
    /// Height of the rubber feet (m).
    public var footHeight: Float = 0.003
    /// Housing plastic.
    public var housing: MaterialKey = "plastic.matte:2A2A2C"
    /// Display window.
    public var window: MaterialKey = "screen.off"
    /// Lit segments.
    public var led: MaterialKey = "emissive.led-red"
    /// Buttons and feet.
    public var rubber: MaterialKey = "rubber.silicone:2A2A2A"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = size.x, D = size.z, h0 = footHeight
        let zf = D / 2 - 0.002, zb = -D / 2
        // Side profile (x = -z so the extrusion rotated about Y faces +Z), wedge with a tilted front and sloped top.
        let pts: [(Float, Float)] = [
            (zb, h0), (zf, h0), (zf, h0 + 0.012), (zf - 0.007, h0 + 0.058), (zb, size.y - 0.0),
        ]
        var outline = pts.map { V2(-$0.0, $0.1) }
        outline = Shape2D.rounded(outline, radius: 0.006)
        let body = Prim.extrude(outline, depth: W, bevel: 0.0025, bevelSegments: 1, material: housing)
        m.add(body, Xform(rotation: simd_quatf(degrees: 90, axis: V3(0, 1, 0))))

        // Front face frame: line from (zf, h0+0.012) to (zf-0.007, h0+0.058).
        let fy0 = h0 + 0.012, fy1 = h0 + 0.058
        let tilt = atan2(0.007, fy1 - fy0)           // lean of the front face back from vertical
        let faceMid = V3(0, (fy0 + fy1) / 2, zf - 0.0035)
        let faceTilt = simd_quatf(angle: -tilt, axis: V3(1, 0, 0))
        // Glossy bezel around the window.
        m.add(Prim.roundedBox(V3(W - 0.022, 0.042, 0.0016), radius: 0.0016, bevelSegments: 1, material: "plastic.gloss:151517"),
              Xform(translation: faceMid + faceTilt.act(V3(0, 0.002, 0.0006)), rotation: faceTilt))
        // Window: dark glass slab, slightly proud of the face.
        let wW: Float = W - 0.03, wH: Float = 0.034
        let wy: Float = 0.002
        let off = faceTilt.act(V3(0, wy, 0.0013))
        m.add(Prim.roundedBox(V3(wW, wH, 0.0026), radius: 0.0012, bevelSegments: 1, material: window),
              Xform(translation: faceMid + off, rotation: faceTilt))
        // Black backing plate behind the glass so the digits read as lit on black.
        m.add(Prim.roundedBox(V3(wW - 0.002, wH - 0.002, 0.0016), radius: 0.001, bevelSegments: 1, material: "plastic.black"),
              Xform(translation: faceMid + faceTilt.act(V3(0, wy, 0.0001)), rotation: faceTilt))
        // Seven-segment digits "7:30" in the face frame.
        let seg: [[Int]] = [[0, 1, 2], [0, 1, 6, 4, 3], [0, 1, 2, 3, 4, 5], [0, 1, 2, 3, 4, 5]] // placeholder replaced below
        _ = seg
        // a b c d e f g = top, upper-right, lower-right, bottom, lower-left, upper-left, middle
        let digits: [[Bool]] = [
            [true, true, true, false, false, false, false],   // 7
            [true, true, true, true, false, false, true],     // 3
            [true, true, true, true, true, true, false],      // 0
        ]
        let dw: Float = 0.016, dh: Float = 0.026, t: Float = 0.0030
        let pitch: Float = 0.0255
        // Layout: d1 [colon] d2 d3 d4 where d4 = 0 as well: "7:300"? use 4 digits: 0 7 : 3 0 -> "07:30".
        let seq: [[Bool]?] = [digits[2], digits[0], nil, digits[1], digits[2]]
        var xs: [Float] = [-0.0475, -0.0245, 0, 0.0245, 0.0475]
        xs = xs.map { $0 }
        _ = pitch
        for (i, d) in seq.enumerated() {
            let cx = xs[i]
            if let d {
                func segBox(_ k: Int) -> (V2, V2) {
                    let hw = dw / 2, hh = dh / 2
                    switch k {
                    case 0: return (V2(0, hh), V2(dw - t, t))
                    case 1: return (V2(hw, hh / 2), V2(t, dh / 2 - t * 0.6))
                    case 2: return (V2(hw, -hh / 2), V2(t, dh / 2 - t * 0.6))
                    case 3: return (V2(0, -hh), V2(dw - t, t))
                    case 4: return (V2(-hw, -hh / 2), V2(t, dh / 2 - t * 0.6))
                    case 5: return (V2(-hw, hh / 2), V2(t, dh / 2 - t * 0.6))
                    default: return (V2(0, 0), V2(dw - t, t))
                    }
                }
                for k in 0..<7 where d[k] {
                    let (c, s) = segBox(k)
                    let p = faceMid + faceTilt.act(V3(cx + c.x, wy + c.y, 0.0033))
                    m.add(cuboid(V3(s.x, s.y, 0.0012), material: led),
                          Xform(translation: p, rotation: faceTilt))
                }
            } else {
                for dy: Float in [-0.0065, 0.0065] {
                    let p = faceMid + faceTilt.act(V3(cx, wy + dy, 0.0033))
                    m.add(cuboid(V3(0.0032, 0.0032, 0.0012), material: led),
                          Xform(translation: p, rotation: faceTilt))
                }
            }
        }
        // Small status LED (alarm on) under the glass, right.
        // Alarm-on indicator: small green dot on the lower bezel strip.
        m.add(cuboid(V3(0.0024, 0.0024, 0.0010), material: "emissive.led-green"),
              Xform(translation: faceMid + faceTilt.act(V3(0.052, wy - 0.0205, 0.0014)), rotation: faceTilt))
        // Back: speaker slots and a battery door, proud by 0.3 mm.
        for k in 0..<6 {
            m.add(cuboid(V3(0.032, 0.0016, 0.0010), material: "plastic.black"),
                  Xform(translation: V3(-0.040, 0.052 - Float(k) * 0.0045, zb + 0.0005)))
        }
        m.add(Prim.roundedBox(V3(0.040, 0.028, 0.0010), radius: 0.0012, bevelSegments: 1, material: housing),
              Xform(translation: V3(0.038, 0.040, zb + 0.0005)))
        m.add(cuboid(V3(0.012, 0.0016, 0.0010), material: "plastic.black"), Xform(translation: V3(0.038, 0.034, zb + 0.0003)))
        // Front lower edge: a small brand-style slot mark under the window.

        // Top slope: from (zf-0.007, h0+0.058) to (zb, size.y).
        let top0 = V3(0, h0 + 0.058, zf - 0.007), top1 = V3(0, size.y, zb)
        let dir = top1 - top0
        let slope = atan2(dir.y, -dir.z)              // rise toward the back
        let topQ = simd_quatf(angle: slope, axis: V3(1, 0, 0)) // tips +Z edge up? rotate so local +Y follows the surface normal
        func onTop(_ f: Float, _ y: Float) -> V3 { top0 + dir * f + V3(0, 0, 0) + topQ.act(V3(0, y, 0)) }
        // Snooze bar: wide, rounded, raised 4 mm from the slope near the front.
        let barLen: Float = 0.108
        m.add(Prim.roundedBox(V3(barLen, 0.0065, 0.026), radius: 0.003, bevelSegments: 1, material: "plastic.matte:55555A"),
              Xform(translation: onTop(0.30, 0.0022), rotation: simd_quatf(angle: -slope, axis: V3(1, 0, 0))))
        // Three small set buttons toward the back of the slope.
        for (i, bx) in ([-0.036, 0.0, 0.036] as [Float]).enumerated() {
            m.add(Prim.roundedBox(V3(0.020, 0.004, 0.010), radius: 0.0018, bevelSegments: 1, material: rubber),
                  Xform(translation: onTop(0.72, 0.001) + V3(bx, 0, 0), rotation: simd_quatf(angle: -slope, axis: V3(1, 0, 0))).jittered(&rng))
            _ = i
        }
        // Rubber feet.
        for fx: Float in [-1, 1] { for fz: Float in [-1, 1] {
            m.add(Prim.cylinder(radius: 0.006, height: h0 + 0.001, bevel: 0.0008, segments: 10, material: rubber),
                  Xform(translation: V3(fx * (W / 2 - 0.014), 0, fz * (D / 2 - 0.012))))
        } }
        let b = m.bounds
        m = m.transformed(Xform(translation: V3(0, -b.min.y, 0)))
        groundAO(&m, height: 0.01, floor: 0.7)
        return LODModel(m)
    }
}
