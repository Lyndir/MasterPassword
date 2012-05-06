//
//  MPSearchDelegate.m
//  MasterPassword
//
//  Created by Maarten Billemont on 04/01/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import "MPSearchDelegate.h"
#import "MPAppDelegate_Key.h"
#import "MPElementGeneratedEntity.h"

@interface MPSearchDelegate (Private)

- (void)configureCell:(UITableViewCell *)cell inTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath;
- (void)update;

@end

@implementation MPSearchDelegate
@synthesize query;
@synthesize dateFormatter;
@synthesize fetchedResultsController;
@synthesize delegate;
@synthesize searchDisplayController;
@synthesize searchTipContainer;

- (id)init {
    
    if (!([super init]))
        return nil;
    
    self.dateFormatter = [NSDateFormatter new];
    self.dateFormatter.dateStyle = NSDateFormatterShortStyle;
    self.query = @"";
    
    NSFetchRequest *fetchRequest    = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([MPElementEntity class])];
    fetchRequest.sortDescriptors    = [NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"uses" ascending:NO]];
    self.fetchedResultsController   = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                        managedObjectContext:[MPAppDelegate managedObjectContext]
                                                                          sectionNameKeyPath:nil cacheName:nil];
    self.fetchedResultsController.delegate = self;
    
    return self;
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
    
    [TestFlight passCheckpoint:MPTestFlightCheckpointCancelSearch];
    
    [self.delegate didSelectElement:nil];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    
    if (searchBar.searchResultsButtonSelected && !searchText.length)
        searchBar.text = @" ";
    
    self.query = [searchBar.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (!self.query)
        self.query = @"";
}

- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller {
    
    controller.searchBar.prompt = @"Enter the site's name (eg. apple.com):";
    
    [UIView animateWithDuration:0.2f animations:^{
        self.searchTipContainer.alpha = 0;
    }];
}

- (void)searchDisplayControllerDidBeginSearch:(UISearchDisplayController *)controller {
    
    controller.searchBar.text = controller.searchBar.searchResultsButtonSelected? @" ": @"";
    self.query = @"";
}

- (void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller {
    
    controller.searchBar.prompt = nil;
    controller.searchBar.searchResultsButtonSelected = NO;
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView {
    
    tableView.backgroundColor = [UIColor blackColor];
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    tableView.rowHeight = 48.0f;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    
    [self update];
    
    return NO;
}

- (void)update {
    
    assert(self.query);
    assert([MPAppDelegate get].keyHashHex);
    
    self.fetchedResultsController.fetchRequest.predicate = [NSPredicate predicateWithFormat:@"(%@ == '' OR name BEGINSWITH[cd] %@) AND mpHashHex == %@",
                                                            self.query, self.query, [MPAppDelegate get].keyHashHex];
    
    NSError *error;
    if (![self.fetchedResultsController performFetch:&error])
        err(@"Couldn't fetch elements: %@", error);
    [self.searchDisplayController.searchResultsTableView reloadData];
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    
    [self.searchDisplayController.searchResultsTableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    
    UITableView *tableView = self.searchDisplayController.searchResultsTableView;
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath]
                    inTableView:tableView atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    
    UITableView *tableView = self.searchDisplayController.searchResultsTableView;
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                     withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                     withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    
    [self.searchDisplayController.searchResultsTableView endUpdates];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return (signed)[[self.fetchedResultsController sections] count] + ([self.query length]? 1: 0);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    NSArray *sections = [self.fetchedResultsController sections];
    if (section < (signed)[sections count])
        return (signed)[[sections objectAtIndex:(unsigned)section] numberOfObjects];
    
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MPElementSearch"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"MPElementSearch"];
        
        UIImageView *backgroundImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ui_list_middle"]];
        backgroundImageView.frame = CGRectMake(-5, 0, 330, 34);
        backgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        backgroundImageView.contentStretch = CGRectMake(0.2f, 0.2f, 0.6f, 0.6f);
        UIView *backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 34)];
        [backgroundView addSubview:backgroundImageView];
        backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        cell.backgroundView = backgroundView;
        cell.textLabel.backgroundColor = [UIColor clearColor];
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.detailTextLabel.backgroundColor = [UIColor clearColor];
        cell.detailTextLabel.textColor = [UIColor lightGrayColor];
        cell.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        cell.clipsToBounds = YES;
    }
    
    [self configureCell:cell inTableView:tableView atIndexPath:indexPath];
    
    return cell;
}

- (void)configureCell:(UITableViewCell *)cell inTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section < (signed)[[self.fetchedResultsController sections] count]) {
        MPElementEntity *element = [self.fetchedResultsController objectAtIndexPath:indexPath];
        
        cell.textLabel.text = element.name;
        cell.detailTextLabel.text = [NSString stringWithFormat:@"Used %d times, last on %@",
                                     element.uses, [self.dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSinceReferenceDate:element.lastUsed]]];
    } else {
        // "New" section
        cell.textLabel.text = self.query;
        cell.detailTextLabel.text = @"Create a new site.";
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section < (signed)[[self.fetchedResultsController sections] count])
        [self.delegate didSelectElement:[self.fetchedResultsController objectAtIndexPath:indexPath]];
    
    else {
        // "New" section.
        NSString *siteName = self.query;
        [PearlAlert showAlertWithTitle:@"New Site"
                               message:l(@"Do you want to create a new site named:\n%@", siteName)
                             viewStyle:UIAlertViewStyleDefault
                     tappedButtonBlock:^(UIAlertView *alert, NSInteger buttonIndex) {
                         [tableView deselectRowAtIndexPath:indexPath animated:YES];
                         
                         if (buttonIndex == [alert cancelButtonIndex])
                             return;
                         
                         [self.fetchedResultsController.managedObjectContext performBlock:^{
                             MPElementGeneratedEntity *element = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([MPElementGeneratedEntity class])
                                                                                               inManagedObjectContext:self.fetchedResultsController.managedObjectContext];
                             assert([element isKindOfClass:ClassFromMPElementType((unsigned)element.type)]);
                             assert([MPAppDelegate get].keyHashHex);
                             
                             element.name = siteName;
                             element.mpHashHex = [MPAppDelegate get].keyHashHex;
                             
                             dispatch_async(dispatch_get_main_queue(), ^{
                                 [self.delegate didSelectElement:element];
                             });
                         }];
                     } cancelTitle:[PearlStrings get].commonButtonCancel otherTitles:[PearlStrings get].commonButtonYes, nil];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    if (section < (signed)[[self.fetchedResultsController sections] count])
        return [[[self.fetchedResultsController sections] objectAtIndex:(unsigned)section] name];
    
    return @"";
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    
    return [self.fetchedResultsController sectionIndexTitles];
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    
    return [self.fetchedResultsController sectionForSectionIndexTitle:title atIndex:index];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section < (signed)[[self.fetchedResultsController sections] count]) {
        if (editingStyle == UITableViewCellEditingStyleDelete)
            [self.fetchedResultsController.managedObjectContext performBlock:^{
                MPElementEntity *element = [self.fetchedResultsController objectAtIndexPath:indexPath];
                [self.fetchedResultsController.managedObjectContext deleteObject:element];
                
                [TestFlight passCheckpoint:MPTestFlightCheckpointDeleteElement];
            }];
    }
}


@end
