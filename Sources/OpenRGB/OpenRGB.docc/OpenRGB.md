# ``OpenRGB``

A Swift client library for the OpenRGB SDK protocol, built on SwiftNIO.

## Overview

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

## Topics

### Connections

- ``OpenRGBConnection``

### Requests

- ``OpenRGBControllerUpdateLEDs``
- ``OpenRGBControllerUpdateZoneLEDs``
- ``OpenRGBControllerZoneResize``

### Responses

- ``OpenRGBControllerData``
- ``OpenRGBProfile``
