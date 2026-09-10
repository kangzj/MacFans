import Testing
@testable import SMCKit

@Suite struct SMCKeyTests {
    @Test func roundTripsFourCharacterCode() {
        let key = SMCKey("F0Ac")
        #expect(key.code == 0x4630_4163)
        #expect(key.string == "F0Ac")
        #expect(key.hasPrefix("F0"))
    }

    @Test func sortsByString() {
        #expect([SMCKey("Tp04"), SMCKey("Tp00")].sorted() == [SMCKey("Tp00"), SMCKey("Tp04")])
    }
}
