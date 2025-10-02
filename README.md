# UnitSideNumbers-WotLK
Lightweight addon for **World of Warcraft: Wrath of the Lich King 3.3.5a (12340)** that adds **clear side numbers** next to Blizzard’s default frames (Player/Target/Focus): **%HP**, **current/max HP**, and **current/max Power**. Separate holders and boosted frame levels ensure nothing overlaps or hides the text.

<img width="474" height="125" alt="image" src="https://github.com/user-attachments/assets/e7cba24b-6e1c-4088-94c3-0a06f5621fc5" />

---

## Key Features
- **Three data lines** next to each unit frame:
  1. **% HP** (slightly raised for readability)
  2. **HP current / max** (short format like `12.5k`, `1.2m`)
  3. **Power current / max** (hidden if the unit has no power bar)
- **Stable layering** — independent holder with boosted `FrameLevel`, so text never gets occluded.
- **Player level color** (top-right of PlayerFrame) with multiple modes:
  - `RANGE` — by level ranges (≤19 gray, ≤39 white, ≤59 light blue, ≤69 orange, 70–79 green, 80 yellow)
  - `CLASS` — player class color
  - `STATIC` — fixed color via `/usn lvlrgb R G B`
- **Simple slash commands** for position reset and frame strata.

---

## Compatibility
- **Client:** WotLK 3.3.5a (build 12340)  
- **Frames:** Player, Target, Focus (default Blizzard frames)

---

## Installation
1. Place the folder **`UnitSideNumbers-WotLK`** into:
