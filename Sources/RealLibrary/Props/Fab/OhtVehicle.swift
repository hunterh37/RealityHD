import simd
import Foundation

/// OHT hoist vehicle: Daifuku/Murata class overhead hoist transport, white covers, clean room.
public struct OhtVehicle: RealAsset {
    public static let id = "oht-vehicle"
    public static let summary = "Overhead hoist transport vehicle with four-wheel carriage and belt hoist gripper."
    public static let tags = ["prop", "semiconductor", "articulated"]
    public static let budget = 6000
    public static let author = "realityhd"

    /// Overall size in meters (x width, y height, z length along the rail).
    public var size = V3(0.6, 0.6, 0.9)
    /// Hoist lowering in meters below the stowed position (belts extend, gripper descends).
    public var hoistDrop: Float = 0
    /// Cover material key.
    public var coverMaterial = "plastic.gloss:E4E6E8"
    public init() {}

    private func bx(_ s: V3, _ r: Float, _ mat: String) -> Surface {
        Prim.extrude(Shape2D.rect(s.x, s.y), depth: s.z, bevel: min(r, s.min() * 0.4), bevelSegments: 1, material: mat)
    }

    public func build(seed: UInt64) -> LODModel {
        var rng = SeededRNG(seed: seed)
        var m = Model(name: Self.id)
        let al = "metal.aluminum-brushed", dark = "plastic.matte:2A2C2F"
        let gy: Float = 0.02 - hoistDrop   // gripper plate bottom
        // Main cover body.
        m.add(bx(V3(0.60, 0.30, 0.84), 0.02, coverMaterial), Xform(translation: V3(0, 0.30, 0)))
        // Underside recess frame and slide unit.
        m.add(bx(V3(0.54, 0.04, 0.78), 0.006, al), Xform(translation: V3(0, 0.17, 0)))
        // Travel carriage on top: chassis and four wheels (axis along X).
        m.add(bx(V3(0.30, 0.06, 0.70), 0.008, al), Xform(translation: V3(0, 0.48, 0)))
        for sz: Float in [-1, 1] {
            for sx: Float in [-1, 1] {
                m.add(Prim.cylinder(radius: 0.04, height: 0.03, bevel: 0.004, segments: 14, material: "rubber.tubing"),
                      Xform(translation: V3(sx * 0.15 + (sx > 0 ? 0.015 : -0.015) + 0, 0.57, sz * 0.27), rotation: simd_quatf(degrees: 90, axis: V3(0, 0, 1))).jittered(&rng))
            }
            m.add(bx(V3(0.06, 0.12, 0.05), 0.006, al), Xform(translation: V3(0, 0.54, sz * 0.27)))
            m.add(bx(V3(0.36, 0.016, 0.016), 0.003, "metal.steel"), Xform(translation: V3(0, 0.57, sz * 0.27)))
        }
        // Status lamp and sensor on the front.
        m.add(Prim.cylinder(radius: 0.012, height: 0.01, bevel: 0.002, segments: 10, material: "glass.lamp"),
              Xform(translation: V3(0.15, 0.36, 0.42), rotation: simd_quatf(degrees: 90, axis: V3(1, 0, 0))))
        m.add(bx(V3(0.06, 0.03, 0.01), 0.003, dark), Xform(translation: V3(-0.12, 0.30, 0.425)))
        // Four hoist belts from cover underside to the gripper.
        let top: Float = 0.15
        for sx: Float in [-1, 1] {
            for sz: Float in [-1, 1] {
                let len = max(0.01, top - gy - 0.02)
                m.add(bx(V3(0.012, len, 0.0025), 0.0005, "plastic.matte:3A3A3C"),
                      Xform(translation: V3(sx * 0.12, gy + 0.02 + len / 2, sz * 0.12)))
            }
        }
        // Gripper: plate, four claws, flange pads.
        m.add(bx(V3(0.30, 0.02, 0.20), 0.004, al), Xform(translation: V3(0, gy + 0.025, 0)))
        for sx: Float in [-1, 1] {
            m.add(bx(V3(0.012, 0.03, 0.14), 0.002, "metal.steel"), Xform(translation: V3(sx * 0.075, gy + 0.005, 0)))
        }
        _ = gy
        groundAO(&m)
        return LODModel(m)
    }
}
