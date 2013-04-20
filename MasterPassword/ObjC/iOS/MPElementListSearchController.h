//
//  MPSearchDelegate.h
//  MasterPassword
//
//  Created by Maarten Billemont on 04/01/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MPElementListController.h"

@interface MPElementListSearchController : MPElementListController<UISearchBarDelegate, UISearchDisplayDelegate>

@property(strong, nonatomic) UILabel *tipView;

@property(strong, nonatomic) IBOutlet UISearchDisplayController *searchDisplayController;
@property(weak, nonatomic) IBOutlet UIView *searchTipContainer;

@end
