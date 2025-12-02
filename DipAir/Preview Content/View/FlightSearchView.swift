import SwiftUI
struct FlightSearchView: View {
    @StateObject private var viewModel = FlightViewModel()
    
    var body: some View {
        NavigationStack {
            VStack {
                // 출발지 선택 피커
                Picker("출발지", selection: $viewModel.selectedOrigin) {
                    ForEach(AirportCode.allCases) { code in
                        Text(code.rawValue).tag(code)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                // 추천 리스트
                List(viewModel.recommendations) { flight in
                    NavigationLink(destination: FlightDetailView(recommendation: flight, viewModel: viewModel)) {
                        HStack {
                            Image(systemName: flight.image)
                                .font(.largeTitle)
                                .frame(width: 50)
                            
                            VStack(alignment: .leading) {
                                Text(flight.destination)
                                    .font(.headline)
                                
                                if flight.isRecommended {
                                    Text("이번주가 \(flight.priceDifference * -1)원 더 저렴해요! 👍")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                } else {
                                    Text("다음주가 더 저렴할 수 있어요")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            Spacer()
                            
                            Text("\(flight.thisWeekPrice)원~")
                                .bold()
                        }
                        .padding(.vertical, 8)
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("최저가 항공권 ✈️")
        }
    }
}