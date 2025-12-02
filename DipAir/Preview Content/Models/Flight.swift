import Foundation
// 공항 코드 열거형 (출발지)
enum AirportCode: String, CaseIterable, Identifiable {
    case ICN = "인천(ICN)"
    case GMP = "김포(GMP)"
    case PUS = "김해(PUS)"
    
    var id: String { self.rawValue }
}
// 주간 최저가 정보
struct WeeklyPrice: Identifiable {
    let id = UUID()
    let weekLabel: String // 예: "11월 1주"
    let price: Int        // 최저가
}
// 항공권 추천 정보
struct FlightRecommendation: Identifiable {
    let id = UUID()
    let destination: String      // 목적지
    let thisWeekPrice: Int       // 이번주 최저가
    let nextWeekPrice: Int       // 다음주 최저가
    let image: String            // 목적지 이미지 (시스템 이미지 등)
    
    // 가격 차이 계산
    var priceDifference: Int {
        return nextWeekPrice - thisWeekPrice
    }
    
    // 추천 여부 (이번주가 더 싸면 추천)
    var isRecommended: Bool {
        return thisWeekPrice < nextWeekPrice
    }
}