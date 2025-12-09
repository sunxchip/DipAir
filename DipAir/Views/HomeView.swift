import SwiftUI

struct HomeView: View {

    @StateObject private var vm = HomeViewModel()

    var body: some View {
        ZStack {
            // 하늘색 그라데이션 배경
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.72, green: 0.83, blue: 1.0),
                    Color(red: 0.93, green: 0.96, blue: 1.0)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                header
                controlCard
                contentList
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
        }
        .navigationBarHidden(true)
        .task {
            await vm.load()
        }
    }

    // MARK: - 헤더

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Date(), formatter: HomeViewModel.dateFormatter)
                .font(.caption2)
                .foregroundColor(.secondary)

            Text("이번 주,\n어디로 떠나볼까요?")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.white)

            if vm.isUsingDemoData, let reason = vm.demoReason {
                Text(reason)
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.9))
            } else if let msg = vm.errorMessage {
                Text(msg)
                    .font(.footnote)
                    .foregroundColor(.yellow)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - 출발지 + 예산 카드

    private var controlCard: some View {
        VStack(alignment: .leading, spacing: 16) {

            // 출발지 세그먼트
            Picker("출발지", selection: $vm.selectedAirportCode) {
                Text("인천 ICN").tag("ICN")
                Text("김포 GMP").tag("GMP")
                Text("부산 PUS").tag("PUS")
            }
            .pickerStyle(.segmented)

            // 직접 IATA 코드 입력
            VStack(alignment: .leading, spacing: 4) {
                Text("직접 IATA 코드 입력 (선택)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                TextField("예: MAD, BOS, LHR …", text: $vm.customOriginCode)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .padding(10)
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)

            }

            // 예산 슬라이더
            VStack(alignment: .leading, spacing: 4) {
                Text("예산: 약 \(HomeView.priceFormatter.string(from: NSNumber(value: vm.budget)) ?? "0")원 이하")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Slider(
                    value: $vm.budget,
                    in: 200_000...2_000_000,
                    step: 50_000
                )
            }

        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
    }

    // MARK: - 리스트 / 로딩 / 빈 상태

    private var contentList: some View {
        Group {
            if vm.isLoading {
                VStack {
                    Spacer()
                    ProgressView()
                        .tint(.white)
                    Spacer()
                }
            } else if vm.thisWeekDeals.isEmpty && vm.nextWeekDeals.isEmpty {
                VStack {
                    Spacer()
                    Text("표시할 항공권이 없습니다.\n예산이나 출발지를 바꿔보세요.")
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                    Spacer()
                }
            } else {
                List {
                    if !vm.thisWeekDeals.isEmpty {
                        Section(header: Text("가까운 일정 추천")) {
                            ForEach(vm.thisWeekDeals, id: \.id) { deal in
                                DealRow(deal: deal)
                            }
                        }
                    }

                    if !vm.nextWeekDeals.isEmpty {
                        Section(header: Text("조금 여유로운 일정")) {
                            ForEach(vm.nextWeekDeals, id: \.id) { deal in
                                DealRow(deal: deal)
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
            }
        }
    }

    // MARK: - 가격 포맷터 (Int 변환 없이 안전하게)

    private static let priceFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return f
    }()
}

// MARK: - 개별 행

struct DealRow: View {

    static let priceFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return f
    }()

    let deal: FlightDeal

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(deal.destinationName)
                    .font(.headline)

                Text(deal.weekLabel)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(DealRow.priceFormatter.string(from: NSNumber(value: deal.price)) ?? "-")원")
                    .font(.headline)
                Text(deal.currency)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

