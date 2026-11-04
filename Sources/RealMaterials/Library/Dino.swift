import RealCore

public extension MaterialLibrary {
    /// Dinosaur surfaces. `dino.scale-skin`: pebbly countershaded scale atlas (`dinoScale`, Loft UVs).
    /// `dino.feather-coat`: proto-feather body coat (`plumageBody`). Species variants live in `DinoMaterials` (AnimalCore).
    static let dino: [MaterialSpec] = [
        MaterialSpec(key: "dino.scale-skin", program: .dinoScale).with {
            $0.colorA = linear(0x4E4A3A); $0.colorB = linear(0xB8A888); $0.colorC = linear(0x2A2620, 3)
            $0.knobs = V4(160, 0.62, 0.8, 0.4); $0.seed = 9301; $0.tileSize = 0; $0.resolution = 2048
            $0.normalStrength = 2.2; $0.roughness = 0.7
        },
        MaterialSpec(key: "dino.feather-coat", program: .plumageBody).with {
            $0.colorA = linear(0x6B4A2E); $0.colorB = linear(0xCDB894); $0.colorC = linear(0x2C2016)
            $0.knobs = V4(60, 0.55, 0, 0.3); $0.seed = 9302; $0.tileSize = 0; $0.resolution = 1024
            $0.normalStrength = 0.9; $0.roughness = 0.85; $0.specular = 0.25
        },
    ]
}
