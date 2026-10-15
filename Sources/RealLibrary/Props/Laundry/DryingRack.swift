import simd
import Foundation

/// Folding drying rack: White powder-coated steel tube, scuffed at the feet and clip joints.. Parts: two tubular A-frame end frames with floor bars, eight fixed rails across the body, front and back wings folded up on hinge clips, wing rails and side bars, plastic hinge clips and end caps, rubber feet, a few clothespins on the lower rail.
public struct DryingRack: RealAsset {
    public static let id = "drying-rack"
    public static let summary = "Folding wing drying rack: white tubular A-frame with eight rails, two wings folded up on clips, rubber feet and clothespins."
    public static let tags = ["prop", "floorplan", "laundry", "metal", "interior"]
    public static let budget = 6500
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(0.7, 1.0, 0.55)
    /// Wing angle above horizontal in degrees.
    public var wingAngle: Float = 55
    /// Tube radius in meters.
    public var tubeRadius: Float = 0.0055
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [make(seed: seed, lite: false), make(seed: seed, lite: true)], switchDistances: [4])
    }

    private func make(seed: UInt64, lite: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let steel: MaterialKey = "metal.enamel:EFEFEA"
        let clip: MaterialKey = "plastic.matte:3A3D42"
        let r = tubeRadius
        let sides = lite ? 6 : 8
        func tube(_ a: V3, _ b: V3, _ mat: MaterialKey = "metal.enamel:EFEFEA", radius: Float? = nil) {
            let rr = radius ?? r
            m.add(Prim.tube([a, b], radii: [rr, rr], sides: sides, seamTile: 0.05, material: mat, capEnd: true))
        }
        func capBox(_ s: V3, _ mat: MaterialKey, at: V3, rot: simd_quatf = .identity) {
            m.add(Prim.roundedBox(s, radius: 0.0025, bevelSegments: 1, material: mat), Xform(translation: at, rotation: rot))
        }
        let xe: Float = 0.34                     // end frame x
        let zFoot: Float = 0.265, zTop: Float = 0.09
        let yTop: Float = 0.76, yFoot: Float = 0.02
        func zLeg(_ y: Float) -> Float { zFoot + (zTop - zFoot) * (y - yFoot) / (yTop - yFoot) }
        // End frames: legs, top bar, floor bar, mid brace.
        for sx in [Float(-1), 1] {
            let x = sx * xe
            for sz in [Float(-1), 1] {
                tube(V3(x, yFoot, sz * zFoot), V3(x, yTop, sz * zTop), radius: r * 1.1)
            }
            tube(V3(x, yTop, -zTop), V3(x, yTop, zTop), radius: r * 1.1)
            tube(V3(x, yFoot, -zFoot), V3(x, yFoot, zFoot))
            tube(V3(x, 0.4, -zLeg(0.4)), V3(x, 0.4, zLeg(0.4)))
            // Rubber feet and caps.
            for sz in [Float(-1), 1] {
                m.add(Prim.cylinder(radius: 0.0105, height: 0.022, bevel: 0.002, segments: lite ? 8 : 12, bevelSegments: 1, material: "rubber.tire"), Xform(translation: V3(x, 0, sz * zFoot)))
            }
        }
        // Fixed rails across the body on both sides of the A.
        for y in [Float(0.16), 0.36, 0.56, yTop] {
            for sz in [Float(-1), 1] {
                tube(V3(-xe, y, sz * zLeg(y)), V3(xe, y, sz * zLeg(y)))
                if !lite { for sx in [Float(-1), 1] { capBox(V3(0.012, 0.016, 0.016), clip, at: V3(sx * xe, y, sz * zLeg(y))) } }
            }
        }
        // Wings: tilted rectangular frames hinged on the top rails.
        let a = wingAngle * .pi / 180
        let L: Float = 0.27
        for sz in [Float(-1), 1] {
            let hinge = V3(0, yTop, sz * zTop)
            let dir = V3(0, sin(a), sz * cos(a))
            let xw: Float = 0.30
            for sx in [Float(-1), 1] { tube(hinge + V3(sx * xw, 0, 0), hinge + dir * L + V3(sx * xw, 0, 0)) }
            for sIdx in 1...3 {
                let t = L * Float(sIdx) / 3
                tube(hinge + dir * t + V3(-xw, 0, 0), hinge + dir * t + V3(xw, 0, 0))
            }
            // Hinge clips: plastic sleeves where the wing side bars meet the top rail.
            for sx in [Float(-1), 1] {
                capBox(V3(0.02, 0.022, 0.026), clip, at: hinge + V3(sx * xw, 0.003, sz * 0.002))
                if !lite { capBox(V3(0.012, 0.016, 0.016), clip, at: hinge + dir * L + V3(sx * xw, 0, 0)) }
            }
        }
        // Pivot rivets on the end frames and the lower rail pins.
        if !lite {
            for sx in [Float(-1), 1] { for sz in [Float(-1), 1] {
                m.add(Prim.cylinder(radius: 0.0065, height: 0.003, bevel: 0.0008, segments: 10, bevelSegments: 1, material: "metal.screw-zinc"),
                      Xform(translation: V3(sx * (xe + r * 1.1), 0.4, sz * zLeg(0.4)), rotation: simd_quatf(from: V3(0, 1, 0), to: V3(sx, 0, 0))))
            } }
            // Clothespins on the lower rails: two legs and a spring each.
            let pinColors: [MaterialKey] = ["plastic.orange", "plastic.white", "plastic.orange", "plastic.white"]
            for k in 0..<4 {
                let x = -0.2 + Float(k) * 0.11 + rng.float(-0.01...0.01)
                let y: Float = 0.36, z = zLeg(y) + 0.0
                let tilt = simd_quatf(degrees: rng.float(-8...8), axis: V3(0, 0, 1))
                for dz in [Float(0.0035), -0.0035] {
                    capBox(V3(0.006, 0.048, 0.003), pinColors[k], at: V3(x, y - 0.008, z + dz), rot: tilt)
                }
                capBox(V3(0.007, 0.01, 0.012), "metal.screw-zinc", at: V3(x, y + 0.013, z), rot: tilt)
            }
        }
        // A hand towel draped over the front rail at y = 0.56 (story detail).
        do {
            let y: Float = 0.56, z = zLeg(y), cx: Float = 0.1
            let towel: MaterialKey = "fabric.canvas:6F93A8"
            let tilt: Float = 0.23   // legs lean in by about this slope
            m.add(Prim.cylinder(radius: r + 0.0035, height: 0.3, bevel: 0.003, segments: lite ? 8 : 12, bevelSegments: 1, material: towel),
                  Xform(translation: V3(cx - 0.15, y, z), rotation: simd_quatf(from: V3(0, 1, 0), to: V3(1, 0, 0))))
            m.add(Prim.roundedBox(V3(0.3, 0.2, 0.003), radius: 0.0012, bevelSegments: 1, material: towel),
                  Xform(translation: V3(cx, y - 0.1, z + r + 0.0035 + 0.0015 + tilt * 0.1), rotation: simd_quatf(angle: -atan(tilt), axis: V3(1, 0, 0))))
            m.add(Prim.roundedBox(V3(0.3, 0.14, 0.003), radius: 0.0012, bevelSegments: 1, material: towel),
                  Xform(translation: V3(cx, y - 0.07, z - r - 0.0035 - 0.0015 + tilt * 0.07), rotation: simd_quatf(angle: -atan(tilt), axis: V3(1, 0, 0))))
        }
        _ = rng.float()
        groundAO(&m, height: 0.12, floor: 0.7)
        return m
    }
}
