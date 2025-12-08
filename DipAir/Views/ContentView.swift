import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 1   // 기본은 홈 탭

    var body: some View {
        TabView(selection: $selectedTab) {
            
            AnalysisView()
                .tabItem {
                    Label("분석", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(0)
            
            HomeView()
                .tabItem {
                    Label("홈", systemImage: "house.fill")
                }
                .tag(1)
            
            BookingView()
                .tabItem {
                    Label("이동", systemImage: "airplane")
                }
                .tag(2)
        }
        .tint(.blue)
    }
}

#Preview {
    ContentView()
}
