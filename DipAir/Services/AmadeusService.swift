import Foundation

// MARK: - Error

enum APIError: Error {
    case noToken
    case invalidResponse
}

// MARK: - OAuth DTO

struct TokenResponse: Decodable {
    let access_token: String
    let expires_in: Int
    let token_type: String
}

// MARK: - Flight Inspiration DTO (/v1/shopping/flight-destinations)

struct FlightInspirationResponse: Decodable {
    let data: [FlightDestination]
}

struct FlightDestination: Decodable, Identifiable {
    let type: String
    let origin: String
    let destination: String
    let departureDate: String
    let returnDate: String?
    let price: FlightPrice
    let links: FlightDestinationLinks?

    // JSON에는 id가 없어서, 안정적인 식별자를 직접 만들어줌
    var id: String {
        "\(origin)-\(destination)-\(departureDate)-\(returnDate ?? "")"
    }
}

struct FlightDestinationLinks: Decodable {
    let flightDates: String?
    let flightOffers: String?
}

struct FlightPrice: Decodable {
    let total: String
    let currency: String?
}

// MARK: - Flight Cheapest Date DTO (/v1/shopping/flight-dates)

struct FlightDatesResponse: Decodable {
    let data: [FlightDateResult]
}

struct FlightDateResult: Decodable {
    let type: String
    let origin: String
    let destination: String
    let departureDate: String
    let returnDate: String?
    let price: FlightPrice
    let links: FlightDateLinks?
}

struct FlightDateLinks: Decodable {
    let flightDestinations: String?
    let flightOffers: String?
}

// MARK: - Service

final class AmadeusService {
    static let shared = AmadeusService()
    private init() {}

    private let baseURL = URL(string: "https://test.api.amadeus.com")!

    private var accessToken: String?
    private var tokenExpiry: Date?
}

// MARK: - Public API

extension AmadeusService {

    /// Flight Inspiration Search
    func searchFlightInspirations(
        origin: String,
        departureDate: String? = nil,
        maxPrice: String = "600000"
    ) async throws -> [FlightDestination] {

        try await authenticateIfNeeded()
        guard let token = accessToken else { throw APIError.noToken }

        var components = URLComponents(
            url: baseURL.appendingPathComponent("/v1/shopping/flight-destinations"),
            resolvingAgainstBaseURL: false
        )!

        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "origin", value: origin),
            URLQueryItem(name: "maxPrice", value: maxPrice),
            URLQueryItem(name: "viewBy", value: "WEEK")
        ]

        // 과거 날짜면 보내지 않음 (400 방지)
        if let departureDate {
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd"
            if let date = df.date(from: departureDate) {
                let today = Calendar.current.startOfDay(for: Date())
                if date >= today {
                    queryItems.append(URLQueryItem(name: "departureDate", value: departureDate))
                }
            }
        }

        components.queryItems = queryItems

        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            print("❌ Flight Inspiration API error (\((response as? HTTPURLResponse)?.statusCode ?? 0)):")
            print(body)
            throw APIError.invalidResponse
        }

        do {
            let decoded = try JSONDecoder().decode(FlightInspirationResponse.self, from: data)
            return decoded.data
        } catch {
            let body = String(data: data, encoding: .utf8) ?? ""
            print("❌ Decoding error (flight-destinations):", error)
            print("👉 Raw JSON:", body)
            throw error
        }
    }

    /// Flight Cheapest Date Search
    func searchFlightDates(
        origin: String,
        destination: String,
        weeksFromNow range: ClosedRange<Int>,
        maxPrice: Int?
    ) async throws -> [FlightDateResult] {

        try await authenticateIfNeeded()
        guard let token = accessToken else { throw APIError.noToken }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        guard
            let start = calendar.date(byAdding: .weekOfYear, value: range.lowerBound, to: today),
            let end = calendar.date(byAdding: .weekOfYear, value: range.upperBound, to: today)
        else {
            return []
        }

        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let startString = df.string(from: start)
        let endString = df.string(from: end)

        var components = URLComponents(
            url: baseURL.appendingPathComponent("/v1/shopping/flight-dates"),
            resolvingAgainstBaseURL: false
        )!

        var items: [URLQueryItem] = [
            URLQueryItem(name: "origin", value: origin),
            URLQueryItem(name: "destination", value: destination),
            URLQueryItem(name: "departureDate", value: "\(startString),\(endString)"),
            URLQueryItem(name: "oneWay", value: "false"),
            URLQueryItem(name: "nonStop", value: "false"),
            URLQueryItem(name: "viewBy", value: "DURATION")
        ]

        if let maxPrice {
            items.append(URLQueryItem(name: "maxPrice", value: String(maxPrice)))
        }

        components.queryItems = items

        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            print("❌ Flight Dates API error (\((response as? HTTPURLResponse)?.statusCode ?? 0)):")
            print(body)
            throw APIError.invalidResponse
        }

        do {
            let decoded = try JSONDecoder().decode(FlightDatesResponse.self, from: data)
            return decoded.data
        } catch {
            let body = String(data: data, encoding: .utf8) ?? ""
            print("❌ Decoding error (flight-dates):", error)
            print("👉 Raw JSON:", body)
            throw error
        }
    }
}

// MARK: - Auth

private extension AmadeusService {

    func authenticateIfNeeded() async throws {
        // 아직 유효한 토큰이면 재사용
        if let expiry = tokenExpiry,
           let _ = accessToken,
           expiry > Date() {
            return
        }

        var request = URLRequest(
            url: baseURL.appendingPathComponent("/v1/security/oauth2/token")
        )
        request.httpMethod = "POST"
        request.setValue(
            "application/x-www-form-urlencoded",
            forHTTPHeaderField: "Content-Type"
        )

        let body = [
            "grant_type=client_credentials",
            "client_id=\(APIConfiguration.apiKey)",
            "client_secret=\(APIConfiguration.apiSecret)"
        ].joined(separator: "&")

        request.httpBody = body.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            let text = String(data: data, encoding: .utf8) ?? ""
            print("❌ Auth error:")
            print(text)
            throw APIError.invalidResponse
        }

        let decoded = try JSONDecoder().decode(TokenResponse.self, from: data)
        accessToken = decoded.access_token
        tokenExpiry = Date().addingTimeInterval(TimeInterval(decoded.expires_in - 60))

        print("✅ Amadeus 토큰 발급 완료 (유효 \(decoded.expires_in)초)")
    }
}
