import Foundation

// MARK: - 에러 정의

enum APIError: Error {
    case noToken
    case invalidResponse(status: Int, body: String)
}

// MARK: - 공통 DTO

struct TokenResponse: Codable {
    let access_token: String
    let expires_in: Int
    let token_type: String
}

// Flight Inspiration Search
struct FlightInspirationResponse: Codable {
    let data: [FlightDestination]
}

struct FlightDestination: Codable {
    let type: String?
    let origin: String?
    let destination: String
    let departureDate: String
    let returnDate: String
    let price: FlightPrice
    let links: FlightDestinationLinks?
}

struct FlightPrice: Codable {
    let total: String
    let currency: String?
}

struct FlightDestinationLinks: Codable {
    let flightDates: String?
    let flightOffers: String?
}

// Flight Cheapest Date Search
struct FlightDateResponse: Codable {
    let data: [FlightDateResult]
}

struct FlightDateResult: Codable {
    let type: String?
    let origin: String?
    let destination: String?
    let departureDate: String
    let returnDate: String?
    let price: FlightPrice
}

// MARK: - AmadeusService

final class AmadeusService {
    static let shared = AmadeusService()
    private init() {}

    private let baseURL = URL(string: "https://test.api.amadeus.com")!

    private var accessToken: String?
    private var tokenExpiry: Date?
}

// MARK: - 공개 API

extension AmadeusService {

    /// Flight Inspiration Search
    /// origin + maxPrice만 던져서 테스트 서버 에러를 최소화
    func searchFlightInspirations(
        origin: String,
        maxPrice: Int
    ) async throws -> [FlightDestination] {

        try await authenticateIfNeeded()
        guard let token = accessToken else { throw APIError.noToken }

        var components = URLComponents(
            url: baseURL.appendingPathComponent("/v1/shopping/flight-destinations"),
            resolvingAgainstBaseURL: false
        )!

        components.queryItems = [
            URLQueryItem(name: "origin", value: origin),
            URLQueryItem(name: "maxPrice", value: String(maxPrice))
            // viewBy, departureDate 등은 테스트 서버에서 500을 많이 내서 일단 제거
        ]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {

            let body = String(data: data, encoding: .utf8) ?? ""
            print(" Flight Inspiration API error (\( (response as? HTTPURLResponse)?.statusCode ?? -1 )):")
            print(body)
            throw APIError.invalidResponse(
                status: (response as? HTTPURLResponse)?.statusCode ?? -1,
                body: body
            )
        }

        do {
            let decoded = try JSONDecoder().decode(FlightInspirationResponse.self, from: data)
            return decoded.data
        } catch {
            let body = String(data: data, encoding: .utf8) ?? ""
            print(" Decoding error:", error)
            print(" Raw JSON:", body)
            throw error
        }
    }

    /// Flight Cheapest Date Search
    func searchFlightDates(
        origin: String,
        destination: String,
        maxPrice: Int
    ) async throws -> [FlightDateResult] {

        try await authenticateIfNeeded()
        guard let token = accessToken else { throw APIError.noToken }

        var components = URLComponents(
            url: baseURL.appendingPathComponent("/v1/shopping/flight-dates"),
            resolvingAgainstBaseURL: false
        )!

        // 공식 예제 링크 형식을 최대한 따라감
        components.queryItems = [
            URLQueryItem(name: "origin", value: origin),
            URLQueryItem(name: "destination", value: destination),
            // 최소/최대 출발일 – 너무 미래 날짜 주면 테스트 데이터가 없어서 오류 날 수 있어서
            // 여기서는 아예 생략해서 서버 기본값 사용
            URLQueryItem(name: "oneWay", value: "false"),
            URLQueryItem(name: "duration", value: "1,15"),
            URLQueryItem(name: "nonStop", value: "false"),
            URLQueryItem(name: "viewBy", value: "DURATION")
        ]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {

            let body = String(data: data, encoding: .utf8) ?? ""
            print(" Flight Dates API error (\( (response as? HTTPURLResponse)?.statusCode ?? -1 )):")
            print(body)
            throw APIError.invalidResponse(
                status: (response as? HTTPURLResponse)?.statusCode ?? -1,
                body: body
            )
        }

        let decoded = try JSONDecoder().decode(FlightDateResponse.self, from: data)
        return decoded.data
    }
}

// MARK: - 인증

private extension AmadeusService {

    func authenticateIfNeeded() async throws {
        // 토큰이 남아 있으면 재사용
        if let expiry = tokenExpiry, expiry > Date() {
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

        // 네가 curl로 쓰던 형식 그대로
        let bodyString = [
            "grant_type=client_credentials",
            "client_id=\(APIConfiguration.apiKey)",
            "client_secret=\(APIConfiguration.apiSecret)"
        ].joined(separator: "&")

        request.httpBody = bodyString.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {

            let body = String(data: data, encoding: .utf8) ?? ""
            print(" Auth error (\( (response as? HTTPURLResponse)?.statusCode ?? -1 )):")
            print(body)
            throw APIError.invalidResponse(
                status: (response as? HTTPURLResponse)?.statusCode ?? -1,
                body: body
            )
        }

        let decoded = try JSONDecoder().decode(TokenResponse.self, from: data)
        accessToken = decoded.access_token

        // 30분짜리 토큰이니까 1분 여유 두고 만료 처리
        tokenExpiry = Date().addingTimeInterval(TimeInterval(decoded.expires_in - 60))

        print("Amadeus 토큰 발급 성공, \(decoded.expires_in)s 유효")
    }
}
