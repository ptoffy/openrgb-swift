import Testing
import NIOCore
import OpenRGB
import Logging
import Foundation

@Suite("OpenRGB Tests")
struct OpenRGBTests {
    let host: String
    let port: Int

    init() {
        self.host = ProcessInfo.processInfo.environment["OPENRGB_HOST"] ?? "localhost"
        self.port = ProcessInfo.processInfo.environment["OPENRGB_PORT"].flatMap(Int.init) ?? 6742
    }

    var logger: Logger {
        var logger = Logger(label: "test.swift.openrgb.logger")
        logger.logLevel = .debug
        return logger
    }

    @Test("Request controller count")
    func requestControllerCount() async throws {
        try await OpenRGBConnection.withConnection(to: host, port: port, logger: logger) { connection in
            let count = try await connection.requestControllerCount()
            #expect(count == 0)
        }
    }

    @Test("Request controller data")
    func requestControllerData() async throws {
        try await OpenRGBConnection.withConnection(to: host, port: port, logger: logger) { connection in
            let data = try await connection.requestAllControllersData()
            #expect(data.isEmpty)
        }
    }

    @Test("Request profile list")
    func requestProfileList() async throws {
        try await OpenRGBConnection.withConnection(to: host, port: port, logger: logger) { connection in
            let list = try await connection.requestProfileList()
            #expect(list.isEmpty)
        }
    }
}
