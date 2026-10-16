import Foundation
import simd
import RealCore

extension GroundRigBuilder {
    /// One antler: main beam plus tines, authored for the animal's right side in head space
    /// (x outward, y up, z back) and mirrored for the left.
    struct Antler {
        var beam: [V3]
        var beamRadius: (Float, Float)
        /// (position along the beam 0...1, direction, length, base radius)
        var tines: [(Float, V3, Float, Float)]
    }

    static func antler(_ style: AntlerStyle) -> Antler {
        switch style {
        case .whitetail:
            return Antler(
                beam: [V3(0, 0, 0), V3(0.025, 0.09, 0.035), V3(0.06, 0.19, 0.07), V3(0.085, 0.29, 0.06), V3(0.08, 0.37, -0.03), V3(0.055, 0.42, -0.15), V3(0.035, 0.435, -0.27)],
                beamRadius: (0.022, 0.0045),
                tines: [(0.13, V3(-0.15, 0.7, -0.7), 0.11, 0.011), (0.42, V3(0.05, 1, -0.12), 0.17, 0.011), (0.62, V3(0.0, 1, 0.0), 0.15, 0.0095), (0.80, V3(0.0, 1, -0.2), 0.085, 0.0075)])
        case .elk:
            return Antler(
                beam: [V3(0, 0, 0), V3(0.04, 0.11, 0.05), V3(0.10, 0.25, 0.12), V3(0.14, 0.39, 0.26), V3(0.14, 0.51, 0.48), V3(0.12, 0.59, 0.74), V3(0.10, 0.63, 0.97), V3(0.08, 0.60, 1.14)],
                beamRadius: (0.042, 0.011),
                tines: [(0.08, V3(0, 0.45, -0.9), 0.34, 0.024), (0.19, V3(0.05, 0.55, -0.82), 0.36, 0.022), (0.36, V3(0.05, 0.9, -0.42), 0.3, 0.019), (0.55, V3(0, 1, -0.2), 0.25, 0.016),
                        (0.97, V3(0.1, 1, 0.05), 0.2, 0.011), (0.97, V3(-0.05, 0.75, -0.7), 0.16, 0.011)])
        case .none:
            return Antler(beam: [V3.zero, V3(0, 0.01, 0)], beamRadius: (0.001, 0.001), tines: [])
        }
    }

    /// Antlers on the skull behind the eyes. They ride the head joint.
    static func addAntlers(_ rig: inout Rig, _ f: GroundFrame) {
        let a = f.a, ant = antler(a.antlers)
        let part = GroundJoint.headPitch.name
        let mat = f.mat(.antler)
        let root = f.headCenter + V3(0, 0.34 * a.headHeight, 0.16 * a.headLength)
        for s in Side.allCases {
            func world(_ p: V3) -> V3 { root + V3(s.sign * (0.26 * a.headWidth + p.x), p.y, p.z) }
            let dense = Loft.resample(ant.beam.map(world), count: 60)
            let n = 16
            let beamPts = Loft.resample(ant.beam.map(world), count: n)
            let radii = (0..<n).map { i -> Float in
                let t = Float(i) / Float(n - 1)
                return lerp(ant.beamRadius.0, ant.beamRadius.1, pow(t, 0.8)) * (i == 0 ? 1.18 : 1)
            }
            rig.add(Prim.tube(beamPts, radii: radii, sides: 7, seamTile: 0.04, material: mat), to: part)
            for (t, d, len, r0) in ant.tines {
                let base = dense[min(dense.count - 1, Int(t * Float(dense.count - 1)))]
                let dir = simd_normalize(V3(s.sign * d.x, d.y, d.z))
                let pts = [base - dir * 0.004, base + dir * (len * 0.45) + V3(0, 0, -len * 0.04), base + dir * (len * 0.8) + V3(0, 0, -len * 0.08), base + dir * len + V3(0, 0, -len * 0.1)]
                rig.add(Prim.tube(pts, radii: [r0, r0 * 0.8, r0 * 0.5, r0 * 0.12], sides: 5, seamTile: 0.04, material: mat), to: part)
            }
            // Burr: the ridged base where the antler meets the skull.
            let b = world(ant.beam[0])
            rig.add(Loft.ellipsoid(center: b + V3(0, 0.004, 0), axis: V3(0, 1, 0), up: V3(0, 0, 1), radii: V3(ant.beamRadius.0 * 1.5, ant.beamRadius.0 * 1.5, 0.014), rings: 5, segments: 10, material: mat), to: part)
        }
    }
}
