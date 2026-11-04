import Foundation
import simd
import RealCore

/// Dog coat as one continuous signed-distance surface: torso, neck, skull, muzzle and legs are smooth-unioned
/// primitives meshed together, skinned by a soft-min over the primitive distances. Ears, eyes, nose, claws and
/// the tail stay separate rigid parts.
extension QuadrupedBody {
    static func dogCoat(_ rig: inout Rig, _ f: GroundFrame, _ plan: QuadrupedPlan, chains: [GroundJoint.Leg: Chain], cell: Float? = nil) {
        let a = f.a, X = GroundFrame.X, Y = GroundFrame.Y, Z = GroundFrame.Z
        var sdf = SDFBody()
        // Smooth-union radii grow with the animal so a bear melts into one body like a dog does.
        let bk: Float = a.bodyLength > 1 ? a.bodyLength / 0.74 : 1, hk: Float = a.headLength > 0.3 ? a.headLength / 0.26 : 1
        // Polar bear: atlas u = 0 (the mirror seam) lies under the belly instead of down the spine.
        let upRef: V3 = a.earRound ? -f.U : f.U, headRef: V3 = a.earRound ? -Y : Y
        func halfCirc(_ rx: Float, _ ry: Float) -> Float { .pi * (0.5 * (rx * rx + ry * ry)).squareRoot() }
        func vs(_ rx: Float, _ ry: Float) -> Float { 1 / halfCirc(rx, ry) }

        // Torso: one ellipsoid per plan station, wide enough to overlap their neighbours.
        let bodyChart = sdf.chart(SDFChart(origin: f.C, axis: f.A, ref: upRef, vScale: vs(0.5 * a.bodyWidth, 0.5 * a.bodyDepth), v0: 2.3, region: .body))
        // Rump cap: its own chart with the pole at the rear-lower point so the fur atlas pinches out of sight.
        let rumpChart = sdf.chart(SDFChart(origin: f.C - f.A * (0.5 * a.bodyLength), axis: -f.A * 0.6 - f.U * 0.8, ref: upRef, vScale: vs(0.5 * a.bodyWidth, 0.5 * a.bodyDepth), v0: 2.9, region: .body))
        let L = a.bodyLength
        // Deer chest cap: pole at the front-lower point so the belly white does not converge into a diamond on the brisket.
        let chestChart = sdf.chart(SDFChart(origin: f.C + f.A * (0.5 * a.bodyLength), axis: f.A * 0.6 - f.U * 0.8, ref: f.U, vScale: vs(0.5 * a.bodyWidth, 0.5 * a.bodyDepth), v0: 2.6, region: .body))
        for st in plan.torso {
            let c = f.C + f.A * ((st.t - 0.5) * L) + f.U * (st.lift * a.bodyDepth)
            let rx = 0.5 * a.bodyWidth * st.w, rd = 0.5 * a.bodyDepth * st.d, rv = 0.5 * a.bodyDepth * 0.95 * st.v
            let end = st.t < 0.05 || st.t > 0.97
            if a.earRound && st.t < 0.21 {
                // Two buttock lobes with a shallow groove under the tail.
                for sx in [Float(-1), 1] {
                    sdf.ellipsoid(c + f.U * (0.5 * (rd - rv)) + X * (sx * 0.3 * rx), V3(rx * (end ? 0.6 : 0.74), 0.5 * (rd + rv) * (end ? 0.8 : 1), L * (end ? 0.07 : 0.15)), x: X, y: f.U,
                                  joint: st.t < 0.5 ? GroundJoint.spine.name : "root", chart: st.t < 0.03 ? rumpChart : bodyChart, blend: 0.03 * bk, bias: 0.03 * bk)
                }
                continue
            }
            sdf.ellipsoid(c + f.U * (0.5 * (rd - rv)), V3(rx, 0.5 * (rd + rv), L * (end ? 0.09 : 0.15)), x: X, y: f.U,
                          joint: st.t < 0.5 ? GroundJoint.spine.name : "root", chart: a.earRound && st.t < 0.03 ? rumpChart : (a.hooves && st.t > 0.9 ? chestChart : bodyChart), blend: 0.07 * bk, bias: 0.03 * bk)
        }

        if a.earRound {
            // Shoulder hump over the withers.
            let hump = f.C + f.A * (0.2 * L) + f.U * (0.38 * a.bodyDepth)
            sdf.ellipsoid(hump, V3(0.42 * a.bodyWidth, 0.2 * a.bodyDepth, 0.2 * L), x: X, y: f.U, joint: GroundJoint.spine.name, chart: bodyChart, blend: 0.09 * bk, bias: 0.03 * bk)
        }

        // Neck: two cones from the withers to the back of the skull.
        let hc = f.headCenter, hl = a.headLength, hw = a.headWidth, hh = a.headHeight
        let nBase = f.neckPivot - f.A * (0.1 * L) - f.U * ((a.hooves ? -0.1 : 0.06) * a.bodyDepth)
        let neckEnd = hc + V3(0, -0.1 * hh, 0.3 * hl)
        let neckMid = lerp(f.neckPivot, neckEnd, 0.5) + V3(0, 0.02 * a.neckLength, 0)
        let r0 = 0.5 * a.bodyWidth * a.neckThick * 0.78 * a.neckDeep.squareRoot(), r1 = 0.5 * hw * 0.82
        let neckChart = sdf.chart(SDFChart(origin: nBase, axis: neckEnd - nBase, ref: upRef, vScale: vs(r0, r0), v0: 3.1, region: a.hooves ? .head : .body))
        sdf.cone(nBase, neckMid, r0, lerp(r0, r1, 0.55), joint: GroundJoint.neckPitch.name, chart: neckChart, blend: 0.07 * bk)
        sdf.cone(neckMid, neckEnd, lerp(r0, r1, 0.55), r1, joint: GroundJoint.neckPitch.name, chart: neckChart, blend: 0.05 * bk)

        // Head: skull stations rear to nose from the same profile the loft used; muzzle from the cheek forward.
        let hp = f.headProfile
        let skullChart = sdf.chart(SDFChart(origin: hc, axis: Z, ref: headRef, vScale: vs(0.5 * hw, 0.55 * hh), v0: 4.2, region: .head))
        let muzzleChart = sdf.chart(SDFChart(origin: hc, axis: Z, ref: headRef, vScale: vs(0.3 * hw, 0.3 * hh), v0: 5.4, region: .muzzle))
        func station(_ t: Float) -> (c: V3, rx: Float, ry: Float, dy: Float) {
            let r = hp(t)
            let c = hc + V3(0, -0.12 * hh * t * t, (0.5 - t) * hl)
            let rd = hh * 0.55 * r, rv = hh * 0.45 * r
            return (c, 0.5 * hw * r, 0.5 * (rd + rv), 0.5 * (rd - rv))
        }
        let head = GroundJoint.headPitch.name
        for t in [Float(0.04), 0.2, 0.36] {
            let s = station(t)
            sdf.ellipsoid(s.c + Y * s.dy, V3(s.rx, s.ry, hl * 0.2), x: X, y: Y, joint: head, chart: skullChart, blend: 0.03 * hk)
        }
        if a.earRound {
            // Forehead dome above the muzzle bridge: brow, then a dip (stop) before the nose.
            let fh = station(0.26)
            sdf.ellipsoid(fh.c + Y * (fh.dy + fh.ry * 0.42), V3(fh.rx * 0.78, fh.ry * 0.6, hl * 0.13), x: X, y: Y, joint: head, chart: skullChart, blend: 0.02 * hk)
        }
        // Muzzle: lower than the skull (stop), the last station ends 4 mm behind the nose pad.
        let noseZ = hc.z - 0.5 * hl
        for t in [Float(0.5), 0.62, 0.74, 0.86] {
            let s = station(t)
            sdf.ellipsoid(s.c + Y * (s.dy * 0.2 - (a.earRound ? -0.28 * sin(.pi * (t - 0.4) / 0.6) : 0.1) * s.ry), V3(s.rx * 1.0, s.ry * (a.earRound ? 1.0 : 0.92), hl * 0.13), x: X, y: Y, joint: head, chart: muzzleChart, blend: 0.025 * hk)
        }
        do {
            let s = station(0.9)
            let zr = hl * 0.1
            sdf.ellipsoid(V3(s.c.x, s.c.y + s.dy * 0.2 - 0.1 * s.ry, noseZ + 0.006 + zr), V3(s.rx * 0.92, s.ry * 0.85, zr), x: X, y: Y, joint: head, chart: muzzleChart, blend: 0.02 * hk)
        }
        // Brow ridge, cheeks, flews and chin.
        for sd in Side.allCases {
            let e = f.eye(sd), R = a.eyeRadius
            sdf.ellipsoid(e + V3(-sd.sign * R * 0.2, R * 1.7, -R * 0.4), V3(R * 1.5, R * (a.earRound ? 1.1 : 0.8), R * 2.4), x: X, y: Y, joint: head, chart: skullChart, blend: 0.012 * hk)
            let ck = station(0.3)
            sdf.ellipsoid(ck.c + V3(sd.sign * ck.rx * 0.78, -ck.ry * 0.5, 0), V3(ck.rx * (a.earRound ? 0.46 : 0.34), ck.ry * 0.62, hl * 0.14), x: X, y: Y, joint: head, chart: skullChart, blend: 0.03 * hk)
            let fl = station(0.74)
            sdf.ellipsoid(fl.c + V3(sd.sign * fl.rx * 0.82, -fl.ry * 0.62, -hl * 0.02), V3(fl.rx * 0.3, fl.ry * 0.36, hl * 0.2), x: X, y: Y, joint: head, chart: muzzleChart, blend: 0.015 * hk)
        }
        let ch = station(0.78)
        sdf.ellipsoid(ch.c + V3(0, -ch.ry * 0.95, 0), V3(ch.rx * 0.6, ch.ry * 0.28, hl * 0.2), x: X, y: Y, joint: head, chart: muzzleChart, blend: 0.02 * hk)

        // Legs.
        let s = plan.legScale
        func mean(_ st: [(Float, Float, Float, Float)], _ t: Float) -> Float { let r = interp(st, t); return (r.0 + 0.5 * (r.1 + r.2)) * 0.5 * s }
        for l in GroundJoint.Leg.allCases {
            guard let c = chains[l] else { continue }
            let sign = l.side.sign
            let hipN = GroundJoint.leg(l, .hip).name, kneeN = GroundJoint.leg(l, .knee).name, ankleN = GroundJoint.leg(l, .ankle).name
            let upSt = l.isFore ? plan.foreUpper : plan.hindUpper
            let top = c.hip + V3(-sign * 0.35 * abs(c.hip.x), (a.hooves ? 0.04 : 0.2) * a.bodyDepth, 0)
            let upR0 = mean(upSt, 0.05) * (l.isFore ? (a.hooves ? 0.5 : 0.95) : 0.7), upR1 = mean(upSt, 1.0) * (l.isFore ? 1.15 : 1.0)
            let thighDir = simd_normalize(c.knee - top)
            let upChart = sdf.chart(SDFChart(origin: top, axis: top - c.knee, ref: V3(sign, 0, 0), vScale: vs(upR0, upR0) * 1.1, v0: 6.3 + Float(l.rawValue), region: .body))
            sdf.cone(top, c.knee, upR0, upR1, joint: hipN, chart: upChart, blend: 0.05 * bk)
            if l.isFore {
                // Shoulder blade lying against the ribs.
                sdf.ellipsoid(c.hip + V3(sign * 0.004, (a.hooves ? 0.075 : 0.05) * plan.massScale, 0.02 * plan.massScale), V3(0.045, 0.115, 0.07) * plan.massScale * (a.hooves ? V3(0.75, 0.8, 0.85) : (a.earRound ? V3(1.15, 1.2, 1.1) : V3(1, 1, 1))) * (a.hooves ? Float(0.8) : Float(1)), x: X, y: V3(0, 1, 0.45), joint: hipN, chart: a.earRound ? bodyChart : upChart, blend: 0.06 * bk, bias: a.earRound ? 0.05 * bk : 0)
            } else {
                // Thigh and rump muscle.
                let mid = lerp(top, c.knee, a.hooves ? 0.42 : 0.28) + (a.hooves ? V3(sign * 0.004, 0.0, 0.016) : V3(sign * 0.012, 0.0, 0.026)) * plan.massScale
                sdf.ellipsoid(mid, V3(0.05 * s * plan.massScale * plan.thighMass, simd_length(c.knee - top) * 0.46, 0.085 * s * plan.massScale * plan.thighMass), x: X, y: -thighDir, joint: hipN, chart: a.earRound ? bodyChart : upChart, blend: 0.06 * bk, bias: a.earRound ? 0.05 * bk : 0)
                if a.earRound {
                    // Ham: muscle behind the thigh, tapering to the hock.
                    let ham = lerp(top, c.knee, 0.5) + V3(sign * 0.01, 0, 0.07 * plan.massScale)
                    sdf.ellipsoid(ham, V3(0.036 * s * plan.massScale * plan.thighMass, simd_length(c.knee - top) * 0.34, 0.05 * s * plan.massScale * plan.thighMass), x: X, y: -thighDir, joint: hipN, chart: bodyChart, blend: 0.04 * bk, bias: 0.05 * bk)
                }
            }
            let lowR0 = (l.isFore ? mean(plan.foreCannon, 0) : mean(plan.hindGaskin, 0.2)) * plan.lowerScale
            let lowR1 = (l.isFore ? mean(plan.foreCannon, 1) : mean(plan.hindGaskin, 1)) * plan.lowerScale
            let lowChart = sdf.chart(SDFChart(origin: c.knee, axis: c.knee - c.toe, ref: V3(sign, 0, 0), vScale: vs(lowR1, lowR1), v0: 7.3 + Float(l.rawValue), region: .limb))
            sdf.cone(c.knee, c.ankle, lowR0, lowR1, joint: kneeN, chart: lowChart, blend: 0.02 * bk)
            let pastR = mean(l.isFore ? plan.forePastern : plan.hindCannon, 0.5) * plan.lowerScale
            if l.isFore {
                sdf.cone(c.ankle, c.toe + V3(0, 0.03, 0), lowR1, pastR, joint: ankleN, chart: lowChart, blend: 0.015 * bk)
            } else {
                let fet = c.toe + V3(0, 0.07, 0.012)
                sdf.cone(c.ankle, fet, mean(plan.hindCannon, 0) * plan.lowerScale, pastR, joint: ankleN, chart: lowChart, blend: 0.02 * bk)
                sdf.cone(fet, c.toe + V3(0, 0.03, 0), pastR, pastR, joint: ankleN, chart: lowChart, blend: 0.015 * bk)
            }
            // Feathering: flat fringe down the back of the forearm and the trousers behind the thigh.
            if plan.feather > 0 {
                let k = Float(plan.feather) * 0.5
                if l.isFore {
                    let m = lerp(c.hip, c.knee, 0.72) + V3(sign * 0.004, 0, 0.03 * s)
                    sdf.ellipsoid(m, V3(0.017 * k, simd_length(c.knee - c.hip) * 0.42, 0.05 * k), x: X, y: V3(0, 1, 0), joint: kneeN, chart: lowChart, blend: 0.03 * bk)
                } else {
                    let m = lerp(top, c.knee, 0.55) + V3(sign * 0.006, -0.01, 0.05 * s)
                    sdf.ellipsoid(m, V3(0.022 * k, simd_length(c.knee - top) * 0.44, 0.06 * k), x: X, y: V3(0, 1, 0), joint: hipN, chart: upChart, blend: 0.04 * bk)
                }
            }
            if a.earRound {
                let rb = a.legRadius * s
                if l.isFore {
                    // Elbow behind the chest and forearm muscle above the wrist.
                    sdf.ellipsoid(lerp(c.hip, c.knee, 0.3) + V3(sign * 0.012, 0, 0.05 * plan.massScale), V3(0.05, 0.11, 0.07) * plan.massScale * 0.9, x: X, y: Y, joint: hipN, chart: bodyChart, blend: 0.04 * bk, bias: 0.05 * bk)
                    sdf.ellipsoid(lerp(c.knee, c.ankle, 0.3), V3(rb * 1.15, rb * 2.2, rb * 1.25), x: X, y: Y, joint: kneeN, chart: lowChart, blend: 0.02 * bk)
                } else {
                    // Hock point and calf.
                    sdf.ellipsoid(c.ankle + V3(0, 0.01, 0.035), V3(rb * 1.0, rb * 1.5, rb * 1.1), x: X, y: Y, joint: ankleN, chart: lowChart, blend: 0.015 * bk)
                    sdf.ellipsoid(lerp(c.knee, c.ankle, 0.35) + V3(0, 0, 0.02), V3(rb * 1.2, rb * 2.4, rb * 1.3), x: X, y: Y, joint: kneeN, chart: lowChart, blend: 0.02 * bk)
                }
            }
            // Paw pad and toes.
            let r = a.legRadius * s * (a.earRound ? (l.isFore ? 1.2 : 1.1) : 1)
            if a.hooves {
                // Carpus and hock knuckles.
                let jt = l.isFore ? c.knee : c.ankle
                sdf.ellipsoid(jt, V3(r * 1.5, r * 2.5, r * 1.6), x: X, y: Y, joint: l.isFore ? kneeN : ankleN, chart: lowChart, blend: 0.012 * bk)
                sdf.ellipsoid(c.toe + V3(0, r * 0.9, -r * 0.25), V3(r * 1.2, r * 1.2, r * 1.85), x: X, y: Y, joint: ankleN, chart: lowChart, blend: 0.01)
                continue
            }
            let turn: Float = a.earRound && l.isFore ? 0.2 * sign : 0   // forepaws toe out
            let pc = c.toe + V3(turn * r * 0.8, r * 0.55 - (a.earRound ? 0.006 : 0), -r * 0.5)
            sdf.ellipsoid(pc, a.earRound ? V3(r * 1.3, r * 0.6, r * (l.isFore ? 1.55 : 2.0)) : V3(r * 1.15, r * 0.8, r * 1.9), x: X, y: Y, joint: ankleN, chart: lowChart, blend: 0.012 * bk)
            let mid = Float(plan.toes - 1) / 2, sp = (a.earRound ? 0.8 : 0.62) * 4 / Float(plan.toes)
            for k in 0..<plan.toes {
                let off = (Float(k) - mid) * r * sp
                let fz = (a.earRound ? 1.8 : 1.55) - 0.14 * abs(Float(k) - mid) * (a.earRound ? 1.6 : 1)
                let tc = pc + V3(off + turn * r * fz, -r * 0.18, -r * fz)
                sdf.ellipsoid(tc, a.earRound ? V3(r * 0.5, r * 0.4, r * 0.6) : V3(r * 0.4, r * 0.38, r * 0.62), x: X, y: Y, joint: ankleN, chart: lowChart, blend: (a.earRound ? 0.012 : 0.006) * bk)
            }
        }

        let size = cell ?? max(0.0065, 0.0105 * a.bodyLength / 0.74)
        let id = f.id
        let mats: [SDFRegion: MaterialKey] = [.body: f.mat(.body), .head: f.mat(.head),
                                              .muzzle: f.p.palette.muzzle != nil ? f.mat(.muzzle) : f.mat(.head), .limb: f.mat(.limb)]
        _ = id
        let names = rig
        let surfaces = sdf.mesh(cell: size, tau: 0.022, materials: mats) { $0 == "root" ? 0 : (names.index($0)! + 1) }
        for srf in surfaces { rig.base[0].surfaces.append(srf) }
    }
}
