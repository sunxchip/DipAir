import Foundation

struct FlightDeal: Identifiable {
    let id = UUID()

    let origin: String          // 출발 공항 코드 (ICN / GMP / PUS)
    let destination: String     // 도착 공항 코드
    let destinationName: String // 리스트/상세에서 쓸 이름
    let departureDate: String   // "yyyy-MM-dd"
    let returnDate: String      // "yyyy-MM-dd"
    let price: Double           // 숫자 가격
    let currency: String        // 통화
    let weekLabel: String       // "이번주", "다음주" 등
}

struct PriceAlert: Codable, Identifiable {
    let id: UUID
    let destination: String
    let threshold: Double
    let isActive: Bool
    let createdAt: Date
}
