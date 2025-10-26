class_name UIManager
extends Node

# UI Nodes
@onready var status_label: Label
@onready var turn_indicator: Label
@onready var player_x_rp_label: Label
@onready var player_o_rp_label: Label
@onready var game_board: GridContainer
@onready var win_screen: Control
@onready var win_label: Label
@onready var restart_button: Button
@onready var bot_timer: Timer

# Power-up buttons
var powerup_buttons: Dictionary = {}

# Managers
var turn_manager: TurnManager
var board_manager: BoardManager
var powerup_manager: PowerUpManager
var bot_controller: BotController

# Assets
var texture_x: Texture2D
var texture_o: Texture2D

func _ready():
	# Preload assets
	texture_x = load(GameConstants.TEXTURE_X_PATH)
	texture_o = load(GameConstants.TEXTURE_O_PATH)

# Setup managers
func setup_managers(p_turn_manager: TurnManager, p_board_manager: BoardManager,
					p_powerup_manager: PowerUpManager, p_bot_controller: BotController):
	turn_manager = p_turn_manager
	board_manager = p_board_manager
	powerup_manager = p_powerup_manager
	bot_controller = p_bot_controller

	# Connect signals
	_connect_signals()

# Setup power-up buttons
func setup_powerup_buttons(buttons: Dictionary):
	powerup_buttons = buttons

# Connect all signals
func _connect_signals():
	# Turn manager signals
	if turn_manager:
		turn_manager.turn_changed.connect(_on_turn_changed)
		turn_manager.rp_changed.connect(_on_rp_changed)

	# Powerup manager signals
	if powerup_manager:
		powerup_manager.powerup_activated.connect(_on_powerup_activated)
		powerup_manager.powerup_completed.connect(_on_powerup_completed)
		powerup_manager.powerup_cancelled.connect(_on_powerup_cancelled)
		powerup_manager.status_message.connect(_on_status_message)

	# Bot controller signals
	if bot_controller:
		bot_controller.bot_status_message.connect(_on_status_message)

	# Game board signals
	if game_board:
		_setup_board_signals()

	# Restart button
	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)

# Setup board cell signals
func _setup_board_signals():
	var cell_index = 0
	for cell_button in game_board.get_children():
		if cell_button is Button:
			cell_button.pressed.connect(_on_cell_pressed.bind(cell_index))
			cell_index += 1

# Update all UI elements
func update_ui():
	_update_info_labels()
	_update_board()
	_update_status_label()
	_update_powerup_buttons()

# Update info labels (RP, turn indicator)
func _update_info_labels():
	if turn_manager:
		player_x_rp_label.text = "RP: " + str(turn_manager.get_player_rp(GameConstants.Player.X))
		player_o_rp_label.text = "RP: " + str(turn_manager.get_player_rp(GameConstants.Player.O))
		turn_indicator.text = "Giliran: " + HelperFunctions.get_player_symbol_str(turn_manager.get_current_turn())

# Update board display
func _update_board():
	if not board_manager or not game_board:
		return

	var can_player_interact = _can_player_interact()
	var cell_index = 0

	for cell_button in game_board.get_children():
		if cell_button is Button:
			cell_button.disabled = not can_player_interact
			cell_button.text = ""  # Hapus teks, kita pakai icon

			var symbol = board_manager.get_symbol(cell_index)
			var base_symbol = HelperFunctions.get_base_symbol(symbol)

			# Set icon berdasarkan simbol
			if base_symbol == "X":
				cell_button.icon = texture_x
			elif base_symbol == "O":
				cell_button.icon = texture_o
			else:
				cell_button.icon = null

			# Set warna
			var color = HelperFunctions.get_player_color(base_symbol)
			cell_button.modulate = color

			# Tanda shield
			if powerup_manager and cell_index == powerup_manager.shielded_cell:
				cell_button.text = "[S]"

			cell_index += 1

# Update status label
func _update_status_label():
	var status_text = ""

	if not board_manager or not turn_manager:
		return

	if bot_controller and bot_controller.is_bot_thinking:
		status_text = "Player O (Bot) sedang berpikir..."
	else:
		status_text = "Giliran " + HelperFunctions.get_player_symbol_str(turn_manager.get_current_turn()) + " untuk melangkah."

	# Tambahkan status power-up
	if powerup_manager:
		match powerup_manager.get_active_powerup():
			GameConstants.PowerUpState.ERASE:
				status_text = "Mode: HAPUS\nPilih sel LAWAN!"
			GameConstants.PowerUpState.SHIELD:
				status_text = "Mode: SHIELD\nPilih sel KOSONG!"
			GameConstants.PowerUpState.GOLDEN:
				status_text = "Mode: GOLDEN MARK\nPilih sel KOSONG!"
			GameConstants.PowerUpState.DOUBLE_1:
				status_text = "Mode: DOUBLE MOVE (1/2)\nPilih sel KOSONG!"
			GameConstants.PowerUpState.DOUBLE_2:
				status_text = "Mode: DOUBLE MOVE (2/2)\nPilih sel KOSONG!"
			GameConstants.PowerUpState.SWAP_1:
				status_text = "Mode: SWAP (1/2)\nPilih sel PERTAMA (berisi)!"
			GameConstants.PowerUpState.SWAP_2:
				status_text = "Mode: SWAP (2/2)\nPilih sel KEDUA (berisi)!"

	status_label.text = status_text

# Update power-up buttons
func _update_powerup_buttons():
	if not turn_manager or not powerup_manager:
		return

	_update_powerup_button_style(GameConstants.PowerUpState.SHIELD, GameConstants.SHIELD_COST)
	_update_powerup_button_style(GameConstants.PowerUpState.ERASE, GameConstants.ERASE_COST)
	_update_powerup_button_style(GameConstants.PowerUpState.GOLDEN, GameConstants.GOLDEN_COST)
	_update_powerup_button_style(GameConstants.PowerUpState.DOUBLE_1, GameConstants.DOUBLE_COST)
	_update_powerup_button_style(GameConstants.PowerUpState.SWAP_1, GameConstants.SWAP_COST)

	# Update button text
	if powerup_buttons.has(GameConstants.PowerUpState.SHIELD):
		powerup_buttons[GameConstants.PowerUpState.SHIELD].get_node("VBoxContainer/Label").text = "Shield\n(%d RP)" % GameConstants.SHIELD_COST
	if powerup_buttons.has(GameConstants.PowerUpState.ERASE):
		powerup_buttons[GameConstants.PowerUpState.ERASE].get_node("VBoxContainer/Label").text = "Erase\n(%d RP)" % GameConstants.ERASE_COST
	if powerup_buttons.has(GameConstants.PowerUpState.GOLDEN):
		powerup_buttons[GameConstants.PowerUpState.GOLDEN].get_node("VBoxContainer/Label").text = "Golden\n(%d RP)" % GameConstants.GOLDEN_COST
	if powerup_buttons.has(GameConstants.PowerUpState.DOUBLE_1):
		powerup_buttons[GameConstants.PowerUpState.DOUBLE_1].get_node("VBoxContainer/Label").text = "Double\n(%d RP)" % GameConstants.DOUBLE_COST
	if powerup_buttons.has(GameConstants.PowerUpState.SWAP_1):
		powerup_buttons[GameConstants.PowerUpState.SWAP_1].get_node("VBoxContainer/Label").text = "Swap\n(%d RP)" % GameConstants.SWAP_COST

# Update individual power-up button style
func _update_powerup_button_style(powerup_state: GameConstants.PowerUpState, cost: int):
	if not powerup_buttons.has(powerup_state):
		return

	var button = powerup_buttons[powerup_state]
	var current_rp = turn_manager.get_current_player_rp()
	var can_player_interact = _can_player_interact()

	button.disabled = not can_player_interact or current_rp < cost

	if button.disabled:
		button.self_modulate = GameConstants.DARK_COLOR
	else:
		button.self_modulate = GameConstants.NORMAL_COLOR

# Check if player can interact
func _can_player_interact() -> bool:
	if not turn_manager or not bot_controller:
		return false

	return not bot_controller.is_bot_thinking and not (bot_controller.is_bot_active and turn_manager.get_current_turn() == GameConstants.Player.O)

# Show win screen
func show_win_screen(winner_player: GameConstants.Player, win_by_rp: bool = false):
	if not win_screen or not win_label:
		return

	win_screen.visible = true

	if winner_player == GameConstants.Player.DRAW:
		win_label.text = "PERMAINAN SERI!"
	else:
		var win_text = "PLAYER " + HelperFunctions.get_player_symbol_str(winner_player) + " MENANG!"
		if win_by_rp:
			win_text = "PLAYER " + HelperFunctions.get_player_symbol_str(winner_player) + " MENANG!\n(RP Terbanyak)"
		win_label.text = win_text

# Hide win screen
func hide_win_screen():
	if win_screen:
		win_screen.visible = false

# ===================================================================
#   SIGNAL HANDLERS
# ===================================================================

func _on_cell_pressed(_index: int):
	# This will be handled by the main game manager
	pass

func _on_turn_changed(_new_player: GameConstants.Player):
	update_ui()

func _on_rp_changed(_player: GameConstants.Player, _new_amount: int):
	update_ui()

func _on_powerup_activated(_powerup_type: GameConstants.PowerUpState):
	update_ui()

func _on_powerup_completed(_powerup_type: GameConstants.PowerUpState):
	update_ui()

func _on_powerup_cancelled():
	update_ui()

func _on_status_message(message: String):
	status_label.text = message

func _on_restart_pressed():
	# This will be handled by the main game manager
	pass