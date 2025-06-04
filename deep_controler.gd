class_name DeepControler
extends Node

var main_model : NeuralNetwork
var target_model : NeuralNetwork

@export var player_name := name
@export var network_layers := [4,16,16,3]

@export_category("Learning parameters")
@export var alpha = 0.1  # Learning rate 
var alpha_min = 0.001
@export var alpha_decay = 0.99999
@export var gamma = 0.9  # Discount factor
@export var epsilon = 1  # Exploration rate
@export var epsilon_decay = 0.9995
@export var epsilon_min = 0.1
@export var tau = 1.0
@export var tau_min = 0.1
@export var tau_decay = 0.9995

@export_category("Training parameters")
@export var saving_frequency = 5 #Save every 5 frames
@export var training_frequency = 500  # Train every 500 experiences
@export var target_sync_frequency = 10 #Sync target every 10 trains
@export var batch_size := 64
@export var buffer_max_capacity := 100000
@export var max_idles_in_a_row := 10
var steps_since_last_train = 0
var steps_since_last_save = 0
var trains_since_last_target_sync = 0 
var idle_actions_in_a_row := 0

@export_category("Related nodes")
@export var paddle : Paddle
@export var ball : Ball

var replay_buffer = []
var reward = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	main_model = NeuralNetwork.new(network_layers, alpha)
	
	target_model = NeuralNetwork.new(network_layers, alpha)
	
	var main_path = "user://data/"+player_name+"_main_model.save"
	var target_path = "user://data/"+player_name+"_target_model.save"
	
	if FileAccess.file_exists(main_path):
		var file = FileAccess.open(main_path, FileAccess.READ)
		if file:
			var json_text = file.get_as_text() 
			# Parse JSON only if we have valid text
			if json_text != "":
				var json = JSON.new()
				var error =json.parse(json_text)
				if error == OK:
					var data_received = json.data
					main_model.weights = data_received.weights
					main_model.biases = data_received.biases
					print("Main model loaded successfully!")
					file.close()  # Close file after reading
				else:
					print("Error parsing main model JSON")
					print("Error code:", error)  
			else:
				print("Warning: main model file is empty.")
		else:
			print("Failed to open main model file.")
	else:
		print("Main model file does not exist.")
	
	if FileAccess.file_exists(target_path):
		var file = FileAccess.open(target_path, FileAccess.READ)
		if file:
			var json_text = file.get_as_text() 
			# Parse JSON only if we have valid text
			if json_text != "":
				var json = JSON.new()
				var error =json.parse(json_text)
				if error == OK:
					var data_received = json.data
					target_model.weights = data_received.weights
					target_model.biases = data_received.biases
					print("Target model loaded successfully!")
					file.close()  # Close file after reading
					return
				else:
					print("Error parsing target model JSON")
					print("Error code:", error)  
			else:
				print("Warning: target model file is empty.")
		else:
			print("Failed to open target model file.")
	else:
		print("Target model file does not exist.")
		
	target_model.weights = main_model.weights.duplicate(true)
	target_model.biases = main_model.biases.duplicate(true)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var state = get_state()
	var result = main_model.forward(state)
	var action = choose_action(result["output"])
	move_paddle(action)
	
	if action == 0:
		idle_actions_in_a_row += 1
	else:
		idle_actions_in_a_row = 0
	
	if idle_actions_in_a_row > max_idles_in_a_row:
		update_reward(-0.1)
		
		
	
	steps_since_last_save += 1
	if steps_since_last_save > saving_frequency:
		add_to_last_experience(state)
		add_to_replay_buffer(state, action)
		steps_since_last_save = 0
	
	steps_since_last_train += 1
	if steps_since_last_train > training_frequency:
		train_model()  # Train the model
		steps_since_last_train = 0  # Reset step counter

func add_to_replay_buffer(current_state, action):
	# Store experience in the replay buffer
	replay_buffer.append({
		"state": current_state,
		"action": action,
		"reward": 0,
		"next_state": [],
		"done": false
		})
	if replay_buffer.size() > buffer_max_capacity:
		replay_buffer.pop_front() 

func add_to_last_experience(next_state):
	if replay_buffer.size() > 0:
		replay_buffer[-1]["reward"] = reward
		replay_buffer[-1]["next_state"] = next_state

func get_state():
	var ball_disc_pos = ball.get_discretized_position()
	var ball_y_bucket = ball_disc_pos.y
	var ball_x_bucket = ball_disc_pos.x
	var ball_v_bucket = ball_disc_pos.z
	var paddle_y_bucket = paddle.get_discretized_position()
	
	if paddle_y_bucket == ball_y_bucket:
		update_reward(1)
	else:
		update_reward(-0.5)
	
	return [ball_x_bucket, ball_y_bucket, ball_v_bucket, paddle_y_bucket]
	
func choose_action(output):
	if randi() % 100 < int(epsilon * 100):
		return randi() % 4 
	else:
		return boltzmann_exploration(output) 
		
func boltzmann_exploration(q_values: Array) -> int:
	var exp_q = []
	var sum_exp_q = 0.0

	# Calculate exponential values and their sum
	for q in q_values:
		var exp_val = exp(q / tau)
		exp_q.append(exp_val)
		sum_exp_q += exp_val

	# Normalize to probabilities
	var probabilities = []
	for exp_val in exp_q:
		probabilities.append(exp_val / sum_exp_q)

	# Select an action based on the probabilities
	var rand = randf()
	var cumulative = 0.0
	for i in range(probabilities.size()):
		cumulative += probabilities[i]
		if rand < cumulative:
			return i

	return argmax(q_values) # Fallback to the best q-value action
	
func train_model():
	if replay_buffer.size() < batch_size:
		return  # Not enough data to train yet
	
	alpha = max (alpha * alpha_decay, alpha_min)
	epsilon = max(epsilon * epsilon_decay, epsilon_min)
	tau = max(tau * tau_decay, tau_min)
	# Sample a random batch of experiences from the replay buffer
	var batch = get_random_batch()

	# Prepare inputs and targets for training
	var states = []
	var actions = []
	var rewards = []
	var next_states = []
	var dones = []

	for experience in batch:
		states.append(experience["state"])
		actions.append(experience["action"])
		rewards.append(experience["reward"])
		next_states.append(experience["next_state"])
		dones.append(experience["done"])
		

	# Convert the states to input data for the model
	var q_values = []  # Will hold Q-values for all states in the batch
	var next_q_values = []  # Will hold Q-values for all next states in the batch

	for state in states:
		q_values.append(main_model.forward(state)["output"])  # Process each state individually

	for next_state in next_states:
		next_q_values.append(target_model.forward(next_state)["output"]) 

	# Calculate target Q-values (Bellman equation)
	var targets = []
	for i in range(batch_size):
		var target = q_values[i].duplicate()  # Duplicate the Q-values to modify
		var action = actions[i]
		var reward = rewards[i]
		var done = dones[i]
		if done: 
			target[action] = reward
		else:
			target[action] = reward + gamma * next_q_values[i][argmax(next_q_values[i])]  # Bellman equation for target
		main_model.backpropagate(states[i],target)
		soft_update_target_network(0.1)
	
	# Hard upgrade (model sync)
	trains_since_last_target_sync+=1 
	if trains_since_last_target_sync >= target_sync_frequency:
		target_model.weights = main_model.weights.duplicate(true)
		target_model.biases = main_model.biases.duplicate(true)
		trains_since_last_target_sync = 0

func soft_update_target_network(tau: float):
	# Loop through all layers
	for l in range(main_model.weights.size()):
		# Update the weights of the target network
		for i in range(target_model.weights[l].size()):
			for j in range(target_model.weights[l][i].size()):
				target_model.weights[l][i][j] = tau * main_model.weights[l][i][j] + (1 - tau) * target_model.weights[l][i][j]
		
		for i in range(main_model.biases[l].size()):
			target_model.biases[l][i] = tau * main_model.biases[l][i] + (1 - tau) * target_model.biases[l][i]

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

func update_reward(reward_modif):
	reward += reward_modif

func save_model():
	var main_file_path = "user://data/"+player_name+"_main_model.save"
	var main_file = FileAccess.open(main_file_path, FileAccess.WRITE)
	
	var main_model_data = {
		"weights": main_model.weights,
		"biases": main_model.biases
		}
	# Convert the Q-table to a string format (JSON)
	var main_model_str = JSON.stringify(main_model_data)
	
	# Write the Q-table string to the file
	main_file.store_string(main_model_str)
	
	main_file.close()
	print("Main model saved successfully.")
	
	var target_file_path = "user://data/"+player_name+"_target_model.save"
	var target_file = FileAccess.open(target_file_path, FileAccess.WRITE)
	
	var target_model_data = {
		"weights": target_model.weights,
		"biases": target_model.biases
		}
	# Convert the Q-table to a string format (JSON)
	var target_model_str = JSON.stringify(target_model_data)
	
	# Write the Q-table string to the file
	target_file.store_string(target_model_str)
	
	target_file.close()
	print("Target model saved successfully.")

#Utils

func argmax(values):
	var max_value = values[0]
	var max_index = 0
	for i in range(1, values.size()):
		if values[i] > max_value:
			max_value = values[i]
			max_index = i
	return max_index
	
func get_random_batch():
	var batch = []
	for i in range(batch_size):
		batch.append(replay_buffer[randi() % replay_buffer.size()])
	return batch

#Signals

func _on_pong_game_match_end(winner):
	reward = 0
	if replay_buffer.size() > 0:
		replay_buffer[-1]["done"] = true

