import SwiftUI
import UserNotifications
class FlightViewModel: ObservableObject {
    // 출발지 선택 (기본값: 인천)
    @Published var selectedOrigin: AirportCode = .ICN {
        didSet {
            fetchRecommendations() // 출발지 변경 시 데이터 갱신
        }
    }
    
    // 추천 목록
    @Published var recommendations: [FlightRecommendation] = []
    
    // 상세 화면용 주별 가격 데이터
    @Published var priceHistory: [WeeklyPrice] = []
    
    // 알림 설정 가격
    @Published var targetPrice: Double = 600000
    @Published var isAlertEnabled: Bool = false
    
    init() {
        fetchRecommendations()
        requestNotificationPermission()
    }
    
    // 데이터 가져오기 (시뮬레이션)
    func fetchRecommendations() {
        // 실제 앱에서는 API 호출이 들어갈 곳입니다.
        // 여기서는 더미 데이터를 생성합니다.
        
        self.recommendations = [
            FlightRecommendation(destination: "오사카(KIX)", thisWeekPrice: 250000, nextWeekPrice: 320000, image: "airplane"),
            FlightRecommendation(destination: "도쿄(NRT)", thisWeekPrice: 380000, nextWeekPrice: 350000, image: "tram.fill"), // 다음주가 더 쌈
            FlightRecommendation(destination: "방콕(BKK)", thisWeekPrice: 450000, nextWeekPrice: 550000, image: "leaf.fill")
        ]
    }
    
    // 상세 데이터 가져오기 (시뮬레이션)
    func fetchPriceHistory(for destination: String) {
        // 최근 8주 데이터 생성
        self.priceHistory = [
            WeeklyPrice(weekLabel: "4주전", price: 420000),
            WeeklyPrice(weekLabel: "3주전", price: 400000),
            WeeklyPrice(weekLabel: "2주전", price: 380000),
            WeeklyPrice(weekLabel: "1주전", price: 390000),
            WeeklyPrice(weekLabel: "이번주", price: 350000),
            WeeklyPrice(weekLabel: "다음주", price: 410000),
            WeeklyPrice(weekLabel: "2주후", price: 430000),
            WeeklyPrice(weekLabel: "3주후", price: 440000)
        ]
    }
    
    // 로컬 알림 권한 요청
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("알림 권한 오류: \(error.localizedDescription)")
            }
        }
    }
    
    // 가격 알림 설정
    func setPriceAlert(destination: String) {
        guard isAlertEnabled else { return }
        
        // 로컬 알림 콘텐츠 생성
        let content = UNMutableNotificationContent()
        content.title = "✈️ 가격 알림: \(destination)"
        content.body = "설정하신 \(Int(targetPrice))원 이하로 가격이 내려갔습니다!"
        content.sound = .default
        
        // 5초 후 알림 발송 (테스트용)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
}