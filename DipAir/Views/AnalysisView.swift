import SwiftUI
import Charts

struct AnalysisView: View {

    @StateObject private var viewModel = AnalysisViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                // 하늘색 그러데이션 배경
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.systemBlue).opacity(0.25),
                        Color(.systemBackground)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {

                        headerSection
                        weeklyChartSection
                        leadTimeSection
                        regretSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("분석")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - 헤더

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("최근 가격 흐름 분석")
                .font(.title2.bold())

            Text("예시 노선 기준(인천 → 도쿄)으로\n최근 8주 가격과 적정 예매 시기를 보여줘요.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - 주간 라인차트 + 통계

    private var weeklyChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("주간 최저가 라인차트 (8주)")
                .font(.headline)

            if viewModel.priceHistory.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
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

                HStack(spacing: 16) {
                    statItem(title: "최저가",
                             value: Int(viewModel.minPrice).formatted() + "원")

                    statItem(title: "최고가",
                             value: Int(viewModel.maxPrice).formatted() + "원")

                    statItem(title: "평균",
                             value: Int(viewModel.averagePrice).formatted() + "원")
                }

                if let diff = viewModel.lastWeekDiffPercent {
                    let arrow = diff >= 0 ? "▲" : "▼"
                    let color: Color = diff >= 0 ? .red : .blue
                    Text("전주 대비 \(arrow) \(abs(diff).rounded())%")
                        .font(.caption)
                        .foregroundColor(color)
                }

                if !viewModel.recommendedLeadTimeLabel.isEmpty {
                    Text("최근 데이터 기준, \(viewModel.recommendedLeadTimeLabel)에 예매했을 때 가격이 가장 낮았습니다.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }

    private func statItem(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline.bold())
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 리드타임 비교

    private var leadTimeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("리드타임별 가격 비교 ")
                .font(.headline)

            Text("출발 60 / 45 / 30일 전에 예매했을 때의 예상 가격을 비교해요.")
                .font(.caption)
                .foregroundColor(.secondary)

            if viewModel.leadTimePoints.isEmpty {
                Text("데이터가 없습니다.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Chart(viewModel.leadTimePoints) { point in
                    BarMark(
                        x: .value("리드타임", point.label),
                        y: .value("가격", point.price)
                    )
                }
                .frame(height: 180)

                HStack {
                    ForEach(viewModel.leadTimePoints) { point in
                        VStack(spacing: 4) {
                            Text(point.label)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(Int(point.price).formatted())원")
                                .font(.subheadline.bold())
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }

    // MARK: - 후회지수

    private var regretSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("후회지수 계산기")
                .font(.headline)

            Text("내가 이미 예매한 가격을 입력하면, 현재 기준 가격과 비교해서\n얼마나 비싸게(또는 싸게) 샀는지 알려줘요.")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack {
                Text("내 예매가")
                Spacer()
                TextField("예: 420000", text: $viewModel.myBookingPriceText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 120)
                Text("원")
            }

            Button {
                viewModel.updateRegretIndex()
            } label: {
                Text("후회지수 계산하기")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.blue.opacity(0.9))
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }

            if let regret = viewModel.regretIndex {
                Group {
                    if regret > 0 {
                        Text("지금이 \(Int(regret).formatted())원 더 싸요 😭")
                    } else if regret < 0 {
                        Text("당신이 \(Int(-regret).formatted())원 이득 봤어요 😎")
                    } else {
                        Text("현재 가격과 거의 비슷해요.")
                    }
                }
                .font(.subheadline)
                .foregroundColor(.primary)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
}
