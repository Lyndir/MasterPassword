//==============================================================================
// This file is part of Master Password.
// Copyright (c) 2011-2017, Maarten Billemont.
//
// Master Password is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Master Password is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You can find a copy of the GNU General Public License in the
// LICENSE file.  Alternatively, see <http://www.gnu.org/licenses/>.
//==============================================================================

#import <UIKit/UIKit.h>
#import "MPTypeViewController.h"
#import "MPSiteQuestionEntity+CoreDataClass.h"

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
