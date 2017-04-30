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

@class MPStoreProductCell;

@interface MPStoreViewController : PearlMutableStaticTableViewController

@property(weak, nonatomic) IBOutlet MPStoreProductCell *generateLoginCell;
@property(weak, nonatomic) IBOutlet MPStoreProductCell *generateAnswersCell;
@property(weak, nonatomic) IBOutlet MPStoreProductCell *iOSIntegrationCell;
@property(weak, nonatomic) IBOutlet MPStoreProductCell *touchIDCell;
@property(weak, nonatomic) IBOutlet MPStoreProductCell *fuelCell;
@property(weak, nonatomic) IBOutlet UITableViewCell *loadingCell;
@property(weak, nonatomic) IBOutlet NSLayoutConstraint *fuelMeterConstraint;
@property(weak, nonatomic) IBOutlet UIButton *fuelSpeedButton;
@property(weak, nonatomic) IBOutlet UILabel *fuelStatusLabel;

+ (NSString *)latestStoreFeatures;

@end

@interface MPStoreProductCell : UITableViewCell

@property(nonatomic) IBOutlet UILabel *priceLabel;
@property(nonatomic) IBOutlet UILabel *titleLabel;
@property(nonatomic) IBOutlet UILabel *descriptionLabel;
@property(nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property(nonatomic) IBOutlet UIView *purchasedIndicator;

@end
