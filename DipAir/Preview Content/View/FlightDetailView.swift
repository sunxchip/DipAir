import SwiftUI
import Charts
struct FlightDetailView: View {
    let recommendation: FlightRecommendation
    @ObservedObject var viewModel: FlightViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 헤더
                Text("\(recommendation.destination) 최저가 흐름")
                    .font(.title2)
                    .bold()
                
                // 차트 뷰
                Chart(viewModel.priceHistory) { item in
                    LineMark(
                        x: .value("주간", item.weekLabel),
                        y: .value("가격", item.price)
                    )
                    .foregroundStyle(.blue)
                    .symbol(by: .value("주간", item.weekLabel))
                    
                    PointMark(
                        x: .value("주간", item.weekLabel),
                        y: .value("가격", item.price)
                    )
                }
                .frame(height: 250)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                Divider()
                
                // 알림 설정 섹션
                VStack(alignment: .leading) {
                    Text("🔔 가격 알림 설정")
                        .font(.headline)
                    
                    HStack {
                        Text("목표 가격: \(Int(viewModel.targetPrice))원")
                        Spacer()
                        Toggle("", isOn: $viewModel.isAlertEnabled)
                            .labelsHidden()
                            .onChange(of: viewModel.isAlertEnabled) { newValue in
                                if newValue {
                                    viewModel.setPriceAlert(destination: recommendation.destination)
                                }
                            }
                    }
                    
                    Slider(value: $viewModel.targetPrice, in: 100000...1000000, step: 10000)
                }
                .padding()
                .background(Color.yellow.opacity(0.1)) // 강조색
                .cornerRadius(12)
                
                Spacer()
                
                // 예약 페이지 이동 버튼
                Link(destination: URL(string: "https://www.google.com/travel/flights")!) {
                    HStack {
                        Text("최저가 예약하러 가기")
                            .bold()
                        Image(systemName: "arrow.up.right.square")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
            .padding()
        }
        .navigationTitle(recommendation.destination)
        .onAppear {
            viewModel.fetchPriceHistory(for: recommendation.destination)
        }
    }
}