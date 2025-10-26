# Start Menu Controller
# Mengatur start menu dengan navigasi ke game dan exit

class_name StartMenu
extends Control

# Node references
@onready var start_button: Button = $VBoxContainer/StartButton
@onready var exit_button: Button = $VBoxContainer/ExitButton
@onready var title_label: Label = $VBoxContainer/Title
@onready var subtitle_label: Label = $VBoxContainer/Subtitle

# Scene references
const game_scene_path = "res://scenes/main/game_screen.tscn"

# Animation variables
var hover_scale: float = 1.1
var normal_scale: float = 1.0
var animation_speed: float = 0.2

func _ready():
	_setup_buttons()
	_setup_animations()

# Setup button signals
func _setup_buttons():
	start_button.pressed.connect(_on_start_button_pressed)
	exit_button.pressed.connect(_on_exit_button_pressed)

	# Hover effects
	start_button.mouse_entered.connect(_on_button_hovered.bind(start_button))
	start_button.mouse_exited.connect(_on_button_exited.bind(start_button))
	exit_button.mouse_entered.connect(_on_button_hovered.bind(exit_button))
	exit_button.mouse_exited.connect(_on_button_exited.bind(exit_button))

# Setup button pivot untuk center scaling
func _setup_button_pivot(button: Button):
	# Set pivot offset ke tengah button
	await get_tree().process_frame  # Tunggu hingga ukuran final
	var button_size = button.size
	button.pivot_offset = button_size / 2

# Setup label pivot untuk center scaling
func _setup_label_pivot(label: Label):
	# Set pivot offset ke tengah label
	await get_tree().process_frame  # Tunggu hingga ukuran final
	var label_size = label.size
	label.pivot_offset = label_size / 2

# Setup initial animations
func _setup_animations():
	# Initial scale
	start_button.scale = Vector2(normal_scale, normal_scale)
	exit_button.scale = Vector2(normal_scale, normal_scale)

	# Set pivot point ke tengah untuk center scaling
	_setup_button_pivot(start_button)
	_setup_button_pivot(exit_button)
	_setup_label_pivot(title_label)
	_setup_label_pivot(subtitle_label)

	# Animate title entrance
	_animate_title_entrance()

# Start button handler
func _on_start_button_pressed():
	_play_click_animation(start_button)

	# Add delay for better feel
	await get_tree().create_timer(0.2).timeout

	# Load game scene
	get_tree().change_scene_to_file(game_scene_path)

# Exit button handler
func _on_exit_button_pressed():
	_play_click_animation(exit_button)

	# Add delay for better feel
	await get_tree().create_timer(0.2).timeout

	# Exit the game
	get_tree().quit()

# Button hover effects
func _on_button_hovered(button: Button):
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(button, "scale", Vector2(hover_scale, hover_scale), animation_speed)

func _on_button_exited(button: Button):
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(button, "scale", Vector2(normal_scale, normal_scale), animation_speed)

# Click animation
func _play_click_animation(button: Button):
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_SPRING)

	# Scale down then up
	tween.tween_property(button, "scale", Vector2(0.9, 0.9), 0.1)
	tween.tween_property(button, "scale", Vector2(normal_scale, normal_scale), 0.1)

# Title entrance animation
func _animate_title_entrance():
	# Animate title
	title_label.modulate.a = 0.0
	title_label.scale = Vector2(0.5, 0.5)

	var title_tween = create_tween()
	title_tween.set_ease(Tween.EASE_OUT)
	title_tween.set_trans(Tween.TRANS_BACK)
	title_tween.tween_property(title_label, "modulate:a", 1.0, 0.5)
	title_tween.parallel().tween_property(title_label, "scale", Vector2(1.0, 1.0), 0.5)

	# Animate subtitle with delay
	subtitle_label.modulate.a = 0.0
	subtitle_label.scale = Vector2(0.8, 0.8)

	await get_tree().create_timer(0.3).timeout

	var subtitle_tween = create_tween()
	subtitle_tween.set_ease(Tween.EASE_OUT)
	subtitle_tween.set_trans(Tween.TRANS_BACK)
	subtitle_tween.tween_property(subtitle_label, "modulate:a", 1.0, 0.4)
	subtitle_tween.parallel().tween_property(subtitle_label, "scale", Vector2(1.0, 1.0), 0.4)

	# Animate buttons with stagger
	await get_tree().create_timer(0.2).timeout

	start_button.modulate.a = 0.0
	start_button.position.y += 50

	var start_tween = create_tween()
	start_tween.set_ease(Tween.EASE_OUT)
	start_tween.set_trans(Tween.TRANS_BACK)
	start_tween.tween_property(start_button, "modulate:a", 1.0, 0.3)
	start_tween.parallel().tween_property(start_button, "position:y", start_button.position.y - 50, 0.3)

	await get_tree().create_timer(0.1).timeout

	exit_button.modulate.a = 0.0
	exit_button.position.y += 50

	var exit_tween = create_tween()
	exit_tween.set_ease(Tween.EASE_OUT)
	exit_tween.set_trans(Tween.TRANS_BACK)
	exit_tween.tween_property(exit_button, "modulate:a", 1.0, 0.3)
	exit_tween.parallel().tween_property(exit_button, "position:y", exit_button.position.y - 50, 0.3)

# Keyboard shortcuts
func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
			_on_start_button_pressed()
		elif event.keycode == KEY_ESCAPE:
			_on_exit_button_pressed()