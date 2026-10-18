import RealCore

public extension MaterialLibrary {
    /// Off-world sites: thermal-control white paint, gold MLI, space solar cells and Kapton, radiator coolant glow.
    static let terawattSite: [MaterialSpec] = [
        // Z93-style white thermal control coating on aluminum: matte warm white, faint orbital darkening.
        MaterialSpec(key: "thermal.radiator-white", program: .paintedMetal).with {
            $0.colorA = linear(0xE6E6E0); $0.colorB = linear(0xC9C8C0)
            $0.knobs = V4(0.3, 0.2, 0.4, 0.1); $0.seed = 9901; $0.tileSize = 0.6; $0.normalStrength = 0.3
            $0.hasMetallicMap = true; $0.metallic = 0.1; $0.roughness = 0.62
        },
        // Radiator coolant lines running hot: blackbody orange emissive on dark metal.
        MaterialSpec(key: "thermal.radiator-glow", program: nil).with {
            $0.baseColor = V3(0.1, 0.06, 0.04); $0.metallic = 0.6; $0.roughness = 0.4
            $0.mode = .emissive; $0.emissive = RealHeat.blackbody(kelvin: 1150); $0.emissiveIntensity = 1.6
        },
        // Gold-coated Kapton multilayer insulation blanket: crinkled facets, sharp creases.
        MaterialSpec(key: "mli.blanket", program: .foilCrinkle).with {
            $0.colorA = linear(0xD9A24A); $0.colorB = linear(0x5A3A12); $0.colorC = linear(0x2E1C08)
            $0.knobs = V4(14, 1.1, 0.16, 1.0); $0.seed = 9902; $0.tileSize = 0.6; $0.normalStrength = 3
            $0.hasMetallicMap = true; $0.metallic = 1; $0.roughness = 0.2
        },
        // Aluminized Mylar outer layer MLI: silver-white crinkle.
        MaterialSpec(key: "mli.silver", program: .foilCrinkle).with {
            $0.colorA = linear(0xD6DADF); $0.colorB = linear(0x565B64); $0.colorC = linear(0x2E3238)
            $0.knobs = V4(12, 0.9, 0.18, 0.8); $0.seed = 9903; $0.tileSize = 0.5; $0.normalStrength = 2.5
            $0.hasMetallicMap = true; $0.metallic = 1; $0.roughness = 0.22
        },
        // Triple-junction cell grid on Kapton, 8 x 4 cm cells.
        MaterialSpec(key: "solar.cell", program: .solarCell).with {
            $0.colorA = linear(0x1A2A5C); $0.colorB = linear(0xB9BEC6); $0.colorC = linear(0xA8671F)
            $0.knobs = V4(8, 16, 0.045, 0.35); $0.seed = 9904; $0.tileSize = 0.64; $0.normalStrength = 0.6
            $0.hasMetallicMap = true; $0.metallic = 0.3; $0.roughness = 0.2
        },
        // Kapton substrate and panel back: amber polyimide film.
        MaterialSpec(key: "solar.kapton", program: .plastic).with {
            $0.colorA = linear(0xB06E22); $0.knobs = V4(0.2, 0.2, 0.3, 0); $0.seed = 9905
            $0.tileSize = 0.3; $0.resolution = 512; $0.normalStrength = 0.2
        },
        // Lunar regolith: fine grey-brown basaltic dust with sharp-edged fragments, no wind ripples.
        MaterialSpec(key: "regolith.lunar", program: .gravel).with {
            $0.colorA = linear(0x6F6D69); $0.colorB = linear(0x4A4947); $0.colorC = linear(0x8C8A85)
            $0.knobs = V4(0.95, 0.35, 0.6, 0); $0.seed = 9911; $0.tileSize = 1.2; $0.normalStrength = 2.4; $0.resolution = 2048
            $0.antiTile = true; $0.roughness = 0.97
        },
        // Compacted regolith on berm slopes and rover tracks: lighter, finer, matte.
        MaterialSpec(key: "regolith.lunar-fine", program: .sand).with {
            $0.colorA = linear(0x84827D); $0.colorB = linear(0x5A5855); $0.colorC = linear(0x9A9893)
            $0.knobs = V4(0.4, 0, 0.05, 90); $0.seed = 9912; $0.tileSize = 1.5; $0.normalStrength = 1.2; $0.resolution = 2048
            $0.antiTile = true; $0.roughness = 0.98
        },
        // Martian dust and sand: iron-oxide red-orange with soft ripples and dark basalt grains.
        MaterialSpec(key: "dust.mars", program: .sand).with {
            $0.colorA = linear(0xA9623A); $0.colorB = linear(0x6B3A24); $0.colorC = linear(0xC8855A)
            $0.knobs = V4(1.0, 0, 0.22, 22); $0.seed = 9913; $0.tileSize = 2.2; $0.normalStrength = 2.4; $0.resolution = 2048
            $0.antiTile = true; $0.roughness = 0.95
        },
        // Dust settled on panels and metal: thin ochre-red film, rougher and flatter than the ground.
        MaterialSpec(key: "dust.mars-film", program: .sand).with {
            $0.colorA = linear(0xB87850); $0.colorB = linear(0x8A5636); $0.colorC = linear(0xD09A70)
            $0.knobs = V4(0.5, 0, 0.1, 60); $0.seed = 9914; $0.tileSize = 0.8; $0.normalStrength = 0.9; $0.resolution = 1024
            $0.roughness = 0.92
        },
    ]
}
