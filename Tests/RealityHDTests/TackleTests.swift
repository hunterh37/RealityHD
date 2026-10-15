import Testing
import simd
@testable import RealCore
@testable import RealLibrary

/// Tackle pack contract (MulberryRiver): ids, rod parts, reel parts and states, anchors near the geometry.
@Suite struct TackleTests {
    static let rods = ["rod-spinning", "rod-baitcasting", "rod-fly", "rod-spincast", "rod-ultralight", "rod-cranking", "rod-flipping", "rod-catfish",
                       "rod-float", "rod-surf", "rod-telescopic", "rod-ice", "rod-trolling", "rod-tenkara"]
    static let reels = ["reel-spinning", "reel-baitcast", "reel-fly", "reel-spincast", "reel-round-baitcast", "reel-conventional", "reel-centerpin",
                        "reel-ice", "reel-surf-spinning"]
    /// Moving parts per reel (spincast has an enclosed spool; centerpin knobs turn the spool directly).
    static let reelPartNames: [String: [String]] = [
        "reel-spincast": ["body", "button", "handle"], "reel-centerpin": ["body", "spool", "check"],
        "reel-conventional": ["body", "spool", "handle", "lever"], "reel-ice": ["body", "spool", "handle", "trigger"],
        "reel-surf-spinning": ["body", "spool", "handle", "rotor", "bail"],
    ]
    static let anchors: [String: [String]] = [
        "rod-spinning": ["reelFoot", "tipTop", "butt"], "rod-baitcasting": ["reelFoot", "tipTop", "butt"], "rod-fly": ["reelFoot", "tipTop", "butt"],
        "rod-blank-graphite": ["butt", "tipTop"], "rod-blank-fiberglass": ["butt", "tipTop"], "rod-blank-bamboo": ["butt", "tipTop"],
        "rod-handle-cork": ["butt", "blankButt", "seatRear", "reelFoot"], "rod-handle-eva": ["butt", "blankButt", "seatRear", "reelFoot"],
        "rod-handle-split-grip": ["butt", "blankButt", "seatRear", "reelFoot"],
        "rod-seat-aluminum": ["rear", "front", "reelFoot"], "rod-seat-wood-insert": ["rear", "front", "reelFoot"],
        "reel-spinning": ["reelFoot", "lineOut"], "reel-baitcast": ["reelFoot", "lineOut"], "reel-fly": ["reelFoot", "lineOut"],
        "rod-spincast": ["reelFoot", "tipTop", "butt"], "rod-ultralight": ["reelFoot", "tipTop", "butt"], "rod-cranking": ["reelFoot", "tipTop", "butt"],
        "rod-flipping": ["reelFoot", "tipTop", "butt"], "rod-catfish": ["reelFoot", "tipTop", "butt"], "rod-float": ["reelFoot", "tipTop", "butt"],
        "rod-surf": ["reelFoot", "tipTop", "butt"], "rod-telescopic": ["reelFoot", "tipTop", "butt"], "rod-ice": ["reelFoot", "tipTop", "butt"],
        "rod-trolling": ["reelFoot", "tipTop", "butt"], "rod-tenkara": ["reelFoot", "tipTop", "butt"],
        "reel-spincast": ["reelFoot", "lineOut"], "reel-round-baitcast": ["reelFoot", "lineOut"], "reel-conventional": ["reelFoot", "lineOut"],
        "reel-centerpin": ["reelFoot", "lineOut"], "reel-ice": ["reelFoot", "lineOut"], "reel-surf-spinning": ["reelFoot", "lineOut"],
        "lure-crankbait": ["lineTie"], "lure-soft-craw": ["lineTie"], "lure-inline-spinner": ["lineTie"],
        "lure-topwater-popper": ["lineTie"], "lure-jig": ["lineTie"],
    ]

    @Test(arguments: Array(anchors.keys))
    func anchorsExistAndSitOnTheAsset(_ id: String) throws {
        let t = try #require(Catalog.type(id) as? any RealAnchored.Type, "\(id) must be RealAnchored")
        #expect(t.tags.contains("handheld"))
        let b = t.init().build(seed: 1).levels[0].bounds
        for name in Self.anchors[id]! {
            let a = try #require(t.anchors[name], "\(id) missing anchor \(name)")
            let tol: Float = 0.01
            let lo = b.min - SIMD3(repeating: tol), hi = b.max + SIMD3(repeating: tol), q = a.position
            #expect(q.x >= lo.x && q.y >= lo.y && q.z >= lo.z && q.x <= hi.x && q.y <= hi.y && q.z <= hi.z, "\(id).\(name) outside bounds")
        }
    }

    @Test(arguments: rods)
    func rodParts(_ id: String) throws {
        let t = try #require(Catalog.type(id) as? any RealArticulated.Type)
        let rig = t.init().rig(seed: 1)
        for p in ["blank", "handle", "reel-seat", "guides", "tip-top"] { #expect(rig.index(p) != nil, "\(id) missing part \(p)") }
    }

    @Test(arguments: reels)
    func reelParts(_ id: String) throws {
        let t = try #require(Catalog.type(id) as? any RealArticulated.Type)
        let rig = t.init().rig(seed: 1)
        for p in Self.reelPartNames[id] ?? ["body", "spool", "handle"] { #expect(rig.index(p) != nil, "\(id) missing part \(p)") }
        if id == "reel-spinning" { #expect(rig.index("bail") != nil && rig.stateNames.contains("open") && rig.stateNames.contains("closed")) }
    }

    /// Every new rod/reel pair the app offers joins foot to foot with the reel standing off the rod's reel side.
    @Test(arguments: ["reel-spincast", "reel-round-baitcast", "reel-conventional", "reel-centerpin", "reel-ice", "reel-surf-spinning"])
    func reelMountsOnSeat(_ id: String) throws {
        let t = try #require(Catalog.type(id) as? any RealAnchored.Type)
        let foot = try #require(t.anchors["reelFoot"]), rod = RodSurf.anchors["reelFoot"]!
        let x = RealityHD.mount(foot, on: rod)
        #expect(simd_dot(x.rotation.act(foot.direction), rod.direction) < -0.999)
        let b = t.init().build(seed: 1).levels[0].bounds
        #expect(abs(foot.position.y - b.min.y) < 0.002, "\(id): reel foot underside at the bottom of the reel")
    }

    @Test func mountJoinsOpposedAnchors() {
        let rod = RodSpinning.anchors["reelFoot"]!, reel = ReelSpinning.anchors["reelFoot"]!
        let x = RealityHD.mount(reel, on: rod)
        let p = x.matrix * SIMD4(reel.position, 1)
        #expect(simd_distance(SIMD3(p.x, p.y, p.z), rod.position) < 1e-4)
        #expect(simd_dot(x.rotation.act(reel.direction), rod.direction) < -0.999)
    }
}
