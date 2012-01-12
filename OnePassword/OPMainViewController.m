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
@synthesize typeLabel = _typeLabel;
@synthesize contentType = _contentType;
@synthesize contentField = _contentField;
@synthesize contentTextView = _contentTextView;

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
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:animated];
}

- (void)viewDidLoad {
    
    // Because IB's edit button doesn't auto-toggle self.editable like editButtonItem does.
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Background.png"]];
    
    [super viewDidLoad];
}

- (void)viewDidUnload {
    
    [self setContentField:nil];
    [self setTypeLabel:nil];
    
    [self setContentType:nil];
    [self setContentTextView:nil];
    [self setSearchResultsController:nil];
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

    self.searchDisplayController.searchBar.placeholder = self.activeElement.name;

    self.typeLabel.text = self.activeElement? NSStringFromOPElementType(self.activeElement.type): @"";

    self.contentTextView.alpha = self.contentType.selectedSegmentIndex == OPElementContentTypeNote? 1: 0;
    self.contentTextView.editable = self.editing && self.activeElement.type & OPElementTypeStored;

    self.contentType.alpha = self.editing && self.activeElement.type & OPElementTypeStored? 1: 0;
    self.contentType.selectedSegmentIndex = self.activeElement.contentType;

    self.contentField.alpha = self.contentType.selectedSegmentIndex == OPElementContentTypePassword? 1: 0;
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
    
    self.activeElement.contentType = self.contentType.selectedSegmentIndex;
    [self updateAnimated:YES];
}

- (IBAction)didTriggerContent:(id)sender {
    
    [[UIPasteboard generalPasteboard] setValue:self.activeElement.content
                             forPasteboardType:self.activeElement.contentUTI];
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

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return NO;
}

@end
