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

package com.lyndir.masterpassword;

import com.google.common.base.Charsets;
import com.lyndir.lhunath.opal.system.MessageAuthenticationDigests;
import com.lyndir.lhunath.opal.system.MessageDigests;
import java.nio.ByteOrder;
import java.nio.charset.Charset;


/**
 * @author lhunath, 2016-10-29
 */
public final class MPConstant {

    /* Environment */

    /**
     * mpw: default user name if one is not provided.
     */
    public static final String env_userName     = "MP_USERNAME";
    /**
     * mpw: default site type if one is not provided.
     *
     * @see MPSiteType#forOption(String)
     */
    public static final String env_siteType     = "MP_SITETYPE";
    /**
     * mpw: default site counter value if one is not provided.
     */
    public static final String env_siteCounter  = "MP_SITECOUNTER";
    /**
     * mpw: default path to look for run configuration files if the platform default is not desired.
     */
    public static final String env_rcDir        = "MP_RCDIR";
    /**
     * mpw: permit automatic update checks.
     */
    public static final String env_checkUpdates = "MP_CHECKUPDATES";

    /* Algorithm */

    /**
     * scrypt: CPU cost parameter.
     */
    public static final int                          scrypt_N      = 32768;
    /**
     * scrypt: Memory cost parameter.
     */
    public static final int                          scrypt_r      = 8;
    /**
     * scrypt: Parallelization parameter.
     */
    public static final int                          scrypt_p      = 2;
    /**
     * mpw: Master key size (byte).
     */
    public static final int                          mpw_dkLen     = 64;
    /**
     * mpw: Input character encoding.
     */
    public static final Charset                      mpw_charset         = Charsets.UTF_8;
    /**
     * mpw: Platform-agnostic byte order.
     */
    public static final ByteOrder                    mpw_byteOrder       = ByteOrder.BIG_ENDIAN;
    /**
     * mpw: Site digest.
     */
    public static final MessageAuthenticationDigests mpw_digest          = MessageAuthenticationDigests.HmacSHA256;
    /**
     * mpw: Key ID hash.
     */
    public static final MessageDigests               mpw_hash            = MessageDigests.SHA256;
    /**
     * mpw: validity for the time-based rolling counter.
     */
    public static final int                          mpw_counter_timeout = 5 * 60 /* s */;


    public static final int MS_PER_S = 1000;
}
