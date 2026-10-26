import Foundation
import simd
import RealCore

/// Anatomical quadruped body: torso, legs, ears, eyes, nose and fur cards from per-species
/// cross-section profiles. Parts attach to the GroundRig joints (rigid skinning per joint with
/// overlapping sections at each bend).
public struct QuadrupedPlan: Sendable {
    /// Torso stations from rump (t 0) to brisket (t 1): t, half width, dorsal, ventral (fractions of
    /// body width/depth) and centre lift along the dorsal axis (fraction of depth).
    public var torso: [(t: Float, w: Float, d: Float, v: Float, lift: Float)]
    /// Leg stations per segment: t along the bone, side half width, rear and front extents (meters
    /// before `legScale`).
    public var foreUpper: [(Float, Float, Float, Float)]
    public var foreCannon: [(Float, Float, Float, Float)]
    public var forePastern: [(Float, Float, Float, Float)]
    public var hindUpper: [(Float, Float, Float, Float)]
    public var hindGaskin: [(Float, Float, Float, Float)]
    public var hindCannon: [(Float, Float, Float, Float)]
    public var legScale: Float = 1
    public var furCards: Int = 160
    public var cardLength: Float = 0.022
    /// Dog body: paws, dog eyes and nose, hanging or erect ears, skinned fur shells.
    public var dog = false
    /// Tail covered in a fur-card brush (plume).
    public var tailBrush = false
    /// Scapula and haunch mass radii (side, front-back) in meters before `legScale`.
    public var haunchFore = V2(0.075, 0.05)
    public var haunchHind = V2(0.12, 0.07)
    /// Feather fringe cards per leg (back of the forelegs and thighs).
    public var feather = 0
    /// Scale of the leg segments below the upper leg (cannon, gaskin, pastern).
    public var lowerScale: Float = 1

    public static func plan(for p: GroundProfile) -> QuadrupedPlan? {
        switch p.species {
        case .whitetailDeer: return whitetail
        case .goldenRetriever: return golden
        case .germanShepherd: return shepherd
        case .pembrokeCorgi: return corgi
        default: return nil
        }
    }

    static let whitetail = QuadrupedPlan(
        torso: [(0.00, 0.34, 0.34, 0.40, 0.10), (0.06, 0.78, 0.74, 0.80, 0.08), (0.17, 0.98, 0.90, 0.92, 0.06),
                (0.30, 0.94, 0.82, 0.70, 0.05), (0.40, 0.88, 0.80, 0.74, 0.03), (0.52, 0.96, 0.84, 0.92, 0.01),
                (0.66, 1.00, 0.88, 1.04, 0.01), (0.78, 0.94, 1.00, 1.10, 0.04), (0.88, 0.82, 0.96, 1.06, 0.04),
                (0.96, 0.62, 0.78, 0.92, 0.02), (1.02, 0.36, 0.52, 0.62, 0.00)],
        foreUpper: [(0, 0.060, 0.080, 0.090), (0.3, 0.048, 0.060, 0.066), (0.62, 0.028, 0.030, 0.032), (1, 0.017, 0.018, 0.019)],
        foreCannon: [(0, 0.016, 0.017, 0.016), (0.2, 0.011, 0.013, 0.012), (0.85, 0.010, 0.012, 0.011), (1, 0.014, 0.016, 0.015)],
        forePastern: [(0, 0.013, 0.014, 0.014), (0.5, 0.010, 0.011, 0.011), (1, 0.011, 0.012, 0.012)],
        hindUpper: [(0, 0.075, 0.150, 0.100), (0.35, 0.070, 0.140, 0.090), (0.7, 0.050, 0.090, 0.065), (1, 0.026, 0.035, 0.032)],
        hindGaskin: [(0, 0.026, 0.035, 0.032), (0.35, 0.022, 0.034, 0.024), (0.8, 0.014, 0.024, 0.014), (1, 0.014, 0.026, 0.015)],
        hindCannon: [(0, 0.013, 0.016, 0.013), (0.15, 0.011, 0.012, 0.012), (0.88, 0.010, 0.011, 0.011), (1, 0.013, 0.014, 0.014)])
}

enum QuadrupedBody {
    typealias Chain = (hip: V3, knee: V3, ankle: V3, toe: V3)

    static func interp(_ st: [(Float, Float, Float, Float)], _ t: Float) -> (Float, Float, Float) {
        guard let j = st.firstIndex(where: { $0.0 >= t }) else { let l = st.last!; return (l.1, l.2, l.3) }
        if j == 0 { return (st[0].1, st[0].2, st[0].3) }
        let a = st[j - 1], b = st[j], k = (t - a.0) / max(1e-5, b.0 - a.0)
        let s = k * k * (3 - 2 * k)
        return (lerp(a.1, b.1, s), lerp(a.2, b.2, s), lerp(a.3, b.3, s))
    }

    static func torsoSection(_ f: GroundFrame, _ plan: QuadrupedPlan, _ t: Float) -> LoftSection {
        let st = plan.torso.map { ($0.t, $0.w, $0.d, $0.v) }
        let (w, d, v) = interp(st, t)
        let lifts = plan.torso.map { ($0.t, $0.lift, $0.lift, $0.lift) }
        let lift = interp(lifts, t).0
        let a = f.a
        let c = f.C + f.A * ((t - 0.5) * a.bodyLength) + f.U * (lift * a.bodyDepth)
        return LoftSection(center: c, right: GroundFrame.X, up: f.U, halfWidth: 0.5 * a.bodyWidth * w,
                           halfDorsal: 0.5 * a.bodyDepth * d, halfVentral: 0.5 * a.bodyDepth * 0.95 * v, exponent: 2.05)
    }

    /// Leg bone loft from `a` to `b` with stations (side, rear, front), extended `ext` past both ends.
    static func limb(_ a: V3, _ b: V3, _ st: [(Float, Float, Float, Float)], scale: Float, ext: Float, material: MaterialKey) -> Surface {
        let fw = simd_normalize(b - a), L = simd_length(b - a)
        var right = GroundFrame.X - fw * simd_dot(GroundFrame.X, fw)
        right = simd_normalize(right)
        let back = simd_normalize(simd_cross(fw, right)) * (simd_dot(simd_cross(fw, right), V3(0, 0, 1)) >= 0 ? 1 : -1)
        let n = 9
        let secs = (0..<n).map { i -> LoftSection in
            let t = Float(i) / Float(n - 1)
            let r = interp(st, t)
            let c = a + fw * (L * (-ext + (1 + 2 * ext) * t))
            return LoftSection(center: c, right: right, up: back, halfWidth: r.0 * scale, halfDorsal: r.1 * scale, halfVentral: r.2 * scale, exponent: 2)
        }
        return Loft.build(secs, segments: 14, material: material) { u, v in V2(0.2 + 0.04 * cos(u * 2 * .pi), 0.3 + 0.3 * v) }
    }

    /// Cupped ear: a curved two-sided sheet, fur outside, pale furred inside.
    static func ear(base: V3, dir: V3, side: V3, normal: V3, len: Float, width: Float, outer: MaterialKey, inner: MaterialKey, soft: Bool = false, erect: Bool = false) -> [Surface] {
        let ns = 9, na = 9
        func pos(_ s: Float, _ a: Float, _ off: Float) -> V3 {
            let w = erect ? 0.5 * width * pow(max(0, 1 - pow(s, 2.4)), 0.5) * (1 - 0.3 * s)
                : soft ? 0.5 * width * pow(sin(.pi * min(1, 0.1 + 0.9 * s * 0.985)), 0.5) * (1 - 0.15 * s)
                : 0.5 * width * pow(sin(.pi * min(1, 0.12 + 0.88 * s)), 0.7) * (1 - 0.25 * s)
            let cup = 0.55 * w * (1 - a * a) + 0.004 * s
            return base + dir * (len * s) + side * (w * a) - normal * (cup - off)
        }
        var out = Surface(material: outer), inn = Surface(material: inner)
        for i in 0..<ns { for j in 0..<na {
            let s = Float(i) / Float(ns - 1), a = Float(j) / Float(na - 1) * 2 - 1
            _ = out.add(pos(s, a, -0.0012), -normal, soft ? V2(0.25 + 1.3 * a * width, 4.8 - 5.15 * len * s) : V2(0.22 + 0.05 * a, 0.5 + 0.1 * s))
            _ = inn.add(pos(s, a, 0.0006), normal, erect ? V2(0.25 + 1.3 * a * width, 4.8 - 5.15 * len * s) : V2(0.5 + 0.5 * a, s))
        }}
        for i in 0..<(ns - 1) { for j in 0..<(na - 1) {
            let q = UInt32(i * na + j), r = UInt32(na)
            out.quad(q, q + 1, q + r + 1, q + r)
            inn.quad(q, q + r, q + r + 1, q + 1)
        }}
        out.recomputeNormals(); out.computeTangents(); inn.recomputeNormals(); inn.computeTangents()
        return [out, inn]
    }

    /// Dog paw: pad-rounded paw with four toes and claws, plus feather fringe down the back of the leg.
    static func pawAndFeather(_ rig: inout Rig, _ f: GroundFrame, _ plan: QuadrupedPlan, _ l: GroundJoint.Leg, _ c: Chain,
                              ankle: String, hipPart: String, top: V3, material: MaterialKey) {
        let a = f.a, r = a.legRadius * plan.legScale
        let pc = c.toe + V3(0, r * 0.55, -r * 0.5)
        for k in 0..<4 {
            let off = (Float(k) - 1.5) * r * 0.62
            let tc = pc + V3(off, -r * 0.18, -r * (1.55 - 0.14 * abs(Float(k) - 1.5)))
            let cl = tc + V3(0, -r * 0.1, -r * 0.45)
            rig.add(Prim.tube([cl, cl + V3(0, -r * 0.1, -r * 0.5)], radii: [r * 0.12, r * 0.03], sides: 4, seamTile: 0.01, material: f.mat(.claw)), to: ankle)
        }
        guard plan.feather > 0 else { return }
        var rng = SplitMix(seed: 91 + UInt64(l.isFore ? 0 : 1) + (l.side == .left ? 0 : 2))
        let top0 = c.hip, bottom = c.knee
        for _ in 0..<plan.feather {
            let t = rng.next01()
            let p0 = lerp(top0, bottom, t) + V3(l.side.sign * 0.012, 0, 0.024 * plan.legScale * (l.isFore ? 0.5 : 1))
            let L = (0.03 + 0.05 * (1 - t)) * (l.isFore ? 1 : 1.3) * plan.cardLength / 0.05
            let d = simd_normalize(V3(l.side.sign * 0.15 * (rng.next01() - 0.5), -0.9, 0.35))
            rig.add(Prim.tube([p0, p0 + d * (0.5 * L), p0 + d * L + V3(0, 0, 0.004)], radii: [0.004, 0.003, 0.0004], sides: 3, seamTile: 0.02, material: f.mat(.body)), to: hipPart)
        }
    }

    static func build(_ rig: inout Rig, _ f: GroundFrame, _ plan: QuadrupedPlan, chains: [GroundJoint.Leg: Chain],
                      earBase: (Side) -> V3, noseTip: V3) {
        let a = f.a, fur = f.mat(.body), white = f.mat(.rump), spine = GroundJoint.spine.name
        // Torso: front half on the base, rear half on the spine part, overlapping at the waist.
        func torso(_ t0: Float, _ t1: Float, _ n: Int) -> Surface {
            let secs = (0..<n).map { torsoSection(f, plan, t0 + (t1 - t0) * Float($0) / Float(n - 1)) }
            return Loft.build(secs, segments: 28, vRange: t0...t1, material: fur)
        }
        if plan.dog { dogCoat(&rig, f, plan, chains: chains) } else {
            rig.base[0].add(torso(0.46, 1.02, 12))
            rig.add(torso(0, 0.56, 12), to: spine)
        }

        // Legs: muscled upper leg, slender cannon, fetlock, pastern, cloven hoof and dewclaws.
        let s = plan.legScale
        let lower = plan.dog ? f.mat(.limb) : fur
        for l in GroundJoint.Leg.allCases {
            let c = chains[l]!
            let hipPart = GroundJoint.leg(l, .hip).name, kneePart = GroundJoint.leg(l, .knee).name, ankle = GroundJoint.leg(l, .ankle).name
            let top = plan.dog ? c.hip + V3(-l.side.sign * 0.35 * abs(c.hip.x), 0.2 * a.bodyDepth, 0) : c.hip + V3(0, 0.05 * a.bodyDepth, 0)
            if plan.dog { pawAndFeather(&rig, f, plan, l, c, ankle: ankle, hipPart: hipPart, top: top, material: lower); continue }
            rig.add(limb(top, c.knee, l.isFore ? plan.foreUpper : plan.hindUpper, scale: s, ext: plan.dog ? 0.08 : 0.06, material: fur), to: hipPart)
            // Scapula / haunch muscle mass on the outside of the upper leg.
            let up = c.knee - top, ln = simd_length(up)
            if !plan.dog { rig.add(Loft.ellipsoid(center: lerp(top, c.knee, l.isFore ? 0.3 : 0.32) + V3(l.side.sign * 0.012, 0, l.isFore ? 0 : 0.012), axis: up, up: GroundFrame.X,
                                   radii: V3(l.isFore ? plan.haunchFore.x : plan.haunchHind.x, l.isFore ? plan.haunchFore.y : plan.haunchHind.y, ln * 0.62) * s, rings: 9, segments: 16, material: plan.dog ? f.mat(.limb) : fur,
                                   uv: { u, v in V2(0.2 + 0.04 * cos(u * 2 * .pi), 0.3 + 0.3 * v) }), to: hipPart) }
            rig.add(limb(c.knee, c.ankle, l.isFore ? plan.foreCannon : plan.hindGaskin, scale: s * plan.lowerScale, ext: 0.05, material: lower), to: kneePart)
            if l.isFore {
                rig.add(limb(c.ankle, c.toe + V3(0, 0.03, 0), plan.forePastern, scale: s * plan.lowerScale, ext: 0.08, material: lower), to: ankle)
            } else {
                // Hind: ankle part holds the long cannon down to the fetlock, then the pastern.
                let fet = c.toe + V3(0, 0.07, 0.012)
                rig.add(limb(c.ankle, fet, plan.hindCannon, scale: s * plan.lowerScale, ext: 0.04, material: lower), to: ankle)
                rig.add(limb(fet, c.toe + V3(0, 0.03, 0), plan.forePastern, scale: s * plan.lowerScale, ext: 0.08, material: lower), to: ankle)
                // Metatarsal gland tuft and white inner hock.
                if !plan.dog { rig.add(Loft.ellipsoid(center: c.ankle + V3(-l.side.sign * 0.006, -0.02, 0.012), axis: V3(0, -1, 0), up: V3(0, 0, 1),
                                       radii: V3(0.012, 0.012, 0.03) * s, rings: 6, segments: 10, material: white), to: ankle) }
            }
            if plan.dog { pawAndFeather(&rig, f, plan, l, c, ankle: ankle, hipPart: hipPart, top: top, material: lower); continue }
            let hc = c.toe + V3(0, 0.018, -0.006)
            for sx in [Float(-1), 1] {
                rig.add(Loft.ellipsoid(center: hc + V3(sx * 0.0068 * s, 0, -0.008), axis: V3(0, -0.35, -1), up: GroundFrame.Y,
                                       radii: V3(0.0075, 0.019, 0.026) * s, rings: 7, segments: 10, material: f.mat(.hoof)), to: ankle)
                rig.add(Loft.ellipsoid(center: c.toe + V3(sx * 0.008, 0.06, 0.016) * s, axis: V3(0, -1, 0.3), up: V3(0, 0, 1),
                                       radii: V3(0.004, 0.004, 0.008) * s, rings: 4, segments: 6, material: f.mat(.hoof)), to: ankle)
            }
        }

        // Eyes: large, bulging, wet; white eye ring and dark lash line around them.
        for sd in Side.allCases where plan.dog {
            // Dog eye: dark lid rim around a deep brown iris, set into the skull.
            let R = a.eyeRadius * 1.3
            let e = f.eye(sd) + V3(sd.sign * a.eyeRadius * 0.25, 0, 0)
            rig.add(Loft.ellipsoid(center: e - V3(sd.sign * R * 0.2, 0, 0), axis: V3(0, 0, -1), up: V3(sd.sign, 0, 0),
                                   radii: V3(R * 0.95, R * 0.88, R * 1.3), rings: 7, segments: 14, material: f.mat(.lid)), to: GroundJoint.headPitch.name)
            rig.add(Prim.cubeSphere(subdivisions: 4, material: f.mat(.eye)) { V3($0.x * R * 0.55, $0.y * R * 0.82, $0.z * R * 1.0) },
                    Xform(translation: e + V3(sd.sign * R * 0.12, 0, 0)), to: GroundJoint.headPitch.name)
        }
        for sd in Side.allCases where !plan.dog {
            let e = f.eye(sd) + V3(sd.sign * 0.004, 0.002, 0)
            let R = a.eyeRadius * 1.2
            rig.add(Loft.ellipsoid(center: e - V3(sd.sign * 0.004, 0, 0), axis: V3(0, 0.1, -1), up: V3(sd.sign, 0, 0),
                                   radii: V3(R * 1.2, R * 0.95, R * 1.45), rings: 7, segments: 12, material: white), to: GroundJoint.headPitch.name)
            rig.add(Loft.ellipsoid(center: e, axis: V3(0, 0.1, -1), up: V3(sd.sign, 0, 0),
                                   radii: V3(R * 1.15, R * 0.62, R * 1.2), rings: 8, segments: 14, material: f.mat(.nose)), to: GroundJoint.headPitch.name)
            rig.add(Prim.cubeSphere(subdivisions: 4, material: f.mat(.eye)) { V3($0.x * R * 0.62, $0.y * R * 0.82, $0.z * R) },
                    Xform(translation: e + V3(sd.sign * R * 0.32, 0, 0)), to: GroundJoint.headPitch.name)
        }
        // Nose pad with nostrils, white muzzle band and chin.
        let hw = a.headWidth
        rig.add(Loft.ellipsoid(center: noseTip + V3(0, 0.002, 0.004), axis: V3(0, 0, -1), up: GroundFrame.Y,
                               radii: plan.dog ? V3(hw * 0.15, hw * 0.1, hw * 0.075) : V3(hw * 0.19, hw * 0.13, hw * 0.1), rings: 7, segments: 12, material: f.mat(.nose)), to: GroundJoint.headPitch.name)
        for sd in Side.allCases {
            // Dog nostrils are comma slits sunk into the pad face; other species keep the round studs.
            let slit = plan.dog
            rig.add(Loft.ellipsoid(center: noseTip + V3(sd.sign * hw * (slit ? 0.065 : 0.09), slit ? -0.001 : 0.0, -hw * (slit ? 0.065 : 0.085)), axis: V3(sd.sign * 0.6, 0.3, -1), up: GroundFrame.Y,
                                   radii: slit ? V3(hw * 0.016, hw * 0.034, hw * 0.012) : V3(hw * 0.03, hw * 0.045, hw * 0.02), rings: 5, segments: 8, material: f.mat(.eye)), to: GroundJoint.headPitch.name)
        }
        if !plan.dog {
            rig.add(Loft.ellipsoid(center: noseTip + V3(0, -0.004, 0.034), axis: V3(0, 0, -1), up: GroundFrame.Y,
                                   radii: V3(hw * 0.22, hw * 0.16, hw * 0.07), rings: 7, segments: 14, material: white), to: GroundJoint.headPitch.name)
            rig.add(Loft.ellipsoid(center: noseTip + V3(0, -0.034, 0.04), axis: V3(0, 0, -1), up: GroundFrame.Y,
                                   radii: V3(hw * 0.16, hw * 0.08, hw * 0.2), rings: 6, segments: 10, material: white), to: GroundJoint.jaw.name)
        }

        // Cupped ears with pale inner fur tufts.
        for sd in Side.allCases where plan.dog {
            // Dog ear: erect and cupped forward, or folded down against the cheek (`earDrop`).
            let drop = a.earDrop
            let base = earBase(sd) + V3(sd.sign * 0.14 * a.headWidth, -0.05 * a.headHeight, 0.1 * a.headLength) * drop
            let dir = simd_normalize(lerp(V3(sd.sign * a.earTilt, 1, 0.12), V3(sd.sign * 0.12, -0.95, 0.1), drop))
            let fwd = lerp(V3(sd.sign * 0.3, 0.05, -1), V3(-sd.sign, 0, -0.1), drop)
            let normal = simd_normalize(fwd - dir * simd_dot(fwd, dir))
            let side = simd_normalize(simd_cross(normal, dir))
            let part = sd == .left ? GroundJoint.earL.name : GroundJoint.earR.name
            for (i, srf) in ear(base: base - dir * 0.004, dir: dir, side: side, normal: normal, len: a.earLength, width: a.earWidth, outer: f.mat(.head), inner: drop < 0.5 ? f.mat(.head) : f.mat(.pinna), soft: true, erect: drop < 0.5).enumerated() where drop < 0.5 || i == 0 {
                rig.add(srf, to: part)
            }
        }
        for sd in Side.allCases where !plan.dog {
            let base = earBase(sd)
            let dir = simd_normalize(V3(sd.sign * a.earTilt, 0.75, 0.35))
            let normal = simd_normalize(V3(sd.sign * 0.25, 0.1, -1) - dir * simd_dot(V3(sd.sign * 0.25, 0.1, -1), dir))
            let side = simd_normalize(simd_cross(normal, dir))
            let part = sd == .left ? GroundJoint.earL.name : GroundJoint.earR.name
            for srf in ear(base: base, dir: dir, side: side, normal: normal, len: a.earLength, width: a.earWidth * 1.15, outer: f.mat(.head), inner: f.mat(.ear)) {
                rig.add(srf, to: part)
            }
            for k in 0..<7 {
                let sb = 0.08 + 0.05 * Float(k), sa = (Float(k % 3) - 1) * 0.3
                let p0 = base + dir * (a.earLength * sb) + side * (a.earWidth * 0.3 * sa) - normal * 0.004
                rig.add(Prim.tube([p0, p0 + dir * 0.02 + normal * 0.012, p0 + dir * 0.04 + normal * 0.016], radii: [0.002, 0.0015, 0.0003], sides: 3, seamTile: 0.02, material: white), to: part)
            }
        }

        // Fur cards along the topline, belly fringe and rear of the haunch break up the silhouette.
        var rng = SplitMix(seed: 7)
        for k in 0..<plan.furCards {
            let t = rng.next01() * 1.0
            let sec = torsoSection(f, plan, t)
            let ang = rng.next01() * 2 * .pi
            let sx = sin(ang), cy = cos(ang)
            let hy = cy >= 0 ? sec.halfDorsal : sec.halfVentral
            let p0 = sec.center + sec.right * (sec.halfWidth * sx * 0.97) + sec.up * (hy * cy * 0.97)
            let nrm = simd_normalize(sec.right * sx / max(sec.halfWidth, 1e-3) + sec.up * cy / max(hy, 1e-3))
            let L = plan.cardLength * (0.6 + 0.8 * rng.next01()) * (cy < -0.6 ? 1.5 : 1)
            let d = simd_normalize(nrm * 0.45 - f.A * 0.85 + V3(0, -0.15, 0))
            let mat = cy < -0.55 ? white : fur
            let srf = Prim.tube([p0 - d * 0.003, p0 + d * (0.5 * L), p0 + d * L + V3(0, -0.2 * L, 0)], radii: [0.0035, 0.0024, 0.0003], sides: 3, seamTile: 0.02, material: mat)
            if t > 0.5 { rig.base[0].add(srf) } else { rig.add(srf, to: spine) }
            _ = k
        }
    }
}

/// Small deterministic RNG for card scatter.
struct SplitMix {
    var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
    mutating func next01() -> Float { Float(next() >> 40) / Float(1 << 24) }
}
