/// A saved color profile stored on the OpenRGB server.
public struct OpenRGBProfile: Sendable, Codable {
    /// The name of the profile.
    public let name: String
}

extension [OpenRGBProfile]: OpenRGBDecodable, OpenRGBResponse {
    // https://gitlab.com/CalcProgrammer1/OpenRGB/-/blob/master/Documentation/OpenRGBSDK.md?ref_type=heads#response-size-variable-1
    init(from body: inout OpenRGBPacket.Body, protocolVersion: UInt32) throws {
        _ = body.readInteger(endianness: .little, as: UInt32.self)  // data_size
        let profilesCount = try body.requireInteger(endianness: .little, as: UInt16.self)

        var profiles: [OpenRGBProfile] = []
        for _ in 0..<Int(profilesCount) {
            let length = try body.requireInteger(endianness: .little, as: UInt16.self)
            let name = try body.requireString(length: Int(length))
            profiles.append(.init(name: name))
        }

        self = profiles
    }
}
