import simd
import Foundation

/// Beaux-Arts curved stone stair, 3.0 m x 2.4 m, 1.5 m high: a quarter-turn flight of six radial limestone treads
/// (90 mm risers, 60 mm bullnose treads on sooted riser blocks) running into a straight 0.6 m landing. Both sides
/// carry a stepped plinth wall with a proud coping, turned vase balusters, a sloped moulded handrail and square newel
/// piers (panelled shaft, two-step cap, ball finial). A skirting course runs round the foot with a moss patch
/// and rust stains at the baluster feet.
public struct StoneStairFlightCurved: RealAsset {
    public static let id = "stone-stair-flight-curved"
    public static let summary = "Beaux-Arts curved stone stair, 3.0 m: six limestone treads in a quarter turn, landing, baluster parapets with piers."
    public static let tags = ["prop", "architecture", "facade", "stone", "trim"]
    public static let budget = 15000
    public static let author = "realityhd"
    public static let preview = PreviewHint(azimuth: 35, elevation: 22, distance: 3.4)

    /// Riser height in meters.
    public var rise: Float = 0.09
    /// Number of risers across the 90 degree turn.
    public var steps: Int = 6
    /// Inner edge of the treads (meters from the turn centre).
    public var innerRadius: Float = 1.15
    /// Outer edge of the treads.
    public var outerRadius: Float = 2.2
    /// Straight landing length after the turn.
    public var landing: Float = 0.6
    /// Treads, coping and rail.
    public var stone: MaterialKey = "stone.limestone:EADFC4"
    /// Riser blocks and walls.
    public var sooted: MaterialKey = "stone.limestone-sooted:A39A82"
    /// Balusters.
    public var cast: MaterialKey = "stone.cast-stone:F0E8D2"
    public init() {}

    public func build(seed: UInt64) -> LODModel {
        LODModel(levels: [make(seed: seed, lite: false), make(seed: seed, lite: true)], switchDistances: [6])
    }

    func make(seed: UInt64, lite: Bool) -> Model {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let n = steps, dTh: Float = 90 / Float(n)
        let rI = innerRadius, rO = outerRadius, wallT: Float = 0.12
        let woC = rO + wallT / 2, wiC = rI - wallT / 2
        let treadT: Float = 0.06, plinthUp: Float = 0.10, copeUp: Float = 0.085
        let topY = rise * Float(n)
        func rad(_ d: Float) -> Float { d * .pi / 180 }
        func top(_ i: Int) -> Float { rise * Float(i + 1) }

        // Annular sector prism between radii r0...r1 and angles a0...a1 (degrees), y0...y1.
        func sector(_ r0: Float, _ r1: Float, _ a0: Float, _ a1: Float, _ y0: Float, _ y1: Float, _ mat: MaterialKey, bevel: Float = 0.004) {
            let k = max(2, Int(rad(a1 - a0) * r1 / 0.13))
            var pts: [V2] = []
            for j in 0...k { let a = rad(a0 + (a1 - a0) * Float(j) / Float(k)); pts.append(V2(r1 * cos(a), r1 * sin(a))) }
            for j in 0...k { let a = rad(a1 - (a1 - a0) * Float(j) / Float(k)); pts.append(V2(r0 * cos(a), r0 * sin(a))) }
            m.add(Prim.extrude(pts, depth: y1 - y0, bevel: min(bevel, (y1 - y0) * 0.3), bevelSegments: 1, material: mat),
                  Xform(translation: V3(0, (y0 + y1) / 2, 0), rotation: FA.q(90, FA.X)))
        }
        func bx(_ size: V3, _ c: V3, _ mat: MaterialKey, r: Float = 0.004) { FA.box(&m, size, c, mat, r: r) }

        // Treads, riser blocks, landing.
        let nose: Float = 0.85
        for i in 0..<n {
            let a0 = Float(i) * dTh, a1 = a0 + dTh, t = top(i)
            let tints: [MaterialKey] = [stone, "stone.limestone:DDD0B0", "stone.limestone:F1E8D2", "stone.limestone:D6C9A8"]
            sector(rI, rO, a0 - nose, a1, t - treadT, t, tints[(i * 3 + 1) % 4], bevel: 0.012)
            sector(rI + 0.004, rO - 0.004, a0, a1 - 0.2, 0, t - treadT + 0.004, sooted, bevel: 0)
            if !lite {   // wet dirt band along both tread ends
                sector(rO - 0.05, rO - 0.002, a0 + 1, a1 - 0.5, t - 0.003, t + 0.0007, "stone.limestone-sooted:857B64", bevel: 0)
                sector(rI + 0.002, rI + 0.05, a0 + 1, a1 - 0.5, t - 0.003, t + 0.0007, "stone.limestone-sooted:857B64", bevel: 0)
            }
        }
        bx(V3(landing - 0.004, treadT, rO - rI), V3(-landing / 2 - 0.002, topY - treadT / 2, (rI + rO) / 2), stone, r: 0.012)
        bx(V3(landing - 0.01, topY - treadT + 0.004, rO - rI - 0.008), V3(-landing / 2 - 0.002, (topY - treadT + 0.004) / 2, (rI + rO) / 2), sooted, r: 0.002)

        let wallTints: [MaterialKey] = [sooted, "stone.limestone-sooted:94886F", "stone.limestone-sooted:B0A68C", "stone.limestone-sooted:9C917A"]
        // Walls: stepped plinth with a proud coping, skirting at the foot.
        for (r0, r1) in [(rO - 0.003, rO + wallT), (rI - wallT, rI + 0.003)] {
            for i in 0..<n {
                let a0 = Float(i) * dTh, a1 = a0 + dTh, t = top(i)
                sector(r0, r1, a0, a1, 0, t + copeUp, wallTints[(i * 2 + (r0 > rI ? 0 : 1)) % 4], bevel: lite ? 0 : 0.002)
                sector(r0 - 0.014, r1 + 0.014, a0 - 0.1, a1 + 0.1, t + copeUp, t + plinthUp + 0.0001 + 0.005, stone, bevel: 0.004)
            }
            // Raised panels on the outward face of each plinth step.
            for i in 0..<n {
                let a0 = Float(i) * dTh, t = top(i)
                let outerFace = r0 > rI
                sector(outerFace ? r1 - 0.0005 : r0 - 0.005, outerFace ? r1 + 0.005 : r0 + 0.0005, a0 + 2.2, a0 + dTh - 2.2, 0.115, t + copeUp - 0.035, stone, bevel: 0)
            }
            sector(r0 - 0.014, r1 + 0.014, 0, 90, 0, 0.07, "stone.limestone-sooted:7D735C", bevel: 0.006)
            sector(r0 - 0.018, r1 + 0.018, 0, 90, 0.07, 0.082, stone, bevel: 0.004)
            // Straight run past the turn.
            let zc = (r0 + r1) / 2, zw = r1 - r0
            bx(V3(landing, topY + copeUp, zw), V3(-landing / 2, (topY + copeUp) / 2, zc), sooted, r: 0.002)
            bx(V3(landing, plinthUp - copeUp + 0.005, zw + 0.028), V3(-landing / 2, topY + (copeUp + plinthUp + 0.005) / 2, zc), stone, r: 0.004)
            bx(V3(landing + 0.014, 0.07, zw + 0.028), V3(-landing / 2 - 0.007, 0.035, zc), stone, r: 0.006)
            bx(V3(landing + 0.018, 0.012, zw + 0.036), V3(-landing / 2 - 0.009, 0.076, zc), stone, r: 0.004)
        }

        // Handrail centreline height at angle d (degrees): sloped through the nosings, level on the landing.
        let railOff: Float = 0.755
        func railY(_ d: Float) -> Float { railOff + rise * (min(d, Float(n - 1) * dTh) / dTh + 1) }

        func pier(at p: V2, yaw: Float, height: Float) {
            var pm = Model(name: "pier")
            func b(_ s: V3, _ y: Float, _ mat: MaterialKey, r: Float = 0.004) { FA.box(&pm, s, V3(0, y, 0), mat, r: r) }
            b(V3(0.30, 0.12, 0.30), 0.06, "stone.limestone-sooted:7D735C", r: 0.007)
            b(V3(0.24, height - 0.33, 0.24), 0.134 + (height - 0.33) / 2, sooted, r: 0.004)
            for sgn: Float in [-1, 1] {
                pm.add(Prim.roundedBox(V3(0.15, max(0.1, height - 0.52), 0.004), radius: 0.001, bevelSegments: 1, material: stone),
                       Xform(translation: V3(0, 0.30 + max(0.1, height - 0.52) / 2 - 0.05, sgn * 0.121)))
                pm.add(Prim.roundedBox(V3(0.004, max(0.1, height - 0.52), 0.15), radius: 0.001, bevelSegments: 1, material: stone),
                       Xform(translation: V3(sgn * 0.121, 0.30 + max(0.1, height - 0.52) / 2 - 0.05, 0)))
            }
            b(V3(0.31, 0.06, 0.31), height - 0.15, stone, r: 0.008)
            b(V3(0.26, 0.04, 0.26), height - 0.10, stone, r: 0.006)
            b(V3(0.20, 0.03, 0.20), height - 0.035, stone, r: 0.005)
            b(V3(0.15, 0.02, 0.15), height - 0.01, stone, r: 0.004)
            pm.add(Prim.superellipsoid(V3(repeating: 0.11), exponent: 2, subdivisions: 3, material: stone), Xform(translation: V3(0, height + 0.03, 0)))
            m.add(pm, Xform(translation: V3(p.x, 0, p.y), rotation: FA.q(yaw, FA.Y)))
        }

        // Baluster profile: vase between a plinth bead and a neck, built 0.62 m tall and scaled in y.
        let H0: Float = 0.62
        let prof: [(Float, Float)] = [(0, 0), (0.032, 0), (0.033, 0.03), (0.022, 0.05), (0.020, 0.09), (0.040, 0.22),
                                      (0.030, 0.33), (0.019, 0.43), (0.021, 0.50), (0.031, 0.55), (0.028, 0.61), (0, 0.62)]
        let balProf = lite ? prof.enumerated().filter { $0.offset % 2 == 0 || $0.offset == prof.count - 1 }.map { $0.element } : prof

        func rail(_ pts: [V3]) {
            let sec: [V2] = [V2(-0.045, -0.06), V2(0.02, -0.06), V2(0.035, -0.045), V2(0.045, -0.025), V2(0.045, 0.025), V2(0.035, 0.045), V2(0.02, 0.06), V2(-0.045, 0.06)]
            m.add(Prim.sweep(sec, along: pts, up: FA.Y, material: stone))
        }

        let balTints: [MaterialKey] = [cast, "stone.cast-stone:E4DCC2", "stone.cast-stone:EDE4CB"]
        func balustrade(rC: Float, outer: Bool) {
            let arcLen = rC * .pi / 2
            let pierS: Float = 0.14
            let s0: Float = 0.30, s1 = arcLen + landing - pierS - 0.17
            let cnt = max(2, Int((s1 - s0) / 0.26))
            let pitch = (s1 - s0) / Float(cnt)
            for k in 0...cnt {
                let s = s0 + Float(k) * pitch
                var p: V2, baseY: Float, yc: Float
                if s <= arcLen {
                    let a = s / rC, d = a * 180 / .pi
                    p = V2(rC * cos(a), rC * sin(a))
                    let i = min(n - 1, Int(d / dTh))
                    baseY = top(i) + plinthUp
                    yc = railY(d)
                } else {
                    p = V2(-(s - arcLen), rC)
                    baseY = topY + plinthUp
                    yc = railY(90)
                }
                let len = yc - 0.045 + 0.004 - baseY
                m.add(turned(balProf, segments: lite ? 5 : 6, material: balTints[(k + (outer ? 0 : 2)) % 3], seamTile: 0.1, grainVertical: true),
                      Xform(translation: V3(p.x, baseY - 0.002, p.y), scale: V3(1, len / H0, 1)))
                if !lite && k % 6 == 3 {   // rust bleed where an old iron pin rusted at the foot
                    m.add(Prim.cylinder(radius: 0.012, height: 0.002, bevel: 0.0005, segments: 8, bevelSegments: 1, material: "metal.rust"),
                          Xform(translation: V3(p.x, baseY + 0.001, p.y)))
                }
            }
            // Rail along arc then landing.
            let thp = pierS / rC * 180 / .pi
            var pts: [V3] = [V3(rC * cos(rad(thp)), railY(thp), rC * sin(rad(thp)))]
            var d: Float = 5
            while d < 90 { if d > thp + 1 { pts.append(V3(rC * cos(rad(d)), railY(d), rC * sin(rad(d)))) }; d += 5 }
            pts.append(V3(0, railY(90), rC))
            pts.append(V3(-landing + pierS, railY(90), rC))
            rail(pts)
            // Piers: foot and landing end.
            let thf = rad(thp)
            let pierTopFoot = railY(thp) + 0.09
            pier(at: V2(rC * cos(thf), rC * sin(thf)), yaw: -thp, height: pierTopFoot)
            pier(at: V2(-landing + pierS, rC), yaw: 0, height: railY(90) + 0.09)
        }
        balustrade(rC: woC, outer: true)
        balustrade(rC: wiC, outer: false)

        // Moss patch and stain at the foot of the outer wall (proud of the skirting).
        if !lite {
            let a0 = rng.float(8...14)
            sector(woC - wallT / 2 - 0.0145, woC + wallT / 2 + 0.0145, a0 + 8, a0 + 30, 0, 0.03, "stone.granite-moss", bevel: 0.002)
            sector(rI + 0.003, rI + 0.35, 0.3, 4, top(0) - 0.0005, top(0) + 0.0005, "stone.granite-moss", bevel: 0.0002)
        }
        if !lite {
            // Crack across tread 3, a chipped nosing on tread 4, soot runs under the coping, moss in the lower joints.
            let ca = 2 * dTh + 6, ct = top(2) + 0.0006
            let c0 = V2((rI + 0.12) * cos(rad(ca)), (rI + 0.12) * sin(rad(ca))), c1 = V2((rO - 0.2) * cos(rad(ca + 2.5)), (rO - 0.2) * sin(rad(ca + 2.5)))
            let cd = c1 - c0
            FA.box(&m, V3(simd_length(cd), 0.0012, 0.004), V3((c0.x + c1.x) / 2, ct, (c0.y + c1.y) / 2), "stone.slate", r: 0.0004, rot: FA.q(-atan2(cd.y, cd.x) * 180 / .pi, FA.Y))
            sector(rO - 0.18, rO - 0.03, 3 * dTh - nose - 0.2, 3 * dTh - nose + 1.4, top(3) - treadT, top(3) + 0.0008, "stone.limestone-sooted:5E5444", bevel: 0.0006)
            // Rain-splash grime band on the lower parapet faces, and drip soot under the coping.
            for i in 0..<n {
                let a0 = Float(i) * dTh, t = top(i)
                sector(rO + wallT, rO + wallT + 0.0012, a0 + 0.3, a0 + dTh - 0.3, 0.07, 0.19 + Float(i % 2) * 0.03, "stone.limestone-sooted:5A5040", bevel: 0)
                sector(rI - wallT - 0.0012, rI - wallT, a0 + 0.3, a0 + dTh - 0.3, 0.07, 0.19 + Float((i + 1) % 2) * 0.03, "stone.limestone-sooted:5A5040", bevel: 0)
                sector(rO + wallT, rO + wallT + 0.0012, a0 + 0.3, a0 + dTh - 0.3, t + copeUp - 0.045, t + copeUp, "stone.limestone-sooted:6A604C", bevel: 0)
            }
            for (k, a) in [Float(34), 61].enumerated() {
                sector(rI - wallT - 0.016, rI - wallT + 0.002, a, a + 10, 0, 0.05 + Float(k) * 0.02, "stone.granite-moss", bevel: 0)
            }
        }
        // Footing slab and bed of dirt at the foot.
        let ft: MaterialKey = "stone.cast-grey"
        sector(rI - wallT - 0.02, rO + wallT + 0.02, 0, 90, -0.03, 0.004, ft, bevel: 0)
        bx(V3(landing, 0.034, rO - rI + 2 * wallT + 0.04), V3(-landing / 2, -0.013, (rI + rO) / 2), ft, r: 0.002)
        if !lite {
            for (k, a) in [Float(8), 47, 72].enumerated() {
                sector(rO + wallT - 0.006, rO + wallT + 0.019, a, a + 9 + Float(k) * 3, 0.0, 0.004, "stone.granite-moss", bevel: 0)
            }
        }
        groundAO(&m, height: 0.12, floor: 0.75)
        return FC.place(m)
    }
}
