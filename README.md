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

1. Code > Download ZIP, rename **`UnitSideNumbers-WotLK`** to **`UnitSideNumbers`**
2. Place the folder **`UnitSideNumbers`** into: World of Warcraft\Interface\AddOns\
3. In-game, enable **Load out of date addons** if needed.
4. Enter the world — the addon works out of the box.

---

## Usage (Slash Commands)

Prefix: **`/usn`**

- **Reset positions**
  /usn strata LOW
  /usn strata MEDIUM
  /usn strata HIGH

- **Set static RGB color (values 0..1)**
  /usn lvlrgb 1 0.8 0.2

### Level Color Modes

| Mode   | Description                                                                                     |
| ------ | ----------------------------------------------------------------------------------------------- |
| RANGE  | Color by level ranges (≤19 gray, ≤39 white, ≤59 light blue, ≤69 orange, 70–79 green, 80 yellow) |
| CLASS  | Player’s class color (`RAID_CLASS_COLORS`)                                                      |
| STATIC | Fixed color set with `/usn lvlrgb R G B`                                                        |

Current mode and color are **persisted** across `/reload`.

---

## Advanced Config (`cfg` snippet)

> Tweak in code (`local cfg = { ... }`)

- `font` – font path (`Fonts\\FRIZQT__.TTF`)
- `size` – font size (default `10`)
- `outline` – outline style (`"OUTLINE"`)
- `spacing` – spacing between line 2 and 3 (default `-2`)
- `offset` – horizontal distance from the frame (default `-2`)
- `width`, `height` – holder size (default `120 × 40`)
- `percentYOffset` – small lift for the **%HP** line
- `holderFrameLevelBoost` – how many levels above Blizzard’s frame to raise the holder
- `levelOffsetX`, `levelOffsetY` – **player level** position (top-right of PlayerFrame)

Saved globals:

- `UnitSideNumbers_Strata` – `LOW`/`MEDIUM`/`HIGH` (default `MEDIUM`)
- `UnitSideNumbers_LevelMode` – `RANGE`/`CLASS`/`STATIC`
- `UnitSideNumbers_LevelColor` – `{r,g,b}` used when mode is `STATIC`

---

## Screenshots

Place your screenshot at **`docs/preview.png`** to display the image above.  
You can add more images in `docs/` and reference them, e.g.:

```md
![Target & Focus](docs/target_focus.png)
```

## Changelog

```md
v1.5

- Stabilized layering with independent holders and boosted FrameLevel so %HP is never hidden.
- Player level color by range (RANGE) with alternatives CLASS and STATIC.
- Short number formatting (k, m) for HP/Power.
```

## FAQ

```md
Q: I don’t see the Power line.
A: It’s hidden if the unit has no power (UnitPowerMax == 0).

Q: Text overlaps the frame.
A: Use /usn reset, then adjust offset/spacing in cfg (in code) or raise strata with /usn strata HIGH.
```
