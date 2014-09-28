//
//  MPAppDelegate.m
//  MasterPassword
//
//  Created by Maarten Billemont on 24/11/11.
//  Copyright (c) 2011 Lyndir. All rights reserved.
//

#import "MPAppDelegate_InApp.h"

@interface MPAppDelegate_Shared(InApp_Private)<SKProductsRequestDelegate, SKPaymentTransactionObserver>
@end

@implementation MPAppDelegate_Shared(InApp)

PearlAssociatedObjectProperty( NSArray*, Products, products );
PearlAssociatedObjectProperty( NSMutableArray*, ProductObservers, productObservers );

- (void)registerProductsObserver:(id<MPInAppDelegate>)delegate {

    if (!self.productObservers)
        self.productObservers = [NSMutableArray array];
    [self.productObservers addObject:delegate];

    if (self.products)
        [delegate updateWithProducts:self.products];
    else
        [self reloadProducts];
}

- (void)removeProductsObserver:(id<MPInAppDelegate>)delegate {

    [self.productObservers removeObject:delegate];
}

- (void)reloadProducts {

    SKProductsRequest *productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:
            [[NSSet alloc] initWithObjects:MPProductGenerateLogins, MPProductGenerateAnswers, MPProductFuel, nil]];
    productsRequest.delegate = self;
    [productsRequest start];
}

- (SKPaymentQueue *)paymentQueue {

    static dispatch_once_t once = 0;
    dispatch_once( &once, ^{
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    } );

    return [SKPaymentQueue defaultQueue];
}

- (BOOL)canMakePayments {

    return [SKPaymentQueue canMakePayments];
}

- (BOOL)isFeatureUnlocked:(NSString *)productIdentifier {

    if (![productIdentifier length])
        // Missing a product.
        return NO;
    if ([productIdentifier isEqualToString:MPProductFuel])
        // Consumable product.
        return NO;

#if ADHOC || DEBUG
    // All features are unlocked for beta / debug versions.
    return YES;
#else
    // Check if product is purchased.
    return [[NSUserDefaults standardUserDefaults] objectForKey:productIdentifier] != nil;
#endif
}

- (void)restoreCompletedTransactions {

    [[self paymentQueue] restoreCompletedTransactions];
}

- (void)purchaseProductWithIdentifier:(NSString *)productIdentifier quantity:(NSInteger)quantity {

    for (SKProduct *product in self.products)
        if ([product.productIdentifier isEqualToString:productIdentifier]) {
            SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:product];
            payment.quantity = quantity;
            [[self paymentQueue] addPayment:payment];
            return;
        }
}

#pragma mark - SKProductsRequestDelegate

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {

    inf( @"products: %@, invalid: %@", response.products, response.invalidProductIdentifiers );
    self.products = response.products;

    for (id<MPInAppDelegate> productObserver in self.productObservers)
        [productObserver updateWithProducts:self.products];
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {

#if TARGET_OS_IPHONE
    [PearlAlert showAlertWithTitle:@"Purchase Failed" message:
                    strf( @"%@\n\n%@", error.localizedDescription,
                            @"Ensure you are online and try logging out and back into iTunes from your device's Settings." )
                         viewStyle:UIAlertViewStyleDefault initAlert:nil tappedButtonBlock:nil
                       cancelTitle:@"OK" otherTitles:nil];
#else
#endif
    err( @"StoreKit request (%@) failed: %@", request, [error fullDescription] );
}

- (void)requestDidFinish:(SKRequest *)request {

    dbg( @"StoreKit request (%@) finished.", request );
}

#pragma mark - SKPaymentTransactionObserver

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {

    for (SKPaymentTransaction *transaction in transactions) {
        dbg( @"transaction updated: %@ -> %d", transaction.payment.productIdentifier, (int)(transaction.transactionState) );
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchased: {
                inf( @"purchased: %@", transaction.payment.productIdentifier );
                if ([transaction.payment.productIdentifier isEqualToString:MPProductFuel]) {
                    float currentFuel = [[MPiOSConfig get].developmentFuel floatValue];
                    float purchasedFuel = transaction.payment.quantity / MP_FUEL_HOURLY_RATE;
                    [MPiOSConfig get].developmentFuel = @(currentFuel + purchasedFuel);
                    if (![MPiOSConfig get].developmentFuelChecked || !currentFuel)
                        [MPiOSConfig get].developmentFuelChecked = [NSDate date];
                }
                [[NSUserDefaults standardUserDefaults] setObject:transaction.transactionIdentifier
                                                          forKey:transaction.payment.productIdentifier];
                [queue finishTransaction:transaction];
                break;
            }
            case SKPaymentTransactionStateRestored: {
                inf( @"restored: %@", transaction.payment.productIdentifier );
                [[NSUserDefaults standardUserDefaults] setObject:transaction.transactionIdentifier
                                                          forKey:transaction.payment.productIdentifier];
                [queue finishTransaction:transaction];
                break;
            }
            case SKPaymentTransactionStatePurchasing:
            case SKPaymentTransactionStateDeferred:
                break;
            case SKPaymentTransactionStateFailed:
                err( @"Transaction failed: %@, reason: %@", transaction.payment.productIdentifier, [transaction.error fullDescription] );
                [queue finishTransaction:transaction];
                break;
        }

        for (id<MPInAppDelegate> productObserver in self.productObservers)
            [productObserver updateWithTransaction:transaction];
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {

    err( @"StoreKit restore failed: %@", [error fullDescription] );
}

@end
