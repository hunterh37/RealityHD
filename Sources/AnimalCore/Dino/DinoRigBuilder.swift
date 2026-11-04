import Foundation
import simd
import RealCore

/// A built dinosaur: rig plus joint specs in declaration order.
public struct DinoRig: Sendable {
    public var profile: DinoProfile
    public var seed: UInt64
    public var rig: Rig
    public var joints: [BirdJointSpec]
    public var jointNames: [String] { joints.map(\.name) }
    /// Hip joint height above the ground at rest.
    public var hipHeight: Float
    public var triangleCount: Int { rig.base[0].triangleCount + rig.parts.reduce(0) { $0 + $1.levels[0].triangleCount } }
}

/// Joint names shared by every dinosaur rig.
public enum DinoJoint {
    public static let pelvis = "pelvis", chest = "chest", neck0 = "neck0", neck1 = "neck1", headYaw = "headYaw", head = "head", jaw = "jaw"
    public static let tailYaw = "tailYaw"
    public static let tails = ["tail0", "tail1", "tail2", "tail3"]
    public static let axial = [pelvis, chest, neck0, neck1, headYaw, head, jaw, tailYaw] + tails
    public enum Segment: String, CaseIterable, Sendable { case hip, knee, ankle, toe }
    /// Limb prefixes: bipeds `legL legR` plus arms `armL armR`, quadrupeds `hindL hindR foreL foreR`.
    public static func limbs(_ stance: DinoStance) -> [String] { stance == .biped ? ["legL", "legR"] : ["hindL", "hindR", "foreL", "foreR"] }
    public static func name(_ limb: String, _ s: Segment) -> String { "\(limb)_\(s.rawValue)" }
    public static func shoulder(_ side: String) -> String { "arm\(side)_shoulder" }
    public static func elbow(_ side: String) -> String { "arm\(side)_elbow" }
    public static func sickle(_ side: String) -> String { "leg\(side)_sickle" }

    /// Joint count per species: 12 axial; bipeds 8 leg + 4 arm (+2 sickle claws); quadrupeds 16 leg.
    public static func count(_ p: DinoProfile) -> Int { 12 + (p.isBiped ? 12 + (p.hasSickleClaw ? 2 : 0) : 16) }
}

public enum DinoRigBuilder {
    static let X = V3(1, 0, 0), Y = V3(0, 1, 0)

    public static func build(_ p: DinoProfile, seed: UInt64 = 1) -> DinoRig {
        var rng = SeededRNG(seed: seed &+ 0xD1)
        let girth = 1 + rng.float(-0.04...0.04)
        let tusk = 1 + rng.float(-0.12...0.12)
        var rig = Rig(name: p.species.rawValue, lods: 1, switchDistances: [])
        var specs: [BirdJointSpec] = []
        var indexOf: [String: Int] = [:]
        func declare(_ name: String, _ parent: String?, _ pivot: V3, _ axis: V3, _ range: ClosedRange<Float>) {
            let ax = simd_normalize(axis)
            rig.part(name, parent: parent, pivot: pivot, joint: Joint(.revolute, axis: ax, range: range, duration: 0.4))
            indexOf[name] = specs.count
            specs.append(BirdJointSpec(name: name, parent: parent.flatMap { indexOf[$0] }, pivot: pivot, axis: ax, range: range, mimic: nil))
        }
        func mat(_ r: DinoMaterials.Region) -> MaterialKey { DinoMaterials.key(p.species, r) }
        let tip = p.spine[0].z, snout = p.spine[p.spine.count - 1].z, L = tip - snout
        func center(_ z: Float) -> V3 { V3(0, p.section(at: z).y, z) }

        // Axial joints.
        let hipY = p.hind.hip.y
        declare(DinoJoint.pelvis, nil, V3(0, hipY, 0), X, -35...35)
        declare(DinoJoint.chest, DinoJoint.pelvis, center(p.chestZ), X, -30...30)
        let neckMid = (p.neckZ + p.headZ) / 2
        declare(DinoJoint.neck0, DinoJoint.chest, center(p.neckZ), X, -45...45)
        declare(DinoJoint.neck1, DinoJoint.neck0, center(neckMid), X, -45...45)
        declare(DinoJoint.headYaw, DinoJoint.neck1, center(p.headZ), Y, -60...60)
        declare(DinoJoint.head, DinoJoint.headYaw, center(p.headZ), X, -50...50)
        declare(DinoJoint.jaw, DinoJoint.head, p.jawHinge, -X, 0...50)
        declare(DinoJoint.tailYaw, DinoJoint.pelvis, center(p.tailRoot), Y, -45...45)
        let tailStep = (tip - p.tailRoot) / 4
        var tailZ: [Float] = []
        for k in 0..<4 {
            let z = p.tailRoot + Float(k) * tailStep
            tailZ.append(z)
            declare(DinoJoint.tails[k], k == 0 ? DinoJoint.tailYaw : DinoJoint.tails[k - 1], center(z), X, -35...35)
        }

        // Torso mass multiplier: full over chest and hips, fading into the neck and the tail.
        func bulk(_ z: Float) -> Float {
            let back = p.tailRoot + (tip - p.tailRoot) * 0.35, front = p.neckZ
            func ss(_ x: Float) -> Float { let t = min(max(x, 0), 1); return t * t * (3 - 2 * t) }
            let w = ss((back - z) / max(0.001, back - p.tailRoot)) * ss((z - front) / max(0.001, p.chestZ - front))
            return 1 + p.bulk * w
        }
        // Midline body: one loft per part, overlapping its neighbours a little.
        func trunk(_ z0: Float, _ z1: Float, _ part: String, _ m: MaterialKey, n: Int, headUV: Bool = false) {
            let ov = 0.025 * L
            let za = min(z0 + ov, tip), zb = max(z1 - ov, snout)
            var secs: [LoftSection] = []
            for i in 0..<n {
                let z = za + (zb - za) * Float(i) / Float(n - 1)
                let s = p.section(at: z)
                let m = girth * bulk(z)
                let dz = 0.01 * L
                let t = simd_normalize(center(z - dz) - center(z + dz))
                let up = simd_normalize(simd_cross(X, t))
                secs.append(LoftSection(center: V3(0, s.y, z), right: X, up: up, halfWidth: s.halfWidth * m,
                                        halfDorsal: s.halfDorsal * m, halfVentral: s.halfVentral * m, exponent: 2.2))
            }
            let v: ClosedRange<Float> = headUV ? 0...1 : ((tip - za) / L)...((tip - zb) / L)
            rig.add(Loft.build(secs, segments: 28, vRange: v, material: m, caps: true), to: part)
        }
        let coat = p.feathered ? mat(.feather) : mat(.skin)
        for k in 0..<4 { trunk(k == 3 ? tip : tailZ[k + 1], tailZ[k], DinoJoint.tails[k], coat, n: 7) }
        trunk(p.tailRoot, p.chestZ, DinoJoint.pelvis, coat, n: 10)
        trunk(p.chestZ, p.neckZ, DinoJoint.chest, coat, n: 9)
        trunk(p.neckZ, neckMid, DinoJoint.neck0, coat, n: 5)
        trunk(neckMid, p.headZ, DinoJoint.neck1, coat, n: 5)
        trunk(p.headZ, snout, DinoJoint.head, mat(.head), n: 12, headUV: true)

        // Lower jaw, mouth lining and teeth.
        var jsecs: [LoftSection] = []
        if p.species == .triceratops {
            // Beak-shaped mandible: deep at the hinge, tucked under the head, tapering to the predentary.
            let z0 = p.jawHinge.z, z1 = p.chin.z
            for i in 0..<10 {
                let t = Float(i) / 9
                let z = z0 + (z1 - z0) * t
                let hs = p.section(at: z)
                let w = hs.halfWidth * girth * (0.86 - 0.2 * t)
                let d = hs.halfVentral * (0.75 - 0.15 * t)
                let cy = hs.y - hs.halfVentral * 0.55
                jsecs.append(LoftSection(center: V3(0, cy, z), right: X, up: Y, halfWidth: w, halfDorsal: d * 0.9, halfVentral: d * 0.6, exponent: 2.0))
            }
        }
        for i in 0..<(p.species == .triceratops ? 0 : 8) {
            let t = Float(i) / 7
            let c = p.jawHinge + (p.chin - p.jawHinge) * t
            let w = p.jawHinges.x + (p.jawTip.x - p.jawHinges.x) * t, d = p.jawHinges.y + (p.jawTip.y - p.jawHinges.y) * t
            let up = simd_normalize(simd_cross(X, simd_normalize(p.chin - p.jawHinge)))
            jsecs.append(LoftSection(center: c, right: X, up: up, halfWidth: w * girth, halfDorsal: d * 0.35, halfVentral: d, exponent: 2.2))
        }
        rig.add(Loft.build(jsecs, segments: 20, material: mat(.head), caps: true), to: DinoJoint.jaw)
        if p.teeth > 0 {
            for i in 0..<p.teeth {
                let t = 0.12 + 0.84 * Float(i) / Float(p.teeth - 1)
                let c = p.jawHinge + (p.chin - p.jawHinge) * t
                let w = (p.jawHinges.x + (p.jawTip.x - p.jawHinges.x) * t) * 0.82
                let len = p.jawHinges.y * (0.3 + 0.25 * sin(t * .pi)) * tusk * (0.9 + 0.2 * rng.float())
                let r = len * 0.2
                for sx: Float in [-1, 1] {
                    let up = V3(sx * w, c.y + p.jawHinges.y * 0.25, c.z)
                    rig.add(Prim.tube([up, up + V3(0, -len * 0.6, -len * 0.08), up + V3(0, -len, -len * 0.1)], radii: [r, r * 0.6, r * 0.05], sides: 6, seamTile: 0.05, material: mat(.tooth)), to: DinoJoint.head)
                    let lo = V3(sx * w * 0.92, c.y + p.jawHinges.y * 0.1, c.z - len * 0.25)
                    rig.add(Prim.tube([lo, lo + V3(0, len * 0.5, -len * 0.05), lo + V3(0, len * 0.8, -len * 0.08)], radii: [r * 0.85, r * 0.5, r * 0.05], sides: 6, seamTile: 0.05, material: mat(.tooth)), to: DinoJoint.jaw)
                }
            }
        }
        // Eyes.
        let headLen = p.headZ - snout
        let ez = p.headZ - headLen * (p.species == .triceratops ? 0.3 : 0.22)
        let es = p.section(at: ez)
        let er = max(0.008, es.halfWidth * 0.16)
        for sx: Float in [-1, 1] {
            let ec = V3(sx * es.halfWidth * girth * 0.86, es.y + es.halfDorsal * 0.45, ez)
            rig.add(Loft.ellipsoid(center: ec, axis: V3(sx, 0, -0.3), up: Y, radii: V3(er, er, er * 0.8), rings: 6, segments: 10, material: mat(.eye)), to: DinoJoint.head)
            // Brow ridge over the eye.
            rig.add(Loft.ellipsoid(center: ec + V3(-sx * er * 0.2, er * 1.1, 0), axis: V3(0, 0, -1), up: Y, radii: V3(er * 1.1, er * 0.55, er * 2.2), rings: 6, segments: 10, material: mat(.head)), to: DinoJoint.head)
        }
        // Triceratops: frill, brow horns, nose horn, beak.
        if p.species == .triceratops {
            let hb = p.section(at: p.headZ)
            let fc = V3(0, hb.y + 0.65, p.headZ + 0.05)
            rig.add(Loft.ellipsoid(center: fc, axis: simd_normalize(V3(0, -0.55, 1)), up: V3(1, 0, 0), radii: V3(0.06, 1.05, 0.95), rings: 10, segments: 24,
                                   material: mat(.frill)), to: DinoJoint.head)
            for k in 0..<14 {
                let a = Float(k) / 13 * .pi
                let pt = fc + V3(cos(a) * 1.02, sin(a) * 0.55 + 0.05, sin(a) * 0.62)
                rig.add(Prim.tube([pt, pt + simd_normalize(pt - fc) * 0.14], radii: [0.06, 0.004], sides: 6, seamTile: 0.1, material: mat(.horn)), to: DinoJoint.head)
            }
            for sx: Float in [-1, 1] {
                let b = V3(sx * 0.22, es.y + es.halfDorsal * 0.9, ez + 0.05)
                let L = 1.0 * tusk
                rig.add(Prim.tube([b, b + V3(sx * 0.05, 0.45 * L, -0.25 * L), b + V3(sx * 0.06, 0.75 * L, -0.65 * L), b + V3(sx * 0.05, 0.85 * L, -1.0 * L)],
                                  radii: [0.12, 0.09, 0.05, 0.004], sides: 10, seamTile: 0.2, material: mat(.horn)), to: DinoJoint.head)
            }
            let ns = p.section(at: -4.3)
            let nb = V3(0, ns.y + ns.halfDorsal * 0.85, -4.3)
            rig.add(Prim.tube([nb, nb + V3(0, 0.2, -0.08), nb + V3(0, 0.32, -0.04)], radii: [0.09, 0.05, 0.004], sides: 8, seamTile: 0.1, material: mat(.horn)), to: DinoJoint.head)
            let bk = center(snout + 0.25)
            rig.add(Loft.ellipsoid(center: bk + V3(0, -0.04, -0.12), axis: V3(0, -0.4, -1), up: Y, radii: V3(0.07, 0.14, 0.2), rings: 7, segments: 12, material: mat(.horn)), to: DinoJoint.head)
            let cs = p.section(at: p.chin.z + 0.1)
            rig.add(Loft.ellipsoid(center: V3(0, cs.y - cs.halfVentral * 0.6, p.chin.z + 0.14), axis: V3(0, 0.45, -1), up: Y, radii: V3(0.07, 0.07, 0.15), rings: 7, segments: 12, material: mat(.horn)), to: DinoJoint.jaw)
        }

        // Limbs.
        func mirror(_ v: V3, _ sx: Float) -> V3 { V3(v.x * sx, v.y, v.z) }
        func segment(_ a: V3, _ b: V3, _ r0: V3, _ r1: V3, to part: String) {
            let up = abs(simd_normalize(b - a).y) > 0.7 ? V3(0, 0, -1) : Y
            rig.add(Loft.along([a, b], up: up, count: 6, segments: 18, vRange: 0...simd_distance(a, b), material: mat(.limb),
                               radius: { t in r0 + (r1 - r0) * t }), to: part)
        }
        func digits(_ ball: V3, count: Int, spread: Float, length: Float, r: Float, down: Bool, to part: String) {
            for k in 0..<count {
                let a = (Float(k) - Float(count - 1) / 2) * spread
                let dir = simd_normalize(V3(sin(a), down ? -0.08 : -0.3, -cos(a)))
                let e = ball + dir * length
                rig.add(Loft.along([ball, ball + dir * length * 0.5, e], up: Y, count: 5, segments: 12, vRange: 0...length, material: mat(.limb),
                                   radius: { t in V3(r, r * 0.8, r * 0.9) * (1 - 0.4 * t) }), to: part)
                let cl = r * 1.8
                rig.add(Prim.tube([e - dir * r * 0.3, e + dir * cl * 0.6 + V3(0, -cl * 0.25, 0), e + dir * cl + V3(0, -cl * 0.7, 0)],
                                  radii: [r * 0.55, r * 0.35, r * 0.03], sides: 6, seamTile: 0.05, material: mat(.claw)), to: part)
            }
        }
        func leg(_ limb: String, _ l: DinoLeg, sx: Float, parent: String, toes: Int) {
            let hip = mirror(l.hip, sx), knee = mirror(l.knee, sx), ankle = mirror(l.ankle, sx), ball = mirror(l.ball, sx)
            let r = l.radii
            declare(DinoJoint.name(limb, .hip), parent, hip, X, -75...75)
            declare(DinoJoint.name(limb, .knee), DinoJoint.name(limb, .hip), knee, X, -100...70)
            declare(DinoJoint.name(limb, .ankle), DinoJoint.name(limb, .knee), ankle, X, -80...80)
            declare(DinoJoint.name(limb, .toe), DinoJoint.name(limb, .ankle), ball, X, -70...70)
            // Thigh: a heavy muscle mass that blends into the flank.
            // Its top is buried in the flank: a root mass on the parent body plus a thigh that starts above the hip.
            let tl = simd_distance(hip, knee)
            let pm = mat(.limb)
            rig.add(Loft.ellipsoid(center: hip + V3(-sx * r.x * 0.25, -r.x * 0.1, 0), axis: V3(0, -1, 0), up: V3(0, 0, -1), radii: V3(r.x * 1.05, r.x * 1.25, r.x * 1.25),
                                   rings: 10, segments: 18, material: pm), to: parent)
            let tc = hip + (knee - hip) * 0.4 + V3(0, r.x * 0.15, 0)
            rig.add(Loft.ellipsoid(center: tc, axis: knee - hip, up: V3(0, 0, -1), radii: V3(r.x * 0.95, r.x * 1.2, tl * 0.72), rings: 12, segments: 18,
                                   material: pm, uv: { u, v in V2(u, v * 2) }), to: DinoJoint.name(limb, .hip))
            // Joint fillers: spheres on the child part sized to cover both neighbours through the full bend.
            rig.add(Loft.ellipsoid(center: knee, axis: V3(0, -1, 0), up: V3(0, 0, -1), radii: V3(r.y * 1.3, r.y * 1.35, r.y * 1.4), rings: 8, segments: 16, material: pm), to: DinoJoint.name(limb, .knee))
            rig.add(Loft.ellipsoid(center: ankle, axis: V3(0, -1, 0), up: V3(0, 0, -1), radii: V3(r.z * 1.2, r.z * 1.25, r.z * 1.25), rings: 8, segments: 14, material: pm), to: DinoJoint.name(limb, .ankle))
            let kd = simd_normalize(ankle - knee), ad = simd_normalize(ball - ankle)
            segment(knee - kd * r.y * 0.6, ankle, V3(r.y * 1.25, r.y * 1.3, r.y * 1.3), V3(r.y * 0.75, r.y * 0.8, r.y * 0.8), to: DinoJoint.name(limb, .knee))
            segment(ankle - ad * r.z * 0.5, ball, V3(r.z * 1.1, r.z * 1.15, r.z * 1.15), V3(r.z * 0.9, r.z * 0.85, r.z * 0.85), to: DinoJoint.name(limb, .ankle))
            rig.add(Loft.ellipsoid(center: ball, axis: V3(0, 0, -1), up: Y, radii: V3(r.z * 1.2, r.z * 0.7, r.z * 1.1), rings: 6, segments: 12, material: mat(.limb)), to: DinoJoint.name(limb, .toe))
            digits(ball + V3(0, -r.w * 0.2, 0), count: toes, spread: toes == 2 ? 0.18 : 0.32, length: l.toe, r: r.w, down: true, to: DinoJoint.name(limb, .toe))
        }
        func arm(_ side: String, _ l: DinoLeg, sx: Float) {
            let sh = mirror(l.hip, sx), el = mirror(l.knee, sx), hand = mirror(l.ankle, sx)
            let r = l.radii
            declare(DinoJoint.shoulder(side), DinoJoint.chest, sh, X, -70...70)
            declare(DinoJoint.elbow(side), DinoJoint.shoulder(side), el, X, -80...80)
            segment(sh, el, V3(r.x, r.x, r.x), V3(r.y, r.y, r.y), to: DinoJoint.shoulder(side))
            segment(el, hand, V3(r.y, r.y, r.y), V3(r.z, r.z, r.z), to: DinoJoint.elbow(side))
            let fingers = p.species == .trex ? 2 : 3
            digits(hand, count: fingers, spread: 0.25, length: l.toe, r: r.w, down: false, to: DinoJoint.elbow(side))
            if p.feathered {
                // Wing-like feather fan along the forearm and hand.
                for k in 0..<9 {
                    let t = Float(k) / 8
                    let b = el + (hand + (hand - el) * 0.25 - el) * t
                    let dir = simd_normalize(V3(sx * 0.25, -0.75, 0.55 - 0.4 * t))
                    rig.add(Feather.card(base: b, direction: dir, normal: V3(sx, 0, 0), length: 0.07 + 0.06 * t, width: 0.03, droop: 0.01,
                                         flipSide: sx < 0, material: mat(.featherCard)), to: DinoJoint.elbow(side))
                }
            }
        }
        for (i, sx) in [Float(1), -1].enumerated() {
            let side = i == 0 ? "L" : "R"
            if p.isBiped {
                leg("leg\(side)", p.hind, sx: sx, parent: DinoJoint.pelvis, toes: p.hasSickleClaw ? 2 : 3)
                if p.hasSickleClaw {
                    let ball = mirror(p.hind.ball, sx) + V3(-sx * p.hind.radii.w * 1.2, p.hind.radii.w * 0.6, -p.hind.radii.w)
                    declare(DinoJoint.sickle(side), DinoJoint.name("leg\(side)", .toe), ball, X, -20...60)
                    let r = p.hind.radii.w, c = 0.065 * tusk
                    rig.add(Prim.tube([ball, ball + V3(0, c * 0.45, -c * 0.45), ball + V3(0, c * 0.35, -c * 0.95), ball + V3(0, -c * 0.1, -c * 1.15)],
                                      radii: [r * 0.75, r * 0.55, r * 0.3, r * 0.03], sides: 8, seamTile: 0.03, material: mat(.claw)), to: DinoJoint.sickle(side))
                }
                arm(side, p.fore, sx: sx)
            } else {
                leg("hind\(side)", p.hind, sx: sx, parent: DinoJoint.pelvis, toes: 3)
                leg("fore\(side)", p.fore, sx: sx, parent: DinoJoint.chest, toes: 4)
            }
        }
        // Raptor tail fan.
        if p.feathered {
            for k in 0..<14 {
                let z = tailZ[2] + (tip - tailZ[2]) * Float(k) / 13
                let s = p.section(at: z)
                for sx: Float in [-1, 1] {
                    let b = V3(sx * s.halfWidth * 0.8, s.y, z)
                    rig.add(Feather.card(base: b, direction: simd_normalize(V3(sx, 0.05, 0.9)), normal: Y, length: 0.12, width: 0.035,
                                         flipSide: sx < 0, material: mat(.featherCard)), to: z < tailZ[3] ? DinoJoint.tails[2] : DinoJoint.tails[3])
                }
            }
        }

        rig.states = [RigState("stand"), RigState("roar", [DinoJoint.jaw: 40, DinoJoint.neck0: 20, DinoJoint.head: 15])]
        rig.defaultState = "stand"
        return DinoRig(profile: p, seed: seed, rig: rig, joints: specs, hipHeight: hipY)
    }
}
