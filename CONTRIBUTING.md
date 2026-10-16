# Development

The initial release is **0.1.0**. The package requires Swift 6.2 or later.
It has one public product, `Furifont`, and an optional `BundledFont` trait.

## Layout

- `Sources/Furifont`: reading selection, font configuration, and SwiftUI rendering.
- `Sources/FurifontResources`: optional upstream assets and their licences.
- `Tests/FurifontTests`: reading, configuration, resource, and rendering checks.
- `Scripts/check-consumer.swift`: separate consumer builds that verify resource inclusion.

Keep package code and examples independent of any consuming app. Preserve the
upstream notices and licences; the font and tables are unmodified third-party assets.

## Format

```sh
swift format format --in-place --recursive Package.swift Sources Tests Scripts
swift format lint --strict --recursive Package.swift Sources Tests Scripts
```

The repository's `.swift-format` defines the style.

## Validate both configurations

```sh
swift test --parallel
swift build -c release
swift Scripts/check-consumer.swift

swift test --parallel --traits BundledFont
swift build -c release --traits BundledFont
swift Scripts/check-consumer.swift --bundled-font
```

The consumer script uses only Swift and Foundation. It creates a temporary
package, builds the public product, checks its reading API, and verifies that the
font and both tables are absent or present in the output. Tests use synthetic
reading fixtures unless checking the bundled preset.

On macOS, the same tests also cover Core Text registration, font weights, and
ruby visibility. iOS simulator tests exercise actual SwiftUI rendering. To run
the package tests in Xcode, open `Package.swift` and select the `Furifont` scheme
and an available iOS simulator. The default configuration tests plain-text
fallback; enable `BundledFont` when testing the preset.

GitHub Actions checks both configurations on macOS and Linux, formatting on
macOS, and package tests on an available iOS simulator.
