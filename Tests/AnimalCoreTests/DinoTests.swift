import XCTest
import RealCore
@testable import AnimalCore

final class DinoTests: XCTestCase {
    func testJointCounts() {
        let expected: [DinoSpecies: Int] = [.trex: 24, .triceratops: 28, .velociraptor: 26]
        for s in DinoSpecies.allCases {
            let r = DinoRigBuilder.build(s.profile)
            XCTAssertEqual(r.joints.count, expected[s], "\(s)")
            XCTAssertEqual(r.joints.count, DinoJoint.count(s.profile), "\(s)")
            XCTAssertEqual(r.rig.validate(), [], "\(s)")
            XCTAssertTrue(r.jointNames.contains(DinoJoint.jaw))
            XCTAssertGreaterThan(r.triangleCount, 4000, "\(s)")
            XCTAssertLessThan(r.triangleCount, 60000, "\(s)")
        }
    }

    func testRealScaleBounds() {
        for s in DinoSpecies.allCases {
            let p = s.profile, r = DinoRigBuilder.build(p)
            let b = r.rig.posed("stand").levels[0].bounds
            let length = b.max.z - b.min.z
            XCTAssertEqual(length, p.targetLength, accuracy: p.targetLength * 0.15, "\(s) length \(length)")
            XCTAssertEqual(r.hipHeight, p.targetHipHeight, accuracy: p.targetHipHeight * 0.15, "\(s) hip \(r.hipHeight)")
            XCTAssertEqual(b.min.y, 0, accuracy: p.targetHipHeight * 0.05, "\(s) feet at y 0")
        }
        let t = DinoRigBuilder.build(DinoSpecies.trex.profile).rig.posed("stand").levels[0].bounds
        XCTAssertEqual(t.max.z - t.min.z, 12, accuracy: 1.8)
        XCTAssertEqual(DinoSpecies.trex.profile.hind.hip.y, 4, accuracy: 0.6)
    }

    func testAnimationsPresentAndDeterministic() {
        XCTAssertEqual(Set(DinoAnimation.allCases.map(\.rawValue)), ["idle", "walk", "stomp", "roar", "pulled"])
        for s in DinoSpecies.allCases {
            let r = DinoRigBuilder.build(s.profile)
            let names = Set(r.jointNames)
            for a in DinoAnimation.allCases {
                let p1 = DinoMotion.pose(s.profile, a, time: 1.3, seed: 7), p2 = DinoMotion.pose(s.profile, a, time: 1.3, seed: 7)
                XCTAssertEqual(p1.values, p2.values)
                for k in p1.values.keys { XCTAssertTrue(names.contains(k), "\(s) \(a) unknown joint \(k)") }
            }
            let roar = DinoMotion.pose(s.profile, .roar, time: DinoMotion.period(.roar, s.profile) * 0.5)
            XCTAssertGreaterThan(roar.values[DinoJoint.jaw] ?? 0, 20)
            XCTAssertGreaterThan(roar.values[DinoJoint.neck0] ?? 0, 10)
        }
    }

    func testGeometryDeterministicBySeed() {
        let a = DinoRigBuilder.build(DinoSpecies.trex.profile, seed: 3), b = DinoRigBuilder.build(DinoSpecies.trex.profile, seed: 3)
        XCTAssertEqual(a.rig.parts[0].levels[0].surfaces.map(\.positions), b.rig.parts[0].levels[0].surfaces.map(\.positions))
    }

    func testMaterialsCoverRig() {
        for s in DinoSpecies.allCases {
            let have = Set(DinoMaterials.specs(for: s.profile).map(\.key))
            let r = DinoRigBuilder.build(s.profile)
            for m in r.rig.parts.flatMap({ $0.levels[0].materials }) { XCTAssertTrue(have.contains(m), "\(s) missing \(m)") }
        }
    }
}
