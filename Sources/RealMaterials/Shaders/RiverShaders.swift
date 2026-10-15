// River programs: barkSycamore.

let metalRiver = #"""
// ---------------------------------------------------------------- river
// American sycamore bark: thin brown outer plates flake off in irregular jigsaw patches, exposing
// cream, pale olive and grey-green inner bark. colorA outer bark, colorB fresh inner bark (cream),
// colorC older inner bark (olive grey); knobs.x exposed fraction 0...1, knobs.y plate edge relief.
S barkSycamore(float2 uv, constant RFParams &P) {
    S s = defaults(); uint sd = P.seed;
    float expose = P.f.x > 0.0 ? P.f.x : 0.55;
    float relief = P.f.y > 0.0 ? P.f.y : 0.5;
    float2 warp = float2(fbm(uv, int2(3, 3), 3, sd + 1u), fbm(uv, int2(3, 3), 3, sd + 2u)) * 0.12;
    // Patches: Worley cells stretched slightly along the stem, each either outer bark or inner bark.
    float4 w = worley(uv + warp, int2(5, 4), sd + 3u, 0.95);
    float edge = w.y - w.x;
    float inner = smoothstep(-0.05, 0.05, w.z - (1.0 - expose) + fbm(uv, int2(6, 6), 3, sd + 5u) * 0.25);
    // Inner bark shade varies cream to olive grey by a second, slower field.
    float age = smoothstep(-0.3, 0.4, fbm(uv, int2(3, 2), 4, sd + 6u) + w.w * 0.3);
    float fine = fbm(uv, int2(32, 32), 3, sd + 7u);
    float3 innerCol = mix(P.colorB.rgb, P.colorC.rgb, age) * (0.94 + 0.12 * fine);
    float3 outerCol = P.colorA.rgb * (0.85 + 0.25 * fbm(uv, int2(24, 12), 3, sd + 8u));
    // Outer plates curl at their rims: a darker lip with a thin shadow line.
    float rim = 1.0 - smoothstep(0.0, 0.05, edge);
    float lip = (1.0 - inner) * smoothstep(0.02, 0.0, abs(edge - 0.03));
    s.albedo = mix(outerCol, innerCol, inner);
    s.albedo *= 1.0 - 0.45 * rim * (1.0 - inner) - 0.25 * lip;
    s.height = 0.45 + (1.0 - inner) * 0.18 * relief + fine * 0.04 - rim * 0.1 * relief;
    s.rough = mix(0.88, 0.62, inner);
    s.ao = mix(1.0, 0.7, rim * (1.0 - inner));
    return s;
}
"""#
