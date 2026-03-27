# OpenRGB Swift SDK

A Swift client library for the [OpenRGB](https://openrgb.org) SDK protocol, built on SwiftNIO.

## Installation

Add the package to your `Package.swift`:

```swift
.package(url: "https://github.com/pt/openrgb-swift.git", from: "0.1.0"),
```

Then add `OpenRGB` to your target's dependencies.

## Usage

### Automatic connection lifecycle

```swift
import OpenRGB

try await OpenRGBConnection.withConnection(to: "localhost", port: 6742) { connection in
    let controllers = try await connection.requestAllControllersData()
    for controller in controllers {
        print(controller.name)
    }
}
```

### Manual connection

```swift
let connection = try await OpenRGBConnection.connect(to: "localhost", port: 6742)

let count = try await connection.requestControllerCount()

try await connection.disconnect()
```

### Updating LED colors

```swift
try await OpenRGBConnection.withConnection { connection in
    let controllers = try await connection.requestAllControllersData()
    guard let first = controllers.first else { return }

    // Set LEDs to rainbow colors
    let colors = (0..<first.leds.count).map { i in
        OpenRGBColor(
            red: UInt8((i * 255) / first.leds.count),
            green: UInt8(255 - (i * 255) / first.leds.count),
            blue: 128
        )
    }
    
    try await connection.rgbControllerUpdateLEDs(
        deviceIndex: first.deviceIndex,
        body: OpenRGBControllerUpdateLEDs(ledColors: colors)
    )
}
```
