extends CollisionShape2D  # Or Control, depending on your setup

# Paddle size
var bg_size = shape.size

func _process(delta):
	queue_redraw()

func _draw():
	# Define the rectangle's position and size
	var rect = Rect2(Vector2.ZERO, bg_size)
	
	# Draw a white rectangle
	draw_rect(rect, Color(0, 0, 0))  # RGB (1,1,1) makes the rectangle white
