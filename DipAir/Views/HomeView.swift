import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 출발지 선택
                    airportSelector
                    
                    // 이번주 최저가
                    dealSection(title: "이번주 최저가", deals: viewModel.thisWeekDeals)
                    
                    // 다음주 최저가
                    dealSection(title: "다음주 최저가", deals: viewModel.nextWeekDeals)
                }
                .padding()
            }
            .navigationTitle("항공권 최저가")
            .task {
                await viewModel.loadDeals()
            }
            .refreshable {
                await viewModel.loadDeals()
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                }
            }
        }
    }
    
    private var airportSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("출발지")
                .font(.headline)
            
            Picker("출발 공항", selection: $viewModel.selectedAirport) {
                ForEach(Airport.korean) { airport in
                    Text("\(airport.name) (\(airport.code))")
                        .tag(airport)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: viewModel.selectedAirport) { _, _ in
                Task {
                    await viewModel.loadDeals()
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func dealSection(title: String, deals: [FlightDeal]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title2)
                .bold()
            
            if deals.isEmpty {
                Text("검색 결과가 없습니다")
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(deals) { deal in
                    NavigationLink(destination: DetailView(deal: deal)) {
                        DealCard(deal: deal)
                    }
                }
            }
        }
    }
}
