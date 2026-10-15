import simd
import Foundation

/// NACA 4-digit airfoil outline for a unit chord: x 0 (leading edge) ... 1 (trailing edge), y thickness.
/// `t` thickness ratio (0.12 for a 2412), `m` max camber (0.02), `p` camber position (0.4).
/// Closed loop without repeated points: upper surface TE -> LE, lower surface LE -> TE (blunt TE).
/// `n` points per side, cosine spaced so the leading edge stays round.
public func nacaOutline(t: Float, m: Float = 0, p: Float = 0.4, n: Int = 16) -> [V2] {
    func yt(_ x: Float) -> Float {
        5 * t * (0.2969 * x.squareRoot() - 0.126 * x - 0.3516 * x * x + 0.2843 * x * x * x - 0.1036 * x * x * x * x)
    }
    func camber(_ x: Float) -> (Float, Float) {
        guard m > 0 else { return (0, 0) }
        if x < p { return (m / (p * p) * (2 * p * x - x * x), 2 * m / (p * p) * (p - x)) }
        return (m / ((1 - p) * (1 - p)) * (1 - 2 * p + 2 * p * x - x * x), 2 * m / ((1 - p) * (1 - p)) * (p - x))
    }
    func point(_ x: Float, upper: Bool) -> V2 {
        let h = yt(x), (yc, dy) = camber(x), th = atan(dy)
        return upper ? V2(x - h * sin(th), yc + h * cos(th)) : V2(x + h * sin(th), yc - h * cos(th))
    }
    let xs = (0...n).map { k -> Float in 0.5 * (1 - cos(Float(k) / Float(n) * .pi)) }
    var out: [V2] = []
    for x in xs.reversed() { out.append(point(x, upper: true)) }          // TE -> LE (includes x = 0)
    for x in xs.dropFirst() { out.append(point(x, upper: false)) }       // LE -> TE
    return out
}

/// Maps a unit-chord airfoil outline into 3D: chord runs from `le` along `chordDir` for `chord` meters,
/// thickness along `up`. Used to build loft rings for wings, fins and control surfaces.
public func airfoilRing(_ outline: [V2], le: V3, chord: Float, chordDir: V3, up: V3) -> [V3] {
    outline.map { le + chordDir * ($0.x * chord) + up * ($0.y * chord) }
}
