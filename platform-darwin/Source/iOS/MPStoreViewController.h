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

#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>

@class MPStoreProductCell;

@interface MPStoreViewController : UITableViewController

+ (NSString *)latestStoreFeatures;

@end

@interface MPStoreProductCell : UITableViewCell

@property(nonatomic) IBOutlet UILabel *priceLabel;
@property(nonatomic) IBOutlet UILabel *titleLabel;
@property(nonatomic) IBOutlet UILabel *descriptionLabel;
@property(nonatomic) IBOutlet UIImageView *thumbnailView;
@property(nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property(nonatomic) IBOutlet UIView *purchasedIndicator;

@property(nonatomic, readonly) SKProduct *product;
@property(nonatomic, readonly) NSInteger quantity;

- (void)updateWithProduct:(SKProduct *)product transaction:(SKPaymentTransaction *)transaction;

@end

@interface MPStoreFuelProductCell : MPStoreProductCell

@property(weak, nonatomic) IBOutlet NSLayoutConstraint *fuelMeterConstraint;
@property(weak, nonatomic) IBOutlet UIButton *fuelSpeedButton;
@property(weak, nonatomic) IBOutlet UILabel *fuelStatusLabel;

@end
