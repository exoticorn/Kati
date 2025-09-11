shader_type spatial;

render_mode blend_premul_alpha, unshaded;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec3 normal = normalize((INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz - NODE_POSITION_WORLD);
	float a = (0.5 + 0.5 * sin(length(normal.xy) * 10.0 + TIME));
	ALBEDO = vec3(0.0, 0.0, 0.05) * (1.0 - a);
	ALPHA = a * 0.5;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
