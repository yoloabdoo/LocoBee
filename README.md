# LocoBee SDK

`LocoBee` is an easy-to-use location SDK for managing and uploading location data. It provides a comprehensive API to register location tracking services, start and stop location observation, and upload the latest location data to a server.

## Features
- **Location Tracking**: Observe and collect location data seamlessly.
- **Batch Uploads**: Efficiently upload location data in batches.
- **Singleton Access**: Easily access `LocoBee` via its singleton instance.

## Installation
### Swift Package Manager
1. Open your Xcode project, and navigate to **File > Swift Packages > Add Package Dependency**.
2. Enter the repository URL: `https://github.com/yoloabdoo/LocoBee.git`.
3. Select the latest version.

### Manual Installation
1. Clone or download the repository.
2. Drag the `LocoBee` folder into your Xcode project.

### Add Location Info to `Info.plist`

To request location permissions, add the following keys to your app's `Info.plist` file:

1. **NSLocationWhenInUseUsageDescription**  
   Used for requesting location access while the app is in the foreground.

   ```xml
   <key>NSLocationWhenInUseUsageDescription</key>
   <string>We need your location for tracking purposes.</string>
   ```

2. **NSLocationAlwaysUsageDescription**  
   Used for requesting location access even when the app is in the background.

   ```xml
   <key>NSLocationAlwaysUsageDescription</key>
   <string>We need your location for background tracking purposes.</string>
   ```

3. **NSLocationAlwaysAndWhenInUseUsageDescription** (Optional)  
   Covers both the above cases and simplifies location authorization management.

   ```xml
   <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
   <string>We need your location for continuous tracking purposes.</string>
   ```

## Usage
### Register the SDK
Make sure to call the `register` method to set up the necessary network clients before starting location observation.

```swift
let locoBee = LocoBee.shared
locoBee.register()
```

### Start Observing Location Data
Ensure the app has the appropriate location permissions before starting observation.

```swift
do {
    try LocoBee.shared.startObserving()
} catch {
    print("Error starting observation: \(error)")
}
```

### Send the Latest Location
Upload the most recent location data to the server.

```swift
Task {
    do {
        try await LocoBee.shared.sendLatestLocation()
    } catch {
        print("Error sending latest location: \(error)")
    }
}
```

### Stop Observing Location Data
Stop observing location data and cancel the observation task.

```swift
LocoBee.shared.stopObservingLocation()
```

## Documentation
### Classes
#### `LocoBee`
The `LocoBee` class is a singleton responsible for managing location updates and uploading location data to a server.

- `register()`: Registers the location tracking service.
- `startObserving()`: Starts observing location data.
- `sendLatestLocation()`: Uploads the latest location data to the server.
- `stopObservingLocation()`: Stops observing location data.


### Complete Example
```swift
import LocoBee

let locoBee = LocoBee.shared

// Register the SDK
locoBee.register()

// Start observing location data
do {
    try locoBee.startObserving()
} catch {
    print("Error starting observation: \(error)")
}

// Send the latest location
Task {
    do {
        try await locoBee.sendLatestLocation()
    } catch {
        print("Error sending latest location: \(error)")
    }
}

// Stop observing location data
locoBee.stopObservingLocation()
```
