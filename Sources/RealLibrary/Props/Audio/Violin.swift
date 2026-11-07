import simd
import Foundation

/// Full size (4/4) violin, 0.59 m long, lying face up: two-bout flamed maple body (355 mm) with arched spruce top and back,
/// ribs, purfling, f-holes, ebony fingerboard, nut, tailpiece, chin rest, endpin and pegs, maple neck and scroll,
/// maple bridge and four steel strings. A bow (round stick with wrap, ebony frog, flat hair ribbon, tip head) lies beside it.
/// The body runs along -Z from the lower end at z = 0 to the scroll; the bow lies at +X. Origin at the base centre.
public struct Violin: RealAsset {
    public static let id = "violin"
    public static let summary = "Full size violin, 0.59 m: arched maple body, f-holes, ebony neck parts, scroll, pegs, bridge, tailpiece, 4 strings, plus a bow beside it."
    public static let tags = ["prop", "audio", "music", "instrument", "wood", "string"]
    public static let budget = 24_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 20, elevation: 40, distance: 0.7, studio: true)

    public var back: MaterialKey = "wood.maple-natural:B8741A"
    public var top: MaterialKey = "wood.maple-natural:D9B36A"
    public var ebony: MaterialKey = "wood.walnut:17110D"
    public var withBow = true
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        _ = seed
        var levels: [Model] = []
        let bodyLen: Float = 0.355, cy: Float = 0.1775
        let varnish: MaterialKey = "wood.maple-natural:A8661F"
        let dark: MaterialKey = "plastic.matte:0A0806"
        let steel: MaterialKey = "metal.chrome"
        func W(_ x: Float, _ ly: Float, _ y: Float) -> V3 { V3(x, y, -ly) }
        for l in 0..<2 {
            var m = Model(name: Self.id)
            let hi = l == 0
            // Body outline (x, length coordinate): right half bottom to top, mirrored for the left half.
            let ctrl: [V3] = [V3(0, 0, 0), V3(0.05, 0.002, 0), V3(0.09, 0.015, 0), V3(0.104, 0.05, 0), V3(0.1, 0.085, 0), V3(0.077, 0.12, 0),
                              V3(0.0575, 0.155, 0), V3(0.0565, 0.18, 0), V3(0.06, 0.21, 0), V3(0.075, 0.235, 0), V3(0.082, 0.27, 0),
                              V3(0.078, 0.31, 0), V3(0.06, 0.34, 0), V3(0.03, 0.352, 0), V3(0, bodyLen, 0)]
            let half = catmull(ctrl, per: hi ? 6 : 3).map { V2($0.x, $0.y) }
            let right = Array(half.dropLast())
            let left = half.dropFirst().reversed().map { V2(-$0.x, $0.y) }
            let outline = Shape2D.deduped(right + Array(left.dropLast()))
            let plate = Shape2D.offset(outline, 0.0016)
            let c = V2(0, cy)
            // Polar table of the plate outline for height lookups.
            let polar = plate.map { (atan2($0.y - c.y, $0.x - c.x), simd_length($0 - c)) }
            func sOf(_ x: Float, _ ly: Float) -> Float {
                let p = V2(x, ly) - c, a = atan2(p.y, p.x)
                var best = polar[0].1, bd = Float.greatestFiniteMagnitude
                for q in polar { var d = abs(q.0 - a); if d > .pi { d = 2 * .pi - d }; if d < bd { bd = d; best = q.1 } }
                return min(1, simd_length(p) / best)
            }
            func topY(_ s: Float) -> Float { 0.043 + 0.0145 * pow(max(0, 1 - s * s), 0.7) }
            func backY(_ s: Float) -> Float { 0.0005 + 0.0115 * s * s }
            func ring(_ s: Float, _ y: Float) -> [V3] { Prim.ring(plate.map { c + ($0 - c) * s }, y: y) }
            // Arched top (edge -> centre) and back (centre -> edge) keep outward normals.
            let ts: [Float] = hi ? [1, 0.965, 0.9, 0.8, 0.65, 0.45, 0.25, 0.1] : [1, 0.9, 0.65, 0.3, 0.1]
            m.add(Prim.loft(ts.map { ring($0, topY($0)) }, capEnd: true, material: top))
            let bsc: [Float] = hi ? [0.1, 0.3, 0.5, 0.7, 0.85, 1] : [0.1, 0.5, 0.85, 1]
            m.add(Prim.loft(bsc.map { ring($0, backY($0)) }, capStart: true, material: back))
            m.add(Prim.loft([Prim.ring(outline, y: 0.011), Prim.ring(outline, y: topY(1) + 0.0004)], material: varnish))
            // Purfling: dark inlay just inside the top edge.
            let pRing = ring(ts[1], topY(ts[1]) + 0.0003)
            m.add(Prim.sweep(Shape2D.circle(0.0007, segments: 6), along: pRing, closedPath: true, caps: false, material: dark))
            // F-holes (right one, mirrored).
            let fh: [V3] = [V3(0.0445, 0.200, 0), V3(0.0405, 0.185, 0), V3(0.0365, 0.172, 0), V3(0.0350, 0.160, 0), V3(0.0365, 0.148, 0),
                            V3(0.0420, 0.135, 0), V3(0.0475, 0.126, 0)]
            for sx in [Float(1), -1] {
                let path = catmull(fh, per: hi ? 4 : 2).map { W(sx * $0.x, $0.y, topY(sOf($0.x, $0.y)) - 0.0004) }
                let rr = path.indices.map { i -> Float in 0.0013 + 0.0009 * pow(abs(Float(i) / Float(path.count - 1) * 2 - 1), 2) }
                m.add(Prim.tube(path, radii: rr, sides: hi ? 8 : 5, seamTile: 0.01, material: dark))
            }
            // Bridge: extruded maple silhouette standing on the top plate at ly 0.160.
            let bridge: [V2] = [V2(-0.0205, 0), V2(-0.0165, 0), V2(-0.0125, 0.007), V2(0, 0.0105), V2(0.0125, 0.007), V2(0.0165, 0), V2(0.0205, 0),
                                V2(0.0185, 0.011), V2(0.0155, 0.022), V2(0.0170, 0.0295), V2(0.0172, 0.031), V2(0.0075, 0.0315), V2(0, 0.0319),
                                V2(-0.0075, 0.0315), V2(-0.0172, 0.031), V2(-0.0170, 0.0295), V2(-0.0155, 0.022), V2(-0.0185, 0.011)]
            let bridgeY: Float = 0.0553, bridgeTop = bridgeY + 0.0319
            m.add(Prim.extrude(bridge, depth: 0.0016, bevel: 0.0004, bevelSegments: 1, material: "wood.maple-natural:E3C890"),
                  Xform(translation: V3(0, bridgeY, -0.160)))
            // Neck (maple), fingerboard (ebony), nut, pegbox, scroll.
            func fbY(_ ly: Float) -> Float { 0.066 - 0.014 * (ly - 0.215) / 0.27 }
            let neckPath = [W(0, 0.30, fbY(0.30) - 0.008), W(0, 0.485, fbY(0.485) - 0.008)]
            m.add(Prim.sweep(Shape2D.circle(0.009, ry: 0.0105, segments: hi ? 20 : 10), along: neckPath, up: V3(0, 1, 0), material: varnish))
            var fb: [V2] = []
            for k in 0...10 { let w = -0.0215 + 0.043 * Float(k) / 10; fb.append(V2(0.004 + 0.0025 * (1 - pow(w / 0.0215, 2)), w)) }
            fb += [V2(0, 0.0215), V2(0, -0.0215)]
            let fbPath = [W(0, 0.215, fbY(0.215)), W(0, 0.485, fbY(0.485))]
            m.add(Prim.sweep(fb, along: fbPath, up: V3(0, 1, 0), scales: [1, 0.56], material: ebony))
            m.add(Prim.roundedBox(V3(0.0245, 0.0042, 0.0032), radius: 0.001, bevelSegments: 2, material: "ceramic.porcelain:E8E2D0"),
                  Xform(translation: W(0, 0.4865, fbY(0.485) + 0.0058)))
            m.add(Prim.roundedBox(V3(0.0245, 0.0205, 0.060), radius: 0.003, bevelSegments: hi ? 3 : 1, material: varnish),
                  Xform(translation: W(0, 0.515, fbY(0.485) - 0.0095)))
            m.add(Prim.roundedBox(V3(0.0105, 0.004, 0.044), radius: 0.001, bevelSegments: 1, material: dark),
                  Xform(translation: W(0, 0.512, fbY(0.485) + 0.0005)))
            // Scroll: tapering ribbon spiral in the length-height plane.
            let sc = W(0, 0.560, fbY(0.485) - 0.0045)
            let turns: Float = 2.4, n = hi ? 44 : 22
            var sp: [V3] = [], ss: [Float] = []
            for i in 0...n {
                let u = Float(i) / Float(n), a = -Float.pi / 2 + u * turns * 2 * .pi
                let r = 0.0205 - 0.0165 * u
                sp.append(sc + V3(0, r * sin(a), -r * cos(a)))
                ss.append(1 - 0.55 * u)
            }
            m.add(Prim.sweep(Shape2D.roundedRect(0.0215, 0.0058, radius: 0.0016, segments: 2), along: sp, up: V3(1, 0, 0), scales: ss, material: varnish))
            // Pegs: ebony, two per side through the pegbox.
            let pegProfile: [V2] = [V2(0, 0), V2(0.0022, 0), V2(0.0026, 0.014), V2(0.0036, 0.0165), V2(0.0045, 0.0195), V2(0.0066, 0.022),
                                    V2(0.0095, 0.0265), V2(0.0105, 0.0295), V2(0.0085, 0.0315), V2(0, 0.0315)]
            for (i, ly) in [Float(0.500), 0.5185, 0.5335, 0.549].enumerated() {
                let sx: Float = i % 2 == 0 ? 1 : -1
                m.add(Prim.lathe(pegProfile, segments: hi ? 20 : 10, seamTile: 0.03, material: ebony),
                      Xform(translation: W(sx * 0.003, ly, fbY(0.485) - 0.0095), rotation: simd_quatf(angle: -sx * .pi / 2, axis: V3(0, 0, 1))))
            }
            // Tailpiece, gut, endpin, chin rest.
            let tail = Shape2D.rounded([V2(-0.0075, 0.048), V2(0.0075, 0.048), V2(0.0120, 0.090), V2(0.0172, 0.126), V2(-0.0172, 0.126), V2(-0.0120, 0.090)],
                                       radius: 0.004, segments: 2)
            m.add(Prim.loft([Prim.ring(tail, y: 0.0545), Prim.ring(tail, y: 0.0615)], capStart: true, capEnd: true, material: ebony))
            m.add(Prim.tube(catmull([V3(0, 0.0285, 0.006), V3(0, 0.043, -0.002), V3(0, 0.0535, -0.030), V3(0, 0.0585, -0.047)], per: 4),
                            radii: Array(repeating: 0.0009, count: 13), sides: 6, seamTile: 0.01, material: dark))
            m.add(Prim.lathe([V2(0, 0), V2(0.003, 0), V2(0.0035, 0.006), V2(0.0055, 0.009), V2(0.0065, 0.014), V2(0.004, 0.019), V2(0, 0.0205)],
                             segments: hi ? 20 : 10, seamTile: 0.03, material: ebony),
                  Xform(translation: V3(0, 0.0275, -0.002), rotation: simd_quatf(angle: .pi / 2, axis: V3(1, 0, 0))))
            m.add(Prim.superellipsoid(V3(0.085, 0.016, 0.062), exponent: 3, subdivisions: hi ? 8 : 4, material: ebony),
                  Xform(translation: V3(-0.052, 0.0585, -0.080)))
            // Strings: nut -> bridge -> tailpiece.
            let nutY = fbY(0.485) + 0.0075
            for (xn, xb, xt) in [(Float(-0.0108), Float(-0.0160), Float(-0.0075)), (-0.0036, -0.0053, -0.0025), (0.0036, 0.0053, 0.0025), (0.0108, 0.0160, 0.0075)] {
                let pts = [V3(xn, nutY, -0.485), V3(xb, bridgeTop, -0.160), V3(xt, 0.0625, -0.052)]
                for k in 0..<2 {
                    m.add(Prim.tube([pts[k], pts[k + 1]], radii: [0.0004, 0.0004], sides: hi ? 6 : 4, seamTile: 0.003, material: steel, capEnd: false))
                }
            }
            // Bow: lies at +X beside the violin, frog toward the lower end.
            if withBow {
                let bx: Float = 0.165, zF: Float = 0.07, bl: Float = 0.74
                func bz(_ t: Float) -> Float { zF - bl * t }
                func by(_ t: Float) -> Float { 0.004 + (0.032 - 0.012 * t) - 0.014 * sin(.pi * t) }
                let ts2 = (0...(hi ? 40 : 16)).map { Float($0) / Float(hi ? 40 : 16) }
                let stick = ts2.map { V3(bx, by($0), bz($0)) }
                m.add(Prim.tube(stick, radii: ts2.map { 0.0050 - 0.0016 * $0 }, sides: hi ? 12 : 6, seamTile: 0.02, material: "wood.mahogany"))
                let wrapN = hi ? 8 : 3
                func seg(_ t0: Float, _ t1: Float, _ r: Float, _ mat: MaterialKey) {
                    let tt = (0...wrapN).map { t0 + (t1 - t0) * Float($0) / Float(wrapN) }
                    m.add(Prim.tube(tt.map { V3(bx, by($0), bz($0)) }, radii: tt.map { _ in r }, sides: hi ? 12 : 6, seamTile: 0.02, material: mat, capEnd: false))
                }
                seg(0.07, 0.115, 0.0058, "leather.black")
                seg(0.115, 0.185, 0.0056, steel)
                m.add(Prim.roundedBox(V3(0.0125, 0.026, 0.050), radius: 0.003, bevelSegments: hi ? 3 : 1, material: ebony),
                      Xform(translation: V3(bx, 0.017, zF - 0.032)))
                m.add(Prim.roundedBox(V3(0.0132, 0.0058, 0.052), radius: 0.002, bevelSegments: 2, material: steel),
                      Xform(translation: V3(bx, 0.0045, zF - 0.032)))
                m.add(Prim.roundedBox(V3(0.0105, 0.0013, bl * 0.935), radius: 0.0004, bevelSegments: 1, material: "fabric.linen:EDE6D2"),
                      Xform(translation: V3(bx, 0.0072, zF - 0.056 - bl * 0.935 / 2 + 0.0)))
                m.add(Prim.roundedBox(V3(0.0085, 0.021, 0.024), radius: 0.003, bevelSegments: hi ? 3 : 1, material: "ceramic.porcelain:E8E2D0"),
                      Xform(translation: V3(bx, 0.0115, bz(1) - 0.004)))
                m.add(Prim.cylinder(radius: 0.0045, height: 0.014, bevel: 0.0012, segments: hi ? 16 : 8, bevelSegments: 2, material: ebony),
                      Xform(translation: V3(bx, by(0), zF + 0.003), rotation: simd_quatf(angle: .pi / 2, axis: V3(1, 0, 0))))
            }
            let bb = m.bounds
            levels.append(m.transformed(Xform(translation: V3(-(bb.min.x + bb.max.x) / 2, -bb.min.y, -(bb.min.z + bb.max.z) / 2))))
        }
        return LODModel(levels: levels, switchDistances: [2])
    }
}
