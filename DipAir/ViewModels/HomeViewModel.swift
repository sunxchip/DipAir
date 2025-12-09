import Foundation

@MainActor
class HomeViewModel: ObservableObject {

    // MARK: - 입력 상태

    @Published var selectedAirportCode: String = "ICN"
    let airportOptions: [String] = ["ICN", "GMP", "PUS"]

    /// 사용자가 직접 입력하는 IATA 코드 (예: MAD, BOS, LHR)
    @Published var customOriginCode: String = ""

    /// 예산 (슬라이더)
    @Published var budget: Double = 500_000

    // MARK: - 결과 리스트

    @Published var thisWeekDeals: [FlightDeal] = []
    @Published var nextWeekDeals: [FlightDeal] = []

    // MARK: - 상태

    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isUsingDemoData: Bool = false
    @Published var demoReason: String?

    private let service = AmadeusService.shared

    var effectiveOriginCode: String {
        let trimmed = customOriginCode.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? selectedAirportCode : trimmed.uppercased()
    }

    /// 오늘 날짜를 "yyyy-MM-dd" 포맷으로 (과거 날짜 넣으면 400 떠서)
    static var defaultDepartureDateString: String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df.string(from: Date())
    }

    
    // MARK: - 날짜 포맷터 (헤더 "오늘 날짜" 표시용)
    static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy년 M월 d일 (E)"   // ex) 2025년 12월 9일 (화)
        df.locale = Locale(identifier: "ko_KR")
        df.timeZone = .current
        return df
    }()

    // MARK: - 로드

    func load() async {
        // Xcode Preview에서는 네트워크 타지 말고 더미 데이터만
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            await loadPreviewData()
            return
        }

        isLoading = true
        errorMessage = nil
        isUsingDemoData = false
        demoReason = nil

        do {
            let raw = try await service.searchFlightInspirations(
                origin: effectiveOriginCode,
                departureDate: Self.defaultDepartureDateString,
                maxPrice: String(Int(budget))
            )

            var deals = raw.map { dest -> FlightDeal in
                let priceDouble = Double(dest.price.total) ?? 0
                return FlightDeal(
                    origin: dest.origin,
                    destination: dest.destination,
                    destinationName: dest.destination, // 나중에 공항명/도시명 맵핑 가능
                    departureDate: dest.departureDate,
                    returnDate: dest.returnDate ?? "",
                    price: priceDouble,
                    currency: dest.price.currency ?? "EUR",
                    weekLabel: "추천"
                )
            }

            // 날짜순 정렬
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd"
            deals.sort { a, b in
                let da = df.date(from: a.departureDate) ?? .distantFuture
                let db = df.date(from: b.departureDate) ?? .distantFuture
                return da < db
            }

            // 앞 5개 = 이번 주, 뒤 5개 = 다음 주 느낌
            thisWeekDeals = Array(deals.prefix(5))
            nextWeekDeals = Array(deals.dropFirst(5).prefix(5))

            if thisWeekDeals.isEmpty && nextWeekDeals.isEmpty {
                useDemoData(reason: "조건에 맞는 항공권이 없어 데모 데이터를 사용합니다.")
            }

        } catch {
            print(" Flight Inspiration error:", error)
            useDemoData(reason: "Amadeus 서버 오류로 데모 데이터를 사용합니다.")
            errorMessage = """
            Amadeus 서버에서 유효하지 않은 응답을 받았습니다.
            (자세한 내용은 Xcode 콘솔 로그 참고)
            """
        }

        isLoading = false
    }

    // MARK: - Demo & Preview

    private func useDemoData(reason: String) {
        thisWeekDeals = FlightDeal.mockThisWeek
        nextWeekDeals = FlightDeal.mockNextWeek
        isUsingDemoData = true
        demoReason = reason
    }

    private func loadPreviewData() async {
        await MainActor.run {
            thisWeekDeals = FlightDeal.mockThisWeek
            nextWeekDeals = FlightDeal.mockNextWeek
            isUsingDemoData = true
            demoReason = " "
        }
    }
}
