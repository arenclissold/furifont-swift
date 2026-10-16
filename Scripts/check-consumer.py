#!/usr/bin/env python3
"""Check the public product and actual resource inclusion from a separate consumer."""
import argparse
import json
import pathlib
import subprocess
import tempfile

parser = argparse.ArgumentParser()
parser.add_argument('--traits', choices=['BundledFont'])
args = parser.parse_args()
bundled = args.traits == 'BundledFont'
repository = pathlib.Path(__file__).resolve().parents[1]
traits = '["BundledFont"]' if bundled else '[]'
with tempfile.TemporaryDirectory(prefix='furifont-consumer-') as directory:
    root = pathlib.Path(directory)
    (root / 'Sources' / 'Consumer').mkdir(parents=True)
    (root / 'Package.swift').write_text('''// swift-tools-version: 6.2
import PackageDescription
let package = Package(name: "Consumer", platforms: [.macOS(.v12)], dependencies: [
    .package(path: %s, traits: %s)
], targets: [.executableTarget(name: "Consumer", dependencies: [
    .product(name: "Furifont", package: %s)
])])
''' % (json.dumps(str(repository)), traits, json.dumps(repository.name)))
    check = '''
let configuration = try FurifontConfiguration.bundled()
precondition(configuration.readings.annotateOkurigana("来ない") == "来\\u{E01E5}ない")
''' if bundled else '''
do {
    _ = try FurifontConfiguration.bundled()
    fatalError("Bundled font unexpectedly available")
} catch FurifontConfiguration.LoadingError.bundledFontNotEnabled {
    print("No bundled font, as expected")
}
'''
    (root / 'Sources' / 'Consumer' / 'main.swift').write_text('''import Furifont
let readings = try FurifontReadings(
    lists: .init(kanji: ["来": ["らい", "こ"]], words: [:], lone: ["来": "らい"]),
    pairs: ["来": ["こ": ["ない"]]])
precondition(readings.annotateOkurigana("来ない") == "来\\u{E01E2}ない")
#if canImport(CoreText)
''' + check + '\n#endif\n')
    subprocess.run(['swift', 'run', '--package-path', str(root), '-c', 'release'], check=True)
    fonts = list((root / '.build').rglob('FurifontSerifVF.ttf'))
    if bool(fonts) != bundled:
        raise SystemExit('Unexpected font resources in consumer output: ' + str(fonts))
    resources = list((root / '.build').rglob('okurigana.json'))
    if bool(resources) != bundled:
        raise SystemExit('Unexpected reading resources in consumer output: ' + str(resources))
    print('Consumer verified: bundled resources ' + ('included' if bundled else 'omitted'))
