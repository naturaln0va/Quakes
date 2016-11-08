
import StoreKit
import Foundation


class IAPUtility: NSObject
{
    
    static let IAPHelperPurchaseNotification = "IAPHelperPurchaseNotification"
    static let IAPHelperFailedNotification = "IAPHelperFailedNotification"
    
    typealias ProductsRequestCompletionHandler = (_ products: [SKProduct]?) -> ()
    
    fileprivate var productsRequest: SKProductsRequest?
    fileprivate var removeAdsProduct: SKProduct?
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

//MARK: Public Methods
extension IAPUtility
{
    
    static func isRemoveAdsProduct(_ product: SKProduct) -> Bool {
        return product.productIdentifier == "io.ackermann.quakes.removeads"
    }
    
    func requestProducts(_ completionHandler: @escaping ProductsRequestCompletionHandler) {
        guard SKPaymentQueue.canMakePayments() else { return }
        
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
extension IAPUtility: SKProductsRequestDelegate
{
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse)
    {
        for product in response.products {
            if product.productIdentifier == removeAdsProductIdentifier {
                removeAdsProduct = product
            }
        }
        
        productsRequestCompletionHandler?(response.products)
        clearRequest()
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error)
    {
        print("Failed to load list of products. Error: \(error)")
        productsRequestCompletionHandler?(.none)
        clearRequest()
    }
    
    fileprivate func clearRequest()
    {
        productsRequestCompletionHandler = .none
        productsRequest = nil
    }
    
}

extension IAPUtility: SKPaymentTransactionObserver
{
    
    func paymentQueue(_ queue: SKPaymentQueue, removedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            failedTransaction(transaction)
        }
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction])
    {
        for transaction in transactions {
            switch (transaction.transactionState) {
            case .purchased:
                completeTransaction(transaction)
                break
            case .failed:
                failedTransaction(transaction)
                break
            case .restored:
                restoredTransaction(transaction)
                break
            default:
                print("Unhandled transaction type")
            }
        }
    }
    
    fileprivate func completeTransaction(_ transaction: SKPaymentTransaction) {
        deliverPurchaseNotification()
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    fileprivate func failedTransaction(_ transaction: SKPaymentTransaction) {
        let errorCode = (transaction.error as! NSError).code
        if errorCode == SKError.clientInvalid.rawValue || errorCode == SKError.paymentNotAllowed.rawValue || errorCode == SKError.paymentInvalid.rawValue {
            print("Transaction error: \(transaction.error)")
            NotificationCenter.default.post(name: Notification.Name(rawValue: type(of: self).IAPHelperFailedNotification), object: nil)
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
        NotificationCenter.default.post(name: Notification.Name(rawValue: type(of: self).IAPHelperPurchaseNotification), object: nil)
        removeAdsProduct = nil
    }
    
}
