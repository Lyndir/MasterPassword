//==============================================================================
// This file is part of Master Password.
// Copyright (c) 2011-2017, Maarten Billemont.
//
// Master Password is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Master Password is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You can find a copy of the GNU General Public License in the
// LICENSE file.  Alternatively, see <http://www.gnu.org/licenses/>.
//==============================================================================

#import "MPAppDelegate_InApp.h"

@interface MPAppDelegate_Shared(InApp_Private)<SKProductsRequestDelegate, SKPaymentTransactionObserver>
@end

@implementation MPAppDelegate_Shared(InApp)

PearlAssociatedObjectProperty( NSDictionary*, Products, products );

PearlAssociatedObjectProperty( NSMutableArray*, ProductObservers, productObservers );

- (NSDictionary<NSString *, SKPaymentTransaction *> *)transactions {

    NSMutableDictionary<NSString *, SKPaymentTransaction *> *transactions =
            [NSMutableDictionary dictionaryWithCapacity:self.paymentQueue.transactions.count];
    for (SKPaymentTransaction *transaction in self.paymentQueue.transactions)
        transactions[transaction.payment.productIdentifier] = transaction;

    return transactions;
}

- (void)registerProductsObserver:(id<MPInAppDelegate>)delegate {

    if (!self.productObservers)
        self.productObservers = [NSMutableArray array];
    [self.productObservers addObject:delegate];

    if (self.products)
        [delegate updateWithProducts:self.products transactions:[self transactions]];
    else
        [self reloadProducts];
}

- (void)removeProductsObserver:(id<MPInAppDelegate>)delegate {

    [self.productObservers removeObject:delegate];
}

- (void)reloadProducts {

    SKProductsRequest *productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:
            [[NSSet alloc] initWithObjects:MPProductGenerateLogins, MPProductGenerateAnswers, MPProductTouchID, MPProductFuel, nil]];
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

#if DEBUG
    // All features are unlocked for beta / debug / mac versions.
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

#if TARGET_OS_IPHONE
    if (![[MPAppDelegate_Shared get] canMakePayments]) {
        [PearlAlert showAlertWithTitle:@"App Store Not Set Up" message:
                        @"Make sure your Apple ID is set under Settings -> iTunes & App Store, "
                                @"you have a payment method added to the account and purchases are"
                                @"not disabled under General -> Restrictions."
                             viewStyle:UIAlertViewStyleDefault initAlert:nil
                     tappedButtonBlock:^(UIAlertView *alert, NSInteger buttonIndex) {
                         if (buttonIndex == alert.cancelButtonIndex)
                             // Cancel
                             return;
                         if (buttonIndex == alert.firstOtherButtonIndex) {
                             // Settings
                             [PearlLinks openSettingsStore];
                             return;
                         }

                         // Try Anyway
                         [self performPurchaseProductWithIdentifier:productIdentifier quantity:quantity];
                     } cancelTitle:@"Cancel" otherTitles:@"Settings", @"Try Anyway", nil];
        return;
    }
#endif

    [self performPurchaseProductWithIdentifier:productIdentifier quantity:quantity];
}

- (void)performPurchaseProductWithIdentifier:(NSString *)productIdentifier quantity:(NSInteger)quantity {

    for (SKProduct *product in [self.products allValues])
        if ([product.productIdentifier isEqualToString:productIdentifier]) {
            SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:product];
            if (payment) {
                payment.quantity = quantity;
                [[self paymentQueue] addPayment:payment];
            }
            return;
        }
}

#pragma mark - SKProductsRequestDelegate

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {

    if ([response.invalidProductIdentifiers count])
        inf( @"Invalid products: %@", response.invalidProductIdentifiers );

    NSMutableDictionary *products = [NSMutableDictionary dictionaryWithCapacity:[response.products count]];
    for (SKProduct *product in response.products)
        products[product.productIdentifier] = product;
    self.products = products;

    for (id<MPInAppDelegate> productObserver in self.productObservers)
        [productObserver updateWithProducts:self.products transactions:[self transactions]];
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {

    MPError( error, @"StoreKit request (%@) failed.", request );

#if TARGET_OS_IPHONE
    [PearlAlert showAlertWithTitle:@"Purchase Failed" message:
                    strf( @"%@\n\n%@", error.localizedDescription,
                            @"Ensure you are online and try logging out and back into iTunes from your device's Settings." )
                         viewStyle:UIAlertViewStyleDefault initAlert:nil tappedButtonBlock:nil
                       cancelTitle:@"OK" otherTitles:nil];
#else
#endif
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
                inf( @"Purchased: %@", transaction.payment.productIdentifier );
                NSMutableDictionary *attributes = [NSMutableDictionary new];

                if ([transaction.payment.productIdentifier isEqualToString:MPProductFuel]) {
                    float currentFuel = [[MPiOSConfig get].developmentFuelRemaining floatValue];
                    float purchasedFuel = transaction.payment.quantity / MP_FUEL_HOURLY_RATE;
                    [MPiOSConfig get].developmentFuelRemaining = @(currentFuel + purchasedFuel);
                    if (![MPiOSConfig get].developmentFuelChecked || currentFuel < DBL_EPSILON)
                        [MPiOSConfig get].developmentFuelChecked = [NSDate date];
                    [attributes addEntriesFromDictionary:@{
                            @"currentFuel"  : @(currentFuel),
                            @"purchasedFuel": @(purchasedFuel),
                    }];
                }

                [[NSUserDefaults standardUserDefaults] setObject:transaction.transactionIdentifier
                                                          forKey:transaction.payment.productIdentifier];
                [queue finishTransaction:transaction];

                if ([[MPConfig get].sendInfo boolValue]) {
#ifdef CRASHLYTICS
                    SKProduct *product = self.products[transaction.payment.productIdentifier];
                    for (int q = 0; q < transaction.payment.quantity; ++q)
                        [Answers logPurchaseWithPrice:product.price currency:[product.priceLocale objectForKey:NSLocaleCurrencyCode]
                                              success:@YES itemName:product.localizedTitle itemType:@"InApp"
                                               itemId:product.productIdentifier customAttributes:attributes];
#endif
                }
                break;
            }
            case SKPaymentTransactionStateRestored: {
                inf( @"Restored: %@", transaction.payment.productIdentifier );
                [[NSUserDefaults standardUserDefaults] setObject:transaction.transactionIdentifier
                                                          forKey:transaction.payment.productIdentifier];
                [queue finishTransaction:transaction];
                break;
            }
            case SKPaymentTransactionStatePurchasing:
            case SKPaymentTransactionStateDeferred:
                break;
            case SKPaymentTransactionStateFailed:
                MPError( transaction.error, @"Transaction failed: %@.", transaction.payment.productIdentifier );
                [queue finishTransaction:transaction];

                if ([[MPConfig get].sendInfo boolValue]) {
#ifdef CRASHLYTICS
                    SKProduct *product = self.products[transaction.payment.productIdentifier];
                    [Answers logPurchaseWithPrice:product.price currency:[product.priceLocale objectForKey:NSLocaleCurrencyCode]
                                          success:@NO itemName:product.localizedTitle itemType:@"InApp" itemId:product.productIdentifier
                                 customAttributes:@{
                                         @"state"   : @"Failed",
                                         @"quantity": @(transaction.payment.quantity),
                                         @"reason"  : [transaction.error localizedFailureReason]?: [transaction.error localizedDescription],
                                 }];
#endif
                }
                break;
        }
    }

    if (![[NSUserDefaults standardUserDefaults] synchronize])
        wrn( @"Couldn't synchronize after transaction updates." );

    NSMutableDictionary<NSString *, SKPaymentTransaction *> *allTransactions = [[self transactions] mutableCopy];
    for (SKPaymentTransaction *transaction in transactions)
        allTransactions[transaction.payment.productIdentifier] = transaction;
    for (id<MPInAppDelegate> productObserver in self.productObservers)
        [productObserver updateWithProducts:self.products transactions:allTransactions];
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {

    MPError( error, @"StoreKit restore failed." );
}

@end
