import simd
import Foundation

/// New Orleans cast-iron lacework railing, 2.4 m: five cast panels of ring-and-scroll lace set between a moulded
/// bottom rail and a moulded top rail with a half-round handrail cap, divided by flat stiles with rivet heads and
/// closed by a square newel post at each end on a bolted base flange. Each panel has a ringed rosette, diagonal
/// lace bars, C-scroll pairs and leaf sprigs. Black paint worn through to rust at the lower rail, flanges and
/// stile joints, with one panel repainted in a fresher black and bright replacement bolts on one flange.
public struct CastIronLaceworkRailing: RealAsset {
    public static let id = "cast-iron-lacework-railing"
    public static let summary = "New Orleans cast-iron lacework railing, 2.4 m: five ring-and-scroll lace panels, moulded rails, stiles and end posts on flanges."
    public static let tags = ["prop", "architecture", "facade", "trim", "metal"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 10, distance: 3.6)

    /// Black painted cast iron.
    public var iron: MaterialKey = "metal.wrought-iron"
    /// Bare cast iron of flanges and finials.
    public var cast: MaterialKey = "metal.cast-iron"
    /// Rust showing through chipped paint.
    public var rust: MaterialKey = "metal.rust"
    /// Replacement bolts.
    public var bolt: MaterialKey = "metal.bolt-bright"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [make(seed: seed, lite: false), make(seed: seed, lite: true)], switchDistances: [6])
    }

    func make(seed: UInt64, lite: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let px: Float = 1.175                         // post centre x
        let span: Float = 2 * px - 0.04               // clear run between post faces
        let yb0: Float = 0.07, yb1: Float = 0.14      // bottom rail
        let yt0: Float = 0.86, yt1: Float = 0.90      // top rail
        let sides = lite ? 4 : 5
        // Bottom rail: base fillet with a cove moulding and a thin top bead.
        FA.run(&m, [V2(-0.016, yb0), V2(0.016, yb0), V2(0.016, yb0 + 0.02), V2(0.012, yb0 + 0.026), V2(0.012, yb1 - 0.012), V2(0.0165, yb1 - 0.008), V2(0.0165, yb1 - 0.003), V2(0.011, yb1), V2(-0.011, yb1), V2(-0.0165, yb1 - 0.003), V2(-0.0165, yb1 - 0.008), V2(-0.012, yb1 - 0.012), V2(-0.012, yb0 + 0.026), V2(-0.016, yb0 + 0.02)],
               length: span + 0.02, at: .zero, iron, bevel: 0.0012)
        // Top rail: flat bar, ogee moulding and a half-round handrail cap.
        FA.run(&m, [V2(-0.014, yt0), V2(0.014, yt0), V2(0.014, yt0 + 0.012), V2(0.019, yt0 + 0.018), V2(0.019, yt1), V2(0.023, yt1 + 0.004), V2(0.024, yt1 + 0.012), V2(0.02, yt1 + 0.022), V2(0.011, yt1 + 0.028), V2(0, yt1 + 0.03), V2(-0.011, yt1 + 0.028), V2(-0.02, yt1 + 0.022), V2(-0.024, yt1 + 0.012), V2(-0.023, yt1 + 0.004), V2(-0.019, yt1), V2(-0.019, yt0 + 0.018), V2(-0.014, yt0 + 0.012)],
               length: span + 0.02, at: .zero, iron, bevel: 0.0012)
        // Small flat bars are bevelled extrusions (fewer triangles than rounded boxes).
        func bar(_ size: V3, _ c: V3, _ mat: MaterialKey) {
            let hx = size.x / 2, hy = size.y / 2
            m.add(Prim.extrude([V2(-hx, -hy), V2(hx, -hy), V2(hx, hy), V2(-hx, hy)], depth: size.z, bevel: min(0.0018, min(size.x, size.y) * 0.3), bevelSegments: 1, material: mat), Xform(translation: c))
        }
        // Stiles: panel dividers with a raised centre bead and rivet heads top and bottom.
        let cells = 5
        let stile: Float = 0.034
        let cw = (span - Float(cells - 1) * stile) / Float(cells)
        let ch = yt0 - yb1
        let cyMid = (yb1 + yt0) / 2
        var cx: [Float] = []
        for i in 0..<cells { cx.append(-span / 2 + cw / 2 + Float(i) * (cw + stile)) }
        for i in 0..<(cells - 1) {
            let sx = cx[i] + cw / 2 + stile / 2
            bar(V3(stile, ch + 0.01, 0.022), V3(sx, cyMid, 0), iron)
            bar(V3(0.01, ch - 0.02, 0.028), V3(sx, cyMid, 0), iron)
            if !lite {
                for ry in [yb1 + 0.018, yt0 - 0.018] { FA.cylZ(&m, r: 0.0045, h: 0.006, at: V3(sx, ry, 0.014), cast, bevel: 0.0012, segments: 6) }
            }
        }
        // Lace panels.
        func scroll(_ c: V3, radius R: Float, dir: Float, start: Float, turns: Float, r0: Float, _ mat: MaterialKey) {
            var pts: [V3] = [], rad: [Float] = []
            let steps = lite ? 6 : 7
            for k in 0...steps {
                let t = Float(k) / Float(steps)
                let a = start + dir * t * turns * 2 * .pi
                let r = R * (1 - 0.8 * t)
                pts.append(c + V3(cos(a) * r, sin(a) * r, 0)); rad.append(r0 - 0.0018 * t)
            }
            m.add(Prim.tube(pts, radii: rad, sides: 4, seamTile: 0.1, material: mat, capEnd: true))
            m.add(Prim.superellipsoid(V3(repeating: 0.0125), exponent: 2, subdivisions: lite ? 1 : 2, material: mat), Xform(translation: pts.last!))
        }
        func leaf(_ at: V3, deg: Float, len: Float, _ mat: MaterialKey) {
            // Pointed leaf: lathe lozenge laid along the local Y axis, rotated in the panel plane, flattened in Z.
            m.add(turned([(0, 0), (0.0055 * len / 0.05, 0.1 * len), (0.0105 * len / 0.05, 0.4 * len), (0.0075 * len / 0.05, 0.75 * len), (0, len)], segments: 4, material: mat, seamTile: 0.1),
                  Xform(translation: at, rotation: FA.q(deg, FA.Z), scale: V3(1, 1, 0.55)))
        }
        for (ci, x0) in cx.enumerated() {
            let tones: [MaterialKey] = [iron, "metal.cast-iron-street", "metal.wrought-iron:1B1A19", "metal.enamel:141416", "metal.wrought-iron:332D28"]
            let mat: MaterialKey = tones[ci]
            // Border: four flat bars bounding the lace field.
            let bw: Float = 0.012, bd: Float = 0.016
            bar(V3(cw, bw, bd), V3(x0, yb1 + bw / 2 - 0.001, 0), mat)
            bar(V3(cw, bw, bd), V3(x0, yt0 - bw / 2 + 0.001, 0), mat)
            for sx: Float in [-1, 1] { bar(V3(bw, ch, bd), V3(x0 + sx * (cw / 2 - bw / 2), cyMid, 0), mat) }
            // Central ring, rosette and boss.
            let ringR: Float = 0.105
            m.add(Prim.torus(major: ringR, minor: 0.0065, segments: lite ? 14 : 20, sides: 6, material: mat), Xform(translation: V3(x0, cyMid, 0), rotation: FA.q(90, FA.X)))
            m.add(Prim.torus(major: ringR * 0.62, minor: 0.0042, segments: lite ? 8 : 8, sides: 4, material: mat), Xform(translation: V3(x0, cyMid, 0), rotation: FA.q(90, FA.X)))
            let petals = lite ? 4 : 6
            for p in 0..<petals {
                let a = Float(p) / Float(petals) * 360
                leaf(V3(x0, cyMid, 0) + V3(sin(a * .pi / 180) * 0.012, cos(a * .pi / 180) * 0.012, 0), deg: -a, len: ringR * 0.62 - 0.012, mat)
            }
            m.add(Prim.superellipsoid(V3(0.03, 0.03, 0.026), exponent: 2, subdivisions: lite ? 1 : 3, material: mat), Xform(translation: V3(x0, cyMid, 0.004)))
            // Vertical stem to the rails with a pair of leaf sprigs.
            for sy: Float in [-1, 1] {
                bar(V3(0.009, ch / 2 - ringR - 0.012, 0.012), V3(x0, cyMid + sy * (ringR + (ch / 2 - ringR) / 2), 0), mat)
                let ly = cyMid + sy * (ringR + 0.06)
                for sx: Float in [-1, 1] { leaf(V3(x0, ly, 0), deg: -sx * 55 + (sy < 0 ? 180 : 0) * 1, len: 0.055, mat) }
            }
            // Diagonal lace bars from the ring to the corner roundels.
            for sx: Float in [-1, 1] { for sy: Float in [-1, 1] {
                let corner = V3(x0 + sx * (cw / 2 - 0.05), cyMid + sy * (ch / 2 - 0.05), 0)
                let dir = simd_normalize(corner - V3(x0, cyMid, 0))
                FA.rod(&m, V3(x0, cyMid, 0) + dir * (ringR + 0.004), corner, r: 0.0042, mat, sides: sides)
                m.add(Prim.torus(major: 0.032, minor: 0.0045, segments: lite ? 8 : 8, sides: 4, material: mat), Xform(translation: corner, rotation: FA.q(90, FA.X)))
                FC.bead(&m, r: 0.0085, at: corner, mat, sub: lite ? 1 : 2)
                // C-scrolls curling off the ring towards the side bars.
                scroll(V3(x0 + sx * 0.165, cyMid + sy * 0.1, 0), radius: 0.05, dir: sx * sy, start: sx > 0 ? 3.14 : 0, turns: 0.9, r0: 0.0055, mat)
            }}
        }
        // Pearl bead row under the top rail.
        if !lite {
            var bx = -span / 2 + 0.02
            while bx < span / 2 - 0.02 { FC.bead(&m, r: 0.0042, at: V3(bx, yt0 - 0.0035, 0.0165), iron, sub: 1); bx += 0.046 }
        }
        // Newel posts: square shaft with a moulded cap, ball finial and a cast flange with bolts.
        for e: Float in [-1, 1] {
            let x = e * px
            FA.box(&m, V3(0.04, 0.82, 0.04), V3(x, 0.5, 0), iron, r: 0.0035)
            bar(V3(0.048, 0.016, 0.048), V3(x, 0.115, 0), iron)
            bar(V3(0.048, 0.016, 0.048), V3(x, yt1 + 0.03, 0), iron)
            FA.box(&m, V3(0.05, 0.012, 0.05), V3(x, 0.006, 0), cast, r: 0.003)
            m.add(turned([(0, 0.012), (0.024, 0.012), (0.022, 0.02), (0.019, 0.035), (0.019, 0.045), (0, 0.045)], segments: 8, material: cast, seamTile: 0.1), Xform(translation: V3(x, 0, 0)))
            m.add(turned([(0, 0.938), (0.022, 0.938), (0.024, 0.944), (0.017, 0.952), (0.017, 0.958), (0.023, 0.968), (0.024, 0.982), (0.022, 0.998), (0.016, 1.008), (0.008, 1.012), (0.011, 1.017), (0.008, 1.028), (0, 1.03)], segments: lite ? 8 : 10, material: cast, seamTile: 0.1, grainVertical: true), Xform(translation: V3(x, 0, 0)))
            if !lite {
                for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
                    let fresh = e > 0 && sx > 0
                    m.add(Prim.cylinder(radius: 0.0052, height: 0.005, bevel: 0.0008, segments: 6, bevelSegments: 1, material: fresh ? bolt : cast), Xform(translation: V3(x + sx * 0.019, 0.012, sz * 0.019)))
                }}
            }
        }
        // Weathering.
        if !lite {
            func flat(_ cx: Float, _ cz: Float, _ rx: Float, _ rz: Float, y: Float, _ mat: MaterialKey) {
                var poly: [V2] = []
                for j in 0..<9 { let a = Float(j) / 9 * 2 * .pi; poly.append(V2(cx + cos(a) * rx * rng.float(0.55...1.1), cz + sin(a) * rz * rng.float(0.55...1.1))) }
                m.add(HTKit.plate(outer: poly, depth: 0.0008, bevel: 0.0002, segments: 1, material: mat), Xform(translation: V3(0, y, 0), rotation: FA.q(90, FA.X)))
            }
            for _ in 0..<6 { flat(rng.float(-1.1...1.1), rng.float(-0.008...0.008), rng.float(0.015...0.06), rng.float(0.004...0.008), y: yb1 + 0.0004, rust) }
            for _ in 0..<4 { flat(rng.float(-1.1...1.1), rng.float(-0.01...0.01), rng.float(0.012...0.05), rng.float(0.004...0.009), y: yt1 + 0.0301, rust) }
            for i in 0..<(cells - 1) { bar(V3(stile + 0.0004, 0.05, 0.0225), V3(cx[i] + cw / 2 + stile / 2, yb1 + 0.03, 0), rust) }
            for e: Float in [-1, 1] {
                for _ in 0..<3 { flat(e * px + rng.float(-0.02...0.02), rng.float(-0.014...0.014), rng.float(0.005...0.01), rng.float(0.004...0.008), y: 0.0121, rust) }
                bar(V3(0.0505, 0.003, 0.0505), V3(e * px, 0.0015, 0), rust)
                bar(V3(0.0405, 0.035, 0.0405), V3(e * px, 0.06, 0), rust)
                bar(V3(0.0408, 0.012, 0.0408), V3(e * px, 0.083, 0), iron)
            }
            // Rust streaks running down from the rivets, rings and the lower border, a brass foundry plaque, and bare metal worn bright on the handrail cap where hands slide.
            for i in 0..<(cells - 1) {
                let sx = cx[i] + cw / 2 + stile / 2
                bar(V3(0.004, rng.float(0.05...0.12), 0.0226), V3(sx + rng.float(-0.008...0.008), yb1 + 0.08, 0), rust)
                bar(V3(0.003, rng.float(0.04...0.09), 0.0226), V3(sx + rng.float(-0.01...0.01), yt0 - 0.06, 0), rust)
            }
            for ci in 0..<cells {
                // Paint gone from the lower border and the lower ends of the side bars where water pools.
                let w = cw * rng.float(0.35...0.8)
                bar(V3(w, 0.0125, 0.0166), V3(cx[ci] + rng.float(-0.5...0.5) * (cw - w), yb1 + 0.0059, 0), rust)
                for sx: Float in [-1, 1] where rng.chance(0.7) { bar(V3(0.0123, rng.float(0.05...0.16), 0.0166), V3(cx[ci] + sx * (cw / 2 - 0.006), yb1 + 0.1, 0), rust) }
            }
            for ci in [0, 2, 4] { bar(V3(0.006, 0.05, 0.0166), V3(cx[ci] + rng.float(-0.1...0.1), yb1 + 0.036, 0), rust) }
            for k in 0..<5 { flat(-0.9 + Float(k) * 0.45 + rng.float(-0.08...0.08), rng.float(-0.004...0.004), rng.float(0.05...0.11), 0.0045, y: yt1 + 0.0302, "metal.steel") }
            bar(V3(0.07, 0.022, 0.006), V3(cx[1], yb0 + 0.012, 0.0165), "metal.brass-aged")
            for rx: Float in [-0.028, 0.028] { FA.cylZ(&m, r: 0.0032, h: 0.003, at: V3(cx[1] + rx, yb0 + 0.012, 0.0225), cast, bevel: 0.0008, segments: 6) }
            bar(V3(0.0012, 0.3, 0.0405), V3(-px + 0.012, 0.5, 0), rust)
        }
        groundAO(&m, height: 0.15, floor: 0.8)
        return FC.place(m)
    }
}
