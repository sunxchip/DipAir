import SwiftUI
import Charts

struct DetailView: View {
    @StateObject private var viewModel: DetailViewModel
    @Environment(\.openURL) private var openURL
    
    init(deal: FlightDeal) {
        _viewModel = StateObject(wrappedValue: DetailViewModel(deal: deal))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                priceChartSection
                alertSection
                bookingButton
            }
            .padding()
        }
        .navigationTitle(viewModel.deal.destinationName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadPriceHistory()
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(viewModel.deal.origin)
                        .font(.title2)
                        .bold()
                    Text("출발")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Image(systemName: "airplane")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .trailing) {
                    Text(viewModel.deal.destination)
                        .font(.title2)
                        .bold()
                    Text("도착")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text("₩\(Int(viewModel.deal.price).formatted())")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.blue)
            
            Text("왕복 최저가")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private var priceChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("최근 8주 가격 추이")
                .font(.headline)
            
            if viewModel.priceHistory.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                Chart(viewModel.priceHistory) { item in
                    LineMark(
                        x: .value("주차", item.weekLabel),
                        y: .value("가격", item.price)
                    )
                    .foregroundStyle(.blue)
                    
                    PointMark(
                        x: .value("주차", item.weekLabel),
                        y: .value("가격", item.price)
                    )
                    .foregroundStyle(.blue)
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis {
                    AxisMarks()
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private var alertSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("가격 알림 설정")
                .font(.headline)
            
            HStack {
                Text("목표 가격")
                Spacer()
                TextField("가격", value: $viewModel.threshold, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 120)
                Text("원")
            }
            
            Toggle("알림 활성화", isOn: $viewModel.isAlertActive)
                .onChange(of: viewModel.isAlertActive) { _, _ in
                    viewModel.toggleAlert()
                }
            
            if viewModel.isAlertActive {
                Text("설정한 가격 이하로 내려가면 알림을 보내드립니다")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private var bookingButton: some View {
        Button(action: {
            let urlString = "https://www.google.com/flights?hl=ko#flt=\(viewModel.deal.origin).\(viewModel.deal.destination).\(viewModel.deal.departureDate)*\(viewModel.deal.destination).\(viewModel.deal.origin).\(viewModel.deal.returnDate)"
            if let url = URL(string: urlString) {
                openURL(url)
            }
        }) {
            HStack {
                Image(systemName: "airplane.departure")
                Text("항공권 검색하기")
                    .bold()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
    }
}
