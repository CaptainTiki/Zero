shader_type spatial;
render_mode diffuse_burley;
// Use one sampler: Compatibility can share filter state for the same texture.
// Sampling exact texel centers gives the sharp endpoint without sampler aliasing.
uniform sampler2D normal_texture : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D roughness_texture : hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;
uniform bool surface_maps = false;
uniform float bump_strength : hint_range(0.0, 1.0) = 0.1;
uniform vec2 roughness_range = vec2(0.9, 1.0);
uniform sampler2D soft_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 tint : source_color = vec4(1.0);
uniform float repeat_metres = 4.0;
uniform bool rectangular_texture = false;
uniform bool painted_finish = false;
uniform float emission_strength = 0.0;
uniform bool diffuser_ribs = false;
uniform int crack_variant = 0;
uniform vec3 crack_origin = vec3(0.0);
uniform float contact_strength = 0.14;
uniform bool lower_paint = false;
uniform float floor_height = 0.0;
uniform float ceiling_height = 4.5;
uniform vec4 lower_tint : source_color = vec4(0.19, 0.34, 0.30, 1.0);
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
    // Preserve the chosen pixel blend while magnified. Once texels become smaller
    // than a screen pixel, use the unsnapped gradients to select stable mip levels.
    vec2 dx = dFdx(uv), dy = dFdy(uv);
    float footprint = max(length(dx * size), length(dy * size));
    float minified = smoothstep(0.5, 1.0, footprint);
    vec3 close_color = mix(textureLod(soft_texture, center, 0.0).rgb,
                           textureLod(soft_texture, uv, 0.0).rgb, softness);
    vec3 distant_color = textureGrad(soft_texture, uv, dx, dy).rgb;
    return mix(close_color, distant_color, minified);
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
    // Height-relative contact tone: no hard-coded sample-room corners in the level.
    float height = world_position.y - floor_height;
    float edge = max(0.0, min(height, ceiling_height-world_position.y));
    float contact = (1.0-weights.y)*exp(-edge*4.0);
    float broad_variation = 0.97 + 0.03*sin(world_position.x*0.31 + world_position.z*0.23)*sin(world_position.y*0.47-world_position.z*0.17);
    ALBEDO *= tint.rgb;
    if (lower_paint && height < 1.1 && weights.y < 0.5) {
        ALBEDO = lower_tint.rgb * mix(vec3(0.8), surface(vec2(p.x+p.z,-p.y)), 0.35);
    }
    ALBEDO *= broad_variation * (1.0 - contact_strength * contact);
    ROUGHNESS = painted_finish ? 0.78 : 1.0;
    if (surface_maps) {
        vec2 uvx = vec2(p.z, -p.y), uvy = p.xz, uvz = vec2(p.x, -p.y);
        vec2 nx = texture(normal_texture,uvx).rg*2.0-1.0;
        vec2 ny = texture(normal_texture,uvy).rg*2.0-1.0;
        vec2 nz = texture(normal_texture,uvz).rg*2.0-1.0;
        // Projection directions replace mesh tangents for this world-mapped material.
        vec3 slope = vec3(0.0,-nx.y,nx.x)*weights.x
                   + vec3(ny.x,0.0,ny.y)*weights.y
                   + vec3(nz.x,-nz.y,0.0)*weights.z;
        vec3 n = normalize(world_normal);
        slope -= n*dot(n,slope);
        NORMAL = normalize((VIEW_MATRIX*vec4(normalize(n+slope*bump_strength),0.0)).xyz);
        float rough = texture(roughness_texture,uvx).r*weights.x
                    + texture(roughness_texture,uvy).r*weights.y
                    + texture(roughness_texture,uvz).r*weights.z;
        ROUGHNESS = clamp(mix(roughness_range.x,roughness_range.y,rough)+contact*0.04,0.0,1.0);
        SPECULAR = 0.35;
    }
    EMISSION = ALBEDO * emission_strength;
}
