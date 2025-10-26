class_name BoardManager
extends RefCounted

var board_state: Array[String] = []
var board_size: int
var win_streak: int

func _init(size: int = GameConstants.BOARD_SIZE, streak: int = GameConstants.WIN_STREAK):
	board_size = size
	win_streak = streak
	reset_board()

# Reset papan ke kondisi awal
func reset_board():
	board_state.clear()
	for i in range(board_size * board_size):
		board_state.append("")

# Mengisi sel dengan simbol
func place_symbol(index: int, symbol: String) -> bool:
	if is_valid_move(index):
		board_state[index] = symbol
		return true
	return false

# Mengecek apakah move valid
func is_valid_move(index: int) -> bool:
	return index >= 0 and index < board_state.size() and board_state[index] == ""

# Menghapus simbol dari sel
func remove_symbol(index: int) -> bool:
	if index >= 0 and index < board_state.size():
		board_state[index] = ""
		return true
	return false

# Menukar simbol antara dua sel
func swap_symbols(index1: int, index2: int) -> bool:
	if index1 >= 0 and index1 < board_state.size() and index2 >= 0 and index2 < board_state.size():
		var temp = board_state[index1]
		board_state[index1] = board_state[index2]
		board_state[index2] = temp
		return true
	return false

# Mendapatkan simbol di sel tertentu
func get_symbol(index: int) -> String:
	if index >= 0 and index < board_state.size():
		return board_state[index]
	return ""

# Mengecek apakah papan penuh
func is_board_full() -> bool:
	return not "" in board_state

# Mendapatkan semua sel kosong
func get_empty_cells() -> Array[int]:
	var empty_cells: Array[int] = []
	for i in range(board_state.size()):
		if board_state[i] == "":
			empty_cells.append(i)
	return empty_cells

# Fungsi Cek Menang
func check_for_win() -> bool:
	for r in range(board_size):
		for c in range(board_size):
			var index = r * board_size + c
			var current_symbol = HelperFunctions.get_base_symbol(board_state[index])

			if current_symbol == "":
				continue

			# Cek Horizontal (ke Kanan)
			if c <= board_size - win_streak:
				if _check_horizontal_line(index, current_symbol):
					return true

			# Cek Vertikal (ke Bawah)
			if r <= board_size - win_streak:
				if _check_vertical_line(index, current_symbol):
					return true

			# Cek Diagonal (ke Bawah-Kanan)
			if r <= board_size - win_streak and c <= board_size - win_streak:
				if _check_diagonal_down_right(index, current_symbol):
					return true

			# Cek Diagonal (ke Bawah-Kiri)
			if r <= board_size - win_streak and c >= win_streak - 1:
				if _check_diagonal_down_left(index, current_symbol):
					return true

	return false

# Helper functions untuk checking win conditions
func _check_horizontal_line(start_index: int, symbol: String) -> bool:
	for i in range(1, win_streak):
		if HelperFunctions.get_base_symbol(board_state[start_index + i]) != symbol:
			return false
	return true

func _check_vertical_line(start_index: int, symbol: String) -> bool:
	for i in range(1, win_streak):
		if HelperFunctions.get_base_symbol(board_state[start_index + (i * board_size)]) != symbol:
			return false
	return true

func _check_diagonal_down_right(start_index: int, symbol: String) -> bool:
	for i in range(1, win_streak):
		if HelperFunctions.get_base_symbol(board_state[start_index + (i * board_size) + i]) != symbol:
			return false
	return true

func _check_diagonal_down_left(start_index: int, symbol: String) -> bool:
	for i in range(1, win_streak):
		if HelperFunctions.get_base_symbol(board_state[start_index + (i * board_size) - i]) != symbol:
			return false
	return true

# Mengecek apakah ada simbol tertentu di baris/kolom/diagonal
func count_symbols_in_line(start_index: int, direction: Vector2i, symbol: String, length: int) -> int:
	var count = 0
	var start_coord = HelperFunctions.index_to_coordinates(start_index, board_size)

	for i in range(length):
		var coord = start_coord + direction * i
		if not HelperFunctions.is_valid_coordinate(coord.x, coord.y, board_size):
			break

		var index = HelperFunctions.coordinates_to_index(coord.x, coord.y, board_size)
		if HelperFunctions.get_base_symbol(board_state[index]) == symbol:
			count += 1

	return count