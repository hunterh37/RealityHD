#if canImport(RealityKit)
import Foundation
import RealityKit
import RealCore
import RealKit

/// Live controller for a `halogen-siphon-bar` entity built with `RealityHD.articulated` or
/// `scene.addLive`: key taps press the key 1.8 mm and feed `SiphonBarController`; a 10 Hz loop advances
/// the timers and water temperature, lights the segments of both red displays and the halogen lamps
/// (orange lens glow plus a point light scaled by output).
///
/// ```swift
/// let bar = try await RealityHD.articulated("halogen-siphon-bar", grabbable: true)
/// let live = HalogenSiphonBarRuntime(root: bar)!; live.start()
/// // tap gesture: if live.handleTap(value.entity) { return } else { value.entity.realToggle() }
/// ```
@MainActor
public final class HalogenSiphonBarRuntime {
    public private(set) var controller = SiphonBarController()
    /// Articulated root of the bar.
    public let root: Entity
    /// Simulation speed (1 = real time). The scripted brew runs faster.
    public var timeScale: Double = 1
    /// Called after every key press and tick with the new state.
    public var onChange: ((SiphonBarController) -> Void)?

    private var task: Task<Void, Never>?
    private var shownMasks: [String: [UInt8]] = [:]
    private var shownLamp: [String: Float] = [:]
    private var baseIntensity: [String: Float] = [:]
    private let keyTravel: Float
    static let sides = ["left", "right"]

    public init?(root: Entity, keyTravel: Float = HalogenSiphonBar().keyTravel) {
        guard let r = root.articulationRoot ?? (root.components.has(RealArticulationComponent.self) ? root : nil),
              r.realJoint("left-heat") != nil else { return nil }
        self.root = r
        self.keyTravel = keyTravel
        for s in Self.sides {
            if let l = r.realLight("\(s)-halogen"), let p = l.components[PointLightComponent.self] { baseIntensity[s] = p.intensity }
        }
        r.setOptions(["left-display": 0, "right-display": 0])
        refresh()
    }

    /// Starts the 10 Hz simulation loop.
    public func start() {
        task?.cancel()
        task = Task { [weak self] in
            var last = Date()
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100))
                guard let self else { return }
                let now = Date()
                self.controller.tick(now.timeIntervalSince(last) * self.timeScale)
                last = now
                self.refresh()
            }
        }
    }

    public func stop() { task?.cancel(); task = nil }

    /// Handles a tap on any entity. Returns true when it hit a key of this bar.
    @discardableResult
    public func handleTap(_ entity: Entity) -> Bool {
        var e: Entity? = entity
        while let c = e, c !== root {
            if let j = c.components[RealJointComponent.self], c.articulationRoot === root {
                guard SiphonBurner.Key(rawValue: String(j.name.split(separator: "-").last ?? "")) != nil,
                      !j.name.contains("-seg") else { return false }
                press(j.name)
                return true
            }
            e = c.parent
        }
        return false
    }

    /// Presses key part `part` ("left-heat"): animates it in and out and updates the model.
    public func press(_ part: String) {
        guard controller.press(part: part) else { return }
        root.setJoints([part: keyTravel])
        Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(160))
            self?.root.setJoints([part: 0])
        }
        refresh()
    }

    /// Pushes the model to the segments, lamp glow and lights.
    public func refresh() {
        var options: [String: Int] = [:]
        for side in Self.sides {
            let burner = controller[side]
            let masks = burner.segmentMasks
            if shownMasks[side] != masks {
                shownMasks[side] = masks
                for d in 0..<4 { for b in 0..<7 {
                    options[HalogenSiphonBar.segmentPart(side, digit: d, bit: b)] = masks[d] & (1 << UInt8(b)) != 0 ? 1 : 0
                }}
            }
            let lamp = burner.lampLevel
            if shownLamp[side] != lamp {
                shownLamp[side] = lamp
                options["\(side)-burner"] = lamp > 0 ? 1 : 0
                if lamp > 0, let base = baseIntensity[side], let l = root.realLight("\(side)-halogen"), var p = l.components[PointLightComponent.self] {
                    p.intensity = base * (0.35 + 0.65 * lamp) * 2.5
                    l.components.set(p)
                }
                if let glow = root.optionEntity(part: "\(side)-burner", index: 1) {
                    glow.scale = SIMD3(repeating: 0.75 + 0.25 * lamp)
                }
            }
        }
        if !options.isEmpty { root.setOptions(options) }
        onChange?(controller)
    }

    /// Grab box over the stainless chassis only, so keys, globes and flasks above and in front of it
    /// keep their own tap and grab targets.
    public func limitGrabToChassis(_ bar: HalogenSiphonBar = HalogenSiphonBar()) {
        let b = bar.body
        root.makeGrabbable(min: SIMD3(-b.x / 2, 0, -b.z / 2), max: SIMD3(b.x / 2, b.y, b.z / 2))
    }

    /// Moves `globe` (an entity under the bar root, or anywhere) into the clamp of `station` over `duration`.
    public func placeGlobe(_ globe: Entity, station: Int, duration: TimeInterval = 1.6) {
        let tip = HalogenSiphonBar().globeStemTip(station)
        var t = Transform(matrix: root.transformMatrix(relativeTo: nil) * Transform(translation: SIMD3(tip.x, tip.y, tip.z)).matrix)
        t.scale = globe.scale(relativeTo: nil)
        globe.move(to: t, relativeTo: nil, duration: duration, timingFunction: .easeInOut)
    }

    /// Scripted brew on one station: output 8, time 1:00, heat to boil, globe in, extract, keep warm.
    /// `speed` scales the simulated clock while it runs; `globe` is moved into the clamp at the boil.
    public func runBrew(side: String = "left", globe: Entity? = nil, speed: Double = 6) async {
        let previous = timeScale
        timeScale = speed
        defer { timeScale = previous }
        func tap(_ k: String, _ ms: Int = 450) async { press("\(side)-\(k)"); try? await Task.sleep(for: .milliseconds(ms)) }
        await tap("stop")
        await tap("out")
        while controller[side].output < 8 { await tap("up", 300) }
        while controller[side].output > 8 { await tap("down", 300) }
        await tap("time")
        while controller[side].brewTime < 60 { await tap("up", 200) }
        while controller[side].brewTime > 60 { await tap("down", 200) }
        // The globe comes out while the water heats (it sits tilted in the flask in a real cafe).
        if let globe {
            var lifted = globe.transform
            lifted.translation.y += 0.12
            lifted.rotation = simd_quatf(angle: 0.35, axis: SIMD3(0, 0, 1)) * lifted.rotation
            globe.move(to: lifted, relativeTo: globe.parent, duration: 1.2, timingFunction: .easeInOut)
        }
        await tap("heat", 800)
        while !controller[side].boiling, controller[side].mode == .heating {
            try? await Task.sleep(for: .milliseconds(200))
            if Task.isCancelled { return }
        }
        if let globe { placeGlobe(globe, station: side == "left" ? 0 : 1); try? await Task.sleep(for: .milliseconds(1800)) }
        await tap("brew")
        while controller[side].mode == .extracting {
            try? await Task.sleep(for: .milliseconds(200))
            if Task.isCancelled { return }
        }
        try? await Task.sleep(for: .seconds(2))
        await tap("warm")
    }
}
#endif
