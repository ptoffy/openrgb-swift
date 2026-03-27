import struct NIOCore.ByteBuffer

public struct OpenRGBControllerUpdateLEDs: OpenRGBEncodable {
    let ledColors: [RGBColor]

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
