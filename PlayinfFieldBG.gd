extends CollisionShape2D  


var paddle_size = shape.size

func _process(delta):
	queue_redraw()

func _draw():
	var origin = Vector2(-paddle_size.x/2, -paddle_size.y/2)
	var rect = Rect2(origin, paddle_size)
	
	draw_rect(rect, Color(0.1, 0.1, 0.1))  
