//
//  MPSearchDelegate.m
//  MasterPassword
//
//  Created by Maarten Billemont on 04/01/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import "MPSearchDelegate.h"
#import "MPAppDelegate.h"
#import "MPElementGeneratedEntity.h"

@interface MPSearchDelegate (Private)

- (void)configureCell:(UITableViewCell *)cell inTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath;
- (void)update;

@end

@implementation MPSearchDelegate
@synthesize fetchedResultsController;
@synthesize delegate;
@synthesize searchDisplayController;
@synthesize searchTipContainer;

- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller {
    
    self.searchDisplayController.searchBar.text = @"";
    self.searchDisplayController.searchBar.prompt = @"Enter the site's domain name (eg. apple.com):";
    
    [UIView animateWithDuration:0.2f animations:^{
        self.searchTipContainer.alpha = 0;
    }];
    
    [self update];
}

- (void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller {
    
    self.searchDisplayController.searchBar.prompt = nil;
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView {
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIScreenModeDidChangeNotification
                                                      object:nil queue:nil usingBlock:^(NSNotification *note) {
                                                          NSError *error;
                                                          if (![self.fetchedResultsController performFetch:&error])
                                                              err(@"Couldn't fetch elements: %@", error);
                                                      }];
    
    tableView.backgroundColor = [UIColor blackColor];
    tableView.rowHeight = 34.0f;
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    
    [self update];
    
    return YES;
}

- (void)update {
    
    NSString *query = self.searchDisplayController.searchBar.text;
    if (!query)
        query = @"";
    
    NSFetchRequest *fetchRequest = [[MPAppDelegate get].managedObjectModel
                                    fetchRequestFromTemplateWithName:@"MPSearchElement"
                                    substitutionVariables:[NSDictionary dictionaryWithObjectsAndKeys:
                                                           query,                                   @"query",
                                                           [MPAppDelegate get].keyPhraseHashHex,    @"mpHashHex",
                                                           nil]];
    [fetchRequest setSortDescriptors:
     [NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"uses" ascending:NO]]];
    
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                        managedObjectContext:[MPAppDelegate managedObjectContext]
                                                                          sectionNameKeyPath:nil cacheName:nil];
    self.fetchedResultsController.delegate = self;
    
    NSError *error;
    if (![self.fetchedResultsController performFetch:&error])
        err(@"Couldn't fetch elements: %@", error);
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
                    inTableView:tableView
                    atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
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
    
    return [[self.fetchedResultsController sections] count] + 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (section == [self numberOfSectionsInTableView:tableView] - 1)
        return 1;
    
    return [[[self.fetchedResultsController sections] objectAtIndex:section] numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MPElementSearch"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"MPElementSearch"];
        UIImageView *backgroundImageView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"ui_list_middle"] resizableImageWithCapInsets:UIEdgeInsetsMake(5, 5, 5, 5)]];
        backgroundImageView.frame = CGRectMake(-5, 0, 330, 34);
        UIView *backgroundView = [[UIView alloc] initWithFrame:cell.frame];
        [backgroundView addSubview:backgroundImageView];
        
        cell.backgroundView = backgroundView;
        cell.textLabel.backgroundColor = [UIColor clearColor];
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.detailTextLabel.backgroundColor = [UIColor clearColor];
        cell.detailTextLabel.textColor = [UIColor lightGrayColor];
    }
    
    [self configureCell:cell inTableView:tableView atIndexPath:indexPath];
    
    return cell;
}

- (void)configureCell:(UITableViewCell *)cell inTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section < [[self.fetchedResultsController sections] count]) {
        MPElementEntity *element = [self.fetchedResultsController objectAtIndexPath:indexPath];
        
        cell.textLabel.text = element.name;
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", element.uses];
    } else {
        // "New" section
        cell.textLabel.text = self.searchDisplayController.searchBar.text;
        cell.detailTextLabel.text = @"New";
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section < [[self.fetchedResultsController sections] count])
        [self.delegate didSelectElement:[self.fetchedResultsController objectAtIndexPath:indexPath]];
    
    else {
        // "New" section.
        NSString *siteName = self.searchDisplayController.searchBar.text;
        [AlertViewController showAlertWithTitle:@"New Site"
                                        message:l(@"Do you want to create a new site named:\n%@", siteName)
                                      viewStyle:UIAlertViewStyleDefault
                              tappedButtonBlock:^(UIAlertView *alert, NSInteger buttonIndex) {
                                  [tableView deselectRowAtIndexPath:indexPath animated:YES];
                                  
                                  if (buttonIndex == [alert cancelButtonIndex])
                                      return;
                                  
                                  [self.fetchedResultsController.managedObjectContext performBlock:^{
                                      MPElementEntity *element = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([MPElementGeneratedEntity class])
                                                                                               inManagedObjectContext:self.fetchedResultsController.managedObjectContext];
                                      assert([element isKindOfClass:ClassFromMPElementType(element.type)]);
                                      
                                      element.name = siteName;
                                      element.mpHashHex = [MPAppDelegate get].keyPhraseHashHex;
                                      
                                      dispatch_async(dispatch_get_main_queue(), ^{
                                          [self.delegate didSelectElement:element];
                                      });
                                  }];
                              } cancelTitle:[PearlStrings get].commonButtonCancel otherTitles:[PearlStrings get].commonButtonYes, nil];
    }
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
    
    if (indexPath.section == [[self.fetchedResultsController sections] count])
        // "New" section.
        return;
    
    if (editingStyle == UITableViewCellEditingStyleDelete)
        [self.fetchedResultsController.managedObjectContext performBlock:^{
            MPElementEntity *element = [self.fetchedResultsController objectAtIndexPath:indexPath];
            [self.fetchedResultsController.managedObjectContext deleteObject:element];

#ifndef PRODUCTION
            [TestFlight passCheckpoint:MPTestFlightCheckpointDeleteElement];
#endif
        }];
}


@end
