//
//  MPPreferencesViewController.h
//  MasterPassword-iOS
//
//  Created by Maarten Billemont on 04/06/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

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
@property(nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property(nonatomic) IBOutlet UIView *purchasedIndicator;

@end
