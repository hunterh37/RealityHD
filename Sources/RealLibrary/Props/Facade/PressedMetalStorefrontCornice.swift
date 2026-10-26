import simd
import Foundation

/// American Commercial pressed-metal storefront cornice, 2.4 x 0.8 x 0.5 m: a galvanized sheet crown over a wood nailer with a
/// frieze carrying a central pedimented panel and brass-centred rosette, embossed swags between rosettes, a cove bed mould, twelve
/// scroll modillions and two large end consoles, an egg-and-dart ovolo, a projecting corona and a cyma top. Sheets meet at
/// standing seams; flanges are riveted. Dark green paint flakes to bare galvanized and rust at edges and rivets. Base on y = 0.
public struct PressedMetalStorefrontCornice: RealAsset {
    public static let id = "pressed-metal-storefront-cornice"
    public static let summary = "American Commercial pressed metal storefront cornice, 2.4 x 0.8 m: crown, brackets, modillions, pediment rosette, frieze swags, rivets, rust."
    public static let tags = ["prop", "architecture", "facade", "trim", "metal", "decor"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 30, elevation: 4, distance: 2.9)

    /// Run length in meters.
    public var length: Float = 2.4
    /// Dark green enamel.
    public var paint: MaterialKey = "metal.painted:3D5A49"
    /// Bare galvanized sheet.
    /// Cream highlight paint on raised ornament.
    public var hl: MaterialKey = "metal.painted:C9BB92"
    public var tin: MaterialKey = "metal.galvanized-aged"
    public var rust: MaterialKey = "metal.rust"
    public var brass: MaterialKey = "metal.brass-aged"
    public var wood: MaterialKey = "wood.trim-weathered"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let L = length
        let k: Float = 0.97
        let raw: [V2] = [V2(0, 0), V2(0.04, 0), V2(0.04, 0.3), V2(0.06, 0.31), V2(0.1, 0.34), V2(0.12, 0.4), V2(0.12, 0.5), V2(0.14, 0.51), V2(0.16, 0.55),
                         V2(0.18, 0.58), V2(0.18, 0.59), V2(0.42, 0.59), V2(0.42, 0.66), V2(0.46, 0.67), V2(0.47, 0.7), V2(0.44, 0.75), V2(0.34, 0.8), V2(0, 0.8)]
        let prof = raw.map { V2($0.x * k, $0.y) }
        let zf: Float = 0.04 * k

        // Three sheets: the centre sheet 800 mm, repainted at different dates.
        let cuts: [Float] = [-L / 2, -0.4, 0.4, L / 2]
        let tones: [MaterialKey] = ["metal.painted:36503F", paint, "metal.painted:456352"]
        for i in 0..<3 {
            let a = cuts[i], b = cuts[i + 1]
            FA.run(&m, prof, length: b - a - 0.002, at: V3((a + b) / 2, 0, 0), tones[i], bevel: 0.002)
        }
        for sx: Float in [-0.4, 0.4] {
            m.add(Prim.extrude(Shape2D.offset(prof, 0.003), depth: 0.02, bevel: 0.0015, bevelSegments: 1, material: "metal.painted:2A372F"),
                  Xform(translation: V3(sx, 0, 0), rotation: FA.q(-90, FA.Y)))
        }

        // Wood nailer rails behind the sheets.
        for y: Float in [0.1, 0.7] { FA.box(&m, V3(L - 0.02, 0.07, 0.04), V3(0, y, -0.02), wood, r: 0.003) }

        // Frieze centre: raised panel with pediment, large rosette with brass centre, flanking small rosettes.
        let fz = zf + 0.004
        FO.slab(&m, 0.84, 0.17, 0.008, V3(0, 0.14, fz), paint, bevel: 0.002)
        FO.slab(&m, 0.78, 0.13, 0.006, V3(0, 0.14, fz + 0.006), "metal.painted:456352", bevel: 0.0015)
        FO.slab(&m, 0.84, 0.012, 0.01, V3(0, 0.222, fz + 0.001), hl, bevel: 0.002)
        FO.slab(&m, 0.84, 0.012, 0.01, V3(0, 0.058, fz + 0.001), hl, bevel: 0.002)
        m.add(Prim.extrude([V2(-0.42, 0), V2(0.42, 0), V2(0, 0.075)], depth: 0.009, bevel: 0.002, bevelSegments: 1, material: hl),
              Xform(translation: V3(0, 0.225, fz)))
        func rosette(_ x: Float, _ y: Float, _ r: Float) {
            FA.cylZ(&m, r: r, h: 0.01, at: V3(x, y, zf + 0.012), hl, bevel: 0.002, segments: 18)
            m.add(Prim.torus(major: r * 0.7, minor: r * 0.12, segments: 16, sides: 5, material: hl), Xform(translation: V3(x, y, zf + 0.024), rotation: FA.q(90, FA.X)))
            for p in 0..<8 {
                let a = Float(p) / 8 * 2 * .pi
                FC.bead(&m, r: r * 0.1, at: V3(x + r * 0.84 * cos(a), y + r * 0.84 * sin(a), zf + 0.022), hl, sub: 1)
            }
            FC.bead(&m, r: r * 0.28, at: V3(x, y, zf + 0.026), brass, sub: 3)
        }
        rosette(0, 0.14, 0.062)
        for sx: Float in [-0.3, 0.3] { rosette(sx, 0.14, 0.032) }

        // Embossed swags: a garland on a catenary with a tassel bead, between small rosettes.
        for cx: Float in [-0.95, -0.62, 0.62, 0.95] {
            var pts: [V3] = []
            for i in 0...8 {
                let t = Float(i) / 8 * 2 - 1
                pts.append(V3(cx + t * 0.14, 0.22 - 0.1 * (1 - t * t), zf + 0.012))
            }
            m.add(Prim.tube(pts, radii: Array(repeating: 0.0075, count: pts.count), sides: 5, seamTile: 0.1, material: hl, capEnd: true))
            FC.bead(&m, r: 0.011, at: V3(cx, 0.115, zf + 0.012), brass, sub: 2)
            for e: Float in [-1, 1] { FC.bead(&m, r: 0.012, at: V3(cx + e * 0.145, 0.222, zf + 0.012), hl, sub: 2) }
        }

        // Egg-and-dart on the ovolo, 60 mm pitch.
        var x: Float = -L / 2 + 0.06
        while x < L / 2 - 0.04 {
            m.add(Prim.superellipsoid(V3(0.024, 0.042, 0.02), exponent: 2, subdivisions: 2, material: hl), Xform(translation: V3(x, 0.54, 0.145 * k)))
            m.add(Prim.extrude([V2(0, -0.017), V2(0.008, 0), V2(0, 0.017), V2(-0.008, 0)], depth: 0.008, bevel: 0.001, bevelSegments: 1, material: hl),
                  Xform(translation: V3(x + 0.03, 0.54, 0.139 * k)))
            x += 0.06
        }

        // Scroll modillions (12) and two large end consoles with volutes.
        let bracket: [V2] = [V2(0.11, 0.405), V2(0.14, 0.405), V2(0.22, 0.45), V2(0.32, 0.51), V2(0.39, 0.55), V2(0.41, 0.552), V2(0.41, 0.59), V2(0.11, 0.59)].map { V2($0.x * k, $0.y) }
        for i in 0..<12 {
            let mx = -1.1 + Float(i) * 0.2
            m.add(Prim.extrude(bracket, depth: 0.05, bevel: 0.0025, bevelSegments: 1, material: paint), Xform(translation: V3(mx, 0, 0), rotation: FA.q(-90, FA.Y)))
            m.add(Prim.superellipsoid(V3(0.034, 0.03, 0.022), exponent: 2, subdivisions: 2, material: hl), Xform(translation: V3(mx, 0.47, 0.25 * k)))
        }
        let console: [V2] = [V2(0.04, 0.0), V2(0.1, 0.0), V2(0.2, 0.06), V2(0.3, 0.2), V2(0.37, 0.38), V2(0.4, 0.5), V2(0.41, 0.59), V2(0.04, 0.59)].map { V2($0.x * k, $0.y) }
        for sx: Float in [-1, 1] {
            let cx = sx * (L / 2 - 0.045)
            m.add(Prim.extrude(console, depth: 0.07, bevel: 0.003, bevelSegments: 1, material: tones[sx > 0 ? 2 : 0]), Xform(translation: V3(cx, 0, 0), rotation: FA.q(-90, FA.Y)))
            // Volute on each face of the console.
            for fs: Float in [-1, 1] {
                var pts: [V3] = []
                for i in 0...12 {
                    let t = Float(i) / 12
                    let a = t * 2.9 * .pi + 0.3, r = 0.07 * (1 - 0.78 * t)
                    pts.append(V3(cx + fs * 0.037, 0.2 + r * sin(a), 0.19 + r * cos(a) * 0.9))
                }
                m.add(Prim.tube(pts, radii: Array(repeating: 0.008, count: pts.count), sides: 5, seamTile: 0.1, material: hl, capEnd: true))
                hexBolt(&m, at: V3(cx + fs * 0.035, 0.08, 0.1), normal: V3(fs, 0, 0), size: 0.012, material: rust)
            }
        }

        // Riveted flanges: rows along the frieze foot and head, plus the cove.
        for y: Float in [0.014, 0.286] {
            var nx: Float = -L / 2 + 0.12
            while nx < L / 2 - 0.1 {
                if abs(nx) > 0.46 || y < 0.1 { rivet(&m, at: V3(nx, y, zf + 0.0002), normal: FA.Z, radius: 0.0048, segments: 6, material: tin) }
                nx += 0.085
            }
        }

        // Wear: rust runs below rivets, bare galvanized scrapes on edges, soot on the soffit, paint blisters on the top.
        for _ in 0..<8 {
            let nx = rng.float(-L / 2 + 0.2...L / 2 - 0.2)
            FO.slab(&m, rng.float(0.006...0.014), rng.float(0.04...0.11), 0.0014, V3(nx, 0.09 + rng.float(-0.03...0.12), zf + 0.0004), rust, bevel: 0.0004)
        }
        for _ in 0..<10 {
            let nx = rng.float(-L / 2 + 0.2...L / 2 - 0.2)
            let yy: Float = rng.chance(0.5) ? 0.665 : 0.315
            FO.slab(&m, rng.float(0.03...0.09), rng.float(0.008...0.02), 0.0016, V3(nx, yy, yy > 0.5 ? 0.42 * k + 0.003 : zf + 0.019), rng.chance(0.5) ? tin : rust, bevel: 0.0004)
        }
        for i in 0..<11 {
            FA.box(&m, V3(0.17, 0.002, 0.22), V3(-1.0 + Float(i) * 0.2, 0.5885, 0.3 * k), "metal.painted:3F4641", r: 0.0006)
        }

        // Larger wear: rust runs from the cove down the frieze, a flaked cream undercoat on the cove and corona face, rust at the consoles.
        for _ in 0..<7 {
            let nx = rng.float(-L / 2 + 0.2...L / 2 - 0.2)
            FO.slab(&m, rng.float(0.014...0.03), rng.float(0.1...0.22), 0.0016, V3(nx, 0.2, zf + 0.0012), "metal.rust:8A4A2A", bevel: 0.0004)
        }
        for _ in 0..<10 {
            let nx = rng.float(-L / 2 + 0.2...L / 2 - 0.2)
            FO.slab(&m, rng.float(0.05...0.14), rng.float(0.02...0.05), 0.0016, V3(nx, 0.625, 0.42 * k + 0.0045), rng.chance(0.5) ? "metal.painted:B9AE8A" : tin, bevel: 0.0005)
        }
        for sx: Float in [-1, 1] {
            FO.slab(&m, 0.02, 0.12, 0.0016, V3(sx * (L / 2 - 0.06), 0.1, zf + 0.0012), "metal.rust:8A4A2A", bevel: 0.0004)
        }

        // End returns.
        for en: Float in [-1, 1] {
            m.add(Prim.extrude(prof, depth: 0.004, bevel: 0.001, bevelSegments: 1, material: paint),
                  Xform(translation: V3(en * (L / 2 + 0.002), 0, 0), rotation: FA.q(-90, FA.Y)))
        }

        groundAO(&m, height: 0.1, floor: 0.85)
        return LODModel(FC.place(m))
    }
}
