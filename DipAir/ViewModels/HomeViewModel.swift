import Foundation

@MainActor
final class HomeViewModel: ObservableObject {

    @Published var selectedAirportCode: String = "ICN"
    @Published var budget: Int = 500_000

    @Published var primaryDeals: [FlightDeal] = []   // 상단 추천 리스트
    @Published var secondaryDeals: [FlightDeal] = [] // 그 외 옵션

    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let service = AmadeusService.shared

    func load() async {
        isLoading = true
        errorMessage = nil

        do {
            let originForAPI = selectedAirportCode

            let raw = try await service.searchFlightInspirations(
                origin: originForAPI,
                maxPrice: budget
            )

            print("🔍 Flight Inspiration 결과 개수:", raw.count)

            if raw.isEmpty {
                useDummyDeals()
                errorMessage = "표시할 항공권이 없어 데모 데이터를 보여주고 있어요."
                isLoading = false
                return
            }

            let sorted = raw.sorted {
                (Double($0.price.total) ?? .greatestFiniteMagnitude) <
                (Double($1.price.total) ?? .greatestFiniteMagnitude)
            }

            let first = Array(sorted.prefix(10))
            let second = Array(sorted.dropFirst(10).prefix(10))

            primaryDeals = first.map {
                makeDeal(from: $0, label: "가까운 일정")
            }

            secondaryDeals = second.map {
                makeDeal(from: $0, label: "다른 일정")
            }

        } catch let apiError as APIError {
            switch apiError {
            case .noToken:
                errorMessage = "Amadeus 토큰을 받지 못했습니다. API 키/시크릿을 다시 확인해 주세요."
            case .invalidResponse(let status, let body):
                print("❌ APIError.invalidResponse status=\(status)")
                print(body)

                // 500 / 429 처럼 서버쪽 문제는 데모 데이터로 채워서라도 보여주기
                if status == 500 || status == 429 {
                    useDummyDeals()
                    errorMessage = "Amadeus 테스트 서버에서 오류가 발생해\n데모 데이터를 대신 보여주고 있어요."
                } else {
                    errorMessage = "Amadeus 서버에서 유효하지 않은 응답을 받았습니다. (status \(status))"
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - 변환 / 더미

    private func makeDeal(from item: FlightDestination, label: String) -> FlightDeal {
        let priceValue = Double(item.price.total) ?? 0
        return FlightDeal(
            origin: item.origin ?? selectedAirportCode,
            destination: item.destination,
            destinationName: item.destination,       // 일단 공항 코드 그대로 사용
            departureDate: item.departureDate,
            returnDate: item.returnDate,
            price: priceValue,
            currency: item.price.currency ?? "EUR",
            weekLabel: label
        )
    }

    private func useDummyDeals() {
        let sampleDestinations = ["NRT", "CTS", "KIX", "FUK", "OKA", "BKK", "TPE", "HKG", "SIN", "BOS"]

        primaryDeals = sampleDestinations.enumerated().map { index, code in
            FlightDeal(
                origin: selectedAirportCode,
                destination: code,
                destinationName: code,
                departureDate: "2025-01-\(String(format: "%02d", index + 5))",
                returnDate: "2025-01-\(String(format: "%02d", index + 8))",
                price: Double(250_000 + index * 25_000),
                currency: "KRW",
                weekLabel: "가까운 일정"
            )
        }

        secondaryDeals = sampleDestinations.enumerated().map { index, code in
            FlightDeal(
                origin: selectedAirportCode,
                destination: code,
                destinationName: code,
                departureDate: "2025-02-\(String(format: "%02d", index + 5))",
                returnDate: "2025-02-\(String(format: "%02d", index + 8))",
                price: Double(300_000 + index * 30_000),
                currency: "KRW",
                weekLabel: "다른 일정"
            )
        }
    }
}
