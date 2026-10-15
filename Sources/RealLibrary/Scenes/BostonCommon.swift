import simd
import Foundation
import RealityKit
import RealKit

/// Boston Common, about 420 x 380 m, +X east (Tremont St), -Z north (Beacon St). Lawns, asphalt malls
/// lined with American elms and acorn lamps, iron perimeter fence on granite curb, Frog Pond, Parkman
/// Bandstand, Flagstaff Hill with the Soldiers and Sailors Monument, Brewer Fountain, visitor kiosk,
/// Park Street T headhouses, Central Burying Ground. Across the streets: the State House and Shaw
/// Memorial on Beacon Hill, Park Street Church, Beacon St rowhouses and Tremont St blocks.
/// Camera stands by Brewer Fountain looking up the Common toward the gold dome.
public struct BostonCommon: RealSceneBuilder {
    public static let id = "boston-common"
    public static let summary = "Boston Common: elm malls, Frog Pond, bandstand, Soldiers and Sailors Monument, Brewer Fountain, State House, Park Street Church, burying ground."
    public static let tags = ["urban", "park", "outdoor", "showcase"]
    public static let author = "hunterh37"

    /// Half extents of the Common (east-west, north-south), meters.
    public var half = V2(210, 190)
    public init() {}

    public func build(seed: UInt64) -> RealScene {
        var scene = RealScene(name: Self.id)
        var rng = SeededRNG(seed: seed &+ 99)
        let hill = V2(70, 50), hillRadius: Float = 45, hillHeight: Float = 7
        let ground = GroundPatch().with {
            $0.size = 900; $0.segments = 192; $0.relief = 0.25; $0.gullies = 0; $0.flatCenter = 300
            $0.material = "ground.meadow"
        }
        func base(_ p: V2) -> Float { ground.height(x: p.x, z: p.y, seed: seed) }
        func hillY(_ p: V2) -> Float {
            let t = saturate(1 - simd_distance(p, hill) / hillRadius)
            return hillHeight * t * t * (3 - 2 * t)
        }
        func y(_ p: V2) -> Float { base(p) + hillY(p) }
        let groundModel = ground.build(seed: seed)
        scene.singles.append(.init(asset: groundModel, at: .identity))
        // Flagstaff Hill mound.
        var mound = Model(name: "flagstaff-hill")
        mound.add(Prim.terrain(size: V2(hillRadius * 2.1, hillRadius * 2.1), segments: 64, material: "ground.meadow") { q in
            let p = q + hill
            return hillY(p) > 0.01 ? y(p) + 0.02 : base(p) - 0.3
        }, Xform(translation: V3(hill.x, 0, hill.y)))
        scene.add(mound)

        // Streets around the Common and sidewalks.
        var streets = Model(name: "streets")
        let roadW: Float = 14, walkW: Float = 5
        func strip(_ a: V2, _ b: V2, width: Float, material: MaterialKey, lift: Float) {
            let d = b - a, len = simd_length(d), mid = (a + b) / 2
            let yaw = atan2(-d.y, d.x)
            streets.add(Prim.terrain(size: V2(len, width), segments: max(2, Int(len / 8)), material: material) { _ in lift },
                        Xform(translation: V3(mid.x, y(mid), mid.y), rotation: simd_quatf(angle: yaw, axis: .up)))
        }
        let corners = [V2(-half.x, -half.y), V2(half.x, -half.y), V2(half.x, half.y), V2(-half.x, half.y)]
        for i in 0..<4 {
            let a = corners[i], b = corners[(i + 1) % 4]
            let n = simd_normalize(V2(-(b - a).y, (b - a).x)) * -1 // outward
            strip(a + n * (walkW + roadW / 2), b + n * (walkW + roadW / 2), width: roadW + 2 * walkW + 30, material: "asphalt", lift: 0.02)
            strip(a + n * walkW / 2, b + n * walkW / 2, width: walkW, material: "concrete.smooth", lift: 0.12)
            strip(a + n * (walkW * 1.5 + roadW), b + n * (walkW * 1.5 + roadW), width: walkW, material: "concrete.smooth", lift: 0.12)
        }
        // Interior malls and footpaths (asphalt), the Common's diagonal web.
        let nodes: [String: V2] = [
            "park": V2(185, -185), "beaconMid": V2(60, -190), "beaconW": V2(-150, -190), "charlesN": V2(-210, -120),
            "charlesS": V2(-210, 120), "boylW": V2(-120, 190), "boylE": V2(150, 190), "tremS": V2(210, 120),
            "tremMid": V2(210, 20), "fountain": V2(165, -150), "pond": V2(30, -70), "band": V2(-70, 40), "hill": hill,
        ]
        let paths: [(String, String, Float)] = [
            ("park", "fountain", 8), ("fountain", "pond", 5), ("beaconMid", "pond", 5), ("pond", "band", 4),
            ("beaconW", "pond", 4), ("charlesN", "band", 4), ("charlesS", "band", 4), ("band", "boylW", 4),
            ("hill", "boylE", 4), ("hill", "tremMid", 4), ("hill", "pond", 4), ("fountain", "tremMid", 5),
            ("band", "hill", 4), ("tremS", "hill", 4),
        ]
        for (a, b, w) in paths { strip(nodes[a]!, nodes[b]!, width: w, material: "asphalt", lift: 0.04) }
        // Mall along Beacon and Tremont just inside the fence.
        strip(V2(-200, -178), V2(200, -178), width: 6, material: "asphalt", lift: 0.04)
        strip(V2(198, -178), V2(198, 178), width: 6, material: "asphalt", lift: 0.04)
        scene.add(streets)

        func one<A: RealAsset>(_ a: A, _ p: V2, yaw: Float = 0, s: UInt64) {
            scene.add(a, at: place(p.x, p.y, y: y(p), yaw: yaw), seed: seed &+ s)
        }
        // Landmarks inside the Common.
        one(FrogPond(), nodes["pond"]!, yaw: 10, s: 1)
        one(ParkmanBandstand(), nodes["band"]!, s: 2)
        one(SoldiersSailorsMonument(), hill, s: 3)
        one(BrewerFountain(), nodes["fountain"]!, s: 4)
        one(VisitorKiosk(), V2(178, -128), yaw: -90, s: 5)
        one(MbtaHeadhouse(), V2(192, -168), yaw: -90, s: 6)
        one(MbtaHeadhouse(), V2(192, -152), yaw: -90, s: 7)
        // Across the streets: Beacon Hill and Park Street.
        let north = -half.y - walkW * 2 - roadW
        one(ShawMemorial(), V2(60, -half.y + 6), s: 8)
        one(MassachusettsStateHouse(), V2(60, north - 30), s: 9)
        one(ParkStreetChurch(), V2(half.x + walkW * 2 + roadW + 14, -half.y + 10), yaw: -90, s: 10)
        // Beacon St Federal rowhouses west of the State House, Tremont St blocks east of the Common.
        let rowStyles = ["federal", "brownstone", "georgian", "federal", "brownstone", "italianate"]
        var x: Float = -205
        var i = 0
        while x < 15 {
            let style = rowStyles[i % rowStyles.count], w = rng.float(7...10)
            var b = BuildingSpec(footprint: .rect(width: w, depth: 14), floors: rng.int(4...5), style: style, seed: seed &+ UInt64(100 + i))
            b.bayWidth = 2.2
            b.roof = style == "federal" ? .gable : nil
            scene.add(GeneratedBuilding(spec: b), at: place(x + w / 2, north - 9, y: y(V2(x, north - 9))), seed: seed &+ UInt64(100 + i))
            x += w + 0.05; i += 1
        }
        var zt: Float = -120
        let towerStyles = ["beaux-arts", "art-deco", "haussmann", "modernist", "italianate"]
        while zt < 180 {
            let style = towerStyles[i % towerStyles.count], w = rng.float(16...28)
            var b = BuildingSpec(footprint: .rect(width: w, depth: 18), floors: rng.int(6...12), style: style, seed: seed &+ UInt64(100 + i))
            b.bayWidth = style == "modernist" ? 1.5 : 3
            b.groundFloorHeight = 4.4
            let px = half.x + walkW * 2 + roadW + 10
            scene.add(GeneratedBuilding(spec: b), at: place(px, zt + w / 2, y: y(V2(px, zt)), yaw: -90), seed: seed &+ UInt64(100 + i))
            zt += w + 0.1; i += 1
        }

        // Central Burying Ground, southeast corner: slate headstones in loose rows.
        var stones: [simd_float4x4] = []
        for r in 0..<9 {
            for c in 0..<14 where rng.float() > 0.18 {
                let p = V2(130 + Float(c) * 3.2 + rng.float(-0.5...0.5), 140 + Float(r) * 4 + rng.float(-0.6...0.6))
                stones.append(place(p.x, p.y, y: y(p) - 0.05, yaw: rng.float(-8...8), scale: rng.float(0.85...1.15)).matrix)
            }
        }
        scene.field(SlateHeadstone(), seed: seed &+ 20, transforms: stones, options: .props)

        // Perimeter iron fence on the Beacon, Park and Tremont sides plus the burying ground.
        var fence: [simd_float4x4] = []
        let bay: Float = 2.4
        for fx in stride(from: -half.x + 2, to: half.x - 2, by: bay) where abs(fx - 60) > 5 && abs(fx - 185) > 6 {
            fence.append(place(fx + bay / 2, -half.y + 0.4, y: y(V2(fx, -half.y))).matrix)
        }
        for fz in stride(from: -half.y + 2, to: half.y - 2, by: bay) where abs(fz + 160) > 14 && abs(fz - 20) > 4 && abs(fz - 120) > 4 {
            fence.append(place(half.x - 0.4, fz + bay / 2, y: y(V2(half.x, fz)), yaw: 90).matrix)
        }
        for fx in stride(from: Float(124), to: 180, by: bay) { fence.append(place(fx + bay / 2, 134, y: y(V2(fx, 134))).matrix) }
        scene.field(BostonIronFence(), seed: seed &+ 21, transforms: fence, options: .props)

        // Acorn lamps and benches along the paths, elms lining the malls.
        var lamps: [simd_float4x4] = [], benches: [simd_float4x4] = [], bins: [simd_float4x4] = [], elms: [simd_float4x4] = []
        func along(_ a: V2, _ b: V2, every: Float, offset: Float, _ body: (V2, Float, Int) -> Void) {
            let d = b - a, len = simd_length(d), u = d / len, n = V2(-u.y, u.x)
            let yaw = atan2(-u.y, u.x) * 180 / .pi
            var k = 0
            for t in stride(from: every / 2, to: len - every / 2, by: every) {
                for side: Float in [-1, 1] { body(a + u * t + n * offset * side, yaw + (side < 0 ? 0 : 180), k) }
                k += 1
            }
        }
        for (a, b, w) in paths {
            along(nodes[a]!, nodes[b]!, every: 30, offset: w / 2 + 0.6) { p, yaw, k in
                if k % 2 == 0 { lamps.append(place(p.x, p.y, y: y(p)).matrix) }
                else { benches.append(place(p.x, p.y, y: y(p), yaw: yaw).matrix) }
                if k % 4 == 1 { bins.append(place(p.x + 1.4, p.y, y: y(p)).matrix) }
            }
            along(nodes[a]!, nodes[b]!, every: 26, offset: w / 2 + 5) { p, _, _ in
                if rng.float() < 0.7 { elms.append(place(p.x, p.y, y: y(p) - 0.1, yaw: rng.float(0...360), scale: rng.float(0.8...1.1)).matrix) }
            }
        }
        along(V2(-200, -178), V2(200, -178), every: 14, offset: 6) { p, _, _ in
            elms.append(place(p.x, p.y, y: y(p) - 0.1, yaw: rng.float(0...360), scale: rng.float(0.85...1.1)).matrix)
        }
        along(V2(198, -170), V2(198, 178), every: 14, offset: 6) { p, _, _ in
            if p.x < half.x - 2 { elms.append(place(p.x, p.y, y: y(p) - 0.1, yaw: rng.float(0...360), scale: rng.float(0.85...1.1)).matrix) }
        }
        for x in stride(from: Float(-200), through: 200, by: 24) {
            lamps.append(place(x, -half.y - 1.5, y: y(V2(x, -half.y))).matrix)
        }
        scene.field(BostonAcornLamp(), seed: seed &+ 22, transforms: lamps, options: .props)
        scene.field(ParkBench(), seed: seed &+ 23, transforms: benches, options: .props)
        scene.field(TrashCan(), seed: seed &+ 24, transforms: bins, options: .props)

        // Open-lawn specimen trees, kept off paths and landmarks.
        let keepOut: [(V2, Float)] = [(nodes["pond"]!, 40), (nodes["band"]!, 14), (hill, 12), (nodes["fountain"]!, 14), (V2(165, 165), 45)]
        let lawnTrees = Scatter.poisson(count: 140, outerRadius: 260, innerRadius: 0, minSpacing: 16, seed: seed &+ 25) { p in
            abs(p.x) < half.x - 8 && abs(p.y) < half.y - 8 && simd_distance(p, V2(192, -118)) > 25 && !keepOut.contains { simd_distance(p, $0.0) < $0.1 }
        }
        var oaks: [simd_float4x4] = [], maples: [simd_float4x4] = []
        for p in lawnTrees {
            let m = place(p.x, p.y, y: y(p) - 0.1, yaw: rng.float(0...360), scale: rng.float(0.85...1.15)).matrix
            let r = rng.float()
            if r < 0.5 { elms.append(m) } else if r < 0.75 { oaks.append(m) } else { maples.append(m) }
        }
        let clear: [(V2, Float)] = keepOut + [(V2(192, -118), 14), (V2(178, -128), 8), (V2(192, -160), 14), (V2(60, -184), 9)]
        elms.removeAll { m in clear.contains { simd_distance(V2(m.columns.3.x, m.columns.3.z), $0.0) < $0.1 } }
        scene.field(AmericanElm(), seed: seed &+ 26, transforms: elms, options: .trees)
        scene.field(OakTree(), seed: seed &+ 27, transforms: oaks, options: .trees)
        scene.field(MapleTree(), seed: seed &+ 28, transforms: maples, options: .trees)

        // Lawn cover near the camera.
        let eye = V2(192, -118)
        let grass = Scatter.uniform(count: 18000, outerRadius: 45, seed: seed &+ 29) { q in
            let p = q + eye
            return simd_distance(p, nodes["fountain"]!) > 8 && abs(p.y + 150) > 3 && abs(p.y + 178) > 4 && abs(p.x - 198) > 4
        }.map { $0 + eye }
        scene.field(GrassClump().with { $0.height = 0.12; $0.width = 0.3 }, seed: seed &+ 30, transforms: grass.map {
            place($0.x, $0.y, y: y($0) - 0.02, yaw: rng.float(0...360), scale: rng.float(0.7...1.3)).matrix
        }, options: .groundCover(cull: 40))
        let leaves = elms.prefix(80).flatMap { m -> [simd_float4x4] in
            (0..<2).map { _ in
                let p = V2(m.columns.3.x + rng.float(-3...3), m.columns.3.z + rng.float(-3...3))
                return place(p.x, p.y, y: y(p), yaw: rng.float(0...360), scale: rng.float(1...1.6)).matrix
            }
        }
        scene.field(LeafLitter(), seed: seed &+ 31, transforms: leaves, options: .groundCover(cull: 60))

        scene.farGround = "ground.meadow"
        scene.lighting = .init(sky: SunSky(elevation: 34, azimuth: 200, turbidity: 2.2), fog: 0.0008)
        let e = V3(eye.x, y(eye) + 1.65, eye.y)
        scene.camera = .init(eye: e, target: V3(90, 16, -230), fov: 66)
        return scene
    }
}
