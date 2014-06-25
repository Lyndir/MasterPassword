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

@interface MPPasswordWindowController : NSWindowController<NSTextViewDelegate, NSTextFieldDelegate, NSTableViewDataSource, NSTableViewDelegate>

@property(nonatomic, strong) NSMutableArray *elements;

@property(nonatomic, weak) IBOutlet NSArrayController *elementsController;
@property(nonatomic, weak) IBOutlet NSImageView *blurView;
@property(nonatomic, weak) IBOutlet NSTextField *inputLabel;
@property(nonatomic, weak) IBOutlet NSSearchField *siteField;
@property(nonatomic, weak) IBOutlet NSSecureTextField *passwordField;
@property(nonatomic, weak) IBOutlet NSTableView *siteTable;
@property(nonatomic, weak) IBOutlet NSProgressIndicator *progressView;
@property(nonatomic, weak) IBOutlet NSButton *typeButton;
@property(nonatomic, weak) IBOutlet NSButton *loginButton;
@property(nonatomic, weak) IBOutlet NSView *counterContainer;
@property(nonatomic, weak) IBOutlet NSStepper *counterStepper;
@property(nonatomic, weak) IBOutlet NSTextField *counterLabel;

@end
