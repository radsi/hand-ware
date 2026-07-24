shader_type canvas_item;

uniform float shake_amount : hint_range(0.0, 20.0) = 0.0;
uniform float shake_speed : hint_range(0.0, 50.0) = 25.0;

void vertex() {
	float t = TIME * shake_speed;

	vec2 shake = vec2(
		sin(t * 1.7),
		cos(t * 2.3)
	) * shake_amount;

	VERTEX += shake;
}