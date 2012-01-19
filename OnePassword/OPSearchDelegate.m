//
//  OPSearchDelegate.m
//  OnePassword
//
//  Created by Maarten Billemont on 04/01/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import "OPSearchDelegate.h"
#import "OPAppDelegate.h"
#import "OPElementGeneratedEntity.h"

@interface OPSearchDelegate (Private)

- (void)update;

@end

@implementation OPSearchDelegate
@synthesize fetchedResultsController;
@synthesize delegate;
@synthesize searchDisplayController;

- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller {
    
    self.searchDisplayController.searchBar.text = @"";
    self.searchDisplayController.searchBar.prompt = @"Enter the site's domain name (eg. apple.com):";
    [self update];
}

- (void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller {
    
    self.searchDisplayController.searchBar.prompt = nil;
}

- (void)searchDisplayController:(UISearchDisplayController *)controller willShowSearchResultsTableView:(UITableView *)tableView {
    
    [tableView setEditing:self.searchDisplayController.searchContentsController.editing animated:NO];
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    
    [self update];
    
    return YES;
}

- (void)update {
    
    NSString *text = self.searchDisplayController.searchBar.text;
    if (!text)
        text = @"";
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass([OPElementEntity class])];
    [fetchRequest setSortDescriptors:
     [NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"uses" ascending:NO]]];
    [fetchRequest setPredicate:
     [NSPredicate predicateWithFormat:@"name BEGINSWITH[cd] %@", text]];
    
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                        managedObjectContext:[OPAppDelegate managedObjectContext]
                                                                          sectionNameKeyPath:nil cacheName:nil];
    self.fetchedResultsController.delegate = self;
    
    NSError *error;
    if (![self.fetchedResultsController performFetch:&error])
        err(@"Couldn't fetch elements: %@", error);
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    
    [self.searchDisplayController.searchResultsTableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    
    indexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section + 1];
    newIndexPath = [NSIndexPath indexPathForRow:newIndexPath.row inSection:newIndexPath.section + 1];
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [self.searchDisplayController.searchResultsTableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.searchDisplayController.searchResultsTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[self.searchDisplayController.searchResultsTableView cellForRowAtIndexPath:indexPath]
                    atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [self.searchDisplayController.searchResultsTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                                                                       withRowAnimation:UITableViewRowAnimationFade];
            [self.searchDisplayController.searchResultsTableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                                                                       withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    
    ++sectionIndex;
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [self.searchDisplayController.searchResultsTableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                                                               withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.searchDisplayController.searchResultsTableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                                                               withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    
    [self.searchDisplayController.searchResultsTableView endUpdates];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return [[self.fetchedResultsController sections] count] + 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (--section == -1)
        return 1;
    
    return [[[self.fetchedResultsController sections] objectAtIndex:section] numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"OPElementSearch"];
    if (!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"OPElementSearch"];
    
    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    
    indexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section - 1];
    if (indexPath.section == -1) {
        cell.textLabel.text = self.searchDisplayController.searchBar.text;
        cell.detailTextLabel.text = @"New";
    } else {
        OPElementEntity *element = [self.fetchedResultsController objectAtIndexPath:indexPath];
        
        cell.textLabel.text = element.name;
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", element.uses];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    OPElementEntity *element;
    indexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section - 1];
    if (indexPath.section == -1) {
        element = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([OPElementGeneratedEntity class])
                                                inManagedObjectContext:[OPAppDelegate managedObjectContext]];
        element.name = self.searchDisplayController.searchBar.text;
    } else
        element = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    [self.delegate didSelectElement:element];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    if (--section == -1)
        return @"";
    
    return [[[self.fetchedResultsController sections] objectAtIndex:section] name];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    
    return [self.fetchedResultsController sectionIndexTitles];
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    
    return [self.fetchedResultsController sectionForSectionIndexTitle:title atIndex:index];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    indexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section - 1];
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        OPElementEntity *element = [self.fetchedResultsController objectAtIndexPath:indexPath];
        
        [[OPAppDelegate managedObjectContext] deleteObject:element];
    }
}


@end
