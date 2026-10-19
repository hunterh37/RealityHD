import simd
import Foundation

/// Air-cooled screw chiller, 10 x 2.8 x 2.4 m: off-white painted casing on a steel skid, compressor enclosure with doors
/// and nameplate at the -X end, louvered condenser coil sides, four fans with guards on the deck, insulated chilled water
/// nozzles with victaulic flanges on the -X end, and rain streaks under the deck lip and louver frames.
public struct ChillerUnit: RealAsset {
    public static let id = "chiller-unit"
    public static let summary = "Air-cooled chiller: off-white casing, louvered condenser coils, top fans, compressor enclosure, insulated water nozzles, nameplate."
    public static let tags = ["prop", "datacenter", "metal", "cooling"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 20, distance: 1.0, studio: true)

    public var paint: MaterialKey = "metal.painted:E9E9E4"
    public var skid: MaterialKey = "metal.painted:3A3F43"
    public var fins: MaterialKey = "metal.aluminum-fins"
    public var steel: MaterialKey = "metal.steel"
    /// Fan radius (m).
    public var fanRadius: Float = 0.78
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        func put(_ ps: [CoolKit.Part]) { for (s, x) in ps { m.add(s, x) } }
        func B(_ s: V3, _ c: V3, _ mat: MaterialKey, r: Float = 0.004) {
            let (a, x) = OK.box(s, c, mat, r: r); m.add(a, x)
        }
        let L: Float = 10, W: Float = 2.4
        let x0: Float = -5, xc: Float = -2.5, x1: Float = 5       // casing start, compressor/condenser split, end
        let y0: Float = 0.3, yd: Float = 2.28                     // skid top, deck underside
        // Skid: long rails, cross members, lifting holes.
        for sz: Float in [-1, 1] { B(V3(L, 0.3, 0.16), V3(0, 0.15, sz * (W / 2 - 0.2)), skid, r: 0.006) }
        for k in 0..<6 { B(V3(0.14, 0.2, W - 0.5), V3(x0 + 0.3 + Float(k) * 1.88, 0.2, 0), skid, r: 0.004) }
        // Compressor enclosure: body, base plinth, panels, doors, handles.
        B(V3(xc - x0, yd - y0, W - 0.02), V3((x0 + xc) / 2, (y0 + yd) / 2, 0), paint, r: 0.012)
        B(V3(xc - x0 + 0.04, 0.06, W + 0.04), V3((x0 + xc) / 2, y0 + 0.03, 0), "metal.painted:C9CBC6", r: 0.005)
        for sz: Float in [-1, 1] {
            let z = sz * (W / 2 + 0.003)
            for d in 0..<2 {
                let cx = x0 + 0.65 + Float(d) * 1.2
                B(V3(1.06, 1.5, 0.014), V3(cx, 1.2, z), "metal.painted:EEEEE9", r: 0.006)
                B(V3(0.05, 0.16, 0.03), V3(cx + 0.42, 1.2, z + sz * 0.015), "metal.stainless", r: 0.006)
                for hy: Float in [0.55, 1.85] { B(V3(0.05, 0.1, 0.012), V3(cx - 0.47, hy, z + sz * 0.007), steel, r: 0.003) }
                // Vent louver on the upper door.
                for j in 0..<6 { B(V3(0.7, 0.012, 0.018), V3(cx, 1.62 + Float(j) * 0.04, z + sz * 0.012), "metal.painted:DADBD5", r: 0.002) }
            }
            // Nameplate and control placard on door 1.
            B(V3(0.26, 0.17, 0.006), V3(x0 + 0.65, 0.78, z + sz * 0.012), "metal.aluminum-brushed", r: 0.002)
            for j in 0..<4 { B(V3(0.2, 0.006, 0.002), V3(x0 + 0.65, 0.82 - Float(j) * 0.03, z + sz * 0.016), "plastic.black", r: 0.0005) }
            B(V3(0.14, 0.1, 0.004), V3(x0 + 1.85, 0.8, z + sz * 0.012), "metal.painted:E0B000", r: 0.001)
        }
        // Top lid of the compressor enclosure, junction box, lifting eyes.
        B(V3(xc - x0 + 0.06, 0.06, W + 0.06), V3((x0 + xc) / 2, yd + 0.03, 0), "metal.painted:DDDDD7", r: 0.01)
        B(V3(0.5, 0.35, 0.3), V3(x0 + 0.7, yd + 0.24, 0.6), "metal.painted:C9CBC6", r: 0.01)
        for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
            m.add(Prim.torus(major: 0.05, minor: 0.012, segments: 12, sides: 6, material: steel), Xform(translation: V3((sx > 0 ? xc - 0.25 : x0 + 0.25), yd + 0.12, sz * 1.0), rotation: simd_quatf(angle: .pi / 2, axis: V3(1, 0, 0)))) } }
        // End panel on the -X face with insulated chilled water nozzles.
        B(V3(0.02, yd - y0, W), V3(x0 - 0.001, (y0 + yd) / 2, 0), "metal.painted:EDEDE8", r: 0.006)
        for (k, z) in ([-0.55, 0.55] as [Float]).enumerated() {
            let y: Float = 0.78
            m.add(Prim.tube([V3(x0 - 0.01, y, z), V3(x0 - 0.5, y, z)], radii: [0.13, 0.13], sides: 20, seamTile: 0.3, material: "plastic.black"))
            let (cap, cx) = OK.cylX(0.14, 0.04, x0: x0 - 0.54, y: y, z: z, "plastic.black", seg: 20, bevel: 0.005); m.add(cap, cx)
            let (fl, fx) = OK.cylX(0.1, 0.03, x0: x0 - 0.58, y: y, z: z, steel, seg: 20, bevel: 0.003); m.add(fl, fx)
            var bolts = Model(name: "nb\(k)")
            for b in 0..<8 { let a = Float(b) / 8 * 2 * .pi
                bolts.add(Prim.cylinder(radius: 0.009, height: 0.012, bevel: 0.001, segments: 6, bevelSegments: 1, material: "metal.titanium"), Xform(translation: V3(x0 - 0.585, y + sin(a) * 0.078, z + cos(a) * 0.078), rotation: OK.qx)) }
            m.add(bolts)
            // Insulation jacket straps.
            for sx: Float in [-0.15, -0.35] { m.add(Prim.torus(major: 0.131, minor: 0.006, segments: 16, sides: 4, material: "metal.stainless"), Xform(translation: V3(x0 + sx, y, z), rotation: OK.qx)) }
        }
        // Condenser: corner posts, louvered sides with coils behind, end panel, deck.
        let cx0 = xc, cl = x1 - xc
        for sz: Float in [-1, 1] {
            for k in 0...4 { B(V3(0.1, yd - y0, 0.1), V3(cx0 + Float(k) * cl / 4, (y0 + yd) / 2, sz * (W / 2 - 0.05)), paint, r: 0.006) }
            B(V3(cl, 0.2, 0.1), V3((cx0 + x1) / 2, y0 + 0.1, sz * (W / 2 - 0.05)), paint, r: 0.006)
            B(V3(cl, 0.16, 0.1), V3((cx0 + x1) / 2, yd - 0.08, sz * (W / 2 - 0.05)), paint, r: 0.006)
            // Coil slab behind louvers.
            let ly0: Float = y0 + 0.2, ly1: Float = yd - 0.16, lh = ly1 - ly0
            put(CoolKit.coil(center: V3((cx0 + x1) / 2, (ly0 + ly1) / 2, sz * (W / 2 - 0.2)), length: cl - 0.25, h: lh - 0.04, thick: 0.12, tilt: 0, fins, ribs: 0))
            put(CoolKit.coil(center: V3((cx0 + x1) / 2, (ly0 + ly1) / 2, sz * (W / 2 - 0.45)), length: cl - 0.25, h: lh - 0.1, thick: 0.1, tilt: 0, fins, ribs: 0))
            // Louver slats (angled).
            let n = Int(lh / 0.055)
            for j in 0..<n {
                let y = ly0 + 0.03 + Float(j) * lh / Float(n)
                m.add(Prim.extrude(Shape2D.rect(cl - 0.15, 0.05), depth: 0.012, bevel: 0, bevelSegments: 1, material: "metal.painted:E3E3DD"),
                      Xform(translation: V3((cx0 + x1) / 2, y, sz * (W / 2 - 0.045)), rotation: simd_quatf(angle: 0.6 * sz, axis: V3(1, 0, 0))))
            }
            for k in 0...4 { B(V3(0.05, lh, 0.02), V3(cx0 + Float(k) * cl / 4 + (k == 4 ? -0.1 : (k == 0 ? 0.1 : 0)), (ly0 + ly1) / 2, sz * (W / 2 - 0.03)), "metal.painted:DADBD5", r: 0.003) }
        }
        B(V3(0.04, yd - y0, W - 0.04), V3(x1 - 0.02, (y0 + yd) / 2, 0), paint, r: 0.008)
        B(V3(0.4, yd - y0 - 0.3, 0.02), V3(x1 + 0.005, 1.25, 0), "metal.painted:DADBD5", r: 0.003)
        // Dark interior floor under the fans plus condenser deck with fan openings.
        let deckY = yd + 0.03
        let nF = 4, pitch = cl / Float(nF), R = fanRadius
        for sz: Float in [-1, 1] { B(V3(cl + 0.1, 0.06, W / 2 - R + 0.02), V3((cx0 + x1) / 2, deckY, sz * (W / 2 + R) / 2 - 0.0), paint, r: 0.006) }
        for k in 0...nF { B(V3(0.12, 0.06, 2 * R + 0.04), V3(cx0 + Float(k) * pitch, deckY, 0), paint, r: 0.006) }
        B(V3(cl, 0.02, 2 * R), V3((cx0 + x1) / 2, yd - 0.02, 0), "plastic.black", r: 0.002)
        for k in 0..<nF {
            let c = V3(cx0 + pitch / 2 + Float(k) * pitch, deckY, 0)
            put(CoolKit.shroud(c, r: R, h: 0.4, "metal.painted:E3E3DD"))
            put(CoolKit.guardWire(c + V3(0, 0.43, 0), r: R, "metal.galvanized"))
            put(CoolKit.wheel(c + V3(0, 0.22, 0), r: R, phase: Float(k) * 0.5 + Float(rng.next() % 100) / 60, blade: "plastic.black", hub: "metal.painted:2F3438"))
            for a: Float in [0, .pi / 2] { m.add(OK.rod(c + V3(cos(a) * R, 0.12, sin(a) * R), c + V3(-cos(a) * R, 0.12, -sin(a) * R), r: 0.012, steel)) }
        }
        // Rain and dirt streaks under the deck lip, louver frame and door tops.
        let streak: [MaterialKey] = ["metal.painted:CFCBBE", "metal.painted:BDB8AA", "metal.painted:D6D2C6"]
        for sz: Float in [-1, 1] {
            for k in 0..<22 {
                let x = x0 + 0.3 + Float(rng.next() % 1000) / 1000 * (L - 0.6)
                let hgt = 0.15 + Float(rng.next() % 1000) / 1000 * 0.5
                let top = (x < xc ? 1.95 : yd - 0.02) - Float(rng.next() % 100) / 400
                B(V3(0.012 + Float(k % 3) * 0.008, hgt, 0.002), V3(x, top - hgt / 2, sz * (W / 2 + 0.012)), streak[k % 3], r: 0.0004)
            }
        }
        groundAO(&m, height: 0.6, floor: 0.6)
        return LODModel(m)
    }
}
