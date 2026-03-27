import struct NIOCore.ByteBuffer

/// Request body for updating all LED colors within a specific zone.
public struct OpenRGBControllerUpdateZoneLEDs: OpenRGBEncodable {
    let zoneIndex: UInt32
    let ledColors: [RGBColor]

    /// Creates a request targeting the given zone.
    ///
    /// - Parameters:
    ///   - zoneIndex: The zero-based index of the zone to update.
    ///   - ledColors: Colors for each LED in the zone, in order.
    public init(zoneIndex: UInt32, ledColors: [RGBColor]) {
        self.zoneIndex = zoneIndex
        self.ledColors = ledColors
    }

    func encode(into byteBuffer: inout ByteBuffer) {
        byteBuffer.writeInteger(UInt32(4 + 2 + 4 + 4 * ledColors.count), endianness: .little)
        byteBuffer.writeInteger(zoneIndex, endianness: .little)
        byteBuffer.writeInteger(UInt16(ledColors.count), endianness: .little)

        for color in ledColors {
            color.encode(into: &byteBuffer)
        }
    }
}
