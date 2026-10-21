import Testing
import Foundation
@testable import RealCore
@testable import RealLibrary

@Suite struct PrebakeTests {
    @Test func codecRoundTripsEveryLevel() throws {
        let id = try #require(Catalog.ids().first)
        var lod = try #require(Catalog.build(id, seed: 2))
        lod.anchors["grip"] = Xform(translation: V3(1, 2, 3), rotation: simd_quatf(angle: 0.5, axis: V3(0, 1, 0)), scale: V3(1, 2, 1))
        let data = LODModelCodec.encode(lod)
        let back = try #require(LODModelCodec.decode(data))
        #expect(back.levels.count == lod.levels.count)
        #expect(back.switchDistances == lod.switchDistances)
        #expect(back.anchors["grip"] == lod.anchors["grip"])
        #expect(LODModelCodec.encode(back) == data)
        #expect(zip(back.levels, lod.levels).allSatisfy { $0.triangleCount == $1.triangleCount && $0.materials == $1.materials })
    }

    @Test func decodeRejectsTruncatedAndForeignData() throws {
        let id = try #require(Catalog.ids().first)
        let lod = try #require(Catalog.build(id))
        let data = LODModelCodec.encode(lod)
        #expect(LODModelCodec.decode(data.prefix(data.count / 2)) == nil)
        #expect(LODModelCodec.decode(Data([1, 2, 3, 4, 5, 6, 7, 8])) == nil)
    }

    @Test func storedAssetLoadsBack() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("prebake-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: dir) }
        let id = try #require(Catalog.ids().first)
        let lod = try #require(Catalog.build(id, seed: 4))
        RealPrebake.store(lod, id: id, seed: 4, in: dir)
        RealPrebake.flush()
        let saved = RealPrebake.directories
        defer { RealPrebake.directories = saved }
        RealPrebake.directories = [dir]
        #expect(RealPrebake.load(id: id, seed: 4)?.levels[0].triangleCount == lod.levels[0].triangleCount)
        #expect(RealPrebake.load(id: id, seed: 5) == nil)
    }
}
