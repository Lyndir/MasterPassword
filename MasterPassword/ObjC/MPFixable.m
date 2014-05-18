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
//  MPFixable.m
//  MPFixable
//
//  Created by lhunath on 2014-04-26.
//  Copyright, lhunath (Maarten Billemont) 2014. All rights reserved.
//

#import "MPFixable.h"

MPFixableResult MPApplyFix(MPFixableResult previousResult, MPFixableResult(^fixBlock)(void)) {

    MPFixableResult additionalResult = fixBlock();
    switch (previousResult) {
        case MPFixableResultNoProblems:
            return additionalResult;
        case MPFixableResultProblemsFixed:
            switch (additionalResult) {
                case MPFixableResultNoProblems:
                case MPFixableResultProblemsFixed:
                    return previousResult;
                case MPFixableResultProblemsNotFixed:
                    return additionalResult;
            }
        case MPFixableResultProblemsNotFixed:
            return additionalResult;
    }

    Throw( @"Unexpected previous=%ld or additional=%ld result.", (long)previousResult, (long)additionalResult );
}
