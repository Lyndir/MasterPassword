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

#import "MPConfig.h"

@interface MPiOSConfig : MPConfig

@property(nonatomic, retain) NSNumber *helpHidden;
@property(nonatomic, retain) NSNumber *siteInfoHidden;
@property(nonatomic, retain) NSNumber *showSetup;
@property(nonatomic, retain) NSNumber *actionsTipShown;
@property(nonatomic, retain) NSNumber *typeTipShown;
@property(nonatomic, retain) NSNumber *loginNameTipShown;
@property(nonatomic, retain) NSNumber *traceMode;
@property(nonatomic, retain) NSNumber *dictationSearch;
@property(nonatomic, retain) NSNumber *allowDowngrade;
@property(nonatomic, retain) NSNumber *developmentFuelRemaining;
@property(nonatomic, retain) NSNumber *developmentFuelInvested;
@property(nonatomic, retain) NSNumber *developmentFuelConsumption;
@property(nonatomic, retain) NSDate *developmentFuelChecked;

@end
