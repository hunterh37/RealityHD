// Single-scattering sky into an equirect HDR map.

let metalSky = #"""
// ---------------------------------------------------------------- sky
// Single-scattering atmosphere (Rayleigh + Mie, Nishita-style ray march) into an equirect HDR map.
struct SkyParams { float3 sunDir; float sunIntensity; float turbidity; float groundAlbedo; int width; int height; int drawSun; float exposure; float overcast; float cloudSeed; int vacuum; float earthAz; float earthEl; float earthRadius; };

float2 raySphere(float3 ro, float3 rd, float R) {
    float b = dot(ro, rd), c = dot(ro, ro) - R * R, d = b * b - c;
    if (d < 0.0) return float2(1e9, -1e9);
    d = sqrt(d); return float2(-b - d, -b + d);
}
float3 atmosphere(float3 rd, float3 sunDir, float turb, float sunI) {
    const float Re = 6360e3, Ra = 6420e3, Hr = 7994.0, Hm = 1200.0;
    const float3 betaR = float3(5.8e-6, 13.5e-6, 33.1e-6);
    float3 betaM = float3(21e-6) * turb;
    float3 ro = float3(0, Re + 2.0, 0);
    float2 t = raySphere(ro, rd, Ra);
    float tmax = t.y;
    float2 tg = raySphere(ro, rd, Re);
    if (tg.x > 0.0) tmax = min(tmax, tg.x);
    const int NS = 16, NL = 6;
    float seg = tmax / float(NS), tc = 0.0;
    float3 sumR = 0.0, sumM = 0.0; float odR = 0.0, odM = 0.0;
    float mu = dot(rd, sunDir);
    float phR = 3.0 / (16.0 * 3.14159) * (1.0 + mu * mu);
    float g = 0.76;
    float phM = 3.0 / (8.0 * 3.14159) * ((1.0 - g * g) * (1.0 + mu * mu)) / ((2.0 + g * g) * pow(1.0 + g * g - 2.0 * g * mu, 1.5));
    for (int i = 0; i < NS; i++) {
        float3 p = ro + rd * (tc + seg * 0.5);
        float h = length(p) - Re;
        float hr = exp(-h / Hr) * seg, hm = exp(-h / Hm) * seg;
        odR += hr; odM += hm;
        float2 tl = raySphere(p, sunDir, Ra);
        float segL = tl.y / float(NL), tcl = 0.0, odRL = 0.0, odML = 0.0; bool ok = true;
        for (int j = 0; j < NL; j++) {
            float3 pl = p + sunDir * (tcl + segL * 0.5);
            float hl = length(pl) - Re;
            if (hl < 0.0) { ok = false; break; }
            odRL += exp(-hl / Hr) * segL; odML += exp(-hl / Hm) * segL; tcl += segL;
        }
        if (ok) {
            const float3 betaO = float3(0.65e-6, 1.881e-6, 0.085e-6) * 2.0;   // ozone: keeps horizons blue, not green
            float3 tau = (betaR + betaO) * (odR + odRL) + betaM * 1.1 * (odM + odML);
            float3 att = exp(-tau);
            sumR += att * hr; sumM += att * hm;
        }
        tc += seg;
    }
    return sunI * (sumR * betaR * phR + sumM * betaM * phM);
}
float cloudHash(float2 p) { p = fract(p * float2(123.34, 456.21)); p += dot(p, p + 45.32); return fract(p.x * p.y); }
float cloudNoise(float2 p) {
    float2 i = floor(p), f = fract(p); f = f * f * (3.0 - 2.0 * f);
    return mix(mix(cloudHash(i), cloudHash(i + float2(1, 0)), f.x), mix(cloudHash(i + float2(0, 1)), cloudHash(i + float2(1, 1)), f.x), f.y);
}
float cloudFbm(float2 p) {
    float a = 0.5, s = 0.0;
    for (int i = 0; i < 6; i++) { s += a * cloudNoise(p); p = p * 2.03 + float2(17.1, 9.2); a *= 0.5; }
    return s;
}
// Cloud deck: projected onto a plane so cloud cells shrink toward the horizon. x = coverage, y = thickness shade.
float2 cloudDeck(float3 rd, float cover, float seed) {
    float2 uv = rd.xz / (max(rd.y, 0.0) + 0.12) * 0.9 + seed * 7.3;
    float n = cloudFbm(uv), n2 = cloudFbm(uv * 2.7 + 3.1);
    float c = smoothstep(1.02 - cover * 1.18, 1.1 - cover * 0.55, n * 0.8 + n2 * 0.2);
    return float2(c, 0.55 + 0.45 * n2);
}
// Vacuum sky (airless body): black, procedural stars, hard sun disk, optional Earth disc with phase.
float vHash(float3 p) { p = fract(p * 0.3183099 + 0.1); p *= 17.0; return fract(p.x * p.y * p.z * (p.x + p.y + p.z)); }
float3 vacuumSky(float3 rd, float3 sd, constant SkyParams &S) {
    float3 col = float3(0.0);
    if (S.drawSun == 1) {
        // Stars: jittered point per 3D cell, a few bright ones, faint galactic band.
        float3 q = rd * 260.0, c = floor(q), f = fract(q);
        float h = vHash(c);
        if (h > 0.972) {
            float3 o = 0.25 + 0.5 * float3(vHash(c + 3.1), vHash(c + 7.7), vHash(c + 11.3));
            float d = length(f - o);
            float mag = pow((h - 0.972) / 0.028, 3.0);
            float3 tint = mix(float3(1.0, 0.82, 0.65), float3(0.7, 0.8, 1.0), vHash(c + 19.0));
            col += tint * smoothstep(0.33, 0.0, d) * (0.05 + 0.9 * mag) * 1.6;
        }
        float band = exp(-pow(dot(rd, normalize(float3(0.3, 0.8, -0.5))) * 4.5, 2.0));
        col += float3(0.8, 0.85, 1.0) * band * 0.012 * (0.6 + 0.8 * cloudFbm(rd.xz * 6.0 + rd.y * 3.0));
        // Sun disk, 0.53 degrees across, no extinction.
        col += smoothstep(0.999984, 0.999989, dot(rd, sd)) * S.sunIntensity * 40.0;
        // Earth disc.
        if (S.earthRadius > 0.0) {
            float ce = cos(S.earthEl), se = sin(S.earthEl);
            float3 e = float3(sin(S.earthAz) * ce, se, -cos(S.earthAz) * ce);
            float cosA = dot(rd, e), sinR = sin(S.earthRadius);
            if (cosA > 0.0) {
                float3 t = (rd - e * cosA) / (sinR * max(cosA, 1e-4));
                float r2 = dot(t, t);
                if (r2 < 1.0) {
                    float3 n = normalize(t + e * sqrt(1.0 - r2));
                    float2 cuv = float2(atan2(n.z, n.x) * 1.9 + 3.0, n.y * 3.2);
                    float cl = smoothstep(0.52, 0.75, cloudFbm(cuv * 2.2));
                    float land = smoothstep(0.55, 0.62, cloudFbm(cuv * 1.3 + 11.0));
                    float3 ground = mix(float3(0.04, 0.12, 0.34), float3(0.28, 0.24, 0.12), land);
                    float3 surf = mix(ground, float3(0.95), cl * 0.85);
                    float lit = smoothstep(-0.05, 0.4, dot(n, sd));
                    float limb = mix(1.0, 0.55, pow(r2, 3.0));
                    float edge = smoothstep(1.0, 0.94, r2);
                    col = mix(col, (surf * (0.003 + lit) * S.sunIntensity * 0.09 + float3(0.1, 0.25, 0.7) * pow(r2, 8.0) * 0.05 * lit) * limb, edge);
                }
            }
        }
    }
    return col;
}
kernel void rf_sky(texture2d<float, access::write> out [[texture(0)]],
                   constant SkyParams &S [[buffer(0)]],
                   uint2 gid [[thread_position_in_grid]]) {
    if (int(gid.x) >= S.width || int(gid.y) >= S.height) return;
    float u = (float(gid.x) + 0.5) / float(S.width), v = (float(gid.y) + 0.5) / float(S.height);
    float phi = (u - 0.5) * 2.0 * 3.14159265, theta = (0.5 - v) * 3.14159265;   // theta: elevation
    // Equirect convention: u=0.5 looks down -Z, +X at u=0.75.
    float3 rd = float3(sin(phi) * cos(theta), sin(theta), -cos(phi) * cos(theta));
    float3 sd = normalize(S.sunDir);
    float3 col;
    if (S.vacuum == 1) {
        col = vacuumSky(rd, sd, S);
        if (rd.y < 0.0) col = float3(0.02, 0.019, 0.018) * S.sunIntensity * max(sd.y, 0.02);
        else col += float3(0.0006);
        col *= S.exposure;
        out.write(float4(col, 1.0), gid);
        return;
    }
    if (rd.y >= 0.0) {
        // Single scattering darkens grazing rays; real horizons stay bright from multiple scattering.
        col = atmosphere(normalize(float3(rd.x, max(rd.y, 0.045), rd.z)), sd, S.turbidity, S.sunIntensity);
        float veil = 0.0;
        if (S.overcast > 0.001) {
            // Overcast light is the sky's mean irradiance scattered by droplets: grey, a little brighter than
            // the clear average (cloud tops reflect sun the blue sky does not).
            float3 az = float3(0.0, 1.0, 0.0), ax = normalize(float3(1.0, 1.0, 0.0)), ay = normalize(float3(-1.0, 1.0, 0.0));
            float3 a1 = atmosphere(az, sd, S.turbidity, S.sunIntensity) + atmosphere(ax, sd, S.turbidity, S.sunIntensity) + atmosphere(ay, sd, S.turbidity, S.sunIntensity);
            float zl = dot(a1, float3(0.2126, 0.7152, 0.0722)) / 3.0;
            float3 deckLit = float3(0.93, 0.97, 1.03) * zl * 1.7;
            float2 cd = cloudDeck(rd, S.overcast, S.cloudSeed);
            float dark = mix(1.0, 0.62, smoothstep(0.7, 1.0, S.overcast));
            // CIE overcast sky: zenith about three times brighter than the horizon.
            float3 cloud = deckLit * dark * mix(0.7, 1.1, cd.y) * (1.0 + 2.0 * max(rd.y, 0.05)) / 2.1;
            // Thin the deck toward the horizon so it dissolves into haze rather than a hard edge.
            float cover = cd.x * smoothstep(0.0, 0.22, rd.y) * smoothstep(0.0, 0.5, S.overcast) + smoothstep(0.55, 1.0, S.overcast) * 0.85 * cd.x;
            veil = clamp(cover + smoothstep(0.4, 1.0, S.overcast) * 0.35, 0.0, 1.0);
            col = mix(col, cloud, veil);
        }
        if (S.drawSun == 1) {
            float cosA = dot(rd, sd);
            float disk = smoothstep(0.99996, 0.999985, cosA);
            float3 trans = exp(-(float3(5.8e-6, 13.5e-6, 33.1e-6) * 7994.0 + 21e-6 * S.turbidity * 1200.0) / max(sd.y, 0.03));
            col += disk * trans * S.sunIntensity * 40.0 * (1.0 - veil);
        }
    } else {
        // Below the horizon: distant land seen through haze (never a hard brown band).
        float3 horizon = atmosphere(normalize(float3(rd.x, 0.045, rd.z)), sd, S.turbidity, S.sunIntensity);
        float3 land = horizon * float3(0.55, 0.6, 0.5) * S.groundAlbedo;
        if (S.overcast > 0.001) {
            float hl = dot(horizon, float3(0.2126, 0.7152, 0.0722));
            horizon = mix(horizon, float3(hl) * float3(0.95, 0.98, 1.02), S.overcast * 0.85);
            land = horizon * float3(0.55, 0.6, 0.5) * S.groundAlbedo;
        }
        col = mix(horizon, land, smoothstep(0.0, 0.35, -rd.y));
    }
    col *= S.exposure;
    out.write(float4(col, 1.0), gid);
}
"""#
