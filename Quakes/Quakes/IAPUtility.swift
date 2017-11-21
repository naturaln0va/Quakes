
import StoreKit
import Foundation

class IAPUtility: NSObject {
    
    typealias ProductsRequestCompletionHandler = (_ products: [SKProduct]?) -> ()
    
    fileprivate var removeAdsProduct: SKProduct?
    fileprivate var productsRequest: SKProductsRequest?
    fileprivate let removeAdsProductIdentifier: String = "io.ackermann.quakes.removeads"
    fileprivate var productsRequestCompletionHandler:  ProductsRequestCompletionHandler?
    
    deinit {
        SKPaymentQueue.default().remove(self)
    }
    
    override init() {
        super.init()
        SKPaymentQueue.default().add(self)
    }
    
}

extension Notification.Name {
    
    static var didPurchaseProduct: Notification.Name {
        return Notification.Name("didPurchaseProduct")
    }
    
    static var didFailToPurchaseProduct: Notification.Name {
        return Notification.Name("didFailToPurchaseProduct")
    }
    
    static var didCancelPurchaseProduct: Notification.Name {
        return Notification.Name("didCancelPurchaseProduct")
    }

}

//MARK: Public Methods
extension IAPUtility {
    
    static func isRemoveAdsProduct(_ product: SKProduct) -> Bool {
        return product.productIdentifier == "io.ackermann.quakes.removeads"
    }
    
    func requestProducts(_ completionHandler: ProductsRequestCompletionHandler?) {
        guard SKPaymentQueue.canMakePayments() else {
            return
        }
        
        productsRequest?.cancel()
        productsRequestCompletionHandler = completionHandler
        
        productsRequest = SKProductsRequest(productIdentifiers: Set([removeAdsProductIdentifier]))
        productsRequest?.delegate = self
        productsRequest?.start()
    }
    
    func purchaseRemoveAds() {
        guard let product = removeAdsProduct, SKPaymentQueue.canMakePayments() else { return }

        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    func restorePurchases() {
        guard SKPaymentQueue.canMakePayments() else { return }

        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
}

//MARK: SKProductsRequestDelegate

extension IAPUtility: SKProductsRequestDelegate {
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        for product in response.products {
            if product.productIdentifier == removeAdsProductIdentifier {
                removeAdsProduct = product
            }
        }
        
        productsRequestCompletionHandler?(response.products)
        clearRequest()
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        print("Failed to load list of products. Error: \(error)")
        productsRequestCompletionHandler?(.none)
        clearRequest()
    }
    
    fileprivate func clearRequest() {
        productsRequestCompletionHandler = .none
        productsRequest = nil
    }
    
}

//MARK: SKPaymentTransactionObserver

extension IAPUtility: SKPaymentTransactionObserver {
    
    func paymentQueue(_ queue: SKPaymentQueue, removedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            failedTransaction(transaction)
        }
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch (transaction.transactionState) {
            case .purchased:
                completeTransaction(transaction)
            case .failed:
                failedTransaction(transaction)
            case .restored:
                restoredTransaction(transaction)
            case .purchasing, .deferred:
                break // don't handle this state
            }
        }
    }
    
    fileprivate func completeTransaction(_ transaction: SKPaymentTransaction) {
        deliverPurchaseNotification()
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    fileprivate func failedTransaction(_ transaction: SKPaymentTransaction) {
        let nsError = transaction.error as NSError?
        guard let transactionError = nsError else {
            SKPaymentQueue.default().finishTransaction(transaction)
            return
        }
        
        switch transactionError.code {
        case SKError.paymentCancelled.rawValue:
            NotificationCenter.default.post(name: .didCancelPurchaseProduct, object: nil)
        default:
            NotificationCenter.default.post(name: .didFailToPurchaseProduct, object: nil)
            print("Transaction failed with error: \(transactionError.localizedDescription).")
        }
        
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    fileprivate func restoredTransaction(_ transaction: SKPaymentTransaction) {
        if transaction.original?.payment.productIdentifier == removeAdsProductIdentifier {
            deliverPurchaseNotification()
        }
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    fileprivate func deliverPurchaseNotification() {
        NotificationCenter.default.post(name: .didPurchaseProduct, object: nil)
        removeAdsProduct = nil
    }
    
}
