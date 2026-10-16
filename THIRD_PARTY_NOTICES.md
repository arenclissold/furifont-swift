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

This package includes no font files or upstream dictionary data. Test tables are
small synthetic fixtures written for this package. Font files and matching reading
data supplied by an application retain their own licences:

- Furifont fonts: SIL Open Font License 1.1.
- Furifont compiled dictionary/reading data: CC BY-SA 4.0, with upstream source credits.

See https://github.com/antfu/furifont/tree/v0.3.0 and the notices distributed with
the font release or custom build you use. This package's MIT licence applies to
its code and does not replace the licences of separately obtained resources.
