# Furifont Swift

Japanese text with furigana and okurigana-aware readings in Swift apps.
Powered by [Furifont](https://furifont.antfu.me/) and a native Swift port of its
[okurigana helper](https://github.com/antfu/furifont/blob/v0.3.0/packages/helper-web/src/okurigana.ts).
No JavaScript or web view needed.

## Quick start: SwiftUI

Add `https://github.com/arenclissold/furifont-swift` in Xcode's package dependencies
and select the **FurifontSwiftUI** product. Then:

```swift
import FurifontSwiftUI

FurifontText("来ない、来ます、来る。")
```

<img src="Documentation/quick-start.png" alt="Furifont Serif with context-sensitive readings, a medium-weight sentence, and text with furigana hidden" width="390">

That's it. The optional product includes Furifont Serif VF v0.3.0, its matching
reading tables, and automatic font registration. You don't need to download
files, look up font names, or change Info.plist.

```swift
FurifontText("今日は日本語を勉強します。", size: 32, weight: .medium)
    .foregroundStyle(.primary)
    .multilineTextAlignment(.center)

FurifontText("来ない", showsFurigana: false)
```

The view scales with Dynamic Type, handles ruby line spacing, and uses the
original text for accessibility. Hiding furigana keeps the same font and weight.
Use normal SwiftUI modifiers for color, alignment, selection, and line limits;
use `size` and `weight` to configure the font.

Resources are loaded once and reused. Optionally prepare them during startup or
in a background task to avoid first-use work:

```swift
try FurifontText.prepare()
```

Preparation is safe to repeat. If automatic preparation fails, the view falls
back to plain source text; `prepare()` lets you handle that error explicitly.
The bundled preset is Serif with hiragana readings. For another font or custom
build, use the core library below.

## Choose the product

| Product | Use it for | Bundled resources |
| --- | --- | --- |
| `FurifontSwiftUI` | A ready-to-use SwiftUI view | Serif VF and matching tables, about 24 MB before app packaging |
| `Furifont` | Your own fonts, data, or text renderer | None; Foundation-only |

Only linking `FurifontSwiftUI` adds its resource bundle to an app. Swift Package
Manager still downloads the repository when resolving either product.
Both products need Swift 6.0+. Supported Apple platforms: iOS 15+, macOS 12+,
tvOS 15+, watchOS 8+. The core library also runs on Linux.

### Package.swift

```swift
.package(url: "https://github.com/arenclissold/furifont-swift.git", from: "0.2.0")

// In your target's dependencies, choose one:
.product(name: "FurifontSwiftUI", package: "furifont-swift")
// or:
.product(name: "Furifont", package: "furifont-swift")
```

## Core library: bring your own font

The existing `Furifont` product stays independent of SwiftUI and font resources.
Choose a Furifont release or custom build and bundle:

1. A native font file (`.ttf` or `.otf`).
2. Its matching `.ivs.json` file.
3. The packed `okurigana.json` from the same Furifont version.

For example, [Furifont v0.3.0](https://github.com/antfu/furifont/releases/tag/v0.3.0)
provides `FurifontSerifVF.ttf` and `FurifontSerifVF.ivs.json`. The matching packed
table is [okurigana.json](https://github.com/antfu/furifont/blob/v0.3.0/packages/dictionary/data/okurigana.json).

Load the reading tables with one initializer:

```swift
import Furifont

let readings = try FurifontReadings(fontResource: "FurifontSerifVF")
let display = readings.annotateOkurigana("来ない、来ます、来る。")
```

This loads `FurifontSerifVF.ivs.json` and `okurigana.json` from `Bundle.main`.
You can supply `bundle:` and `okuriganaResource:` for other bundles or filenames.
Use the file's stem, not the font's PostScript name. Missing resources throw
`LoadingError.resourceNotFound` with the missing filename.

Alternatively, load via `init(readingsURL:okuriganaURL:)`,
`init(readingsData:okuriganaData:)`, or `init(lists:pairs:)`.
Initialize once and reuse the immutable, `Sendable` value. Loading is synchronous;
initialize away from the UI thread when appropriate. The core never downloads
files or registers fonts. Malformed JSON, unsupported tables, and file errors throw.

### Render with your registered font

On iOS, register your font with Core Text or list its filename in `UIAppFonts`.
Use its actual PostScript name, which may differ from the filename. With the core
library, font registration and text layout remain the application's responsibility.

```swift
// SwiftUI, after registering the font:
Text(readings.annotateOkurigana(source))
    .font(.custom("FurifontSerifVF-ExtraLight", size: 28))
    .lineSpacing(12)
    .accessibilityLabel(source)

// UIKit:
label.font = UIFont(name: "FurifontSerifVF-ExtraLight", size: 28)
label.text = readings.annotateOkurigana(source)
label.accessibilityLabel = source

// AppKit:
textField.font = NSFont(name: "FurifontSerifVF-ExtraLight", size: 28)
textField.stringValue = readings.annotateOkurigana(source)
```

Import SwiftUI, UIKit, or AppKit for the respective sample, and set `source` to
your Japanese text. Core Text consumers can use the transformed string in their
usual attributed-text layout. Give lines enough room for ruby. The sample font's
PostScript name denotes its default ExtraLight instance; choose the desired
variable-font weight in your renderer. The optional SwiftUI view defaults to Regular.

## Inspect matches or select a reading explicitly

```swift
for match in readings.matches(in: source) {
    // NSRange in the ORIGINAL string's UTF-16 coordinates, not Character offsets.
    let range = Range(match.range, in: source)!
    print(source[range], match.reading, match.salt)
}

let alternate = readings.annotated("今日", reading: "こんにち") // Optional<String>
let hidden = readings.annotated("今日", reading: "")          // VS225: no ruby
let unknown = readings.annotated("今日", reading: "とくべつ") // nil
```

`selector(for:reading:)` returns a Unicode scalar for explicit readings, including
defaults. `salt(for:reading:)` follows upstream correction semantics: zero means
unavailable or already the default. `matches(in:)` reports corrections in source order.

## Behavior and limits

- Only complete Han runs immediately followed by hiragana are considered.
- The longest matching okurigana prefix wins. An ambiguous longest prefix prevents
  a shorter prefix from selecting a reading.
- Unknown pairs, unsupported readings, and default readings are unchanged.
- Reading order comes from the font's tables. At most 15 readings are supported.
- Existing variation selectors are preserved; processing the output again is safe.
- This is a table-based helper, not a tokenizer or a general Japanese reading engine.
  It cannot infer arbitrary readings or create glyphs missing from the font.
- The SwiftUI view accepts normal Japanese text and font variation selectors.
  It does not parse bracket notation or draw arbitrary custom readings.

For the core API, keep the source string for storage, search, copying, and
accessibility. Transformed strings contain real, invisible Unicode characters.
Render them with the matching Furifont. The SwiftUI view manages its display copy;
text selection can still copy invisible selectors along with the rendered text.

## Development

```sh
swift test --parallel
swift build -c release
```

Tests cover ambiguity, defaults, words, UTF-16 ranges, supplementary Han,
resource loading, bundled font registration, variable weights, and ruby hiding.
Core checks run on macOS and Linux; SwiftUI checks run on Apple platforms.

## Credits and licences

Code: MIT. Based on Anthony Fu's `@furifont/helper-web` v0.3.0, with a Swift
adaptation by [arenclissold](https://github.com/arenclissold). This is an independent port.

The optional resources have separate licences: Furifont Serif is derived from
Adobe Source Han Serif under SIL OFL 1.1; reading data is CC BY-SA 4.0 with EDRDG,
JmdictFurigana, Tatoeba, and other upstream credits. Include those credits in your
application's acknowledgements. Full notices and licences ship in the resource bundle.

See [LICENSE](LICENSE), [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md), and
[bundled resource notices](Sources/FurifontSwiftUI/Resources/NOTICE.md).
