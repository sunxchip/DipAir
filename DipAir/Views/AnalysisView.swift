import SwiftUI

struct AnalysisView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Text("DipAir 분석 탭")
                        .font(.title3)
                        .bold()
                        .padding(.top, 24)

                    Text("향후에는 자주 검색한 출발지·목적지, 평균 구매 시점, 본인만의 적정 가격대 등을 분석해서 보여줄 예정입니다.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .padding()

                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6]))
                        .frame(height: 120)
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "chart.bar.xaxis")
                                    .font(.largeTitle)
                                Text("데이터가 쌓이면,\n여기서 인사이트를 보여드릴게요.")
                                    .font(.footnote)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.secondary)
                            }
                        )
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle("분석")
        }
    }
}
