import Foundation

struct APIConfiguration {
    static var apiKey: String {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let key = dict["API_KEY"] as? String else {
            fatalError("API_KEY not found in Secrets.plist")
        }
        return key
    }
    
    static var apiSecret: String {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let secret = dict["API_SECRET"] as? String else {
            fatalError("API_SECRET not found in Secrets.plist")
        }
        return secret
    }
}
