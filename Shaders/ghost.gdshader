shader_type spatial;

render_mode blend_add, cull_disabled;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec3 fromCamera = normalize(VERTEX);
	float dir = dot(NORMAL, fromCamera);
	float rim = 1.0 - dir * dir;
	ALBEDO = vec3(0.1, 0.3, 0.2) * rim;
	// Called for every pixel the material is visible on.
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
