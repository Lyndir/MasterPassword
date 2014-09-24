//
//  MPAppDelegate_Key.h
//  MasterPassword
//
//  Created by Maarten Billemont on 24/11/11.
//  Copyright (c) 2011 Lyndir. All rights reserved.
//

#import "MPAppDelegate_Shared.h"

#define MPProductGenerateLogins               @"com.lyndir.masterpassword.products.generatelogins"
#define MPProductGenerateAnswers              @"com.lyndir.masterpassword.products.generateanswers"

@interface MPAppDelegate_Shared(InApp)

@property(nonatomic, strong) NSArray /* SKProduct */ *products;
@property(nonatomic, strong) NSArray /* SKPaymentTransaction */ *paymentTransactions;

- (void)updateProducts;
- (BOOL)canMakePayments;
- (BOOL)isPurchased:(NSString *)productIdentifier;

- (void)restoreCompletedTransactions;
- (void)purchaseProductWithIdentifier:(NSString *)productIdentifier;

@end
