# Idle Number Kit (Lite)

Free, MIT-licensed GDScript utilities for Godot 4 idle/incremental games:
arbitrary-magnitude numbers and player-facing formatting. Extracted from a
larger paid asset so you can try the core math for free before buying the
full kit.

Built and tested by an AI (see [snowball-ai](https://github.com/maindtim/snowball-ai)
for the transparency reports behind this project). A human owns the
accounts and the code; the AI writes and tests it.

## What's inside

- **`addons/idle_number_kit_lite/big_number.gd`** — `BigNumber`: stores a value as `mantissa * 10^exponent`
  so idle-game economies can go far past float range (well beyond `1e308`)
  without losing precision where it matters. Arithmetic (`add`, `sub`, `mul`,
  `div`, `power`), comparisons, string parsing (`"1.5e300"`), and dictionary
  (de)serialization for save files.
- **`addons/idle_number_kit_lite/number_formatter.gd`** — `NumberFormatter`: turns a `BigNumber` into
  player-facing text — `1.23K`, `4.56Qa`, `7.89aa`, or scientific/engineering
  notation once the short-suffix table runs out.
- **`run_tests.gd`** — headless test runner, 37 checks. Run it yourself:

  ```sh
  godot --headless --script run_tests.gd
  ```

## Install

**From the Godot editor:** open the AssetLib tab, search for *Idle Number Kit Lite* and install it.

**Manually:** copy the `addons/idle_number_kit_lite` folder into your Godot 4 project.
Both are plain `RefCounted` classes with `class_name`, so `BigNumber.new(...)`
and `NumberFormatter.format(...)` work anywhere once the files are in your
project.

```gdscript
var gold := BigNumber.from_float(0.0)
gold = gold.add(BigNumber.from_float(1234.0))
print(NumberFormatter.format(gold)) # "1.23K"
```

## Want more?

This lite kit covers big numbers and formatting. The full **Idle Economy
Kit** adds generators with cost curves, an income/purchase loop, offline
progress, prestige, and a versioned save system with atomic writes and
automatic backup/migration — all with a 73-check test suite and a playable
demo:

**[Idle Economy Kit on itch.io — $4.99](https://cesarlars.itch.io/idle-economy-kit)**

## License

MIT — see [LICENSE](LICENSE). Use it in anything, commercial or not.
