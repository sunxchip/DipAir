import Foundation
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    @Published var selectedAirport: Airport = Airport.korean[0]
    @Published var thisWeekDeals: [FlightDeal] = []
    @Published var nextWeekDeals: [FlightDeal] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let service = AmadeusService.shared
    
    func loadDeals() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let calendar = Calendar.current
            let today = Date()
            
            // 이번주 시작일
            let thisWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
            let thisWeekString = formatDate(thisWeekStart)
            
            // 다음주 시작일
            let nextWeekStart = calendar.date(byAdding: .weekOfYear, value: 1, to: thisWeekStart)!
            let nextWeekString = formatDate(nextWeekStart)
            
            async let thisWeek = service.searchFlightInspirations(origin: selectedAirport.code, departureDate: thisWeekString)
            async let nextWeek = service.searchFlightInspirations(origin: selectedAirport.code, departureDate: nextWeekString)
            
            let (thisWeekResults, nextWeekResults) = try await (thisWeek, nextWeek)
            
            thisWeekDeals = thisWeekResults.sorted { $0.price < $1.price }.prefix(10).map { $0 }
            nextWeekDeals = nextWeekResults.sorted { $0.price < $1.price }.prefix(10).map { $0 }
            
        } catch {
            errorMessage = "데이터를 불러오는데 실패했습니다: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
