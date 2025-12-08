import SwiftUI
import Charts

struct DetailView: View {

    @StateObject private var viewModel: DetailViewModel
    @Environment(\.openURL) private var openURL

    // HomeView에서 DetailView(deal: deal) 로 들어오니까 그대로 유지
    init(deal: FlightDeal) {
        _viewModel = StateObject(wrappedValue: DetailViewModel(deal: deal))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
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

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 4) {
            Text("\(viewModel.deal.origin) → \(viewModel.deal.destinationName)")
                .font(.headline)

            Text("\(viewModel.deal.departureDate) ~ \(viewModel.deal.returnDate)")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("현재 최저가: \(Int(viewModel.deal.price).formatted())원")
                .font(.title3)
                .bold()
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    // MARK: - Price Chart

    private var priceChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("최근 8주 최저가 추이")
                .font(.headline)

            if viewModel.isLoading && viewModel.priceHistory.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if viewModel.priceHistory.isEmpty {
                Text("가격 데이터를 불러오지 못했습니다.")
                    .foregroundColor(.secondary)
            } else {
                Chart(viewModel.priceHistory) { point in
                    LineMark(
                        x: .value("Week", point.weekLabel),
                        y: .value("Price", point.price)
                    )
                    PointMark(
                        x: .value("Week", point.weekLabel),
                        y: .value("Price", point.price)
                    )
                }
                .frame(height: 220)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    // MARK: - Alert Section

    private var alertSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("가격 알림 설정")
                .font(.headline)

            HStack {
                Text("목표 가격")
                Spacer()
                TextField(
                    "600000",
                    value: $viewModel.threshold,
                    format: .number
                )
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 120)

                Text("원")
            }

            Toggle("알림 활성화", isOn: $viewModel.isAlertActive)
                .onChange(of: viewModel.isAlertActive) { isOn in
                    if isOn {
                        viewModel.checkThresholdAndScheduleNotification()
                    }
                }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    // MARK: - Booking Button

    private var bookingButton: some View {
        Button {
            openGoogleFlights()
        } label: {
            Text("예약 / 검색 페이지로 이동")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(16)
        }
    }

    // MARK: - Google Flights 딥링크

    private func openGoogleFlights() {
        let base = "https://www.google.com/travel/flights"
        let query = "\(viewModel.deal.origin) to \(viewModel.deal.destinationName) on \(viewModel.deal.departureDate)"

        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(base)?q=\(encoded)") else { return }

        openURL(url)
    }
}
