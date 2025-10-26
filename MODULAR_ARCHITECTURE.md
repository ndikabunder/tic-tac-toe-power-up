# Tic-Tac-Toe Power-Up - Modular Architecture

## Overview
Project ini telah direstrukturisasi dari monolitik (936 baris dalam satu file) menjadi arsitektur modular yang terorganisir dengan baik untuk meningkatkan maintainability, readability, dan scalability.

## Struktur Folder

```
/
├── scripts/                          # Semua script GDScript
│   ├── core/                         # Core game logic
│   │   ├── game_manager.gd          # [DEPRECATED] Koordinator utama game
│   │   ├── board_manager.gd         # Logika papan dan validasi moves
│   │   └── turn_manager.gd          # Manajemen giliran dan RP
│   ├── powerups/                     # Power-up system
│   │   └── powerup_manager.gd       # Manajer semua power-up
│   ├── ai/                          # AI/Bot system
│   │   ├── bot_controller.gd        # Controller utama bot
│   │   └── board_evaluator.gd       # Evaluasi papan untuk AI
│   ├── ui/                          # UI management
│   │   ├── ui_manager.gd            # Manajemen UI utama
│   │   └── powerup_info_popup.gd    # Popup info power-up
│   └── utils/                       # Utility functions
│       ├── game_constants.gd        # Konstanta dan enums
│       └── helper_functions.gd      # Fungsi helper reusable
├── scenes/                          # Scene files
│   ├── main/                        # Main game scenes
│   │   ├── game_screen.tscn         # Scene utama game
│   │   └── main_scene.tscn          # Entry point
│   └── ui/                          # UI scenes
│       └── powerup_info_popup.tscn  # Popup info
├── assets/                          # Assets
│   └── images/                      # Semua gambar
│       ├── pedang.png               # Asset X (sword)
│       ├── perisai.png              # Asset O (shield)
│       ├── background.png           # Background
│       ├── bingkai.png              # Frame
│       └── [power-up icons]         # Icon power-up
└── project.godot                    # Konfigurasi project
```

## Komponen Modular

### 1. Utils (Foundation Layer)

#### GameConstants
- **Location**: `scripts/utils/game_constants.gd`
- **Purpose**: Centralized constants and enums
- **Contains**:
  - `Player` enum (X, O)
  - `PowerUpState` enum
  - Game constants (costs, board size, win streak)
  - Asset paths
  - Color constants

#### HelperFunctions
- **Location**: `scripts/utils/helper_functions.gd`
- **Purpose**: Reusable utility functions
- **Contains**:
  - Symbol manipulation functions
  - Player utilities
  - Board coordinate conversions
  - Color management

### 2. Core Game Logic

#### BoardManager
- **Location**: `scripts/core/board_manager.gd`
- **Purpose**: Manages game board state and validation
- **Responsibilities**:
  - Board state management
  - Move validation
  - Win condition checking
  - Symbol placement/removal
  - Board analysis functions

#### TurnManager
- **Location**: `scripts/core/turn_manager.gd`
- **Purpose**: Manages game turns and player resources
- **Responsibilities**:
  - Turn management
  - RP (Resource Points) tracking
  - Player identification
  - Turn switching logic

### 3. Power-Up System

#### PowerUpManager
- **Location**: `scripts/powerups/powerup_manager.gd`
- **Purpose**: Centralized power-up management
- **Responsibilities**:
  - Power-up activation/deactivation
  - Power-up execution logic
  - State management for active power-ups
  - RP validation and deduction
  - Special state handling (shield, swap)

### 4. AI System

#### BotController
- **Location**: `scripts/ai/bot_controller.gd`
- **Purpose**: High-level bot decision making
- **Responsibilities**:
  - Bot turn management
  - Strategic decision making
  - Power-up usage logic
  - Turn timing control

#### BoardEvaluator
- **Location**: `scripts/ai/board_evaluator.gd`
- **Purpose**: Board position evaluation for AI
- **Responsibilities**:
  - Position scoring
  - Move evaluation
  - Threat analysis
  - Best move calculation

### 5. UI Management

#### UIManager
- **Location**: `scripts/ui/ui_manager.gd`
- **Purpose**: Centralized UI management
- **Responsibilities**:
  - UI updates and synchronization
  - Power-up button styling
  - Board display management
  - Status message handling
  - Win screen management

### 6. Main Coordinator

#### GameScreen
- **Location**: `game_screen.gd` (root script)
- **Purpose**: Main game coordinator
- **Responsibilities**:
  - Manager initialization and setup
  - Signal connection and routing
  - High-level game flow control
  - Integration of all systems

## Alur Data dan Communication

### Signal-Based Architecture
System menggunakan signal-based communication untuk loose coupling:

```
User Input → GameScreen → [Managers] → UIManager → Display Update
```

### Manager Dependencies
```
GameScreen (Coordinator)
├── BoardManager (Board state)
├── TurnManager (Turns & RP)
├── PowerUpManager (Power-ups)
│   ├── depends on: BoardManager
│   └── depends on: TurnManager
├── BotController (AI logic)
│   ├── depends on: BoardManager
│   ├── depends on: TurnManager
│   └── depends on: PowerUpManager
└── UIManager (Display)
    ├── depends on: All managers
    └── receives signals from all
```

## Benefits of Modular Architecture

### 1. **Maintainability**
- Setiap komponen memiliki responsibility yang jelas
- Mudah untuk locate dan fix bugs
- Dependencies terdokumentasi dengan jelas

### 2. **Scalability**
- Mudah menambah power-up baru
- Mudah mengimplementasikan AI strategy baru
- Mudah menambah UI elements baru

### 3. **Testability**
- Setiap manager dapat di-test secara独立
- Mock dependencies untuk unit testing
- Isolated logic validation

### 4. **Reusability**
- Helper functions dapat digunakan di seluruh project
- Managers dapat digunakan di game modes berbeda
- AI components dapat digunakan untuk games lain

### 5. **Readability**
- Code organization yang logical
- Clear separation of concerns
- Documentation for each component

## Migration dari Monolitik

### Before (936 baris dalam 1 file):
```gdscript
# Semua logic dalam game_screen.gd
# - Board state
# - Turn management
# - Power-up logic
# - AI logic
# - UI updates
# - Signal handling
```

### After (Modular):
```gdscript
# Terdistribusi across 8+ specialized files
# Setiap file dengan responsibility yang jelas
# Dependencies yang explicit
# Documentation yang lengkap
```

## How to Extend

### Menambah Power-Up Baru:
1. Tambah enum di `GameConstants`
2. Tambah cost constant di `GameConstants`
3. Tambah execution logic di `PowerUpManager`
4. Tambah UI button di `GameScreen`
5. Tambah AI logic di `BotController`

### Menambah AI Strategy:
1. Tambah evaluation function di `BoardEvaluator`
2. Tambah strategy logic di `BotController`
3. Tambah priority di decision tree

### Menambah UI Elements:
1. Tambah node references di `GameScreen`
2. Tambah management logic di `UIManager`
3. Connect signals di `GameScreen`

## Best Practices

1. **Single Responsibility**: Setiap class memiliki satu purpose
2. **Dependency Injection**: Managers menerima dependencies via constructor
3. **Signal Communication**: Gunakan signals untuk loose coupling
4. **Documentation**: Setiap class memiliki clear documentation
5. **Constants**: Centralize semua constants di `GameConstants`
6. **Error Handling**: Validate inputs dan handle edge cases
7. **Testing**: Consider unit tests untuk critical logic

## Conclusion

Arsitektur modular ini meningkatkan code quality significantly:
- **Readability**: 936 lines → 8 focused files
- **Maintainability**: Clear responsibilities, easy debugging
- **Extensibility**: Easy to add new features
- **Testability**: Components can be tested independently
- **Reusability**: Components can be reused in other projects