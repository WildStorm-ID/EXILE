shader_type canvas_item;

uniform float vignette_strength : hint_range(0.0, 1.0) = 0.55;
uniform float radius : hint_range(0.0, 1.0) = 0.68;
uniform float softness : hint_range(0.0, 1.0) = 0.32;

void fragment() {
	vec2 centered_uv = UV - vec2(0.5);
	float dist = length(centered_uv);
	float edge = smoothstep(radius, radius - softness, dist);
	float alpha = (1.0 - edge) * vignette_strength;
	COLOR = vec4(0.0, 0.0, 0.0, alpha);
}
