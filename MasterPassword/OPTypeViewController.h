//
//  OPTypeViewController.h
//  MasterPassword
//
//  Created by Maarten Billemont on 27/11/11.
//  Copyright (c) 2011 Lyndir. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol OPTypeDelegate <NSObject>

- (void)didSelectType:(OPElementType)type;

@end

@interface OPTypeViewController : UITableViewController

@property (nonatomic, weak) id<OPTypeDelegate> delegate;

@end
