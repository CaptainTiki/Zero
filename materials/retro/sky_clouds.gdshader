shader_type sky;
// Flat-shaded sky with drifting noise clouds. No textures; runs in Compatibility.

uniform vec3 top_color : source_color = vec3(0.36, 0.5, 0.72);
uniform vec3 horizon_color : source_color = vec3(0.86, 0.74, 0.6);
uniform vec3 ground_color : source_color = vec3(0.22, 0.2, 0.18);
uniform vec3 cloud_color : source_color = vec3(1.0, 0.97, 0.92);
uniform vec3 cloud_shadow : source_color = vec3(0.66, 0.64, 0.66);
uniform float cloud_cover : hint_range(0.0, 1.0) = 0.42;
uniform float cloud_speed = 0.012;
uniform float cloud_scale = 1.1;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float amp = 0.5;
	for (int i = 0; i < 3; i++) {
		v += amp * noise(p);
		p = p * 2.03 + vec2(17.0, 9.0);
		amp *= 0.5;
	}
	return v;
}

void sky() {
	float h = EYEDIR.y;
	vec3 col = mix(horizon_color, top_color, clamp(pow(max(h, 0.0), 0.55), 0.0, 1.0));
	if (h < 0.0) {
		col = mix(horizon_color, ground_color, clamp(-h * 3.0, 0.0, 1.0));
	}
	if (LIGHT0_ENABLED) {
		float sun = max(dot(EYEDIR, LIGHT0_DIRECTION), 0.0);
		col += LIGHT0_COLOR * (pow(sun, 900.0) * 6.0 + pow(sun, 8.0) * 0.12);
	}
	if (h > 0.01) {
		// Project onto a cloud plane so clouds flatten toward the horizon.
		vec2 uv = EYEDIR.xz / (h + 0.18) * 0.9 * cloud_scale + vec2(TIME * cloud_speed, TIME * cloud_speed * 0.35);
		float n = fbm(uv) / 0.875; // three octaves sum to 0.875
		// fbm sits around 0.5; slide the threshold with cover so 0.4 reads as scattered cumulus.
		float threshold = 0.64 - cloud_cover * 0.4;
		float cover = smoothstep(threshold, threshold + 0.26, n);
		float fade = smoothstep(0.01, 0.22, h);
		float shade = fbm(uv * 1.6 + vec2(0.3, 0.7)) / 0.875;
		vec3 cc = mix(cloud_shadow, cloud_color, smoothstep(0.35, 0.75, shade));
		col = mix(col, cc, cover * fade * 0.92);
	}
	COLOR = col;
}
