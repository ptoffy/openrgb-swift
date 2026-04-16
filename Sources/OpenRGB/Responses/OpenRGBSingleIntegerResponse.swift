import struct NIOCore.ByteBuffer

// https://github.com/CalcProgrammer1/OpenRGB/blob/master/Documentation/OpenRGBSDK.md#response-size-4
// https://github.com/CalcProgrammer1/OpenRGB/blob/master/Documentation/OpenRGBSDK.md#response-size-4-1
typealias OpenRGBSingleIntegerResponse = UInt32

extension OpenRGBSingleIntegerResponse: OpenRGBResponse {
    init(from body: inout OpenRGBPacket.Body, protocolVersion: UInt32) throws {
        self = try body.requireInteger(endianness: .little, as: UInt32.self)
    }
}
