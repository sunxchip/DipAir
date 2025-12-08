import Foundation

struct PriceHistory: Identifiable {
    let id = UUID()
    let weekNumber: Int      // 주 번호
    let weekLabel: String    // "11월 2주" 같은 표시 텍스트
    let price: Double        // 그 주의 최저가
}
