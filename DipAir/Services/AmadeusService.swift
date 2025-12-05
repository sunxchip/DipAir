import Foundation

class AmadeusService {
    static let shared = AmadeusService()
    private var accessToken: String?
    private var tokenExpiry: Date?
    
    private let baseURL =
    "test.api.amadeus.com"
    
    private init() {}
    
    func authenticate() async throws {
        guard tokenExpiry == nil || Date() > tokenExpiry! else { return }
        
        let url = URL(string: "\(baseURL)/v1/security/oauth2/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let body = "grant_type=client_credentials&client_id=\(APIConfiguration.apiKey)&client_secret=\(APIConfiguration.apiSecret)"
        request.httpBody = body.data(using: .utf8)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(TokenResponse.self, from: data)
        
        accessToken = response.access_token
        tokenExpiry = Date().addingTimeInterval(TimeInterval(response.expires_in))
    }
    
    func searchFlightInspirations(origin: String, departureDate: String? = nil) async throws -> [FlightDeal] {
        try await authenticate()
        
        guard let token = accessToken else { throw APIError.noToken }
        
        var components = URLComponents(string: "\(baseURL)/v1/shopping/flight-destinations")!
        components.queryItems = [
            URLQueryItem(name: "origin", value: origin),
            URLQueryItem(name: "maxPrice", value: "1000000"),
            URLQueryItem(name: "viewBy", value: "WEEK")
        ]
        
        if let date = departureDate {
            components.queryItems?.append(URLQueryItem(name: "departureDate", value: date))
        }
        
        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(FlightInspirationResponse.self, from: data)
        
        return response.data.map { item in
            let weekLabel = formatWeekLabel(from: item.departureDate)
            return FlightDeal(
                origin: origin,
                destination: item.destination,
                destinationName: getDestinationName(code: item.destination),
                departureDate: item.departureDate,
                returnDate: item.returnDate,
                price: Double(item.price.total) ?? 0,
                currency: "KRW",
                weekLabel: weekLabel
            )
        }
    }
    
    private func formatWeekLabel(from dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return dateString }
        
        let calendar = Calendar.current
        let weekOfYear = calendar.component(.weekOfYear, from: date)
        let month = calendar.component(.month, from: date)
        return "\(month)월 \(weekOfYear)주차"
    }
    
    private func getDestinationName(code: String) -> String {
        let destinations: [String: String] = [
            "NRT": "도쿄(나리타)", "HND": "도쿄(하네다)", "KIX": "오사카",
            "NGO": "나고야", "FUK": "후쿠오카", "BKK": "방콕",
            "HKT": "푸켓", "SGN": "호치민", "HAN": "하노이",
            "DAD": "다낭", "SIN": "싱가포르", "KUL": "쿠알라룸푸르",
            "MNL": "마닐라", "CEB": "세부", "HKG": "홍콩",
            "TPE": "타이베이", "PEK": "베이징", "PVG": "상하이",
            "SYD": "시드니", "MEL": "멜버른", "LAX": "로스앤젤레스",
            "SFO": "샌프란시스코", "JFK": "뉴욕", "LHR": "런던",
            "CDG": "파리", "FCO": "로마", "BCN": "바르셀로나"
        ]
        return destinations[code] ?? code
    }
}

struct TokenResponse: Codable {
    let access_token: String
    let expires_in: Int
}

struct FlightInspirationResponse: Codable {
    let data: [FlightDestination]
}

struct FlightDestination: Codable {
    let destination: String
    let departureDate: String
    let returnDate: String
    let price: Price
}

struct Price: Codable {
    let total: String
}

enum APIError: Error {
    case noToken
    case invalidResponse
}
