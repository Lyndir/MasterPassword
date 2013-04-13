//
// Created by lhunath on 2013-02-09.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "MPElementListController.h"

#import "MPAppDelegate_Store.h"
#import "MPAppDelegate.h"

@interface MPElementListController ()
@end

@implementation MPElementListController {

    NSFetchedResultsController *_fetchedResultsController;
    NSDateFormatter *_dateFormatter;
}

- (void)addElementNamed:(NSString *)siteName completion:(void(^)(BOOL success))completion {

    if (![siteName length]) {
        if (completion)
            completion(false);
        return;
    }

    [MPAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *moc) {
        MPUserEntity *activeUser = [[MPAppDelegate get] activeUserInContext:moc];
        assert(activeUser);

        MPElementType type = activeUser.defaultType;
        if (!type)
            type = activeUser.defaultType = MPElementTypeGeneratedLong;
        NSString *typeEntityClassName = [MPAlgorithmDefault classNameOfType:type];

        MPElementEntity *element = [NSEntityDescription insertNewObjectForEntityForName:typeEntityClassName
                                                                 inManagedObjectContext:moc];

        element.name = siteName;
        element.user = activeUser;
        element.type = type;
        element.lastUsed = [NSDate date];
        element.version = MPAlgorithmDefaultVersion;
        [moc saveToStore];

        NSManagedObjectID *elementOID = [element objectID];
        dispatch_async(dispatch_get_main_queue(), ^{
            MPElementEntity *element_ = (MPElementEntity *) [[MPAppDelegate managedObjectContextForThreadIfReady]
                    objectRegisteredForID:elementOID];
            [self.delegate didSelectElement:element_];
            if (completion)
                completion(true);
        });
    }];
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

- (NSDateFormatter *)dateFormatter {

    if (!_dateFormatter)
        (_dateFormatter = [NSDateFormatter new]).dateStyle = NSDateFormatterShortStyle;

    return _dateFormatter;
}

- (void)updateData {

    MPUserEntity *activeUser = [MPAppDelegate get].activeUser;
    if (!activeUser)
        return;

    // Build predicate.
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"user == %@", activeUser];
    UISearchBar *searchBar = self.searchDisplayController.searchBar;
    if (searchBar) {
        NSString *query = [searchBar.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (!query)
            return;

        // Add query predicate.
        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:
                @[predicate, [NSPredicate predicateWithFormat:@"name BEGINSWITH[cd] %@", query]]];

        // Add scope predicate.
        switch ((MPSearchScope) searchBar.selectedScopeButtonIndex) {

            case MPSearchScopeAll:
                break;
            case MPSearchScopeOutdated:
                predicate = [NSCompoundPredicate andPredicateWithSubpredicates:
                        @[[NSPredicate predicateWithFormat:@"requiresExplicitMigration_ == YES"], predicate]];
                break;
        }
    }
    self.fetchedResultsController.fetchRequest.predicate = predicate;

    NSError *error;
    if (![self.fetchedResultsController performFetch:&error])
        err(@"Couldn't fetch elements: %@", error);
    else
        [self.tableView reloadData];
}

- (void)customTableViewUpdates {

}

// See MP-14, also crashes easily on internal assertions etc..
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {

    dbg(@"%@", NSStringFromSelector(_cmd));
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {

    switch (type) {

        case NSFetchedResultsChangeInsert:
            dbg(@"%@ -- NSFetchedResultsChangeInsert:%@", NSStringFromSelector(_cmd), anObject);
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;

        case NSFetchedResultsChangeDelete:
            dbg(@"%@ -- NSFetchedResultsChangeDelete:%@", NSStringFromSelector(_cmd), anObject);
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;

        case NSFetchedResultsChangeUpdate:
            dbg(@"%@ -- NSFetchedResultsChangeUpdate:%@", NSStringFromSelector(_cmd), anObject);
            [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;

        case NSFetchedResultsChangeMove:
            dbg(@"%@ -- NSFetchedResultsChangeMove:%@", NSStringFromSelector(_cmd), anObject);
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {

    switch (type) {

        case NSFetchedResultsChangeInsert:
            dbg(@"%@ -- NSFetchedResultsChangeInsert:%d", NSStringFromSelector(_cmd), sectionIndex);
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                          withRowAnimation:UITableViewRowAnimationAutomatic];
            break;

        case NSFetchedResultsChangeDelete:
            dbg(@"%@ -- NSFetchedResultsChangeDelete:%d", NSStringFromSelector(_cmd), sectionIndex);
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                          withRowAnimation:UITableViewRowAnimationAutomatic];
            break;

        case NSFetchedResultsChangeMove:
        case NSFetchedResultsChangeUpdate:
            Throw(@"Invalid change type for section changes: %d", type);
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {

    dbg(@"%@ on %@", NSStringFromSelector(_cmd), [NSThread currentThread].name);
    [self customTableViewUpdates];
    [self.tableView endUpdates];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    NSInteger integer = (NSInteger)[[self.fetchedResultsController sections] count];
    dbg(@"%@ = %d", NSStringFromSelector(_cmd), integer);
    return integer;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    NSInteger integer = (NSInteger)[[[self.fetchedResultsController sections] objectAtIndex:(unsigned)section] numberOfObjects];
    dbg(@"%@%d = %d", NSStringFromSelector(_cmd), section, integer);
    return integer;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MPElementListCell"];
    if (!cell)
        cell = (UITableViewCell *) [[UIViewController alloc] initWithNibName:@"MPElementListCellView" bundle:nil].view;

    [self configureCell:cell inTableView:tableView atIndexPath:indexPath];

    return cell;
}

- (void)configureCell:(UITableViewCell *)cell inTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath {

    MPElementEntity *element = [self.fetchedResultsController objectAtIndexPath:indexPath];

    cell.textLabel.text = element.name;
    cell.detailTextLabel.text = PearlString(@"%d views, last on %@: %@",
            element.uses, [self.dateFormatter stringFromDate:element.lastUsed], [element.algorithm shortNameOfType:element.type]);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    [self.delegate didSelectElement:[self.fetchedResultsController objectAtIndexPath:indexPath]];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {

    return [[[self.fetchedResultsController sections] objectAtIndex:(unsigned)section] name];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {

    return [self.fetchedResultsController sectionIndexTitles];
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {

    return [self.fetchedResultsController sectionForSectionIndexTitle:title atIndex:index];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath {

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

@end
