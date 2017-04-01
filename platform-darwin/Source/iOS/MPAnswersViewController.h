//
//  MPPreferencesViewController.h
//  MasterPassword-iOS
//
//  Created by Maarten Billemont on 04/06/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MPTypeViewController.h"
#import "MPSiteQuestionEntity.h"

@interface MPAnswersViewController : UIViewController

@property(nonatomic) IBOutlet UITableView *tableView;

- (void)setSite:(MPSiteEntity *)site;
- (MPSiteEntity *)siteInContext:(NSManagedObjectContext *)context;

@end

@interface MPGlobalAnswersCell : UITableViewCell

@property(nonatomic) IBOutlet UILabel *titleLabel;
@property(nonatomic) IBOutlet UITextField *answerField;

- (void)setSite:(MPSiteEntity *)site;

@end

@interface MPSendAnswersCell : UITableViewCell

@end

@interface MPMultipleAnswersCell : UITableViewCell<UITextFieldDelegate>

@end

@interface MPAnswersQuestionCell : UITableViewCell

@property(nonatomic) IBOutlet UITextField *questionField;
@property(nonatomic) IBOutlet UITextField *answerField;

- (void)setQuestion:(MPSiteQuestionEntity *)question forSite:(MPSiteEntity *)site inVC:(MPAnswersViewController *)VC;

@end
