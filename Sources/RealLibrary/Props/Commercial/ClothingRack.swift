import simd
import Foundation

/// Boutique garment rack, 120 x 160 x 50 cm: chrome hang rail through clamps on two telescoping uprights with height collars
/// and knobs, black powder-coated splayed bases on four swivel casters, a lower shelf rail frame holding folded knits and
/// a shoe box, and a row of wood and plastic hangers carrying shirts, jackets and dresses in varied colors with price tags.
public struct ClothingRack: RealAsset {
    public static let id = "clothing-rack"
    public static let summary = "Clothing rack, 1.2 x 1.6 x 0.5 m: chrome rail on adjustable posts and casters with hangers and hanging garments."
    public static let tags = ["prop", "floorplan", "commercial", "retail", "metal", "interior"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 28, elevation: 10, distance: 0.95, studio: true)

    /// Overall size in meters (x rail length, y height to the upright caps, z base depth); the shoppers' side faces +Z.
    public var size = V3(1.2, 1.6, 0.5)
    /// Rail height above the floor.
    public var railHeight: Float = 1.45
    /// Chrome tube.
    public var chrome: MaterialKey = "metal.chrome"
    /// Base and collar powder coat.
    public var powder: MaterialKey = "metal.powdercoat:1E1E20"
    /// Hangers on the rail (0 = empty).
    public var garmentDensity: Float = 1
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [model(seed: seed, detail: true), model(seed: seed, detail: false)], switchDistances: [4.5])
    }

    func model(seed: UInt64, detail: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let W = size.x, D = size.z
        let upX = W / 2 - 0.1                  // upright x position
        let sides = detail ? 10 : 6
        let casterH: Float = 0.075
        let railY = railHeight

        func tube(_ pts: [V3], r: Float, mat: MaterialKey? = nil, sides sd: Int? = nil) {
            m.add(Prim.tube(pts, radii: pts.map { _ in r }, sides: sd ?? sides, seamTile: 0.1, material: mat ?? chrome))
        }
        func cyl(_ r: Float, _ h: Float, _ p: V3, _ mat: MaterialKey, rot: simd_quatf = .identity, bevel: Float? = nil) {
            m.add(Prim.cylinder(radius: r, height: h, bevel: bevel ?? r * 0.25, segments: sides, bevelSegments: 1, seamTile: 0.1, material: mat), Xform(translation: p, rotation: rot))
        }

        /// Swivel caster: top plate, swivel barrel, fork cheeks and a rubber wheel on an axle.
        func swivelCaster(_ p: V3, yaw: Float) {
            let q = simd_quatf(degrees: yaw, axis: .up)
            func X(_ t: V3, _ r: simd_quatf = .identity) -> Xform { Xform(translation: p + q.act(t), rotation: q * r) }
            let wr: Float = 0.026
            m.add(Prim.roundedBox(V3(0.05, 0.004, 0.05), radius: 0.0015, bevelSegments: 1, material: chrome), X(V3(0, casterH - 0.002, 0)))
            m.add(Prim.cylinder(radius: 0.016, height: 0.012, bevel: 0.003, segments: sides, bevelSegments: 1, material: chrome), X(V3(0, casterH - 0.016, 0)))
            for sd: Float in [-1, 1] {
                m.add(cuboid(V3(0.012, casterH - 0.012 - wr + 0.012, 0.003), material: chrome), X(V3(0.006, wr + (casterH - 0.016 - wr) / 2, sd * 0.0155)))
            }
            m.add(Prim.cylinder(radius: wr, height: 0.022, bevel: 0.005, segments: detail ? 14 : 8, bevelSegments: 1, seamTile: 0.1, material: "rubber"), X(V3(0.012, wr, -0.011), simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
            m.add(Prim.cylinder(radius: 0.011, height: 0.026, bevel: 0.002, segments: 8, bevelSegments: 1, material: "plastic.matte:2B2B2E"), X(V3(0.012, wr, -0.013), simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        }

        // Rail: chrome tube through the upright clamps with capped, domed ends.
        let rx0 = -W / 2 + 0.026, rx1 = W / 2 - 0.026
        cyl(0.0125, rx1 - rx0, V3(rx0, railY, 0), chrome, rot: simd_quatf(degrees: -90, axis: V3(0, 0, 1)), bevel: 0.002)
        for s: Float in [-1, 1] {
            m.add(Prim.lathe([V2(0.0001, 0), V2(0.0165, 0), V2(0.0175, 0.003), V2(0.0175, 0.012), V2(0.012, 0.022), V2(0.0001, 0.026)], segments: sides, seamTile: 0.1, material: powder),
                  Xform(translation: V3(s * (W / 2 - 0.026), railY, 0), rotation: simd_quatf(degrees: s > 0 ? -90 : 90, axis: V3(0, 0, 1))))
        }

        // Uprights: two telescoping tubes with a height collar and thumb knob, rail clamp and domed cap.
        let topY = size.y - 0.012
        for s: Float in [-1, 1] {
            let x = s * upX
            tube([V3(x, casterH + 0.04, 0), V3(x, 1.0, 0)], r: 0.0145, mat: "metal.aluminum-brushed")
            cyl(0.0185, 0.05, V3(x, 0.98, 0), powder, bevel: 0.005)
            cyl(0.0125, topY - 1.02, V3(x, 1.02, 0), chrome, bevel: 0.002)       // inner tube above the collar
            m.add(Prim.lathe([V2(0.0001, 0), V2(0.0145, 0), V2(0.0145, 0.006), V2(0.01, 0.014), V2(0.0001, 0.018)], segments: sides, seamTile: 0.1, material: powder), Xform(translation: V3(x, topY - 0.006, 0)))
            // Collar knob on the +Z side.
            cyl(0.004, 0.025, V3(x, 1.0, 0.0185), powder, rot: simd_quatf(degrees: 90, axis: V3(1, 0, 0)), bevel: 0.001)
            m.add(Prim.superellipsoid(V3(0.026, 0.026, 0.016), exponent: 2.4, subdivisions: 2, material: "plastic.matte:2B2B2E"), Xform(translation: V3(x, 1.0, 0.0185 + 0.032)))
            // Rail clamp block.
            m.add(Prim.roundedBox(V3(0.04, 0.05, 0.036), radius: 0.006, bevelSegments: 1, material: powder), Xform(translation: V3(x, railY, 0)))
            // Base: a short stem and two splayed legs ending in feet with swivel casters.
            cyl(0.02, 0.04, V3(x, casterH + 0.0, 0), powder, bevel: 0.006)
            for sz: Float in [-1, 1] {
                let leg: [V3] = [V3(x, casterH + 0.035, 0), V3(x + s * 0.018, casterH + 0.022, sz * 0.09), V3(x + s * 0.045, casterH + 0.012, sz * 0.2), V3(x + s * 0.052, casterH + 0.004, sz * (D / 2 - 0.075))]
                tube(catmull(leg, per: 4), r: 0.0125, mat: powder, sides: detail ? 10 : 6)
                m.add(Prim.roundedBox(V3(0.05, 0.016, 0.05), radius: 0.006, bevelSegments: 1, material: powder), Xform(translation: V3(x + s * 0.052, casterH - 0.004, sz * (D / 2 - 0.075))))
                swivelCaster(V3(x + s * 0.052, 0, sz * (D / 2 - 0.075)), yaw: sz > 0 ? 18 : -25)
            }
        }

        // Lower shelf rail: a rectangular tube frame between the uprights, mitred at the corners.
        let sy: Float = 0.34, sz: Float = 0.17
        let frame: [V3] = [V3(-upX, sy, -sz), V3(upX, sy, -sz), V3(upX, sy, sz), V3(-upX, sy, sz), V3(-upX, sy, -sz)]
        m.add(Prim.sweep(Shape2D.circle(0.0095, segments: detail ? 10 : 6), along: frame, closedPath: true, caps: false, material: chrome))
        for s: Float in [-1, 1] {
            tube([V3(s * upX, sy, -sz), V3(s * upX, sy, 0)], r: 0.0095, sides: 8)
            cyl(0.017, 0.03, V3(s * upX, sy - 0.015, 0), powder, bevel: 0.004)         // clamp ring on the upright
        }

        // Garments: lofted bodies with sleeves, local frame at the hook (rail center), hanger yawed on the rail.
        let palette: [MaterialKey] = ["fabric.linen:E9E4D8", "fabric.linen:9FB4C7", "fabric.wool:3C4350", "fabric.linen:D2B98F", "fabric.canvas:8E9A72", "fabric.linen:C9D3DA",
                                      "fabric.wool:A8453D", "fabric.linen:F1EEE6", "fabric.wool:4C6A8E", "fabric.canvas:C49A63", "fabric.linen:D5A9A0", "fabric.wool:B8553A",
                                      "fabric.upholstery:5D6A57", "fabric.linen:E5C9C0"]
        let woodH: MaterialKey = "wood.beech-stained", plasH: MaterialKey = "plastic.matte:D8D2C2"
        func garment(x: Float, kind: Int, mat: MaterialKey, yaw: Float, wood: Bool) {
            let q = simd_quatf(degrees: yaw, axis: .up)
            func put(_ s: Surface) { m.add(s, Xform(translation: V3(x, railY, 0), rotation: q)) }
            let gw: Float = kind == 2 ? rng.float(0.34...0.38) : rng.float(0.38...0.44)
            let len: Float = kind == 0 ? rng.float(0.6...0.68) : (kind == 1 ? rng.float(0.7...0.78) : rng.float(0.82...0.9))
            let gt: Float = kind == 1 ? 0.07 : 0.05
            let top: Float = -0.05
            // Body: a rounded slab pulled in at the shoulders (or flared into a skirt) with vertical creases and a wavy hem.
            let ph1 = rng.float(0...6.28), ph2 = rng.float(0...6.28)
            var body = Prim.superellipsoid(V3(gt, len, gw), exponent: 3.2, subdivisions: detail ? 6 : 2, material: mat)
            body.deform { p in
                let t = p.y / len + 0.5
                var q = p
                let sh = smoothstep(0.7, 1.0, t)
                q.z *= kind == 2 ? (1 + 0.42 * (1 - smoothstep(0.0, 0.62, t))) * (1 - 0.34 * sh) : (1.07 - 0.46 * sh)
                q.x += gt * 0.3 * sin(p.z * 36 + ph1) * sin(p.y * 6 + ph2) * (0.35 + 0.65 * (1 - t))
                q.y -= 0.022 * sin(p.z * 17 + ph2) * (1 - smoothstep(0, 0.12, t))
                if t > 0.93 { q.y -= 0.018 * max(0, 1 - abs(p.z) / 0.06) }
                return q
            }
            put(body.transformed(Xform(translation: V3(0, top - len / 2, 0))))
            if kind < 2 {
                // Sleeves.
                let sl: Float = kind == 1 ? 0.36 : 0.16
                for sz: Float in [-1, 1] {
                    let a = V3(0, top - 0.025, sz * gw * 0.44), b = V3(0.008, top - 0.03 - sl, sz * (gw * 0.5 + 0.018))
                    put(Prim.tube([a, (a + b) / 2 + V3(0, 0, sz * 0.012), b], radii: [0.032, 0.029, 0.024], sides: detail ? 5 : 4, seamTile: 0.1, material: mat, capEnd: true))
                }
            }
            // Hanger: shoulders swept in the YZ plane, hook over the rail.
            let hp: [V3] = [V3(0, -0.062, -gw * 0.5), V3(0, -0.026, -gw * 0.24), V3(0, -0.014, 0), V3(0, -0.026, gw * 0.24), V3(0, -0.062, gw * 0.5)]
            if wood {
                put(Prim.sweep(Shape2D.roundedRect(0.014, 0.0095, radius: 0.003, segments: 1), along: catmull(hp, per: 3), up: V3(1, 0, 0), caps: true, grainAlongPath: true, material: woodH))
            } else {
                put(Prim.sweep(Shape2D.roundedRect(0.012, 0.007, radius: 0.0025, segments: 1), along: catmull(hp, per: 3), up: V3(1, 0, 0), caps: true, material: plasH))
            }
            let hook: [V3] = [V3(0, -0.014, 0), V3(0, 0.0, 0), V3(0.0, 0.016, 0.004), V3(0, 0.03, -0.004), V3(0, 0.026, -0.016), V3(0, 0.012, -0.02)]
            if detail { put(Prim.tube(hook, radii: hook.map { _ in 0.0017 }, sides: 4, seamTile: 0.02, material: wood ? chrome : "metal.chrome")) }
            // Price tag on a string from the hook.
            if detail && rng.chance(0.8) {
                let tz = rng.float(-0.1...0.1)
                put(Prim.tube([V3(0, -0.014, 0), V3(0.04, -0.08, tz * 0.4), V3(0.07, -0.17, tz)], radii: [0.0006, 0.0006, 0.0006], sides: 3, seamTile: 0.02, material: "plastic.black:1A1A1A"))
                let tag = Prim.roundedBox(V3(0.004, 0.1, 0.065), radius: 0.0012, bevelSegments: 1, material: rng.chance(0.5) ? "paper.sheet:E4D9BD" : "paper.sheet:2E2E30")
                m.add(tag, Xform(translation: V3(x, railY, 0) + q.act(V3(0.072, -0.22, tz)), rotation: q * simd_quatf(degrees: rng.float(-12...12), axis: V3(1, 0, 0))))
            }
        }
        if garmentDensity > 0 {
            var x = -upX + 0.055
            var gi = 0
            while x < upX - 0.04 {
                let kind = [0, 0, 1, 2, 0, 1, 0, 2][gi % 8]
                let yaw = (rng.chance(0.5) ? 1 : -1) * rng.float(3...10)
                garment(x: x, kind: kind, mat: palette[(gi * 5 + Int(rng.int(0...3))) % palette.count], yaw: yaw, wood: gi % 3 == 0)
                x += rng.float(0.082...0.096); gi += 1
            }
        }

        // Sale sign: a red card on an S-hook at the rail center.
        let sx: Float = 0.12
        m.add(Prim.tube([V3(sx, railY + 0.016, 0), V3(sx, railY + 0.026, 0.01), V3(sx, railY + 0.012, 0.02), V3(sx, railY - 0.02, 0.012), V3(sx, railY - 0.04, 0.012)], radii: [0.0016, 0.0016, 0.0016, 0.0016, 0.0016], sides: 4, seamTile: 0.02, material: chrome))
        m.add(Prim.roundedBox(V3(0.004, 0.12, 0.16), radius: 0.0015, bevelSegments: 1, material: "paper.sheet:C23B2E"), Xform(translation: V3(sx, railY - 0.1, 0.012), rotation: simd_quatf(degrees: 8, axis: .up)))
        m.add(Prim.roundedBox(V3(0.0045, 0.05, 0.12), radius: 0.001, bevelSegments: 1, material: "paper.sheet:F2EFE4"), Xform(translation: V3(sx + 0.001, railY - 0.1, 0.012), rotation: simd_quatf(degrees: 8, axis: .up)))

        // Lower shelf: folded knits and a shoe box on the frame, a pair of sneakers.
        let fold: [MaterialKey] = ["fabric.wool:55606A", "fabric.wool:A8453D", "fabric.wool:E3DCCB", "fabric.wool:2F4A63", "fabric.linen:CFC8B6"]
        func stack(x: Float, n: Int, w: Float, d: Float) {
            var yy = sy + 0.0095
            for k in 0..<n {
                let h = rng.float(0.028...0.04)
                m.add(Prim.superellipsoid(V3(w - rng.float(0...0.02), h * 1.1, d), exponent: 4, subdivisions: 1, material: fold[(k + Int(rng.int(0...4))) % fold.count]),
                      Xform(translation: V3(x, yy + h / 2, rng.float(-0.01...0.01)), rotation: simd_quatf(degrees: rng.float(-3...3), axis: .up)))
                yy += h
            }
        }
        stack(x: -0.3, n: 4, w: 0.3, d: 0.3)
        stack(x: 0.02, n: 3, w: 0.3, d: 0.3)
        m.add(Prim.roundedBox(V3(0.3, 0.11, 0.2), radius: 0.003, bevelSegments: 1, material: "paper.sheet:B7573F"), Xform(translation: V3(0.34, sy + 0.0095 + 0.055, 0.0), rotation: simd_quatf(degrees: 4, axis: .up)))
        m.add(Prim.roundedBox(V3(0.305, 0.03, 0.205), radius: 0.003, bevelSegments: 1, material: "paper.sheet:9F4631"), Xform(translation: V3(0.34, sy + 0.0095 + 0.115, 0.0), rotation: simd_quatf(degrees: 4, axis: .up)))

        // Authoring frame: centered on X/Z, base at y = 0.
        let bb = m.bounds
        m = m.transformed(Xform(translation: V3(-(bb.min.x + bb.max.x) / 2, -bb.min.y, -(bb.min.z + bb.max.z) / 2)))
        groundAO(&m, height: 0.12, floor: 0.6)
        return m
    }
}
