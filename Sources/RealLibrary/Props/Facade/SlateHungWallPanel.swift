import simd
import Foundation

/// Cornish slate-hung wall panel, 1.2 x 2.0 x 0.05 m: eleven courses of riven slates (0.24 x 0.40 m, 0.1525 m
/// gauge, 2.5-fold lap) with half-bond staggered joints, hung on horizontal battens over a dark underlay, each slate
/// tilted a degree off the wall so the tails kick out, with timber edge trims at the verges and foot, lead verge
/// flashing, a lead head cap and copper nail heads face-fixed on the verge and eaves slates. Slates carry varied
/// grey tints, a broken corner, one slipped slate, lichen on the lower courses and rust from iron nails.
public struct SlateHungWallPanel: RealAsset {
    public static let id = "slate-hung-wall-panel"
    public static let summary = "Cornish slate-hung wall panel, 1.2 x 2.0 m: staggered courses of riven slate on battens, timber verge trims, lead flashing and copper nails."
    public static let tags = ["prop", "architecture", "facade", "wood", "stone"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 10, distance: 1.1)

    /// Slate tints, from blue-grey to green-grey.
    public var tints: [String] = ["5C646C", "4F575F", "666E70", "586068", "6A6F6B"]
    /// Weathered timber trims and battens.
    public var timber: MaterialKey = "wood.painted-exterior:9A9684"
    /// Underlay felt behind the slates.
    public var underlay: MaterialKey = "wood.charred"
    /// Lead flashing.
    public var lead: MaterialKey = "metal.galvanized-aged"
    /// Copper nail heads.
    public var copper: MaterialKey = "metal.copper-patina"
    /// Rust from iron nails.
    public var rust: MaterialKey = "metal.rust"
    /// Lichen on the lower courses.
    public var lichen: MaterialKey = "stone.granite-moss:7C8A55"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [make(seed: seed, lite: false), make(seed: seed, lite: true)], switchDistances: [5])
    }

    func make(seed: UInt64, lite: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W: Float = 1.2, H: Float = 2.0
        let trim: Float = 0.04, foot: Float = 0.045, head: Float = 0.03
        let sl: Float = 0.40, sw: Float = 0.24, gauge: Float = 0.1525
        let courses = 11
        let xl = -W / 2 + trim, xr = W / 2 - trim
        let tilt: Float = -asin(0.016 / sl) * 180 / .pi
        // Underlay and battens.
        FA.box(&m, V3(xr - xl, H - foot - head, 0.004), V3(0, (H + foot - head) / 2, 0.002), underlay, r: 0.001)
        for c in 0..<courses {
            let yb = foot + Float(c) * gauge + 0.31
            if yb < H - head - 0.02 { FA.box(&m, V3(xr - xl, 0.036, 0.02), V3(0, yb, 0.013), timber, r: 0.002) }
        }
        // Edge trims at the verges and the foot (full depth), head cap above.
        for s: Float in [-1, 1] { FA.box(&m, V3(trim, H, 0.05), V3(s * (W / 2 - trim / 2), H / 2, 0.025), timber, r: 0.003) }
        FA.box(&m, V3(xr - xl, foot, 0.05), V3(0, foot / 2, 0.025), timber, r: 0.003)
        // Lead verge flashing: a dressed strip folded over each trim's inner edge.
        for s: Float in [-1, 1] {
            FA.box(&m, V3(0.014, H - 0.04, 0.052), V3(s * (xr - 0.007 + 0.0), H / 2 + 0.0, 0.026), lead, r: 0.002)
        }
        FA.box(&m, V3(W, head, 0.05), V3(0, H - head / 2, 0.025), lead, r: 0.003)
        // Slate courses.
        var edges: [Float] = []
        var idx = 0
        for c in 0..<courses {
            var r = rng.fork(200 + c)
            let tail = foot + Float(c) * gauge
            // Joint lines: random scantle widths, kept at least 4 cm off the joints of the course below.
            var xs: [Float] = [xl]
            var x = xl
            while true {
                var w = r.float(0.18...0.3)
                var tries = 0
                while tries < 8, edges.contains(where: { abs($0 - (x + w)) < 0.04 }) { w = r.float(0.18...0.3); tries += 1 }
                x += w + 0.004
                if x > xr - 0.1 { break }
                xs.append(x)
            }
            xs.append(xr)
            edges = xs
            for k in 0..<(xs.count - 1) {
                let x0 = xs[k] + 0.002, x1 = xs[k + 1] - 0.002
                let w = x1 - x0
                if w < 0.03 { continue }
                var yc = tail + sl / 2
                var drop: Float = 0
                var outTilt: Float = tilt
                if c == 6 && k == 2 { drop = 0.035; outTilt = tilt - 1.0 }   // slipped slate
                yc -= drop
                let tint = r.chance(0.1) ? "66705F" : tints[r.int(0...(tints.count - 1))]
                let mat = MaterialKey(stringLiteral: "stone.slate:" + tint)
                let th = r.float(0.007...0.0095)
                let hx = w / 2, hy = sl / 2
                // Rectangle with chamfered tail corners, plus a broken corner on one slate.
                var ch0: Float = r.float(0.002...0.006), ch1: Float = r.float(0.002...0.006)
                if c == 3 && k == 1 { ch1 = 0.06 }
                let o: [V2] = [V2(-hx + ch0, -hy), V2(hx - ch1, -hy), V2(hx, -hy + ch1), V2(hx, hy), V2(-hx, hy), V2(-hx, -hy + ch0)]
                ch0 = 0
                m.add(Prim.extrude(o, depth: th, bevel: 0.0009, bevelSegments: 1, material: mat),
                      Xform(translation: V3((x0 + x1) / 2 + r.float(-0.001...0.001), yc, 0.0285 + th / 2 + r.float(-0.0008...0.0008) + (drop > 0 ? -0.003 : 0)),
                            rotation: FA.q(r.float(-0.7...0.7), FA.Z) * FA.q(outTilt + r.float(-0.5...0.5), FA.X)))
                // Face nails: copper heads on verge slates and the eaves course.
                if !lite && (c == 0 || k == 0 || k == xs.count - 2) {
                    for nx in [x0 + 0.03, x1 - 0.03] {
                        if w < 0.07 { continue }
                        FO9.head(&m, at: V3(nx, tail + 0.04, 0.0455), r: 0.0042, h: 0.0022, segments: 6, copper)
                    }
                }
                idx += 1
            }
        }
        _ = edges
        if !lite {
            // Iron nail rust streaks on three verge slates, lichen on the lower courses, water staining at the foot.
            for (k, y) in [Float(0.62), 1.12, 1.55].enumerated() {
                FO9.patch(&m, cx: xl + 0.03 + Float(k) * 0.005, cy: y, rx: 0.0035, ry: rng.float(0.03...0.07), z: 0.0482, rust, rng: &rng, depth: 0.0006, n: 6)
            }
            for _ in 0..<9 { FO9.patch(&m, cx: rng.float(xl + 0.05...xr - 0.05), cy: rng.float(foot + 0.02...0.6), rx: rng.float(0.015...0.05), ry: rng.float(0.01...0.03), z: 0.0475, lichen, rng: &rng, depth: 0.0006, n: 9) }
            // Weathering on timber trims: bare grey grain showing and a few drying checks.
            for s: Float in [-1, 1] { for _ in 0..<4 { FO9.patch(&m, cx: s * (W / 2 - trim / 2) + rng.float(-0.008...0.008), cy: rng.float(0.1...1.9), rx: 0.006, ry: rng.float(0.03...0.08), z: 0.0505, "wood.charred", rng: &rng, depth: 0.0004, n: 6) } }
        }
        groundAO(&m, height: 0.1, floor: 0.8)
        return FC.place(m)
    }
}
