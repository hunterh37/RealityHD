import simd
import Foundation
import RealityKit
import RealKit

/// Layout of `siphon-cafe` for apps (scene root space, meters).
public enum SiphonCafeLayout {
    /// Brew table top height.
    public static let tableTopY: Float = 0.9
    /// Brew table centre (x, z) and size (length along X, depth along Z).
    public static let tableCenter = V2(0, -1.2)
    public static let tableSize = V2(1.5, 0.8)
    /// Siphon bar origin on the table (front faces +Z, toward the viewer).
    public static let barOrigin = V3(0, tableTopY, -1.32)
    /// Entity names (`findEntity(named:)`).
    public static let barName = "siphon-bar"
    public static func globeName(_ station: Int) -> String { station == 0 ? "left-globe" : "right-globe" }
    public static func flaskName(_ station: Int) -> String { station == 0 ? "left-flask" : "right-flask" }
}

/// Outdoor café terrace at a siphon brew table: a walnut-topped bar table on herringbone pavers holding
/// a two-station halogen beam siphon bar with live keypads, both lower flasks on the burners and the
/// upper globes in the clamps, a copper gooseneck kettle, drip scale, bean bag, bamboo paddle, spare cloth
/// filter and cups on saucers. Around it: café tables under market umbrellas, bentwood chairs, concrete
/// planters, potted boxwoods, a patio heater, street lamps, and maples and oaks beyond the terrace.
public struct SiphonCafe: RealSceneBuilder {
    public static let id = "siphon-cafe"
    public static let summary = "Outdoor café terrace around a halogen beam siphon bar on a walnut brew table: live keypads and displays, removable globes and flasks, kettle, scale, cups."
    public static let tags = ["kitchen", "outdoor", "showcase"]
    public static let author = "realityhd"

    /// Terrace paving extent (m).
    public var terrace = V2(12, 10)
    public init() {}

    typealias L = SiphonCafeLayout

    public func build(seed: UInt64) -> RealScene {
        var scene = RealScene(name: Self.id)
        var rng = SeededRNG(seed: seed &+ 77)

        // Ground: meadow beyond, herringbone terrace with a soldier border.
        scene.add(GroundPatch().with { $0.size = 80; $0.segments = 96; $0.relief = 0.25; $0.flatCenter = 9; $0.material = "ground.meadow" }, seed: seed)
        var paving = Model(name: "terrace")
        paving.add(Prim.terrain(size: terrace, segments: 8, material: "paver.herringbone") { _ in 0.03 }, Xform(translation: V3(0, 0, -2.5)))
        for (sx, sz, w, d) in [(Float(0), -2.5 - terrace.y / 2, terrace.x + 0.24, Float(0.24)), (0, -2.5 + terrace.y / 2, terrace.x + 0.24, 0.24),
                               (-terrace.x / 2, -2.5, 0.24, terrace.y), (terrace.x / 2, -2.5, 0.24, terrace.y)] {
            paving.add(Prim.roundedBox(V3(w, 0.06, d), radius: 0.008, bevelSegments: 1, material: "concrete.smooth"), Xform(translation: V3(sx, 0.012, sz)))
        }
        scene.add(paving, bake: true)

        // Brew table: walnut top on black steel slab legs, bar height.
        let table = ConferenceTable().with { $0.length = L.tableSize.x; $0.depth = L.tableSize.y; $0.height = L.tableTopY - 0.03; $0.wood = "wood.walnut" }
        scene.add(table, at: place(L.tableCenter.x, L.tableCenter.y, y: 0.03), seed: seed &+ 1)
        let top = L.tableTopY

        // Siphon bar (grabbable as a whole), flasks on the burners, globes in the clamps.
        let bar = HalogenSiphonBar().with { $0.globes = false }
        let bo = L.barOrigin
        scene.addLive(bar, at: place(bo.x, bo.z, y: bo.y), seed: seed &+ 2, state: "idle", grabbable: true, name: L.barName)
        for s in 0..<2 {
            let rim = bar.burnerRim(s) + bo, tip = bar.globeStemTip(s) + bo
            scene.addGrabbable(SiphonLowerFlask(), at: place(rim.x, rim.z, y: rim.y), seed: seed &+ 3 &+ UInt64(s), name: L.flaskName(s))
            scene.addGrabbable(SiphonUpperGlobe(), at: place(tip.x, tip.z, y: tip.y), seed: seed &+ 5 &+ UInt64(s), name: L.globeName(s))
        }

        // Brewing kit around the bar.
        scene.addGrabbable(CopperKettle(), at: place(-0.53, -1.36, y: top, yaw: 35), seed: seed &+ 10, name: "kettle")
        scene.addGrabbable(CoffeeScale(), at: place(-0.48, -0.98, y: top, yaw: 4), seed: seed &+ 11, name: "scale")
        scene.addGrabbable(CoffeeBeanBag(), at: place(0.52, -1.42, y: top, yaw: -20), seed: seed &+ 12, name: "beans")
        scene.addGrabbable(BambooPaddle(), at: place(-0.3, -0.9, y: top, yaw: 84), seed: seed &+ 13, name: "paddle")
        scene.addGrabbable(SiphonClothFilter(), at: place(0.05, -0.95, y: top, yaw: 20), seed: seed &+ 14, name: "cloth-filter")
        scene.addGrabbable(CoffeeCupSaucer(), at: place(0.36, -1.0, y: top, yaw: -30), seed: seed &+ 15, name: "cup-1")
        scene.addGrabbable(CoffeeCupSaucer().with { $0.fillDrop = nil }, at: place(0.56, -1.04, y: top, yaw: 15), seed: seed &+ 16, name: "cup-2")

        // Guests' side of the brew table.
        for (i, x) in [Float(-0.35), 0.35].enumerated() {
            scene.add(BentwoodChair(), at: place(x, -1.95, yaw: rng.float(-8...8)), seed: seed &+ 20 &+ UInt64(i))
        }

        // Café tables under market umbrellas.
        let cafe: [V2] = [V2(-3.2, -3.0), V2(3.0, -3.4), V2(-2.6, -6.4), V2(2.4, -6.8)]
        for (i, p) in cafe.enumerated() {
            scene.add(CafeTableSet(), at: place(p.x, p.y, yaw: rng.float(0...360)), seed: seed &+ 30 &+ UInt64(i))
            if i < 2 { scene.add(PatioUmbrella(), at: place(p.x + 0.05, p.y - 0.05), seed: seed &+ 34 &+ UInt64(i), state: "open") }
        }
        scene.add(BistroSet(), at: place(-4.5, -0.2, yaw: 70), seed: seed &+ 38)
        scene.addGrabbable(CoffeeCupSaucer(), at: place(-3.12, -2.95, y: 0.74, yaw: 40), seed: seed &+ 39, name: "cup-3")
        scene.add(PatioHeater(), at: place(0.9, -4.6), seed: seed &+ 40)

        // Terrace edge: concrete planters with boxwood, potted boxwoods, lamps.
        for (i, x) in stride(from: Float(-4.5), through: 4.5, by: 3).enumerated() {
            scene.add(ConcretePlanter().with { $0.width = 1.0; $0.height = 0.6; $0.shrubDiameter = 0.75 }, at: place(x, -7.2 - 0.6, yaw: rng.float(-3...3)), seed: seed &+ 50 &+ UInt64(i))
        }
        for (i, p) in [V2(-1.2, -0.3), V2(1.3, -0.4), V2(-5.4, -4.6), V2(5.4, -1.8)].enumerated() {
            scene.add(PottedBoxwood(), at: place(p.x, p.y, y: 0.03), seed: seed &+ 60 &+ UInt64(i))
        }
        scene.add(StreetLamp(), at: place(-5.6, -7.0), seed: seed &+ 70)
        scene.add(StreetLamp(), at: place(5.6, -7.0), seed: seed &+ 71)
        scene.add(StreetLamp(), at: place(5.7, 1.6), seed: seed &+ 72)

        // Trees beyond the terrace.
        let spots = Scatter.poisson(count: 16, outerRadius: 30, innerRadius: 10, minSpacing: 6, seed: seed &+ 80) { $0.y < -9 || abs($0.x) > 8.5 }
        var oaks: [simd_float4x4] = [], maples: [simd_float4x4] = []
        for p in spots {
            let m = place(p.x, p.y, y: -0.1, yaw: rng.float(0...360), scale: rng.float(0.85...1.1)).matrix
            if rng.chance(0.5) { oaks.append(m) } else { maples.append(m) }
        }
        scene.field(OakTree(), seed: seed &+ 81, transforms: oaks, options: .trees)
        scene.field(MapleTree(), seed: seed &+ 82, transforms: maples, options: .trees)

        scene.lighting = .init(sky: .afternoon)
        scene.camera = .init(eye: V3(0.05, 1.58, -0.38), target: V3(0, 1.02, -1.3), fov: 60)
        scene.spots = [.init("brew", eye: V3(0.05, 1.58, -0.38), target: V3(0, 1.02, -1.3)),
                       .init("terrace", eye: V3(-1.8, 1.6, 0.6), target: V3(0, 0.9, -1.4))]
        return scene
    }
}
