extends Panel

func _ready():
	# Set warna background panel
	self_modulate = Color(0.1, 0.1, 0.2, 0.95)

	# Connect close button
	var close_button = get_node("MarginContainer/VBoxContainer/CloseButton")
	if close_button:
		close_button.pressed.connect(_on_close_pressed)

	# Set warna buttons
	if close_button:
		close_button.modulate = Color(1, 1, 1, 1)

	# Set warna labels
	_set_label_colors()

func _set_label_colors():
	var container = get_node("MarginContainer/VBoxContainer")
	for child in container.get_children():
		if child is Label:
			child.modulate = Color(1, 1, 1, 1)

func _on_close_pressed():
	queue_free()

# Fungsi untuk close dengan ESC key
func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			queue_free()