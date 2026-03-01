# Hex Calculator

this is the hex calculator I wanted and couldn't find.

Most calculators act weird when you care about exact bit width, overflow behavior, and low-level sanity checks. This one is built for that.

Hex Calculator is a macOS app for devs doing systems, embedded, reverse engineering, low-level debugging, or just anything where `0x` life is real.

## What It Does

- Fixed bit widths: `8`, `16`, `32`, `64`
- Hex-first input and formatted output
- Decimal output alongside hex
- Arithmetic + bitwise ops: `+`, `-`, `AND`, `OR`, `XOR`, `<<`, `>>`, `NOT`, `NEG`
- One's and Two's complement checksum helpers (`CHK~`, `CHK-`)
- Wrap-on-overflow toggle
- History sidebar with quick recall
- Keyboard-friendly workflow
- Paste hex from clipboard
- Copy result as hex or decimal
- Optional Float-on-Top mode

## Why This Exists

Because regular calculators default to giant integer behavior and then you end up mentally simulating registers at 2am.

No thanks.

This app keeps math constrained to the width you actually care about.

## Build From Source

Requirements:
- Xcode (recent version)
- macOS 13.5+

Steps:
1. Clone this repo.
2. Open `HexCalculator.xcodeproj`.
3. Select the `HexCalculator` scheme.
4. Build and run.

## Privacy

This app does not track you, sell your data, or phone home.

Read the full policy here: [Privacy.md](Privacy.md)

## Contributing

PRs are welcome.

If you have ideas, bug reports, or feature requests, open an issue and keep it direct.

Good first contributions:
- More bitwise tools
- Better keyboard shortcuts
- UX polish for power users
- Tests for edge-case math behavior

## License

No license file has been added yet.

If you want reuse permissions, open an issue and I'll add one.
