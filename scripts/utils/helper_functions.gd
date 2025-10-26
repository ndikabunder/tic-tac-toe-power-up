class_name HelperFunctions
extends RefCounted

# ===================================================================
#   FUNGSI HELPER (Pembantu)
# ===================================================================

# Mengambil simbol dasar ("X" atau "O") dari string ("GX", "O", dll)
static func get_base_symbol(symbol_str: String) -> String:
	if "X" in symbol_str:
		return "X"
	if "O" in symbol_str:
		return "O"
	return ""

# Mendapatkan string simbol ("X" atau "O") dari enum Player
static func get_player_symbol_str(player: GameConstants.Player) -> String:
	if player == GameConstants.Player.X:
		return "X"
	elif player == GameConstants.Player.O:
		return "O"
	else:
		return ""

# Mendapatkan pemain lawan
static func get_opponent(player: GameConstants.Player) -> GameConstants.Player:
	if player == GameConstants.Player.X:
		return GameConstants.Player.O
	elif player == GameConstants.Player.O:
		return GameConstants.Player.X
	else:
		return GameConstants.Player.DRAW

# Mengubah index board ke koordinat (row, col)
static func index_to_coordinates(index: int, board_size: int = GameConstants.BOARD_SIZE) -> Vector2i:
	return Vector2i(index % board_size, index / board_size)

# Mengubah koordinat (row, col) ke index board
static func coordinates_to_index(row: int, col: int, board_size: int = GameConstants.BOARD_SIZE) -> int:
	return row * board_size + col

# Validasi koordinat apakah dalam bounds board
static func is_valid_coordinate(row: int, col: int, board_size: int = GameConstants.BOARD_SIZE) -> bool:
	return row >= 0 and row < board_size and col >= 0 and col < board_size

# Mendapatkan warna untuk player
static func get_player_color(player_symbol: String) -> Color:
	if player_symbol == "X":
		return Color.from_string("#ffffff", Color.WHITE)
	elif player_symbol == "O":
		return Color.from_string("#ffffff", Color.WHITE)
	return Color.WHITE