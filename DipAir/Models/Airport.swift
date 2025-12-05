import Foundation

struct Airport: Identifiable, Hashable {
    let id = UUID()
    let code: String
    let name: String
    let city: String
    
    static let korean = [
        Airport(code: "ICN", name: "인천국제공항", city: "서울"),
        Airport(code: "GMP", name: "김포국제공항", city: "서울"),
        Airport(code: "PUS", name: "김해국제공항", city: "부산")
    ]
}
