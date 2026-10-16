import Foundation
import simd
import RealCore

// Skin and feather ornaments of game birds: turkey wattle, snood and beard, pheasant collar and face patch.

extension BirdRigBuilder {
    static func addOrnaments(_ rig: inout Rig, _ f: BirdFrame) {
        let a = f.a
        let head = BirdJoint.headPitch.name
        if a.caruncle > 0 {
            let c = a.caruncle, orn = f.mat(.ornament)
            // Wattle hanging from the chin and throat.
            let chin = f.headCenterAt(0.78) + V3(0, -0.46 * a.headHeight, 0)
            rig.add(Loft.ellipsoid(center: chin + V3(0, -0.5 * c, 0.1 * c), axis: V3(0, -1, 0.18), up: V3(1, 0, 0), radii: V3(0.14 * c, 0.2 * c, 0.62 * c),
                                   rings: 7, segments: 10, material: orn), to: head)
            // Snood draping over the bill base.
            let top = f.headCenterAt(0.97) + V3(0, 0.28 * a.headHeight, 0)
            rig.add(Loft.ellipsoid(center: top + V3(0, -0.28 * c, -0.28 * c), axis: V3(0, -0.8, -0.55), up: V3(1, 0, 0), radii: V3(0.09 * c, 0.16 * c, 0.46 * c),
                                   rings: 6, segments: 8, material: orn), to: head)
        }
        if a.facePatch > 0 {
            let R = a.facePatch, orn = f.mat(.ornament)
            for s in Side.allCases {
                let e = f.eyeCenter(s)
                rig.add(Loft.ellipsoid(center: e + V3(-s.sign * 0.2 * R, -0.1 * R, 0.1 * R), axis: V3(0, 0, -1), up: V3(1, 0, 0), radii: V3(R * 0.85, R * 0.3, R * 1.25),
                                       rings: 7, segments: 12, material: orn), to: head)
            }
        }
        if a.collar > 0 {
            // A ring of white feathers around the lower neck, open at the throat is not drawn: the full ring reads as the collar.
            let pn = f.neckPivot
            let pe = f.headCenter + V3(0, -0.12 * a.headHeight, 0.05 * a.headLength)
            let r0 = 0.5 * a.bodyWidth * a.neckThick, r1 = 0.5 * a.headWidth * 0.92
            let p0 = lerp(pn, pe, 0.28), p1 = lerp(pn, pe, 0.28 + a.collar / max(0.01, simd_distance(pn, pe)))
            let ring = Loft.along([p0, p1], up: V3(0, 1, 0.3), count: 4, segments: 18, vRange: 0.9...1.0, exponent: 2, material: f.mat(.collar)) { t in
                let u = lerp(0.28, 0.5, t)
                let r = lerp(r0, r1, u) * (1.12 - 0.05 * t); return V3(r, r * 0.9, r * 1.25)
            }
            rig.add(ring, to: BirdJoint.neckPitch.name)
        }
        if a.beard > 0 {
            let L = a.beard
            let root = f.bodyFront - f.A * (0.14 * a.bodyLength) - f.U * (0.18 * a.bodyDepth)
            let n = 7
            for k in 0..<n {
                let x = (Float(k) - Float(n - 1) / 2) * 0.0035
                let sway = (Float(k % 3) - 1) * 0.004
                let pts = [root + V3(x, 0, 0), root + V3(x + sway * 0.5, -0.45 * L, -0.03 * L), root + V3(x + sway, -0.8 * L, -0.045 * L), root + V3(x + sway * 1.3, -L * (0.92 + 0.03 * Float(k % 2)), -0.05 * L)]
                rig.base[0].add(Prim.tube(pts, radii: [0.0055, 0.0048, 0.0036, 0.0012], sides: 4, seamTile: 0.02, material: f.mat(.beard)))
            }
        }
    }
}
