import simd
import RealityKit
import RealCore

/// Precomputed room visibility for interiors. A cell is an axis-aligned room volume (scene space); a
/// portal is a doorway or glazed opening joining two cells. Walls are opaque, so from inside a cell only
/// cells reached through portals inside the head view can be seen.
public struct RealCellGraph: Sendable, Equatable {
    public struct Cell: Sendable, Equatable {
        public var name: String
        public var min: V3, max: V3
        public init(_ name: String, min: V3, max: V3) { self.name = name; self.min = min; self.max = max }
        public func contains(_ p: V3) -> Bool { all(p .>= min) && all(p .<= max) }
    }
    public struct Portal: Sendable, Equatable {
        /// Cell indices on either side.
        public var a: Int, b: Int
        /// Opening center and half-diagonal (scene space).
        public var center: V3, radius: Float
        public init(_ a: Int, _ b: Int, center: V3, width: Float, height: Float) {
            self.a = a; self.b = b; self.center = center; radius = simd_length(V2(width, height)) / 2
        }
    }
    public var cells: [Cell]
    public var portals: [Portal]
    /// Portals this close to the eye count as visible whatever the view direction (turning past a doorway).
    public var nearPortal: Float = 1.5
    /// Portal hops followed from the viewer's cell.
    public var depth = 3

    public init(cells: [Cell] = [], portals: [Portal] = []) { self.cells = cells; self.portals = portals }

    public func index(_ name: String) -> Int? { cells.firstIndex { $0.name == name } }

    /// Cell holding `p`, if any (nil in doorways, walls and outside).
    public func cell(at p: V3) -> Int? { cells.firstIndex { $0.contains(p) } }

    /// Cells visible from `eye` looking along `forward` (nil = all: the eye is in no cell).
    public func visible(eye: V3, forward: V3) -> Set<Int>? {
        guard let start = cell(at: eye) else { return nil }
        let view = ViewVolume(eye: eye, forward: forward)
        var seen: Set<Int> = [start]
        var frontier = [start]
        for _ in 0..<depth {
            var next: [Int] = []
            for c in frontier {
                for p in portals where p.a == c || p.b == c {
                    let other = p.a == c ? p.b : p.a
                    guard !seen.contains(other) else { continue }
                    let near = simd_distance(p.center, eye) < nearPortal + p.radius
                    guard near || view.intersects(center: p.center, radius: p.radius) else { continue }
                    seen.insert(other); next.append(other)
                }
            }
            frontier = next
            if frontier.isEmpty { break }
        }
        return seen
    }
}

/// On a scene root: the cell graph in the root's local space and the child entity holding each cell.
public struct RealCellVisibilityComponent: Component {
    public var graph: RealCellGraph
    public var cellRoots: [Entity]
    public var lastVisible: Set<Int>? = []
    public init(graph: RealCellGraph, cellRoots: [Entity]) { self.graph = graph; self.cellRoots = cellRoots }
}

/// Enables only the cells visible from the viewer (`RealViewer` position and forward), every 0.1 s.
public struct RealCellVisibilitySystem: System {
    static let query = EntityQuery(where: .has(RealCellVisibilityComponent.self))
    /// Off: every cell stays enabled (A/B switch).
    nonisolated(unsafe) public static var enabled = true
    private var accumulator: Double = .greatestFiniteMagnitude

    public init(scene: RealityKit.Scene) {}

    public mutating func update(context: SceneUpdateContext) {
        accumulator += context.deltaTime
        guard accumulator >= 0.1 else { return }
        accumulator = 0
        let (eye, fwd) = MainActor.assumeIsolated { RealViewer.refresh(); return (RealViewer.position, RealViewer.forward) }
        for e in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            guard var v = e.components[RealCellVisibilityComponent.self] else { continue }
            let local = e.convert(position: eye, from: nil), dir = e.convert(direction: fwd, from: nil)
            let vis = Self.enabled ? v.graph.visible(eye: local, forward: simd_normalize(dir)) : nil
            guard vis != v.lastVisible else { continue }
            for (i, c) in v.cellRoots.enumerated() { c.isEnabled = vis?.contains(i) ?? true }
            v.lastVisible = vis
            e.components.set(v)
        }
    }
}
