import Foundation
import UserNotifications

@MainActor
class DetailViewModel: ObservableObject {

    @Published var priceHistory: [PriceHistory] = []
    @Published var threshold: Double = 600_000
    @Published var isAlertActive: Bool = false
    @Published var isLoading: Bool = false

    // 선택 사항: 통계 값 (원하면 UI에서 써도 됨)
    @Published var minPrice: Double?
    @Published var maxPrice: Double?
    @Published var averagePrice: Double?

    let deal: FlightDeal
    private let service = AmadeusService.shared

    init(deal: FlightDeal) {
        self.deal = deal
    }

    /// 최근 4~8주 구간 가격 히스토리 로드
    /// - 실제 API 먼저 시도, 실패하면 랜덤 더미 데이터
    func loadPriceHistory() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let raw = try await service.searchFlightDates(
                origin: deal.origin,
                destination: deal.destination,
                weeksFromNow: 4...8,
                maxPrice: Int(threshold)
            )

            if raw.isEmpty {
                generateDummyHistory()
                return
            }

            priceHistory = buildHistory(from: raw)
            updateStats()
            return
        } catch {
            print(" Flight Dates 로드 실패:", error)
        }

        // 에러난 경우 더미 데이터
        generateDummyHistory()
    }

    // MARK: - 알림 관련

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

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

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

        // 출발일 기준 오름차순 정렬
        let sorted = raw.sorted { lhs, rhs in
            let d1 = df.date(from: lhs.departureDate) ?? .distantPast
            let d2 = df.date(from: rhs.departureDate) ?? .distantPast
            return d1 < d2
        }

        // 최대 8개까지만 사용
        let sliced = Array(sorted.prefix(8))

        return sliced.enumerated().map { index, item in
            let date = df.date(from: item.departureDate) ?? Date()
            let comps = calendar.dateComponents([.month, .weekOfMonth], from: date)
            let month = comps.month ?? 0
            let week = comps.weekOfMonth ?? 0
            let label = "\(month)월 \(week)주"

            return PriceHistory(
                weekNumber: index,
                weekLabel: label,
                price: Double(item.price.total) ?? 0
            )
        }
    }

    private func updateStats() {
        guard !priceHistory.isEmpty else {
            minPrice = nil
            maxPrice = nil
            averagePrice = nil
            return
        }

        let prices = priceHistory.map { $0.price }
        minPrice = prices.min()
        maxPrice = prices.max()
        averagePrice = prices.reduce(0, +) / Double(prices.count)
    }

    // MARK: - 더미 데이터 (API 실패 시)

    private func generateDummyHistory() {
        var history: [PriceHistory] = []
        let calendar = Calendar.current
        let today = Date()

        for week in 0..<8 {
            guard let weekDate = calendar.date(byAdding: .weekOfYear, value: -week, to: today)
            else { continue }

            let weekNum = calendar.component(.weekOfYear, from: weekDate)
            let month = calendar.component(.month, from: weekDate)

            let basePrice = deal.price
            let variance = Double.random(in: 0.85...1.15)
            let price = basePrice * variance

            let label = "\(month)월 \(weekNum)주"

            history.append(
                PriceHistory(
                    weekNumber: weekNum,
                    weekLabel: label,
                    price: price
                )
            )
        }

        priceHistory = history.reversed()
        updateStats()
    }
}
