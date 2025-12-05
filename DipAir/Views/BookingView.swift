import SwiftUI

struct BookingView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Text("예약 관리 기능은 준비 중입니다")
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
            .navigationTitle("이동")
        }
    }
}
