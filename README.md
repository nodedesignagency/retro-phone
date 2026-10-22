# Retro Phone

An iPhone dialer whose keypad is a camera-style mode dial: a semicircle of
hairline ticks, a ring of digits that spins under an amber index, and glass
surfaces throughout. Black, minimal, Apple's keypad layout.

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

## Using the dial

- **Spin:** drag the ring. Each digit clicks as it passes the index; flick it
  and it coasts a few digits and settles. Let go after a turn and the digit
  under the index is entered.
- **Tap:** tap any digit and the ring spins it to the index and enters it.
  Tap the digit already under the index to enter it again.
- **Call:** the green button places the call. With nothing dialled it brings
  back the last number you called, like the iPhone keypad.
- **Delete:** tap to remove a digit, touch and hold to clear.
- **Copy/paste:** touch and hold the number boxes.

## Layout

```
RetroPhone/
  App/          app entry point
  Dialer/       screen, number boxes, call/delete controls, model, formatter
  ModeDial/     geometry, engine (spin physics, detents, queue), the dial view
  Feedback/     Core Haptics and synthesised clicks
  Design/       glass material, palette, button press style, shake effect
Config/Info.plist  enables 120 Hz on iPhone (merged with the generated plist)
```

`ModeDialGeometry` and `ModeDialEngine` are plain Swift with no UI
dependencies, so the dial's mechanics can be exercised without a simulator.
