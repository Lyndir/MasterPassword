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
#import "MPSitesViewController.h"

PearlEnum( MPDevelopmentFuelConsumption,
        MPDevelopmentFuelConsumptionQuarterly, MPDevelopmentFuelConsumptionMonthly, MPDevelopmentFuelWeekly );

@interface MPStoreViewController()<MPInAppDelegate>

@property(nonatomic, strong) NSDictionary<NSString *, SKProduct *> *products;
@property(nonatomic, strong) NSDictionary<NSString *, SKPaymentTransaction *> *transactions;
@property(nonatomic, strong) NSMutableArray<NSArray *> *dataSource;

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
        [features appendFormat:@"%@\n", storeVersions[(NSUInteger)storeVersion]];
    if (![features length])
        return nil;

    [[NSUserDefaults standardUserDefaults] setInteger:storeVersion forKey:@"storeVersion"];
    if (![[NSUserDefaults standardUserDefaults] synchronize])
        wrn( @"Couldn't synchronize store version update." );
    return features;
}

- (void)viewDidLoad {

    [super viewDidLoad];

    self.tableView.tableHeaderView = [UIView new];
    self.tableView.tableFooterView = [UIView new];
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 400;
    self.view.backgroundColor = [UIColor clearColor];

    self.dataSource = [@[ @[], @[ @"MPStoreCellSpinner", @"MPStoreCellFooter" ] ] mutableCopy];
}

- (void)viewWillAppear:(BOOL)animated {

    [super viewWillAppear:animated];

    self.tableView.contentInset = UIEdgeInsetsMake( 64, 0, 49, 0 );

    [[MPiOSAppDelegate get] registerProductsObserver:self];
}

- (void)viewWillDisappear:(BOOL)animated {

    [super viewWillDisappear:animated];

    [[MPiOSAppDelegate get] removeProductsObserver:self];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    return [self.dataSource count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return [self.dataSource[(NSUInteger)section] count];
}

- (MPStoreProductCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    id content = self.dataSource[(NSUInteger)indexPath.section][(NSUInteger)indexPath.row];
    if ([content isKindOfClass:[SKProduct class]]) {
        SKProduct *product = content;
        MPStoreProductCell *cell;
        if ([product.productIdentifier isEqualToString:MPProductFuel])
            cell = [MPStoreFuelProductCell dequeueCellFromTableView:tableView indexPath:indexPath];
        else
            cell = [MPStoreProductCell dequeueCellFromTableView:tableView indexPath:indexPath];
        [cell updateWithProduct:product transaction:self.transactions[product.productIdentifier]];

        return cell;
    }

    return [tableView dequeueReusableCellWithIdentifier:content forIndexPath:indexPath];
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {

    return UITableViewAutomaticDimension;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    UITableViewCell *cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];
    if (cell.selectionStyle != UITableViewCellSelectionStyleNone && [cell isKindOfClass:[MPStoreProductCell class]]) {
        MPStoreProductCell *productCell = (MPStoreProductCell *)cell;

        if (productCell.product && ![[MPAppDelegate_Shared get] isFeatureUnlocked:productCell.product.productIdentifier])
            [[MPAppDelegate_Shared get] purchaseProductWithIdentifier:productCell.product.productIdentifier quantity:productCell.quantity];
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Actions

- (IBAction)toggleFuelConsumption:(id)sender {

    NSUInteger fuelConsumption = [[MPiOSConfig get].developmentFuelConsumption unsignedIntegerValue];
    [MPiOSConfig get].developmentFuelConsumption = @((fuelConsumption + 1) % MPDevelopmentFuelConsumptionCount);

    [self.tableView updateDataSource:self.dataSource toSections:nil reloadItems:@[ self.products[MPProductFuel] ]
                    withRowAnimation:UITableViewRowAnimationAutomatic];
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
            [NSURL URLWithString:@"https://thanks.lhunath.com"]];
}

#pragma mark - MPInAppDelegate

- (void)updateWithProducts:(NSDictionary<NSString *, SKProduct *> *)products
              transactions:(NSDictionary<NSString *, SKPaymentTransaction *> *)transactions {

    self.products = products;
    self.transactions = transactions;
    NSMutableArray *newDataSource = [NSMutableArray arrayWithCapacity:2];

    // Section 0: products
    [newDataSource addObject:[[products allValues] sortedArrayUsingComparator:
            ^NSComparisonResult(SKProduct *p1, SKProduct *p2) {
                return [p1.productIdentifier compare:p2.productIdentifier];
            }]];
    NSArray *reloadProducts = [newDataSource[0] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:
            ^BOOL(SKProduct *product, NSDictionary *bindings) {
                return self.transactions[product.productIdentifier] != nil;
            }]];

    // Section 1: information cells
    [newDataSource addObject:@[ @"MPStoreCellFooter" ]];

    [self.tableView updateDataSource:self.dataSource toSections:newDataSource
                         reloadItems:reloadProducts withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - Private

- (MPSitesViewController *)dismissPopup {

    for (UIViewController *vc = self; (vc = vc.parentViewController);)
        if ([vc isKindOfClass:[MPSitesViewController class]]) {
            MPSitesViewController *passwordsVC = (MPSitesViewController *)vc;
            [passwordsVC dismissPopdown:self];
            return passwordsVC;
        }

    return nil;
}

@end

@implementation MPStoreProductCell

- (void)updateWithProduct:(SKProduct *)product transaction:(SKPaymentTransaction *)transaction {

    _product = product;

    BOOL purchased = [[MPiOSAppDelegate get] isFeatureUnlocked:self.product.productIdentifier];
    self.selectionStyle = purchased? UITableViewCellSelectionStyleNone: UITableViewCellSelectionStyleDefault;
    self.selectedBackgroundView = self.selectionStyle == UITableViewCellSelectionStyleNone? nil: [[UIView alloc] initWithFrame:self.bounds];
    self.selectedBackgroundView.backgroundColor = [UIColor colorWithRGBAHex:0x78DDFB33];

    self.purchasedIndicator.visible = purchased;
    self.priceLabel.text = purchased? @"": [self price];
    self.titleLabel.text = product.localizedTitle;
    self.descriptionLabel.text = product.localizedDescription;
    self.thumbnailView.image = [self productImage];

    if (transaction && (transaction.transactionState == SKPaymentTransactionStateDeferred ||
                        transaction.transactionState == SKPaymentTransactionStatePurchasing))
        [self.activityIndicator startAnimating];
    else
        [self.activityIndicator stopAnimating];
}

- (UIImage *)productImage {

    if ([MPProductGenerateLogins isEqualToString:self.product.productIdentifier])
        return [UIImage imageNamed:@"thumb_generated_login"];
    if ([MPProductGenerateAnswers isEqualToString:self.product.productIdentifier])
        return [UIImage imageNamed:@"thumb_generated_answers"];
    if ([MPProductOSIntegration isEqualToString:self.product.productIdentifier])
        return [UIImage imageNamed:@"thumb_ios_integration"];
    if ([MPProductTouchID isEqualToString:self.product.productIdentifier])
        return [UIImage imageNamed:@"thumb_touch_id"];
    if ([MPProductFuel isEqualToString:self.product.productIdentifier])
        return [UIImage imageNamed:@"thumb_fuel"];

    return nil;
}

- (NSString *)price {

    NSNumberFormatter *currencyFormatter = [NSNumberFormatter new];
    currencyFormatter.numberStyle = NSNumberFormatterCurrencyStyle;
    currencyFormatter.locale = self.product.priceLocale;

    return [currencyFormatter stringFromNumber:@([self.product.price floatValue] * self.quantity)];
}

- (NSInteger)quantity {

    return 1;
}

@end

@implementation MPStoreFuelProductCell

- (void)updateWithProduct:(SKProduct *)product transaction:(SKPaymentTransaction *)transaction {

    [super updateWithProduct:product transaction:transaction];

    CGFloat weeklyFuelConsumption = [self weeklyFuelConsumption]; /* consume x fuel / week */
    [self.fuelSpeedButton setTitle:[self weeklyFuelConsumptionTitle] forState:UIControlStateNormal];

    NSTimeInterval fuelSecondsElapsed = 0;
    CGFloat fuelRemaining = [[MPiOSConfig get].developmentFuelRemaining floatValue]; /* x fuel left */
    CGFloat fuelInvested = [[MPiOSConfig get].developmentFuelInvested floatValue]; /* x fuel left */
    NSDate *now = [NSDate date], *checked = [MPiOSConfig get].developmentFuelChecked;
    if (!checked || 3600 < (fuelSecondsElapsed = [now timeIntervalSinceDate:checked])) {
        NSTimeInterval weeksElapsed = fuelSecondsElapsed / (3600 * 24 * 7 /* 1 week */); /* x weeks elapsed */
        NSTimeInterval fuelConsumed = MIN( fuelRemaining, weeklyFuelConsumption * weeksElapsed );
        fuelRemaining -= fuelConsumed;
        fuelInvested += fuelConsumed;
        [MPiOSConfig get].developmentFuelChecked = now;
        [MPiOSConfig get].developmentFuelRemaining = @(fuelRemaining);
        [MPiOSConfig get].developmentFuelInvested = @(fuelInvested);
    }

    CGFloat fuelRatio = weeklyFuelConsumption? fuelRemaining / weeklyFuelConsumption: 0; /* x weeks worth of fuel left */
    [self.fuelMeterConstraint updateConstant:MIN( 0.5f, fuelRatio - 0.5f ) * 160]; /* -80pt = 0 weeks left, +80pt = >=1 week left */
    self.fuelStatusLabel.text = strf( @"Fuel left: %0.1f work hours\nFunded: %0.1f work hours", fuelRemaining, fuelInvested );
    self.fuelStatusLabel.hidden = (fuelRemaining + fuelInvested) == 0;
}

- (NSInteger)quantity {

    return MAX( 1, (NSInteger)ceil( MP_FUEL_HOURLY_RATE * [self weeklyFuelConsumption] ) );
}

- (CGFloat)weeklyFuelConsumption {

    switch ((MPDevelopmentFuelConsumption)[[MPiOSConfig get].developmentFuelConsumption unsignedIntegerValue]) {
        case MPDevelopmentFuelConsumptionQuarterly:
            return 1.f / 12 /* 12 weeks */;
        case MPDevelopmentFuelConsumptionMonthly:
            return 1.f / 4 /* 4 weeks */;
        case MPDevelopmentFuelWeekly:
            return 1.f /* 1 week */;
    }

    return 0;
}

- (NSString *)weeklyFuelConsumptionTitle {

    switch ((MPDevelopmentFuelConsumption)[[MPiOSConfig get].developmentFuelConsumption unsignedIntegerValue]) {
        case MPDevelopmentFuelConsumptionQuarterly:
            return @"1h / quarter";
        case MPDevelopmentFuelConsumptionMonthly:
            return @"1h / month";
        case MPDevelopmentFuelWeekly:
            return @"1h / week";
    }

    return nil;
}

@end
