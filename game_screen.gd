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

const PowerUpInfoPopup = preload("res://powerup_info_popup.tscn")

# Warna untuk status tombol
const NORMAL_COLOR = Color(1, 1, 1, 1)  # Putih
const DARK_COLOR = Color(0.5, 0.5, 0.5, 1) # Abu-abu

# Pengaturan Papan (sudah baik!)
const BOARD_SIZE = 5
const WIN_STREAK = 4

# ===================================================================
#   REFERENSI NODE (UI)
# ===================================================================
@onready var status_label = $MainVBox/StatusLabel
@onready var turn_indicator = $MainVBox/Header/VBoxContainer/TurnIndicator
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
	PowerUpState.DOUBLE_1: $MainVBox/PowerUpBar/PowerUpGrid/PowerUp_Double,  # DOUBLE_1 sebagai ID
	PowerUpState.SWAP_1: $MainVBox/PowerUpBar/PowerUpGrid/PowerUp_Swap  # SWAP_1 sebagai ID
}

@export var is_bot_active = true  # Aktifkan/matikan bot dari Godot Editor

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
	$MainVBox/Header/VBoxContainer/InfoButton.pressed.connect(_on_info_button_pressed)

	# --- Hubungkan Timer Bot ---
	bot_timer.timeout.connect(_on_bot_timer_timeout)
	# -------------------------

	reset_game()


func _on_info_button_pressed():
	var popup = PowerUpInfoPopup.instantiate()
	add_child(popup)


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
	# Pengecekan input sekarang ditangani dengan menonaktifkan tombol di update_ui()

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
		_check_game_over(false)  # Erase menggunakan giliran
	else:
		status_label.text = "Target salah! Pilih sel milik LAWAN."


func _execute_shield(index):
	if board_state[index] == "":
		shielded_cell = index
		modify_current_player_rp(-SHIELD_COST)
		active_power_up = PowerUpState.NONE
		# PENTING: Panggil switch_turn dengan 'false' agar shield tidak langsung hilang
		switch_turn(false, false)
		update_ui()  # Panggil update_ui manual karena _check_game_over dilewati
	else:
		status_label.text = "Target salah! Pilih sel KOSONG."


func _execute_golden(index):
	if board_state[index] == "":
		modify_current_player_rp(-GOLDEN_COST)
		board_state[index] = "G" + get_player_symbol_str(current_turn)
		active_power_up = PowerUpState.NONE
		_check_game_over(false)  # Golden Mark menggunakan giliran
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
		_check_game_over(false)  # Selesai Double Move, gunakan giliran
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
			switch_turn(true, false)  # Swap menggunakan giliran
			update_ui()
	else:
		status_label.text = "Target salah! (Sel harus berisi & berbeda)"


# ===================================================================
#   FUNGSI LOGIKA GAME (Ganti Giliran, Cek Menang, dll)
# ===================================================================


# Fungsi baru untuk mengecek status akhir game
func _check_game_over(award_rp = true):
	if check_for_win():
		end_game(current_turn)
	elif not "" in board_state:
		# Papan penuh, tentukan pemenang berdasarkan RP
		if player_rp[Player.X] > player_rp[Player.O]:
			end_game(Player.X, true) # Player X menang via RP
		elif player_rp[Player.O] > player_rp[Player.X]:
			end_game(Player.O, true) # Player O menang via RP
		else:
			end_game(null) # RP sama, hasil tetap seri
	else:
		switch_turn(true, award_rp)


# Mengganti giliran (sudah di-update untuk bug Shield)
func switch_turn(clear_shield = true, award_rp = true):
	if clear_shield:
		shielded_cell = -1

	# Tambah RP untuk pemain yang BARU SAJA selesai giliran
	if award_rp:
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
func end_game(winner_player, win_by_rp = false):  # Menggunakan enum Player, 'null' jika seri
	game_active = false
	win_screen.visible = true

	if winner_player == null:
		win_label.text = "PERMAINAN SERI!"
	else:
		var win_text = "PLAYER " + get_player_symbol_str(winner_player) + " MENANG!"
		if win_by_rp:
			win_text = "PLAYER " + get_player_symbol_str(winner_player) + " MENANG!\n(RP Terbanyak)"
		win_label.text = win_text


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
func get_player_color(player_symbol):
	if player_symbol == "X":
		return Color.from_string("#7e7d7d", Color.WHITE)
	elif player_symbol == "O":
		return Color.from_string("#7ec7fe", Color.WHITE)
	return Color.WHITE


func _update_powerup_button_style(powerup_state, cost):
	var button = powerup_buttons[powerup_state]
	var icon = button.get_node("VBoxContainer/TextureRect")
	var label = button.get_node("VBoxContainer/Label")
	var current_rp = get_current_player_rp()
	var can_player_interact = game_active and not is_bot_thinking and not (is_bot_active and current_turn == Player.O)

	button.disabled = not can_player_interact or current_rp < cost

	if button.disabled:
		icon.modulate = DARK_COLOR
		label.self_modulate = DARK_COLOR
	else:
		icon.modulate = NORMAL_COLOR
		label.self_modulate = NORMAL_COLOR


func update_ui():
	# 1. Update Label Info (menggunakan @onready var dan dict RP)
	player_x_rp_label.text = "RP: " + str(player_rp[Player.X])
	player_o_rp_label.text = "RP: " + str(player_rp[Player.O])
	turn_indicator.text = "Giliran: " + get_player_symbol_str(current_turn)

	# Tentukan apakah pemain bisa berinteraksi
	var can_player_interact = game_active and not is_bot_thinking and not (is_bot_active and current_turn == Player.O)

	# 2. Update Tampilan Papan (25 Tombol)
	var cell_index = 0
	for cell_button in game_board.get_children():
		if cell_button is Button:
			cell_button.disabled = not can_player_interact
			cell_button.text = board_state[cell_index]
			var symbol = board_state[cell_index]
			cell_button.text = symbol

			var base_symbol = get_base_symbol(symbol)
			var color = get_player_color(base_symbol)
			cell_button.modulate = color

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

	# 4. Update Tombol Power-Up
	_update_powerup_button_style(PowerUpState.SHIELD, SHIELD_COST)
	_update_powerup_button_style(PowerUpState.ERASE, ERASE_COST)
	_update_powerup_button_style(PowerUpState.GOLDEN, GOLDEN_COST)
	_update_powerup_button_style(PowerUpState.DOUBLE_1, DOUBLE_COST)
	_update_powerup_button_style(PowerUpState.SWAP_1, SWAP_COST)

	# 5. Update Teks Tombol Power-Up
	powerup_buttons[PowerUpState.SHIELD].get_node("VBoxContainer/Label").text = "Shield\n(%d RP)" % SHIELD_COST
	powerup_buttons[PowerUpState.ERASE].get_node("VBoxContainer/Label").text = "Erase\n(%d RP)" % ERASE_COST
	powerup_buttons[PowerUpState.GOLDEN].get_node("VBoxContainer/Label").text = "Golden\n(%d RP)" % GOLDEN_COST
	powerup_buttons[PowerUpState.DOUBLE_1].get_node("VBoxContainer/Label").text = "Double\n(%d RP)" % DOUBLE_COST
	powerup_buttons[PowerUpState.SWAP_1].get_node("VBoxContainer/Label").text = "Swap\n(%d RP)" % SWAP_COST


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
		status_label.text = "Selesaikan power-up " + str(active_power_up).to_upper() + " dulu!"
		return false
	return true


# --- Fungsi untuk setiap tombol ---


func _on_powerup_shield_pressed():
	# Pengecekan input sekarang ditangani dengan menonaktifkan tombol di update_ui()
	if not _can_activate_powerup(PowerUpState.SHIELD):
		return
	if get_current_player_rp() < SHIELD_COST:
		return

	active_power_up = PowerUpState.SHIELD
	update_ui()


func _on_powerup_erase_pressed():
	# Pengecekan input sekarang ditangani dengan menonaktifkan tombol di update_ui()
	if not _can_activate_powerup(PowerUpState.ERASE):
		return
	if get_current_player_rp() < ERASE_COST:
		return

	active_power_up = PowerUpState.ERASE
	update_ui()


func _on_powerup_golden_pressed():
	# Pengecekan input sekarang ditangani dengan menonaktifkan tombol di update_ui()
	if not _can_activate_powerup(PowerUpState.GOLDEN):
		return
	if get_current_player_rp() < GOLDEN_COST:
		return

	active_power_up = PowerUpState.GOLDEN
	update_ui()


func _on_powerup_double_pressed():
	# Pengecekan input sekarang ditangani dengan menonaktifkan tombol di update_ui()

	# Logika batal sedikit beda
	if active_power_up == PowerUpState.DOUBLE_1 or active_power_up == PowerUpState.DOUBLE_2:
		active_power_up = PowerUpState.NONE
		# Seharusnya RP dikembalikan jika dibatalkan, tapi untuk simpelnya kita anggap hangus
		# modify_current_player_rp(DOUBLE_COST) # <- Aktifkan ini jika ingin RP kembali
		update_ui()
		return

	if active_power_up != PowerUpState.NONE:
		status_label.text = "Selesaikan power-up " + str(active_power_up).to_upper() + " dulu!"
		return

	if get_current_player_rp() < DOUBLE_COST:
		return

	# Bayar RP di MUKA
	modify_current_player_rp(-DOUBLE_COST)
	active_power_up = PowerUpState.DOUBLE_1
	update_ui()


func _on_powerup_swap_pressed():
	# Pengecekan input sekarang ditangani dengan menonaktifkan tombol di update_ui()

	# Logika batal juga beda
	if active_power_up == PowerUpState.SWAP_1 or active_power_up == PowerUpState.SWAP_2:
		active_power_up = PowerUpState.NONE
		swap_cell_1 = -1
		update_ui()
		return

	if active_power_up != PowerUpState.NONE:
		status_label.text = "Selesaikan power-up " + str(active_power_up).to_upper() + " dulu!"
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
	# Logika disabilitas tombol sekarang terpusat di update_ui()
	# Fungsi ini sekarang hanya pemicu untuk update.
	# Argumen is_interactive secara implisit digunakan di dalam update_ui
	# melalui variabel state seperti is_bot_thinking dan current_turn.
	update_ui()


# 1. Memulai giliran bot
func _execute_bot_turn():
	is_bot_thinking = true
	_set_board_interactive(false)  # Matikan input human
	status_label.text = "Player O (Bot) sedang berpikir..."

	# Atur timer "berpikir" (0.75 - 1.5 detik) agar tidak instan
	bot_timer.start(randf() * 0.75 + 0.75)


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

	# PRIORITAS 3: Gunakan Power-Up jika memungkinkan dan menguntungkan
	if _bot_try_use_powerup():
		# Jika bot berhasil menggunakan power-up, power-up itu akan menangani
		# sisa gilirannya (misalnya, _check_game_over atau switch_turn).
		# Jadi, kita bisa keluar dari fungsi ini lebih awal.
		is_bot_thinking = false
		_set_board_interactive(true)
		return

	# PRIORITAS 4: Lakukan langkah terbaik berdasarkan evaluasi
	var best_move = _find_best_move(Player.O)
	if best_move != -1:
		_handle_normal_click(best_move)
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


# 4. HELPER AI: Mencari langkah terbaik dengan evaluasi papan
func _find_best_move(player):
	var best_score = -10000  # Inisialisasi dengan skor yang sangat rendah
	var best_move = -1
	var empty_cells = []

	for i in range(board_state.size()):
		if board_state[i] == "":
			empty_cells.append(i)

	# Jika papan kosong, pilih tengah
	if empty_cells.size() == BOARD_SIZE * BOARD_SIZE:
		return int(BOARD_SIZE * BOARD_SIZE / 2)

	for i in empty_cells:
		# Coba letakkan bidak bot
		board_state[i] = get_player_symbol_str(player)
		var score = _evaluate_board(player)
		board_state[i] = "" # Hapus bidak

		if score > best_score:
			best_score = score
			best_move = i

	return best_move


# 5. HELPER AI: Mengevaluasi skor keseluruhan papan untuk seorang pemain
func _evaluate_board(player):
	var score = 0
	var opponent = get_opponent() if player == current_turn else current_turn

	# Cek setiap sel untuk potensi
	for i in range(board_state.size()):
		score += _evaluate_line(i, player) # Skor untuk membuat baris
		score -= _evaluate_line(i, opponent) # Skor untuk memblokir lawan

	return score


# 6. HELPER AI: Mengevaluasi skor untuk satu baris (horizontal, vertikal, diagonal)
func _evaluate_line(start_index, player):
	var score = 0
	var directions = [[0, 1], [1, 0], [1, 1], [1, -1]]
	
	for dir in directions:
		var own_pieces = 0
		var empty_cells = 0
		var is_blocked = false

		for i in range(WIN_STREAK):
			var r = int(start_index / BOARD_SIZE) + dir[0] * i
			var c = (start_index % BOARD_SIZE) + dir[1] * i

			if r < 0 or r >= BOARD_SIZE or c < 0 or c >= BOARD_SIZE:
				is_blocked = true
				break

			var index = r * BOARD_SIZE + c
			var symbol = get_base_symbol(board_state[index])
			var player_symbol = get_player_symbol_str(player)

			if symbol == player_symbol:
				own_pieces += 1
			elif symbol == "":
				empty_cells += 1
			else:
				is_blocked = true
				break
		
		if not is_blocked:
			if own_pieces == WIN_STREAK - 1 and empty_cells == 1:
				score += 100 # Potensi menang
			elif own_pieces == WIN_STREAK - 2 and empty_cells == 2:
				score += 10 # Potensi baris panjang
			elif own_pieces == WIN_STREAK - 3 and empty_cells == 3:
				score += 1 # Sedikit potensi

	return score


# 7. HELPER AI: Coba gunakan power-up
func _bot_try_use_powerup():
	var bot_rp = player_rp[Player.O]
	var opponent_symbol = get_player_symbol_str(Player.X)

	# Strategi 1: Gunakan ERASE untuk menghancurkan kesempatan menang lawan
	if bot_rp >= ERASE_COST:
		# Cari baris milik lawan yang punya 3 bidak dan 1 kosong (potensi menang)
		var erase_target = _find_line_to_break(Player.X, WIN_STREAK - 1)
		if erase_target != -1:
			# Pastikan target bukan Golden Mark
			if "G" not in board_state[erase_target]:
				status_label.text = "Bot menggunakan power-up ERASE!"
				print("BOT: Menggunakan ERASE pada sel %d" % erase_target)
				_execute_erase(erase_target)
				# Setelah erase, giliran langsung berganti.
				return true # Aksi berhasil dilakukan

	# Strategi 2: Gunakan SHIELD untuk melindungi sel krusial
	# (Misal: untuk melindungi baris 3-bidak milik bot)
	if bot_rp >= SHIELD_COST:
		# Cari sel kosong yang jika diisi BOT akan membuat 3-in-a-row
		var shield_target = _find_line_to_complete(Player.O, WIN_STREAK - 1)
		if shield_target != -1:
			# Pastikan selnya kosong
			if board_state[shield_target] == "":
				status_label.text = "Bot menggunakan power-up SHIELD!"
				print("BOT: Menggunakan SHIELD pada sel %d" % shield_target)
				_execute_shield(shield_target)
				# Menggunakan Shield mengakhiri giliran Bot.
				return true # Aksi berhasil

	# Strategi 3: Gunakan GOLDEN untuk mengamankan kemenangan
	if bot_rp >= GOLDEN_COST:
		# Cari sel kosong yang jika diisi akan membuat 3-in-a-row
		var golden_target = _find_line_to_complete(Player.O, WIN_STREAK - 1)
		if golden_target != -1:
			if board_state[golden_target] == "":
				status_label.text = "Bot menggunakan power-up GOLDEN!"
				print("BOT: Menggunakan GOLDEN pada sel %d" % golden_target)
				_execute_golden(golden_target)
				return true # Aksi berhasil

	return false # Tidak ada power-up yang digunakan


# 8. HELPER AI: Cari baris yang bisa di-break dengan ERASE
func _find_line_to_break(player, streak_needed):
	var player_symbol = get_player_symbol_str(player)
	for i in range(board_state.size()):
		# Cek hanya pada sel yang dimiliki lawan
		if get_base_symbol(board_state[i]) == player_symbol:
			# Simulasikan penghapusan
			var original_symbol = board_state[i]
			board_state[i] = ""

			# Cek apakah dengan menghapus ini, potensi menang lawan hilang?
			# Cara simpel: cek apakah lawan TIDAK BISA menang di giliran berikutnya
			if _find_immediate_win(player) == -1:
				board_state[i] = original_symbol # Kembalikan
				# Logika lebih cerdas: cari baris panjang
				var result = _analyze_threat_at(i, player, streak_needed)
				var is_threatening = result[0]
				var cells = result[1]
				if is_threatening:
					board_state[i] = original_symbol # Kembalikan
					# Pilih salah satu bidak dari baris tersebut untuk dihapus
					if not cells.is_empty():
						return cells[randi() % cells.size()]

			board_state[i] = original_symbol # Kembalikan
	return -1

# 9. HELPER AI: Menganalisa ancaman pada satu titik
func _analyze_threat_at(index, player, streak_needed):
	var r = int(index / BOARD_SIZE)
	var c = index % BOARD_SIZE
	var player_symbol = get_player_symbol_str(player)

	var directions = [[0, 1], [1, 0], [1, 1], [1, -1]] # Horizontal, Vertikal, Diagonal
	for dir in directions:
		var line_cells = []
		var empty_spots = []
		var count = 0
		# Cek ke dua arah dari titik
		for step in range(-streak_needed + 1, streak_needed):
			var new_r = r + dir[0] * step
			var new_c = c + dir[1] * step
			if new_r >= 0 and new_r < BOARD_SIZE and new_c >= 0 and new_c < BOARD_SIZE:
				var new_idx = new_r * BOARD_SIZE + new_c
				var symbol = get_base_symbol(board_state[new_idx])
				if symbol == player_symbol:
					count += 1
					line_cells.append(new_idx)
				elif board_state[new_idx] == "":
					empty_spots.append(new_idx)
		
		# Jika ada baris dengan panjang `streak_needed` dan ada ruang kosong untuk menang
		if count >= streak_needed and empty_spots.size() >= (WIN_STREAK - streak_needed):
			return [true, line_cells]
			
	return [false, []]


# 10. HELPER AI: Cari sel kosong untuk melengkapi baris
func _find_line_to_complete(player, streak_needed):
	for i in range(board_state.size()):
		if board_state[i] == "":
			# Coba isi
			board_state[i] = get_player_symbol_str(player)
			# Cek apakah ini menciptakan baris dengan `streak_needed`
			var result = _analyze_threat_at(i, player, streak_needed)
			var is_potential = result[0]
			board_state[i] = "" # Kembalikan
			if is_potential:
				return i # Kembalikan sel kosongnya
	return -1
