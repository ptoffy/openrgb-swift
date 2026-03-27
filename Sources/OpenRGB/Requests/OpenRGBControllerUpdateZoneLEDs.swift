import struct NIOCore.ByteBuffer

public struct OpenRGBControllerUpdateZoneLEDs: OpenRGBEncodable {
    let zoneIndex: UInt32
    let ledColors: [RGBColor]

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
