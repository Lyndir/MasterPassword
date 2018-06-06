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

package com.lyndir.masterpassword.model;

import org.joda.time.format.DateTimeFormatter;
import org.joda.time.format.ISODateTimeFormat;


/**
 * @author lhunath, 2016-10-29
 */
public final class MPConstant {

    /* Environment */

    /**
     * mpw: default path to look for run configuration files if the platform default is not desired.
     */
    public static final String env_rcDir        = "MPW_RCDIR";
    /**
     * mpw: permit automatic update checks.
     */
    public static final String env_checkUpdates = "MPW_CHECKUPDATES";

    /* Algorithm */

    public static final int MS_PER_S = 1000;

    public static final DateTimeFormatter dateTimeFormatter = ISODateTimeFormat.dateTimeNoMillis().withZoneUTC();
}
