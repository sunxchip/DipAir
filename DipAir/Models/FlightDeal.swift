import Foundation

struct FlightDeal: Identifiable {
    let id = UUID()

    let origin: String          // 출발 공항 코드 (ICN / GMP / PUS 등)
    let destination: String     // 도착 공항 코드
    let destinationName: String // 리스트/상세에서 쓸 이름
    let departureDate: String   // "yyyy-MM-dd"
    let returnDate: String      // "yyyy-MM-dd"
    let price: Double           // 숫자 가격
    let currency: String        // 통화
    let weekLabel: String       // "이번 주", "다음 주" 등
}

// MARK: - 샘플 데이터 (Demo / Preview 용)

extension FlightDeal {
    static let mockThisWeek: [FlightDeal] = [
        FlightDeal(
            origin: "ICN",
            destination: "NRT",
            destinationName: "도쿄",
            departureDate: "2025-12-15",
            returnDate: "2025-12-18",
            price: 420_000,
            currency: "KRW",
            weekLabel: "이번 주"
        ),
        FlightDeal(
            origin: "ICN",
            destination: "HKG",
            destinationName: "홍콩",
            departureDate: "2025-12-16",
            returnDate: "2025-12-19",
            price: 380_000,
            currency: "KRW",
            weekLabel: "이번 주"
        )
    ]

    static let mockNextWeek: [FlightDeal] = [
        FlightDeal(
            origin: "ICN",
            destination: "BKK",
            destinationName: "방콕",
            departureDate: "2025-12-22",
            returnDate: "2025-12-27",
            price: 510_000,
            currency: "KRW",
            weekLabel: "다음 주"
        ),
        FlightDeal(
            origin: "GMP",
            destination: "KIX",
            destinationName: "오사카",
            departureDate: "2025-12-23",
            returnDate: "2025-12-25",
            price: 330_000,
            currency: "KRW",
            weekLabel: "다음 주"
        )
    ]
}
