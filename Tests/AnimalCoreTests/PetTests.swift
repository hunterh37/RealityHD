import XCTest
import RealCore
@testable import AnimalCore

final class PetTests: XCTestCase {
    func testGrowthStages() {
        XCTAssertEqual(PetGrowth.stage(ageDays: 0), .baby)
        XCTAssertEqual(PetGrowth.stage(ageDays: 13.9), .baby)
        XCTAssertEqual(PetGrowth.stage(ageDays: 14), .juvenile)
        XCTAssertEqual(PetGrowth.stage(ageDays: 60), .adult)
        XCTAssertEqual(PetGrowth.stage(ageDays: 730), .elder)
        XCTAssertEqual(PetGrowth(stage: .baby).scale, 0.62)
        XCTAssertEqual(PetGrowth(stage: .juvenile).scale, 0.82)
        XCTAssertEqual(PetGrowth(stage: .adult).scale, 1)
    }

    func testGrowthAppliesToProfiles() {
        let base = GroundSpecies.fennecFox.profile
        let baby = PetGrowth(stage: .baby).apply(to: base)
        XCTAssertEqual(baby.anatomy.bodyLength, base.anatomy.bodyLength * 0.62, accuracy: 1e-5)
        XCTAssertGreaterThan(baby.anatomy.headLength / baby.anatomy.bodyLength, base.anatomy.headLength / base.anatomy.bodyLength)
        XCTAssertGreaterThan(baby.anatomy.eyeRadius / baby.anatomy.bodyLength, base.anatomy.eyeRadius / base.anatomy.bodyLength)
        XCTAssertEqual(PetGrowth(stage: .adult).apply(to: base).anatomy.bodyLength, base.anatomy.bodyLength)
        let bird = BirdSpecies.easternBluebird.profile
        XCTAssertEqual(PetGrowth(stage: .juvenile).apply(to: bird).anatomy.wingspan, bird.anatomy.wingspan * 0.82, accuracy: 1e-5)
    }

    func testFennecProfile() {
        let p = GroundSpecies.fennecFox.profile
        XCTAssertEqual(p.latin, "Vulpes zerda")
        XCTAssertFalse(p.behavior.climbs)
        XCTAssertEqual(p.behavior.gait, .stride)
        XCTAssertGreaterThanOrEqual(p.anatomy.earLength, 0.1)
        XCTAssertTrue(AnimalKind.pets.contains(.ground(.fennecFox)))
        XCTAssertEqual(AnimalKind(rawValue: "fennec-fox"), .ground(.fennecFox))
    }

    func testSurfaceCrawlAlignsUpToNormal() {
        let cases: [(V3, V3)] = [(V3(0, 1, 0), V3(0, 0, -1)), (V3(1, 0, 0), V3(0, 1, 0)), (V3(0, 0, 1), V3(1, 0, 0)), (V3(0, -1, 0), V3(1, 0, 0)), (V3(0, 1, 0), V3(0, 1, 0))]
        for (n, h) in cases {
            let q = SurfaceCrawl.orientation(normal: n, heading: h)
            XCTAssertEqual(simd_length(q.act(V3(0, 1, 0)) - n), 0, accuracy: 1e-4, "up for \(n)")
            let f = q.act(V3(0, 0, -1))
            XCTAssertEqual(simd_dot(f, n), 0, accuracy: 1e-4)
            XCTAssertFalse(f.x.isNaN)
        }
        let id = SurfaceCrawl.orientation(normal: V3(0, 1, 0), heading: V3(0, 0, -1))
        XCTAssertEqual(simd_length(id.act(V3(1, 0, 0)) - V3(1, 0, 0)), 0, accuracy: 1e-4)
        // Wall heading up the wall keeps facing up.
        let w = SurfaceCrawl.orientation(normal: V3(1, 0, 0), heading: V3(0, 1, 0))
        XCTAssertEqual(simd_length(w.act(V3(0, 0, -1)) - V3(0, 1, 0)), 0, accuracy: 1e-4)
    }

    func testSurfaceSpeedScale() {
        XCTAssertEqual(PetSurface.classify(normal: V3(0, 1, 0)), .floor)
        XCTAssertEqual(PetSurface.classify(normal: V3(0, 1, 0), raised: true), .table)
        XCTAssertEqual(PetSurface.classify(normal: V3(1, 0, 0)), .wall)
        XCTAssertEqual(PetSurface.classify(normal: V3(0, -1, 0)), .ceiling)
        XCTAssertGreaterThan(PetSurface.floor.speedScale, PetSurface.table.speedScale)
        XCTAssertGreaterThan(PetSurface.table.speedScale, PetSurface.wall.speedScale)
        let p = SurfaceCrawl.step(position: .zero, normal: V3(1, 0, 0), heading: V3(0, 1, 0), speed: 1, dt: 1)
        XCTAssertEqual(p.y, PetSurface.wall.speedScale, accuracy: 1e-4)
        XCTAssertEqual(p.x, 0, accuracy: 1e-4)
    }

    func testHandPerch() {
        let palm = V3(0.2, 1.0, -0.4)
        for kind in [HandPerch.Kind.squirrel, .bird] {
            let t = HandPerch.target(kind: kind, palm: palm, normal: V3(0, 1, 0), fingers: V3(0, 0, -1))
            XCTAssertGreaterThan(t.position.y, palm.y)
            XCTAssertLessThan(t.position.y - palm.y, 0.03)
            XCTAssertEqual(t.position.x, palm.x, accuracy: 1e-5)
            XCTAssertEqual(simd_length(t.rotation.act(V3(0, 1, 0)) - V3(0, 1, 0)), 0, accuracy: 1e-4)
        }
        // Tilted palm: body up follows the palm normal, facing along the fingers.
        let n = simd_normalize(V3(0.3, 1, 0))
        let t = HandPerch.target(kind: .bird, palm: palm, normal: n, fingers: V3(0, 0, -1))
        XCTAssertEqual(simd_length(t.rotation.act(V3(0, 1, 0)) - n), 0, accuracy: 1e-4)
        XCTAssertGreaterThan(HandPerch.target(kind: .squirrel, palm: palm, normal: n).crouch, HandPerch.target(kind: .bird, palm: palm, normal: n).crouch)
    }
}
