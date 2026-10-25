import simd
import Foundation

/// Shared helpers for details group 17.
enum DetailKit17 {
    /// One small rock as a 2-LOD model with contact shadow.
    static func rock(id: String, shape: RockShape, seed: UInt64, material: MaterialKey, detail: [Int], ao: Float) -> LODModel {
        let levels = shape.surfaces(seed: seed, material: material, detail: detail).map { s -> Model in
            var s = s
            rockContactAO(&s, height: ao)
            s.computeTangents()
            return Model(name: id, surfaces: [s])
        }
        return LODModel(levels: levels, switchDistances: [6])
    }
}
