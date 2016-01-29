
import StoreKit
import Foundation


class IAPUtility: NSObject
{
    
    static let IAPHelperPurchaseNotification = "IAPHelperPurchaseNotification"
    
    typealias ProductsRequestCompletionHandler = (products: [SKProduct]?) -> ()
    
    private var productsRequest: SKProductsRequest?
    private var removeAdsProduct: SKProduct?
    private let removeAdsProductIdentifier: String = "io.ackermann.quakes.removeads"
    private var productsRequestCompletionHandler:  ProductsRequestCompletionHandler?
    
    deinit {
        SKPaymentQueue.defaultQueue().removeTransactionObserver(self)
    }
    
    override init() {
        super.init()
        SKPaymentQueue.defaultQueue().addTransactionObserver(self)
    }
    
}

//MARK: Public Methods
extension IAPUtility
{
    
    static func isRemoveAdsProduct(product: SKProduct) -> Bool {
        return product.productIdentifier == "io.ackermann.quakes.removeads"
    }
    
    func requestProducts(completionHandler: ProductsRequestCompletionHandler) {
        guard SKPaymentQueue.canMakePayments() else { return }
        
        productsRequest?.cancel()
        productsRequestCompletionHandler = completionHandler
        
        productsRequest = SKProductsRequest(productIdentifiers: Set([removeAdsProductIdentifier]))
        productsRequest?.delegate = self
        productsRequest?.start()
    }
    
    func purchaseRemoveAds() {
        guard let product = removeAdsProduct where SKPaymentQueue.canMakePayments() else { return }

        let payment = SKPayment(product: product)
        SKPaymentQueue.defaultQueue().addPayment(payment)
    }
    
    func restorePurchases() {
        guard SKPaymentQueue.canMakePayments() else { return }

        SKPaymentQueue.defaultQueue().restoreCompletedTransactions()
    }
    
}

//MARK: SKProductsRequestDelegate
extension IAPUtility: SKProductsRequestDelegate
{
    
    func productsRequest(request: SKProductsRequest, didReceiveResponse response: SKProductsResponse)
    {
        for product in response.products {
            if product.productIdentifier == removeAdsProductIdentifier {
                removeAdsProduct = product
            }
        }
        
        productsRequestCompletionHandler?(products: response.products)
        clearRequest()
    }
    
    func request(request: SKRequest, didFailWithError error: NSError)
    {
        print("Failed to load list of products. Error: \(error)")
        productsRequestCompletionHandler?(products: .None)
        clearRequest()
    }
    
    private func clearRequest()
    {
        productsRequestCompletionHandler = .None
        productsRequest = nil
    }
    
}

extension IAPUtility: SKPaymentTransactionObserver
{
    
    func paymentQueue(queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction])
    {
        for transaction in transactions {
            switch (transaction.transactionState) {
            case .Purchased:
                completeTransaction(transaction)
                break
            case .Failed:
                failedTransaction(transaction)
                break
            case .Restored:
                restoredTransaction(transaction)
                break
            default:
                print("Unhandled transaction type")
            }
        }
    }
    
    private func completeTransaction(transaction: SKPaymentTransaction) {
        deliverPurchaseNotification()
        SKPaymentQueue.defaultQueue().finishTransaction(transaction)
    }
    
    private func failedTransaction(transaction: SKPaymentTransaction) {
        if transaction.error?.code != SKErrorPaymentCancelled {
            print("Transaction error: \(transaction.error?.localizedDescription)")
        }
        SKPaymentQueue.defaultQueue().finishTransaction(transaction)
    }
    
    private func restoredTransaction(transaction: SKPaymentTransaction) {
        if transaction.originalTransaction?.payment.productIdentifier == removeAdsProductIdentifier {
            deliverPurchaseNotification()
        }
        SKPaymentQueue.defaultQueue().finishTransaction(transaction)
    }
    
    private func deliverPurchaseNotification() {
        NSNotificationCenter.defaultCenter().postNotificationName(self.dynamicType.IAPHelperPurchaseNotification, object: nil)
        removeAdsProduct = nil
    }
    
}
