import struct NIOCore.ByteBuffer

// https://gitlab.com/CalcProgrammer1/OpenRGB/-/blob/master/Documentation/OpenRGBSDK.md?ref_type=heads#response-size-variable
/// Data describing an RGB controller returned by the server.
public struct OpenRGBControllerData: OpenRGBResponse, Codable {
    /// The zero-based index of this controller among all controllers on the server.
    public var deviceIndex: UInt32 = 0
    /// The byte length of the serialized controller data.
    public let dataSize: UInt32
    /// The device type identifier.
    public let type: Int32
    /// The human-readable name of the device.
    public let name: String
    /// The vendor name, if reported by the device (protocol v1+).
    public let vendor: String?
    /// A description of the device.
    public let description: String
    /// The firmware or driver version string.
    public let version: String
    /// The serial number of the device.
    public let serial: String
    /// The physical or logical location of the device.
    public let location: String
    /// The index of the currently active lighting mode.
    public let activeMode: Int32
    /// The lighting modes supported by this controller.
    public let modes: [Mode]
    /// The LED zones defined on this controller.
    public let zones: [Zone]
    /// The individual LEDs on this controller.
    public let leds: [LED]
    /// The current color of each LED.
    public let colors: [RGBColor]
    /// Alternate names for LEDs (protocol v5+).
    public let ledAlternateNames: [LEDAlternateName]?
    /// Controller-level feature flags.
    public let flags: UInt32

    init(from body: inout OpenRGBPacket.Body, protocolVersion: UInt32) throws {
        self.dataSize = try body.requireInteger(endianness: .little)
        self.type = try body.requireInteger(endianness: .little)

        let nameLength = try body.requireInteger(endianness: .little, as: UInt16.self)
        self.name = try body.requireString(length: Int(nameLength))

        if protocolVersion >= 1 {
            let vendorLength = try body.requireInteger(endianness: .little, as: UInt16.self)
            self.vendor = try body.requireString(length: Int(vendorLength))
        } else {
            self.vendor = nil
        }

        let descriptionLength = try body.requireInteger(endianness: .little, as: UInt16.self)
        self.description = try body.requireString(length: Int(descriptionLength))

        let versionLength = try body.requireInteger(endianness: .little, as: UInt16.self)
        self.version = try body.requireString(length: Int(versionLength))

        let serialLength = try body.requireInteger(endianness: .little, as: UInt16.self)
        self.serial = try body.requireString(length: Int(serialLength))

        let locationLength = try body.requireInteger(endianness: .little, as: UInt16.self)
        self.location = try body.requireString(length: Int(locationLength))

        let modesCount = try body.requireInteger(endianness: .little, as: UInt16.self)
        self.activeMode = try body.requireInteger(endianness: .little)
        var modes: [Mode] = []
        for _ in 0..<Int(modesCount) {
            try modes.append(Mode(from: &body, protocolVersion: protocolVersion))
        }
        self.modes = modes

        let zonesCount = try body.requireInteger(endianness: .little, as: UInt16.self)
        var zones: [Zone] = []
        for _ in 0..<Int(zonesCount) {
            try zones.append(Zone(from: &body, protocolVersion: protocolVersion))
        }
        self.zones = zones

        let ledsCount = try body.requireInteger(endianness: .little, as: UInt16.self)
        var leds: [LED] = []
        for _ in 0..<Int(ledsCount) {
            try leds.append(LED(from: &body, protocolVersion: protocolVersion))
        }
        self.leds = leds

        let colorsCount = try body.requireInteger(endianness: .little, as: UInt16.self)
        var colors: [RGBColor] = []
        for _ in 0..<Int(colorsCount) {
            try colors.append(RGBColor(from: &body, protocolVersion: protocolVersion))
        }
        self.colors = colors

        if protocolVersion >= 5 {
            let ledAlternateNameCount = try body.requireInteger(endianness: .little, as: UInt16.self)
            var ledAlternateNames: [LEDAlternateName] = []
            for _ in 0..<Int(ledAlternateNameCount) {
                try ledAlternateNames.append(LEDAlternateName(from: &body, protocolVersion: protocolVersion))
            }
            self.ledAlternateNames = ledAlternateNames
        } else {
            self.ledAlternateNames = nil
        }

        self.flags = try body.requireInteger()
    }

    // https://gitlab.com/CalcProgrammer1/OpenRGB/-/blob/master/Documentation/OpenRGBSDK.md?ref_type=heads#mode-data
    /// A lighting mode supported by a controller.
    public struct Mode: OpenRGBDecodable, Codable {
        let name: String
        let value: Int32
        let flags: UInt32
        let speedMin: UInt32
        let speedMax: UInt32
        let brightnessMin: UInt32?
        let brightnessMax: UInt32?
        let colorsMin: UInt32
        let colorsMax: UInt32
        let speed: UInt32
        let brightness: UInt32?
        let direction: UInt32
        let colorMode: UInt32
        let colors: [RGBColor]

        init(from body: inout OpenRGBPacket.Body, protocolVersion: UInt32) throws {
            let nameLength = try body.requireInteger(endianness: .little, as: UInt16.self)
            self.name = try body.requireString(length: Int(nameLength))
            self.value = try body.requireInteger(endianness: .little)
            self.flags = try body.requireInteger(endianness: .little)
            self.speedMin = try body.requireInteger(endianness: .little)
            self.speedMax = try body.requireInteger(endianness: .little)
            if protocolVersion >= 3 {
                self.brightnessMin = try body.requireInteger(endianness: .little)
                self.brightnessMax = try body.requireInteger(endianness: .little)
            } else {
                self.brightnessMin = nil
                self.brightnessMax = nil
            }
            self.colorsMin = try body.requireInteger(endianness: .little)
            self.colorsMax = try body.requireInteger(endianness: .little)
            self.speed = try body.requireInteger(endianness: .little)
            if protocolVersion >= 3 {
                self.brightness = try body.requireInteger(endianness: .little)
            } else {
                self.brightness = nil
            }
            self.direction = try body.requireInteger(endianness: .little)
            self.colorMode = try body.requireInteger(endianness: .little)

            let colorsCount = try body.requireInteger(endianness: .little, as: UInt16.self)
            var colors: [RGBColor] = []
            for _ in 0..<colorsCount {
                colors.append(try RGBColor(from: &body, protocolVersion: protocolVersion))
            }

            self.colors = colors
        }
    }

    /// A named grouping of LEDs within a controller.
    public struct Zone: OpenRGBDecodable, Codable {
        let name: String
        let type: Int32
        let ledsMin: UInt32
        let ledsMax: UInt32
        let ledsCount: UInt32
        let matrixSize: UInt16
        let matrixHeight: UInt32?
        let matrixWidth: UInt32?
        let matrixData: [[UInt32?]]
        let segments: [Segment]?
        let flags: UInt32?

        init(from body: inout OpenRGBPacket.Body, protocolVersion: UInt32) throws {
            let nameCount = try body.requireInteger(endianness: .little, as: UInt16.self)
            self.name = try body.requireString(length: Int(nameCount))

            self.type = try body.requireInteger(endianness: .little)
            self.ledsMin = try body.requireInteger(endianness: .little)
            self.ledsMax = try body.requireInteger(endianness: .little)
            self.ledsCount = try body.requireInteger(endianness: .little)
            self.matrixSize = try body.requireInteger(endianness: .little)

            if matrixSize != 0 {
                self.matrixHeight = try body.requireInteger(endianness: .little)
                self.matrixWidth = try body.requireInteger(endianness: .little)

                var matrixData: [[UInt32?]] = []
                for i in 0..<Int(matrixHeight!) {
                    matrixData[i] = []
                    for j in 0..<Int(matrixWidth!) {
                        let led = try body.requireInteger(endianness: .little, as: UInt32.self)
                        matrixData[i][j] = led != 0xffff_ffff ? led : nil
                    }
                }
                self.matrixData = matrixData
            } else {
                self.matrixHeight = nil
                self.matrixWidth = nil
                self.matrixData = [[]]
            }

            if protocolVersion >= 4 {
                let segmentsCount = try body.requireInteger(endianness: .little, as: UInt16.self)
                var segments: [Segment] = []
                for _ in 0..<segmentsCount {
                    segments.append(try Segment(from: &body, protocolVersion: protocolVersion))
                }
                self.segments = segments
            } else {
                self.segments = nil
            }

            if protocolVersion >= 5 {
                self.flags = try body.requireInteger(endianness: .little)
            } else {
                self.flags = nil
            }
        }

        struct Segment: OpenRGBDecodable, Codable {
            let name: String
            let type: Int32
            let startIdx: UInt32
            let ledsCount: UInt32

            init(from body: inout OpenRGBPacket.Body, protocolVersion: UInt32) throws {
                let nameCount = try body.requireInteger(endianness: .little, as: UInt16.self)
                self.name = try body.requireString(length: Int(nameCount))

                self.type = try body.requireInteger(endianness: .little)
                self.startIdx = try body.requireInteger(endianness: .little)
                self.ledsCount = try body.requireInteger(endianness: .little)
            }
        }
    }

    /// An individual LED on a controller.
    public struct LED: OpenRGBDecodable, Codable {
        let name: String
        let value: UInt32

        init(from body: inout OpenRGBPacket.Body, protocolVersion: UInt32) throws {
            let nameCount = try body.requireInteger(endianness: .little, as: UInt16.self)
            self.name = try body.requireString(length: Int(nameCount))

            self.value = try body.requireInteger(endianness: .little)
        }
    }

    /// An alternate name for an LED, available in protocol v5+.
    public struct LEDAlternateName: OpenRGBDecodable, Codable {
        let name: String

        init(from body: inout OpenRGBPacket.Body, protocolVersion: UInt32) throws {
            let nameCount = try body.requireInteger(endianness: .little, as: UInt16.self)
            self.name = try body.requireString(length: Int(nameCount))
        }
    }
}
