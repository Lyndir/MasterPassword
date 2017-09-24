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
import com.google.common.primitives.UnsignedInteger;
import com.lyndir.lhunath.opal.system.MessageAuthenticationDigests;
import com.lyndir.lhunath.opal.system.MessageDigests;
import java.io.Serializable;
import java.nio.ByteOrder;
import java.nio.charset.Charset;
import javax.annotation.Nullable;


/**
 * @see MPMasterKey.Version
 */
public interface MPAlgorithm {

    /**
     * mpw: validity for the time-based rolling counter.
     */
    int mpw_otp_window = 5 * 60 /* s */;

    /**
     * mpw: Key ID hash.
     */
    MessageDigests mpw_hash = MessageDigests.SHA256;

    /**
     * mpw: Site digest.
     */
    MessageAuthenticationDigests mpw_digest = MessageAuthenticationDigests.HmacSHA256;

    /**
     * mpw: Platform-agnostic byte order.
     */
    ByteOrder mpw_byteOrder = ByteOrder.BIG_ENDIAN;

    /**
     * mpw: Input character encoding.
     */
    Charset mpw_charset = Charsets.UTF_8;

    /**
     * mpw: Master key size (byte).
     */
    int mpw_dkLen = 64;

    /**
     * scrypt: Parallelization parameter.
     */
    int scrypt_p = 2;

    /**
     * scrypt: Memory cost parameter.
     */
    int scrypt_r = 8;

    /**
     * scrypt: CPU cost parameter.
     */
    int scrypt_N = 32768;

    MPMasterKey.Version getAlgorithmVersion();

    byte[] masterKey(String fullName, char[] masterPassword);

    byte[] siteKey(byte[] masterKey, String siteName, UnsignedInteger siteCounter, MPKeyPurpose keyPurpose,
                   @Nullable String keyContext);

    String siteResult(byte[] masterKey, final byte[] siteKey, String siteName, UnsignedInteger siteCounter, MPKeyPurpose keyPurpose,
                      @Nullable String keyContext, MPResultType resultType, @Nullable String resultParam);

    String sitePasswordFromTemplate(byte[] masterKey, byte[] siteKey, MPResultType resultType, @Nullable String resultParam);

    String sitePasswordFromCrypt(byte[] masterKey, byte[] siteKey, MPResultType resultType, @Nullable String resultParam);

    String sitePasswordFromDerive(byte[] masterKey, byte[] siteKey, MPResultType resultType, @Nullable String resultParam);

    String siteState(byte[] masterKey, final byte[] siteKey, String siteName, UnsignedInteger siteCounter, MPKeyPurpose keyPurpose,
                     @Nullable String keyContext, MPResultType resultType, String resultParam);
}
