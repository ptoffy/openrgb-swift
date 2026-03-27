import struct NIOCore.ByteBuffer

/// Request body for updating all LED colors on a controller.
public struct OpenRGBControllerUpdateLEDs: OpenRGBEncodable {
    let ledColors: [RGBColor]

    /// Creates a request with the given LED colors.
    ///
    /// - Parameter ledColors: Colors for each LED, in order.
    public init(ledColors: [RGBColor]) {
        self.ledColors = ledColors
    }

    func encode(into byteBuffer: inout ByteBuffer) {
        byteBuffer.writeInteger(UInt32(4 + 2 + 4 * ledColors.count), endianness: .little)
        byteBuffer.writeInteger(UInt16(ledColors.count), endianness: .little)

        for color in ledColors {
            color.encode(into: &byteBuffer)
        }
    }
}
