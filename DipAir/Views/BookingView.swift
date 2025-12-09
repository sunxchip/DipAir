import SwiftUI

struct BookingView: View {

    @State private var originCode: String = "ICN"
    @State private var destinationCode: String = "NRT"

    @State private var departureDate: Date = Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date()
    @State private var returnDate: Date = Calendar.current.date(byAdding: .day, value: 21, to: Date()) ?? Date()

    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.systemBlue).opacity(0.2),
                        Color(.systemBackground)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 24) {
                    headerSection
                    searchForm
                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("이동")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - 헤더

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("바로 예약/검색하기")
                .font(.title3.bold())
            Text("출발지, 도착지, 날짜를 선택하고\nGoogle Flights 검색 결과로 바로 넘어가요.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - 폼 + 버튼

    private var searchForm: some View {
        VStack(spacing: 16) {
            // 출발지 선택 (국내 공항 세 개)
            VStack(alignment: .leading, spacing: 4) {
                Text("출발지")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Picker("출발지", selection: $originCode) {
                    Text("인천 ICN").tag("ICN")
                    Text("김포 GMP").tag("GMP")
                    Text("부산 PUS").tag("PUS")
                }
                .pickerStyle(.segmented)
            }

            // 도착지 IATA 코드 입력
            VStack(alignment: .leading, spacing: 4) {
                Text("도착지 (IATA 코드)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                TextField("예: NRT, BKK, TPE …", text: $destinationCode)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .padding(10)
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
            }

            // 날짜 선택
            VStack(alignment: .leading, spacing: 8) {
                Text("출발 / 귀국 날짜")
                    .font(.caption)
                    .foregroundColor(.secondary)

                DatePicker("출발일",
                           selection: $departureDate,
                           displayedComponents: .date)
                    .datePickerStyle(.compact)

                DatePicker("귀국일",
                           selection: $returnDate,
                           displayedComponents: .date)
                    .datePickerStyle(.compact)
            }

            Button {
                openGoogleFlights()
            } label: {
                Text("Google Flights에서 검색")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(16)
            }
            .padding(.top, 8)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }

    // MARK: - 딥링크 생성

    private func openGoogleFlights() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dep = formatter.string(from: departureDate)
        let ret = formatter.string(from: returnDate)

        let base = "https://www.google.com/travel/flights"
        let query = "\(originCode) to \(destinationCode) \(dep) - \(ret)"

        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(base)?q=\(encoded)") else {
            return
        }

        openURL(url)
    }
}


#Preview {
    ContentView()
}
