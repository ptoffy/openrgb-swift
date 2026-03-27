import Logging
import NIOCore
import NIOPosix

/// A connection to an OpenRGB server.
///
/// Use ``withConnection(to:port:logger:maxVersion:clientName:closure:)`` for automatic
/// lifecycle management, or ``connect(to:port:logger:maxVersion:clientName:)`` to manage
/// the connection manually.
public struct OpenRGBConnection: Sendable {
    /// The default maximum OpenRGB SDK protocol version to negotiate.
    public static let defaultMaxVersion = 5

    let logger: Logger

    let version: UInt32

    let handler: OpenRGBChannelHandler
    let channel: Channel

    /// Connects to an OpenRGB server, runs the provided closure, then disconnects.
    ///
    /// - Parameters:
    ///   - host: The hostname or IP address of the OpenRGB server.
    ///   - port: The port the server is listening on.
    ///   - logger: The logger to use for connection diagnostics.
    ///   - maxVersion: The maximum SDK protocol version to negotiate. Must be in `0...5`.
    ///   - clientName: The client name sent to the server during the handshake.
    ///   - closure: An async closure that receives the open connection.
    public static func withConnection(
        to host: String = "localhost",
        port: Int = 6742,
        logger: Logger = .init(label: "swift.openrgb.logger"),
        maxVersion: Int = Self.defaultMaxVersion,
        clientName: String = "openrgb.swift",
        closure: sending (Self) async throws -> Void,
    ) async throws {
        let connection = try await Self.connect(
            to: host,
            port: port,
            logger: logger,
            maxVersion: maxVersion,
            clientName: clientName
        )
        try await closure(connection)
        try await connection.disconnect()
    }

    /// Opens a TCP connection to an OpenRGB server and negotiates the protocol version.
    ///
    /// - Parameters:
    ///   - host: The hostname or IP address of the OpenRGB server.
    ///   - port: The port the server is listening on.
    ///   - logger: The logger to use for connection diagnostics.
    ///   - maxVersion: The maximum SDK protocol version to negotiate. Must be in `0...5`.
    ///   - clientName: The client name sent to the server during the handshake.
    /// - Returns: An open connection ready to accept requests.
    public static func connect(
        to host: String = "localhost",
        port: Int = 6742,
        logger: Logger = .init(label: "swift.openrgb.logger"),
        maxVersion: Int = Self.defaultMaxVersion,
        clientName: String = "openrgb.swift",
    ) async throws -> OpenRGBConnection {
        guard maxVersion >= 0, maxVersion <= 5 else {
            throw OpenRGBConnectionError.maxVersionNotInRange
        }
        let channelHandler = OpenRGBChannelHandler(logger: logger)
        let eventLoopGroup: EventLoopGroup = .singletonMultiThreadedEventLoopGroup
        let client = ClientBootstrap(group: eventLoopGroup)
            // allow the channel's address to be reused when it's in TIME_WAIT state
            .channelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .channelInitializer { channel in
                channel.eventLoop.makeCompletedFuture {
                    try channel.pipeline.syncOperations.addHandler(
                        ByteToMessageHandler(ByteToOpenRGBPacketBodyDecoder())
                    )
                    try channel.pipeline.syncOperations.addHandler(channelHandler)
                }
            }

        let version: UInt32
        let channel = try await client.connect(host: host, port: port).get()
        do {
            version =
                try await channel.send(
                    packet: OpenRGBPacket(
                        .requestProtocolVersion,
                        body: channel.allocator.buffer(integer: UInt32(maxVersion), endianness: .little)
                    ),
                    version: 0,
                    decoding: OpenRGBSingleIntegerResponse.self,
                    logger: logger
                )
        } catch OpenRGBConnectionError.requestTimeout {
            logger.debug("Protocol version request timed out, defaulting to 0")
            version = 0
        }

        logger.info("Connected to \(host):\(port) with SDK version \(version)")

        return OpenRGBConnection(
            logger: logger,
            version: version,
            handler: channelHandler,
            channel: channel,
        )
    }

    func request<Response: OpenRGBResponse>(
        packet: OpenRGBPacket,
        decoding: Response.Type = Response.self,
        timeout: TimeAmount = .seconds(10)
    ) async throws -> Response {
        try await self.channel.send(
            packet: packet,
            version: version,
            decoding: Response.self,
            timeout: timeout,
            logger: logger
        )
    }

    func request(
        packet: OpenRGBPacket,
        timeout: TimeAmount = .seconds(10)
    ) async throws {
        try await self.channel.send(packet: packet, version: version, timeout: timeout, logger: logger)
    }

    /// Closes the connection to the OpenRGB server.
    public func disconnect() async throws { try await self.channel.close() }
}

extension Channel {
    fileprivate func send(
        packet: OpenRGBPacket,
        version: UInt32,
        timeout: TimeAmount = .seconds(3),
        logger: Logger
    ) async throws {
        logger.debug("Sending \(packet)")
        try await self.writeAndFlush((packet, EventLoopPromise<OpenRGBPacket>?.none))
    }

    fileprivate func send<Response: OpenRGBResponse>(
        packet: OpenRGBPacket,
        version: UInt32,
        decoding: Response.Type = Response.self,
        timeout: TimeAmount = .seconds(3),
        logger: Logger
    ) async throws -> Response {
        logger.debug("Sending \(packet), expecting \(Response.self)")
        let promise = self.eventLoop.makePromise(of: OpenRGBPacket.Body.self)
        let timeoutTask = self.eventLoop.scheduleTask(in: timeout) {
            promise.fail(OpenRGBConnectionError.requestTimeout(after: timeout))
        }
        promise.futureResult.whenComplete { _ in
            timeoutTask.cancel()
        }
        try await self.writeAndFlush((packet, promise))
        var body = try await promise.futureResult.get()
        return try Response(from: &body, protocolVersion: version)
    }
}

enum OpenRGBConnectionError: Error {
    case maxVersionNotInRange
    case requestTimeout(after: TimeAmount)
}
