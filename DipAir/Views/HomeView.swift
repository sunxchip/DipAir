import SwiftUI

struct HomeView: View {
    @StateObject private var vm = HomeViewModel()
    @State private var selectedDeal: FlightDeal?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // 하늘색 그라데이션 배경
                LinearGradient(
                    colors: [
                        Color(red: 0.84, green: 0.92, blue: 1.0),
                        Color.white
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 24) {
                    headerSection
                    controlCard
                    contentSection
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)
            }
            .navigationBarHidden(true)
            .task {
                await vm.load()
            }
            .sheet(item: $selectedDeal) { deal in
                DetailView(deal: deal)
            }
        }
    }

    // MARK: - 헤더

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(todayString)
                .font(.caption)
                .foregroundColor(.secondary)

            Text("이번 주,\n어디로 떠나볼까요?")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.black)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var todayString: String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "ko_KR")
        df.dateFormat = "오늘은 yyyy년 M월 d일 (E)"
        return df.string(from: Date())
    }

    // MARK: - 출발지 / 예산 카드

    private var controlCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Picker("출발지", selection: $vm.selectedAirportCode) {
                Text("인천 ICN").tag("ICN")
                Text("김포 GMP").tag("GMP")
                Text("부산 PUS").tag("PUS")
            }
            .pickerStyle(.segmented)

            VStack(alignment: .leading, spacing: 4) {
                Text("예산: 약 \(vm.budget.formatted())원 이하")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Slider(
                    value: Binding(
                        get: { Double(vm.budget) },
                        set: { vm.budget = Int($0) }
                    ),
                    in: 200_000...2_000_000,
                    step: 50_000
                )
            }
        }
        .padding(16)
        .background(.white.opacity(0.95))
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
    }

    // MARK: - 콘텐츠 섹션

    private var contentSection: some View {
        Group {
            if vm.isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("최저가 항공권을 찾는 중이에요…")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

            } else if let error = vm.errorMessage {
                VStack(spacing: 8) {
                    Text(error)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.red)
                        .padding(.bottom, 8)

                    if vm.primaryDeals.isEmpty && vm.secondaryDeals.isEmpty {
                        Text("표시할 항공권이 없습니다.\n예산이나 출발지를 바꿔보세요.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    } else {
                        Text("아래 리스트는 예시 데이터일 수 있습니다.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)

                resultsList

            } else if vm.primaryDeals.isEmpty && vm.secondaryDeals.isEmpty {
                VStack(spacing: 8) {
                    Text("표시할 항공권이 없습니다.")
                        .font(.footnote)
                    Text("예산이나 출발지를 바꿔보세요.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)

            } else {
                resultsList
            }
        }
    }

    private var resultsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if !vm.primaryDeals.isEmpty {
                    sectionHeader("지금 떠나기 좋은 일정")
                    ForEach(vm.primaryDeals) { deal in
                        DealCard(deal: deal)
                            .onTapGesture { selectedDeal = deal }
                    }
                }

                if !vm.secondaryDeals.isEmpty {
                    sectionHeader("다른 일정도 둘러볼까요?")
                        .padding(.top, 8)
                    ForEach(vm.secondaryDeals) { deal in
                        DealCard(deal: deal)
                            .onTapGesture { selectedDeal = deal }
                    }
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.headline)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
