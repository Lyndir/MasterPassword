/**
* Copyright Maarten Billemont (http://www.lhunath.com, lhunath@lyndir.com)
*
* See the enclosed file LICENSE for license information (LGPLv3). If you did
* not receive this file, see http://www.gnu.org/licenses/lgpl-3.0.txt
*
* @author   Maarten Billemont <lhunath@lyndir.com>
* @license  http://www.gnu.org/licenses/lgpl-3.0.txt
*/

//
//  MPFixable.h
//  MPFixable
//
//  Created by lhunath on 2014-04-26.
//  Copyright, lhunath (Maarten Billemont) 2014. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM( NSUInteger, MPFixableResult ) {
    MPFixableResultNoProblems,
    MPFixableResultProblemsFixed,
    MPFixableResultProblemsNotFixed,
};

MPFixableResult MPApplyFix(MPFixableResult previousResult, MPFixableResult(^fixBlock)(void));

@protocol MPFixable<NSObject>

- (MPFixableResult)findAndFixInconsistenciesInContext:(NSManagedObjectContext *)context;

@end
