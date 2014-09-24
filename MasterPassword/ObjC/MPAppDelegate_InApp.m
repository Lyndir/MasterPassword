//
//  MPAppDelegate.m
//  MasterPassword
//
//  Created by Maarten Billemont on 24/11/11.
//  Copyright (c) 2011 Lyndir. All rights reserved.
//

#import "MPAppDelegate_InApp.h"
#import <StoreKit/StoreKit.h>

@interface MPAppDelegate_Shared(InApp_Private)<SKProductsRequestDelegate, SKPaymentTransactionObserver>
@end

@implementation MPAppDelegate_Shared(InApp)

PearlAssociatedObjectProperty( NSArray*, Products, products );
PearlAssociatedObjectProperty( NSArray*, PaymentTransactions, paymentTransactions );

- (void)updateProducts {

    SKProductsRequest *productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:
            [[NSSet alloc] initWithObjects:MPProductGenerateLogins, MPProductGenerateAnswers, nil]];
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

- (BOOL)isPurchased:(NSString *)productIdentifier {

    return YES; //[[NSUserDefaults standardUserDefaults] objectForKey:productIdentifier] != nil;
}

- (void)restoreCompletedTransactions {

    [[self paymentQueue] restoreCompletedTransactions];
}

- (void)purchaseProductWithIdentifier:(NSString *)productIdentifier {

    for (SKProduct *product in self.products)
        if ([product.productIdentifier isEqualToString:productIdentifier]) {
            [[self paymentQueue] addPayment:[SKPayment paymentWithProduct:product]];
            return;
        }
}

#pragma mark - SKProductsRequestDelegate

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {

    inf( @"products: %@, invalid: %@", response.products, response.invalidProductIdentifiers );
    self.products = response.products;
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {

    err( @"StoreKit request (%@) failed: %@", request, [error fullDescription] );
}

- (void)requestDidFinish:(SKRequest *)request {

    dbg( @"StoreKit request (%@) finished.", request );
}

#pragma mark - SKPaymentTransactionObserver

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {

    for (SKPaymentTransaction *transaction in transactions) {
        dbg( @"transaction updated: %@", transaction );
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchased:
            case SKPaymentTransactionStateRestored: {
                inf( @"purchased: %@", transaction.payment.productIdentifier );
                [[NSUserDefaults standardUserDefaults] setObject:transaction.transactionIdentifier
                                                          forKey:transaction.payment.productIdentifier];
                break;
            }
            case SKPaymentTransactionStatePurchasing:
            case SKPaymentTransactionStateFailed:
            case SKPaymentTransactionStateDeferred:
                break;
        }
    }

    self.paymentTransactions = transactions;
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {

    err( @"StoreKit restore failed: %@", [error fullDescription] );
}

@end
