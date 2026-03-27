import struct NIOCore.ByteBuffer

protocol OpenRGBDecodable: Sendable {
    init(from body: inout ByteBuffer, protocolVersion: UInt32) throws
}

enum OpenRGBDecodingError: Swift.Error, Sendable {
    case couldNotDecodeInteger(as: any (FixedWidthInteger & Sendable).Type)
    case couldNotDecodeString
    case missingBody
    case nonUTF8Name
}
