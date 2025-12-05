import Foundation
import UserNotifications

@MainActor
class DetailViewModel: ObservableObject {
    @Published var priceHistory: [PriceHistory] = []
    @Published var threshold: Double = 600000
    @Published var isAlertActive = false
    @Published var isLoading = false
    
    let deal: FlightDeal
    private let service = AmadeusService.shared
    
    init(deal: FlightDeal) {
        self.deal = deal
    }
    
    func loadPriceHistory() async {
        isLoading = true
        
        do {
            var history: [PriceHistory] = []
            let calendar = Calendar.current
            let today = Date()
            
            // 최근 8주 데이터 시뮬레이션 (실제로는 historical API 필요)
            for week in 0..<8 {
                let weekDate = calendar.date(byAdding: .weekOfYear, value: -week, to: today)!
                let weekNum = calendar.component(.weekOfYear, from: weekDate)
                let month = calendar.component(.month, from: weekDate)
                
                // 실제 앱에서는 historical API 호출
                let basePrice = deal.price
                let variance = Double.random(in: 0.85...1.15)
                let price = basePrice * variance
                
                history.append(PriceHistory(
                    weekNumber: weekNum,
                    weekLabel: "\(month)월 \(weekNum)주",
                    price: price
                ))
            }
            
            priceHistory = history.reversed()
            
        } catch {
            print("Failed to load price history: \(error)")
        }
        
        isLoading = false
    }
    
    func toggleAlert() {
        isAlertActive.toggle()
        
        if isAlertActive {
            requestNotificationPermission()
            scheduleNotification()
        } else {
            cancelNotification()
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("알림 권한 승인됨")
            }
        }
    }
    
    private func scheduleNotification() {
        let content = UNMutableNotificationContent()
        content.title = "🎉 가격 알림!"
        content.body = "\(deal.destinationName) 항공권이 ₩\(Int(deal.price).formatted())원으로 하락했습니다!"
        content.sound = .default
        
        // 매일 오전 9시에 체크 (실제로는 백그라운드 fetch 필요)
        var dateComponents = DateComponents()
        dateComponents.hour = 9
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: deal.destination, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func cancelNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [deal.destination])
    }
}
