# Upstream attribution

The okurigana matching algorithm is a Swift adaptation of Anthony Fu's
`@furifont/helper-web` (`createOkuriganaReader`) from Furifont v0.3.0:

https://github.com/antfu/furifont/blob/v0.3.0/packages/helper-web/src/okurigana.ts

The port retains longest-prefix matching, ambiguity handling, font reading order,
default-reading suppression, and the 15-reading limit. It adds immutable Swift
value types, local JSON loading, UTF-16 match ranges, and variation-selector output
for native text rendering instead of web spans.

## Upstream MIT licence

MIT License

Copyright (c) 2025-PRESENT Anthony Fu <https://github.com/antfu>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

## Fonts and reading data

The `Furifont` core product includes no font files or upstream dictionary data.
Its tests use small synthetic fixtures written for this package.

The optional `FurifontSwiftUI` product bundles unmodified Furifont Serif VF v0.3.0
and matching reading tables. These resources are not MIT licensed:

- `FurifontSerifVF.ttf`: SIL OFL 1.1, derived from Adobe Source Han Serif.
- `FurifontSerifVF.ivs.json` and `okurigana.json`: CC BY-SA 4.0, with upstream source credits.

Full licences and source credits are included in
`Sources/FurifontSwiftUI/Resources/OFL.txt`, `DATA-LICENSE.md`, and `CC-BY-SA-4.0.txt`.
See `Resources/NOTICE.md` for exact upstream locations. Applications distributing
the optional resources should include the upstream credits in their acknowledgements.
This package's MIT licence applies to its code, not those font or data resources.

The resources are unchanged from https://github.com/antfu/furifont/tree/v0.3.0.
SHA-256:

- Font: `c34ee815684e643b7c9a3cf9b96f227a3f6c8ff9242b9bb1bd6e825f5c96bb64`
- Reading lists: `1a1fee335de5534ba09480ae2f2a2e0c8f321ec2d89d94f4fe030cb583211876`
- Okurigana pairs: `8ab945b0c3ecb585e7f37bf08d1692b4b103571f9c0abd808f3d9d58703b5057`
