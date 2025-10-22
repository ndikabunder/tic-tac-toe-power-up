# Tic-Tac-Toe Power-Up

A strategic twist on the classic Tic-Tac-Toe game, featuring a 5x5 board and special power-ups that add depth and excitement to gameplay. Challenge yourself against an AI opponent or a friend in this enhanced version of the timeless game.

## 🎮 Features

- **Enhanced Board**: Play on a 5x5 grid where you need 4 in a row to win
- **Power-Up System**: Use special abilities to gain tactical advantages:
  - **Shield**: Protect a cell from opponent moves (cost: 2 RP)
  - **Erase**: Remove an opponent's marker (cost: 4 RP)
  - **Golden Mark**: Place an untouchable marker (cost: 2 RP)
  - **Double Move**: Place two markers in one turn (cost: 6 RP)
  - **Swap**: Exchange positions of two markers on the board (cost: 4 RP)
- **Resource Points (RP)**: Earn and spend points to use power-ups
- **Smart AI**: Built-in computer opponent with strategic thinking
- **Turn-Based Strategy**: Plan your moves and power-up usage carefully

## 📋 How to Play

### Basic Rules
- Players alternate turns placing their markers (X or O) on the 5x5 board
- Win by getting 4 of your markers in a row (horizontally, vertically, or diagonally)
- Earn 1 Resource Point (RP) at the end of each turn

### Power-Up Usage
1. Each power-up requires a certain amount of Resource Points (RP)
2. Click a power-up button to activate it
3. Follow the on-screen prompts to select the appropriate cells
4. Pay the RP cost when the action is completed

### Special Markers
- **Regular Markers**: "X" or "O" - placed normally
- **Golden Markers**: "GX" or "GO" - cannot be erased by opponent

## ⚙️ Installation

1. Install Godot Engine (version 4.x or later)
2. Clone or download this repository
3. Open the project in Godot
4. Run the game from the editor or export for your platform

## 🔧 Controls

- **Left Click**: Place a marker or select cells
- **Power-Up Buttons**: Activate special abilities
- **Restart Button**: Start a new game

## 🎯 Game Strategy

- Manage your Resource Points wisely - don't spend them all at once
- Balance between placing markers and using power-ups
- Consider blocking your opponent's potential winning lines
- Use the Shield power-up to protect key positions
- The Swap power-up can create unexpected winning opportunities

## 🤖 AI Behavior

The computer opponent features:
- Win detection - will prioritize winning moves
- Blocking - will attempt to block your winning moves
- Strategic placement - prefers moves near existing markers
- Random thinking delay for a more human-like experience

## 🛠️ Technical Details

- Language: GDScript
- Engine: Godot 4.x
- Game Mode: Turn-based strategy
- Board Size: 5x5
- Win Condition: 4 in a row

## 📜 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 👨‍💻 Author

Created by Ghibran as a Godot learning project.