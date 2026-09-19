shader_type spatial;
render_mode cull_disabled, diffuse_burley;
uniform sampler2D metal_texture : source_color, filter_linear, repeat_enable;
uniform vec2 panel_size = vec2(2.0);
uniform float grid_pitch = 0.10;
uniform float bar_width = 0.015;
varying vec3 world_position;
void vertex() { world_position = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz; }
void fragment() {
    vec2 p = UV * panel_size;
    vec2 d = (0.5-abs(fract(p/grid_pitch)-0.5))*grid_pitch;
    float aa = max(length(fwidth(p))*0.45,0.0003);
    float bars = 1.0-smoothstep(bar_width*0.5-aa,bar_width*0.5+aa,min(d.x,d.y));
    // Resolve to a solid distant surface when holes are smaller than a pixel.
    ALPHA = mix(bars,1.0,smoothstep(0.025,0.07,aa));
    ALPHA_SCISSOR_THRESHOLD = 0.5;
    ALBEDO = mix(vec3(0.4),texture(metal_texture,world_position.xz*1.25).rgb,0.3)*vec3(0.36,0.44,0.43);
    ROUGHNESS = 0.86;
    SPECULAR = 0.25;
}
