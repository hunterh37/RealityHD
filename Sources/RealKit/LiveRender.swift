import Foundation
import Metal
import QuartzCore
import RealityKit
import simd

/// Decides when a live secondary render (a camera LCD, a mirror, a portal) needs a new frame.
///
/// A second `RealityRenderer` re-submits the whole scene on the main actor every call. When the view
/// has not moved, the only change is shader time (wind), so the pacer drops to `staticInterval`
/// instead of rendering at the moving rate. Animated content (`animated: true`) always renders.
public struct RealLivePacer: Sendable {
    /// Minimum seconds between renders while the view moves. 0 renders on every call.
    public var movingInterval: Double
    /// Minimum seconds between renders while the view is unchanged.
    public var staticInterval: Double
    private var lastKey: SIMD8<Float>?
    private var lastRender: Double = -.infinity

    public init(movingInterval: Double = 0, staticInterval: Double = 0.1) {
        self.movingInterval = movingInterval
        self.staticInterval = staticInterval
    }

    /// `key` is any value that changes when the picture changes (eye, forward, FOV, roll).
    public mutating func shouldRender(key: SIMD8<Float>, animated: Bool = false, now: Double = CACurrentMediaTime()) -> Bool {
        let moved = lastKey.map { simd_distance_squared($0, key) > 1e-8 } ?? true
        let interval = (moved || animated) ? movingInterval : staticInterval
        guard now - lastRender >= interval else { return false }
        lastKey = key
        lastRender = now
        return true
    }

    /// Forces the next `shouldRender` to pass (scene edit, resize).
    public mutating func invalidate() { lastKey = nil; lastRender = -.infinity }
}

extension RealPreview {
    /// Renders one frame into `target` (rgba16Float, render-target usage) and waits for the GPU
    /// completion callback without blocking the main actor.
    public func renderLive(into target: MTLTexture, deltaTime: Double = 1.0 / 30) async {
        guard let out = try? RealityRenderer.CameraOutput(.singleProjection(colorTexture: target)) else { return }
        await withCheckedContinuation { (c: CheckedContinuation<Void, Never>) in
            do { try renderer.updateAndRender(deltaTime: deltaTime, cameraOutput: out, onComplete: { _ in c.resume() }) }
            catch { c.resume() }
        }
    }
}
