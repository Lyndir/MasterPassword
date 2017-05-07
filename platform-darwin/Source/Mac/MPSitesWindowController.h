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

#import <Cocoa/Cocoa.h>
#import "MPSiteModel.h"
#import "MPSitesTableView.h"
#import "MPSitesWindow.h"

@class MPMacAppDelegate;

@interface MPSitesWindowController : NSWindowController<NSTextViewDelegate, NSTextFieldDelegate, NSTableViewDataSource, NSTableViewDelegate>

@property(nonatomic) NSMutableArray *sites;
@property(nonatomic) NSString *masterPassword;
@property(nonatomic) BOOL showVersionContainer;
@property(nonatomic) BOOL alternatePressed;
@property(nonatomic) BOOL shiftPressed;
@property(nonatomic) BOOL locked;
@property(nonatomic) BOOL newUser;

@property(nonatomic, weak) IBOutlet NSArrayController *sitesController;
@property(nonatomic, weak) IBOutlet NSTextField *inputLabel;
@property(nonatomic, weak) IBOutlet NSTextField *securePasswordField;
@property(nonatomic, weak) IBOutlet NSTextField *revealPasswordField;
@property(nonatomic, weak) IBOutlet NSTextField *sitePasswordTipField;
@property(nonatomic, weak) IBOutlet NSSearchField *siteField;
@property(nonatomic, weak) IBOutlet MPSitesTableView *siteTable;
@property(nonatomic, weak) IBOutlet NSProgressIndicator *progressView;

@property(nonatomic, strong) IBOutlet NSBox *passwordTypesBox;
@property(nonatomic, weak) IBOutlet NSMatrix *passwordTypesMatrix;

@property(nonatomic, strong) IBOutlet NSBox *securityQuestionsBox;
@property(nonatomic, weak) IBOutlet NSTextField *securityQuestionField;
@property(nonatomic, weak) IBOutlet NSTextField *securityAnswerField;

- (BOOL)handleCommand:(SEL)commandSelector;

@end
