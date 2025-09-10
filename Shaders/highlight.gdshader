shader_type spatial;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec3 pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float f = mod(dot(pos, vec3(0.25, 0.5, 0.04)) + TIME, 2.0);
	f = smoothstep(0.885, 0.9, f) * smoothstep(1.15, 1.0, f) * 0.2;
	ALBEDO = vec3(0.3, 0.4, 0.5);
	ALPHA = f;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
