# CursorRing

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0.html)
![WoW Version](https://img.shields.io/badge/WoW-Retail_\(The_War_Within\)-orange)
![Language](https://img.shields.io/badge/Lua-5.1%2B-lightgrey)
![Status](https://img.shields.io/badge/Status-Active-green)

---

**CursorRing** is a World of Warcraft addon that enhances your mouse cursor with a customizable, class-colored ring, real-time spell cast/channel progress, and optional mouse trail effects. It is inspired by the excellent [Ultimate Mouse Cursor](https://wago.io/ZbjlsgMkp) WeakAura by [Ultimate](https://wago.io/p/Ultimate) and improved by the contributions of my brother.

---

## Features

- **Class-colored cursor ring**
  - Matches your character’s class color or a custom RGB color.
- **Cast progress display**
  - Real-time radial fill during casts and channels.
  - Choose segmented or legacy half-circle animation.
- **Visibility control**
  - Only show in combat/instances, or always show.
- **Mouse Trail & Sparkles**
  - Optional glowing trail and sparkle effect behind the cursor.
  - Customizable trail/sparkle color and fade length.
- **Full in-game configuration**
  - Accessible via *Options → AddOns → CursorRing* or the modern *Settings* menu.
  - Includes: ring size slider, ring/cast/trail/sparkle color pickers, toggles for trail and combat visibility, “reset to class color”, and more.
- **Persistent, per-spec settings**
  - All preferences are saved character spec-wise in `CursorRingDB`.

---

## Textures and Assets

The addon expects the following files in  
`Interface\AddOns\CursorRing\`:

- `ring.tga` — main cursor ring
- `cast_segment.tga` — wedge segment for cast/channel progress
- `cast_wedge.tga`
- `sparkle.tga`
- `trail_glow.tga`
- `innerring_left.tga` and `innerring_right.tga` — legacy fallback halves

If modern segment textures are missing, the addon falls back to half-circle animation (not recommended for newer WoW clients).

---

## Installation

1. **Download** or **clone** this repository:
    ```bash
    git clone https://github.com/RedAntisocial/CursorRing.git
    ```
2. Put the `CursorRing` folder inside your WoW AddOns directory:
    ```
    World of Warcraft/_retail_/Interface/AddOns/CursorRing/
    ```
3. Ensure the required files from the assets section are present.
4. Reload your UI (`/reload`).

Alternatively, use your favourite addon manager (Wago, CurseForge, etc).

---

## Usage & Configuration

- Open the options panel:
    - In-game: *Interface → AddOns → CursorRing* or via the new *Settings* system.
- Configure:
    - Cursor ring enabled, size, color (or reset to class color)
    - Cast ring style and color
    - Mouse trail (toggle, color, length)
    - Sparkle effect for mouse trail
    - Trail/sparkle color pickers
    - Show only in combat/instances or anywhere

### Commands

- Type `/reload` after changing settings for best results (or use in-game settings).

---

## Technical Summary

- **Language:** Lua, WoW API (no dependencies outside Blizzard UI)
- **Event-driven:** Handles spellcast, combat, spec, zone, and login events automatically
- **Saved Variables (per-spec):**
    - `CursorRingDB.ringEnabled`
    - `CursorRingDB.ringSize`
    - `CursorRingDB.ringColor`
    - `CursorRingDB.castColor`
    - `CursorRingDB.showOutOfCombat`
    - `CursorRingDB.castStyle`
    - `CursorRingDB.mouseTrail`
    - `CursorRingDB.sparkleTrail`
    - `CursorRingDB.trailFadeTime`
    - `CursorRingDB.trailColor`
    - `CursorRingDB.sparkleColor`

---

## Contributing

Contributions and feature requests are welcome!

- Submit issues or pull requests via GitHub.
- Follow Blizzard’s Lua API standards.
- Test changes with `/reload` and enable script errors using `/console scriptErrors 1`.
- Ensure compatibility with *Retail (The War Within)*.

---

## Credits

- **Authors:** Alex Pierce and brother.
- **Art & Design:** Alex Pierce (GIMP 3.x) and WoW artists whose icons are used.
- **Special Thanks:** Blizzard UI API authors, and [Ultimate Mouse Cursor](https://wago.io/ZbjlsgMkp).

---

## License

This project is licensed under the **GNU General Public License v3.0 (GPL v3)**.  
You are free to modify and redistribute under the same terms.  
Full text: [https://www.gnu.org/licenses/gpl-3.0.html](https://www.gnu.org/licenses/gpl-3.0.html)

---
