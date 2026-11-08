import simd
import Foundation

/// 1773 colonial merchant brig at 1:2 scale (Boston Tea Party type), 4.0 m beam, 5.2 m to the main truck and about
/// 14 m including bowsprit and rudder. Origin at the waterline centre, bow +Z, keel line at y = 0. The hull is lofted
/// from 67-point rings with tumblehome, a bulwark and a closed deck line, then planked with proud strakes, a tarred
/// black strake and an ochre wale. On top: deck, hatch coamings, windlass, stern cabin, two masts with yards and
/// furled square sails tied with gaskets, bowsprit, shrouds with ratlines, stays, stern windows, taffrail, rudder
/// and two brass lanterns with emissive glass.
public struct ColonialBrig: RealAsset {
    public static let id = "colonial-brig"
    public static let summary = "1773 colonial merchant brig at 1:2 scale: tumblehome planked hull, two masts with furled square sails, shrouds with ratlines, bowsprit, stern windows, rudder and lanterns."
    public static let tags = ["prop", "vehicle", "boat", "harbor", "wood", "antique"]
    public static let budget = 22000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 52, elevation: 16, distance: 1.0, studio: true)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(4.0, 5.2, 14.0)
    /// Hull body: tar-stained oak.
    public var hullDark: MaterialKey = "wood.weathered:2A2119"
    /// Black paint for the tarred strake and topsides.
    public var blackPaint: MaterialKey = "wood.painted-exterior:15120F"
    /// Ochre paint for the wale stripe.
    public var waleOchre: MaterialKey = "wood.painted-exterior:C79A3B"
    /// Deck planking.
    public var deckWood: MaterialKey = "wood.pine-aged"
    /// Spars and masts.
    public var sparWood: MaterialKey = "wood.pine-aged:8A6B45"
    /// Joinery oak (rails, coamings, windlass).
    public var oak: MaterialKey = "wood.lumber-oak"
    /// Furled sail cloth.
    public var canvas: MaterialKey = "fabric.canvas:C9BC9C"
    /// Standing and running rigging.
    public var rope: MaterialKey = "rope.hemp"
    public init() {}

    // MARK: Hull definition (u 0 stern ... 1 bow, v 0 keel ... 1 bulwark top)
    static let zS: Float = -6.3, hullLen: Float = 11.3, maxBeam: Float = 1.9
    static func z(_ u: Float) -> Float { zS + u * hullLen }
    static func beam(_ u: Float) -> Float {
        let w: Float = u < 0.4 ? 0.46 + 0.54 * sin(u / 0.4 * .pi / 2) : pow(max(0, cos((u - 0.4) / 0.6 * .pi / 2)), 0.85)
        return max(0.08, maxBeam * w)
    }
    static func sheer(_ u: Float) -> Float { 1.1 + 0.22 * pow(1 - u, 2) + 0.38 * pow(u, 3) }
    static func deckY(_ u: Float) -> Float { sheer(u) - 0.42 }
    static func ky(_ u: Float) -> Float {
        let a = max(0, (0.22 - u) / 0.22), c = max(0, (u - 0.7) / 0.3)
        return 0.3 * a * a + 0.85 * pow(c, 2.2)
    }
    static func wv(_ v: Float) -> Float {
        v < 0.45 ? pow(sin(v / 0.45 * .pi / 2), 0.55) : 1 - 0.14 * pow((v - 0.45) / 0.55, 1.6)
    }
    static func hp(_ u: Float, _ v: Float, _ side: Float, _ off: Float = 0) -> V3 {
        let k = ky(u), h = sheer(u)
        return V3(side * (beam(u) * wv(v) + off), k + v * (h - k), z(u))
    }
    static func inset(_ x: Float) -> Float { min(0.07, 0.4 * x) }
    static func innerDeckX(_ u: Float) -> Float {
        let k = ky(u), h = sheer(u)
        let x = hp(u, (deckY(u) - k) / (h - k), 1).x
        return max(0.02, x - inset(x))
    }
    /// u of a world z.
    static func u(forZ z: Float) -> Float { (z - zS) / hullLen }

    func faceOutward(_ s: inout Surface) {
        var vol: Float = 0
        for t in stride(from: 0, to: s.indices.count, by: 3) {
            let a = s.positions[Int(s.indices[t])], b = s.positions[Int(s.indices[t + 1])], c = s.positions[Int(s.indices[t + 2])]
            vol += simd_dot(a, simd_cross(b, c))
        }
        if vol < 0 { for t in stride(from: 0, to: s.indices.count, by: 3) { s.indices.swapAt(t + 1, t + 2) } }
        s.recomputeNormals(weldSeams: false)
        s.computeTangents()
    }
    func faceToward(_ s: inout Surface, _ dir: V3) {
        var sum: Float = 0
        for t in stride(from: 0, to: s.indices.count, by: 3) {
            let a = s.positions[Int(s.indices[t])], b = s.positions[Int(s.indices[t + 1])], c = s.positions[Int(s.indices[t + 2])]
            sum += simd_dot(simd_cross(b - a, c - a), dir)
        }
        if sum < 0 { for t in stride(from: 0, to: s.indices.count, by: 3) { s.indices.swapAt(t + 1, t + 2) } }
        s.recomputeNormals(weldSeams: false)
        s.computeTangents()
    }

    func line(_ pts: [V3], _ r: Float, sides: Int = 6, _ mat: MaterialKey? = nil) -> Surface {
        Prim.tube(pts, radii: pts.map { _ in r }, sides: sides, seamTile: 0.1, material: mat ?? rope, capEnd: true)
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var tone = rng.fork(1)
        let full = model(hi: true, rng: &rng, tone: &tone)
        var rng2 = SeededRNG(seed: seed)
        var tone2 = rng2.fork(1)
        let lite = model(hi: false, rng: &rng2, tone: &tone2)
        return LODModel(levels: [full, lite], switchDistances: [8])
    }

    func model(hi: Bool, rng: inout SeededRNG, tone: inout SeededRNG) -> Model {
        typealias S = ColonialBrig
        var m = Model(name: Self.id)
        let zS = S.zS

        // MARK: Hull loft
        let K = hi ? 24 : 14
        let ns = hi ? 24 : 16
        func ring(_ u: Float) -> [V3] {
            var s: [V3] = (0...K).map { S.hp(u, Float($0) / Float(K), 1) }
            let top = S.hp(u, 1, 1)
            let inTop = top.x - S.inset(top.x)
            let inDeck = S.innerDeckX(u)
            s.append(V3(inTop, top.y, top.z))
            s.append(V3((inTop + inDeck) / 2, (top.y + S.deckY(u)) / 2, top.z))
            s.append(V3(inDeck, S.deckY(u), top.z))
            let port = s.dropFirst().reversed().map { V3(-$0.x, $0.y, $0.z) }
            return s + port
        }
        let rings = (0...ns).map { ring(Float($0) / Float(ns)) }
        var hull = Prim.loft(rings, capStart: true, capEnd: true, material: hullDark)
        faceOutward(&hull)
        m.add(hull)

        // MARK: Planking strips on both sides
        func strips(_ bands: [(Float, Float)], off: Float, rows: Int, mat: MaterialKey, u0: Float = 0.012, u1: Float = 0.975) -> Surface {
            var s = Surface(material: mat)
            let nst = hi ? 16 : 10
            for side: Float in [1, -1] {
                for (v0, v1) in bands {
                    let base = UInt32(s.positions.count)
                    for i in 0...nst {
                        let u = u0 + (u1 - u0) * Float(i) / Float(nst)
                        for r in 0..<rows {
                            let v = v0 + (v1 - v0) * Float(r) / Float(rows - 1)
                            let p = S.hp(u, v, side, off)
                            s.add(p, .up, V2(p.z * side, v * 4.1 + v0 * 31))
                        }
                    }
                    let w = UInt32(rows)
                    for i in 0..<nst { for r in 0..<(rows - 1) {
                        let a = base + UInt32(i) * w + UInt32(r)
                        s.quad(a, a + 1, a + w + 1, a + w)
                    }}
                }
            }
            WoodParts.orientOutward(&s) { p in V3(0, 0.5, p.z) }
            s.recomputeNormals(weldSeams: false)
            s.computeTangents()
            return s
        }
        if hi {
            // Lower hull planks, 12 per side in two alternating tones, with seams left between them.
            var bandsA: [(Float, Float)] = [], bandsB: [(Float, Float)] = []
            for k in 0..<6 {
                let v0 = 0.05 + Float(k) * 0.0925
                if k % 2 == 0 { bandsA.append((v0, v0 + 0.08)) } else { bandsB.append((v0, v0 + 0.08)) }
            }
            m.add(strips(bandsA, off: 0.006, rows: 2, mat: "wood.pine-aged:4B3A2A"))
            m.add(strips(bandsB, off: 0.006, rows: 2, mat: "wood.weathered:3B2E23"))
            // Topside planks above the wale, tarred.
            m.add(strips([(0.795, 0.84), (0.845, 0.89), (0.895, 0.94), (0.945, 0.99)], off: 0.006, rows: 2, mat: blackPaint))
        } else {
            m.add(strips([(0.79, 0.99)], off: 0.006, rows: 2, mat: blackPaint))
        }
        m.add(strips([(0.60, 0.715)], off: 0.008, rows: 2, mat: blackPaint))
        m.add(strips([(0.725, 0.79)], off: 0.011, rows: 2, mat: waleOchre))
        if hi { m.add(strips([(0.715, 0.727), (0.788, 0.80)], off: 0.014, rows: 2, mat: "wood.lumber-oak:3A2A1A")) }

        // MARK: Deck
        let nd = hi ? 12 : 8
        var deck = Surface(material: deckWood)
        for i in 0...nd {
            let u = 0.015 + 0.955 * Float(i) / Float(nd)
            let xd = S.innerDeckX(u), y = S.deckY(u) + 0.003
            for c in 0..<5 {
                let x = xd * (Float(c) / 2 - 1)
                deck.add(V3(x, y, S.z(u)), .up, V2(S.z(u), x))
            }
        }
        for i in 0..<nd { for c in 0..<4 {
            let a = UInt32(i * 5 + c)
            deck.quad(a, a + 5, a + 6, a + 1)
        }}
        faceToward(&deck, V3(0, 1, 0))
        m.add(deck)

        func dy(_ z: Float) -> Float { S.deckY(S.u(forZ: z)) }
        func put(_ s: Surface, _ at: V3, rot: simd_quatf = .identity) { m.add(s, Xform(translation: at, rotation: rot)) }

        // MARK: Rails, rail cap, stem
        for side: Float in [1, -1] {
            let pts = (0...(hi ? 14 : 8)).map { i -> V3 in
                let u = 0.02 + 0.95 * Float(i) / Float(hi ? 14 : 8)
                let top = S.hp(u, 1, side)
                return V3(top.x - side * S.inset(abs(top.x)) * 0.5, top.y + 0.012, top.z)
            }
            m.add(Prim.sweep(Shape2D.roundedRect(0.115, 0.04, radius: 0.014, segments: 1), along: pts, up: V3(1, 0, 0),
                             grainAlongPath: true, material: oak))
        }
        let stemPath = catmull([V3(0, 0.80, 4.84), V3(0, 1.0, 4.97), V3(0, 1.26, 5.1), V3(0, 1.55, 5.3)], per: hi ? 6 : 3)
        m.add(Prim.sweep(Shape2D.roundedRect(0.1, 0.12, radius: 0.03, segments: 2), along: stemPath, up: V3(1, 0, 0),
                         scales: stemPath.indices.map { 1.1 - 0.35 * Float($0) / Float(stemPath.count - 1) }, grainAlongPath: true,
                         material: "wood.lumber-oak:5A432B"))

        // MARK: Channels and chainplates
        let masts: [(z: Float, top: Float, head: Float, yards: [(Float, Float)])] = [
            (-1.5, 5.2, 3.35, [(2.45, 3.8), (4.15, 2.7)]),
            (2.2, 4.65, 3.0, [(2.2, 3.3), (3.7, 2.4)])
        ]
        func mastPt(_ zm: Float, _ y: Float) -> V3 { V3(0, y, zm - 0.035 * (y - 0.9)) }
        for mast in masts {
            for side: Float in [1, -1] {
                let u = S.u(forZ: mast.z)
                let cx = S.hp(u, 0.8, side).x + side * 0.07
                put(Prim.roundedBox(V3(0.2, 0.045, 1.55), radius: 0.012, bevelSegments: 1, material: oak),
                    V3(cx, S.deckY(u) - 0.1, mast.z - 0.1))
            }
        }

        // MARK: Hatches
        func hatch(_ z: Float, _ w: Float, _ l: Float) {
            let y = dy(z)
            put(Prim.roundedBox(V3(w, 0.15, l), radius: 0.015, bevelSegments: 1, material: oak), V3(0, y + 0.075, z))
            put(Prim.roundedBox(V3(w - 0.12, 0.03, l - 0.12), radius: 0.008, bevelSegments: 1, material: "wood.pine-aged:6B4F33"), V3(0, y + 0.162, z))
            if hi {
                for k in 0..<0 {
                    put(Prim.roundedBox(V3(w - 0.1, 0.025, 0.04), radius: 0.008, bevelSegments: 1, material: oak),
                        V3(0, y + 0.19, z + (Float(k) - 1.5) * (l - 0.2) / 3))
                }
            }
        }
        hatch(0.4, 0.95, 1.15)
        hatch(-3.2, 0.72, 0.82)

        // MARK: Windlass
        do {
            let wz: Float = 3.55, y = dy(wz) + 0.42
            put(Prim.cylinder(radius: 0.1, height: 1.3, bevel: 0.012, segments: hi ? 28 : 14, bevelSegments: 1, seamTile: 0.3, material: oak),
                V3(0.65, y, wz), rot: simd_quatf(degrees: 90, axis: V3(0, 0, 1)))
            for sx: Float in [-1, 1] {
                put(Prim.roundedBox(V3(0.12, 0.55, 0.16), radius: 0.016, bevelSegments: 1, material: oak), V3(sx * 0.72, dy(wz) + 0.27, wz))
                put(Prim.cylinder(radius: 0.118, height: 0.05, bevel: 0.008, segments: hi ? 24 : 12, bevelSegments: 1, material: "metal.cast-iron"),
                    V3(sx * 0.3 + 0.025, y, wz), rot: simd_quatf(degrees: 90, axis: V3(0, 0, 1)))
            }
            if hi {
                for k in 0..<2 {
                    let a = Float(k) * .pi + 0.4
                    let d = V3(0, sin(a), cos(a))
                    m.add(line([V3(0, y, wz) + d * 0.08, V3(0, y, wz) + d * 0.42], 0.02, sides: 8, oak))
                }
                put(Prim.torus(major: 0.13, minor: 0.018, segments: 24, sides: 6, material: rope), V3(0.0, y + 0.0, wz), rot: simd_quatf(degrees: 90, axis: V3(0, 0, 1)))
            }
        }

        // MARK: Stern cabin, companionway
        let cabinZ: Float = -5.2
        put(Prim.roundedBox(V3(1.55, 0.55, 1.5), radius: 0.02, bevelSegments: 1, material: "wood.lumber-oak:4A3524"), V3(0, dy(cabinZ) + 0.275, cabinZ))
        put(Prim.roundedBox(V3(1.62, 0.03, 1.58), radius: 0.012, bevelSegments: 1, material: oak), V3(0, dy(cabinZ) + 0.565, cabinZ))
        put(Prim.roundedBox(V3(0.55, 0.14, 0.7), radius: 0.015, bevelSegments: 1, material: oak), V3(0, dy(cabinZ) + 0.65, cabinZ + 0.05))
        put(Prim.roundedBox(V3(0.4, 0.012, 0.52), radius: 0.004, bevelSegments: 1, material: "glass.pane"), V3(0, dy(cabinZ) + 0.725, cabinZ + 0.05))
        put(Prim.roundedBox(V3(0.72, 0.52, 0.62), radius: 0.02, bevelSegments: 1, material: "wood.lumber-oak:4A3524"), V3(0, dy(-3.9) + 0.26, -3.95))
        put(Prim.roundedBox(V3(0.6, 0.05, 0.5), radius: 0.015, bevelSegments: 1, material: oak), V3(0, dy(-3.9) + 0.545, -3.93))

        // MARK: Stern windows, taffrail, lanterns, rudder
        let tz = zS - 0.01
        for k in 0..<4 {
            let x = (Float(k) - 1.5) * 0.37
            put(Prim.roundedBox(V3(0.31, 0.27, 0.03), radius: 0.01, bevelSegments: 1, material: "wood.lumber-oak:3A2A1A"), V3(x, 0.84, tz - 0.004))
            put(Prim.roundedBox(V3(0.24, 0.2, 0.012), radius: 0.004, bevelSegments: 1, material: "glass.pane"), V3(x, 0.84, tz - 0.022))
        }
        let rx = S.beam(0) * 0.97
        let tafPts = (0...(hi ? 16 : 8)).map { i -> V3 in
            let t = Float(i) / Float(hi ? 16 : 8) * 2 - 1
            return V3(t * rx, S.sheer(0) + 0.2 + 0.05 * (1 - t * t), zS - 0.015)
        }
        m.add(Prim.sweep(Shape2D.roundedRect(0.075, 0.075, radius: 0.022, segments: 2), along: tafPts, up: V3(0, 0, 1),
                         grainAlongPath: true, material: oak))
        let bal = hi ? 4 : 3
        for k in 0..<bal {
            let t = (Float(k) + 0.5) / Float(bal) * 2 - 1
            put(Prim.roundedBox(V3(0.035, 0.2, 0.035), radius: 0.01, bevelSegments: 1, material: oak), V3(t * rx * 0.96, S.sheer(0) + 0.1, zS - 0.015))
        }
        func lantern(_ at: V3) {
            put(Prim.lathe([V2(0, 0), V2(0.065, 0), V2(0.07, 0.012), V2(0.052, 0.03), V2(0.0, 0.03)], segments: hi ? 16 : 8, material: "metal.brass-aged"), at)
            put(Prim.cylinder(radius: 0.05, height: 0.15, bevel: 0.004, segments: hi ? 20 : 12, bevelSegments: 1, material: "glass.lamp"), at + V3(0, 0.03, 0))
            if hi {
                for k in 0..<4 {
                    let a = Float(k) * .pi / 2 + .pi / 4
                    m.add(line([at + V3(cos(a) * 0.054, 0.03, sin(a) * 0.054), at + V3(cos(a) * 0.054, 0.18, sin(a) * 0.054)], 0.005, sides: 4, "metal.brass-aged"))
                }
            }
            put(Prim.lathe([V2(0.0, 0.18), V2(0.066, 0.18), V2(0.07, 0.19), V2(0.05, 0.22), V2(0.016, 0.255), V2(0.0, 0.26)], segments: hi ? 16 : 8, material: "metal.brass-aged"), at)
            put(Prim.torus(major: 0.032, minor: 0.006, segments: hi ? 12 : 8, sides: hi ? 5 : 4, material: "metal.brass-aged"), at + V3(0, 0.285, 0), rot: simd_quatf(degrees: 90, axis: V3(1, 0, 0)))
        }
        for sx: Float in [-1, 1] {
            put(Prim.roundedBox(V3(0.06, 0.4, 0.06), radius: 0.014, bevelSegments: 1, material: oak), V3(sx * rx, S.sheer(0) + 0.2, zS + 0.0))
            lantern(V3(sx * rx, S.sheer(0) + 0.4, zS))
        }
        // Rudder with iron pintle straps and tiller head.
        put(Prim.roundedBox(V3(0.09, 1.15, 0.42), radius: 0.012, bevelSegments: 1, material: "wood.lumber-oak:4A3524"), V3(0, 0.66, zS - 0.3))
        put(Prim.cylinder(radius: 0.05, height: 1.25, bevel: 0.01, segments: hi ? 24 : 10, bevelSegments: 1, material: oak), V3(0, 0.1, zS - 0.1))
        for y: Float in [0.25, 0.65, 1.05] {
            put(Prim.roundedBox(V3(0.105, 0.05, 0.4), radius: 0.008, bevelSegments: 1, material: "metal.cast-iron"), V3(0, y, zS - 0.28))
        }

        // MARK: Masts, tops, yards, furled sails
        let sidesM = hi ? 24 : 10
        for mast in masts {
            let zm = mast.z
            let lowerPts = (0...8).map { k in mastPt(zm, 0.6 + (mast.head + 0.15 - 0.6) * Float(k) / 5) }
            m.add(Prim.tube(lowerPts, radii: lowerPts.indices.map { 0.125 - 0.04 * pow(Float($0) / 5, 1.2) }, sides: sidesM, seamTile: 0.3, material: sparWood, capEnd: true))
            let topPts = (0...3).map { k in mastPt(zm, mast.head - 0.25 + (mast.top - mast.head + 0.25) * Float(k) / 3) }
            m.add(Prim.tube(topPts, radii: topPts.indices.map { 0.058 - 0.03 * Float($0) / 3 }, sides: hi ? 24 : 10, seamTile: 0.3, material: sparWood, capEnd: true))
            // Top platform with crosstrees and a brass truck.
            let head = mastPt(zm, mast.head)
            put(Prim.cylinder(radius: 0.4, height: 0.04, bevel: 0.01, segments: hi ? 20 : 12, bevelSegments: 1, material: oak), head + V3(0, -0.04, 0.0))
            for sx: Float in [-1, 1] {
                put(Prim.roundedBox(V3(0.07, 0.09, 0.8), radius: 0.012, bevelSegments: 1, material: oak), head + V3(sx * 0.07, -0.1, 0))
            }
            put(Prim.roundedBox(V3(0.8, 0.06, 0.07), radius: 0.012, bevelSegments: 1, material: oak), head + V3(0, -0.14, 0))
            put(Prim.cylinder(radius: 0.034, height: 0.05, bevel: 0.01, segments: hi ? 20 : 8, bevelSegments: 1, material: "metal.brass-aged"), mastPt(zm, mast.top - 0.01))
            // Yards and furled sails.
            for (idx, yd) in mast.yards.enumerated() {
                let (yy, span) = yd
                let c = mastPt(zm, yy) + V3(0, 0, 0.11)
                let yp = (0...6).map { k in V3(-span / 2 + span * Float(k) / 6, c.y, c.z) }
                m.add(Prim.tube(yp, radii: yp.indices.map { 0.025 + 0.03 * (1 - pow(abs(Float($0) / 3 - 1), 2)) }, sides: hi ? 16 : 8, seamTile: 0.25, material: sparWood, capEnd: true))
                // Parrel rope around the mast and topping lifts to the mast head.
                if hi {
                    for sx: Float in [-1, 1] {
                        m.add(line([V3(sx * (span / 2 - 0.05), c.y + 0.02, c.z), V3(sx * span * 0.22, (c.y + mast.head) / 2 + 0.2, c.z - 0.04), mastPt(zm, mast.head + 0.1) + V3(sx * 0.04, 0, 0.04)], 0.008, sides: 5))
                    }
                }
                // Furled sail: lumpy roll lying on the yard with two sagging lobes and gasket ties.
                let n = hi ? 12 : 8
                let half = span * 0.45
                let roll = (0...n).map { V3(-half + 2 * half * Float($0) / Float(n), c.y + 0.12, c.z + 0.025) }
                let ph = tone.float(0...6)
                let rr = roll.indices.map { i -> Float in
                    let t = Float(i) / Float(n)
                    let body: Float = 0.145 * (1 - 0.2 * pow(abs(2 * t - 1), 3)) * (idx == 1 ? 0.86 : 1)
                    return body + (hi ? 0.011 * sin(Float(i) * 2.3 + ph) + 0.006 * sin(Float(i) * 5.1 + ph * 2) : 0)
                }
                m.add(Prim.tube(roll, radii: rr, sides: hi ? 16 : 8, seamTile: 0.3, material: canvas, capEnd: true))
                if hi {
                    for (k, dz) in [(0, Float(0.09)), (1, Float(-0.1))] {
                        let lobe = (0...9).map { i -> V3 in
                            let t = Float(i) / 9
                            return V3(-half * 0.92 + 2 * half * 0.92 * t, c.y + 0.07 - 0.03 * sin(t * .pi), c.z + dz + 0.025)
                        }
                        m.add(Prim.tube(lobe, radii: lobe.indices.map { 0.075 + 0.012 * sin(Float($0) * 1.9 + Float(k) * 2 + ph) - 0.025 * pow(abs(Float($0) / 4.5 - 1), 3) }, sides: 8, seamTile: 0.3, material: canvas, capEnd: true))
                    }
                    let ties = 2
                    for k in 0..<ties {
                        let t = (Float(k) + 0.5) / Float(ties)
                        put(Prim.torus(major: 0.152, minor: 0.011, segments: 14, sides: 4, material: rope),
                            V3(-half + 2 * half * t, c.y + 0.12, c.z + 0.025), rot: simd_quatf(degrees: 90, axis: V3(0, 0, 1)))
                    }
                }
            }
            // Shrouds with ratlines, 4 per side.
            for side: Float in [1, -1] {
                let u = S.u(forZ: zm)
                let ch = S.hp(u, 0.8, side).x + side * 0.06
                var shroud: [[V3]] = []
                for i in 0..<4 {
                    let a = V3(ch + side * 0.02, S.deckY(u) - 0.06, zm - 0.45 + Float(i) * 0.3)
                    let b = mastPt(zm, mast.head - 0.02) + V3(side * 0.1, 0, (Float(i) - 1.5) * 0.05)
                    let pts = (0...(hi ? 3 : 2)).map { k -> V3 in
                        let t = Float(k) / Float(hi ? 3 : 2)
                        return simd_mix(a, b, V3(repeating: t)) + V3(side * 0.012 * sin(t * .pi), 0, 0)
                    }
                    shroud.append(pts)
                    m.add(line(pts, 0.012, sides: hi ? 6 : 4))
                    if hi {
                        m.add(line([V3(ch + side * 0.04, S.deckY(u) - 0.05, a.z), V3(ch + side * 0.045, S.deckY(u) - 0.3, a.z)], 0.011, sides: 4, "metal.cast-iron"))
                    }
                }
                if hi {
                    for j in 0..<8 {
                        let t = 0.13 + Float(j) * 0.105
                        let rp = (0..<4).map { i -> V3 in simd_mix(shroud[i].first!, shroud[i].last!, V3(repeating: t)) }
                        m.add(line(rp, 0.0065, sides: 4))
                    }
                }
            }
        }

        // MARK: Bowsprit, stays, bobstay
        let spritPts = (0...(hi ? 6 : 4)).map { k -> V3 in
            let t = Float(k) / Float(hi ? 6 : 4)
            return V3(0, 0.95 + 1.05 * t, 3.5 + 3.4 * t)
        }
        m.add(Prim.tube(spritPts, radii: spritPts.indices.map { 0.105 - 0.065 * Float($0) / Float(spritPts.count - 1) }, sides: hi ? 28 : 12, seamTile: 0.3, material: sparWood, capEnd: true))
        put(Prim.cylinder(radius: 0.05, height: 0.04, bevel: 0.01, segments: hi ? 20 : 8, bevelSegments: 1, material: "metal.cast-iron"), spritPts.last! + V3(0, -0.01, 0))
        func stay(_ a: V3, _ b: V3, sag: Float, r: Float = 0.014) {
            let n = hi ? 5 : 3
            let pts = (0...n).map { k -> V3 in
                let t = Float(k) / Float(n)
                return simd_mix(a, b, V3(repeating: t)) - V3(0, sag * 4 * t * (1 - t), 0)
            }
            m.add(line(pts, r, sides: hi ? 6 : 4))
        }
        let mainHead = mastPt(-1.5, 3.35), foreHead = mastPt(2.2, 3.0)
        stay(mainHead + V3(0, 0.1, 0.1), foreHead + V3(0, 0.1, -0.1), sag: 0.06)
        stay(foreHead + V3(0, 0.1, 0.1), spritPts.last! + V3(0, 0.02, -0.04), sag: 0.12)
        stay(mastPt(2.2, 4.45), spritPts[spritPts.count - 2] + V3(0, 0.04, 0), sag: 0.1, r: 0.011)
        stay(spritPts.last! + V3(0, -0.04, 0), V3(0, 0.88, 4.9), sag: 0.02, r: 0.018)
        for side: Float in [1, -1] {
            stay(mainHead + V3(side * 0.1, 0.05, -0.05), V3(side * 0.95, S.sheer(0.1) - 0.05, -5.65), sag: 0.05)
            stay(foreHead + V3(side * 0.1, 0.05, -0.05), V3(side * 1.4, S.deckY(0.5) + 0.5, -0.2), sag: 0.04, r: 0.012)
        }

        // Rope coils on deck.
        if hi {
            for (cz, cx) in [(Float(-2.2), Float(0.9))] {
                put(Prim.torus(major: 0.13, minor: 0.024, segments: 16, sides: 5, material: rope), V3(cx, dy(cz) + 0.03, cz))
                put(Prim.torus(major: 0.09, minor: 0.024, segments: 14, sides: 5, material: rope), V3(cx, dy(cz) + 0.075, cz))
            }
        }

        groundAO(&m)
        return m
    }
}
