class_name Ball
extends CharacterBody2D

signal pointLeft
signal pointRight

signal pastLeft
signal pastRight

signal tap

@export var playing_field : Area2D

# Get the top and bottom boundaries of the playing field
@onready var field_top = playing_field.global_position.y - (playing_field.shape.size.y/2)
@onready var field_bottom = playing_field.global_position.y + (playing_field.shape.size.y/2)
@onready var field_left = playing_field.global_position.x - (playing_field.shape.size.x/2)
@onready var field_right = playing_field.global_position.x + (playing_field.shape.size.x/2)

const X_BUCKETS = 20
const Y_BUCKETS = 20

@onready var screen_height = field_bottom-field_top
@onready var screen_width = field_right-field_left
# Calculate bucket sizes
@onready var x_bucket_size = screen_width / X_BUCKETS
@onready var y_bucket_size = screen_height / Y_BUCKETS

var emited_past = false


var direction_velocity = Vector2(200, 0)  # Initial speed of the ball

func _ready():
	randomize()
	reset_ball()

func _process(delta):
	
	#Move and check collision with paddles
	var collision = move_and_collide(direction_velocity * delta)
	
	if collision: 
		var collider = collision.get_collider()
		direction_velocity.x = -direction_velocity.x
		
		var offset = position.y - collider.position.y
		direction_velocity.y += offset * 5  # Adjust this factor to control the angle change
		
		if collider is Paddle:
			collider.AI_controller.update_reward(5)
			tap.emit()
		
	# Reverse direction if the top of the paddle exceeds the top of the playing field
	var top_of_ball = global_position.y - ($BallShape.shape.radius/2)
	var bottom_of_ball = global_position.y + ($BallShape.shape.radius/2)

	if top_of_ball < field_top or bottom_of_ball > field_bottom:
		direction_velocity.y = -direction_velocity.y
		
	var left_of_ball = global_position.x - ($BallShape.shape.radius/2)
	var right_of_ball = global_position.x + ($BallShape.shape.radius/2)
	
	if (left_of_ball + $BallShape.shape.radius) < field_left:
		pointRight.emit()
		reset_ball()
	
	elif (right_of_ball - $BallShape.shape.radius) > field_right:
		pointLeft.emit()
		reset_ball()
		
	elif (left_of_ball + $BallShape.shape.radius) < field_left + 105 and not emited_past:
		pastLeft.emit()
		emited_past = true
	
	elif (right_of_ball - $BallShape.shape.radius) > field_right - 105 and not emited_past:
		pastRight.emit()
		emited_past = true

	

func reset_ball():
	emited_past = false
	position = get_viewport_rect().size / 2
	var reverse = -1 if randi() % 2 > 0 else 1
	direction_velocity = Vector2(400*reverse, randf_range(-150, 150))

# Function to discretize ball position
func get_discretized_position():
	var x_bucket = int(position.x / x_bucket_size)
	var y_bucket = int(position.y / y_bucket_size)
	
	# Ensure values stay within bounds
	x_bucket = clamp(x_bucket, 0, X_BUCKETS - 1)
	y_bucket = clamp(y_bucket, 0, Y_BUCKETS - 1)
	
	var v_bucket = 1 
	if direction_velocity.y >= 50: v_bucket = 2
	if direction_velocity.y <= -50: v_bucket = 0
	# Return as a string or tuple for use as state
	return Vector3i(x_bucket,y_bucket,v_bucket)
