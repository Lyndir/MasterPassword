//
//  OPMainViewController.h
//  MasterPassword
//
//  Created by Maarten Billemont on 24/11/11.
//  Copyright (c) 2011 Lyndir. All rights reserved.
//

#import "OPTypeViewController.h"
#import "OPElementEntity.h"
#import "OPSearchDelegate.h"

@interface OPMainViewController : UIViewController <OPTypeDelegate, UITextFieldDelegate, UISearchBarDelegate, OPSearchResultsDelegate, UIWebViewDelegate>

@property (strong, nonatomic) OPElementEntity *activeElement;
@property (strong, nonatomic) IBOutlet OPSearchDelegate *searchResultsController;
@property (weak, nonatomic) IBOutlet UITextField *contentField;
@property (weak, nonatomic) IBOutlet UIButton *typeButton;
@property (weak, nonatomic) IBOutlet UIWebView *helpView;
@property (weak, nonatomic) IBOutlet UILabel *siteName;
@property (weak, nonatomic) IBOutlet UILabel *passwordCounter;
@property (weak, nonatomic) IBOutlet UIButton *passwordIncrementer;
@property (weak, nonatomic) IBOutlet UIButton *passwordEdit;
@property (weak, nonatomic) IBOutlet UIView *contentContainer;
@property (weak, nonatomic) IBOutlet UIView *helpContainer;
@property (weak, nonatomic) IBOutlet UIView *contentTipContainer;
@property (weak, nonatomic) IBOutlet UIView *alertContainer;
@property (weak, nonatomic) IBOutlet UILabel *alertTitle;
@property (weak, nonatomic) IBOutlet UITextView *alertBody;
@property (weak, nonatomic) IBOutlet UILabel *contentTipBody;
@property (weak, nonatomic) IBOutlet UIImageView *contentTipEditIcon;
@property (weak, nonatomic) IBOutlet UIView *searchTipContainer;

- (IBAction)copyContent;
- (IBAction)incrementPasswordCounter;
- (IBAction)editPassword;
- (IBAction)closeAlert;
- (IBAction)action:(UIBarButtonItem *)sender;

- (BOOL)isHelpVisible;
- (void)toggleHelpAnimated:(BOOL)animated;
- (void)setHelpHidden:(BOOL)hidden animated:(BOOL)animated;
- (void)setHelpChapter:(NSString *)chapter;

@end
