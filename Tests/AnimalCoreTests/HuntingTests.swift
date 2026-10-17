import XCTest
import simd
@testable import AnimalCore

final class HuntingTests: XCTestCase {
    let ground: [GroundSpecies] = [.whitetailDeer, .rockyMountainElk, .wildBoar, .blackBear, .coyote]
    let birds: [BirdSpecies] = [.wildTurkey, .ringneckPheasant]

    func testIdsAndCounts() {
        XCTAssertEqual(GroundSpecies.hunting, ground)
        XCTAssertEqual(BirdSpecies.hunting, birds)
        XCTAssertEqual(ground.map(\.rawValue), ["whitetail-deer", "rocky-mountain-elk", "wild-boar", "black-bear", "coyote"])
        XCTAssertEqual(birds.map(\.rawValue), ["wild-turkey", "ringneck-pheasant"])
        XCTAssertEqual(AnimalKind.hunting.count, 7)
        XCTAssertEqual(AnimalKind(rawValue: "wild-turkey"), .bird(.wildTurkey))
        XCTAssertEqual(AnimalKind(rawValue: "black-bear"), .ground(.blackBear))
        XCTAssertTrue(GroundSpecies.whitetailDeer.hasAntlers && GroundSpecies.rockyMountainElk.hasAntlers)
        XCTAssertFalse(GroundSpecies.coyote.hasAntlers)
    }

    func testGameStaysOutOfYards() {
        for k in AnimalKind.hunting { XCTAssertFalse(AnimalKind.all.contains(k), k.rawValue) }
        let h = HabitatInventory.build(items: [("bird-feeder", 2), ("birdbath", 1), ("maple-tree", 3), ("privet-hedge", 2), ("lavender-clump", 3)], openArea: 80)
        var s = VisitScheduler(seed: 11, firstVisitIn: 0.1)
        s.settings.frequency = .busy
        var seen = Set<AnimalKind>()
        let hunting = Set(AnimalKind.hunting)
        for _ in 0..<(60 * 900) { for r in s.tick(dt: 1 / 60, habitat: h, view: YardView(), present: [], journal: Journal()) { seen.insert(r.kind) } }
        XCTAssertFalse(seen.isEmpty)
        XCTAssertTrue(seen.isDisjoint(with: hunting), "\(seen.intersection(hunting))")
    }

    func testGroundRigsBuildAtRealSize() {
        // (species, shoulder height range of the body center, tri range)
        let rows: [(GroundSpecies, ClosedRange<Float>)] = [(.whitetailDeer, 0.6...0.9), (.rockyMountainElk, 0.9...1.25), (.wildBoar, 0.4...0.65),
                                                           (.blackBear, 0.5...0.75), (.coyote, 0.38...0.56)]
        for (s, h) in rows {
            for v in GroundVariant.allCases {
                let r = GroundRigBuilder.build(s.profile(v))
                XCTAssertEqual(r.rig.validate(), [], "\(s) \(v)")
                XCTAssertEqual(r.joints.count, GroundJoint.count)
                XCTAssertTrue(h.contains(r.comHeight), "\(s) com \(r.comHeight)")
                XCTAssertGreaterThan(r.triangleCount, 3500, "\(s)")
                XCTAssertLessThan(r.triangleCount, 40000, "\(s)")
                // Feet stand on the ground at rest.
                var minY = Float.infinity
                for part in r.rig.parts { for sf in part.levels[0].surfaces { for p in sf.positions { minY = min(minY, p.y) } } }
                XCTAssertGreaterThan(minY, -0.02, "\(s) sinks \(minY)")
                XCTAssertLessThan(minY, 0.03, "\(s) floats \(minY)")
            }
        }
    }

    func testAntlersAddGeometryOnlyForBucksAndBulls() {
        for s in [GroundSpecies.whitetailDeer, .rockyMountainElk] {
            let plain = GroundRigBuilder.build(s.profile(.standard)), rack = GroundRigBuilder.build(s.profile(.antlered))
            XCTAssertGreaterThan(rack.triangleCount, plain.triangleCount + 400, "\(s)")
            XCTAssertEqual(s.profile(.antlered).anatomy.antlers, s == .whitetailDeer ? .whitetail : .elk)
            XCTAssertEqual(s.profile(.standard).anatomy.antlers, .none)
            XCTAssertEqual(rack.rig.name, s.rawValue + "-antlered")
        }
        XCTAssertEqual(GroundSpecies.coyote.profile(.antlered).variant, .standard)
        XCTAssertEqual(GroundRigBuilder.build(GroundSpecies.coyote.profile(.antlered)).triangleCount, GroundRigBuilder.build(GroundSpecies.coyote.profile).triangleCount)
    }

    func testGaitsAreDistinctPeriodicAndAlternating() {
        for s in ground {
            let p = s.profile
            let idle = GroundMotion.pose(p, .idle), walk = GroundMotion.pose(p, .walk, phase: 0.1), trot = GroundMotion.pose(p, .trot, phase: 0.1)
            let run = GroundMotion.pose(p, .run, phase: 0.2), graze = GroundMotion.pose(p, .graze)
            XCTAssertNotEqual(idle, walk, "\(s)"); XCTAssertNotEqual(walk, trot, "\(s)"); XCTAssertNotEqual(trot, run, "\(s)"); XCTAssertNotEqual(idle, graze, "\(s)")
            for a in [GroundAction.walk, .trot, .run] {
                let a0 = GroundMotion.pose(p, a, phase: 0.13), a1 = GroundMotion.pose(p, a, phase: 1.13)
                for i in 0..<GroundJoint.count { XCTAssertEqual(a0.values[i], a1.values[i], accuracy: 1e-3, "\(s) \(a) joint \(i)") }
            }
            // Walk: the right fore leg trails the left by half a cycle.
            for ph in stride(from: Float(0), to: 1, by: 0.125) {
                let l = GroundMotion.pose(p, .walk, phase: ph)[.foreL, .hip], r = GroundMotion.pose(p, .walk, phase: ph + 0.5)[.foreR, .hip]
                XCTAssertEqual(l, r, accuracy: 1e-3, "\(s)")
            }
            // Trot: diagonal pairs move together.
            let t = GroundMotion.pose(p, .trot, phase: 0.3)
            XCTAssertEqual(t[.foreL, .hip], t[.hindR, .hip], accuracy: 1e-3, "\(s) diagonal")
            XCTAssertNotEqual(t[.foreL, .hip], t[.foreR, .hip], "\(s)")
            // Every pose stays inside the joint ranges.
            for q in [idle, walk, trot, run, graze] { var c = q; c.clamp(); XCTAssertEqual(c, q, "\(s) out of range") }
        }
    }

    func testGrazePutsTheNoseOnTheGround() {
        for s in [GroundSpecies.whitetailDeer, .rockyMountainElk, .wildBoar, .blackBear, .coyote] {
            let r = GroundRigBuilder.build(s.profile)
            // Height of the lowest head point with the body leaned by `bodyPitch` about the center of mass.
            func noseHeight(_ pose: GroundPose, _ pitch: Float) -> Float {
                let xf = r.rig.partTransforms(r.rig.values(pose.named))
                let i = r.rig.index(GroundJoint.headPitch.name)!
                let c = cos(pitch * .pi / 180), sn = sin(pitch * .pi / 180)
                var low = Float.infinity
                for sf in r.rig.parts[i].levels[0].surfaces { for p in sf.positions { let w = xf[i].point(p); low = min(low, r.comHeight + (w.y - r.comHeight) * c + w.z * sn) } }
                return low
            }
            let up = noseHeight(GroundMotion.pose(s.profile, .idle), 0)
            let down = noseHeight(GroundMotion.pose(s.profile, .graze), GroundMotion.bodyPitch(.graze, s.profile))
            XCTAssertLessThan(down, up - 0.15, "\(s) graze \(down) idle \(up)")
            // Long necks reach the grass with the neck alone; short ones also tip the body forward (`bodyPitch`).
            XCTAssertLessThan(down, s.profile.anatomy.neckLength > 0.2 ? 0.16 : 0.26, "\(s) nose at \(down)")
        }
    }

    func testBrainsDriveGamePoses() {
        for s in ground {
            var v = YardView(min: V2(-6, -6), max: V2(6, 6))
            v.player.head = V3(0, 1.6, 20)
            v.forage = [V2(2, 0)]
            let b = GroundBrain(id: 1, profile: s.profile, spawn: V2(-5, 0), yaw: -1.57, stay: 30, trust: 0, groundY: 0, seed: 5)
            var grazed = false, walked = false
            for _ in 0..<(60 * 60) {
                b.update(dt: 1 / 60, view: v, book: PerchBook())
                if b.input.graze > 0.5 { grazed = true }
                if b.speedNow > 0.3 { walked = true }
                XCTAssertEqual(b.input.sit, 0, "\(s) sits")
            }
            XCTAssertTrue(walked, "\(s) never walked")
            XCTAssertTrue(grazed, "\(s) never grazed")
        }
    }

    func testGameAnimalsBoltAndLeave() {
        for s in ground {
            var v = YardView(min: V2(-6, -6), max: V2(6, 6))
            v.player.head = V3(0, 1.6, 40)
            let b = GroundBrain(id: 1, profile: s.profile, spawn: V2(0, 0), yaw: 0, stay: 60, trust: 0, groundY: 0, seed: 9)
            for _ in 0..<300 { b.update(dt: 1 / 60, view: v, book: PerchBook()) }
            // Walk toward it fast: inside the skittish radius it spooks and runs.
            v.player.head = V3(0, 1.6, b.position.z + 8); v.player.headSpeed = 2
            b.update(dt: 1 / 60, view: v, book: PerchBook())
            XCTAssertTrue(b.drainEvents().contains(.spooked), "\(s)")
            XCTAssertEqual(b.phase, .fleeing)
            var t: Float = 0
            while t < 60 && !b.isGone { b.update(dt: 1 / 60, view: v, book: PerchBook()); XCTAssertFalse(b.position.x.isNaN); t += 1 / 60 }
            XCTAssertTrue(b.isGone, "\(s) never left (\(b.phase))")
        }
    }

    func testGameBirdProportions() {
        let tom = BirdRigBuilder.build(BirdSpecies.wildTurkey.profile), cock = BirdRigBuilder.build(BirdSpecies.ringneckPheasant.profile)
        for r in [tom, cock] {
            XCTAssertEqual(r.rig.validate(), [])
            XCTAssertEqual(r.joints.count, BirdJoint.count)
        }
        XCTAssertTrue((0.4...0.6).contains(tom.comHeight), "\(tom.comHeight)")
        XCTAssertTrue((0.16...0.26).contains(cock.comHeight), "\(cock.comHeight)")
        XCTAssertGreaterThan(tom.triangleCount, 6000)
        XCTAssertLessThan(tom.triangleCount, 40000)
        XCTAssertLessThan(cock.triangleCount, 40000)
        // Wattle, beard and collar add parts that plain songbirds lack.
        XCTAssertTrue(tom.rig.base[0].materials.contains(FaunaMaterials.key("wild-turkey", .beard)))
        XCTAssertTrue(cock.rig.parts.contains { $0.levels[0].materials.contains(FaunaMaterials.key("ringneck-pheasant", .collar)) })
    }

    func testBirdWalkAlternatesLegsAndRunIsWider() {
        for s in birds {
            let p = s.profile
            let idle = BirdMotion.pose(p, .idle)
            XCTAssertEqual(idle[.left, .hip], 0, accuracy: 1e-4)
            func span(_ a: BirdAction) -> Float {
                var lo = Float.infinity, hi = -Float.infinity
                for k in 0..<16 { let h = BirdMotion.pose(p, a, phase: Float(k) / 16)[.left, .hip]; lo = min(lo, h); hi = max(hi, h) }
                return hi - lo
            }
            XCTAssertGreaterThan(span(.walk), 20, "\(s)")
            XCTAssertGreaterThan(span(.run), span(.walk) + 8, "\(s)")
            for k in 0..<8 {
                let ph = Float(k) / 8
                XCTAssertEqual(BirdMotion.pose(p, .walk, phase: ph)[.left, .hip], BirdMotion.pose(p, .walk, phase: ph + 0.5)[.right, .hip], accuracy: 1e-3)
            }
            for a in [BirdAction.walk, .trot, .run, .graze] {
                let a0 = BirdMotion.pose(p, a, phase: 0.21), a1 = BirdMotion.pose(p, a, phase: 1.21)
                for i in 0..<BirdJoint.count { XCTAssertEqual(a0.values[i], a1.values[i], accuracy: 1e-3, "\(s) \(a)") }
            }
            // A lifted foot bends the ankle.
            var maxAnkle: Float = 0
            for k in 0..<16 { maxAnkle = max(maxAnkle, BirdMotion.pose(p, .walk, phase: Float(k) / 16)[.left, .ankle]) }
            XCTAssertGreaterThan(maxAnkle, 20)
        }
    }

    func testPeckLowersTheHead() {
        for s in birds {
            let r = BirdRigBuilder.build(s.profile)
            func headLow(_ q: BirdPose) -> Float {
                let xf = r.rig.partTransforms(r.rig.values(q.named))
                let i = r.rig.index(BirdJoint.headPitch.name)!
                var low = Float.infinity
                for sf in r.rig.parts[i].levels[0].surfaces { for p in sf.positions { low = min(low, xf[i].point(p).y) } }
                return low
            }
            let idle = headLow(BirdMotion.pose(s.profile, .idle)), peck = headLow(BirdMotion.pose(s.profile, .graze, phase: 0.5))
            XCTAssertLessThan(peck, idle - 0.1, "\(s) \(peck) vs \(idle)")
        }
    }

    func testGameMaterialsComplete() {
        for s in ground {
            for v in GroundVariant.allCases {
                let have = Set(FaunaMaterials.specs(for: s.profile(v)).map(\.key))
                let r = GroundRigBuilder.build(s.profile(v))
                for m in r.rig.base[0].materials + r.rig.parts.flatMap({ $0.levels[0].materials }) { XCTAssertTrue(have.contains(m), "\(s) missing \(m)") }
            }
        }
        for s in birds {
            let have = Set(FaunaMaterials.specs(for: s.profile).map(\.key))
            let r = BirdRigBuilder.build(s.profile)
            for m in r.rig.base[0].materials + r.rig.parts.flatMap({ $0.levels[0].materials + $0.alternates.flatMap { $0[0].materials } }) { XCTAssertTrue(have.contains(m), "\(s) missing \(m)") }
        }
    }

    func testGameVoicesExist() {
        for s in birds {
            XCTAssertFalse(s.profile.voice.songs.isEmpty); XCTAssertFalse(s.profile.voice.calls.isEmpty)
        }
    }
}
