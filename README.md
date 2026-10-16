# Furifont Swift

Use [Furifont](https://furifont.antfu.me/) with okurigana-aware readings in native
Swift apps. A Foundation-only Swift port of Furifont's
[`createOkuriganaReader`](https://github.com/antfu/furifont/blob/v0.3.0/packages/helper-web/src/okurigana.ts).
No JavaScript runtime, web view, UI framework, or third-party dependencies.

Furifont supplies furigana inside its glyphs. This package uses the following kana
to pick the reading of a kanji run: 来 in 来ない is こ, while 来 in 来ます is き.
It inserts the font's invisible variation selectors, which native text views can render.

Requires Swift 6.0 or later. Supports iOS 15+, macOS 12+, tvOS 15+, and watchOS 8+.
The core also uses only Foundation APIs available in Swift on Linux.

## Install

Add `https://github.com/arenclissold/furifont-swift` in Xcode's package dependencies,
or add this dependency and the `Furifont` product to your Package.swift:

```swift
.package(url: "https://github.com/arenclissold/furifont-swift.git", from: "0.1.0")
// In your target's dependencies:
.product(name: "Furifont", package: "furifont-swift")
```

## Supply the font and matching tables

The package deliberately ships no fonts or dictionary data. Choose a Furifont
release or custom build and bundle these resources in your app:

1. A native font file (`.ttf` or `.otf`).
2. Its matching `.ivs.json` file.
3. The packed `okurigana.json` from the same Furifont version.

For example, [Furifont v0.3.0](https://github.com/antfu/furifont/releases/tag/v0.3.0)
provides `FurifontSerifVF.ttf` and `FurifontSerifVF.ivs.json`. The matching packed
table is [okurigana.json](https://github.com/antfu/furifont/blob/v0.3.0/packages/dictionary/data/okurigana.json).
Preserve those resources' licences and upstream credits when distributing them.
The Swift code is MIT; separately obtained fonts and reading data have their own
licences. See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

On iOS, add the font filename to `UIAppFonts` (Fonts provided by application) in
your Info.plist. Other platforms can register app-bundled fonts with Core Text.
Use the font's actual PostScript name, which can differ from the filename.
For the v0.3.0 Serif variable font it is `FurifontSerifVF-ExtraLight`.

## Load once and transform display text

```swift
import Foundation
import Furifont

let readingsURL = Bundle.main.url(forResource: "FurifontSerifVF.ivs", withExtension: "json")!
let okuriganaURL = Bundle.main.url(forResource: "okurigana", withExtension: "json")!
let readings = try FurifontReadings(readingsURL: readingsURL, okuriganaURL: okuriganaURL)

let source = "来ない、来ます、来る。"
let display = readings.annotateOkurigana(source)
```

Initialize once and reuse the immutable, `Sendable` value. Files are loaded
synchronously; initialize away from the UI thread when appropriate. If your app
loads resources another way, use `init(readingsData:okuriganaData:)` or
`init(lists:pairs:)`. The package never downloads resources or registers fonts.
Malformed JSON, unsupported font tables (`salt: false`), and file errors throw.

### SwiftUI

```swift
import SwiftUI

Text(readings.annotateOkurigana(source))
    .font(.custom("FurifontSerifVF-ExtraLight", size: 28))
    .lineSpacing(12)
    .accessibilityLabel(source)
```

Give lines enough vertical space for the ruby and avoid clipping the top of the
text. Choose a desired variable-font weight through your UI framework or Core Text.
The sample font's PostScript name denotes its default ExtraLight instance.

### UIKit or AppKit

```swift
// UIKit, after registering the font:
label.font = UIFont(name: "FurifontSerifVF-ExtraLight", size: 28)
label.text = readings.annotateOkurigana(source)
label.accessibilityLabel = source

// AppKit:
textField.font = NSFont(name: "FurifontSerifVF-ExtraLight", size: 28)
textField.stringValue = readings.annotateOkurigana(source)
```

Import UIKit or AppKit for the respective sample. Core Text consumers can pass the
transformed string into their normal attributed-text layout with the registered font.

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
defaults. `salt(for:reading:)` follows upstream correction semantics: it returns zero
when a reading is unavailable or already the default. `matches(in:)` reports only
actual corrections, in source order.

## Behavior and limits

- Only complete Han runs immediately followed by hiragana are considered.
- The longest matching okurigana prefix wins. An ambiguous longest prefix prevents
  a shorter, apparently certain prefix from selecting a reading.
- Unknown pairs, unsupported readings, and default readings are unchanged.
- Reading order comes from the font's tables. At most 15 readings are supported.
- Existing variation selectors are preserved; processing the output again is safe.
- This is a table-based helper, not a tokenizer or a general Japanese reading engine.
  It cannot infer arbitrary readings or create glyphs missing from the font.

Keep `source` for storage, search, copying, and accessibility. The transformed
string contains real, invisible Unicode characters. Render it only with the
matching Furifont; ordinary fonts do not provide its furigana behavior.

## Development

```sh
swift test --parallel
swift build -c release
```

Tests use synthetic tables and cover ambiguity, defaults, words, UTF-16 ranges,
supplementary Han, repeated processing, explicit selectors, and resource loading.

## Credits and licence

Based on Anthony Fu's MIT-licensed `@furifont/helper-web` from Furifont v0.3.0.
Swift adaptation by [arenclissold](https://github.com/arenclissold). This is an
independent Swift port. See [LICENSE](LICENSE) and [upstream notices](THIRD_PARTY_NOTICES.md).
