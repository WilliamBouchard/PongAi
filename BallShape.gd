class_name BallShape
extends CollisionShape2D  # Or Control, depending on your setup

# ball size
var ball_radius = shape.radius

func _process(delta):
	queue_redraw()

func _draw():
	# Define the rectangle's position and size
	var origin = Vector2(-ball_radius/2, -ball_radius/2)
	# Draw a white rectangle
	draw_circle(origin, ball_radius, Color.WHITE)
