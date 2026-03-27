import struct NIOCore.ByteBuffer

/// A 24-bit RGB color value.
public struct RGBColor: OpenRGBCodable, Codable {
    let r: UInt8
    let g: UInt8
    let b: UInt8

    init(from body: inout OpenRGBPacket.Body, protocolVersion: UInt32) throws {
        self.r = try body.requireInteger(endianness: .little)
        self.g = try body.requireInteger(endianness: .little)
        self.b = try body.requireInteger(endianness: .little)
        let _: UInt8 = try body.requireInteger()  // padding byte
    }

    func encode(into byteBuffer: inout ByteBuffer) {
        byteBuffer.writeInteger(r, endianness: .little)
        byteBuffer.writeInteger(g, endianness: .little)
        byteBuffer.writeInteger(b, endianness: .little)
        byteBuffer.writeInteger(UInt8(0x00))  // padding byte
    }
}
