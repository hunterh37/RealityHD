import simd
import Foundation

/// Cheap geometry for roofline props: flat decals and unbeveled thin plates (10 triangles, no underside).
enum RK {
    /// Thin plate, top face and four skirts, planar UVs in meters. Use for stains, slots and patches.
    static func plate(_ m: inout Model, _ size: V3, _ c: V3, _ mat: MaterialKey, rot: simd_quatf = .identity) {
        var s = Surface(material: mat)
        let h = size / 2
        func face(_ pts: [V3], _ n: V3, _ ua: V3, _ va: V3) {
            let ids = pts.map { s.add($0, n, V2(simd_dot($0, ua), simd_dot($0, va))) }
            s.quad(ids[0], ids[1], ids[2], ids[3])
        }
        face([V3(-h.x, h.y, h.z), V3(h.x, h.y, h.z), V3(h.x, h.y, -h.z), V3(-h.x, h.y, -h.z)], V3(0, 1, 0), V3(1, 0, 0), V3(0, 0, 1))
        face([V3(-h.x, -h.y, h.z), V3(h.x, -h.y, h.z), V3(h.x, h.y, h.z), V3(-h.x, h.y, h.z)], V3(0, 0, 1), V3(1, 0, 0), V3(0, 1, 0))
        face([V3(h.x, -h.y, -h.z), V3(-h.x, -h.y, -h.z), V3(-h.x, h.y, -h.z), V3(h.x, h.y, -h.z)], V3(0, 0, -1), V3(1, 0, 0), V3(0, 1, 0))
        face([V3(h.x, -h.y, h.z), V3(h.x, -h.y, -h.z), V3(h.x, h.y, -h.z), V3(h.x, h.y, h.z)], V3(1, 0, 0), V3(0, 0, 1), V3(0, 1, 0))
        face([V3(-h.x, -h.y, -h.z), V3(-h.x, -h.y, h.z), V3(-h.x, h.y, h.z), V3(-h.x, h.y, -h.z)], V3(-1, 0, 0), V3(0, 0, 1), V3(0, 1, 0))
        s.computeTangents()
        m.add(s, Xform(translation: c, rotation: rot))
    }
}
