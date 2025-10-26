class_name BotController
extends RefCounted

signal bot_started_thinking()
signal bot_finished_thinking()
signal bot_status_message(message: String)

var board_manager: BoardManager
var turn_manager: TurnManager
var powerup_manager: PowerUpManager
var evaluator: BoardEvaluator

var is_bot_active: bool = true
var is_bot_thinking: bool = false

func _init(p_board_manager: BoardManager, p_turn_manager: TurnManager, p_powerup_manager: PowerUpManager):
	board_manager = p_board_manager
	turn_manager = p_turn_manager
	powerup_manager = p_powerup_manager
	evaluator = BoardEvaluator.new(board_manager)

# Mengecek apakah bot harus bergerak
func should_bot_move() -> bool:
	return is_bot_active and turn_manager.get_current_turn() == GameConstants.Player.O

# Memulai giliran bot
func start_bot_turn():
	if not should_bot_move():
		return

	is_bot_thinking = true
	bot_started_thinking.emit()
	bot_status_message.emit("Player O (Bot) sedang berpikir...")

# Mengeksekusi langkah bot (dipanggil dari game manager)
func execute_bot_move() -> bool:
	if not is_bot_thinking or not should_bot_move():
		is_bot_thinking = false
		bot_finished_thinking.emit()
		return false

	# PRIORITAS 1: Cari langkah untuk MENANG
	var winning_move = evaluator.find_immediate_win(GameConstants.Player.O)
	if winning_move != -1:
		_execute_normal_move(winning_move)
		is_bot_thinking = false
		bot_finished_thinking.emit()
		return true

	# PRIORITAS 2: Cari langkah untuk BLOKIR lawan
	var blocking_move = evaluator.find_immediate_win(GameConstants.Player.X)
	if blocking_move != -1:
		_execute_normal_move(blocking_move)
		is_bot_thinking = false
		bot_finished_thinking.emit()
		return true

	# PRIORITAS 3: Gunakan Power-Up jika memunggkinkan dan menguntungkan
	if try_use_powerup():
		is_bot_thinking = false
		bot_finished_thinking.emit()
		return true

	# PRIORITAS 4: Lakukan langkah terbaik berdasarkan evaluasi
	var best_move = evaluator.find_best_move(GameConstants.Player.O)
	if best_move != -1:
		_execute_normal_move(best_move)
	else:
		# Failsafe jika tidak ada move (seharusnya tidak terjadi)
		pass

	is_bot_thinking = false
	bot_finished_thinking.emit()
	return true

# Reset state bot
func reset_bot():
	is_bot_thinking = false

# Mengaktifkan/menonaktifkan bot
func set_bot_active(active: bool):
	is_bot_active = active

# ===================================================================
#   PRIVATE METHODS
# ===================================================================

func _execute_normal_move(index: int):
	var symbol = HelperFunctions.get_player_symbol_str(GameConstants.Player.O)
	board_manager.place_symbol(index, symbol)

# Mencoba menggunakan power-up
func try_use_powerup() -> bool:
	var bot_rp = turn_manager.get_player_rp(GameConstants.Player.O)

	# Strategi 1: Gunakan ERASE untuk menghancurkan kesempatan menang lawan
	if bot_rp >= GameConstants.ERASE_COST:
		var erase_target = evaluator.find_line_to_break(GameConstants.Player.X, GameConstants.WIN_STREAK - 1)
		if erase_target != -1:
			# Pastikan target bukan Golden Mark
			if "G" not in board_manager.get_symbol(erase_target):
				bot_status_message.emit("Bot menggunakan power-up ERASE!")
				print("BOT: Menggunakan ERASE pada sel %d" % erase_target)
				powerup_manager.activate_powerup(GameConstants.PowerUpState.ERASE, GameConstants.ERASE_COST)
				powerup_manager.handle_cell_click(erase_target)
				return true

	# Strategi 2: Gunakan SHIELD untuk melindungi sel krusial
	if bot_rp >= GameConstants.SHIELD_COST:
		var shield_target = evaluator.find_line_to_complete(GameConstants.Player.O, GameConstants.WIN_STREAK - 1)
		if shield_target != -1:
			if board_manager.is_valid_move(shield_target):
				bot_status_message.emit("Bot menggunakan power-up SHIELD!")
				print("BOT: Menggunakan SHIELD pada sel %d" % shield_target)
				powerup_manager.activate_powerup(GameConstants.PowerUpState.SHIELD, GameConstants.SHIELD_COST)
				powerup_manager.handle_cell_click(shield_target)
				return true

	# Strategi 3: Gunakan GOLDEN untuk mengamankan kemenangan
	if bot_rp >= GameConstants.GOLDEN_COST:
		var golden_target = evaluator.find_line_to_complete(GameConstants.Player.O, GameConstants.WIN_STREAK - 1)
		if golden_target != -1:
			if board_manager.is_valid_move(golden_target):
				bot_status_message.emit("Bot menggunakan power-up GOLDEN!")
				print("BOT: Menggunakan GOLDEN pada sel %d" % golden_target)
				powerup_manager.activate_powerup(GameConstants.PowerUpState.GOLDEN, GameConstants.GOLDEN_COST)
				powerup_manager.handle_cell_click(golden_target)
				return true

	return false