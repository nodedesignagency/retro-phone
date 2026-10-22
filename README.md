# Retro Phone

An iPhone keypad where the keypad is a real-looking chrome GPO rotary dial,
set in an Apple-style dialer: black, a soft studio light from above, the
number in SF Pro and the green call button.

## Run it

1. Open `RetroPhone.xcodeproj` in Xcode 16 or later.
2. Pick an iPhone simulator or your phone and press Run.
   For a real device, choose your team under *Signing & Capabilities* first.

Requires iOS 17. iPhone only, portrait.

## Using the dial

- **Dial:** put a finger in a hole, pull it round clockwise to the finger
  stop, and let go. The digit registers when you let go at the stop. Let go
  early and nothing is dialled, just like the real thing.
- **Tap:** tap a digit and the dial pulls itself round for you. Tap several in
  a row and they queue up and dial in order.
- **Catch:** you can grab the wheel by a hole while it's spinning home.
- **Call:** the green button places the call. With nothing dialled it brings
  back the last number you called, like the iPhone keypad.
- **Delete:** tap to remove a digit, touch and hold to clear.
- **Copy/paste:** touch and hold the number.

## How the dial is made

The dial is photographic artwork cut into four aligned layers in the asset
catalog:

| Layer        | Moves? | What it is                                          |
|--------------|--------|-----------------------------------------------------|
| `DialPlate`  | no     | The grey number plate the digits are printed on     |
| `DialWheel`  | turns  | The chrome finger wheel with its ten holes          |
| `DialStop`   | no     | The finger stop, with its shadow                    |
| `DialCenter` | no     | The blank chrome centre cap                         |

Only the wheel rotates, so the digits stay put and slide under the chrome the
way they do on a real dial. A soft shade is drawn inside each hole and travels
with it, so the lighting stays consistent as the wheel turns.

`DialGeometry.chromeGPO` holds each hole's position and how far it travels
to the stop. These were measured from the artwork, so touch targets, the stop
and the pulse count all line up with what's on screen.

## How it feels

- The wheel returns at a steady governed pace. Each pulse is a crisp haptic
  tick and click: one for 1, ten for 0.
- Winding gives softer detent ticks, the stop gives a firm thud, and the wheel
  settles home with a tiny spring.
- All sounds are synthesised in code (`ClickSynth`), so there are no audio
  files. They follow the silent switch.
- Animation runs at up to 120 Hz on ProMotion displays.
- Reduce Motion is respected: tapping a digit enters it instantly.

## Layout

```
RetroPhone/
  App/          app entry point
  Dialer/       screen, number display, call/delete controls, model, formatter
  RotaryDial/   geometry, engine (physics + pulses), and the dial view
  Feedback/     Core Haptics and synthesised sounds
  Design/       palette, button press style, shake effect
Config/Info.plist  enables 120 Hz on iPhone (merged with the generated plist)
```

`DialGeometry` and `RotaryDialEngine` are plain Swift with no UI dependencies,
so the dial's mechanics can be exercised without a simulator.
