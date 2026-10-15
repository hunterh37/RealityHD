import simd
import Foundation

/// Full-size SuperCrew pickup at 1:1 (2024 F-150 class, 3683 mm wheelbase, 5.5 ft box), front faces +Z,
/// driver side +X. Boxy lofted cab and bed in clearcoat paint, chrome grille, headlights, tail lamps,
/// tinted greenhouse, running boards, tailgate, under-bed spare hung on a winch cable, scissor jack
/// stowed behind the rear seat.
///
/// Parts: `body` (lift slide 0...0.18 m), `suspension.<corner>` (droop, mimic of `body`),
/// `wheel.<corner>` (slides off 0...0.4 m), `wheel.<corner>.lug0...lug5` (unscrew 0...0.05 m),
/// `tailgate` (0...90), `spareWinch` (lowers the spare 0...0.3 m on its cable).
/// States: `parked`, `tailgate-open`, `spare-lowered`, `jacked`, `lugs-loose`, `wheel-off`.
public struct PickupTruck: RealArticulated {
    public static let id = "pickup-truck"
    public static let summary = "Full-size crew-cab pickup at 1:1: boxy cab, 5.5 ft bed, tailgate, four live wheels with six lug nuts, under-bed spare on a winch cable."
    public static let tags = ["prop", "vehicle", "articulated", "street", "road", "metal", "glass", "rubber"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 14, distance: 1.0)

    /// Wheelbase in meters (SuperCrew 5.5 ft box 3.683).
    public var wheelbase: Float = 3.683
    /// Track, wheel center to wheel center, meters.
    public var track: Float = 1.73
    /// Tire outer diameter (275/60R20 = 0.84 m).
    public var tireDiameter: Float = 0.84
    /// Front overhang, meters.
    public var frontOverhang: Float = 0.95
    /// Rear overhang, meters.
    public var rearOverhang: Float = 1.25
    /// Body half width (2.03 m overall without mirrors).
    public var halfWidth: Float = 1.0
    /// Roof height, meters.
    public var roofHeight: Float = 1.96
    /// Body paint (tint with `:RRGGBB`).
    public var paint: MaterialKey = "paint.car-clearcoat:6B1E1A"
    /// Window glass.
    public var glass: MaterialKey = "glass.tinted"
    public static let liftMax: Float = 0.18
    public init() {}

    public func rig(seed: UInt64) -> Rig {
        var rig = Rig(name: Self.id, lods: 2, switchDistances: [18])
        let L = frontOverhang + wheelbase + rearOverhang, zF = L / 2, zR = -L / 2
        let zFA = zF - frontOverhang, zRA = zFA - wheelbase
        let R = tireDiameter / 2, archR = R + 0.07
        let zW = zFA - 0.72, zRoofF = zW - 0.5, zCB = zR + 1.78, zBF = zCB - 0.05
        let n: Float = 7, tumble: Float = 0.03
        let topKeys: [(Float, Float)] = [(zR, 1.36), (zCB, 1.38), (zW, 1.37), (zFA, 1.34), (zF - 0.12, 1.3), (zF, 1.2)]
        let botKeys: [(Float, Float)] = [(zR, 0.6), (zRA - archR - 0.05, 0.52), (zFA + archR + 0.05, 0.5), (zF - 0.3, 0.45), (zF, 0.5)]
        func section(_ z: Float) -> CK.Section {
            var b = CK.curve(botKeys, z)
            for az in [zFA, zRA] where abs(z - az) < archR { b = max(b, R + sqrt(archR * archR - (z - az) * (z - az))) }
            let zc = (zF + zR) / 2, zn = min(0.999, abs(z - zc) / (L / 2 * 1.02))
            return CK.Section(halfWidth: halfWidth * pow(1 - pow(zn, 12), 1 / 12), bottom: b, top: CK.curve(topKeys, z))
        }
        func stations(_ z0: Float, _ z1: Float, _ c: Int) -> [Float] { (0...c).map { z0 + (z1 - z0) * Float($0) / Float(c) } }
        func bodyStations(_ z0: Float, _ z1: Float, _ step: Float) -> [Float] {
            var out: [Float] = [], z = z0
            while z > z1 { out.append(z); z -= [zFA, zRA].contains { abs(z - $0) < archR + 0.06 } ? step * 0.4 : step }
            return out + [z1]
        }
        func belt(_ z: Float) -> Float { section(z).top - 0.012 }
        func wBelt(_ z: Float) -> Float { section(z).halfWidth * (1 - tumble) - 0.06 }
        let roofKeys: [(Float, Float)] = [(zCB, roofHeight - 0.02), (zCB + 0.6, roofHeight), (zRoofF, roofHeight - 0.02), (zW, 1.38)]
        func roofY(_ z: Float) -> Float { max(belt(z) + 0.008, CK.curve(roofKeys, z)) }
        let crownN: Float = 8

        rig.part("body", pivot: V3(0, 0.8, 0), joint: .slide(axis: .up, 0...Self.liftMax, duration: 3))
        for l in 0..<2 {
            let lo = l...l, pts = l == 0 ? 20 : 12, step: Float = l == 0 ? 0.3 : 0.5
            // MARK: front clip and cab lower body.
            rig.add(Prim.loft(bodyStations(zF, zCB, step).map { CK.ring(section($0), z: $0, n: n, tumble: tumble, points: pts) }, capStart: true, capEnd: true, material: paint), to: "body", lods: lo)
            // MARK: bed: U section (sides, floor), front wall, liner.
            let ths: Float = 0.45 * .pi, half = pts / 2
            let tub = stations(zBF, zR + 0.06, l == 0 ? 6 : 3).map { z -> [V3] in
                let s = section(z)
                var o: [V3] = [], i: [V3] = []
                for k in 0...half {
                    let th = ths - (Float.pi + 2 * ths) * Float(k) / Float(half)
                    var p = CK.point(s, th, n: n, tumble: tumble); p.z = z
                    var q = CK.point(s, th, n: n, tumble: tumble, inset: 0.07); q.z = z; q.y = max(q.y, 0.95)
                    o.append(p); i.append(q)
                }
                return o + i.reversed()
            }
            rig.add(Prim.loft(tub, capStart: false, capEnd: false, material: paint), to: "body", lods: lo)
            let bw = 2 * section(zCB - 0.8).halfWidth
            rig.add(cuboid(V3(bw - 0.16, 0.42, 0.04), material: paint), Xform(translation: V3(0, 1.17, zBF - 0.02)), to: "body", lods: lo)
            rig.add(cuboid(V3(bw - 0.15, 0.012, zBF - zR - 0.1), material: "plastic.matte:1E1F21"), Xform(translation: V3(0, 0.956, (zBF + zR) / 2 + 0.03)), to: "body", lods: lo)
            for sx: Float in [-1, 1] {
                // Bed rail caps, tail lamps, stake pockets.
                rig.add(HK.box(V3(0.09, 0.03, zBF - zR - 0.06), V3(sx * (halfWidth - 0.05), 1.38, (zBF + zR) / 2 + 0.03), "plastic.matte:1A1B1C", r: 0.012, seg: 1), to: "body", lods: lo)
                rig.add(HK.box(V3(0.006, 0.22, 0.5), V3(sx * (section(zRA - archR - 0.3).halfWidth + 0.002), 0.75, zRA - archR - 0.3), "decal.rubber-scuff", r: 0.002, seg: 1), to: "body", lods: lo)
                rig.add(cuboid(V3(0.1, 0.32, 0.03), material: "emissive.signal-red"), Xform(translation: V3(sx * (halfWidth - 0.07), 1.15, zR + 0.055)), to: "body", lods: lo)
            }
            // Rear bumper (chrome step bumper) and hitch.
            rig.add(HK.box(V3(2 * halfWidth - 0.1, 0.2, 0.16), V3(0, 0.82, zR + 0.04), "metal.chrome", r: 0.03, seg: 1), to: "body", lods: lo)
            rig.add(cuboid(V3(0.07, 0.07, 0.25), material: "metal.painted:1A1B1C"), Xform(translation: V3(0, 0.66, zR + 0.0)), to: "body", lods: lo)
            rig.add(cuboid(V3(0.31, 0.155, 0.01), material: "plastic.gloss:E4E4DE"), Xform(translation: V3(0, 0.82, zR - 0.042)), to: "body", lods: lo)
            // MARK: greenhouse, roof, pillars.
            rig.add(Prim.loft(stations(zW, zCB, l == 0 ? 10 : 5).map { CK.cabinRing(z: $0, belt: belt($0), roof: roofY($0), wBelt: wBelt($0), wTop: wBelt($0) - 0.12, n: crownN, points: l == 0 ? 18 : 10) }, capEnd: true, material: glass), to: "body", lods: lo)
            func strip(_ z0: Float, _ z1: Float, _ a0: Float, _ a1: Float, _ mat: MaterialKey, outset: Float, count: Int, sp: Int) -> Surface {
                Prim.loft(stations(z0, z1, count).map { CK.crownStrip(z: $0, belt: belt($0), roof: roofY($0), wBelt: wBelt($0), wTop: wBelt($0) - 0.12, n: crownN, a0: a0, a1: a1, points: sp, outset: outset, thick: 0.014) },
                          capStart: true, capEnd: true, material: mat)
            }
            rig.add(strip(zRoofF + 0.04, zCB, 0.1, 0.9, paint, outset: 0.014, count: l == 0 ? 6 : 3, sp: l == 0 ? 12 : 6), to: "body", lods: lo)
            for (a0, a1) in [(Float(0.0), Float(0.14)), (0.86, 1.0)] {
                rig.add(strip(zW - 0.03, zRoofF + 0.06, a0, a1, paint, outset: 0.016, count: l == 0 ? 5 : 2, sp: 3), to: "body", lods: lo)
                rig.add(strip(zCB + 0.16, zCB, a0, a1, paint, outset: 0.016, count: 1, sp: 3), to: "body", lods: lo)
                for zb in [zFA - 1.55] {
                    rig.add(strip(zb + 0.05, zb - 0.05, a0, a1, "plastic.gloss:121314", outset: 0.014, count: 1, sp: 3), to: "body", lods: lo)
                }
            }
            // Rear window black frame with sliding center pane.
            rig.add(cuboid(V3(2 * wBelt(zCB) - 0.3, 0.38, 0.012), material: "plastic.gloss:121314"), Xform(translation: V3(0, (belt(zCB) + roofY(zCB)) / 2, zCB - 0.004)), to: "body", lods: lo)
            // Arch liners and black arch flares.
            for az in [zFA, zRA] {
                for sx: Float in [-1, 1] {
                    rig.add(CK.archLiner(center: V3(0, R, az), radius: archR - 0.005, x0: sx * (track / 2 - 0.2), x1: sx * (section(az).halfWidth - 0.02), mat: "plastic.matte:151617"), to: "body", lods: lo)
                }
            }
            // MARK: front: chrome grille frame with dark mesh, headlights, fog lamps, plate.
            rig.add(HK.box(V3(1.2, 0.48, 0.05), V3(0, 1.0, zF - 0.02), "metal.chrome", r: 0.03, seg: 1), to: "body", lods: lo)
            rig.add(cuboid(V3(1.08, 0.38, 0.04), material: "plastic.gloss:0E0F10"), Xform(translation: V3(0, 1.0, zF - 0.005)), to: "body", lods: lo)
            if l == 0 {
                for k in 0..<4 { rig.add(cuboid(V3(1.06, 0.018, 0.02), material: "metal.chrome"), Xform(translation: V3(0, 0.86 + Float(k) * 0.09, zF + 0.012)), to: "body", lods: lo) }
            }
            rig.add(HK.box(V3(2 * halfWidth - 0.14, 0.24, 0.14), V3(0, 0.62, zF - 0.06), "metal.chrome", r: 0.04, seg: 1), to: "body", lods: lo)
            rig.add(cuboid(V3(0.31, 0.155, 0.01), material: "plastic.gloss:E4E4DE"), Xform(translation: V3(0, 0.62, zF + 0.012)), to: "body", lods: lo)
            for sx: Float in [-1, 1] {
                rig.add(HK.box(V3(0.3, 0.22, 0.03), V3(sx * 0.78, 1.06, zF - 0.03), "plastic.gloss:15161A", r: 0.012, seg: 1), to: "body", lods: lo)
                rig.add(HK.box(V3(0.31, 0.23, 0.02), V3(sx * 0.78, 1.06, zF - 0.005), "glass.pane", r: 0.008, seg: 1), to: "body", lods: lo)
                rig.add(cuboid(V3(0.025, 0.2, 0.02), material: "emissive.signal-white"), Xform(translation: V3(sx * 0.66, 1.06, zF - 0.002)), to: "body", lods: lo)
                rig.add(cuboid(V3(0.12, 0.05, 0.02), material: "emissive.signal-orange"), Xform(translation: V3(sx * 0.76, 0.98, zF - 0.008)), to: "body", lods: lo)
                // Mirrors (towing-style caps), door seams, handles, running boards.
                let mz = zW - 0.2, mw = wBelt(mz)
                rig.add(cuboid(V3(0.14, 0.06, 0.1), material: "plastic.matte:1A1B1C"), Xform(translation: V3(sx * (mw + 0.08), belt(mz) + 0.04, mz)), to: "body", lods: lo)
                rig.add(HK.box(V3(0.12, 0.3, 0.12), V3(sx * (mw + 0.2), belt(mz) + 0.14, mz - 0.03), "plastic.matte:1A1B1C", r: 0.03, seg: 1), to: "body", lods: lo)
                rig.add(cuboid(V3(0.1, 0.27, 0.006), material: "glass.pane"), Xform(translation: V3(sx * (mw + 0.2), belt(mz) + 0.14, mz - 0.093)), to: "body", lods: lo)
                if l == 0 {
                    for dz in [zW - 0.05, zFA - 1.55, zCB + 0.02] {
                        let s = section(dz)
                        let path = stride(from: s.bottom + 0.05, through: s.top - 0.02, by: 0.2).map { y in V3(sx * (CK.sideX(s, y: y, n: n, tumble: tumble) + 0.0005), y, dz) }
                        rig.add(HK.pipe(path, r: 0.003, sides: 4, mat: "plastic.gloss:0A0A0B"), to: "body", lods: lo)
                    }
                    for hz in [zFA - 1.4, zCB + 0.2] {
                        let s = section(hz)
                        rig.add(cuboid(V3(0.025, 0.04, 0.2), material: "metal.chrome"), Xform(translation: V3(sx * (CK.sideX(s, y: 1.22, n: n, tumble: tumble) + 0.01), 1.22, hz)), to: "body", lods: lo)
                    }
                }
                let rz0 = zFA - archR - 0.05, rz1 = zRA + archR + 0.05
                rig.add(HK.box(V3(0.2, 0.045, rz0 - rz1), V3(sx * (halfWidth - 0.02), 0.42, (rz0 + rz1) / 2), "plastic.matte:1A1B1C", r: 0.015, seg: 1), to: "body", lods: lo)
                for bz in [rz0 - 0.4, rz1 + 0.4] {
                    rig.add(cuboid(V3(0.2, 0.08, 0.04), material: "metal.painted:1A1B1C"), Xform(translation: V3(sx * (halfWidth - 0.15), 0.48, bz)), to: "body", lods: lo)
                }
            }
            // Frame rails visible under the bed, spare winch housing.
            for sx: Float in [-1, 1] {
                rig.add(cuboid(V3(0.08, 0.2, L - 1.0), material: "metal.painted:1A1B1C"), Xform(translation: V3(sx * 0.55, 0.58, -0.1)), to: "body", lods: lo)
            }
            rig.add(cuboid(V3(0.14, 0.1, 0.14), material: "metal.painted:1A1B1C"), Xform(translation: V3(0, 0.88, zR + 0.45)), to: "body", lods: lo)
            // MARK: interior: floor, dash, seats, wheel, jack behind rear seat.
            let cz0 = zW - 0.3, cz1 = zCB + 0.03
            rig.add(cuboid(V3(2 * wBelt((cz0 + cz1) / 2) - 0.02, 0.01, cz0 - cz1), material: "carpet.tile:1E1F21"), Xform(translation: V3(0, 1.37, (cz0 + cz1) / 2)), to: "body", lods: lo)
            rig.add(HK.box(V3(1.7, 0.16, 0.4), V3(0, 1.43, zW - 0.42), "plastic.dash", r: 0.04, seg: 1), to: "body", lods: lo)
            for sx: Float in [-1, 1] {
                for sz in [zFA - 1.35, zCB + 0.45] {
                    rig.add(Prim.superellipsoid(V3(0.56, 0.12, 0.5), exponent: 5, subdivisions: 2, material: "vinyl.seat-grey:2F3134"), Xform(translation: V3(sx * 0.42, 1.4, sz)), to: "body", lods: lo)
                    rig.add(Prim.superellipsoid(V3(0.56, 0.5, 0.13), exponent: 5, subdivisions: 2, material: "vinyl.seat-grey:2F3134"), Xform(translation: V3(sx * 0.42, 1.62, sz - 0.27), rotation: simd_quatf(angle: -0.2, axis: V3(1, 0, 0))), to: "body", lods: lo)
                }
            }
            let sw = V3(0.42, 1.56, zW - 0.72)
            rig.add(Prim.torus(major: 0.19, minor: 0.017, segments: l == 0 ? 18 : 10, sides: 6, material: "leather.black")
                .transformed(Xform(translation: sw, rotation: simd_quatf(angle: .pi / 2 - 0.35, axis: V3(1, 0, 0)))), to: "body", lods: lo)
            // Factory scissor jack in its foam tray behind the rear seat back.
            let jc = V3(0.3, 1.48, zCB + 0.1)
            rig.add(cuboid(V3(0.5, 0.18, 0.1), material: "plastic.matte:151515"), Xform(translation: jc - V3(0, 0.03, 0)), to: "body", lods: lo)
            for k in 0..<2 {
                let a: Float = k == 0 ? 0.35 : -0.35
                rig.add(cuboid(V3(0.4, 0.035, 0.05), material: "metal.painted:1A1B1C"), Xform(translation: jc + V3(0, 0.03, 0.02), rotation: simd_quatf(angle: a, axis: V3(0, 0, 1))), to: "body", lods: lo)
            }
            rig.add(HK.cyl(r: 0.008, len: 0.46, at: jc + V3(0, 0.03, 0.05), axis: V3(1, 0, 0), mat: "metal.steel", seg: 6), to: "body", lods: lo)
        }

        // MARK: tailgate
        let tgz = zR + 0.06
        rig.part("tailgate", parent: "body", pivot: V3(0, 0.96, tgz), joint: .hinge(axis: V3(-1, 0, 0), 0...90, duration: 1.5))
        // MARK: under-bed spare on its winch cable
        let sc = V3(0, 0.66, zR + 0.45)
        rig.part("spareWinch", parent: "body", pivot: sc, joint: .slide(axis: V3(0, -1, 0), 0...0.3, duration: 4))
        let spare = CK.WheelSpec(tireRadius: R, tireWidth: 0.275, rimRadius: 0.254, lugs: 6, pcdRadius: 0.0675, spokes: 0, rim: "metal.painted:1C1D1F", rubber: "rubber.truck-tire")
        for l in 0..<2 {
            let lo = l...l
            let tw = 2 * section(tgz).halfWidth - 0.12
            rig.add(HK.box(V3(tw, 0.42, 0.06), V3(0, 1.17, tgz - 0.01), paint, r: 0.015, seg: 1), to: "tailgate", lods: lo)
            rig.add(cuboid(V3(0.28, 0.06, 0.03), material: "metal.chrome"), Xform(translation: V3(0, 1.3, tgz - 0.045)), to: "tailgate", lods: lo)
            rig.add(cuboid(V3(0.3, 0.1, 0.004), material: "metal.chrome"), Xform(translation: V3(0, 1.1, tgz - 0.041)), to: "tailgate", lods: lo)
            rig.add(cuboid(V3(tw - 0.08, 0.36, 0.006), material: "plastic.matte:1E1F21"), Xform(translation: V3(0, 1.17, tgz + 0.022)), to: "tailgate", lods: lo)
            for srf in CK.wheel(spare, lod: 1) {
                rig.add(srf, Xform(translation: sc, rotation: simd_quatf(angle: .pi / 2, axis: V3(0, 0, 1))), to: "spareWinch", lods: lo)
            }
            // Cable runs up from the spare hub into the winch; extra length hides above the bed floor.
            rig.add(HK.cyl(r: 0.004, len: 0.55, at: sc + V3(0, 0.3, 0), axis: .up, mat: "metal.steel", seg: 6), to: "spareWinch", lods: lo)
            rig.add(HK.cyl(r: 0.06, len: 0.02, at: sc + V3(0, 0.15, 0), axis: .up, mat: "metal.painted:1A1B1C", seg: 10), to: "spareWinch", lods: lo)
        }

        // MARK: wheels
        let spec = CK.WheelSpec(tireRadius: R, tireWidth: 0.275, rimRadius: 0.254, lugs: 6, pcdRadius: 0.0675, spokes: 6, rim: "metal.aluminum-brushed:C9CCD0", rubber: "rubber.truck-tire")
        CK.rigWheels(&rig, spec: spec, frontZ: zFA, rearZ: zRA, frontTrack: track, rearTrack: track, liftMax: Self.liftMax, droop: 0.6, detach: 0.4)

        groundAO(&rig, height: 0.3)
        let lugs = Dictionary(uniqueKeysWithValues: (0..<6).map { ("wheel.frontLeft.lug\($0)", Float(0.05)) })
        rig.states = [
            RigState("parked"),
            RigState("tailgate-open", ["tailgate": 90]),
            RigState("spare-lowered", ["spareWinch": 0.3]),
            RigState("jacked", ["body": 0.15]),
            RigState("lugs-loose", ["body": 0.15].merging(lugs) { a, _ in a }),
            RigState("wheel-off", ["body": 0.15, "wheel.frontLeft": 0.4].merging(lugs) { a, _ in a }),
        ]
        return rig
    }
}
