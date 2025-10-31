Here is the **final GitHub-optimized README** with badges and full structured layout:

---

# CursorRing

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0.html)
![WoW Version](https://img.shields.io/badge/WoW-Retail_\(The_War_Within\)-orange)
![Language](https://img.shields.io/badge/Lua-5.1%2B-lightgrey)
![Status](https://img.shields.io/badge/Status-Active-green)

---

**CursorRing** is a World of Warcraft addon that adds a customizable, class-colored ring around your cursor.
It dynamically tracks spell casts, channels, and combat states, providing visual feedback through smooth radial animations.
It's inspried by the indispensible [Ultimate Mouse Cursor](https://wago.io/ZbjlsgMkp) WeakAura by [Ultimate](https://wago.io/p/Ultimate)
And it only works as well as it does because of the contributions of my brother.

---

## Features

* **Class-colored cursor ring**
  Matches your character’s class color or a custom RGB color.

* **Cast progress display**
  Shows real-time radial fill during casts and channels.
  Supports segmented or legacy half-circle animation.

* **Visibility control**
  Configurable to appear always, only in combat, or only inside instances.

* **In-game configuration**
  Accessible via *Interface → AddOns → CursorRing* or the modern *Settings* menu.
  Includes:

  * Ring size slider
  * Ring and cast color pickers
  * “Show out of combat” toggle
  * “Reset to class color” button

* **Persistent settings**
  Stored in `CursorRingDB` between sessions.

---

## Textures and Assets

Expected files in
`Interface\AddOns\CursorRing\`:

* `ring.tga` — main cursor ring
* `cast_segment.tga` — wedge segment for smooth progress
* `innerring_left.tga`, `innerring_right.tga` — legacy fallback halves

If `cast_segment.tga` is missing, the addon uses the half-circle fallback animation. You really don't want that, but some older versions of WoW won't support the `cast_segment.tga` method.

---

## Technical Summary

* **Language:** Lua (WoW API only)
* **Event handling:** Unified handler for spellcast, combat, zone, and login events
* **Saved Variables:**

  * `CursorRingDB.ringSize`
  * `CursorRingDB.ringColor`
  * `CursorRingDB.castColor`
  * `CursorRingDB.showOutOfCombat`

---

## Installation

1. Extract the addon into your WoW AddOns directory:

   ```
   World of Warcraft/_retail_/Interface/AddOns/CursorRing/
   ```
2. Ensure the following files exist:

   ```
   CursorRing.lua
   CursorRing.toc
   ring.tga
   innerring_left.tga
   innerring_right.tga
   (optional) cast_segment.tga
   ```
3. Restart WoW or use `/reload`.

---

## Contributing

Contributions and feature requests are welcome.

* Submit issues or pull requests via GitHub.
* Follow Blizzard’s Lua API standards.
* Ensure compatibility with *Retail (The War Within)*.
* Test changes with `/reload` and enable script errors using `/console scriptErrors 1`.

---

## Credits

* **Authors:** Alex Pierce and his brother.
* **Art & Design:** Alex Pierce, who draws circles in GIMP 3.x , and the WoW artists we've used the icons of :D
* **References:** Blizzard UI API and open-source addon templates.

---

## License

This project is licensed under the **GNU General Public License v3.0 (GPL v3)**.
You are free to modify and redistribute under the same terms.
Full text: [https://www.gnu.org/licenses/gpl-3.0.html](https://www.gnu.org/licenses/gpl-3.0.html)
