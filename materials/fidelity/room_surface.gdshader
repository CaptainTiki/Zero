shader_type spatial;
render_mode diffuse_burley;
// Use one sampler: Compatibility can share filter state for the same texture.
// Sampling exact texel centers gives the sharp endpoint without sampler aliasing.
uniform sampler2D normal_texture : hint_normal, filter_linear, repeat_enable;
uniform sampler2D roughness_texture : hint_default_white, filter_linear, repeat_enable;
uniform bool surface_maps = false;
uniform float bump_strength : hint_range(0.0, 1.0) = 0.1;
uniform vec2 roughness_range = vec2(0.9, 1.0);
uniform sampler2D soft_texture : source_color, filter_linear, repeat_enable;
uniform vec4 tint : source_color = vec4(1.0);
uniform float repeat_metres = 4.0;
uniform bool rectangular_texture = false;
uniform bool painted_finish = false;
uniform float emission_strength = 0.0;
uniform bool diffuser_ribs = false;
uniform int crack_variant = 0;
uniform vec3 crack_origin = vec3(0.0);
uniform float contact_strength = 0.18;
uniform vec3 sample_origin = vec3(0.0);
uniform float softness : hint_range(0.0, 1.0) = 0.5;
varying vec3 world_position;
varying vec3 world_normal;
void vertex() {
    world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    world_normal = MODEL_NORMAL_MATRIX * NORMAL;
}
float line_distance(vec2 p, vec2 a, vec2 b) {
    vec2 d = b-a;
    return length(p-a-d*clamp(dot(p-a,d)/dot(d,d),0.0,1.0));
}
float crack(vec2 p) {
    if (crack_variant == 2) p.x = -p.x;
    p += vec2(0.0, 0.45);
    float d = line_distance(p, vec2(-0.15,0.0), vec2(-0.09,0.16));
    d = min(d,line_distance(p,vec2(-0.09,0.16),vec2(-0.13,0.28)));
    d = min(d,line_distance(p,vec2(-0.13,0.28),vec2(0.02,0.47)));
    d = min(d,line_distance(p,vec2(0.02,0.47),vec2(-0.015,0.66)));
    d = min(d,line_distance(p,vec2(-0.015,0.66),vec2(0.12,0.82)));
    d = min(d,line_distance(p,vec2(0.02,0.47),vec2(0.19,0.53)));
    d = min(d,line_distance(p,vec2(0.19,0.53),vec2(0.25,0.65)));
    return (1.0-smoothstep(0.003,0.009,d))*0.22;
}
vec3 surface(vec2 uv) {
    if (rectangular_texture) uv.y *= float(textureSize(soft_texture,0).x)/float(textureSize(soft_texture,0).y);
    vec2 size = vec2(textureSize(soft_texture, 0));
    vec2 center = (floor(uv * size) + vec2(0.5)) / size;
    return mix(textureLod(soft_texture, center, 0.0).rgb, textureLod(soft_texture, uv, 0.0).rgb, softness);
}
void fragment() {
    vec3 weights = pow(abs(normalize(world_normal)), vec3(8.0));
    weights /= max(weights.x + weights.y + weights.z, 0.0001);
    vec3 p = (world_position - sample_origin) / repeat_metres;
    ALBEDO = surface(vec2(p.z, -p.y)) * weights.x
           + surface(p.xz) * weights.y
           + surface(vec2(p.x, -p.y)) * weights.z;
    if (painted_finish) ALBEDO = mix(vec3(0.8), ALBEDO, 0.5);
    if (diffuser_ribs) ALBEDO *= 0.86 + 0.14*smoothstep(0.15,0.45,fract(world_position.x*22.0));
    if (crack_variant > 0) {
        vec3 cp = world_position-crack_origin;
        vec2 coords = abs(world_normal.x)>0.5 ? vec2(cp.z, cp.y) : cp.xy;
        ALBEDO *= 1.0-crack(coords);
    }
    // Authored contact shading for this room, not screen-space AO.
    float xedge = max(0.0, 5.85 - abs(world_position.x));
    float zedge = max(0.0, 6.85 - abs(world_position.z));
    float floor_edge = min(xedge, zedge);
    float wall_edge = min(world_position.y, 4.0 - world_position.y);
    float side_edge = abs(world_normal.x) > 0.5 ? zedge : xedge;
    float contact = abs(world_normal.y) > 0.5 ? exp(-floor_edge * 4.0) : max(exp(-max(wall_edge, 0.0) * 5.0), exp(-side_edge * 4.0));
    ALBEDO *= tint.rgb * (1.0 - contact_strength * contact);
    ROUGHNESS = painted_finish ? 0.78 : 1.0;
    if (surface_maps) {
        vec2 uvx = vec2(p.z, -p.y), uvy = p.xz, uvz = vec2(p.x, -p.y);
        vec2 nx = textureLod(normal_texture,uvx,0.0).rg*2.0-1.0;
        vec2 ny = textureLod(normal_texture,uvy,0.0).rg*2.0-1.0;
        vec2 nz = textureLod(normal_texture,uvz,0.0).rg*2.0-1.0;
        // Projection directions replace mesh tangents for this world-mapped material.
        vec3 slope = vec3(0.0,-nx.y,nx.x)*weights.x
                   + vec3(ny.x,0.0,ny.y)*weights.y
                   + vec3(nz.x,-nz.y,0.0)*weights.z;
        vec3 n = normalize(world_normal);
        slope -= n*dot(n,slope);
        NORMAL = normalize((VIEW_MATRIX*vec4(normalize(n+slope*bump_strength),0.0)).xyz);
        float rough = textureLod(roughness_texture,uvx,0.0).r*weights.x
                    + textureLod(roughness_texture,uvy,0.0).r*weights.y
                    + textureLod(roughness_texture,uvz,0.0).r*weights.z;
        ROUGHNESS = clamp(mix(roughness_range.x,roughness_range.y,rough)+contact*0.04,0.0,1.0);
        SPECULAR = 0.35;
    }
    EMISSION = ALBEDO * emission_strength;
}
