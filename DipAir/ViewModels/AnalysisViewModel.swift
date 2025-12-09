import Foundation

struct LeadTimePoint: Identifiable {
    let id = UUID()
    let label: String      // "D-30" 같은 표기
    let daysBefore: Int
    let price: Double
}

@MainActor
final class AnalysisViewModel: ObservableObject {

    // 주간 가격 히스토리 (4~8주)
    @Published var priceHistory: [PriceHistory] = []

    // 통계 값
    @Published var minPrice: Double = 0
    @Published var maxPrice: Double = 0
    @Published var averagePrice: Double = 0
    @Published var lastWeekDiffPercent: Double?

    // 적정 예매 시기 라벨
    @Published var recommendedLeadTimeLabel: String = ""

    // 리드타임 비교용 (D-60 / D-45 / D-30)
    @Published var leadTimePoints: [LeadTimePoint] = []

    // 후회지수 계산용
    @Published var myBookingPriceText: String = ""
    @Published var regretIndex: Double?        // 내 예매가 - 현재 최저가

    init() {
        generateDemoData()
    }

    /// 데모용 데이터 생성 (API 안 쓰고 랜덤 편차로 만듦)
    func generateDemoData() {
        let basePrice = 500_000.0
        let calendar = Calendar.current
        let today = Date()

        var history: [PriceHistory] = []

        // 8주 전 ~ 이번 주
        for weekOffset in (0..<8).reversed() {
            let weekDate = calendar.date(byAdding: .weekOfYear,
                                         value: -weekOffset,
                                         to: today) ?? today

            let weekNum = calendar.component(.weekOfYear, from: weekDate)
            let month = calendar.component(.month, from: weekDate)
            let variance = Double.random(in: 0.8...1.2)
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

        priceHistory = history
        recalcStats()

        // 리드타임 비교 (D-60 / D-45 / D-30)
        leadTimePoints = [
            LeadTimePoint(label: "D-60", daysBefore: 60, price: basePrice * 0.92),
            LeadTimePoint(label: "D-45", daysBefore: 45, price: basePrice * 0.85),
            LeadTimePoint(label: "D-30", daysBefore: 30, price: basePrice * 0.95)
        ]
    }

    /// min / max / 평균 / 전주 대비 % / 적정 예매 시기 계산
    func recalcStats() {
        guard !priceHistory.isEmpty else { return }

        let prices = priceHistory.map { $0.price }
        minPrice = prices.min() ?? 0
        maxPrice = prices.max() ?? 0
        averagePrice = prices.reduce(0, +) / Double(prices.count)

        if priceHistory.count >= 2 {
            let last = priceHistory[priceHistory.count - 1].price
            let prev = priceHistory[priceHistory.count - 2].price
            lastWeekDiffPercent = ((last - prev) / prev) * 100
        } else {
            lastWeekDiffPercent = nil
        }

        // 가장 쌌던 주를 기준으로 적정 예매 시기 라벨 만들기 (대충 주 단위)
        if let minIndex = prices.firstIndex(of: minPrice) {
            let weeksFromNow = priceHistory.count - 1 - minIndex
            switch weeksFromNow {
            case 0...1:
                recommendedLeadTimeLabel = "출발 1~2주 전"
            case 2...3:
                recommendedLeadTimeLabel = "출발 3~4주 전"
            default:
                recommendedLeadTimeLabel = "출발 5주 이상 전"
            }
        }
    }

    /// 후회지수 = 내 예매가 - 현재 최저가
    func updateRegretIndex() {
        let cleaned = myBookingPriceText
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: " ", with: "")

        guard let myPrice = Double(cleaned),
              let latest = priceHistory.last?.price else {
            regretIndex = nil
            return
        }

        regretIndex = myPrice - latest
    }
}
