# OverlayPad

[English](README.md) | [简体中文](README.zh-CN.md)

> Turn any touchscreen into a real gamepad.

A floating virtual controller that feeds native GameController input into your game — not fake taps, not screen taps. UNDERTALE / DELTARUNE (mobile ports), and anything else that speaks Gamepad API, just works.

---

## Why you'll like it

- **Real gamepad input** — speaks `GCController`, so engines see a hardware pad. Zero per-game patches.
- **Fully yours** — drag, resize, recolor, reshape, remap every button and the stick.
- **Combos & turbo** — one button can fire A+B, or auto-tap at any interval you like.
- **Presets** — save, load, export, import. Share a `.json`, get the same layout.
- **Non-intrusive** — long-press the ball to hide everything. No HUD clutter.
- **Bilingual UI** — auto-follows system language, or pin to EN / 中文.

## Quick start

1. Inject `OverlayPad.dylib` into the target app.
2. Launch. A floating ball appears.
3. Tap it → settings. Drag buttons. Play.

Works with both **TrollStore IPA re-sign** and **LiveContainer-style sideloading**.

## Build

```sh
make DEBUG=1        # debug build with on-screen console
make sign           # sign with ldid
```

## Requirements

- iOS **15+**
- Target app must read GameController input (most modern mobile ports do)
- visionOS may need extra entitlements

## Credits

Built by [@locationovo](https://github.com/locationovo).
Icons, presets, and dylib injection tips — all welcome.

## License

[LGPL-3.0](LICENSE). Fork it, remix it, ship it.