import simd
import Foundation

/// Leaning full-length mirror, 0.6 x 1.7 m and 0.45 m deep where it leans: a walnut frame with a stepped moulding around a beveled silvered
/// pane, plywood back, a folding rear support strut with brass hinge plates, wall bumpers at the top and two walnut feet. Tilted back about
/// 13 degrees. Wall lean: lowest point at y = 0, top of the back edge at z = -depth / 2, front is +Z.
public struct FloorMirror: RealAsset {
    public static let id = "floor-mirror"
    public static let summary = "Leaning full-length mirror, 0.6 x 1.7 m: walnut stepped frame, beveled silvered glass, plywood back with folding strut."
    public static let tags = ["prop", "floorplan", "decor", "wood", "glass", "wall", "interior"]
    public static let budget = 6000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 10, distance: 3.4, studio: true)

    /// Overall size in meters (x width, y height, z depth). Depth is the lean footprint.
    public var size = V3(0.6, 1.7, 0.45)
    /// Frame wood.
    public var wood: MaterialKey = "wood.walnut"
    /// Mirror silvering.
    public var mirror: MaterialKey = "metal.chrome:9AA5A8"
    /// Frame moulding width (m).
    public var frameWidth: Float = 0.05
    /// Frame depth (m).
    public var frameDepth: Float = 0.036
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        func make(_ hi: Bool) -> Model {
            var rng = SeededRNG(seed: seed)
            var m = Model(name: Self.id)
            let W = size.x, fw = frameWidth, t = frameDepth
            // Lean angle so that the panel top lands on the back plane of the footprint.
            let theta = asin((size.z - t - 0.024) / size.y)
            let L = (size.y - t * sin(theta)) / cos(theta)
            var panel = Model(name: "panel")
            // Stepped moulding swept around the panel outline (profile x = depth, y = lateral, positive inward).
            let pw = W - fw, ph = L - fw
            let rect = Shape2D.rounded([V2(0, 0), V2(pw, 0), V2(pw, ph), V2(0, ph)], radius: 0.004, segments: hi ? 4 : 2)
            let path = rect.map { V3($0.x - pw / 2, fw / 2 + $0.y, 0) }
            let hf = fw / 2
            let prof: [V2] = [V2(0, -hf), V2(t - 0.0012, -hf), V2(t, -hf + 0.0015), V2(t, -hf + 0.013), V2(t - 0.0045, -hf + 0.019), V2(t - 0.011, -hf + 0.027),
                              V2(t - 0.0135, hf - 0.012), V2(t - 0.0135, hf - 0.001), V2(0, hf)]
            panel.add(Prim.sweep(prof, along: path, up: V3(0, 0, 1), closedPath: true, caps: false, grainAlongPath: true, material: wood))
            // Backing board, a hair proud of the frame back.
            panel.add(Prim.roundedBox(V3(W - 0.034, L - 0.034, 0.005), radius: 0.0008, bevelSegments: 1, material: "wood.plywood"), Xform(translation: V3(0, L / 2, 0.0019)))
            // Beveled mirror pane tucked behind the frame lip.
            let mw = W - 2 * fw + 0.014, mh = L - 2 * fw + 0.014
            panel.add(Prim.extrude(Shape2D.roundedRect(mw, mh, radius: 0.002, segments: 2), depth: 0.006, bevel: 0.0055, bevelSegments: hi ? 2 : 1, material: mirror),
                      Xform(translation: V3(0, L / 2, 0.0145)))
            // Foxing: small patches of tarnished silvering creeping in from the pane edges (clustered at the corners and the lower edge).
            if hi {
                var fr = rng.fork(5)
                for _ in 0..<26 {
                    let edge = fr.int(0...3)
                    let u = fr.float(0...1), inset = fr.float(0.0085...0.032) * (fr.chance(0.4) ? 1.8 : 1)
                    var x: Float, y: Float
                    switch edge {
                    case 0: x = (u - 0.5) * mw * 0.8; y = -mh / 2 + inset * 0.7 + (fr.chance(0.5) ? 0 : 0.03)
                    case 1: x = (u - 0.5) * mw * 0.8; y = mh / 2 - inset
                    case 2: x = -mw / 2 + inset; y = (u - 0.5) * mh * 0.7
                    default: x = mw / 2 - inset; y = (u - 0.5) * mh * 0.7
                    }
                    let d = fr.float(0.006...0.02)
                    panel.add(Prim.superellipsoid(V3(d * fr.float(0.8...1.5), d, 0.0006), exponent: 2, subdivisions: 1, material: "metal.chrome:4E5658"),
                              Xform(translation: V3(x, L / 2 + y, 0.0145 + 0.003 + 0.0002)))
                }
            }
            // Folded support strut: walnut slat on the back with two brass hinge plates and a rubber stop.
            let strutH: Float = 0.92, strutW: Float = 0.036, strutT: Float = 0.014
            let sz = -0.0006 - strutT / 2 - 0.0004
            panel.add(Prim.roundedBox(V3(strutW, strutH, strutT), radius: 0.0025, bevelSegments: 2, material: wood), Xform(translation: V3(0.04, 0.2 + strutH / 2 + 0.17, sz)))
            for y: Float in [0.2 + 0.17 + strutH - 0.045, 0.2 + 0.17 + strutH - 0.18] {
                panel.add(Prim.roundedBox(V3(0.07, 0.034, 0.002), radius: 0.0007, bevelSegments: 1, material: "metal.brass-aged"),
                          Xform(translation: V3(0.04, y, -0.0006 - strutT - 0.0014)))
                for s: Float in [-1, 1] {
                    for dy: Float in [-0.01, 0.01] {
                        panel.add(Prim.cylinder(radius: 0.0027, height: 0.0016, bevel: 0.0004, segments: 8, material: "metal.brass"),
                                  Xform(translation: V3(0.04 + s * 0.025, y + dy, -0.0006 - strutT - 0.0018), rotation: simd_quatf(degrees: -90, axis: V3(1, 0, 0))))
                    }
                }
            }
            panel.add(Prim.roundedBox(V3(0.05, 0.022, 0.011), radius: 0.003, bevelSegments: 1, material: "rubber"),
                      Xform(translation: V3(0.04, 0.2 + 0.17 + 0.012, sz - strutT / 2 - 0.0035)))
            // Wall bumpers at the top back corners.
            for s: Float in [-1, 1] {
                panel.add(Prim.cylinder(radius: 0.011, height: 0.0065, bevel: 0.0015, segments: hi ? 14 : 8, material: "rubber"),
                          Xform(translation: V3(s * (W / 2 - 0.05), L - 0.1, -0.0006), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
            }
            // Lean the panel back and plant it.
            let lean = Xform(rotation: simd_quatf(angle: -theta, axis: V3(1, 0, 0)))
            m.add(panel.transformed(lean))
            // Two walnut feet under the bottom rail, bumper pads below them. Foot front lies behind the panel front plane.
            for s: Float in [-1, 1] {
                let fx = s * (W / 2 - 0.1)
                m.add(Prim.roundedBox(V3(0.075, 0.026, 0.052), radius: 0.006, bevelSegments: hi ? 3 : 2, material: wood),
                      Xform(translation: V3(fx, 0.013 + 0.0015, t * cos(theta) * 0.5 + 0.004)).jittered(&rng))
                m.add(Prim.roundedBox(V3(0.065, 0.003, 0.042), radius: 0.001, bevelSegments: 1, material: "rubber"), Xform(translation: V3(fx, 0.0015, t * cos(theta) * 0.5 + 0.004)))
            }
            // Plant: lowest point y = 0, panel top back at z = -depth / 2.
            let bb = m.bounds
            m = m.transformed(Xform(translation: V3(-(bb.min.x + bb.max.x) / 2, -bb.min.y, -size.z / 2 - bb.min.z)))
            groundAO(&m, height: 0.03, floor: 0.6)
            return m
        }
        return LODModel(levels: [make(true), make(false)], switchDistances: [5])
    }
}
