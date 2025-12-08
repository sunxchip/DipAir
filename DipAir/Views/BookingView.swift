import SwiftUI

struct BookingView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Text("이동 / 예약")
                        .font(.title3)
                        .bold()
                        .padding(.top, 24)

                    Text("현재는 Google Flights 등의 검색 페이지로 이동하는 딥링크만 제공하고,\n추후에는 실제 예약 파트너 연동을 고려할 수 있습니다.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .padding()

                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6]))
                        .frame(height: 120)
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "airplane.circle")
                                    .font(.largeTitle)
                                Text("지금은 DipAir에서\n타이밍만 잡고, 예약은 외부 서비스에서 진행하세요.")
                                    .font(.footnote)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.secondary)
                            }
                        )
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle("이동")
        }
    }
}
