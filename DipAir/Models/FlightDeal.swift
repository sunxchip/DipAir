import Foundation

struct FlightDeal: Identifiable {
    let id = UUID()
    let origin: String
    let destination: String
    let destinationName: String
    let departureDate: String
    let returnDate: String
    let price: Double
    let currency: String
    let weekLabel: String
}

struct PriceHistory: Identifiable {
    let id = UUID()
    let weekNumber: Int
    let weekLabel: String
    let price: Double
}

struct PriceAlert: Codable, Identifiable {
    let id: UUID
    let destination: String
    let threshold: Double
    let isActive: Bool
    let createdAt: Date
}
