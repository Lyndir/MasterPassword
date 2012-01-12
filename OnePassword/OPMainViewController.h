//
//  OPMainViewController.h
//  OnePassword
//
//  Created by Maarten Billemont on 24/11/11.
//  Copyright (c) 2011 Lyndir. All rights reserved.
//

#import "OPTypeViewController.h"
#import "OPElementEntity.h"
#import "OPSearchDelegate.h"

@interface OPMainViewController : UITableViewController <OPTypeDelegate, UITextFieldDelegate, UISearchBarDelegate, OPSearchResultsDelegate>

@property (strong, nonatomic) OPElementEntity *activeElement;
@property (strong, nonatomic) IBOutlet OPSearchDelegate *searchResultsController;
@property (weak, nonatomic) IBOutlet UITextField *contentField;
@property (weak, nonatomic) IBOutlet UITextView *contentTextView;
@property (weak, nonatomic) IBOutlet UILabel *typeLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *contentType;

- (IBAction)didChangeContentType:(UISegmentedControl *)sender;
- (IBAction)didTriggerContent:(id)sender;

@end
