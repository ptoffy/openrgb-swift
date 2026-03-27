import struct NIOCore.ByteBuffer

/// Request body for resizing a zone on a controller.
public struct OpenRGBControllerZoneResize: OpenRGBEncodable {
    let zoneIndex: UInt32
    let newSize: UInt32

    /// Creates a resize request for the given zone.
    ///
    /// - Parameters:
    ///   - zoneIndex: The zero-based index of the zone to resize.
    ///   - newSize: The new number of LEDs in the zone.
    public init(zoneIndex: UInt32, newSize: UInt32) {
        self.zoneIndex = zoneIndex
        self.newSize = newSize
    }

    func encode(into byteBuffer: inout NIOCore.ByteBuffer) throws {
        byteBuffer.writeInteger(zoneIndex, endianness: .little)
        byteBuffer.writeInteger(newSize, endianness: .little)
    }
}
