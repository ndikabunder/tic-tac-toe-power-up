# Tic-Tac-Toe Power-Up - Modular Architecture

## Quick Setup

### Prerequisites
- Godot Engine 4.5 or later
- Project telah direstrukturisasi menggunakan arsitektur modular

### Cara Menjalankan Project

1. **Buka di Godot Editor**
   - Buka Godot Engine
   - Import project dengan memilih folder ini
   - Main scene sudah diatur ke `scenes/main/main_scene.tscn`

2. **Run Project**
   - Tekan F5 atau klik "Play" button
   - **Start Menu akan muncul** dengan pilihan:
     - **Start Game** - Mulai bermain
     - **Exit** - Keluar dari game

3. **Dalam Game**
   - Game akan dimulai dengan AI bot aktif
   - **Menu Button** - Kembali ke start menu kapan saja
   - **Info Button** - Lihat penjelasan power-up

4. **Konfigurasi Bot**
   - Di Inspector, pada node `GameScreen`, Anda dapat toggle `is_bot_active`
   - Set ke `false` untuk bermain 2-player mode

### Struktur Project

```
📁 Modular Architecture
├── 📂 scripts/           # Semua logic code
│   ├── 📂 core/         # Core game logic
│   ├── 📂 powerups/     # Power-up system
│   ├── 📂 ai/           # AI/Bot logic
│   ├── 📂 ui/           # UI management
│   └── 📂 utils/        # Constants & helpers
├── 📂 scenes/           # Scene files
│   ├── 📂 main/         # Main game scenes
│   │   ├── start_menu.tscn  # Start menu dengan animasi
│   │   ├── game_screen.tscn # Main game scene
│   │   └── main_scene.tscn  # Entry point
│   └── 📂 ui/           # UI components
└── 📂 assets/           # All assets
    └── 📂 images/       # Images & textures
```

### Game Features

✅ **Core Gameplay**
- Papan 5x5 dengan win condition 4-in-a-row
- Sistem RP (Resource Points) untuk power-up
- Turn-based gameplay dengan visual feedback

✅ **Power-Ups**
- 🛡️ **Shield** (2 RP) - Lindungi sel dari attack
- 🗑️ **Erase** (4 RP) - Hapus simbol lawan
- ⭐ **Golden** (2 RP) - Tempatkan mark yang tidak bisa dihapus
- 🔁 **Double** (6 RP) - Gerakan dua kali
- 🔄 **Swap** (4 RP) - Tukar posisi dua simbol

✅ **AI Bot**
- Smart AI dengan strategic decision making
- Priority system: Win → Block → Power-up → Best Move
- Power-up usage logic
- Realistic thinking time (0.75-1.5 seconds)

### Controls

#### Start Menu
- **Start Game** - Memulai permainan baru
- **Exit** - Keluar dari aplikasi
- **Keyboard**: `Enter` atau `Space` untuk Start, `Esc` untuk Exit

#### Dalam Game
- **Mouse Click** - Pilih cell atau aktifkan power-up
- **Power-up Buttons** - Klik untuk mengaktifkan power-up
- **Menu Button** - Kembali ke start menu
- **Info Button** - Lihat penjelasan power-up
- **Restart Button** - Mulai game baru (di win screen)
- **Menu Utama** - Kembali ke start menu (di win screen)

### Troubleshooting

#### Error: "Parser Error: extends can only be used once"
✅ **Sudah diperbaiki** - Error ini terjadi karena double `extends` statement di `game_screen.gd`

#### Error: Path not found
✅ **Sudah diperbaiki** - Semua asset path sudah diupdate ke struktur baru

#### Scene tidak muncul
- Pastikan main scene di-set ke `scenes/main/main_scene.tscn`
- Cek project settings → Run → Main Scene

### Development Guide

#### Menambah Power-Up Baru
1. Edit `scripts/utils/game_constants.gd`:
   - Tambah enum value
   - Tambah cost constant

2. Edit `scripts/powerups/powerup_manager.gd`:
   - Tambah execution function
   - Tambah logic di `handle_cell_click()`

3. Edit `game_screen.gd`:
   - Tambah button handler
   - Connect button signal

#### Menambah AI Strategy
1. Edit `scripts/ai/bot_controller.gd`:
   - Tambah strategy logic di `try_use_powerup()`

2. Edit `scripts/ai/board_evaluator.gd`:
   - Tambah evaluation function
   - Modifikasi scoring system

#### Modifying UI
1. Edit scene files di `scenes/`
2. Update node references di `game_screen.gd`
3. Modify display logic di `scripts/ui/ui_manager.gd`

### Architecture Benefits

🎯 **Modular** - Setiap komponen memiliki responsibility yang jelas
🔧 **Maintainable** - Mudah locate dan fix bugs
📈 **Scalable** - Mudah tambah fitur baru
🧪 **Testable** - Components dapat di-test independently
♻️ **Reusable** - Components dapat digunakan di project lain

### File Reference

| Component | File | Purpose |
|-----------|------|---------|
| **Start Menu** | `scripts/ui/start_menu.gd` | Menu utama dengan animasi |
| **Main Coordinator** | `game_screen.gd` | Integrasi semua system |
| **Board Logic** | `scripts/core/board_manager.gd` | Papan & validasi |
| **Turn Management** | `scripts/core/turn_manager.gd` | Giliran & RP |
| **Power-ups** | `scripts/powerups/powerup_manager.gd` | Semua logic power-up |
| **AI Controller** | `scripts/ai/bot_controller.gd` | AI decision making |
| **UI Manager** | `scripts/ui/ui_manager.gd` | UI updates & display |
| **Constants** | `scripts/utils/game_constants.gd` | Centralized constants |
| **Helpers** | `scripts/utils/helper_functions.gd` | Utility functions |

---

**Project ini berhasil di-restrukturisasi dari 936 baris monolitik menjadi 8+ file modular yang maintainable!** 🎉