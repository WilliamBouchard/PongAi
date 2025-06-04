extends Node2D

signal match_end(winner)

@export var left_paddle: Paddle
@export var right_paddle : Paddle
@export var ball : Ball
@export var score_left_label : Label
@export var score_right_label : Label

@export var match_left_label : Label
@export var match_right_label : Label
@export var total_match_label : Label

@export var points_per_match := 12

var total_taps = 0

var right_score = 0:
	set(value):
		right_score = value
		score_right_label.text = str(right_score)
var left_score = 0:
	set(value):
		left_score = value
		score_left_label.text = str(left_score)

var right_match = 0:
	set(value):
		total_match += value-right_match
		right_match = value
		match_right_label.text = str(right_match)
var left_match = 0:
	set(value):
		total_match += value-left_match
		left_match = value
		match_left_label.text = str(left_match)

var total_match = 0:
	set(value):
		total_match = value
		total_match_label.text = str(total_match)

func _ready():
	if not DirAccess.dir_exists_absolute("user://data"):
		DirAccess.make_dir_recursive_absolute("user://data")
		
	if not DirAccess.dir_exists_absolute("user://logs"):
		DirAccess.make_dir_recursive_absolute("user://logs")
	
	var file_path = "user://logs/matches.txt"

	if !FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.WRITE)
		file.store_line("PongAI Matches Log")
		file.close()

func _on_ball_point_left():
	left_paddle.reset_paddle()
	right_paddle.reset_paddle()
	left_score += 1
	
	left_paddle.AI_controller.update_reward(10)
	right_paddle.AI_controller.update_reward(-10)

	if left_score >= points_per_match:
		finish_match("left")
		
func _on_ball_point_right():
	left_paddle.reset_paddle()
	right_paddle.reset_paddle()
	
	right_score += 1
	
	left_paddle.AI_controller.update_reward(-10)
	right_paddle.AI_controller.update_reward(10)
	
	if right_score >= points_per_match:
		finish_match("right")

func finish_match(winner):
	if winner == "right": 
		right_match +=1
		right_paddle.AI_controller.update_reward(50)
		left_paddle.AI_controller.update_reward(-50)
	elif winner == "left": 
		left_match += 1
		right_paddle.AI_controller.update_reward(-50)
		left_paddle.AI_controller.update_reward(50)

	var match_log_file = FileAccess.open("user://logs/matches.txt", FileAccess.READ_WRITE)	
	match_log_file.seek_end()
	var log_line = "Match #"+str(total_match)+ " Winner: " + winner + " Score: " +str(left_score)+"-"+str(right_score) + " L-reward: "+str(left_paddle.AI_controller.reward)+" R-reward: "+str(right_paddle.AI_controller.reward) + " Total taps: " + str(total_taps)
	match_log_file.store_line(log_line)
	match_log_file.close()
	
	right_score = 0
	left_score = 0
	total_taps = 0
	
	if total_match % 10 == 0:
		left_paddle.AI_controller.save_model()
		right_paddle.AI_controller.save_model()
	
	match_end.emit(winner)


func _on_ball_past_right():
	var distance = abs(right_paddle.get_discretized_position() - ball.get_discretized_position().y)
	var penalty = -5 * (distance / float(right_paddle.Y_BUCKETS))
	right_paddle.AI_controller.update_reward(penalty)
	left_paddle.AI_controller.update_reward(-1*penalty)


func _on_ball_past_left():
	var distance = abs(left_paddle.get_discretized_position() - ball.get_discretized_position().y)
	var penalty = -5 * (distance / float(left_paddle.Y_BUCKETS))
	left_paddle.AI_controller.update_reward(penalty)
	right_paddle.AI_controller.update_reward(-1*penalty)


func _on_ball_tap():
	total_taps += 1
