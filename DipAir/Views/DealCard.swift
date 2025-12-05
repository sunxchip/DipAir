import SwiftUI

struct DealCard: View {
    let deal: FlightDeal
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(deal.destinationName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("\(deal.origin) → \(deal.destination)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(deal.weekLabel)
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("₩\(Int(deal.price).formatted())")
                    .font(.title3)
                    .bold()
                    .foregroundColor(.primary)
                
                Text("왕복")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}
