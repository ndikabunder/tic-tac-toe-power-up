class_name TurnManager
extends RefCounted

signal turn_changed(new_player: GameConstants.Player)
signal rp_changed(player: GameConstants.Player, new_amount: int)

var current_turn: GameConstants.Player = GameConstants.Player.X
var player_rp: Dictionary = {
	GameConstants.Player.X: 0,
	GameConstants.Player.O: 0,
	GameConstants.Player.DRAW: 0
}

# Mendapatkan giliran saat ini
func get_current_turn() -> GameConstants.Player:
	return current_turn

# Mendapatkan lawan dari giliran saat ini
func get_opponent() -> GameConstants.Player:
	return HelperFunctions.get_opponent(current_turn)

# Mengganti giliran
func switch_turn(award_rp: bool = true):
	# Tambah RP untuk pemain yang BARU SAJA selesai giliran
	if award_rp:
		modify_player_rp(current_turn, 1)

	# Ganti giliran
	current_turn = get_opponent()
	turn_changed.emit(current_turn)

# Mengubah RP pemain
func modify_player_rp(player: GameConstants.Player, amount: int):
	player_rp[player] += amount
	rp_changed.emit(player, player_rp[player])

# Mendapatkan RP pemain
func get_player_rp(player: GameConstants.Player) -> int:
	return player_rp[player]

# Mendapatkan RP pemain saat ini
func get_current_player_rp() -> int:
	return player_rp[current_turn]

# Reset RP ke nilai awal
func reset_rp():
	player_rp[GameConstants.Player.X] = 1  # Player X mulai dengan 1 RP
	player_rp[GameConstants.Player.O] = 2  # Player O mulai dengan 2 RP (Balanced)
	player_rp[GameConstants.Player.DRAW] = 0  # DRAW tidak memiliki RP
	rp_changed.emit(GameConstants.Player.X, player_rp[GameConstants.Player.X])
	rp_changed.emit(GameConstants.Player.O, player_rp[GameConstants.Player.O])

# Reset giliran ke awal
func reset_turn():
	current_turn = GameConstants.Player.X
	turn_changed.emit(current_turn)