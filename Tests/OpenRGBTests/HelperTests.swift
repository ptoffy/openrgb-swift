import Testing
import NIOCore

@testable import OpenRGB

@Suite("Helper Tests")
struct HelperTests {
    @Test("Decode NetPacketHeader")
    func decodeNetPacketHeader() async throws {
        var buffer = try ByteBuffer(plainHexEncodedBytes: "4f524742000000000000000004000000")
        let header = try OpenRGBNetPacketHeader.decode(reading: &buffer)
        let expected = OpenRGBNetPacketHeader(id: .requestControllerCount, bodyLength: 4)
        #expect(header == expected)
    }
}
