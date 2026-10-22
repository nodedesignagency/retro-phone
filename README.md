# Retro Phone

An iPhone dialer built as a piece of hardware: a matte black face divided
into square tiles, with a speaker grille, a black mono screen, round keys
sunk into collars, an orange call button and a row of grey-to-white
speed-dial knobs.

v1, the photographic chrome rotary dial, is kept on the `v1` branch.

## Run it

From Terminal, with Xcode 16 or later installed:

```sh
./scripts/run.sh                            # newest iPhone simulator
SIMULATOR="iPhone 16 Pro" ./scripts/run.sh  # or pick one by name
```

It builds the app, boots the simulator and launches Retro Phone. Build
errors are printed in the Terminal.

Or open `RetroPhone.xcodeproj` in Xcode, pick a simulator or your phone, and
press Run. For a real device, choose your team under *Signing & Capabilities*
first.

Requires iOS 17. On iOS 26 and later the boxes, the index window and the
buttons are Liquid Glass; on iOS 17 and 18 they use a blurred material with
a lit rim.

## Using it

- **Keys:** `1 2 3 4` / `5 6 7 8` / `9 0 * #`, plus `+` for international
  numbers. Each key clicks and its LED lights while it's down.
- **Screen:** the number fills `000 000 0000`; status messages appear on the
  top line. Touch and hold the screen to copy or paste.
- **Call:** the orange button. With nothing dialled it brings back the last
  number you called.
- **Delete / Clear:** tap DELETE to remove a digit (hold to clear), or tap
  CLEAR.
- **Speed dials S1–S4:** touch and hold a knob to save the current number;
  tap it to bring the number back. A lit LED means the slot is in use.

## Layout

```
RetroPhone/
  App/          app entry point
  Dialer/       the screen layout, model (number, speed dials), formatter
  Device/       tiles, keys, pills, knobs, grille, the mono screen
  Feedback/     Core Haptics and the synthesised key click
  Design/       palette, shake effect
Config/Info.plist  enables 120 Hz on iPhone (merged with the generated plist)
```
