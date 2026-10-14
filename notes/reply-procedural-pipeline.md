RealityHD builds every asset at runtime from Swift code. No meshes or textures ship in the package.

Geometry. Each asset is a deterministic function of a seed. A seeded RNG, forked per sub-part, drives parametric primitives (lathes, extrusions, swept boards, Catmull-Rom tubes) and space-colonization-style tree growth. Real-world dimensions in meters, authored as tunable parameters.

Materials. Textures are synthesized on the GPU by Metal compute kernels: layered noise fields (fBm, Voronoi, domain warping) produce albedo, normal and roughness maps. A material is a spec (family, variant, palette, tiling) that selects a kernel and its knobs.

Shading. Maps feed a RealityKit ShaderGraph material. Per-vertex channels carry baked ambient occlusion and wind weight, so foliage sways in the vertex stage and crevices darken without runtime cost.

Lighting. AO is baked by ray casting against a BVH. Image-based lighting comes from a procedural sky; interiors add probe lighting and fog.

Scale. Each asset emits a LOD chain under a triangle budget. Scenes scatter instances, batch static meshes and switch LOD by head-tracked distance.

Quality control. A CLI renders contact sheets, a vision model scores them against a rubric and a reference photo, and only signed-off assets merge.

One line: seeded parametric geometry plus GPU noise-synthesized PBR textures, baked AO, LOD and instancing, gated by automated visual review.
