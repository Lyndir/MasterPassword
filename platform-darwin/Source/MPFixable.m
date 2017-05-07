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
