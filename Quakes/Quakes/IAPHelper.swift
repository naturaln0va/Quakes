import StoreKit
import Foundation


class IAPHelper: NSObject
{
    
    static let sharedController = IAPHelper()
    
    typealias ProductsRequestCompletionHandler = (products: [SKProduct]?) -> ()
    
    private var productsRequest: SKProductsRequest?
    private var removeAdsProduct: SKProduct?
    private let removeAdsProductIdentifier: String = "io.ackermann.quakes.removeads"
    private var productsRequestCompletionHandler:  ProductsRequestCompletionHandler?
    
}

//:- API
extension IAPHelper
{
    
    func hasCompletedPurchase() -> Bool {
        if SKPaymentQueue.canMakePayments() {
            productsRequest?.cancel()
            productsRequest = SKProductsRequest(productIdentifiers: Set([removeAdsProductIdentifier]))
            productsRequest?.delegate = self
            productsRequest?.start()
        }
        
        return false
    }
    
}

//:- SKProductsRequestDelegate
extension IAPHelper: SKProductsRequestDelegate
{
    
    func productsRequest(request: SKProductsRequest, didReceiveResponse response: SKProductsResponse)
    {
        let products = response.products
        
        for product in products {
            if product.productIdentifier == removeAdsProductIdentifier {
                removeAdsProduct = product
            }
            
            print("Product: \(product.productIdentifier) \(product.localizedTitle) \(product.price.floatValue)")
        }
        
        clearRequest()
    }
    
    func request(request: SKRequest, didFailWithError error: NSError)
    {
        print("Failed to load list of products.")
        print("Error: \(error)")
        clearRequest()
    }
    
    private func clearRequest()
    {
        productsRequest = nil
    }
    
}

extension IAPHelper: SKPaymentTransactionObserver
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
            case .Deferred, .Purchasing:
                break
            }
        }
    }
    
    private func completeTransaction(transaction: SKPaymentTransaction) {        
        removeAdsProduct = nil
        SKPaymentQueue.defaultQueue().finishTransaction(transaction)
    }
    
    private func failedTransaction(transaction: SKPaymentTransaction) {
        if transaction.error?.code != SKErrorPaymentCancelled {
            print("Transaction error: \(transaction.error?.localizedDescription)")
        }
        SKPaymentQueue.defaultQueue().finishTransaction(transaction)
    }
    
    private func restoredTransaction(transaction: SKPaymentTransaction) {
        
    }
    
}
