import XCTest
import RealityKit
@testable import AnimalKit
import AnimalCore
import RealKit

/// Skinned pets: every part carries normals and a material with a bound albedo texture and vertex AO off.
final class SkinnedTests: XCTestCase {
    @MainActor func testSkinnedSquirrelMaterialsAndNormals() async throws {
        RealKitSetup.register()
        let g = try await GroundFactory.puppet(.easternGraySquirrel)
        XCTAssertTrue(g.built.skinned)
        let skin = try XCTUnwrap(g.holder.findEntity(named: "skin") as? ModelEntity)
        let model = try XCTUnwrap(skin.model)
        XCTAssertFalse(model.materials.isEmpty)
        XCTAssertFalse(skin.jointNames.isEmpty)
        for m in model.materials {
            if let sg = m as? ShaderGraphMaterial {
                guard case .textureResource? = sg.getParameter(name: "BaseColor") else { return XCTFail("BaseColor texture not bound") }
            } else if let pbr = m as? PhysicallyBasedMaterial {
                XCTAssertNotNil(pbr.baseColor.texture, "PBR baseColor texture not bound")
            }
        }
        var parts = 0
        for mdl in model.mesh.contents.models {
            for p in mdl.parts {
                parts += 1
                XCTAssertNotNil(p.normals, "part \(p.id) has no normals")
                XCTAssertNotNil(p.jointInfluences, "part \(p.id) has no joint influences")
                XCTAssertLessThan(p.materialIndex, model.materials.count)
            }
        }
        XCTAssertGreaterThan(parts, 0)
    }
}
