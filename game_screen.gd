extends Control

# ===================================================================
#   ENUMERASI (Tipe Data Kustom untuk State)
# ===================================================================
# Menggunakan enum lebih aman dan bersih daripada string "X" atau "O"
enum Player { X, O }

# Enum untuk semua status power-up, menghindari bug salah ketik string
enum PowerUpState { NONE, ERASE, SHIELD, GOLDEN, DOUBLE_1, DOUBLE_2, SWAP_1, SWAP_2 }

# ===================================================================
#   KONSTANTA GAME
# ===================================================================
# Biaya baru yang lebih seimbang
const SHIELD_COST = 2
const GOLDEN_COST = 2  # <- Turun
const ERASE_COST = 4  # <- Naik
const SWAP_COST = 4  # <- Turun
const DOUBLE_COST = 6  # <- Naik

# Pengaturan Papan (sudah baik!)
const BOARD_SIZE = 5
const WIN_STREAK = 4

@export var is_bot_active = true  # Aktifkan/matikan bot dari Godot Editor

# ===================================================================
#   REFERENSI NODE (UI)
# ===================================================================
@onready var status_label = $MainVBox/StatusLabel
@onready var turn_indicator = $MainVBox/Header/TurnIndicator
@onready var player_x_rp_label = $MainVBox/Header/PlayerX_Info/VBox/PlayerX_RP_Label
@onready var player_o_rp_label = $MainVBox/Header/PlayerO_Info/VBox/PlayerO_RP_Label
@onready var game_board = $MainVBox/BoardArea/GameBoard
@onready var win_screen = $WinScreen
@onready var win_label = $WinScreen/VBox/WinLabel
@onready var restart_button = $WinScreen/VBox/RestartButton
@onready var bot_timer = $BotTimer  # Referensi ke Node Timer yang baru Anda buat

# Dictionary untuk menyimpan referensi tombol power-up
@onready var powerup_buttons = {
	PowerUpState.SHIELD: $MainVBox/PowerUpBar/PowerUpGrid/PowerUp_Shield,
	PowerUpState.ERASE: $MainVBox/PowerUpBar/PowerUpGrid/PowerUp_Erase,
	PowerUpState.GOLDEN: $MainVBox/PowerUpBar/PowerUpGrid/PowerUp_Golden,
	PowerUpState.DOUBLE_1: $MainVBox/PowerUpBar/PowerUpGrid/PowerUp_Double,  # Kita pakai DOUBLE_1 sebagai ID
	PowerUpState.SWAP_1: $MainVBox/PowerUpBar/PowerUpGrid/PowerUp_Swap  # Kita pakai SWAP_1 sebagai ID
}

# ===================================================================
#   VARIABEL STATE BOT
# ===================================================================

var is_bot_thinking = false

# ===================================================================
#   VARIABEL STATE GAME
# ===================================================================
var board_state = []
var game_active = true
var shielded_cell = -1
var swap_cell_1 = -1

# Menggunakan Enum untuk state
var current_turn = Player.X
var active_power_up = PowerUpState.NONE

# Menggunakan Dictionary untuk RP, jauh lebih rapi!
var player_rp = {Player.X: 0, Player.O: 0}

# ===================================================================
#   FUNGSI HELPER (Pembantu)
# ===================================================================


# Mengambil simbol dasar ("X" atau "O") dari string ("GX", "O", dll)
func get_base_symbol(symbol_str):
	if "X" in symbol_str:
		return "X"
	if "O" in symbol_str:
		return "O"
	return ""


# Mengambil RP pemain saat ini
func get_current_player_rp():
	return player_rp[current_turn]


# Mengubah RP pemain saat ini (misal: amount = -5, amount = 1)
func modify_current_player_rp(amount):
	player_rp[current_turn] += amount


# Mendapatkan pemain lawan
func get_opponent():
	return Player.O if current_turn == Player.X else Player.X


# Mendapatkan string simbol ("X" atau "O") dari enum Player
func get_player_symbol_str(player):
	return "X" if player == Player.X else "O"


# ===================================================================
#   FUNGSI BAWAAN GODOT (_ready)
# ===================================================================
func _ready():
	_setup_board_signals()
	_setup_powerup_signals()
	restart_button.pressed.connect(reset_game)

	# --- Hubungkan Timer Bot ---
	bot_timer.timeout.connect(_on_bot_timer_timeout)
	# -------------------------

	reset_game()


# ===================================================================
#   FUNGSI PENGATUR SINYAL (Dipanggil dari _ready)
# ===================================================================


# Menghubungkan semua 25 tombol di papan
func _setup_board_signals():
	var cell_index = 0
	for cell_button in game_board.get_children():
		if cell_button is Button:
			cell_button.pressed.connect(_on_cell_pressed.bind(cell_index))
			cell_index += 1


# Menghubungkan semua tombol power-up
func _setup_powerup_signals():
	powerup_buttons[PowerUpState.SHIELD].pressed.connect(_on_powerup_shield_pressed)
	powerup_buttons[PowerUpState.ERASE].pressed.connect(_on_powerup_erase_pressed)
	powerup_buttons[PowerUpState.GOLDEN].pressed.connect(_on_powerup_golden_pressed)
	powerup_buttons[PowerUpState.DOUBLE_1].pressed.connect(_on_powerup_double_pressed)
	powerup_buttons[PowerUpState.SWAP_1].pressed.connect(_on_powerup_swap_pressed)


# ===================================================================
#   FUNGSI LOGIKA UTAMA (Callback Tombol Papan)
# ===================================================================


# Fungsi ini sekarang jauh lebih bersih, hanya sebagai "router"
func _on_cell_pressed(index):
	# --- Pengecekan Bot ---
	if is_bot_thinking or (is_bot_active and current_turn == Player.O):
		return  # Jangan lakukan apa-apa jika bot sedang mikir atau giliran bot
	# ---------------------------

	# 1. Cek Shield dulu (prioritas tertinggi)
	if index == shielded_cell:
		status_label.text = "Sel ini dilindungi Shield!"
		return

	# 2. Cek apakah sedang memakai power-up
	if active_power_up != PowerUpState.NONE:
		_handle_powerup_click(index)
	# 3. Jika tidak, lakukan langkah normal
	else:
		_handle_normal_click(index)


# Fungsi untuk menangani klik jika TIDAK ada power-up aktif
func _handle_normal_click(index):
	if not game_active or board_state[index] != "":
		return

	board_state[index] = get_player_symbol_str(current_turn)
	_check_game_over()  # Cek menang/seri, dan ganti giliran jika perlu
	update_ui()


# Fungsi untuk menangani klik JIKA ADA power-up aktif
func _handle_powerup_click(index):
	# 'match' (cocokkan) dengan state enum
	match active_power_up:
		PowerUpState.ERASE:
			_execute_erase(index)
		PowerUpState.SHIELD:
			_execute_shield(index)
		PowerUpState.GOLDEN:
			_execute_golden(index)
		PowerUpState.DOUBLE_1:
			_execute_double_1(index)
		PowerUpState.DOUBLE_2:
			_execute_double_2(index)
		PowerUpState.SWAP_1:
			_execute_swap_1(index)
		PowerUpState.SWAP_2:
			_execute_swap_2(index)

	update_ui()  # Selalu update UI setelah aksi power-up


# ===================================================================
#   FUNGSI EKSEKUSI POWER-UP (Dipecah dari _on_cell_pressed)
# ===================================================================


func _execute_erase(index):
	var opponent_symbol_str = get_player_symbol_str(get_opponent())
	var target_symbol = board_state[index]

	if "G" in target_symbol:
		status_label.text = "Golden Mark tidak bisa dihapus!"
		return

	if get_base_symbol(target_symbol) == opponent_symbol_str:
		board_state[index] = ""
		modify_current_player_rp(-ERASE_COST)
		active_power_up = PowerUpState.NONE
		_check_game_over()  # Erase menggunakan giliran
	else:
		status_label.text = "Target salah! Pilih sel milik LAWAN."


func _execute_shield(index):
	if board_state[index] == "":
		shielded_cell = index
		modify_current_player_rp(-SHIELD_COST)
		active_power_up = PowerUpState.NONE
		# PENTING: Panggil switch_turn dengan 'false' agar shield tidak langsung hilang
		switch_turn(false)
		update_ui()  # Panggil update_ui manual karena _check_game_over dilewati
	else:
		status_label.text = "Target salah! Pilih sel KOSONG."


func _execute_golden(index):
	if board_state[index] == "":
		modify_current_player_rp(-GOLDEN_COST)
		board_state[index] = "G" + get_player_symbol_str(current_turn)
		active_power_up = PowerUpState.NONE
		_check_game_over()  # Golden Mark menggunakan giliran
	else:
		status_label.text = "Target salah! Pilih sel KOSONG."


func _execute_double_1(index):
	if board_state[index] == "":
		board_state[index] = get_player_symbol_str(current_turn)
		active_power_up = PowerUpState.DOUBLE_2  # Lanjut ke langkah kedua

		# Cek menang di langkah pertama
		if check_for_win():
			end_game(current_turn)
			active_power_up = PowerUpState.NONE  # Matikan power-up jika menang
	else:
		status_label.text = "Target salah! Pilih sel KOSONG."


func _execute_double_2(index):
	if board_state[index] == "":
		board_state[index] = get_player_symbol_str(current_turn)
		active_power_up = PowerUpState.NONE  # Selesai
		_check_game_over()  # Selesai Double Move, gunakan giliran
	else:
		status_label.text = "Target salah! Pilih sel KOSONG."


func _execute_swap_1(index):
	if board_state[index] != "":
		swap_cell_1 = index
		active_power_up = PowerUpState.SWAP_2  # Lanjut ke langkah kedua
	else:
		status_label.text = "Target salah! Pilih sel yang ADA SIMBOLNYA."


func _execute_swap_2(index):
	if board_state[index] != "" and index != swap_cell_1:
		var temp_symbol = board_state[swap_cell_1]
		board_state[swap_cell_1] = board_state[index]
		board_state[index] = temp_symbol

		modify_current_player_rp(-SWAP_COST)
		active_power_up = PowerUpState.NONE
		swap_cell_1 = -1

		# Swap bisa menyebabkan salah satu pemain menang, cek keduanya!
		if check_for_win():
			# Cek siapa yg menang pasca-swap (agak rumit, cara mudahnya cek giliran saat ini)
			end_game(current_turn)
		else:
			switch_turn()  # Swap menggunakan giliran
			update_ui()
	else:
		status_label.text = "Target salah! (Sel harus berisi & berbeda)"


# ===================================================================
#   FUNGSI LOGIKA GAME (Ganti Giliran, Cek Menang, dll)
# ===================================================================


# Fungsi baru untuk mengecek status akhir game
func _check_game_over():
	if check_for_win():
		end_game(current_turn)
	elif not "" in board_state:
		end_game(null)  # null = Seri
	else:
		switch_turn()


# Mengganti giliran (sudah di-update untuk bug Shield)
func switch_turn(clear_shield = true):
	if clear_shield:
		shielded_cell = -1

	# Tambah RP untuk pemain yang BARU SAJA selesai giliran
	modify_current_player_rp(1)

	# Ganti giliran
	current_turn = get_opponent()

	# --- Pemicu Bot ---
	# Jika game aktif, bot diaktifkan, dan giliran O
	if game_active and is_bot_active and current_turn == Player.O:
		_execute_bot_turn()
	# -------------------------


# Fungsi Cek Menang (Logika sudah bagus, hanya diberi komentar)
func check_for_win():
	for r in range(BOARD_SIZE):
		for c in range(BOARD_SIZE):
			# Helper (baris, kolom) -> index: (baris * LEBAR_PAPAN + kolom)
			var index = r * BOARD_SIZE + c
			var current_symbol = get_base_symbol(board_state[index])

			if current_symbol == "":
				continue

			# 1. Cek Horizontal (ke Kanan)
			if c <= BOARD_SIZE - WIN_STREAK:
				var has_match = true
				for i in range(1, WIN_STREAK):
					if get_base_symbol(board_state[index + i]) != current_symbol:
						has_match = false
						break
				if has_match:
					return true

			# 2. Cek Vertikal (ke Bawah)
			if r <= BOARD_SIZE - WIN_STREAK:
				var has_match = true
				for i in range(1, WIN_STREAK):
					if get_base_symbol(board_state[index + (i * BOARD_SIZE)]) != current_symbol:
						has_match = false
						break
				if has_match:
					return true

			# 3. Cek Diagonal (ke Bawah-Kanan)
			if r <= BOARD_SIZE - WIN_STREAK and c <= BOARD_SIZE - WIN_STREAK:
				var has_match = true
				for i in range(1, WIN_STREAK):
					if get_base_symbol(board_state[index + (i * BOARD_SIZE) + i]) != current_symbol:
						has_match = false
						break
				if has_match:
					return true

			# 4. Cek Diagonal (ke Bawah-Kiri)
			if r <= BOARD_SIZE - WIN_STREAK and c >= WIN_STREAK - 1:
				var has_match = true
				for i in range(1, WIN_STREAK):
					if get_base_symbol(board_state[index + (i * BOARD_SIZE) - i]) != current_symbol:
						has_match = false
						break
				if has_match:
					return true

	return false  # Tidak ada pemenang ditemukan


# Mengakhiri permainan
func end_game(winner_player):  # Menggunakan enum Player, 'null' jika seri
	game_active = false
	win_screen.visible = true

	if winner_player == null:
		win_label.text = "PERMAINAN SERI!"
	else:
		win_label.text = "PLAYER " + get_player_symbol_str(winner_player) + " MENANG!"


# Me-reset game ke status awal
func reset_game():
	# Reset papan
	board_state = []
	for i in range(BOARD_SIZE * BOARD_SIZE):
		board_state.append("")

	# Reset variabel state
	current_turn = Player.X
	game_active = true
	# Player X (P1) mulai dengan 1 RP, Player O (P2) mulai dengan 2 RP (Balanced)
	player_rp = {Player.X: 1, Player.O: 2}
	active_power_up = PowerUpState.NONE
	shielded_cell = -1
	swap_cell_1 = -1

	win_screen.visible = false

	# --- Reset Bot ---
	is_bot_thinking = false
	bot_timer.stop()
	_set_board_interactive(true)  # Memastikan papan bisa diklik lagi
	# -------------------------

	update_ui()  # Panggil update_ui di akhir reset


# ===================================================================
#   FUNGSI UPDATE UI (Tampilan)
# ===================================================================
func update_ui():
	# 1. Update Label Info (menggunakan @onready var dan dict RP)
	player_x_rp_label.text = "RP: " + str(player_rp[Player.X])
	player_o_rp_label.text = "RP: " + str(player_rp[Player.O])
	turn_indicator.text = "Giliran: " + get_player_symbol_str(current_turn)

	# 2. Update Tampilan Papan (25 Tombol)
	var cell_index = 0
	for cell_button in game_board.get_children():
		if cell_button is Button:
			cell_button.text = board_state[cell_index]
			if cell_index == shielded_cell:
				cell_button.text = "[S]"  # Tanda Shield
			cell_index += 1

	# 3. Update Label Status (menggunakan Enum)
	if game_active:
		var status_text = "Giliran " + get_player_symbol_str(current_turn) + " untuk melangkah."

		# Tambahan: Tampilkan status bot
		if is_bot_thinking:
			status_text = "Player O (Bot) sedang berpikir..."

		match active_power_up:
			PowerUpState.ERASE:
				status_text = "Mode: HAPUS\nPilih sel LAWAN!"
			PowerUpState.SHIELD:
				status_text = "Mode: SHIELD\nPilih sel KOSONG!"
			PowerUpState.GOLDEN:
				status_text = "Mode: GOLDEN MARK\nPilih sel KOSONG!"
			PowerUpState.DOUBLE_1:
				status_text = "Mode: DOUBLE MOVE (1/2)\nPilih sel KOSONG!"
			PowerUpState.DOUBLE_2:
				status_text = "Mode: DOUBLE MOVE (2/2)\nPilih sel KOSONG!"
			PowerUpState.SWAP_1:
				status_text = "Mode: SWAP (1/2)\nPilih sel PERTAMA (berisi)!"
			PowerUpState.SWAP_2:
				status_text = "Mode: SWAP (2/2)\nPilih sel KEDUA (berisi)!"
		status_label.text = status_text

	# 4. Update Tombol Power-Up (menggunakan helper get_current_player_rp)
	var current_rp = get_current_player_rp()
	powerup_buttons[PowerUpState.SHIELD].disabled = current_rp < SHIELD_COST
	powerup_buttons[PowerUpState.ERASE].disabled = current_rp < ERASE_COST
	powerup_buttons[PowerUpState.GOLDEN].disabled = current_rp < GOLDEN_COST
	powerup_buttons[PowerUpState.DOUBLE_1].disabled = current_rp < DOUBLE_COST
	powerup_buttons[PowerUpState.SWAP_1].disabled = current_rp < SWAP_COST


# ===================================================================
#   FUNGSI TOMBOL POWER-UP (Callback)
# ===================================================================


# Fungsi helper untuk cek aktivasi (sudah bagus)
func _can_activate_powerup(powerup_state):
	if active_power_up == powerup_state:
		active_power_up = PowerUpState.NONE  # Batal
		update_ui()
		return false
	if active_power_up != PowerUpState.NONE:
		status_label.text = "Selesaikan power-up %s dulu!" % str(active_power_up).to_upper()
		return false
	return true


# --- Fungsi untuk setiap tombol ---


func _on_powerup_shield_pressed():
	# --- Pengecekan Bot ---
	if is_bot_thinking or (is_bot_active and current_turn == Player.O):
		return
	# ---------------------------
	if not _can_activate_powerup(PowerUpState.SHIELD):
		return
	if get_current_player_rp() < SHIELD_COST:
		return

	active_power_up = PowerUpState.SHIELD
	update_ui()


func _on_powerup_erase_pressed():
	# --- [DIPERBAIKI] Pengecekan Bot ---
	if is_bot_thinking or (is_bot_active and current_turn == Player.O):
		return
	# ---------------------------
	if not _can_activate_powerup(PowerUpState.ERASE):
		return
	if get_current_player_rp() < ERASE_COST:
		return

	active_power_up = PowerUpState.ERASE
	update_ui()


func _on_powerup_golden_pressed():
	# --- [DIPERBAIKI] Pengecekan Bot ---
	if is_bot_thinking or (is_bot_active and current_turn == Player.O):
		return
	# ---------------------------
	if not _can_activate_powerup(PowerUpState.GOLDEN):
		return
	if get_current_player_rp() < GOLDEN_COST:
		return

	active_power_up = PowerUpState.GOLDEN
	update_ui()


func _on_powerup_double_pressed():
	# --- [DIPERBAIKI] Pengecekan Bot ---
	if is_bot_thinking or (is_bot_active and current_turn == Player.O):
		return
	# ---------------------------

	# Logika batal sedikit beda
	if active_power_up == PowerUpState.DOUBLE_1 or active_power_up == PowerUpState.DOUBLE_2:
		active_power_up = PowerUpState.NONE
		# Seharusnya RP dikembalikan jika dibatalkan, tapi untuk simpelnya kita anggap hangus
		# modify_current_player_rp(DOUBLE_COST) # <- Aktifkan ini jika ingin RP kembali
		update_ui()
		return

	if active_power_up != PowerUpState.NONE:
		status_label.text = "Selesaikan power-up %s dulu!" % str(active_power_up).to_upper()
		return

	if get_current_player_rp() < DOUBLE_COST:
		return

	# Bayar RP di MUKA
	modify_current_player_rp(-DOUBLE_COST)
	active_power_up = PowerUpState.DOUBLE_1
	update_ui()


func _on_powerup_swap_pressed():
	# --- [DIPERBAIKI] Pengecekan Bot ---
	if is_bot_thinking or (is_bot_active and current_turn == Player.O):
		return
	# ---------------------------

	# Logika batal juga beda
	if active_power_up == PowerUpState.SWAP_1 or active_power_up == PowerUpState.SWAP_2:
		active_power_up = PowerUpState.NONE
		swap_cell_1 = -1
		update_ui()
		return

	if active_power_up != PowerUpState.NONE:
		status_label.text = "Selesaikan power-up %s dulu!" % str(active_power_up).to_upper()
		return

	if get_current_player_rp() < SWAP_COST:
		return

	active_power_up = PowerUpState.SWAP_1
	swap_cell_1 = -1
	update_ui()


# ===================================================================
#   LOGIKA BOT (AI)
# ===================================================================


# Fungsi untuk menonaktifkan/mengaktifkan input pemain
func _set_board_interactive(is_interactive):
	# Nonaktifkan semua sel papan
	for cell_button in game_board.get_children():
		if cell_button is Button:
			cell_button.disabled = not is_interactive

	# Nonaktifkan semua tombol power-up
	# Kita bisa nonaktifkan semua saat bot mikir
	for button in powerup_buttons.values():
		button.disabled = not is_interactive

	# Saat mengaktifkan kembali, panggil update_ui()
	# agar disabilitas tombol power-up sesuai RP
	if is_interactive:
		update_ui()


# 1. Memulai giliran bot
func _execute_bot_turn():
	is_bot_thinking = true
	_set_board_interactive(false)  # Matikan input human
	status_label.text = "Player O (Bot) sedang berpikir..."

	# Atur timer "berpikir" (0.75 - 1.5 detik) agar tidak instan
	bot_timer.start(randf_range(0.75, 1.5))


# 2. Logika inti AI (dipanggil setelah Timer selesai)
func _on_bot_timer_timeout():
	# Pengecekan keamanan
	if not game_active or current_turn != Player.O:
		is_bot_thinking = false
		_set_board_interactive(true)
		return

	# PRIORITAS 1: Cari langkah untuk MENANG
	var winning_move = _find_immediate_win(Player.O)
	if winning_move != -1:
		_handle_normal_click(winning_move)
		is_bot_thinking = false
		_set_board_interactive(true)
		return

	# PRIORITAS 2: Cari langkah untuk BLOKIR lawan
	var blocking_move = _find_immediate_win(Player.X)
	if blocking_move != -1:
		_handle_normal_click(blocking_move)
		is_bot_thinking = false
		_set_board_interactive(true)
		return

	# PRIORITAS 3: (Logika Power-Up bisa ditambah di sini nanti)
	# var bot_rp = player_rp[Player.O]
	# if bot_rp >= ERASE_COST:
	#     ... (logika erase) ...

	# PRIORITAS 4: Lakukan langkah acak yang "baik"
	var good_move = _find_good_random_move()
	if good_move != -1:
		_handle_normal_click(good_move)
	else:
		# Failsafe jika papan penuh (seharusnya tidak terjadi)
		pass

	is_bot_thinking = false
	_set_board_interactive(true)  # Selesai berpikir, aktifkan lagi
	# update_ui() akan dipanggil otomatis dari dalam _handle_normal_click


# 3. HELPER AI: Mengecek semua sel kosong untuk kemenangan 1 langkah
func _find_immediate_win(player_to_check):
	# Kita perlu simbol "X" atau "O"
	var symbol = get_player_symbol_str(player_to_check)

	for i in range(board_state.size()):
		# Cek hanya di sel yang kosong
		if board_state[i] == "":
			# 1. Coba letakkan bidak
			board_state[i] = symbol

			# 2. Cek apakah ini menang?
			# Kita harus pura-pura giliran player tsb
			var original_turn = current_turn
			current_turn = player_to_check
			var is_win = check_for_win()
			current_turn = original_turn  # Kembalikan giliran

			# 3. Hapus bidak (batalkan percobaan)
			board_state[i] = ""

			# 4. Jika tadi menang, ini langkahnya!
			if is_win:
				return i

	return -1  # Tidak ada langkah menang instan


# 4. HELPER AI: Mencari langkah acak di dekat bidak lain
func _find_good_random_move():
	var empty_cells = []
	var good_cells = []  # Sel kosong yang tetanggaan sama bidak lain

	for i in range(board_state.size()):
		if board_state[i] == "":
			empty_cells.append(i)

			# Cek 8 tetangga
			var is_adjacent = false
			var r = i / BOARD_SIZE
			var c = i % BOARD_SIZE

			for dr in [-1, 0, 1]:
				for dc in [-1, 0, 1]:
					if dr == 0 and dc == 0:
						continue  # Lewati diri sendiri

					var nr = r + dr
					var nc = c + dc

					# Cek di dalam papan
					if nr >= 0 and nr < BOARD_SIZE and nc >= 0 and nc < BOARD_SIZE:
						var neighbor_index = nr * BOARD_SIZE + nc
						if board_state[neighbor_index] != "":
							is_adjacent = true
							break
				if is_adjacent:
					break

			if is_adjacent:
				good_cells.append(i)

	# Utamakan pilih dari sel yang "baik"
	if not good_cells.is_empty():
		return good_cells.pick_random()
	# Jika tidak ada (misal di awal game), pilih dari semua sel kosong
	elif not empty_cells.is_empty():
		return empty_cells.pick_random()

	return -1  # Papan penuh
