//
//  OPMainViewController.m
//  OnePassword
//
//  Created by Maarten Billemont on 24/11/11.
//  Copyright (c) 2011 Lyndir. All rights reserved.
//

#import "OPMainViewController.h"
#import "OPAppDelegate.h"
#import "OPContentViewController.h"
#import "OPElementGeneratedEntity.h"
#import "OPElementStoredEntity.h"

#import <MobileCoreServices/MobileCoreServices.h>


@interface OPMainViewController (Private)

- (void)updateAnimated:(BOOL)animated;
- (void)updateWasAnimated:(BOOL)animated;

@end

@implementation OPMainViewController
@synthesize activeElement = _activeElement;
@synthesize searchResultsController = _searchResultsController;
@synthesize typeButton = _typeButton;
@synthesize helpView = _helpView;
@synthesize siteName = _siteName;
@synthesize passwordCounter = _passwordCounter;
@synthesize passwordIncrementer = _passwordIncrementer;
@synthesize passwordEdit = _passwordEdit;
@synthesize contentContainer = _contentContainer;
@synthesize helpContainer = _helpContainer;
@synthesize contentField = _contentField;

#pragma mark - View lifecycle

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    
    return [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad || interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([[segue identifier] isEqualToString:@"OP_Main_ChooseType"])
        [[segue destinationViewController] setDelegate:self];
    if ([[segue identifier] isEqualToString:@"OP_Main_Content"])
        ((OPContentViewController *)[segue destinationViewController]).activeElement = self.activeElement;
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    [self toggleHelp:[[OPConfig get].helpHidden boolValue]];
    [self updateAnimated:NO];
}

- (void)viewDidLoad {
    
    // Because IB's edit button doesn't auto-toggle self.editable like editButtonItem does.
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"background"]];
    
    [super viewDidLoad];
}

- (void)viewDidUnload {
    
    [self setContentField:nil];
    [self setTypeButton:nil];
    [self setSearchResultsController:nil];
    [self setHelpView:nil];
    [self setSiteName:nil];
    [self setPasswordCounter:nil];
    [self setPasswordIncrementer:nil];
    [self setPasswordEdit:nil];
    [self setContentContainer:nil];
    [self setHelpContainer:nil];
    [super viewDidUnload];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    
    [super setEditing:editing animated:animated];
    
    [self updateAnimated:animated];
}

- (void)updateAnimated:(BOOL)animated {
    
    [[OPAppDelegate get] saveContext];
    
    if (animated)
        [UIView animateWithDuration:0.2 animations:^{
            [self updateWasAnimated:YES];
        }];
    else
        [self updateWasAnimated:NO];
}

- (void)updateWasAnimated:(BOOL)animated {
    
    NSUInteger chapter = self.activeElement? 2: 1;
    [self.helpView loadRequest:
     [NSURLRequest requestWithURL:
      [NSURL URLWithString:[NSString stringWithFormat:@"#%d", chapter] relativeToURL:
       [[NSBundle mainBundle] URLForResource:@"help" withExtension:@"html"]]]];
    
    [self.navigationItem setRightBarButtonItem:self.activeElement.type & OPElementTypeStored? self.editButtonItem: nil animated:animated];
    
    self.siteName.text = self.activeElement.name;
    
    self.passwordCounter.alpha = self.activeElement.type & OPElementTypeCalculated? 0.5f: 0;
    self.passwordIncrementer.alpha = self.activeElement.type & OPElementTypeCalculated? 0.5f: 0;
    self.passwordEdit.alpha = self.activeElement.type & OPElementTypeStored? 0.5f: 0;
    
    [self.typeButton setTitle:NSStringFromOPElementType(self.activeElement.type)
                     forState:UIControlStateNormal];
    self.typeButton.alpha = NSStringFromOPElementType(self.activeElement.type).length? 1: 0;
    
    self.contentField.enabled = NO;
    
    if ([self.activeElement isKindOfClass:[OPElementGeneratedEntity class]])
        self.passwordCounter.text = [NSString stringWithFormat:@"%d", ((OPElementGeneratedEntity *) self.activeElement).counter];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSString *contentDescription = self.activeElement.contentDescription;
        dispatch_async(dispatch_get_main_queue(), ^{
            self.contentField.text = contentDescription;
        });
    });
}

#pragma mark - Protocols

- (IBAction)copyContent {
    
    [[UIPasteboard generalPasteboard] setValue:self.activeElement.content
                             forPasteboardType:self.activeElement.contentUTI];
}

- (IBAction)incrementPasswordCounter {
    
    if ([self.activeElement isKindOfClass:[OPElementGeneratedEntity class]])
        [AlertViewController showAlertWithTitle:@"Change Password"
                                        message:l(@"Setting a new password for %@.\n"
                                                  @"Don't forget to update your password on the site as well!", self.activeElement.name)
                              tappedButtonBlock:^(NSInteger buttonIndex) {
                                  if (!buttonIndex)
                                      return;
                                  
                                  // Update password counter.
                                  if ([self.activeElement isKindOfClass:[OPElementGeneratedEntity class]]) {
                                      ++((OPElementGeneratedEntity *) self.activeElement).counter;
                                      [self updateAnimated:YES];
                                  }
                              } cancelTitle:[PearlStrings get].commonButtonAbort otherTitles:[PearlStrings get].commonButtonThanks, nil];
}

- (IBAction)editPassword {
    
    if (self.activeElement.type & OPElementTypeStored) {
        self.contentField.enabled = YES;
        [self.contentField becomeFirstResponder];
    }
}

- (IBAction)toggleHelp {
    
    [UIView animateWithDuration:0.3f animations:^{
        if (self.helpContainer.frame.origin.y < 400)
            [self toggleHelp:YES];
        else
            [self toggleHelp:NO];
    }];
}

- (void)toggleHelp:(BOOL)hidden {
    
        if (hidden) {
            self.contentContainer.frame = CGRectSetHeight(self.contentContainer.frame, 373);
            //self.helpContainer.frame = CGRectSetHeight(self.helpContainer.frame, 0);
            self.helpContainer.frame = CGRectSetY(self.helpContainer.frame, 414);
            [OPConfig get].helpHidden = [NSNumber numberWithBool:YES];
        } else {
            self.contentContainer.frame = CGRectSetHeight(self.contentContainer.frame, 155);
            //self.helpContainer.frame = CGRectSetHeight(self.helpContainer.frame, 219);
            self.helpContainer.frame = CGRectSetY(self.helpContainer.frame, 196);
            [OPConfig get].helpHidden = [NSNumber numberWithBool:NO];
        }
}

- (void)didSelectType:(OPElementType)type {
    
    [AlertViewController showAlertWithTitle:@"Change Password Type"
                                    message:l(@"Changing the type of %@'s password.\n"
                                              @"Don't forget to update your password on the site as well!", self.activeElement.name)
                          tappedButtonBlock:^(NSInteger buttonIndex) {
                              if (!buttonIndex)
                                  return;
                              
                              // Update password type.
                              if (ClassForOPElementType(type) != ClassForOPElementType(self.activeElement.type)) {
                                  // Type requires a different class of element.  Recreate the element.
                                  OPElementEntity *newElement = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass(ClassForOPElementType(type))
                                                                                              inManagedObjectContext:[OPAppDelegate managedObjectContext]];
                                  
                                  newElement.name = self.activeElement.name;
                                  newElement.uses = self.activeElement.uses;
                                  newElement.lastUsed = self.activeElement.lastUsed;
                                  newElement.contentUTI = self.activeElement.contentUTI;
                                  newElement.contentType = self.activeElement.contentType;
                                  
                                  [[OPAppDelegate managedObjectContext] deleteObject:self.activeElement];
                                  self.activeElement = newElement;
                              }
                              self.activeElement.type = type;
                              
                              // Redraw.
                              [self updateAnimated:YES];
                          } cancelTitle:[PearlStrings get].commonButtonAbort otherTitles:[PearlStrings get].commonButtonThanks, nil];
}

- (void)didSelectElement:(OPElementEntity *)element {
    
    self.activeElement = element;
    [self.activeElement use];
    
    [self.searchDisplayController setActive:NO animated:YES];
    self.searchDisplayController.searchBar.text = self.activeElement.name;
    
    [self updateAnimated:YES];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    
    [self updateAnimated:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    if (textField == self.contentField)
        [self.contentField resignFirstResponder];
    
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    
    if (textField == self.contentField) {
        self.contentField.enabled = NO;
        [AlertViewController showAlertWithTitle:@"Change Password"
                                        message:l(@"Setting a new password for %@.\n"
                                                  @"Don't forget to update your password on the site as well!", self.activeElement.name)
                              tappedButtonBlock:^(NSInteger buttonIndex) {
                                  if (buttonIndex) {
                                      // Update password content.
                                      if ([self.activeElement isKindOfClass:[OPElementStoredEntity class]])
                                          ((OPElementStoredEntity *) self.activeElement).contentObject = self.contentField.text;
                                  }
                                  
                                  // Redraw.
                                  [self updateAnimated:YES];
                              } cancelTitle:[PearlStrings get].commonButtonAbort otherTitles:[PearlStrings get].commonButtonThanks, nil];
    }
}

@end
