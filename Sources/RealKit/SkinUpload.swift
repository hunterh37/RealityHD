import Foundation
import RealityKit
import CoreGraphics
import RealCore

public extension Skin {
    /// Skinned ModelEntity: one part per surface, four influences per vertex, skeleton from the rig joints.
    /// Pose it through `ModelEntity.jointTransforms` (local to the parent joint, same order as `jointNames`).
    @MainActor
    func modelEntityAsync(name: String, materials: RealMaterialCache? = nil) async throws -> ModelEntity {
        let cache = materials ?? .shared
        let restT = restLocal.map { Transform(scale: $0.scale, rotation: $0.rotation, translation: $0.translation) }
        guard let skel = MeshResource.Skeleton(id: "skel", jointNames: jointNames, inverseBindPoseMatrices: inverseBind,
                                               restPoseTransforms: restT, parentIndices: parents.map { $0 < 0 ? nil : $0 }) else {
            throw CocoaError(.featureUnsupported)
        }
        var keys: [MaterialKey] = [], parts: [MeshResource.Part] = []
        for (i, var s) in surfaces.enumerated() {
            s.finalize()
            let mi: Int
            if let k = keys.firstIndex(of: s.material) { mi = k } else { keys.append(s.material); mi = keys.count - 1 }
            var p = MeshResource.Part(id: "p\(i)", materialIndex: mi)
            p.positions = MeshBuffers.Positions(s.positions)
            p.normals = MeshBuffers.Normals(s.normals)
            p.tangents = MeshBuffers.Tangents(s.tangents.map { SIMD3($0.x, $0.y, $0.z) })
            p.textureCoordinates = MeshBuffers.TextureCoordinates(s.uvs)
            p.triangleIndices = MeshBuffer(s.indices)
            p.skeletonID = "skel"
            // uv1 = (wind weight, baked AO) as in PackedMesh; ShaderGraph reads it as texcoord 1.
            let uv1 = (0..<s.vertexCount).map { SIMD2(s.extra[$0].x, s.occlusion[$0]) }
            p[MeshBuffers.custom("uv1", type: SIMD2<Float>.self)] = MeshBuffer(uv1)
            var inf: [MeshJointInfluence] = []
            inf.reserveCapacity(s.vertexCount * 4)
            for v in influences[i] { for k in 0..<4 { inf.append(MeshJointInfluence(jointIndex: Int(v.joints[k]), weight: v.weights[k])) } }
            p.jointInfluences = MeshResource.JointInfluences(influences: MeshBuffer(inf), influencesPerVertex: 4)
            parts.append(p)
        }
        var contents = MeshResource.Contents()
        contents.skeletons = MeshSkeletonCollection([skel])
        contents.models = MeshModelCollection([MeshResource.Model(id: "m", parts: parts)])
        contents.instances = MeshInstanceCollection([MeshResource.Instance(id: "i", model: "m")])
        let mesh = try await MeshResource(from: contents)
        var mats: [any RealityKit.Material] = []
        for k in keys {
            var m = await cache.materialAsync(k)
            // Skinned parts cannot carry texcoord 1, so the graph reads baked AO as 0 (albedo x 0.6).
            // Lift Tint to cancel it; surfaces here have no baked AO.
            if var g = m as? ShaderGraphMaterial, case .color(let c)? = g.getParameter(name: "Tint"), let cc = c.components {
                let k: CGFloat = 1 / 0.6
                let lifted = CGColor(colorSpace: c.colorSpace ?? CGColorSpace(name: CGColorSpace.extendedLinearSRGB)!,
                                     components: [cc[0] * k, cc[1] * k, cc[2] * k, cc.count > 3 ? cc[3] : 1])!
                try? g.setParameter(name: "Tint", value: .color(lifted)); m = g
            }
            mats.append(m)
        }
        let e = ModelEntity(mesh: mesh, materials: mats)
        e.name = name
        return e
    }
}
