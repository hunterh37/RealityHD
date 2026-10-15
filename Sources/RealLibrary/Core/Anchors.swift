import simd
import RealityKit
import RealKit

/// A named mount point in asset space (the rest pose: base at y = 0, centred on X/Z). `direction` is the
/// outward unit normal of the mounting face, so two parts join when one's anchor meets the other's with
/// opposite directions (a rod's `reelFoot` faces +Y, a reel's `reelFoot` faces -Y).
public struct RealAnchor: Sendable, Equatable {
    public var position: SIMD3<Float>
    public var direction: SIMD3<Float>
    public init(_ position: SIMD3<Float>, direction: SIMD3<Float>) { self.position = position; self.direction = simd_normalize(direction) }
}

/// An asset that exposes named anchors so an app can assemble it with other assets at runtime
/// (rod blank + handle + reel seat + reel, line tie on a lure).
public protocol RealAnchored: RealAsset {
    static var anchors: [String: RealAnchor] { get }
}

public extension Catalog {
    /// Assets with named anchors.
    static var anchored: [any RealAnchored.Type] { assets.compactMap { $0 as? any RealAnchored.Type } }
}

public extension RealityHD {
    /// Anchor `name` of asset `id` in asset space, nil when the asset or anchor is unknown.
    static func anchor(_ id: String, _ name: String) -> RealAnchor? {
        (Catalog.type(id) as? any RealAnchored.Type)?.anchors[name]
    }

    /// Transform (in the parent's frame) that puts `childAnchor` of a child entity on `parentAnchor`,
    /// with the anchor directions opposed and `roll` degrees about the joined axis.
    static func mount(_ childAnchor: RealAnchor, on parentAnchor: RealAnchor, roll: Float = 0) -> Transform {
        let from = childAnchor.direction, to = -parentAnchor.direction
        let d = simd_dot(from, to)
        var q: simd_quatf
        if d < -0.9999 {
            let axis = abs(from.x) < 0.9 ? simd_normalize(simd_cross(from, SIMD3(1, 0, 0))) : simd_normalize(simd_cross(from, SIMD3(0, 0, 1)))
            q = simd_quatf(angle: .pi, axis: axis)
        } else {
            q = simd_quatf(from: from, to: to)
        }
        q = simd_quatf(angle: roll * .pi / 180, axis: to) * q
        return Transform(scale: .one, rotation: q, translation: parentAnchor.position - q.act(childAnchor.position))
    }

    /// Adds `child` (asset `childId`) under `parent` (asset `parentId`), joined at the named anchors.
    @MainActor static func attach(_ child: Entity, _ childId: String, at childAnchor: String,
                                  to parent: Entity, _ parentId: String, at parentAnchor: String, roll: Float = 0) throws {
        guard let c = anchor(childId, childAnchor), let p = anchor(parentId, parentAnchor) else { throw RealityHDError.unknown("\(childId).\(childAnchor) or \(parentId).\(parentAnchor)") }
        child.transform = mount(c, on: p, roll: roll)
        parent.addChild(child)
    }
}
