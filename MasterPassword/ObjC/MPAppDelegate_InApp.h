//
//  MPAppDelegate_Key.h
//  MasterPassword
//
//  Created by Maarten Billemont on 24/11/11.
//  Copyright (c) 2011 Lyndir. All rights reserved.
//

#import <StoreKit/StoreKit.h>
#import "MPAppDelegate_Shared.h"

@interface MPAppDelegate_Shared(InApp)<SKProductsRequestDelegate, SKPaymentTransactionObserver>

@property(nonatomic, strong) NSArray /* SKProduct */ *products;
@property(nonatomic, strong) NSArray /* SKPaymentTransaction */ *paymentTransactions;

- (void)updateProducts;
- (BOOL)isPurchased:(NSString *)productIdentifier;

@end
