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
//  MPAllSitesViewController
//
//  Created by Maarten Billemont on 2013-01-31.
//  Copyright 2013 lhunath (Maarten Billemont). All rights reserved.
//

#import "MPAllSitesViewController.h"

#import "MPAppDelegate.h"
#import "MPAppDelegate_Store.h"


@interface MPAllSitesViewController() <NSFetchedResultsControllerDelegate>

@property (nonatomic,strong)NSDateFormatter *dateFormatter;

@end

@implementation MPAllSitesViewController {

    NSFetchedResultsController *_fetchedResultsController;
}


- (void)viewDidLoad {

    [super viewDidLoad];

    self.dateFormatter           = [NSDateFormatter new];
    self.dateFormatter.dateStyle = NSDateFormatterShortStyle;
}

- (IBAction)close:(id)sender {

    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)add:(id)sender {

    [PearlAlert showAlertWithTitle:@"Add Site" message:nil viewStyle:UIAlertViewStylePlainTextInput initAlert:nil
                 tappedButtonBlock:^(UIAlertView *alert, NSInteger buttonIndex) {
                     if (alert.cancelButtonIndex == buttonIndex)
                         return;

                     NSString *siteName = [alert textFieldAtIndex:0].text;
                     if (![siteName length])
                         return;

                     [MPAppDelegate managedObjectContextPerform:^(NSManagedObjectContext *moc) {
                         MPUserEntity *activeUser = [[MPAppDelegate get] activeUserInContext:moc];
                         assert(activeUser);
         
                         MPElementType type = activeUser.defaultType;
                         if (!type)
                             type = activeUser.defaultType = MPElementTypeGeneratedLong;
                         NSString *typeEntityClassName = [MPAlgorithmDefault classNameOfType:type];

                         MPElementEntity *element = [NSEntityDescription insertNewObjectForEntityForName:typeEntityClassName
                                                                                  inManagedObjectContext:moc];

                         element.name     = siteName;
                         element.user     = activeUser;
                         element.type     = type;
                         element.lastUsed = [NSDate date];
                         element.version  = MPAlgorithmDefaultVersion;
                         [element saveContext];

                         NSManagedObjectID *elementOID = [element objectID];
                         dispatch_async(dispatch_get_main_queue(), ^{
                             MPElementEntity *element_ = (MPElementEntity *)[[MPAppDelegate managedObjectContextForThreadIfReady]
                                                                                            objectRegisteredForID:elementOID];
                             [self.delegate didSelectElement:element_];
                             [self close:nil];
                         });
                     }];

                 }
                       cancelTitle:[PearlStrings get].commonButtonCancel otherTitles:[PearlStrings get].commonButtonOkay, nil];
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

- (void)fetchData {

    MPUserEntity *activeUser = [MPAppDelegate get].activeUser;
    if (!activeUser)
        return;

    self.fetchedResultsController.fetchRequest.predicate = [NSPredicate predicateWithFormat:@"user == %@", activeUser];

    NSError *error;
    if (![self.fetchedResultsController performFetch:&error])
        err(@"Couldn't fetch elements: %@", error);
    
    [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated {

    [super viewWillAppear:animated];

    [self fetchData];
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
    [self.tableView reloadData];
    //[self.tableView endUpdates];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    return (NSInteger)[[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return (NSInteger)[[[self.fetchedResultsController sections] objectAtIndex:(unsigned)section] numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MPElementSearch"];
    if (!cell.backgroundView) {
//        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"MPElementSearch"];

        UIImage *backgroundImage = [[UIImage imageNamed:@"ui_list_middle"] resizableImageWithCapInsets:UIEdgeInsetsMake(3, 3, 3, 3)
                                                                                          resizingMode:UIImageResizingModeStretch];
        UIImageView *backgroundImageView     = [[UIImageView alloc] initWithImage:backgroundImage];
        backgroundImageView.frame            = CGRectMake(-5, 0, 330, 34);
        backgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        UIView *backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 34)];
        [backgroundView addSubview:backgroundImageView];
        backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

        cell.backgroundView                  = backgroundView;
//        cell.textLabel.backgroundColor       = [UIColor clearColor];
//        cell.textLabel.textColor             = [UIColor whiteColor];
//        cell.detailTextLabel.backgroundColor = [UIColor clearColor];
//        cell.detailTextLabel.textColor       = [UIColor lightGrayColor];
//        cell.autoresizingMask                = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
//        cell.clipsToBounds                   = YES;
    }

    [self configureCell:cell inTableView:tableView atIndexPath:indexPath];

    return cell;
}

- (void)configureCell:(UITableViewCell *)cell inTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath {

    MPElementEntity *element = [self.fetchedResultsController objectAtIndexPath:indexPath];

    cell.textLabel.text       = element.name;
    cell.detailTextLabel.text = PearlString(@"Used %d times, last on %@",
                                            element.uses, [self.dateFormatter stringFromDate:element.lastUsed]);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    [self.delegate didSelectElement:[self.fetchedResultsController objectAtIndexPath:indexPath]];
    [self close:nil];
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
