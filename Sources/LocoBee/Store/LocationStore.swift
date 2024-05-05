import Foundation

/**
 The `LocationStore` class is responsible for managing and uploading location data to a server.
 
 - The class initially stores location data in memory. When the data count exceeds a specified limit,
 it uploads the data to the server in batches.
 - Currently, location data is only stored in memory, which could be enhanced later to persist data to disk
 to retain it across app restarts.
 - Features include:
 - In-memory location data storage
 - Batch uploads triggered upon reaching a specified limit
 - Parallel network requests for efficient uploads (#enhancement)
 
 ## Usage Example:
 ```swift
 // Example of initializing and using the LocationStore class
 let networkClient = LocationUseCase()
 let locationStore = LocationStore(network: networkClient, limit: 5)
 
 let newLocation = Location(latitude: 37.7749, longitude: -122.4194)
 Task {
 try await locationStore.add(location: newLocation)
 }
 **/
@available(macOS 10.15, iOS 13, *)
class LocationStore {
    private var items: [Date: Location]
    private let limit: Int
    private let network: LocationNetworkClient
    private var currentTask: Task<Void, Error>?

    init(items: [Date : Location] = [Date: Location](), network: any LocationNetworkClient,limit: Int = 10) {
        self.items = items
        self.network = network
        self.limit = limit
    }
    
    func add(location: Location) async throws {
        // add location, when reach specific threshold inform someone to start uploading to offload some data.
        items[location.date] = location

        if items.count > limit {
            try await uploadOldest()
        }
    }

    private func uploadOldest() async throws {
        // Prevent re-entry if there's an ongoing task
        if let currentTask = currentTask {
            return try await currentTask.value
        }
        
        currentTask = Task {
            defer { currentTask = nil }
            // Sort locations by key (date) and get the oldest `limit` locations
            let sortedLocations = items.sorted { $0.key < $1.key }
            let toUploadLocations = Array(sortedLocations.prefix(limit))
            
            for (date, location) in toUploadLocations {
                try await network.update(location)
                // Remove uploaded locations from cache
                items[date] = nil
            }
        }
        
        try await currentTask?.value
    }
    
    func uploadLatest() async throws {
        guard let latest = items.keys.max(), let location = items[latest] else { return }
        try await network.update(location)
        items[latest] = nil
    }
}
