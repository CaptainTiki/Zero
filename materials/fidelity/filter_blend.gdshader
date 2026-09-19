shader_type spatial;
render_mode diffuse_burley;
// Use one sampler: Compatibility can share filter state for the same texture.
// Sampling exact texel centers gives the sharp endpoint without sampler aliasing.
uniform sampler2D soft_texture : source_color, filter_linear, repeat_enable;
uniform vec3 sample_origin = vec3(0.0);
uniform float softness : hint_range(0.0, 1.0) = 0.5;
varying vec3 world_position;
varying vec3 world_normal;
void vertex() {
    world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    world_normal = MODEL_NORMAL_MATRIX * NORMAL;
}
vec3 surface(vec2 uv) {
    vec2 size = vec2(textureSize(soft_texture, 0));
    vec2 center = (floor(uv * size) + vec2(0.5)) / size;
    return mix(textureLod(soft_texture, center, 0.0).rgb, textureLod(soft_texture, uv, 0.0).rgb, softness);
}
void fragment() {
    vec3 weights = pow(abs(normalize(world_normal)), vec3(8.0));
    weights /= max(weights.x + weights.y + weights.z, 0.0001);
    vec3 p = (world_position - sample_origin) * 0.25;
    ALBEDO = surface(vec2(p.z, -p.y)) * weights.x
           + surface(p.xz) * weights.y
           + surface(vec2(p.x, -p.y)) * weights.z;
    ROUGHNESS = 1.0;
}
