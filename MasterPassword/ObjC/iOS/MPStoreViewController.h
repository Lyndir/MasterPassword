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

@end

@interface MPStoreProductCell : UITableViewCell

@property(nonatomic) IBOutlet UILabel *priceLabel;
@property(nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property(nonatomic) IBOutlet UIView *purchasedIndicator;

@end
