class_name BoardEvaluator
extends RefCounted

var board_manager: BoardManager
var win_streak: int

func _init(p_board_manager: BoardManager):
	board_manager = p_board_manager
	win_streak = GameConstants.WIN_STREAK

# Mengevaluasi skor keseluruhan papan untuk seorang pemain
func evaluate_board(player: GameConstants.Player) -> int:
	var score = 0
	var opponent = HelperFunctions.get_opponent(player)

	# Cek setiap sel untuk potensi
	for i in range(board_manager.board_state.size()):
		score += evaluate_line_from_position(i, player)  # Skor untuk membuat baris
		score -= evaluate_line_from_position(i, opponent)  # Skor untuk memblokir lawan

	return score

# Mengevaluasi skor untuk satu posisi (horizontal, vertikal, diagonal)
func evaluate_line_from_position(start_index: int, player: GameConstants.Player) -> int:
	var score = 0
	var directions = [Vector2i(0, 1), Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, -1)]  # Horizontal, Vertikal, Diagonal

	for dir in directions:
		var line_score = evaluate_direction(start_index, dir, player)
		score += line_score

	return score

# Mengevaluasi satu arah dari posisi tertentu
func evaluate_direction(start_index: int, direction: Vector2i, player: GameConstants.Player) -> int:
	var own_pieces = 0
	var empty_cells = 0
	var is_blocked = false
	var player_symbol = HelperFunctions.get_player_symbol_str(player)

	for i in range(win_streak):
		var start_coord = HelperFunctions.index_to_coordinates(start_index, board_manager.board_size)
		var r = start_coord.x + direction.x * i
		var c = start_coord.y + direction.y * i

		if not HelperFunctions.is_valid_coordinate(r, c, board_manager.board_size):
			is_blocked = true
			break

		var index = HelperFunctions.coordinates_to_index(r, c, board_manager.board_size)
		var symbol = HelperFunctions.get_base_symbol(board_manager.get_symbol(index))

		if symbol == player_symbol:
			own_pieces += 1
		elif board_manager.get_symbol(index) == "":
			empty_cells += 1
		else:
			is_blocked = true
			break

	if not is_blocked:
		if own_pieces == win_streak - 1 and empty_cells == 1:
			return 100  # Potensi menang
		elif own_pieces == win_streak - 2 and empty_cells == 2:
			return 10   # Potensi baris panjang
		elif own_pieces == win_streak - 3 and empty_cells == 3:
			return 1    # Sedikit potensi

	return 0

# Mencari langkah menang instan untuk player
func find_immediate_win(player: GameConstants.Player) -> int:
	var symbol = HelperFunctions.get_player_symbol_str(player)

	for i in range(board_manager.board_state.size()):
		if board_manager.is_valid_move(i):
			# Coba letakkan bidak
			board_manager.place_symbol(i, symbol)

			# Cek apakah ini menang
			var is_win = board_manager.check_for_win()

			# Hapus bidak (batalkan percobaan)
			board_manager.remove_symbol(i)

			# Jika tadi menang, ini langkahnya!
			if is_win:
				return i

	return -1  # Tidak ada langkah menang instan

# Mencari langkah terbaik berdasarkan evaluasi
func find_best_move(player: GameConstants.Player) -> int:
	var best_score = -10000  # Inisialisasi dengan skor yang sangat rendah
	var best_move = -1
	var empty_cells = board_manager.get_empty_cells()

	# Jika papan kosong, pilih tengah
	if empty_cells.size() == board_manager.board_size * board_manager.board_size:
		return int(board_manager.board_size * board_manager.board_size / 2)

	for i in empty_cells:
		# Coba letakkan bidak
		var symbol = HelperFunctions.get_player_symbol_str(player)
		board_manager.place_symbol(i, symbol)
		var score = evaluate_board(player)
		board_manager.remove_symbol(i)

		if score > best_score:
			best_score = score
			best_move = i

	return best_move

# Menganalisa ancaman pada satu titik
func analyze_threat_at(index: int, player: GameConstants.Player, streak_needed: int) -> Array:
	var r = int(index / board_manager.board_size)
	var c = index % board_manager.board_size
	var player_symbol = HelperFunctions.get_player_symbol_str(player)

	var directions = [Vector2i(0, 1), Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, -1)]

	for dir in directions:
		var line_cells = []
		var count = 0

		# Cek ke dua arah dari titik
		for step in range(-streak_needed + 1, streak_needed):
			var new_r = r + dir.x * step
			var new_c = c + dir.y * step

			if HelperFunctions.is_valid_coordinate(new_r, new_c, board_manager.board_size):
				var new_idx = HelperFunctions.coordinates_to_index(new_r, new_c, board_manager.board_size)
				var symbol = HelperFunctions.get_base_symbol(board_manager.get_symbol(new_idx))

				if symbol == player_symbol:
					count += 1
					line_cells.append(new_idx)

		# Jika ada baris dengan panjang `streak_needed`
		if count >= streak_needed:
			return [true, line_cells]

	return [false, []]

# Mencari baris yang bisa di-break dengan ERASE
func find_line_to_break(player: GameConstants.Player, streak_needed: int) -> int:
	var player_symbol = HelperFunctions.get_player_symbol_str(player)

	for i in range(board_manager.board_state.size()):
		# Cek hanya pada sel yang dimiliki lawan
		if HelperFunctions.get_base_symbol(board_manager.get_symbol(i)) == player_symbol:
			# Simulasikan penghapusan
			var original_symbol = board_manager.get_symbol(i)
			board_manager.remove_symbol(i)

			# Cek apakah dengan menghapus ini, potensi menang lawan hilang?
			if find_immediate_win(player) == -1:
				board_manager.place_symbol(i, original_symbol)  # Kembalikan
				# Logika lebih cerdas: cari baris panjang
				var result = analyze_threat_at(i, player, streak_needed)
				var is_threatening = result[0]
				var cells = result[1]

				if is_threatening:
					board_manager.place_symbol(i, original_symbol)  # Kembalikan
					# Pilih salah satu bidak dari baris tersebut untuk dihapus
					if not cells.is_empty():
						return cells[randi() % cells.size()]

			board_manager.place_symbol(i, original_symbol)  # Kembalikan

	return -1

# Mencari sel kosong untuk melengkapi baris
func find_line_to_complete(player: GameConstants.Player, streak_needed: int) -> int:
	for i in range(board_manager.board_state.size()):
		if board_manager.is_valid_move(i):
			# Coba isi
			var symbol = HelperFunctions.get_player_symbol_str(player)
			board_manager.place_symbol(i, symbol)

			# Cek apakah ini menciptakan baris dengan `streak_needed`
			var result = analyze_threat_at(i, player, streak_needed)
			var is_potential = result[0]

			board_manager.remove_symbol(i)  # Kembalikan

			if is_potential:
				return i  # Kembalikan sel kosongnya

	return -1