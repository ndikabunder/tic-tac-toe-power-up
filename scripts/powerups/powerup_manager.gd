class_name PowerUpManager
extends RefCounted

signal powerup_activated(powerup_type: GameConstants.PowerUpState)
signal powerup_completed(powerup_type: GameConstants.PowerUpState)
signal powerup_cancelled()
signal status_message(message: String)

var active_power_up: GameConstants.PowerUpState = GameConstants.PowerUpState.NONE
var turn_manager: TurnManager
var board_manager: BoardManager

# Special state variables
var shielded_cell: int = -1
var swap_cell_1: int = -1

func _init(p_turn_manager: TurnManager, p_board_manager: BoardManager):
	turn_manager = p_turn_manager
	board_manager = p_board_manager

# Mendapatkan powerup yang aktif
func get_active_powerup() -> GameConstants.PowerUpState:
	return active_power_up

# Mengecek apakah bisa mengaktifkan powerup
func can_activate_powerup(powerup_type: GameConstants.PowerUpState) -> bool:
	# Batal jika menekan tombol yang sama
	if active_power_up == powerup_type:
		active_power_up = GameConstants.PowerUpState.NONE
		powerup_cancelled.emit()
		return false

	# Tidak bisa mengaktifkan jika ada powerup lain yang aktif
	if active_power_up != GameConstants.PowerUpState.NONE:
		status_message.emit("Selesaikan power-up " + str(active_power_up).to_upper() + " dulu!")
		return false

	return true

# Mengecek apakah pemain memiliki cukup RP
func has_enough_rp(cost: int) -> bool:
	return turn_manager.get_current_player_rp() >= cost

# Mengaktifkan powerup
func activate_powerup(powerup_type: GameConstants.PowerUpState, cost: int) -> bool:
	if not can_activate_powerup(powerup_type):
		return false

	if not has_enough_rp(cost):
		return false

	active_power_up = powerup_type
	powerup_activated.emit(powerup_type)
	return true

# Menangani klik pada cell
func handle_cell_click(index: int) -> bool:
	if active_power_up == GameConstants.PowerUpState.NONE:
		return false

	# Cek Shield dulu (prioritas tertinggi)
	if index == shielded_cell:
		status_message.emit("Sel ini dilindungi Shield!")
		return true

	match active_power_up:
		GameConstants.PowerUpState.ERASE:
			_execute_erase(index)
		GameConstants.PowerUpState.SHIELD:
			_execute_shield(index)
		GameConstants.PowerUpState.GOLDEN:
			_execute_golden(index)
		GameConstants.PowerUpState.DOUBLE_1:
			_execute_double_1(index)
		GameConstants.PowerUpState.DOUBLE_2:
			_execute_double_2(index)
		GameConstants.PowerUpState.SWAP_1:
			_execute_swap_1(index)
		GameConstants.PowerUpState.SWAP_2:
			_execute_swap_2(index)

	return true

# Reset semua state powerup
func reset_powerup_state():
	active_power_up = GameConstants.PowerUpState.NONE
	shielded_cell = -1
	swap_cell_1 = -1

# Clear shield (biasanya dipanggil saat ganti giliran)
func clear_shield():
	shielded_cell = -1

# ===================================================================
#   EKSEKUSI POWER-UP
# ===================================================================

func _execute_erase(index: int):
	var opponent_symbol = HelperFunctions.get_player_symbol_str(turn_manager.get_opponent())
	var target_symbol = board_manager.get_symbol(index)

	if "G" in target_symbol:
		status_message.emit("Golden Mark tidak bisa dihapus!")
		return

	if HelperFunctions.get_base_symbol(target_symbol) == opponent_symbol:
		board_manager.remove_symbol(index)
		turn_manager.modify_player_rp(turn_manager.get_current_turn(), -GameConstants.ERASE_COST)
		active_power_up = GameConstants.PowerUpState.NONE
		powerup_completed.emit(GameConstants.PowerUpState.ERASE)
	else:
		status_message.emit("Target salah! Pilih sel milik LAWAN.")

func _execute_shield(index: int):
	if board_manager.get_symbol(index) == "":
		shielded_cell = index
		turn_manager.modify_player_rp(turn_manager.get_current_turn(), -GameConstants.SHIELD_COST)
		active_power_up = GameConstants.PowerUpState.NONE
		powerup_completed.emit(GameConstants.PowerUpState.SHIELD)
	else:
		status_message.emit("Target salah! Pilih sel KOSONG.")

func _execute_golden(index: int):
	if board_manager.get_symbol(index) == "":
		turn_manager.modify_player_rp(turn_manager.get_current_turn(), -GameConstants.GOLDEN_COST)
		var symbol = "G" + HelperFunctions.get_player_symbol_str(turn_manager.get_current_turn())
		board_manager.place_symbol(index, symbol)
		active_power_up = GameConstants.PowerUpState.NONE
		powerup_completed.emit(GameConstants.PowerUpState.GOLDEN)
	else:
		status_message.emit("Target salah! Pilih sel KOSONG.")

func _execute_double_1(index: int):
	if board_manager.get_symbol(index) == "":
		var symbol = HelperFunctions.get_player_symbol_str(turn_manager.get_current_turn())
		board_manager.place_symbol(index, symbol)
		active_power_up = GameConstants.PowerUpState.DOUBLE_2
		powerup_completed.emit(GameConstants.PowerUpState.DOUBLE_1)
	else:
		status_message.emit("Target salah! Pilih sel KOSONG.")

func _execute_double_2(index: int):
	if board_manager.get_symbol(index) == "":
		var symbol = HelperFunctions.get_player_symbol_str(turn_manager.get_current_turn())
		board_manager.place_symbol(index, symbol)
		active_power_up = GameConstants.PowerUpState.NONE
		powerup_completed.emit(GameConstants.PowerUpState.DOUBLE_2)
	else:
		status_message.emit("Target salah! Pilih sel KOSONG.")

func _execute_swap_1(index: int):
	if board_manager.get_symbol(index) != "":
		swap_cell_1 = index
		active_power_up = GameConstants.PowerUpState.SWAP_2
		powerup_completed.emit(GameConstants.PowerUpState.SWAP_1)
	else:
		status_message.emit("Target salah! Pilih sel yang ADA SIMBOLNYA.")

func _execute_swap_2(index: int):
	if board_manager.get_symbol(index) != "" and index != swap_cell_1:
		board_manager.swap_symbols(swap_cell_1, index)
		turn_manager.modify_player_rp(turn_manager.get_current_turn(), -GameConstants.SWAP_COST)
		active_power_up = GameConstants.PowerUpState.NONE
		swap_cell_1 = -1
		powerup_completed.emit(GameConstants.PowerUpState.SWAP_2)
	else:
		status_message.emit("Target salah! (Sel harus berisi & berbeda)")

# Fungsi khusus untuk Double Move (batal)
func cancel_double_powerup():
	if active_power_up == GameConstants.PowerUpState.DOUBLE_1 or active_power_up == GameConstants.PowerUpState.DOUBLE_2:
		active_power_up = GameConstants.PowerUpState.NONE
		powerup_cancelled.emit()

# Fungsi khusus untuk Swap (batal)
func cancel_swap_powerup():
	if active_power_up == GameConstants.PowerUpState.SWAP_1 or active_power_up == GameConstants.PowerUpState.SWAP_2:
		active_power_up = GameConstants.PowerUpState.NONE
		swap_cell_1 = -1
		powerup_cancelled.emit()