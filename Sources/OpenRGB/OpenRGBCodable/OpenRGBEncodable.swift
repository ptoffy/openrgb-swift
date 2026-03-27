import struct NIOCore.ByteBuffer

protocol OpenRGBEncodable: Sendable {
    func encode(into byteBuffer: inout ByteBuffer) throws
}

enum OpenRGBEncodingError: Swift.Error, Sendable {}
