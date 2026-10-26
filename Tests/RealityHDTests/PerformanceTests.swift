import Foundation
import Testing
import simd
import RealityKit
@testable import RealCore
@testable import RealKit
@testable import RealLibrary

@Suite struct PerformanceTests {
    /// Three-level box asset: 1.2k / 300 / 108 triangles roughly.
    static func asset(size: Float = 1) -> LODModel {
        let levels = [4, 2, 1].map { seg -> Model in
            var m = Model(name: "box")
            m.add(Prim.roundedBox(V3(repeating: size), radius: size * 0.1, bevelSegments: seg, material: "wood.oak"))
            return m
        }
        return LODModel(levels: levels, switchDistances: [10, 30])
    }

    static func scene() -> RealScene {
        var s = RealScene(name: "perf-test")
        var grass: [simd_float4x4] = []
        for i in 0..<40 { for j in 0..<40 { grass.append(place(Float(i) - 20, Float(j) - 20).matrix) } }
        s.fields.append(.init(asset: asset(size: 0.2), transforms: grass, options: .groundCover(cull: 30)))
        var trees: [simd_float4x4] = []
        for i in 0..<30 { trees.append(place(Float(i % 6) * 12 - 30, Float(i / 6) * 12 - 30).matrix) }
        s.fields.append(.init(asset: asset(size: 3), transforms: trees, options: .trees))
        for i in 0..<60 { s.singles.append(.init(asset: asset(size: i % 3 == 0 ? 0.3 : 1.5), at: place(Float(i) * 2 - 60, 5))) }
        for k in 0..<12 { s.lights.append(RigLight(name: "l\(k)", position: V3(Float(k), 3, 0), intensity: Float(100 * k))) }
        s.camera = .init(eye: V3(0, 1.6, 0), target: V3(0, 1, -10), fov: 60)
        return s
    }

    @Test func balancedIsTheDefault() {
        #expect(RealPerformance() == RealPerformance(.balanced))
        let b = RealPerformance(.balanced)
        #expect(b.lodBias == 1 && b.drawDistance == 0 && b.fieldDensity == 1 && b.distantThinning == 0)
        #expect(b.shadowCasterMaxLOD == 1 && b.textureScale == 1 && b.maxTextureSize == 1024 && !b.forceBatching && !b.adaptive)
    }

    @Test func settingsRoundTripThroughDefaults() throws {
        let d = try #require(UserDefaults(suiteName: "realityhd.tests.\(UUID())"))
        let s = RealPerformance(.ultra).with { $0.lodBias = 1.7; $0.tier = nil; $0.wind = false }
        s.save(to: d)
        #expect(RealPerformance.load(from: d) == s)
        d.set(Data("{}".utf8), forKey: RealPerformance.defaultsKey)
        #expect(RealPerformance.load(from: d) == nil, "unreadable settings fall back")
    }

    @Test func rebuildClassification() {
        let b = RealPerformance(.balanced)
        #expect(!b.with { $0.lodBias = 0.5; $0.drawDistance = 80; $0.shadows = false; $0.adaptive = true }.needsRebuild(from: b), "live settings")
        #expect(b.with { $0.fieldDensity = 0.5 }.needsRebuild(from: b))
        #expect(b.with { $0.wind = false }.needsRebuild(from: b))
        #expect(b.with { $0.maxTextureSize = 512 }.needsRebuild(from: b))
        #expect(b.with { $0.forceBatching = true }.needsRebuild(from: b))
    }

    @Test func levelSelectionFollowsBiasAndCulls() {
        let sw: [Float] = [10, 30]
        let b = RealPerformance(.balanced)
        #expect(b.level(distance: 9, switchDistances: sw) == 0)
        #expect(b.level(distance: 20, switchDistances: sw) == 1)
        #expect(b.level(distance: 500, switchDistances: sw) == 2, "balanced never culls")
        let low = b.with { $0.lodBias = 0.5 }
        #expect(low.level(distance: 9, switchDistances: sw) == 1)
        #expect(b.with { $0.lodBias = 2 }.level(distance: 50, switchDistances: sw) == 1)
        #expect(b.level(distance: 9, switchDistances: sw, adaptive: 0.5) == 1, "adaptive scale lowers the bias")
        let far = b.with { $0.drawDistance = 100 }
        #expect(far.level(distance: 120, switchDistances: sw) == nil)
        let detail = b.with { $0.detailCullDistance = 15; $0.detailSize = 0.6 }
        #expect(detail.level(distance: 20, switchDistances: sw, size: 0.3) == nil)
        #expect(detail.level(distance: 20, switchDistances: sw, size: 2) == 1)
        let cover = b.with { $0.groundCoverDistance = 0.5 }
        #expect(cover.level(distance: 20, switchDistances: sw, cullDistance: 30, groundCover: true) == nil)
        #expect(cover.level(distance: 20, switchDistances: sw, cullDistance: 30, groundCover: false) == 1)
    }

    @MainActor @Test func primeSetsLevelsBeforeTheSceneJoins() throws {
        let parent = Entity()
        let near = try Self.asset().entity(), mid = try Self.asset().entity(), far = try Self.asset().entity()
        near.position = [0, 0, -2]; mid.position = [0, 0, -20]; far.position = [0, 0, -60]
        for e in [near, mid, far] { parent.addChild(e) }
        parent.position = [0, 0, -1]   // final placement is applied before priming
        RealLODSystem.prime(parent, viewer: [0, 1.6, 0])
        func on(_ e: Entity) -> [String] { e.children.filter { $0.isEnabled }.map { $0.name } }
        #expect(on(near) == ["lod0"]); #expect(on(mid) == ["lod1"]); #expect(on(far) == ["lod2"])
        #expect(far.components[RealLODComponent.self]?.current == 2)
    }

    @Test func peripheralScaleRampsOutsideTheView() {
        let b = RealPerformance(.balanced), fwd = SIMD3<Float>(0, 0, -1)
        #expect(b.peripheralScale(forward: fwd, toObject: [0, 0, -5]) == 1)
        #expect(b.peripheralScale(forward: fwd, toObject: [5, 0, -5]) == 1, "45 degrees is in view")
        #expect(abs(b.peripheralScale(forward: fwd, toObject: [0, 0, 5]) - b.peripheralBias) < 1e-4)
        #expect(b.with { $0.peripheralLOD = false }.peripheralScale(forward: fwd, toObject: [0, 0, 5]) == 1)
    }

    @MainActor @Test func offViewLODStopsAtTheShadowCasterLimit() throws {
        let perf = RealPerformance(.balanced)
        let front = try Self.asset().entity(), behind = try Self.asset().entity(), behindMid = try Self.asset().entity()
        front.position = [0, 0, -5]; behind.position = [0, 0, 5]; behindMid.position = [0, 0, 20]
        for e in [front, behind, behindMid] {
            RealLODSystem.evaluate(e, viewer: .zero, forward: [0, 0, -1], perf: perf, adapt: 1, bias: 1, reach: 0)
        }
        #expect(front.components[RealLODComponent.self]?.current == 0)
        #expect(behind.components[RealLODComponent.self]?.current == 1, "behind: one level coarser, still a caster")
        #expect(behindMid.components[RealLODComponent.self]?.current == 1, "capped at shadowCasterMaxLOD")
        let off = perf.with { $0.peripheralLOD = false }
        let b2 = try Self.asset().entity(); b2.position = [0, 0, 5]
        RealLODSystem.evaluate(b2, viewer: .zero, forward: [0, 0, -1], perf: off, adapt: 1, bias: 1, reach: 0)
        #expect(b2.components[RealLODComponent.self]?.current == 0)
    }

    @Test func shadowPolicy() {
        let b = RealPerformance(.balanced)
        #expect(b.castsShadow(lod: 1, size: 1) && !b.castsShadow(lod: 2, size: 1))
        #expect(!b.castsShadow(lod: 0, size: 1, eligible: false))
        #expect(!b.castsShadow(lod: 0, size: 1, lodShift: -2), "ground cover never casts")
        #expect(RealPerformance(.ultra).castsShadow(lod: 2, size: 1))
        let perf = RealPerformance(.performance)
        #expect(!perf.castsShadow(lod: 0, size: 0.1) && perf.castsShadow(lod: 0, size: 1) && !perf.castsShadow(lod: 1, size: 1))
        #expect(!b.with { $0.shadows = false }.castsShadow(lod: 0, size: 5))
    }

    @Test func thinningIsDeterministicAndProportional() {
        var t: [simd_float4x4] = []
        for i in 0..<100 { for j in 0..<100 { t.append(place(Float(i) * 0.37, Float(j) * 0.41).matrix) } }
        let half = RealPerformance(.balanced).with { $0.fieldDensity = 0.5 }
        let a = half.thinned(t), b = half.thinned(t)
        #expect(a.count == b.count)
        #expect(abs(Double(a.count) / Double(t.count) - 0.5) < 0.05)
        let thin = RealPerformance(.balanced).with { $0.distantThinning = 0.6 }
        #expect(thin.instances(t, level: 0, levels: 3).count == t.count, "LOD0 keeps everything")
        let coarse = thin.instances(t, level: 2, levels: 3)
        #expect(abs(Double(coarse.count) / Double(t.count) - 0.4) < 0.05)
        #expect(coarse.allSatisfy { simd_length(SIMD3($0.columns.0.x, $0.columns.0.y, $0.columns.0.z)) > 1.2 }, "survivors grow to cover")
    }

    @Test func tiersOrderByCost() {
        let s = Self.scene()
        let w = RealPerformance.Tier.allCases.map { s.estimate(settings: RealPerformance($0)) }
        for (a, b) in zip(w, w.dropFirst()) { #expect(a.weight <= b.weight, "\(a) vs \(b)") }
        let battery = w[0], balanced = w[2]
        #expect(battery.weight * 2 < balanced.weight, "battery at least halves the frame weight")
        #expect(battery.lights == 2 && balanced.lights == 8)
        #expect(balanced.instances > battery.instances)
    }

    @Test func balancedEstimateMatchesScene() {
        let s = Self.scene()
        let c = s.estimate(settings: RealPerformance(.balanced))
        #expect(c.instances == 1600 + 30 + 60, "balanced keeps every grass, tree and static instance")
    }

    @Test func viewVolumeIsTheUnionOfBothEyes() {
        let v = ViewVolume(eye: V3(0, 1.6, 0), target: V3(0, 1.6, -10))
        #expect(v.eyes.count == 2)
        #expect(v.intersects(center: V3(0, 1.6, -5), radius: 0.1))
        #expect(!v.intersects(center: V3(0, 1.6, 5), radius: 0.1), "behind the head")
        #expect(v.intersects(center: V3(0, 1.6, 0.3), radius: 0.5), "a sphere around the head touches the view")
        #expect(v.intersects(center: V3(-5, 1.6, -5), radius: 0.1), "45 degrees left sits inside a 100 degree field")
        #expect(!v.intersects(center: V3(-10, 1.6, -1), radius: 0.1), "84 degrees left is outside")
        // A tall caster behind and to the side throws its shadow forward into view.
        #expect(v.castsIntoView(center: V3(0, 3, 1), radius: 0.5, toLight: simd_normalize(V3(0, 1, 1)), shadowLength: 3))
        #expect(!v.castsIntoView(center: V3(0, 3, 1), radius: 0.5, toLight: simd_normalize(V3(0, 1, -1)), shadowLength: 3))
    }

    @Test func frustumEstimateDropsWhatIsBehind() {
        let s = Self.scene()
        let all = s.estimate(settings: RealPerformance(.balanced))
        let seen = s.estimate(settings: RealPerformance(.balanced), view: s.viewVolume())
        #expect(seen.triangles < all.triangles && seen.triangles > 0)
        #expect(seen.drawCalls < all.drawCalls)
        #expect(seen.shadowTriangles <= all.shadowTriangles)
        var turned = s
        turned.camera = .init(eye: V3(0, 1.6, 0), target: V3(0, 1, 10), fov: 60)
        #expect(turned.estimate(settings: RealPerformance(.balanced), view: turned.viewVolume()) != seen, "the view follows the camera")
    }

    @Test func liveRigsCountOneDrawPerPartMaterial() {
        var rig = Rig(name: "test-rig", lods: 1, switchDistances: [])
        var base = Model(name: "base"); base.add(Prim.roundedBox(V3(1, 1, 1), radius: 0.05, bevelSegments: 1, material: "wood.oak"))
        rig.base = [base]
        for k in 0..<3 {
            var m = Model(name: "p\(k)")
            m.add(Prim.roundedBox(V3(0.2, 0.2, 0.2), radius: 0.02, bevelSegments: 1, material: "wood.oak"))
            m.add(Prim.roundedBox(V3(0.1, 0.1, 0.1), radius: 0.01, bevelSegments: 1, material: "metal.steel"))
            rig.parts.append(RigPart(name: "p\(k)", parent: nil, pivot: .identity, joint: .hinge(0...90), levels: [m]))
        }
        rig.states = [RigState("a"), RigState("b")]
        var folded = rig
        for k in folded.parts.indices { folded.parts[k].joint = .fixed }
        let f = folded.foldingStatics()
        #expect(f.base[0].surfaces.count == 2 && f.parts.allSatisfy { $0.levels[0].triangleCount == 0 })
        #expect(f.posed().levels[0].triangleCount == rig.posed().levels[0].triangleCount)
        var s = RealScene(name: "rig-test")
        s.farGround = nil
        s.rigs.append(.init(rig: rig, at: Xform(translation: V3(0, 0, -3)), state: "a", interactive: true))
        s.camera = .init(eye: V3(0, 1.6, 0), target: V3(0, 0.5, -3), fov: 60)
        let c = s.estimate(settings: RealPerformance(.balanced), view: s.viewVolume())
        #expect(c.liveDrawCalls == 1 + 3 * 2 && c.drawCalls == c.liveDrawCalls)
        #expect(c.meshes == 4)
    }

    @Test func interiorStaticsOutOfTheSunStopCasting() {
        var s = RealScene(name: "sun-test")
        s.farGround = nil
        // A closed 10 x 3 x 10 box (shell) with one prop inside, and one prop outside in the sun.
        var shell = Model(name: "shell")
        shell.add(Prim.roundedBox(V3(10.4, 0.2, 10.4), radius: 0.01, bevelSegments: 1, material: "wood.oak"), Xform(translation: V3(0, 3.1, 0)))
        for (x, z, w, d) in [(Float(5.1), Float(0), Float(0.2), Float(10.4)), (-5.1, 0, 0.2, 10.4), (0, 5.1, 10.4, 0.2), (0, -5.1, 10.4, 0.2)] {
            shell.add(Prim.roundedBox(V3(w, 3.2, d), radius: 0.01, bevelSegments: 1, material: "wood.oak"), Xform(translation: V3(x, 0, z)))
        }
        s.add(shell, bake: true)
        s.singles.append(.init(asset: Self.asset(size: 0.5), at: Xform(translation: V3(0, 0, 0))))
        s.singles.append(.init(asset: Self.asset(size: 0.5), at: Xform(translation: V3(20, 0, 0))))
        s.lighting = .init(sky: .midday, interior: .office, fog: 0)
        let r = s.shadowResolved(s.singles)
        #expect(r.map { $0.castsShadow } == [true, false, true], "shell casts, enclosed prop stops, sunlit prop casts")
        s.cullSunBlockedCasters = false
        #expect(s.shadowResolved(s.singles).allSatisfy { $0.castsShadow })
        s.cullSunBlockedCasters = nil
        s.lighting.interior = nil
        #expect(s.shadowResolved(s.singles).allSatisfy { $0.castsShadow }, "exteriors keep every caster")
    }

    @Test func forcedBatchingKeepsSmallObjectsApart() {
        let s = Self.scene()
        let batched = s.uploadedStatics(RealPerformance(.balanced).with { $0.forceBatching = true })
        #expect(batched.count < s.singles.count)
        let sizes = batched.map { $0.asset.levels[0].boundsDiagonal }
        #expect(sizes.contains { $0 < 0.6 }, "small props batch on their own")
        #expect(s.uploadedStatics(RealPerformance(.balanced)).count == s.singles.count)
    }

    @Test func lightBudgetKeepsTheBrightest() {
        let l = RealScene.budgetLights(Self.scene().lights, max: 3)
        #expect(l.map(\.name) == ["l11", "l10", "l9"])
    }
}

@Suite struct GovernorTests {
    let perf = RealPerformance(.balanced).with { $0.adaptive = true; $0.targetFPS = 90 }

    @Test func idleGapDoesNotCutScale() {
        var g = RealGovernor(); var s: Float = 1
        for _ in 0..<200 { s = g.step(1 / 95.0, perf, scale: s) }
        s = g.step(3.0, perf, scale: s)                       // RealityKit idle span
        for _ in 0..<200 { s = g.step(1 / 95.0, perf, scale: s) }
        #expect(s == 1)
    }

    @Test func slowFramesStillCutScale() {
        var g = RealGovernor(); var s: Float = 1
        for _ in 0..<60 { s = g.step(1 / 60.0, perf, scale: s) }
        #expect(s < 1)
    }

    @Test @MainActor func meshUploadHoldsGovernor() throws {
        let before = RealPerformance.adaptiveHoldUntil
        _ = try PerformanceTests.asset().levels[0].lowLevelMesh()
        #expect(RealPerformance.adaptiveHoldUntil > max(before, CFAbsoluteTimeGetCurrent()))
    }
}

@Suite struct LivePacerTests {
    @Test func staticViewDropsToStaticInterval() {
        var p = RealLivePacer(movingInterval: 0, staticInterval: 0.1)
        let k = SIMD8<Float>(1, 2, 3, 40, 0, 0, 0, 0)
        let first = p.shouldRender(key: k, now: 0)
        let held = p.shouldRender(key: k, now: 0.05)
        let due = p.shouldRender(key: k, now: 0.11)
        let moved = p.shouldRender(key: SIMD8(1, 2, 3.5, 40, 0, 0, 0, 0), now: 0.12)
        #expect(first && !held && due && moved)
    }

    @Test func animatedAlwaysRenders() {
        var p = RealLivePacer(movingInterval: 0, staticInterval: 0.1)
        let k = SIMD8<Float>(0, 0, 0, 40, 0, 0, 0, 0)
        let a = p.shouldRender(key: k, animated: true, now: 0)
        let b = p.shouldRender(key: k, animated: true, now: 0.01)
        #expect(a && b)
    }
}
