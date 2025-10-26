class_name GameConstants
extends RefCounted

# ===================================================================
#   ENUMERASI (Tipe Data Kustom untuk State)
# ===================================================================
enum Player { X, O, DRAW }
enum PowerUpState { NONE, ERASE, SHIELD, GOLDEN, DOUBLE_1, DOUBLE_2, SWAP_1, SWAP_2 }

# ===================================================================
#   KONSTANTA GAME
# ===================================================================
const SHIELD_COST = 2
const GOLDEN_COST = 2
const ERASE_COST = 4
const SWAP_COST = 4
const DOUBLE_COST = 6

# Pengaturan Papan
const BOARD_SIZE = 5
const WIN_STREAK = 4

# Warna untuk status tombol
const NORMAL_COLOR = Color(1, 1, 1, 1)  # Putih
const DARK_COLOR = Color(0.5, 0.5, 0.5, 1) # Abu-abu

# Path untuk assets
const TEXTURE_X_PATH = "res://assets/images/pedang.png"
const TEXTURE_O_PATH = "res://assets/images/perisai.png"
const POWERUP_INFO_POPUP_PATH = "res://scenes/ui/powerup_info_popup.tscn"