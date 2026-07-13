# AbysseaProc

Auto-detects Abyssea elemental WS procs from chat, swaps weapons, and manages the full proc cycle.

## Setup

Edit `data/settings.lua` with your proc weapons, kill weapon, and per-character overrides.

## Controls
| Key | Action |
|-----|--------|
| **F10** | Cycle element (+ Kill mode at end) |
| **F11** | Cycle weapon for current element |
| **F12** | Use appropriate weaponskill |

## Commands
| Command | Action |
|---------|--------|
| `//aproc element` | Cycle element |
| `//aproc weapon` | Cycle weapon |
| `//aproc ws` | Use WS |
| `//aproc kill` | Show kill weapon |
| `//aproc kill Chango / Utu Grip` | Set kill weapon |
| `//aproc reload` | Reload settings.lua |
| `//aproc reset` | Reset to first element |

## Full Automated Flow
1. **Load** → equips Fire proc weapon → sets autows to Fire WS → autows ON
2. **AutoWS spams** proc WS (e.g. Red Lotus Blade) until vulnerability message appears
3. **Vulnerability detected** → autows OFF → swaps to correct element weapon → F12 to fire proc WS manually
4. **Stagger lands** → swaps to kill weapon → sets autows to kill WS → autows ON → kills mob
5. **Next mob** → next vulnerability message auto-swaps out of Kill mode → repeat

## Features
- Auto-detects "The fiend appears vulnerable to..." and equips matching weapon
- Auto-swaps back to kill weapon on "attack staggers the fiend!"
- AutoWS integration: ON for fishing/killing, OFF during proc attempt
- Repeated same-element messages ignored (won't reset your F11 selection)
- IPC multibox: any account that detects element broadcasts to all others
- Kill mode in F10 cycle (skipped if kill disabled for character)
- HUD overlay with element-colored text and gold kill weapon
- HUD position saves on unload (drag to reposition)
- Sets GearSwap weapons to None on load (Selendrile compatibility)
- Normalizes game text ("darkness"→"Dark", "lightning"→"Thunder")

## Settings (data/settings.lua)
- `kill_weapon` / `kill_sub` / `kill_ws` — kill weapon config
- `key_element` / `key_weapon` / `key_ws` — keybinds
- `hud_x` / `hud_y` — HUD position (auto-saved on unload)
- `weapons` — proc weapons by type (main + sub)
- `kill_per_character` — per-character kill overrides (or `kill_weapon = false` for proc-only)
- `weapons_per_character` — per-character weapon overrides (merged with defaults)

## Per-Character Examples
```lua
kill_per_character = {
    Deemo = {kill_weapon = "Chango", kill_sub = "Utu Grip", kill_ws = "Upheaval"},
    Kiakoda = {kill_weapon = false},  -- proc only, no kill mode
},

weapons_per_character = {
    Pferi = {
        ["Sword"] = {main = "Twinned Blade", sub = "Ammurapi Shield"},
        ["Club"]  = {main = "Chac-chacs", sub = "Ammurapi Shield"},
    },
},
```

## Notes
- Requires Discernment key item to see proc messages
- Works with any job, no GearSwap dependency for proc detection
- If using Selendrile GearSwap, weapons are set to None on load automatically
- AutoWS requires Selendrile GearSwap (`gs c autows` / `gs c set AutoWSMode`)
