shader_type spatial;
render_mode cull_disabled;
uniform sampler2D undercoat : source_color, filter_linear, repeat_enable;
uniform vec4 pigment : source_color = vec4(0.23, 0.20, 0.15, 0.25);
uniform bool chipped = false;
uniform float seed = 0.0;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7)) + seed) * 43758.5453); }
float noise(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i+vec2(1,0)), f.x), mix(hash(i+vec2(0,1)), hash(i+vec2(1,1)), f.x), f.y);
}
void fragment() {
    vec2 uv = floor(UV * 64.0) / 64.0;
    float r = length((uv - 0.5) * 2.0);
    float n = noise(uv * 9.0) * 0.19 + noise(uv * 23.0) * 0.08;
    float mask = chipped ? 1.0-smoothstep(0.64, 0.69, r+n+noise(uv*17.0)*0.20) : 1.0-smoothstep(0.15, 0.95, r+n);
    vec2 size = vec2(textureSize(undercoat, 0));
    vec2 center = (floor(UV*size)+0.5)/size;
    vec3 tex = mix(textureLod(undercoat, center, 0.0).rgb, textureLod(undercoat, UV, 0.0).rgb, 0.5);
    ALBEDO = chipped ? tex * pigment.rgb : pigment.rgb;
    ALPHA = mask * pigment.a;
    ROUGHNESS = 1.0;
}
