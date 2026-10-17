import simd
import Foundation

/// Archery target butt and stand: World Archery 122 cm face (rings 6.1 cm wide: 10/9 gold, 8/7 red, 6/5 blue, 4/3 black, 2/1 white), arrow-worn centre, on a wood easel. Face normal +Z, face centre at y = 1.30. Parts: straw boss, target face, gold ring, red ring, blue ring, black ring, white ring, stand legs, brace bar, retaining straps.
public struct ArcheryTarget: RealAsset {
    public static let id = "archery-target"
    public static let summary = "Archery target: 122 cm ten-ring face on a coiled-straw boss, braced on a wooden A-frame stand."
    public static let tags = ["prop", "archery", "sports", "outdoor", "wood"]
    public static let budget = 14500
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 0, elevation: 8, distance: 1.3)

    /// Overall size in meters (x width, y height, z depth).
    public var size = V3(1.39, 2.0, 0.665)
    /// Height of the face centre above ground.
    public var faceCenterY: Float = 1.30
    /// Face radius (122 cm face).
    public var faceRadius: Float = 0.61
    /// Boss thickness.
    public var bossThickness: Float = 0.13
    /// Number of arrow holes in the worn cluster.
    public var holeCount = 18
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let cy = faceCenterY, R = faceRadius, T = bossThickness
        let ringW = R / 10
        let bossR: Float = 0.652
        let toZ = simd_quatf(angle: .pi / 2, axis: V3(1, 0, 0))   // lathe +Y -> +Z
        let wood: MaterialKey = "wood.pine-aged"
        let steel: MaterialKey = "metal.galvanized-aged"

        // Straw boss: coiled rope of straw, concentric ridges on the back, step at the face margin.
        var prof: [V2] = [V2(0, -T)]
        var r: Float = 0.02
        while r < bossR - 0.05 { prof.append(V2(r, -T + 0.0025 * 1)); r += 0.045 }
        prof += [V2(bossR - 0.012, -T), V2(bossR - 0.003, -T + 0.012), V2(bossR + 0.001, -T + 0.04),
                 V2(bossR + 0.002, -0.04), V2(bossR - 0.001, -0.014), V2(bossR - 0.012, -0.002),
                 V2(R + 0.012, 0), V2(0, 0)]
        var boss = Prim.lathe(prof, segments: 64, seamTile: 0.4, material: "straw.hay")
        boss.displace { p, n in 0.0011 * Float(sin(Double(atan2(p.z, p.x)) * 23 + Double(p.y) * 150)) }
        m.add(boss, Xform(translation: V3(0, cy, 0), rotation: toZ))
        // Spiral stitching: a tape/cord helix on the back face and one ring on the front margin.
        var sp: [V3] = []
        let steps = 18 * 14
        for i in 0...steps {
            let t = Float(i) / Float(steps)
            let rr = 0.04 + t * (bossR - 0.07)
            let a = t * 13.4 * 2 * .pi
            sp.append(V3(rr * cos(a), cy + rr * sin(a), -T - 0.0012))
        }
        m.add(Prim.tube(sp, radii: sp.map { _ in 0.0032 }, sides: 3, seamTile: 0.02, material: "fabric.canvas:6E5C3A", capEnd: true))
        // Stitches across the barrel every 20 cm of rim.
        for k in 0..<22 {
            let a = Float(k) / 22 * 2 * .pi + rng.float(-0.02...0.02)
            let c = V3(bossR * cos(a), cy + bossR * sin(a), -T / 2)
            m.add(Prim.tube([c + V3(0, 0, -0.06) , c + V3(0, 0, 0.06)], radii: [0.0022, 0.0022], sides: 4, seamTile: 0.02,
                            material: "fabric.canvas:6E5C3A", capEnd: true),
                  Xform(translation: V3(0.0015 * cos(a), 0.0015 * sin(a), 0)))
        }
        // Loose straw wisps on the rim.
        for k in 0..<30 {
            var w = rng.fork(100 + k)
            let a = w.float(0...(2 * .pi)), z = w.float(-T...0.0)
            let base = V3(bossR * cos(a), cy + bossR * sin(a), z)
            let out = V3(cos(a), sin(a), 0)
            let dir = simd_normalize(out * 0.5 + V3(w.float(-0.5...0.5), w.float(-0.5...0.5), w.float(-0.6...0.6)))
            let len = w.float(0.03...0.09)
            m.add(Prim.tube([base - out * 0.004, base + dir * len * 0.6 + V3(0, -0.01, 0), base + dir * len + V3(0, -0.025, 0)],
                            radii: [0.0013, 0.0011, 0.0004], sides: 4, seamTile: 0.02, material: "straw.hay", capEnd: true))
        }

        // Face: stacked concentric discs (outer white first), each 0.7 mm above the last.
        let bands: [(MaterialKey, Int)] = [("paper.sheet:D9D3C0", 10), ("paper.sheet:2B2A29", 8), ("paper.sheet:2F6C9C", 6),
                                           ("paper.sheet:B02A25", 4), ("paper.sheet:E2B52E", 2)]
        func disc(_ rad: Float, _ z: Float, _ mat: MaterialKey, seg: Int = 72) {
            let s = Prim.lathe([V2(0, 0), V2(rad - 0.0004, 0), V2(rad, -0.0004)], segments: seg, seamTile: 0.3, material: mat).flipped()
            m.add(s, Xform(translation: V3(0, cy, z), rotation: toZ))
        }
        for (i, b) in bands.enumerated() {
            disc(ringW * Float(b.1), 0.0042 + Float(i) * 0.0007, b.0, seg: 72)
        }
        // Ring boundary lines.
        let lineZ: Float = 0.0042 + 4 * 0.0007 + 0.0004
        for k in 1...10 {
            let rr = ringW * Float(k)
            let col: MaterialKey = (k >= 6 && k <= 8) ? "paper.sheet:E4DFD0" : "paper.sheet:1B1A19"
            let hw: Float = 0.0006
            let z = 0.0042 + Float(bands.count - 1 - max(0, (k - 1) / 2)) * 0.0007 + 0.0004
            let ln = Prim.lathe([V2(rr - hw, 0), V2(rr + hw, 0)], segments: 72, seamTile: 0.3, material: col).flipped()
            m.add(ln, Xform(translation: V3(0, cy, max(z, 0.0042 + 0.0004 + Float(4 - (k - 1) / 2) * 0.0007)), rotation: toZ))
        }
        // Centre dot.
        disc(0.004, lineZ + 0.0004, "paper.sheet:1B1A19", seg: 16)
        // Arrow holes: torn paper ring, dark hole, concentrated near the gold and offset low-right.
        let topZ: Float = 0.0042 + 4 * 0.0007 + 0.0012
        for k in 0..<holeCount {
            var h = rng.fork(300 + k)
            let q = h.inDisc(radius: 1)
            let c = V2(0.035 + q.x * 0.11 * (h.chance(0.3) ? 2.2 : 1), -0.045 + q.y * 0.10 * (h.chance(0.3) ? 2.2 : 1))
            let hr = h.float(0.0045...0.0075)
            m.add(Prim.lathe([V2(0, 0), V2(hr * 1.9, 0)], segments: 7, seamTile: 0.2,
                             material: "paper.sheet:CFC5A8").flipped(),
                  Xform(translation: V3(c.x, cy + c.y, topZ + Float(k) * 0.00002), rotation: toZ))
            m.add(Prim.lathe([V2(0, 0), V2(hr, 0)], segments: 7, seamTile: 0.2,
                             material: "paper.sheet:1A130C").flipped(),
                  Xform(translation: V3(c.x, cy + c.y, topZ + 0.0003 + Float(k) * 0.00002), rotation: toZ))
        }
        // Face pins.
        for k in 0..<4 {
            let a = Float(k) * .pi / 2 + .pi / 4
            m.add(Prim.cylinder(radius: 0.006, height: 0.0018, bevel: 0.0004, segments: 8, material: steel), Xform(translation: V3(0.575 * cos(a), cy + 0.575 * sin(a), topZ), rotation: toZ))
        }

        // Easel. Uprights behind the boss, rear legs raking back, ledge under the boss, rear brace.
        let wdt: Float = 0.09, thk: Float = 0.045
        func add(_ a: V3, _ b: V3, up: V3 = .up, w: Float = wdt, t: Float = thk) {
            let (s, x) = board(from: a, to: b, width: w, thick: t, up: up, bevel: 0.004, material: wood)
            m.add(s, x.jittered(&rng))
        }
        let zU: Float = -T - thk / 2 - 0.003
        for sx: Float in [-1, 1] {
            add(V3(sx * 0.50, 0, zU), V3(sx * 0.50, 1.62, zU), up: V3(0, 0, 1))
            add(V3(sx * 0.44, 1.56, zU - thk - 0.002), V3(sx * 0.60, 0.0, -0.58), up: V3(1, 0, 0), w: 0.085, t: 0.042)
        }
        // Top cross bar tying uprights (behind boss) and the ledge carrying the boss.
        add(V3(-0.52, 1.50, zU - 0.0), V3(0.52, 1.50, zU), up: V3(0, 0, 1), w: 0.08)
        add(V3(-0.60, 0.627, -T / 2 - 0.01), V3(0.60, 0.627, -T / 2 - 0.01), up: .up, w: 0.11, t: 0.045)
        // Lower stretcher between the uprights and the rear brace bar between the legs.
        add(V3(-0.52, 0.30, zU), V3(0.52, 0.30, zU), up: V3(0, 0, 1), w: 0.08)
        let lt: Float = (1.56 - 0.50) / 1.56
        let braceX: Float = 0.44 + 0.16 * lt, braceZ: Float = zU - thk - 0.002 + (-0.58 - (zU - thk - 0.002)) * lt
        add(V3(-braceX, 0.50, braceZ + 0.0), V3(braceX, 0.50, braceZ + 0.0), up: V3(0, 0, 1), w: 0.07, t: 0.04)
        // Diagonal brace from the rear bar up to the upright.
        add(V3(0.0, 0.5, braceZ), V3(0.0, 1.50, zU - thk - 0.002), up: V3(1, 0, 0), w: 0.07, t: 0.04)
        // Bolts at the pivot, and a bolt through the ledge.
        for sx: Float in [-1, 1] {
            m.add(Prim.cylinder(radius: 0.012, height: 0.003, bevel: 0.0005, segments: 8, material: steel), Xform(translation: V3(sx * 0.44, 1.56, zU - thk - 0.002 - 0.0215), rotation: facing(V3(0, 0, -1))))
            m.add(Prim.cylinder(radius: 0.01, height: 0.003, bevel: 0.0005, segments: 8, material: steel), Xform(translation: V3(sx * 0.50, 0.30, zU + 0.0235), rotation: facing(V3(0, 0, 1))))
        }

        // Retaining straps: canvas webbing over the top rim, buckled to the rear legs.
        for sx: Float in [-0.40, 0.40] {
            let top = cy + sqrt(bossR * bossR - sx * sx)
            let pts: [V3] = [V3(sx, top - 0.03, 0.0035), V3(sx, top - 0.004, 0.0035), V3(sx, top + 0.004, -0.002),
                             V3(sx, top + 0.004, -0.04), V3(sx, top + 0.004, -T + 0.01), V3(sx, top - 0.01, -T - 0.004),
                             V3(sx, top - 0.14, -T - 0.004)]
            let path = catmull(pts, per: 2)
            m.add(Prim.sweep(Shape2D.roundedRect(0.045, 0.004, radius: 0.001), along: path, up: V3(1, 0, 0),
                             material: "fabric.canvas:5E5A44"))
            m.add(HuntKit.box(V3(sx, top - 0.12, -T - 0.009), V3(0.05, 0.03, 0.006), r: 0.0015, steel))
        }
        groundAO(&m)
        // Center on X/Z (asset contract); the scene offsets z by -0.288 to put the face on its mark.
        m.surfaces = m.surfaces.map { $0.transformed(Xform(translation: V3(0, 0, 0.288))) }
        return LODModel(m)
    }
}
