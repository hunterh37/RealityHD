import simd
import Foundation
import RealityKit
import RealKit

/// Supermarket interior, 20 x 14 m with a 3.6 m drop ceiling. Store frame: x -10...10, z -12 (back wall)
/// to +2 (front wall with the entrance), floor at y = 0. Polished vinyl tile floor, painted walls, lay-in
/// ceiling with LED panels. Produce tables front-left; four double-sided gondola runs at x = -3, -1, 1, 3
/// from z -3 to -10 with endcaps at both ends, making aisles centered at x = -4, -2, 0, 2, 4; numbered
/// hanging aisle signs; an open multideck dairy wall along the back (z = -11.5); a glass-door freezer row
/// on the east wall; three checkout lanes front-right; carts and baskets by the entrance; shelf talkers;
/// department lettering. Layout constants are public statics and documented in docs/scenes/grocery-store.md.
public struct GroceryStore: RealSceneBuilder {
    public static let id = "grocery-store"
    public static let summary = "Supermarket, 20 x 14 m: produce tables, four stocked gondola runs with endcaps and aisle signs, dairy wall, freezers, three checkouts."
    public static let tags = ["grocery", "retail", "commercial", "interior", "showcase"]
    public static let author = "realityhd"

    /// Interior size (x, ceiling height, z).
    public var size = V3(20, 3.6, 14)
    /// Stock fill on every gondola, endcap, dairy case and freezer (0 empty to 1 full).
    public var stockFill: Float = 0.96
    /// Facings deep behind each front facing, 1...6 (6 runs to the back of the shelf).
    public var stockDepth: Int = 6
    /// Facing spacing: 0 loose gaps, 0.5 the original spacing, 1 shoulder to shoulder and end to end.
    public var packing: Float = 0.85
    /// Case-pack cartons on the gondola tops (y 1.8) plus stocking carts and a wrapped pallet in the back
    /// cross aisle (z about -10.5), clear of the aisle centers.
    public var overstock = false
    public init() {}

    /// Room center in the store frame (the back wall is at z = -12, the front wall at z = +2).
    public static let roomCenter = V2(0, -5)
    /// Gondola run centerlines (x) and aisle centers between and beside them.
    public static let gondolaRowX: [Float] = [-3, -1, 1, 3]
    public static let aisleCenterX: [Float] = [-4, -2, 0, 2, 4]
    /// Runs span z -3 (front endcap face) to -10 (back endcap face): endcaps 0.5 m, five 1.2 m sections.
    public static let runFrontZ: Float = -3, runBackZ: Float = -10
    public static let sectionLength: Float = 1.2, sectionsPerRun = 5, endcapDepth: Float = 0.5
    /// Dairy wall: case centers on z = -11.5, ten 1.2 m sections centered on x = 0.
    public static let dairyZ: Float = -11.5, dairySections = 10
    /// Freezer row on the east wall, doors facing -X.
    public static let freezerX: Float = 9.55, freezerZ: [Float] = [-10.1, -8.5, -6.9, -5.3]
    /// Checkout lane centers (x) on z = -1.5; belts run toward the front, bagging at the +z end.
    public static let checkoutX: [Float] = [4.4, 6.6, 8.8], checkoutZ: Float = -1.5
    /// Produce tables (yawed 90 degrees, long side along z).
    public static let produceTables: [V2] = [V2(-8.2, -1.4), V2(-5.6, -1.4), V2(-8.2, -3.6), V2(-5.6, -3.6), V2(-8.2, -5.8), V2(-5.6, -5.8)]
    /// Entrance opening on the front wall: center x and width.
    public static let entranceX: Float = -1.5, entranceWidth: Float = 3.0
    /// Shelf top heights on each gondola face.
    public static let shelfHeights: [Float] = [0.15, 0.55, 0.95, 1.35]

    public func build(seed: UInt64) -> RealScene {
        var scene = RealScene(name: Self.id)
        var rng = SeededRNG(seed: seed &+ 77)
        let W = size.x, H = size.y, D = size.z
        let rc = Self.roomCenter
        func at(_ x: Float, _ z: Float, y: Float = 0, yaw: Float = 0) -> Xform { place(x, z, y: y, yaw: yaw) }

        // ---- Shell: floor, walls, openings, drop ceiling with LED panels.
        var room = Room(size: size)
        room.floor = "floor.grocery-vct"
        room.wall = "paint.wall:ECEAE4"
        room.skirting = "laminate.white:3A3D42"
        room.skirtingHeight = 0.12
        room.ceiling = .grid(pitch: 0.6)
        room.openings = [
            .init(.south, offset: Self.entranceX, width: Self.entranceWidth, sill: 0, head: 2.5),
            .init(.south, offset: -6.5, width: 4.0, sill: 0.9, head: 2.7),
            .init(.south, offset: 6.6, width: 5.0, sill: 0.9, head: 2.7),
        ]
        room.fixtureCells = room.fixturePattern(every: SIMD2(4, 3), inset: 1.0)
        scene.add(room.shell(), at: at(rc.x, rc.y), bake: true)
        scene.add(room.ceilingModel(), at: at(rc.x, rc.y))
        scene.field(CeilingLight(), seed: seed, state: "on", transforms: room.fixtureCells.sorted { ($0.x, $0.y) < ($1.x, $1.y) }.map {
            let c = room.cellCenter($0); return place(c.x + rc.x, c.z + rc.y, y: H).matrix
        })

        // Storefront glazing, entrance sliding doors parked open, mullions.
        var front = Model(name: "storefront")
        let fz = rc.y + D / 2
        for op in room.openings {
            let bottom = op.sill, top = op.head
            if op.sill > 0 {
                GroceryKit.box(&front, V3(op.width, top - bottom, 0.012), V3(op.offset, (bottom + top) / 2, fz), "glass.pane", r: 0.002)
            } else {
                for s: Float in [-1, 1] {
                    GroceryKit.box(&front, V3(op.width * 0.3, top - 0.05, 0.012), V3(op.offset + s * op.width * 0.38, (top - 0.05) / 2, fz - 0.08), "glass.pane", r: 0.002)
                }
                GroceryKit.box(&front, V3(op.width, 0.25, 0.25), V3(op.offset, top - 0.125, fz - 0.12), "metal.anodized", r: 0.01)
            }
            var x = op.offset - op.width / 2
            while x <= op.offset + op.width / 2 + 0.01 {
                GroceryKit.box(&front, V3(0.05, top - bottom, 0.1), V3(x, (bottom + top) / 2, fz), "metal.anodized", r: 0.004)
                x += op.sill > 0 ? op.width / 2 : op.width
            }
            GroceryKit.box(&front, V3(op.width, 0.05, 0.1), V3(op.offset, top - 0.025, fz), "metal.anodized", r: 0.004)
        }
        GroceryKit.box(&front, V3(2.4, 0.01, 1.4), V3(Self.entranceX, 0.005, fz - 0.9), "rubber.floor-mat", r: 0.003)
        scene.add(front)

        // ---- Produce zone (front-left).
        for (i, p) in Self.produceTables.enumerated() {
            scene.add(ProduceDisplayTable(), at: at(p.x, p.y, yaw: 90), seed: seed &+ UInt64(10 + i))
        }

        // ---- Gondola runs with endcaps.
        let cats: [GroceryGondola.Category] = [.breakfast, .dry, .canned, .snack]
        let runStart = Self.runFrontZ - Self.endcapDepth
        for (ri, gx) in Self.gondolaRowX.enumerated() {
            var even: [simd_float4x4] = [], odd: [simd_float4x4] = []
            for k in 0..<Self.sectionsPerRun {
                let z = runStart - Self.sectionLength * (Float(k) + 0.5)
                if k % 2 == 0 { even.append(at(gx, z, yaw: 90).matrix) } else { odd.append(at(gx, z, yaw: 90).matrix) }
            }
            let cat = ri == 3 ? GroceryGondola.Category.snack : cats[ri]
            scene.field(GroceryGondola().with { $0.category = cat; stock(&$0) }, seed: seed &+ UInt64(100 + ri * 2), transforms: even, options: .props)
            scene.field(GroceryGondola().with { $0.category = ri == 3 ? .household : cat; stock(&$0) }, seed: seed &+ UInt64(101 + ri * 2), transforms: odd, options: .props)
            let backZ = runStart - Self.sectionLength * Float(Self.sectionsPerRun)
            scene.add(GondolaEndcap().with { $0.price = ["2/$5", "$3.99", "4/$6", "$1.99"][ri]; stock(&$0) }, at: at(gx, runStart + Self.endcapDepth / 2), seed: seed &+ UInt64(120 + ri))
            scene.add(GondolaEndcap().with { stock(&$0); $0.headline = "NEW"; $0.price = ["$4.49", "2/$7", "$2.49", "$5.99"][ri] },
                      at: at(gx, backZ - Self.endcapDepth / 2, yaw: 180), seed: seed &+ UInt64(130 + ri))
            // Shelf talkers on a few lips, sticking into the aisles.
            for _ in 0..<3 {
                let k = rng.int(0...(Self.sectionsPerRun - 1))
                let z = runStart - Self.sectionLength * (Float(k) + 0.5) + rng.float(-0.4...0.4)
                let sy = Self.shelfHeights[rng.int(1...3)] - 0.02
                let side: Float = rng.chance(0.5) ? 1 : -1
                let lip = gx + side * 0.446
                scene.add(SaleSign().with { $0.price = "$" + String(format: "%.2f", Float(rng.int(99...599)) / 100) },
                          at: at(lip + side * 0.0605, z, y: sy - 0.075, yaw: side > 0 ? 0 : 180), seed: seed &+ UInt64(rng.int(0...999)))
            }
        }

        if overstock { addOverstock(&scene, seed: seed) }

        // Hanging aisle signs over each aisle.
        let lines: [[String]] = [["BREAKFAST", "CEREAL", "COFFEE & TEA"], ["BAKING", "PASTA", "RICE & BEANS"], ["CANNED GOODS", "SOUP", "CONDIMENTS"],
                                 ["SNACKS", "CHIPS", "SODA & WATER"], ["HOUSEHOLD", "PAPER GOODS", "CLEANING"]]
        for (i, ax) in Self.aisleCenterX.enumerated() {
            scene.add(GroceryAisleSign().with { $0.number = i + 1; $0.lines = lines[i]; $0.hangerLength = H - 2.6 - 0.5 },
                      at: at(ax, -6.5, y: 2.6), seed: seed &+ UInt64(140 + i))
        }

        // ---- Dairy wall (back).
        let dairy = RefrigeratedCase().with { $0.endPanels = false; $0.fill = stockFill; $0.stockDepth = stockDepth; $0.packing = packing }
        let dx = (0..<Self.dairySections).map { at(Self.sectionLength * (Float($0) - Float(Self.dairySections - 1) / 2), Self.dairyZ).matrix }
        scene.field(dairy, seed: seed &+ 200, transforms: dx.enumerated().filter { $0.offset % 2 == 0 }.map { $0.element }, options: .props)
        scene.field(dairy, seed: seed &+ 201, transforms: dx.enumerated().filter { $0.offset % 2 == 1 }.map { $0.element }, options: .props)
        for s: Float in [-1, 1] {
            var cap = Model(name: "dairy-end")
            GroceryKit.box(&cap, V3(0.06, 2.0, 0.95), V3(0, 1.0, 0), "metal.powder-white", r: 0.01)
            scene.add(cap, at: at(s * (Self.sectionLength * Float(Self.dairySections) / 2 + 0.03), Self.dairyZ))
        }

        // ---- Freezer row (east wall), one bay with its doors open.
        for (i, z) in Self.freezerZ.enumerated() {
            scene.addLive(FreezerCase().with { $0.fill = stockFill; $0.stockDepth = stockDepth; $0.packing = packing }, at: at(Self.freezerX, z, yaw: -90), seed: seed &+ UInt64(220 + i), state: i == 2 ? "left-open" : "closed")
        }

        // ---- Checkout lanes (front-right): belts toward the front, bagging at +z.
        for (i, x) in Self.checkoutX.enumerated() {
            scene.add(CheckoutLane().with { $0.laneNumber = i + 1 }, at: at(x, Self.checkoutZ, yaw: -90), seed: seed &+ UInt64(240 + i))
        }
        // A few items waiting on the first belt.
        let bx = Self.checkoutX[0], belt: Float = 0.86
        scene.add(BananaBunch(), at: at(bx - 0.03, -2.75, y: belt, yaw: 85), seed: seed &+ 249)
        scene.add(SodaCan(), at: at(bx, -2.5, y: belt), seed: seed &+ 250)
        scene.add(JuiceCarton(), at: at(bx + 0.05, -2.3, y: belt, yaw: 80), seed: seed &+ 251)
        scene.add(CookiePack(), at: at(bx - 0.02, -2.05, y: belt, yaw: 95), seed: seed &+ 252)
        scene.add(KetchupBottle(), at: at(bx + 0.1, -1.85, y: belt, yaw: 70), seed: seed &+ 253)

        // ---- Carts nested by the entrance, baskets stacked.
        let carts = (0..<6).map { at(Self.entranceX - 3.2 + Float($0) * 0.26, 1.15, yaw: 90).matrix }
        scene.field(ShoppingCart(), seed: seed &+ 260, state: "folded", transforms: carts)
        scene.addLive(ShoppingCart(), at: at(-0.4, -1.2, yaw: 200), seed: seed &+ 261, state: "seat-open")
        scene.field(ShoppingBasket(), seed: seed &+ 262, transforms: (0..<5).map { at(Self.entranceX + 2.0, 1.3, y: Float($0) * 0.045).matrix })

        // ---- Department lettering on the walls.
        var signs = Model(name: "department-signs")
        GroceryKit.print(&signs, "DAIRY", height: 0.42, at: V3(0, 2.55, rc.y - D / 2 + 0.01), "plastic.matte:1F4E96")
        GroceryKit.print(&signs, "PRODUCE", height: 0.42, at: V3(-W / 2 + 0.01, 2.55, -3.6), "plastic.matte:2F7D45", rot: simd_quatf(degrees: 90, axis: .up))
        GroceryKit.print(&signs, "FROZEN", height: 0.42, at: V3(W / 2 - 0.01, 2.6, -7.7), "plastic.matte:2E73C8", rot: simd_quatf(degrees: -90, axis: .up))
        scene.add(signs)

        scene.farGround = "concrete.sidewalk"
        scene.lighting = .init(sky: SunSky(elevation: 38, azimuth: 160, turbidity: 2.4), interior: InteriorLight.office.with {
            $0.floor = SIMD3(0.46, 0.45, 0.43); $0.walls = SIMD3(0.55, 0.54, 0.51); $0.fixtures = SIMD3(6.2, 6.1, 5.9)
            $0.windowAzimuth = 180; $0.windowWidth = 120
        }, fog: 0)
        scene.bake = .interior
        scene.batchStatics = true
        scene.camera = .init(eye: V3(5.6, 1.65, 0.6), target: V3(-1.5, 1.1, -8.5), fov: 70)
        return scene
    }

    func stock(_ g: inout GroceryGondola) { g.fill = stockFill; g.stockDepth = stockDepth; g.packing = packing }
    func stock(_ e: inout GondolaEndcap) { e.fill = min(1, stockFill + 0.02); e.stockDepth = stockDepth; e.packing = packing }

    /// Case-pack cartons on the gondola tops, two stocking carts and a wrapped pallet in the back cross aisle.
    func addOverstock(_ scene: inout RealScene, seed: UInt64) {
        var rng = SeededRNG(seed: seed &+ 911)
        var tops = Model(name: "overstock-tops")
        let brands = ["GREENFIELD", "SALTWELL", "MILLSTONE", "TRAILCREST", "NONNA ROSA", "BRIGHTWAVE", "SOFTCLOUD", "CANEBROOK"]
        let runStart = Self.runFrontZ - Self.endcapDepth
        let runLen = Self.sectionLength * Float(Self.sectionsPerRun)
        for gx in Self.gondolaRowX {
            // A thin deck over the header strip carries the cases.
            GroceryKit.box(&tops, V3(0.62, 0.012, runLen - 0.04), V3(gx, 1.806, runStart - runLen / 2), "metal.powdercoat:3A3E44", r: 0.003)
            var z = runStart - 0.04
            while z > runStart - runLen + 0.3 {
                let s = V3(rng.float(0.38...0.56), rng.float(0.2...0.34), rng.float(0.3...0.46))
                if rng.chance(0.85) {
                    let c = V3(gx + rng.float(-0.04...0.04), 1.812, z - s.x / 2)
                    var one = Model(name: "case")
                    GroceryKit.caseCarton(&one, size: s, at: .zero, brand: brands[rng.int(0...(brands.count - 1))], rng: &rng)
                    tops.add(one, Xform(translation: c, rotation: simd_quatf(degrees: 90 + rng.float(-3...3), axis: .up)))
                    if rng.chance(0.3) && s.y < 0.28 {
                        var two = Model(name: "case")
                        let s2 = V3(s.x * 0.9, rng.float(0.16...0.26), s.z * 0.9)
                        GroceryKit.caseCarton(&two, size: s2, at: .zero, brand: brands[rng.int(0...(brands.count - 1))], rng: &rng)
                        tops.add(two, Xform(translation: c + V3(0, s.y, 0), rotation: simd_quatf(degrees: 90 + rng.float(-6...6), axis: .up)))
                    }
                }
                z -= s.x + rng.float(0.02...0.12)
            }
        }
        scene.add(tops)

        // Back cross aisle (z -10 to -11): carts on the gondola lines x = -3 and 1, pallet east of the runs.
        var back = Model(name: "overstock-back")
        for cx: Float in [-3, 1] {
            let base = V3(cx, 0, -10.5)
            GroceryKit.box(&back, V3(0.9, 0.04, 0.5), base + V3(0, 0.17, 0), "metal.powdercoat:1F4E96", r: 0.006)
            for sx: Float in [-1, 1] { for sz: Float in [-1, 1] {
                back.add(GroceryKit.cyl(0.05, 0.03, seg: 10, "rubber.tire:2A2A2A"), Xform(translation: base + V3(sx * 0.38, 0.05, sz * 0.2 - 0.015),
                         rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
                GroceryKit.box(&back, V3(0.03, 0.08, 0.03), base + V3(sx * 0.38, 0.11, sz * 0.2), "metal.chrome", r: 0.004)
            }}
            // Push handle at the -x end.
            for sz: Float in [-1, 1] { GroceryKit.box(&back, V3(0.025, 0.85, 0.025), base + V3(-0.44, 0.6, sz * 0.21), "metal.chrome", r: 0.008) }
            GroceryKit.box(&back, V3(0.025, 0.025, 0.45), base + V3(-0.44, 1.02, 0), "metal.chrome", r: 0.008)
            var y: Float = 0.19
            for _ in 0..<rng.int(2...3) {
                let s = V3(rng.float(0.36...0.42), rng.float(0.2...0.3), rng.float(0.38...0.46))
                for k in [-1, 1] as [Float] {
                    var one = Model(name: "case")
                    GroceryKit.caseCarton(&one, size: s, at: .zero, brand: brands[rng.int(0...(brands.count - 1))], rng: &rng)
                    back.add(one, Xform(translation: base + V3(k * 0.2, y, rng.float(-0.02...0.02)), rotation: simd_quatf(degrees: rng.float(-4...4), axis: .up)))
                }
                y += s.y
            }
        }
        // Wrapped pallet of cases at x = 6.4.
        let pb = V3(6.4, 0, -10.5)
        for i in 0..<3 { GroceryKit.box(&back, V3(1.0, 0.02, 0.1), pb + V3(0, 0.134, -0.34 + Float(i) * 0.34), "wood.pine-aged:9A6A3E", r: 0.002) }
        for i in 0..<3 { GroceryKit.box(&back, V3(0.1, 0.1, 0.8), pb + V3(-0.45 + Float(i) * 0.45, 0.07, 0), "wood.pine-aged:9A6A3E", r: 0.003) }
        for i in 0..<7 { GroceryKit.box(&back, V3(1.0, 0.02, 0.09), pb + V3(0, 0.146, -0.355 + Float(i) * 0.118), "wood.pine-aged:9A6A3E", r: 0.002) }
        var py: Float = 0.156
        for layer in 0..<4 {
            let h: Float = 0.27
            for ix in 0..<2 { for iz in 0..<2 {
                var one = Model(name: "case")
                GroceryKit.caseCarton(&one, size: V3(0.48, h, 0.38), at: .zero, brand: brands[(layer + ix + iz) % brands.count], rng: &rng)
                back.add(one, Xform(translation: pb + V3(-0.245 + Float(ix) * 0.49, py, -0.195 + Float(iz) * 0.39)))
            }}
            py += h
        }
        GroceryKit.box(&back, V3(1.0, py - 0.25, 0.8), pb + V3(0, 0.25 + (py - 0.25) / 2, 0), "plastic.translucent:E8ECEE", r: 0.02)
        scene.add(back)
    }
}
