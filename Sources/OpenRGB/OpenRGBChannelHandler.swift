import Logging
import NIOCore
import NIOConcurrencyHelpers

/// This handler basically works like an HTTP client, but directly on TCP instead.
/// We send requests to the OpenRGB server through ``write(context:, data:, promise:)``
/// and wait for the response to come in through ``channelRead(context:, data:)``.
/// Before joining this handler, the data is parsed through a ``ByteToOpenRGBPacketBodyDecoder`` (via)
/// a `ByteToMessageHandler`, so we get the packet here and not the raw data.
final class OpenRGBChannelHandler: ChannelDuplexHandler, Sendable {
    /// We receive data from ORGB but it's parsed into a packet body by a `ByteToMessageHandler<ByteToOpenRGBPacketBodyDecoder>`` first.
    typealias InboundIn = OpenRGBPacket.Body
    /// Receive an ``OpenRGBPacket`` from the business logic to send to.
    typealias OutboundIn = (OpenRGBPacket, EventLoopPromise<OpenRGBPacket.Body>?)
    /// Don't expect to send anything into another channel as this is the last consumer.
    typealias InboundOut = Never
    /// Send raw data to OpenRGB.
    typealias OutboundOut = ByteBuffer

    let logger: Logger

    private let pendingPromises: NIOLockedValueBox<[EventLoopPromise<OpenRGBPacket.Body>]>

    init(logger: Logger) {
        self.logger = logger
        self.pendingPromises = .init([])
    }

    // Called when data is written _to_ this handler.
    // In this case it's basically when a response comes in.
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let packet = self.unwrapInboundIn(data)
        logger.trace("Received data")

        // Pull the promise out first, then succeed it outside of the lock
        let promise: EventLoopPromise<OpenRGBPacket.Body>? = pendingPromises.withLockedValue {
            guard !$0.isEmpty else { return nil }
            return $0.removeFirst()
        }

        if let promise {
            promise.succeed(packet)
        } else {
            logger.warning("Received packet without pending promise")
        }
    }

    func channelInactive(context: ChannelHandlerContext) {
        pendingPromises.withLockedValue {
            for response in $0 {
                response.fail(OpenRGBChannelHandlerError.channelInactive)
            }
            $0.removeAll()
        }
    }

    func errorCaught(context: ChannelHandlerContext, error: any Error) {
        pendingPromises.withLockedValue {
            for response in $0 {
                response.fail(error)
            }
            $0.removeAll()
        }
    }

    // Called when we want to write data outside of this handler.
    // In this case we send data to the network since this is the first and last handler.
    func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        let (packet, outerPromise) = self.unwrapOutboundIn(data)
        self.logger.trace("Sending packet", metadata: ["packetId": "\(packet.id)"])

        var buffer = context.channel.allocator.buffer(capacity: Int(packet.size))
        packet.encode(into: &buffer)

        // Here we call .write and not .fire* because we're not passing the data along to another handler
        // but we're the final consumer and and sending it out of the pipeline
        context.writeAndFlush(self.wrapOutboundOut(buffer), promise: promise)

        if let outerPromise {
            self.pendingPromises.withLockedValue { queue in
                queue.append(outerPromise)
            }
        }
    }
}

enum OpenRGBChannelHandlerError: Error {
    case channelInactive
    case couldNotReadBytesFromBuffer
}
