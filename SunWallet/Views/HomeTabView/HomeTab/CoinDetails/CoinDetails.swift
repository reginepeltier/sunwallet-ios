import SwiftUI

struct CoinDetails: View {
    // MARK:- Properties
    let asset: Asset2
    
    // MARK:- Environment
    @EnvironmentObject var dataSource: DataSource
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    // MARK:- States
    @State private var selectedValue: Double? = nil
    @State private var selectedValueChange: Double? = nil

    // MARK:- Calculated Variables
    private var currentValue: Double {
        selectedValue ?? asset.dollarPrice
    }
    private var currentValueChange: Double {
        selectedValueChange ?? asset.dollarPriceChange
    }
    
    // MARK:- Subviews
    private var title: Text {
        let price = Text(currentValue.currencyString + " ")
            .font(.largeTitle)
            .bold()
        let priceChange = Text(currentValueChange.priceChangeString)
            .font(.title)
            .bold()
            .foregroundColor(.green)
        return price + priceChange
    }
    private var subtitle: Text {
        Text("\(asset.title) price")
    }
    
    var body: some View {
        SWScrollView(title: title, subtitle: subtitle, presentationMode: presentationMode) {
            VStack(alignment: .leading, spacing: 8) {
                ChartViewSection(
                    valueHistory: self.asset.valueHistory,
                    color: .orange,
                    selectedValue: self.$selectedValue,
                    selectedValueChange: self.$selectedValueChange
                )
                Divider()
                BuyAssetSection(asset: self.asset)
                Divider()
                HintSection()
                Divider()
                DetailsCell(text: Text("Get Started").foregroundColor(.primaryBlue).bold())
                Divider()
                AboutSection(asset: self.asset)
                MarketStatsSection(asset: self.asset)
            }
        }
    }
}

struct CoinDetails_Previews: PreviewProvider {
    
    static var previews: some View {
        CoinDetails(asset: TestData.randomAsset)
            .environmentObject(DataSource())
    }
}
