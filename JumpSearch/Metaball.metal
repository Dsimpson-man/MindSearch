#include <metal_stdlib>
using namespace metal;

struct Blob {
    float2 center;
    float radius;
    float weight;
};

vertex float4 metaball_vertex(uint vid [[vertex_id]]) {
    float2 positions[3] = {
        float2(-1.0, -1.0),
        float2(3.0, -1.0),
        float2(-1.0, 3.0)
    };
    return float4(positions[vid], 0.0, 1.0);
}

fragment float4 metaball_fragment(
    float4 position [[position]],
    constant float2 &viewSize [[buffer(0)]],
    constant Blob *blobs [[buffer(1)]],
    constant int &blobCount [[buffer(2)]],
    constant float3 &tint [[buffer(3)]]
) {
    float2 p = position.xy;
    float field = 0.0;
    for (int i = 0; i < blobCount; i++) {
        Blob b = blobs[i];
        float2 d = p - b.center;
        float r2 = b.radius * b.radius;
        field += b.weight * r2 / (dot(d, d) + r2 * 0.2);
    }
    float alpha = smoothstep(0.5, 0.72, field);
    return float4(tint, alpha);
}
