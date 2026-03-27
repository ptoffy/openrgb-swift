import struct NIOCore.ByteBuffer

public struct OpenRGBControllerZoneResize: OpenRGBEncodable {
    let zoneIndex: UInt32
    let newSize: UInt32

    public init(zoneIndex: UInt32, newSize: UInt32) {
        self.zoneIndex = zoneIndex
        self.newSize = newSize
    }

    func encode(into byteBuffer: inout NIOCore.ByteBuffer) throws {
        byteBuffer.writeInteger(zoneIndex, endianness: .little)
        byteBuffer.writeInteger(newSize, endianness: .little)
    }
}
