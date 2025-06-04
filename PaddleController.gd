class_name PaddleController
extends Node

enum Action {
	STAY,
	MOVE_UP,
	MOVE_DOWN
}

# Number of buckets for each variable
var ball_x_buckets = 20  # Discretized positions for ball's x-coordinate
var ball_y_buckets = 20  # Discretized positions for ball's y-coordinate
var ball_v_buckets = 3
var paddle_y_buckets = 20  # Discretized positions for paddle's y-coordinate

@export var player_name : String

@export_category("Learning parameters")
@export var alpha = 0.2  # Learning rate
@export var gamma = 0.8  # Discount factor
@export var epsilon = 0.1  # Exploration rate
@export var episodes = 1000  # Number of episodes for training

@export_category("Related nodes")
@export var paddle : Paddle
@export var ball : Ball



# Q-table dictionary
var q_table = {}

# Actions: 0 = stay, 1 = move up, 2 = move down
var actions = [Action.STAY, Action.MOVE_UP, Action.MOVE_DOWN]

func _ready():
	
	var qtable_path = "user://data/"+player_name+"_q_table.save"
	
	if FileAccess.file_exists(qtable_path):
		var file = FileAccess.open(qtable_path, FileAccess.READ)
		if file:
			var json_text = file.get_as_text() 
			# Parse JSON only if we have valid text
			if json_text != "":
				var json = JSON.new()
				var error =json.parse(json_text)
				if error == OK:
					var data_received = json.data
					q_table = data_received
					print("Q-table loaded successfully!")
					file.close()  # Close file after reading
					return
				else:
					print("Error parsing Q-table JSON")
					print("Error code:", error)  
			else:
				print("Warning: Q-table file is empty.")
		else:
			print("Failed to open Q-table file.")
	else:
		print("Q-table file does not exist.")
		initialize_q_table()

var previous_state = str(Vector4i())
var reward = 0

func _process(delta):	
	var state = get_state()
	var action = choose_action(state, epsilon)
	move_paddle(action)
	var next_state = get_state()
	previous_state = next_state	
	
func initialize_q_table():
	for ball_x in range(ball_x_buckets):
		for ball_y in range(ball_y_buckets):
			for paddle_y in range(paddle_y_buckets):
				for ball_v in range(ball_v_buckets):
					var state = str(Vector4i(ball_x, ball_y, paddle_y, ball_v))
					q_table[state] = [0, 0, 0]  

func get_state():
	var ball_disc_pos = ball.get_discretized_position()
	var ball_y_bucket = ball_disc_pos.y
	var ball_x_bucket = ball_disc_pos.x
	var ball_v_bucket = ball_disc_pos.z
	var paddle_y_bucket = paddle.get_discretized_position()
	
	return str(Vector4i(ball_x_bucket, ball_y_bucket, paddle_y_bucket, ball_v_bucket)) 

func move_paddle(action):
	match action:
		0:
			paddle.is_moving = false
		1: 
			paddle.is_moving = true
			paddle.is_going_up = true
		2:	
			paddle.is_moving = true
			paddle.is_going_up = false

func choose_action(state, epsilon):
	if randi() % 100 < int(epsilon * 100):
		return randi() % 3 
	else:
		return argmax(q_table[state]) 

func update_q_table(state, action, next_state):
	var max_future_q = q_table[next_state][argmax(q_table[next_state])]  # Max Q-value for next state
	q_table[state][action] += alpha * (reward + gamma * max_future_q - q_table[state][action])

func update_reward(reward_modif):
	reward += reward_modif

func argmax(values):
	var max_value = values[0]
	var max_index = 0
	for i in range(1, values.size()):
		if values[i] > max_value:
			max_value = values[i]
			max_index = i
	return max_index

func _on_pong_game_match_end(winner):
	reward = 0
	
func save_q_table():
	var file_path = "user://data/"+player_name+"_q_table.save"
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	 
	# Convert the Q-table to a string format (JSON)
	var q_table_str = JSON.stringify(q_table)
	
	# Write the Q-table string to the file
	file.store_string(q_table_str)
	
	file.close()
	print("Q-table saved successfully.")

