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

#import "MPStoreViewController.h"
#import "MPiOSAppDelegate.h"
#import "UIColor+Expanded.h"
#import "MPAppDelegate_InApp.h"
#import "MPPasswordsViewController.h"

PearlEnum( MPDevelopmentFuelConsumption,
        MPDevelopmentFuelConsumptionQuarterly, MPDevelopmentFuelConsumptionMonthly, MPDevelopmentFuelWeekly );

@interface MPStoreViewController()<MPInAppDelegate>

@property(nonatomic, strong) NSNumberFormatter *currencyFormatter;
@property(nonatomic, strong) NSArray *products;

@end

@implementation MPStoreViewController

+ (NSString *)latestStoreFeatures {

    NSMutableString *features = [NSMutableString string];
    NSArray *storeVersions = @[
            @"Generated Usernames\nSecurity Question Answers",
            @"TouchID Support"
    ];
    NSInteger storeVersion = [[NSUserDefaults standardUserDefaults] integerForKey:@"storeVersion"];
    for (; storeVersion < [storeVersions count]; ++storeVersion)
        [features appendFormat:@"%@\n", storeVersions[storeVersion]];
    if (![features length])
        return nil;

    [[NSUserDefaults standardUserDefaults] setInteger:storeVersion forKey:@"storeVersion"];
    if (![[NSUserDefaults standardUserDefaults] synchronize])
        wrn( @"Couldn't synchronize store version update." );
    return features;
}

- (void)viewDidLoad {

    [super viewDidLoad];

    self.currencyFormatter = [NSNumberFormatter new];
    self.currencyFormatter.numberStyle = NSNumberFormatterCurrencyStyle;

    self.tableView.tableHeaderView = [UIView new];
    self.tableView.tableFooterView = [UIView new];
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 400;
    self.view.backgroundColor = [UIColor clearColor];
}

- (void)viewWillAppear:(BOOL)animated {

    [super viewWillAppear:animated];

    self.tableView.contentInset = UIEdgeInsetsMake( 64, 0, 49, 0 );

    [self updateCellsHiding:self.allCellsBySection[0] showing:@[ self.loadingCell ]];
    [self.allCellsBySection[0] enumerateObjectsUsingBlock:^(MPStoreProductCell *cell, NSUInteger idx, BOOL *stop) {
        if ([cell isKindOfClass:[MPStoreProductCell class]]) {
            cell.purchasedIndicator.visible = NO;
            [cell.activityIndicator stopAnimating];
        }
    }];

    PearlAddNotificationObserver( NSUserDefaultsDidChangeNotification, nil, [NSOperationQueue mainQueue],
            ^(MPStoreViewController *self, NSNotification *note) {
                [self updateProducts];
                [self updateFuel];
            } );
    [[MPiOSAppDelegate get] registerProductsObserver:self];
    [self updateFuel];
}

- (void)viewWillDisappear:(BOOL)animated {

    [super viewWillDisappear:animated];

    PearlRemoveNotificationObservers();
}

#pragma mark - UITableViewDataSource

- (MPStoreProductCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    MPStoreProductCell *cell = (MPStoreProductCell *)[super tableView:tableView cellForRowAtIndexPath:indexPath];
    if (indexPath.section == 0)
        cell.selectionStyle = [[MPiOSAppDelegate get] isFeatureUnlocked:[self productForCell:cell].productIdentifier]?
                              UITableViewCellSelectionStyleNone: UITableViewCellSelectionStyleDefault;

    if (cell.selectionStyle != UITableViewCellSelectionStyleNone) {
        cell.selectedBackgroundView = [[UIView alloc] initWithFrame:cell.bounds];
        cell.selectedBackgroundView.backgroundColor = [UIColor colorWithRGBAHex:0x78DDFB33];
    }

    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {

    return NO;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {

    return UITableViewAutomaticDimension;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    MPStoreProductCell *cell = (MPStoreProductCell *)[self tableView:tableView cellForRowAtIndexPath:indexPath];
    if (cell.selectionStyle == UITableViewCellSelectionStyleNone)
        return;

    SKProduct *product = [self productForCell:cell];
    if (product && ![[MPAppDelegate_Shared get] isFeatureUnlocked:product.productIdentifier])
        [[MPAppDelegate_Shared get] purchaseProductWithIdentifier:product.productIdentifier
                                                         quantity:[self quantityForProductIdentifier:product.productIdentifier]];

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Actions

- (IBAction)toggleFuelConsumption:(id)sender {

    NSUInteger fuelConsumption = [[MPiOSConfig get].developmentFuelConsumption unsignedIntegerValue];
    [MPiOSConfig get].developmentFuelConsumption = @((fuelConsumption + 1) % MPDevelopmentFuelConsumptionCount);
    [self updateProducts];
}

- (IBAction)restorePurchases:(id)sender {

    [PearlAlert showAlertWithTitle:@"Restore Previous Purchases" message:
                    @"This will check with Apple to find and activate any purchases you made from other devices."
                         viewStyle:UIAlertViewStyleDefault initAlert:nil
                 tappedButtonBlock:^(UIAlertView *alert, NSInteger buttonIndex) {
                     if (buttonIndex == [alert cancelButtonIndex])
                         return;

                     [[MPAppDelegate_Shared get] restoreCompletedTransactions];
                 } cancelTitle:@"Cancel" otherTitles:@"Find Purchases", nil];
}

- (IBAction)sendThanks:(id)sender {

    [[self dismissPopup].navigationController performSegueWithIdentifier:@"web" sender:
            [NSURL URLWithString:@"http://thanks.lhunath.com"]];
}

#pragma mark - MPInAppDelegate

- (void)updateWithProducts:(NSArray *)products {

    self.products = products;

    [self updateProducts];
}

- (void)updateWithTransaction:(SKPaymentTransaction *)transaction {

    MPStoreProductCell *cell = [self cellForProductIdentifier:transaction.payment.productIdentifier];
    if (!cell)
        return;

    switch (transaction.transactionState) {
        case SKPaymentTransactionStatePurchasing:
            [cell.activityIndicator startAnimating];
            break;
        case SKPaymentTransactionStatePurchased:
            [cell.activityIndicator stopAnimating];
            break;
        case SKPaymentTransactionStateFailed:
            [cell.activityIndicator stopAnimating];
            break;
        case SKPaymentTransactionStateRestored:
            [cell.activityIndicator stopAnimating];
            break;
        case SKPaymentTransactionStateDeferred:
            [cell.activityIndicator startAnimating];
            break;
    }
}

#pragma mark - Private

- (MPPasswordsViewController *)dismissPopup {

    for (UIViewController *vc = self; (vc = vc.parentViewController);)
        if ([vc isKindOfClass:[MPPasswordsViewController class]]) {
            MPPasswordsViewController *passwordsVC = (MPPasswordsViewController *)vc;
            [passwordsVC dismissPopdown:self];
            return passwordsVC;
        }

    return nil;
}

- (SKProduct *)productForCell:(MPStoreProductCell *)cell {

    for (SKProduct *product in self.products)
        if ([self cellForProductIdentifier:product.productIdentifier] == cell)
            return product;

    return nil;
}

- (MPStoreProductCell *)cellForProductIdentifier:(NSString *)productIdentifier {

    if ([productIdentifier isEqualToString:MPProductGenerateLogins])
        return self.generateLoginCell;
    if ([productIdentifier isEqualToString:MPProductGenerateAnswers])
        return self.generateAnswersCell;
    if ([productIdentifier isEqualToString:MPProductOSIntegration])
        return self.iOSIntegrationCell;
    if ([productIdentifier isEqualToString:MPProductTouchID])
        return self.touchIDCell;
    if ([productIdentifier isEqualToString:MPProductFuel])
        return self.fuelCell;

    return nil;
}

- (void)updateProducts {

    NSMutableArray *showCells = [NSMutableArray array];
    NSMutableArray *hideCells = [NSMutableArray array];
    [hideCells addObjectsFromArray:[self.allCellsBySection[0] array]];
    [hideCells addObject:self.loadingCell];

    for (SKProduct *product in self.products) {
        [self showCellForProductWithIdentifier:MPProductGenerateLogins ifProduct:product showingCells:showCells];
        [self showCellForProductWithIdentifier:MPProductGenerateAnswers ifProduct:product showingCells:showCells];
        [self showCellForProductWithIdentifier:MPProductOSIntegration ifProduct:product showingCells:showCells];
        [self showCellForProductWithIdentifier:MPProductTouchID ifProduct:product showingCells:showCells];
        [self showCellForProductWithIdentifier:MPProductFuel ifProduct:product showingCells:showCells];
    }

    [hideCells removeObjectsInArray:showCells];
    [self updateCellsHiding:hideCells showing:showCells];
}

- (void)updateFuel {

    CGFloat weeklyFuelConsumption = [self weeklyFuelConsumption]; /* consume x fuel / week */
    CGFloat fuelRemaining = [[MPiOSConfig get].developmentFuelRemaining floatValue]; /* x fuel left */
    CGFloat fuelInvested = [[MPiOSConfig get].developmentFuelInvested floatValue]; /* x fuel left */
    NSDate *now = [NSDate date];
    NSTimeInterval fuelSecondsElapsed = -[[MPiOSConfig get].developmentFuelChecked timeIntervalSinceDate:now];
    if (fuelSecondsElapsed > 3600 || ![MPiOSConfig get].developmentFuelChecked) {
        NSTimeInterval weeksElapsed = fuelSecondsElapsed / (3600 * 24 * 7 /* 1 week */); /* x weeks elapsed */
        NSTimeInterval fuelConsumed = weeklyFuelConsumption * weeksElapsed;
        fuelRemaining -= fuelConsumed;
        fuelInvested += fuelConsumed;
        [MPiOSConfig get].developmentFuelChecked = now;
        [MPiOSConfig get].developmentFuelRemaining = @(fuelRemaining);
        [MPiOSConfig get].developmentFuelInvested = @(fuelInvested);
    }

    CGFloat fuelRatio = weeklyFuelConsumption == 0? 0: fuelRemaining / weeklyFuelConsumption; /* x weeks worth of fuel left */
    [self.fuelMeterConstraint updateConstant:MIN( 0.5f, fuelRatio - 0.5f ) * 160]; /* -80pt = 0 weeks left, 80pt = >=1 week left */
    self.fuelStatusLabel.text = strf( @"fuel left: %0.1f work hours\ninvested: %0.1f work hours", fuelRemaining, fuelInvested );
    self.fuelStatusLabel.hidden = (fuelRemaining + fuelInvested) == 0;
}

- (CGFloat)weeklyFuelConsumption {

    switch ((MPDevelopmentFuelConsumption)[[MPiOSConfig get].developmentFuelConsumption unsignedIntegerValue]) {
        case MPDevelopmentFuelConsumptionQuarterly:
            [self.fuelSpeedButton setTitle:@"1h / quarter" forState:UIControlStateNormal];
            return 1.f / 12 /* 12 weeks */;
        case MPDevelopmentFuelConsumptionMonthly:
            [self.fuelSpeedButton setTitle:@"1h / month" forState:UIControlStateNormal];
            return 1.f / 4 /* 4 weeks */;
        case MPDevelopmentFuelWeekly:
            [self.fuelSpeedButton setTitle:@"1h / week" forState:UIControlStateNormal];
            return 1.f;
    }

    return 0;
}

- (void)showCellForProductWithIdentifier:(NSString *)productIdentifier ifProduct:(SKProduct *)product
                            showingCells:(NSMutableArray *)showCells {

    if (![product.productIdentifier isEqualToString:productIdentifier])
        return;

    MPStoreProductCell *cell = [self cellForProductIdentifier:productIdentifier];
    [showCells addObject:cell];

    self.currencyFormatter.locale = product.priceLocale;
    BOOL purchased = [[MPiOSAppDelegate get] isFeatureUnlocked:productIdentifier];
    NSInteger quantity = [self quantityForProductIdentifier:productIdentifier];
    cell.priceLabel.text = purchased? @"": [self.currencyFormatter stringFromNumber:@([product.price floatValue] * quantity)];
    cell.purchasedIndicator.visible = purchased;
}

- (NSInteger)quantityForProductIdentifier:(NSString *)productIdentifier {

    if ([productIdentifier isEqualToString:MPProductFuel])
        return (NSInteger)(MP_FUEL_HOURLY_RATE * [self weeklyFuelConsumption] + .5f);

    return 1;
}

@end

@implementation MPStoreProductCell
@end
