shader_type canvas_item;

// Plants lean in the wind: the top of the sprite moves, the roots stay put.
uniform float strength = 1.5;
uniform float speed = 1.6;
uniform float phase = 0.0;

void vertex() {
	VERTEX.x += sin(TIME * speed + phase) * strength * (1.0 - UV.y);
}
