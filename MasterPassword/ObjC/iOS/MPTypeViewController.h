//
//  MPTypeViewController.h
//  MasterPassword
//
//  Created by Maarten Billemont on 27/11/11.
//  Copyright (c) 2011 Lyndir. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MPEntities.h"

@protocol MPTypeDelegate<NSObject>

@required
- (void)didSelectType:(MPSiteType)type;
- (MPSiteType)selectedType;

@optional
- (MPSiteEntity *)selectedElement;

@end

@interface MPTypeViewController : UITableViewController

@property(nonatomic, weak) id<MPTypeDelegate> delegate;
@property(weak, nonatomic) IBOutlet UIView *recommendedTipContainer;

@end
