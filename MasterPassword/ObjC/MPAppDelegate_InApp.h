//
//  MPAppDelegate_Key.h
//  MasterPassword
//
//  Created by Maarten Billemont on 24/11/11.
//  Copyright (c) 2011 Lyndir. All rights reserved.
//

#import <StoreKit/StoreKit.h>
#import "MPAppDelegate_Shared.h"

#define MPProductGenerateLogins                 @"com.lyndir.masterpassword.products.generatelogins"
#define MPProductGenerateAnswers                @"com.lyndir.masterpassword.products.generateanswers"
#define MPProductFuel                           @"com.lyndir.masterpassword.products.fuel"

#define MP_FUEL_HOURLY_RATE                     30.f /* Tier 1 purchases/h ~> USD/h */

@protocol MPInAppDelegate

- (void)updateWithProducts:(NSArray /* SKProduct */ *)products;
- (void)updateWithTransaction:(SKPaymentTransaction *)transaction;

@end

@interface MPAppDelegate_Shared(InApp)

- (void)registerProductsObserver:(id<MPInAppDelegate>)delegate;
- (void)removeProductsObserver:(id<MPInAppDelegate>)delegate;

- (void)reloadProducts;
- (BOOL)canMakePayments;
- (BOOL)isFeatureUnlocked:(NSString *)productIdentifier;

- (void)restoreCompletedTransactions;
- (void)purchaseProductWithIdentifier:(NSString *)productIdentifier quantity:(NSInteger)quantity;

@end
