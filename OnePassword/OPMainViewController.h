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

@interface OPMainViewController : UIViewController <OPTypeDelegate, UITextFieldDelegate, UISearchBarDelegate, OPSearchResultsDelegate>

@property (strong, nonatomic) OPElementEntity *activeElement;
@property (strong, nonatomic) IBOutlet OPSearchDelegate *searchResultsController;
@property (weak, nonatomic) IBOutlet UITextField *contentField;
@property (weak, nonatomic) IBOutlet UIButton *typeButton;
@property (weak, nonatomic) IBOutlet UIWebView *helpView;
@property (weak, nonatomic) IBOutlet UILabel *siteName;
@property (weak, nonatomic) IBOutlet UILabel *passwordCounter;
@property (weak, nonatomic) IBOutlet UIButton *passwordIncrementer;

- (IBAction)didChangeContentType:(UISegmentedControl *)sender;
- (IBAction)didTriggerContent;
- (IBAction)didIncrementPasswordCounter;

@end
