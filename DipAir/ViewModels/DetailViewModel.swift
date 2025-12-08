import Foundation
import UserNotifications

@MainActor
class DetailViewModel: ObservableObject {

    @Published var priceHistory: [PriceHistory] = []
    @Published var threshold: Double = 600_000      // 임계가
    @Published var isAlertActive: Bool = false
    @Published var isLoading: Bool = false

    // 통계
    @Published var averagePrice: Double = 0
    @Published var minPrice: Double = 0
    @Published var maxPrice: Double = 0
    @Published var lastPriceDiffPercent: Double = 0 // 마지막 값이 평균보다 몇 % 낮은지

    let deal: FlightDeal
    private let service = AmadeusService.shared

    init(deal: FlightDeal) {
        self.deal = deal
    }

    /// 4~8주치 가격 히스토리 로드 (Flight Cheapest Date Search 기반)
    func loadPriceHistory() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let raw = try await service.searchFlightDates(
                origin: deal.origin,
                destination: deal.destination,
                maxPrice: Int(threshold)
            )

            if raw.isEmpty {
                generateDummyHistory()
                return
            }

            priceHistory = buildHistory(from: raw)
            updateStats()

        } catch {
            print(" Detail price history error:", error)
            generateDummyHistory()
        }
    }

    // MARK: - 알림

    func checkThresholdAndScheduleNotification() {
        guard let latest = priceHistory.last else { return }

        if latest.price <= threshold {
            scheduleNotification(currentPrice: latest.price)
            isAlertActive = true
        } else {
            isAlertActive = false
        }
    }

    private func scheduleNotification(currentPrice: Double) {
        let content = UNMutableNotificationContent()
        content.title = "\(deal.destinationName) 항공권 알림"
        content.body = "가격이 \(Int(currentPrice))원으로 임계가 이하로 떨어졌어요."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 1,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    // MARK: - 히스토리 빌드 / 통계

    private func buildHistory(from raw: [FlightDateResult]) -> [PriceHistory] {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let calendar = Calendar.current

        let sorted = raw.sorted {
            let d1 = df.date(from: $0.departureDate) ?? .distantPast
            let d2 = df.date(from: $1.departureDate) ?? .distantPast
            return d1 < d2
        }

        let sliced = Array(sorted.prefix(8)) // 최대 8개만

        return sliced.enumerated().map { index, item in
            let date = df.date(from: item.departureDate) ?? Date()
            let comps = calendar.dateComponents([.month, .weekOfMonth], from: date)

            let label = "\(comps.month ?? 0)월 \(comps.weekOfMonth ?? (index+1))주"
            let price = Double(item.price.total) ?? 0

            return PriceHistory(
                weekNumber: index + 1,
                weekLabel: label,
                price: price
            )
        }
    }

    private func updateStats() {
        guard !priceHistory.isEmpty else { return }

        let prices = priceHistory.map { $0.price }
        guard let min = prices.min(), let max = prices.max() else { return }

        let avg = prices.reduce(0, +) / Double(prices.count)
        averagePrice = avg
        minPrice = min
        maxPrice = max

        if let last = prices.last {
            lastPriceDiffPercent = (avg == 0) ? 0 : (avg - last) / avg * 100
        }
    }

    private func generateDummyHistory() {
        var history: [PriceHistory] = []
        let calendar = Calendar.current
        let today = Date()

        for i in 0..<8 {
            guard let date = calendar.date(byAdding: .weekOfYear, value: -i, to: today) else { continue }

            let comps = calendar.dateComponents([.month, .weekOfMonth], from: date)
            let label = "\(comps.month ?? 0)월 \(comps.weekOfMonth ?? (i + 1))주"

            let base = deal.price
            let variance = Double.random(in: 0.85...1.15)
            let price = base * variance

            history.append(
                PriceHistory(
                    weekNumber: i + 1,
                    weekLabel: label,
                    price: price
                )
            )
        }

        priceHistory = history.reversed()
        updateStats()
    }
}
