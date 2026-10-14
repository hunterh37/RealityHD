import Testing
import RealityKit
@testable import RealKit
@testable import RealLibrary

@MainActor
struct PackedMeshTests {
    /// Off-main packing must produce the exact buffers of the main-actor upload.
    @Test func packedMatchesLowLevelMesh() throws {
        let t = try #require(Catalog.type("river-birch"))
        let m = t.init().build(seed: 3).levels[0]
        let a = try m.lowLevelMesh(), b = try PackedMesh(m).lowLevelMesh()
        #expect(a.parts.count == b.parts.count)
        let va = a.withUnsafeBytes(bufferIndex: 0) { Array($0) }, vb = b.withUnsafeBytes(bufferIndex: 0) { Array($0) }
        #expect(va == vb)
        let ia = a.withUnsafeIndices { Array($0) }, ib = b.withUnsafeIndices { Array($0) }
        #expect(ia == ib)
    }
}
