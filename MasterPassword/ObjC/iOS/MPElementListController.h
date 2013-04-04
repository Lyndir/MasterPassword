//
// Created by lhunath on 2013-02-09.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>

#import "MPElementListDelegate.h"

typedef enum {
    MPSearchScopeAll,
    MPSearchScopeOutdated,
} MPSearchScope;

@interface MPElementListController : UITableViewController <NSFetchedResultsControllerDelegate>

@property (weak, nonatomic) IBOutlet id<MPElementListDelegate> delegate;
@property (readonly) NSFetchedResultsController *fetchedResultsController;
@property (readonly) NSDateFormatter *dateFormatter;

- (void)updateData;
- (void)addElementNamed:(NSString *)siteName completion:(void (^)(BOOL success))completion;
- (void)configureCell:(UITableViewCell *)cell inTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath;
- (void)customTableViewUpdates;

@end
