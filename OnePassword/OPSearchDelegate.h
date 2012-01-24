//
//  OPSearchDelegate.h
//  OnePassword
//
//  Created by Maarten Billemont on 04/01/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OPElementEntity.h"

@protocol OPSearchResultsDelegate <NSObject>

- (void)didSelectElement:(OPElementEntity *)element;

@end

@interface OPSearchDelegate : NSObject <UITableViewDelegate, UITableViewDataSource, UISearchDisplayDelegate, NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

@property (weak, nonatomic) IBOutlet id<OPSearchResultsDelegate> delegate;
@property (weak, nonatomic) IBOutlet UISearchDisplayController *searchDisplayController;
@property (weak, nonatomic) IBOutlet UIView *searchTipContainer;

@end
