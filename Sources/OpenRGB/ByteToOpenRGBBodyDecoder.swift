import NIOCore

struct ByteToOpenRGBPacketBodyDecoder: NIOSingleStepByteToMessageDecoder, Sendable {
    typealias InboundOut = OpenRGBPacket.Body

    func decode(buffer: inout ByteBuffer) throws -> OpenRGBPacket.Body? {
        if buffer.readableBytes < OpenRGBNetPacketHeader.defaultLength {
            return nil
        }

        let savedIndex = buffer.readerIndex
        let header = try OpenRGBNetPacketHeader.decode(reading: &buffer)

        guard
            buffer.readableBytes >= header.bodyLength,
            let slice = buffer.readSlice(length: Int(header.bodyLength))
        else {
            // if we don't restore the index, we won't read be able to read the header
            // when the body arrives and will try to read the body as a header instead
            buffer.moveReaderIndex(to: savedIndex)
            return nil
        }

        return slice
    }

    func decodeLast(buffer: inout ByteBuffer, seenEOF: Bool) throws -> OpenRGBPacket.Body? {
        try decode(buffer: &buffer)
    }
}
