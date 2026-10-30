import Foundation
import CoreGraphics
import RealityKit
import RealKit

/// B1 probe: does a caster with `OpacityComponent(opacity: 0)` still cast a sun shadow on the visionOS
/// RealityRenderer? Renders a box over a ground plane per variant and counts shadowed ground pixels.
@MainActor
func shadowTestCommand(_ args: Args) async throws {
    RealKitSetup.register()
    enum Variant: String, CaseIterable { case none, cast, opacityZeroCast, opacityZeroNoCast, hiddenCast }
    var images: [Variant: [Int]] = [:]
    for v in Variant.allCases {
        let env = try RealEnvironment(.afternoon, skybox: true)
        let preview = try RealPreview(environment: env)
        let root = Entity()
        let ground = ModelEntity(mesh: .generatePlane(width: 20, depth: 20), materials: [SimpleMaterial(color: .init(white: 0.7, alpha: 1), isMetallic: false)])
        ground.components.set(DynamicLightShadowComponent(castsShadow: false))
        root.addChild(ground)
        if v != .none {
            let box = ModelEntity(mesh: .generateBox(size: 1), materials: [SimpleMaterial(color: .red, isMetallic: false)])
            box.position = [0, 1.2, 0]
            switch v {
            case .cast: box.components.set(DynamicLightShadowComponent(castsShadow: true))
            case .opacityZeroCast:
                box.components.set(DynamicLightShadowComponent(castsShadow: true)); box.components.set(OpacityComponent(opacity: 0))
            case .opacityZeroNoCast:
                box.components.set(DynamicLightShadowComponent(castsShadow: false)); box.components.set(OpacityComponent(opacity: 0))
            case .hiddenCast:
                box.components.set(DynamicLightShadowComponent(castsShadow: true)); box.isEnabled = false
            case .none: break
            }
            root.addChild(box)
        }
        env.illuminate(root)
        preview.add(root)
        preview.look(from: [0, 9, 0.01], at: [0, 0, 0], fov: 60)
        guard let img = try await preview.render(width: 512, height: 512, frames: 6, deltaTime: 0.0166) else { throw CLIError("render failed \(v)") }
        writePNG(img, "out/shadowtest-\(v.rawValue).png")
        var lum = [Int]()
        let w = img.width, h = img.height
        var px = [UInt8](repeating: 0, count: w * h * 4)
        let ctx = CGContext(data: &px, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.draw(img, in: CGRect(x: 0, y: 0, width: w, height: h))
        for i in 0..<w * h { lum.append((Int(px[i * 4]) * 3 + Int(px[i * 4 + 1]) * 6 + Int(px[i * 4 + 2])) / 10) }
        images[v] = lum
    }
    let base = images[.none]!
    for v in Variant.allCases {
        let l = images[v]!
        let darker = zip(l, base).filter { $0.1 - $0.0 > 12 }.count
        print("\(v.rawValue): pixels darker than no-caster baseline by >12/255: \(darker)")
    }
}
