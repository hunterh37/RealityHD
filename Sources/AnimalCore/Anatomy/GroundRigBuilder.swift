import Foundation
import simd
import RealCore

/// A built ground animal: rig plus the numbers the behavior and driver code need.
public struct GroundRig: Sendable {
    public var profile: GroundProfile
    public var rig: Rig
    public var joints: [BirdJointSpec]
    /// Body center above the feet when standing.
    public var comHeight: Float
    /// Small mammals render as one skinned mesh (`Rig.skin`); the rest keep rigid parts.
    public var skinned: Bool = false
    public var triangleCount: Int { rig.base[0].triangleCount + rig.parts.reduce(0) { $0 + $1.levels[0].triangleCount } }
}

struct GroundFrame {
    let p: GroundProfile
    let a: GroundAnatomy
    let id: String
    /// Body axis (toward the head, pointing down by `pitch`), dorsal axis, center.
    let A: V3, U: V3, C: V3
    let psi: Float

    init(_ p: GroundProfile) {
        self.p = p; a = p.anatomy; id = p.species.rawValue
        psi = radians(a.pitch)
        A = V3(0, -sin(psi), -cos(psi)); U = V3(0, cos(psi), -sin(psi))
        C = V3(0, a.standHeight, 0)
    }

    func mat(_ r: FaunaMaterials.GroundRegion) -> MaterialKey { FaunaMaterials.key(id, r) }
    static let X = V3(1, 0, 0), Y = V3(0, 1, 0), Z = V3(0, 0, 1)

    var bodyProfile: Profile {
        a.pitch > 10 && p.species == .easternCottontail
            ? Profile([V2(0, 0.7), V2(0.18, 1.05), V2(0.4, 1.0), V2(0.62, 0.86), V2(0.82, 0.68), V2(1, 0.52)])
            : Profile([V2(0, 0.55), V2(0.18, 0.88), V2(0.4, 1.0), V2(0.62, 0.96), V2(0.82, 0.8), V2(1, 0.6)])
    }

    func shoulder(_ l: GroundJoint.Leg) -> V3 { C + A * (0.34 * a.bodyLength) - U * ((a.digitigrade ? 0.06 : (a.thighScale > 1.3 ? 0.12 : 0.26)) * a.bodyDepth) + V3(l.side.sign * 0.34 * a.bodyWidth, 0, 0) }
    func hip(_ l: GroundJoint.Leg) -> V3 { C - A * (0.34 * a.bodyLength) + U * ((a.digitigrade ? 0.1 : (a.thighScale > 1.3 ? 0.0 : -0.2)) * a.bodyDepth) + V3(l.side.sign * 0.36 * a.bodyWidth, 0, 0) }
    var neckPivot: V3 { C + A * (0.46 * a.bodyLength) + U * ((a.neckLength > 0.2 ? 0.24 : 0.12) * a.bodyDepth) }
    var neckVec: V3 { let r = radians(a.neckRise); return V3(0, sin(r), -cos(r)) * a.neckLength }
    var headCenter: V3 { neckPivot + neckVec + V3(0, 0.25 * a.headHeight, -0.5 * a.headLength + 0.02) }
    var headProfile: Profile {
        if let h = a.headShape { return Profile(h) }
        return Profile([V2(0, 0.8), V2(0.2, 1.0), V2(0.45, 0.92), V2(0.7, 0.6), V2(0.9, 0.3), V2(1, 0.14)])
    }
    /// Eye position: shaped heads seat it on the skull surface, the originals keep their placement.
    func eye(_ s: Side) -> V3 {
        if a.headShape == nil && p.species == .fennecFox {
            let t: Float = 0.5
            return headCenter + V3(s.sign * 0.5 * a.headWidth * headProfile(t) * 0.8, 0.16 * a.headHeight, (0.5 - t) * a.headLength)
        }
        if a.headShape == nil { return headCenter + V3(s.sign * 0.5 * a.headWidth * 0.8, 0.12 * a.headHeight, -0.12 * a.headLength) }
        let t: Float = 0.42
        let hw = 0.5 * a.headWidth * headProfile(t)
        let up: Float = p.species == .easternGraySquirrel ? 0.26 : 0.14
        return headCenter + V3(s.sign * hw * (p.species == .easternGraySquirrel ? 0.84 : 0.9), up * a.headHeight, (0.5 - t) * a.headLength)
    }
    var rump: V3 { C - A * (0.5 * a.bodyLength) + U * (0.1 * a.bodyDepth) }
}

public enum GroundRigBuilder {
    /// Two-bone IK in the sagittal plane (coordinates are (z, y)). Returns the middle joint.
    static func twoBone(hip: V2, foot: V2, l1: Float, l2: Float, forward: Bool) -> V2 {
        let d0 = foot - hip
        let dist = max(1e-4, min(simd_length(d0), l1 + l2 - 1e-4))
        let dir = d0 / simd_length(d0)
        let a = (l1 * l1 - l2 * l2 + dist * dist) / (2 * dist)
        let h = max(0, l1 * l1 - a * a).squareRoot()
        let base = hip + dir * a
        let perp = V2(-dir.y, dir.x)
        let k1 = base + perp * h, k2 = base - perp * h
        // Forward means smaller z.
        return (k1.x < k2.x) == forward ? k1 : k2
    }

    public static func build(_ p: GroundProfile, seed: UInt64 = 1) -> GroundRig {
        let f = GroundFrame(p)
        let a = f.a
        var rig = Rig(name: p.species.rawValue + (p.variant == .antlered ? "-antlered" : ""), lods: 1, switchDistances: [])
        var specs = [BirdJointSpec?](repeating: nil, count: GroundJoint.count)

        func declare(_ j: GroundJoint, parent: GroundJoint?, pivot: V3, axis: V3) {
            let ax = simd_normalize(axis)
            rig.part(j.name, parent: parent?.name, pivot: pivot, joint: Joint(.revolute, axis: ax, range: j.range, duration: 0.4))
            specs[j.index] = BirdJointSpec(name: j.name, parent: parent?.index, pivot: pivot, axis: ax, range: j.range, mimic: nil)
        }

        // Legs first so the leg geometry is known; chain endpoints.
        struct Chain { var hip: V3, knee: V3, ankle: V3, toe: V3 }
        var chains: [GroundJoint.Leg: Chain] = [:]
        for l in GroundJoint.Leg.allCases {
            let hip = l.isFore ? f.shoulder(l) : f.hip(l)
            let total = l.isFore ? a.foreLeg : a.hindLeg
            let l1 = total * (l.isFore ? 0.52 : 0.5), l2 = total * (l.isFore ? 0.48 : 0.5)
            let footLen = l.isFore ? total * 0.22 : total * 0.42
            if a.digitigrade {
                // Toe walker: hip, stifle or carpus, then fetlock (front) or hock (behind) over the hoof or paw.
                let ankleH = l.isFore ? a.foreAnkle : a.hindAnkle
                let tz = l.isFore ? hip.z - 0.015 : hip.z + 0.07 * a.bodyLength
                let target = V2(tz, ankleH)
                let chord = simd_length(V2(hip.z, hip.y) - target)
                let kk: Float = l.isFore ? 0.53 : 0.66
                let knee = twoBone(hip: V2(hip.z, hip.y), foot: target, l1: chord * kk, l2: chord * kk, forward: true)
                let an = V3(hip.x, ankleH, tz)
                let toe = l.isFore ? an + V3(0, -(ankleH - a.legRadius * 0.4), -ankleH * 0.28) : an + V3(0, -(ankleH - a.legRadius * 0.4), -ankleH * 0.05)
                chains[l] = Chain(hip: hip, knee: V3(hip.x, knee.y, knee.x), ankle: an, toe: toe)
                continue
            }
            let groundY: Float = a.legRadius * 0.8
            let ankleTarget = V2(hip.z + (l.isFore ? -0.015 : 0.03), groundY + (l.isFore ? 0 : a.legRadius * 0.6))
            let knee = twoBone(hip: V2(hip.z, hip.y), foot: ankleTarget, l1: l1, l2: l2, forward: !l.isFore)
            let k = V3(hip.x, knee.y, knee.x), an = V3(hip.x, ankleTarget.y, ankleTarget.x)
            chains[l] = Chain(hip: hip, knee: k, ankle: an, toe: an + V3(0, -a.legRadius * 0.2, -footLen))
        }

        let plan = QuadrupedPlan.plan(for: p)
        // Small furred mammals (pets, squirrels): blended neck, seated eyes, cupped ears, fur-card tail.
        let small = plan == nil && !a.hooves && !a.spines && a.bodyLength < 0.35
        declare(.spine, parent: nil, pivot: f.C, axis: GroundFrame.X)
        declare(.tailYaw, parent: .spine, pivot: f.rump, axis: GroundFrame.Y)
        let tl = a.tailLength
        let tailSeg = tl / 3
        // Tail rest path: out from the rump, curling up for squirrels and chipmunks.
        let curl: Float = p.species == .easternGraySquirrel ? 1 : (p.species == .easternChipmunk ? 0.75 : 0)
        func tailPoint(_ i: Int) -> V3 {
            var pos = f.rump
            var ang = radians(-8 + a.pitch - a.tailDrop)
            for k in 0..<i {
                ang += radians(24) * curl * (k == 0 ? 0.4 : 1)
                // Direction: rearward (+z) rotating up by `ang`.
                pos += V3(0, sin(ang), cos(ang)) * tailSeg
            }
            return pos
        }
        declare(.tail0, parent: .tailYaw, pivot: tailPoint(0), axis: GroundFrame.X)
        declare(.tail1, parent: .tail0, pivot: tailPoint(1), axis: GroundFrame.X)
        declare(.tail2, parent: .tail1, pivot: tailPoint(2), axis: GroundFrame.X)

        declare(.neckPitch, parent: nil, pivot: f.neckPivot, axis: GroundFrame.X)
        let headPivot = f.headCenter + V3(0, -0.1 * a.headHeight, 0.4 * a.headLength)
        declare(.headYaw, parent: .neckPitch, pivot: headPivot, axis: GroundFrame.Y)
        declare(.headPitch, parent: .headYaw, pivot: headPivot, axis: GroundFrame.X)
        let gape = f.headCenter + V3(0, -0.28 * a.headHeight, -0.15 * a.headLength)
        declare(.jaw, parent: .headPitch, pivot: gape, axis: -GroundFrame.X)
        let earBase: (Side) -> V3 = { s in f.headCenter + V3(s.sign * 0.26 * a.headWidth, 0.2 * a.headHeight, 0.16 * a.headLength) }
        declare(.earL, parent: .headPitch, pivot: earBase(.left), axis: GroundFrame.X)
        declare(.earR, parent: .headPitch, pivot: earBase(.right), axis: GroundFrame.X)
        let noseTip = f.headCenter + V3(0, -0.04 * a.headHeight, -0.5 * a.headLength)
        declare(.nose, parent: .headPitch, pivot: noseTip, axis: GroundFrame.X)
        let eyeAt: (Side) -> V3 = { f.eye($0) }
        declare(.lidL, parent: .headPitch, pivot: eyeAt(.left), axis: V3(0, 0, -1))
        declare(.lidR, parent: .headPitch, pivot: eyeAt(.right), axis: V3(0, 0, 1))
        for l in GroundJoint.Leg.allCases {
            let c = chains[l]!
            let parent: GroundJoint = l.isFore ? .neckPitch : .spine
            _ = parent
            // Fore legs hang from the chest (base, via no parent), hind legs from the spine part.
            declare(.leg(l, .hip), parent: l.isFore ? nil : .spine, pivot: c.hip, axis: GroundFrame.X)
            declare(.leg(l, .knee), parent: .leg(l, .hip), pivot: c.knee, axis: GroundFrame.X)
            declare(.leg(l, .ankle), parent: .leg(l, .knee), pivot: c.ankle, axis: GroundFrame.X)
        }
        precondition(specs.allSatisfy { $0 != nil })

        // Body: chest in the base, rump in the spine part, both from one profile and one atlas.
        let bp = f.bodyProfile
        let bodySecs = a.depthShape == nil ? 6 : 8
        let fur = f.mat(.body)
        let dShape = a.depthShape.map { Profile($0 as [Float]) }, wShape = a.widthShape.map { Profile($0 as [Float]) }
        func section(_ t: Float) -> LoftSection {
            let r = bp(t)
            let rd = dShape?(t) ?? r, rw = wShape?(t) ?? r
            let c = f.C + f.A * ((t - 0.5) * a.bodyLength)
            let depthK: Float = p.species == .europeanHedgehog ? 1.0 : 1
            return LoftSection(center: c, right: GroundFrame.X, up: f.U, halfWidth: 0.5 * a.bodyWidth * rw, halfDorsal: 0.5 * a.bodyDepth * 1.0 * rd * depthK,
                               halfVentral: 0.5 * a.bodyDepth * 0.9 * rd, exponent: a.depthShape == nil ? 2.2 : 2.0)
        }
        func lofted(_ t0: Float, _ t1: Float, _ n: Int, material: MaterialKey, uv: ((Float, Float) -> V2)? = nil) -> Surface {
            let secs = (0..<n).map { section(t0 + (t1 - t0) * Float($0) / Float(n - 1)) }
            return Loft.build(secs, segments: 20, vRange: t0...t1, material: material, uv: uv)
        }
        if a.spines {
            // Hedgehog: spine dome over the back, fur belly.
            func dome(_ t0: Float, _ t1: Float) -> Surface {
                let secs = (0..<7).map { i -> LoftSection in
                    var s = section(t0 + (t1 - t0) * Float(i) / 6)
                    s.halfDorsal *= 1.9; s.halfWidth *= 1.06; s.halfVentral *= 0.8
                    s.center += f.U * (0.18 * a.bodyDepth)
                    return s
                }
                let circ = 2 * Float.pi * 0.5 * (a.bodyWidth + a.bodyDepth) / 2
                return Loft.build(secs, segments: 24, vRange: t0...t1, material: f.mat(.quill)) { u, v in V2(u * circ, v * a.bodyLength) }
            }
            rig.base[0].add(lofted(0.46, 1, 6, material: fur))
            rig.add(lofted(0, 0.54, 6, material: fur), to: GroundJoint.spine.name)
            rig.base[0].add(dome(0.5, 1.02))
            rig.add(dome(-0.02, 0.52), to: GroundJoint.spine.name)
        } else if plan == nil {
            rig.base[0].add(lofted(0.46, small ? 0.9 : 1, bodySecs, material: fur))
            if a.rumpPatch > 0 {
                let rp = a.rumpPatch
                rig.add(lofted(0, rp, 5, material: f.mat(.rump)), to: GroundJoint.spine.name)
                rig.add(lofted(rp, 0.54, bodySecs, material: fur), to: GroundJoint.spine.name)
            } else {
                rig.add(lofted(0, 0.54, bodySecs, material: fur), to: GroundJoint.spine.name)
            }
            if a.withers > 0 {
                // Shoulder blade hump rising over the front legs.
                let w = a.withers
                rig.base[0].add(Loft.ellipsoid(center: f.C + f.A * (0.26 * a.bodyLength) + f.U * (0.26 * a.bodyDepth * w), axis: -f.A - f.U * 0.25, up: f.U,
                                               radii: V3(0.34 * a.bodyWidth, 0.2 * a.bodyDepth * w, 0.2 * a.bodyLength), rings: 9, segments: 16, material: fur))
            }
            if a.bristle > 0 {
                // Dorsal bristle ridge: stiff hairs leaning back along the spine from the poll to the rump.
                let n = 34
                for k in 0..<n {
                    let t = 1.04 - 1.0 * Float(k) / Float(n - 1)
                    let sec = section(max(0, min(1, t)))
                    let jit = Float(k % 5) * 0.12 - 0.24
                    let b = sec.center + f.U * (sec.halfDorsal * 0.92) + V3(jit * 0.012, 0, 0)
                    let L = a.bristle * (0.7 + 0.5 * sin(.pi * min(1, Float(k) / Float(n - 1) * 1.1))) * (0.85 + 0.3 * Float(k % 3) / 2)
                    let d = simd_normalize(f.U * 0.85 - f.A * 0.5 + V3(jit * 0.25, 0, 0))
                    let pts = [b - d * 0.004, b + d * (0.5 * L) + V3(0, 0, 0.1 * L * 0.5), b + d * L + V3(0, -0.12 * L, 0.35 * L)]
                    let surf = Prim.tube(pts, radii: [0.0036, 0.0026, 0.0004], sides: 4, seamTile: 0.02, material: f.mat(.bristle))
                    if t > 0.54 { rig.base[0].add(surf) } else { rig.add(surf, to: GroundJoint.spine.name) }
                }
            }
        }

        // Neck and head.
        let hc = f.headCenter, hl = a.headLength
        let neckEnd = hc + V3(0, -0.1 * a.headHeight, 0.3 * hl)
        let limbFur = a.darkLimbs ? f.mat(.head) : (small ? f.mat(.limb) : fur)
        // Neck: sections along the spine of the neck with a shoulder blend at the base, a crest above and
        // a brisket or throat swell below.
        let nBase = small ? f.C + f.A * (0.36 * a.bodyLength) + f.U * (0.02 * a.bodyDepth) : f.neckPivot - f.A * (0.1 * a.bodyLength) - f.U * (0.06 * a.bodyDepth)
        let neckPath = a.neckLength > 0 ? [nBase, lerp(f.neckPivot, neckEnd, 0.5) + V3(0, 0.02 * a.neckLength, 0), neckEnd] : [nBase, lerp(nBase, neckEnd, 0.5), neckEnd]
        let NN = 13
        let npts = Loft.resample(neckPath, count: NN)
        let r0 = small ? 0.5 * a.bodyWidth * bp(0.86) : 0.5 * a.bodyWidth * a.neckThick, r1 = 0.5 * a.headWidth * 0.95
        func neckSecs(_ i0: Int, _ i1: Int, grow: Float = 1, mane: Float = 0) -> [LoftSection] {
            (i0...i1).map { i in
                let t = Float(i) / Float(NN - 1)
                let fw = simd_normalize(npts[min(NN - 1, i + 1)] - npts[max(0, i - 1)])
                var u = GroundFrame.Y - fw * simd_dot(GroundFrame.Y, fw)
                if simd_length(u) < 1e-5 { u = fw.anyPerpendicular }
                u = simd_normalize(u)
                let base = lerp(r0, r1, a.neckLength > 0 ? pow(t, 0.75) : t)
                let blend: Float = a.neckLength > 0.2 ? 1 + 0.38 * pow(max(0, 1 - t / 0.3), 2) : 1
                let w = base * blend * grow
                let crest = 1 + 0.07 * sin(.pi * min(1, t * 1.2))
                let brisket = 1 + 0.32 * pow(max(0, 1 - t / 0.35), 1.5) + (a.neckLength > 0.2 ? 0.14 * sin(.pi * min(1, max(0, (t - 0.25) / 0.6))) : 0)
                let bump = sin(.pi * min(1, max(0, (t - 0.04) / 0.9)))
                let deepK: Float = small ? lerp(a.bodyDepth / a.bodyWidth * 0.95, 1, pow(t, 0.8)) : 1
                var hv = w * a.neckDeep * brisket * deepK + mane * bump
                let hd = w * a.neckDeep * crest * deepK
                let c = npts[i] - u * (0.35 * mane * bump)
                hv = max(hv, 0.001)
                return LoftSection(center: c, right: simd_normalize(simd_cross(fw, u)), up: u, halfWidth: w, halfDorsal: hd, halfVentral: hv, exponent: 2.1)
            }
        }
        if small {
            // One continuous surface from the chest into the skull: sections blend from the torso's
            // front section to the head's rear section, no cap or seam at the shoulder.
            let s0 = section(0.9)
            let hr = f.headProfile(0), kHs: Float = a.headShape == nil ? 0.5 : 1.0
            let hc0 = f.headCenter + V3(0, 0, 0.5 * a.headLength)
            let s1 = LoftSection(center: hc0, right: GroundFrame.X, up: GroundFrame.Y, halfWidth: 0.5 * a.headWidth * hr,
                                 halfDorsal: kHs * a.headHeight * 0.55 * hr, halfVentral: kHs * a.headHeight * 0.45 * hr, exponent: 2.2)
            let mid = lerp(s0.center, s1.center, 0.5) + f.U * (0.06 * a.bodyDepth)
            var secs: [LoftSection] = []
            for i in 0..<9 {
                let t = Float(i) / 8, k = t * t * (3 - 2 * t)
                let c = (1 - t) * (1 - t) * s0.center + 2 * (1 - t) * t * mid + t * t * s1.center
                let up = simd_normalize(lerp(s0.up, s1.up, k))
                let narrow: Float = 1 - 0.12 * sin(.pi * t)
                secs.append(LoftSection(center: c, right: GroundFrame.X, up: up, halfWidth: lerp(s0.halfWidth, s1.halfWidth, k) * narrow,
                                        halfDorsal: lerp(s0.halfDorsal, s1.halfDorsal, k) * narrow, halfVentral: lerp(s0.halfVentral, s1.halfVentral, k) * narrow,
                                        exponent: lerp(s0.exponent, s1.exponent, k)))
            }
            rig.add(Loft.build(secs, segments: 20, vRange: 0.9...1.0, material: fur), to: GroundJoint.neckPitch.name)
        }
        let iT = a.throatFrom < 1 && !small ? max(2, min(NN - 3, Int(a.throatFrom * Float(NN - 1)))) : NN - 1
        if !small { rig.add(Loft.build(neckSecs(0, iT), segments: 20, vRange: 0.9...1.0, material: limbFur), to: GroundJoint.neckPitch.name) }
        if iT < NN - 1 {
            rig.add(Loft.build(neckSecs(iT, NN - 1), segments: 20, vRange: 0.9...1.0, material: f.mat(.throat)), to: GroundJoint.neckPitch.name)
        }
        if a.maneDrop > 0 {
            let lo = 1, hi = NN - 3
            rig.add(Loft.build(neckSecs(lo, hi, grow: 1.07, mane: a.maneDrop), segments: 22, vRange: 0.9...1.0, material: f.mat(.mane)), to: GroundJoint.neckPitch.name)
            // Long guard hairs hanging off the throat.
            for k in 0..<9 {
                let i = lo + 1 + k * (hi - lo - 1) / 8
                let t = Float(i) / Float(NN - 1)
                let w = lerp(r0, r1, pow(t, 0.75)) * 1.1
                let b = npts[i] - V3(0, w * a.neckDeep * 1.15 + a.maneDrop * 0.55, 0) + V3((Float(k % 3) - 1) * w * 0.25, 0, 0)
                let L = a.maneDrop * (1.1 + 0.2 * Float(k % 2))
                rig.add(Prim.tube([b, b + V3(0, -0.5 * L, 0.2 * L), b + V3(0, -L, 0.28 * L)], radii: [0.007, 0.005, 0.0008], sides: 4, seamTile: 0.02, material: f.mat(.bristle)), to: GroundJoint.neckPitch.name)
            }
        }
        let hp = f.headProfile
        let kH: Float = a.headShape == nil ? 0.5 : 1.0
        var hs: [LoftSection] = []
        for i in 0..<9 {
            let t = Float(i) / 8
            let c = hc + V3(0, -0.12 * a.headHeight * t * t, (0.5 - t) * hl)
            let r = hp(t)
            hs.append(LoftSection(center: c, right: GroundFrame.X, up: GroundFrame.Y, halfWidth: 0.5 * a.headWidth * r,
                                  halfDorsal: kH * a.headHeight * 0.55 * r, halfVentral: kH * a.headHeight * 0.45 * r, exponent: 2.2))
        }
        if p.palette.muzzle != nil {
            // Skull in the face coat, snout in the muzzle coat from the cheek forward.
            let cut = 5
            rig.add(Loft.build(Array(hs[0...cut]), segments: 18, vRange: 0...0.62, material: f.mat(.head)), to: GroundJoint.headPitch.name)
            rig.add(Loft.build(Array(hs[cut...]), segments: 18, vRange: 0.62...1, material: f.mat(.muzzle)), to: GroundJoint.headPitch.name)
        } else {
            rig.add(Loft.build(hs, segments: 18, material: f.mat(.head)), to: GroundJoint.headPitch.name)
        }
        // Lower jaw.
        let jawK: Float = a.headShape == nil ? 1 : 1.5
        let shaped = a.headShape != nil
        let jawC = small ? V3(0, 0.1 * a.headHeight, 0.1 * hl) : V3(0, 0, 0)
        let jawS: Float = small ? 0.7 : 1
        let jawLoft = Loft.ellipsoid(center: jawC + (shaped ? gape + V3(0, 0, -0.14 * hl) : gape + V3(0.0, 0.0, -0.18 * hl * jawK)), axis: V3(0, 0, -1), up: GroundFrame.Y,
                                     radii: V3(0.2 * a.headWidth * (shaped ? 0.62 : 1), 0.07 * a.headHeight, (shaped ? 0.2 : 0.26 * jawK) * hl) * jawS, rings: 6, segments: 10, material: f.mat(p.palette.muzzle != nil ? .muzzle : .head), uv: { u, v in V2((small ? 0.32 : 0.5) + 0.1 * cos(u * 2 * .pi), 0.8) })
        rig.add(jawLoft, to: GroundJoint.jaw.name)
        // Nose, eyes, lids.
        let nr = a.noseSize * a.headWidth
        let disc = a.snoutDisc
        rig.add(Prim.cubeSphere(subdivisions: 3, material: f.mat(.nose)) { disc ? V3($0.x * nr, $0.y * nr * 0.8, $0.z * nr * 0.4) : $0 * nr },
                Xform(translation: noseTip + V3(0, 0, disc ? -0.002 : 0.004)), to: GroundJoint.headPitch.name)
        for s in Side.allCases {
            var c = eyeAt(s)
            if small {
                // Seat the eye in a socket: sunk into the skull, flattened, ringed by a dark lid rim.
                let R = a.eyeRadius
                c -= V3(s.sign * R * 0.6, 0, 0)
                let face = simd_quatf(angle: -s.sign * .pi / 2, axis: GroundFrame.Z)
                var rim: [V2] = []
                for k in 0...6 { let al = radians(58 + 40 * Float(k) / 6); rim.append(V2(R * 1.12 * sin(al), R * 1.12 * cos(al) * 0.92)) }
                rig.add(Prim.lathe(rim, segments: 18, seamTile: 0.02, material: f.mat(.lid)), Xform(translation: c, rotation: face), to: GroundJoint.headPitch.name)
                rig.add(Prim.cubeSphere(subdivisions: 3, material: f.mat(.eye)) { V3($0.x * R * 0.8, $0.y * R * 0.92, $0.z * R * 1.05) }, Xform(translation: c), to: GroundJoint.headPitch.name)
                if p.species == .easternGraySquirrel {
                    // White eye ring outside the dark rim.
                    var ring: [V2] = []
                    for k in 0...5 { let al = radians(62 + 34 * Float(k) / 5); ring.append(V2(R * 1.32 * sin(al), R * 1.32 * cos(al) * 0.9)) }
                    rig.add(Prim.lathe(ring, segments: 18, seamTile: 0.02, material: f.mat(.whisker)), Xform(translation: c + V3(s.sign * R * 0.05, 0, 0), rotation: face), to: GroundJoint.headPitch.name)
                }
                if p.species == .fennecFox {
                    // Dark tear line from the inner eye corner down toward the muzzle.
                    let e0 = c + V3(s.sign * R * 0.35, -R * 0.4, -R * 0.75)
                    let pts = [e0, e0 + V3(s.sign * 0.002, -0.006, -0.008), e0 + V3(s.sign * 0.001, -0.012, -0.018)]
                    rig.add(Prim.tube(pts, radii: [R * 0.18, R * 0.14, R * 0.05], sides: 4, seamTile: 0.01, material: f.mat(.lid)), to: GroundJoint.headPitch.name)
                }
            }
            if plan == nil && !small { rig.add(Prim.cubeSphere(subdivisions: 3, material: f.mat(.eye)) { $0 * a.eyeRadius }, Xform(translation: c), to: GroundJoint.headPitch.name) }
            let face = simd_quatf(angle: -s.sign * .pi / 2, axis: GroundFrame.Z)
            var prof: [V2] = []
            let R = a.eyeRadius * 1.2
            for k in 0...5 { let al = Float(k) / 5 * radians(78); prof.append(V2(R * sin(al), R * cos(al))) }
            rig.add(Prim.lathe(prof, segments: 14, seamTile: 0.02, material: f.mat(.head)), Xform(translation: c, rotation: face),
                    to: s == .left ? GroundJoint.lidL.name : GroundJoint.lidR.name)
        }
        // Ears: flattened shells, inner skin and outer fur.
        for s in Side.allCases where small {
            let drop = a.earDrop
            let base = earBase(s) + V3(s.sign * 0.12 * a.headWidth, -0.2 * a.headHeight, 0.05 * a.headLength) * drop
            let dir = simd_normalize(lerp(V3(s.sign * a.earTilt, 1, 0.12), V3(s.sign * 0.3, -0.9, 0.18), drop))
            let fwd = lerp(V3(s.sign * 0.3, 0.05, -1), V3(-s.sign, 0, -0.15), drop)
            let normal = simd_normalize(fwd - dir * simd_dot(fwd, dir))
            let side = simd_normalize(simd_cross(normal, dir))
            let part = s == .left ? GroundJoint.earL.name : GroundJoint.earR.name
            for srf in QuadrupedBody.ear(base: base - dir * 0.004, dir: dir, side: side, normal: normal, len: a.earLength, width: a.earWidth,
                                         outer: f.mat(.ear), inner: f.mat(.pinna)) { rig.add(srf, to: part) }
            if p.species == .easternGraySquirrel {
                // Rounded ear rim with short fur tufts at the tip.
                for k in 0..<6 {
                    let tip = base + dir * (a.earLength * 0.92) + side * (a.earWidth * 0.12 * (Float(k) - 2.5))
                    let L = a.earLength * 0.16
                    rig.add(Prim.tube([tip, tip + dir * (0.5 * L) - normal * 0.001, tip + dir * L + side * (0.1 * L * (Float(k) - 2.5))], radii: [0.0011, 0.0007, 0.0001], sides: 3, seamTile: 0.02, material: f.mat(.head)), to: part)
                }
            }
            // Fine pale hair fringing the inner ear.
            for k in 0..<9 {
                let sb = 0.06 + 0.07 * Float(k), sa = (Float(k % 3) - 1) * 0.35
                let p0 = base + dir * (a.earLength * sb) + side * (a.earWidth * 0.32 * sa) + normal * 0.0015
                let L = a.earLength * 0.22
                rig.add(Prim.tube([p0, p0 + dir * (0.5 * L) + normal * (0.25 * L), p0 + dir * L + normal * (0.35 * L)], radii: [0.0007, 0.0005, 0.0001], sides: 3, seamTile: 0.02, material: f.mat(.whisker)), to: part)
            }
        }
        for s in Side.allCases where plan == nil && !small {
            let base = earBase(s)
            let erect = simd_normalize(V3(s.sign * (p.species == .easternCottontail ? 0.18 : a.earTilt), 1, p.species == .easternCottontail ? 0.25 : 0.1))
            let hang = simd_normalize(V3(s.sign * 0.4, -0.9, 0.12))
            let dir = a.earDrop > 0 ? simd_normalize(lerp(erect, hang, a.earDrop)) : erect
            let len = a.earLength
            let center = base + dir * (len * 0.45) + V3(s.sign * 0.12 * a.headWidth, -0.16 * a.headHeight, 0) * a.earDrop
            let thick: Float = a.earDrop > 0 ? 0.0042 : 0.0022
            let side = simd_normalize(simd_cross(dir, a.headShape == nil ? V3(0, 0, 1) : V3(1, 0, 0)))
            let normal = simd_normalize(simd_cross(side, dir))
            let outer = Loft.ellipsoid(center: center - normal * 0.0008, axis: dir, up: normal, radii: V3(a.earWidth * 0.5, thick, len * 0.5), rings: 7, segments: 10, material: f.mat(.head),
                                       uv: { u, v in V2(0.22 + 0.1 * cos(u * 2 * .pi), 0.5 + 0.1 * v) })
            let inner = Loft.ellipsoid(center: center + normal * 0.0012, axis: dir, up: normal, radii: V3(a.earWidth * 0.42, thick * 0.7, len * 0.44), rings: 7, segments: 10, material: f.mat(.ear))
            let part = s == .left ? GroundJoint.earL.name : GroundJoint.earR.name
            rig.add(outer, to: part); rig.add(inner, to: part)
        }
        // Whiskers.
        if a.whiskers {
            let r = 0.0004 + a.headLength * 0.003
            for s in Side.allCases { for k in 0..<4 {
                let y = (Float(k) - 1.5) * 0.004 * a.headHeight / 0.05
                let start = noseTip + V3(s.sign * 0.1 * a.headWidth, 0.1 * a.headHeight * 0.3 + y, 0.2 * hl)
                let len = a.headLength * (0.8 - 0.08 * Float(k))
                let ang = radians(25 + 12 * Float(k))
                let d = V3(s.sign * sin(ang), 0.1 - 0.1 * Float(k), cos(ang) * 0.5 + 0.35)
                let dn = simd_normalize(d)
                let pts = [start, start + dn * (len * 0.5) + V3(0, 0.002, 0), start + dn * len + V3(0, -0.004, 0.004)]
                rig.add(Prim.tube(pts, radii: [r, r * 0.7, r * 0.3], sides: 3, seamTile: 0.02, material: f.mat(.whisker)), to: GroundJoint.headPitch.name)
            }}
        }

        // Tail segments.
        func tailMaterial() -> MaterialKey { f.mat(.tail) }
        let tw = a.tailWidth
        for i in 0..<3 {
            let p0 = tailPoint(i), p1 = tailPoint(i + 1)
            let t0 = Float(i) / 3, t1 = Float(i + 1) / 3
            let wTail: (Float) -> Float = { t in
                switch p.species {
                case .easternGraySquirrel: return tw * 0.5 * (0.8 + 0.4 * sin(.pi * min(1, t * 1.15)) - 0.15 * t)
                case .easternChipmunk: return tw * 0.5 * (0.8 - 0.4 * t)
                case .easternCottontail: return tw * 0.5 * sin(.pi * max(0.15, 1 - t * 0.8) * 0.9)
                case .goldenRetriever, .germanShepherd: return tw * 0.5 * (1 - 0.8 * pow(t, 1.4))
                case .coyote: return tw * 0.5 * (0.55 + 0.45 * sin(.pi * min(1, t * 1.25)))
                case .whitetailDeer: return tw * 0.5 * (0.7 + 0.3 * sin(.pi * min(1, t * 1.2)))
                default: return tw * 0.5 * (1 - 0.5 * t)
                }
            }
            let fluffy = (small && a.tailLength > 0.6 * a.bodyLength) || plan?.tailBrush == true
            let coreK: Float = fluffy && plan?.dog != true ? 0.62 : 1
            let pm = lerp(p0, p1, 0.5) + V3(0, curl * tailSeg * 0.07, 0)
            let seg = Loft.along([p0 - (p1 - p0) * 0.1, pm, p1 + (p1 - p0) * 0.06], up: GroundFrame.Y, count: 5, segments: 14, vRange: t0...t1, exponent: 2, material: tailMaterial()) { t in
                let r = wTail(lerp(t0, t1, t)) * coreK; return V3(r, r * (p.species == .easternGraySquirrel ? 0.8 : 1), r * (p.species == .easternGraySquirrel ? 0.8 : 1))
            }
            let partName = [GroundJoint.tail0, .tail1, .tail2][i].name
            rig.add(seg, to: partName)
            if fluffy && !small {
                // Volumetric brush: tapered fur cards fanning out from the tail bone, leaning toward the tip.
                var rng = SplitMix(seed: 31 + UInt64(i))
                let ax = simd_normalize(p1 - p0)
                let rt = simd_normalize(simd_cross(ax, GroundFrame.X)), sd = GroundFrame.X
                for _ in 0..<150 {
                    let tt = rng.next01()
                    let w = wTail(lerp(t0, t1, tt))
                    let ang = rng.next01() * 2 * .pi
                    let radial = sd * cos(ang) * 1.15 + rt * sin(ang) * 0.85
                    let b = lerp(p0, p1, tt) + radial * (w * 0.18 * rng.next01())
                    let L = w * (0.55 + 0.35 * rng.next01())
                    let d = simd_normalize(radial + ax * 0.9)
                    // Flat card, two-sided, normals bent outward from the tail axis; u runs coat to pale tip.
                    let across = simd_normalize(simd_cross(d, radial)) * (w * 0.34)
                    var card = Surface(material: tailMaterial())
                    let n = simd_normalize(radial * 0.8 + d * 0.2)
                    for side in [Float(1), -1] {
                        let o = UInt32(card.vertexCount)
                        for r in 0..<3 {
                            let q = Float(r) / 2, wq = 1 - 0.8 * q
                            let c = b + d * (L * q) + radial * (0.1 * L * q * q)
                            _ = card.add(c - across * wq, n, V2(0.04 + 0.17 * q, 0.5))
                            _ = card.add(c + across * wq, n, V2(0.05 + 0.17 * q, 0.5))
                        }
                        for r in 0..<2 {
                            let a0 = o + UInt32(r * 2)
                            if side > 0 { card.quad(a0, a0 + 1, a0 + 3, a0 + 2) } else { card.quad(a0, a0 + 2, a0 + 3, a0 + 1) }
                        }
                    }
                    card.computeTangents()
                    rig.add(card, to: partName)
                }
            }
        }
        if p.species == .easternCottontail {
            // Pom-pom: replace segmented tail look with a ball.
            rig.add(Prim.cubeSphere(subdivisions: 4, material: tailMaterial()) { $0 * (a.tailWidth * 0.5) }, Xform(translation: f.rump + V3(0, 0.01, 0.02)), to: GroundJoint.tail0.name)
        }

        // Legs.
        let legU = small ? 0.22 : max(0.1, p.palette.flankLine * 0.5 * 0.6)
        for l in GroundJoint.Leg.allCases where plan == nil {
            let c = chains[l]!
            let r = a.legRadius * (small ? 1.3 : 1)
            let thighR = (l.isFore ? r * 1.4 : r * 2.0) * a.thighScale * (small ? 1.35 : 1)
            let kneeR: Float = a.digitigrade ? r * (l.isFore ? 1.3 : max(1.1, a.thighScale)) : r * 1.05
            let shankEnd: Float = a.digitigrade ? r * (l.isFore ? 0.85 : 1.0) : r * 0.8
            func leg(_ pts: [V3], _ radii: [Float], vr: ClosedRange<Float>) -> Surface {
                Loft.along(pts, up: GroundFrame.X, count: small ? 8 : 6, segments: small ? 16 : 12, vRange: vr, exponent: 2, material: limbFur, radius: { t in
                    // Small mammals: smooth taper with a calf swell, slightly deeper than wide.
                    let k = small ? t * t * (3 - 2 * t) : t
                    let r = lerp(radii[0], radii[1], k) * (small ? 1 + 0.12 * sin(.pi * t) : 1); return small ? V3(r * 0.9, r * 1.08, r * 1.08) : V3(r, r, r)
                }, uv: { u, v in V2(legU + 0.05 * cos(u * 2 * .pi), 0.3 + 0.3 * v) })
            }
            rig.add(Loft.along([c.hip + (small ? f.U * ((l.isFore ? 0.3 : 0.12) * a.bodyDepth) - V3(c.hip.x * 0.55, 0, 0) : V3(0, 0.004, 0)), c.knee], up: GroundFrame.X, count: small ? 8 : 6, segments: small ? 16 : 12, vRange: 0...0.5, exponent: 2, material: small ? limbFur : fur, radius: { t in let k = small ? 1 - pow(1 - t, 2) : t; let r = lerp(thighR * (small ? 1.15 : 1), kneeR, k); return V3(r, r, r) }, uv: { u, v in V2(legU + 0.05 * cos(u * 2 * .pi), 0.3 + 0.3 * v) }), to: GroundJoint.leg(l, .hip).name)
            rig.add(leg([c.knee, c.ankle], [kneeR, shankEnd], vr: 0.5...1), to: GroundJoint.leg(l, .knee).name)
            rig.add(leg([c.ankle, c.toe], [r * 0.85, r * 0.9], vr: 0.5...1), to: GroundJoint.leg(l, .ankle).name)
            let ankle = GroundJoint.leg(l, .ankle).name
            if a.digitigrade || a.thighScale > 1.3 {
                // Shoulder and haunch muscle mass hanging from the hip joint.
                let up = c.knee - c.hip, len = simd_length(up)
                let mid = small ? lerp(c.hip, c.knee, 0.1) + f.U * (0.16 * a.bodyDepth) - V3(l.side.sign * thighR * 0.45, 0, 0) : lerp(c.hip, c.knee, l.isFore ? 0.3 : 0.4)
                let wx = thighR * (l.isFore ? 0.8 : 0.95), wz = thighR * (l.isFore ? 1.05 : 1.3)
                // Texture scale follows the body: u spans the body circumference, v its length.
                let circ = Float.pi * (a.bodyWidth + a.bodyDepth) * 0.5, span = 2 * len * 0.66 / a.bodyLength
                rig.add(Loft.ellipsoid(center: mid + V3(l.side.sign * 0.004, 0, 0), axis: up, up: GroundFrame.X, radii: small ? V3(wz * 1.05, wx * 0.85, len * 0.46) : V3(wz, wx, len * 0.66), rings: 9, segments: 16, material: fur,
                                       uv: { u, v in V2(0.16 + 0.5 * (wz + wx) * cos(u * 2 * .pi) / circ, 0.25 + span * (v - 0.5)) }), to: GroundJoint.leg(l, .hip).name)
            }
            if a.hooves {
                for sx in [Float(-1), 1] {
                    let hc = c.toe + V3(sx * r * 0.62, r * 1.05, -r * 0.55)
                    rig.add(Loft.ellipsoid(center: hc, axis: V3(0, -0.5, -1), up: GroundFrame.Y, radii: V3(r * 0.62, r * 1.2, r * 1.75), rings: 6, segments: 10, material: f.mat(.hoof)), to: ankle)
                }
            } else {
                // Paw and claws.
                let pc = a.digitigrade ? c.toe + V3(0, r * 0.35, -r * 0.8) : c.toe + V3(0, 0, 0.004)
                rig.add(Loft.ellipsoid(center: pc, axis: V3(0, 0, -1), up: GroundFrame.Y, radii: V3(r * 1.1, r * 0.7, r * 1.7), rings: 5, segments: 8, material: limbFur,
                                       uv: { u, v in V2(legU + 0.04 * cos(u * 2 * .pi), 0.45) }), to: ankle)
                let n = a.clawScale > 2 ? 4 : 3
                if small {
                    // Rounded toes fanned at the front of the paw.
                    for k in 0..<4 {
                        let off = (Float(k) - 1.5) * r * 0.62
                        let tc = pc + V3(off, -r * 0.15, -r * (1.45 - 0.12 * abs(Float(k) - 1.5)))
                        rig.add(Loft.ellipsoid(center: tc, axis: V3(off * 8, 0, -1), up: GroundFrame.Y, radii: V3(r * 0.3, r * 0.26, r * 0.5), rings: 5, segments: 8, material: limbFur,
                                               uv: { u, v in V2(legU + 0.03 * cos(u * 2 * .pi), 0.45) }), to: ankle)
                    }
                }
                for k in 0..<n {
                    let off = (Float(k) - Float(n - 1) / 2) * r * 0.7
                    let cl = pc + V3(off, -r * 0.3, -r * 1.4)
                    rig.add(Prim.tube([cl, cl + V3(0, -0.0006 * a.clawScale, -r * 1.6 * a.clawScale)], radii: [r * (small ? 0.1 : 0.22) * a.clawScale.squareRoot(), r * 0.02], sides: small ? 5 : 4, seamTile: 0.01, material: f.mat(.claw)), to: ankle)
                }
            }
        }

        if let plan {
            var cm: [GroundJoint.Leg: QuadrupedBody.Chain] = [:]
            for (k, c) in chains { cm[k] = (c.hip, c.knee, c.ankle, c.toe) }
            QuadrupedBody.build(&rig, f, plan, chains: cm, earBase: earBase, noseTip: noseTip)
        }
        if a.antlers != .none { addAntlers(&rig, f) }
        if a.tusks > 0 {
            let gp = f.headCenter + V3(0, -0.28 * a.headHeight, -0.15 * a.headLength)
            for s in Side.allCases {
                let b = gp + V3(s.sign * 0.34 * a.headWidth, 0.004, -0.3 * a.headLength), L = a.tusks
                let pts = [b, b + V3(s.sign * 0.004, 0.3 * L, -0.12 * L), b + V3(s.sign * 0.012, 0.65 * L, -0.1 * L), b + V3(s.sign * 0.018, 0.95 * L, 0.04 * L)]
                rig.add(Prim.tube(pts, radii: [0.0075, 0.0068, 0.005, 0.0012], sides: 6, seamTile: 0.03, material: f.mat(.antler)), to: GroundJoint.jaw.name)
            }
        }

        rig.states = [RigState("stand", GroundPoses.stand(p).named), RigState("sit", GroundPoses.sit(p).named)]
        rig.defaultState = "stand"
        return GroundRig(profile: p, rig: rig, joints: specs.map { $0! }, comHeight: a.standHeight, skinned: small || plan?.dog == true)
    }
}

extension GroundPose {
    var named: [String: Float] {
        var d: [String: Float] = [:]
        for j in GroundJoint.all { d[j.name] = values[j.index] }
        return d
    }
}
