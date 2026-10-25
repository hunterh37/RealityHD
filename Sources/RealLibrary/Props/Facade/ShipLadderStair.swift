import simd
import Foundation

/// Nautical ship ladder, 0.7 m wide, 1.0 m deep, 2.5 m to the rail top, 1.7 m rise at 69 degrees: two painted steel
/// channel stringers (web plate with inward flanges, bolted foot angles on deck pads), five varnished teak treads
/// with black non-skid inlay, stainless nosing angles with brass screws and stainless clip angles, a diamond-plate
/// top platform on rim channels and two braced legs, and stainless handrails on raked stanchions with brass
/// collars that bend onto a horizontal grab rail. Salt weathering: paint chipped to rust at the bolts, rust runs,
/// grey worn teak, one unvarnished replacement tread, salt crust on the deck.
public struct ShipLadderStair: RealAsset {
    public static let id = "ship-ladder-stair"
    public static let summary = "Steep ship ladder 0.7 x 1.0 m, 1.7 m rise: channel stringers, teak treads, stainless rails on stanchions, deck platform."
    public static let tags = ["prop", "architecture", "facade", "metal", "wood"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 38, elevation: 12, distance: 2.6)

    /// Rise to the platform in meters.
    public var rise: Float = 1.7
    /// Horizontal run of the stringers in meters.
    public var run: Float = 0.64
    /// Number of treads below the platform.
    public var treads = 5
    /// Stringer and leg paint (white marine enamel).
    public var paint: MaterialKey = "metal.painted:A3B2B8"
    /// Tread timber.
    public var teak: MaterialKey = "wood.mahogany"
    /// Rails and nosings.
    public var steel: MaterialKey = "metal.stainless"
    /// Collars and screws.
    public var brass: MaterialKey = "metal.brass-aged"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [make(seed: seed, lite: false), make(seed: seed, lite: true)], switchDistances: [6])
    }

    /// Beveled box as an extruded rectangle (about 40 triangles).
    func bx(_ m: inout Model, _ size: V3, _ c: V3, _ mat: MaterialKey, r: Float = 0.003, rot: simd_quatf = .identity) {
        let x = size.x / 2, y = size.y / 2
        m.add(Prim.extrude([V2(-x, -y), V2(x, -y), V2(x, y), V2(-x, y)], depth: size.z, bevel: min(r, min(size.x, min(size.y, size.z)) * 0.3), bevelSegments: 1, material: mat),
              Xform(translation: c, rotation: rot))
    }

    /// Hex bolt head, about 40 triangles. Axis along `n`.
    func hb(_ m: inout Model, at p: V3, normal n: V3, size: Float, material: MaterialKey) {
        let hex = Shape2D.polygon(sides: 6, radius: size / sqrt(3))
        m.add(Prim.extrude(hex, depth: size * 0.5, bevel: size * 0.07, bevelSegments: 1, material: material),
              Xform(translation: p + simd_normalize(n) * size * 0.25, rotation: facing(n) * simd_quatf(degrees: -90, axis: V3(1, 0, 0))))
    }

    /// Brass screw head, octagonal, about 30 triangles.
    func sc(_ m: inout Model, at p: V3, r: Float, normal n: V3) {
        m.add(Prim.extrude(Shape2D.polygon(sides: 8, radius: r), depth: 0.002, bevel: 0.0006, bevelSegments: 1, material: brass),
              Xform(translation: p + simd_normalize(n) * 0.001, rotation: facing(n) * simd_quatf(degrees: -90, axis: V3(1, 0, 0))))
    }

    func make(seed: UInt64, lite: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let H = rise, R = run
        let s = H / R
        let th = atan2(H, R)
        let thd = th * 180 / .pi
        let wh: Float = 0.075 / sin(th)                    // horizontal width of the stringer band
        let zc: Float = 0.31                              // stringer web plane
        let wt: Float = 0.007                               // web thickness
        let L = sqrt(R * R + H * H)
        let dir = V3(cos(th), sin(th), 0), nrm = V3(-sin(th), cos(th), 0)
        let bolt: MaterialKey = "metal.bolt-bright"
        func xc(_ y: Float) -> Float { y / s + wh / 2 }     // stringer centre line x at height y
        // Deck pads and foot angles.
        for e: Float in [-1, 1] {
            bx(&m, V3(0.2, 0.01, 0.07), V3(0.1, 0.005, e * zc), "metal.galvanized-aged", r: 0.002)
            bx(&m, V3(0.11, 0.008, 0.06), V3(0.07, 0.014, e * zc), paint, r: 0.0015)
            if !lite {
                for dx: Float in [-0.035, 0.035] {
                    for dz: Float in [-0.02, 0.02] { hb(&m, at: V3(0.07 + dx, 0.018, e * zc + dz), normal: FA.Y, size: 0.011, material: bolt) }
                }
            }
        }
        // Stringers: web plate plus flanges turned inward.
        for e: Float in [-1, 1] {
            let web: [V2] = [V2(0, 0), V2(wh, 0), V2(R + wh, H), V2(R, H)]
            m.add(Prim.extrude(web, depth: wt, bevel: 0.0028, bevelSegments: 1, material: e < 0 ? paint : "metal.painted:97A7AF"), Xform(translation: V3(0, 0, e * zc)))
            for side: Float in [-1, 1] {
                let edgeMid = V3(R / 2 + (side > 0 ? wh : 0), H / 2, 0)
                let c = edgeMid - nrm * side * 0.0028
                bx(&m, V3(L, 0.0055, 0.024), V3(c.x, c.y, e * (zc - wt / 2 - 0.012)), paint, r: 0.0012, rot: FA.q(thd, FA.Z))
            }
            // Cut ends: foot flange return and top bearing plate.
            bx(&m, V3(wh, 0.005, 0.024), V3(wh / 2, 0.0025, e * (zc - wt / 2 - 0.012)), paint, r: 0.001)
            bx(&m, V3(wh, 0.005, 0.024), V3(R + wh / 2, H - 0.0025, e * (zc - wt / 2 - 0.012)), paint, r: 0.001)
            if !lite {
                // Lightening holes are drawn as dark ovals on the web, bolt heads at the platform and foot.
                for k in 0..<2 {
                    let y = 0.5 + Float(k) * 0.42
                    bx(&m, V3(0.11, 0.032, 0.0012), V3(xc(y) + 0.0, y, e * (zc + wt / 2 + 0.0004)), "metal.anodized-black", r: 0.012, rot: FA.q(thd, FA.Z))
                }
            }
        }
        // Treads: varnished teak with inlay, stainless nosing, clip angles.
        let nT = treads
        let replaced = 3
        for k in 1...nT {
            let y = Float(k) * H / Float(nT + 1)
            let cx = xc(y) - 0.01
            let mat: MaterialKey = k == replaced ? "wood.lumber-oak" : [teak, "wood.walnut-oiled", teak, "wood.walnut", "wood.mahogany"][k - 1]
            let wTr: Float = 2 * (zc - wt / 2) - 0.004
            // Tread: two slats with a 6 mm drain gap, 3 mm bevel.
            for sl: Float in [-1, 1] {
                bx(&m, V3(0.0985, 0.032, wTr), V3(cx + sl * 0.05, y - 0.016, 0), mat, r: 0.0045)
            }
            // Black non-skid inlay strips.
            if !lite {
                for j in 0..<4 {
                    bx(&m, V3(0.011, 0.0035, wTr - 0.07), V3(cx - 0.065 + Float(j) * 0.04, y + 0.0005, 0), "metal.anodized-black", r: 0.001)
                }
            }
            // Stainless nosing angle over the front edge.
            bx(&m, V3(0.036, 0.0035, wTr + 0.003), V3(cx - 0.1 + 0.018 - 0.0, y + 0.0018, 0), steel, r: 0.001)
            bx(&m, V3(0.0035, 0.034, wTr + 0.003), V3(cx - 0.1 - 0.0004, y - 0.016, 0), steel, r: 0.001)
            if !lite {
                for j in 0..<5 {
                    let z = -wTr / 2 + 0.05 + Float(j) * (wTr - 0.1) / 4
                    sc(&m, at: V3(cx - 0.1 + 0.018, y + 0.0035, z), r: 0.0042, normal: FA.Y)
                }
            }
            // Clip angles on the inner web faces, bolted through the web.
            for e: Float in [-1, 1] {
                bx(&m, V3(0.055, 0.003, 0.04), V3(cx, y - 0.0335, e * (zc - wt / 2 - 0.02)), steel, r: 0.0008)
                bx(&m, V3(0.055, 0.045, 0.003), V3(cx, y - 0.056, e * (zc - wt / 2 - 0.0015)), steel, r: 0.0008)
                if !lite {
                    for dx: Float in [0.0] {
                        let zb = e * (zc + wt / 2)
                        m.add(Prim.cylinder(radius: 0.0055, height: 0.0035, bevel: 0.0008, segments: 6, bevelSegments: 1, material: bolt),
                              Xform(translation: V3(cx + dx, y - 0.06, zb + (e < 0 ? -0.0035 : 0)), rotation: FA.q(90, FA.X)))
                    }
                }
            }
        }
        // Platform: rim channels, diamond plate, rib bumps, legs with base plates, back brace.
        let px0 = R + wh * 0.55, px1: Float = 1.0
        let pcx = (px0 + px1) / 2, pw = px1 - px0
        bx(&m, V3(pw, 0.009, 0.69), V3(pcx, H - 0.0045, 0), "metal.painted:8A9096", r: 0.003)
        for e: Float in [-1, 1] {
            bx(&m, V3(pw, 0.07, 0.008), V3(pcx, H - 0.044, e * 0.341), paint, r: 0.0015)
            bx(&m, V3(pw, 0.006, 0.026), V3(pcx, H - 0.0125 - 0.0, e * 0.3), paint, r: 0.001)
            // Legs.
            bx(&m, V3(0.06, H - 0.1 - 0.012, 0.06), V3(px1 - 0.045, 0.012 + (H - 0.112) / 2, e * 0.295), paint, r: 0.009)
            bx(&m, V3(0.11, 0.012, 0.11), V3(px1 - 0.045, 0.006, e * 0.295), "metal.galvanized-aged", r: 0.002)
            bx(&m, V3(0.09, 0.012, 0.09), V3(px1 - 0.045, H - 0.099, e * 0.295), paint, r: 0.002)
            if !lite {
                for (dx, dz) in [(-0.045, -0.045), (0.045, -0.045), (-0.045, 0.045), (0.045, 0.045)] as [(Float, Float)] {
                    hb(&m, at: V3(px1 - 0.045 + dx, 0.012, e * 0.295 + dz), normal: FA.Y, size: 0.012, material: bolt)
                }
            }
        }
        bx(&m, V3(0.008, 0.07, 0.69), V3(px0 + 0.004, H - 0.044, 0), paint, r: 0.0015)
        FA.rod(&m, V3(px1 - 0.045, 0.2, -0.295), V3(px1 - 0.045, H - 0.28, 0.295), r: 0.0075, paint, sides: lite ? 5 : 8)
        FA.rod(&m, V3(px1 - 0.045, 0.2, 0.295), V3(px1 - 0.045, H - 0.28, -0.295), r: 0.0075, paint, sides: lite ? 5 : 8)
        if !lite {
            // Diamond-plate bumps.
            let dia: [V2] = [V2(-0.011, 0), V2(0, 0.0035), V2(0.011, 0), V2(0, -0.0035)]
            for i in 0..<3 {
                for j in 0..<7 {
                    let x = px0 + 0.03 + Float(i) * (pw - 0.06) / 4, z = -0.31 + Float(j) * 0.62 / 9
                    m.add(Prim.extrude(dia, depth: 0.0022, bevel: 0, bevelSegments: 1, material: "metal.painted:8A9096"),
                          Xform(translation: V3(x, H + 0.0012, z), rotation: FA.q(90, FA.X) * FA.q((i + j) % 2 == 0 ? 45 : -45, FA.Z)))
                }
            }
            // Rim bolts and a nosing lip along the platform edge.
            for k in 0..<4 {
                for e: Float in [-1, 1] { hb(&m, at: V3(px0 + 0.04 + Float(k) * 0.07, H - 0.05, e * 0.345), normal: V3(0, 0, e), size: 0.011, material: bolt) }
            }
        }
        bx(&m, V3(0.03, 0.006, 0.69), V3(px0 + 0.015, H + 0.003, 0), steel, r: 0.0012)
        // Handrails.
        let railUp: Float = 0.77
        for e: Float in [-1, 1] {
            let z = e * zc
            func yr(_ x: Float) -> Float { s * (x - wh / 2) + railUp }
            let xb: Float = R + wh / 2
            var pts: [V3] = [V3(0.09, yr(0.09), z)]
            var x: Float = 0.09
            while x < xb - 0.22 { x += 0.13; pts.append(V3(x, yr(x), z)) }
            pts += [V3(xb - 0.075, yr(xb - 0.075), z), V3(xb - 0.025, yr(xb - 0.025) + 0.02, z), V3(xb + 0.045, H + railUp - 0.012, z), V3(xb + 0.11, H + railUp, z), V3(px1 - 0.06, H + railUp, z)]
            let hp = catmull(pts, per: lite ? 2 : 3)
            FA.path(&m, hp, r: 0.0195, steel, sides: lite ? 8 : 10)
            m.add(Prim.superellipsoid(V3(repeating: 0.037), exponent: 2, subdivisions: 3, material: steel), Xform(translation: hp.first!))
            m.add(Prim.superellipsoid(V3(repeating: 0.037), exponent: 2, subdivisions: 3, material: steel), Xform(translation: hp.last!))
            // Raked stanchions: collar plate on the stringer edge, brass collar, vertical post into the rail.
            for sx in [0.2, 0.4, 0.55] as [Float] {
                let by = s * (sx - 0.0) + 0.0                  // upper-left stringer edge height
                let top = yr(sx) - 0.01
                let foot = V3(sx, by - 0.0, z)
                bx(&m, V3(0.075, 0.006, 0.05), foot + V3(0, 0.0, 0) - V3(0.0, 0.0, e * 0.0), steel, r: 0.0012, rot: FA.q(thd, FA.Z))
                FA.rod(&m, V3(sx, by + 0.01, z), V3(sx, top, z), r: 0.0095, steel, sides: lite ? 6 : 10)
                m.add(Prim.cylinder(radius: 0.0165, height: 0.022, bevel: 0.003, segments: lite ? 6 : 10, bevelSegments: 1, material: brass), Xform(translation: V3(sx, by + 0.006, z)))
                if !lite {
                    for d: Float in [-1, 1] {
                        let p = foot + dir * d * 0.027 + nrm * 0.0035
                        sc(&m, at: p, r: 0.004, normal: nrm)
                    }
                    // Lower collar under the rail.
                    m.add(Prim.cylinder(radius: 0.0125, height: 0.014, bevel: 0.002, segments: 8, bevelSegments: 1, material: brass), Xform(translation: V3(sx, top - 0.034, z)))
                }
            }
            // Top end stanchion down to the platform rim, with flange.
            let ex = px1 - 0.065
            FA.rod(&m, V3(ex, H + 0.012, z), V3(ex, H + railUp - 0.012, z), r: 0.0095, steel, sides: lite ? 6 : 10)
            m.add(Prim.cylinder(radius: 0.03, height: 0.006, bevel: 0.002, segments: lite ? 10 : 18, bevelSegments: 1, material: steel), Xform(translation: V3(ex, H, z)))
            m.add(Prim.cylinder(radius: 0.0165, height: 0.022, bevel: 0.003, segments: lite ? 6 : 10, bevelSegments: 1, material: brass), Xform(translation: V3(ex, H + 0.006, z)))
            if !lite {
                for a in 0..<4 {
                    let t = Float(a) * .pi / 2 + .pi / 4
                    sc(&m, at: V3(ex + cos(t) * 0.022, H + 0.006, z + sin(t) * 0.022), r: 0.0038, normal: FA.Y)
                }
            }
        }
        // Manila rope coil hung over the lower rail, a seamanship detail.
        if !lite {
            let x: Float = 0.33, z = -zc
            let c = V3(x, s * (x - wh / 2) + railUp - 0.04, z)
            let q = simd_quatf(from: FA.Y, to: dir)
            for k in 0..<3 {
                m.add(Prim.torus(major: 0.03 - Float(k) * 0.002, minor: 0.0085, segments: 20, sides: 6, material: "wood.rattan"),
                      Xform(translation: c + dir * (Float(k) - 1) * 0.02, rotation: q))
            }
        }
        // Weathering.
        if !lite {
            func patch(_ c: V3, _ w: Float, _ h: Float, _ mat: MaterialKey, rot: Float = 0) {
                var poly: [V2] = []
                for j in 0..<8 { let a = Float(j) / 8 * 2 * .pi; poly.append(V2(cos(a) * w * rng.float(0.6...1.1), sin(a) * h * rng.float(0.6...1.1))) }
                m.add(HTKit.plate(outer: poly, depth: 0.0008, bevel: 0.0002, segments: 1, material: mat), Xform(translation: c, rotation: FA.q(rot, FA.Z)))
            }
            for e: Float in [-1, 1] {
                let zo = e * (zc + wt / 2 + (e < 0 ? 0.0 : 0.0))
                let off: Float = e > 0 ? 0.0004 : -0.0004
                // Paint chipped to rust and bare steel along the stringer edges and around bolts.
                for _ in 0..<12 {
                    let y = rng.float(0.1...H - 0.1)
                    let edge: Float = rng.chance(0.5) ? 0.012 : wh - 0.012
                    patch(V3(y / s + edge, y, zo + off), rng.float(0.015...0.04), rng.float(0.02...0.06), rng.chance(0.7) ? "metal.rust" : "metal.steel", rot: thd - 90)
                }
                // Rust runs below the clip bolts.
                for k in 1...nT {
                    let y = Float(k) * H / Float(nT + 1)
                    for dx: Float in [-0.016, 0.016] {
                        bx(&m, V3(rng.float(0.014...0.03), rng.float(0.18...0.34), 0.0012), V3(xc(y) - 0.01 + dx, y - 0.08 - 0.1, zo + off), rng.chance(0.7) ? "metal.rust" : "wood.deadwood", r: 0.0003)
                    }
                }
                // Salt bloom on the platform.
                bx(&m, V3(0.1, 0.0012, 0.16), V3(0.9, H + 0.003, e * 0.2), "stone.limestone", r: 0.0004)
            }
            // Touch-up paint patches in a slightly different grey.
            for e: Float in [-1, 1] {
                for k in 0..<3 {
                    let y = 0.3 + Float(k) * 0.5 + rng.float(-0.08...0.08)
                    bx(&m, V3(rng.float(0.05...0.08), rng.float(0.14...0.26), 0.0012), V3(y / s + wh / 2, y, e * (zc + wt / 2 + 0.0003)), k % 2 == 0 ? "metal.painted:B9C4C6" : "metal.painted:8C9DA4", r: 0.0004, rot: FA.q(thd - 90, FA.Z))
                }
            }
            // Bare-steel chips along the flange edges, salt crust near the foot.
            for e: Float in [-1, 1] {
                for _ in 0..<7 {
                    let y = rng.float(0.05...H - 0.2), side: Float = rng.chance(0.5) ? 0 : wh
                    bx(&m, V3(rng.float(0.01...0.03), rng.float(0.05...0.16), 0.0012), V3(y / s + side + (side > 0 ? -0.004 : 0.004), y, e * (zc + wt / 2 + 0.0004)), rng.chance(0.6) ? "metal.steel" : "metal.rust", r: 0.0003, rot: FA.q(thd - 90, FA.Z))
                }
                for k in 0..<4 {
                    let y = 0.05 + Float(k) * 0.1
                    bx(&m, V3(rng.float(0.03...0.07), rng.float(0.03...0.07), 0.0012), V3(y / s + rng.float(0.01...0.06), y, e * (zc + wt / 2 + 0.0006)), "stone.limestone", r: 0.0003)
                }
            }
            // Grey worn centre on the lower treads, scuffs on the inlay.
            for k in 1...4 {
                let y = Float(k) * H / Float(nT + 1)
                bx(&m, V3(0.1, 0.0008, 0.3), V3(xc(y) - 0.01 - 0.01, y + 0.0004, rng.float(-0.05...0.05)), "wood.weathered", r: 0.0003)
            }
            // Water stain on the foot pads, rust under the foot angles.
            for e: Float in [-1, 1] {
                bx(&m, V3(0.14, 0.0008, 0.08), V3(0.1, 0.0104, e * zc), "metal.rust", r: 0.0003)
            }
            // Rail scuffs where hands land.
            for _ in 0..<6 {
                let x = rng.float(0.15...0.55), e: Float = rng.chance(0.5) ? -1 : 1
                bx(&m, V3(0.03, 0.0008, 0.012), V3(x, s * (x - wh / 2) + railUp + 0.0166, e * zc), "metal.satin-aluminum", r: 0.0003, rot: FA.q(thd, FA.Z))
            }
        }
        groundAO(&m, height: 0.25, floor: 0.7)
        return FC.place(m.transformed(Xform(rotation: FA.q(90, FA.Y))))
    }
}
