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

    self.searchDisplayController.searchBar.placeholder = self.activeElement.name;
    self.siteName.text = self.activeElement.name;
    
    self.passwordCounter.alpha = self.activeElement.type & OPElementTypeCalculated? 1: 0;
    self.passwordIncrementer.alpha = self.activeElement.type & OPElementTypeCalculated? 1: 0;

    [self.typeButton setTitle:NSStringFromOPElementType(self.activeElement.type)
                     forState:UIControlStateNormal];

    self.contentField.enabled = self.editing && self.activeElement.type & OPElementTypeStored;
    self.contentField.clearButtonMode = self.contentField.enabled? UITextFieldViewModeAlways: UITextFieldViewModeNever;
    self.contentField.text = @"...";

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSString *contentDescription = self.activeElement.contentDescription;
        dispatch_async(dispatch_get_main_queue(), ^{
            self.contentField.text = contentDescription;
        });
    });
}

#pragma mark - Protocols

- (IBAction)didChangeContentType:(UISegmentedControl *)sender {
    
    [self updateAnimated:YES];
}

- (IBAction)didTriggerContent:(id)sender {
    
    [[UIPasteboard generalPasteboard] setValue:self.activeElement.content
                             forPasteboardType:self.activeElement.contentUTI];
}

- (IBAction)didIncrementPasswordCounter {
}

- (void)didSelectType:(OPElementType)type {
    
    self.activeElement.type = type;
    [self updateAnimated:YES];
}

- (void)didSelectElement:(OPElementEntity *)element {
    
    self.activeElement = element;
    [self.activeElement use];
    [self updateAnimated:YES];

    self.searchDisplayController.searchBar.text = @"";
    [self.searchDisplayController setActive:NO animated:YES];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    
    [self updateAnimated:YES];
}

@end
