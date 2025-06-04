class_name Paddle
extends CharacterBody2D

@export var speed := 600
@export var playing_field : Area2D
@export var AI_controller : Node

const Y_BUCKETS = 20

# Get the top and bottom boundaries of the playing field
@onready var field_top = playing_field.global_position.y - (playing_field.shape.size.y/2)
@onready var field_bottom = playing_field.global_position.y + (playing_field.shape.size.y/2)
@onready var screen_height = field_bottom-field_top

@onready var y_bucket_size = screen_height / Y_BUCKETS

var is_moving := true
var is_going_up := true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# Only move if is_moving is true
	if is_moving:
		var top_of_paddle = global_position.y - $CollisionShape2D.shape.extents.y
		var bottom_of_paddle = global_position.y + $CollisionShape2D.shape.extents.y
		if top_of_paddle >= field_top and bottom_of_paddle <= field_bottom:
		# Determine the direction based on is_going_up
			var direction = -1 if is_going_up else 1
			# Move the paddle vertically
			position.y += direction * speed * delta
		elif top_of_paddle < field_top:
			global_position.y = field_top + $CollisionShape2D.shape.extents.y
		elif bottom_of_paddle > field_bottom:
			global_position.y = field_bottom - $CollisionShape2D.shape.extents.y

func reverse_direction():
	is_going_up = not is_going_up		

func reset_paddle():
	position.y = get_viewport_rect().size.y / 2
	
func get_discretized_position():
	var y_bucket = int(position.y / y_bucket_size)
	y_bucket = clamp(y_bucket, 0, Y_BUCKETS - 1)
	
	return y_bucket

