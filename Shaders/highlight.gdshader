shader_type spatial;

render_mode unshaded, blend_premul_alpha;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec3 pos = VERTEX - NODE_POSITION_VIEW;
	float fresnel = pow(1.0 - clamp( dot( NORMAL, VIEW ), 0.0, 1.0 ), 2.0);
	float f = pow(min(length(pos) * 2.0, 1.0), 1.0);
	ALBEDO = vec3(0.1, 0.6, 0.2)*0.3 * fresnel;//d * (0.2 + fresnel * 0.5);
	ALPHA = f;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
