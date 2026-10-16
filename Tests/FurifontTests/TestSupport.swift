import Furifont

func testReadings() throws -> FurifontReadings {
    try FurifontReadings(
        lists: .init(kanji: ["来": ["らい", "こ"]], words: [:], lone: ["来": "らい"]),
        pairs: ["来": ["こ": ["ない"]]]
    )
}
