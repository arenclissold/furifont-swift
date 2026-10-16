# Rendering and reading APIs

Import `Furifont` for all APIs. The package supports iOS 15+, macOS 12+,
tvOS 15+, and watchOS 8+. Reading selection also works on Linux.

## SwiftUI behavior

`FurifontText` scales with Dynamic Type and preserves font metrics when hiding
furigana. Use `size` and `weight` to configure its font, and ordinary SwiftUI
modifiers for color, alignment, selection, and line limits.

Configuration priority is the view's explicit `configuration:`, then the nearest
`.furifont(...)` modifier, then bundled Serif when `BundledFont` is enabled.
Without a configuration or bundled font, the view displays plain source text.
Custom configurations always use their own reading tables.

You can preload bundled resources before the first view appears:

```swift
try FurifontText.prepare()
```

Preparation is cached and safe to repeat or run from a background task.
`FurifontConfiguration.bundled()` also prepares the font and returns a configurable
copy. Both methods throw `LoadingError.bundledFontNotEnabled` when the trait is off.
Otherwise, loading and registration errors throw; the automatic view setup falls
back to plain source text if preparation fails.

## Explicit reading notation

```swift
FurifontText(annotated: "今日[こんにち]は、食[た]べる。来ない。")
```

A kanji run immediately followed by `[reading]` selects that reading from the
configured font's matching tables. A whole word such as `今日[こんにち]` uses its
word entry; `今[こん]日[にち]` selects individual kanji readings. Explicit choices
win over okurigana inference. Unannotated text still gets automatic corrections.

- `今日[]` hides ruby on every kanji in that annotation.
- A reading absent from the tables also hides the entire annotated run's ruby.
  This includes words absent from the word table, even if the font knows a default
  reading for them. Annotate individual kanji when those readings are available.
- Readings cannot contain brackets or line breaks. Malformed and nested annotations
  remain literal, as do other brackets such as `English [note]` and `かな[かな]`.
- `showsFurigana: false`, accessibility labels, and the fallback when no font is
  configured use the base text, without recognized brackets or reading text.
- The ordinary `FurifontText("...")` initializer always keeps brackets literal.

The same processing is available outside SwiftUI:

```swift
let display = readings.annotateReadings("今日[こんにち]、来ない。")
```

The result uses the matching font's variation selectors and, where adjacent kanji
require it, invisible shaping boundaries that preserve an explicit reading. Keep source notation for
editing and storage; it is not suitable as an accessibility label. The SwiftUI
view manages its clean accessibility label automatically. Unsupported readings are
not synthesized or drawn as custom ruby.

## Custom fonts and resources

Bundle a compatible Furifont build: the native `.ttf` or `.otf`, its matching
`.ivs.json`, and packed `okurigana.json` from the same version or build.

```swift
let custom = try FurifontConfiguration(fontResource: "MyFurifont")
FurifontText("来ない", configuration: custom)
```

The initializer loads `MyFurifont.ttf`, `MyFurifont.ivs.json`, and `okurigana.json`
from `Bundle.main`, registers the font, and discovers its PostScript name.
Supply `bundle:`, `fontExtension: "otf"`, or `okuriganaResource:` for other resources.
For resources in your own Swift package, pass your own `Bundle.module`.
Construct configurations once and reuse them. File loading is synchronous;
prepare away from the UI thread when appropriate.

For local font URLs and separately loaded tables:

```swift
let readings = try FurifontReadings(readingsURL: readingsURL, okuriganaURL: okuriganaURL)
let custom = try FurifontConfiguration(fontURL: fontURL, readings: readings)
```

For an already registered font, use `init(fontName:readings:)` with its actual
PostScript name. The package cannot add furigana glyphs to an ordinary Japanese font.

## Rendering preferences

`variations` accepts four-character OpenType axis tags such as `wght` or `wdth`.
Explicit axis values override the view's `weight`. `features` accepts four-character
OpenType feature tags supported by the font; `ss01` is reserved for `showsFurigana`.
Invalid tags are ignored. `lineHeightMultiple` specifies a minimum line height;
font ascent and descent are preserved so ruby is not clipped.

## UIKit, AppKit, and custom renderers

With `BundledFont` enabled, use the same configuration outside SwiftUI,
or substitute your own custom configuration:

```swift
let configuration = try FurifontConfiguration.bundled()
let source = "来ない、来ます、来る。"
let display = configuration.readings.annotateOkurigana(source)
let font = configuration.makeFont(size: 28, weight: 400)

// UIKit (import UIKit):
label.font = font as UIFont
label.text = display
label.accessibilityLabel = source

// AppKit (import AppKit):
textField.font = font as NSFont
textField.stringValue = display
textField.setAccessibilityLabel(source)
```

`makeFont` returns a Core Text font with your variations, features, and ruby
visibility settings. Weight uses the OpenType 100–900 scale. UIKit/AppKit callers
manage line layout, Dynamic Type, and accessibility. Keep the original string for
storage and search, and allow enough line height for ruby.

You can also use `FurifontReadings` alone. It does no registration or rendering:

```swift
let readings = try FurifontReadings(fontResource: "MyFurifont")
let display = readings.annotateOkurigana("来ない、来ます、来る。")
```

Its bundle initializer accepts `bundle:` and `okuriganaResource:`. Alternatives
include `init(readingsURL:okuriganaURL:)`, `init(readingsData:okuriganaData:)`, and
`init(lists:pairs:)`. Reading values are immutable and `Sendable`.

## Inspect matches or select a reading explicitly

```swift
for match in readings.matches(in: source) {
    // NSRange in the ORIGINAL string's UTF-16 coordinates, not Character offsets.
    let range = Range(match.range, in: source)!
    print(source[range], match.reading, match.salt)
}

let alternate = readings.annotated("今日", reading: "こんにち") // Optional<String>
let hidden = readings.annotated("来", reading: "")           // VS225: no ruby
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
- The ordinary SwiftUI initializer accepts Japanese text and font variation selectors.
  The `annotated:` initializer additionally parses bracket readings; neither draws
  arbitrary custom readings.

For the core API, keep the source string for storage, search, copying, and
accessibility. Transformed strings contain real, invisible Unicode characters.
Render them with the matching Furifont. The SwiftUI view manages its display copy;
text selection can still copy invisible selectors along with the rendered text.
