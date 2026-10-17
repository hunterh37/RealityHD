import simd
import Foundation

/// Mid-size four-door sedan at 1:1 (2024 Camry / Civic class), front faces +Z, driver side +X.
/// Lofted clearcoat body with wheel arches, tinted greenhouse with painted roof and pillars, headlights,
/// tail lamps, a furnished cabin (door skins, headliner, dash with cluster and screen, console, cloth seats,
/// steering wheel, pedals, hazard button and parking brake), trunk tub with
/// a carpeted floor cover over the spare well and a temporary spare, pinch-weld jack points behind the
/// front and ahead of the rear wheels. Wheelbase, track and tire diameter are knobs
/// (`wheelbase = 2.735` gives a Civic).
///
/// Parts: `body` (lift slide 0...0.15 m, raises the body for jacking), `suspension.<corner>` (droop,
/// mimic of `body`), `wheel.<corner>` (slides off the hub 0...0.35 m), `wheel.<corner>.lug0...lug4`
/// (unscrew 0...0.05 m), `trunkLid` (0...80), `trunkFloor` (0...85), `hazardButton` (push, lights
/// `hazardLamps`), `parkingBrake` (0...30). Corners: frontLeft, frontRight, rearLeft, rearRight.
/// States: `parked`, `trunk-open`, `spare-access`, `hazards-on`, `brake-set`, `jacked`,
/// `lugs-loose`, `wheel-off`.
public struct CompactSedan: RealArticulated {
    public static let id = "compact-sedan"
    public static let summary = "Mid-size four-door sedan at 1:1 (Camry/Civic): clearcoat body, furnished cabin, four live wheels with lug nuts, articulated trunk, jack points and a lift state."
    public static let tags = ["prop", "vehicle", "articulated", "street", "road", "metal", "glass", "rubber"]
    public static let budget = 30000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 14, distance: 1.0)

    /// Wheelbase in meters (2024 Camry 2.825, Civic 2.735).
    public var wheelbase: Float = 2.825
    /// Front track (wheel center to wheel center), meters.
    public var frontTrack: Float = 1.58
    /// Rear track, meters.
    public var rearTrack: Float = 1.58
    /// Tire outer diameter (235/45R18 = 0.669 m).
    public var tireDiameter: Float = 0.669
    /// Front overhang (bumper to front axle), meters.
    public var frontOverhang: Float = 0.97
    /// Rear overhang, meters.
    public var rearOverhang: Float = 1.12
    /// Body half width at the widest point (1.84 m overall).
    public var halfWidth: Float = 0.92
    /// Roof height, meters.
    public var roofHeight: Float = 1.445
    /// Body paint (tint with `:RRGGBB`).
    public var paint: MaterialKey = "paint.car-clearcoat"
    /// Window glass.
    public var glass: MaterialKey = "glass.cabin"
    /// Lift travel of the `body` joint (jacking), meters.
    public static let liftMax: Float = 0.15
    public init() {}

    var length: Float { frontOverhang + wheelbase + rearOverhang }

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [16])
        let L = length, zF = L / 2, zR = -L / 2
        let zFA = zF - frontOverhang, zRA = zFA - wheelbase
        let R = tireDiameter / 2, archR = R + 0.045
        let zW = zFA - 0.38, zRoofF = zFA - 1.22, zRoofR = zRA + 0.38, zTF = zRA - 0.42, zLidR = zR + 0.14
        let n: Float = 5.5, tumble: Float = 0.07

        let topKeys: [(Float, Float)] = [(zR, 0.6), (zR + 0.03, 0.86), (zR + 0.14, 0.99), (zTF - 0.4, 1.005), (zTF, 0.985),
                                         (zW - 0.3, 0.96), (zW, 0.94), (zFA, 0.87), (zF - 0.3, 0.83), (zF - 0.08, 0.79), (zF, 0.7)]
        let botKeys: [(Float, Float)] = [(zR, 0.44), (zR + 0.35, 0.24), (zRA - archR - 0.05, 0.21), (zFA + archR + 0.05, 0.2), (zF - 0.25, 0.2), (zF, 0.27)]
        func section(_ z: Float) -> CK.Section {
            var b = CK.curve(botKeys, z)
            for az in [zFA, zRA] where abs(z - az) < archR {
                b = max(b, R + sqrt(archR * archR - (z - az) * (z - az)))
            }
            let zc = (zF + zR) / 2, zn = min(0.999, abs(z - zc) / (L / 2 * 1.045))
            let p: Float = z > zc ? 7 : 7
            let w = halfWidth * pow(1 - pow(zn, p), 1 / p)
            return CK.Section(halfWidth: w, bottom: b, top: CK.curve(topKeys, z))
        }
        func stations(_ z0: Float, _ z1: Float, _ count: Int) -> [Float] { (0...count).map { z0 + (z1 - z0) * Float($0) / Float(count) } }
        // Denser stations across the arches so the arch curve stays round.
        func bodyStations(_ z0: Float, _ z1: Float, _ step: Float) -> [Float] {
            var out: [Float] = []
            var z = z0
            while z > z1 {
                out.append(z)
                let nearArch = [zFA, zRA].contains { abs(z - $0) < archR + 0.06 }
                z -= nearArch ? step * 0.45 : step
            }
            out.append(z1)
            return out
        }

        rig.part("body", pivot: V3(0, 0.5, 0), joint: .slide(axis: .up, 0...Self.liftMax, duration: 3))
        let roofKeys: [(Float, Float)] = [(zTF, 0.97), (zTF + 0.3, 1.2), (zRoofR, roofHeight - 0.04), ((zRoofR + zRoofF) / 2, roofHeight), (zRoofF, roofHeight - 0.035), (zW - 0.3, 1.1), (zW, 0.93)]
        func belt(_ z: Float) -> Float { section(z).top - 0.012 }
        func roofY(_ z: Float) -> Float { max(belt(z) + 0.008, CK.curve(roofKeys, z)) }
        func wBelt(_ z: Float) -> Float { section(z).halfWidth * (1 - tumble) - 0.035 }
        let crownN: Float = 5

        for l in 0..<2 {
            let lo = l...l
            let pts = l == 0 ? 20 : 12
            let step: Float = l == 0 ? 0.2 : 0.34
            // MARK: lower body front bumper to trunk opening (capped at both ends).
            let zs = bodyStations(zF, zW, step)
            rig.add(Prim.loft(zs.map { CK.ring(section($0), z: $0, n: n, tumble: tumble, points: pts) }, capStart: true, capEnd: true, material: paint), to: "body", lods: lo)
            // MARK: trunk tub (U section: rocker, quarter panels and floor), rear cap and trunk lid.
            let ths: Float = 0.2 * .pi
            let tz = stations(zTF + 0.01, zLidR, l == 0 ? 8 : 4)
            let half = pts / 2
            let tub = tz.map { z -> [V3] in
                let s = section(z)
                var outer: [V3] = [], inner: [V3] = []
                for k in 0...half {
                    let th = ths - (Float.pi + 2 * ths) * Float(k) / Float(half)
                    var p = CK.point(s, th, n: n, tumble: tumble); p.z = z
                    outer.append(p)
                    var q = CK.point(s, th, n: n, tumble: tumble, inset: 0.04); q.z = z
                    q.y = max(q.y, 0.34)
                    inner.append(q)
                }
                return outer + inner.reversed()
            }
            rig.add(Prim.loft(tub, material: paint), to: "body", lods: lo)
            rig.add(Prim.loft(stations(zLidR, zR, l == 0 ? 5 : 2).map { CK.ring(section($0), z: $0, n: n, tumble: tumble, points: pts) }, capStart: true, capEnd: true, material: paint), to: "body", lods: lo)
            // Trunk interior: black liner floor, carpeted side trims, rear bulkhead face.
            let sm = section((zTF + zLidR) / 2)
            rig.add(HK.box(V3(sm.halfWidth * 2 - 0.16, 0.01, zTF - zLidR - 0.04), V3(0, 0.345, (zTF + zLidR) / 2), "plastic.matte:1B1C1E", r: 0.003, seg: 1), to: "body", lods: lo)
            rig.add(HK.box(V3(sm.halfWidth * 2 - 0.2, 0.62, 0.012), V3(0, 0.65, zTF + 0.005), "carpet.tile:2A2B2D", r: 0.004, seg: 1), to: "body", lods: lo)
            // MARK: greenhouse glass, roof skin, pillars, seals.
            let gz = stations(zW, zRoofF, l == 0 ? 6 : 3) + stations(zRoofF, zTF, l == 0 ? 10 : 5).dropFirst()
            let gp = l == 0 ? 22 : 12
            func glassRing(_ z: Float, _ o: Float) -> [V3] { CK.cabinRing(z: z, belt: belt(z), roof: roofY(z), wBelt: wBelt(z), wTop: wBelt(z) - 0.2, n: crownN, points: gp, outset: o, floor: false) }
            rig.add(Prim.loft(gz.map { glassRing($0, 0) + glassRing($0, -0.004).reversed() }, material: glass), to: "body", lods: lo)
            func strip(_ z0: Float, _ z1: Float, _ a0: Float, _ a1: Float, _ mat: MaterialKey, outset: Float, count: Int = 10, sp: Int = 6) -> Surface {
                Prim.loft(stations(z0, z1, count).map { CK.crownStrip(z: $0, belt: belt($0), roof: roofY($0), wBelt: wBelt($0), wTop: wBelt($0) - 0.2, n: crownN, a0: a0, a1: a1, points: sp, outset: outset, thick: 0.012) },
                          capStart: true, capEnd: true, material: mat)
            }
            rig.add(strip(zRoofF + 0.04, zRoofR - 0.03, 0.13, 0.87, paint, outset: 0.012, count: l == 0 ? 10 : 4, sp: l == 0 ? 12 : 6), to: "body", lods: lo)
            for (a0, a1) in [(Float(0.0), Float(0.17)), (0.83, 1.0)] {
                // A pillars, C pillars (wide sail panel), B pillar (black), belt seal.
                rig.add(strip(zW - 0.04, zRoofF + 0.06, a0 + (a0 > 0.5 ? 0.06 : 0.04), a1 - (a0 > 0.5 ? 0.04 : 0.06), paint, outset: 0.014, count: l == 0 ? 8 : 3, sp: 3), to: "body", lods: lo)
                rig.add(strip(zRoofR + 0.05, zTF + 0.3, a0, a1, paint, outset: 0.016, count: l == 0 ? 8 : 3, sp: 4), to: "body", lods: lo)
                let zB = zFA - 1.62
                rig.add(strip(zB + 0.045, zB - 0.045, a0, a1, "plastic.gloss:121314", outset: 0.012, count: 1, sp: 4), to: "body", lods: lo)
                rig.add(strip(zW - 0.3, zTF + 0.15, a0 < 0.5 ? 0 : 0.975, a0 < 0.5 ? 0.025 : 1, "metal.chrome", outset: 0.004, count: l == 0 ? 10 : 3, sp: 2), to: "body", lods: lo)
            }
            // Wheel-arch liners.
            for az in [zFA, zRA] {
                for sx: Float in [-1, 1] {
                    let tr = az == zFA ? frontTrack : rearTrack
                    rig.add(CK.archLiner(center: V3(0, R, az), radius: archR - 0.005, x0: sx * (tr / 2 - 0.16), x1: sx * (section(az).halfWidth - 0.02), mat: "plastic.matte:151617"), to: "body", lods: lo)
                }
            }
            // MARK: front fascia: grille, lower intake, headlights, fog bezels, plate recess.
            rig.add(cuboid(V3(0.8, 0.11, 0.03), material: "plastic.gloss:0E0F10"), Xform(translation: V3(0, 0.56, zF - 0.012)), to: "body", lods: lo)
            rig.add(cuboid(V3(1.25, 0.17, 0.03), material: "plastic.gloss:0E0F10"), Xform(translation: V3(0, 0.39, zF - 0.02)), to: "body", lods: lo)
            // Headlights and tail lamps: shells conforming to the body corners (glass over a dark housing).
            func patch(_ z0: Float, _ z1: Float, _ t0: Float, _ t1: Float, sx: Float, outset: Float, _ mat: MaterialKey, nz: Int = 6, nt: Int = 5) -> Surface {
                let rings = stations(z0, z1, nz).map { z -> [V3] in
                    let sec = section(z)
                    var o: [V3] = [], i: [V3] = []
                    for k in 0...nt {
                        let t = t1 - (t1 - t0) * Float(k) / Float(nt)
                        let th = sx > 0 ? t : Float.pi - t
                        var a = CK.point(sec, th, n: n, tumble: tumble, inset: -outset); a.z = z
                        var b = CK.point(sec, th, n: n, tumble: tumble, inset: 0.01); b.z = z
                        o.append(a); i.append(b)
                    }
                    let ring = o + i.reversed()
                    return sx > 0 ? ring : ring.reversed()
                }
                return Prim.loft(rings, capStart: true, capEnd: true, material: mat)
            }
            for sx: Float in [-1, 1] {
                rig.add(patch(zF - 0.03, zF - 0.52, 0.3, 0.85, sx: sx, outset: 0.002, "plastic.gloss:15161A"), to: "body", lods: lo)
                rig.add(patch(zF - 0.025, zF - 0.53, 0.28, 0.87, sx: sx, outset: 0.007, "glass.pane"), to: "body", lods: lo)
                rig.add(patch(zF - 0.05, zF - 0.48, 0.78, 0.82, sx: sx, outset: 0.004, "emissive.signal-white", nz: 4, nt: 1), to: "body", lods: lo)
                if l == 0 {
                    for (k, zz) in [zF - 0.12, zF - 0.24].enumerated() {
                        let sec = section(zz)
                        var c = CK.point(sec, sx > 0 ? 0.5 : .pi - 0.5, n: n, tumble: tumble, inset: 0.006); c.z = zz
                        rig.add(HK.cyl(r: 0.03 - Float(k) * 0.004, len: 0.012, at: c, axis: simd_normalize(V3(sx * 0.6, 0.1, 0.8)), mat: "metal.chrome", seg: 12), to: "body", lods: lo)
                    }
                }
                // Black rocker cladding with road film and a curb scuff near the rear door.
                rig.add(patch(zFA - archR - 0.02, zRA + archR + 0.02, -0.42, -0.12, sx: sx, outset: 0.003, "plastic.matte:1A1B1C", nz: 4, nt: 2), to: "body", lods: lo)
                rig.add(patch(zRA + archR + 0.5, zRA + archR + 0.12, -0.3, -0.2, sx: sx, outset: 0.005, "decal.rubber-scuff", nz: 2, nt: 1), to: "body", lods: lo)
                rig.add(patch(zR + 0.42, zR + 0.02, 0.1, 0.55, sx: sx, outset: 0.004, "plastic.gloss:6E0B09"), to: "body", lods: lo)
                rig.add(patch(zR + 0.36, zR + 0.04, 0.3, 0.38, sx: sx, outset: 0.007, "emissive.signal-red", nz: 4, nt: 1), to: "body", lods: lo)
            }
            rig.add(cuboid(V3(0.53, 0.115, 0.01), material: "plastic.gloss:E4E4DE"), Xform(translation: V3(0, 0.46, zF + 0.002)), to: "body", lods: lo)
            // MARK: rear: tail lamps, reflectors, plate, exhaust tips.
            for sx: Float in [-1, 1] {
                rig.add(HK.box(V3(0.1, 0.03, 0.02), V3(sx * 0.62, 0.48, zR + 0.03), "plastic.gloss:7A1410", r: 0.005, seg: 1), to: "body", lods: lo)
                rig.add(HK.cyl(r: 0.04, len: 0.1, at: V3(sx * 0.5, 0.36, zR + 0.06), axis: V3(0, 0, -1), mat: "metal.chrome", seg: 10, bevel: 0.004), to: "body", lods: lo)
            }
            rig.add(cuboid(V3(0.31, 0.155, 0.01), material: "plastic.gloss:E4E4DE"), Xform(translation: V3(0, 0.62, zR + 0.005)), to: "body", lods: lo)
            // MARK: sides: mirrors, door seams, handles, pinch welds with jack points.
            for sx: Float in [-1, 1] {
                let mz = zW - 0.18, mw = wBelt(mz)
                rig.add(HK.box(V3(0.12, 0.05, 0.1), V3(sx * (mw + 0.06), belt(mz) + 0.03, mz), paint, r: 0.02, seg: 1), to: "body", lods: lo)
                rig.add(Prim.superellipsoid(V3(0.2, 0.12, 0.1), exponent: 3, subdivisions: l == 0 ? 3 : 2, material: paint), Xform(translation: V3(sx * (mw + 0.13), belt(mz) + 0.08, mz - 0.02)), to: "body", lods: lo)
                rig.add(HK.box(V3(0.17, 0.095, 0.006), V3(sx * (mw + 0.13), belt(mz) + 0.08, mz - 0.073), "glass.pane", r: 0.003, seg: 1), to: "body", lods: lo)
                if l == 0 {
                    for dz in [zW - 0.02, zFA - 1.62, zRA + archR + 0.03] {
                        let s = section(dz)
                        let path = stride(from: s.bottom + 0.06, through: s.top - 0.015, by: 0.1).map { y in V3(sx * (CK.sideX(s, y: y, n: n, tumble: tumble) + 0.0005), y, dz) }
                        rig.add(HK.pipe(path, r: 0.0025, sides: 4, mat: "plastic.gloss:0A0A0B"), to: "body", lods: lo)
                    }
                    for hz in [zFA - 1.5, zRA + 0.85] {
                        let s = section(hz)
                        rig.add(cuboid(V3(0.02, 0.03, 0.15), material: "metal.chrome"), Xform(translation: V3(sx * (CK.sideX(s, y: 0.86, n: n, tumble: tumble) + 0.008), 0.86, hz)), to: "body", lods: lo)
                    }
                }
                let jf = zFA - archR - 0.22, jr = zRA + archR + 0.22
                let sill = section((jf + jr) / 2)
                for srf in CK.pinchWeld(x: sx * (sill.halfWidth - 0.13), y: sill.bottom + 0.008, z0: jf + 0.3, z1: jr - 0.3, notches: [jf, jr], mat: "metal.painted:23262A") {
                    rig.add(srf, to: "body", lods: lo)
                }
            }
            // MARK: interior: cabin tub, dash, console, seats, steering wheel, headliner, trim.
            let floorY: Float = 0.34, skin: Float = 0.04, flatBottom: Float = 0.22
            let trimM: MaterialKey = "plastic.soft-touch", dashM: MaterialKey = "plastic.dash", cloth: MaterialKey = "fabric.seat-cloth"
            let carpet: MaterialKey = "carpet.tile:1E1F21", piano: MaterialKey = "plastic.gloss:0E0F10", screenM: MaterialKey = "screen.cluster"
            let dashFace = zW - 0.555
            // Cabin tub: paint skin from the windshield base to the trunk bulkhead, open above the belt line.
            // The side skins keep the wheel-arch humps; between the wheels the pan runs flat.
            func cabinPath(_ z: Float, inset: Float, drop: Float = 0, cap: Bool = false, arcPts: Int) -> [V3] {
                let s = section(z)
                let mid = (s.bottom + s.top) / 2
                let u = min(0.98, wBelt(z) / (s.halfWidth * (1 - tumble * 0.76)))
                let th0 = acos(min(0.97, pow(u, n / 2)))
                var arc: [V3] = []
                for k in 0...arcPts {
                    let th = th0 - (Float.pi + 2 * th0) * Float(k) / Float(arcPts)
                    var p = CK.point(s, th, n: n, tumble: tumble, inset: inset); p.z = z
                    if p.y < mid && abs(p.x) < 0.62 { p.y = inset > 0 ? floorY : flatBottom }
                    else if inset > 0 { p.y = max(p.y, floorY) }
                    arc.append(p)
                }
                let y = belt(z) - drop
                var out = [V3(arc[0].x, y, z)] + arc + [V3(arc[arcPts].x, y, z)]
                if cap {
                    let rim = CK.point(s, th0, n: n, tumble: tumble).x
                    out = [V3(rim - 0.004, y, z)] + out + [V3(-rim + 0.004, y, z)]
                }
                return out
            }
            let ap = l == 0 ? 10 : 5
            let cz = bodyStations(zW, zTF, step)
            rig.add(Prim.loft(cz.map { z in cabinPath(z, inset: 0, arcPts: ap) + cabinPath(z, inset: 0.004, arcPts: ap).reversed() }, material: paint), to: "body", lods: lo)
            rig.add(Prim.loft(cz.map { z in cabinPath(z, inset: skin + 0.004, cap: true, arcPts: ap).reversed() + cabinPath(z, inset: skin, drop: 0.004, cap: true, arcPts: ap) }, material: trimM), to: "body", lods: lo)

            // Floor carpet, toeboard, transmission tunnel and rear shelf.
            let cabinMid = (zW + zTF) / 2
            rig.add(HK.box(V3(1.56, 0.012, zW - zTF - 0.08), V3(0, floorY + 0.006, cabinMid), carpet, r: 0.003, seg: 1), to: "body", lods: lo)
            rig.add(HK.box(V3(1.56, 0.32, 0.02), V3(0, floorY + 0.16, zW - 0.014), carpet, r: 0.004, seg: 1), to: "body", lods: lo)
            rig.add(HK.box(V3(0.3, 0.09, 2.1), V3(0, floorY + 0.05, 0.0 - 0.45), carpet, r: 0.04, seg: 2), to: "body", lods: lo)
            rig.add(HK.box(V3(2 * wBelt(zTF + 0.2) - 0.1, 0.03, 0.4), V3(0, belt(zTF + 0.2) - 0.02, zTF + 0.22), trimM, r: 0.01, seg: 1), to: "body", lods: lo)

            // Dash: one swept body (windshield base, top pad, face, knee bolster), profile is (height, z).
            let dashProfile: [V2] = [V2(0.930, zW - 0.02), V2(0.975, zW - 0.22), V2(0.992, zW - 0.40), V2(0.985, zW - 0.50), V2(0.955, zW - 0.545),
                                     V2(0.90, dashFace), V2(0.82, dashFace - 0.004), V2(0.74, zW - 0.545), V2(0.66, zW - 0.50), V2(0.50, zW - 0.42), V2(0.46, zW - 0.02)]
            let dashX: Float = 0.78
            rig.add(Prim.sweep(dashProfile, along: [V3(-dashX, 0, 0), V3(-0.26, 0, 0), V3(0.26, 0, 0), V3(dashX, 0, 0)], up: V3(0, 1, 0), material: dashM), to: "body", lods: lo)
            // Instrument hood and cluster behind the wheel, driver side.
            let dx: Float = 0.37
            rig.add(HK.box(V3(0.46, 0.1, 0.17), V3(dx, 1.02, zW - 0.46), trimM, r: 0.02, seg: 1), to: "body", lods: lo)
            rig.add(HK.box(V3(0.4, 0.085, 0.006), V3(dx, 1.0, zW - 0.552), piano, r: 0.004, seg: 1, rot: simd_quatf(angle: 0.18, axis: V3(1, 0, 0))), to: "body", lods: lo)
            for sx: Float in [-1, 1] {
                rig.add(HK.cyl(r: 0.044, len: 0.006, at: V3(dx + sx * 0.1, 1.0, zW - 0.557), axis: simd_normalize(V3(0, 0.2, -1)), mat: screenM, seg: l == 0 ? 20 : 8), to: "body", lods: lo)
            }
            if l == 0 {
                rig.add(HK.box(V3(0.003, 0.036, 0.002), V3(dx - 0.1 + 0.012, 1.0 + 0.004, zW - 0.562), "emissive.signal-orange", r: 0.0008, seg: 1, rot: simd_quatf(angle: -0.9, axis: V3(0, 0, 1))), to: "body", lods: lo)
                rig.add(HK.box(V3(0.003, 0.036, 0.002), V3(dx + 0.1 - 0.008, 1.0 + 0.008, zW - 0.562), "emissive.signal-orange", r: 0.0008, seg: 1, rot: simd_quatf(angle: 0.6, axis: V3(0, 0, 1))), to: "body", lods: lo)
            }
            // Center screen in a piano-black bezel, honeycomb vent strip and four outlets.
            rig.add(HK.box(V3(0.25, 0.15, 0.03), V3(0, 0.915, dashFace - 0.015), piano, r: 0.01, seg: 1), to: "body", lods: lo)
            rig.add(HK.box(V3(0.215, 0.118, 0.004), V3(0, 0.915, dashFace - 0.032), screenM, r: 0.002, seg: 1, rot: simd_quatf(angle: 0.06, axis: V3(1, 0, 0))), to: "body", lods: lo)
            rig.add(HK.box(V3(1.3, 0.036, 0.008), V3(0, 0.80, dashFace - 0.004), "metal.satin-aluminum", r: 0.002, seg: 1), to: "body", lods: lo)
            for vx: Float in [-0.62, -0.3, 0.3, 0.62] {
                rig.add(HK.box(V3(0.11, 0.045, 0.014), V3(vx, 0.80, dashFace - 0.008), piano, r: 0.006, seg: 1), to: "body", lods: lo)
            }
            if l == 0 {
                rig.add(HK.box(V3(0.4, 0.05, 0.012), V3(0, 0.74, dashFace + 0.03), trimM, r: 0.004, seg: 1), to: "body", lods: lo)
                rig.add(HK.box(V3(0.34, 0.2, 0.012), V3(-dx, 0.84, dashFace - 0.0), trimM, r: 0.01, seg: 1), to: "body", lods: lo)
            }

            // Steering wheel in its own frame: +Y is the column axis, +Z points to the bottom spoke.
            let sw = V3(dx, 0.88, zW - 0.665), wq = simd_quatf(angle: Float.pi / 2 + 0.38, axis: V3(1, 0, 0))
            let wheelX = Xform(translation: sw, rotation: wq)
            rig.add(Prim.torus(major: 0.18, minor: 0.017, segments: l == 0 ? 32 : 14, sides: l == 0 ? 10 : 6, material: "leather.black").transformed(wheelX), to: "body", lods: lo)
            rig.add(HK.box(V3(0.11, 0.03, 0.095), V3(0, 0, 0), trimM, r: 0.012, seg: 1).transformed(wheelX), to: "body", lods: lo)
            rig.add(HK.box(V3(0.16, 0.014, 0.036), V3(0.095, 0, 0.004), trimM, r: 0.006, seg: 1).transformed(wheelX), to: "body", lods: lo)
            rig.add(HK.box(V3(0.16, 0.014, 0.036), V3(-0.095, 0, 0.004), trimM, r: 0.006, seg: 1).transformed(wheelX), to: "body", lods: lo)
            rig.add(HK.box(V3(0.034, 0.014, 0.12), V3(0, 0, 0.095), trimM, r: 0.006, seg: 1).transformed(wheelX), to: "body", lods: lo)
            rig.add(HK.cyl(r: 0.02, len: 0.004, at: V3(0, -0.016, 0), axis: V3(0, 1, 0), mat: "metal.chrome", seg: l == 0 ? 14 : 6).transformed(wheelX), to: "body", lods: lo)
            let colAxis = wq.act(V3(0, 1, 0))
            rig.add(HK.cyl(r: 0.05, len: 0.15, at: sw + colAxis * 0.085, axis: colAxis, mat: trimM, seg: l == 0 ? 14 : 6), to: "body", lods: lo)
            if l == 0 {
                for sx: Float in [-1, 1] {
                    rig.add(HK.cyl(r: 0.007, len: 0.1, at: sw + colAxis * 0.04 + V3(sx * 0.1, 0, 0), axis: simd_normalize(V3(sx, 0, 0.35)), mat: trimM, seg: 8), to: "body", lods: lo)
                }
                // Pedals on the toeboard.
                for (px, pw) in [(Float(0.27), Float(0.1)), (0.40, 0.065), (0.5, 0.15)] {
                    rig.add(HK.box(V3(pw, 0.012, 0.14), V3(px, 0.5, zW - 0.1), "rubber.floor-mat", r: 0.004, seg: 1, rot: simd_quatf(angle: -0.5, axis: V3(1, 0, 0))), to: "body", lods: lo)
                }
            }

            // Center console: tray, shifter, brake lever bay and armrest.
            rig.add(HK.box(V3(0.26, 0.3, 0.8), V3(0, 0.49, 0.0), trimM, r: 0.03, seg: 2), to: "body", lods: lo)
            rig.add(HK.box(V3(0.22, 0.004, 0.2), V3(0, 0.642, 0.3), "plastic.gloss:08090A", r: 0.002, seg: 1), to: "body", lods: lo)
            rig.add(HK.box(V3(0.12, 0.022, 0.15), V3(0, 0.65, 0.22), "leather.black", r: 0.008, seg: 1), to: "body", lods: lo)
            rig.add(HK.cyl(r: 0.008, len: 0.1, at: V3(0, 0.7, 0.22), axis: V3(0, 1, 0), mat: "metal.chrome", seg: 8), to: "body", lods: lo)
            rig.add(Prim.superellipsoid(V3(0.055, 0.07, 0.055), exponent: 3, subdivisions: l == 0 ? 3 : 2, material: "leather.black"), Xform(translation: V3(0, 0.76, 0.22)), to: "body", lods: lo)
            rig.add(HK.box(V3(0.23, 0.07, 0.34), V3(0, 0.675, -0.31), "leather.black", r: 0.025, seg: 2), to: "body", lods: lo)

            // Seats: cloth cushion and back, bolsters, headrests on posts.
            let lean: Float = -0.22, lq = simd_quatf(angle: lean, axis: V3(1, 0, 0))
            func seat(_ cx: Float, _ sz: Float, w: Float, heads: [Float]) -> [Surface] {
                var out: [Surface] = []
                out.append(HK.box(V3(w, 0.13, 0.52), V3(cx, 0.5, sz), cloth, r: 0.05, seg: 2))
                out.append(HK.box(V3(w - 0.04, 0.05, 0.46), V3(cx, 0.43, sz), trimM, r: 0.01, seg: 1))
                let base = V3(cx, 0.565, sz - 0.25)
                let up = lq.act(V3(0, 1, 0))
                out.append(HK.box(V3(w, 0.58, 0.12), base + up * 0.29, cloth, r: 0.05, seg: 2, rot: lq))
                if l == 0 {
                    for sx: Float in [-1, 1] {
                        out.append(HK.box(V3(0.07, 0.5, 0.15), base + up * 0.26 + V3(sx * (w / 2 - 0.03), 0, 0.012), cloth, r: 0.03, seg: 1, rot: lq))
                        out.append(HK.box(V3(0.08, 0.075, 0.5), V3(cx + sx * (w / 2 - 0.035), 0.57, sz + 0.005), cloth, r: 0.03, seg: 1))
                    }
                }
                for hx in heads {
                    out.append(HK.box(V3(0.25, 0.15, 0.09), base + up * 0.7 + V3(hx, 0, 0), cloth, r: 0.04, seg: 1, rot: lq))
                    for px: Float in [-0.07, 0.07] {
                        out.append(HK.cyl(r: 0.007, len: 0.09, at: base + up * 0.6 + V3(hx + px, 0, 0), axis: up, mat: "metal.chrome", seg: 6))
                    }
                }
                return out
            }
            for sx: Float in [-1, 1] {
                for srf in seat(sx * 0.37, -0.22, w: 0.52, heads: [0]) { rig.add(srf, to: "body", lods: lo) }
            }
            for srf in seat(0, -0.98, w: 1.4, heads: [-0.4, 0, 0.4]) { rig.add(srf, to: "body", lods: lo) }

            // Door trim: armrest, pull handle, speaker grille, window switch bank.
            if l == 0 {
                for sx: Float in [-1, 1] {
                    for dz in [Float(0.3), -0.85] {
                        let dxw = sx * 0.78
                        rig.add(HK.box(V3(0.075, 0.05, 0.4), V3(dxw, 0.78, dz), trimM, r: 0.02, seg: 1), to: "body", lods: lo)
                        rig.add(HK.cyl(r: 0.009, len: 0.2, at: V3(sx * 0.795, 0.85, dz - 0.02), axis: V3(0, 0, 1), mat: "metal.satin-aluminum", seg: 8), to: "body", lods: lo)
                        rig.add(HK.cyl(r: 0.07, len: 0.01, at: V3(sx * 0.81, 0.5, dz), axis: V3(1, 0, 0), mat: "plastic.gloss:0A0A0B", seg: 14), to: "body", lods: lo)
                    }
                    rig.add(HK.box(V3(0.04, 0.012, 0.16), V3(sx * 0.785, 0.81, 0.4), "plastic.gloss:0E0F10", r: 0.003, seg: 1), to: "body", lods: lo)
                }
            }

            // Seat belts: webbing from the B pillar to the buckle (front seats).
            if l == 0 {
                for sx: Float in [-1, 1] {
                    let top = V3(sx * 0.76, 1.12, -0.2), buckle = V3(sx * 0.2, 0.6, -0.16)
                    let d = buckle - top, len = simd_length(d), mid = (top + buckle) / 2
                    let q = simd_quatf(from: V3(0, 1, 0), to: simd_normalize(d))
                    rig.add(HK.box(V3(0.046, len, 0.004), mid + V3(sx * -0.0, 0, -0.07), "fabric.webbing:1A1A1A", r: 0.001, seg: 1, rot: q), to: "body", lods: lo)
                    rig.add(HK.box(V3(0.03, 0.05, 0.02), buckle + V3(0, 0, -0.07), "metal.chrome", r: 0.004, seg: 1), to: "body", lods: lo)
                }
            }
            // Pillar trim and headliner (inside of the paint strips), mirror, visors, dome lamp.
            for (a0, a1) in [(Float(0.0), Float(0.17)), (0.83, 1.0)] {
                rig.add(strip(zW - 0.04, zRoofF + 0.06, a0 + (a0 > 0.5 ? 0.06 : 0.04), a1 - (a0 > 0.5 ? 0.04 : 0.06), trimM, outset: -0.012, count: l == 0 ? 8 : 3, sp: 3), to: "body", lods: lo)
                rig.add(strip(zRoofR + 0.05, zTF + 0.3, a0, a1, trimM, outset: -0.012, count: l == 0 ? 8 : 3, sp: 4), to: "body", lods: lo)
                let zB = zFA - 1.62
                rig.add(strip(zB + 0.045, zB - 0.045, a0, a1, trimM, outset: -0.012, count: 1, sp: 4), to: "body", lods: lo)
            }
            rig.add(strip(zRoofF + 0.04, zRoofR - 0.03, 0.13, 0.87, "fabric.headliner", outset: -0.012, count: l == 0 ? 10 : 4, sp: l == 0 ? 12 : 6), to: "body", lods: lo)
            if l == 0 {
                let mzr: Float = 0.3
                rig.add(HK.cyl(r: 0.006, len: 0.07, at: V3(0, roofY(mzr) - 0.045, mzr), axis: V3(0, 1, 0), mat: trimM, seg: 6), to: "body", lods: lo)
                rig.add(HK.box(V3(0.26, 0.065, 0.025), V3(0, roofY(mzr) - 0.095, mzr - 0.02), trimM, r: 0.012, seg: 1), to: "body", lods: lo)
                rig.add(HK.box(V3(0.24, 0.05, 0.004), V3(0, roofY(mzr) - 0.095, mzr - 0.034), "glass.pane", r: 0.002, seg: 1), to: "body", lods: lo)
                for sx: Float in [-1, 1] {
                    rig.add(HK.box(V3(0.34, 0.016, 0.2), V3(sx * 0.4, roofY(0.28) - 0.035, 0.28), "fabric.headliner", r: 0.006, seg: 1), to: "body", lods: lo)
                }
                rig.add(HK.box(V3(0.16, 0.012, 0.09), V3(0, roofY(-0.4) - 0.012, -0.4), "plastic.gloss:E4E4DE", r: 0.004, seg: 1), to: "body", lods: lo)
            }
            // Fuel door outline on the rear left quarter.
            let fz = zRA - 0.3, fs = section(fz)
            rig.add(HK.box(V3(0.004, 0.13, 0.17), V3(CK.sideX(fs, y: 0.82, n: n, tumble: tumble) + 0.002, 0.82, fz), paint, r: 0.02, seg: 1), to: "body", lods: lo)
        }

        // MARK: trunk lid
        rig.part("trunkLid", parent: "body", pivot: V3(0, section(zTF).top, zTF), joint: .hinge(axis: V3(1, 0, 0), 0...80, duration: 1.8))
        // MARK: trunk floor cover, spare
        rig.part("trunkFloor", parent: "body", pivot: V3(0, 0.53, zTF - 0.04), joint: .hinge(axis: V3(1, 0, 0), 0...85, duration: 1.2))
        let ths: Float = 0.2 * .pi
        for l in 0..<2 {
            let lo = l...l, pts = l == 0 ? 14 : 8
            let lz = stations(zTF + 0.005, zLidR - 0.004, l == 0 ? 8 : 4)
            let lid = lz.map { z -> [V3] in
                let s = section(z)
                var outer: [V3] = [], inner: [V3] = []
                for k in 0...pts {
                    let th = Float.pi - ths - (Float.pi - 2 * ths) * Float(k) / Float(pts)
                    var p = CK.point(s, th, n: n, tumble: tumble, inset: -0.003); p.z = z
                    var q = CK.point(s, th, n: n, tumble: tumble, inset: 0.02); q.z = z
                    q.y = max(q.y, p.y - 0.03)
                    outer.append(p); inner.append(q)
                }
                return outer + inner.reversed()
            }
            rig.add(Prim.loft(lid, capStart: true, capEnd: true, material: paint), to: "trunkLid", lods: lo)
            // Lid lip spoiler, badge and inner liner.
            let ls = section(zLidR + 0.03)
            rig.add(HK.box(V3(ls.halfWidth * 1.3, 0.012, 0.04), V3(0, ls.top + 0.006, zLidR + 0.03), paint, r: 0.005, seg: 1), to: "trunkLid", lods: lo)
            rig.add(cuboid(V3(0.11, 0.05, 0.006), material: "metal.chrome"), Xform(translation: V3(0, section(zLidR + 0.02).top - 0.05, zLidR - 0.008)), to: "trunkLid", lods: lo)
            // Full-width light bar across the lid edge.
            rig.add(cuboid(V3(ls.halfWidth * 1.45, 0.028, 0.012), material: "emissive.signal-red"), Xform(translation: V3(0, ls.top - 0.06, zLidR - 0.002)), to: "trunkLid", lods: lo)
            // Floor cover: carpeted hardboard with a pull strap.
            let fl = section((zTF + zLidR) / 2)
            rig.add(cuboid(V3(fl.halfWidth * 2 - 0.2, 0.014, zTF - zLidR - 0.1), material: "carpet.tile:2A2B2D"), Xform(translation: V3(0, 0.53, (zTF + zLidR) / 2 - 0.01)), to: "trunkFloor", lods: lo)
            rig.add(cuboid(V3(0.12, 0.004, 0.06), material: "fabric.webbing:1A1A1A"), Xform(translation: V3(0, 0.539, zLidR + 0.1)), to: "trunkFloor", lods: lo)
            // Spare well: black tub with the temporary spare lying flat (static on the body).
            let wc = V3(0, 0.36, (zTF + zLidR) / 2)
            rig.add(Prim.lathe([V2(0.0, 0.0), V2(0.37, 0.0), V2(0.38, 0.01), V2(0.39, 0.16), V2(0.4, 0.165)], segments: l == 0 ? 18 : 10, material: "plastic.matte:1B1C1E")
                .flipped().transformed(Xform(translation: wc - V3(0, 0.01, 0))), to: "body", lods: lo)
            let spare = CK.WheelSpec(tireRadius: 0.322, tireWidth: 0.155, rimRadius: 0.216, lugs: 5, pcdRadius: 0.057, spokes: 0, rim: "metal.painted:1C1D1F", rubber: "rubber.tire")
            for srf in CK.wheel(spare, lod: 1) {
                rig.add(srf, Xform(translation: wc + V3(0, 0.08, 0), rotation: simd_quatf(angle: .pi / 2, axis: V3(0, 0, 1))), to: "body", lods: lo)
            }
        }

        // MARK: hazard button, hazard lamps, parking brake
        let hb = V3(0, 0.87, zW - 0.552)
        rig.part("hazardButton", parent: "body", pivot: hb, joint: .slide(axis: V3(0, 0, 1), 0...0.005, duration: 0.2), options: 2)
        rig.part("hazardLamps", parent: "body", pivot: .zero, joint: .fixed, options: 2)
        rig.part("parkingBrake", parent: "body", pivot: V3(0, 0.645, -0.12), joint: .hinge(axis: V3(-1, 0, 0), 0...30, duration: 0.6))
        for l in 0..<2 {
            let lo = l...l
            rig.add(HK.box(V3(0.05, 0.035, 0.015), hb, "plastic.gloss:B01810", r: 0.004, seg: 1), to: "hazardButton", lods: lo)
            rig.add(HK.box(V3(0.05, 0.035, 0.015), hb, "emissive.signal-red", r: 0.004, seg: 1), to: "hazardButton", option: 1, lods: lo)
            for opt in 0..<2 {
                let amber: MaterialKey = opt == 0 ? "plastic.gloss:B86A12" : "emissive.signal-orange"
                for sx: Float in [-1, 1] {
                    let fz = zF - 0.3, fs = section(fz)
                    rig.add(cuboid(V3(0.1, 0.025, 0.06), material: amber), Xform(translation: V3(sx * (fs.halfWidth - 0.08), 0.62, zF - 0.16), rotation: simd_quatf(angle: sx * 0.6, axis: .up)), to: "hazardLamps", option: opt, lods: lo)
                    rig.add(cuboid(V3(0.006, 0.018, 0.06), material: amber), Xform(translation: V3(sx * (wBelt(zW - 0.18) + 0.225), belt(zW - 0.18) + 0.06, zW - 0.2)), to: "hazardLamps", option: opt, lods: lo)
                    let rz = zR + 0.07, rs = section(rz)
                    rig.add(cuboid(V3(0.14, 0.03, 0.03), material: amber), Xform(translation: V3(sx * (rs.halfWidth - 0.22), 0.8, rz - 0.02), rotation: simd_quatf(angle: -sx * 0.3, axis: .up)), to: "hazardLamps", option: opt, lods: lo)
                }
            }
            // Parking brake lever with grip and release button.
            let pb = V3(0, 0.645, -0.12)
            rig.add(HK.box(V3(0.04, 0.04, 0.26), pb + V3(0, 0.02, 0.13), "plastic.dash", r: 0.012, seg: 1), to: "parkingBrake", lods: lo)
            rig.add(HK.cyl(r: 0.012, len: 0.02, at: pb + V3(0, 0.02, 0.27), axis: V3(0, 0, 1), mat: "metal.chrome", seg: 8), to: "parkingBrake", lods: lo)
        }
        rig.optionLinks = [RigOptionLink(part: "hazardButton", joint: "hazardButton", thresholds: [0.004]),
                           RigOptionLink(part: "hazardLamps", joint: "hazardButton", thresholds: [0.004])]

        // MARK: wheels
        let spec = CK.WheelSpec(tireRadius: R, tireWidth: 0.235, rimRadius: 0.2286, lugs: 5, pcdRadius: 0.05715, spokes: 5, rim: "metal.aluminum-brushed:B9BCC0", rubber: "rubber.tire")
        CK.rigWheels(&rig, spec: spec, frontZ: zFA, rearZ: zRA, frontTrack: frontTrack, rearTrack: rearTrack, liftMax: Self.liftMax, droop: 0.6, detach: 0.35)

        groundAO(&rig, height: 0.25)
        let lugs = Dictionary(uniqueKeysWithValues: (0..<5).map { ("wheel.frontLeft.lug\($0)", Float(0.05)) })
        rig.states = [
            RigState("parked"),
            RigState("trunk-open", ["trunkLid": 80]),
            RigState("spare-access", ["trunkLid": 80, "trunkFloor": 85]),
            RigState("hazards-on", ["hazardButton": 0.005], options: ["hazardButton": 1, "hazardLamps": 1]),
            RigState("brake-set", ["parkingBrake": 28]),
            RigState("jacked", ["body": 0.12]),
            RigState("lugs-loose", ["body": 0.12].merging(lugs) { a, _ in a }),
            RigState("wheel-off", ["body": 0.12, "wheel.frontLeft": 0.35].merging(lugs) { a, _ in a }),
        ]
        return rig
    }
}
