import struct NIOCore.ByteBuffer
import enum NIOCore.Endianness

extension UInt32 {
    var asLEUInt8Array: [UInt8] {
        [
            UInt8(truncatingIfNeeded: self),
            UInt8(truncatingIfNeeded: self >> 8),
            UInt8(truncatingIfNeeded: self >> 16),
            UInt8(truncatingIfNeeded: self >> 24),
        ]
    }

    var asBEUInt8Array: [UInt8] {
        [
            UInt8(truncatingIfNeeded: self >> 24),
            UInt8(truncatingIfNeeded: self >> 16),
            UInt8(truncatingIfNeeded: self >> 8),
            UInt8(truncatingIfNeeded: self),
        ]
    }

    // swift-format-ignore
    init(littleEndian: [UInt8]) {
        self =
            UInt32(littleEndian[0]) |
            UInt32(littleEndian[1] << 8) |
            UInt32(littleEndian[2] << 16) |
            UInt32(littleEndian[3] << 32)
    }
}

extension UInt16 {
    // swift-format-ignore
    init(littleEndian: Span<UInt8>) {
        self =
            UInt16(littleEndian[0]) |
            UInt16(littleEndian[1] << 8)
    }

    // swift-format-ignore
    init(littleEndian: Array<UInt8>) {
        self =
            UInt16(littleEndian[0]) |
            UInt16(littleEndian[1] << 8)
    }
}

extension ByteBuffer {
    mutating func requireInteger<T: FixedWidthInteger & Sendable>(
        endianness: Endianness = .big,
        as: T.Type = T.self
    ) throws -> T {
        guard let integer = self.readInteger(endianness: endianness, as: T.self) else {
            throw OpenRGBDecodingError.couldNotDecodeInteger(as: T.self)
        }
        return integer
    }

    mutating func requireString(length: Int) throws -> String {
        guard let string = self.readString(length: length) else {
            throw OpenRGBDecodingError.couldNotDecodeString
        }
        return string
    }
}
