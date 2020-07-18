import SwiftUI

struct LoggedInBranch: View {
    // MARK:- States
    @State private var showTradeSheet = false
    
    // MARK:- Subviews
    private var tradeButton: some View {
        Button(action: { self.showTradeSheet.toggle() }) {
            Image(systemName: "arrow.right.arrow.left")
                .foregroundColor(.white)
                .font(.headline)
                .frame(width: 60, height: 40)
                .background(Circle().fill(Color.primary))
                .padding(5)
        }
    }
    
    var body: some View {
        ZStack {
            TabView() {
                HomeScreen()
                    .tabItem({ makeTabLabel(imageName: "home", title: "Home") })
                    .tag(1)
                
                PortfolioScreen()
                    .tabItem({ makeTabLabel(imageName: "discover", title: "Portfolio") })
                    .tag(2)
                
                Spacer()
                    .tabItem({ Text("") })
                    .disabled(true)
                    .tag(3)
                
                HomeScreen()
                    .tabItem({ makeTabLabel(imageName: "invest", title: "Prices") })
                    .tag(4)
                
                PreferenceView()
                    .tabItem({ makeTabLabel(imageName: "settings", title: "Settings") })
                    .tag(5)
            }
            .overlay(tradeButton, alignment: .bottom)
            
            if showTradeSheet {
                BottomSheetView(isOpen: $showTradeSheet) {
                    TradeSheet()
                }
            }
        }
    }
    
    // MARK:- Methods
    private func makeTabLabel(imageName: String, title: String) -> some View {
        HStack {
            Image(imageName)
            Text(title)
        }
    }
}

struct HomeTabView_Previews: PreviewProvider {
    static var previews: some View {
        LoggedInBranch()
            .environmentObject(DataSource())
    }
}
