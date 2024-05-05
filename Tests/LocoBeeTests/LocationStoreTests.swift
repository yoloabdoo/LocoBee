import XCTest
@testable import LocoBee

final class LocationStoreTests: XCTestCase {

    private var mockNetworkClient: MockLocationNetworkClient!
    private var locationStore: LocationStore!
    
    override func setUp() {
        super.setUp()
        mockNetworkClient = MockLocationNetworkClient()
        locationStore = LocationStore(items: [:], network: mockNetworkClient, limit: 3)
    }
    
    override func tearDown() {
        locationStore = nil
        mockNetworkClient = nil
        super.tearDown()
    }
}

extension LocationStoreTests {
    func testAddLocation_ShouldNotTriggerUpload_WhenUnderLimit() async throws {
        let location1 = Location(latitude: 37.7749, longitude: -122.4194)
        let location2 = Location(latitude: 40.7128, longitude: -74.0060)
        
        try await locationStore.add(location: location1)
        try await locationStore.add(location: location2)
        
        XCTAssertEqual(mockNetworkClient.updateCallCount, 0)
    }
    
    func testAddLocation_ShouldTriggerUpload_WhenExceedingLimit() async throws {
        let location1 = Location(latitude: 37.7749, longitude: -122.4194)
        let location2 = Location(latitude: 40.7128, longitude: -74.0060, date: Date().addingTimeInterval(1))
        let location3 = Location(latitude: 34.0522, longitude: -118.2437, date: Date().addingTimeInterval(2))
        let location4 = Location(latitude: 51.5074, longitude: -0.1278, date: Date().addingTimeInterval(3))
        
        try await locationStore.add(location: location1)
        try await locationStore.add(location: location2)
        try await locationStore.add(location: location3)
        try await locationStore.add(location: location4)
        
        XCTAssertEqual(mockNetworkClient.updateCallCount, 3)
    }
    
    func testUploadOldest_ShouldHandleNetworkError() async throws {
        mockNetworkClient.shouldThrowError = true
        
        let location1 = Location(latitude: 37.7749, longitude: -122.4194)
        let location2 = Location(latitude: 40.7128, longitude: -74.0060, date: Date().addingTimeInterval(1))
        let location3 = Location(latitude: 34.0522, longitude: -118.2437, date: Date().addingTimeInterval(2))
        let location4 = Location(latitude: 51.5074, longitude: -0.1278, date: Date().addingTimeInterval(3))
        
        
        do {
            try await locationStore.add(location: location1)
            try await locationStore.add(location: location2)
            try await locationStore.add(location: location3)
            try await locationStore.add(location: location4)
            XCTFail("Error needs to be thrown")
        } catch {
            XCTAssertTrue(error is URLSessionAPIClient.ClientError)
        }
    }
    
    func testUploadOldest_ShouldRemoveSuccessfullyUploadedLocations() async throws {
        let location1 = Location(latitude: 37.7749, longitude: -122.4194)
        let location2 = Location(latitude: 40.7128, longitude: -74.0060, date: Date().addingTimeInterval(1))
        let location3 = Location(latitude: 34.0522, longitude: -118.2437, date: Date().addingTimeInterval(2))
        let location4 = Location(latitude: 51.5074, longitude: -0.1278, date: Date().addingTimeInterval(3))
        
        try await locationStore.add(location: location1)
        try await locationStore.add(location: location2)
        try await locationStore.add(location: location3)
        try await locationStore.add(location: location4)
        
        XCTAssertEqual(mockNetworkClient.updateCallCount, 3)
    }
    
    func generateRandomLocations(count: Int) -> [Location] {
        var locations = [Location]()
        
        for _ in 0..<count {
            let randomLatitude = Double.random(in: -90...90)
            let randomLongitude = Double.random(in: -180...180)
            let location = Location(latitude: randomLatitude, longitude: randomLongitude)
            locations.append(location)
        }
        
        return locations
    }

}

class MockLocationNetworkClient: LocationNetworkClient{
    var updateCallCount = 0
    var shouldThrowError = false
    func update(_ location: Location) async throws -> MessageResponse {
        updateCallCount += 1
        if shouldThrowError {
            throw URLSessionAPIClient.ClientError.invalidResponse
        }
        return MessageResponse(message: "Updated")
    }
}
