#import <Foundation/Foundation.h>

#import "MPElementListDelegate.h"

#define MPElementListFilterNone @"MPElementListFilterNone"
#define MPElementListFilterOutdated @"MPElementListFilterOutdated"

@interface MPElementListController : UITableViewController <NSFetchedResultsControllerDelegate>

@property (weak, nonatomic) IBOutlet id<MPElementListDelegate> delegate;
@property (strong, nonatomic) NSString *filter;

@property (readonly) NSFetchedResultsController *fetchedResultsControllerByUses;
@property (readonly) NSFetchedResultsController *fetchedResultsControllerByLastUsed;
@property (readonly) NSDateFormatter *dateFormatter;

- (void)updateData;
- (void)addElementNamed:(NSString *)siteName completion:(void (^)(BOOL success))completion;
- (void)configureCell:(UITableViewCell *)cell inTableView:(UITableView *)tableView atTableIndexPath:(NSIndexPath *)indexPath;
- (void)customTableViewUpdates;

@end
