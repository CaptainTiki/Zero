shader_type spatial;
render_mode diffuse_lambert, specular_disabled;
uniform sampler2D surface_texture : source_color, filter_nearest_mipmap, repeat_enable;
uniform vec4 tint : source_color = vec4(1.0);
uniform float texels_per_metre = 24.0;
varying vec3 world_position;
varying vec3 world_normal;
void vertex() {
 world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
 world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}
void fragment() {
 vec3 p = floor(world_position * texels_per_metre) / texels_per_metre;
 vec3 n = abs(world_normal);
 vec2 uv = p.xz;
 if (n.x > n.y && n.x > n.z) { uv = p.zy; }
 else if (n.z > n.y) { uv = p.xy; }
 vec3 painted = texture(surface_texture, uv / 4.0).rgb;
 float grey = dot(painted, vec3(0.299, 0.587, 0.114));
 vec3 albedo = mix(vec3(grey), painted, 0.48) * tint.rgb;
 // Ground-contact grime on vertical faces gives walls a base without new textures.
 if (n.y < 0.5) {
  albedo *= mix(0.68, 1.0, smoothstep(0.0, 1.6, world_position.y));
 }
 ALBEDO = albedo;
 ROUGHNESS = 1.0;
}
