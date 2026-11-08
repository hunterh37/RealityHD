import simd
import Foundation

/// Full-size 4/4 violin lying on its back, 59.5 cm long, body 35.6 cm, lower bout 20.5 cm: arched spruce top and
/// flamed maple back under amber oil varnish, maple ribs, inlaid purfling, f-holes, maple bridge, ebony
/// fingerboard, tailpiece, pegs and chinrest, carved scroll, four strings. The bow lies alongside as its own
/// part ("bow", entity `joint:bow`): pernambuco stick, ebony frog, ivory-white horsehair ribbon. States "rest"
/// and "drawn" (bow slid 0.25 m).
public struct Violin: RealArticulated {
    public static let id = "violin"
    public static let summary = "4/4 violin, 59.5 cm: arched varnished spruce top, maple back, f-holes, ebony fittings, scroll, 4 strings, chinrest, separate bow part with horsehair."
    public static let tags = ["prop", "interior", "music", "wood", "instrument", "handheld", "articulated"]
    public static let budget = 15_000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 24, elevation: 52, distance: 0.8, studio: true)

    public var top: MaterialKey = "wood.mahogany:A8581E"
    public var back: MaterialKey = "wood.mahogany:8A3E16"
    public var ebony: MaterialKey = "wood.walnut:141110"
    public var maple: MaterialKey = "wood.maple-natural"
    /// Varnished flamed maple (neck, scroll, ribs).
    public var flame: MaterialKey = "wood.mahogany:9A4A1A"
    public var string: MaterialKey = "metal.nickel"
    public var hair: MaterialKey = "fabric.bowstring:EDE6D4"
    public var stick: MaterialKey = "wood.mahogany:5A2412"
    public init() {}

    // Body plan: z from -0.178 (neck end) to +0.178 (tail end); half width by u in 0...1.
    private static let bodyL: Float = 0.356
    private static func halfWidth(_ u: Float) -> Float {
        let keys: [(Float, Float)] = [(0, 0.096), (0.27, 0.096), (0.42, 0.062), (0.5, 0.055), (0.58, 0.064), (0.72, 0.114), (1, 0.114)]
        var g = keys.last!.1
        for i in 0..<(keys.count - 1) where u >= keys[i].0 && u <= keys[i + 1].0 {
            let t = (u - keys[i].0) / (keys[i + 1].0 - keys[i].0)
            let s = t * t * (3 - 2 * t)
            g = keys[i].1 + (keys[i + 1].1 - keys[i].1) * s
        }
        return 2 * sqrt(max(0, u * (1 - u))) * g
    }
    private static func uOf(_ z: Float) -> Float { (z + bodyL / 2) / bodyL }
    /// Plan outline (x, z) going around: right side neck-to-tail, then left side back.
    private static func outline(_ n: Int = 72, shrink: Float = 0) -> [V2] {
        var r: [V2] = [], l: [V2] = []
        for k in 0...n {
            let t = Float(k) / Float(n)
            let u = 0.5 - 0.5 * cos(t * .pi)
            let z = -bodyL / 2 + u * bodyL
            let w = max(0, halfWidth(u) - shrink)
            r.append(V2(w, z)); if k > 0 && k < n { l.append(V2(-w, z)) }
        }
        return r + l.reversed()
    }
    /// Arch height of a plate at (x, z), 0 at the edge.
    private static func arch(_ x: Float, _ z: Float, _ a: Float) -> Float {
        let u = max(0, min(1, uOf(z))), w = max(0.004, halfWidth(u))
        let cross = pow(max(0, 1 - pow(abs(x) / w, 2)), 0.7)
        return a * cross * pow(max(0, sin(u * .pi)), 0.3)
    }

    /// Domed plate: radial grid from the center to the outline, edge skirt `thick` deep. `dir` +1 top, -1 back.
    private static func plate(y: Float, archH: Float, thick: Float, dir: Float, material: MaterialKey) -> Surface {
        var s = Surface(material: material)
        let o = outline(40, shrink: -0.0015)
        let rings = 6, n = o.count
        var idx: [[UInt32]] = []
        for k in 0...rings {
            let t = Float(k) / Float(rings)
            var row: [UInt32] = []
            for i in 0...n {
                let p = o[i % n] * t
                let h = y + dir * (arch(p.x, p.y, archH) + thick)
                row.append(s.add(V3(p.x, h, p.y), V3(0, dir, 0), V2(p.y, p.x)))
            }
            idx.append(row)
        }
        // Skirt down to the rib line.
        var skirt: [UInt32] = []
        for i in 0...n { let p = o[i % n]; skirt.append(s.add(V3(p.x, y, p.y), V3(p.x, 0, p.y), V2(Float(i) * 0.004, 0))) }
        idx.append(skirt)
        func q(_ a: UInt32, _ b: UInt32, _ c: UInt32, _ d: UInt32) {
            let pa = s.positions[Int(a)], pb = s.positions[Int(b)], pc = s.positions[Int(c)]
            var nn = simd_cross(pb - pa, pc - pa)
            if simd_length(nn) < 1e-12 { let pd = s.positions[Int(d)]; nn = simd_cross(pc - pa, pd - pa) }
            let want = V3(pa.x, 0, pa.z) * 0.2 + V3(0, dir, 0)
            if simd_dot(nn, want) >= 0 { s.quad(a, b, c, d) } else { s.quad(a, d, c, b) }
        }
        for k in 0..<(idx.count - 1) { for i in 0..<n { q(idx[k][i], idx[k + 1][i], idx[k + 1][i + 1], idx[k][i + 1]) } }
        s.recomputeNormals()
        s.computeTangents()
        return s
    }

    public func rig(seed: UInt64) -> Rig {
        var rng = SeededRNG(seed: seed)
        var rig = Rig(name: Self.id)
        var m = Model(name: Self.id)
        let flat = simd_quatf(degrees: -90, axis: V3(1, 0, 0))
        let backA: Float = 0.014, topA: Float = 0.016, ribH: Float = 0.031
        let yB = backA + 0.004, yT = yB + ribH
        // Ribs: extruded outline (plan y = -z after the flat turn, so feed mirrored z).
        let ribOutline = Self.outline(40, shrink: 0.002).map { V2($0.x, -$0.y) }
        m.add(Prim.extrude(ribOutline, depth: ribH, bevel: 0.001, bevelSegments: 2, material: flame), Xform(translation: V3(0, yB + ribH / 2, 0), rotation: flat))
        m.add(Self.plate(y: yT, archH: topA, thick: 0.003, dir: 1, material: top))
        m.add(Self.plate(y: yB, archH: backA, thick: 0.003, dir: -1, material: back))
        // Purfling: black line 4 mm in from the edge on the top.
        let pur = Self.outline(40, shrink: 0.0045)
        var pPath = pur.map { V3($0.x, yT + 0.003 + Self.arch($0.x, $0.y, topA) + 0.0001, $0.y) }
        pPath.append(pPath[0])
        m.add(Prim.tube(pPath, radii: pPath.map { _ in 0.0006 }, sides: 6, seamTile: 0.05, material: ebony))
        // F-holes: S curves with round eyes, black voids slightly proud of the varnish.
        for sx: Float in [-1, 1] {
            var path: [V3] = []
            for k in 0...20 {
                let t = Float(k) / 20
                let z = -0.035 + t * 0.075
                let x = sx * (0.043 + 0.008 * sin((t - 0.5) * .pi) - 0.004 * sin(t * 2 * .pi))
                path.append(V3(x, yT + 0.003 + Self.arch(x, z, topA) + 0.0002, z))
            }
            var f = Prim.tube(path, radii: path.indices.map { i in 0.0016 + 0.001 * sin(Float(i) / 20 * .pi) }, sides: 8, seamTile: 0.02, material: "plastic.matte:050403")
            f.deform { p in V3(p.x, p.y, p.z) }
            m.add(f)
            for e in [path.first!, path.last!] {
                m.add(Prim.cylinder(radius: 0.0028, height: 0.0006, bevel: 0.0002, segments: 16, bevelSegments: 1, material: "plastic.matte:050403"), Xform(translation: e))
            }
        }
        // Bridge between the f-hole notches.
        let bz: Float = 0.006, bTop = yT + 0.003 + topA + 0.033
        let bridgeO: [V2] = Shape2D.rounded([V2(-0.0205, 0), V2(0.0205, 0), V2(0.019, 0.012), V2(0.0175, 0.033), V2(0, 0.0345), V2(-0.0175, 0.033), V2(-0.019, 0.012)], radius: 0.003, segments: 4)
        m.add(Prim.extrude(bridgeO, depth: 0.0035, bevel: 0.0008, bevelSegments: 2, material: maple), Xform(translation: V3(0, yT + 0.003 + topA - 0.0005, bz)))
        // Neck, fingerboard, pegbox, scroll (toward -Z).
        let neckZ0: Float = -Self.bodyL / 2 + 0.004, neckLen: Float = 0.13
        var neck = Prim.superellipsoid(V3(0.026, 0.026, neckLen + 0.01), exponent: 2.6, subdivisions: 6, material: flame)
        neck.deform { p in V3(p.x * (1 - 0.12 * (-(p.z) / neckLen + 0.5)), p.y, p.z) }
        m.add(neck, Xform(translation: V3(0, yT + 0.004, neckZ0 - neckLen / 2)))
        let fbLen: Float = 0.27
        var fb = Prim.roundedBox(V3(0.034, 0.006, fbLen), radius: 0.002, bevelSegments: 2, material: ebony)
        fb.deform { p in
            let t = (p.z + fbLen / 2) / fbLen
            let w = 0.0115 + 0.0105 * t
            return V3(p.x / 0.017 * w, p.y + 0.0018 * (1 - pow(p.x / 0.017, 2)), p.z)
        }
        let fbZ = neckZ0 - neckLen + fbLen / 2
        m.add(fb, Xform(translation: V3(0, yT + 0.019 + 0.008 * (fbZ / 0.2), fbZ), rotation: simd_quatf(degrees: -2.2, axis: V3(1, 0, 0))))
        let headZ = neckZ0 - neckLen
        m.add(Prim.roundedBox(V3(0.024, 0.032, 0.07), radius: 0.006, bevelSegments: 2, material: flame), Xform(translation: V3(0, yT + 0.008, headZ - 0.035)))
        m.add(Prim.roundedBox(V3(0.026, 0.004, 0.006), radius: 0.001, bevelSegments: 2, material: ebony), Xform(translation: V3(0, yT + 0.022, headZ + 0.002)))
        // Scroll: spiral volute on both cheeks.
        for sx: Float in [-1, 1] {
            var path: [V3] = [], rr: [Float] = []
            for k in 0...18 {
                let t = Float(k) / 18
                let a = t * 2.6 * .pi, r = 0.019 * (1 - 0.8 * t)
                path.append(V3(sx * (0.006 - 0.003 * t), yT + 0.012 + r * sin(a), headZ - 0.085 - r * cos(a)))
                rr.append(0.0062 * (1 - 0.6 * t))
            }
            m.add(Prim.tube(path, radii: rr, sides: 12, seamTile: 0.04, material: flame))
        }
        // Pegs: two per side through the pegbox, ebony.
        for (i, sx) in [(0, Float(-1)), (1, 1), (2, -1), (3, 1)] {
            let z = headZ - 0.014 - Float(i) * 0.015
            m.add(Prim.cylinder(radius: 0.004, height: 0.05, bevel: 0.001, segments: 20, bevelSegments: 1, material: ebony),
                  Xform(translation: V3(sx * 0.02, yT + 0.01, z), rotation: simd_quatf(degrees: 90, axis: V3(0, 0, 1))))
            m.add(Prim.superellipsoid(V3(0.004, 0.022, 0.017), exponent: 2.4, subdivisions: 4, material: ebony), Xform(translation: V3(sx * 0.047, yT + 0.01, z)))
        }
        // Tailpiece, saddle, endpin, chinrest (left of the tailpiece).
        let tailZ = Self.bodyL / 2
        let tpO = Shape2D.rounded([V2(-0.0205, 0), V2(0.0205, 0), V2(0.012, 0.11), V2(-0.012, 0.11)], radius: 0.006, segments: 5).map { V2($0.x, $0.y) }
        m.add(Prim.extrude(tpO, depth: 0.006, bevel: 0.0018, bevelSegments: 2, material: ebony), Xform(translation: V3(0, yT + 0.003 + 0.012, tailZ - 0.11 - 0.006), rotation: simd_quatf(degrees: 90 - 4, axis: V3(1, 0, 0))))
        m.add(Prim.cylinder(radius: 0.0045, height: 0.012, bevel: 0.0015, segments: 32, bevelSegments: 2, material: ebony), Xform(translation: V3(0, yB + ribH / 2, tailZ + 0.004), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        m.add(Prim.superellipsoid(V3(0.0085, 0.0085, 0.0085), exponent: 2, subdivisions: 5, material: ebony), Xform(translation: V3(0, yB + ribH / 2, tailZ + 0.013)))
        var chin = Prim.superellipsoid(V3(0.058, 0.011, 0.04), exponent: 2.4, subdivisions: 5, material: ebony)
        chin.deform { p in V3(p.x, p.y - 0.25 * pow(max(0, -p.x / 0.0375), 2) * 0.008 + 0.004 * pow(p.z / 0.025, 2), p.z) }
        m.add(chin, Xform(translation: V3(-0.034, yT + 0.003 + Self.arch(-0.034, tailZ - 0.04, topA) + 0.009, tailZ - 0.04)))
        // Strings: tailpiece -> bridge -> nut -> pegbox.
        for i in 0..<4 {
            let x = (Float(i) - 1.5) * 0.0068, xn = (Float(i) - 1.5) * 0.0042
            let p0 = V3(x * 0.9, yT + 0.003 + 0.02, tailZ - 0.1)
            let p1 = V3(x, bTop + 0.0006, bz)
            let p2 = V3(xn, yT + 0.025, headZ + 0.002)
            let p3 = V3(xn * 0.6, yT + 0.014, headZ - 0.014 - Float(i) * 0.015)
            let r: Float = [0.00042, 0.00034, 0.00030, 0.00026][3 - i] * 1.3
            m.add(Prim.tube([p0, p1, p2, p3], radii: [r, r, r, r], sides: 8, seamTile: 0.02, material: i == 0 ? "metal.brass-aged" : string))
        }
        rig.base[0].add(m)
        // Bow alongside, its own part.
        rig.part("bow", pivot: V3(0.16, 0, 0), joint: .slide(axis: V3(0, 0, 1), 0...0.25, duration: 0.8))
        let bowL: Float = 0.745, bx: Float = 0.165, z0: Float = -bowL / 2 + 0.06
        var sp: [V3] = [], sr: [Float] = []
        for k in 0...20 {
            let t = Float(k) / 20
            sp.append(V3(bx, 0.022 - 0.008 * sin(t * .pi), z0 + t * bowL)); sr.append(0.0043 - 0.0016 * t)
        }
        rig.add(Prim.tube(sp, radii: sr, sides: 12, seamTile: 0.06, material: stick), to: "bow")
        // Head (tip) and frog with silver ferrule and adjuster.
        rig.add(Prim.roundedBox(V3(0.007, 0.024, 0.014), radius: 0.003, bevelSegments: 2, material: stick), Xform(translation: V3(bx, 0.014, sp.last!.z)), to: "bow")
        rig.add(Prim.roundedBox(V3(0.0075, 0.003, 0.012), radius: 0.001, bevelSegments: 2, material: "plastic.white:EFE8D8"), Xform(translation: V3(bx, 0.0025, sp.last!.z)), to: "bow")
        rig.add(Prim.roundedBox(V3(0.012, 0.024, 0.045), radius: 0.004, bevelSegments: 2, material: ebony), Xform(translation: V3(bx, 0.01, z0 + 0.03)), to: "bow")
        rig.add(Prim.cylinder(radius: 0.0062, height: 0.006, bevel: 0.001, segments: 32, bevelSegments: 2, material: "metal.nickel"), Xform(translation: V3(bx, 0.0105, z0 + 0.054), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))), to: "bow")
        rig.add(Prim.cylinder(radius: 0.0045, height: 0.022, bevel: 0.0012, segments: 32, bevelSegments: 2, material: ebony), Xform(translation: V3(bx, 0.022, z0 - 0.01), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))), to: "bow")
        rig.add(Prim.cylinder(radius: 0.0046, height: 0.02, bevel: 0.0005, segments: 32, bevelSegments: 1, material: "metal.nickel"), Xform(translation: V3(bx, 0.022, z0 + 0.075), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))), to: "bow")
        // Horsehair ribbon: 10 mm flat band from frog to tip.
        let hz0 = z0 + 0.055, hz1 = sp.last!.z - 0.004
        var ribbon = Prim.roundedBox(V3(0.0105, 0.0011, hz1 - hz0), radius: 0.0004, bevelSegments: 1, material: hair)
        ribbon.deform { p in V3(p.x + 0.00015 * sin(p.z * 900), p.y, p.z) }
        rig.add(ribbon, Xform(translation: V3(bx, 0.0016, (hz0 + hz1) / 2)), to: "bow")
        _ = rng.float(0...1)
        rig.states = [RigState("rest"), RigState("drawn", ["bow": 0.25])]
        groundAO(&rig, height: 0.03, floor: 0.6)
        return rig
    }
}
