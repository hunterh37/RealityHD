import XCTest
import RealityKit
@testable import AnimalKit
import AnimalCore
import RealKit

final class DinoPuppetTests: XCTestCase {
    @MainActor func testLoadByIdAndPlayEveryClip() async throws {
        RealKitSetup.register()
        let d = try await DinoFactory.puppet(id: "velociraptor", seed: 2, scale: 0.5)
        XCTAssertEqual(d.species, .velociraptor)
        XCTAssertEqual(d.entity.scale.x, 0.5, accuracy: 1e-5)
        for n in ["idle", "walk", "stomp", "roar", "pulled"] { XCTAssertTrue(d.play(n, time: 0.7)) }
        XCTAssertFalse(d.play("dance"))
        d.play(.roar, time: 1.6)
        let jaw = try XCTUnwrap(d.model.findEntity(named: "joint:jaw"))
        XCTAssertNotEqual(jaw.orientation.angle, 0, accuracy: 1e-3)
        d.scale = 2
        XCTAssertEqual(d.entity.scale.y, 2, accuracy: 1e-5)
        do { _ = try await DinoFactory.puppet(id: "stegosaurus"); XCTFail() } catch {}
    }
}
