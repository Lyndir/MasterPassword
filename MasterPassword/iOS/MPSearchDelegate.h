//
//  MPSearchDelegate.h
//  MasterPassword
//
//  Created by Maarten Billemont on 04/01/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MPElementEntity.h"

@protocol MPSearchResultsDelegate<NSObject>

- (void)didSelectElement:(MPElementEntity *)element;

@end

@interface MPSearchDelegate : NSObject<UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UISearchDisplayDelegate, NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) NSDateFormatter            *dateFormatter;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSString                   *query;
@property (strong, nonatomic) UILabel                    *tipView;

@property (weak, nonatomic) IBOutlet id<MPSearchResultsDelegate> delegate;
@property (strong, nonatomic) IBOutlet UISearchDisplayController *searchDisplayController;
@property (weak, nonatomic) IBOutlet UIView                    *searchTipContainer;

@end
