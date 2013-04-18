//
//  MPSearchDelegate.m
//  MasterPassword
//
//  Created by Maarten Billemont on 04/01/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import "MPElementListSearchController.h"
#import "MPMainViewController.h"
#import "MPAppDelegate.h"

@interface MPElementListSearchController ()

@property (nonatomic) BOOL newSiteSectionWasNeeded;

@end

@implementation MPElementListSearchController
@synthesize searchDisplayController;

- (id)init {

    if (!(self = [super init]))
        return nil;

    self.tipView                  = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, 170)];
    self.tipView.textAlignment    = NSTextAlignmentCenter;
    self.tipView.backgroundColor  = [UIColor clearColor];
    self.tipView.textColor        = [UIColor lightTextColor];
    self.tipView.shadowColor      = [UIColor blackColor];
    self.tipView.shadowOffset     = CGSizeMake(0, -1);
    self.tipView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight
     | UIViewAutoresizingFlexibleBottomMargin;
    self.tipView.numberOfLines    = 0;
    self.tipView.font             = [UIFont systemFontOfSize:14];
    self.tipView.text =
     @"Tip:\n"
      @"Name your sites by their domain name:\n"
      @"apple.com, twitter.com\n\n"
      @"For email accounts, use the address:\n"
      @"john@apple.com, john@gmail.com";

    return self;
}

- (void)searchBarBookmarkButtonClicked:(UISearchBar *)searchBar {

    [((MPMainViewController *)self.delegate) performSegueWithIdentifier:@"MP_AllSites" sender:MPElementListFilterNone];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {

    // Simulate a tap on the first visible row.
    UITableView *tableView = self.searchDisplayController.searchResultsTableView;
    for (NSInteger section = 0; section < [self numberOfSectionsInTableView:tableView]; ++section) {

        if (![self tableView:tableView numberOfRowsInSection:section])
            continue;

        [self tableView:tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:section]];
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {

    [self.delegate didSelectElement:nil];
}

- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller {

    controller.searchBar.text                  = @"";

    [UIView animateWithDuration:0.2f animations:^{
        self.searchTipContainer.alpha = 0;
    }];
}

- (void)searchDisplayControllerDidBeginSearch:(UISearchDisplayController *)controller {

    [self updateData];
}

- (void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller {

    controller.searchBar.prompt                      = nil;
    controller.searchBar.searchResultsButtonSelected = NO;
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView {

    tableView.backgroundColor = [UIColor blackColor];
    tableView.separatorStyle  = UITableViewCellSeparatorStyleNone;
    tableView.rowHeight       = 48.0f;

    self.tableView = tableView;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {

    [self updateData];
    return NO;
}

- (void)updateData {
    
    [super updateData];

    UISearchBar *searchBar = self.searchDisplayController.searchBar;
    CGRect searchBarFrame = searchBar.frame;
    [searchBar.superview enumerateSubviews:^(UIView *subview, BOOL *stop, BOOL *recurse) {

        if ([subview isKindOfClass:[UIControl class]] &&
                CGPointEqualToPoint(
                        CGPointDistanceBetweenCGPoints(searchBarFrame.origin, subview.frame.origin),
                        CGPointMake(0, searchBarFrame.size.height))) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tipView removeFromSuperview];
                [subview addSubview:self.tipView];
            });

            *stop = YES;
        }
    }                              recurse:NO];
}

- (BOOL)newSiteSectionNeeded {

    NSString *query = [self.searchDisplayController.searchBar.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (![query length])
        return NO;

    __block BOOL hasExactQueryMatch = NO;
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsControllerByUses sections] lastObject];
    [[sectionInfo objects] enumerateObjectsUsingBlock:^(id obj_, NSUInteger idx_, BOOL *stop_) {
        if ([[obj_ name] isEqualToString:query]) {
            hasExactQueryMatch = YES;
            *stop_ = YES;
        }
    }];
    if (hasExactQueryMatch)
        return NO;

    sectionInfo = [[self.fetchedResultsControllerByLastUsed sections] lastObject];
    [[sectionInfo objects] enumerateObjectsUsingBlock:^(id obj_, NSUInteger idx_, BOOL *stop_) {
        if ([[obj_ name] isEqualToString:query]) {
            hasExactQueryMatch = YES;
            *stop_ = YES;
        }
    }];
    if (hasExactQueryMatch)
        return NO;

    return YES;
}

- (void)customTableViewUpdates {

    BOOL newSiteSectionIsNeeded = [self newSiteSectionNeeded];
    if (newSiteSectionIsNeeded && !self.newSiteSectionWasNeeded)
        [self.tableView insertSections:[NSIndexSet indexSetWithIndex:2]
                      withRowAnimation:UITableViewRowAnimationAutomatic];
    else if (!newSiteSectionIsNeeded && self.newSiteSectionWasNeeded)
        [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:2]
                      withRowAnimation:UITableViewRowAnimationAutomatic];
    self.newSiteSectionWasNeeded = newSiteSectionIsNeeded;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    NSInteger sectionCount = [super numberOfSectionsInTableView:tableView];
    if ([self newSiteSectionNeeded])
        ++sectionCount;

    return sectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    if (section < [super numberOfSectionsInTableView:tableView])
        // Section is one of super's sections.
        return [super tableView:tableView numberOfRowsInSection:section];

    return 1;
}

- (void)configureCell:(UITableViewCell *)cell inTableView:(UITableView *)tableView atTableIndexPath:(NSIndexPath *)indexPath {

    if (indexPath.section < [super numberOfSectionsInTableView:tableView]) {
        // Section is one of super's sections.
        [super configureCell:cell inTableView:tableView atTableIndexPath:indexPath];
        return;
    }

    // "New" section
    NSString *query = [self.searchDisplayController.searchBar.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    cell.textLabel.text = query;
    cell.detailTextLabel.text = PearlString(@"New site: %@",
            [MPAlgorithmDefault shortNameOfType:[[[MPAppDelegate get] activeUserForThread] defaultType]]);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    if (indexPath.section < [super numberOfSectionsInTableView:tableView]) {
        // Section is one of super's sections.
        [super tableView:tableView didSelectRowAtIndexPath:indexPath];
        return;
    }

    // "New" section.
    NSString *siteName = [self.searchDisplayController.searchBar.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

    [PearlAlert showAlertWithTitle:@"New Site"
                           message:PearlString(@"Do you want to create a new site named:\n%@", siteName)
                         viewStyle:UIAlertViewStyleDefault
                         initAlert:nil tappedButtonBlock:^(UIAlertView *alert, NSInteger buttonIndex) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];

        if (buttonIndex == [alert cancelButtonIndex])
            return;

        [self addElementNamed:siteName completion:nil];
    }                  cancelTitle:[PearlStrings get].commonButtonCancel otherTitles:[PearlStrings get].commonButtonYes, nil];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {

    if (section < [super numberOfSectionsInTableView:tableView])
        // Section is one of super's sections.
        return [super tableView:tableView titleForHeaderInSection:section];

    return @"Create";
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath {

    if (indexPath.section < [super numberOfSectionsInTableView:tableView])
        // Section is one of super's sections.
        [super tableView:tableView commitEditingStyle:editingStyle forRowAtIndexPath:indexPath];
}


@end
