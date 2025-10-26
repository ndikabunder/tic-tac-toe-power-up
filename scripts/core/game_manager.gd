class_name GameManager
extends Node

# ===================================================================
#   MANAGERS
# ===================================================================
var board_manager: BoardManager
var turn_manager: TurnManager
var powerup_manager: PowerUpManager
var bot_controller: BotController
var ui_manager: UIManager

# ===================================================================
#   GAME STATE
# ===================================================================
var game_active: bool = true
@export var is_bot_active: bool = true

# ===================================================================
#   NODE REFERENCES
# ===================================================================
@onready var status_label = $MainVBox/StatusLabel
@onready var turn_indicator = $MainVBox/Header/VBoxContainer/TurnIndicator
@onready var player_x_rp_label = $MainVBox/Header/PlayerX_Info/VBox/PlayerX_RP_Label
@onready var player_o_rp_label = $MainVBox/Header/PlayerO_Info/VBox/PlayerO_RP_Label
@onready var game_board = $MainVBox/BoardArea/GameBoard
@onready var win_screen = $WinScreen
@onready var win_label = $WinScreen/VBox/WinLabel
@onready var restart_button = $WinScreen/VBox/RestartButton
@onready var bot_timer = $BotTimer

# ===================================================================
#   READY AND INITIALIZATION
# ===================================================================
func _ready():
	_initialize_managers()
	_setup_ui_connections()
	_setup_powerup_buttons()
	_setup_bot_timer()
	reset_game()

func _initialize_managers():
	# Create managers in dependency order
	board_manager = BoardManager.new()
	turn_manager = TurnManager.new()
	powerup_manager = PowerUpManager.new(turn_manager, board_manager)
	bot_controller = BotController.new(board_manager, turn_manager, powerup_manager)
	ui_manager = UIManager.new()

	# Add UI manager to scene tree
	add_child(ui_manager)

	# Setup UI manager with references
	ui_manager.setup_managers(turn_manager, board_manager, powerup_manager, bot_controller)

	# Set UI nodes
	ui_manager.status_label = status_label
	ui_manager.turn_indicator = turn_indicator
	ui_manager.player_x_rp_label = player_x_rp_label
	ui_manager.player_o_rp_label = player_o_rp_label
	ui_manager.game_board = game_board
	ui_manager.win_screen = win_screen
	ui_manager.win_label = win_label
	ui_manager.restart_button = restart_button
	ui_manager.bot_timer = bot_timer

	# Set bot controller active state
	bot_controller.set_bot_active(is_bot_active)

func _setup_ui_connections():
	# Connect game signals to UI
	if ui_manager:
		ui_manager.game_board = game_board
		ui_manager.restart_button = restart_button

	# Connect button signals manually (overriding UI manager's empty handlers)
	if restart_button:
		restart_button.pressed.disconnect(_on_restart_pressed)
		restart_button.pressed.connect(reset_game)

	# Connect board signals
	if game_board:
		var cell_index = 0
		for cell_button in game_board.get_children():
			if cell_button is Button:
				cell_button.pressed.disconnect(_on_cell_pressed)
				cell_button.pressed.connect(_on_cell_pressed.bind(cell_index))
				cell_index += 1

func _setup_powerup_buttons():
	var buttons = {
		GameConstants.PowerUpState.SHIELD: $MainVBox/PowerUpBar/PowerUpGrid/PowerUp_Shield,
		GameConstants.PowerUpState.ERASE: $MainVBox/PowerUpBar/PowerUpGrid/PowerUp_Erase,
		GameConstants.PowerUpState.GOLDEN: $MainVBox/PowerUpBar/PowerUpGrid/PowerUp_Golden,
		GameConstants.PowerUpState.DOUBLE_1: $MainVBox/PowerUpBar/PowerUpGrid/PowerUp_Double,
		GameConstants.PowerUpState.SWAP_1: $MainVBox/PowerUpBar/PowerUpGrid/PowerUp_Swap
	}

	ui_manager.setup_powerup_buttons(buttons)

	# Connect power-up button signals
	buttons[GameConstants.PowerUpState.SHIELD].pressed.connect(_on_powerup_shield_pressed)
	buttons[GameConstants.PowerUpState.ERASE].pressed.connect(_on_powerup_erase_pressed)
	buttons[GameConstants.PowerUpState.GOLDEN].pressed.connect(_on_powerup_golden_pressed)
	buttons[GameConstants.PowerUpState.DOUBLE_1].pressed.connect(_on_powerup_double_pressed)
	buttons[GameConstants.PowerUpState.SWAP_1].pressed.connect(_on_powerup_swap_pressed)

func _setup_bot_timer():
	if bot_timer:
		bot_timer.timeout.connect(_on_bot_timer_timeout)

# ===================================================================
#   CORE GAME LOGIC
# ===================================================================
func _on_cell_pressed(index: int):
	if not game_active:
		return

	# Handle power-up clicks first
	if powerup_manager.handle_cell_click(index):
		# Power-up was handled, check for game over
		_check_game_over_after_powerup()
		return

	# Handle normal clicks
	if board_manager.is_valid_move(index):
		var symbol = HelperFunctions.get_player_symbol_str(turn_manager.get_current_turn())
		board_manager.place_symbol(index, symbol)
		_check_game_over()

	ui_manager.update_ui()

func _check_game_over():
	# Check for win
	if board_manager.check_for_win():
		end_game(turn_manager.get_current_turn())
		return

	# Check for draw (board full)
	if board_manager.is_board_full():
		# Determine winner by RP
		var x_rp = turn_manager.get_player_rp(GameConstants.Player.X)
		var o_rp = turn_manager.get_player_rp(GameConstants.Player.O)

		if x_rp > o_rp:
			end_game(GameConstants.Player.X, true)  # X wins by RP
		elif o_rp > x_rp:
			end_game(GameConstants.Player.O, true)  # O wins by RP
		else:
			end_game(null)  # Draw
		return

	# Continue game
	_continue_game()

func _check_game_over_after_powerup():
	# Special handling for power-ups that might immediately end the game
	if board_manager.check_for_win():
		end_game(turn_manager.get_current_turn())
		return

	# Check if we need to switch turns (some power-ups don't switch turns)
	var should_switch = true
	match powerup_manager.get_active_powerup():
		GameConstants.PowerUpState.NONE:
			should_switch = true
		GameConstants.PowerUpState.SHIELD:
			should_switch = true
			powerup_manager.clear_shield()
		_:
			should_switch = false  # Don't switch for multi-step power-ups

	if should_switch and powerup_manager.get_active_powerup() == GameConstants.PowerUpState.NONE:
		_continue_game()
	else:
		ui_manager.update_ui()

func _continue_game():
	# Switch turn and award RP
	turn_manager.switch_turn(true)

	# Clear shield on turn change
	powerup_manager.clear_shield()

	# Check if bot should move
	if bot_controller.should_bot_move():
		bot_controller.start_bot_turn()
		bot_timer.start(randf() * 0.75 + 0.75)  # 0.75-1.5 second delay

	ui_manager.update_ui()

func end_game(winner_player: GameConstants.Player, win_by_rp: bool = false):
	game_active = false
	ui_manager.show_win_screen(winner_player, win_by_rp)

	# Stop bot timer
	if bot_timer:
		bot_timer.stop()

func reset_game():
	# Reset board
	board_manager.reset_board()

	# Reset managers
	turn_manager.reset_turn()
	turn_manager.reset_rp()
	powerup_manager.reset_powerup_state()
	bot_controller.reset_bot()

	# Reset game state
	game_active = true

	# Hide win screen
	ui_manager.hide_win_screen()

	# Update UI
	ui_manager.update_ui()

# ===================================================================
#   BOT HANDLING
# ===================================================================
func _on_bot_timer_timeout():
	if not game_active:
		return

	if bot_controller.is_bot_thinking:
		bot_controller.execute_bot_move()
		_check_game_over()

# ===================================================================
#   POWER-UP BUTTON HANDLERS
# ===================================================================
func _on_powerup_shield_pressed():
	_activate_powerup(GameConstants.PowerUpState.SHIELD, GameConstants.SHIELD_COST)

func _on_powerup_erase_pressed():
	_activate_powerup(GameConstants.PowerUpState.ERASE, GameConstants.ERASE_COST)

func _on_powerup_golden_pressed():
	_activate_powerup(GameConstants.PowerUpState.GOLDEN, GameConstants.GOLDEN_COST)

func _on_powerup_double_pressed():
	# Special handling for double move
	if powerup_manager.get_active_powerup() == GameConstants.PowerUpState.DOUBLE_1 or powerup_manager.get_active_powerup() == GameConstants.PowerUpState.DOUBLE_2:
		powerup_manager.cancel_double_powerup()
		ui_manager.update_ui()
		return

	if powerup_manager.activate_powerup(GameConstants.PowerUpState.DOUBLE_1, GameConstants.DOUBLE_COST):
		# Pay RP upfront for double move
		turn_manager.modify_player_rp(turn_manager.get_current_turn(), -GameConstants.DOUBLE_COST)

	ui_manager.update_ui()

func _on_powerup_swap_pressed():
	# Special handling for swap
	if powerup_manager.get_active_powerup() == GameConstants.PowerUpState.SWAP_1 or powerup_manager.get_active_powerup() == GameConstants.PowerUpState.SWAP_2:
		powerup_manager.cancel_swap_powerup()
		ui_manager.update_ui()
		return

	_activate_powerup(GameConstants.PowerUpState.SWAP_1, GameConstants.SWAP_COST)

func _activate_powerup(powerup_type: GameConstants.PowerUpState, cost: int):
	if powerup_manager.activate_powerup(powerup_type, cost):
		# Some power-ups pay RP immediately, others pay on execution
		if powerup_type != GameConstants.PowerUpState.DOUBLE_1:
			turn_manager.modify_player_rp(turn_manager.get_current_turn(), -cost)

	ui_manager.update_ui()

# ===================================================================
#   UI HANDLERS
# ===================================================================
func _on_restart_pressed():
	reset_game()

# Info button handler
func _on_info_button_pressed():
	var popup_scene = load(GameConstants.POWERUP_INFO_POPUP_PATH)
	var popup = popup_scene.instantiate()
	add_child(popup)