import Testing
@testable import SMCKit

@Suite struct SMCDataTypeTests {
    @Test func decodesFloat() {
        let bytes = withUnsafeBytes(of: Float(1350).bitPattern.littleEndian) { Array($0) }
        #expect(SMCDataType.flt.decode(bytes) == 1350)
    }

    @Test func decodesSP78() { #expect(SMCDataType.sp78.decode([0x2A, 0x80]) == 42.5) }

    @Test func decodesFPE2() { #expect(SMCDataType.fpe2.decode([0x14, 0x00]) == 1280) }

    @Test func decodesUnsignedIntegers() {
        #expect(SMCDataType.ui8.decode([2]) == 2)
        #expect(SMCDataType.ui16.decode([0x96, 0x00]) == 38400)
        #expect(SMCDataType.ui32.decode([0, 0, 0x0E, 0x55]) == 3669)
    }

    @Test func unknownTypeDecodesToNil() { #expect(SMCDataType(tag: "hex_").decode([1, 2]) == nil) }

    @Test func encodesFloatAndUI8() {
        #expect(SMCDataType.flt.encode(1350) == withUnsafeBytes(of: Float(1350).bitPattern.littleEndian) { Array($0) })
        #expect(SMCDataType.ui8.encode(1) == [1])
        #expect(SMCDataType.sp78.encode(1) == nil)
    }

    @Test func tagRoundTrip() { #expect(SMCDataType(tag: "flt ").tag == "flt ") }
}
