import Logging
import struct NIOCore.ByteBuffer

extension OpenRGBConnection {
    // https://gitlab.com/CalcProgrammer1/OpenRGB/-/blob/master/Documentation/OpenRGBSDK.md?ref_type=heads#net_packet_id_request_controller_count
    public func requestControllerCount() async throws -> Int {
        let controllerCount = try await self.request(
            packet: .init(.requestControllerCount),
            decoding: OpenRGBSingleIntegerResponse.self
        )
        return Int(controllerCount)
    }

    // https://gitlab.com/CalcProgrammer1/OpenRGB/-/blob/master/Documentation/OpenRGBSDK.md?ref_type=heads#net_packet_id_request_controller_data
    public func requestControllerData(deviceIndex: UInt32) async throws -> OpenRGBControllerData {
        let packet =
            if version == 0 {
                OpenRGBPacket(
                    .requestControllerData,
                    deviceIndex: deviceIndex,
                )
            } else {
                OpenRGBPacket(
                    .requestControllerData,
                    deviceIndex: deviceIndex,
                    body: .init(integer: version, endianness: .little)
                )
            }

        return try await self.request(packet: packet)
    }

    public func requestAllControllersData() async throws -> [OpenRGBControllerData] {
        var data: [OpenRGBControllerData] = []
        let controllerCount = try await self.requestControllerCount()
        for i in 0..<UInt32(controllerCount) {
            var controller = try await self.requestControllerData(deviceIndex: i)
            controller.deviceIndex = i
            data.append(controller)
        }
        return data
    }

    // https://gitlab.com/CalcProgrammer1/OpenRGB/-/blob/master/Documentation/OpenRGBSDK.md?ref_type=heads#net_packet_id_request_protocol_version
    public func requestProtocolVersion(minVersion: Int = 5) async throws -> Int {
        guard minVersion >= 0 && minVersion < 5 else {
            throw OpenRGBError.invalidVersion(minVersion)
        }
        let packet = OpenRGBPacket(
            .requestProtocolVersion,
            body: channel.allocator.buffer(integer: minVersion)
        )

        let version: OpenRGBSingleIntegerResponse
        do {
            version = try await self.request(
                packet: packet,
                decoding: OpenRGBSingleIntegerResponse.self
            )
        } catch OpenRGBConnectionError.requestTimeout {
            // If the server is using protocol version 0, it will not send a response.
            // If no response is received, assume the server's highest supported protocol version is version 0.
            logger.trace("Protocol version request timed out, defaulting to 0")
            version = 0
        }

        return Int(version)
    }

    // https://gitlab.com/CalcProgrammer1/OpenRGB/-/blob/master/Documentation/OpenRGBSDK.md?ref_type=heads#net_packet_id_request_rescan_devices
    public func requestRescanDevices() async throws {
        try await self.request(packet: .init(.requestRescanDevices))
    }

    // https://gitlab.com/CalcProgrammer1/OpenRGB/-/blob/master/Documentation/OpenRGBSDK.md?ref_type=heads#net_packet_id_request_profile_list
    public func requestProfileList() async throws -> [OpenRGBProfile] {
        try await self.request(packet: .init(.requestProfileList))
    }

    // https://github.com/CalcProgrammer1/OpenRGB/blob/master/Documentation/OpenRGBSDK.md#net_packet_id_rgbcontroller_updateleds
    public func rgbControllerUpdateLEDs(deviceIndex: UInt32, body: OpenRGBControllerUpdateLEDs) async throws {
        var buffer = ByteBuffer()
        body.encode(into: &buffer)
        try await self.request(
            packet: .init(.rgbControllerUpdateLEDs, deviceIndex: deviceIndex, body: buffer)
        )
    }

    // https://github.com/CalcProgrammer1/OpenRGB/blob/master/Documentation/OpenRGBSDK.md#net_packet_id_rgbcontroller_updatezoneleds
    public func rgbControllerUpdateZoneLEDs(deviceIndex: UInt32, body: OpenRGBControllerUpdateZoneLEDs) async throws {
        var buffer = ByteBuffer()
        body.encode(into: &buffer)
        try await self.request(
            packet: .init(.rgbControllerUpdateZoneLEDs, deviceIndex: deviceIndex, body: buffer)
        )
    }

    // https://github.com/CalcProgrammer1/OpenRGB/blob/master/Documentation/OpenRGBSDK.md#net_packet_id_rgbcontroller_resizezone
    public func rgbControllerResizeZone(deviceIndex: UInt32, body: OpenRGBControllerZoneResize) async throws {
        var buffer = ByteBuffer()
        try body.encode(into: &buffer)
        try await self.request(
            packet: .init(.rgbControllerResizeZone, deviceIndex: deviceIndex, body: buffer)
        )
    }
}
