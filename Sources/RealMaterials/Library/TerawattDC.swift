import RealCore

public extension MaterialLibrary {
    /// Terawatt data center lane (L1): perforated rack doors, plated and polished cooling copper, PCB solder mask.
    static let terawattDC: [MaterialSpec] = [
        // Rack door perforation: 4.5 mm holes at 6 mm pitch (0.12 m tile / 20), black powder coat, bare steel rims.
        MaterialSpec(key: "metal.perforated", program: .perforatedSheet).with {
            $0.colorA = linear(0x1A1C1F); $0.colorB = linear(0x5A5C5E); $0.colorC = linear(0x4A4C50)
            $0.knobs = V4(20, 0.32, 0.5, 0.25); $0.seed = 3101; $0.tileSize = 0.12; $0.resolution = 1024
            $0.normalStrength = 1.0; $0.mode = .cutout; $0.twoSided = true; $0.roughness = 0.5
        },
        // Polished cold plate copper: bright, a faint tarnish haze, fine machining swirl via hammer 0.
        MaterialSpec(key: "copper.polished", program: .polishedMetal).with {
            $0.colorA = linear(0xE29A74); $0.colorB = linear(0x8A4A2E); $0.colorC = linear(0x58A08A)
            $0.knobs = V4(0.12, 0.0, 0, 0.1); $0.seed = 3102; $0.tileSize = 0.1; $0.normalStrength = 0.4
            $0.hasMetallicMap = true; $0.metallic = 1; $0.roughness = 0.1
        },
        // Electroless nickel plating: pale warm grey, satin, fine brushed streak.
        MaterialSpec(key: "metal.nickel", program: .brushedMetal).with {
            $0.colorA = linear(0xB9B8B2); $0.colorB = linear(0x8C8A84)
            $0.knobs = V4(0.3, 0.3, 0.3, 0.3); $0.seed = 3103; $0.tileSize = 0.12; $0.normalStrength = 0.25
            $0.hasMetallicMap = true; $0.metallic = 1; $0.roughness = 0.3
        },
        // Green solder-mask PCB: satin dark green epoxy, faint fiber weave relief.
        MaterialSpec(key: "plastic.pcb", program: .plastic).with {
            $0.colorA = linear(0x0F4A2A); $0.knobs = V4(0.25, 0.15, 0.4, 0); $0.seed = 3104; $0.tileSize = 0.08
            $0.resolution = 512; $0.normalStrength = 0.4; $0.roughness = 0.38; $0.clearcoat = 0.25
        },
    ]
}
