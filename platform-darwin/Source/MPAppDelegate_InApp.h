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

#import <StoreKit/StoreKit.h>
#import "MPAppDelegate_Shared.h"

#define MPProductGenerateLogins                 @"com.lyndir.masterpassword.products.generatelogins"
#define MPProductGenerateAnswers                @"com.lyndir.masterpassword.products.generateanswers"
#define MPProductOSIntegration                  @"com.lyndir.masterpassword.products.osintegration"
#define MPProductTouchID                        @"com.lyndir.masterpassword.products.touchid"
#define MPProductFuel                           @"com.lyndir.masterpassword.products.fuel"

#define MP_FUEL_HOURLY_RATE                     40.f /* payment in tier 1 purchases / h (≅ USD / h) */

@protocol MPInAppDelegate

- (void)updateWithProducts:(NSDictionary<NSString *, SKProduct *> *)products
              transactions:(NSDictionary<NSString *, SKPaymentTransaction *> *)transactions;

@end

@interface MPAppDelegate_Shared(InApp)

- (NSDictionary<NSString *, SKProduct *> *)products;
- (NSDictionary<NSString *, SKPaymentTransaction *> *)transactions;

- (void)registerProductsObserver:(id<MPInAppDelegate>)delegate;
- (void)removeProductsObserver:(id<MPInAppDelegate>)delegate;

- (void)reloadProducts;
- (BOOL)canMakePayments;
- (BOOL)isFeatureUnlocked:(NSString *)productIdentifier;

- (void)restoreCompletedTransactions;
- (void)purchaseProductWithIdentifier:(NSString *)productIdentifier quantity:(NSInteger)quantity;

@end
