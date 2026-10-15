import Foundation

/// Control logic of one halogen beam siphon burner station (Bonmac / Hario beam heater class), free of
/// RealityKit so it can be unit tested. `HalogenSiphonBarRuntime` drives the live prop from it.
///
/// Behavior modelled on the Bonmac BMH-2 / Hario BGH beam heater keypads:
/// - Output (出力) runs in 10 steps, 1 (about 40 W) to 10 (about 400 W at the lamp). Up/down change it
///   while output set (出力セット) is selected; the display shows `P 10`.
/// - Time set (時間セット) selects the brew timer, adjusted in 5 s steps from 0:05 to 9:55 (`0130` = 1:30).
/// - Heat (加熱) runs the lamp at full output to bring the lower flask to a boil; the display shows
///   the water temperature (`98 C`).
/// - Extract (抽出) runs the lamp at the set output and counts the set time down; at 0 the lamp
///   switches off so the coffee draws back down. Timer start (タイマースタート) starts or pauses the countdown on its own.
/// - Keep warm (保温) holds a low output (step 2) to keep brewed coffee hot; the display shows `L  2`.
/// - Stop (停止) switches the lamp off and clears the countdown.
public struct SiphonBurner: Equatable, Sendable {
    public enum Mode: String, Sendable, CaseIterable { case off, heating, extracting, keepWarm }
    /// What up/down adjust.
    public enum Setting: String, Sendable { case none, output, time }
    public enum Key: String, Sendable, CaseIterable { case up, down, out, time, timer, heat, brew, warm, stop }

    public static let outputRange = 1...10
    public static let timeRange = 5...595
    public static let timeStep = 5
    public static let keepWarmOutput = 2
    public static let ambient: Double = 20
    public static let boiling: Double = 96

    public private(set) var mode: Mode = .off
    public private(set) var setting: Setting = .none
    /// Output step 1...10 used by extract.
    public private(set) var output = 6
    /// Brew time (s) loaded into the countdown by extract or timer start.
    public private(set) var brewTime = 60
    /// Remaining countdown (s).
    public private(set) var remaining: Double = 0
    public private(set) var timerRunning = false
    /// Simulated water temperature in the lower flask (°C).
    public private(set) var temperature: Double = SiphonBurner.ambient
    /// Seconds left showing the setting value before the display returns to the mode readout.
    var settingHold: Double = 0
    /// Set for one tick when the countdown reaches 0 (beep).
    public private(set) var finished = false

    public init() {}

    /// Output step the lamp runs at now (0 when off).
    public var activeOutput: Int {
        switch mode {
        case .off: 0
        case .heating: 10
        case .extracting: output
        case .keepWarm: Self.keepWarmOutput
        }
    }

    /// Lamp brightness 0...1.
    public var lampLevel: Float { Float(activeOutput) / 10 }

    /// Water has reached the boil (the water rises into the upper globe).
    public var boiling: Bool { temperature >= Self.boiling - 0.5 }

    public mutating func press(_ key: Key) {
        finished = false
        switch key {
        case .out:
            setting = setting == .output ? .none : .output; settingHold = setting == .none ? 0 : 4
        case .time:
            setting = setting == .time ? .none : .time; settingHold = setting == .none ? 0 : 4
        case .up, .down:
            let d = key == .up ? 1 : -1
            switch setting {
            case .output, .none:
                setting = .output
                output = min(max(output + d, Self.outputRange.lowerBound), Self.outputRange.upperBound)
            case .time:
                brewTime = min(max(brewTime + d * Self.timeStep, Self.timeRange.lowerBound), Self.timeRange.upperBound)
                if !timerRunning { remaining = 0 }
            }
            settingHold = 4
        case .timer:
            if timerRunning { timerRunning = false }
            else { if remaining <= 0 { remaining = Double(brewTime) }; timerRunning = true }
            setting = .none; settingHold = 0
        case .heat:
            mode = .heating; setting = .none; settingHold = 0
        case .brew:
            mode = .extracting; remaining = Double(brewTime); timerRunning = true; setting = .none; settingHold = 0
        case .warm:
            mode = .keepWarm; timerRunning = false; remaining = 0; setting = .none; settingHold = 0
        case .stop:
            mode = .off; timerRunning = false; remaining = 0; setting = .none; settingHold = 0
        }
    }

    /// Advances the timer and the water temperature by `dt` seconds.
    public mutating func tick(_ dt: Double) {
        finished = false
        if settingHold > 0 { settingHold -= dt; if settingHold <= 0 { settingHold = 0; setting = .none } }
        if timerRunning {
            remaining -= dt
            if remaining <= 0 {
                remaining = 0; timerRunning = false; finished = true
                if mode == .extracting { mode = .off }
            }
        }
        // Lumped model of ~250 ml water: full output brings 20 °C water to the boil in about 4 minutes.
        let watts = Double(activeOutput) * 40
        let heatIn = watts * 0.85 / (0.25 * 4186)            // K/s
        let loss = (temperature - Self.ambient) * 0.0008     // K/s
        temperature = min(Self.boiling, max(Self.ambient, temperature + (heatIn - loss) * dt))
    }

    /// Four-character readout for the red seven-segment display ("" = dark).
    public var display: String {
        switch setting {
        case .output: return output >= 10 ? "P 10" : "P  \(output)"
        case .time: return Self.clock(brewTime)
        case .none: break
        }
        if timerRunning || remaining > 0 { return Self.clock(Int(remaining.rounded(.up))) }
        switch mode {
        case .off: return temperature > 40 ? Self.temp(temperature) : "----"
        case .heating: return Self.temp(temperature)
        case .extracting: return Self.clock(0)
        case .keepWarm: return "L  \(Self.keepWarmOutput)"
        }
    }

    static func clock(_ s: Int) -> String { String(format: "%02d%02d", s / 60, s % 60) }
    static func temp(_ t: Double) -> String {
        let v = Int(t.rounded())
        return (v < 100 ? " " : "") + "\(v)C"
    }

    /// Segment masks a...g (bit 0 = a, top; clockwise; bit 6 = g) for display characters.
    public static let glyphs: [Character: UInt8] = [
        "0": 0b0111111, "1": 0b0000110, "2": 0b1011011, "3": 0b1001111, "4": 0b1100110, "5": 0b1101101,
        "6": 0b1111101, "7": 0b0000111, "8": 0b1111111, "9": 0b1101111, "-": 0b1000000, "E": 0b1111001,
        "L": 0b0111000, "A": 0b1110111, "o": 0b1011100, "H": 0b1110110, "P": 0b1110011, "C": 0b0111001, "r": 0b1010000, " ": 0,
    ]

    /// Lit segment masks for the four digits of `display`.
    public var segmentMasks: [UInt8] {
        let chars = Array(display.padding(toLength: 4, withPad: " ", startingAt: 0).prefix(4))
        return chars.map { Self.glyphs[$0] ?? 0 }
    }
}

/// Both stations of a `halogen-siphon-bar`, addressed by the rig part prefixes "left" and "right".
public struct SiphonBarController: Equatable, Sendable {
    public var left = SiphonBurner()
    public var right = SiphonBurner()
    public init() {}

    public subscript(side: String) -> SiphonBurner {
        get { side == "right" ? right : left }
        set { if side == "right" { right = newValue } else { left = newValue } }
    }

    /// Handles a key part name such as "left-heat". Returns false for names that are not keys.
    @discardableResult
    public mutating func press(part: String) -> Bool {
        let bits = part.split(separator: "-", maxSplits: 1).map(String.init)
        guard bits.count == 2, bits[0] == "left" || bits[0] == "right", let key = SiphonBurner.Key(rawValue: bits[1]) else { return false }
        self[bits[0]].press(key)
        return true
    }

    public mutating func tick(_ dt: Double) { left.tick(dt); right.tick(dt) }
}
