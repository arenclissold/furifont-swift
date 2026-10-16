# Furifont Swift

**0.1.0 — in development.**

Japanese text with furigana and okurigana-aware readings in Swift apps.
Powered by [Furifont](https://furifont.antfu.me/) and a native Swift port of its
[okurigana helper](https://github.com/antfu/furifont/blob/v0.3.0/packages/helper-web/src/okurigana.ts).
No JavaScript or web view needed.

## Quick start

Add the **Furifont** product and enable the **BundledFont** trait for the Serif preset:

```swift
.package(
    url: "https://github.com/arenclissold/furifont-swift.git",
    exact: "0.1.0",
    traits: ["BundledFont"]
)

// Your target's dependencies:
.product(name: "Furifont", package: "furifont-swift")
```

```swift
import Furifont

FurifontText("来ない、来ます、来る。")
FurifontText("今日は日本語を勉強します。", size: 32, weight: .medium)
FurifontText("来ない", showsFurigana: false)
```

<img src="Documentation/quick-start.png" alt="Furifont Serif with context-sensitive readings, a medium-weight sentence, and text with furigana hidden" width="390">

The preset includes Furifont Serif VF v0.3.0 and matching tables, with automatic
registration. No downloads, font names, or Info.plist changes are needed.
Text respects Dynamic Type and uses the original characters for accessibility.
Use SwiftUI modifiers for color, alignment, selection, and line limits.

Requires **Swift 6.2+**. In [Xcode 26.4 or later](https://developer.apple.com/documentation/xcode-release-notes/xcode-26_4-release-notes),
enable the trait in **Package Dependencies**. With older Xcode versions that
include Swift 6.2+, declare the dependency in a local Swift package as above.
Apple platforms: iOS 15+, macOS 12+, tvOS 15+, watchOS 8+.
The reading APIs also run on Linux.

## Optional font resources

There is one product and one import: `Furifont`. Assets are **opt-in**.
Omit `BundledFont` or use `traits: []` when supplying your own font and tables.

| Configuration | App resources | Default view behavior |
| --- | --- | --- |
| No traits | No bundled font or tables | Uses your configuration, otherwise plain text |
| `BundledFont` | Serif VF and matching tables, about 24 MB | Uses bundled Serif automatically |

Swift Package Manager still downloads the repository in either case. No files
are fetched at runtime. Traits are additive: another dependency enabling
`BundledFont` will include its assets. Swift 6.2+ is required to exclude disabled
optional targets correctly.

## Custom fonts and appearance

Bundle a compatible Furifont build and its matching reading tables:

```swift
let custom = try FurifontConfiguration(fontResource: "MyFurifont")
FurifontText("来ない", configuration: custom)
```

This loads `MyFurifont.ttf`, `MyFurifont.ivs.json`, and `okurigana.json` from
your app bundle. You can also supply another bundle, local file URLs, or an
already registered font. Custom fonts must be Furifont builds with matching data.

Apply configuration to a whole view hierarchy, or customize the bundled preset:

```swift
var appearance = try FurifontConfiguration.bundled() // Requires BundledFont.
appearance.lineHeightMultiple = 1.9
appearance.variations["wght"] = 500

VStack {
    FurifontText("来ない、来ます、来る。")
    FurifontText("今日は日本語を勉強します。")
}
.furifont(appearance)
```

An explicit `configuration:` overrides the nearest `.furifont(...)` modifier.
Configurations also support OpenType features and Core Text fonts for UIKit,
AppKit, or custom renderers.

See the [usage guide](Documentation/Usage.md) for loading options, explicit
readings, rendering APIs, accessibility, and limitations. The helper selects
readings from tables; it is not a tokenizer and cannot invent missing readings.
`FurifontText` does not parse bracket notation.

## Development

See [CONTRIBUTING.md](CONTRIBUTING.md) for formatting, tests, and build checks.
Both trait configurations are verified with separate consumers to ensure the
optional font and tables are included only when enabled.

## Credits and licences

Code: MIT. Based on Anthony Fu's `@furifont/helper-web` v0.3.0, adapted by
[arenclissold](https://github.com/arenclissold). This is an independent port.

Optional assets have separate licences: Furifont Serif derives from Adobe Source
Han Serif under SIL OFL 1.1; reading data is CC BY-SA 4.0 with EDRDG,
JmdictFurigana, Tatoeba, and other upstream credits. Include those credits in your
app's acknowledgements when distributing the resources.

See [LICENSE](LICENSE), [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md), and
[bundled resource notices](Sources/FurifontResources/Resources/NOTICE.md).
