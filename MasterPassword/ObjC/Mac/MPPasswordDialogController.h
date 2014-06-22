//
//  MPPasswordDialogController.h
//  MasterPassword-Mac
//
//  Created by Maarten Billemont on 04/03/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class MPElementModel;

@interface MPPasswordDialogController : NSWindowController<NSTextFieldDelegate, NSCollectionViewDelegate>

@property(nonatomic, strong) NSMutableArray *elements;
@property(nonatomic, strong) NSIndexSet *elementSelectionIndexes;
@property(nonatomic, weak) IBOutlet NSTextField *siteField;
@property(nonatomic, weak) IBOutlet NSView *contentContainer;
@property(nonatomic, weak) IBOutlet NSTextField *userLabel;
@property(nonatomic, weak) IBOutlet NSCollectionView *siteCollectionView;

- (void)updateElements;

@end
