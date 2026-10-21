import Foundation
import simd

/// Up to four joint influences for one vertex. Joint 0 is the rig root (base geometry).
public struct SkinInfluence: Sendable, Equatable {
    public var joints: SIMD4<UInt16>
    public var weights: SIMD4<Float>
}

/// One continuous skinned mesh baked from a rig: skeleton joint 0 is the root, joint i + 1 is part i.
/// Rest transforms are local to the parent joint; `inverseBind` maps asset space into each joint frame.
public struct Skin: Sendable {
    public var jointNames: [String]
    public var parents: [Int]
    public var restLocal: [Xform]
    public var inverseBind: [simd_float4x4]
    public var surfaces: [Surface]
    public var influences: [[SkinInfluence]]
    public var triangleCount: Int { surfaces.reduce(0) { $0 + $1.triangleCount } }
}

public extension Rig {
    /// Bakes LOD 0 of the base and every part into one skinned mesh. Surfaces whose material passes `blend`
    /// get weights from their own joint, its parent and its children by inverse distance to each bone
    /// segment (smooth falloff across the bend); every other surface stays rigid on its own joint.
    func skin(blend: (MaterialKey) -> Bool) -> Skin {
        let n = parts.count + 1
        var parents = [Int](repeating: -1, count: n), names = [String](repeating: "root", count: n)
        var rest = [Xform](repeating: .identity, count: n), inv = [simd_float4x4](repeating: matrix_identity_float4x4, count: n)
        var children = [[Int]](repeating: [], count: n), pivot = [V3](repeating: .zero, count: n)
        for (i, p) in parts.enumerated() {
            let j = i + 1
            parents[j] = p.parent.flatMap(index).map { $0 + 1 } ?? 0
            names[j] = names[parents[j]] + "/" + p.name
            rest[j] = localJointTransform(i, value: 0)
            inv[j] = p.pivot.matrix.inverse
            pivot[j] = p.pivot.translation
            children[parents[j]].append(j)
        }
        // Bone segments: pivot to the mean child pivot; leaves extend half their parent bone; the root spans its children.
        var seg = [(V3, V3)](repeating: (.zero, .zero), count: n)
        for j in 0..<n {
            let kids = children[j].map { pivot[$0] }
            if j == 0 {
                let zs = kids.sorted { $0.z < $1.z }
                seg[j] = (zs.first ?? .zero, zs.last ?? .zero)
            } else if !kids.isEmpty {
                seg[j] = (pivot[j], kids.reduce(.zero, +) / Float(kids.count))
            } else {
                seg[j] = (pivot[j], pivot[j] + (pivot[j] - pivot[parents[j]]) * 0.5)
            }
        }
        func dist(_ p: V3, _ s: (V3, V3)) -> Float {
            let ab = s.1 - s.0, l2 = simd_length_squared(ab)
            let t = l2 < 1e-10 ? 0 : min(1, max(0, simd_dot(p - s.0, ab) / l2))
            return simd_length(p - (s.0 + ab * t))
        }
        var surfaces: [Surface] = [], infl: [[SkinInfluence]] = []
        func bake(_ m: Model, _ own: Int) {
            for s in m.surfaces where !s.isEmpty {
                let cands = [own] + (own == 0 ? [] : [parents[own]]) + children[own]
                let soft = blend(s.material)
                var out: [SkinInfluence] = []
                out.reserveCapacity(s.vertexCount)
                for p in s.positions {
                    if !soft { out.append(SkinInfluence(joints: SIMD4(UInt16(own), 0, 0, 0), weights: SIMD4(1, 0, 0, 0))); continue }
                    var ws = cands.map { c -> (Int, Float) in
                        let d = max(1e-3, dist(p, seg[c]))
                        return (c, (c == own ? 2 : 1) / pow(d, 4))
                    }
                    ws.sort { $0.1 > $1.1 }
                    ws = Array(ws.prefix(4))
                    let sum = ws.reduce(0) { $0 + $1.1 }
                    var J = SIMD4<UInt16>(repeating: 0), W = SIMD4<Float>(repeating: 0)
                    for (k, w) in ws.enumerated() { J[k] = UInt16(w.0); W[k] = w.1 / sum }
                    out.append(SkinInfluence(joints: J, weights: W))
                }
                surfaces.append(s); infl.append(out)
            }
        }
        bake(base[0], 0)
        for (i, p) in parts.enumerated() { bake(p.levels[0], i + 1) }
        return Skin(jointNames: names, parents: parents, restLocal: rest, inverseBind: inv, surfaces: surfaces, influences: infl)
    }
}
