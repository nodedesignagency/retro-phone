# Retro Phone

A phone keypad for iPhone where the keypad is a rotary dial: machined gunmetal,
a clear acrylic finger wheel, a chrome finger stop, and the "LISTEN BEFORE
CALLING" card in the middle.

## Run it

1. Open `RetroPhone.xcodeproj` in Xcode 16 or later.
2. Pick an iPhone simulator or your phone and press Run.
   For a real device, choose your team under *Signing & Capabilities* first.

Requires iOS 17. iPhone only, portrait.

## Using the dial

- **Dial:** put a finger in a hole, pull it round clockwise to the metal stop,
  and let go. The digit registers when you let go at the stop. Let go early
  and nothing is dialled, just like the real thing.
- **Tap:** tap a digit and the dial pulls itself round for you. Tap several in
  a row and they queue up and dial in order.
- **Catch:** you can grab the wheel by a hole while it's spinning home.
- **Call:** the green button places the call. With nothing dialled it brings
  back the last number you called, like the iPhone keypad.
- **Delete:** tap to remove a digit, touch and hold to clear.
- **Copy/paste:** touch and hold the number.

## How it feels

- The wheel returns at a governed ten pulses per second. Each pulse is a crisp
  haptic tick and click: one for 1, ten for 0.
- Winding gives softer detent ticks, the stop gives a firm thud, and the wheel
  settles home with a tiny spring.
- All sounds are synthesised in code (`ClickSynth`), so there are no audio
  files. They follow the silent switch.
- Animation runs at up to 120 Hz on ProMotion displays.
- Reduce Motion is respected: tapping a digit enters it instantly and the
  ambient effects stop.

## Layout

```
RetroPhone/
  App/          app entry point
  Dialer/       screen, number display, call/delete controls, model, formatter
  RotaryDial/   geometry, engine (physics + pulses), and the dial's layers
  Feedback/     Core Haptics and synthesised sounds
  Design/       palette and metal finishes, glass orb, lathe grain, curved text
Config/Info.plist  enables 120 Hz on iPhone (merged with the generated plist)
```

`DialGeometry` and `RotaryDialEngine` are plain Swift with no UI dependencies,
so the dial's mechanics can be exercised without a simulator.
