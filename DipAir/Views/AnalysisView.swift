import SwiftUI

struct AnalysisView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Text("가격 분석 기능은 준비 중입니다")
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
            .navigationTitle("분석")
        }
    }
}
