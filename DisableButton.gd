extends Button

var is_disabled = false:
	set(value):
		is_disabled = value
		if is_disabled: 
			text = "Enable learning"
			get_parent().epsilon = 0
		else: 
			text = "Disable learning"
			get_parent().epsilon = 0.1


func _on_pressed():
	is_disabled = !is_disabled
