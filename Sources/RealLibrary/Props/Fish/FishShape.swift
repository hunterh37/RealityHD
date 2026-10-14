import simd
import RealCore

/// Body plan for a procedural fish. Positions along the body use `s`, 0 at the snout and 1 at the caudal
/// fin base; all proportions are fractions of total length (snout to caudal tip) unless noted.
/// Asset frame while building: snout at x = 0, body extends toward -X, lateral axis Z, back toward +Y.
public struct FishShape: Sendable {
    public enum Caudal: Sendable { case forked(Float), emarginate, rounded, truncate }

    /// A median or paired fin. `start`/`end` are body positions of the base; `height` the longest ray
    /// as a fraction of length; `rake` sweeps the rays rearward (degrees); `notch` 0...1 dips the margin
    /// between spines; `split` > 0 makes a spiny/soft dorsal with a notch at that fraction of the base.
    public struct Fin: Sendable {
        public var start: Float, end: Float, height: Float, rake: Float
        public var peak: Float = 0.35, notch: Float = 0, rays: Int = 12, split: Float = 0, splitDepth: Float = 0.5
        public var round: Float = 0.5
        public init(_ start: Float, _ end: Float, height: Float, rake: Float, peak: Float = 0.35, notch: Float = 0,
                    rays: Int = 12, split: Float = 0, splitDepth: Float = 0.5, round: Float = 0.5) {
            self.start = start; self.end = end; self.height = height; self.rake = rake; self.peak = peak
            self.notch = notch; self.rays = rays; self.split = split; self.splitDepth = splitDepth; self.round = round
        }
    }

    public var length: Float = 0.3
    /// Snout to caudal base, fraction of total length.
    public var bodyFrac: Float = 0.82
    /// Maximum body depth (fraction of length) and where it sits along the body.
    public var depth: Float = 0.24
    public var maxAt: Float = 0.36
    /// Maximum width as a fraction of depth.
    public var width: Float = 0.5
    /// Head width relative to body width at the head (catfish > 1).
    public var headWidth: Float = 1
    /// Peduncle depth relative to max depth.
    public var peduncle: Float = 0.36
    /// Head profile exponent: < 1 blunt and deep, > 1 long pointed snout.
    public var snout: Float = 0.8
    /// Dorsal vs ventral share of depth (0 symmetric, + humped back, - deep belly).
    public var arch: Float = 0.1
    /// Cross-section superellipse exponent (2 ellipse, larger boxier).
    public var section: Float = 2.2
    /// Dorsal keel: narrows the back toward a ridge (0 round, 0.5 sunfish).
    public var keel: Float = 0.25
    /// Flat belly (catfish): squashes the lower half.
    public var flatBelly: Float = 0

    /// Mouth corner position, mouth line height at the snout (fraction of depth, + up) and drop toward the corner.
    public var mouthEnd: Float = 0.13
    public var mouthY: Float = -0.05
    public var mouthDrop: Float = 0.25
    /// Lower jaw protrusion beyond the upper lip (fraction of length).
    public var underbite: Float = 0.008
    /// Gill cover edge position.
    public var operculum: Float = 0.27
    /// Eye: body position, height (fraction of half depth above axis), radius (fraction of length).
    public var eyeAt: Float = 0.09
    public var eyeY: Float = 0.35
    public var eyeR: Float = 0.026

    public var dorsal: Fin? = Fin(0.33, 0.78, height: 0.11, rake: 22, notch: 0.4, rays: 23, split: 0.45, splitDepth: 0.45)
    public var anal: Fin? = Fin(0.66, 0.84, height: 0.08, rake: 30, rays: 12)
    public var adipose: Bool = false
    public var caudal: Caudal = .emarginate
    public var caudalSpread: Float = 0.24
    /// Pectoral and pelvic fin length (fraction of length).
    public var pectoral: Float = 0.14
    public var pelvic: Float = 0.11
    public var pelvicAt: Float = 0.34
    /// Catfish whiskers: 0 none, else count (8 for ictalurids).
    public var barbels: Int = 0
    /// Sunfish opercular ear flap length (fraction of length), 0 none.
    public var earFlap: Float = 0

    public var skin: MaterialKey = "fish.smallmouth-skin"
    public var fin: MaterialKey = "fish.bass-fin"
    public var eye: MaterialKey = "fish.eye-red"
    public var earFlapMaterial: MaterialKey = "fish.ear-flap"

    public init() {}

    // MARK: profiles (meters, building frame)

    var bodyLength: Float { length * bodyFrac }
    func x(_ s: Float) -> Float { -s * bodyLength }

    /// Normalised depth profile 0...1 along the body.
    func depthShape(_ s: Float) -> Float {
        let pedStart: Float = 0.9
        if s < maxAt {
            let k = s / maxAt
            return 0.10 + 0.90 * pow(sin(k * .pi / 2), snout)
        }
        if s < pedStart {
            let k = (s - maxAt) / (pedStart - maxAt)
            let c = pow(cos(k * .pi / 2), 1.3)
            return peduncle + (1 - peduncle) * c
        }
        let k = (s - pedStart) / (1 - pedStart)
        return peduncle * (1 + 0.18 * k * k)
    }
    func halfDepth(_ s: Float) -> Float { depth * length * 0.5 * depthShape(s) }
    func top(_ s: Float) -> Float { halfDepth(s) * (1 + arch * smoothstep(0, 0.4, s) * (1 - smoothstep(0.6, 0.95, s))) }
    func bottom(_ s: Float) -> Float { -halfDepth(s) * (1 - arch * 0.5 * smoothstep(0, 0.4, s) * (1 - smoothstep(0.6, 0.95, s))) }
    func halfWidth(_ s: Float) -> Float {
        let base = depth * length * 0.5 * width * pow(depthShape(s), 0.85)
        let head = 1 + (headWidth - 1) * (1 - smoothstep(0.1, 0.45, s))
        // Peduncle is laterally compressed.
        return base * head * (1 - 0.35 * smoothstep(0.75, 1, s))
    }
    func mouthLine(_ s: Float) -> Float {
        let k = min(1, s / max(mouthEnd, 0.01))
        return halfDepth(0.0) * 0 + mouthY * depth * length * 0.5 - mouthDrop * depth * length * 0.5 * k * k * 0.6
    }

    /// Body point at position s and angle theta (0 dorsal, pi ventral, + toward +Z).
    func point(_ s: Float, _ theta: Float) -> V3 {
        let e = 2 / section
        let c = cos(theta), sn = sin(theta)
        var y = c >= 0 ? pow(c, e) * top(s) : -pow(-c, e) * -bottom(s)
        if c < 0 { y *= 1 - flatBelly * 0.35 * (1 - pow(-c, 4)) }
        let keelK = 1 - keel * max(0, c) * max(0, c)
        let z = (sn >= 0 ? 1 : -1) * pow(abs(sn), e) * halfWidth(s) * keelK
        return V3(x(s), y, z)
    }

    /// Lateral surface half-width at body position s and height y (for placing paired fins and eyes).
    func surfaceZ(_ s: Float, y: Float) -> Float {
        var best: Float = 0, bestD: Float = .infinity
        for i in 0...48 {
            let th = Float(i) / 48 * .pi
            let p = point(s, th)
            let d = abs(p.y - y)
            if d < bestD { bestD = d; best = p.z }
        }
        return best
    }
}
