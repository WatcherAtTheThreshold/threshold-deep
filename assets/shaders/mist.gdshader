shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix;

// Rolling doorway mist with feathered edges: alpha falls off toward
// the quad's sides (no hard cut on wonky doorways) and thins toward
// the top.

uniform sampler2D mist_tex: source_color;
uniform vec4 tint: source_color = vec4(0.72, 0.85, 1.0, 0.55);
uniform vec2 scroll = vec2(0.03, 0.05);

void fragment() {
	vec2 uv = UV + scroll * TIME;
	vec4 tex = texture(mist_tex, uv);
	float edge_x = smoothstep(0.0, 0.2, UV.x) * smoothstep(1.0, 0.8, UV.x);
	float top_fade = smoothstep(0.0, 0.3, UV.y);
	ALBEDO = tex.rgb * tint.rgb;
	ALPHA = tex.a * tint.a * edge_x * top_fade;
}
