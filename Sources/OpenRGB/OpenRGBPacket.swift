import struct NIOCore.ByteBuffer
import struct NIOCore.ByteBufferAllocator

// https://github.com/CalcProgrammer1/OpenRGB/blob/master/Documentation/OpenRGBSDK.md#netpacketheader-structure
struct OpenRGBPacket: Sendable, CustomStringConvertible {
    typealias Body = ByteBuffer

    let header: OpenRGBNetPacketHeader
    let body: Body?

    init(header: OpenRGBNetPacketHeader, body: Body? = nil) {
        self.header = header
        self.body = body
    }

    init(
        _ packetId: OpenRGBNetPacketHeader.PacketID,
        deviceIndex: UInt32 = 0,
        body: Body? = nil
    ) {
        let bodyLength = UInt32(body?.readableBytes ?? 0)
        self.header = .init(id: packetId, deviceIndex: deviceIndex, bodyLength: bodyLength)
        self.body = body
    }

    var id: OpenRGBNetPacketHeader.PacketID {
        self.header.id
    }

    var size: UInt32 {
        self.header.bodyLength
    }

    var description: String {
        let bodyInfo: String
        if let body {
            let previewBytes = body.readableBytesView.prefix(16)
            let hexPreview =
                previewBytes.map { byte in
                    String(byte, radix: 16, uppercase: true).padLeft(to: 2, with: "0")
                }
                .joined(separator: " ")

            let ellipsis = body.readableBytes > previewBytes.count ? " ..." : ""
            bodyInfo = "body:[\(hexPreview)\(ellipsis)]"
        } else {
            bodyInfo = "no body"
        }

        return "OpenRGBPacket(id: \(id), deviceIndex: \(header.deviceIndex), size: \(size), \(bodyInfo))"
    }
}

extension String {
    func padLeft(to length: Int, with char: Character) -> String {
        let padCount = length - self.count
        return padCount > 0 ? String(repeating: char, count: padCount) + self : self
    }
}

struct OpenRGBNetPacketHeader: Sendable {
    static let defaultLength: UInt32 = 16
    static let packetMagic: UInt32 = 0x4f52_4742  // ORGB

    let id: PacketID
    let deviceIndex: UInt32
    let bodyLength: UInt32

    init(id: PacketID, deviceIndex: UInt32 = 0, bodyLength: UInt32) {
        self.id = id
        self.deviceIndex = deviceIndex
        self.bodyLength = bodyLength
    }

    // swift-format-ignore
    enum PacketID: UInt32, Sendable {
        case requestControllerCount = 0     // NET_PACKET_ID_REQUEST_CONTROLLER_COUNT
        case requestControllerData  = 1     // NET_PACKET_ID_REQUEST_CONTROLLER_DATA
        // The NET_PACKET_ID_REQUEST_PROTOCOL_VERSION packet was not present in protocol version 0,
        // but clients supporting protocol versions 1+ should always send this packet.
        // If no response is received, it should be assumed that the server is using protocol 0.
        case requestProtocolVersion = 40    // NET_PACKET_ID_REQUEST_PROTOCOL_VERSION
        case setClientName          = 50    // NET_PACKET_ID_SET_CLIENT_NAME
        case deviceListUpdated      = 100   // NET_PACKET_ID_DEVICE_LIST_UPDATED
        case requestRescanDevices   = 140   // NET_PACKET_ID_REQUEST_RESCAN_DEVICES
        case requestProfileList     = 150   // NET_PACKET_ID_REQUEST_PROFILE_LIST
        case requestSaveProfile     = 151   // NET_PACKET_ID_REQUEST_SAVE_PROFILE
        case requestLoadProfile     = 152   // NET_PACKET_ID_REQUEST_LOAD_PROFILE
        case requestDeleteProfile   = 153   // NET_PACKET_ID_REQUEST_DELETE_PROFILE
        case requestPluginList      = 200   // NET_PACKET_ID_REQUEST_PLUGIN_LIST
        case pluginSpecific         = 201   // NET_PACKET_ID_PLUGIN_SPECIFIC

        // RGBController commands
        case rgbControllerResizeZone        = 1000  // NET_PACKET_ID_RGBCONTROLLER_RESIZEZONE
        case rgbControllerClearSegments     = 1001  // NET_PACKET_ID_RGBCONTROLLER_CLEARSEGMENTS
        case rgbControllerAddSegment        = 1002  // NET_PACKET_ID_RGBCONTROLLER_ADDSEGMENT
        case rgbControllerUpdateLEDs        = 1050  // NET_PACKET_ID_RGBCONTROLLER_UPDATELEDS
        case rgbControllerUpdateZoneLEDs    = 1051  // NET_PACKET_ID_RGBCONTROLLER_UPDATEZONELEDS
        case rgbControllerUpdateSingleLED   = 1052  // NET_PACKET_ID_RGBCONTROLLER_UPDATESINGLELED
        case rgbControllerSetCustomMode     = 1100  // NET_PACKET_ID_RGBCONTROLLER_SETCUSTOMMODE
        case rgbControllerUpdateMode        = 1101  // NET_PACKET_ID_RGBCONTROLLER_UPDATEMODE
        case rgbControllerSaveMode          = 1102  // NET_PACKET_ID_RGBCONTROLLER_SAVEMODE
    }
}

extension OpenRGBPacket {
    func encode(into buffer: inout ByteBuffer) {
        buffer.reserveCapacity(16)
        buffer.writeInteger(OpenRGBNetPacketHeader.packetMagic, endianness: .little)
        buffer.writeInteger(header.deviceIndex, endianness: .little)
        buffer.writeInteger(id.rawValue, endianness: .little)
        buffer.writeInteger(size, endianness: .little)
        if let body { buffer.writeImmutableBuffer(body) }
    }
}

extension OpenRGBNetPacketHeader: Equatable {
    #if compiler(>=6.2)
    init?(from bufferSpan: inout RawSpan) {
        guard let packetId = PacketID(rawValue: bufferSpan.extractFirstUInt32()) else {
            return nil
        }
        let deviceIndex = bufferSpan.extractFirstUInt32()
        let size = bufferSpan.extractFirstUInt32()

        self.init(
            id: packetId,
            deviceIndex: deviceIndex,
            bodyLength: size
        )
    }
    #endif

    static func decode(reading buffer: inout ByteBuffer) throws -> OpenRGBNetPacketHeader {
        guard
            let magic = buffer.readInteger(as: UInt32.self),
            magic == 0x4f52_4742
        else {
            throw DecodingError.missingMagicNumber
        }

        guard
            let deviceIndex = buffer.readInteger(endianness: .little, as: UInt32.self),
            let _packetId = buffer.readInteger(endianness: .little, as: UInt32.self),
            let packetId = PacketID(rawValue: _packetId),
            let size = buffer.readInteger(endianness: .little, as: UInt32.self)
        else {
            throw DecodingError.couldNotDecodeAsUInt32
        }

        return .init(
            id: packetId,
            deviceIndex: deviceIndex,
            bodyLength: size
        )
    }
}

extension OpenRGBNetPacketHeader {
    enum DecodingError: Error {
        case missingMagicNumber
        case couldNotDecodeAsUInt32
    }
}

extension RawSpan {
    mutating func extractFirstUInt32() -> UInt32 {
        let value = unsafeLoadUnaligned(as: UInt32.self)
        self = self.extracting(droppingFirst: 4)
        return value
    }
}
