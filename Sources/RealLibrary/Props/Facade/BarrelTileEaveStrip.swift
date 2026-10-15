import simd
import Foundation

/// Barrel tile eave strip: Spanish Colonial Revival eave, 2.0 m of fired clay barrel tile. Twelve concave pan
/// tile columns with tapered convex cover tiles over the joints, two overlapping courses, mortar bird-stop
/// closures in the cover mouths, a sloped plank deck on exposed rafter tails with shaped ends, a wood fascia
/// with nail heads and a stucco wall edge. Lichen and efflorescence weather the clay.
public struct BarrelTileEaveStrip: RealAsset {
    public static let id = "barrel-tile-eave-strip"
    public static let summary = "Spanish barrel tile eave, 2.0 m: pan and cover tiles, bird-stop closures, fascia board, exposed rafter tails."
    public static let tags = ["prop", "architecture", "facade", "trim", "decor", "stone", "wood"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 22, distance: 1.3)

    /// Overall width in meters.
    public var width: Float = 2.0
    /// Roof pitch in degrees.
    public var pitch: Float = 16
    /// Fired clay tile material.
    public var clay: MaterialKey = "ceramic.terracotta:B8603F"
    /// Aged clay for the older courses and covers.
    public var clayAged: MaterialKey = "ceramic.terracotta:A5593B"
    /// Fascia and rafter wood.
    public var wood: MaterialKey = "wood.cedar-weathered"
    /// Wall stucco and mortar.
    public var stucco: MaterialKey = "paint.stucco:EFE0C2"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let th = pitch * .pi / 180, sn = sin(th), cs = cos(th)
        let zFront: Float = 0.2, zBack: Float = -0.175
        let yFront: Float = 0.10   // top of the deck at the eave
        // Point on the roof plane: t metres up-slope from the eave, x across, h normal to the deck.
        func P(_ x: Float, _ t: Float, _ h: Float = 0) -> V3 {
            V3(x, yFront + t * sn + h * cs, zFront - t * cs + h * sn)
        }
        let slopeLen = (zFront - zBack) / cs
        let axisX = V3(1, 0, 0)
        // Domed square-cut nail head.
        func nail(_ r: Float, _ c: V3) {
            m.add(Prim.superellipsoid(V3(repeating: r * 2), exponent: 2, subdivisions: 2, material: "metal.cast-iron"), Xform(translation: c))
        }

        // Exposed rafter tails: 0.05 x 0.07 sawn cedar, 12 of them, parallel to the deck, ends cut with a bevel and a chamfer.
        let nR = 13
        for i in 0..<nR {
            let x = -width / 2 + 0.04 + Float(i) * (width - 0.08) / Float(nR - 1)
            let len: Float = slopeLen + 0.02
            let c = P(x, len / 2 - 0.045, -0.043)
            FA.box(&m, V3(0.05, 0.07, len), c, wood, r: 0.004, rot: FA.q(pitch, axisX))
            // Bevelled tail end: a shaped cap, 0.07 high at the eave, cut square then chamfered.
            let tip = P(x, -0.046, -0.043)
            FA.box(&m, V3(0.05, 0.012, 0.03), tip + V3(0, 0.026, 0.002), wood, r: 0.003, rot: FA.q(pitch + 38, axisX))
            // Nail heads in the tail top and end grain.
        }
        // Plank deck over the rafters, laid across them in six courses with open joints.
        let nP = 5
        for i in 0..<nP {
            let t0 = -0.04 + Float(i) * (slopeLen + 0.04) / Float(nP)
            let len = (slopeLen + 0.04) / Float(nP) - 0.004
            FA.box(&m, V3(width - 0.01, 0.014, len), P(0, t0 + len / 2, -0.007), "wood.pine-aged", r: 0.0025, rot: FA.q(pitch, axisX))
        }
        // Fascia board and a drip batten at the eave line.
        let fz = zFront + 0.012
        FA.box(&m, V3(width, 0.082, 0.022), V3(0, 0.063, fz), wood, r: 0.004)
        FA.box(&m, V3(width, 0.014, 0.034), V3(0, 0.108, fz - 0.004), wood, r: 0.003)
        for i in 0..<nR {
            let x = -width / 2 + 0.04 + Float(i) * (width - 0.08) / Float(nR - 1)
            for y: Float in [0.04, 0.08] { nail(0.0042, V3(x + 0.012, y, fz + 0.011)) }
        }
        // Stucco wall edge behind the tile with a hard plaster cap and a flashing line.
        FA.box(&m, V3(width, 0.3, 0.05), V3(0, 0.15, zBack - 0.0), stucco, r: 0.004)
        FA.box(&m, V3(width, 0.03, 0.065), V3(0, 0.285, zBack - 0.0), stucco, r: 0.004)
        FA.box(&m, V3(width - 0.02, 0.012, 0.004), V3(0, 0.27, zBack + 0.027), "metal.galvanized-aged", r: 0.0015)

        // Tile profiles. Profile x runs across the roof, y out of the roof plane (checked on the sheet).
        let pitchX = width / 12
        let panHalf: Float = pitchX / 2 - 0.004
        func pan() -> [V2] {
            let n = 5, t: Float = 0.007, rise: Float = 0.02
            var outer: [V2] = [], inner: [V2] = []
            for i in 0...n {
                let u = -1 + 2 * Float(i) / Float(n)
                outer.append(V2(u * panHalf, rise * u * u))
                inner.append(V2(u * (panHalf - 0.004), rise * u * u + t))
            }
            return outer + inner.reversed()
        }
        func cover() -> [V2] {
            let n = 5, t: Float = 0.007, h: Float = 0.046, hw: Float = 0.052
            var outer: [V2] = [], inner: [V2] = []
            for i in 0...n {
                let u = -1 + 2 * Float(i) / Float(n)
                outer.append(V2(u * hw, h * (1 - u * u) + 0.004))
                inner.append(V2(u * (hw - 0.007), h * (1 - u * u) + 0.004 - t))
            }
            return outer + inner.reversed()
        }
        let panProf = Shape2D.deduped(pan().map { V2($0.x, -$0.y) }), coverProf = Shape2D.deduped(cover().map { V2($0.x, -$0.y) })
        // Sweep a tile from t0 to t1 up-slope at lateral x; scales taper the cover tiles toward the ridge.
        func tile(_ x: Float, _ t0: Float, _ t1: Float, _ prof: [V2], taper: Float, lift: Float, _ mat: MaterialKey) {
            let pts = (0...2).map { i -> V3 in P(x, t0 + (t1 - t0) * Float(i) / 2, lift) }
            let sc = (0...2).map { i -> Float in 1 - taper * Float(i) / 2 }
            m.add(Prim.sweep(prof, along: pts, up: axisX, scales: sc, caps: true, material: mat))
        }
        // Four firing tints: salmon (underfired), standard, dark (overfired) and sun-bleached.
        let tints: [MaterialKey] = [clay, clayAged, "ceramic.terracotta:C9754F", "ceramic.terracotta:93492F", "ceramic.terracotta:D08A63"]
        let courses: [(Float, Float, Float)] = [(-0.035, 0.235, 0.0), (0.195, slopeLen + 0.005, 0.009)]
        for (ci, (t0, t1, lift)) in courses.enumerated() {
            for k in 0..<12 {
                var r = rng.fork(ci * 40 + k)
                let x = -width / 2 + pitchX * (Float(k) + 0.5)
                let mat = r.pick(tints)
                tile(x, t0 + r.float(-0.004...0.004), t1, panProf, taper: 0.0, lift: 0.0012 + lift, mat)
            }
            for k in 1..<12 {
                var r = rng.fork(100 + ci * 40 + k)
                let x = -width / 2 + pitchX * Float(k)
                let mat = r.pick(tints)
                tile(x, t0 + r.float(-0.005...0.005) + 0.005, t1 - 0.006, coverProf, taper: 0.22, lift: 0.001 + lift, mat)
            }
        }
        // Half covers along the two ends hold the edge pans.
        for e: Float in [-1, 1] {
            for (ci, (t0, t1, lift)) in courses.enumerated() {
                let x = e * (width / 2 - 0.012)
                FA.box(&m, V3(0.024, 0.03, t1 - t0), P(x, (t0 + t1) / 2, 0.02 + lift), clay, r: 0.004, rot: FA.q(pitch, axisX))
                _ = ci
            }
        }
        // Bird-stop: curved mortar closure in the mouth of each cover tile at the eave.
        for k in 1..<12 {
            let x = -width / 2 + pitchX * Float(k)
            FA.box(&m, V3(0.082, 0.026, 0.026), P(x, 0.0, 0.0245), stucco, r: 0.006, rot: FA.q(pitch, axisX))
            FA.box(&m, V3(0.07, 0.016, 0.01), P(x, -0.02, 0.012), "paint.stucco:C4B290", r: 0.004, rot: FA.q(pitch, axisX))
        }
        // Weathering: lichen and efflorescence blotches on the clay, soot streaks at the cover crowns.
        for i in 0..<22 {
            let x = rng.float(-width / 2 + 0.05...width / 2 - 0.05), t = rng.float(0.0...slopeLen - 0.03)
            let isLichen = i % 6 != 0
            FA.cylZ(&m, r: rng.float(0.008...0.02), h: 0.002, at: P(x, t, 0.042 + (t > 0.2 ? 0.009 : 0)), isLichen ? "paint.stucco:9AA27F" : "paint.stucco:D9D2C0", bevel: 0.0005, segments: 5)
        }
        // Chipped tile corners at the eave lip show the pale fired core.
        for i in 0..<6 {
            let x = -width / 2 + pitchX * (Float(i) * 2 + 1.5)
            FA.box(&m, V3(0.014, 0.004, 0.012), P(x, -0.03, 0.0185), "paint.stucco:E8C9A5", r: 0.0008, rot: FA.q(pitch, axisX))
        }
        // Rain-wash stains on the fascia below the eave.
        for _ in 0..<8 {
            let x = rng.float(-width / 2 + 0.05...width / 2 - 0.05)
            FA.box(&m, V3(rng.float(0.01...0.03), rng.float(0.03...0.07), 0.001), V3(x, 0.055, fz + 0.0115), "wood.deadwood", r: 0.0003)
        }
        // Soot and rain streaks on the stucco wall edge below the plaster cap, and a plaster crack.
        for _ in 0..<6 {
            let x = rng.float(-width / 2 + 0.05...width / 2 - 0.05), h = rng.float(0.05...0.12)
            FA.box(&m, V3(rng.float(0.01...0.03), h, 0.001), V3(x, 0.27 - h / 2, zBack + 0.0255), "paint.stucco:B5A685", r: 0.0003)
        }
        FA.box(&m, V3(0.003, 0.09, 0.001), V3(0.3, 0.17, zBack + 0.0255), "paint.stucco:5A4B3A", r: 0.0003, rot: FA.q(18, FA.Z))
        // Back face of the wall: damp rising stain, plaster patches and a hairline crack so the stucco reads as aged.
        let bz = zBack - 0.0255
        FA.box(&m, V3(width - 0.04, 0.05, 0.001), V3(0, 0.04, bz), "paint.stucco:BBA886", r: 0.0003)
        for (x, y, w, h): (Float, Float, Float, Float) in [(-0.6, 0.16, 0.18, 0.1), (0.45, 0.12, 0.14, 0.09), (0.05, 0.2, 0.1, 0.07)] {
            FA.box(&m, V3(w, h, 0.0012), V3(x, y, bz), "paint.stucco:A89878", r: 0.0003)
        }
        FA.box(&m, V3(0.003, 0.12, 0.001), V3(-0.25, 0.13, bz), "paint.stucco:5A4B3A", r: 0.0003, rot: FA.q(-14, FA.Z))
        groundAO(&m, height: 0.08, floor: 0.85)
        return LODModel(FA.centerZ(m))
    }
}
