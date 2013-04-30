#import "MPElementListController.h"

#import "MPAppDelegate_Store.h"
#import "MPiOSAppDelegate.h"

@interface MPElementListController()
@end

@implementation MPElementListController {

    NSFetchedResultsController *_fetchedResultsControllerByUses;
    NSFetchedResultsController *_fetchedResultsControllerByLastUsed;
    NSDateFormatter *_dateFormatter;
}

- (void)viewDidLoad {

    [[NSNotificationCenter defaultCenter] addObserverForName:UbiquityManagedStoreDidChangeNotification object:nil queue:nil usingBlock:
            ^(NSNotification *note) {
                [self updateData];
            }];

    [super viewDidLoad];
}

- (void)addElementNamed:(NSString *)siteName completion:(void (^)(BOOL success))completion {

    if (![siteName length]) {
        if (completion)
            completion( false );
        return;
    }

    [MPiOSAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *moc) {
        MPUserEntity *activeUser = [[MPiOSAppDelegate get] activeUserInContext:moc];
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

        NSError *error = nil;
        if (element.objectID.isTemporaryID && ![moc obtainPermanentIDsForObjects:@[ element ] error:&error])
        err(@"Failed to obtain a permanent object ID after creating new element: %@", error);

        NSManagedObjectID *elementOID = [element objectID];
        dispatch_async( dispatch_get_main_queue(), ^{
            MPElementEntity *element_ = (MPElementEntity *)[[MPiOSAppDelegate managedObjectContextForThreadIfReady]
                    objectRegisteredForID:elementOID];
            [self.delegate didSelectElement:element_];
            if (completion)
                completion( true );
        } );
    }];
}

- (NSFetchedResultsController *)fetchedResultsControllerByLastUsed {

    if (!_fetchedResultsControllerByLastUsed) {
        NSAssert([[NSThread currentThread] isMainThread], @"The fetchedResultsController must be accessed from the main thread.");
        NSManagedObjectContext *moc = [MPiOSAppDelegate managedObjectContextForThreadIfReady];
        if (!moc)
            return nil;

        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass( [MPElementEntity class] )];
        fetchRequest.sortDescriptors = @[ [[NSSortDescriptor alloc] initWithKey:NSStringFromSelector( @selector(lastUsed) ) ascending:NO] ];
        [self configureFetchRequest:fetchRequest];
        _fetchedResultsControllerByLastUsed = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:moc
                                                                                    sectionNameKeyPath:nil cacheName:nil];
        _fetchedResultsControllerByLastUsed.delegate = self;
    }

    return _fetchedResultsControllerByLastUsed;
}

- (NSFetchedResultsController *)fetchedResultsControllerByUses {

    if (!_fetchedResultsControllerByUses) {
        NSAssert([[NSThread currentThread] isMainThread], @"The fetchedResultsController must be accessed from the main thread.");
        NSManagedObjectContext *moc = [MPiOSAppDelegate managedObjectContextForThreadIfReady];
        if (!moc)
            return nil;

        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass( [MPElementEntity class] )];
        fetchRequest.sortDescriptors = @[ [[NSSortDescriptor alloc] initWithKey:NSStringFromSelector( @selector(uses_) ) ascending:NO] ];
        [self configureFetchRequest:fetchRequest];
        _fetchedResultsControllerByUses = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:moc
                                                                                sectionNameKeyPath:nil cacheName:nil];
        _fetchedResultsControllerByUses.delegate = self;
    }

    return _fetchedResultsControllerByUses;
}

- (void)configureFetchRequest:(NSFetchRequest *)fetchRequest {

    fetchRequest.fetchLimit = 5;
}

- (NSDateFormatter *)dateFormatter {

    if (!_dateFormatter)
        (_dateFormatter = [NSDateFormatter new]).dateStyle = NSDateFormatterShortStyle;

    return _dateFormatter;
}

- (void)updateData {

    MPUserEntity *activeUser = [[MPiOSAppDelegate get] activeUserForThread];
    if (!activeUser) {
        _fetchedResultsControllerByLastUsed = nil;
        _fetchedResultsControllerByUses = nil;
        [self.tableView reloadData];
        return;
    }

    // Build predicate.
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"user == %@", activeUser];

    // Add query predicate.
    UISearchBar *searchBar = self.searchDisplayController.searchBar;
    if (searchBar) {
        NSString *query = [searchBar.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (!query)
            return;

        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:
                @[ predicate, [NSPredicate predicateWithFormat:@"name BEGINSWITH[cd] %@", query] ]];
    }

    // Add filter predicate.
    if ([self.filter isEqualToString:MPElementListFilterOutdated])
        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:
                @[ [NSPredicate predicateWithFormat:@"requiresExplicitMigration_ == YES"], predicate ]];

    // Fetch
    NSError *error;
    self.fetchedResultsControllerByLastUsed.fetchRequest.predicate = predicate;
    self.fetchedResultsControllerByUses.fetchRequest.predicate = predicate;
    if (self.fetchedResultsControllerByLastUsed && ![self.fetchedResultsControllerByLastUsed performFetch:&error])
    err(@"Couldn't fetch elements: %@", error);
    if (self.fetchedResultsControllerByUses && ![self.fetchedResultsControllerByUses performFetch:&error])
    err(@"Couldn't fetch elements: %@", error);

    [self.tableView reloadData];
}

- (void)customTableViewUpdates {
}

// See MP-14, also crashes easily on internal assertions etc..
//- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
//
//    [self.tableView beginUpdates];
//}
//
//- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
//       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
//
//    switch (type) {
//
//        case NSFetchedResultsChangeInsert:
//            [self.tableView insertRowsAtIndexPaths:@[ [self tableIndexPathForFetchController:controller indexPath:newIndexPath] ]
//                                  withRowAnimation:UITableViewRowAnimationAutomatic];
//            break;
//
//        case NSFetchedResultsChangeDelete:
//            [self.tableView deleteRowsAtIndexPaths:@[ [self tableIndexPathForFetchController:controller indexPath:indexPath] ]
//                                  withRowAnimation:UITableViewRowAnimationAutomatic];
//            break;
//
//        case NSFetchedResultsChangeUpdate:
//            [self.tableView reloadRowsAtIndexPaths:@[ [self tableIndexPathForFetchController:controller indexPath:indexPath] ]
//                                  withRowAnimation:UITableViewRowAnimationAutomatic];
//            break;
//
//        case NSFetchedResultsChangeMove:
//            [self.tableView deleteRowsAtIndexPaths:@[ [self tableIndexPathForFetchController:controller indexPath:indexPath] ]
//                                  withRowAnimation:UITableViewRowAnimationAutomatic];
//            [self.tableView insertRowsAtIndexPaths:@[ [self tableIndexPathForFetchController:controller indexPath:newIndexPath] ]
//                                  withRowAnimation:UITableViewRowAnimationAutomatic];
//            break;
//    }
//}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {

//    [self customTableViewUpdates];
//    [self.tableView endUpdates];

    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    if (section == 0)
        return (NSInteger)[[[self.fetchedResultsControllerByLastUsed sections] lastObject] numberOfObjects];

    if (section == 1)
        return (NSInteger)[[[self.fetchedResultsControllerByUses sections] lastObject] numberOfObjects];

    Throw(@"Unsupported section: %d", section);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MPElementListCell"];
    if (!cell)
        cell = (UITableViewCell *)[[UIViewController alloc] initWithNibName:@"MPElementListCellView" bundle:nil].view;

    [self configureCell:cell inTableView:tableView atTableIndexPath:indexPath];

    return cell;
}

- (void)configureCell:(UITableViewCell *)cell inTableView:(UITableView *)tableView atTableIndexPath:(NSIndexPath *)indexPath {

    MPElementEntity *element = [self elementForTableIndexPath:indexPath];

    cell.textLabel.text = element.name;
    cell.detailTextLabel.text = PearlString( @"%d views, last on %@: %@",
            element.uses, [self.dateFormatter stringFromDate:element.lastUsed], [element.algorithm shortNameOfType:element.type] );
}

- (NSIndexPath *)tableIndexPathForFetchController:(NSFetchedResultsController *)fetchedResultsController
                                        indexPath:(NSIndexPath *)indexPath {

    if (fetchedResultsController == self.fetchedResultsControllerByLastUsed)
        return [NSIndexPath indexPathForRow:indexPath.row inSection:0];
    if (fetchedResultsController == self.fetchedResultsControllerByUses)
        return [NSIndexPath indexPathForRow:indexPath.row inSection:1];

    Throw(@"Unknown fetched results controller: %@, for index path: %@", fetchedResultsController, indexPath);
}

- (NSIndexPath *)fetchedIndexPathForTableIndexPath:(NSIndexPath *)indexPath {

    return [NSIndexPath indexPathForRow:indexPath.row inSection:0];
}

- (MPElementEntity *)elementForTableIndexPath:(NSIndexPath *)indexPath {

    if (indexPath.section == 0)
        return [self.fetchedResultsControllerByLastUsed objectAtIndexPath:[self fetchedIndexPathForTableIndexPath:indexPath]];

    if (indexPath.section == 1)
        return [self.fetchedResultsControllerByUses objectAtIndexPath:[self fetchedIndexPathForTableIndexPath:indexPath]];

    Throw(@"Unsupported section: %d", indexPath.section);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    [self.delegate didSelectElement:[self elementForTableIndexPath:indexPath]];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {

    if (section == 0)
        return @"Most Recently Used";

    if (section == 1)
        return @"Most Commonly Used";

    Throw(@"Unsupported section: %d", section);
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {

    return @[ @"recency", @"uses" ];
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {

    return index;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath {

    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSManagedObjectID *elementOID = [self elementForTableIndexPath:indexPath].objectID;
        [MPiOSAppDelegate managedObjectContextPerformBlockAndWait:^(NSManagedObjectContext *context) {
            NSError *error = nil;
            MPElementEntity *element = (MPElementEntity *)[context existingObjectWithID:elementOID error:&error];
            if (!element) {
                err(@"Failed to retrieve element to delete: %@", error);
                return;
            }

            inf(@"Deleting element: %@", element.name);
            [context deleteObject:element];
            [context saveToStore];

            MPCheckpoint( MPCheckpointDeleteElement, @{
                    @"type"    : element.typeName,
                    @"version" : @(element.version)
            } );
        }];
    }
}

@end
