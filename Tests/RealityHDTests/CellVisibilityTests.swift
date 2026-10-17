import Testing
import simd
import RealityKit
@testable import RealKit
@testable import RealLibrary
import RealCore

@Suite struct CellVisibilityTests {
    static let graph = RealCellGraph(cells: [
        .init("a", min: V3(-5, 0, -5), max: V3(5, 3, 5)),
        .init("b", min: V3(-5, 0, -15), max: V3(5, 3, -5.4)),
        .init("c", min: V3(-5, 0, -25), max: V3(5, 3, -15.4)),
    ], portals: [
        .init(0, 1, center: V3(0, 1, -5.2), width: 1, height: 2),
        .init(1, 2, center: V3(0, 1, -15.2), width: 1, height: 2),
    ])

    @Test func portalsInViewChainRooms() {
        let g = Self.graph
        #expect(g.visible(eye: V3(0, 1.6, 3), forward: V3(0, 0, -1)) == [0, 1, 2])
        #expect(g.visible(eye: V3(0, 1.6, 3), forward: V3(0, 0, 1)) == [0], "facing away from the door")
        #expect(g.visible(eye: V3(0, 1.6, -4.6), forward: V3(0, 0, 1)) == [0, 1], "next to a portal it stays visible")
        #expect(g.visible(eye: V3(0, 1.6, -5.2), forward: V3(0, 0, -1)) == nil, "in the doorway: everything")
    }

    @Test func hospitalFloorSplitsByRoom() async throws {
        let s = try #require(SceneCatalog.build("hospital", seed: 1))
        let g = try #require(s.cells)
        let split = await s.cellSplit(g)
        #expect(split.cells.count == 4)
        let inCells = split.cells.reduce(0) { $0 + $1.singles.count + $1.rigs.count }
        #expect(inCells > split.core.singles.count + split.core.rigs.count, "most content belongs to a room")
        #expect(split.core.lights.count == s.lights.count)
        let cam = try #require(s.camera)
        #expect(g.cell(at: cam.eye) != nil)
    }
}
