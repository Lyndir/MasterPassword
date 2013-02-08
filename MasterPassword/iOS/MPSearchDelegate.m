//
//  MPSearchDelegate.m
//  MasterPassword
//
//  Created by Maarten Billemont on 04/01/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import "MPSearchDelegate.h"
#import "MPAppDelegate.h"
#import "MPAppDelegate_Store.h"
#import "MPMainViewController.h"

@implementation MPSearchDelegate {

    NSFetchedResultsController *_fetchedResultsController;
}

- (id)init {

    if (!(self = [super init]))
        return nil;

    self.dateFormatter           = [NSDateFormatter new];
    self.dateFormatter.dateStyle = NSDateFormatterShortStyle;

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

- (NSFetchedResultsController *)fetchedResultsController {

    if (!_fetchedResultsController) {
        NSAssert([[NSThread currentThread] isMainThread], @"The fetchedResultsController must run on the main thread.");
        NSManagedObjectContext *moc = [MPAppDelegate managedObjectContextForThreadIfReady];
        if (!moc)
            return nil;

        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([MPElementEntity class])];
        fetchRequest.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"uses_" ascending:NO]];
        fetchRequest.fetchBatchSize = 20;
        _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:moc
                                                                          sectionNameKeyPath:nil cacheName:nil];
        _fetchedResultsController.delegate = self;
    }

    return _fetchedResultsController;
}

- (void)searchBarBookmarkButtonClicked:(UISearchBar *)searchBar {

    [((MPMainViewController *)self.delegate) performSegueWithIdentifier:@"MP_AllSites" sender:self];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {

    UITableView *tableView = self.searchDisplayController.searchResultsTableView;
    for (NSInteger section = 0; section < [self numberOfSectionsInTableView:tableView]; ++section) {
        NSInteger rowCount = [self tableView:tableView numberOfRowsInSection:section];
        if (!rowCount)
            continue;

        if (rowCount == 1)
            [self tableView:tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:section]];
        break;
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {

    [self.delegate didSelectElement:nil];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {

}

- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller {

    controller.searchBar.prompt                = @"Enter the site's name:";
    controller.searchBar.showsScopeBar         = controller.searchBar.selectedScopeButtonIndex != MPSearchScopeAll;
    controller.searchBar.text                  = @"";
    if (controller.searchBar.showsScopeBar)
        controller.searchBar.scopeButtonTitles = @[@"All", @"Outdated"];
    else
        controller.searchBar.scopeButtonTitles = nil;

    [UIView animateWithDuration:0.2f animations:^{
        self.searchTipContainer.alpha = 0;
    }];
}

- (void)searchDisplayControllerDidBeginSearch:(UISearchDisplayController *)controller {

}

- (void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller {

    controller.searchBar.prompt                      = nil;
    controller.searchBar.searchResultsButtonSelected = NO;
    controller.searchBar.selectedScopeButtonIndex    = MPSearchScopeAll;
    controller.searchBar.showsScopeBar               = NO;
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView {

    tableView.backgroundColor = [UIColor blackColor];
    tableView.separatorStyle  = UITableViewCellSeparatorStyleNone;
    tableView.rowHeight       = 48.0f;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {

    if (!controller.active)
        return NO;

    [self fetchData];

    return YES;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption {

    if (!controller.active)
        return NO;

    [self fetchData];

    return YES;
}

- (void)fetchData {

    
    NSString *query = [self.searchDisplayController.searchBar.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (!query)
        return;

    MPUserEntity *activeUser = [MPAppDelegate get].activeUser;
    if (!activeUser)
        return;

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"user == %@ AND name BEGINSWITH[cd] %@", activeUser, query];
    switch ((MPSearchScope)self.searchDisplayController.searchBar.selectedScopeButtonIndex) {

        case MPSearchScopeAll:
            break;
        case MPSearchScopeOutdated:
            predicate = [NSCompoundPredicate
             andPredicateWithSubpredicates:@[[NSPredicate predicateWithFormat:@"requiresExplicitMigration_ == YES"], predicate]];
            break;
    }
    self.fetchedResultsController.fetchRequest.predicate = predicate;

    NSError *error;
    if (![self.fetchedResultsController performFetch:&error])
        err(@"Couldn't fetch elements: %@", error);

    [self.searchDisplayController.searchBar.superview enumerateSubviews:^(UIView *subview, BOOL *stop, BOOL *recurse) {
        CGRect searchBarFrame = self.searchDisplayController.searchBar.frame;
        if ([subview isKindOfClass:[UIControl class]] &&
         CGPointEqualToPoint(
          CGPointDistanceBetweenCGPoints(searchBarFrame.origin, subview.frame.origin),
          CGPointMake(0, searchBarFrame.size.height))) {
            [self.tipView removeFromSuperview];
            [subview addSubview:self.tipView];
            *stop = YES;
        }
    }                                                           recurse:NO];
}

// See MP-14, also crashes easily on internal assertions etc..
//- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
//    
//    [self.searchDisplayController.searchResultsTableView beginUpdates];
//}
//
//- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
//       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
//    
//    UITableView *tableView = self.searchDisplayController.searchResultsTableView;
//    switch(type) {
//            
//        case NSFetchedResultsChangeInsert:
//            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
//            break;
//            
//        case NSFetchedResultsChangeDelete:
//            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
//            break;
//            
//        case NSFetchedResultsChangeUpdate:
//            [self configureCell:[tableView cellForRowAtIndexPath:indexPath]
//                    inTableView:tableView atIndexPath:indexPath];
//            break;
//            
//        case NSFetchedResultsChangeMove:
//            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
//                             withRowAnimation:UITableViewRowAnimationFade];
//            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
//                             withRowAnimation:UITableViewRowAnimationFade];
//            break;
//    }
//}
//
//
//- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo
//           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
//    
//    UITableView *tableView = self.searchDisplayController.searchResultsTableView;
//    switch(type) {
//            
//        case NSFetchedResultsChangeInsert:
//            [tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]
//                     withRowAnimation:UITableViewRowAnimationFade];
//            break;
//            
//        case NSFetchedResultsChangeDelete:
//            [tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]
//                     withRowAnimation:UITableViewRowAnimationFade];
//            break;
//    }
//}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {

    dbg(@"controllerDidChangeContent on thread: %@", [NSThread currentThread].name);
    [self.searchDisplayController.searchResultsTableView reloadData];
    //    [self.searchDisplayController.searchResultsTableView endUpdates];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    NSArray *sections = [self.fetchedResultsController sections];
    NSUInteger sectionCount = [sections count];

    NSString *query = [self.searchDisplayController.searchBar.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if ([query length]) {
        __block BOOL hasExactQueryMatch = NO;
        [sections enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            id<NSFetchedResultsSectionInfo> sectionInfo = obj;
            [[sectionInfo objects] enumerateObjectsUsingBlock:^(id obj_, NSUInteger idx_, BOOL *stop_) {
                if ([[obj_ name] isEqualToString:query]) {
                    hasExactQueryMatch = YES;
                    *stop_ = YES;
                }
            }];
            if (hasExactQueryMatch)
                *stop                                   = YES;
        }];
        if (!hasExactQueryMatch)
         // Add a section for "new site".
            ++sectionCount;
    }

    return (NSInteger)sectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    NSArray *sections = [self.fetchedResultsController sections];
    if (section < (NSInteger)[sections count])
        return (NSInteger)[[sections objectAtIndex:(unsigned)section] numberOfObjects];

    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MPElementSearch"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"MPElementSearch"];

        UIImage *backgroundImage = [[UIImage imageNamed:@"ui_list_middle"] resizableImageWithCapInsets:UIEdgeInsetsMake(3, 3, 3, 3)
                                                                                          resizingMode:UIImageResizingModeStretch];
        UIImageView *backgroundImageView     = [[UIImageView alloc] initWithImage:backgroundImage];
        backgroundImageView.frame            = CGRectMake(-5, 0, 330, 34);
        backgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        UIView *backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 34)];
        [backgroundView addSubview:backgroundImageView];
        backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

        cell.backgroundView                  = backgroundView;
        cell.textLabel.backgroundColor       = [UIColor clearColor];
        cell.textLabel.textColor             = [UIColor whiteColor];
        cell.detailTextLabel.backgroundColor = [UIColor clearColor];
        cell.detailTextLabel.textColor       = [UIColor lightGrayColor];
        cell.autoresizingMask                = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        cell.clipsToBounds                   = YES;
    }

    [self configureCell:cell inTableView:tableView atIndexPath:indexPath];

    return cell;
}

- (void)configureCell:(UITableViewCell *)cell inTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath {

    if (indexPath.section < (NSInteger)[[self.fetchedResultsController sections] count]) {
        MPElementEntity *element = [self.fetchedResultsController objectAtIndexPath:indexPath];

        cell.textLabel.text       = element.name;
        cell.detailTextLabel.text = PearlString(@"%d views, last on %@: %@",
                element.uses, [self.dateFormatter stringFromDate:element.lastUsed], [element.algorithm shortNameOfType:element.type]);
    } else {
        // "New" section
        NSString *query = [self.searchDisplayController.searchBar.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        cell.textLabel.text       = query;
        cell.detailTextLabel.text = PearlString(@"Add new site: %@", [MPAlgorithmDefault shortNameOfType:[[MPAppDelegate get].activeUser defaultType]]);
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    if (indexPath.section < (NSInteger)[[self.fetchedResultsController sections] count])
        [self.delegate didSelectElement:[self.fetchedResultsController objectAtIndexPath:indexPath]];

    else {
        // "New" section.
        NSString *siteName = [self.searchDisplayController.searchBar.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        [PearlAlert showAlertWithTitle:@"New Site"
                               message:PearlString(@"Do you want to create a new site named:\n%@", siteName)
                             viewStyle:UIAlertViewStyleDefault
                             initAlert:nil tappedButtonBlock:^(UIAlertView *alert, NSInteger buttonIndex) {
            [tableView deselectRowAtIndexPath:indexPath animated:YES];

            if (buttonIndex == [alert cancelButtonIndex])
                return;

            [MPAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *moc) {
                MPUserEntity *activeUser = [[MPAppDelegate get] activeUserInContext:moc];
                assert(activeUser);

                MPElementType type = activeUser.defaultType;
                if (!type)
                    type = activeUser.defaultType = MPElementTypeGeneratedLong;
                NSString *typeEntityClassName = [MPAlgorithmDefault classNameOfType:type];

                MPElementEntity *element = [NSEntityDescription insertNewObjectForEntityForName:typeEntityClassName
                                                                         inManagedObjectContext:moc];

                element.name    = siteName;
                element.user    = activeUser;
                element.type    = type;
                element.lastUsed = [NSDate date];
                element.version = MPAlgorithmDefaultVersion;
                [element saveContext];

                NSManagedObjectID *elementOID = [element objectID];
                dispatch_async(dispatch_get_main_queue(), ^{
                    MPElementEntity *element_ = (MPElementEntity *)[[MPAppDelegate managedObjectContextForThreadIfReady]
                                                                                   objectRegisteredForID:elementOID];
                    [self.delegate didSelectElement:element_];
                });
            }];
        }                  cancelTitle:[PearlStrings get].commonButtonCancel otherTitles:[PearlStrings get].commonButtonYes, nil];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {

    if (section < (NSInteger)[[self.fetchedResultsController sections] count])
        return [[[self.fetchedResultsController sections] objectAtIndex:(unsigned)section] name];

    return @"";
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {

    return [self.fetchedResultsController sectionIndexTitles];
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {

    return [self.fetchedResultsController sectionForSectionIndexTitle:title atIndex:index];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath {

    if (indexPath.section < (NSInteger)[[self.fetchedResultsController sections] count]) {
        if (editingStyle == UITableViewCellEditingStyleDelete)
            [self.fetchedResultsController.managedObjectContext performBlock:^{
                MPElementEntity *element = [self.fetchedResultsController objectAtIndexPath:indexPath];

                inf(@"Deleting element: %@", element.name);
                [self.fetchedResultsController.managedObjectContext deleteObject:element];

#ifdef TESTFLIGHT_SDK_VERSION
                [TestFlight passCheckpoint:MPCheckpointDeleteElement];
#endif
                [[LocalyticsSession sharedLocalyticsSession] tagEvent:MPCheckpointDeleteElement attributes:@{
                 @"type"    : element.typeName,
                 @"version" : @(element.version)}];
            }];
    }
}


@end
