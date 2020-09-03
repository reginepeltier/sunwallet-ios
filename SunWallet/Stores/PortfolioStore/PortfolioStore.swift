import Combine
import Foundation

typealias WalletsHistory = [WalletHistory]

class PortfolioStore: ObservableObject {
    private typealias WalletsHistorySubject = CurrentValueSubject<WalletsHistory?, Never>
    typealias WalletsHistoryPublisher = AnyPublisher<WalletsHistory?, Never>
    
    private var portfolioSubject: WalletsHistorySubject?
    private var portfolioSubscription: AnyCancellable?
    private var walletsSubscription: AnyCancellable?
    
    let historyStore: HistoryStore
    let blockchainStore: BlockchainStore
    let walletStore: WalletStore
    
    init(historyStore: HistoryStore, blockchainStore: BlockchainStore, walletStore: WalletStore) {
        self.historyStore = historyStore
        self.blockchainStore = blockchainStore
        self.walletStore = walletStore
        
        subscribeOnWalletStore()
    }
    
    var portfolioHistoryPublisher: WalletsHistoryPublisher {
        if let subject = portfolioSubject {
            return subject.eraseToAnyPublisher()
        } else {
            return refreshPortfolioSubject().eraseToAnyPublisher()
        }
    }
    
    func walletsHistoryPublisher(wallets: [Wallet]) -> WalletsHistoryPublisher {
        let infoPublisher = blockchainStore.walletsInfoPublisher(wallets: wallets)
        let historyPublisher = historyStore.publisher(for: .all)
        
        return Publishers.CombineLatest(infoPublisher, historyPublisher)
            .map { info, history -> WalletsHistory? in
                guard let info = info, let history = history else { return nil }
                return self.generateWalletsHistory(info: info, history: history)
            }
            .eraseToAnyPublisher()
    }
    
    func walletsHistory(wallets: [Wallet], completion: @escaping (WalletsHistory?) -> Void) {
        var cancellable: AnyCancellable?
        cancellable = walletsHistoryPublisher(wallets: wallets)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveValue: {
                    guard $0 != nil else { return }
                    completion($0)
                    cancellable?.cancel()
                }
            )
    }
    
    private func generateWalletsHistory(info: [Wallet : WalletBalance], history: [ExchangeHistory]) -> WalletsHistory {
        info.map { wallet, walletBalance -> WalletHistory in
            let assetsHistory = walletBalance.assets.compactMap { assetBalance -> AssetHistory? in
                guard let exchangeHistory = history.first(where: { $0.source == assetBalance.asset }) else { return nil }
                return AssetHistory(assetBalance: assetBalance, historySet: exchangeHistory.historySet)
            }
            return WalletHistory(wallet: wallet, assetsHistory: assetsHistory)
        }
    }
}

private extension AssetHistory {
    
    init(assetBalance: AssetBalance, historySet: HistorySet) {
        let equity = historySet.lastValue * assetBalance.balance
        let balanceHistory = BalanceHistory(assetInfo: assetBalance)
        let convertedHistorySet = balanceHistory.converted(historySet: historySet)
        let transactions = assetBalance.transactions.map { transaction -> AssetTransaction in
            let historyPrice = (historySet.all + historySet.hourly).first(where: { $0.date > transaction.date })?.value ?? historySet.lastValue
            return AssetTransaction(
                asset: assetBalance.asset,
                value: transaction.value,
                currencyValue: historyPrice * transaction.value,
                date: transaction.date
            )
        }
        self.init(
            asset: assetBalance.asset,
            balance: assetBalance.balance,
            equity: equity,
            transactions: transactions,
            historySet: convertedHistorySet
        )
    }
}


// MARK: - Publishers
extension PortfolioStore {
    
    @discardableResult
    private func refreshPortfolioSubject() -> WalletsHistorySubject {
        let subject = WalletsHistorySubject(nil)
        portfolioSubject = subject
        portfolioSubscription = walletsHistoryPublisher(wallets: walletStore.wallets).sink(receiveValue: { subject.send($0) })
        return subject
    }
    
    private func subscribeOnWalletStore() {
        walletsSubscription = walletStore.objectWillChange.sink(receiveValue: { self.refreshPortfolioSubject() })
    }
}
