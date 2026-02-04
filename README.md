# Combat Timer

Combat status indicator for World of Warcraft (Midnight expansion, Interface 120000).

## Features

- **Combat+ / Combat-** – Displays status text when entering or leaving combat (flashes for 2 seconds)
- **Combat timer** – 00:00 format timer during combat (hidden until combat starts)
- **Draggable frames** – Move status and timer independently in edit mode
- **Timer font size** – Adjust via slash command (8–48 or small/medium/large)

## Installation

1. Download or clone into `World of Warcraft\_retail_\Interface\AddOns\CombatTimer\`
2. Ensure the addon is enabled at character select

## Usage

### Slash commands

| Command | Description |
|---------|-------------|
| `/ct` or `/combattimer` | Toggle edit mode |
| `/ct font <size>` | Timer font: 8–48, or `small` / `medium` / `large` |
| `/ct reset` | Reset positions to default |
| `/ct help` | Show help |

### Edit mode

Use `/ct` (or `/combattimer`) to toggle edit mode. When enabled, drag the status and timer frames to position them. Run `/ct` again to exit.

## Requirements

- World of Warcraft (Midnight, Interface 120000)

## License

See [LICENSE](LICENSE).
