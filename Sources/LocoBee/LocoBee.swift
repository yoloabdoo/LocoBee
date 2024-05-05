import Foundation

/**
 `LocoBee` is a singleton class responsible for managing location updates and uploading location data to a server.

 - The class provides an easy-to-use API for:
 - Registering the location tracking service.
 - Starting and stopping location observation.
 - Uploading the latest location data.

 ## Usage Example
 ```swift
 let locoBee = LocoBee.shared

 locoBee.register()

 do {
    try locoBee.startObserving()
 } catch {
    print("Error starting observation: \(error)")
 }

 Task {
     do {
        try await locoBee.sendLatestLocation()
     } catch {
        print("Error sending latest location: \(error)")
     }
 }

 locoBee.stopObservingLocation()
 ```
 Note: Make sure to request proper location permissions in your app.
 */
@available(macOS 10.15, iOS 13, *)
public class LocoBee: ObservableObject {
    public static let shared = LocoBee()
    private let networkClient: URLSessionAPIClient
    private let locationStream: AsyncLocationStream
    private let locationStore: LocationStore
    private var observeTask: Task<Void, Error>?

    /// Initializes the LocationManager with the specified network client.
    /// - Parameter networkClient: The network client to use for uploading locations.
    private init(
        networkClient: URLSessionAPIClient = .shared,
        locationStore: LocationStore = LocationStore(
            network: LocationUseCase()
        ),
        locationStream: AsyncLocationStream = AsyncLocationStream()
    ) {
        self.networkClient = networkClient
        self.locationStore = locationStore
        self.locationStream = locationStream
    }

    public func register() {
        Task {
            await networkClient.setup()
        }
    }

    public func startObserving() throws {
        try locationStream.startUpdatingLocation()

        observeTask = Task {
            let locations = locationStream.stream

            for try await location in locations {
                try await locationStore.add(location: Location(location))
            }
        }
    }

    public func sendLatestLocation() async throws {
        try await locationStore.uploadLatest()
    }

    public func stopObservingLocation() {
        observeTask?.cancel()
        locationStream.stopUpdatingLocation()
    }
}
