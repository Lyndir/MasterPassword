/**
* Copyright Maarten Billemont (http://www.lhunath.com, lhunath@lyndir.com)
*
* See the enclosed file LICENSE for license information (LGPLv3). If you did
* not receive this file, see http://www.gnu.org/licenses/lgpl-3.0.txt
*
* @author   Maarten Billemont <lhunath@lyndir.com>
* @license  http://www.gnu.org/licenses/lgpl-3.0.txt
*/

//
//  MPPasswordWindowController.h
//  MPPasswordWindowController
//
//  Created by lhunath on 2014-06-18.
//  Copyright, lhunath (Maarten Billemont) 2014. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MPElementModel.h"
#import "MPElementsTableView.h"

@class MPMacAppDelegate;

@interface MPPasswordWindowController : NSWindowController<NSTextViewDelegate, NSTextFieldDelegate, NSTableViewDataSource, NSTableViewDelegate>

@property(nonatomic) NSMutableArray *elements;
@property(nonatomic) NSString *masterPassword;
@property(nonatomic) BOOL alternatePressed;
@property(nonatomic) BOOL locked;
@property(nonatomic) BOOL newUser;

@property(nonatomic, weak) IBOutlet NSArrayController *elementsController;
@property(nonatomic, weak) IBOutlet NSImageView *blurView;
@property(nonatomic, weak) IBOutlet NSTextField *inputLabel;
@property(nonatomic, weak) IBOutlet NSTextField *securePasswordField;
@property(nonatomic, weak) IBOutlet NSTextField *revealPasswordField;
@property(nonatomic, weak) IBOutlet NSSearchField *siteField;
@property(nonatomic, weak) IBOutlet MPElementsTableView *siteTable;
@property(nonatomic, weak) IBOutlet NSProgressIndicator *progressView;

@property(nonatomic, strong) IBOutlet NSBox *passwordTypesBox;
@property(nonatomic, weak) IBOutlet NSMatrix *passwordTypesMatrix;

- (BOOL)handleCommand:(SEL)commandSelector;

@end
